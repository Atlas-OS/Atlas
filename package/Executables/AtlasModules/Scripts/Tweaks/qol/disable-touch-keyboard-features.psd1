@{
    Name        = 'Disable Unnecessary Touch Keyboard Settings'
    Description = 'Turns off automatic capitalisation and key sounds on the touch keyboard.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableAutoShiftEngage'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableKeyAudioFeedback'; Type = 'DWord'; Data = 0 }
        # EnableShiftLock (double-tap Shift for Caps Lock) stays on: it acts only when you ask for it.
    )
}
