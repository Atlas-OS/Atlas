:: Name: Atlas Configuration Script
:: Description: This is the master script used to congigure the Atlas Operating System.
:: Version: 0.5.1
:: Branch: 20H2

:: CREDITS, in no particular order
:: Amit
:: Artanis
:: CYNAR
:: Canonez
:: CatGamerOP
:: EverythingTech
:: Melody
:: Revision
:: imribiy
:: nohopestage

@echo off
>nul 2>nul "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto permFAIL
)
:permSUCCESS
SETLOCAL EnableDelayedExpansion

if /i "%~1"=="/start"		   goto startup
:: will loop update check if debugging.
:: Notifications
if /i "%~1"=="/dn"         goto notiD
if /i "%~1"=="/en"         goto notiE
:: Animations
if /i "%~1"=="/ad"         goto aniD
if /i "%~1"=="/ae"         goto aniE
:: Search Indexing
if /i "%~1"=="/di"         goto indexD
if /i "%~1"=="/ei"         goto indexE
:: Wi-Fi
if /i "%~1"=="/dw"         goto wifiD
if /i "%~1"=="/ew"         goto wifiE
:: Microsoft Store
if /i "%~1"=="/ds"         goto storeD
if /i "%~1"=="/es"         goto storeE
:: Bluetooth
if /i "%~1"=="/btd"         goto btD
if /i "%~1"=="/bte"         goto btE
:: Hard Drive Prefetching
if /i "%~1"=="/hddd"         goto hddD
if /i "%~1"=="/hdde"         goto hddE
:: DEP (nx)
if /i "%~1"=="/depE"         goto depE
if /i "%~1"=="/depD"         goto depD
if /i "%~1"=="/ssD"         goto SearchStart
if /i "%~1"=="/ssE"         goto enableStart
if /i "%~1"=="/openshell"         goto openshellInstall
:: Remove UWP
if /i "%~1"=="/uwp"			goto uwp
if /i "%~1"=="/uwpE"			goto uwpE
if /i "%~1"=="/mite"			goto mitE
:: Remove Start Layout GPO (Allow Tiles on Start Menu)
if /i "%~1"=="/stico"          goto startlayout
:: Sleep States
if /i "%~1"=="/sleepD"         goto sleepD
if /i "%~1"=="/sleepE"         goto sleepE
:: Xbox
if /i "%~1"=="/xboxU"         goto xboxU
:: Reinstall VC++ redistributable
if /i "%~1"=="/vcreR"         goto vcreR
:: DWM
if /i "%~1"=="/dwmCon"		goto dwmCon
:: User Account Control
if /i "%~1"=="/uacD"		goto uacD
if /i "%~1"=="/uacE"		goto uacE
:: Workstation Service (SMB)
if /i "%~1"=="/workD"		goto workstationD
if /i "%~1"=="/workE"		goto workstationE
:: Windows Firewall
if /i "%~1"=="/firewallD"		goto firewallD
if /i "%~1"=="/firewallE"		goto firewallE
:: Printing
if /i "%~1"=="/printD"		goto printD
if /i "%~1"=="/printE"		goto printE
:: Data Queue Sizes
if /i "%~1"=="/dataQueueM"		goto dataQueueM
if /i "%~1"=="/dataQueueK"		goto dataQueueK
:: Network
if /i "%~1"=="/netWinDefault"		goto netWinDefault
if /i "%~1"=="/netAtlasDefault"		goto netAtlasDefault
:: Clipboard History Service (Also required for Snip and Sketch to copy correctly)
if /i "%~1"=="/cbdhsvcD"    goto cbdhsvcD
if /i "%~1"=="/cbdhsvcE"    goto cbdhsvcE
:: VPN 
if /i "%~1"=="/vpnD"    goto vpnD
if /i "%~1"=="/vpnE"    goto vpnE
:: debugging purposes only
if /i "%~1"=="/test"         goto TestPrompt
:argumentFAIL
echo atlas-config had no arguements passed to it, either you are launching atlas-config directly or the script, "%~nx0" script is broken.
echo Please report this to the Atlas discord or github.
pause&exit
:TestPrompt
set /p c="Test with echo on?"
if %c% equ Y echo on
set /p argPrompt="Which script would you like to test? e.g. (:testScript)"
goto %argPrompt%
echo You should not reach this message!
pause
exit
:startup
:: Create log directory, for troubleshooting
mkdir C:\Windows\AtlasModules\logs
cls
echo Please wait, this may take a moment.
setx path "%path%;C:\Windows\AtlasModules;" -m  >nul 2>nul
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Atlas Modules Path Set...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set Atlas Modules Path! >> C:\Windows\AtlasModules\logs\install.log)
:: Breaks setting keyboard language
:: Rundll32.exe advapi32.dll,ProcessIdleTasks
break>C:\Users\Public\success.txt
echo false > C:\Users\Public\success.txt
:auto
SETLOCAL EnableDelayedExpansion
C:\Windows\AtlasModules\vcredist.exe /ai
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Visual C++ Redistributable Runtimes Installed...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to install Visual C++ Redistributable Runtimes! >> C:\Windows\AtlasModules\logs\install.log)
:: change ntp server from windows server to pool.ntp.org
sc config W32Time start=demand >nul 2>nul
sc start W32Time >nul 2>nul
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
sc queryex "w32time"|Find "STATE"|Find /v "RUNNING"||(
    net stop w32time
    net start w32time
) >nul 2>nul
:: resync time to pool.ntp.org
w32tm /config /update
w32tm /resync
sc stop W32Time
sc config W32Time start=disabled
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% NTP Server Set...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set NTP Server! >> C:\Windows\AtlasModules\logs\install.log)
cls
echo Please wait. This may take a moment.
:: Optimize NTFS parameters
:: Disable Last Access information on directories, performance/privacy.
fsutil behavior set disableLastAccess 1 
:: https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security/
fsutil behavior set disable8dot3 1
:: Disable NTFS compression
fsutil behavior set disablecompression 1
:: Disable FS Mitigations
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "0" /f
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% FS Optimized...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Optimize FS! >> C:\Windows\AtlasModules\logs\install.log)
:: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/language-packs-known-issue
schtasks /Change /Disable /TN "\Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" >nul 2>nul
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Control Panel\International" /v "BlockCleanupOfUnusedPreinstalledLangPacks" /t REG_DWORD /d "1" /f
:: Disable unneeded Tasks
schtasks /Change /Disable /TN "\MicrosoftEdgeUpdateTaskMachineCore" >nul 2>nul
schtasks /Change /Disable /TN "\MicrosoftEdgeUpdateTaskMachineUA" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskFootprint\Diagnostics" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\StartupAppTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Autochk\Proxy" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskFootprint\StorageSense" >nul 2>nul
schtasks /Change /Disable /TN "\MicrosoftEdgeUpdateBrowserReplacementTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Registry\RegIdleBackup" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange" >nul 2>nul
:: Breaks setting Lock Screen
:: schtasks /Change /Disable /TN "\Microsoft\Windows\Shell\CreateObjectTask"
schtasks /Change /Disable /TN "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance" >nul 2>nul
:: Should already be disabled
schtasks /Change /Disable /TN "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\StateRepository\MaintenanceTasks" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UPnP\UPnPHostConfig" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\RetailDemo\CleanupOfflineContent" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Shell\FamilySafetyMonitor" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\InstallService\ScanForUpdates" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\InstallService\SmartRetry" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\International\Synchronize Language Settings" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Multimedia\Microsoft\Windows\Multimedia" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Printing\EduPrintProv" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Ras\MobilityManager" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\PushToInstall\LoginCheck" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Time Synchronization\SynchronizeTime" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Time Zone\SynchronizeTimeZone" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\WaaSMedic\PerformRemediation" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Diagnosis\Scheduled" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Wininet\CacheTask" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Device Setup\Metadata Refresh" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" >nul 2>nul
schtasks /Change /Disable /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" >nul 2>nul
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Disabled Scheduled Tasks...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable Scheduled Tasks! >> C:\Windows\AtlasModules\logs\install.log)
cls
echo Please wait. This may take a moment.

:: Enable MSI Mode on USB Controllers
:: second command for each device deletes device priorty, setting it to undefined
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
:: Enable MSI Mode on GPU
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
:: Enable MSI Mode on Network Adapters
:: undefined priority on some VMs may break connection
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
:: If e.g. vmware is used, skip setting to undefined.
wmic computersystem get manufacturer /format:value| findstr /i /C:VMWare&&goto vmGO
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
goto noVM
:vmGO
:: Set to Normal Priority
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2"  /f
:noVM
:: Enable MSI Mode on Sata controllers
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID^| findstr /L "PCI\VEN_"') do reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% MSI Mode Set...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set MSI Mode! >> C:\Windows\AtlasModules\logs\install.log)
cls
echo Please wait. This may take a moment.

:: Disabling certain process mitigations

::DEP
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#data-execution-prevention
powershell -NoProfile set-ProcessMitigation -System -Disable DEP
powershell -NoProfile set-ProcessMitigation -System -Disable EmulateAtlThunks
::ASLR
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#address-space-layout-randomization
powershell -NoProfile set-ProcessMitigation -System -Disable RequireInfo
powershell -NoProfile set-ProcessMitigation -System -Disable BottomUp
powershell -NoProfile set-ProcessMitigation -System -Disable HighEntropy
powershell -NoProfile set-ProcessMitigation -System -Disable StrictHandle
::BlockDynamicCode
::AllowThreadsToOptOut
::AuditDynamicCode
::CFG
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#control-flow-guard
powershell -NoProfile set-ProcessMitigation -System -Disable CFG
powershell -NoProfile set-ProcessMitigation -System -Disable StrictCFG
powershell -NoProfile set-ProcessMitigation -System -Disable SuppressExports
::SEHOP
::https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#structured-exception-handling-overwrite-protection
powershell -NoProfile set-ProcessMitigation -System -Disable SEHOP
powershell -NoProfile set-ProcessMitigation -System -Disable AuditSEHOP
powershell -NoProfile set-ProcessMitigation -System -Disable SEHOPTelemetry
powershell -NoProfile set-ProcessMitigation -System -Disable ForceRelocateImages
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Mitigations Disabled...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable Mitigations! >> C:\Windows\AtlasModules\logs\install.log)

