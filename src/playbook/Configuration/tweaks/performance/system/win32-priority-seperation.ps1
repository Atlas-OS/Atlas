$key = "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl"

reg add $key /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f
