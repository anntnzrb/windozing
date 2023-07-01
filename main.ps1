. ./util.ps1

# Chocolatey
Invoke-Script ".\choco.ps1"

# Mouse tweaks
Invoke-Script ".\mouse.ps1"

# Cleanup
Restart-Process "explorer"
Write-Host "Done."

Write-Host "Main script finalized."

pause