[CmdletBinding()]
param()

function Test-WingetInstalled {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-Winget {
    [CmdletBinding()]
    param()
    
    Write-InfoLog "Winget not found. Installing winget using modern methods..."
    
    try {
        $progressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        
        # Method 1: Try PowerShell WinGet Client module approach (2024 recommended)
        Write-InfoLog "Attempting installation via PowerShell WinGet Client module..."
        try {
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
            Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser | Out-Null
            Import-Module -Name Microsoft.WinGet.Client -Force
            Repair-WinGetPackageManager
            
            if (Test-WingetInstalled) {
                Write-SuccessLog "Winget installed successfully via PowerShell module"
                $ProgressPreference = $progressPreference
                return $true
            }
        }
        catch {
            Write-WarnLog "PowerShell module method failed: $($_.Exception.Message)"
        }
        
        # Method 2: Try App Installer registration (for existing installations)
        Write-InfoLog "Attempting winget registration..."
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
            
            if (Test-WingetInstalled) {
                Write-SuccessLog "Winget registered successfully"
                $ProgressPreference = $progressPreference
                return $true
            }
        }
        catch {
            Write-WarnLog "Registration method failed: $($_.Exception.Message)"
        }
        
        # Method 3: Direct download from GitHub (fallback)
        Write-InfoLog "Attempting direct download from GitHub..."
        $downloadUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Write-InfoLog "Downloading winget from: $downloadUrl"
        Add-AppxPackage $downloadUrl
        
        $ProgressPreference = $progressPreference
        
        if (Test-WingetInstalled) {
            Write-SuccessLog "Winget installed successfully via direct download"
            return $true
        }
        else {
            Write-ErrorLog "All winget installation methods failed"
            return $false
        }
    }
    catch {
        Write-ErrorLog "Failed to install winget: $($_.Exception.Message)"
        $ProgressPreference = $progressPreference
        return $false
    }
}

function Update-Winget {
    [CmdletBinding()]
    param()
    
    Write-InfoLog "Updating winget..."
    
    try {
        $result = & winget upgrade --id Microsoft.DesktopAppInstaller --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-SuccessLog "Winget updated successfully"
        }
        else {
            Write-WarnLog "Winget update completed with warnings or no updates available"
        }
        
        return $true
    }
    catch {
        Write-ErrorLog "Failed to update winget: $($_.Exception.Message)"
        return $false
    }
}

function Initialize-Winget {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    Write-InfoLog "Initializing winget..."
    
    if (Test-WingetInstalled) {
        Write-InfoLog "Winget is already installed. Attempting update..."
        Update-Winget
        return $true
    }
    else {
        Write-InfoLog "Winget not found. Installing..."
        return Install-Winget
    }
}

function Get-WingetPackageList {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageListPath
    )
    
    if (-not (Test-Path $PackageListPath)) {
        throw "Package list file not found: $PackageListPath"
    }
    
    try {
        $packages = Get-Content $PackageListPath | Where-Object {
            $_.Trim() -and -not $_.Trim().StartsWith('#')
        } | ForEach-Object { $_.Trim() }
        
        Write-InfoLog "Found $($packages.Count) packages in list"
        return $packages
    }
    catch {
        throw "Failed to read package list: $($_.Exception.Message)"
    }
}

function Install-WingetPackage {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )
    
    Write-InfoLog "Installing package: $PackageId"
    
    try {
        $result = & winget install --id $PackageId --accept-source-agreements --accept-package-agreements --silent 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-SuccessLog "Successfully installed: $PackageId"
            return $true
        }
        else {
            Write-WarnLog "Package installation completed with warnings: $PackageId"
            Write-DebugLog "Winget output: $result"
            return $true
        }
    }
    catch {
        Write-ErrorLog "Failed to install package $PackageId`: $($_.Exception.Message)"
        return $false
    }
}

function Install-WingetPackages {
    [CmdletBinding()]
    param(
        [string]$PackageListPath = (Join-Path $PSScriptRoot "..\..\..\..\pkgs\winget_pkgs.txt")
    )
    
    Write-InfoLog "Starting winget package installation process..."
    
    if (-not (Test-IsAdministrator)) {
        Write-ErrorLog "Administrator privileges required for package installation"
        return
    }
    
    if (-not (Initialize-Winget)) {
        Write-ErrorLog "Failed to initialize winget. Cannot proceed with package installation."
        return
    }
    
    try {
        $packages = Get-WingetPackageList -PackageListPath $PackageListPath
        
        if ($packages.Count -eq 0) {
            Write-WarnLog "No packages found in list"
            return
        }
        
        Write-InfoLog "Installing $($packages.Count) packages..."
        
        $successCount = 0
        $failureCount = 0
        
        foreach ($package in $packages) {
            if (Install-WingetPackage -PackageId $package) {
                $successCount++
            }
            else {
                $failureCount++
            }
        }
        
        Write-InfoLog "Package installation summary:"
        Write-SuccessLog "  Successfully installed: $successCount packages"
        
        if ($failureCount -gt 0) {
            Write-ErrorLog "  Failed to install: $failureCount packages"
        }
        
        Write-InfoLog "Winget package installation process completed."
    }
    catch {
        Write-ErrorLog "Package installation process failed: $($_.Exception.Message)"
    }
}