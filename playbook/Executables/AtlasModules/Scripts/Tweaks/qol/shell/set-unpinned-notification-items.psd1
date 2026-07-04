@{
    Name        = 'Set Unpinned Control Center Items'
    Description = 'Disables unused control center items by default for QoL'
    # Everything happens in the companion script: the toggle data is one packed string,
    # and explorer must be stopped before the writes and restarted afterwards.
    Script      = 'set-unpinned-notification-items.ps1'
}
