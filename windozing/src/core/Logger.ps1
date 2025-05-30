# Logger.ps1 - Logging functionality for windozing

enum LogLevel {
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
}

$script:LogConfig = @{
    Level = [LogLevel]::INFO
    FilePath = Join-Path $PSScriptRoot "..\..\logs\windozing.log"
    MaxFileSize = 10MB
    MaxFiles = 5
    ConsoleOutput = $true
    FileOutput = $true
}

function Initialize-Logger {
    [CmdletBinding()]
    param(
        [LogLevel]$Level = [LogLevel]::INFO,
        [string]$LogPath = $null,
        [bool]$ConsoleOutput = $true,
        [bool]$FileOutput = $true
    )
    
    $script:LogConfig.Level = $Level
    $script:LogConfig.ConsoleOutput = $ConsoleOutput
    $script:LogConfig.FileOutput = $FileOutput
    
    if ($LogPath) {
        $script:LogConfig.FilePath = $LogPath
    }
    
    # Create logs directory if needed
    if ($FileOutput) {
        $logDir = Split-Path $script:LogConfig.FilePath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [LogLevel]$Level = [LogLevel]::INFO,
        
        [string]$Category = "General"
    )
    
    # Check if we should log this level
    if ($Level -lt $script:LogConfig.Level) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $levelText = $Level.ToString().PadRight(5)
    $logEntry = "$timestamp [$levelText] [$Category] $Message"
    
    # Console output
    if ($script:LogConfig.ConsoleOutput) {
        $color = switch ($Level) {
            ([LogLevel]::DEBUG) { "Gray" }
            ([LogLevel]::INFO)  { "White" }
            ([LogLevel]::WARN)  { "Yellow" }
            ([LogLevel]::ERROR) { "Red" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File output
    if ($script:LogConfig.FileOutput) {
        try {
            if (Test-Path $script:LogConfig.FilePath) {
                $fileInfo = Get-Item $script:LogConfig.FilePath
                if ($fileInfo.Length -gt $script:LogConfig.MaxFileSize) {
                    Rotate-LogFile
                }
            }
            
            # Append to log file
            Add-Content -Path $script:LogConfig.FilePath -Value $logEntry -Encoding UTF8
        }
        catch {
            if ($script:LogConfig.ConsoleOutput) {
                Write-Host "Failed to write to log file: $_" -ForegroundColor Red
            }
        }
    }
}

function Rotate-LogFile {
    [CmdletBinding()]
    param()
    
    $basePath = $script:LogConfig.FilePath
    $directory = Split-Path $basePath -Parent
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($basePath)
    $extension = [System.IO.Path]::GetExtension($basePath)
    
    # Shift existing log files
    for ($i = $script:LogConfig.MaxFiles - 1; $i -ge 1; $i--) {
        $oldFile = Join-Path $directory "$fileName.$i$extension"
        $newFile = Join-Path $directory "$fileName.$($i + 1)$extension"
        
        if (Test-Path $oldFile) {
            if ($i -eq ($script:LogConfig.MaxFiles - 1)) {
                Remove-Item $oldFile -Force
            }
            else {
                Move-Item $oldFile $newFile -Force
            }
        }
    }
    
    if (Test-Path $basePath) {
        $firstArchive = Join-Path $directory "$fileName.1$extension"
        Move-Item $basePath $firstArchive -Force
    }
}

function Write-DebugLog {
    param([string]$Message, [string]$Category = "General")
    Write-Log -Message $Message -Level ([LogLevel]::DEBUG) -Category $Category
}

function Write-InfoLog {
    param([string]$Message, [string]$Category = "General")
    Write-Log -Message $Message -Level ([LogLevel]::INFO) -Category $Category
}

function Write-WarnLog {
    param([string]$Message, [string]$Category = "General")
    Write-Log -Message $Message -Level ([LogLevel]::WARN) -Category $Category
}

function Write-ErrorLog {
    param([string]$Message, [string]$Category = "General")
    Write-Log -Message $Message -Level ([LogLevel]::ERROR) -Category $Category
}

function Write-SuccessLog {
    param([string]$Message, [string]$Category = "General")
    if ($script:LogConfig.ConsoleOutput) {
        Write-Host "$Message" -ForegroundColor Green
    }
    Write-Log -Message "[SUCCESS] $Message" -Level ([LogLevel]::INFO) -Category $Category
}

function Get-LogPath {
    return $script:LogConfig.FilePath
}

function Set-LogLevel {
    param([LogLevel]$Level)
    $script:LogConfig.Level = $Level
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-Log',
    'Write-DebugLog',
    'Write-InfoLog',
    'Write-WarnLog',
    'Write-ErrorLog',
    'Write-SuccessLog',
    'Get-LogPath',
    'Set-LogLevel'
) -Variable @()