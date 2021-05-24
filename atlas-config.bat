@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto permFAIL
) else ( goto permSUCCESS )
:: Mostly for debugging
echo This echo should not be shown, permission check did not run.
pause&exit
:permSUCCESS
SETLOCAL EnableDelayedExpansion
:: set script version, not OS
set ver=1.0.5
set devbranch=update-test1-NOMERGE
set workdir=Atlas-%devbranch%

for /f "usebackq tokens=3,4,5" %%i in (`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName`) DO set winprod=%%k
if /i "%winprod%"=="Pro" goto ProdCheckGood
if /i "%winprod%"=="Home" goto ProdCheckGood
echo It seems you are using a Windows Product version that is not supported. This script only supports Pro and Home versions
:ProdCheckGood
:: bypass update check on postinstall for automation
if /i "%~1"=="/start"		   goto startup

:updatecheck
if exist "ver.txt" del /f /q "ver.txt" >nul 2>&1
aria2c https://raw.githubusercontent.com/Atlas-OS/Atlas/%devbranch%/ver.txt >nul 2>&1
cls
:: read from ver.txt
for /f "tokens=*" %%i in (ver.txt) do set gitver=%%i
:: checking if the current version number is less than git version
if /i %ver% LSS %gitver% (
    cls
    echo An update is available!
    echo.
    echo Current Version:   %ver%
    echo Available Version:   %gitver%
    :: if idled for 20 seconds, automatically answer yes
    choice /c yn /m "Update? [y/n]" /n /t 20 /d y
    :: https://stackoverflow.com/a/8616822
    if !ERRORLEVEL! equ 1 (
        echo.
        echo Updating to the latest version, please wait...
        echo.
        :: github's download system is not compatible with aria2c, curling...
        curl -L https://github.com/Atlas-OS/Atlas/archive/refs/heads/%devbranch%.zip -o update.zip
        7z -aoa -r e "update.zip" -o%~dp0\ >nul 2>&1
        cls
        del /F /Q update.zip >nul 2>&1
        rmdir /S /Q Atlas-%devbranch% >nul 2>&1
        :: relaunch as updated
        C:\Windows\AtlasModules\nsudo -U:T -P:E atlas-config.bat %~1&exit
    )
    echo Skipping Update...
)

:: will loop update check if debugging.
if /i "%~1"=="/t"         goto TestSuccess
if /i "%~1"=="/dn"         goto notiD
if /i "%~1"=="/en"         goto notiE
if /i "%~1"=="/di"         goto indexD
if /i "%~1"=="/ei"         goto indexE
if /i "%~1"=="/dw"         goto wifiD
if /i "%~1"=="/ew"         goto wifiE
if /i "%~1"=="/ds"         goto storeD
if /i "%~1"=="/es"         goto storeE
if /i "%~1"=="/btd"         goto btD
if /i "%~1"=="/bte"         goto btE
if /i "%~1"=="/hddd"         goto hddD
if /i "%~1"=="/hdde"         goto hddE
if /i "%~1"=="/depE"         goto depE
if /i "%~1"=="/depD"         goto depD
if /i "%~1"=="/ssD"         goto SearchStart
if /i "%~1"=="/openshell"         goto openshellInstall
if /i "%~1"=="/uwp"			goto uwp
if /i "%~1"=="/mite"			goto mitE
if /i "%~1"=="/stico"          goto startlayout
if /i "%~1"=="/sleepD"         goto sleepD
if /i "%~1"=="/sleepE"         goto sleepE
:: debugging purposes only
if /i "%~1"=="/update"         goto updatecheck
if /i "%~1"=="/test"         goto TestSuccess
:argumentFAIL
echo atlas-config had no arguements passed to it, either you are launching atlas-config directly or the script, "%~nx0" script is broken.
echo Please report this to the Atlas discord or github.
pause&exit
:TestSuccess
echo Arguement Test Successful, good job mate!
pause&exit
:startup
:: CREDITS
:: CatGamerOP; some bcdedits
:: Artanis; setting MSI mode
:: Revision; SvcHostSplitThreshold
cls
echo Please wait. This may take a moment.
setx path "%path%;C:\Windows\AtlasModules;" -m
:: Breaks setting keyboard language
:: Rundll32.exe advapi32.dll,ProcessIdleTasks
C:\ProgramData\vcredist.exe /ai
:: change ntp server from windows server to pool.ntp.org
sc config W32Time start=demand
sc start W32Time
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
sc queryex "w32time"|Find "STATE"|Find /v "RUNNING"||(
    net stop w32time
    net start w32time
)
:: resync time to pool.ntp.org
w32tm /config /update
w32tm /resync
sc stop W32Time
sc config W32Time start=disabled
cls
echo Please wait. This may take a moment.
:: Optimize NTFS parameters
:: Disable Last Access information on directories, performance/privacy.
fsutil behavior set disableLastAccess 1 
:: https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security/
fsutil behavior set disable8dot3 1

