@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call setSvc.cmd WSearch 2

:: Hide Settings pages
set "pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
reg query "%pageKey%" /v "SettingsPageVisibility" > nul 2>&1
if "%errorlevel%" == "0" call :enableSettingsPage

echo Finished, please reboot your device for changes to apply.
pause
exit /b

:enableSettingsPage
for /f "usebackq tokens=3" %%a in (`reg query "%pageKey%" /v "SettingsPageVisibility"`) do (set "currentPages=%%a")
reg add "%pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "%currentPages:cortana-windowssearch;=%" /f > nul
exit /b