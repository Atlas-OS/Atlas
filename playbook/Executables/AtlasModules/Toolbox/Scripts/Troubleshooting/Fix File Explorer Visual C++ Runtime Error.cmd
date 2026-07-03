@echo off
setlocal
set "silent="
if /i "%~1"=="/silent" set "silent=1"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath 'cmd.exe' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if not defined silent pause
		exit /b 1
	)
	exit /b
)

if not defined silent (
	echo This will remove the legacy File Explorer search redirect used by older Atlas builds.
	echo It can fix blank Microsoft Visual C++ Runtime Library errors from explorer.exe.
	echo]
	pause
	cls
)

echo Restoring modern File Explorer search...
call :deleteKey "HKLM\SOFTWARE\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
call :deleteKey "HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
call :deleteKey "HKLM\SOFTWARE\WOW6432Node\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
call :deleteKey "HKCU\Software\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
call :deleteKey "HKCU\Software\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"

for /f "tokens=*" %%a in ('reg query HKU 2^>nul ^| findstr /r /c:"HKEY_USERS\\S-1-5-21"') do (
	call :deleteKey "%%a\Software\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
	call :deleteKey "%%a\Software\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
)

echo Restarting File Explorer...
taskkill /f /im explorer.exe > nul 2>&1
start "" "%windir%\explorer.exe"

echo Finished.
if defined silent exit /b
pause
exit /b

:deleteKey
reg delete "%~1" /f > nul 2>&1
exit /b
