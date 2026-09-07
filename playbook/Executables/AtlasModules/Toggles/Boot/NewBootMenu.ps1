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
