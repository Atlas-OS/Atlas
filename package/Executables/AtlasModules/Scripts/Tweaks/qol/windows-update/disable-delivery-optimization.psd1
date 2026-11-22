@{
    Name        = 'Disable Delivery Optimization'
    Description = 'Turns off Delivery Optimization peer-to-peer downloads, so this PC doesn''t share update data with other PCs in the background.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name = 'DODownloadMode'; Type = 'DWord'; Data = 0 }
    )
}
