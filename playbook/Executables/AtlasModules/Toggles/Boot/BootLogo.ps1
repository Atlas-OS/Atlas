# Toggle: Windows boot logo (single-launcher menu).
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
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable the boot logo'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{globalsettings}', 'custom:16000067', 'true')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable the boot logo (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
                    -AllowedExitCodes ([int[]]@(0))
                if (($bcdEditOutput -join [Environment]::NewLine) -match
                    '(?im)^[ \t]*custom:16000067(?:[ \t]+|$)') {
                    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                        -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'custom:16000067')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                }
            }
        }
    }
}
