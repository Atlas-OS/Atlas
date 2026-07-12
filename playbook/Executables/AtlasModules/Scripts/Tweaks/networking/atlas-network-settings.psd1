@{
    Name        = 'Applies Atlas'' Network Settings'
    Description = 'Applies Atlas'' optimised network settings. Disables vendor NIC power-saving features (green Ethernet, DMA coalescing and similar) for consistent latency, which slightly increases idle power draw - relevant on laptops.'
    Run         = @(
        @{
            Exe  = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
            Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Invoke-AtlasInstallMachineToggle.ps1', '-Name', 'DefaultAtlasNetwork')
            Wait = $true
        }
    )
}
