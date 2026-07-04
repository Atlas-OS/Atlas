@{
    Name        = 'Applies Atlas'' Network Settings'
    Description = 'Applies Atlas'' optimised network settings. Disables vendor NIC power-saving features (green Ethernet, DMA coalescing and similar) for consistent latency, which slightly increases idle power draw - relevant on laptops.'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\9. Troubleshooting\Network\Reset Network to Atlas Default.cmd'; Args = '/silent'; Wait = $true }
    )
}
