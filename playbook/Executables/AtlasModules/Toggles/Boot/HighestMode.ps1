# Toggle: Highest graphical mode for boot applications (single-launcher menu).
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
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
                    -AllowedExitCodes ([int[]]@(0))
                if (($bcdEditOutput -join [Environment]::NewLine) -match
                    '(?im)^[ \t]*highestmode(?:[ \t]+|$)') {
                    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                        -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'highestmode')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{globalsettings}', 'highestmode', 'true')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
    }
}
