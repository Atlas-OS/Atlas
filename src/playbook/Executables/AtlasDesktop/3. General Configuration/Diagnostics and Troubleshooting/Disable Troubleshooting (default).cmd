@echo off

if "%~1"=="/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
for %%a in (
	"WdiServiceHost"
	"WdiSystemHost"
) do (
	call "%windir%\AtlasModules\Scripts\setSvc.cmd" %%~a 4
)

for %%a in (
	"Microsoft-Windows-SleepStudy/Diagnostic"
	"Microsoft-Windows-Kernel-Processor-Power/Diagnostic"
	"Microsoft-Windows-UserModePowerService/Diagnostic"
) do (
	wevtutil sl "%%~a" /q:false > nul
)
schtasks /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable > nul

if "%~1"=="/silent" exit /b

echo Although it's one less service, disabling DPS breaks Battery Levels ^& Data Usage in Settings.
choice /c:yn /n /m "Would you like to disable it? [Y/N] "
if %ERRORLEVEL% == 1 call setSvc.cmd DPS 4

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b