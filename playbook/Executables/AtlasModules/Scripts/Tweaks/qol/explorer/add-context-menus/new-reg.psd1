@{
    Name        = 'Add Registry Entries to ''New'' Context Menu'
    Description = 'Adds registry entries (.reg) to ''New'' context menu'
    Registry    = @(
        @{ Path = 'HKCR\.reg\ShellNew'; Name = 'NullFile'; Type = 'String'; Data = '' }
        @{ Path = 'HKCR\.reg\ShellNew'; Name = 'ItemName'; Type = 'ExpandString'; Data = '%windir%\regedit.exe,-309' }
    )
}
