@echo off
setlocal EnableDelayedExpansion

taskkill /f /im OneDriveSetup.exe > nul 2>&1
taskkill /f /im OneDrive.exe > nul 2>&1
taskkill /f /im OneDriveStandaloneUpdater.exe > nul 2>&1

"%windir%\System32\OneDriveSetup.exe" /uninstall
"%windir%\SysWOW64\OneDriveSetup.exe" /uninstall

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
	reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul
	if not !errorlevel! == 1 (
		call :USERREG "%%a"
	)
)

rmdir /q /s "C:\ProgramData\Microsoft OneDrive" > nul
rmdir /q /s "%localappdata%\Microsoft\OneDrive" > nul

for /f "usebackq delims=" %%a in (`dir /b /a:d "C:\Users"`) do (
	rmdir /q /s "C:\Users\%%a\AppData\Local\Microsoft\OneDrive" > nul
	rmdir /q /s "C:\Users\%%a\OneDrive" > nul
	del /q /f "C:\Users\%%a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" > nul
)

for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager" ^| findstr /i /c:"OneDrive"`) do reg delete "%%a" /f

for /f "tokens=2 delims=\" %%a in ('schtasks /query /fo list /v ^| findstr /c:"\OneDrive Reporting Task" /c:"\OneDrive Standalone Update Task"') do (
	schtasks /delete /tn "%%a" /f > nul
)

exit /b

:USERREG
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BannerStore" ^| findstr /i /c:"OneDrive"`) do (
	reg delete "%%a" /f > nul
)
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers" ^| findstr /i /c:"OneDrive"`) do (
	reg delete "%%a" /f > nul
)
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths" ^| findstr /i /c:"OneDrive"`) do (
	reg delete "%%a" /f > nul
)
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" ^| findstr /i /c:"OneDrive"`) do (
	reg delete "%%a" /f > nul
)

reg delete "HKU\%~1\Environment" /v "OneDrive" /f > nul
