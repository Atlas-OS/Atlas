@{
    Name        = 'Disable Microsoft Copilot'
    Description = 'Disables Microsoft Copilot as it depends on Edge, as well it collecting data and not being used by most users'
    MinBuild    = 22000
    Registry    = @(
        # Doesn't work with HKLM
        @{ Path = 'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Type = 'DWord'; Data = 1 }
    )
}
