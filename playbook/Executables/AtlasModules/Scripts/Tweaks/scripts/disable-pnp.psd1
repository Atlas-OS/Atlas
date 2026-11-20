@{
    OnUpgrade   = 'Skip'
    OnRebase    = 'Run'
    Name        = 'Disable Devices'
    Description = 'Turns off the LLDP network adapter binding and devices most PCs don''t use, to reduce background work. The File Sharing toggle manages the SMB and discovery bindings.'
    Script      = 'disable-pnp.ps1'
}
