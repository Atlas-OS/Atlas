# Companion for the BootLogo toggle: turns the boot logo setting (custom:16000067) on or off
# in the boot configuration. Its functions run as Administrator when you choose a state from
# the menu and when an update replays the recorded state.

# Microsoft does not document custom:16000067. Community source:
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

    Remove-AtlasToggleBcdValue -WinDir $Toggle.WinDir -Identifier '{globalsettings}' -Element 'custom:16000067'
}
