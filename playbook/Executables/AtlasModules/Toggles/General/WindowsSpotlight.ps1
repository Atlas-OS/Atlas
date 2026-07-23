# Toggle: Windows Spotlight (lock screen, tips, suggestions, spotlight content).
#
# The HKLM CloudContent policy runs in the machine child; per-user values run only in
# the original non-elevated caller.
@{
    Name      = 'WindowsSpotlight'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Windows Spotlight\Disable Windows Spotlight (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $hklmCloud = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
                if (-not (Test-Path -LiteralPath $hklmCloud)) { New-Item -Path $hklmCloud -Force | Out-Null }
                foreach ($name in @(
                        'DisableCloudOptimizedContent'
                        'DisableWindowsSpotlightFeatures'
                        'DisableWindowsSpotlightWindowsWelcomeExperience'
                        'DisableWindowsSpotlightOnActionCenter'
                        'DisableWindowsSpotlightOnSettings'
                        'DisableThirdPartySuggestions'
                    )) {
                    New-ItemProperty -LiteralPath $hklmCloud -Name $name -Value 1 -PropertyType DWord -Force | Out-Null
                }
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'ContentDeliveryAllowed' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'FeatureManagementEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContentEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338387Enabled' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenOverlayEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Type DWord -Data 1

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, Windows Spotlight is now disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Windows Spotlight\Enable Windows Spotlight.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                foreach ($name in @(
                        'DisableCloudOptimizedContent'
                        'DisableWindowsSpotlightFeatures'
                        'DisableWindowsSpotlightWindowsWelcomeExperience'
                        'DisableWindowsSpotlightOnActionCenter'
                        'DisableWindowsSpotlightOnSettings'
                        'DisableThirdPartySuggestions'
                    )) {
                    Remove-AtlasRegistryValue `
                        -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
                        -Name $name
                }
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'ContentDeliveryAllowed' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'FeatureManagementEnabled' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContentEnabled' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338387Enabled' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenOverlayEnabled' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Type DWord -Data 0

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, Windows Spotlight is now enabled.'
                }
            }
        }
    }
}
