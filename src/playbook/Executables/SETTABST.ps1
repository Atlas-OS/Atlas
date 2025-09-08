param (
    [string]$Browser
)
if (!$Browser) {
    $ArgString = "`"${Env:WinDir}\AtlasModules\Scripts\taskbarPins.ps1`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File $ArgString"
    $Trigger = New-ScheduledTaskTrigger -AtLogon
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:COMPUTERNAME\$env:USERNAME" -LogonType Interactive -RunLevel Highest

    Register-ScheduledTask -TaskName "TaskBarPins" -Action $Action -Trigger $Trigger -Principal $Principal -Force
}
else {
    $ArgString = "`"${Env:WinDir}\AtlasModules\Scripts\taskbarPins.ps1`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File $ArgString `"$Browser`""
    $Trigger = New-ScheduledTaskTrigger -AtLogon
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:COMPUTERNAME\$env:USERNAME" -LogonType Interactive -RunLevel Highest

    Register-ScheduledTask -TaskName "TaskBarPins" -Action $Action -Trigger $Trigger -Principal $Principal -Force

}



