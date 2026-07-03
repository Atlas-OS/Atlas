@{
    Name        = 'Disable Internet File Association Service'
    Description = 'Makes it so that Windows does not ask you if you want to get results from the web for an unknown file extension'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoInternetOpenWith'; Type = 'DWord'; Data = 1 }
    )
}
