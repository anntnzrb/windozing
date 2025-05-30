# Process.ps1 - Process management utilities

function Restart-Process {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,
        
        [int]$WaitTime = 2000,
        
        [string[]]$Arguments = @(),
        
        [switch]$AsAdmin
    )
    
    # Import logger if available
    $logAvailable = Get-Command Write-InfoLog -ErrorAction SilentlyContinue
    
    if ($PSCmdlet.ShouldProcess($ProcessName, "Restart process")) {
        # Get the process before stopping it
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        
        if ($process) {
            $processPath = $process.Path | Select-Object -First 1
            
            # Stop the process
            try {
                if ($logAvailable) {
                    Write-InfoLog "Stopping process: $ProcessName" -Category "Process"
                }
                
                Stop-Process -Name $ProcessName -Force -ErrorAction Stop
                
                # Wait for process to fully terminate
                Start-Sleep -Milliseconds $WaitTime
            }
            catch {
                Write-Error "Failed to stop process $ProcessName : $_"
                return $false
            }
        }
        else {
            Write-Warning "Process $ProcessName not found running"
            # Try to find the executable
            $processPath = Get-Command $ProcessName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        }
        
        # Restart the process
        if ($processPath) {
            try {
                if ($logAvailable) {
                    Write-InfoLog "Starting process: $ProcessName" -Category "Process"
                }
                
                $startParams = @{
                    FilePath = $processPath
                    ArgumentList = $Arguments
                }
                
                if ($AsAdmin) {
                    $startParams['Verb'] = 'RunAs'
                }
                
                Start-Process @startParams
                return $true
            }
            catch {
                Write-Error "Failed to start process $ProcessName : $_"
                return $false
            }
        }
        else {
            Write-Error "Could not find executable path for $ProcessName"
            return $false
        }
    }
}

function Test-ProcessElevated {
    [CmdletBinding()]
    param()
    
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Stop-ProcessSafely {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,
        
        [int]$Timeout = 30,
        
        [switch]$Force
    )
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if (-not $processes) {
        Write-Verbose "Process $ProcessName not found"
        return $true
    }
    
    foreach ($process in $processes) {
        if ($PSCmdlet.ShouldProcess($process.ProcessName, "Stop process (PID: $($process.Id))")) {
            try {
                # Try graceful shutdown first
                $process.CloseMainWindow() | Out-Null
                
                # Wait for graceful shutdown
                $waited = 0
                while (-not $process.HasExited -and $waited -lt $Timeout) {
                    Start-Sleep -Seconds 1
                    $waited++
                    $process.Refresh()
                }
                
                # Force kill if necessary
                if (-not $process.HasExited) {
                    if ($Force) {
                        $process.Kill()
                        Write-Warning "Force killed process $ProcessName (PID: $($process.Id))"
                    }
                    else {
                        Write-Error "Process $ProcessName did not exit gracefully within timeout"
                        return $false
                    }
                }
                
                Write-Verbose "Successfully stopped process $ProcessName (PID: $($process.Id))"
            }
            catch {
                Write-Error "Failed to stop process $ProcessName : $_"
                return $false
            }
        }
    }
    
    return $true
}

function Wait-ProcessStart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,
        
        [int]$Timeout = 30
    )
    
    $waited = 0
    while ($waited -lt $Timeout) {
        if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
            Write-Verbose "Process $ProcessName started"
            return $true
        }
        
        Start-Sleep -Seconds 1
        $waited++
    }
    
    Write-Error "Process $ProcessName did not start within timeout"
    return $false
}

function Get-ProcessInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if (-not $processes) {
        return $null
    }
    
    $results = @()
    foreach ($process in $processes) {
        $results += [PSCustomObject]@{
            Name = $process.ProcessName
            Id = $process.Id
            Path = $process.Path
            StartTime = $process.StartTime
            CPU = $process.CPU
            Memory = [Math]::Round($process.WorkingSet64 / 1MB, 2)
            Threads = $process.Threads.Count
            Handles = $process.HandleCount
        }
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Restart-Process',
    'Test-ProcessElevated',
    'Stop-ProcessSafely',
    'Wait-ProcessStart',
    'Get-ProcessInfo'
)