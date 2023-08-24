@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

for %%a in (
	"WdiServiceHost"
	"WdiSystemHost"
) do (
	call setSvc.cmd %%~a 4
)

choice /c:yn /n /m "Would you like to disable Diagnostic Policy Service (DPS)? Note: It breaks Data Usage page in Settings [Y/N] "
if !errorlevel! == 1 call setSvc.cmd DPS 4

:: Disable DiagLog autologger
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" /v "Start" /t REG_DWORD /d "0" /f > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b