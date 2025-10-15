@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=DefaultAtlasNetwork"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=1"
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
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

:: End of state and path update

echo Setting network settings to Atlas defaults...

:: Set network adapter driver registry key
for /f "usebackq" %%a in (`powershell -NonI -NoP -C "(Get-CimInstance Win32_NetworkAdapter).PNPDeviceID | sls 'PCI\\VEN_'"`) do (
	for /f "tokens=3" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%a" /v "Driver"') do ( 
        set "netKey=HKLM\SYSTEM\CurrentControlSet\Control\Class\%%b"
    ) > nul 2>&1
)

:: Configure network adapter settings

rem --------------------------
rem Unknown benefit
rem --------------------------
rem "LargeSendOffload"
rem "LargeSendOffloadJumboCombo"
rem "LsoV1IPv4"
rem "LsoV2IPv4"
rem "LsoV2IPv6"
rem "LogLevelWarn"
rem "AlternateSemaphoreDelay"
rem "DeviceSleepOnDisconnect"
rem "EnableModernStandby"
rem "PriorityVLANTag"
rem "Node"
rem "MPC"
rem "PowerDownPll"
rem "PMWiFiRekeyOffload"
rem "ARPOffloadEnable"
rem "bAdvancedLPs"
rem "NSOffloadEnable"
rem "GTKOffloadEnable"
rem "Enable9KJFTpt"
rem "EnableEDT"
rem "GPPSW"
rem "MasterSlave"
rem "PacketCoalescing"
rem Could cause dropped network frames
rem "FlowControl"
rem "FlowControlCap"

for %%a in (
    rem Don't disable gigabit
    "AutoDisableGigabit"

    rem Access Point Compatibility Mode
    rem Zero is 'High Performance'
    "ApCompatMode"

    rem About reducing link speed
    "SipsEnabled"
    "ReduceSpeedOnPowerDown"

    rem 'may increase latency'
    rem https://www.intel.com/content/www/us/en/support/articles/000007456/ethernet-products.html
    "DMACoalescing"
) do (
    rem Check without '*'
    for /f %%b in ('reg query "%netKey%" /v "%%~a" ^| findstr "HKEY"') do (
        reg add "%netKey%" /v "%%~a" /t REG_SZ /d "0" /f > nul
    )
    rem Check with '*'
    for /f %%b in ('reg query "%netKey%" /v "*%%~a" ^| findstr "HKEY"') do (
        reg add "%netKey%" /v "*%%~a" /t REG_SZ /d "0" /f > nul
    )
) > nul 2>&1

if "%~1"=="/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b