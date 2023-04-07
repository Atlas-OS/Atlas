@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable the option for Microsoft Store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f > nul 2>&1

:: Allow access to Microsoft Store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f > nul 2>&1

call setSvc.cmd AppXSvc 3
call setSvc.cmd ClipSVC 3
call setSvc.cmd FileCrypt 1
call setSvc.cmd FileInfo 0
call setSvc.cmd InstallService 3
call setSvc.cmd LicenseManager 3
call setSvc.cmd TokenBroker 3
call setSvc.cmd WinHttpAutoProxySvc 3
call setSvc.cmd wlidsvc 3

echo Finished, please reboot your device for changes to apply.
pause
exit /b