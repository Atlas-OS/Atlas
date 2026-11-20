@{
    Name        = 'Apply Atlas Network Settings'
    Description = 'Applies the Atlas network adapter defaults through the DefaultAtlasNetwork toggle. It turns off adapter power-saving features such as Green Ethernet and DMA coalescing for steadier latency, which slightly raises idle power use on laptops.'
    Toggle      = @(
        @{ Name = 'DefaultAtlasNetwork'; State = 'Enable' }
    )
}
