# Toggle: Windows boot logo (single-launcher menu).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Boot Configuration\Appearance\Boot Logo.cmd'.
#
# The original script recorded 'state' correctly but never declared a stateValue up
# front; the per-state StateValue keys below make the recorded state explicit.
# SilentDefault mirrors the original '/silent goto enable' behavior for upgrades.
# https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings
@{
    Name          = 'BootLogo'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\Boot Logo.cmd'
    SilentDefault = 'Enable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            MenuLabel  = 'Disable the boot logo'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{globalsettings}' custom:16000067 true | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            MenuLabel  = 'Enable the boot logo (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /deletevalue '{globalsettings}' custom:16000067 2>$null | Out-Null
            }
        }
    }
}
