@{
    Name        = 'Disable Feature Updates'
    Description = 'Disables feature updates as they might reset tweaks, bring back bloatware and potentially break the system.'
    Registry    = @(
        # Intentionally not applied:
        # @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'DeferFeatureUpdates'; Type = 'DWord'; Data = 1 }
        # @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'DeferFeatureUpdatesPeriodInDays'; Type = 'DWord'; Data = 365 }
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::TargetReleaseVersion
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'TargetReleaseVersion'; Type = 'DWord'; Data = 1 }
    )
    Script      = 'disable-feature-updates.ps1'
}
