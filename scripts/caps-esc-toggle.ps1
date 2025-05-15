#Requires -RunAsAdministrator

# Script to toggle Caps Lock to/from Escape key functionality

# --- Configuration ---
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
$ValueName    = "Scancode Map"

# Scancode Map bytes for: Caps Lock (003A) -> Escape (0001)
$MapCapsLockToEscapeBytes = [byte[]](
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00,
    0x01, 0x00, # Escape
    0x3A, 0x00, # Caps Lock
    0x00, 0x00, 0x00, 0x00
)

# --- Helper Function: Compare Byte Arrays ---
function Test-ByteArraysEqual {
    param(
        [AllowNull()][byte[]]$Array1,
        [AllowNull()][byte[]]$Array2
    )
    if (($null -eq $Array1) -ne ($null -eq $Array2)) { return $false }
    if ($null -eq $Array1) { return $true }
    if ($Array1.Length -ne $Array2.Length) { return $false }
    for ($i = 0; $i -lt $Array1.Length; $i++) {
        if ($Array1[$i] -ne $Array2[$i]) { return $false }
    }
    return $true
}

# --- Main Script Logic ---
Write-Host "Caps Lock <-> Escape Key Remapper" -ForegroundColor Yellow
Write-Host "----------------------------------"

# Initialize $currentScancodeMap to $null
$currentScancodeMap = $null
try {
    # Attempt to get the Scancode Map value
    $currentScancodeMap = Get-ItemPropertyValue -Path $RegistryPath -Name $ValueName -ErrorAction Stop # ErrorAction Stop to ensure catch block is hit
}
catch [System.Management.Automation.PSArgumentException] {
    # This specific exception occurs when the property does not exist.
    # We expect this if the Scancode Map hasn't been set, so we do nothing here.
    # $currentScancodeMap remains $null, which is the desired state.
}
catch {
    # Catch any other unexpected errors during Get-ItemPropertyValue
    Write-Warning "An unexpected error occurred while trying to read the registry: $($_.Exception.Message)"
}

$isCurrentlyMappedToEscape = Test-ByteArraysEqual -Array1 $currentScancodeMap -Array2 $MapCapsLockToEscapeBytes

# Determine current status and define the action to be taken
if ($isCurrentlyMappedToEscape) {
    Write-Host "Current Status: Caps Lock is remapped to ESCAPE."
    $actionVerb = "Revert"
    $actionDetails = "Caps Lock from ESCAPE to NORMAL behavior"
    $registryOperation = { Remove-ItemProperty -Path $RegistryPath -Name $ValueName -Force -ErrorAction Stop }
    $successStateMessage = "Caps Lock will function as NORMAL after restart."
} else {
    if ($null -ne $currentScancodeMap) {
        Write-Host "Current Status: Caps Lock has an UNKNOWN custom 'Scancode Map'."
        Write-Warning "The existing 'Scancode Map' is not the specific CapsLock->Escape mapping this script manages."
        Write-Warning "Proceeding will OVERWRITE this existing custom mapping."
    } else {
        Write-Host "Current Status: Caps Lock is behaving NORMALLY (no 'Scancode Map' registry value found)."
    }
    $actionVerb = "Remap"
    $actionDetails = "Caps Lock to function as ESCAPE"
    $registryOperation = { Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $MapCapsLockToEscapeBytes -Type Binary -Force -ErrorAction Stop }
    $successStateMessage = "Caps Lock will function as ESCAPE after restart."
}

$choice = Read-Host -Prompt "Do you want to $actionVerb $actionDetails? (y/n)"

if ($choice -eq 'y') {
    try {
        & $registryOperation
        Write-Host "[SUCCESS] Registry updated. $successStateMessage" -ForegroundColor Green
        Write-Host "A system RESTART is required for changes to take effect." -ForegroundColor Magenta
    } catch {
        Write-Error "[FAILURE] Could not $actionVerb registry settings: $($_.Exception.Message)"
    }
} else {
    Write-Host "No changes made."
}

Write-Host "----------------------------------"