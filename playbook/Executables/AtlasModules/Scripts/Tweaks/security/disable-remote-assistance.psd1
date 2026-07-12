@{
    Name        = 'Disable Remote Assistance'
    Description = 'As Remote Assistance is an unused and a potential vulnerable feature, it is disabled'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name = 'fAllowFullControl'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name = 'fAllowToGetHelp'; Type = 'DWord'; Data = 0 }
    )
    Run         = @(
        # Belt-and-braces on top of the registry disable. netsh matches the LOCALIZED rule
        # group name, so this only matches on English Windows and returns exit code 1
        # elsewhere - IgnoreErrors keeps that from failing the tweak.
        @{ Exe = '{windir}\System32\netsh.exe'; Args = @('advfirewall', 'firewall', 'set', 'rule', 'group=Remote Assistance', 'new', 'enable=no'); IgnoreErrors = $true }
    )
}
