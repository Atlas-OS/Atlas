@{
    Name        = 'Disable Microsoft Copilot'
    Description = 'Sets the policy that removes the Microsoft Copilot app on editions that honour it. The install removes the Copilot app and its taskbar pin separately.'
    Registry    = @(
        # Copilot removal is primarily the Copilot AppX phase plus the taskbar unpin in
        # taskbar/config-pins. RemoveMicrosoftCopilotApp (25H2+) additionally uninstalls
        # the Copilot app where supported; only Enterprise and Education honour it, and
        # other editions ignore it.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'RemoveMicrosoftCopilotApp'; Type = 'DWord'; Data = 1; VerifyWithToggle = @{ Name = 'Copilot'; State = 1; Operation = 'Delete' } }
    )
}
