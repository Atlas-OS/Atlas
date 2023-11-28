@echo off
setlocal EnableDelayedExpansion

:: MSI Mode

:: Enable MSI mode on USB, GPU, Audio, SATA controllers, disk drives and network adapters
:: Deleting DevicePriority sets the priority to undefined
for %%a in ("CIM_NetworkAdapter", "CIM_USBController", "CIM_VideoController" "Win32_IDEController", "Win32_PnPEntity", "Win32_SoundDevice") do (
    if "%%~a" == "Win32_PnPEntity" (
        for /f "tokens=*" %%b in ('PowerShell -NoP -C "Get-WmiObject -Class Win32_PnPEntity | Where-Object {($_.PNPClass -eq 'SCSIAdapter') -or ($_.Caption -like '*High Definition Audio*')} | Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } | Select-Object -ExpandProperty DeviceID"') do (
            reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > nul
            reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>&1
        )
    ) else (
        for /f %%b in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
            reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > nul
            reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>&1
        )
    )
)

:: If a virtual machine is used, set network adapter to normal priority as Undefined may break internet connection
for %%a in ("hvm", "hyper", "innotek", "kvm", "parallel", "qemu", "virtual", "xen", "vmware") do (
    wmic computersystem get manufacturer /format:value | findstr /i /c:%%~a && (
        for /f %%b in ('wmic path CIM_NetworkAdapter get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
            reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2" /f > nul
        )
    )
)

:: Network Configuration

:: Disable NetBios over tcp/ip
:: Works only when services are enabled
for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f > nul
)

:: Disable Nagle's Algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%a in ('wmic path Win32_NetworkAdapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d "1" /f > nul
)

:: Set network adapter driver registry key
for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%a" /v "Driver" 2^>nul') do (
        set "netKey=HKLM\SYSTEM\CurrentControlSet\Control\Class\%%b"
    )
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
    for /f %%b in ('reg query "%netKey%" /v "%%~a" 2^>nul ^| findstr "HKEY" 2^>nul') do (
        reg add "%netKey%" /v "%%~a" /t REG_SZ /d "0" /f > nul
    )
    rem Check with '*'
    for /f %%b in ('reg query "%netKey%" /v "*%%~a" 2^>nul ^| findstr "HKEY" 2^>nul') do (
        reg add "%netKey%" /v "*%%~a" /t REG_SZ /d "0" /f > nul
    )
)

:: Miscellaneous

:: Disable Direct Memory Access remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
    reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f > nul
)

:: Hide unnecessary items from the 'Send To' context menu
for %%a in (
    "Documents.mydocs"
    "Mail Recipient.MAPIMail"
) do (
    attrib +h "%APPDATA%\Microsoft\Windows\SendTo\%%~a" > nul
)

:: Set RunOnce login script
:: This is the script that will be ran on login for new users
reg add "HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "RunScript" /t REG_SZ /d "powershell -EP Bypass -NoP & \"$env:windir\AtlasModules\Scripts\newUsers.ps1\"" /f

:: Remove Fax Recipient from the 'Send to' context menu as Fax feature is removed
del /f /q "%APPDATA%\Microsoft\Windows\SendTo\Fax Recipient.lnk" > nul 2>&1

:: Disable audio exclusive mode on all devices
for %%a in ("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture", "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render") do (
    for /f "delims=" %%b in ('reg query "%%a"') do (
        reg add "%%b\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f > nul
        reg add "%%b\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f > nul
    )
)

