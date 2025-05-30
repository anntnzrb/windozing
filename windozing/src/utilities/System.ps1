# System.ps1 - System utilities

function Get-WindowsVersion {
    [CmdletBinding()]
    param()
    
    try {
        $osInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        
        return [PSCustomObject]@{
            ProductName = $osInfo.ProductName
            DisplayVersion = $osInfo.DisplayVersion
            BuildNumber = $osInfo.CurrentBuildNumber
            UBR = $osInfo.UBR
            ReleaseId = $osInfo.ReleaseId
            Edition = $osInfo.EditionID
            Architecture = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        }
    }
    catch {
        Write-Error "Failed to get Windows version information: $_"
        return $null
    }
}

function Test-WindowsBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$MinimumBuild,
        
        [int]$MaximumBuild = 99999
    )
    
    $currentBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
    
    return ($currentBuild -ge $MinimumBuild -and $currentBuild -le $MaximumBuild)
}

function Get-SystemUptime {
    [CmdletBinding()]
    param()
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        
        return [PSCustomObject]@{
            Days = $uptime.Days
            Hours = $uptime.Hours
            Minutes = $uptime.Minutes
            TotalHours = [Math]::Round($uptime.TotalHours, 2)
            LastBootTime = $os.LastBootUpTime
            FormattedUptime = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        }
    }
    catch {
        Write-Error "Failed to get system uptime: $_"
        return $null
    }
}

function Get-SystemInfo {
    [CmdletBinding()]
    param()
    
    try {
        $computerInfo = Get-CimInstance Win32_ComputerSystem
        $osInfo = Get-CimInstance Win32_OperatingSystem
        $processorInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
        
        return [PSCustomObject]@{
            ComputerName = $computerInfo.Name
            Domain = $computerInfo.Domain
            Manufacturer = $computerInfo.Manufacturer
            Model = $computerInfo.Model
            TotalMemoryGB = [Math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
            AvailableMemoryGB = [Math]::Round($osInfo.FreePhysicalMemory / 1MB / 1024, 2)
            ProcessorName = $processorInfo.Name
            ProcessorCores = $processorInfo.NumberOfCores
            ProcessorThreads = $processorInfo.NumberOfLogicalProcessors
            SystemType = $computerInfo.SystemType
        }
    }
    catch {
        Write-Error "Failed to get system information: $_"
        return $null
    }
}

function Test-Feature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName
    )
    
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
        return $feature.State -eq "Enabled"
    }
    catch {
        Write-Verbose "Feature $FeatureName not found or error occurred: $_"
        return $false
    }
}

function Test-Service {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [ValidateSet("Running", "Stopped", "Paused", "Any")]
        [string]$Status = "Any"
    )
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        return $false
    }
    
    if ($Status -eq "Any") {
        return $true
    }
    
    return $service.Status -eq $Status
}

function Get-DiskUsage {
    [CmdletBinding()]
    param(
        [string]$DriveLetter = "C"
    )
    
    try {
        $drive = Get-PSDrive -Name $DriveLetter.TrimEnd(':') -ErrorAction Stop
        
        return [PSCustomObject]@{
            Drive = $DriveLetter
            TotalGB = [Math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
            UsedGB = [Math]::Round($drive.Used / 1GB, 2)
            FreeGB = [Math]::Round($drive.Free / 1GB, 2)
            PercentUsed = [Math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)
            PercentFree = [Math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 2)
        }
    }
    catch {
        Write-Error "Failed to get disk usage for drive $DriveLetter : $_"
        return $null
    }
}

function Invoke-SystemCommand {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        
        [string[]]$Arguments = @(),
        
        [switch]$AsAdmin,
        
        [switch]$Wait,
        
        [switch]$NoNewWindow
    )
    
    if ($PSCmdlet.ShouldProcess($Command, "Execute system command")) {
        try {
            $startParams = @{
                FilePath = $Command
                ArgumentList = $Arguments
                PassThru = $true
            }
            
            if ($AsAdmin) {
                $startParams['Verb'] = 'RunAs'
            }
            
            if ($NoNewWindow) {
                $startParams['NoNewWindow'] = $true
            }
            
            $process = Start-Process @startParams
            
            if ($Wait) {
                $process.WaitForExit()
                return $process.ExitCode
            }
            
            return $process
        }
        catch {
            Write-Error "Failed to execute command: $_"
            return $null
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-WindowsVersion',
    'Test-WindowsBuild',
    'Get-SystemUptime',
    'Get-SystemInfo',
    'Test-Feature',
    'Test-Service',
    'Get-DiskUsage',
    'Invoke-SystemCommand'
)