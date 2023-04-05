@echo off
setlocal EnableDelayedExpansion

:: Make dual boot menu more descriptive
bcdedit /set description Atlas 22H2

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
        echo reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
        echo delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
        reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
    )
)

:: If e.g. VMWare is used, set network adapter to normal priority as undefined on some virtual machines may break internet connection
wmic computersystem get manufacturer /format:value | findstr /i /c:VMWare && (
    for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        echo reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2" /f
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2" /f
    )
)

:: Miscellaneous

:: Disable DMA remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
    echo reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
    reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)
echo Disabled DMA remapping...

:: Disable NetBios over tcp/ip
:: Works only when services are enabled
for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    echo reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)
@if !errorlevel! == 0 (echo Disabled netbios over tcp/ip...
) ELSE (echo Failed to disable netbios over tcp/ip!)

:: Disable Nagle's Algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm

for /f %%a in ('wmic path Win32_NetworkAdapter get GUID ^| findstr "{"') do (
    echo reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    echo reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    echo reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
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
            echo reg add "%%j" /v "%%~i" /t REG_SZ /d "0" /f
            reg add "%%j" /v "%%~i" /t REG_SZ /d "0" /f
        )
    )
)

for /f "tokens=1" %%a in ('netsh int ip show interfaces ^| findstr [0-9]') do (
    echo netsh int ip set interface %%a routerdiscovery=disabled store=persistent
    netsh int ip set interface %%a routerdiscovery=disabled store=persistent
)

@if !errorlevel! == 0 (echo Network optimized...
) ELSE (echo Failed to optimize network!)

:: Get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set "mitigation_mask=%%a"
)

:: Set all bits to 2 (disable all mitigations)
for /l %%a in (0,1,9) do (
    set "mitigation_mask=!mitigation_mask:%%a=2!"
)

:: Apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "!mitigation_mask!" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "!mitigation_mask!" /f

:: Fix Valorant with mitigations disabled - enable CFG
for %%a in (valorant valorant-win64-shipping vgtray vgc) do (
    PowerShell -NoP -C "Set-ProcessMitigation -Name %%a.exe -Enable CFG"
)

:: Set correct username variable of the currently logged-in user
@for /f "tokens=3 delims==\" %%a in ('wmic computersystem get username /value ^| find "="') do set "loggedinusername=%%a"

:: Debloat 'Send To' context menu, hidden files do not show up in the 'Send To' context menu
attrib +h "C:\Users\!loggedinusername!\AppData\Roaming\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
attrib +h "C:\Users\!loggedinusername!\AppData\Roaming\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail"
attrib +h "C:\Users\!loggedinusername!\AppData\Roaming\Microsoft\Windows\SendTo\Documents.mydocs"

:: Disable audio exclusive mode on all devices
for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"') do (
    echo reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    echo reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"') do (
    echo reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    echo reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

:: Set sound scheme to 'No Sounds'
for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    :: If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
    reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul 2>&1
    if not !errorlevel! == 1 (
        PowerShell -NoP -C "New-PSDrive HKU Registry HKEY_USERS; Get-ChildItem -Path 'HKU:\%%a\AppEvents\Schemes\Apps' | Get-ChildItem | Get-ChildItem | Where-Object {$_.PSChildName -eq '.Current'} | Set-ItemProperty -Name '(Default)' -Value ''"
    )
)

@if !errorlevel! == 0 (echo Registry configuration applied...
) ELSE (echo Failed to apply registry configuration!)

echo BCD Options Set...

:: Write to script log file
echo This log keeps track of which scripts have been run. This is never transferred to an online resource and stays local. > !windir!\AtlasModules\logs\userScript.log
echo -------------------------------------------------------------------------------------------------------------------- >> !windir!\AtlasModules\logs\userScript.log
