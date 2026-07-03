@{
    Name        = 'Adds Batch Scripts to ''New'' Context Menu'
    Description = 'Adds batch scripts (.bat) to ''New'' context menu'
    Registry    = @(
        @{ Path = 'HKCR\.bat\ShellNew'; Name = 'ItemName'; Type = 'ExpandString'; Data = '%windir%\System32\acppage.dll,-6002' }
        @{ Path = 'HKCR\.bat\ShellNew'; Name = 'NullFile'; Type = 'String'; Data = '' }
    )
}
