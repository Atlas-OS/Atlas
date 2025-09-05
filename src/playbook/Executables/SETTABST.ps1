param (
    [string]$Browser
)
if (!$Browser) {
    $Command = "& 'C:\Windows\AtlasModules\Scripts\taskbarPins.ps1'"
} else {
    $Command = "& 'C:\Windows\AtlasModules\Scripts\taskbarPins.ps1' '$Browser'"
}

Register-ScheduledTask -TaskName "TASKBARPINS" -Trigger (New-ScheduledTaskTrigger -AtStartup) `
 -Action (New-ScheduledTaskAction `
 -Execute "${Env:WinDir}\System32\WindowsPowerShell\v1.0\powershell.exe" `
 -Argument "-WindowStyle Hidden -Command `"$Command`"") `
 -RunLevel Highest -Force
