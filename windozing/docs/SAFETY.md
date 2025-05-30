# Windozing Safety Guidelines

This document outlines important safety considerations and best practices when using windozing.

## Before You Begin

### Prerequisites

1. **Administrator Access**: Most tweaks require administrator privileges
2. **Windows Version**: Ensure you're running Windows 10 or 11
3. **System Backup**: Create a system restore point or full backup
4. **Stable System**: Don't apply tweaks to an already unstable system

### Recommended Preparation

```powershell
# Create a system restore point
Checkpoint-Computer -Description "Before windozing tweaks"

# Or use windozing's backup feature
Initialize-Windozing
$backup = New-RegistryBackup -Name "pre-tweaks" -Description "Before applying any tweaks"
```

## Safety Features

### 1. Automatic Backup System

Windozing includes an automatic backup system that:
- Creates timestamped backups before changes
- Stores registry values in an easily restorable format
- Maintains backup history with metadata
- Allows selective restoration

### 2. Validation System

Before applying tweaks, windozing:
- Checks Windows version compatibility
- Verifies administrator privileges
- Validates registry paths exist
- Confirms safe registry locations
- Prompts for high-risk operations

### 3. Dry Run Mode

Test changes without applying them:
```powershell
Invoke-Tweak -Category "performance" -DryRun
```

### 4. Protected Registry Paths

Windozing blocks modifications to critical system paths:
- Security provider configurations
- Windows Defender settings
- System audit policies
- Core Windows services

## Risk Assessment

### Low Risk Tweaks
- **Mouse settings**: User preferences, easily reversible
- **Game Mode settings**: User-specific, minimal system impact
- **Game DVR**: Entertainment features, no core system impact

### Medium Risk Tweaks
- **Performance optimizations**: May affect system behavior
- **Network tweaks**: Could impact network stability
- **MMCSS settings**: May affect multimedia performance

### High Risk Operations
- **Power plan changes**: Can affect system stability
- **Core system services**: Not modified by default
- **Security settings**: Blocked by safety checks

## Best Practices

### 1. Incremental Application
Apply one category at a time:
```powershell
# Good approach
Invoke-Tweak -Category "mouse" -BackupFirst
# Test system...
Invoke-Tweak -Category "performance" -BackupFirst
# Test system...
```

### 2. Testing After Each Change
After applying tweaks:
1. Restart the system
2. Test critical applications
3. Monitor system stability for 24-48 hours
4. Check Event Viewer for errors

### 3. Backup Management
```powershell
# List all backups
Get-RegistryBackup

# Keep only recent backups
Clear-OldBackups -DaysToKeep 7 -MaxBackups 10

# Export important backup
Export-RegistryBackup -Id "backup-id" -Path "C:\SafeBackups\windozing-backup.zip"
```

## Recovery Procedures

### If Something Goes Wrong

#### 1. Using Windozing Restore
```powershell
# List available backups
Get-RegistryBackup

# Restore specific backup
Restore-RegistryBackup -Id "backup-id"

# Restore with force flag if needed
Restore-RegistryBackup -Id "backup-id" -Force
```

#### 2. Safe Mode Recovery
1. Boot into Safe Mode (hold Shift while clicking Restart)
2. Open PowerShell as Administrator
3. Import windozing and restore:
   ```powershell
   Import-Module windozing
   Initialize-Windozing
   Get-RegistryBackup
   Restore-RegistryBackup -Id "latest-backup-id"
   ```

#### 3. Manual Registry Restoration
Backup files are stored in `.reg` format:
1. Navigate to `%USERPROFILE%\Documents\WindowsPowerShell\Modules\windozing\backups`
2. Find your backup folder by ID
3. Double-click `.reg` files to restore

#### 4. System Restore
If windozing restore fails:
1. Open System Restore: `rstrui.exe`
2. Choose a restore point before tweaks
3. Follow the wizard

## Do's and Don'ts

### DO:
- ✅ Run as Administrator
- ✅ Create backups before changes
- ✅ Test one category at a time
- ✅ Read tweak descriptions
- ✅ Monitor system after changes
- ✅ Keep backup history

### DON'T:
- ❌ Apply all tweaks at once on first use
- ❌ Ignore warning messages
- ❌ Modify the JSON configs without understanding
- ❌ Use -Force flag unless necessary
- ❌ Apply tweaks to unstable systems
- ❌ Delete backups immediately

## Monitoring System Health

After applying tweaks, monitor:

1. **Performance**
   - Task Manager CPU/Memory usage
   - Resource Monitor for bottlenecks
   - Game/Application performance

2. **Stability**
   - Event Viewer for errors
   - Blue Screen View if crashes occur
   - System uptime

3. **Functionality**
   - Network connectivity
   - USB devices
   - Audio/Video playback

## Reporting Issues

If you encounter problems:

1. Document the issue:
   - Which tweaks were applied
   - When the issue started
   - Error messages
   - System specifications

2. Attempt restoration:
   - Use windozing restore
   - Try System Restore
   - Boot into Safe Mode

3. Report to project:
   - GitHub Issues page
   - Include backup IDs
   - Attach relevant logs

## Final Recommendations

1. **Start Small**: Begin with low-risk tweaks
2. **Document Changes**: Keep notes on what you've applied
3. **Regular Backups**: Beyond windozing's automatic backups
4. **Stay Informed**: Read documentation before applying
5. **Be Patient**: Allow time between changes to assess impact

Remember: All windozing tweaks are reversible, but prevention is better than recovery. Take your time, understand what each tweak does, and always maintain good backups.