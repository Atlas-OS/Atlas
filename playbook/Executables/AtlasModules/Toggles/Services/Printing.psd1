@{
    Name        = 'Printing'
    Description = 'Printing services, Windows features and the Print context menu entries. The context menu part can be run alone with /justcontext.'
    Elevation   = 'Admin'
    Warning     = 'Changes the printing services and Windows printing features. While disabled, printers, Print to PDF, XPS and the Print Management console do not work.'
    Script      = 'Printing.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '6. Advanced Configuration\Services\Printing\Disable Printing.cmd'
            Reboot        = 'Recommend'
            ContextAction = 'Set-AtlasPrintContextMenu'
            MachineAction = 'Set-AtlasPrintingMachineState'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Services\Printing\Enable Printing (default).cmd'
            Reboot        = 'Recommend'
            ContextAction = 'Set-AtlasPrintContextMenu'
            MachineAction = 'Set-AtlasPrintingMachineState'
        }
    )
}
