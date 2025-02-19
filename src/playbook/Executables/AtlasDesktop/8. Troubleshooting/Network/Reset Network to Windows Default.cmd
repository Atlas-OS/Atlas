@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=DefaultAtlasNetwork"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=0"
set "scriptPath=%~f0"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%*"=="" pause
        exit /b 1
    )
    exit /b
)

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

:: End of state and path update

echo Resetting network settings to Windows defaults...

(
	netsh int ip reset
	netsh interface ipv4 reset
	netsh interface ipv6 reset
	netsh interface tcp reset
	netsh winsock reset
) > nul

PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') { pnputil /remove-device $dev.InstanceId }" > nul
pnputil /scan-devices > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b