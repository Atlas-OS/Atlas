@{
    Name        = 'Disable Automatic Restart Sign-On'
    Description = 'Stops Windows caching your credentials across a restart to auto-restore your last session behind the lock screen; you sign in manually instead'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-43245
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'DisableAutomaticRestartSignOn'; Type = 'DWord'; Data = 1 }
    )
}
