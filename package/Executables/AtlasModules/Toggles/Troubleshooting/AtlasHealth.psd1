@{
    Name          = 'AtlasHealth'
    Description   = 'Reports what Atlas installed and which recorded toggle states or install tweaks have changed since. It changes nothing.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'AtlasHealth.ps1'
    States        = @(
        @{
            Name          = 'Run'
            Launcher      = '9. Troubleshooting\Check Atlas Health.cmd'
            Reboot        = 'None'
            MachineAction = 'Show-AtlasHealthReport'
        }
    )
}
