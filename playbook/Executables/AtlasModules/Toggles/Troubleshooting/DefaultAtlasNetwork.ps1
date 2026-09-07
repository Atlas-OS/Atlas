function Set-AtlasNetworkDefaultState {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Network
    $mode = if ($Toggle.State -ceq 'AtlasDefault') { 'Atlas' } else { 'Windows' }
    if (-not $Toggle.Silent) {
        if ($mode -ceq 'Atlas') {
            Write-AtlasStep -Text 'Applying the Atlas network adapter defaults...'
        }
        else {
            Write-AtlasStep -Text 'Resetting the network stack and adapters to the Windows defaults. This can take a minute...'
        }
    }
    [void](Set-AtlasNetworkDefaults -Mode $mode)
}
