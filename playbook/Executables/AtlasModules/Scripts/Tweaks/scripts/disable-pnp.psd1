@{
    OnUpgrade   = 'Skip'
    OnRebase    = 'Run'
    Name        = 'Disable Devices'
    Description = 'Disables the LLDP network adapter binding and PnP devices that most users don''t need, to reduce background resource usage. The File Sharing toggle manages the SMB client, server and discovery bindings.'
    Script      = 'disable-pnp.ps1'
}
