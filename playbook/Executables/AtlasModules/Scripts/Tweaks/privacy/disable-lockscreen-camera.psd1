@{
    Name        = 'Disable Lockscreen Camera'
    Description = 'Disables camera access on the lockscreen'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoLockScreenCamera'; Type = 'DWord'; Data = 1 }
    )
}
