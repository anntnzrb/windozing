# network.ps1 --- Network tweaks

# Resources
# - https://www.speedguide.net/articles/gaming-tweaks-5812

# Code:

. ./util.ps1

# network throttling index
Edit-RegistryEntry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" -Hex "ffffffff"

# get all subkeys under the interfaces path & loop through them
$interfaceKeys = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
foreach ($key in $interfaceKeys) {
    $interfacePath = $key.PSPath

    Edit-RegistryEntry $interfacePath "TcpAckFrequency" -Dec 1
    Edit-RegistryEntry $interfacePath "TcpDelAckTicks" -Dec 0
    Edit-RegistryEntry $interfacePath "TCPNoDelay" -Dec 1
}

Write-Host "=> Network tweaks applied."