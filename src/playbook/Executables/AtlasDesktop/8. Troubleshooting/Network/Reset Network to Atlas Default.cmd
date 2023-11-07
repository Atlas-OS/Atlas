@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo Applying changes...

:: Disable Nagle's Algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%a in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d "1" /f > nul
)

:: https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f > nul
:: https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f > nul
:: reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f > nul

:: Set default power saving mode for all network cards to disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "DefaultPnPCapabilities" /t REG_DWORD /d "24" /f > nul

:: Set network adapter driver registry key
for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%a" /v "Driver"') do ( 
        set "netKey=HKLM\SYSTEM\CurrentControlSet\Control\Class\%%b"
    ) > nul 2>&1
)

:: Configure internet adapter settings
:: Dump of all possible settings found
:: TO DO: revise and document each setting
for %%a in (
    "AdvancedEEE"
    "AlternateSemaphoreDelay"
    "ApCompatMode"
    "ARPOffloadEnable"
    "AutoDisableGigabit"
    "AutoPowerSaveModeEnabled"
    "bAdvancedLPs"
    "bLeisurePs"
    "bLowPowerEnable"
    "DeviceSleepOnDisconnect"
    "DMACoalescing"
    "EEE"
    "EEELinkAdvertisement"
    "EeePhyEnable"
    "Enable9KJFTpt"
    "EnableConnectedPowerGating"
    "EnableDynamicPowerGating"
    "EnableEDT"
    "EnableGreenEthernet"
    "EnableModernStandby"
    "EnablePME"
    "EnablePowerManagement"
    "EnableSavePowerNow"
    "EnableWakeOnLan"
    "FlowControl"
    "FlowControlCap"
    "GigaLite"
    "GPPSW"
    "GTKOffloadEnable"
    "InactivePs"
    "LargeSendOffload"
    "LargeSendOffloadJumboCombo"
    "LogLevelWarn"
    "LsoV1IPv4"
    "LsoV2IPv4"
    "LsoV2IPv6"
    "MasterSlave"
    "ModernStandbyWoLMagicPacket"
    "MPC"
    "NicAutoPowerSaver"
    "Node"
    "NSOffloadEnable"
    "PacketCoalescing"
    rem Offload "PMARPOffload"
    rem Offload "PMNSOffload"
    "PMWiFiRekeyOffload"
    "PowerDownPll"
    "PowerSaveMode"
    "PowerSavingMode"
    "PriorityVLANTag"
    "ReduceSpeedOnPowerDown"
    "S5WakeOnLan"
    "SavePowerNowEnabled"
    "SelectiveSuspend"
    "SipsEnabled"
    "uAPSDSupport"
    "ULPMode"
    "WaitAutoNegComplete"
    "WakeOnDisconnect"
    "WakeOnLink"
    "WakeOnMagicPacket"
    "WakeOnPattern"
    "WakeOnSlot"
    "WakeUpModeCap"
    "WoWLANLPSLevel"
    "WoWLANS5Support"
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

:: Configure netsh settings
netsh int tcp set supplemental Internet congestionprovider=ctcp > nul
netsh interface Teredo set state type=enterpriseclient > nul
netsh interface Teredo set state servername=default > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b