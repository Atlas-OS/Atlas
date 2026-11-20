<#
.SYNOPSIS
    Publishes the installing user's identity for the TrustedInstaller Run phase.
.DESCRIPTION
    Entry\Install-Atlas.ps1 runs this script in its own process, as the signed-in
    user, between the Capture and Run phases. It writes the capture's
    nonce, the user's SID and the Windows session to HKCU\Software\AtlasOS\InstallSession
    and reads them back. The Run phase binds the user whose loaded hive carries that
    nonce, then removes the marker.
.NOTES
    Throws on any failure, so the front door stops with its install-failure exit code.
#>
[CmdletBinding()]
param()

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) { throw "The PowerShell bootstrap is missing at '$bootstrap'." }
. $bootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$stateManifest = Join-Path -Path $scriptsRoot `
    -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1'
Import-Module -Name $stateManifest -Force -DisableNameChecking -ErrorAction Stop

$state = Get-AtlasInstallState
if ($null -eq $state) {
    throw 'No active Atlas install state is available to publish the install user.'
}
$nonce = [string]$state.captureNonce
if ($nonce -notmatch '^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$') {
    throw 'The active install state contains an invalid capture nonce.'
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if ($null -eq $identity.User) {
    throw 'The current user token has no Windows SID.'
}
# The install plan's per-user steps accept only account SIDs, which Entra ID accounts lack.
if (-not $identity.User.IsAccountSid()) {
    throw "Atlas can't be installed from a work or school (Microsoft Entra ID) account. Sign in with a local account or a Microsoft account, then try again."
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
