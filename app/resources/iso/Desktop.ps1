# Opens Atlas before presenting the desktop. Never runs on the ISO host.
[CmdletBinding()]
param([switch]$RestoreDesktop, [switch]$Detached)
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:WINDIR 'AtlasISO'
if ([IO.Path]::GetFullPath($PSScriptRoot) -ine [IO.Path]::GetFullPath($root)) { throw 'Unexpected desktop setup location.' }
$policyPath = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
$shell = '"' + (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') + '" -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + (Join-Path $root 'Desktop.ps1') + '"'
$state = 'HKCU:\Software\AtlasOS\DesktopSetup'
. (Join-Path $root 'Desktop-Policy.ps1')
function Start-AtlasWindowsShell {
    # Explorer must run as the unelevated signed-in user. Its shell services are
    # required for Settings, Windows Security and Store app activation on Pro.
    # Atlas covers the desktop; this is an onboarding flow, not a kiosk lock.
    $session = [Diagnostics.Process]::GetCurrentProcess().SessionId
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session)) {
        Start-Process -FilePath (Join-Path $env:WINDIR 'explorer.exe')
    }
}
function Restore-AtlasDesktop {
    try {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($policyPath)
        try { $ownedShell = $key -and [string]::Equals([string]$key.GetValue('Shell'), $shell, [StringComparison]::Ordinal) }
        finally { if ($key) { $key.Dispose() } }
        if (-not $ownedShell) { return }
        Request-AtlasDesktopCleanup ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
        $deadline = [DateTime]::UtcNow.AddSeconds(15)
        do {
            Start-Sleep -Milliseconds 200
            $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($policyPath)
            try { $ownedShell = $key -and [string]::Equals([string]$key.GetValue('Shell'), $shell, [StringComparison]::Ordinal) }
            finally { if ($key) { $key.Dispose() } }
        } while ($ownedShell -and [DateTime]::UtcNow -lt $deadline)
        if ($ownedShell) { throw 'Atlas desktop policy cleanup did not finish. Retry Desktop.ps1 -RestoreDesktop.' }
    }
    catch {
        [IO.File]::WriteAllText((Join-Path $env:LOCALAPPDATA 'Atlas-desktop-recovery.log'), ($_ | Out-String))
    }
    finally { Start-AtlasWindowsShell }
}
if ($RestoreDesktop) { Restore-AtlasDesktop; exit }
if (-not $Detached) {
    try {
        # WindowStyle Hidden still opens the default terminal and blocks its Store
        # update. Relaunch without a console, then release the original terminal.
        $start = New-Object Diagnostics.ProcessStartInfo
        $start.FileName = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $start.Arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -Detached'
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $process = [Diagnostics.Process]::Start($start)
        $process.Dispose()
    } catch {
        [IO.File]::WriteAllText((Join-Path $env:LOCALAPPDATA 'Atlas-desktop-recovery.log'), ($_ | Out-String))
        Restore-AtlasDesktop
    }
    exit
}
$mutex = New-Object Threading.Mutex($false, ('Local\AtlasOS.DesktopSetup.' + [Diagnostics.Process]::GetCurrentProcess().SessionId))
$owned = $false
try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
if (-not $owned) {
    # Explorer recovery can ask Windows to start the configured shell again.
    # Leave the existing supervisor and its recovery policy alone.
    $mutex.Dispose()
    exit
}
try {
    # FirstLogonCommands prepares the account and signs out. Do not show Explorer
    # during that bootstrap, or run updates before the user's native password change.
    $marker = Join-Path $root 'account-ready'
    $deadline = [DateTime]::UtcNow.AddMinutes(3)
    $bootstrap = -not (Test-Path -LiteralPath $marker)
    while (-not (Test-Path -LiteralPath $marker)) {
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Account preparation timed out.' }
        Start-Sleep -Seconds 1
    }
    if ($bootstrap) { Start-Sleep -Seconds 60; throw 'Account preparation did not sign out.' }
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if ([IO.File]::ReadAllText($marker).Trim() -ne $sid) { throw 'This account does not own Atlas setup.' }
    New-Item -Path $state -Force | Out-Null
    Remove-ItemProperty -LiteralPath $state -Name RestartRequested -ErrorAction SilentlyContinue
    $app = Join-Path $root 'AtlasManager.exe'
    if (-not (Test-Path -LiteralPath $app)) { throw 'The Atlas setup app is missing.' }
    # The real user's elevated interactive token is required by both providers.
    # Declining UAC returns to the desktop, without changing the update result.
    $child = Start-Process -FilePath $app -ArgumentList '--before-desktop' -Verb RunAs -PassThru
    # Let the full-screen app appear before starting the normal shell behind it.
    # A failed or hung app must still leave access to Windows.
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        $child.Refresh()
        if ($child.HasExited -or $child.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 200
    } while ([DateTime]::UtcNow -lt $deadline)
    Start-AtlasWindowsShell
    # Wait for Atlas itself. Settings or help windows may outlive it and must
    # not prevent the user from returning to the desktop.
    $child.WaitForExit()
    $intent = Get-ItemProperty -LiteralPath $state -ErrorAction SilentlyContinue
    if ($intent -and $intent.PSObject.Properties['RestartRequested']) {
        $requested = [DateTimeOffset]::FromUnixTimeSeconds([long]$intent.RestartRequested)
        if (([DateTimeOffset]::UtcNow - $requested).TotalSeconds -lt 120) {
            # Windows closes the app before shutting down. Keep the shell policy
            # until the next sign-in instead of mistaking this for a user exit.
            Start-Sleep -Seconds 60
        }
    }
    if ($child.ExitCode -ne 0) { throw "Atlas exited with code $($child.ExitCode)." }
}
catch {
    # A broken app, declined elevation or bootstrap failure must leave a usable PC.
    [IO.File]::WriteAllText((Join-Path $env:LOCALAPPDATA 'Atlas-desktop-recovery.log'), ($_ | Out-String))
}
finally {
    try { Restore-AtlasDesktop }
    finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
}
