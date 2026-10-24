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
