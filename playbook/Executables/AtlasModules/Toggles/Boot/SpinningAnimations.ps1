# https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

function Disable-AtlasSpinningAnimations {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'custom:16000069', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Enable-AtlasSpinningAnimations {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
        -AllowedExitCodes ([int[]]@(0))
    if (($bcdEditOutput -join [Environment]::NewLine) -match
        '(?im)^[ \t]*custom:16000069(?:[ \t]+|$)') {
        Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
            -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'custom:16000069')) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}
