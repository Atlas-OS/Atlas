@{
    Name        = 'Blocks Anonymous Enumeration of SAM Accounts'
    Description = 'Blocks the anonymous enumeration of SAM accounts to prevent the ability to list the potential points of attack to the system'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-220929
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'; Name = 'RestrictAnonymousSAM'; Type = 'DWord'; Data = 1 }
    )
}
