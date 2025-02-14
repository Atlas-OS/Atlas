$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
$valueName = "EnableMulticast"
$data = 0

reg add $key /v $valueName /t REG_DWORD /d $data /f

Write-Host "LLMNR protocol has been disabled successfully."
