@{
    Name        = 'Disable Automatic Folder Discovery'
    Description = 'Improves performance in File Explorer by not automatically determining the folder ''type'' (such as pictures) for each folder''s content.'
    Run         = @(
        # Use this instead once AME fixes hives issue
        # - !registryValue:
        #   path: 'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'
        #   value: 'FolderType'
        #   data: 'NotSpecified'
        #   type: REG_SZ
        @{ Exe = '{windir}\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
