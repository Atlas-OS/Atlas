@{
    Name        = 'Disable Settings AI Agent'
    Description = 'Turns off the AI agent in Settings, the on-device model behind natural-language search in Settings on Copilot+ PCs.'
    Registry    = @(
        # Documented for Enterprise and Education; set on every edition so it applies wherever Windows reads it.
        # https://learn.microsoft.com/windows/client-management/mdm/policy-csp-windowsai#disablesettingsagent
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableSettingsAgent'; Type = 'DWord'; Data = 1 }
    )
}
