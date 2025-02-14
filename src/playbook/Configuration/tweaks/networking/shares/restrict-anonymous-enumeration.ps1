$key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
$valueName = "RestrictAnonymous"
$data = 1

reg add $key /v $valueName /t REG_DWORD /d $data /f

Write-Host "Anonymous enumeration of shares has been restricted successfully."
