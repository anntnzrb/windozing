. ./util.ps1

# set mouse speed to 6 (default)
Edit-RegistryEntry "HKCU:\Control Panel\Mouse" "MouseSensitivity" 10

# disable acceleration
Edit-RegistryEntry "HKCU:\Control Panel\Mouse" "MouseSpeed" 0

Write-Host "Mouse tweaks applied."