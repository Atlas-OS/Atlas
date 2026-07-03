@{
    Name        = 'Add ''End task'' to the taskbar'
    Description = 'Adds ''End task'' as a right-click option on taskbar for QoL'
    # Legacy playbook gated this to builds > 22000; the value is harmless on builds
    # without the taskbar developer settings.
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name = 'TaskbarEndTask'; Type = 'DWord'; Data = 1 }
    )
}
