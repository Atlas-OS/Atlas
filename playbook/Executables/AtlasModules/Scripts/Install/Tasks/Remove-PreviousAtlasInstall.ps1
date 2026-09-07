[CmdletBinding()]
param()

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', '..', 'Initialize-AtlasPowerShell.ps1'
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

    # These files describe this device before Atlas changed its services. They
    # cannot be recreated from the already optimized installation.
    $backupNames = @('winServices.reg', 'atlasServices.reg')
    $otherPath = Join-Path $resolvedTarget 'Other'
    $backups = @()
    if ($childName -eq 'AtlasModules' -and (Test-Path -LiteralPath $otherPath -PathType Container)) {
        $other = Get-Item -LiteralPath $otherPath -Force
        if ($other.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to preserve service backups through a reparse point at '$otherPath'."
        }
        $backups = @(Get-ChildItem -LiteralPath $otherPath -Force | Where-Object {
            -not $_.PSIsContainer -and $backupNames -contains $_.Name -and
            -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
        })
    }
    if ($backups.Count -eq 0) {
        Remove-Item -LiteralPath $resolvedTarget -Force -Recurse -ErrorAction Stop
        continue
    }

    # Keep backups in place across interruption; the new payload merges into
    # these directories without carrying forward any old executable scripts.
    foreach ($item in Get-ChildItem -LiteralPath $resolvedTarget -Force) {
        if ($item.FullName -eq $otherPath) { continue }
        $resolvedItem = (Resolve-Path -LiteralPath $item.FullName).ProviderPath
        if (-not $resolvedItem.StartsWith($resolvedTarget + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected Atlas path '$resolvedItem'."
        }
        Remove-Item -LiteralPath $resolvedItem -Force -Recurse -ErrorAction Stop
    }
    foreach ($item in Get-ChildItem -LiteralPath $otherPath -Force) {
        if ($backups.FullName -contains $item.FullName) { continue }
        $resolvedItem = (Resolve-Path -LiteralPath $item.FullName).ProviderPath
        if (-not $resolvedItem.StartsWith($otherPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected Atlas path '$resolvedItem'."
        }
        Remove-Item -LiteralPath $resolvedItem -Force -Recurse -ErrorAction Stop
    }
}
