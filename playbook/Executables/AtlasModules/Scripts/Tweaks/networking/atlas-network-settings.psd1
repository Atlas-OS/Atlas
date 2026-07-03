@{
    Name        = 'Applies Atlas'' Network Settings'
    Description = 'Applies Atlas'' optimised network settings'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\9. Troubleshooting\Network\Reset Network to Atlas Default.cmd'; Args = '/silent'; Wait = $true }
    )
}
