@{
    Name        = 'Remove Rich Text Document from ''New'' Context Menu'
    Description = 'Removes rich text document from ''New'' context menu'
    Registry    = @(
        @{ Path = 'HKCR\.rtf\ShellNew'; Operation = 'DeleteKey' }
    )
}
