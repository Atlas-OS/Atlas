function Invoke-AtlasStoreFixer {
    param($Toggle)

    $storeFixer = Join-Path -Path $Toggle.AtlasModulesPath -ChildPath 'Tools\StoreFixer.exe'
    if (-not (Test-Path -LiteralPath $storeFixer -PathType Leaf)) {
        throw "Required StoreFixer executable is missing: '$storeFixer'."
    }

    if ($Toggle.Silent) {
        Invoke-AtlasToggleNativeCommand -FilePath $storeFixer -ArgumentList ([string[]]@('silent', '-wait')) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
        return
    }

    Write-AtlasStep -Text 'Running StoreFixer. This can take a few minutes...'
    Invoke-AtlasToggleNativeCommand -FilePath $storeFixer -ArgumentList ([string[]]@('-wait')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
