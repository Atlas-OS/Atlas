function Invoke-AtlasStoreFixer {
    param($Toggle)

    $storeFixer = Join-Path -Path $Toggle.AtlasModulesPath -ChildPath 'Tools\StoreFixer.exe'
    if (-not (Test-Path -LiteralPath $storeFixer -PathType Leaf)) {
        throw "Required StoreFixer executable is missing: '$storeFixer'."
    }

    # The TrustedInstaller broker always runs this silently.
    Invoke-AtlasToggleNativeCommand -FilePath $storeFixer -ArgumentList ([string[]]@('silent', '-wait')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
