@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo Setting network settings to Atlas defaults...

:: Set network adapter driver registry key
for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
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