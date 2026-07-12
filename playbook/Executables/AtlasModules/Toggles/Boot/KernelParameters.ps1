# Toggle: Editing of kernel parameters on startup (single-launcher menu).
@{
    Name          = 'KernelParameters'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Behavior\Editing Kernel Parameters on Startup.cmd'
    SilentDefault = 'Disable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            MenuLabel  = 'Disable editing of kernel parameters on startup (default)'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                $bcdEditOutput = Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/enum', '{globalsettings}')) `
                    -AllowedExitCodes ([int[]]@(0))
                if (($bcdEditOutput -join [Environment]::NewLine) -match
                    '(?im)^[ \t]*optionsedit(?:[ \t]+|$)') {
                    Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                        -ArgumentList ([string[]]@('/deletevalue', '{globalsettings}', 'optionsedit')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            MenuLabel  = 'Enable editing of kernel parameters on startup'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $bcdEditPath = [IO.Path]::Combine($Toggle.WinDir, 'System32', 'bcdedit.exe')
                Invoke-AtlasToggleNativeCommand -FilePath $bcdEditPath `
                    -ArgumentList ([string[]]@('/set', '{globalsettings}', 'optionsedit', 'true')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
            }
        }
    }
}
