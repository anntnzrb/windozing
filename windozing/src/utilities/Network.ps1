# Network.ps1 - Network interface utilities for windozing

function Get-NetworkInterfaces {
    [CmdletBinding()]
    param(
        [switch]$ActiveOnly
    )
    
    try {
        # Get network adapters with their registry information
        $adapters = Get-NetAdapter | Where-Object {
            (-not $ActiveOnly) -or ($_.Status -eq 'Up')
        }
        
        $interfaces = @()
        
        foreach ($adapter in $adapters) {
            # Build the registry path for this interface
            $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
            
            # Check if the registry path exists (some interfaces may not have TCP/IP configured)
            if (Test-Path $interfacePath) {
                $interfaces += [PSCustomObject]@{
                    Name = $adapter.Name
                    FriendlyName = $adapter.InterfaceDescription
                    GUID = $adapter.InterfaceGuid
                    Status = $adapter.Status
                    RegistryPath = $interfacePath
                    MediaType = $adapter.MediaType
                    LinkSpeed = $adapter.LinkSpeed
                }
            }
        }
        
        return $interfaces
    }
    catch {
        Write-ErrorLog "Failed to enumerate network interfaces: $_" -Category "Network"
        return @()
    }
}

function Get-NetworkInterfaceTweakPaths {
    [CmdletBinding()]
    param(
        [switch]$ActiveOnly
    )
    
    $interfaces = Get-NetworkInterfaces -ActiveOnly:$ActiveOnly
    return $interfaces | ForEach-Object { $_.RegistryPath }
}

function Apply-NetworkInterfaceTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$InterfaceTweaks,
        
        [switch]$ActiveOnly,
        [switch]$Force,
        [switch]$DryRun
    )
    
    $interfaces = Get-NetworkInterfaces -ActiveOnly:$ActiveOnly
    $results = @()
    
    if ($interfaces.Count -eq 0) {
        Write-WarnLog "No network interfaces found" -Category "Network"
        return $results
    }
    
    Write-InfoLog "Found $($interfaces.Count) network interface$(if($interfaces.Count -ne 1){'s'})" -Category "Network"
    
    foreach ($interface in $interfaces) {
        Write-InfoLog "Processing interface: $($interface.FriendlyName)" -Category "Network"
        
        # Skip certain interface types if not forced
        if (-not $Force) {
            $skipTypes = @("Loopback", "Tunnel", "VPN")
            if ($skipTypes | Where-Object { $interface.MediaType -like "*$_*" -or $interface.FriendlyName -like "*$_*" }) {
                Write-InfoLog "Skipping interface type: $($interface.MediaType)" -Category "Network"
                continue
            }
        }
        
        foreach ($tweak in $InterfaceTweaks) {
            $result = [PSCustomObject]@{
                InterfaceName = $interface.Name
                FriendlyName = $interface.FriendlyName
                TweakId = $tweak.id
                Success = $false
                DryRun = $DryRun
                Error = $null
            }
            
            try {
                if ($DryRun) {
                    Write-InfoLog "[DRY RUN] Would apply $($tweak.id) to $($interface.FriendlyName): $($tweak.key) = $($tweak.value)" -Category "Network"
                    $result.Success = $true
                }
                else {
                    # Ensure the registry path exists
                    if (-not (Test-Path $interface.RegistryPath)) {
                        Write-WarnLog "Registry path does not exist: $($interface.RegistryPath)" -Category "Network"
                        continue
                    }
                    
                    # Apply the tweak to this interface
                    Set-ItemProperty -Path $interface.RegistryPath -Name $tweak.key -Value $tweak.value -Type $tweak.type -Force
                    
                    Write-DebugLog "Applied $($tweak.id) to $($interface.FriendlyName): $($tweak.key) = $($tweak.value)" -Category "Network"
                    $result.Success = $true
                }
            }
            catch {
                $errorMessage = "Failed to apply $($tweak.id) to $($interface.FriendlyName): $_"
                Write-ErrorLog $errorMessage -Category "Network"
                $result.Error = $errorMessage
            }
            
            $results += $result
        }
    }
    
    return $results
}

function Test-NetworkInterfaceHealth {
    [CmdletBinding()]
    param(
        [string]$InterfaceName = $null
    )
    
    try {
        $interfaces = Get-NetworkInterfaces
        
        if ($InterfaceName) {
            $interfaces = $interfaces | Where-Object { $_.Name -eq $InterfaceName }
        }
        
        $healthReport = @()
        
        foreach ($interface in $interfaces) {
            $health = [PSCustomObject]@{
                Name = $interface.FriendlyName
                Status = $interface.Status
                HasTcpipConfig = Test-Path $interface.RegistryPath
                Connectivity = "Unknown"
            }
            
            # Test basic connectivity if interface is up
            if ($interface.Status -eq 'Up') {
                try {
                    $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -TimeoutSeconds 3
                    $health.Connectivity = if ($pingResult) { "Good" } else { "Limited" }
                }
                catch {
                    $health.Connectivity = "Failed"
                }
            }
            
            $healthReport += $health
        }
        
        return $healthReport
    }
    catch {
        Write-ErrorLog "Failed to test network interface health: $_" -Category "Network"
        return @()
    }
}

function Get-NetworkTweakStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$InterfaceTweaks
    )
    
    $interfaces = Get-NetworkInterfaces
    $status = @()
    
    foreach ($interface in $interfaces) {
        foreach ($tweak in $InterfaceTweaks) {
            try {
                $currentValue = Get-ItemProperty -Path $interface.RegistryPath -Name $tweak.key -ErrorAction SilentlyContinue
                
                $tweakStatus = [PSCustomObject]@{
                    InterfaceName = $interface.FriendlyName
                    TweakId = $tweak.id
                    CurrentValue = if ($currentValue) { $currentValue.($tweak.key) } else { "Not Set" }
                    ExpectedValue = $tweak.value
                    IsApplied = $false
                }
                
                if ($currentValue -and $currentValue.($tweak.key) -eq $tweak.value) {
                    $tweakStatus.IsApplied = $true
                }
                
                $status += $tweakStatus
            }
            catch {
                Write-DebugLog "Could not check tweak status for $($interface.FriendlyName): $_" -Category "Network"
            }
        }
    }
    
    return $status
}

# Export functions
Export-ModuleMember -Function @(
    'Get-NetworkInterfaces',
    'Get-NetworkInterfaceTweakPaths', 
    'Apply-NetworkInterfaceTweaks',
    'Test-NetworkInterfaceHealth',
    'Get-NetworkTweakStatus'
)