# https://winaero.com/how-to-disable-automatic-repair-at-windows-10-boot

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
