# main.ps1 --- Entry point

# Code:

. ./util.ps1

# define files to invoke in order
$files = @(
    ".\choco.ps1",
    ".\mouse.ps1",
    ".\regedit.ps1"
)

# loop through each file (script) file and invoke it
foreach ($f in $files) {
    Invoke-Script $f
}

Restart-Process "explorer"
Write-Host "=> Script finalized. Consider rebooting."

pause