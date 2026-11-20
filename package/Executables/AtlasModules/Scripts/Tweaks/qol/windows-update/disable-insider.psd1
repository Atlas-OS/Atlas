@{
    Name        = 'Restrict Windows Insider'
    Description = 'Blocks Windows Insider Preview builds and hides the Windows Insider Program page in Settings, avoiding extra data collection, reverted settings and unstable builds.'
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
