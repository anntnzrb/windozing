# windozing.psm1 - Main module file for windozing PowerShell module

# Module initialization
$script:ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:IsInitialized = $false

function Initialize-Windozing {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path $script:ModulePath "config"),
        [string]$LogPath = (Join-Path $script:ModulePath "logs"),
        [string]$BackupPath = (Join-Path $script:ModulePath "backups"),
        [switch]$Silent
    )
    
    if ($script:IsInitialized -and -not $Force) {
        Write-Verbose "Windozing module already initialized"
        return $true
    }
    
    try {
        # Initialize logging first
        Initialize-Logger -LogPath (Join-Path $LogPath "windozing.log") -FileOutput $true
        
        if (-not $Silent) {
            Write-InfoLog "Initializing windozing module..." -Category "Core"
        }
        
        # Check administrator privileges
        if (-not (Test-IsAdministrator)) {
            Write-ErrorLog "Administrator privileges required. Please run as Administrator." -Category "Core"
            return $false
        }
        
        # Initialize configuration
        if (-not (Initialize-Config -ConfigDirectory $ConfigPath)) {
            Write-ErrorLog "Failed to initialize configuration system" -Category "Core"
            return $false
        }
        
        # Initialize backup system
        if (-not (Initialize-Backup -BackupDirectory $BackupPath)) {
            Write-ErrorLog "Failed to initialize backup system" -Category "Core"
            return $false
        }
        
        # Check Windows version
        $supportedVersions = @("10", "11")
        if (-not (Test-WindowsVersion -SupportedVersions $supportedVersions)) {
            Write-WarnLog "Current Windows version may not be fully supported" -Category "Core"
        }
        
        $script:IsInitialized = $true
        
        if (-not $Silent) {
            Write-SuccessLog "Windozing module initialized successfully" -Category "Core"
        }
        
        return $true
    }
    catch {
        Write-ErrorLog "Failed to initialize windozing: $_" -Category "Core"
        return $false
    }
}

function Get-AvailableTweaks {
    [CmdletBinding()]
    param(
        [string]$Category = $null,
        [ValidateSet("low", "medium", "high")]
        [string]$MaxRisk = "high",
        [switch]$IncludeMetadata
    )
    
    if (-not $script:IsInitialized) {
        if (-not (Initialize-Windozing -Silent)) {
            return @()
        }
    }
    
    $tweaks = Get-TweaksByCategory -Category $Category
    
    if (-not $tweaks) {
        return @()
    }
    
    # Filter by risk level
    $filteredTweaks = @{}
    $riskLevels = @{
        "low" = 1
        "medium" = 2
        "high" = 3
    }
    
    $maxRiskLevel = $riskLevels[$MaxRisk]
    
    foreach ($category in $tweaks.Keys) {
        $categoryTweaks = $tweaks[$category]
        if ($categoryTweaks.risk -and $riskLevels[$categoryTweaks.risk] -le $maxRiskLevel) {
            if ($IncludeMetadata) {
                $filteredTweaks[$category] = $categoryTweaks
            }
            else {
                $filteredTweaks[$category] = $categoryTweaks.name
            }
        }
    }
    
    return $filteredTweaks
}

