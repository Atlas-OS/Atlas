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

for %%a in (
	"Microsoft-Windows-SleepStudy/Diagnostic"
	"Microsoft-Windows-Kernel-Processor-Power/Diagnostic"
	"Microsoft-Windows-UserModePowerService/Diagnostic"
) do (
	wevtutil sl "%%~a" /q:false > nul
)
schtasks /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable > nul

echo Finished, changes have been applied.
pause
exit /b