:: --- Hardening ---

:: Delete Defaultuser0
:: Used during OOBE
net user defaultuser0 /delete >nul 2>nul

:: Disable "Administrator"
:: Used in OEM Situations to install OEM-specific programs when a user is not yet created.
net user administrator /active:no

:: Delete Adobe Font Type Manager
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Font Drivers" /v "Adobe Type Manager" /f

:: Disable Autorun/play
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d "1" /f

:: Disable Camera Access when locked
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d "1" /f

:: Disable Remote Assistance
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowFullControl" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Remote Assistance" /v "fEnableChatControl" /t REG_DWORD /d "0" /f

:: SMB Hardening
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220932
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters" /v "RestrictNullSessAccess" /t REG_DWORD /d "1" /f
:: Disable SMB Compression (Possible SMBGhost Vulnerability workaround)
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters" /v "DisableCompression" /t REG_DWORD /d "1" /f

:: Restrict Enumeration of Anonymous SAM Accounts
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220929
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" /v "RestrictAnonymousSAM" /t REG_DWORD /d "1" /f
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220930
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" /v "RestrictAnonymous" /t REG_DWORD /d "1" /f

:: Harden NetBios
:: NetBios is disabled. If it manages to become enabled, protect against NBT-NS poisoning attacks
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters" /v "NodeType" /t REG_DWORD /d "2" /f

:: Mitigate against HiveNightmare/SeriousSAM
icacls %windir%\system32\config\*.* /inheritance:e

:: Import the powerplan
powercfg -import "C:\Windows\AtlasModules\Atlas.pow" 11111111-1111-1111-1111-111111111111
:: Set current powerplan to Atlas
powercfg /s 11111111-1111-1111-1111-111111111111
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% PowerPlan Imported...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to import PowerPlan! >> C:\Windows\AtlasModules\logs\install.log)

:: Set SvcSplitThreshold
:: Credits: revision
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%i
set /a ram=%mem% + 1024000
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Service Memory Split Set...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set Service Memory Split! >> C:\Windows\AtlasModules\logs\install.log)

:: tokens arg breaks path to just \Device instead of \Device Parameters
:: Disable Power savings on drives
for /f "tokens=*" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum" /s /f "StorPort"^| findstr "StorPort"') do reg add "%%i" /v "EnableIdlePowerManagement" /t REG_DWORD /d "0" /f
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Disabled Storage Powersaving...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable Storage Powersaving! >> C:\Windows\AtlasModules\logs\install.log)

:: Disable Power Saving
:: Now lists PnP devices, instead of the previously used 'reg query'
for /f "tokens=*" %%i in ('wmic PATH Win32_PnPEntity GET DeviceID ^| findstr "USB\VID_"') do (
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d "0" /f
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "AllowIdleIrpInD3" /t REG_DWORD /d "0" /f
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "EnableSelectiveSuspend" /t REG_DWORD /d "0" /f
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "DeviceSelectiveSuspended" /t REG_DWORD /d "0" /f
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "SelectiveSuspendEnabled" /t REG_DWORD /d "0" /f
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "SelectiveSuspendOn" /t REG_DWORD /d "0" /f
 reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "D3ColdSupported" /t REG_DWORD /d "0" /f
)
powershell -NoProfile -Command "$devices = Get-WmiObject Win32_PnPEntity; $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($p in $powerMgmt){$IN = $p.InstanceName.ToUpper(); foreach ($h in $devices){$PNPDI = $h.PNPDeviceID; if ($IN -like \"*$PNPDI*\"){$p.enable = $False; $p.psbase.put()}}}" >nul 2>nul
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Disabled Powersaving...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable Powersaving! >> C:\Windows\AtlasModules\logs\install.log)

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
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Enabled Hidden PowerPlan Attributes...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Enable Hidden PowerPlan Attributes! >> C:\Windows\AtlasModules\logs\install.log)

:: Residual File Cleanup
:: Files are removed in official ISO
del /F /Q "%WinDir%\System32\GameBarPresenceWriter.exe" >nul 2>nul
del /F /Q "%WinDir%\System32\mobsync.exe" >nul 2>nul
del /F /Q "%WinDir%\System32\mcupdate_genuineintel.dll" >nul 2>nul
del /F /Q "%WinDir%\System32\mcupdate_authenticamd.dll" >nul 2>nul
:: Remove Edge
rmdir /s /q "C:\Program Files (x86)\Microsoft" >nul 2>nul
:: Remove residual registry keys
reg delete "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\Classes\MSEdgeHTM" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EventLog\Application\edgeupdate" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EventLog\Application\edgeupdatem" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\EdgeUpdate" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Edge" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Device Metadata" /f >nul 2>nul
:: Not checking for errorlevel, as these are often deleted in the first place. So if it were to error it would only cause confusion.
echo %date% - %time% Residule Files Deleted...>> C:\Windows\AtlasModules\logs\install.log

:: Disable Nagle's Algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%i in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
  reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
  reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
  reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: Configure NIC Setting
:: Get nic driver settings path by querying for dword
:: If you see a way to optimize this segment, feel free to open a pull request.
for /f %%a in ('reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    :: Check if the value exists, to prevent errors and uneeded settings
    for /f %%i in ('reg query "%%a" /v "GigaLite" ^| findstr "HKEY"') do (
        :: add the value
        :: if the value does not exist, it will silently error.
        reg add "%%i" /v "GigaLite" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "*EEE" ^| findstr "HKEY"') do (
        reg add "%%i" /v "*EEE" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "*FlowControl" ^| findstr "HKEY"') do (
        reg add "%%i" /v "*FlowControl" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "PowerSavingMode" ^| findstr "HKEY"') do (
        reg add "%%i" /v "PowerSavingMode" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableSavePowerNow" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnablePowerManagement" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePowerManagement" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableGreenEthernet" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableDynamicPowerGating" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableDynamicPowerGating" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableConnectedPowerGating" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableConnectedPowerGating" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "AutoPowerSaveModeEnabled" ^| findstr "HKEY"') do (
        reg add "%%i" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "AutoDisableGigabit" ^| findstr "HKEY"') do (
        reg add "%%i" /v "AutoDisableGigabit" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "AdvancedEEE" ^| findstr "HKEY"') do (
        reg add "%%i" /v "AdvancedEEE" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "ULPMode" ^| findstr "HKEY"') do (
        reg add "%%i" /v "ULPMode" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "ReduceSpeedOnPowerDown" ^| findstr "HKEY"') do (
        reg add "%%i" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnablePME" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePME" /t REG_SZ /d "0" /f
    )
) >nul 2>nul
netsh int tcp set heuristics disabled
netsh int tcp set supplemental Internet congestionprovider=ctcp
netsh int tcp set global timestamps=disabled
netsh int tcp set global rsc=disabled
for /f "tokens=1" %%i in ('netsh int ip show interfaces ^| findstr [0-9]') do (
	netsh int ip set interface %%i routerdiscovery=disabled store=persistent
)
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Network Optimized...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Optimize Network! >> C:\Windows\AtlasModules\logs\install.log)
:: Disable Network Adapters
:: IPv6
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6"
:: Client for Microsoft Networks
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient"
:: QoS Packet Scheduler
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_pacer"
:: File and Printer Sharing
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_server"

sc stop wuauserv >nul 2>nul
:: reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientIdValidation" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientId" /t REG_SZ /d "00000000-0000-0000-0000-000000000000" /f

:: disable hibernation
powercfg -h off

:: Fix explorer whitebar bug
start explorer.exe
taskkill /f /im explorer.exe
start explorer.exe

:: Disable Memory Compression
powershell -NoProfile -Command "Disable-MMAgent -mc"

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
::devmanview /disable "Microsoft Virtual Drive Enumerator" < Breaks ISO mounts
devmanview /disable "Numeric Data Processor"
devmanview /disable "Microsoft RRAS Root Enumerator"
IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Disabled Devices...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable Devices! >> C:\Windows\AtlasModules\logs\install.log)

:: Backup Default Windows Services and Drivers
:: Services
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows Services.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo. >> %filename%
for /f "skip=1" %%i in ('wmic service get Name^| findstr "[a-z]"^| findstr /V "TermService"') do (
	set svc=%%i
	set svc=!svc: =!
	for /f "tokens=3" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e^| findstr "[0-4]$"') do (
		set start=%%i
		if !start!==0x4 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000004 >> %filename%
			echo. >> %filename% )
		if !start!==0x3 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000003 >> %filename%
			echo. >> %filename% )
		if !start!==0x2 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000002 >> %filename%
			echo. >> %filename% )
		if !start!==0x1 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000001 >> %filename%
			echo. >> %filename% )
		if !start!==0x0 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000000 >> %filename%
			echo. >> %filename% )
	)
) >nul 2>&1

:: Drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows Drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo. >> %filename%
for /f "delims=," %%i in ('driverquery /FO CSV') do (
	set svc=%%~i
	for /f "tokens=3" %%f in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%~i" /t REG_DWORD /s /c /f "Start" /e^| findstr "[0-4]$"') do (
		set start=%%f
		if !start!==0x4 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000004 >> %filename%
			echo. >> %filename% )
		if !start!==0x3 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000003 >> %filename%
			echo. >> %filename% )
		if !start!==0x2 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000002 >> %filename%
			echo. >> %filename% )
		if !start!==0x1 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000001 >> %filename%
			echo. >> %filename% )
		if !start!==0x0 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000000 >> %filename%
			echo. >> %filename% )
	) 
) >nul 2>&1

