@{
    Name        = 'Disable Low Disk Space Checks'
    Description = 'Disables low disk space checks, meaning that there will not be a low disk space warning for QoL. Trade-off: a drive can silently run completely full, which breaks updates and shadow copies.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoLowDiskSpaceChecks'; Type = 'DWord'; Data = 1 }
    )
}
