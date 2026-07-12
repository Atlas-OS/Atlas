@{
    Name        = 'Disable Microsoft Copilot'
    Description = 'Disables Microsoft Copilot as it depends on Edge, as well it collecting data and not being used by most users'
    Registry    = @(
        # TurnOffWindowsCopilot is deprecated and only ever controlled the old Copilot
        # sidebar. The real removal is the Copilot AppX phase; this remains as
        # legacy belt-and-braces for Windows builds that still honor it.
        # (Doesn't work with HKLM.)
        @{ Path = 'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Type = 'DWord'; Data = 1 }
        # Documented replacement (25H2+): uninstalls the Copilot app where supported.
        # Only honored on Enterprise/Education - a silent extra there, inert elsewhere.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'RemoveMicrosoftCopilotApp'; Type = 'DWord'; Data = 1 }
    )
}
