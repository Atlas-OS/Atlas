@{
    Name        = 'Decrease Shutdown Time'
    Description = 'Makes it so that Windows is less tolerable to hung apps, and tries to kill them as fast as possible on shutdown'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'HungAppTimeout'; Type = 'String'; Data = '2000' }
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'WaitToKillAppTimeOut'; Type = 'String'; Data = '2000' }
        # WaitToKillServiceTimeout is deliberately left at the 5000 default: services doing
        # legitimate shutdown work (databases, sync clients, VSS) get killed mid-flush at
        # 2000, and the visible shutdown speedup comes from the app timeouts above.
    )
}
