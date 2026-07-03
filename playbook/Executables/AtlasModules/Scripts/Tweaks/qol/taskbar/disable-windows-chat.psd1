@{
    Name        = 'Disable Windows Chat'
    Description = 'Disables Windows Chat as it''s not commonly used'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the values are
    # harmless on Windows 10, where Windows Chat does not exist.
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat'; Name = 'ChatIcon'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarMn'; Type = 'DWord'; Data = 0 }
    )
}
