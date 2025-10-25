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

echo Disabling and uninstalling Copilot...

powershell -NoP -NonI "Get-AppxPackage -AllUsers Microsoft.Copilot* | Remove-AppxPackage -AllUsers"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f > nul
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f > nul
if /I not "%~2"=="/noAction" powershell -command "stop-process -name explorer -force"


echo]
echo Finished, changes are applied.
echo Press any key to exit...
pause > nul
exit /b
