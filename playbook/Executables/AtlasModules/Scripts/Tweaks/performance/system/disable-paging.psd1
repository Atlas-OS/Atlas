@{
    Name        = 'Disable Paging Settings'
    Description = 'Disables memory paging settings for the best performance'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'DisablePagingExecutive'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'DisablePageCombining'; Type = 'DWord'; Data = 1 }
    )
}
