@{
    Name        = 'Set Unpinned Control Center Items'
    Description = 'Disables unused control center items by default for QoL'
    # Everything happens in the companion script: the quick action names and toggle
    # data differ between Windows 10 and Windows 11 (same value, different data), which
    # the declarative Registry schema cannot express, and explorer must be stopped
    # before the writes and restarted afterwards.
    Script      = 'set-unpinned-notification-items.ps1'
}
