@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Enable the option for Microsoft Store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f > nul 2>&1

:: Allow access to Microsoft Store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f > nul 2>&1

!setSvcScript! AppXSvc 3
!setSvcScript! ClipSVC 3
!setSvcScript! FileCrypt 1
!setSvcScript! FileInfo 0
!setSvcScript! InstallService 3
!setSvcScript! LicenseManager 3
!setSvcScript! TokenBroker 3
!setSvcScript! WinHttpAutoProxySvc 3
!setSvcScript! wlidsvc 3

echo Finished, please reboot your device for changes to apply.
pause
exit /b