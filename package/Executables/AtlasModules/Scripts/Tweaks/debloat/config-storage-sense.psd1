@{
    Name           = 'Configure Storage Sense'
    Description    = 'Turns on Storage Sense to delete temporary files every month. It leaves the Downloads folder, the Recycle Bin and OneDrive files alone.'
    Registry       = @(
        # Reference: https://gist.github.com/he3als/3d9dcf6e796aa920c24a98130165fb17
        # Enable Storage Sense
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '01'; Type = 'DWord'; Data = 1 }
        # Run Storage Sense
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '1024'; Type = 'DWord'; Data = 1 }
        # Run Storage Sense every month
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '2048'; Type = 'DWord'; Data = 30 }
        # Enable cleaning temporary files
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '04'; Type = 'DWord'; Data = 1 }
        # Disable the 'Downloads' from being cleared
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '32'; Type = 'DWord'; Data = 0 }
        # Disable OneDrive cleanup
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '02'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '128'; Type = 'DWord'; Data = 0 }
        # Disable Recycle Bin cleanup
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '08'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name = '256'; Type = 'DWord'; Data = 0 }
    )
    ScheduledTasks = @(
        # Enable cleaning temp files
        @{ Path = '\Microsoft\Windows\DiskCleanup\SilentCleanup'; Operation = 'Enable' }
    )
    # The OneDrive cleanup subkeys aren't set, because Atlas removes OneDrive.
}
