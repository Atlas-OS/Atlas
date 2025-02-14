$key = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

reg add $key /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f

reg add $key /v "DisablePageCombining" /t REG_DWORD /d 1 /f
