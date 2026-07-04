@{
    Name        = 'Disable Recommendations in the Start Menu'
    Description = 'Do not show recommendations for tips, shortcuts, new apps, and more in the Start Menu'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_IrisRecommendations'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_AccountNotifications'; Type = 'DWord'; Data = 0 }
    )
}
