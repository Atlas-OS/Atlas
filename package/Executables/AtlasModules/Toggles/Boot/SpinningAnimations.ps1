# Companion for the SpinningAnimations toggle: turns the spinning animation setting
# (custom:16000069) on or off in the boot configuration. Its functions run as Administrator
# when you choose a state from the menu and when an update replays the recorded state.

# Microsoft does not document custom:16000069. Community source:
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

    Remove-AtlasToggleBcdValue -WinDir $Toggle.WinDir -Identifier '{globalsettings}' -Element 'custom:16000069'
}