:: Disable unneeded Tasks
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\DiskFootprint\Diagnostics"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Application Experience\StartupAppTask"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Autochk\Proxy"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Defrag\ScheduledDefrag"
schtasks /Change /DISABLE /TN "\MicrosoftEdgeUpdateBrowserReplacementTask"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Registry\RegIdleBackup"
:: Breaks setting Lock Screen
:: schtasks /Change /DISABLE /TN "\Microsoft\Windows\Shell\CreateObjectTask"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"
:: Should already be disabled
schtasks /Change /DISABLE /TN "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon"

schtasks /Change /DISABLE /TN "\Microsoft\Windows\StateRepository\MaintenanceTasks"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UPnP\UPnPHostConfig"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\RetailDemo\CleanupOfflineContent"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Shell\FamilySafetyMonitor"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\InstallService\ScanForUpdates"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\InstallService\SmartRetry"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\InstallService\ScanForUpdates"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\WaaSMedic\PerformRemediation"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup"
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Diagnosis\Scheduled"

cls
echo Please wait. This may take a moment.

:: Enable MSI Mode on USB Controllers
:: second command for each device deletes device priorty, setting it to undefined
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>&1
:: Eenable MSI Mode on GPU
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>&1
:: Enable MSI Mode on Network Adapters
:: undefined priority on some VMs may break connection
:: TODO: VM Detection, if VM = set to normal
for /f "tokens=2 delims==" %%i in ('wmic bios get Manufacturer /value') do set vmchk=%%i

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
if /i "%vmchk%"=="VMware, Inc." goto vmGO
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>&1
goto noVM
:vmGO
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2"  /f
:noVM
:: Enable MSI Mode on Sata controllers
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>&1
cls
echo Please wait. This may take a moment.

:: Disabling certain process mitigations

::DEP
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#data-execution-prevention
powershell set-ProcessMitigation -System -Disable DEP
powershell set-ProcessMitigation -System -Disable EmulateAtlThunks
::ASLR
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#address-space-layout-randomization
powershell set-ProcessMitigation -System -Disable RequireInfo
powershell set-ProcessMitigation -System -Disable BottomUp
powershell set-ProcessMitigation -System -Disable HighEntropy
powershell set-ProcessMitigation -System -Disable StrictHandle
::BlockDynamicCode
::AllowThreadsToOptOut
::AuditDynamicCode
::CFG
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#control-flow-guard
powershell set-ProcessMitigation -System -Disable CFG
powershell set-ProcessMitigation -System -Disable StrictCFG
powershell set-ProcessMitigation -System -Disable SuppressExports
::SEHOP
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#structured-exception-handling-overwrite-protection
powershell set-ProcessMitigation -System -Disable SEHOP
powershell set-ProcessMitigation -System -Disable AuditSEHOP
powershell set-ProcessMitigation -System -Disable SEHOPTelemetry
powershell set-ProcessMitigation -System -Disable ForceRelocateImages

:: Import the powerplan
:: send output to log to debug tell if missing file
powercfg -import "C:\Windows\AtlasModules\Atlas.pow" 11111111-1111-1111-1111-111111111111
:: Set current powerplan to Atlas
:: TODO: implement laptop check and change to a more power friendly plan by default
powercfg /s 11111111-1111-1111-1111-111111111111
:: Delete power file after import
del /F /Q C:\Windows\AtlasModules\Atlas.pow

:: Set SvcSplitThreshold
:: Credits: revision
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%i
set /a ram=%mem% + 1024000
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f

:: tokens arg breaks path to just \Device instead of \Device Parameters
:: Disable Power savings on drives
for /f "tokens=*" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum" /s /f "StorPort"^| findstr "StorPort"') do reg add "%%i" /v "EnableIdlePowerManagement" /t REG_DWORD /d "0" /f

