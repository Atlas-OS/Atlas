# Companion for the KernelParameters toggle: sets or removes optionsedit in the boot
# configuration. Its functions run as Administrator when you choose a state from the menu and
# when an update replays the recorded state.

function Disable-AtlasKernelParameters {
    param($Toggle)

    Remove-AtlasToggleBcdValue -WinDir $Toggle.WinDir -Identifier '{globalsettings}' -Element 'optionsedit'
}

function Enable-AtlasKernelParameters {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'optionsedit', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
