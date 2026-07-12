@{
    Name        = 'Disable Automatic Folder Discovery'
    Description = 'Improves performance in File Explorer by not automatically determining the folder ''type'' (such as pictures) for each folder''s content.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'; Name = 'FolderType'; Type = 'String'; Data = 'NotSpecified' }
    )
}
