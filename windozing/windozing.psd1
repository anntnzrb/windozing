# Module manifest for module 'windozing'

@{

# Script module or binary module file associated with this manifest.
RootModule = 'windozing.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'a8f59b29-5e4f-4d3c-9a7f-8b5c6d2e3f1a'

# Author of this module
Author = 'windozing contributors'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) windozing contributors. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A PowerShell module for applying Windows system optimizations and tweaks with safety features including backup/restore, validation, and configuration management.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
    'src\core\Logger.ps1',
    'src\core\Config.ps1',
    'src\core\Backup.ps1',
    'src\core\Validation.ps1',
    'src\utilities\Registry.ps1',
    'src\utilities\Process.ps1',
    'src\utilities\System.ps1',
    'src\utilities\Network.ps1'
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    # Logger functions
    'Initialize-Logger',
    'Write-Log',
    'Write-DebugLog',
    'Write-InfoLog',
    'Write-WarnLog',
    'Write-ErrorLog',
    'Write-SuccessLog',
    'Get-LogPath',
    'Set-LogLevel',
    
    # Config functions
    'Initialize-Config',
    'Get-Config',
    'Set-Config',
    'Save-Config',
    'New-TweakConfig',
    'Get-TweaksByCategory',
    'Test-WindowsVersionCompatibility',
    'Get-DefaultValue',
    
    # Backup functions
    'Initialize-Backup',
    'New-RegistryBackup',
    'Get-RegistryBackup',
    'Restore-RegistryBackup',
    'Remove-RegistryBackup',
    'Export-RegistryBackup',
    'Clear-OldBackups',
    
    # Validation functions
    'Test-IsAdministrator',
    'Test-WindowsVersion',
    'Test-RegistryPath',
    'Test-RegistryValue',
    'Test-SafeRegistryPath',
    'Confirm-UserAction',
    'Test-ProcessRunning',
    'Test-ServiceRunning',
    'Test-DiskSpace',
    'Test-SystemReady',
    'Test-RegistryValueType',
    'Get-SafeValue',
    
    # Main module functions
    'Initialize-Windozing',
    'Invoke-Tweak',
    'Get-AvailableTweaks',
    'Show-Menu',
    
    # Registry utilities
    'Edit-RegistryEntry',
    'Get-RegistryValue',
    'Test-RegistryKeyExists',
    'Remove-RegistryValue',
    
    # Process utilities
    'Restart-Process',
    'Test-ProcessElevated',
    'Stop-ProcessSafely',
    'Wait-ProcessStart',
    'Get-ProcessInfo',
    
    # System utilities
    'Get-WindowsVersion',
    'Test-WindowsBuild',
    'Get-SystemUptime',
    'Get-SystemInfo',
    'Test-Feature',
    'Test-Service',
    'Get-DiskUsage',
    'Invoke-SystemCommand',
    
    # Network utilities
    'Get-NetworkInterfaces',
    'Get-NetworkInterfaceProperty',
    'Set-NetworkInterfaceProperty',
    'Get-NetworkInterfaceTweakPaths',
    'Apply-NetworkInterfaceTweaks',
    'Test-NetworkConnectivity',
    'Get-NetworkAdapterInfo'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Windows', 'Optimization', 'Tweaks', 'Registry', 'Performance', 'System')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/anntnzrb/windozing/blob/main/COPYING'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/anntnzrb/windozing'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Initial release with core infrastructure for safe Windows system tweaking.'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}