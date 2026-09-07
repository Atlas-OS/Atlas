# Destination-only handoff. Atlas follows Windows and per-user Store updates.
[CmdletBinding()]
param([switch]$FirstLogon, [switch]$RestoreDesktopPolicy)
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:WINDIR 'AtlasISO'
if ([IO.Path]::GetFullPath($PSScriptRoot) -ine [IO.Path]::GetFullPath($root)) { throw 'Unexpected setup location.' }
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$config = Get-Content -LiteralPath (Join-Path $root 'setup.json') -Raw | ConvertFrom-Json
if ($config.schema -ne 2 -or $config.mode -notin @('interactive', 'configured', 'before-desktop')) { throw 'Unsupported setup configuration.' }
$log = Join-Path $root 'setup.log'
$desktopShell = '"' + (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') + '" -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + (Join-Path $root 'Desktop.ps1') + '"'
. (Join-Path $root 'Desktop-Policy.ps1')
if ($RestoreDesktopPolicy) {
    if ($FirstLogon -or $identity.User.Value -ne 'S-1-5-18' -or $config.mode -ne 'before-desktop') { throw 'Desktop policy cleanup requires the setup SYSTEM task.' }
    $sid = [IO.File]::ReadAllText((Join-Path $root 'account-ready')).Trim()
    $account = Get-LocalUser -Name $config.username
    if ($account.SID.Value -ne $sid) { throw 'The desktop cleanup account does not match setup.' }
    $userHive = [Microsoft.Win32.Registry]::Users.OpenSubKey($sid)
    if (-not $userHive) { throw 'The setup profile is not loaded. Retry cleanup after signing in.' }
    try {
        $key = $userHive.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Policies\System', $true)
        try { Remove-AtlasOwnedShell -Key $key -Shell $desktopShell }
        finally { if ($key) { $key.Dispose() } }
    } finally { $userHive.Dispose() }
    Unregister-AtlasDesktopCleanup $sid
    exit 0
}
if (-not $FirstLogon) {
    if ($identity.User.Value -ne 'S-1-5-18' -or (Get-ItemPropertyValue -LiteralPath 'HKLM:\SYSTEM\Setup' -Name SystemSetupInProgress) -ne 1) {
        throw 'Atlas media setup can run only as SYSTEM during Windows Setup.'
    }
    # Protect the fixed SYSTEM task action and configuration before any user
    # session exists. No reparse point may redirect this owned deployment tree.
    foreach ($item in @((Get-Item -LiteralPath $root -Force)) + @(Get-ChildItem -LiteralPath $root -Force -Recurse)) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Unexpected link in Atlas setup files.' }
    }
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-18')))
    foreach ($sid in @('S-1-5-18', 'S-1-5-32-544', 'S-1-5-32-545')) {
        $rights = if ($sid -eq 'S-1-5-32-545') { 'ReadAndExecute' } else { 'FullControl' }
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule((New-Object Security.Principal.SecurityIdentifier($sid)), $rights, 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
    }
    Set-Acl -LiteralPath $root -AclObject $acl
    if (Test-Path -LiteralPath (Join-Path $root 'DriverPolicy.reg')) {
        & (Join-Path $env:WINDIR 'System32\reg.exe') import (Join-Path $root 'DriverPolicy.reg') | Add-Content -LiteralPath $log -Encoding UTF8
        if ($LASTEXITCODE -ne 0) { throw 'Windows could not apply the ISO driver policy.' }
    }
    $networkDrivers = Join-Path $root 'NetworkDrivers'
    if (Test-Path -LiteralPath $networkDrivers) {
        # Run in specialize, before OOBE needs a network connection. This is
        # independent of the user's Windows Update driver policy.
        & (Join-Path $env:WINDIR 'System32\pnputil.exe') /add-driver (Join-Path $networkDrivers '*.inf') /subdirs /install | Add-Content -LiteralPath $log -Encoding UTF8
        $networkExit = $LASTEXITCODE
        [IO.File]::WriteAllText((Join-Path $root 'network-drivers-result.json'), (@{ schema=1; exitCode=$networkExit; complete=($networkExit -in @(0,3010)) } | ConvertTo-Json -Compress))
        # A driver that does not support the selected Windows build must not
        # abort Windows installation. Keep its files and diagnostics for recovery.
        if ($networkExit -notin @(0,3010)) { 'Network drivers need attention. Driver packages remain in Windows\AtlasISO\NetworkDrivers.' | Add-Content -LiteralPath $log -Encoding UTF8 }
    }
    'Atlas media staged. Updates will run in the destination user session.' | Add-Content -LiteralPath $log -Encoding UTF8
    exit 0
}
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Account initialization requires administrator access.' }
$account = Get-LocalUser -SID $identity.User
if ($account.Name -ine [string]$config.username) { throw 'The setup account does not match the signed-in user.' }
# Disable the bootstrap automatic logon before expiring the empty password.
$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty -LiteralPath $winlogon -Name AutoAdminLogon -Value '0'
Set-ItemProperty -LiteralPath $winlogon -Name AutoLogonCount -Value 0 -Type DWord
Remove-ItemProperty -LiteralPath $winlogon -Name DefaultPassword -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath (Join-Path $root 'account-ready')) { exit 0 }
Set-LocalUser -SID $identity.User -PasswordNeverExpires $false
& (Join-Path $env:WINDIR 'System32\net.exe') user $account.Name /logonpasswordchg:yes | Add-Content -LiteralPath $log -Encoding UTF8
if ($LASTEXITCODE -ne 0) { throw 'Windows could not require a password change for the local account.' }
if ($config.mode -eq 'before-desktop') {
    # Register only after OOBE. A default-profile shell prevents Windows deployment.
    $shellKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
    New-Item -Path $shellKey -Force | Out-Null
    $policy = Get-Item -LiteralPath $shellKey
    try {
        if ($policy.GetValue('Shell')) { throw 'A custom Windows shell is already configured.' }
    } finally { $policy.Dispose() }
    Register-AtlasDesktopCleanup -Sid $identity.User.Value -Root $root
    try {
        [IO.File]::WriteAllText((Join-Path $root 'account-ready'), $identity.User.Value)
        Set-ItemProperty -LiteralPath $shellKey -Name Shell -Value $desktopShell
    } catch {
        Unregister-AtlasDesktopCleanup $identity.User.Value
        Remove-Item -LiteralPath (Join-Path $root 'account-ready') -Force -ErrorAction SilentlyContinue
        throw
    }
}
$runOnce = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
New-Item -Path $runOnce -Force | Out-Null
$command = '"' + (Join-Path $root 'AtlasManager.exe') + '" --playbook "' + (Join-Path $root 'Atlas.apbx') + '"'
if ($config.mode -ne 'before-desktop') {
    New-ItemProperty -LiteralPath $runOnce -Name 'Atlas ISO setup' -Value $command -PropertyType String -Force | Out-Null
}
[IO.File]::WriteAllText((Join-Path $root 'account-ready'), $identity.User.Value)
'Account prepared. Windows will request a new password at sign-in.' | Add-Content -LiteralPath $log -Encoding UTF8
& (Join-Path $env:WINDIR 'System32\shutdown.exe') /l
if ($LASTEXITCODE -ne 0) { throw 'Sign out to finish setting your Windows password.' }
