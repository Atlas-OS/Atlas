# https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

function Disable-AtlasBootLogo {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'custom:16000067', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Enable-AtlasBootLogo {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
        -AllowedExitCodes ([int[]]@(0))
    if (($bcdEditOutput -join [Environment]::NewLine) -match
        '(?im)^[ \t]*custom:16000067(?:[ \t]+|$)') {
        Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
            -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'custom:16000067')) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}
