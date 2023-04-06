@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Disable the option for Microsoft Store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f > nul 2>&1

:: Block access to Microsoft Store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f > nul 2>&1

call setSvc,cmd AppXSvc 3
call setSvc,cmd BFE 2
call setSvc,cmd ClipSVC 3
call setSvc,cmd InstallService 3
call setSvc,cmd LicenseManager 3
call setSvc,cmd mpssvc 2
call setSvc,cmd TabletInputService 3
call setSvc,cmd TokenBroker 3
call setSvc,cmd WinHttpAutoProxySvc 3
call setSvc,cmd wlidsvc 3

taskkill /f /im StartMenuExperienceHost* > nul 2>&1
ren %windir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
taskkill /f /im SearchApp* > nul 2>&1
ren %windir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy.old Microsoft.Windows.Search_cw5n1h2txyewy
ren %windir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old Microsoft.XboxGameCallableUI_cw5n1h2txyewy
ren %windir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe
taskkill /f /im RuntimeBroker* > nul 2>&1
ren %windir%\System32\RuntimeBroker.exe.old RuntimeBroker.exe
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f > nul 2>&1
taskkill /f /im explorer.exe
start explorer.exe

echo Finished, please reboot your device for changes to apply.
pause
exit /b