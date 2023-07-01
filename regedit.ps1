# Resources
# - https://www.speedguide.net/articles/gaming-tweaks-5812

. ./util.ps1

# system responsiveness
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" -Dec 0

# network throttling index
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" -Hex "ffffffff"

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

# get all subkeys under the interfaces path
$interfaceKeys = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"

# loop through each interface
foreach ($key in $interfaceKeys) {
    $interfacePath = $key.PSPath

    Edit-RegistryEntry $interfacePath "TcpAckFrequency" -Dec 1
    Edit-RegistryEntry $interfacePath "TcpDelAckTicks" -Dec 0
    Edit-RegistryEntry $interfacePath "TCPNoDelay" -Dec 1
}

Write-Host "=> Network tweaks applied."