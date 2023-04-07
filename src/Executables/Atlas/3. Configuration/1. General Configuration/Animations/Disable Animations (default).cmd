@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_DWORD /d "0" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f > nul
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f > nul

echo Finished, please reboot your device or login and log out for changes to apply.
pause
exit /b
