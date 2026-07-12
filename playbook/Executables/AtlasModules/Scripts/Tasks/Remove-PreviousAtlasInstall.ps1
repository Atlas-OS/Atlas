[CmdletBinding()]
param()

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', 'Internal', 'Initialize-PowerShellTrust.ps1'
    ))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$ErrorActionPreference = 'Stop'

$windowsPath = [Environment]::GetFolderPath('Windows')
if ([string]::IsNullOrWhiteSpace($windowsPath) -or -not (Test-Path -LiteralPath $windowsPath -PathType Container)) {
    throw "Windows directory '$windowsPath' is not available."
}

$resolvedWindowsPath = (Resolve-Path -LiteralPath $windowsPath).ProviderPath.TrimEnd('\')
foreach ($childName in @('AtlasDesktop', 'AtlasModules')) {
    $target = Join-Path -Path $resolvedWindowsPath -ChildPath $childName
    if (-not (Test-Path -LiteralPath $target)) {
        continue
    }

    $resolvedTarget = (Resolve-Path -LiteralPath $target).ProviderPath.TrimEnd('\')
    if (-not $resolvedTarget.StartsWith($resolvedWindowsPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove unexpected Atlas path '$resolvedTarget'."
    }

    Remove-Item -LiteralPath $resolvedTarget -Force -Recurse -ErrorAction Stop
}
