function Show-AtlasBootValues {
    param($Toggle)

    $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
    $output = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
        -ArgumentList ([string[]]@('/enum', '{current}')) `
        -AllowedExitCodes ([int[]]@(0))
    Write-AtlasNote -Text ([string[]]@($output | Select-Object -Skip 3 | ForEach-Object { [string]$_ }))
}
