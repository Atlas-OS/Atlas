@{
    Name        = 'FSOGameBar'
    Description = 'Fullscreen Optimizations (FSO) and Game Bar / Game DVR support. Machine changes run as TrustedInstaller; current-user changes run in the caller''s session.'
    Elevation   = 'TrustedInstaller'
    Warning     = 'Changes the Game Bar and Game DVR services and packages. While disabled, Game Bar shortcuts, game recording and fullscreen optimizations are unavailable.'
    Script      = 'FSOGameBar.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\FSO and Game Bar\Disable FSO and Game Bar Support.cmd'
            Reboot        = 'None'
            Registry      = @(
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; Name = '__COMPAT_LAYER'; Type = 'String'; Data = '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'; Name = 'ActivationType'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'; Name = 'value'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_DSEBehavior'; Type = 'DWord'; Data = 2 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_DXGIHonorFSEWindowsCompatible'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_EFSEFeatureFlags'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehavior'; Type = 'DWord'; Data = 2 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Type = 'DWord'; Data = 2 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_HonorUserFSEBehaviorMode'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'GamePanelStartupTipIndex'; Type = 'DWord'; Data = 3 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Type = 'DWord'; Data = 0 }
            )
            MachineAction = 'Remove-AtlasGameBarOverlayPackage'
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\FSO and Game Bar\Enable FSO and Game Bar Support (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; Name = '__COMPAT_LAYER'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'; Name = 'ActivationType'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Operation = 'DeleteKey' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'; Name = 'value'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_DSEBehavior'; Operation = 'Delete' }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_DXGIHonorFSEWindowsCompatible'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_EFSEFeatureFlags'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehavior'; Operation = 'Delete' }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Type = 'DWord'; Data = 2 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_HonorUserFSEBehaviorMode'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'GamePanelStartupTipIndex'; Operation = 'Delete' }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Operation = 'Delete' }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Operation = 'Delete' }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Operation = 'Delete' }
            )
            UserAction = 'Install-AtlasGameBarPackage'
        }
    )
}
