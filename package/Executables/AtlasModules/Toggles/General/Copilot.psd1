@{
    Name        = 'Copilot'
    Description = 'Turns Microsoft Copilot on or off: its taskbar button, app and policy. Copilot needs Microsoft Edge, and Enable installs the Copilot app from Microsoft Store through WinGet. Both states restart File Explorer so the taskbar updates.'
    Elevation   = 'Admin'
    Script      = 'Copilot.ps1'
    States      = @(
        @{
            Name            = 'Disable'
            StateValue      = 0
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Disable Microsoft Copilot (default).cmd'
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
            Reboot          = 'RestartExplorer'
            # Atlas 0.5.0 recorded Enable before checking for Edge, which it removes by
            # default; such a record is dropped on replay rather than failing the upgrade.
            ReplayApplicable = 'Test-AtlasCopilotEdgeInstalled'
            MachineAction   = 'Enable-AtlasCopilotMachine'
            UserAction      = 'Enable-AtlasCopilotUser'
        }
    )
}
