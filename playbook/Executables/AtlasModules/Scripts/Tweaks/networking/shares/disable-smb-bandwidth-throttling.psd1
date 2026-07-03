@{
    Name        = 'Disable SMB Bandwidth Throttling'
    Description = 'Disables SMB bandwidth throttling for improved performance'
    Registry    = @(
        # https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/file-server
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'; Name = 'DisableBandwidthThrottling'; Type = 'DWord'; Data = 1 }
    )
}
