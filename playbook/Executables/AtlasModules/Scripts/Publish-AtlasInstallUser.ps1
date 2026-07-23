[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$stateManifest = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1'
Import-Module -Name $stateManifest -Force -DisableNameChecking -ErrorAction Stop

$state = Get-AtlasInstallState
if ($null -eq $state) {
    throw 'No active Atlas install state is available to publish the install user.'
}
if ([bool]$state.isOobe) {
    throw 'OOBE installs do not publish an interactive-user marker.'
}
$nonce = [string]$state.captureNonce
if ($nonce -notmatch '^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$') {
    throw 'The active install state contains an invalid capture nonce.'
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if ($null -eq $identity.User) {
    throw 'The current user token has no Windows SID.'
}
$userSid = $identity.User.Value
$sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
if ($sessionId -lt 1) {
    throw 'The current-user publisher is not running in an interactive Windows session.'
}

$markerPath = 'Software\AtlasOS\InstallSession'
$marker = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($markerPath)
if ($null -eq $marker) {
    throw "Could not create HKCU\$markerPath."
}
try {
    $marker.SetValue('Nonce', $nonce, [Microsoft.Win32.RegistryValueKind]::String)
    $marker.SetValue('UserSid', $userSid, [Microsoft.Win32.RegistryValueKind]::String)
    $marker.SetValue('SessionId', $sessionId, [Microsoft.Win32.RegistryValueKind]::DWord)

    if ([string]$marker.GetValue('Nonce') -cne $nonce -or
        [string]$marker.GetValue('UserSid') -cne $userSid -or
        [int]$marker.GetValue('SessionId') -ne $sessionId) {
        throw 'The current-user install marker failed its readback check.'
    }
}
finally {
    $marker.Dispose()
}

Write-Output "Published Atlas install user $userSid in session $sessionId."
