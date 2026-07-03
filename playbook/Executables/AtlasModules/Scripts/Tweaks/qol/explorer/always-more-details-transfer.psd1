@{
    Name        = 'Show More Details by Default on Transfers'
    Description = 'Shows more details by default on file transfers such as exact speed of files copying, moving, deleting, etc.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager'; Name = 'EnthusiastMode'; Type = 'DWord'; Data = 1 }
    )
}
