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
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable always going to the advanced boot options (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
                    -AllowedExitCodes ([int[]]@(0))
                if (($bcdEditOutput -join [Environment]::NewLine) -match
                    '(?im)^[ \t]*advancedoptions(?:[ \t]+|$)') {
                    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                        -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'advancedoptions')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable always going to the advanced boot options'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{globalsettings}', 'advancedoptions', 'true')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
    }
}
