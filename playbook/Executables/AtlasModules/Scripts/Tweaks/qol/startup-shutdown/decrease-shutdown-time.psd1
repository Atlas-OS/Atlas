@{
    Name        = 'Decrease Shutdown Time'
    Description = 'Makes it so that Windows is less tolerable to hung apps, and tries to kill them as fast as possible on shutdown'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'HungAppTimeout'; Type = 'String'; Data = '2000' }
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'WaitToKillAppTimeOut'; Type = 'String'; Data = '2000' }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control'; Name = 'WaitToKillServiceTimeout'; Type = 'String'; Data = '2000' }
    )
}
