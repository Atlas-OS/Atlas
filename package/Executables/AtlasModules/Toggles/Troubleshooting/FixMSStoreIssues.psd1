@{
    Name          = 'FixMSStoreIssues'
    Description   = 'Fixes common Microsoft Store problems by running StoreFixer.'
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
