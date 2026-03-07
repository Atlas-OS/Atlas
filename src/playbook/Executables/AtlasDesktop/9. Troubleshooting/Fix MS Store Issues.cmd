<# : batch section
@echo off & setlocal enabledelayedexpansion

:: Check if running as TrustedInstaller
whoami /user | find /i "S-1-5-18" > nul 2>&1 && goto :main

sc query GamingServices >nul 2>&1
if %errorlevel% equ 0 (
  echo === Checking Gaming Services ===
  echo  Gaming Services is installed, removing...
  winget uninstall 9MWPM2CQNLHN --silent
  echo  Gaming Services removed.
)

call %SYSTEMROOT%\AtlasModules\Scripts\RunAsTI.cmd "%~f0" %*
exit /b

:main
start /wait "Fix Store Issues" powershell -NoProfile -ExecutionPolicy Bypass -Command "iex((gc '%~f0' -Raw))"
exit /b
#>

# ======================== PowerShell ========================
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

$Desktop = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' -Name 'Common Desktop').'Common Desktop'
$LogFile = "$Desktop\fixStoreIssues.txt"
Start-Transcript -Path $LogFile -Force | Out-Null

$Silent = $env:SILENT -eq '1'

$TargetFile = 'C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Deployment.srd'
$RootServices = @('ClipSVC', 'AppXSvc', 'StateRepository')

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
    # 2. Disable every service via sc.exe
    # ========================================================
    Write-Host "`n=== Disabling all services ===" -ForegroundColor Cyan

    $setSvc = "$env:SYSTEMROOT\AtlasModules\Scripts\setSvc.cmd"

    foreach ($svc in $allServiceNames) {
        & $setSvc $svc 4 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Failed to disable $svc" }
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
        try { sc.exe stop $name | Out-Null } catch {
            Write-Host "    Warning: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
        }
    }

    foreach ($name in $RootServices) {
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($null -eq $s) { continue }
        $s.Refresh()
        if ($s.Status -eq 'Stopped') { continue }
        Write-Host "  Sending stop to root: $name ..."
        try { sc.exe stop $name | Out-Null } catch {
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
        while ($s.Status -ne 'Stopped') {
            Write-Warning "$name is still $($s.Status) - waiting up to 10s ..."
            try {
                $s.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(10))
            }
            catch {
                $s.Refresh()
                if ($s.Status -ne 'Stopped') {
                    Write-Host "  $name still running, attempting to stop again..." -ForegroundColor Yellow
                    try { sc.exe stop $name | Out-Null } catch {}
                    Start-Sleep -Seconds 5
                    $s.Refresh()
                    if ($s.Status -ne 'Stopped') {
                        $stubborn += $name
                        Write-Host "  FAILED: $name did not stop ($($s.Status))" -ForegroundColor Red
                    }
                }
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
    }
    else {
        Write-Host "  File not found (already absent): $TargetFile" -ForegroundColor Yellow
    }

}
catch {
    $hasFailed = $true
    Write-Host "`n!!! ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {

    # ========================================================
    # 5. ALWAYS restore original start types via Set-Service
    # ========================================================
    Write-Host "`n=== Restoring original start types ===" -ForegroundColor Cyan

    $startTypeMap = @{
        'Automatic' = 2
        'Manual'    = 3
        'Disabled'  = 4
        'Boot'      = 0
        'System'    = 1
    }

    $setSvc = "$env:SYSTEMROOT\AtlasModules\Scripts\setSvc.cmd"

    foreach ($svc in $allServiceNames) {
        $origValue = $originalStartTypes[$svc]
        $startValue = $startTypeMap[$origValue.ToString()]
        if ($null -eq $startValue) {
            Write-Host "  FAILED to restore ${svc}: unknown start type '$origValue'" -ForegroundColor Red
            continue
        }
        & $setSvc $svc $startValue | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  FAILED to restore ${svc} (setSvc exit code $LASTEXITCODE)" -ForegroundColor Red
        } else {
            Write-Host "  Restored: $svc  ->  StartType = $origValue"
        }
    }

    # ========================================================
    # 6. Start StateRepository back up
    # ========================================================
    Write-Host "`n=== Starting StateRepository ===" -ForegroundColor Cyan
    try {
        Start-Service -Name 'StateRepository' -ErrorAction Stop
        Write-Host "  StateRepository is running." -ForegroundColor Green
    }
    catch {
        Write-Host "  FAILED to start StateRepository: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($hasFailed) {
    Write-Host "`n=== Finished WITH ERRORS. Review output above. ===" -ForegroundColor Red
}
else {
    # ========================================================
    # 7. Run wsreset.exe -i to reinstall Store
    # ========================================================
    Write-Host "`n=== Running wsreset.exe -i (this may take a moment) ===" -ForegroundColor Cyan
    $wsresetProcess = Start-Process -FilePath 'wsreset.exe' -ArgumentList '-i' -PassThru -Wait
    if ($wsresetProcess.ExitCode -ne 0) {
        Write-Host "  wsreset.exe -i exited with code $($wsresetProcess.ExitCode)" -ForegroundColor Yellow
    } else {
        Write-Host "  wsreset.exe -i completed successfully." -ForegroundColor Green
    }

    Write-Host "`n=== Done. ===" -ForegroundColor Green
}

Stop-Transcript | Out-Null
Write-Host "  Log saved to: $LogFile"

if (-not $Silent) {
    Write-Host ""
    pause
}
