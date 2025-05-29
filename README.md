# windozing

Collection of scripts for automating the installation of packages 
and making a few other system tweaks on Windows systems.

**NOTE:** This repository is experimental, as I do not use Windows as my daily
driver. Use at your own risk.

## Project Structure

```
windozing/
├── main.ps1                # Main menu script
├── run.bat                 # Admin launcher
├── src/
│   ├── tweaks/            # System tweak scripts
│   │   ├── performance.ps1
│   │   ├── network.ps1
│   │   ├── mouse.ps1
│   │   ├── power.ps1
│   │   └── game.ps1
│   └── utilities/         # Utility functions
│       └── util.ps1
└── scripts/               # Standalone scripts
    └── caps-esc-toggle.ps1
```

## Installation

To use the scripts in this repository, you will need to have
[PowerShell](https://docs.microsoft.com/en-us/powershell/).

## Usage

To use the scripts in this repository, navigate to the repository
directory in a PowerShell window and run the script you want to use.
For example, to run the `main.ps1` script, you would enter
the following command:

```powershell
.\main.ps1
```

Or use the batch file for automatic admin elevation:

```batch
run.bat
```
