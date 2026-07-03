@{
    Name        = 'Restrict Anonymous Access'
    Description = 'Restricts anonymous access to named pipes and shares to prevent unauthorized system access'
    Registry    = @(
        # https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-220932
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters'; Name = 'RestrictNullSessAccess'; Type = 'DWord'; Data = 1 }
    )
}
