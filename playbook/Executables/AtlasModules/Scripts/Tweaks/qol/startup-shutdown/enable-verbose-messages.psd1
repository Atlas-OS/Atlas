@{
    Name        = 'Enable verbose startup, shutdown, logon, and logoff status messages'
    Description = 'Enables verbose status messages so users can have more insight on exactly what''s happening on startup, shutdown, logon, and logoff'
    # NOTE: intentionally not enabled (no reason recorded).
    # Keep it commented out in the tweak manifest.
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'verbosestatus'; Type = 'DWord'; Data = 1 }
    )
}
