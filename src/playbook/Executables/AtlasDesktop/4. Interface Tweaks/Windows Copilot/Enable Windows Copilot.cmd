@echo off

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
	exit /b
)

echo Please note that some regions or devices may not have Copilot avaliable.
echo This means that the script can seem to 'not work', but it would do if it was avaliable.
pause

echo]
call "%windir%\AtlasModules\Scripts\edgeCheck.cmd"
if %errorlevel% neq 0 exit /b 1
echo]

echo Enabling Copilot...
taskkill /f /im explorer.exe > nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f > nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "1" /f > nul
start explorer.exe

echo]
echo Finished, changes are applied.
echo Press any key to exit...
pause > nul
exit /b