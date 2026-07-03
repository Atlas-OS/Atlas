@{
    Name        = 'Disable Ease of Access Sounds'
    Description = 'Disable Ease Of Access sounds on activation or sound warnings, like the infamous sticky keys sound, for QoL'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Accessibility'; Name = 'Warning Sounds'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Accessibility'; Name = 'Sound on Activation'; Type = 'DWord'; Data = 0 }
        # Disable visual warning for sounds in ease of access
        @{ Path = 'HKCU\Control Panel\Accessibility\SoundSentry'; Name = 'WindowsEffect'; Type = 'String'; Data = '0' }
    )
}
