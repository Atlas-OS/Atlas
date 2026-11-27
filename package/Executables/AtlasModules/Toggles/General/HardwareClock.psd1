@{
    Name        = 'HardwareClock'
    # Windows reads the clock when it starts, so a restart applies the change. Linux and macOS keep the
    # hardware clock in UTC, so a dual-boot PC shows the wrong time in one system unless both agree.
    Description = 'Sets how Windows reads the hardware clock. Disable treats it as local time, which is the Windows default. Enable treats it as UTC, so a PC that also runs Linux or macOS shows the same time in both.'
    Elevation   = 'Admin'
    Warning     = 'Enable makes Windows read the hardware clock as UTC. If another system on this PC treats it as local time, its clock will be wrong by your UTC offset until it is set to UTC too.'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\Hardware Clock\Disable UTC Hardware Clock (default).cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'; Name = 'RealTimeIsUniversal'; Operation = 'Delete' }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\Hardware Clock\Enable UTC Hardware Clock.cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'; Name = 'RealTimeIsUniversal'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
