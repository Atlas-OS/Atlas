@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call toggleDev.cmd -Silent -Enable @("NDIS Virtual Network Adapter Enumerator", "Microsoft RRAS Root Enumerator", "WAN Miniport*")

call setSvc.cmd BFE 2
call setSvc.cmd Eaphost 3
call setSvc.cmd IKEEXT 3
call setSvc.cmd iphlpsvc 3
call setSvc.cmd NdisVirtualBus 3
call setSvc.cmd RasMan 2
call setSvc.cmd SstpSvc 3
call setSvc.cmd WinHttpAutoProxySvc 3

:: Hide Settings pages
set "pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
reg query "%pageKey%" /v "SettingsPageVisibility" > nul 2>&1
if %ERRORLEVEL% == 0 call :enableSettingsPage

echo Finished, please reboot your device for changes to apply.
pause
exit /b

:enableSettingsPage
for /f "usebackq tokens=3" %%a in (`reg query "%pageKey%" /v "SettingsPageVisibility"`) do (set "currentPages=%%a")
reg add "%pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "%currentPages:network-vpn;=%" /f > nul
exit /b