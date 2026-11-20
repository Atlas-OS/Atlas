@{
    Name        = 'Disable Automatic Restart Sign-On'
    Description = 'Stops Windows using your saved credentials to sign in after a restart and restore your apps behind the lock screen; you sign in yourself instead.'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-43245
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'DisableAutomaticRestartSignOn'; Type = 'DWord'; Data = 1 }
    )
}
