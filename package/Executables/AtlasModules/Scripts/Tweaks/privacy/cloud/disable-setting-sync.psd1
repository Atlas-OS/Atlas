@{
    Name        = 'Disable Settings Sync'
    Description = 'Turns off settings sync in Windows Backup, so your theme, passwords, accessibility and other Windows settings aren''t uploaded to your Microsoft account.'
    Registry    = @(
        # The policies don't grey out the switches in Settings, so Atlas hides that page instead.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync'; Name = 'DisableSettingSync'; Type = 'DWord'; Data = 2 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync'; Name = 'DisableSettingSyncUserOverride'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync'; Name = 'DisableSyncOnPaidNetwork'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync'; Name = 'DisableWindowsSettingSync'; Type = 'DWord'; Data = 2 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync'; Name = 'SyncPolicy'; Type = 'DWord'; Data = 5 }
    )
}
