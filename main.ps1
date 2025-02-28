# main.ps1 --- Entry point

# Code:

. ./util.ps1

function Show-Menu {
    Clear-Host
    Write-Host "==== Windows Tweaking Menu ====" -ForegroundColor Cyan
    Write-Host "1: Performance Tweaks"
    Write-Host "2: Network Tweaks" 
    Write-Host "3: Mouse Tweaks"
    Write-Host "4: Power Tweaks"
    Write-Host "5: Game Tweaks"
    Write-Host "6: Apply All Tweaks"
    Write-Host "0: Exit"
    Write-Host "================================" -ForegroundColor Cyan
}

function Invoke-MenuSelection {
    param([string]$Selection)
    
    switch ($Selection) {
        '1' {
            Write-Host "`nApplying performance tweaks..." -ForegroundColor Yellow
            Invoke-Script ".\performance.ps1"
            Restart-Process "explorer"
            Write-Host "`n[SUCCESS] Performance tweaks applied. Explorer restarted." -ForegroundColor Green
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
        '2' {
            Write-Host "`nApplying network tweaks..." -ForegroundColor Yellow
            Invoke-Script ".\network.ps1"
            Restart-Process "explorer"
            Write-Host "`n[SUCCESS] Network tweaks applied. Explorer restarted." -ForegroundColor Green
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
        '3' {
            Write-Host "`nApplying mouse tweaks..." -ForegroundColor Yellow
            Invoke-Script ".\mouse.ps1"
            Restart-Process "explorer"
            Write-Host "`n[SUCCESS] Mouse tweaks applied. Explorer restarted." -ForegroundColor Green
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
        '4' {
            Write-Host "`nApplying power tweaks..." -ForegroundColor Yellow
            Invoke-Script ".\power.ps1"
            Write-Host "`n[SUCCESS] Power tweaks applied. Ultimate Performance plan activated." -ForegroundColor Green
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
        '5' {
            Write-Host "`nApplying game tweaks..." -ForegroundColor Yellow
            Invoke-Script ".\game.ps1"
            Write-Host "`n[SUCCESS] Game tweaks applied. Game Mode and Hardware Accelerated GPU Scheduling disabled." -ForegroundColor Green
            Write-Host "A system restart is recommended for all changes to take effect." -ForegroundColor Yellow
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
        '6' {
            Write-Host "`nApplying all tweaks..." -ForegroundColor Yellow
            
            Write-Host "  > Performance tweaks..." -ForegroundColor DarkYellow
            Invoke-Script ".\performance.ps1"
            
            Write-Host "  > Network tweaks..." -ForegroundColor DarkYellow
            Invoke-Script ".\network.ps1"
            
            Write-Host "  > Mouse tweaks..." -ForegroundColor DarkYellow
            Invoke-Script ".\mouse.ps1"
            
            Write-Host "  > Power tweaks..." -ForegroundColor DarkYellow
            Invoke-Script ".\power.ps1"
            
            Write-Host "  > Game tweaks..." -ForegroundColor DarkYellow
            Invoke-Script ".\game.ps1"
            
            Restart-Process "explorer"
            Write-Host "`n[SUCCESS] All tweaks applied. Explorer restarted." -ForegroundColor Green
            Write-Host "A system reboot is recommended for all changes to take effect." -ForegroundColor Yellow
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
        '0' {
            Write-Host "`nExiting..." -ForegroundColor Yellow
            return $false  # Exit
        }
        default {
            Write-Host "`n[ERROR] Invalid selection. Please try again." -ForegroundColor Red
            Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
            pause
        }
    }
    return $true  # keep showing menu
}

# Main execution loop
$continue = $true
while ($continue) {
    Show-Menu
    $selection = Read-Host "`nPlease make a selection"
    $continue = Invoke-MenuSelection $selection
}
