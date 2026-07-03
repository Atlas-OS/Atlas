@{
    Name        = 'Disable Windows 11 Settings Banner'
    Description = 'Disables the Windows 11 Settings banner (ValueBanner), which normally displays ''advertisements'' such as Microsoft 365 on non-Enterprise editions'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, where the ValueBanner class does not exist.
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\ValueBanner.IdealStateFeatureControlProvider'; Name = 'ActivationType'; Type = 'DWord'; Data = 0 }
    )
}
