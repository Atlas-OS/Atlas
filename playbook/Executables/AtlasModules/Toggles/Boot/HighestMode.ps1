# Toggle: Highest graphical mode for boot applications (single-launcher menu).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Boot Configuration\Behavior\Highest Mode.cmd'.
# SilentDefault mirrors the original '/silent goto disable' behavior.
# https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings
@{
    Name          = 'HighestMode'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Behavior\Highest Mode.cmd'
    SilentDefault = 'Disable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            MenuLabel  = 'Disable (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /deletevalue '{globalsettings}' highestmode 2>$null | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            MenuLabel  = 'Enable'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{globalsettings}' highestmode true | Out-Null
            }
        }
    }
}