:: tokens arg breaks path to just \Device instead of \Device Parameters
for /f "tokens=*" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB" /s /f "EnhancedPowerManagementEnabled"^| findstr "HKEY"') do (
    reg add "%%i" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "AllowIdleIrpInD3" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "EnableSelectiveSuspend" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "DeviceSelectiveSuspended" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "SelectiveSuspendEnabled" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "SelectiveSuspendOn" /t REG_DWORD /d "0" /f
	reg add "%%1" /v "D3ColdSupported" /t REG_DWORD /d "0" /f
)
:: Some devices only have selective suspend or EnhancedPowerManagementEnabled etc etc. There is probably a more efficient way to do this.
for /f "tokens=*" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB" /s /f "DeviceSelectiveSuspended"^| findstr "HKEY"') do (
    reg add "%%i" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "AllowIdleIrpInD3" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "EnableSelectiveSuspend" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "DeviceSelectiveSuspended" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "SelectiveSuspendEnabled" /t REG_DWORD /d "0" /f
    reg add "%%i" /v "SelectiveSuspendOn" /t REG_DWORD /d "0" /f
	reg add "%%i" /v "D3ColdSupported" /t REG_DWORD /d "0" /f
)
cls
echo Please wait. This may take a moment.

:: Unhide powerplan attributes
:: Credits to: Eugene Muzychenko
for /f "tokens=1-9* delims=\ " %%A in ('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings /s /f attributes /e') do (
  if /i "%%A" == "HKEY_LOCAL_MACHINE" (
    set Ident=
    if not "%%G" == "" (
      set Err=
      set Group=%%G
      set Setting=%%H
      if "!Group:~35,1!" == "" set Err=group
      if not "!Group:~36,1!" == "" set Err=group
      if not "!Setting!" == "" (
        if "!Setting:~35,1!" == "" set Err=setting
        if not "!Setting:~36,1!" == "" set Err=setting
        Set Ident=!Group!:!Setting!
      ) else (
        Set Ident=!Group!
      )
      if not "!Err!" == "" (
        echo ***** Error in !Err! GUID: !Ident"
      )
    )
  ) else if "%%A" == "Attributes" (
    if "!Ident!" == "" (
      echo ***** No group/setting GUIDs before Attributes value
    )
    set /a Attr = %%C
    set /a Hidden = !Attr! ^& 1
    if !Hidden! equ 1 (
      echo Unhiding !Ident!
      powercfg -attributes !Ident::= ! -attrib_hide
    )
  )
)

sc stop wuauserv >nul 2>&1
:: reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientIdValidation" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientId" /t REG_SZ /d "00000000-0000-0000-0000-000000000000" /f

:: disable hibernation
powercfg -h off

start explorer.exe
taskkill /f /im explorer.exe
start explorer.exe

:: Disable Devices
devmanview /disable "System Speaker"
devmanview /disable "System Timer"
devmanview /disable "WAN Miniport (IKEv2)"
devmanview /disable "WAN Miniport (IP)"
devmanview /disable "WAN Miniport (IPv6)"
devmanview /disable "WAN Miniport (L2TP)"
devmanview /disable "WAN Miniport (Network Monitor)"
devmanview /disable "WAN Miniport (PPPOE)"
devmanview /disable "WAN Miniport (PPTP)"
devmanview /disable "WAN Miniport (SSTP)"
devmanview /disable "UMBus Root Bus Enumerator"
devmanview /disable "Microsoft System Management BIOS Driver"
devmanview /disable "Programmable Interrupt Controller"
devmanview /disable "High Precision Event Timer"
devmanview /disable "PCI Encryption/Decryption Controller"
devmanview /disable "AMD PSP"
devmanview /disable "Intel SMBus"
devmanview /disable "Intel Management Engine"
devmanview /disable "PCI Memory Controller"
devmanview /disable "PCI standard RAM Controller"
devmanview /disable "Composite Bus Enumerator"
devmanview /disable "Microsoft Kernel Debug Network Adapter"
devmanview /disable "SM Bus Controller"
devmanview /disable "NDIS Virtual Network Adapter Enumerator"
devmanview /disable "Microsoft Virtual Drive Enumerator"
devmanview /disable "Numeric Data Processor"
devmanview /disable "Microsoft RRAS Root Enumerator"

:: lowering dual boot choice time
:: No, this does NOT affect single OS boot time.
:: This is directly shown in microsoft docs https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--timeout#parameters
bcdedit /timeout 10
:: Settings to No provides worse results, delete the value instead.
:: This is here as a safeguard incase of User Error.
bcdedit /deletevalue useplatformclock >nul 2>&1
:: Disable synthetic timer
bcdedit /set useplatformtick yes
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /set disabledynamictick Yes
:: Disable DEP, may need to enable for FACEIT, Valorant, and other Anti-Cheats.
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOff
:: Hyper-V support is removed, other virtualization programs are supported
bcdedit /set hypervisorlaunchtype off
:: disable EMS
bcdedit /set ems No
bcdedit /set bootems No 

