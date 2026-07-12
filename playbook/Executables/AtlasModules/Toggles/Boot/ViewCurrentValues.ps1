# Toggle: View the current boot configuration values (read-only info action).
# Purely prints 'bcdedit /enum {current}' output; records no state.
@{
    Name          = 'ViewCurrentValues'
    Elevation     = 'Admin'
    NoStateRecord = $true
    States        = [ordered]@{
        View = @{
            Launcher        = '6. Advanced Configuration\Boot Configuration\View Current Values.cmd'
            ToolboxLauncher = 'Scripts\viewBootValues.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                $output = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/enum', '{current}')) `
                    -AllowedExitCodes ([int[]]@(0))
                $output | Select-Object -Skip 3 | ForEach-Object { Write-Host $_ }
            }
        }
    }
}
