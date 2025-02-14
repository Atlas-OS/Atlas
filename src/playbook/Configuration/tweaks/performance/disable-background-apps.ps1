$key1 = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
reg add $key1 /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f

$key2 = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
reg add $key2 /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f
