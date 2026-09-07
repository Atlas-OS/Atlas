function Disable-AtlasKernelParameters {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
        -AllowedExitCodes ([int[]]@(0))
    if (($bcdEditOutput -join [Environment]::NewLine) -match
        '(?im)^[ \t]*optionsedit(?:[ \t]+|$)') {
        Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
            -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'optionsedit')) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}

function Enable-AtlasKernelParameters {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'optionsedit', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
