@{
    Name        = 'Disable Lockscreen Camera'
    Description = 'Turns off the camera on the lock screen.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoLockScreenCamera'; Type = 'DWord'; Data = 1 }
    )
}
