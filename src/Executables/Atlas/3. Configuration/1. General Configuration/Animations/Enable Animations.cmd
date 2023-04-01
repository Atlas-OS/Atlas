@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /f > nul
reg delete "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9e3e078012000000" /f > nul

echo Finished, please reboot your device or login and log out for changes to apply.
pause
exit /b
