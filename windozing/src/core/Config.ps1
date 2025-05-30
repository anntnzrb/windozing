# Config.ps1 - Configuration management for windozing

$script:ConfigPath = Join-Path $PSScriptRoot "..\..\config"
$script:ConfigCache = @{}

function Initialize-Config {
    [CmdletBinding()]
    param(
        [string]$ConfigDirectory = $null
    )
    
    if ($ConfigDirectory) {
        $script:ConfigPath = $ConfigDirectory
    }
    
    # Ensure config directory exists
    if (-not (Test-Path $script:ConfigPath)) {
        Write-Warning "Config directory not found at: $script:ConfigPath"
        return $false
    }
    
    # Load all configuration files
    $configFiles = @("tweaks.json", "defaults.json")
    
    foreach ($file in $configFiles) {
        $filePath = Join-Path $script:ConfigPath $file
        if (Test-Path $filePath) {
            try {
                $configName = [System.IO.Path]::GetFileNameWithoutExtension($file)
                $script:ConfigCache[$configName] = Get-Content $filePath -Raw | ConvertFrom-Json
            }
            catch {
                Write-Error "Failed to load config file $file : $_"
                return $false
            }
        }
    }
    
    return $true
}

function Get-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigName,
        
        [string]$Section = $null,
        
        [string]$Key = $null
    )
    
    # Check if config is loaded
    if (-not $script:ConfigCache.ContainsKey($ConfigName)) {
        Write-Error "Configuration '$ConfigName' not found. Did you run Initialize-Config?"
        return $null
    }
    
    $config = $script:ConfigCache[$ConfigName]
    
    # Return full config if no section specified
    if (-not $Section) {
        return $config
    }
    
    # Navigate to section
    $current = $config
    foreach ($part in $Section.Split('.')) {
        if ($current.PSObject.Properties.Name -contains $part) {
            $current = $current.$part
        }
        else {
            Write-Error "Section '$part' not found in configuration"
            return $null
        }
    }
    
    # Return section or specific key
    if ($Key) {
        if ($current.PSObject.Properties.Name -contains $Key) {
            return $current.$Key
        }
        else {
            Write-Error "Key '$Key' not found in section '$Section'"
            return $null
        }
    }
    
    return $current
}

function Set-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigName,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        $Value
    )
    
    if (-not $script:ConfigCache.ContainsKey($ConfigName)) {
        $script:ConfigCache[$ConfigName] = [PSCustomObject]@{}
    }
    
    $parts = $Path.Split('.')
    $current = $script:ConfigCache[$ConfigName]
    
    # Navigate to parent
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $part = $parts[$i]
        if (-not ($current.PSObject.Properties.Name -contains $part)) {
            $current | Add-Member -NotePropertyName $part -NotePropertyValue ([PSCustomObject]@{})
        }
        $current = $current.$part
    }
    
    # Set the value
    $lastPart = $parts[-1]
    if ($current.PSObject.Properties.Name -contains $lastPart) {
        $current.$lastPart = $Value
    }
    else {
        $current | Add-Member -NotePropertyName $lastPart -NotePropertyValue $Value
    }
    
    return $true
}

function Save-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigName
    )
    
    if (-not $script:ConfigCache.ContainsKey($ConfigName)) {
        Write-Error "Configuration '$ConfigName' not found"
        return $false
    }
    
    $filePath = Join-Path $script:ConfigPath "$ConfigName.json"
    
    try {
        $script:ConfigCache[$ConfigName] | ConvertTo-Json -Depth 10 | 
            Set-Content -Path $filePath -Encoding UTF8
        return $true
    }
    catch {
        Write-Error "Failed to save config file: $_"
        return $false
    }
}

function New-TweakConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Category,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Description = "",
        
        [ValidateSet("low", "medium", "high")]
        [string]$Risk = "low",
        
        [bool]$RequiresRestart = $false,
        
        [string[]]$WindowsVersions = @("10", "11"),
        
        [hashtable[]]$Tweaks = @()
    )
    
    $config = @{
        name = $Name
        description = $Description
        risk = $Risk
        requires_restart = $RequiresRestart
        windows_versions = $WindowsVersions
        tweaks = $Tweaks
    }
    
    return $config
}

function Get-TweaksByCategory {
    [CmdletBinding()]
    param(
        [string]$Category = $null
    )
    
    $tweaksConfig = Get-Config -ConfigName "tweaks"
    
    if (-not $tweaksConfig) {
        return @()
    }
    
    if ($Category) {
        if ($tweaksConfig.PSObject.Properties.Name -contains $Category) {
            return @($tweaksConfig.$Category)
        }
        else {
            return @()
        }
    }
    
    # Return all categories
    $allTweaks = @{}
    foreach ($prop in $tweaksConfig.PSObject.Properties) {
        $allTweaks[$prop.Name] = $prop.Value
    }
    
    return $allTweaks
}

function Test-WindowsVersionCompatibility {
    [CmdletBinding()]
    param(
        [string[]]$SupportedVersions
    )
    
    $currentVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $majorVersion = $currentVersion.Split('.')[0]
    
    return $SupportedVersions -contains $majorVersion
}

function Get-DefaultValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,
        
        $DefaultValue = $null
    )
    
    $defaults = Get-Config -ConfigName "defaults"
    
    if ($defaults -and $defaults.PSObject.Properties.Name -contains $Key) {
        return $defaults.$Key
    }
    
    return $DefaultValue
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Config',
    'Get-Config',
    'Set-Config',
    'Save-Config',
    'New-TweakConfig',
    'Get-TweaksByCategory',
    'Test-WindowsVersionCompatibility',
    'Get-DefaultValue'
)