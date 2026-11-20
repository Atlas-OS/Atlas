@{
    Name        = 'Disable Advertising ID'
    Description = 'Turns off the advertising ID, so apps can''t use it to show you personalised adverts.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        # Machine-scope variant listed in the 'Manage connections' doc, for completeness.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\AdvertisingInfo'; Name = 'DisabledByGroupPolicy'; Type = 'DWord'; Data = 1 }
    )
}
