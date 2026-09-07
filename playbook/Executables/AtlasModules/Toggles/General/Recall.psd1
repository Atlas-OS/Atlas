@{
    Name        = 'Recall'
    Description = 'Recall and Windows AI data analysis through the DisableAIDataAnalysis policy.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\AI Features\Recall\Disable Recall Support (default).cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableAIDataAnalysis'; Type = 'DWord'; Data = 1 }
                # 0 = Recall cannot be enabled: removes the Recall component bits and
                # deletes existing snapshots (24H2 26100.3915+; needs a restart to finish).
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'AllowRecallEnablement'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\AI Features\Recall\Enable Recall Support.cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableAIDataAnalysis'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'AllowRecallEnablement'; Operation = 'Delete' }
            )
        }
    )
}