:: Disable all audio enhancements in mmsys.cpl (audio settings)
for %%a in ("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture", "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render") do (
    for /f "delims=" %%b in ('reg query "%%a"') do (
        reg add "%%b\FxProperties" /v "{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5" /t REG_DWORD /d "1" /f > nul
        reg add "%%b\FxProperties" /v "{1b5c2483-0839-4523-ba87-95f89d27bd8c},3" /t REG_BINARY /d "030044CD0100000000000000" /f > nul
        reg add "%%b\FxProperties" /v "{73ae880e-8258-4e57-b85f-7daa6b7d5ef0},3" /t REG_BINARY /d "030044CD0100000001000000" /f > nul
        reg add "%%b\FxProperties" /v "{9c00eeed-edce-4cd8-ae08-cb05e8ef57a0},3" /t REG_BINARY /d "030044CD0100000004000000" /f > nul
        reg add "%%b\FxProperties" /v "{fc52a749-4be9-4510-896e-966ba6525980},3" /t REG_BINARY /d "0B0044CD0100000000000000" /f > nul
        reg add "%%b\FxProperties" /v "{ae7f0b2a-96fc-493a-9247-a019f1f701e1},3" /t REG_BINARY /d "0300BC5B0100000001000000" /f > nul
        reg add "%%b\FxProperties" /v "{1864a4e0-efc1-45e6-a675-5786cbf3b9f0},4" /t REG_BINARY /d "030044CD0100000000000000" /f > nul
        reg add "%%b\FxProperties" /v "{61e8acb9-f04f-4f40-a65f-8f49fab3ba10},4" /t REG_BINARY /d "030044CD0100000050000000" /f > nul
        reg add "%%b\Properties" /v "{e4870e26-3cc5-4cd2-ba46-ca0a9a70ed04},0" /t REG_BINARY /d "4100FE6901000000FEFF020080BB000000DC05000800200016002000030000000300000000001000800000AA00389B71" /f > nul
        reg add "%%b\Properties" /v "{e4870e26-3cc5-4cd2-ba46-ca0a9a70ed04},1" /t REG_BINARY /d "41008EC901000000A086010000000000" /f > nul
        reg add "%%b\Properties" /v "{3d6e1656-2e50-4c4c-8d85-d0acae3c6c68},3" /t REG_BINARY /d "4100020001000000FEFF020080BB000000DC05000800200016002000030000000300000000001000800000AA00389B71" /f > nul
        reg delete "%%b\Properties" /v "{624f56de-fd24-473e-814a-de40aacaed16},3" /f > nul 2>&1
        reg delete "%%b\Properties" /v "{3d6e1656-2e50-4c4c-8d85-d0acae3c6c68},2" /f > nul 2>&1
    )
)

:: Detect hard drive - Solid State Drive (SSD) or Hard Disk Drive (HDD)
for /f %%a in ('PowerShell -NoP -C "(Get-PhysicalDisk -SerialNumber (Get-Disk -Number (Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1)).DiskNumber).SerialNumber.TrimStart()).MediaType"') do (
  set "diskDrive=%%a"
)

if "%diskDrive%" == "SSD" (
    rem Remove lower filters for rdyboost driver
    set "reg_path=HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
    for /f "skip=1 tokens=3*" %%a in ('reg query "!reg_path!" /v "LowerFilters"') do (set "val=%%a")
    set "val=!val:rdyboost\0=!"
    set "val=!val:\0rdyboost=!"
    set "val=!val:rdyboost=!"
    reg add "!reg_path!" /v "LowerFilters" /t REG_MULTI_SZ /d "!val!" /f > nul

    rem Disable ReadyBoost
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\rdyboost" /v "Start" /t REG_DWORD /d "4" /f > nul

    rem Remove ReadyBoost tab
    reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f > nul 2>&1

    rem Disable Memory Compression
    rem If SysMain is disabled, MC should be too, but ensure its state by executing this command.
    PowerShell -NoP -C "Disable-MMAGent -MemoryCompression" > nul

    rem Disable SysMain (Superfetch and Prefetch)
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v "Start" /t REG_DWORD /d "4" /f > nul
)

:: Disable brightness slider service if it's not supported on the current display
powershell -nop -c "if ((Get-Computerinfo).CsPCSystemType -eq 'Desktop') { exit 532 }" 
if errorlevel 532 set disableBright=true
powershell -nop -c "Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods -EA 0; if (!$?) {exit 533}"
if errorlevel 533 set disableBright=true
if "%disableBright%"=="true" call %windir%\AtlasModules\Scripts\setSvc.cmd DisplayEnhancementService 4