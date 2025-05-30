# regedit.ps1 --- Regedit tweaks

# Resources
# - https://www.speedguide.net/articles/gaming-tweaks-5812

# Code:

. ../utilities/util.ps1

# system responsiveness
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" -Dec 0

# MMCSS tweaks
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Affinity" -Dec 0
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Background Only" -String "False"
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Clock Rate" -Dec 2710
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" -Dec 8
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" -Dec 6
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" -String "High"
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" -String "High"

# LargeSystemCache
Edit-RegistryEntry "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" -Dec 0

# Process priority control
Edit-RegistryEntry "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" -Dec 40
