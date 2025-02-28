. ./util.ps1

$Tweaks = @(
    @{Id = 1; Name = "Performance Tweaks"; ScriptPath = ".\performance.ps1"; 
      SuccessMessage = "Performance tweaks applied. Explorer restarted."},
    @{Id = 2; Name = "Network Tweaks"; ScriptPath = ".\network.ps1";
      SuccessMessage = "Network tweaks applied. Explorer restarted."},
    @{Id = 3; Name = "Mouse Tweaks"; ScriptPath = ".\mouse.ps1";
      SuccessMessage = "Mouse tweaks applied. Explorer restarted."},
    @{Id = 4; Name = "Power Tweaks"; ScriptPath = ".\power.ps1"; 
      SuccessMessage = "Power tweaks applied. Ultimate Performance plan activated."},
    @{Id = 5; Name = "Game Tweaks"; ScriptPath = ".\game.ps1";
      SuccessMessage = "Game tweaks applied. Game Mode and Hardware Accelerated GPU Scheduling disabled.";
      ExtraMessage = "A system restart is recommended for all changes to take effect."}
)

function Apply-Tweak {
    param([hashtable]$Tweak)
    Write-Host "  > $($Tweak.Name)..." -ForegroundColor DarkYellow
    Invoke-Script $Tweak.ScriptPath
}

function Show-Menu {
    Clear-Host
    Write-Host "==== Windows Tweaking Menu ====" -ForegroundColor Cyan
    $Tweaks | ForEach-Object { Write-Host "$($_.Id): $($_.Name)" }
    Write-Host "6: Apply All Tweaks"
    Write-Host "0: Exit"
    Write-Host "================================" -ForegroundColor Cyan
}

function Invoke-MenuSelection {
    param([string]$Selection)
    
    if ($Selection -eq '6') {
        Write-Host "`nApplying all tweaks..." -ForegroundColor Yellow
        
        foreach ($tweak in $Tweaks) {
            Apply-Tweak $tweak
        }
        
        # Always restart explorer after applying tweaks
        Write-Host "  > Restarting Explorer..." -ForegroundColor DarkYellow
        Restart-Process "explorer"
        
        Write-Host "`n[SUCCESS] All tweaks applied." -ForegroundColor Green
        Write-Host "A system reboot is recommended for all changes to take effect." -ForegroundColor Yellow
    }
    elseif ($Selection -eq '0') {
        Write-Host "`nExiting..." -ForegroundColor Yellow
        return $false
    }
    else {
        $selectedTweak = $Tweaks | Where-Object { $_.Id -eq $Selection }
        
        if ($selectedTweak) {
            Write-Host "`nApplying $($selectedTweak.Name)..." -ForegroundColor Yellow
            Apply-Tweak $selectedTweak
            
            # Always restart explorer after applying any tweak
            Write-Host "  > Restarting Explorer..." -ForegroundColor DarkYellow
            Restart-Process "explorer"
            
            Write-Host "`n[SUCCESS] $($selectedTweak.SuccessMessage)" -ForegroundColor Green
            
            if ($selectedTweak.ExtraMessage) {
                Write-Host "$($selectedTweak.ExtraMessage)" -ForegroundColor Yellow
            }
        } 
        else {
            Write-Host "`n[ERROR] Invalid selection. Please try again." -ForegroundColor Red
        }
    }
    
    Write-Host "`nPress any key to return to the menu..." -ForegroundColor Cyan
    [void](Read-Host)
    return $true
}

do {
    Show-Menu
    $selection = Read-Host "`nPlease make a selection"
} while (Invoke-MenuSelection $selection)
