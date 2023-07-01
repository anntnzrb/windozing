function Install-Chocolatey {
    # check if chocolatey is already installed
    if (-not (Test-Path "$env:ChocolateyInstall\choco.exe")) {
        # set security protocol
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        # download & install chocolatey
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

function Update-Chocolatey {
    # upgrade chocolatey itself
    choco upgrade chocolatey -y
}

function Update-Packages {
    # upgrade all chocolatey packages
    choco upgrade all -y
}

function Get-Packages-File {
    param(
        [string]$PackageFile
    )

    # read the contents of the package file & filter out empty lines and comments
    return (Get-Content $PackageFile) | Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }
}

function Install-Package {
    param(
        [string]$Package
    )

    # install package
    choco install -y $Package
}

function Install-Packages-From-File {
    param(
        [string]$PackageFile
    )

    # get the list of packages from file
    $Packages = Get-Packages-File $PackageFile

    # install the packages
    foreach ($Pkg in $Packages) {
        Install-Package $Pkg
    }
}

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

# install & update
Install-Chocolatey
Update-Chocolatey
Update-Packages

# install packages from file
Install-Packages-From-File "./assets/choco_pkgs.txt"