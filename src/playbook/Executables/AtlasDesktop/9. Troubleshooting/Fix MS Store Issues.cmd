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
$MaxRetries = 5
$FileDeleted = $false

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
# Retry loop: Attempt file deletion up to 5 times
# ============================================================
for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
    if ($attempt -gt 1) {
        Write-Host "`n=== RETRY ATTEMPT $attempt of $MaxRetries ===" -ForegroundColor Yellow
        Write-Host "Waiting 5 seconds before retry..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
    else {
        Write-Host "`n=== ATTEMPT $attempt of $MaxRetries ===" -ForegroundColor Cyan
    }

    # ============================================================
    # 1. Collect every service and save original start types
    # ============================================================
    Write-Host "`n=== Collecting services and saving original start types ===" -ForegroundColor Cyan
    Write-Host "DO NOT CLOSE THIS SCRIPT!!!!" -ForegroundColor Red

    $allServiceNames = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    try {
        foreach ($root in $RootServices) {
            $rootService = Get-Service -Name $root -ErrorAction Stop
            [void]$allServiceNames.Add($root)
            foreach ($dep in (Get-AllDependents $root)) {
                [void]$allServiceNames.Add($dep)
            }
        }
    }
    catch {
        Write-Host "ERROR: Failed to enumerate services: $($_.Exception.Message)" -ForegroundColor Red
        if ($attempt -lt $MaxRetries) { continue }
    }

    $originalStartTypes = @{}
    try {
        foreach ($svc in $allServiceNames) {
            $startType = (Get-Service -Name $svc -ErrorAction Stop).StartType
            $originalStartTypes[$svc] = $startType
            Write-Host "  $svc  ->  StartType = $startType"
        }
    }
    catch {
        Write-Host "ERROR: Failed to get service start types: $($_.Exception.Message)" -ForegroundColor Red
        if ($attempt -lt $MaxRetries) { continue }
    }

    $hasFailed = $false

    try {

        # ========================================================
        # 2. Disable every service
        # ========================================================
        Write-Host "`n=== Disabling all services ===" -ForegroundColor Cyan

        $setSvc = "$env:SYSTEMROOT\AtlasModules\Scripts\setSvc.cmd"

        foreach ($svc in $allServiceNames) {
            try {
                & $setSvc $svc 4 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "setSvc.cmd returned exit code $LASTEXITCODE" }
                Write-Host "  Disabled: $svc"
            }
            catch {
                Write-Host "  Warning: Failed to disable $svc - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # ========================================================
        # 3. Stop every service — dependents first, then roots
        # ========================================================
        Write-Host "`n=== Stopping all services ===" -ForegroundColor Cyan

        $dependentsOnly = $allServiceNames | Where-Object { $_ -notin $RootServices }

        foreach ($name in $dependentsOnly) {
            $s = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($null -eq $s -or $s.Status -eq 'Stopped') { continue }
            Write-Host "  Stopping dependent: $name ..."
            try { 
                $s.Stop()
                $s.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(3))
                Write-Host "    STOPPED: $name"
            } catch {
                Write-Host "    Warning: Could not stop $name" -ForegroundColor Yellow
            }
        }

        foreach ($name in $RootServices) {
            $s = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($null -eq $s -or $s.Status -eq 'Stopped') { continue }
            Write-Host "  Stopping root service: $name ..."
            try { 
                $s.Stop()
                $s.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(3))
                Write-Host "    STOPPED: $name"
            } catch {
                Write-Host "    Warning: Could not stop $name" -ForegroundColor Yellow
            }
        }

        Write-Host "  Waiting for services to stabilize ..."
        Start-Sleep -Seconds 2

        # ========================================================
        # 4. Delete the target file
        # ========================================================
        Write-Host "`n=== Attempting file deletion ===" -ForegroundColor Cyan
        
        if (Test-Path -LiteralPath $TargetFile) {
            try {
                Remove-Item -LiteralPath $TargetFile -Force -ErrorAction Stop
                Write-Host "  Deleted: $TargetFile" -ForegroundColor Green
                $FileDeleted = $true
            }
            catch {
                Write-Host "  ERROR: Could not delete file - $($_.Exception.Message)" -ForegroundColor Red
                throw $_
            }
        }
        else {
            Write-Host "  File not found (already absent): $TargetFile" -ForegroundColor Yellow
            $FileDeleted = $true
        }

    }
    catch {
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        $hasFailed = $true
    }
    finally {

        # ========================================================
        # 5. ALWAYS restore original start types
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
            try {
                $origValue = $originalStartTypes[$svc]
                $startValue = $startTypeMap[$origValue.ToString()]
                if ($null -eq $startValue) {
                    Write-Host "  Warning: Unknown start type for ${svc}: '$origValue'" -ForegroundColor Yellow
                    continue
                }
                & $setSvc $svc $startValue 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Restored: $svc  ->  $origValue"
                }
            }
            catch {
                Write-Host "  Warning: Failed to restore $svc" -ForegroundColor Yellow
            }
        }

        # ========================================================
        # 6. Start StateRepository back up
        # ========================================================
        Write-Host "`n=== Starting StateRepository ===" -ForegroundColor Cyan
        try {
            $sr = Get-Service -Name 'StateRepository' -ErrorAction Stop
            if ($sr.Status -eq 'Stopped') {
                $sr.Start()
                $sr.WaitForStatus('Running', [TimeSpan]::FromSeconds(5))
            }
            Write-Host "  StateRepository is running." -ForegroundColor Green
        }
        catch {
            Write-Host "  Warning: Could not start StateRepository" -ForegroundColor Yellow
        }
    }

    if ($FileDeleted) {
        Write-Host "`n=== File successfully deleted on attempt $attempt ===" -ForegroundColor Green
        break
    } elseif ($attempt -lt $MaxRetries) {
        Write-Host "`n!!! Will retry (attempt $attempt of $MaxRetries)..." -ForegroundColor Yellow
    }
}

