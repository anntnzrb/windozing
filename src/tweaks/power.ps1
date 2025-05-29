# power.ps1 --- Power management tweaks

# Code:

. ../utilities/util.ps1

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

function Disable-UsbSelectiveSuspend {
    Write-Host "Disabling USB Selective Suspend..."
    
    # Get active power scheme GUID
    $powerScheme = (powercfg -getactivescheme).Split()[3]
    
    # Disable USB selective suspend for AC (plugged in)
    powercfg -setacvalueindex $powerScheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    
    # Disable USB selective suspend for DC (battery)
    powercfg -setdcvalueindex $powerScheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    Write-Host "> USB Selective Suspend disabled for both AC and DC power."
}

Enable-UltimatePerformancePlan
Disable-UsbSelectiveSuspend
