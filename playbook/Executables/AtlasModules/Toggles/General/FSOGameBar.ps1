# Toggle: Fullscreen Optimizations (FSO) and Game Bar / Game DVR support.
#
# TrustedInstaller elevation is required to write the Windows.Gaming ActivatableClassId key.
# HKCU writes go through Atlas.Registry so they hit the real user under TI elevation. The
# Disable path removes the Xbox Game Bar overlay package; the Enable path reinstalls it.
@{
    Name      = 'FSOGameBar'
    Elevation = 'TrustedInstaller'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\FSO and Game Bar\Disable FSO and Game Bar Support.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DSEBehavior' -Type DWord -Data 2
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_EFSEFeatureFlags' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehavior' -Type DWord -Data 2
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Type DWord -Data 2
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_HonorUserFSEBehaviorMode' -Type DWord -Data 1

                $env = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
                if (-not (Test-Path -LiteralPath $env)) { New-Item -Path $env -Force | Out-Null }
                New-ItemProperty -LiteralPath $env -Name '__COMPAT_LAYER' -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -PropertyType String -Force | Out-Null

                Set-AtlasRegistryValue -Path 'HKCU:\System\GameBar' -Name 'GamePanelStartupTipIndex' -Type DWord -Data 3
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameBar' -Name 'ShowStartupPanel' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameBar' -Name 'UseNexusForGameBarEnabled' -Type DWord -Data 0

                $presence = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'
                if (-not (Test-Path -LiteralPath $presence)) { New-Item -Path $presence -Force | Out-Null }
                New-ItemProperty -LiteralPath $presence -Name 'ActivationType' -Value 0 -PropertyType DWord -Force | Out-Null

                $gameDvrPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
                if (-not (Test-Path -LiteralPath $gameDvrPolicy)) { New-Item -Path $gameDvrPolicy -Force | Out-Null }
                New-ItemProperty -LiteralPath $gameDvrPolicy -Name 'AllowGameDVR' -Value 0 -PropertyType DWord -Force | Out-Null

                $allowGameDvr = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'
                if (-not (Test-Path -LiteralPath $allowGameDvr)) { New-Item -Path $allowGameDvr -Force | Out-Null }
                New-ItemProperty -LiteralPath $allowGameDvr -Name 'value' -Value 0 -PropertyType DWord -Force | Out-Null

                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Type DWord -Data 0

                # -AllUsers on both ends: under TrustedInstaller/SYSTEM a plain Get-AppxPackage
                # only sees SYSTEM's (empty) package list, so the overlay would never be removed.
                Get-AppxPackage -AllUsers '*xboxgamingoverlay*' | Remove-AppxPackage -AllUsers -Confirm:$false -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'FSO and Game Bar have been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\FSO and Game Bar\Enable FSO and Game Bar Support (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Remove-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DSEBehavior'
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_EFSEFeatureFlags' -Type DWord -Data 0
                Remove-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehavior'
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Type DWord -Data 2
                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_HonorUserFSEBehaviorMode' -Type DWord -Data 0

                Remove-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name '__COMPAT_LAYER' -Force -ErrorAction SilentlyContinue
                Remove-AtlasRegistryValue -Path 'HKCU:\System\GameBar' -Name 'GamePanelStartupTipIndex'
                Remove-AtlasRegistryValue -Path 'HKCU:\System\GameBar' -Name 'ShowStartupPanel'
                Remove-AtlasRegistryValue -Path 'HKCU:\System\GameBar' -Name 'UseNexusForGameBarEnabled'

                $presence = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'
                if (-not (Test-Path -LiteralPath $presence)) { New-Item -Path $presence -Force | Out-Null }
                New-ItemProperty -LiteralPath $presence -Name 'ActivationType' -Value 1 -PropertyType DWord -Force | Out-Null

                Remove-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Recurse -Force -ErrorAction SilentlyContinue

                $allowGameDvr = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'
                if (-not (Test-Path -LiteralPath $allowGameDvr)) { New-Item -Path $allowGameDvr -Force | Out-Null }
                New-ItemProperty -LiteralPath $allowGameDvr -Name 'value' -Value 1 -PropertyType DWord -Force | Out-Null

                Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Data 1
                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled'

                # winget is non-functional under SYSTEM/TrustedInstaller, so run the Game Bar
                # install in the interactive user's session (Invoke-AtlasAsUser, Atlas.Core).
                try {
                    $wingetArguments = '/c winget install 9NZKPSTSNW4P --accept-package-agreements --accept-source-agreements --silent'
                    $wingetExitCode = Invoke-AtlasAsUser -FilePath (Join-Path -Path $Toggle.WinDir -ChildPath 'System32\cmd.exe') -Arguments $wingetArguments
                    if ($wingetExitCode -ne 0) {
                        Write-AtlasLog -Level Warning -Message "FSOGameBar: winget Xbox Game Bar install exited with code $wingetExitCode."
                    }
                }
                catch {
                    Write-AtlasLog -Level Warning -Message "FSOGameBar: could not install Xbox Game Bar as the interactive user: $($_.Exception.Message)"
                }

                if (-not $Toggle.Silent) { Write-Host 'FSO and Game Bar have been enabled.' }
            }
        }
    }
}
