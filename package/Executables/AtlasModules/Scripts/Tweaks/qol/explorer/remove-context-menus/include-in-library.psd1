@{
    Name        = 'Remove ''Include in Library'' from Context Menu'
    Description = 'Removes Include in library from the context menu.'
    Registry    = @(
        @{ Path = 'HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location'; Operation = 'DeleteKey' }
    )
}
