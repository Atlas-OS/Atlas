# Toggle: New (Windows 8+) boot menu vs. the legacy Windows 7 boot menu (single-launcher menu).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Boot Configuration\Appearance\New Boot Menu.cmd'.
# SilentDefault mirrors the original '/silent goto disable' behavior.
@{
    Name          = 'NewBootMenu'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\New Boot Menu.cmd'
    SilentDefault = 'Disable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            MenuLabel  = 'Disable the new boot menu (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{default}' bootmenupolicy legacy | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            MenuLabel  = 'Enable the new boot menu'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{default}' bootmenupolicy standard 2>$null | Out-Null
            }
        }
    }
}