:: Services
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AppIDSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AppVClient" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AppXSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BthAvctpSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\cbdhsvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\CryptSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\defragsvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\diagnosticshub.standardcollector.service" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\diagsvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DispBrokerDesktopSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DisplayEnhancementService" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DoSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DPS" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DsmSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DsSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Eaphost" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\edgeupdate" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\edgeupdatem" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EFS" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\fdPHost" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\FDResPub" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\FontCache" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\FontCache3.0.0.0" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\icssvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\IKEEXT" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\InstallService" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\IpxlatCfgSvc" /v "Start" /t REG_DWORD /d "4" /f
::Causes issues with NVCleanstall and driver telemetry tweak
:: reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\KeyIso" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\KtmRm" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanmanServer" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanmanWorkstation" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\lmhosts" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\MSDTC" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetTcpPortSharing" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\PcaSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\QWAVE" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\RasMan" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SharedAccess" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\ShellHWDetection" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SmsRouter" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Spooler" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\sppsvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SSDPSRV" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SstpSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SysMain" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Themes" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VaultSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\W32Time" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WarpJITSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WdiServiceHost" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WdiSystemHost" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Wecsvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WEPHOSTSVC" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WPDBusEnum" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "3" /f
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
)
sc config CDPSvc start=disabled

:: Drivers
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\3ware" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\ADP80XX" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AmdK8" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\arcsas" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AsyncMac" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Beep" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\bindflt" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\buttonconverter" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\CAD" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\cdfs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\CimFS" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\circlass" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\cnghwassist" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\CompositeBus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Dfsc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\ErrDev" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\fdc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\flpydisk" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\fvevol" /v "Start" /t REG_DWORD /d "4" /f
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\FileInfo" /v "Start" /t REG_DWORD /d "4" /f < Breaks installing Store Apps to different disk. (Now disabled via store script)
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\FileCrypt" /v "Start" /t REG_DWORD /d "4" /f < Breaks installing Store Apps to different disk. (Now disabled via store script)
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\GpuEnergyDrv" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb20" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NdisVirtualBus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\nvraid" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\PEAUTH" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\QWAVEdrv" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rdbss" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rdyboost" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\KSecPkg" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb20" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\srv2" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\sfloppy" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SiSRaid2" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SiSRaid4" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip6" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\tcpipreg" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Telemetry" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\udfs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\umbus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VerifierExt" /v "Start" /t REG_DWORD /d "4" /f
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\volmgrx" /v "Start" /t REG_DWORD /d "4" /f < Breaks Dynamic Disks
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\vsmraid" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VSTXRAID" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\wcifs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\wcnfs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WindowsTrustedRTProxy" /v "Start" /t REG_DWORD /d "4" /f

:: Remove dependencies
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Dhcp" /v "DependOnService" /t REG_MULTI_SZ /d "NSI\0Afd" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Dnscache" /v "DependOnService" /t REG_MULTI_SZ /d "nsi" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rdyboost" /v "DependOnService" /t REG_MULTI_SZ /d "" /f

reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_SZ /d "" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_SZ /d "" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\fvevol" /v "Start" /t REG_DWORD /d "4" /f

IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Disabled Services...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable Services! >> C:\Windows\AtlasModules\logs\install.log)

:: Backup Default Atlas Services and Drivers
:: Services
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas Services.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo. >> %filename%
for /f "skip=1" %%i in ('wmic service get Name^| findstr "[a-z]"^| findstr /V "TermService"') do (
	set svc=%%i
	set svc=!svc: =!
	for /f "tokens=3" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e^| findstr "[0-4]$"') do (
		set start=%%i
		if !start!==0x4 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000004 >> %filename%
			echo. >> %filename% )
		if !start!==0x3 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000003 >> %filename%
			echo. >> %filename% )
		if !start!==0x2 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000002 >> %filename%
			echo. >> %filename% )
		if !start!==0x1 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000001 >> %filename%
			echo. >> %filename% )
		if !start!==0x0 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000000 >> %filename%
			echo. >> %filename% )
	)
) >nul 2>&1

:: Drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas Drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo. >> %filename%
for /f "delims=," %%i in ('driverquery /FO CSV') do (
	set svc=%%~i
	for /f "tokens=3" %%f in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%~i" /t REG_DWORD /s /c /f "Start" /e^| findstr "[0-4]$"') do (
		set start=%%f
		if !start!==0x4 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000004 >> %filename%
			echo. >> %filename% )
		if !start!==0x3 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000003 >> %filename%
			echo. >> %filename% )
		if !start!==0x2 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000002 >> %filename%
			echo. >> %filename% )
		if !start!==0x1 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000001 >> %filename%
			echo. >> %filename% )
		if !start!==0x0 (
			echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
			echo "Start"=dword:00000000 >> %filename%
			echo. >> %filename% )
	) 
) >nul 2>&1

:: Registry
:: Done through script now, HKCU\.. keys often don't integrate correctly.

:: BSOD QoL
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\CrashControl" /v "AutoReboot" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\CrashControl" /v "DisplayParameters" /t REG_DWORD /d "1" /f

:: GPO for Startmenu (tiles)
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "C:\Windows\layout.xml" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "C:\Windows\layout.xml" /f

:: Enable dark mode, disable transparency
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f

:: Disable Windows Updates
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableDualScan" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AUPowerManagement" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAutoRestartNotificationDisable" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ManagePreviewBuilds" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ManagePreviewBuildsPolicyValue" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdates" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "BranchReadinessLevel" /t REG_DWORD /d "20" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d "365" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdates" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUAsDefaultShutdownOption" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "	DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d "1" /f

:: Disable Speech Model Updates
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d "0" /f

::Disable Windows Insider and Build Previews
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableConfigFlighting" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\PreviewBuilds" /v "AllowBuildPreview" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableExperimentation" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\WindowsSelfHost\UI\Visibility" /v "HideInsiderPage" /t REG_DWORD /d "1" /f

:: Pause Maps Updates/Downloads
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Maps" /v "AutoDownloadAndUpdateMapData" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d "0" /f

:: Disable Smartscreen
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v "LowRiskFileTypes" /t REG_SZ /d ".avi;.bat;.cmd;.exe;.htm;.html;.lnk;.mpg;.mpeg;.mov;.mp3;.mp4;.mkv;.msi;.m3u;.rar;.reg;.txt;.vbs;.wav;.zip;.7z" /f

:: Disable CEIP
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Messenger\Client" /v "CEIP" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d "0" /f

:: Disable Windows Media Player DRM Online Access
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WMDRM" /v "DisableOnline" /t REG_DWORD /d "1" /f

:: Disable Web in Search
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0" /f

:: Data Queue Sizes
:: set to half of default
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d "50" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d "50" /f

:: Explorer
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "LinkResolveIgnoreLinkInfo" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInternetOpenWith" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d "1" /f
:: Old Alt Tab
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "AltTabSettings" /t REG_DWORD /d "1" /f

:: Enable Hardware Accelerated Scheduling
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f

:: Application Compatability
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppCompat" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableEngine" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d "1" /f

:: Disable Mouse Acceleration
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f

:: Disable Annoying Keyboard Features
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_DWORD /d "0" /f

:: Disable Connection Checking (pings Microsoft Servers)
:: May cause internet icon to show it is disconnected
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d "0" /f

:: Restrict Windows' access to internet resources
:: Enables various other GPOs that limit access on specific windows services
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\InternetManagement" /v "RestrictCommunication" /t REG_DWORD /d "1" /f

:: Disable Text/Ink/Handwriting Telemetry
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\TabletPC" /v "PreventHandwritingDataSharing" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d "1" /f

:: Disable Windows Error Reporting
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d "0" /f

:: Disable Data Collection
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d "0" /f

:: Misc
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v "ShowedToastAtLevel" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d "0" /f

:: Content Delivery Manager
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314563Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d "0" /f

:: Advertising Info
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f

:: Disable Sleep Study
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Power" /v "SleepStudyDisabled" /t REG_DWORD /d "1" /f

:: Opt-out of sending KMS client activation data to Microsoft automatically. Enabling this setting prevents this computer from sending data to Microsoft regarding its activation state. 
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d "1" /f

:: Disable Feedback
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d "0" /f

:: Disable Settings Sync
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSync" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSyncUserOverride" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\SettingSync" /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" /v "Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" /v "Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" /v "Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" /v "Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" /v "Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SettingSync" /v "SyncPolicy" /t REG_DWORD /d "5" /f

:: Power
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Power" /v "EventProcessorEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f

:: Location Tracking
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\FindMyDevice" /v "LocationSyncEnabled" /t REG_DWORD /d "0" /f

:: remove readyboost tab
reg delete "HKEY_CLASSES_ROOT\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f >nul 2>nul

:: Hide "Meet Now" button. For future proofing
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f

:: Disable Shared Experiences
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d "0" /f

:: Internet Explorer QoL
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v "NoUpdateCheck" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v "Enable Browser Extensions" /t REG_SZ /d "no" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v "Isolation" /t REG_SZ /d "PMEM" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v "Isolation64Bit" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\BrowserEmulation" /v "IntranetCompatibilityMode" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer" /v "DisableFlashInIE" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\DomainSuggestion" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Security" /v "DisableSecuritySettingsCheck" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Security" /v "DisableFixSecuritySettings" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Privacy" /v "EnableInPrivateBrowsing" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Privacy" /v "ClearBrowsingHistoryOnExit" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v "EnableAutoUpgrade" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v "HideNewEdgeButton" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Feed Discovery" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Feeds" /v "BackgroundSyncStatus" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\FlipAhead" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Suggested Sites" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\TabbedBrowsing" /v "NewTabPageShow" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Internet Explorer\Control Panel" /v "HomePage" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "https://atlasos.net" /f

