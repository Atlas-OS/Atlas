@{
    Name        = 'Hide Unused Windows Security Pages'
    Description = 'Hides Windows Security pages that are not commonly needed/used to have a more clean UI'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Family options'; Name = 'UILockdown'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Device performance and health'; Name = 'UILockdown'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Account protection'; Name = 'UILockdown'; Type = 'DWord'; Data = 1 }
    )
}
