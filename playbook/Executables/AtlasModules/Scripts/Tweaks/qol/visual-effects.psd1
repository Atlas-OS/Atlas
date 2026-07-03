@{
    Name        = 'Configure Visual Effects'
    Description = 'Configures the visual effects in Windows for the optimal responsiveness, performance and QoL'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'FontSmoothing'; Type = 'String'; Data = '2' }
        # Legacy REG_BINARY 9012038010000000
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Type = 'Binary'; Data = @(0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00) }
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'DragFullWindows'; Type = 'String'; Data = '1' }
        @{ Path = 'HKCU\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Type = 'String'; Data = '0' }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewAlphaSelect'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'IconsOnly'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAnimations'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewShadow'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\DWM'; Name = 'AlwaysHibernateThumbnails'; Type = 'DWord'; Data = 0 }
    )
}
