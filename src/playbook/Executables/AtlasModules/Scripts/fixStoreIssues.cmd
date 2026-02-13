<# : batch section
@echo off & setlocal enabledelayedexpansion

:: Check if running as TrustedInstaller (re-entry point)
whoami /user | find /i "S-1-5-18" > nul 2>&1 && (
    set "gamingServicesInstalled=%~1"
    goto :main
)

:: Check if Gaming Services is installed
set "gamingServicesInstalled=0"
sc query GamingServices >nul 2>&1
if %errorlevel% equ 0 (
    set "gamingServicesInstalled=1"
    echo === Checking Gaming Services ===
    echo   Gaming Services is installed, removing...
    winget uninstall 9MWPM2CQNLHN --silent
    echo   Gaming Services removed.
)

call %SYSTEMROOT%\AtlasModules\Scripts\RunAsTI.cmd "%~f0" !gamingServicesInstalled!

:: Back in non-admin context - reinstall Gaming Services if needed
if "!gamingServicesInstalled!"=="1" (
    echo === Reinstalling Gaming Services ===
    winget install 9MWPM2CQNLHN --silent --accept-package-agreements --accept-source-agreements
)

exit /b

:main
start /wait "Fix Store Issues" powershell -NoProfile -ExecutionPolicy Bypass -Command "iex((gc '%~f0' -Raw))" 
exit /b
#>

# ======================== PowerShell ========================

$TargetFile = 'C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Deployment.srd'
$RootServices = @('ClipSVC','AppXSvc', 'StateRepository')

function Get-AllDependents {
    param([string]$ServiceName)

    $result = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    $queue = [System.Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($ServiceName)

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        $deps = Get-Service -Name $current -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty DependentServices

        foreach ($dep in $deps) {
            if ($result.Add($dep.Name)) {
                $queue.Enqueue($dep.Name)
            }
        }
    }

    return $result
}

# ============================================================
# 1. Collect every service and save original start types
#    (nothing is modified yet — safe to fail here)
# ============================================================
Write-Host "`n=== Collecting services and saving original start types ===" -ForegroundColor Cyan

$allServiceNames = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)

foreach ($root in $RootServices) {
    [void]$allServiceNames.Add($root)
    foreach ($dep in (Get-AllDependents $root)) {
        [void]$allServiceNames.Add($dep)
    }
}

$originalStartTypes = @{}
foreach ($svc in $allServiceNames) {
    $startType = (Get-Service -Name $svc -ErrorAction Stop).StartType
    $originalStartTypes[$svc] = $startType
    Write-Host "  $svc  ->  StartType = $startType"
}

# ============================================================
# From here on, every change MUST be rolled back on failure.
# ============================================================
$hasFailed = $false

try {

    # ========================================================
    # 2. Disable every service via Set-Service
    # ========================================================
    Write-Host "`n=== Disabling all services ===" -ForegroundColor Cyan

    foreach ($svc in $allServiceNames) {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Write-Host "  Disabled: $svc"
    }

    # ========================================================
    # 3. Stop every service — dependents first, then roots.
    # ========================================================
    Write-Host "`n=== Stopping all services ===" -ForegroundColor Cyan

    $dependentsOnly = $allServiceNames | Where-Object { $_ -notin $RootServices }

    foreach ($name in $dependentsOnly) {
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($null -eq $s) { continue }
        $s.Refresh()
        if ($s.Status -eq 'Stopped') { continue }
        Write-Host "  Sending stop to dependent: $name ..."
        try { Stop-Service $s } catch {
            Write-Host "    Warning: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
        }
    }
    
    foreach ($name in $RootServices) {
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($null -eq $s) { continue }
        $s.Refresh()
        if ($s.Status -eq 'Stopped') { continue }
        Write-Host "  Sending stop to root: $name ..."
        try { Stop-Service $s } catch {
            Write-Host "    Warning: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host "  Waiting for services to stop ..."
    Start-Sleep -Seconds 5

    $stubborn = @()
    foreach ($name in $allServiceNames) {
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($null -eq $s) { continue }
        $s.Refresh()
        if ($s.Status -eq 'Stopped') { continue }
        Write-Warning "$name is still $($s.Status) - waiting up to 30s ..."
        try {
            $s.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))
        } catch {
            $s.Refresh()
            if ($s.Status -ne 'Stopped') {
                $stubborn += $name
                Write-Host "  FAILED: $name did not stop ($($s.Status))" -ForegroundColor Red
            }
        }
    }

    if ($stubborn.Count -gt 0) {
        throw "The following services could not be stopped: $($stubborn -join ', '). File deletion skipped."
    }

    Write-Host "  All services stopped." -ForegroundColor Green

    # ========================================================
    # 4. Delete the target file
    # ========================================================
    if (Test-Path -LiteralPath $TargetFile) {
        Remove-Item -LiteralPath $TargetFile -Force -ErrorAction Stop
        Write-Host "  Deleted: $TargetFile" -ForegroundColor Green
    } else {
        Write-Host "  File not found (already absent): $TargetFile" -ForegroundColor Yellow
    }

} catch {
    $hasFailed = $true
    Write-Host "`n!!! ERROR: $($_.Exception.Message)" -ForegroundColor Red
} finally {

    # ========================================================
    # 5. ALWAYS restore original start types via Set-Service
    # ========================================================
    Write-Host "`n=== Restoring original start types ===" -ForegroundColor Cyan

    foreach ($svc in $allServiceNames) {
        $origValue = $originalStartTypes[$svc]
        try {
            Set-Service -Name $svc -StartupType $origValue -ErrorAction Stop
            Write-Host "  Restored: $svc  ->  StartType = $origValue"
        } catch {
            Write-Host "  FAILED to restore ${svc}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # ========================================================
    # 6. Start StateRepository back up
    # ========================================================
    Write-Host "`n=== Starting StateRepository ===" -ForegroundColor Cyan
    try {
        Start-Service -Name 'StateRepository' -ErrorAction Stop
        Write-Host "  StateRepository is running." -ForegroundColor Green
    } catch {
        Write-Host "  FAILED to start StateRepository: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($hasFailed) {
    Write-Host "`n=== Finished WITH ERRORS. Review output above. ===" -ForegroundColor Red
} else {
    Write-Host "`n=== Done. ===" -ForegroundColor Green
}

Write-Host ""
pause