for /F "tokens=* skip=1" %%n in ('wmic cpu get numberOfLogicalProcessors ^| findstr "."') do set THREADS=%%n
:: on 4 cores and lower disable distribute timers
if %THREADS% LSS 5 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "DistributeTimers" /t REG_DWORD /d "0" /f

del /f C:\ProgramData\vcredist.exe

shutdown /r /f /t 10 /c "Required Reboot"
timeout 20
exit
:notiD
sc config WpnService start=disabled
sc stop WpnService >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
goto finish
:notiE
sc config WpnUserService start=auto
sc config WpnService start=auto 
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "0" /f
goto finish
:indexD
sc config WSearch start=disabled
sc stop WSearch >nul 2>&1
goto finish
:indexE
sc config WSearch start=delayed-auto
sc start WSearch >nul 2>&1
goto finish
:wifiD
:: netprofm seems to break internet connection checking for example in store or in spotify
::sc config netprofm start=disabled
::sc queryex "netprofm"|Find "STATE"|Find /v "RUNNING">Nul||(
::sc stop netprofm
::)
sc config NlaSvc start=disabled
sc config WlanSvc start=disabled
sc config vwififlt start=disabled
goto finish
:wifiE
sc config netprofm start=demand
sc config NlaSvc start=auto
sc config WlanSvc start=demand
sc config vwififlt start=system
:: If wifi is still not working, set wlansvc to auto
ping -n 1 -4 1.1.1.1 |Find "Failulre"|(
    sc config WlanSvc start=auto
)
goto finish
:storeD
echo If you have a linked MS Account, you NEED to unlink it. Or you will NOT be able to login. 
echo Take this into consideration before running this and rebooting.
echo This will break a majority of UWP apps and their deployment.
:: This includes Windows Firewall, I only see the point in keeping it because of Store. 
:: If you notice something else breaks when firewall/store is disabled please open an issue.
pause
:: Disable the option for Windows Store in the "Open With" dialog
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f
:: Block Access to Windows Store
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
sc config InstallService start=disabled
:: Insufficent permissions to disable
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f
sc config mpssvc start=disabled
sc config wlidsvc start=disabled
sc config AppXSvc start=disabled
sc config BFE start=disabled
sc config TokenBroker start=disabled
sc config LicenseManager start=disabled
sc config AppXSVC start=disabled
sc config ClipSVC start=disabled
goto finish
:storeE
:: Enable the option for Windows Store in the "Open With" dialog
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f
:: Allow Access to Windows Store
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
sc config InstallService start=demand
:: Insufficent permissions to enable through SC
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f
sc config mpssvc start=auto
sc config wlidsvc start=demand
sc config AppXSvc start=demand
sc config BFE start=auto
sc config TokenBroker start=demand
sc config LicenseManager start=demand
sc config wuauserv start=demand
sc config AppXSVC start=demand
goto finish
:btD
sc config BthAvctpSvc start=disabled
sc stop BthAvctpSvc >nul 2>&1
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
  sc stop %%~nI
)
sc config CDPSvc start=disabled
goto finish
:btE
sc config BthAvctpSvc start=auto
sc start BthAvctpSvc >nul 2>&1
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "2" /f
  sc start %%~nI
)
sc config CDPSvc start=auto
goto finish
:hddD
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
sc config SysMain start=disabled
sc config FontCache start=disabled
goto finish
:hddE
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f
sc config SysMain start=auto
sc config FontCache start=auto
goto finish
:depE
powershell set-ProcessMitigation -System -Enable DEP
powershell set-ProcessMitigation -System -Enable EmulateAtlThunks
bcdedit /set nx OptIn
goto finish
:depD
echo If you get issues with some anti-cheats, please re-enable DEP.
powershell set-ProcessMitigation -System -Disable DEP
powershell set-ProcessMitigation -System -Disable EmulateAtlThunks
bcdedit /set nx AlwaysOff
goto finish
:SearchStart
IF EXIST "C:\Program Files\Open-Shell" goto existS
IF EXIST "C:\Program Files (x86)\StartIsBack" goto existS
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the startmenu being removed.
pause
:existS
set /P c=This will remove SearchApp and StartMenuExperienceHost, are you sure you want to continue[Y/N]?
if /I "%c%" EQU "Y" goto continSS
if /I "%c%" EQU "N" goto :stopS
:continSS
:: Delete Start Menu
icacls "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy /R /D Y  >nul 2>nul
:: Deleting will fail if process runs, kill
taskkill /F /IM StartMenuExperienceHost*  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy  >nul 2>nul
:: Delete Search
icacls "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" /T /C /Q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy /R /D Y  >nul 2>nul
:: Deleting will fail if process runs, kill
taskkill /F /IM SearchApp*  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy  >nul 2>nul
taskkill /F /IM SearchApp*  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy  >nul 2>nul
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 0 /F
taskkill /f /im explorer.exe
start explorer.exe
goto finish
:stopS
exit
:openshellInstall
:: Download OpenShell through aria2c
aria2c -d C:\Windows\AtlasModules -o oshellI.exe --file-allocation=falloc https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.160/OpenShellSetup_4_4_160.exe
:: Install silently
echo.
echo Openshell is installing...
:: TODO: set openshell settings
:: TODO: copy metro skin to openshell skins folder
:: StartMenu.exe -xml <path>
"oshellI.exe" /qn ADDLOCAL=StartMenu
goto finishNRB
:uwp
IF EXIST "C:\Program Files\Open-Shell" goto uwpS
IF EXIST "C:\Program Files (x86)\StartIsBack" goto uwpS
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the startmenu being removed.
pause&exit
:uwpS
echo This will remove all UWP packages that are currently installed. This will break many things.
echo A reminder of a few things this may break.
echo - Searching in file explorer
echo - Store
echo - Xbox
echo - Immersive Control Panel
echo - Adobe XD
echo Please PROCEED WITH CAUTION, you are doing this at your own risk.
pause
choice /c yn /m "Last warning, continue? [y/n]" /n
sc stop TabletInputService
sc config TabletInputService start=disabled

