# Windozing Project Restructure Plan

## Overview
This document outlines the proposed restructuring of the windozing project to improve maintainability, safety, and user experience.

## Current Issues
- Flat file structure with all scripts in root directory
- No configuration management system
- Limited error handling and validation
- No backup/rollback capabilities
- Hardcoded values throughout scripts
- No testing framework
- Limited documentation

## Proposed Directory Structure

```
windozing/
├── README.md
├── COPYING
├── Install.ps1              # One-line installer
├── windozing.psd1          # PowerShell module manifest
├── windozing.psm1          # Main module file
│
├── src/
│   ├── core/
│   │   ├── Config.ps1      # Configuration management
│   │   ├── Logger.ps1      # Logging functionality
│   │   ├── Backup.ps1      # Backup/restore registry
│   │   └── Validation.ps1  # Input validation
│   │
│   ├── tweaks/
│   │   ├── Performance.ps1
│   │   ├── Network.ps1
│   │   ├── Mouse.ps1
│   │   ├── Power.ps1
│   │   ├── Game.ps1
│   │   └── Privacy.ps1     # New: privacy tweaks
│   │
│   │
│   └── utilities/
│       ├── Registry.ps1     # Registry helpers
│       ├── Process.ps1      # Process management
│       └── System.ps1       # System utilities
│
├── config/
│   ├── tweaks.json         # Tweak definitions
│   └── defaults.json       # Default settings
│
├── scripts/
│   ├── caps-esc-toggle.ps1
│   └── run-as-admin.bat
│
├── tests/
│   ├── core/
│   ├── tweaks/
│   └── Pester.ps1         # Test runner
│
├── docs/
│   ├── TWEAKS.md          # Detailed tweak documentation
│   ├── SAFETY.md          # Safety guidelines
│   └── API.md             # Module API reference
│
└── logs/                   # Generated at runtime
```

## Key Improvements

### 1. PowerShell Module Structure
Convert the project into a proper PowerShell module with:
- Module manifest (`.psd1`) for metadata and versioning
- Module script (`.psm1`) for main functionality
- Exported cmdlets with standard PowerShell naming conventions

**Benefits:**
- Professional PowerShell module structure
- Easy installation via `Install-Module`
- Version management
- Dependency tracking

### 2. Configuration Management

#### JSON-based Configuration
```json
// config/tweaks.json
{
  "performance": {
    "name": "Performance Optimizations",
    "description": "System responsiveness and MMCSS tweaks",
    "risk": "low",
    "requires_restart": true,
    "windows_versions": ["10", "11"],
    "tweaks": [
      {
        "id": "system-responsiveness",
        "path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
        "key": "SystemResponsiveness",
        "value": 0,
        "type": "DWORD",
        "description": "Reduces system reserved CPU for multimedia"
      }
    ]
  }
}
```

**Benefits:**
- Centralized configuration
- Easy to update without code changes
- Machine-readable format
- Version compatibility checking

### 3. Safety Features

#### Backup System
- Automatic registry backup before changes
- Timestamped backup files
- Rollback functionality
- Export/import capability

#### Validation System
- Windows version compatibility checks
- Registry key existence verification
- Value type validation
- User confirmation for high-risk changes

#### Dry Run Mode
- Preview all changes before applying
- Generate change reports
- Risk assessment display

### 4. Enhanced Command Line Interface

#### New Commands
```powershell
# Apply tweaks
windozing apply --category performance --dry-run
windozing apply --all --exclude game

# Backup management
windozing backup create --name "before-gaming-tweaks"
windozing backup list
windozing backup restore --name "before-gaming-tweaks"

# Status and reporting
windozing status
windozing report --format html


# Configuration
windozing config set log-level verbose
windozing config export --file my-config.json
```

### 5. Logging and Monitoring

#### Structured Logging
```powershell
# Example log entry
2024-01-20 10:30:45 [INFO] Applying tweak: system-responsiveness
2024-01-20 10:30:45 [DEBUG] Registry path: HKLM:\SOFTWARE\Microsoft\...
2024-01-20 10:30:45 [INFO] Previous value: 20, New value: 0
2024-01-20 10:30:46 [SUCCESS] Tweak applied successfully
```

**Features:**
- Multiple log levels (DEBUG, INFO, WARN, ERROR)
- Timestamped entries
- Structured format for parsing
- Rotation and archival

### 6. Testing Framework

#### Pester Tests
- Unit tests for each module function
- Integration tests for tweak application
- Mock registry for safe testing
- CI/CD integration ready

### 8. Documentation

#### Comprehensive Documentation
- **TWEAKS.md**: Detailed explanation of each tweak
- **SAFETY.md**: Best practices and warnings
- **API.md**: Module cmdlet reference
- **README.md**: Quick start and overview

## Implementation Phases

### Phase 1: Core Infrastructure
1. Create directory structure
2. Implement core modules (Config, Logger, Backup)
3. Convert util.ps1 to modular utilities
4. Create module manifest and main module file

### Phase 2: Configuration System
1. Create JSON configuration files
2. Implement configuration parser
3. Add validation system
4. Create dry-run functionality

### Phase 3: Migration
1. Refactor existing tweak scripts
2. Update to use new configuration system
3. Add safety checks and validation
4. Implement backup functionality

### Phase 4: Enhanced Features
1. Implement new CLI commands
2. Add reporting functionality
3. Add privacy tweaks category

### Phase 5: Testing and Documentation
1. Write Pester tests
2. Create comprehensive documentation
3. Add example configurations
4. Create migration guide

## Benefits Summary

1. **Maintainability**: Modular structure makes updates easier
2. **Safety**: Backup and validation prevent system damage
3. **Flexibility**: JSON configuration allows easy customization
4. **Professional**: Follows PowerShell best practices
5. **User-Friendly**: Better CLI with helpful commands
6. **Extensible**: Easy to add new tweaks and features
7. **Testable**: Automated testing ensures reliability
8. **Documented**: Users understand what each tweak does

## Next Steps

1. Review and approve this plan
2. Create feature branches for each phase
3. Begin Phase 1 implementation
4. Set up GitHub Actions for testing
5. Plan release strategy (semantic versioning)