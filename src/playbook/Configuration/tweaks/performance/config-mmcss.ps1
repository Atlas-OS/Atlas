$key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
reg add $key /v "SystemResponsiveness" /t REG_DWORD /d 10 /f
