# Companion of add-newUser-script.psd1: creates the marker key that Initialize-NewUser.ps1
# (registered in RunOnce) uses to track per-user setup, granting the built-in Users
# group (S-1-5-32-545) read/write access so non-admin accounts can record their state.
# CreateSubKey is required: the registry provider behind Set-ItemProperty opens keys
# with KEY_WRITE (SetValue + CreateSubKey), so SetValue alone is denied.
$ErrorActionPreference = 'Stop'

$markerPath = 'HKLM:\SOFTWARE\AtlasOS\UserSetup'
$null = New-Item -Path $markerPath -Force

$acl = Get-Acl -Path $markerPath
$users = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-32-545'
$rule = New-Object -TypeName System.Security.AccessControl.RegistryAccessRule -ArgumentList @(
    $users,
    [System.Security.AccessControl.RegistryRights]'ReadKey, SetValue, CreateSubKey',
    [System.Security.AccessControl.AccessControlType]::Allow
)
$acl.SetAccessRule($rule)
Set-Acl -Path $markerPath -AclObject $acl

$installLogsPath = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Logs'
if (Test-Path -LiteralPath $installLogsPath -PathType Container)
{
    & icacls.exe $installLogsPath /grant '*S-1-5-32-545:(OI)(CI)M' /T | Out-Null
}
