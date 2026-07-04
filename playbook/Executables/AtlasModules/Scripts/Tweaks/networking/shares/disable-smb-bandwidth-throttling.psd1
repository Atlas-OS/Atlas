@{
    Name        = 'Disable SMB Bandwidth Throttling'
    Description = 'Disables SMB client bandwidth throttling. Mainly improves file-share throughput on high-latency links (the redirector throttles there by design); little effect on a LAN. Same setting as Set-SmbClientConfiguration -EnableBandwidthThrottling 0.'
    Registry    = @(
        # https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/file-server
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'; Name = 'DisableBandwidthThrottling'; Type = 'DWord'; Data = 1 }
    )
}
