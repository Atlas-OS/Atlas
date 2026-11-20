@{
    Name          = 'FixMSStoreIssues'
    Description   = 'Fixes Microsoft Store issues: removes AppX deployment rows left by packages that are no longer registered, or runs StoreFixer when there are none. Records no state.'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    Script        = 'FixMSStoreIssues.ps1'
    States        = @(
        @{
            Name          = 'Run'
            Launcher      = '9. Troubleshooting\Fix MS Store Issues.cmd'
            Reboot        = 'None'
            MachineAction = 'Invoke-AtlasStoreFixer'
        }
    )
}