:: show all tasks on control panel, credits to tenforums
reg add "HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "InfoTip" /t REG_SZ /d "View list of all Control Panel tasks" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "System.ControlPanel.Category" /t REG_SZ /d "5" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-27" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\Shell\Open\Command" /ve /t REG_SZ /d "explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f

:: Memory Management
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableCfg" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePageCombining" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d "1" /f

:: Disable Fault Tolerant Heap
:: https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
:: Doc listed as only affected in windows 7, is also in 7+
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d "0" /f
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#structured-exception-handling-overwrite-protection
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "KernelSEHOPEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "1" /f
:: https://www.intel.com/content/www/us/en/support/articles/000059422/processors.html
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: MMCSS
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d "10" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "10" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "10000" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d "10000" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d "18" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d "6" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Latency Sensitive" /t REG_SZ /d "True" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "NoLazyMode" /t REG_DWORD /d "1" /f

:: GameBar/FSE
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d "3" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_DSEBehavior" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f

:: Disallow Background Apps
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f

:: Set Win32PrioritySeparation 26 hex/38 dec
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "38" /f

:: Disable Notification/Action Center
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoTileApplicationNotification" /t REG_DWORD /d "1" /f

:: Hung Apps, Wait to Kill, QoL
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "8" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d "1000" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9A12038010000000" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f

:: Visual
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f

:: DWM
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM" /v "Composition" /t REG_DWORD /d "0" /f
:: Needs testing 
:: https://djdallmann.github.io/GamingPCSetup/CONTENT/RESEARCH/FINDINGS/registrykeys_dwm.txt
::reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Dwm" /v "AnimationAttributionEnabled" /t REG_DWORD /d "0" /f

:: add batch to new file menu
reg add "HKEY_LOCAL_MACHINE\Software\Classes\.bat\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6002" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\.bat\ShellNew" /v "NullFile" /t REG_SZ /d "" /f

:: add reg to new file menu
reg add "HKEY_LOCAL_MACHINE\Software\Classes\.reg\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\regedit.exe,-309" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\.reg\ShellNew" /v "NullFile" /t REG_SZ /d "" /f

:: Disable Storage Sense
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d "0" /f

:: Disable Maintenance
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "1" /f

:: Do not reduce sounds while in a call
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Multimedia\Audio" /v "UserDuckingPreference" /t REG_DWORD /d "3" /f

:: Edge
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\EdgeUI" /v "DisableMFUTracking" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d "0" /f

:: install cab context menu
reg delete "HKEY_CLASSES_ROOT\CABFolder\Shell\RunAs" /f >nul 2>nul
reg add "HKEY_CLASSES_ROOT\CABFolder\Shell\RunAs" /ve /t REG_SZ /d "Install" /f
reg add "HKEY_CLASSES_ROOT\CABFolder\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKEY_CLASSES_ROOT\CABFolder\Shell\RunAs\Command" /ve /t REG_SZ /d "cmd /k dism /online /add-package /packagepath:\"%%1\"" /f

:: "Merge as TrustedInstaller" for .regs
reg add "HKEY_CLASSES_ROOT\regfile\Shell\RunAs" /ve /t REG_SZ /d "Merge As TrustedInstaller" /f
reg add "HKEY_CLASSES_ROOT\regfile\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "1" /f
reg add "HKEY_CLASSES_ROOT\regfile\Shell\RunAs\Command" /ve /t REG_SZ /d "nsudo -U:T -P:E reg import "%%1"" /f

:: add run with priority context menu
reg add "HKEY_CLASSES_ROOT\exefile\shell\Priority" /v "MUIVerb" /t REG_SZ /d "Run with priority" /f
reg add "HKEY_CLASSES_ROOT\exefile\shell\Priority" /v "SubCommands" /t REG_SZ /d "" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\001flyout" /ve /t REG_SZ /d "Realtime" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\001flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /Realtime \"%%1\"" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\002flyout" /ve /t REG_SZ /d "High" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\002flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /High \"%%1\"" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\003flyout" /ve /t REG_SZ /d "Above normal" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\003flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /AboveNormal \"%%1\"" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\004flyout" /ve /t REG_SZ /d "Normal" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\004flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /Normal \"%%1\"" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\005flyout" /ve /t REG_SZ /d "Below normal" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\005flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /BelowNormal \"%%1\"" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\006flyout" /ve /t REG_SZ /d "Low" /f
reg add "HKEY_CLASSES_ROOT\exefile\Shell\Priority\shell\006flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /Low \"%%1\"" /f

:: remove include in library context menu
reg delete "HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\Library Location" /f >nul 2>nul
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" /f >nul 2>nul

:: Remove Share in context menu
reg delete "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\ModernSharing" /f >nul 2>nul

:: double click to import power plans
reg add "HKEY_LOCAL_MACHINE\Software\Classes\powerplan\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\powercpl.dll,1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\powerplan\Shell\open\command" /ve /t REG_SZ /d "powercfg /import \"%%1\"" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\.pow" /ve /t REG_SZ /d "powerplan" /f
reg add "HKEY_LOCAL_MACHINE\Software\Classes\.pow" /v "FriendlyTypeName" /t REG_SZ /d "PowerPlan" /f

IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Registry Tweaks Applied...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Apply Registry Tweaks! >> C:\Windows\AtlasModules\logs\install.log)

:: Disable DmaRemapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /f DmaRemappingCompatible ^| find /i "Services\" ') do (
	reg add "%%i" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)
echo %date% - %time% Disabled Dma Remapping...>> C:\Windows\AtlasModules\logs\install.log

IF %NUMBER_OF_PROCESSORS% LSS 7 (reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "DistributeTimers" /t REG_DWORD /d "0" /f
) ELSE (reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "DistributeTimers" /t REG_DWORD /d "1" /f)
echo %date% - %time% Distribute Timers Set...>> C:\Windows\AtlasModules\logs\install.log

:: set CSRSS to high
:: csrss is responsible for mouse input, setting to high may yield an improvement in input latency.
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "IoPriority" /t REG_DWORD /d "3" /f

:: Set System Processes Priority below normal
for %%i in (lsass.exe sppsvc.exe SearchIndexer.exe fontdrvhost.exe sihost.exe ctfmon.exe) do (
  reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "5" /f
)
:: Set background apps priority below normal
for %%i in (OriginWebHelperService.exe ShareX.exe EpicWebHelper.exe SocialClubHelper.exe steamwebhelper.exe) do (
  reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "5" /f
)
:: Set  DWM to normal
wmic process where name="dwm.exe" CALL setpriority "normal"

IF %ERRORLEVEL% EQU 0 (echo %date% - %time% Process Priorities Set...>> C:\Windows\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Set Priorities! >> C:\Windows\AtlasModules\logs\install.log)

:: lowering dual boot choice time
:: No, this does NOT affect single OS boot time.
:: This is directly shown in microsoft docs https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--timeout#parameters
bcdedit /timeout 10
:: Setting to No provides worse results, delete the value instead.
:: This is here as a safeguard incase of User Error.
bcdedit /deletevalue useplatformclock >nul 2>nul
:: Disable synthetic timer
bcdedit /set useplatformtick yes
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /set disabledynamictick Yes
:: Disable DEP, may need to enable for FACEIT, Valorant, and other Anti-Cheats.
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOff
:: Hyper-V support is removed, other virtualization programs are supported
bcdedit /set hypervisorlaunchtype off
:: Use legacy boot menu
bcdedit /set bootmenupolicy Legacy
:: Make dual boot menu more descriptive
bcdedit /set description Atlas
echo %date% - %time% BCD Options Set...>> C:\Windows\AtlasModules\logs\install.log

:: Write to script log file
echo This script keeps track of which scripts have been run. This is never transfered to an online resource and stays local. > C:\Windows\AtlasModules\logs\userScript.log
echo ----------------------------------------------------------------------------------------------------------------------- >> C:\Windows\AtlasModules\logs\userScript.log

