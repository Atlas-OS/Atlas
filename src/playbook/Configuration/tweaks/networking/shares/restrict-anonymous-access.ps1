$key = "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$valueName = "RestrictNullSessAccess"
$data = 1

reg add $key /v $valueName /t REG_DWORD /d $data /f
