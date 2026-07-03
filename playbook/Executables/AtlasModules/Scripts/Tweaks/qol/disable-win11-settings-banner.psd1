@{
    Name        = 'Disable Windows 11 Settings Banner'
    Description = 'Disables the Windows 11 Settings banner (ValueBanner), which normally displays ''advertisements'' such as Microsoft 365 on non-Enterprise editions'
    MinBuild    = 22000
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\ValueBanner.IdealStateFeatureControlProvider'; Name = 'ActivationType'; Type = 'DWord'; Data = 0 }
    )
}
