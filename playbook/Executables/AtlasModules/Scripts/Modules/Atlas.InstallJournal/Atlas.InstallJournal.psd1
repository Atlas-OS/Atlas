@{
    RootModule        = 'Atlas.InstallJournal.psm1'
    ModuleVersion     = '0.2.1'
    GUID              = 'b21d29b6-b919-4d72-a4e4-7d38e3a69fc8'
    Author            = 'AtlasOS'
    Description       = 'Durable Atlas-owned install transaction journal and recovery checkpoints.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-AtlasInstallJournalPath'
        'Initialize-AtlasInstallJournalStore'
        'New-AtlasInstallJournal'
        'Get-AtlasInstallJournal'
        'Resume-AtlasInstallJournal'
        'Get-AtlasInstallResumePlan'
        'Start-AtlasInstallJournalPhase'
        'Skip-AtlasInstallJournalPhase'
        'Complete-AtlasInstallJournalPhase'
        'Set-AtlasInstallJournalPhaseFailed'
        'Resolve-AtlasInterruptedJournalPhase'
        'Register-AtlasInstallCompensation'
        'Get-AtlasInstallCompensationPlan'
        'Start-AtlasInstallCompensation'
        'Resolve-AtlasInstallCompensation'
        'Complete-AtlasInstallCompensation'
        'Set-AtlasInstallCompensationFailed'
        'Complete-AtlasInstallJournal'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
