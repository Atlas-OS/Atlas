@{
    Name        = 'Block Anonymous Enumeration of SAM Accounts'
    Description = 'Stops anonymous users listing the accounts on this PC (SAM accounts), which would show attackers what to target.'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-220929
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'; Name = 'RestrictAnonymousSAM'; Type = 'DWord'; Data = 1 }
    )
}
