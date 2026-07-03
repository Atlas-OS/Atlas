@{
    Name        = 'Disable Low Disk Space Checks'
    Description = 'DIsables low disk space checks, meaning that there will not be a low disk space warning for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoLowDiskSpaceChecks'; Type = 'DWord'; Data = 1 }
    )
}
