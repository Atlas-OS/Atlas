@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Disabling UAC breaks fullscreen on certain UWP applications, one of them being Minecraft Windows 10 Edition.
echo It may also break drag and dropping between certain applications.
echo It is also less secure to disable UAC, as every application you run has complete access to your computer.
echo]
echo With UAC disabled, everything runs as admin, and you can not change that without enabling UAC.
echo]
choice /c:yn /n /m "Do you want to continue? [Y/N] "
if !errorlevel! == 1 goto uacDconfirm
if !errorlevel! == 2 exit /b

:uacDconfirm
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "0" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "0" /f > nul 2>&1

:: Lock UserAccountControlSettings.exe - users can enable UAC from there without luafv enabled, which breaks UAC completely and causes issues
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /t REG_SZ /d "\"C:\Users\%username%\Desktop\Atlas\3. Configuration\1. General Configuration\UAC\Enable UAC (default).cmd\" /uacSettings" /f > nul 2>&1

call setSvc.cmd luafv 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b