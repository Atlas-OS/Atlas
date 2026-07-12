<#
.SYNOPSIS
    Dispatches install-time account setup from TrustedInstaller to the bound user.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..'))
$coreManifest = [IO.Path]::Combine(
    $scriptsRoot,
    'Modules',
    'Atlas.Core',
    'Atlas.Core.psd1'
)
if (-not [IO.File]::Exists($coreManifest)) {
    throw "The Atlas.Core manifest is missing at '$coreManifest'."
}
Import-Module -Name $coreManifest -Force -ErrorAction Stop

Assert-AtlasPrivilege -TrustedInstaller
$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked -or $context.IsOobe) {
    throw 'Installing-user setup requires a non-OOBE active Atlas install state.'
}

$userSid = [string]$context.InteractiveUserSid
if ($userSid -notmatch '^S-\d-\d+(?:-\d+)+$') {
    throw 'Installing-user setup requires a canonical install-state user SID.'
}

$userSetupScript = [IO.Path]::Combine($scriptsRoot, 'Initialize-NewUser.ps1')
$powerShellPath = [IO.Path]::Combine(
    [Environment]::SystemDirectory,
    'WindowsPowerShell',
    'v1.0',
    'powershell.exe'
)
foreach ($requiredFile in @($userSetupScript, $powerShellPath)) {
    if (-not [IO.File]::Exists($requiredFile)) {
        throw "Required installing-user file '$requiredFile' is missing."
    }
}

$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -FromInstall -ExpectedUserSid "{1}"' -f `
    $userSetupScript, $userSid
$exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath -Arguments $arguments
if ($exitCode -ne 0) {
    throw "Installing-user setup exited with code $exitCode."
}
