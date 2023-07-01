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
        [string]$Value,
        [switch]$Dec,
        [switch]$Hex
    )

    if ($Dec) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
    }
    elseif ($Hex) {
        Set-ItemProperty -Path $Path -Name $Name -Value ([UInt32]::Parse($Value, [System.Globalization.NumberStyles]::HexNumber))
    }
    else {
        throw "Please specify either the -dec or -hex flag."
    }
}