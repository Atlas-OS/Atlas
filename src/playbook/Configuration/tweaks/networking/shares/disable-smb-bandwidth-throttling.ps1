$key = "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
$valueName = "DisableBandwidthThrottling"
$data = 1

reg add $key /v $valueName /t REG_DWORD /d $data /f

Write-Host "SMB Bandwidth Throttling has been disabled successfully."
