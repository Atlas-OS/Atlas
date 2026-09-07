@{
    Name        = 'Disable Program Compatibility Assistant (PCA)'
    Description = 'Disables PCA policies, its service and its compatibility-database task for QoL and privacy'
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
    # PcaSvc re-enables PcaPatchDbTask when it starts, even with DisablePCA set.
    # Services run before ScheduledTasks: prevent another start and stop the current
    # instance before disabling the task, so delayed service startup cannot undo it.
    Services = @(
        @{ Name = 'PcaSvc'; StartupType = 4 }
        @{ Name = 'PcaSvc'; Operation = 'Stop' }
    )
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Application Experience\PcaPatchDbTask' }
    )
}
