@{
    Name        = 'Disable Recall Snapshots'
    Description = 'Disables snapshots of Recall (24H2+)'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableAIDataAnalysis'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'AllowRecallEnablement'; Type = 'DWord'; Data = 0 }
    )
}