function Invoke-Tweak {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Category,
        
        [string[]]$TweakIds = $null,
        
        [switch]$BackupFirst,
        
        [switch]$Force,
        
        [switch]$DryRun
    )
    
    if (-not $script:IsInitialized) {
        if (-not (Initialize-Windozing)) {
            return $false
        }
    }
    
    Write-InfoLog "Starting tweak category: $Category" -Category "Tweak"
    
    # Get tweaks for category
    $categoryConfig = Get-Config -ConfigName "tweaks" -Section $Category
    
    if (-not $categoryConfig) {
        Write-ErrorLog "Category '$Category' not found" -Category "Tweak"
        return $false
    }
    
    # Check Windows version compatibility
    if ($categoryConfig.windows_versions) {
        if (-not (Test-WindowsVersionCompatibility -SupportedVersions $categoryConfig.windows_versions)) {
            Write-ErrorLog "This tweak is not compatible with current Windows version" -Category "Tweak"
            return $false
        }
    }
    
    # Filter tweaks if specific IDs provided
    $tweaksToApply = $categoryConfig.tweaks
    if ($TweakIds) {
        $tweaksToApply = $tweaksToApply | Where-Object { $TweakIds -contains $_.id }
    }
    
    # Filter interface tweaks if specific IDs provided
    $interfaceTweaksToApply = @()
    if ($categoryConfig.interface_tweaks) {
        $interfaceTweaksToApply = $categoryConfig.interface_tweaks
        if ($TweakIds) {
            $interfaceTweaksToApply = $interfaceTweaksToApply | Where-Object { $TweakIds -contains $_.id }
        }
    }
    
    # Filter power commands if specific IDs provided
    $powerCommandsToApply = @()
    if ($categoryConfig.power_commands) {
        $powerCommandsToApply = $categoryConfig.power_commands
        if ($TweakIds) {
            $powerCommandsToApply = $powerCommandsToApply | Where-Object { $TweakIds -contains $_.id }
        }
    }
    
    if ($tweaksToApply.Count -eq 0 -and $interfaceTweaksToApply.Count -eq 0 -and $powerCommandsToApply.Count -eq 0) {
        Write-WarnLog "No tweaks to apply" -Category "Tweak"
        return $true
    }
    
    # Confirm with user if high risk
    if ($categoryConfig.risk -eq "high" -and -not $Force) {
        $message = "This category contains high-risk tweaks. Continue?"
        if (-not (Confirm-UserAction -Message $message -DefaultNo)) {
            Write-InfoLog "Operation cancelled by user" -Category "Tweak"
            return $false
        }
    }
    
    # Create backup if requested
    if ($BackupFirst) {
        Write-InfoLog "Creating backup before applying tweaks..." -Category "Backup"
        
        # Collect registry paths from regular tweaks
        $registryPaths = $tweaksToApply | ForEach-Object { $_.path } | Select-Object -Unique
        
        # Add network interface paths if interface tweaks are present
        if ($interfaceTweaksToApply.Count -gt 0) {
            # Import Network utilities
            $networkUtilPath = Join-Path $script:ModulePath "src\utilities\Network.ps1"
            if (Test-Path $networkUtilPath) {
                . $networkUtilPath
                $interfacePaths = Get-NetworkInterfaceTweakPaths
                $registryPaths += $interfacePaths
                $registryPaths = $registryPaths | Select-Object -Unique
            }
        }
        
        if ($registryPaths.Count -gt 0) {
            $backupInfo = New-RegistryBackup -RegistryPaths $registryPaths -Name "$Category-backup" -Description "Backup before $Category tweaks"
            
            if ($backupInfo) {
                Write-SuccessLog "Backup created: $($backupInfo.name) (ID: $($backupInfo.id))" -Category "Backup"
            }
            else {
                Write-ErrorLog "Failed to create backup" -Category "Backup"
                return $false
            }
        }
    }
    
    # Apply tweaks
    $appliedCount = 0
    $failedCount = 0
    
    # Apply regular tweaks
    foreach ($tweak in $tweaksToApply) {
        if ($DryRun) {
            Write-InfoLog "[DRY RUN] Would apply: $($tweak.id) - $($tweak.description)" -Category "Tweak"
            continue
        }
        
        if ($PSCmdlet.ShouldProcess("$($tweak.path)\$($tweak.key)", "Set value to $($tweak.value)")) {
            try {
                # Ensure registry path exists
                if (-not (Test-RegistryPath -Path $tweak.path)) {
                    New-Item -Path $tweak.path -Force | Out-Null
                }
                
                # Apply the tweak
                Set-ItemProperty -Path $tweak.path -Name $tweak.key -Value $tweak.value -Type $tweak.type -Force
                
                Write-SuccessLog "Applied: $($tweak.id)" -Category "Tweak"
                $appliedCount++
            }
            catch {
                Write-ErrorLog "Failed to apply $($tweak.id): $_" -Category "Tweak"
                $failedCount++
            }
        }
    }
    
    # Apply interface tweaks
    if ($interfaceTweaksToApply.Count -gt 0) {
        # Import Network utilities
        $networkUtilPath = Join-Path $script:ModulePath "src\utilities\Network.ps1"
        if (Test-Path $networkUtilPath) {
            . $networkUtilPath
            
            Write-InfoLog "Applying tweaks to network interfaces..." -Category "Tweak"
            
            try {
                $interfaceResults = Apply-NetworkInterfaceTweaks -InterfaceTweaks $interfaceTweaksToApply -ActiveOnly -Force:$Force -DryRun:$DryRun
                
                foreach ($result in $interfaceResults) {
                    if ($result.Success) {
                        if (-not $result.DryRun) {
                            Write-SuccessLog "Applied $($result.TweakId) to $($result.FriendlyName)" -Category "Tweak"
                        }
                        $appliedCount++
                    }
                    else {
                        Write-ErrorLog "Failed to apply $($result.TweakId) to $($result.FriendlyName)" -Category "Tweak"
                        $failedCount++
                    }
                }
            }
            catch {
                Write-ErrorLog "Failed to apply interface tweaks: $_" -Category "Tweak"
                $failedCount += $interfaceTweaksToApply.Count
            }
        }
        else {
            Write-ErrorLog "Network utilities not found, skipping interface tweaks" -Category "Tweak"
            $failedCount += $interfaceTweaksToApply.Count
        }
    }
    
    # Apply power commands
    if ($powerCommandsToApply.Count -gt 0) {
        # Import Power utilities
        $powerUtilPath = Join-Path $script:ModulePath "src\utilities\Power.ps1"
        if (Test-Path $powerUtilPath) {
            . $powerUtilPath
            
            Write-InfoLog "Applying power management tweaks..." -Category "Tweak"
            
            try {
                $powerResults = Apply-PowerTweaks -PowerCommands $powerCommandsToApply -DryRun:$DryRun
                
                foreach ($result in $powerResults) {
                    if ($result.Success) {
                        if (-not $result.DryRun) {
                            Write-SuccessLog "Applied power command: $($result.CommandId)" -Category "Tweak"
                        }
                        $appliedCount++
                    }
                    else {
                        Write-ErrorLog "Failed to apply power command $($result.CommandId): $($result.Error)" -Category "Tweak"
                        $failedCount++
                    }
                }
            }
            catch {
                Write-ErrorLog "Failed to apply power commands: $_" -Category "Tweak"
                $failedCount += $powerCommandsToApply.Count
            }
        }
        else {
            Write-ErrorLog "Power utilities not found, skipping power commands" -Category "Tweak"
            $failedCount += $powerCommandsToApply.Count
        }
    }
    
    # Summary
    if (-not $DryRun) {
        Write-InfoLog "Tweak summary: Applied: $appliedCount, Failed: $failedCount" -Category "Tweak"
        
        if ($categoryConfig.requires_restart) {
            Write-WarnLog "System restart required for changes to take effect" -Category "Tweak"
        }
    }
    
    return $failedCount -eq 0
}

