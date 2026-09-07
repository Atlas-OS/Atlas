@{
    Name        = 'Copilot'
    Description = 'Microsoft Copilot taskbar button, app and policy. Both states refresh Explorer so the taskbar updates. Copilot requires an installed Edge; on 24H2 it is delivered as a Store app installed through the trusted WinGet resolver.'
    Elevation   = 'Admin'
    Script      = 'Copilot.ps1'
    States      = @(
        @{
            Name            = 'Disable'
            StateValue      = 0
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Disable Microsoft Copilot (default).cmd'
            ToolboxLauncher = 'Scripts\Copilot\DisableMicrosoftCopilot.cmd'
            Reboot          = 'RestartExplorer'
            Registry        = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'RemoveMicrosoftCopilotApp'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowCopilotButton'; Type = 'DWord'; Data = 0 }
            )
            MachineAction   = 'Remove-AtlasCopilotApp'
        }
        @{
            Name            = 'Enable'
            StateValue      = 1
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Enable Microsoft Copilot.cmd'
            ToolboxLauncher = 'Scripts\Copilot\Enable Microsoft Copilot.cmd'
            Reboot          = 'RestartExplorer'
            MachineAction   = 'Enable-AtlasCopilotMachine'
            UserAction      = 'Enable-AtlasCopilotUser'
        }
    )
}
