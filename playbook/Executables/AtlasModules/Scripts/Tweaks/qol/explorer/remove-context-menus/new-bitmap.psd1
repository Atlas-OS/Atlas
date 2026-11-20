@{
    Name        = 'Remove Bitmap Image from ''New'' Context Menu'
    Description = 'Removes Bitmap image from the New context menu.'
    Registry    = @(
        @{ Path = 'HKCR\.bmp\ShellNew'; Operation = 'DeleteKey' }
    )
}
