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
    $scriptPath = "C:\Windows\AtlasDesktop\8. Troubleshooting\Network\Reset Network to Atlas Default.cmd"

    Start-Process -FilePath $scriptPath -ArgumentList "/silent" -NoNewWindow -Wait
}

function Disable-LLMNR {
    $key = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    $valueName = "EnableMulticast"
    $data = 0

    reg add $key /v $valueName /t REG_DWORD /d $data /f
}

function Invoke-AllNetworkingOptimizations {
    Write-Host "Disalbing smb bandwith throttling"
    Disable-SMBBandwidthThrottling
    Write-Host "Block anonymous access"
    Block-AnonymousAccess
    Write-Host "block annonymous enumeration"
    Block-AnonymousEnumeration
    Write-Host "setting atlas default network setttings"
    Set-AtlasNetworkSettings
    Write-Host "disabling llmnr"
    Disable-LLMNR
}

Export-ModuleMember -Function Invoke-AllNetworkingOptimizations