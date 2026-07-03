@{
    Name        = 'Disable Program Compatibility Assistant (PCA)'
    Description = 'Disables PCA for QoL and privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'AITEnable'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableEngine'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableInventory'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisablePCA'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableUAR'; Type = 'DWord'; Data = 1 }
    )
}
