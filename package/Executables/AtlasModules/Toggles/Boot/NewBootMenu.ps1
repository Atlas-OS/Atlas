# Companion for the NewBootMenu toggle: sets bootmenupolicy to standard or legacy in the boot
# configuration. Its functions run as Administrator when you choose a state from the menu and
# when an update replays the recorded state.

function Disable-AtlasNewBootMenu {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{default}', 'bootmenupolicy', 'legacy')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Enable-AtlasNewBootMenu {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{default}', 'bootmenupolicy', 'standard')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
