# Toggle: Repair Windows components / system files (DISM RestoreHealth + SFC, no state).
@{
    Name          = 'RepairWindowsComponents'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Warning       = "This will repair and replace any corrupt Windows components and system files.`nFor general issues, this might be a fix. Note that no components of Atlas is reverted with this."
    States        = [ordered]@{
        Run = @{
            Launcher        = '9. Troubleshooting\Repair Windows Components.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Repair Windows Components.cmd'
            Reboot          = 'Recommend'
            Action          = {
                param($Toggle)

                $dashes = '----------------------------------------------'
                Write-Host 'This might take a while.'

                Write-Host ''
                Write-Host $dashes
                Write-Host 'Restoring the component store...'
                Write-Host $dashes
                $system32 = Join-Path $Toggle.WinDir 'System32'
                [void](Invoke-AtlasToggleNativeCommand `
                        -FilePath (Join-Path $system32 'dism.exe') `
                        -ArgumentList @(
                            '/Online'
                            '/Cleanup-Image'
                            '/RestoreHealth'
                            '/NoRestart'
                        ) `
                        -AllowedExitCodes @(0))

                Write-Host ''
                Write-Host $dashes
                Write-Host 'Restoring system files...'
                Write-Host $dashes
                [void](Invoke-AtlasToggleNativeCommand `
                        -FilePath (Join-Path $system32 'sfc.exe') `
                        -ArgumentList @('/scannow') `
                        -AllowedExitCodes @(0))
            }
        }
    }
}
