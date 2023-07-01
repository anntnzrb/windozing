function Restart-Process {
    param ([string] $ProcessName)

    Stop-Process -Name $ProcessName
    Start-Process -FilePath $ProcessName
}
function Invoke-Script {
    param([string]$ScriptPath)

    Invoke-Expression $ScriptPath
}

function Edit-RegistryEntry {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [switch]$Dec,
        [switch]$Hex,
        [switch]$String
    )

    if ($Dec) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
    }
    elseif ($Hex) {
        Set-ItemProperty -Path $Path -Name $Name -Value ([UInt32]::Parse($Value, [System.Globalization.NumberStyles]::HexNumber))
    }
    elseif ($String) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type ([Microsoft.Win32.RegistryValueKind]::String)
    }
    else {
        throw "Please specify either the -dec, -hex, or -string flag."
    }
}