$ErrorActionPreference = 'Stop'

$target = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\4. Interface Tweaks\Start Menu'
if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    return
}

$resolvedTarget = (Resolve-Path -LiteralPath $target).ProviderPath.TrimEnd('\')
$atlasDesktopRoot = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop'
$resolvedAtlasDesktopRoot = (Resolve-Path -LiteralPath $atlasDesktopRoot).ProviderPath.TrimEnd('\')

if (-not $resolvedTarget.StartsWith($resolvedAtlasDesktopRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove version-specific files from unexpected path '$resolvedTarget'."
}

Get-ChildItem -LiteralPath $resolvedTarget -Filter '*Open-Shell*' -Force -ErrorAction Stop |
    ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction Stop
    }
