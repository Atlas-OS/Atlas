@{
    Name        = 'Disable Task View on Taskbar'
    Description = 'Disables the Task View button on the taskbar for QoL, as it can be accessed with Win + Tab anyways'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView'; Name = 'Enabled'; Operation = 'Delete' }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTaskViewButton'; Type = 'DWord'; Data = 0 }
    )
}
