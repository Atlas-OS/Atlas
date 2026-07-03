@{
    Name        = 'Enable verbose startup, shutdown, logon, and logoff status messages'
    Description = 'Enables verbose status messages so users can have more insight on exactly what''s happening on startup, shutdown, logon, and logoff'
    # NOTE: disabled (commented out) in the legacy tweaks.yml (no reason recorded).
    # Keep it commented out in the tweak manifest.
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'verbosestatus'; Type = 'DWord'; Data = 1 }
    )
}
