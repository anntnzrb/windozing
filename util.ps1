function Restart-Process {
    param ([string] $ProcessName)

    Stop-Process -Name $ProcessName
    Start-Process -FilePath $ProcessName
}
function Invoke-Script {
    param([string]$ScriptPath)

    # Run the script
    Invoke-Expression $ScriptPath

    # Print a separator
    Write-Host "`n`n---`n`n"
}

function Edit-RegistryEntry {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    Set-ItemProperty -Path $Path -Name $Name -Value $Value
}