@{
    Name        = 'Disable Startup Delay'
    Description = 'Disables the startup delay of startup applications'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name = 'StartupDelayInMSec'; Type = 'DWord'; Data = 0 }
    )
}
