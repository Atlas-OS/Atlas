<#
.SYNOPSIS
    Runs one fixed AppX session/cache operation for the exact install-state user.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AppxQuiesce', 'AppxSupport', 'StartMenu')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid
)

$trustBootstrap = Join-Path $PSScriptRoot 'Initialize-PowerShellTrust.ps1'
$manifestPath = Join-Path $PSScriptRoot '..\Modules\Atlas.Appx\Atlas.Appx.psd1'
$sessionProcessHelper = Join-Path $PSScriptRoot 'Invoke-AtlasUserShellRefresh.ps1'
foreach ($requiredFile in @($trustBootstrap, $manifestPath, $sessionProcessHelper)) {
    if (-not [IO.File]::Exists($requiredFile)) {
        throw "Required AppX cache helper file is missing: '$requiredFile'."
    }
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
Microsoft.PowerShell.Core\Import-Module -Name $manifestPath -Force -ErrorAction Stop

$sessionOperation = switch -CaseSensitive ($Mode) {
    'StartMenu' { 'StartMenuRefresh' }
    'AppxSupport' { 'AppxQuiesce' }
    'AppxQuiesce' { 'AppxQuiesce' }
    default { throw "Unsupported exact-user AppX operation '$Mode'." }
}
& $sessionProcessHelper -Operation $sessionOperation -ExpectedUserSid $ExpectedUserSid

if ($Mode -ceq 'AppxQuiesce') {
    return
}

Clear-AtlasAppxCache -Mode $Mode -ExpectedUserSid $ExpectedUserSid
