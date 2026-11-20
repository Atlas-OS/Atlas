@{
    Name        = 'Disable Program Compatibility Assistant (PCA)'
    Description = 'Turns off the Program Compatibility Assistant and the application compatibility engine, with their service, app inventory and compatibility database task.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'AITEnable'; Type = 'DWord'; Data = 0 }
        # DisableEngine turns off the whole app-compat engine. Microsoft documents that old
        # installers and antivirus can break without the app-compat engine. Revert
        # DisableEngine first when an old program fails to install.
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
