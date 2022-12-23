function Restart-Process {
    param (
        [string] $ProcessName
    )

    Stop-Process -Name $ProcessName
    Start-Process -FilePath $ProcessName
}

Restart-Process "explorer"

Write-Host "Done."