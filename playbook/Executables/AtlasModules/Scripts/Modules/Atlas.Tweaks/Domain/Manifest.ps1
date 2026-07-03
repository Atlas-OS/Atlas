# Atlas.Tweaks domain: tweak manifest loading.
#
# The manifest (Scripts\Tweaks\tweaks.manifest.psd1) defines category order and the
# tweak files inside each category; disabling a tweak = commenting out its line.

function Get-AtlasTweakManifest {
    <#
    .SYNOPSIS
        Loads the tweak manifest: @{ Categories = @(@{ Name = 'networking';
        Tweaks = @('relative/tweak-file-name-without-ext', ...) }, ...) }.
    #>
    param(
        [string]$Path
    )

    if (-not $Path) {
        $Path = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Tweaks\tweaks.manifest.psd1'
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Tweak manifest not found: '$Path'."
    }

    $manifest = Import-AtlasDataFile -LiteralPath $Path
    if (-not $manifest.ContainsKey('Categories')) {
        throw "Tweak manifest '$Path' has no 'Categories' key."
    }

    return $manifest
}
