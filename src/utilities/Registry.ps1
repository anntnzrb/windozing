# Registry.ps1 - Registry manipulation utilities

function Edit-RegistryEntry {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        $Value,
        
        [Parameter(ParameterSetName = "Decimal")]
        [switch]$Dec,
        
        [Parameter(ParameterSetName = "Hexadecimal")]
        [switch]$Hex,
        
        [Parameter(ParameterSetName = "String")]
        [switch]$String,
        
        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [string]$Type = $null,
        
        [switch]$Force
    )
    
    # Import validation module if not already loaded
    if (-not (Get-Command Test-SafeRegistryPath -ErrorAction SilentlyContinue)) {
        Import-Module "$PSScriptRoot\..\core\Validation.ps1" -Force
    }
    
    # Safety check
    if (-not (Test-SafeRegistryPath -Path $Path)) {
        if (-not $Force) {
            Write-Error "Attempted to modify protected registry path: $Path. Use -Force to override."
            return
        }
        Write-Warning "Modifying protected registry path: $Path"
    }
    
    # Ensure registry path exists
    if (-not (Test-Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Create registry path")) {
            New-Item -Path $Path -Force | Out-Null
        }
    }
    
    # Determine type and value
    if ($Dec) {
        $finalValue = [int]$Value
        $finalType = if ($Type) { $Type } else { "DWord" }
    }
    elseif ($Hex) {
        $finalValue = [UInt32]::Parse($Value, [System.Globalization.NumberStyles]::HexNumber)
        $finalType = if ($Type) { $Type } else { "DWord" }
    }
    elseif ($String) {
        $finalValue = [string]$Value
        $finalType = if ($Type) { $Type } else { "String" }
    }
    else {
        # Auto-detect type
        if ($Value -is [int] -or $Value -is [long]) {
            $finalValue = $Value
            $finalType = if ($Type) { $Type } else { "DWord" }
        }
        elseif ($Value -is [string]) {
            $finalValue = $Value
            $finalType = if ($Type) { $Type } else { "String" }
        }
        else {
            $finalValue = $Value
            $finalType = if ($Type) { $Type } else { "String" }
        }
    }
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set value to $finalValue")) {
        try {
            Set-ItemProperty -Path $Path -Name $Name -Value $finalValue -Type $finalType
            Write-Verbose "Set $Path\$Name = $finalValue (Type: $finalType)"
        }
        catch {
            Write-Error "Failed to set registry value: $_"
        }
    }
}

function Get-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        $DefaultValue = $null
    )
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            return $value.$Name
        }
    }
    catch {
        Write-Verbose "Registry value not found: $Path\$Name"
    }
    
    return $DefaultValue
}

function Test-RegistryKeyExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    return Test-Path $Path
}

function Remove-RegistryValue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [switch]$Force
    )
    
    if (-not (Test-Path $Path)) {
        Write-Verbose "Registry path does not exist: $Path"
        return $true
    }
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Remove registry value")) {
        try {
            Remove-ItemProperty -Path $Path -Name $Name -Force:$Force -ErrorAction Stop
            Write-Verbose "Removed registry value: $Path\$Name"
            return $true
        }
        catch {
            if ($_.Exception.Message -notlike "*Property*does not exist*") {
                Write-Error "Failed to remove registry value: $_"
                return $false
            }
            return $true
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Edit-RegistryEntry',
    'Get-RegistryValue',
    'Test-RegistryKeyExists',
    'Remove-RegistryValue'
)