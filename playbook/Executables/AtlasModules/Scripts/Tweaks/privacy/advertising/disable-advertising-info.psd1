@{
    Name        = 'Disable Advertising ID'
    Description = 'Disables Advertising ID for privacy'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\AdvertisingInfo'; Name = 'DisabledByGroupPolicy'; Type = 'DWord'; Data = 1 }
    )
}
