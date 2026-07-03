# Toggle: Windows Automatic Repair at boot (single-launcher menu).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Boot Configuration\Behavior\Automatic Repair.cmd'.
# SilentDefault mirrors the original '/silent goto enable' behavior.
# https://winaero.com/how-to-disable-automatic-repair-at-windows-10-boot
@{
    Name          = 'AutomaticRepair'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Behavior\Automatic Repair.cmd'
    SilentDefault = 'Enable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            MenuLabel  = 'Disable automatic repair'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{current}' bootstatuspolicy IgnoreAllFailures | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            MenuLabel  = 'Enable automatic repair (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{current}' bootstatuspolicy DisplayAllFailures | Out-Null
            }
        }
    }
}