:: clear false value
break>C:\Users\Public\success.txt
echo true > C:\Users\Public\success.txt
echo %date% - %time% Post-Install Finished Redirecting to sub script...>> C:\Windows\AtlasModules\logs\install.log
echo "C:\Windows\AtlasModules\nsudo -U:T -P:E -Wait C:\Windows\AtlasModules\atlas-config.bat /intsetup" > "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\intsetup.bat"
echo echo If the script unexpectedly closed, launch it from the atlas folder. >>  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\intsetup.bat"
echo pause >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\intsetup.bat"
exit
:notiD
sc config WpnService start=disabled
sc stop WpnService >nul 2>nul
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Notifications Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:notiE
sc config WpnUserService start=auto
sc config WpnService start=auto 
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "0" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Notifications Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:indexD
sc config WSearch start=disabled
sc stop WSearch >nul 2>nul
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Search Indexing Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:indexE
sc config WSearch start=delayed-auto
sc start WSearch >nul 2>nul
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Search Indexing Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:wifiD
echo Applications like Store and Spotify may not function correctly when disabled. If this is a problem, enable the wifi and restart the computer.
sc config WlanSvc start=disabled
sc config vwififlt start=disabled
set /P c="Would you like to disable the Network Icon? (disables 2 extra services) [Y/N]: "
if /I "%c%" EQU "Y" goto wifiDconfirm
if /I "%c%" EQU "N" goto wifiDskip
:wifiDconfirm
sc config netprofm start=disabled
sc config NlaSvc start=disabled
:wifiDskip
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Wi-Fi Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
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
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Wi-Fi Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:storeD
echo This will break a majority of UWP apps and their deployment.
echo Extra note: This breaks the "about" page in settings. If you require it, enable the AppX service.
:: This includes Windows Firewall, I only see the point in keeping it because of Store. 
:: If you notice something else breaks when firewall/store is disabled please open an issue.
pause
:: Detect if user is using a Microsoft Account
powershell -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource"|findstr /C:"MicrosoftAccount" >nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( sc config wlidsvc start=disabled ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )
:: Disable the option for Windows Store in the "Open With" dialog
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f
:: Block Access to Windows Store
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
sc config InstallService start=disabled
:: Insufficent permissions to disable
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f
sc config mpssvc start=disabled
sc config wlidsvc start=disabled
sc config AppXSvc start=disabled
sc config BFE start=disabled
sc config TokenBroker start=disabled
sc config LicenseManager start=disabled
sc config AppXSVC start=disabled
sc config ClipSVC start=disabled
sc config FileInfo start=disabled
sc config FileCrypt start=disabled
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Microsoft Store Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish
:storeE
:: Enable the option for Windows Store in the "Open With" dialog
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f
:: Allow Access to Windows Store
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
sc config InstallService start=demand
:: Insufficent permissions to enable through SC
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "3" /f
sc config mpssvc start=auto
sc config wlidsvc start=demand
sc config AppXSvc start=demand
sc config BFE start=auto
sc config TokenBroker start=demand
sc config LicenseManager start=demand
sc config wuauserv start=demand
sc config AppXSVC start=demand
sc config ClipSVC start=demand
sc config FileInfo start=boot
sc config FileCrypt start=system
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Microsoft Store Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:btD
sc config BthAvctpSvc start=disabled
sc stop BthAvctpSvc >nul 2>nul
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
  sc stop %%~nI
)
sc config CDPSvc start=disabled
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Bluetooth Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish
:btE
sc config BthAvctpSvc start=auto
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "2" /f
  sc start %%~nI
)
sc config CDPSvc start=auto
sc start BthAvctpSvc >nul 2>nul
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Bluetooth Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:cbdhsvcD
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f cbdhsvc ^| find /i "cbdhsvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
)
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "0" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Clipboard History Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:cbdhsvcE
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f cbdhsvc ^| find /i "cbdhsvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "3" /f
)
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "1" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Clipboard History Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:hddD
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
sc config SysMain start=disabled
sc config FontCache start=disabled
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Hard Drive Prefetch Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:hddE
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f
sc config SysMain start=auto
sc config FontCache start=auto
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Hard Drive Prefetch Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:depE
powershell -NoProfile set-ProcessMitigation -System -Enable DEP
powershell -NoProfile set-ProcessMitigation -System -Enable EmulateAtlThunks
bcdedit /set nx OptIn
:: Enable CFG for Valorant related processes
for %%i in (valorant valorant-win64-shipping vgtray vgc) do (
  powershell -NoProfile -Command "Set-ProcessMitigation -Name %%i.exe -Enable CFG"
)
IF %ERRORLEVEL% EQU 0 echo %date% - %time% DEP Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:depD
echo If you get issues with some anti-cheats, please re-enable DEP.
powershell -NoProfile set-ProcessMitigation -System -Disable DEP
powershell -NoProfile set-ProcessMitigation -System -Disable EmulateAtlThunks
bcdedit /set nx AlwaysOff
IF %ERRORLEVEL% EQU 0 echo %date% - %time% DEP Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:SearchStart
IF EXIST "C:\Program Files\Open-Shell" goto existS
IF EXIST "C:\Program Files (x86)\StartIsBack" goto existS
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the startmenu being removed.
pause
:existS
set /P c=This will disable SearchApp and StartMenuExperienceHost, are you sure you want to continue[Y/N]?
if /I "%c%" EQU "Y" goto continSS
if /I "%c%" EQU "N" goto stopS
:continSS
:: Rename Start Menu
chdir /d C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
:restartStart
taskkill /F /IM StartMenuExperienceHost*
ren StartMenuExperienceHost.exe StartMenuExperienceHost.old
:: Loop if it fails to rename the first time
if exist "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto restartStart
:: Rename Search
chdir /d C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy
:restartSearch
taskkill /F /IM SearchApp*  >nul 2>nul
ren SearchApp.exe SearchApp.old
:: Loop if it fails to rename the first time
if exist "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto restartSearch
:: Search Icon
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
start explorer.exe
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Search and Start Menu Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:enableStart
:: Rename Start Menu
chdir /d C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
ren StartMenuExperienceHost.old StartMenuExperienceHost.exe
:: Rename Search
chdir /d C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy
ren SearchApp.old SearchApp.exe
:: Search Icon
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f
taskkill /f /im explorer.exe
start explorer.exe
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Search and Start Menu Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:stopS
exit
:openshellInstall
curl -L --output C:\Windows\AtlasModules\oshellI.exe https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.160/OpenShellSetup_4_4_160.exe
IF EXIST "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" goto existOS
IF EXIST "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" goto existOS
goto rmSSOS
:existOS
set /P c=It appears Search and Start are installed, would you like to disable them also?[Y/N]?
if /I "%c%" EQU "Y" goto rmSSOS
if /I "%c%" EQU "N" goto skipRM
:rmSSOS
:: Rename Start Menu
taskkill /F /IM StartMenuExperienceHost*  >nul 2>nul
ren C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old
:: Rename Search
taskkill /F /IM SearchApp*  >nul 2>nul
ren C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy Microsoft.Windows.Search_cw5n1h2txyewy.old
:: Search Icon
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
start explorer.exe
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Search and Start Menu Removed...>> C:\Windows\AtlasModules\logs\userScript.log
:skipRM
:: Install silently
echo.
echo Openshell is installing...
"oshellI.exe" /qn ADDLOCAL=StartMenu

curl -L https://github.com/bonzibudd/Fluent-Metro/releases/download/v1.5/Fluent-Metro_1.5.zip -o skin.zip
7z -aoa -r e "skin.zip" -o"C:\Program Files\Open-Shell\Skins"
del /F /Q skin.zip >nul 2>nul
taskkill /f /im explorer.exe
start explorer.exe
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Open-Shell Installed...>> C:\Windows\AtlasModules\logs\userScript.log
goto finishNRB
:uwp
IF EXIST "C:\Program Files\Open-Shell" goto uwpD
IF EXIST "C:\Program Files (x86)\StartIsBack" goto uwpD
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the startmenu being removed.
pause&exit
:uwpD
echo This will remove all UWP packages that are currently installed. This will break multiple features that WILL NOT be supported while disabled.
echo A reminder of a few things this may break.
echo - Searching in file explorer
echo - Store
echo - Xbox
echo - Immersive Control Panel (Settings)
echo - Adobe XD
echo - Startmenu context menu
echo - Wi-Fi Menu
echo - Microsoft Accounts
echo - Microsoft Store
echo Please PROCEED WITH CAUTION, you are doing this at your own risk.
pause
:: Detect if user is using a Microsoft Account
powershell -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource"|findstr /C:"MicrosoftAccount" >nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( sc config wlidsvc start=disabled ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )
choice /c yn /m "Last warning, continue? [Y/N]" /n
sc stop TabletInputService
sc config TabletInputService start=disabled

:: Disable the option for Windows Store in the "Open With" dialog
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f
:: Block Access to Windows Store
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
sc config InstallService start=disabled
:: Insufficent permissions to disable
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f
sc config mpssvc start=disabled
sc config AppXSvc start=disabled
sc config BFE start=disabled
sc config TokenBroker start=disabled
sc config LicenseManager start=disabled
sc config ClipSVC start=disabled

taskkill /F /IM StartMenuExperienceHost*  >nul 2>nul
ren C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old
taskkill /F /IM SearchApp*  >nul 2>nul
ren C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy Microsoft.Windows.Search_cw5n1h2txyewy.old
ren C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old
ren C:\Windows\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old

taskkill /F /IM RuntimeBroker*  >nul 2>nul
ren C:\Windows\System32\RuntimeBroker.exe RuntimeBroker.exe.old
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 0 /F
taskkill /f /im explorer.exe
start explorer.exe
IF %ERRORLEVEL% EQU 0 echo %date% - %time% UWP Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
pause
:uwpE
sc config TabletInputService start=demand

:: Disable the option for Windows Store in the "Open With" dialog
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f
:: Block Access to Windows Store
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
sc config InstallService start=demand
:: Insufficent permissions to disable
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "3" /f
sc config mpssvc start=auto
sc config wlidsvc start=demand
sc config AppXSvc start=demand
sc config BFE start=auto
sc config TokenBroker start=demand
sc config LicenseManager start=demand
sc config ClipSVC start=demand

