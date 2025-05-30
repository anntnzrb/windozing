# Backup.ps1 - Backup and restore functionality for windozing

$script:BackupPath = Join-Path $PSScriptRoot "..\..\backups"
$script:BackupHistory = @()

function Initialize-Backup {
    [CmdletBinding()]
    param(
        [string]$BackupDirectory = $null
    )
    
    if ($BackupDirectory) {
        $script:BackupPath = $BackupDirectory
    }
    
    # Ensure backup directory exists
    if (-not (Test-Path $script:BackupPath)) {
        New-Item -ItemType Directory -Path $script:BackupPath -Force | Out-Null
    }
    
    # Load backup history
    $historyFile = Join-Path $script:BackupPath "backup-history.json"
    if (Test-Path $historyFile) {
        try {
            $script:BackupHistory = Get-Content $historyFile -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load backup history: $_"
            $script:BackupHistory = @()
        }
    }
    
    return $true
}

function New-RegistryBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$RegistryPaths,
        
        [string]$Name = $null,
        
        [string]$Description = "",
        
        [hashtable]$Metadata = @{}
    )
    
    # Generate backup name if not provided
    if (-not $Name) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $Name = "backup-$timestamp"
    }
    
    $backupId = [Guid]::NewGuid().ToString()
    $backupDir = Join-Path $script:BackupPath $backupId
    
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    $backupInfo = @{
        id = $backupId
        name = $Name
        description = $Description
        timestamp = (Get-Date).ToString("o")
        registry_paths = $RegistryPaths
        files = @()
        metadata = $Metadata
    }
    
    foreach ($regPath in $RegistryPaths) {
        try {
            $fileName = $regPath -replace '[:\\]', '_'
            $fileName = "$fileName.reg"
            $filePath = Join-Path $backupDir $fileName
            
            # Export registry key
            $exportArgs = @(
                'export',
                $regPath,
                $filePath,
                '/y'
            )
            
            $result = Start-Process -FilePath "reg.exe" -ArgumentList $exportArgs -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                $backupInfo.files += @{
                    path = $regPath
                    file = $fileName
                    size = (Get-Item $filePath).Length
                }
            }
            else {
                Write-Error "Failed to backup registry path: $regPath"
            }
        }
        catch {
            Write-Error "Error backing up $regPath : $_"
        }
    }
    
    $metadataPath = Join-Path $backupDir "backup-info.json"
    $backupInfo | ConvertTo-Json -Depth 5 | Set-Content $metadataPath -Encoding UTF8
    
    $script:BackupHistory += $backupInfo
    Save-BackupHistory
    
    return $backupInfo
}

function Get-RegistryBackup {
    [CmdletBinding()]
    param(
        [string]$Id = $null,
        
        [string]$Name = $null,
        
        [datetime]$After = $null,
        
        [datetime]$Before = $null
    )
    
    $backups = $script:BackupHistory
    
    if ($Id) {
        $backups = $backups | Where-Object { $_.id -eq $Id }
    }
    
    if ($Name) {
        $backups = $backups | Where-Object { $_.name -like "*$Name*" }
    }
    
    if ($After) {
        $backups = $backups | Where-Object { 
            [datetime]$_.timestamp -gt $After 
        }
    }
    
    if ($Before) {
        $backups = $backups | Where-Object { 
            [datetime]$_.timestamp -lt $Before 
        }
    }
    
    return $backups | Sort-Object timestamp -Descending
}

