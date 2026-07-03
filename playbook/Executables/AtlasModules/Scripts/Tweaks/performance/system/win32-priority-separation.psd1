@{
    Name        = 'Prioritize Foreground Applications'
    Description = 'Prioritizes foreground applications for process scheduling by setting Win32PrioritySeparation to 26 hex, meaning a short quantum, variable, high foreground boost'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Type = 'DWord'; Data = 38 }
    )
}
