@{
    Name        = 'Disable Windows Feedback'
    Description = 'Disables Windows Feedback for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Siuf\Rules'; Name = 'NumberOfSIUFInPeriod'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Siuf\Rules'; Name = 'PeriodInNanoSeconds'; Operation = 'Delete' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'DoNotShowFeedbackNotifications'; Type = 'DWord'; Data = 1 }
    )
}
