@{
    Name        = 'Prioritize Foreground Applications'
    Description = 'Sets Win32PrioritySeparation to 0x26: short, variable time slices with a triple boost for the app in the foreground. This matches the Programs setting in Performance Options and the Windows default, so it only changes PCs where other tools set server-style or invalid values.'
    Registry    = @(
        # Keep the client value: 0x28 and 0x18-style values have server semantics.
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Type = 'DWord'; Data = 38 }
    )
}
