@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call setSvc.cmd WSearch 4
sc stop WSearch > nul 2>&1

:: Hide Settings page
set "pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
reg query "!pageKey!" /v "SettingsPageVisibility" > nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f "usebackq tokens=3" %%a in (`reg query "!pageKey!" /v "SettingsPageVisibility"`) do (
        reg add "!pageKey!" /v "SettingsPageVisibility" /t REG_SZ /d "%%a;cortana-windowssearch;" /f > nul
    )
) else (
    reg add "!pageKey!" /v "SettingsPageVisibility" /t REG_SZ /d "hide:cortana-windowssearch;" /f > nul
)

echo Finished.
pause
exit /b