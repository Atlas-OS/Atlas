@{
    Name        = 'AutomaticFolderDiscovery'
    Description = 'Turns automatic folder type discovery in File Explorer on or off.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'; Operation = 'DeleteKey'; SkipVerification = 'Resets cached folder views; the following FolderType entry and Explorer recreate this key.' }
                @{ Path = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'; Name = 'FolderType'; Type = 'String'; Data = 'NotSpecified' }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Enable Automatic Folder Discovery.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders'; Operation = 'DeleteKey' }
            )
        }
    )
}
