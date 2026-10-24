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
# ends just the helper, so pass the code on as this process's exit code.
$global:LASTEXITCODE = 0
& $sessionProcessHelper -Operation $sessionOperation -ExpectedUserSid $ExpectedUserSid
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($Mode -ceq 'AppxQuiesce') {
    return
}

Clear-AtlasAppxCache -Mode $Mode -ExpectedUserSid $ExpectedUserSid
