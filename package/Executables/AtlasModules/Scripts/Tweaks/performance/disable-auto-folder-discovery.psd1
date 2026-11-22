@{
    Name        = 'Disable Automatic Folder Discovery'
    Description = 'Stops File Explorer working out a folder type, such as Pictures, from each folder''s contents, so large folders open without that scan.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'; Operation = 'DeleteKey'; SkipVerification = 'Resets cached folder views; the following FolderType entry and Explorer recreate this key.' }
        @{ Path = 'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'; Name = 'FolderType'; Type = 'String'; Data = 'NotSpecified' }
    )
}
