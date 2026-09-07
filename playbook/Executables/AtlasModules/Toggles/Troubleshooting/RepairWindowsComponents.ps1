function Repair-AtlasWindowsComponents {
    param($Toggle)

    $system32 = Join-Path -Path $Toggle.WinDir -ChildPath 'System32'

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Repairing the component store with DISM. This can take a long time...'
    }
    [void](Invoke-AtlasToggleNativeCommand -FilePath (Join-Path -Path $system32 -ChildPath 'dism.exe') `
            -ArgumentList ([string[]]@('/Online', '/Cleanup-Image', '/RestoreHealth', '/NoRestart')) `
            -AllowedExitCodes ([int[]]@(0)))

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Repairing system files with SFC. This can take a while...'
    }
    [void](Invoke-AtlasToggleNativeCommand -FilePath (Join-Path -Path $system32 -ChildPath 'sfc.exe') `
            -ArgumentList ([string[]]@('/scannow')) `
            -AllowedExitCodes ([int[]]@(0)))
}
