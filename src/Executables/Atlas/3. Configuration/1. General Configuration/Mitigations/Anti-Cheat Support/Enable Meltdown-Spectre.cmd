@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable Control Flow Guard (CFG) for Valorant related processes
for %%a in (valorant valorant-win64-shipping vgtray vgc) do (
    PowerShell -NoP -C "Set-ProcessMitigation -Name %%a.exe -Enable CFG"
)

:: Enable Spectre and Meltdown
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f > nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b