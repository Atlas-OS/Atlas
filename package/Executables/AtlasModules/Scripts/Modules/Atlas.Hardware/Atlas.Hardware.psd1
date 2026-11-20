@{
    RootModule        = 'Atlas.Hardware.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b6d41f8e-2c7a-4e59-9a3b-5f0d8c2e7b14'
    Author            = 'AtlasOS'
    Description       = 'Atlas hardware configuration: the documented Atlas AC power policy with rollback to the prior plan, and Plug and Play device enable/disable by friendly name.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasPowerSavingState'
        'Set-AtlasDeviceState'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
