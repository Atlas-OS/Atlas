@{
    Name        = 'Disable Aero Shake'
    Description = 'Disables Aero Shake, which is where you shake a window and all other Windows minimise, as most of the time it is accidentally triggered'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'DisallowShaking'; Type = 'DWord'; Data = 1 }
    )
}