taskkill /F /IM StartMenuExperienceHost*  >nul 2>nul
ren C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old
taskkill /F /IM SearchApp*  >nul 2>nul
ren C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy.old Microsoft.Windows.Search_cw5n1h2txyewy
ren C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old Microsoft.XboxGameCallableUI_cw5n1h2txyewy
ren C:\Windows\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe
taskkill /F /IM RuntimeBroker*  >nul 2>nul
ren C:\Windows\System32\RuntimeBroker.exe.old RuntimeBroker.exe
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 0 /F
taskkill /f /im explorer.exe
start explorer.exe
IF %ERRORLEVEL% EQU 0 echo %date% - %time% UWP Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:mitE
powershell -NoProfile set-ProcessMitigation -System -Enable DEP
powershell -NoProfile set-ProcessMitigation -System -Enable EmulateAtlThunks
powershell -NoProfile set-ProcessMitigation -System -Enable RequireInfo
powershell -NoProfile set-ProcessMitigation -System -Enable BottomUp
powershell -NoProfile set-ProcessMitigation -System -Enable HighEntropy
powershell -NoProfile set-ProcessMitigation -System -Enable StrictHandle
powershell -NoProfile set-ProcessMitigation -System -Enable CFG
powershell -NoProfile set-ProcessMitigation -System -Enable StrictCFG
powershell -NoProfile set-ProcessMitigation -System -Enable SuppressExports
powershell -NoProfile set-ProcessMitigation -System -Enable SEHOP
powershell -NoProfile set-ProcessMitigation -System -Enable AuditSEHOP
powershell -NoProfile set-ProcessMitigation -System -Enable SEHOPTelemetry
powershell -NoProfile set-ProcessMitigation -System -Enable ForceRelocateImages
goto finish
:startlayout
reg delete "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f
reg delete "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% StartLayout Policy Removed...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:sleepD
:: Disable Away Mode policy
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
:: Disable Idle States
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
:: Disable Hybrid Sleep
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Sleep States Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
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
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Sleep States Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finishNRB
:harden
:: TODO:
:: - Make it extremely clear that this is not aimed to maintain performance
:: - Harden Process Mitigations (lower compatibilty for legacy apps)
:: - Open scripts in notepad to preview instead of executing when clicking
:: - ElamDrivers?
:: - block unsigned processes running from USBS
:: - Kerebos Hardening
:: - UAC Enable
:: - Firewall rules
:: - Disable TsX to mitigate ZombieLoad
:: - Static ARP Entry
:xboxU
choice /c yn /m "This is currently IRREVERSIBLE, continue? [Y/N]" /n
echo Removing via powershell...
nsudo -U:C -ShowWindowMode:Hide -Wait powershell -NoProfile -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage" >nul 2>nul
echo Removing manually...
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.Xbox.TCUI_1.23.28002.0_x64__8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxApp_48.49.31001.0_neutral_~_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxGameOverlay_1.46.11001.0_neutral_split.scale-100_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxGameOverlay_1.46.11001.0_x64__8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_split.scale-100_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_~_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxGamingOverlay_2.34.28001.0_x64__8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxIdentityProvider_12.50.6001.0_x64__8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_split.scale-100_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe" >nul 2>nul
del /F /S /Q "C:\Program Files\WindowsApps\Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_x64__8wekyb3d8bbwe" >nul 2>nul

echo Removing via Regex...
del /F /S /Q "C:\Program Files\WindowsApps\*Xbox*" >nul 2>nul

echo Disabling Services...
sc config XblAuthManager start=disabled
sc config XblGameSave start=disabled
sc config XboxGipSvc start=disabled
sc config XboxNetApiSvc start=disabled
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BcastDVRUserService" /v "Start" /t REG_DWORD /d "4" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Xbox Related Apps and Services Removed...>> C:\Windows\AtlasModules\logs\userScript.log
goto finishNRB
:vcreR
echo Uninstalling Visual C++ Runtimes...
C:\Windows\AtlasModules\vcredist.exe /aiR
echo Finished uninstalling!
echo.
echo Opening Visual C++ Runtimes installer, simply click next.
C:\Windows\AtlasModules\vcredist.exe
echo Installation Finished or Cancelled.
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Visual C++ Runtimes Reinstalled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finishNRB
:uacD
echo Disabling UAC breaks fullscreen on certain UWP applications, one of them being Minecraft Windows 10 Edition. It is also less secure to disable UAC.
set /P c="Do you want to continue? [Y/N]: "
if /I "%c%" EQU "Y" goto uacDconfirm
if /I "%c%" EQU "N" exit
exit
:uacDconfirm
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\luafv" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Appinfo" /v "Start" /t REG_DWORD /d "4" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% UAC Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish
:uacE
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\luafv" /v "Start" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Appinfo" /v "Start" /t REG_DWORD /d "3" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% UAC Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:dwmKILL

:: Two choices:
:: 1. kill DWM
:: 2. Create a script that automatically launches a user-specified process, then kill DWM
set /P c=Would you like to create a script that launches your game and kills DWM? [Y/N]
if /I "%c%" EQU "Y" goto dwmScript
if /I "%c%" EQU "N" goto killDWM

:dwmScript
echo Please input the full path of your game, e.g. "C:\Program Files (x86)\My Game\MyGame.exe"
echo. 
set /p game="What is the full path of your game?"

echo "C:\Windows\AtlasModules\nsudo -U:T -P:E -UseCurrentConsole -Wait C:\Windows\AtlasModules\atlas-config.bat /dwmCon %game%" > %HOMEPATH%\Desktop\KillDWM.bat
:dwmCon
:: if %game% is not found, then just kill DWM
if /i "%~2"==""	goto killDWM
goto customDWM
:: Adapted from EverythingTech's script
:killDWM
taskkill /im explorer.exe /f
taskkill /im shellexperiencehost.exe /f
taskkill /im searchui.exe /f
taskkill /im searchapp.exe /f
taskkill /im runtimebroker.exe /f
taskkill /im textinputhost.exe /f
taskkill /im dllhost.exe /f
taskkill /im wmiprvse.exe /f
start cmd.exe /K echo "Launch your game here!"
cd C:\
cls && echo Launch your game now! You have 1 minute until DWM is killed automatically.
timeout /t 30
pssuspend winlogon.exe
taskkill /im dwm.exe /f
echo DWM Killed! Press any key on this window to resume DWM.
pause >nul 2>nul
pssuspend -r winlogon.exe
start explorer.exe
echo DWM Restored! You may have to restart some applications for them to work properly.
pause
exit
:customDWM
taskkill /im explorer.exe /f
taskkill /im shellexperiencehost.exe /f
taskkill /im searchui.exe /f
taskkill /im searchapp.exe /f
taskkill /im runtimebroker.exe /f
taskkill /im textinputhost.exe /f
taskkill /im dllhost.exe /f
taskkill /im wmiprvse.exe /f
start cmd.exe
cd C:\
cls && echo Launching game..
"%game%"
timeout /t 5
pssuspend winlogon.exe
taskkill /im dwm.exe /f
echo DWM Killed! Press any key on this window to resume DWM.
pause >nul 2>nul
pssuspend -r winlogon.exe
start explorer.exe
echo DWM Restored! You may have to restart some applications for them to work properly.
pause
exit
:firewallD
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "4" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Firewall Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish
:firewallE
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "2" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Firewall Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:aniE
reg delete "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg delete "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9e3e078012000000" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Animations Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:aniD
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f
C:\Windows\AtlasModules\nsudo -U:C -P:E -Wait reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Animations Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:workstationD
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rdbss" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\KSecPkg" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb20" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\srv2" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanmanWorkstation" /v "Start" /t REG_DWORD /d "4" /f
dism /Online /Disable-Feature /FeatureName:SmbDirect /norestart
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Workstation Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:workstationE
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rdbss" /v "Start" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\KSecPkg" /v "Start" /t REG_DWORD /d "0" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb20" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mrxsmb" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\srv2" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanmanWorkstation" /v "Start" /t REG_DWORD /d "2" /f
dism /Online /Enable-Feature /FeatureName:SmbDirect /norestart
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Workstation Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:printE
set /P c=You may be vulnerable to Print Nightmare Exploits while printing is enabled. Would you like to add Group Policies to protect against them? [Y/N]
if /I "%c%" EQU "Y" goto nightmareGPO
if /I "%c%" EQU "N" goto printECont
goto nightmareGPO
:nightmareGPO
echo The spooler will not accept client connections nor allow users to share printers.
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "Restricted" /t REG_DWORD /d "1" /f
:: Prevent Print Drivers over HTTP
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d "1" /f
:: Disable Printing over HTTP
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d "1" /f
:printECont
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Spooler" /v "Start" /t REG_DWORD /d "2" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Printing Enabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:printD
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Spooler" /v "Start" /t REG_DWORD /d "4" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Printing Disabled...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:dataQueueM
echo Mouse Data Queue Sizes
echo This may affect stability and input latency. And if low enough may cause mouse skipping/mouse stutters.
echo.
echo Windows Default: 100
echo Atlas Default: 50
echo Valid Value Range: 1-100
set /P c="Enter the size you want to set Mouse Data Queue Size to: "
:: Filter to numbers only
echo %c%|findstr /r "[^0-9]" > nul
if errorlevel 1 goto dataQueueMSet
cls
echo Only values from 1-100 are allowed!
goto dataQueueM
:: Checks for invalid values
:dataQueueMSet
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d "%c%" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Mouse Data Queue Size set to %c%...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:dataQueueK
echo Keyboard Data Queue Sizes
echo This may affect stability and input latency. And if low enough may cause general keyboard issues like ghosting.
echo.
echo Windows Default: 100
echo Atlas Default: 50
echo Valid Value Range: 1-100
set /P c="Enter the size you want to set Keyboard Data Queue Size to: "
:: Filter to numbers only
echo %c%|findstr /r "[^0-9]" > nul
if errorlevel 1 goto dataQueueKSet
cls
echo Only values from 1-100 are allowed!
goto dataQueueK
:: Checks for invalid values
:dataQueueKSet
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d "%c%" /f
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Keyboard Data Queue Size set to %c%...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:netWinDefault
netsh int ip reset 
netsh winsock reset 
:: TODO: Remove NIC device then rescan to reset Device settings to default
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Network Setting Reset to Windows Default...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:netAtlasDefault
:: Disable Nagle's Algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%i in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
  reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
  reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
  reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: Configure NIC Setting
