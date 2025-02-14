# Disables SMB Bandwidth Throttling for improved performance
function Disable-SMBBandwidthThrottling {
    $key = "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
    $valueName = "DisableBandwidthThrottling"
    $data = 1

    reg add $key /v $valueName /t REG_DWORD /d $data /f
}

# Blocks anonymous access to named pipes and shares
function Block-AnonymousAccess {
    $key = "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
    $valueName = "RestrictNullSessAccess"
    $data = 1

    reg add $key /v $valueName /t REG_DWORD /d $data /f
}

# Blocks anonymous enumeration of shares
function Block-AnonymousEnumeration {
    $key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
    $valueName = "RestrictAnonymous"
    $data = 1

    reg add $key /v $valueName /t REG_DWORD /d $data /f
}

# Sets Atlas' optimized network settings
function Set-AtlasNetworkSettings {
    $scriptPath = "AtlasDesktop\8. Troubleshooting\Network\Reset Network to Atlas Default.cmd"

    Start-Process -FilePath $scriptPath -ArgumentList "/silent" -NoNewWindow -Wait
}

function Disable-LLMNR {
    $key = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    $valueName = "EnableMulticast"
    $data = 0

    reg add $key /v $valueName /t REG_DWORD /d $data /f
}

function Invoke-AllNetworkingOptimizations {
    Disable-SMBBandwidthThrottling
    Block-AnonymousAccess
    Block-AnonymousEnumeration
    Set-AtlasNetworkSettings
    Disable-LLMNR
}

Export-ModuleMember -Function Invoke-AllNetworkingOptimizations