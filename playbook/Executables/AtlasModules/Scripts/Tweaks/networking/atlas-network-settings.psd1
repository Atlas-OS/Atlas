@{
    Name        = 'Applies Atlas'' Network Settings'
    Description = 'Applies Atlas'' optimised network settings. Disables vendor NIC power-saving features (green Ethernet, DMA coalescing and similar) for consistent latency, which slightly increases idle power draw - relevant on laptops.'
    Toggle      = @(
        @{ Name = 'DefaultAtlasNetwork'; State = 'AtlasDefault' }
    )
}
