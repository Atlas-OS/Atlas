@{
    Name        = 'Optimize NTFS'
    Description = 'Optimizes NTFS options for optimal QoL, performance and privacy'
    Run         = @(
        # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil
        # Disable last access information on directories, performance/privacy
        @{ Exe = 'fsutil'; Args = 'behavior set disablelastaccess 1' }
        # Disable the creation of 8.3 character-length file names on FAT- and NTFS-formatted volumes
        # https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security
        @{ Exe = 'fsutil'; Args = '8dot3name set 1' }
    )
}
