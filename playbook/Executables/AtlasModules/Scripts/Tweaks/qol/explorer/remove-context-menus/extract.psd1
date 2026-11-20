@{
    Name        = 'Remove ''Extract'' from Context Menu'
    Description = 'Removes the Extract entries from the context menu of archives through the ExtractContextMenu toggle.'
    Toggle      = @(
        @{ Name = 'ExtractContextMenu'; State = 'Disable' }
    )
}
