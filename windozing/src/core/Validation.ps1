# Validation.ps1 - Input validation and safety checks for windozing

function Test-IsAdministrator {
    [CmdletBinding()]
    param()
    
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WindowsVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SupportedVersions
    )
    
    try {
        $osInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $currentBuild = $osInfo.CurrentBuildNumber
        
        # Map build numbers to versions
        $versionMap = @{
            "10" = @(10240, 19045)  # Windows 10 range
            "11" = @(22000, 99999)  # Windows 11 range
        }
        
        foreach ($version in $SupportedVersions) {
            if ($versionMap.ContainsKey($version)) {
                $range = $versionMap[$version]
                if ($currentBuild -ge $range[0] -and $currentBuild -le $range[1]) {
                    return $true
                }
            }
        }
        
        return $false
    }
    catch {
        Write-Error "Failed to determine Windows version: $_"
        return $false
    }
}

function Test-RegistryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    try {
        return Test-Path -Path $Path -PathType Container
    }
    catch {
        return $false
    }
}

function Test-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    try {
        if (-not (Test-RegistryPath -Path $Path)) {
            return $false
        }
        
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        return $null -ne $value
    }
    catch {
        return $false
    }
}

function Test-SafeRegistryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    # List of protected registry paths that should not be modified
    $protectedPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify",
        "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    )
    
    foreach ($protected in $protectedPaths) {
        if ($Path -like "$protected*") {
            Write-Warning "Attempting to modify protected registry path: $Path"
            return $false
        }
    }
    
    return $true
}

function Confirm-UserAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [string]$Title = "Confirm Action",
        
        [switch]$DefaultNo
    )
    
    $choices = @(
        [Management.Automation.Host.ChoiceDescription]::new("&Yes", "Proceed with the action")
        [Management.Automation.Host.ChoiceDescription]::new("&No", "Cancel the action")
    )
    
    $defaultChoice = if ($DefaultNo) { 1 } else { 0 }
    
    $result = $Host.UI.PromptForChoice($Title, $Message, $choices, $defaultChoice)
    
    return $result -eq 0
}

function Test-ProcessRunning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ProcessNames
    )
    
    $runningProcesses = @()
    
    foreach ($name in $ProcessNames) {
        $process = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($process) {
            $runningProcesses += $name
        }
    }
    
    return $runningProcesses
}

function Test-ServiceRunning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames
    )
    
    $runningServices = @()
    
    foreach ($name in $ServiceNames) {
        $service = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            $runningServices += $name
        }
    }
    
    return $runningServices
}

function Test-DiskSpace {
    [CmdletBinding()]
    param(
        [int64]$RequiredSpaceMB = 100,
        
        [string]$Drive = "C:"
    )
    
    try {
        $disk = Get-PSDrive -Name $Drive.TrimEnd(':') -ErrorAction Stop
        $freeSpaceMB = [Math]::Round($disk.Free / 1MB)
        
        if ($freeSpaceMB -lt $RequiredSpaceMB) {
            Write-Warning "Insufficient disk space. Required: ${RequiredSpaceMB}MB, Available: ${freeSpaceMB}MB"
            return $false
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to check disk space: $_"
        return $false
    }
}

function Test-SystemReady {
    [CmdletBinding()]
    param(
        [hashtable]$Requirements = @{}
    )
    
    $ready = $true
    $issues = @()
    
    # Check if running as administrator
    if (-not (Test-IsAdministrator)) {
        $ready = $false
        $issues += "Not running as administrator"
    }
    
    # Check Windows version if specified
    if ($Requirements.WindowsVersions) {
        if (-not (Test-WindowsVersion -SupportedVersions $Requirements.WindowsVersions)) {
            $ready = $false
            $issues += "Unsupported Windows version"
        }
    }
    
    # Check disk space if specified
    if ($Requirements.DiskSpaceMB) {
        if (-not (Test-DiskSpace -RequiredSpaceMB $Requirements.DiskSpaceMB)) {
            $ready = $false
            $issues += "Insufficient disk space"
        }
    }
    
    # Check for conflicting processes
    if ($Requirements.ConflictingProcesses) {
        $running = Test-ProcessRunning -ProcessNames $Requirements.ConflictingProcesses
        if ($running) {
            $ready = $false
            $issues += "Conflicting processes running: $($running -join ', ')"
        }
    }
    
    return @{
        Ready = $ready
        Issues = $issues
    }
}

function Test-RegistryValueType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Value,
        
        [Parameter(Mandatory)]
        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [string]$ExpectedType
    )
    
    $actualType = switch ($Value.GetType().Name) {
        "String" { "String" }
        "Int32" { "DWord" }
        "Int64" { "QWord" }
        "Byte[]" { "Binary" }
        "String[]" { "MultiString" }
        default { "Unknown" }
    }
    
    return $actualType -eq $ExpectedType
}

function Get-SafeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Value,
        
        [Parameter(Mandatory)]
        [ValidateSet("String", "Int", "Bool", "Array")]
        [string]$Type,
        
        $Default = $null,
        
        $Min = $null,
        
        $Max = $null,
        
        [string[]]$AllowedValues = $null
    )
    
    try {
        switch ($Type) {
            "String" {
                $result = [string]$Value
                if ($AllowedValues -and $result -notin $AllowedValues) {
                    Write-Warning "Value '$result' not in allowed values"
                    return $Default
                }
                return $result
            }
            
            "Int" {
                $result = [int]$Value
                if ($null -ne $Min -and $result -lt $Min) {
                    Write-Warning "Value $result is less than minimum $Min"
                    return $Min
                }
                if ($null -ne $Max -and $result -gt $Max) {
                    Write-Warning "Value $result is greater than maximum $Max"
                    return $Max
                }
                return $result
            }
            
            "Bool" {
                return [bool]$Value
            }
            
            "Array" {
                if ($Value -is [array]) {
                    return $Value
                }
                return @($Value)
            }
        }
    }
    catch {
        Write-Warning "Failed to convert value to $Type : $_"
        return $Default
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-IsAdministrator',
    'Test-WindowsVersion',
    'Test-RegistryPath',
    'Test-RegistryValue',
    'Test-SafeRegistryPath',
    'Confirm-UserAction',
    'Test-ProcessRunning',
    'Test-ServiceRunning',
    'Test-DiskSpace',
    'Test-SystemReady',
    'Test-RegistryValueType',
    'Get-SafeValue'
)