@{
    Name        = 'Prioritize Foreground Applications'
    Description = 'Pins Win32PrioritySeparation to 26 hex (short quantum, variable, 3x foreground boost). This matches what the Performance Options ''Programs'' setting writes and the client default behavior - it changes nothing on a stock install, but normalizes machines where third-party tweaks set server-style or broken values.'
    Registry    = @(
        # Do not "upgrade" this to 0x28/0x18-style values - those are Server semantics.
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Type = 'DWord'; Data = 38 }
    )
}
