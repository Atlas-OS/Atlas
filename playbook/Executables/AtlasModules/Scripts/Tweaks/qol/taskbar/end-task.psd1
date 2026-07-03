@{
    Name        = 'Add ''End task'' to the taskbar'
    Description = 'Adds ''End task'' as a right-click option on taskbar for QoL'
    # The taskbar developer settings only exist on builds above 22000 (22H2+), hence 22001.
    MinBuild    = 22001
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name = 'TaskbarEndTask'; Type = 'DWord'; Data = 1 }
    )
}
