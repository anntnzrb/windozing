# mouse.ps1 --- Mouse tweaks

# Code:

. ../utilities/util.ps1

# set mouse speed to 6th slider (default)
Edit-RegistryEntry "HKCU:\Control Panel\Mouse" "MouseSensitivity" -Dec 10

# disable acceleration
Edit-RegistryEntry "HKCU:\Control Panel\Mouse" "MouseSpeed" -Dec 0
