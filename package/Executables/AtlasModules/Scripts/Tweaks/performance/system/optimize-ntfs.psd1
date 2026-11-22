@{
    Name        = 'Optimize NTFS'
    Description = 'Stops NTFS recording last-access times and creating short 8.3 file names, which saves disk writes. Backup or storage software that relies on last-access times can be affected.'
    Run         = @(
        # https://learn.microsoft.com/windows-server/administration/windows-commands/fsutil
        # Stop recording last-access times, which saves disk writes.
        # Windows already manages this as off on volumes over 128 GB; value 1 pins it off on
        # every volume. Microsoft documents that backup and remote-storage software relying
        # on last-access timestamps can be affected.
        @{ Exe = '{windir}\System32\fsutil.exe'; Args = @('behavior', 'set', 'disablelastaccess', '1') }
        # Disable the creation of 8.3 character-length file names on FAT- and NTFS-formatted volumes
        # https://learn.microsoft.com/windows-server/administration/windows-commands/fsutil-8dot3name
        @{ Exe = '{windir}\System32\fsutil.exe'; Args = @('8dot3name', 'set', '1') }
    )
}
