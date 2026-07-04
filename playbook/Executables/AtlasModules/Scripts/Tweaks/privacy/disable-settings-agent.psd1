@{
    Name        = 'Disable Settings AI Agent'
    Description = 'Disables the 25H2 AI agent in Settings (on-device model behind natural-language Settings search on Copilot+ PCs)'
    Registry    = @(
        # Currently documented for Enterprise/Education; inert elsewhere but pre-staged.
        # TODO: the related 25H2 agent-workspace policies (DisableAgentWorkspaces,
        # agent connector policies) are still Insider-only - revisit when they ship.
        # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai#disablesettingsagent
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableSettingsAgent'; Type = 'DWord'; Data = 1 }
    )
}
