@{
    Name        = 'Disable Delivery Optimization'
    Description = 'Disables Delivery Optimization to make sure that no bandwidth is used in the background for peer-to-peer Windows Updates'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name = 'DODownloadMode'; Type = 'DWord'; Data = 0 }
    )
}
