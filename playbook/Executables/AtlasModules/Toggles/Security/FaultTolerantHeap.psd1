@{
    Name        = 'FaultTolerantHeap'
    Description = 'Fault Tolerant Heap (FTH) mitigation.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '7. Security\Mitigations\Fault Tolerant Heap\Disable FTH (default).cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\FTH'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '7. Security\Mitigations\Fault Tolerant Heap\Enable FTH.cmd'
            Reboot     = 'Recommend'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\FTH'; Name = 'Enabled'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
