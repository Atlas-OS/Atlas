<#
.SYNOPSIS
    Runs one fixed AppX session/cache operation for the exact install-state user.
.DESCRIPTION
    Atlas.Appx starts it during the install in the installing user's non-elevated token.
    It first stops the user's processes that hold the packages, through
    Invoke-AtlasUserShellRefresh.ps1, then clears that user's AppX caches for the mode.
.PARAMETER Mode
    AppxQuiesce only stops Teams and Search. AppxSupport also clears the package caches of
    Client.CBS, Windows Search and Windows Security. StartMenu restarts the Start menu
    and clears its package cache.
.PARAMETER ExpectedUserSid
    The SID of the user the install recorded; the script stops if its token differs.
.NOTES
    Exit codes:
    0       Done.
    1       The cache cleanup failed, or a helper file is missing.
    10-17   Invoke-AtlasUserShellRefresh.ps1 failed; the code names its stage.
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

$trustBootstrap = Join-Path (Split-Path -Parent $PSScriptRoot) 'Initialize-AtlasPowerShell.ps1'
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

# The helper reports failure only through its exit code. Run with &, its exit
# ends only the helper, so pass the code on as this process's exit code.
$global:LASTEXITCODE = 0
& $sessionProcessHelper -Operation $sessionOperation -ExpectedUserSid $ExpectedUserSid
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($Mode -ceq 'AppxQuiesce') {
    return
}

Clear-AtlasAppxCache -Mode $Mode -ExpectedUserSid $ExpectedUserSid
