@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call setSvc.cmd DPS 2
call setSvc.cmd WdiServiceHost 3
call setSvc.cmd WdiSystemHost 3

for %%a in (
	"Microsoft-Windows-SleepStudy/Diagnostic"
	"Microsoft-Windows-Kernel-Processor-Power/Diagnostic"
	"Microsoft-Windows-UserModePowerService/Diagnostic"
) do (
	wevtutil sl "%%~a" /q:true > nul
)
schtasks /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b