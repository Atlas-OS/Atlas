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
