@{
    Name        = 'Disable Unnecessary Touch Keyboard Settings'
    Description = 'Disable unnecessary touch keyboard settings for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableAutoShiftEngage'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableKeyAudioFeedback'; Type = 'DWord'; Data = 0 }
        # Intentionally not applied:
        # @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableShiftLock'; Type = 'DWord'; Data = 0 }
    )
}
