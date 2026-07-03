# Toggle: Always go to the advanced boot options on each boot (single-launcher menu).
@{
    Name          = 'AdvancedBootOptions'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Behavior\Always Go to Advanced Boot Options.cmd'
    SilentDefault = 'Disable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            MenuLabel  = 'Disable always going to the advanced boot options (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /deletevalue '{globalsettings}' advancedoptions 2>$null | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            MenuLabel  = 'Enable always going to the advanced boot options'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\bcdedit.exe" /set '{globalsettings}' advancedoptions true | Out-Null
            }
        }
    }
}
