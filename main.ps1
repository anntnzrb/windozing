. ./util.ps1

# Chocolatey
Invoke-Script ".\choco.ps1"

# Mouse tweaks
Invoke-Script ".\mouse.ps1"

# Network tweaks
Invoke-Script ".\network.ps1"

# Cleanup
Restart-Process "explorer"
Write-Host "=> Script finalized. Consider rebooting."

pause