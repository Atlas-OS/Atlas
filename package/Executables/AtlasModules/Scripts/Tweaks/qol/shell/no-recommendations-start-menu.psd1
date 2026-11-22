@{
    Name        = 'Disable Recommendations in the Start Menu'
    Description = 'Stops Start recommending tips, shortcuts, new apps and other items.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_IrisRecommendations'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_AccountNotifications'; Type = 'DWord'; Data = 0 }
    )
}
