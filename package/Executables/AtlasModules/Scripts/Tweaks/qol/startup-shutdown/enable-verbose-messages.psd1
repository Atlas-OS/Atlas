@{
    Name        = 'Enable verbose startup, shutdown, logon, and logoff status messages'
    Description = 'Shows detailed status messages at startup, shutdown, sign-in and sign-out.'
    # Listed under Disabled in tweaks.manifest.psd1, which records why.
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'verbosestatus'; Type = 'DWord'; Data = 1 }
    )
}