function Restore-RegistryBackup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Id,
        
        [string[]]$RegistryPaths = $null,
        
        [switch]$Force
    )
    
    $backup = Get-RegistryBackup -Id $Id
    
    if (-not $backup) {
        Write-Error "Backup with ID '$Id' not found"
        return $false
    }
    
    $backupDir = Join-Path $script:BackupPath $Id
    
    if (-not (Test-Path $backupDir)) {
        Write-Error "Backup directory not found: $backupDir"
        return $false
    }
    
    # Determine which files to restore
    $filesToRestore = $backup.files
    if ($RegistryPaths) {
        $filesToRestore = $backup.files | Where-Object { 
            $RegistryPaths -contains $_.path 
        }
    }
    
    $restored = 0
    $failed = 0
    
    foreach ($file in $filesToRestore) {
        $filePath = Join-Path $backupDir $file.file
        
        if (-not (Test-Path $filePath)) {
            Write-Error "Backup file not found: $filePath"
            $failed++
            continue
        }
        
        if ($PSCmdlet.ShouldProcess($file.path, "Restore registry backup")) {
            try {
                # Import registry file
                $importArgs = @(
                    'import',
                    $filePath
                )
                
                if ($Force) {
                    $importArgs += '/f'
                }
                
                $result = Start-Process -FilePath "reg.exe" -ArgumentList $importArgs -Wait -PassThru -NoNewWindow
                
                if ($result.ExitCode -eq 0) {
                    Write-Verbose "Restored: $($file.path)"
                    $restored++
                }
                else {
                    Write-Error "Failed to restore: $($file.path)"
                    $failed++
                }
            }
            catch {
                Write-Error "Error restoring $($file.path): $_"
                $failed++
            }
        }
    }
    
    Write-Information "Restore complete. Restored: $restored, Failed: $failed"
    
    return $failed -eq 0
}

function Remove-RegistryBackup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )
    
    $backup = Get-RegistryBackup -Id $Id
    
    if (-not $backup) {
        Write-Error "Backup with ID '$Id' not found"
        return $false
    }
    
    $backupDir = Join-Path $script:BackupPath $Id
    
    if ($PSCmdlet.ShouldProcess($backup.name, "Remove backup")) {
        try {
            # Remove backup directory
            if (Test-Path $backupDir) {
                Remove-Item -Path $backupDir -Recurse -Force
            }
            
            # Remove from history
            $script:BackupHistory = $script:BackupHistory | Where-Object { $_.id -ne $Id }
            Save-BackupHistory
            
            return $true
        }
        catch {
            Write-Error "Failed to remove backup: $_"
            return $false
        }
    }
    
    return $false
}

function Export-RegistryBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$IncludeMetadata
    )
    
    $backup = Get-RegistryBackup -Id $Id
    
    if (-not $backup) {
        Write-Error "Backup with ID '$Id' not found"
        return $false
    }
    
    $backupDir = Join-Path $script:BackupPath $Id
    
    try {
        # Create zip file
        $zipPath = $Path
        if (-not $zipPath.EndsWith('.zip')) {
            $zipPath += '.zip'
        }
        
        # Compress backup directory
        Compress-Archive -Path "$backupDir\*" -DestinationPath $zipPath -Force
        
        return $true
    }
    catch {
        Write-Error "Failed to export backup: $_"
        return $false
    }
}

function Save-BackupHistory {
    [CmdletBinding()]
    param()
    
    $historyFile = Join-Path $script:BackupPath "backup-history.json"
    
    try {
        $script:BackupHistory | ConvertTo-Json -Depth 5 | 
            Set-Content $historyFile -Encoding UTF8
        return $true
    }
    catch {
        Write-Error "Failed to save backup history: $_"
        return $false
    }
}

function Clear-OldBackups {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [int]$DaysToKeep = 30,
        
        [int]$MaxBackups = 50
    )
    
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    
    # Get old backups
    $oldBackups = Get-RegistryBackup -Before $cutoffDate
    
    # Also get excess backups if we have too many
    $allBackups = Get-RegistryBackup
    if ($allBackups.Count -gt $MaxBackups) {
        $excessCount = $allBackups.Count - $MaxBackups
        $oldBackups += $allBackups | Select-Object -Last $excessCount
    }
    
    # Remove duplicates
    $backupsToRemove = $oldBackups | Select-Object -Property id -Unique
    
    $removed = 0
    foreach ($backup in $backupsToRemove) {
        if (Remove-RegistryBackup -Id $backup.id) {
            $removed++
        }
    }
    
    Write-Information "Removed $removed old backups"
    return $removed
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Backup',
    'New-RegistryBackup',
    'Get-RegistryBackup',
    'Restore-RegistryBackup',
    'Remove-RegistryBackup',
    'Export-RegistryBackup',
    'Clear-OldBackups'
)