function Disable-AtlasAdvancedBootOptions {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
        -AllowedExitCodes ([int[]]@(0))
    if (($bcdEditOutput -join [Environment]::NewLine) -match
        '(?im)^[ \t]*advancedoptions(?:[ \t]+|$)') {
        Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
            -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'advancedoptions')) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}

function Enable-AtlasAdvancedBootOptions {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'advancedoptions', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
