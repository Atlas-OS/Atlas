# Toggle: Boot spinning animation (single-launcher menu).
# https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings
@{
    Name          = 'SpinningAnimations'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\Spinning Animation.cmd'
    SilentDefault = 'Enable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable the spinning animation'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{globalsettings}', 'custom:16000069', 'true')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable the spinning animation (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
                    -AllowedExitCodes ([int[]]@(0))
                if (($bcdEditOutput -join [Environment]::NewLine) -match
                    '(?im)^[ \t]*custom:16000069(?:[ \t]+|$)') {
                    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                        -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'custom:16000069')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                }
            }
        }
    }
}
