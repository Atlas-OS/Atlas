@{
    Name        = 'Indexing'
    # Each state hands its machine work to the installed indexing helper, so a launcher and update
    # replay run the same TrustedInstaller action.
    Description = 'Sets Windows Search indexing to off, minimal or full.'
    Elevation   = 'TrustedInstaller'
    Script      = 'Indexing.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Search Indexing\Disable Search Indexing.cmd'
            Reboot        = 'None'
            MachineAction = 'Disable-AtlasSearchIndexing'
        }
        @{
            Name          = 'Minimal'
            StateValue    = 1
            Launcher      = '3. General Configuration\Search Indexing\Minimal Search Indexing (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Set-AtlasMinimalSearchIndexing'
        }
        @{
            Name          = 'Enable'
            StateValue    = 2
            Launcher      = '3. General Configuration\Search Indexing\Enable Search Indexing.cmd'
            Reboot        = 'None'
            MachineAction = 'Enable-AtlasSearchIndexing'
            InteractiveState = 'Select-AtlasFullIndexingState'
        }
        @{
            Name = 'EnableRespectPowerModes'
            Internal = $true
            NoStateRecord = $true
            MachineAction = 'Set-AtlasSelectedFullIndexing'
        }
        @{
            Name = 'EnableIgnorePowerModes'
            Internal = $true
            NoStateRecord = $true
            MachineAction = 'Set-AtlasSelectedFullIndexing'
        }
    )
}
