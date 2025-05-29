# game.ps1 --- Game-related tweaks

# Code:

. ../utilities/util.ps1

function Disable-GameMode {
    Write-Host "Disabling Windows Game Mode..."
    
    # Disable Game Mode
    Edit-RegistryEntry "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" -Dec 0
    Edit-RegistryEntry "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" -Dec 0
    
    # Disable Game DVR
    Edit-RegistryEntry "HKCU:\System\GameConfigStore" "GameDVR_Enabled" -Dec 0
    
    # Create the GameDVR policy key if it doesn't exist
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
    }
    Edit-RegistryEntry "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" -Dec 0
    
    Write-Host "> Windows Game Mode has been disabled."
}

function Disable-HardwareAcceleratedGPUScheduling {
    Write-Host "Disabling Hardware Accelerated GPU Scheduling..."
    
    # Create the registry key path if it doesn't exist
    if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers")) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Force | Out-Null
    }
    
    # Set HwSchMode to 0 to disable hardware accelerated GPU scheduling
    Edit-RegistryEntry "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" -Dec 0
    
    Write-Host "> Hardware Accelerated GPU Scheduling has been disabled."
    Write-Host "> Note: A system restart is required for this change to take effect."
}

# Execute the functions when the script is run directly
Disable-GameMode
Disable-HardwareAcceleratedGPUScheduling
