@{
    Name        = 'Disable Windows Feedback'
    Description = 'Disables Windows Feedback for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Siuf\Rules'; Name = 'NumberOfSIUFInPeriod'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Siuf\Rules'; Name = 'PeriodInNanoSeconds'; Operation = 'Delete' }
        # Documented policy location (the CurrentVersion\Policies mirror is not read for this value)
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'DoNotShowFeedbackNotifications'; Type = 'DWord'; Data = 1 }
    )
}
