@{
    Name        = 'Remove ''Share'' from Context Menu'
    Description = 'Removes Share from the context menu.'
    Registry    = @(
        # '*' is a literal key name under HKCR (all file types)
        @{ Path = 'HKCR\*\shellex\ContextMenuHandlers\ModernSharing'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing'; Operation = 'DeleteKey' }
    )
}
