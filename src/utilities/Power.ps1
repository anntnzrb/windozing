# Power.ps1 - Power management utilities for windozing

function Get-PowerPlans {
    [CmdletBinding()]
    param()
    
    try {
        $output = & powercfg /list
        $plans = @()
        
        foreach ($line in $output) {
            if ($line -match 'Power Scheme GUID: ([a-f0-9\-]+)\s+\((.+?)\)(\s+\*)?') {
                $plans += [PSCustomObject]@{
                    GUID = $Matches[1]
                    Name = $Matches[2].Trim()
                    IsActive = $Matches[3] -ne $null
                }
            }
        }
        
        return $plans
    }
    catch {
        Write-ErrorLog "Failed to get power plans: $_" -Category "Power"
        return @()
    }
}

function Enable-UltimatePerformancePlan {
    [CmdletBinding()]
    param(
        [switch]$DryRun
    )
    
    $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    
    try {
        # Check if Ultimate Performance plan already exists
        $existingPlans = Get-PowerPlans
        $ultimatePlan = $existingPlans | Where-Object { $_.GUID -eq $ultimateGuid }
        
        if ($ultimatePlan) {
            Write-InfoLog "Ultimate Performance plan already exists" -Category "Power"
            return @{
                Success = $true
                AlreadyExists = $true
                PlanGUID = $ultimateGuid
                DryRun = $DryRun
            }
        }
        
        if ($DryRun) {
            Write-InfoLog "[DRY RUN] Would create Ultimate Performance power plan" -Category "Power"
            return @{
                Success = $true
                AlreadyExists = $false
                PlanGUID = $ultimateGuid
                DryRun = $true
            }
        }
        
        # Create the Ultimate Performance plan
        Write-InfoLog "Creating Ultimate Performance power plan..." -Category "Power"
        $result = & powercfg /duplicatescheme $ultimateGuid 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-SuccessLog "Ultimate Performance power plan created successfully" -Category "Power"
            return @{
                Success = $true
                AlreadyExists = $false
                PlanGUID = $ultimateGuid
                DryRun = $false
            }
        }
        else {
            Write-ErrorLog "Failed to create Ultimate Performance plan: $result" -Category "Power"
            return @{
                Success = $false
                Error = $result
                DryRun = $false
            }
        }
    }
    catch {
        Write-ErrorLog "Failed to enable Ultimate Performance plan: $_" -Category "Power"
        return @{
            Success = $false
            Error = $_.Exception.Message
            DryRun = $DryRun
        }
    }
}

function Set-USBSelectiveSuspend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$Enabled,
        
        [switch]$DryRun
    )
    
    $suspendValue = if ($Enabled) { 1 } else { 0 }
    $action = if ($Enabled) { "Enable" } else { "Disable" }
    
    try {
        if ($DryRun) {
            Write-InfoLog "[DRY RUN] Would $action USB selective suspend" -Category "Power"
            return @{
                Success = $true
                Action = $action
                DryRun = $true
            }
        }
        
        Write-InfoLog "${action}ing USB selective suspend..." -Category "Power"
        
        # Set for AC power
        $acResult = & powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 $suspendValue 2>&1
        
        # Set for DC power
        $dcResult = & powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 $suspendValue 2>&1
        
        # Apply the settings
        $applyResult = & powercfg /SETACTIVE SCHEME_CURRENT 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-SuccessLog "USB selective suspend ${action}d successfully" -Category "Power"
            return @{
                Success = $true
                Action = $action
                DryRun = $false
            }
        }
        else {
            $errorMsg = "AC: $acResult, DC: $dcResult, Apply: $applyResult"
            Write-ErrorLog "Failed to $action USB selective suspend: $errorMsg" -Category "Power"
            return @{
                Success = $false
                Error = $errorMsg
                DryRun = $false
            }
        }
    }
    catch {
        Write-ErrorLog "Failed to set USB selective suspend: $_" -Category "Power"
        return @{
            Success = $false
            Error = $_.Exception.Message
            DryRun = $DryRun
        }
    }
}

function Get-PowerPlanSettings {
    [CmdletBinding()]
    param(
        [string]$PlanGUID = "SCHEME_CURRENT"
    )
    
    try {
        $output = & powercfg /query $PlanGUID
        
        # Parse relevant settings
        $settings = @{
            PlanName = ""
            PlanGUID = $PlanGUID
            USBSelectiveSuspendAC = $null
            USBSelectiveSuspendDC = $null
        }
        
        # Extract plan name
        if ($output -match 'Power Scheme GUID: [a-f0-9\-]+\s+\((.+?)\)') {
            $settings.PlanName = $Matches[1].Trim()
        }
        
        # Look for USB selective suspend settings
        $usbSection = $false
        foreach ($line in $output) {
            if ($line -match "USB selective suspend setting") {
                $usbSection = $true
                continue
            }
            
            if ($usbSection) {
                if ($line -match "Current AC Power Setting Index: 0x([0-9a-f]+)") {
                    $settings.USBSelectiveSuspendAC = [int]"0x$($Matches[1])"
                }
                elseif ($line -match "Current DC Power Setting Index: 0x([0-9a-f]+)") {
                    $settings.USBSelectiveSuspendDC = [int]"0x$($Matches[1])"
                    $usbSection = $false  # Found both, stop looking
                }
            }
        }
        
        return $settings
    }
    catch {
        Write-ErrorLog "Failed to get power plan settings: $_" -Category "Power"
        return $null
    }
}

function Apply-PowerTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$PowerCommands,
        
        [switch]$DryRun
    )
    
    $results = @()
    
    foreach ($command in $PowerCommands) {
        $result = [PSCustomObject]@{
            CommandId = $command.id
            Success = $false
            DryRun = $DryRun
            Error = $null
        }
        
        try {
            switch ($command.id) {
                "ultimate-performance" {
                    $commandResult = Enable-UltimatePerformancePlan -DryRun:$DryRun
                    $result.Success = $commandResult.Success
                    if (-not $commandResult.Success) {
                        $result.Error = $commandResult.Error
                    }
                }
                
                "usb-selective-suspend" {
                    $commandResult = Set-USBSelectiveSuspend -Enabled:$command.enabled -DryRun:$DryRun
                    $result.Success = $commandResult.Success
                    if (-not $commandResult.Success) {
                        $result.Error = $commandResult.Error
                    }
                }
                
                default {
                    $result.Error = "Unknown power command: $($command.id)"
                }
            }
        }
        catch {
            $result.Error = $_.Exception.Message
            Write-ErrorLog "Failed to execute power command $($command.id): $_" -Category "Power"
        }
        
        $results += $result
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Get-PowerPlans',
    'Enable-UltimatePerformancePlan',
    'Set-USBSelectiveSuspend',
    'Get-PowerPlanSettings',
    'Apply-PowerTweaks'
)