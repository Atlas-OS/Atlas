@{
    Name        = 'Disable Devices'
    Description  = 'Disables network adapter bindings and PnP devices that most users do not need, to reduce background resource usage. Note: this includes the SMB client and server bindings - accessing network shares (\\NAS) and sharing files/printers from this PC stop working until the bindings are re-enabled.'
    Script       = 'disable-pnp.ps1'
}
