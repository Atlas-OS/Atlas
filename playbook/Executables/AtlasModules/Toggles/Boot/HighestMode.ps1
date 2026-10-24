# highestmode: https://learn.microsoft.com/windows-hardware/drivers/devtest/bcdedit--set#display-settings

function Disable-AtlasHighestMode {
    param($Toggle)

    Remove-AtlasToggleBcdValue -WinDir $Toggle.WinDir -Identifier '{globalsettings}' -Element 'highestmode'
}

function Enable-AtlasHighestMode {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'highestmode', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
