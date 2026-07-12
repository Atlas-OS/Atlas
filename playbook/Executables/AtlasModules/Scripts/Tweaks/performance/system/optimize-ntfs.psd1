@{
    Name        = 'Optimize NTFS'
    Description = 'Optimizes NTFS options for optimal QoL, performance and privacy'
    Run         = @(
        # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil
        # Disable last access information on directories, performance/privacy.
        # Note: since 1803 the OS default is already system-managed-off on volumes >128 GB;
        # value 1 pins the choice. MS documents that backup/remote-storage software relying
        # on last-access timestamps can be affected.
        @{ Exe = '{windir}\System32\fsutil.exe'; Args = @('behavior', 'set', 'disablelastaccess', '1') }
        # Disable the creation of 8.3 character-length file names on FAT- and NTFS-formatted volumes
        # https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security
        @{ Exe = '{windir}\System32\fsutil.exe'; Args = @('8dot3name', 'set', '1') }
    )
}