icacls "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy /R /D Y  >nul 2>nul
taskkill /F /IM StartMenuExperienceHost*  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy  >nul 2>nul
icacls "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" /T /C /Q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy /R /D Y  >nul 2>nul
taskkill /F /IM SearchApp*  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy  >nul 2>nul
taskkill /F /IM SearchApp*  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy  >nul 2>nul
icacls "C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy /R /D Y  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy  >nul 2>nul
icacls "C:\Windows\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe /R /D Y  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe  >nul 2>nul

icacls "C:\Windows\System32\RuntimeBroker.exe" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\System32\RuntimeBroker.exe /R /D Y  >nul 2>nul
taskkill /F /IM RuntimeBroker*  >nul 2>nul
del /S /F /Q C:\Windows\System32\RuntimeBroker.exe  >nul 2>nul
taskkill /F /IM RuntimeBroker*  >nul 2>nul
del /S /F /Q C:\Windows\System32\RuntimeBroker.exe  >nul 2>nul
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 0 /F
taskkill /f /im explorer.exe
start explorer.exe
goto finishNRB
:mitE
powershell set-ProcessMitigation -System -Enable DEP
powershell set-ProcessMitigation -System -Enable EmulateAtlThunks
powershell set-ProcessMitigation -System -Enable RequireInfo
powershell set-ProcessMitigation -System -Enable BottomUp
powershell set-ProcessMitigation -System -Enable HighEntropy
powershell set-ProcessMitigation -System -Enable StrictHandle
powershell set-ProcessMitigation -System -Enable CFG
powershell set-ProcessMitigation -System -Enable StrictCFG
powershell set-ProcessMitigation -System -Enable SuppressExports
powershell set-ProcessMitigation -System -Enable SEHOP
powershell set-ProcessMitigation -System -Enable AuditSEHOP
powershell set-ProcessMitigation -System -Enable SEHOPTelemetry
powershell set-ProcessMitigation -System -Enable ForceRelocateImages
goto finish
:startlayout
reg delete "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f
reg delete "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /f
goto finish
:sleepD
:: Enable Away Mode policy
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
:: Enable Idle States
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
:: Enable Hybrid Sleep
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
goto finishNRB
:sleepE
:: Enable Away Mode policy
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1
:: Enable Idle States
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1
:: Enable Hybrid Sleep
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
goto finishNRB
:harden
:: TODO:
:: - Harden Process Mitigations (lower compatibilty for legacy apps)
:: - Open scripts in notepad to preview instead of executing when clicking
:: - ElamDrivers
:: - block unsigned processes running from USBS
:: - Kerebos Hardening
:: - UAC Enable
:: - Firewall rules
:permFAIL
	echo Permission grants failed. Please try again by launching the script through the respected scripts, which will give it the correct permissions.
	pause&exit
:finish
	echo Finished, please reboot for changes to apply.
	pause&exit
:finishNRB
	echo Finished, changes have been applied.
	pause&exit
pause