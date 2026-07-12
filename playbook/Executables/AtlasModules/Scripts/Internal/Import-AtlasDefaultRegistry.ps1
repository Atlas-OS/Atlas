<#
.SYNOPSIS
    Imports Atlas's bundled default toggle-state registry seed.
#>
[CmdletBinding()]
param()

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$defaultRegistryPath = [IO.Path]::GetFullPath(
    [IO.Path]::Combine($PSScriptRoot, '..', '..', '..', 'DEFAULT.reg')
)
if (-not [IO.File]::Exists($defaultRegistryPath)) {
    throw "The Atlas default registry seed is missing at '$defaultRegistryPath'."
}

$regExePath = [IO.Path]::Combine([Environment]::SystemDirectory, 'reg.exe')
if (-not [IO.File]::Exists($regExePath)) {
    throw "The inbox registry executable is missing at '$regExePath'."
}

& $regExePath import $defaultRegistryPath | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "DEFAULT.reg import failed with exit code '$LASTEXITCODE'."
}
