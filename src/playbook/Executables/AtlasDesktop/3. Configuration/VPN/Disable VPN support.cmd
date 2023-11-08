@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call toggleDev.cmd -Silent @("NDIS Virtual Network Adapter Enumerator", "Microsoft RRAS Root Enumerator", "WAN Miniport*")

for %%a in (
	"Eaphost"
	"IKEEXT"
	"iphlpsvc"
	"NdisVirtualBus"
	"RasMan"
	"SstpSvc"
	"WinHttpAutoProxySvc"
) do (
	call setSvc.cmd %%~a 4
)

:: Hide Settings page
if not "%~1" == "/silent" (
    set "pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    reg query "!pageKey!" /v "SettingsPageVisibility" > nul 2>&1
    if %ERRORLEVEL% == 0 (
        for /f "usebackq tokens=3" %%a in (`reg query "!pageKey!" /v "SettingsPageVisibility"`) do (
            reg add "!pageKey!" /v "SettingsPageVisibility" /t REG_SZ /d "%%a;network-vpn;" /f > nul
        )
    ) else (
        reg add "!pageKey!" /v "SettingsPageVisibility" /t REG_SZ /d "hide:network-vpn;" /f > nul
    )
)

echo Finished, please reboot your device for changes to apply.
pause
exit /b