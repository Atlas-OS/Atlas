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
set ver=1.0.1
set workdir=Atlas-%devbranch%
set devbranch=update-test1-NOMERGE

for /f "usebackq tokens=3,4,5" %%i in (`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName`) DO set winprod=%%k
if /i "%winprod%"=="Pro" goto ProdCheckGood
if /i "%winprod%"=="Home" goto ProdCheckGood
echo It seems you are using a Windows Product version that is not supported. This script only supports Pro and Home
:ProdCheckGood
IF %PROCESSOR_ARCHITECTURE% == x86 ( 
    echo x86 Processor architechtures are not supported!
    timeout 10
    exit
)
if exist "Atlas.pow" (
  goto powex
) ELSE (
     echo Atlas Powerplan does not exist.
     echo Would you like to download and import it?
     choice /c yn /m "" /n /t 10 /d y
    :: https://stackoverflow.com/a/8616822
    if !ERRORLEVEL! equ 1 (
       aria2c https://github.com/Atlas-OS/Atlas/raw/%devbranch%/Atlas.pow
       powercfg -import "C:\Windows\AtlasModules\Atlas.pow" 11111111-1111-1111-1111-111111111111
       )
    )
:powex

:updatecheck
if exist "ver.txt" del /f /q "ver.txt" >nul 2>&1
aria2c https://raw.githubusercontent.com/Atlas-OS/Atlas/%devbranch%/ver.txt
pause
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
    :: if idled for 10 seconds, automatically answer yes
    choice /c yn /m "Update? [y/n]" /n /t 10 /d y
    :: https://stackoverflow.com/a/8616822
    if !ERRORLEVEL! equ 1 (
        echo.
        echo Updating to the latest version, please wait...
        echo.
        :: github's download system is not compatible with aria2c, curling...
        curl -L https://github.com/Atlas-OS/Atlas/archive/refs/heads/%devbranch%.zip -o update.zip
        7z -aoa -r e "update.zip" -o%~dp0\ >nul 2>&1
        cls
        rmdir /S /Q Atlas-%devbranch% >nul 2>&1
        :: relaunch as updated
        nsudo -U:T -P:E atlas-config.bat %~1&exit
    )
    echo Skipping Update...
)

:: will loop update check if debugging.
if /i "%~1"=="/t"		   goto TestSuccess
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
if /i "%~1"=="/depE"         goto depE
if /i "%~1"=="/depD"         goto depD
if /i "%~1"=="/ssD"         goto SearchStart
if /i "%~1"=="/openshell"         goto openshellInstall
if /i "%~1"=="/uwp"			goto uwp
if /i "%~1"=="/mite"			goto mitE
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
Rundll32.exe advapi32.dll,ProcessIdleTasks
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
schtasks /Change /DISABLE /TN "\Microsoft\Windows\Shell\CreateObjectTask"
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
cls
echo Please wait. This may take a moment.

:: Enable MSI Mode on USB Controllers
:: second command for each device deletes device priorty, setting it to undefined
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
:: Eenable MSI Mode on GPU
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
:: Enable MSI Mode on Network Adapters
:: undefined priority on some VMs may break connection
:: TODO: VM Detection, if VM = set to normal
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
:: Enable MSI Mode on Sata controllers
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
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
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%i
set /a ram=%mem% + 1024000
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f
echo SVCSplit: %ram%

:: Disable Power savings on drives
for /f %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "StorPort"^| findstr "StorPort"') do reg add "%%i" /v "EnableIdlePowerManagement" /t REG_DWORD /d "0" /f
cls
echo Please wait. This may take a moment.

sc stop wuauserv
Reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientIdValidation" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientId" /t REG_SZ /d "00000000-0000-0000-0000-000000000000" /f

:: disable hibernation
powercfg -h off

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
del /F /Q C:\Windows\AtlasModules\DevManView.cfg
:: lowering dual boot choice time
:: No, this does NOT affect single OS boot time.
:: This is directly shown in microsoft docs https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--timeout#parameters
bcdedit /timeout 10
:: Settings to No provides worse results, delete the value instead.
:: This is here as a safeguard incase of User Error.
bcdedit /deletevalue useplatformclock
:: Disable synthetic timer
bcdedit /set useplatformtick yes
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /set disabledynamictick Yes

bcdedit /set debug no
bcdedit /bootdebug off
:: Disable DEP, may need to enable for FACEIT or Valorant
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOff
:: Trusted Platform Module is removed, keeping here until I can test if this affects anything.
bcdedit /set tpmbootentropy ForceDisable
:: Disable Early Launch Antimalware drivers
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#verification-settings
bcdedit /set disableelamdrivers yes
:: disable EMS
bcdedit /set ems No
bcdedit /set bootems No 

del /f C:\ProgramData\vcredist.exe

:: re-enable UAC
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f
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
sc config netprofm start=disabled
sc stop netprofm >nul 2>&1
goto finish
:: netprofm needs to be stopped before dependants are disabled
sc config NlaSvc start=disabled
sc config WlanSvc start=disabled
goto finish
:wifiE
sc config netprofm start=demand
sc config NlaSvc start=auto
sc config WlanSvc start=demand
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
:: sc config WinHttpAutoProxySvc start=disabled
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
:: Insufficent permissions to enable
:: sc config WinHttpAutoProxySvc start=demand
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
goto finish
:btE
sc config BthAvctpSvc start=auto
sc start BthAvctpSvc >nul 2>&1
goto finish
:depE
powershell set-ProcessMitigation -System -Enable DEP
powershell set-ProcessMitigation -System -Enable EmulateAtlThunks
bcdedit /set nx OptIn
goto finish
:depD
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
echo This will only remove Startmenu, Search and RuntimeBroker. Which should break the majority of UWP.
echo Removing other UWP apps can be removed via Geek Uninstaller or Bulk Crap Uninstaller.
echo Removal of other UWP apps will be supported later.
pause
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

icacls "C:\Program Files\WindowsApps\" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Program Files\WindowsApps\ /R /D Y  >nul 2>nul
rmdir /S /Q C:\Program Files\WindowsApps\  >nul 2>nul

icacls "C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy /R /D Y  >nul 2>nul
rmdir /S /Q C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy  >nul 2>nul

icacls "C:\Windows\System32\RuntimeBroker.exe" /t /c /q /grant administrators:F  >nul 2>nul
takeown /F C:\Windows\System32\RuntimeBroker.exe /R /D Y  >nul 2>nul
taskkill /F /IM RuntimeBroker*  >nul 2>nul
rmdir /S /Q C:\Windows\System32\RuntimeBroker.exe  >nul 2>nul
taskkill /F /IM RuntimeBroker*  >nul 2>nul
rmdir /S /Q C:\Windows\System32\RuntimeBroker.exe  >nul 2>nul
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
:permFAIL
	echo Permission grants failed. Please try again by launching the script through the respected scripts, which will give it the correct permissions.
	pause&exit
:finish
echo Finished, please reboot for changes to apply.
:finishNRB
echo Finished, changes have been applied.
pause
