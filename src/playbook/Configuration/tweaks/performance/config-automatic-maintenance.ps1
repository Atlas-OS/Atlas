$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance"
reg add $key /v "WakeUp" /t REG_DWORD /d 0 /f
