@{
    Name        = 'Disable SMB Bandwidth Throttling'
    Description = 'Turns off SMB client bandwidth throttling, the same setting as `Set-SmbClientConfiguration -EnableBandwidthThrottling 0`. It mainly speeds up file shares over high-latency links, where the redirector throttles by design, and has little effect on a local network.'
    Registry    = @(
        # https://learn.microsoft.com/windows-server/administration/performance-tuning/role/file-server
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'; Name = 'DisableBandwidthThrottling'; Type = 'DWord'; Data = 1 }
    )
}