function Show-Menu {
    [CmdletBinding()]
    param()
    
    if (-not $script:IsInitialized) {
        if (-not (Initialize-Windozing)) {
            return
        }
    }
    
    $running = $true
    
    while ($running) {
        Clear-Host
        Write-Host "`n===== WINDOZING - Windows Optimization Tool =====" -ForegroundColor Cyan
        Write-Host "`nAvailable Tweaks:" -ForegroundColor Yellow
        
        $tweaks = Get-AvailableTweaks -IncludeMetadata
        $index = 1
        $categoryMap = @{}
        
        foreach ($category in $tweaks.Keys | Sort-Object) {
            $categoryInfo = $tweaks[$category]
            $riskColor = switch ($categoryInfo.risk) {
                "low" { "Green" }
                "medium" { "Yellow" }
                "high" { "Red" }
                default { "White" }
            }
            
            Write-Host "`n  $index. $($categoryInfo.name)" -ForegroundColor White
            Write-Host "     Risk: " -NoNewline
            Write-Host $categoryInfo.risk -ForegroundColor $riskColor
            Write-Host "     $($categoryInfo.description)" -ForegroundColor Gray
            
            $categoryMap[$index] = $category
            $index++
        }
        
        Write-Host "`n  B. Backup Management" -ForegroundColor White
        Write-Host "  S. System Status" -ForegroundColor White
        Write-Host "  Q. Quit" -ForegroundColor White
        
        Write-Host "`n" -NoNewline
        $choice = Read-Host "Select an option"
        
        switch ($choice.ToUpper()) {
            "Q" {
                $running = $false
            }
            
            "B" {
                Show-BackupMenu
            }
            
            "S" {
                Show-SystemStatus
            }
            
            default {
                if ($choice -match '^\d+$') {
                    $selection = [int]$choice
                    if ($categoryMap.ContainsKey($selection)) {
                        $category = $categoryMap[$selection]
                        
                        Write-Host "`nOptions for this tweak:" -ForegroundColor Yellow
                        Write-Host "  1. Apply with backup (recommended)" -ForegroundColor Green
                        Write-Host "  2. Apply without backup" -ForegroundColor Yellow
                        Write-Host "  3. Dry run (preview changes)" -ForegroundColor Cyan
                        Write-Host "  4. Cancel" -ForegroundColor White
                        
                        $tweakChoice = Read-Host "`nSelect option"
                        
                        switch ($tweakChoice) {
                            "1" { Invoke-Tweak -Category $category -BackupFirst }
                            "2" { Invoke-Tweak -Category $category }
                            "3" { Invoke-Tweak -Category $category -DryRun }
                        }
                        
                        if ($tweakChoice -ne "4") {
                            Write-Host "`nPress any key to continue..."
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        }
                    }
                }
            }
        }
    }
    
    Write-Host "`nThank you for using windozing!" -ForegroundColor Green
}

