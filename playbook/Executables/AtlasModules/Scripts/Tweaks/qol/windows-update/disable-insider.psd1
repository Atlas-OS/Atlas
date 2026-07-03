@{
    Name        = 'Restrict Windows Insider'
    Description = 'Forcefully restricts Windows Insider from being enabled to prevent extra data collection, tweaks being reverted and general instability.'
    Registry    = @(
        # Disable Windows Insider
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::ManagePreviewBuilds
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'ManagePreviewBuilds'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'ManagePreviewBuildsPolicyValue'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds'; Name = 'AllowBuildPreview'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds'; Name = 'EnableConfigFlighting'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds'; Name = 'EnableExperimentation'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility'; Name = 'HideInsiderPage'; Type = 'DWord'; Data = 1 }
    )
}
