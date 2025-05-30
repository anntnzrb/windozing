# main.ps1 - Entry point for windozing module

# Import windozing module
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$modulePath\windozing.psd1" -Force -ErrorAction Stop

# Check if running as administrator
if (-not (Test-IsAdministrator)) {
    Write-Warning "This script requires administrator privileges."
    Write-Host ""
    
    # Attempt to restart as admin
    $response = Read-Host "Would you like to restart PowerShell as Administrator? (Y/N)"
    if ($response -eq 'Y') {
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
    else {
        Write-Host "Some tweaks may not work without administrator privileges." -ForegroundColor Yellow
        Write-Host ""
    }
}

# Initialize the module
Write-Host "Initializing windozing..." -ForegroundColor Gray
if (-not (Initialize-Windozing)) {
    Write-Error "Failed to initialize windozing module"
    Write-Host "Please ensure you have administrator privileges and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Clear screen and show the main menu
Clear-Host
Show-Menu