@{
    Name        = 'Disable Game Bar'
    Description = 'Disables XBOX Game Bar, which is known as a bloatware feature'
    Registry    = @(
        # Disable Game Bar
        @{ Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Type = 'DWord'; Data = 0 }
        # Disable Game Bar tips
        # Disable 'Open Xbox Game Bar using this button on a controller'
        @{ Path = 'HKCU\SOFTWARE\Microsoft\GameBar'; Name = 'GamePanelStartupTipIndex'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Type = 'DWord'; Data = 0 }
        # Disable Game Bar Presence Writer, required for GameBar
        @{ Path = 'HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'; Name = 'ActivationType'; Type = 'DWord'; Data = 0 }
        # Disable Windows Game Recording and Broadcasting
        # It automatically disables Game Bar
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'; Name = 'value'; Type = 'DWord'; Data = 0 }
    )
}
