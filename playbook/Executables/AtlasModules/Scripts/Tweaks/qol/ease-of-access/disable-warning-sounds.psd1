@{
    Name        = 'Disable Ease of Access Sounds'
    Description = 'Turns off the sounds Ease of Access plays when a shortcut turns a feature on, such as the Sticky Keys sound, and visual warnings for sounds.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Accessibility'; Name = 'Warning Sounds'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Accessibility'; Name = 'Sound on Activation'; Type = 'DWord'; Data = 0 }
        # Disable visual warning for sounds in ease of access
        @{ Path = 'HKCU\Control Panel\Accessibility\SoundSentry'; Name = 'WindowsEffect'; Type = 'String'; Data = '0' }
    )
}
