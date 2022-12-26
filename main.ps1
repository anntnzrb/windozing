function Invoke-Script {
    param(
        [string]$ScriptPath
    )

    # Run the script
    Invoke-Expression $ScriptPath

    # Print a separator
    Write-Host "`n`n---`n`n"
}

# Chocolatey
Invoke-Script ".\choco.ps1"

# Mouse tweaks
Invoke-Script ".\mouse.ps1"

# Cleanup
Invoke-Script ".\finalize.ps1"

Write-Host "Main script finalized."

pause