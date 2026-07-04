@{
    Name        = 'Add ''End task'' to the taskbar'
    Description = 'Adds ''End task'' as a right-click option on taskbar for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name = 'TaskbarEndTask'; Type = 'DWord'; Data = 1 }
    )
}
