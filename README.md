# windozing

A PowerShell module for applying Windows system optimizations and tweaks with comprehensive safety features including backup/restore, validation, and configuration management.

**NOTE:** This repository is experimental. Use at your own risk and always create backups before applying system tweaks.

## Project Structure

```
windozing/
├── Install.ps1             # One-line installer script
├── README.md               # This file
├── COPYING                 # License file
├── scripts/               # Standalone scripts
│   └── caps-esc-toggle.ps1
└── windozing/             # PowerShell module directory
    ├── windozing.psd1     # Module manifest
    ├── windozing.psm1     # Main module file
    ├── src/               # Module source code
    │   ├── core/          # Core infrastructure modules
    │   │   ├── Config.ps1     # Configuration management
    │   │   ├── Logger.ps1     # Logging functionality
    │   │   ├── Backup.ps1     # Backup/restore system
    │   │   └── Validation.ps1 # Input validation
    │   └── utilities/     # System utility modules
    │       ├── Registry.ps1   # Registry operations
    │       ├── Network.ps1    # Network interface management
    │       ├── Power.ps1      # Power management
    │       ├── Process.ps1    # Process management
    │       └── System.ps1     # System information
    ├── config/            # Configuration files
    │   ├── tweaks.json    # Tweak definitions
    │   └── defaults.json  # Default settings
    └── docs/              # Documentation
        ├── TWEAKS.md      # Detailed tweak documentation
        └── SAFETY.md      # Safety guidelines
```

## Installation

### Quick Install (Recommended)
```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yourusername/windozing/main/Install.ps1'))
```

### Manual Installation
1. Download or clone this repository
2. Copy the `windozing/windozing` folder to your PowerShell modules directory:
   - `$env:USERPROFILE\Documents\WindowsPowerShell\Modules\windozing`
3. Import the module: `Import-Module windozing`

## Usage

### Interactive Menu
```powershell
Import-Module windozing
Show-Menu
```

### Command Line Usage
```powershell
# Apply specific tweak categories
Invoke-Tweak -Category performance -BackupFirst

# Apply with dry run (preview changes)
Invoke-Tweak -Category network -DryRun

# List available tweaks
Get-AvailableTweaks

# Backup management
New-RegistryBackup -Name "before-tweaks"
Get-RegistryBackup
Restore-RegistryBackup -Id "backup-id"
```
