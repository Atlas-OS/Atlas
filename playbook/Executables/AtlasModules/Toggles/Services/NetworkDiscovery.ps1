function Enable-AtlasNetworkDiscoveryServices {
    param($Toggle)

    # Lanman Workstation (SMB) is a machine dependency. The closed service-defaults
    # reset already applies it immediately before NetworkDiscovery.
    if (-not $Toggle.ResetServices) {
        Invoke-AtlasToggleMachineState -Name 'LanmanWorkstation' -State 'Enable' -StateRoot $Toggle.StateRoot
    }

    Set-AtlasServiceStartup -Name 'eventlog' -StartupType 2
    foreach ($serviceName in @('fdPHost', 'FDResPub', 'lmhosts', 'netman', 'NlaSvc', 'SSDPSRV')) {
        Set-AtlasServiceStartup -Name $serviceName -StartupType 3
    }
}
