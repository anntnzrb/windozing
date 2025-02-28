# power.ps1 --- Power management tweaks

# Code:

. ./util.ps1

function Enable-UltimatePerformancePlan {
    # Check if Ultimate Performance plan is installed
    $ultimatePlan = powercfg -list | Select-String -Pattern "Ultimate Performance"
    if ($ultimatePlan) {
        Write-Host "Ultimate Performance plan is already installed."
    } else {
        Write-Host "Installing Ultimate Performance plan..."
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "> Ultimate Performance plan installed."
    }

    # Set the Ultimate Performance plan as active
    $ultimatePlanGUID = (powercfg -list | Select-String -Pattern "Ultimate Performance").Line.Split()[3]
    powercfg -setactive $ultimatePlanGUID

    Write-Host "Ultimate Performance plan is now active."
}

# Execute by default when script is run directly
Enable-UltimatePerformancePlan
