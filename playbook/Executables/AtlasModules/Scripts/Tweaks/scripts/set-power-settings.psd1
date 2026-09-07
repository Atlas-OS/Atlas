@{
    Name        = 'Configure Power Settings'
    Description  = 'Disables Fast Startup and applies the selected power and hibernation choices after the category tweaks.'
    Registry    = @(
        # Disable Fast Startup.
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Type = 'DWord'; Data = 0 }
    )
    # The toggle launchers are gated per option (including the negated '!disable-power-saving'
    # Balanced fallback), which a single Option gate cannot express.
    Script       = 'set-power-settings.ps1'
}