:: Get nic driver settings path by querying for dword
:: If you see a way to optimize this segment, feel free to open a pull request.
for /f %%a in ('reg query HKLM /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    :: Check if the value exists, to prevent errors and uneeded settings
    for /f %%i in ('reg query "%%a" /v "GigaLite" ^| findstr "HKEY"') do (
        :: add the value
        :: if the value does not exist, it will silently error.
        reg add "%%i" /v "GigaLite" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "*EEE" ^| findstr "HKEY"') do (
        reg add "%%i" /v "*EEE" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "*FlowControl" ^| findstr "HKEY"') do (
        reg add "%%i" /v "*FlowControl" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "PowerSavingMode" ^| findstr "HKEY"') do (
        reg add "%%i" /v "PowerSavingMode" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableSavePowerNow" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnablePowerManagement" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePowerManagement" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableGreenEthernet" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableDynamicPowerGating" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableDynamicPowerGating" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnableConnectedPowerGating" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableConnectedPowerGating" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "AutoPowerSaveModeEnabled" ^| findstr "HKEY"') do (
        reg add "%%i" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "AutoDisableGigabit" ^| findstr "HKEY"') do (
        reg add "%%i" /v "AutoDisableGigabit" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "AdvancedEEE" ^| findstr "HKEY"') do (
        reg add "%%i" /v "AdvancedEEE" /t REG_DWORD /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "ULPMode" ^| findstr "HKEY"') do (
        reg add "%%i" /v "ULPMode" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "ReduceSpeedOnPowerDown" ^| findstr "HKEY"') do (
        reg add "%%i" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f
    )
    for /f %%i in ('reg query "%%a" /v "EnablePME" ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePME" /t REG_SZ /d "0" /f
    )
) >nul 2>nul
netsh int tcp set heuristics disabled
netsh int tcp set supplemental Internet congestionprovider=ctcp
netsh int tcp set global timestamps=disabled
netsh int tcp set global rsc=disabled
for /f "tokens=1" %%i in ('netsh int ip show interfaces ^| findstr [0-9]') do (
	netsh int ip set interface %%i routerdiscovery=disabled store=persistent
)
IF %ERRORLEVEL% EQU 0 echo %date% - %time% Network Setting Reset to Atlas Default...>> C:\Windows\AtlasModules\logs\userScript.log
goto finish
:debugProfile
systeminfo > C:\Windows\AtlasModules\logs\systemInfo.log
goto finish
:vpnD
devmanview /disable "WAN Miniport (IKEv2)"
devmanview /disable "WAN Miniport (IP)"
devmanview /disable "WAN Miniport (IPv6)"
devmanview /disable "WAN Miniport (L2TP)"
devmanview /disable "WAN Miniport (Network Monitor)"
devmanview /disable "WAN Miniport (PPPOE)"
devmanview /disable "WAN Miniport (PPTP)"
devmanview /disable "WAN Miniport (SSTP)"
devmanview /disable "NDIS Virtual Network Adapter Enumerator"
devmanview /disable "Microsoft RRAS Root Enumerator"
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\IKEEXT" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\RasMan" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SstpSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NdisVirtualBus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Eaphost" /v "Start" /t REG_DWORD /d "4" /f
goto finish
:vpnE
devmanview /enable "WAN Miniport (IKEv2)"
devmanview /enable "WAN Miniport (IP)"
devmanview /enable "WAN Miniport (IPv6)"
devmanview /enable "WAN Miniport (L2TP)"
devmanview /enable "WAN Miniport (Network Monitor)"
devmanview /enable "WAN Miniport (PPPOE)"
devmanview /enable "WAN Miniport (PPTP)"
devmanview /enable "WAN Miniport (SSTP)"
devmanview /enable "NDIS Virtual Network Adapter Enumerator"
devmanview /enable "Microsoft RRAS Root Enumerator"
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\IKEEXT" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\RasMan" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SstpSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NdisVirtualBus" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Eaphost" /v "Start" /t REG_DWORD /d "3" /f
goto finish

:wmpD
dism /Online /Disable-Feature /FeatureName:WindowsMediaPlayer /norestart
goto finish
:ieD
dism /Online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /norestart
goto finish

:scoop
echo Installing scoop...
set /P c="Review Install script before executing? [Y/N]: "
if /I "%c%" EQU "Y" curl "https://raw.githubusercontent.com/lukesampson/scoop/master/bin/install.ps1" -o C:\Windows\AtlasModules\install.ps1 && notepad C:\Windows\AtlasModules\install.ps1
if /I "%c%" EQU "N" curl "https://raw.githubusercontent.com/lukesampson/scoop/master/bin/install.ps1" -o C:\Windows\AtlasModules\install.ps1
powershell -NoProfile Set-ExecutionPolicy RemoteSigned -scope CurrentUser
powershell -NoProfile C:\Windows\AtlasModules\install.ps1
echo Refreshing environment for Scoop...
call C:\Windows\AtlasModules\refreshenv.bat
echo Installing git...
:: Scoop isn't very nice with batch scripts, and will break the whole script if a warning or error shows..
cmd /c scoop install git -g
call C:\Windows\AtlasModules\refreshenv.bat
echo Adding extras bucket...
cmd /c scoop bucket add extras
goto finish

:browser
multiplechoice "Ungoogled-Chromium;Firefox;Brave;GoogleChrome;" "Pick a Browser" "Browser" > C:\Windows\AtlasModules\tmp.txt
for /f %%i in (C:\Windows\AtlasModules\tmp.txt) do (
	set filter="%%i"
	pause
	set filtered=!filter:;= !
)
::if "%filtered%" == "" echo You need to install a browser! You will need it later on. && pause && goto browser
:: must launch in separate process, scoop seems to exit the whole script if not
cmd /c scoop install %filtered% -g
goto finish

:altSoftware
:: Findstr for 7zip-zstd, add versions bucket if errlvl 0
set filter=""
multiplechoice "discord;bleachbit;notepadplusplus;msiafterburner;rtss;steam;thunderbird;foobar2000;irfanview;git;mpv;vlc;vscode;putty;ditto;" "Install Common Software" "Common Software" > C:\Windows\AtlasModules\tmp.txt
for /f %%i in (C:\Windows\AtlasModules\tmp.txt) do (
	set filter="%%i"
	set filtered=!filter:;= !
)
cmd /c scoop install "%filtered%" -g

:: Static IP
:staticIP
call :netcheck
set /P dns1="Set DNS Server (e.g. 1.1.1.1): "
for /f "tokens=4" %%i in ('netsh int show interface ^| find "Connected"') do set devicename=%%i
::for /f "tokens=2 delims=[]" %%i in ('ping -4 -n 1 %ComputerName%^| findstr [') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name=^"%devicename%" ^| findstr "IP Address:"') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name=^"%devicename%" ^| findstr "Default Gateway:"') do set DHCPGateway=%%i
for /f "tokens=2 delims=()" %%i in ('netsh int ip show config name^="Ethernet" ^| findstr "Subnet Prefix:"') do for /F "tokens=2" %%a in ("%%i") do set DHCPSubnetMask=%%a
netsh int ipv4 set address name="%devicename%" static %LocalIP% %DHCPSubnetMask% %DHCPGateway%
powershell -NoProfile -Command "Set-DnsClientServerAddress -InterfaceAlias "%devicename%" -ServerAddresses %dns1%"
echo %date% - %time% Static IP set! The following was set: >> C:\Windows\AtlasModules\logs\install.log
echo Private IP: %LocalIP% >> C:\Windows\AtlasModules\logs\install.log
echo Gateway: %DHCPGateway% >> C:\Windows\AtlasModules\logs\install.log
echo Subnet Mask: %DHCPSubnetMask% >> C:\Windows\AtlasModules\logs\install.log
echo If this information appears to be incorrect, please report it on Discord (preferred) or Github.
goto finish
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Dhcp" /v "Start" /t REG_DWORD /d "4" /f
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NlaSvc" /v "Start" /t REG_DWORD /d "4" /f
::reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\netprofm" /v "Start" /t REG_DWORD /d "4" /f

:displayScalingD
for /f %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /s /f Scaling ^| find /i "Configuration\"') do (
	reg add "%%i" /v "Scaling" /t REG_DWORD /d "1" /f
)
goto finish

:DSCPauto
for %%i in (csgo VALORANT-Win64-Shipping javaw FortniteClient-Win64-Shipping ModernWarfare r5apex) do (
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Application Name" /t REG_SZ /d "%%i.exe" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Version" /t REG_SZ /d "1.0" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Protocol" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Local Port" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Local IP" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Local IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Remote Port" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Remote IP" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Remote IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "DSCP Value" /t REG_SZ /d "46" /f
    reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Throttle Rate" /t REG_SZ /d "-1" /f
) >nul 2>nul
goto finish

:nvPstate
: add check for nvidia card
:: Credits to Timecard
:: https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0
for /F "tokens=*" %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /s /e /f "DriverDesc" ^| findstr "HK"') do (
	reg add "%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f
)
goto finish

:GPUAffinity
echo Python required for Affinity Script. Installing...
curl -L --output C:\Windows\AtlasModules\pysetup.exe "https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe"
C:\Windows\AtlasModules\pysetup.exe /quiet InstallAllUsers=1 CompileAll=1 Include_doc=0 Include_launcher=1 InstallLauncherAllUsers=1 PrependPath=1 Shortcuts=1
del /f /q "C:\Windows\AtlasModules\pysetup.exe"
call C:\Windows\AtlasModules\refreshenv.bat
echo Installing OCAT...
::scoop install ocat
curl -L --output C:\Windows\AtlasModules\ocatsetup.exe "https://github.com/GPUOpen-Tools/ocat/releases/download/v1.6.1/OCAT_v1.6.1.exe"
C:\Windows\AtlasModules\ocatsetup.exe /silent /install
if not exist "C:\Windows\AtlasModules\OCAT" if exist "C:\Program Files (x86)\OCAT" move "C:\Program Files (x86)\OCAT" "C:\Windows\AtlasModules"
:liblava
echo Installing LibLava...
curl -L --output liblava.zip "https://github.com/liblava/liblava/releases/download/0.5.5/liblava-demo_2020_win.zip"
:: Only extract required files
7z -aoa -r e "C:\Windows\AtlasModules\liblava.zip" -o"C:\Windows\AtlasModules\liblava" >nul 2>nul
del /f /q "C:\Windows\AtlasModules\liblava.zip"