if ($FileDeleted) {
    # ========================================================
    # 7. Run wsreset.exe to reinstall Store
    # ========================================================
    Write-Host "`n=== Running wsreset.exe -i (this may take a moment) ===" -ForegroundColor Cyan
    try {
        $wsresetProcess = Start-Process -FilePath 'wsreset.exe' -ArgumentList '-i' -PassThru -Wait -ErrorAction Stop
        if ($wsresetProcess.ExitCode -ne 0) {
            Write-Host "  wsreset.exe -i exited with code $($wsresetProcess.ExitCode)" -ForegroundColor Yellow
        } else {
            Write-Host "  wsreset.exe -i completed successfully." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Warning: Could not run wsreset.exe" -ForegroundColor Yellow
    }

    Write-Host "`n=== Done. ===" -ForegroundColor Green
}
else {
    Write-Host "`n=== REGISTRY FALLBACK: Attempting Store repair via Registry ===" -ForegroundColor Yellow
    
    try {
        # Reset the Store app package state
        Write-Host "Clearing Store package cache and resetting settings..." -ForegroundColor Cyan
        
        $regPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache'
        )
        
        foreach ($regPath in $regPaths) {
            if (Test-Path -Path $regPath) {
                try {
                    Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  Cleared: $regPath"
                }
                catch {
                    Write-Host "  Could not clear $regPath (non-critical)" -ForegroundColor Yellow
                }
            }
        }
        
        # Restart Store related services
        Write-Host "`nRestarting Store services..." -ForegroundColor Cyan
        foreach ($svc in @('AppXSvc', 'ClipSVC', 'StateRepository')) {
            try {
                $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
                if ($null -ne $s) {
                    if ($s.Status -eq 'Running') {
                        $s.Stop()
                        $s.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(3))
                    }
                    $s.Start()
                    $s.WaitForStatus('Running', [TimeSpan]::FromSeconds(3))
                    Write-Host "  Restarted: $svc"
                }
            }
            catch {
                Write-Host "  Could not restart $svc" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`n=== Registry fallback completed. Store should regenerate. ===" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR during registry fallback: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Write-Host "`n=== Finished (file deletion ultimately failed after $MaxRetries attempts) ===" -ForegroundColor Yellow
    }
}

Stop-Transcript | Out-Null
Write-Host "  Log saved to: $LogFile"

if (-not $Silent) {
    Write-Host ""
    pause
}
