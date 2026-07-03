@{
    Name        = 'Restrict Anonymous Enumeration of Shares'
    Description = 'Restricts anonymous enumeration of shares'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-220930
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'; Name = 'RestrictAnonymous'; Type = 'DWord'; Data = 1 }
    )
}
