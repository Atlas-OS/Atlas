# Companion for the AutomaticRepair toggle: sets bootstatuspolicy in the boot configuration.
# Its functions run as Administrator when you choose a state from the menu and when an update
# replays the recorded state.

# bootstatuspolicy: https://learn.microsoft.com/windows-hardware/drivers/devtest/bcdedit--set#boot-settings

function Disable-AtlasAutomaticRepair {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{current}', 'bootstatuspolicy', 'IgnoreAllFailures')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}

function Enable-AtlasAutomaticRepair {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{current}', 'bootstatuspolicy', 'DisplayAllFailures')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
