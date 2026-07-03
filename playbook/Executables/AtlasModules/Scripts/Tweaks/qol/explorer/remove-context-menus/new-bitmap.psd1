@{
    Name        = 'Remove Bitmap Image from ''New'' Context Menu'
    Description = 'Removes bitmap image from the ''New'' context menu'
    Registry    = @(
        @{ Path = 'HKCR\.bmp\ShellNew'; Operation = 'DeleteKey' }
    )
}
