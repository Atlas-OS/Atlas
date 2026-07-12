# Toggle: Windows Automatic Repair at boot (single-launcher menu).
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
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable automatic repair'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{current}', 'bootstatuspolicy', 'IgnoreAllFailures')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable automatic repair (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{current}', 'bootstatuspolicy', 'DisplayAllFailures')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
    }
}
