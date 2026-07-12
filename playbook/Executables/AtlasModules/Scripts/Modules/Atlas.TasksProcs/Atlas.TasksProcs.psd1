@{
    RootModule        = 'Atlas.TasksProcs.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '1c9e7b34-2d5f-4a86-b0e1-6f4d8c2a9b73'
    Author            = 'AtlasOS'
    Description       = 'Atlas scheduled-task and process helpers with session-aware stopping and Explorer recovery.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Disable-AtlasScheduledTask'
        'Enable-AtlasScheduledTask'
        'Remove-AtlasScheduledTask'
        'Stop-AtlasProcess'
        'Wait-AtlasExplorerShellRecovery'
        'Stop-AtlasProcessUnderRoot'
        'Stop-AtlasScheduledTaskUnderRoot'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
