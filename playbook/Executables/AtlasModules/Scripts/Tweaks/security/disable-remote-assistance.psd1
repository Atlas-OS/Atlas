@{
    Name        = 'Disable Remote Assistance'
    Description = 'As Remote Assistance is an unused and a potential vulnerable feature, it is disabled'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name = 'fAllowFullControl'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name = 'fAllowToGetHelp'; Type = 'DWord'; Data = 0 }
    )
    Run         = @(
        @{ Exe = 'netsh'; Args = 'advfirewall firewall set rule group="Remote Assistance" new enable=no' }
    )
}
