@{
    Name        = 'Disable Windows 11 Settings Banner'
    Description = 'Hides the banner at the top of Settings, which shows offers such as Microsoft 365 on editions other than Enterprise.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\ValueBanner.IdealStateFeatureControlProvider'; Name = 'ActivationType'; Type = 'DWord'; Data = 0 }
    )
}
