# Toggle: New (Windows 8+) boot menu vs. the legacy Windows 7 boot menu (single-launcher menu).
@{
    Name          = 'NewBootMenu'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\New Boot Menu.cmd'
    SilentDefault = 'Disable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable the new boot menu (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{default}', 'bootmenupolicy', 'legacy')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable the new boot menu'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{default}', 'bootmenupolicy', 'standard')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
    }
}
