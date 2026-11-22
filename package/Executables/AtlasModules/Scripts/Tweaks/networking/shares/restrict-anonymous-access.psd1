@{
    Name        = 'Restrict Anonymous Access'
    Description = 'Blocks anonymous access to named pipes and shares, so users who haven''t signed in can''t reach them.'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-220932
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters'; Name = 'RestrictNullSessAccess'; Type = 'DWord'; Data = 1 }
    )
}
