#Requires -RunAsAdministrator

[CmdletBinding()]
param()

using namespace System.Collections.Generic

enum MappingState {
    Normal
    Mapped  
    Unknown
}

class KeyboardConfig {
    [string]$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
    [string]$ValueName = "Scancode Map"
    [byte]$EscapeKey = 0x01
    [byte]$CapsLockKey = 0x3A
    
    [byte[]] GetScancodeMap() {
        return [byte[]](
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x02, 0x00, 0x00, 0x00,
            $this.EscapeKey, 0x00,
            $this.CapsLockKey, 0x00,
            0x00, 0x00, 0x00, 0x00
        )
    }
}

function Test-ByteArraysEqual {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()][byte[]]$Left,
        [AllowNull()][byte[]]$Right
    )
    
    if (($null -eq $Left) -ne ($null -eq $Right)) { return $false }
    if ($null -eq $Left) { return $true }
    if ($Left.Length -ne $Right.Length) { return $false }
    
    for ($i = 0; $i -lt $Left.Length; $i++) {
        if ($Left[$i] -ne $Right[$i]) { return $false }
    }
    
    return $true
}

function Get-CurrentScancodeMap {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [KeyboardConfig]$Config
    )
    
    try {
        Get-ItemPropertyValue -Path $Config.RegistryPath -Name $Config.ValueName -ErrorAction Stop
    }
    catch [System.Management.Automation.PSArgumentException] {
        $null
    }
    catch {
        Write-Warning "Error reading registry: $($_.Exception.Message)"
        $null
    }
}

function Get-MappingState {
    [CmdletBinding()]
    [OutputType([MappingState])]
    param(
        [AllowNull()][byte[]]$Current,
        [byte[]]$Target
    )
    
    if (Test-ByteArraysEqual -Left $Current -Right $Target) {
        [MappingState]::Mapped
    }
    elseif ($null -eq $Current) {
        [MappingState]::Normal
    }
    else {
        [MappingState]::Unknown
    }
}

function Show-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MappingState]$State
    )
    
    $messages = @{
        [MappingState]::Normal = "Current Status: Caps Lock is behaving normally."
        [MappingState]::Mapped = "Current Status: Caps Lock is remapped to Escape."
        [MappingState]::Unknown = "Current Status: Caps Lock has an unknown custom mapping."
    }
    
    Write-Host $messages[$State]
    
    if ($State -eq [MappingState]::Unknown) {
        Write-Warning "Proceeding will overwrite the existing custom mapping."
    }
}

function Confirm-Action {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Verb,
        [Parameter(Mandatory)]
        [string]$Details
    )
    
    $response = Read-Host "Do you want to $Verb $Details? (y/n)"
    $response -eq 'y'
}

function Invoke-RegistryChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [KeyboardConfig]$Config,
        [Parameter(Mandatory)]
        [MappingState]$CurrentState,
        [Parameter(Mandatory)]
        [string]$ActionVerb
    )
    
    try {
        switch ($CurrentState) {
            ([MappingState]::Mapped) {
                Remove-ItemProperty -Path $Config.RegistryPath -Name $Config.ValueName -Force -ErrorAction Stop
                $successMsg = "Caps Lock will function normally after restart."
            }
            default {
                Set-ItemProperty -Path $Config.RegistryPath -Name $Config.ValueName -Value $Config.GetScancodeMap() -Type Binary -Force -ErrorAction Stop
                $successMsg = "Caps Lock will function as Escape after restart."
            }
        }
        
        Write-Host "[SUCCESS] Registry updated. $successMsg" -ForegroundColor Green
        Write-Host "A system restart is required for changes to take effect." -ForegroundColor Magenta
    }
    catch {
        Write-Error "Could not $ActionVerb registry settings: $($_.Exception.Message)"
    }
}

function Start-CapsLockEscapeToggle {
    [CmdletBinding()]
    param()
    
    Write-Host "Caps Lock <-> Escape Key Remapper" -ForegroundColor Yellow
    Write-Host ("=" * 34)
    
    $config = [KeyboardConfig]::new()
    $targetMap = $config.GetScancodeMap()
    $currentMap = Get-CurrentScancodeMap -Config $config
    $state = Get-MappingState -Current $currentMap -Target $targetMap
    
    Show-Status -State $state
    
    $action = switch ($state) {
        ([MappingState]::Mapped) { @{ Verb = "Revert"; Details = "Caps Lock from Escape to normal behavior" } }
        default { @{ Verb = "Remap"; Details = "Caps Lock to function as Escape" } }
    }
    
    if (Confirm-Action -Verb $action.Verb -Details $action.Details) {
        Invoke-RegistryChange -Config $config -CurrentState $state -ActionVerb $action.Verb
    }
    else {
        Write-Host "No changes made."
    }
    
    Write-Host ("=" * 34)
}

Start-CapsLockEscapeToggle