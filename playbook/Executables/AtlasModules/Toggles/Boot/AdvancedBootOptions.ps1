function Disable-AtlasAdvancedBootOptions {
    param($Toggle)

    Remove-AtlasToggleBcdValue -WinDir $Toggle.WinDir -Identifier '{globalsettings}' -Element 'advancedoptions'
}

function Enable-AtlasAdvancedBootOptions {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/set', '{globalsettings}', 'advancedoptions', 'true')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
