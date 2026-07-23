@{
    Name        = 'Disable Settings Sync'
    Description = 'Disables the ''Windows Backup'' settings synchronization for QoL and privacy'
    Registry    = @(
        # Policies don't disable the toggles in the UI, doesn't seem like much can be done about it
        # Whole Settings page is hidden anyways
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
