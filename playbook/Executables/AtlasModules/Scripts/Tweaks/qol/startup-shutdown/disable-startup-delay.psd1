@{
    Name        = 'Disable Startup Delay'
    Description = 'Removes the delay Windows adds before it starts your startup apps.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name = 'StartupDelayInMSec'; Type = 'DWord'; Data = 0 }
    )
}
