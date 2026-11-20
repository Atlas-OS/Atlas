@{
    Name        = 'Disable Remote Assistance'
    Description = 'Turns off Remote Assistance and its firewall rules, removing a rarely used way to reach the PC remotely.'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name = 'fAllowFullControl'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name = 'fAllowToGetHelp'; Type = 'DWord'; Data = 0 }
    )
    Run         = @(
        # An extra layer on top of the registry values. netsh matches the localised rule
        # group name, so this only matches on English Windows and returns exit code 1
        # elsewhere; IgnoreErrors keeps that from failing the tweak.
        @{ Exe = '{windir}\System32\netsh.exe'; Args = @('advfirewall', 'firewall', 'set', 'rule', 'group=Remote Assistance', 'new', 'enable=no'); IgnoreErrors = $true }
    )
}
