@{
    Name        = 'Disable Program Compatibility Assistant (PCA)'
    Description = 'Disables PCA for QoL and privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'AITEnable'; Type = 'DWord'; Data = 0 }
        # DisableEngine turns off the whole app-compat engine; Microsoft documents possible
        # legacy-app breakage (old installers/AV). No field issues observed in Atlas - if a
        # support case ever smells like that, this is the first thing to flip back.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableEngine'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableInventory'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisablePCA'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableUAR'; Type = 'DWord'; Data = 1 }
    )
}
