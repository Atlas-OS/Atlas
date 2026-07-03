@{
    Name        = 'Extend Icon Cache'
    Description = 'Extends the icon cache to 4MB for better explorer responsiveness'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'Max Cached Icons'; Type = 'String'; Data = '4096' }
    )
}
