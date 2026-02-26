<# : batch section
@echo off & setlocal enabledelayedexpansion

:: Parse /silent argument
set "silent=0"
for %%A in (%*) do (
    if /i "%%~A"=="/silent" set "silent=1"
)

:: Check if running as TrustedInstaller (re-entry point)
whoami /user | find /i "S-1-5-18" > nul 2>&1 && (
    goto :main
)

:: Check if Gaming Services is installed
sc query GamingServices >nul 2>&1
if %errorlevel% equ 0 (
    echo === Checking Gaming Services ===
    echo   Gaming Services is installed, removing...
    winget uninstall 9MWPM2CQNLHN --silent
    echo   Gaming Services removed.
)

set "silentArg="
if "!silent!"=="1" set "silentArg=/silent"
call %SYSTEMROOT%\AtlasModules\Scripts\RunAsTI.cmd "%~f0" !silentArg!

exit /b

:main
if "!silent!"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:SILENT='1'; iex((gc '%~f0' -Raw))"
) else (
    start /wait "Fix Store Issues" powershell -NoProfile -ExecutionPolicy Bypass -Command "iex((gc '%~f0' -Raw))"
)
exit /b
#>

# ======================== PowerShell ========================
# ======================== Force GamingServicesNet ========================
# Attempt to forcibly remove GamingServicesNet service
$gamingService = 'GamingServicesNet'
$svcRegPath = "HKLM\\SYSTEM\\CurrentControlSet\\Services\\$gamingService"
Write-Host "`n=== Attempting to forcibly remove GamingServicesNet ===" -ForegroundColor Magenta
try {
    # Stop the service if running
    $svc = Get-Service -Name $gamingService -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Stopped') {
        Stop-Service -Name $gamingService -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped GamingServicesNet." -ForegroundColor Green
    }
    # Remove service using sc.exe
    $null = & cmd.exe /c "sc.exe delete $gamingService"
    Write-Host "  Issued sc delete command for GamingServicesNet." -ForegroundColor Green
    # Remove registry key
    $null = & cmd.exe /c "reg.exe delete \"$svcRegPath\" /f"
    Write-Host "  Deleted registry key for GamingServicesNet." -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not forcibly remove GamingServicesNet: $($_.Exception.Message)" -ForegroundColor Yellow
}


Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
"@ -Name "Console" -Namespace "Win32" -PassThru | Out-Null

$handle = [Win32.Console]::GetStdHandle(-10) # STD_INPUT_HANDLE
$mode = 0
[void][Win32.Console]::GetConsoleMode($handle, [ref]$mode)
$mode = $mode -band (-bnot 0x0040) # Remove ENABLE_QUICK_EDIT_MODE
[void][Win32.Console]::SetConsoleMode($handle, $mode)

$Silent = $env:SILENT -eq '1'

$TargetFile = 'C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Deployment.srd'
$RootServices = @('GamingServicesNet', 'ClipSVC','AppXSvc', 'StateRepository')

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
# Remove GamingServicesNet and GamingServices from the list if forcibly handled
$allServiceNames.Remove('GamingServicesNet') | Out-Null
$allServiceNames.Remove('GamingServices') | Out-Null


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

if (-not $Silent) {
    Write-Host ""
    pause
}