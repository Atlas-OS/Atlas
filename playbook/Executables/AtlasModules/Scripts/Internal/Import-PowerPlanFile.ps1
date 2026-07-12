<#
.SYNOPSIS
    Imports one validated .pow file through the inbox powercfg executable.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$PowerPlanPath
)

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not [IO.Path]::IsPathRooted($PowerPlanPath) -or $PowerPlanPath.Length -gt 32767) {
    throw 'The power-plan path must be one bounded absolute path.'
}
$canonicalPath = [IO.Path]::GetFullPath($PowerPlanPath)
if (-not [IO.Path]::GetExtension($canonicalPath).Equals('.pow', [StringComparison]::OrdinalIgnoreCase)) {
    throw "The selected file is not a .pow power plan: '$canonicalPath'."
}
if (-not [IO.File]::Exists($canonicalPath)) {
    throw "The selected power-plan file does not exist: '$canonicalPath'."
}
$attributes = [IO.File]::GetAttributes($canonicalPath)
if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "The selected power-plan file is a reparse point: '$canonicalPath'."
}

$powerCfgPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'powercfg.exe')
if (-not [IO.File]::Exists($powerCfgPath)) {
    throw "The inbox powercfg executable is missing at '$powerCfgPath'."
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    & $powerCfgPath /import $canonicalPath
    if ($LASTEXITCODE -ne 0) {
        throw "powercfg.exe failed to import the power plan with exit code $LASTEXITCODE."
    }
    return
}

# The path remains a process argument. Windows file names cannot contain a quote, so
# quoting the canonical value is sufficient for ProcessStartInfo's argument string.
$result = Start-Process -FilePath $powerCfgPath `
    -ArgumentList @('/import', ('"{0}"' -f $canonicalPath)) `
    -Verb RunAs `
    -Wait `
    -PassThru
if ($result.ExitCode -ne 0) {
    throw "Elevated powercfg.exe failed to import the power plan with exit code $($result.ExitCode)."
}
