# https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

function Disable-AtlasHighestMode {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
        -AllowedExitCodes ([int[]]@(0))
    if (($bcdEditOutput -join [Environment]::NewLine) -match
        '(?im)^[ \t]*highestmode(?:[ \t]+|$)') {
        Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
            -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'highestmode')) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}

function Enable-AtlasHighestMode {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'highestmode', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
