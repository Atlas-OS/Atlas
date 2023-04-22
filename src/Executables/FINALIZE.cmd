@echo off
setlocal EnableDelayedExpansion

:: MSI Mode

:: Enable MSI mode on USB, GPU, SATA controllers and network adapters
:: Deleting DevicePriority sets the priority to undefined
for %%a in (
    Win32_USBController,
    Win32_VideoController,
    Win32_NetworkAdapter,
    Win32_IDEController
) do (
    for /f %%i in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
        reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
    )
)

:: If e.g. VMWare is used, set network adapter to normal priority as undefined on some virtual machines may break internet connection
wmic computersystem get manufacturer /format:value | findstr /i /c:VMWare && (
    for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2" /f
    )
)

:: Miscellaneous

:: Disable DMA remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
    reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)

:: Disable NetBios over tcp/ip
:: Works only when services are enabled
for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)

:: Disable Nagle's Algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm

for /f %%a in ('wmic path Win32_NetworkAdapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: Configure internet adapter settings
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr "HKEY"') do (
    for %%i in (
        "*EEE"
        "*FlowControl"
        "*LsoV2IPv4"
        "*LsoV2IPv6"
        "*SelectiveSuspend"
        "*WakeOnMagicPacket"
        "*WakeOnPattern"
        "AdvancedEEE"
        "AutoDisableGigabit"
        "AutoPowerSaveModeEnabled"
        "EnableConnectedPowerGating"
        "EnableDynamicPowerGating"
        "EnableGreenEthernet"
        "EnableModernStandby"
        "EnablePME"
        "EnablePowerManagement"
        "EnableSavePowerNow"
        "GigaLite"
        "PowerSavingMode"
        "ReduceSpeedOnPowerDown"
        "ULPMode"
        "WakeOnLink"
        "WakeOnSlot"
        "WakeUpModeCap"
    ) do (
        for /f %%j in ('reg query "%%a" /v "%%~i" ^| findstr "HKEY"') do (
            reg add "%%j" /v "%%~i" /t REG_SZ /d "0" /f
        )
    )
)

for /f "tokens=1" %%a in ('netsh int ip show interfaces ^| findstr [0-9]') do (
    netsh int ip set interface %%a routerdiscovery=disabled store=persistent
)

:: Set correct username variable of the currently logged in user
for /f "tokens=3 delims==\" %%a in ('wmic computersystem get username /value ^| find "="') do set "loggedinusername=%%a"

:: Debloat 'Send To' context menu, hidden files do not show up in the 'Send To' context menu
attrib +h "C:\Users\!loggedinusername!\AppData\Roaming\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
attrib +h "C:\Users\!loggedinusername!\AppData\Roaming\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail"
attrib +h "C:\Users\!loggedinusername!\AppData\Roaming\Microsoft\Windows\SendTo\Documents.mydocs"

:: Disable audio exclusive mode on all devices
for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"') do (
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"') do (
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

:: Set sound scheme to 'No Sounds'
for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
    reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_"
    if not !errorlevel! == 1 (
        PowerShell -NoP -C "New-PSDrive HKU Registry HKEY_USERS; New-ItemProperty -Path 'HKU:\%%a\AppEvents\Schemes' -Name '(Default)' -Value '.None' -Force | Out-Null"
        PowerShell -NoP -C "New-PSDrive HKU Registry HKEY_USERS; Get-ChildItem -Path 'HKU:\%%a\AppEvents\Schemes\Apps' | Get-ChildItem | Get-ChildItem | Where-Object {$_.PSChildName -eq '.Current'} | Set-ItemProperty -Name '(Default)' -Value ''"
    )
)

:: Detect hard drive - Solid State Drive (SSD) or Hard Disk Drive (HDD)
for /f %%a in ('PowerShell -NoP -C "Get-PhysicalDisk | ForEach-Object { $physicalDisk = $_ ; $physicalDisk | Get-Disk | Get-Partition | Where-Object { $_.DriveLetter -eq 'C'} | Select-Object @{n='MediaType';e={$physicalDisk.MediaType}}}"') do (
    set DRIVE=%%a
)

if "!DRIVE!" == "SSD" (
    rem Remove lower filters for rdyboost driver
    set "key=HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
    for /f "skip=1 tokens=3*" %%a in ('reg query !key! /v "LowerFilters"') do (set val=%%a)
    set val=!val:rdyboost\0=!
    set val=!val:\0rdyboost=!
    set val=!val:rdyboost=!
    reg add "!key!" /v "LowerFilters" /t REG_MULTI_SZ /d "!val!" /f

    rem Disable ReadyBoost
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\rdyboost" /v "Start" /t REG_DWORD /d "4" /f

    rem Remove ReadyBoost tab
    reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f

    Rem Disable SysMain (Superfetch and Prefetch)
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v "Start" /t REG_DWORD /d "4" /f

    rem Disable Memory Compression
    rem SysMain should already disable it, but make sure it is disabled by executing this command.
    PowerShell -NoP -C "Disable-MMAGent -MemoryCompression"
)

:: Add Auto-Cleaner to run on startup
schtasks /create /f /sc ONLOGON /ru "nt authority\system" /tn "\Atlas\Auto-Cleaner" /tr "C:\Windows\AtlasModules\Scripts\Auto-Cleaner.cmd" /delay 0000:30
