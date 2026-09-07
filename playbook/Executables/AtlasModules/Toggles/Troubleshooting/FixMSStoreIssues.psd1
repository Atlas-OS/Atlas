@{
    Name          = 'FixMSStoreIssues'
    Description   = 'Fixes Microsoft Store issues by running StoreFixer. Records no state.'
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
