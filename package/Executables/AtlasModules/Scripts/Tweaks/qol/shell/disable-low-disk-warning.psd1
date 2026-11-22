@{
    Name        = 'Disable Low Disk Space Checks'
    Description = 'Turns off low disk space warnings. A drive can then fill up without warning, which stops updates and shadow copies working.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoLowDiskSpaceChecks'; Type = 'DWord'; Data = 1 }
    )
}
