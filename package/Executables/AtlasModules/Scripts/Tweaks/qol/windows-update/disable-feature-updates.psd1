@{
    Name        = 'Disable Feature Updates'
    Description = 'Pins Windows Update to the installed Windows release, so a feature update can''t reset settings, bring back removed apps or break the PC. Atlas Manager moves the pin when it moves Windows to a newer release.'
    Registry    = @(
        # The release pin holds Windows on its release, so DeferFeatureUpdates isn't set as well.
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::TargetReleaseVersion
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'TargetReleaseVersion'; Type = 'DWord'; Data = 1 }
    )
    Script      = 'disable-feature-updates.ps1'
}