function Show-BackupMenu {
    [CmdletBinding()]
    param()
    
    $running = $true
    
    while ($running) {
        Clear-Host
        Write-Host "`n===== BACKUP MANAGEMENT =====" -ForegroundColor Cyan
        
        $backups = Get-RegistryBackup | Select-Object -First 10
        
        if ($backups.Count -eq 0) {
            Write-Host "`nNo backups found." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nRecent Backups:" -ForegroundColor Yellow
            $index = 1
            $backupMap = @{}
            
            foreach ($backup in $backups) {
                $timestamp = [datetime]$backup.timestamp
                Write-Host "`n  $index. $($backup.name)" -ForegroundColor White
                Write-Host "     Created: $($timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
                Write-Host "     Files: $($backup.files.Count)" -ForegroundColor Gray
                
                $backupMap[$index] = $backup.id
                $index++
            }
        }
        
        Write-Host "`n  C. Clean old backups" -ForegroundColor White
        Write-Host "  B. Back to main menu" -ForegroundColor White
        
        Write-Host "`n" -NoNewline
        $choice = Read-Host "Select a backup to restore or an option"
        
        switch ($choice.ToUpper()) {
            "B" {
                $running = $false
            }
            
            "C" {
                $removed = Clear-OldBackups -DaysToKeep 30 -MaxBackups 20
                Write-Host "`nCleaned up $removed old backups." -ForegroundColor Green
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            
            default {
                if ($choice -match '^\d+$') {
                    $selection = [int]$choice
                    if ($backupMap.ContainsKey($selection)) {
                        $backupId = $backupMap[$selection]
                        
                        if (Confirm-UserAction -Message "Restore this backup?") {
                            if (Restore-RegistryBackup -Id $backupId) {
                                Write-Host "`nBackup restored successfully!" -ForegroundColor Green
                            }
                            else {
                                Write-Host "`nFailed to restore backup." -ForegroundColor Red
                            }
                            
                            Write-Host "Press any key to continue..."
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        }
                    }
                }
            }
        }
    }
}

function Show-SystemStatus {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "`n===== SYSTEM STATUS =====" -ForegroundColor Cyan
    
    # Windows version
    $osInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    Write-Host "`nWindows Version: $($osInfo.ProductName) (Build $($osInfo.CurrentBuildNumber))" -ForegroundColor White
    
    # Administrator status
    $isAdmin = Test-IsAdministrator
    $adminColor = if ($isAdmin) { "Green" } else { "Red" }
    Write-Host "Administrator: $isAdmin" -ForegroundColor $adminColor
    
    # Disk space
    $cDrive = Get-PSDrive -Name C
    $freeGB = [Math]::Round($cDrive.Free / 1GB, 2)
    $totalGB = [Math]::Round(($cDrive.Used + $cDrive.Free) / 1GB, 2)
    Write-Host "Disk Space (C:): $freeGB GB free of $totalGB GB" -ForegroundColor White
    
    # Module paths
    Write-Host "`nModule Paths:" -ForegroundColor Yellow
    Write-Host "  Config: $(Join-Path $script:ModulePath 'config')" -ForegroundColor Gray
    Write-Host "  Logs: $(Get-LogPath)" -ForegroundColor Gray
    Write-Host "  Backups: $(Join-Path $script:ModulePath 'backups')" -ForegroundColor Gray
    
    # Backup count
    $backupCount = (Get-RegistryBackup).Count
    Write-Host "`nTotal Backups: $backupCount" -ForegroundColor White
    
    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Auto-initialize on module import with default settings
$null = Initialize-Windozing -Silent

# Export the main function if running as script
if ($MyInvocation.InvocationName -eq '&') {
    Show-Menu
}