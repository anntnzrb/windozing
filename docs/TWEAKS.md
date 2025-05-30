# Windozing Tweaks Documentation

This document provides detailed information about each tweak available in windozing.

## Table of Contents

- [Performance Tweaks](#performance-tweaks)
- [Network Tweaks](#network-tweaks)
- [Mouse Tweaks](#mouse-tweaks)
- [Gaming Tweaks](#gaming-tweaks)
- [Power Tweaks](#power-tweaks)

## Performance Tweaks

### System Responsiveness
- **Registry Path**: `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`
- **Key**: `SystemResponsiveness`
- **Value**: 0
- **Description**: Sets system responsiveness to 0, prioritizing foreground applications over background tasks. This can improve performance in games and active applications.

### MMCSS (Multimedia Class Scheduler Service) Tweaks

#### CPU Affinity
- **Key**: `Affinity`
- **Value**: 0
- **Description**: Allows games to run on all CPU cores instead of being restricted to specific cores.

#### Background Processing
- **Key**: `Background Only`
- **Value**: "False"
- **Description**: Ensures games don't run as background-only processes, maintaining their priority.

#### Clock Rate
- **Key**: `Clock Rate`
- **Value**: 2710 (10kHz)
- **Description**: Sets the clock resolution for game tasks to 10kHz for more precise timing.

#### GPU Priority
- **Key**: `GPU Priority`
- **Value**: 8
- **Description**: Sets high GPU priority for games, ensuring better GPU resource allocation.

#### CPU Priority
- **Key**: `Priority`
- **Value**: 6
- **Description**: Sets CPU priority level for game tasks to "High".

#### Scheduling Category
- **Key**: `Scheduling Category`
- **Value**: "High"
- **Description**: Places games in the high scheduling priority category.

#### File I/O Priority
- **Key**: `SFIO Priority`
- **Value**: "High"
- **Description**: Sets high scheduled file I/O priority for games, improving loading times.

### Memory Management

#### Large System Cache
- **Registry Path**: `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`
- **Key**: `LargeSystemCache`
- **Value**: 0
- **Description**: Optimizes memory for programs rather than file system cache, beneficial for gaming and applications.

### Process Priority

#### Win32 Priority Separation
- **Registry Path**: `HKLM:\SYSTEM\ControlSet001\Control\PriorityControl`
- **Key**: `Win32PrioritySeparation`
- **Value**: 40 (hex: 0x28)
- **Description**: Optimizes CPU scheduling for foreground applications with variable quantum length.

## Network Tweaks

### Network Throttling
- **Registry Path**: `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`
- **Key**: `NetworkThrottlingIndex`
- **Value**: 0xffffffff (4294967295)
- **Description**: Disables network throttling for multimedia applications, potentially improving network performance in games and streaming.

### TCP Optimizations (Per Interface)
**Note**: These tweaks are applied to each network interface individually.

#### TCP Acknowledgment Frequency
- **Key**: `TcpAckFrequency`
- **Value**: 1
- **Description**: Sends immediate TCP acknowledgments instead of delaying, reducing latency at the cost of slightly more overhead.

#### TCP Delayed Acknowledgment Ticks
- **Key**: `TcpDelAckTicks`
- **Value**: 0
- **Description**: Disables delayed acknowledgments to reduce latency.

#### TCP No Delay (Nagle's Algorithm)
- **Key**: `TCPNoDelay`
- **Value**: 1
- **Description**: Disables Nagle's algorithm, which can reduce latency for real-time applications.

## Mouse Tweaks

### Mouse Sensitivity
- **Registry Path**: `HKCU:\Control Panel\Mouse`
- **Key**: `MouseSensitivity`
- **Value**: 10
- **Description**: Sets mouse sensitivity to the 6th notch (default Windows position).

### Mouse Acceleration
- **Registry Path**: `HKCU:\Control Panel\Mouse`
- **Key**: `MouseSpeed`
- **Value**: 0
- **Description**: Disables mouse acceleration (enhanced pointer precision) for consistent 1:1 mouse movement.

## Gaming Tweaks

### Game Mode
- **Registry Path**: `HKCU:\Software\Microsoft\GameBar`
- **Keys**: 
  - `AutoGameModeEnabled` = 0
  - `AllowAutoGameMode` = 0
- **Description**: Disables Windows Game Mode automatic activation, which can sometimes cause performance issues.

### Game DVR
- **Registry Paths**:
  - `HKCU:\System\GameConfigStore` - `GameDVR_Enabled` = 0
  - `HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR` - `AllowGameDVR` = 0
- **Description**: Disables Game DVR recording feature system-wide, freeing up resources.

### Hardware-Accelerated GPU Scheduling
- **Registry Path**: `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`
- **Key**: `HwSchMode`
- **Value**: 0
- **Description**: Disables hardware-accelerated GPU scheduling. While this feature can reduce latency in some cases, it may cause instability or performance issues on some systems.

## Power Tweaks

### Ultimate Performance Power Plan
- **Command**: `powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61`
- **Description**: Enables the hidden "Ultimate Performance" power plan designed for high-end systems, eliminating micro-latencies.

### USB Selective Suspend
- **Commands**:
  ```powershell
  powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
  powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
  ```
- **Description**: Disables USB selective suspend to prevent USB devices from being powered down, which can cause input lag or disconnections.

## Important Notes

1. **Backup**: Always create a system restore point or registry backup before applying tweaks.
2. **Testing**: Test each tweak category individually to ensure system stability.
3. **Compatibility**: Some tweaks may not be compatible with all hardware configurations.
4. **Reversibility**: All registry tweaks can be reversed by restoring from backup or setting original values.
5. **Updates**: Windows updates may occasionally reset some of these tweaks.

## Risk Levels

- **Low Risk**: Mouse, Gaming tweaks - Generally safe for all systems
- **Medium Risk**: Performance, Network tweaks - May need adjustment based on hardware
- **High Risk**: None currently (removed from default configuration)

## Troubleshooting

If you experience issues after applying tweaks:

1. Use the backup restore feature: `Restore-RegistryBackup -Id <backup-id>`
2. Boot into Safe Mode and restore backups manually
3. Use System Restore to revert to a previous state
4. Reset specific tweaks by applying original values