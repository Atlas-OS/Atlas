@{
    Name        = 'Disable Internet File Association Service'
    Description = 'Stops Windows offering to look online for an app when you open a file with an unknown extension.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoInternetOpenWith'; Type = 'DWord'; Data = 1 }
    )
}
