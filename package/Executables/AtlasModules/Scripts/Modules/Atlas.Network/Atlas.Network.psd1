@{
    RootModule        = 'Atlas.Network.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c3f2a8d1-5b64-4e0f-9a7c-1d2e6b8f4a93'
    Author            = 'AtlasOS'
    Description       = 'Atlas network configuration: adapter power-saving defaults, the Windows network stack reset, and the File Sharing machine state (adapter bindings, NetBIOS, NetBT, network profiles, firewall groups and the Sharing context menu).'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasNetworkDefaults'
        'Enable-AtlasFileSharing'
        'Disable-AtlasFileSharing'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
