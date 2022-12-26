function Install-Chocolatey {
    # Check if Chocolatey is already installed
    if (-not (Test-Path "$env:ChocolateyInstall\choco.exe")) {
        # Set the security protocol
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        # Download and install Chocolatey
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

function Update-Chocolatey {
    # Upgrade Chocolatey
    choco upgrade chocolatey

    # Upgrade all the installed packages
    choco upgrade all -y
}

function Install-Packages {
    param(
        [string]$PackageFile
    )

    # Read the contents of the package file and filter out empty lines and comments
    $Packages = (Get-Content $PackageFile) | Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }

    choco install -y $Packages
}

# Install and update
Install-Chocolatey
Update-Chocolatey

# Install packages from file
Install-Packages "./assets/choco_pkgs.txt"