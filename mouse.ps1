function Edit-Regedit {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    Set-ItemProperty -Path $Path -Name $Name -Value $Value
}

# set mouse speed to 6 (default)
Edit-Regedit "HKCU:\Control Panel\Mouse" "MouseSensitivity" 10

# disable acceleration
Edit-Regedit "HKCU:\Control Panel\Mouse" "MouseSpeed" 0

Write-Host "Mouse tweaks applied."

pause