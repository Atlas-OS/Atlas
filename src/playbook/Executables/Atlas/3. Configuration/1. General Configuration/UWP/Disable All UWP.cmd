@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

if exist "C:\Program Files\Open-Shell" goto uwpDisableContinue
if exist "C:\Program Files (x86)\StartIsBack" goto uwpDisableContinue
echo It seems neither Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the start menu being removed.
pause & exit /b 1

:uwpDisableContinue
echo This will remove all UWP packages that are currently installed. This will break multiple features that WILL NOT be supported while disabled.
echo A reminder of a few things this may break.
echo - Adobe XD
echo - Immersive Control Panel (Settings app)
echo - Microsoft accounts
echo - Microsoft Store
echo - Searching in file explorer
echo - Start context menu
echo - Wi-Fi menu
echo - Windows Firewall
echo - Xbox App
echo Please PROCEED WITH CAUTION, you are doing this at your own risk.
pause & cls

:: Detect if user is using a microsoft account
PowerShell -NoP -C "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" > nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "!MSACCOUNT!" == "NO" ( call setSvc.cmd wlidsvc 4 ) else ( echo "Microsoft Account detected, not disabling wlidsvc..." )
choice /c yn /m "Last warning, continue? [Y/N]" /n

:: Disable the option for microsoft store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f > nul 2>&1

:: Block access to Microsoft Store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f > nul 2>&1

call setSvc.cmd AppXSvc 4
call setSvc.cmd BFE 4
call setSvc.cmd ClipSVC 4
call setSvc.cmd InstallService 4
call setSvc.cmd LicenseManager 4
call setSvc.cmd mpssvc 4
call setSvc.cmd TabletInputService 4
call setSvc.cmd TokenBroker 4
call setSvc.cmd WinHttpAutoProxySvc 4

taskkill /f /im StartMenuExperienceHost* > nul 2>&1
ren !windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewyy
taskkill /f /im SearchApp* > nul 2>&1
ren !windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy Microsoft.Windows.Search_cw5n1h2txyewyy
ren !windir!\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy Microsoft.XboxGameCallableUI_cw5n1h2txyewyy
ren !windir!\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwee

taskkill /f /im RuntimeBroker* > nul 2>&1
ren !windir!\System32\RuntimeBroker.exe RuntimeBroker.exee
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f > nul 2>&1
taskkill /f /im explorer.exe
start explorer.exe

echo Finished, please reboot your device for changes to apply.
pause
exit /b