@{
    Name        = 'Configure Power Settings'
    Description  = 'Configures power settings for the best performance and lowest latency, based on the user''s options. Done last on purpose.'
    Registry    = @(
        # Disable Fast Startup.
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Type = 'DWord'; Data = 0 }
    )
    # The toggle launchers are gated per option (including the negated '!disable-power-saving'
    # Balanced fallback), which a single Option gate cannot express.
    Script       = 'set-power-settings.ps1'
}
