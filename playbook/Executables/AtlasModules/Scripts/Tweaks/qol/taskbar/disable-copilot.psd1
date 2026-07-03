@{
    Name        = 'Disable Microsoft Copilot'
    Description = 'Disables Microsoft Copilot as it depends on Edge, as well it collecting data and not being used by most users'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, where Copilot does not exist.
    Registry    = @(
        # Doesn't work with HKLM
        @{ Path = 'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Type = 'DWord'; Data = 1 }
    )
}
