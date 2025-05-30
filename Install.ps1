# Install.ps1 - Windozing module installer
# Usage: iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yourusername/windozing/main/Install.ps1'))

[CmdletBinding()]
param(
    [string]$Branch = "main",
    [string]$InstallPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\windozing",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "Windozing Installer" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "Not running as administrator. Some features may not work properly."
    Write-Host "Consider running PowerShell as Administrator for full functionality." -ForegroundColor Yellow
    Write-Host ""
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    return
}

# Create module directory
if (Test-Path $InstallPath) {
    if ($Force) {
        Write-Host "Removing existing installation..." -ForegroundColor Yellow
        Remove-Item -Path $InstallPath -Recurse -Force
    }
    else {
        Write-Error "Windozing is already installed at $InstallPath. Use -Force to overwrite."
        return
    }
}

Write-Host "Creating module directory..." -ForegroundColor Gray
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null

# Download and extract repository
$tempPath = Join-Path $env:TEMP "windozing-install"
$zipPath = Join-Path $tempPath "windozing.zip"
$extractPath = Join-Path $tempPath "extract"

try {
    # Create temp directory
    if (Test-Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    # Download repository
    Write-Host "Downloading windozing from GitHub..." -ForegroundColor Gray
    $downloadUrl = "https://github.com/yourusername/windozing/archive/refs/heads/$Branch.zip"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download windozing. Please check your internet connection and try again."
        return
    }
    
    # Extract archive
    Write-Host "Extracting files..." -ForegroundColor Gray
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    
    # Find the extracted folder (GitHub adds branch name to folder)
    $sourceFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    
    # Copy module files from windozing subdirectory
    Write-Host "Installing module files..." -ForegroundColor Gray
    $moduleSourcePath = Join-Path $sourceFolder.FullName "windozing"
    
    if (Test-Path $moduleSourcePath) {
        Copy-Item -Path "$moduleSourcePath\*" -Destination $InstallPath -Recurse -Force
    }
    else {
        Write-Error "Module files not found in extracted archive"
        return
    }
    
    # Import module to verify installation
    Write-Host "Verifying installation..." -ForegroundColor Gray
    Import-Module $InstallPath -Force -ErrorAction Stop
    
    Write-Host ""
    Write-Host "Windozing has been successfully installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To get started:" -ForegroundColor Cyan
    Write-Host "  1. Import the module: Import-Module windozing" -ForegroundColor White
    Write-Host "  2. Initialize windozing: Initialize-Windozing" -ForegroundColor White
    Write-Host "  3. Show the menu: Show-Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "For more information, visit: https://github.com/yourusername/windozing" -ForegroundColor Gray
    
}
catch {
    Write-Error "Installation failed: $_"
    
    # Cleanup on failure
    if (Test-Path $InstallPath) {
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
finally {
    # Cleanup temp files
    if (Test-Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Add module to profile if requested
if ($isAdmin) {
    $addToProfile = Read-Host "Would you like to automatically import windozing in your PowerShell profile? (Y/N)"
    if ($addToProfile -eq 'Y') {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        if (-not (Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        }
        
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -notmatch "Import-Module windozing") {
            Add-Content -Path $PROFILE -Value "`n# Import windozing module`nImport-Module windozing -ErrorAction SilentlyContinue"
            Write-Host "Added windozing to PowerShell profile." -ForegroundColor Green
        }
    }
}