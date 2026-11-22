@{
    Name        = 'Decrease Shutdown Time'
    Description = 'Shortens how long Windows waits for unresponsive or closing apps at shutdown to 2 seconds.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'HungAppTimeout'; Type = 'String'; Data = '2000' }
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'WaitToKillAppTimeOut'; Type = 'String'; Data = '2000' }
        # WaitToKillServiceTimeout is deliberately left at the 5000 default: services doing
        # legitimate shutdown work (databases, sync clients, VSS) get killed mid-flush at
        # 2000, and the visible shutdown speedup comes from the app timeouts above.
    )
}
