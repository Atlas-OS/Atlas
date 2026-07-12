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
                New-ItemProperty -LiteralPath $hklmCloud -Name 'DisableCloudOptimizedContent' -Value 1 -PropertyType DWord -Force | Out-Null
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightWindowsWelcomeExperience' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightOnActionCenter' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightOnSettings' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableThirdPartySuggestions' -Type DWord -Data 1
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

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableCloudOptimizedContent'
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures'
                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightWindowsWelcomeExperience'
                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightOnActionCenter'
                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightOnSettings'
                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableThirdPartySuggestions'
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
