# main.ps1 --- Entry point

# Code:

. ./util.ps1

function Show-Menu {
    Clear-Host
    Write-Host "==== Windows Tweaking Menu ===="
    Write-Host "1: Performance Tweaks"
    Write-Host "2: Network Tweaks" 
    Write-Host "3: Mouse Tweaks"
    Write-Host "4: Apply All Tweaks"
    Write-Host "0: Exit"
    Write-Host "================================"
}

function Invoke-MenuSelection {
    param([string]$Selection)
    
    switch ($Selection) {
        '1' {
            Invoke-Script ".\performance.ps1"
            pause
        }
        '2' {
            Invoke-Script ".\network.ps1"
            pause
        }
        '3' {
            Invoke-Script ".\mouse.ps1"
            pause
        }
        '4' {
            # Apply all tweaks
            Invoke-Script ".\performance.ps1"
            Invoke-Script ".\network.ps1"
            Invoke-Script ".\mouse.ps1"
            Restart-Process "explorer"
            Write-Host "=> All tweaks applied. Consider rebooting."
            pause
        }
        '0' {
            return $false  # Exit
        }
        default {
            Write-Host "Invalid selection. Please try again."
            pause
        }
    }
    return $true  # Continue showing menu
}

# Main execution loop
$continue = $true
while ($continue) {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    $continue = Invoke-MenuSelection $selection
}

Write-Host "Exiting program..."
