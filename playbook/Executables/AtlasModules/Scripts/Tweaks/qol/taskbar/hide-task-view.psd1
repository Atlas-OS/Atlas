@{
    Name        = 'Disable Task View on Taskbar'
    Description = 'Hides the Task View button on the taskbar; Windows+Tab still opens Task View.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView'; Name = 'Enabled'; Operation = 'Delete' }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTaskViewButton'; Type = 'DWord'; Data = 0 }
    )
}
