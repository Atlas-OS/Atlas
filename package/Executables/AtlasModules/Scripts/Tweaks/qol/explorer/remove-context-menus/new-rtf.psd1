@{
    Name        = 'Remove Rich Text Document from ''New'' Context Menu'
    Description = 'Removes Rich Text Document from the New context menu.'
    Registry    = @(
        @{ Path = 'HKCR\.rtf\ShellNew'; Operation = 'DeleteKey' }
    )
}
