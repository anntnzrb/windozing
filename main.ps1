function Run-Script {
    param(
        [string]$ScriptPath
    )

    # Run the script
    Invoke-Expression $ScriptPath

    # Print a separator
    Write-Host "`n`n---`n`n"
}


# Chocolatey
Run-Script ".\choco.ps1"

# Mouse tweaks
Run-Script ".\mouse.ps1"

pause