:: This segment of the script is LARGELY based on AMIT's "AutoGPUAffinity" script, which can be found here: https://github.com/amitxvv/AutoGpuAffinity
:: Extra Ideas:
:: - Prompt for Benchmark Time
:: - Improve run time estimation, account for HT
:: Get amount of cores or threads
for /F "skip=1" %%i in ('wmic cpu get NumberOfCores^| findstr "."') do set /a cores=%%i
:: Check for HT
if %cores% EQU %NUMBER_OF_PROCESSORS% (set HT=0) ELSE (set HT=1)
:: Estimated time, 80 seconds per core (60 seconds of bench, ~20 seconds of loading/processing)
set /a est=%cores% * 80
for /f "tokens=1" %%i in ('python calc.py divint %est% 60') do (
    set est=%%i
)
echo Beginning Affinity Script...
echo Estimated Run Time: %est% minutes
echo WARNING: You are required to have installed your Display Drivers
echo. 
echo WARNING: Your Monitor will flash multiple times, this is normal.
echo.
echo IF YOU HAVEN'T ALREADY; INSTALL YOUR GRAPHICS DRIVERS! This script is useless without them.
pause
:checkMSAdapter
for /F "skip=1" %%i in ('wmic path win32_VideoController get name') do (
    if "%%i" equ "Microsoft Basic Display Adapter" echo Graphics Driver not installed! This is REQUIRED for this script to work. & pause & goto checkMSAdapter
)
call :netcheck
:: initialize gpu testing...
set testingCore=%NUMBER_OF_PROCESSORS%
set /a cpus=%NUMBER_OF_PROCESSORS% - 1
set entries=0
set total=0
set test=0
set max_num=1
set capDir=%userprofile%\Documents\OCAT\Captures
set log=C:\Windows\AtlasModules\logs\gpuAffinity.log
set config="%userprofile%\Documents\OCAT\Config\settings.ini"
mkdir "%userprofile%\Documents\OCAT\Config"
if exist lava.log del /f /q lava.log
if exist "%log%" del /f /q "%log%"

echo Creating OCAT config...
:: Testing Purposes Only, fresh install will not have this.
::if exist "%userprofile%\Documents\OCAT\Config\settings.ini" del /f /q "%userprofile%\Documents\OCAT\Config\settings.ini" >nul 2>nul

:: Write Config file to OCAT dir
echo "[Recording]" >> %config% 
echo "toggleCaptureHotkey=121" >> %config% 
echo "toggleOverlayHotkey=120" >> %config% 
echo "toggleFramegraphOverlayHotkey=118" >> %config% 
echo "toggleColoredBarOverlayHotkey=119" >> %config%
echo "toggleLagIndicatorOverlayHotkey=117" >> %config% 
echo "lagIndicatorHotkey=145" >> %config%
echo "overlayPosition=1" >> %config% 
echo "captureTime=60" >> %config% 
echo "captureDelay=0" >> %config% 
echo "captureAllProcesses=0" >> %config% 
echo "audioCue=0" >> %config% 
echo "altKeyComb=0" >> %config% 
echo "disableOverlayDuringCapture=1" >> %config% 
echo "injectOnStart=1" >> %config%  
echo "captureOutputFolder=%capDir%" >> %config% 

:coreTestLoop
if %test% equ 2 set test=0 
if %test% equ 0 if %HT% equ 1 set /a testingCore=%testingCore% - 2
if %test% equ 0 if %HT% equ 0 set /a testingCore=%testingCore% - 1
if %test% lss 2 (set /a test=%test% + 1)
:: Skip core 0..
if %testingCore% equ 0 goto coreTestFinish
:: set to 2 to the power of %testingCore%
set /a "dec=1<<%testingCore%"
:: Convert dec to binary big endian
set "bin="
for /L %%A in (1,1,32) do (
    set /a "bit=dec&1, dec>>=1"
    set bin=!bit!!bin!
)
:: Convert to hex for Process affinity and Little endian
call :bin2hex hex !bin:~-%NUMBER_OF_PROCESSORS%!
:: Get Little Endian version for Affinity
call :ChangeByteOrder %hex%
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f >nul 2>nul
	reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "%BytesLE%" /f >nul 2>nul
)
:: Remove Previous Captures
del /f /q %capDir%\*.csv
:: Restart Display Adapter to apply affinity changes
if %test% equ 1 start "" "C:\Windows\AtlasModules\restart64.exe" /q
timeout 5
start "" "OCAT\OCAT.exe"
cmd /c start "" /affinity %hex% "C:\Windows\AtlasModules\liblava\lava-triangle.exe"
timeout 5 >nul 2>nul
rundll32.exe user32.dll,SetCursorPos
wscript "C:\Windows\AtlasModules\keypress.vbs"
call :testInfo
timeout 32 >nul 2>nul
wscript "C:\Windows\AtlasModules\keypress.vbs"
:: Slight delay for csv to be written
timeout 3 >nul 2>nul
taskkill /F /IM OCAT.exe >nul 2>nul
taskkill /F /IM GlobalHook64.exe >nul 2>nul
taskkill /F /IM lava-triangle.exe >nul 2>nul
:: Get length of benchmark
for %%i in (%capDir%\OCAT-lava-*.csv) do (
	for /f "tokens=1" %%a in ('py calc.py parse %%i') do (
        set lows=%%a
    )
)
if "%test%" equ "1" set T1cpu%testingCore%=%lows%
if "%test%" equ "2" set T2cpu%testingCore%=%lows%
if defined T1cpu%testingCore% if defined T2cpu%testingCore% (
	for /f "tokens=1" %%a in ('py calc.py add !T1cpu%testingCore%! !T2cpu%testingCore%!') do (
		for /f "tokens=1" %%b in ('py calc.py div %%a 2') do (
			for /f "tokens=1" %%c in ('py calc.py rnd %%b') do (set cpu%testingCore%=%%c)
		)
	)
)
if defined T1cpu%testingCore% if defined T2cpu%testingCore% (
	echo CPU %testingCore%: >> "%log%" 
	echo Test 1 - !T1cpu%testingCore%! >> "%log%" 
	echo Test 2 - !T2cpu%testingCore%! >> "%log%" 
	echo Average - !cpu%testingCore%! >> "%log%" 
    echo. >> "%log%" 
)
goto coreTestLoop
:coreTestFinish
cls
if %HT% equ 0 for /L %%n in (%cpus%,-1,0) do (
    echo CPU %%n : !cpu%%n!
)
:: Make sure to only print cores with values
if %HT% equ 1 for /L %%n in (%NUMBER_OF_PROCESSORS%,-2,0) do (
    echo CPU %%n : !cpu%%n! | findstr /v "0 %NUMBER_OF_PROCESSORS%"
)
echo.
echo Benchmark Finished! Analyzing...
for /L %%n in (%cpus%,-1,0) do (
	for %%a in (!cpu%%n!) do (
		if %%a gtr !max_num! set "max_num=%%a" & set "highestfps-cpu=%%n"
	)
)
echo it appears that CPU !highestfps-cpu! overall had the highest 0.01 lows - !max_num! fps
set /P c="Set GPU Affinity to !highestfps-cpu!? [Y/N]: "
if /I "%c%" EQU "Y" goto setGPUAffinity
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	reg delete "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /f
	reg delete "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /f
) >nul 2>nul
:setGPUAffinity
set /a "dec=1<<%highestfps-cpu%"

:: Convert dec to binary big endian
set "bin="
for /L %%A in (1,1,32) do (
    set /a "bit=dec&1, dec>>=1"
    set bin=!bit!!bin!
)
:: Convert to hex for Process affinity and Little endian
call :bin2hex hex !bin:~-%NUMBER_OF_PROCESSORS%!
:: Get Little Endian version for Affinity
call :ChangeByteOrder %hex%
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f >nul 2>nul
	reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "%BytesLE%" /f >nul 2>nul
)
echo GPU affinity set!
goto finish

exit
:: Begin Batch Functions
:bin2hex <var_to_set> <bin_value>
set "hextable=0000-0;0001-1;0010-2;0011-3;0100-4;0101-5;0110-6;0111-7;1000-8;1001-9;1010-A;1011-B;1100-C;1101-D;1110-E;1111-F"
:bin2hexloop
if "%~2"=="" (
    endlocal & set "%~1=%~3"
    goto :EOF
)
set "bin=000%~2"
set "oldbin=%~2"
set "bin=%bin:~-4%"
set "hex=!hextable:*%bin:~-4%-=!"
set hex=%hex:;=&rem.%
endlocal & call :bin2hexloop "%~1" "%oldbin:~0,-4%" %hex%%~3
goto :EOF

:ChangeByteOrder  <data:hex>
set "LittleEndian="
set "BigEndian=%~1"
:ChangeByteOrderLoop
if "%BigEndian:~-2%"=="%BigEndian:~-1%" (
    set "LittleEndian=%LittleEndian%0%BigEndian:~-1%"
) else set "LittleEndian=%LittleEndian%%BigEndian:~-2%"
set "BigEndian=%BigEndian:~0,-2%"
if not defined BigEndian exit /B
goto :ChangeByteOrderLoop

:testInfo
cls
echo "Current Affinity: %testingCore%"
echo "Test: %test%/2"
goto :EOF

:setSvc <service_name> <start_1-4>
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f

:invalidInput <label>
if "%c%"=="" echo Empty Input! Please enter Y or N. & goto %~1
if "%c%" NEQ "Y" if "%c%" NEQ "N" echo Invalid Input! Please enter Y or N. & goto %~1
goto :EOF

:netcheck
ping -n 1 -4 1.1.1.1 ^|Find "Failulre"|(
    echo Network is not connected! Please connect to a network before continuing.
	pause
	goto netcheck
)
goto :EOF

:permFAIL
	echo Permission grants failed. Please try again by launching the script through the respected scripts, which will give it the correct permissions.
	pause&exit
:finish
	echo Finished, please reboot for changes to apply.
	pause&exit
:finishNRB
	echo Finished, changes have been applied.
	pause&exit