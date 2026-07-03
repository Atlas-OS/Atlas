<#
.SYNOPSIS
    Single entry point for all Atlas install phases, invoked by the YAML shim
    (Configuration/custom.yml) once per phase.
.DESCRIPTION
    Exit code contract (consumed by AME Wizard via handleExitCodes):
      0 - success (possibly with logged warnings)
      1 - fatal error
      2 - wrong execution context (privilege assertion failed)
      3 - unsupported environment
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('PreInstall', 'Environment', 'Features', 'Software', 'Services',
        'Components', 'AppxSupport', 'Tweaks', 'Defaults', 'Revert', 'Finalize')]
    [string]$Phase,

    [string]$Category
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')
Import-Module Atlas.Core -Force

Start-AtlasPhase -Phase $Phase -Category $Category
try {
    $phaseScript = Join-Path -Path $PSScriptRoot -ChildPath "Phases\Invoke-${Phase}Phase.ps1"
    if (-not (Test-Path -LiteralPath $phaseScript -PathType Leaf)) {
        throw "Phase script not found: '$phaseScript'."
    }

    $phaseArgs = @{}
    if ($Category) {
        $phaseArgs['Category'] = $Category
    }

    & $phaseScript @phaseArgs
    exit 0
}
catch {
    $isPrivilegeError = $_.Exception.Message -like '`[privilege`]*'
    Write-AtlasLog -Level Error -Message $_.Exception.Message -ErrorRecord $_

    if ($isPrivilegeError) {
        exit 2
    }
    exit 1
}
finally {
    Stop-AtlasPhase
}
