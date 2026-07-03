@{
    Name        = 'Block Razer Software Auto Install'
    Description = 'Blocks automatic Razer software installation on newly connected Razer devices or fresh install'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching'; Name = 'SearchOrderConfig'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer'; Name = 'DisableCoInstallers'; Type = 'DWord'; Data = 1 }
    )
    Script      = 'block-razer-installs.ps1'
}
