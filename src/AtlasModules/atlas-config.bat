:: name: Atlas configuration script
:: description: this is the master script used to configure the Atlas operating system
:: depending on your build, change theses vars to 1803, 20H2 or 21H2 and update the version

:: CREDITS:
:: - AMIT
:: - Artanis
:: - CYNAR
:: - Canonez
:: - CatGamerOP
:: - EverythingTech
:: - Melody
:: - Revision
:: - imribiy
:: - nohopestage
:: - Timecard
:: - Phlegm
:: - Xyueta
:: - JayXTQ

@echo off
set branch="22H2"
set ver="v0.1"
title AtlasOS Configuration Script %branch% %ver%

:: set other variables (do not touch)
set "currentuser=%WinDir%\AtlasModules\NSudo.exe -U:C -P:E -Wait"
set "setSvc=call :setSvc"
set "firewallBlockExe=call :firewallBlockExe"

:: check for administrator privileges
if "%~2"=="/skipAdminCheck" goto permSUCCESS
fltmc > nul 2>&1 || (
    goto permFAIL
)

:: check for trusted installer priviliges
whoami /user | find /i "S-1-5-18" > nul 2>&1
if not %ERRORLEVEL%==0 (
    set system=false
)

:permSUCCESS
SETLOCAL EnableDelayedExpansion

:: Startup
if /i "%~1"=="/start"		   goto startup

:: will loop update check if debugging
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

:: Hyper-V
if /i "%~1"=="/dhyper"         goto hyperD
if /i "%~1"=="/ehyper"         goto hyperE

:: Microsoft Store
if /i "%~1"=="/ds"         goto storeD
if /i "%~1"=="/es"         goto storeE

:: Background Apps
if /i "%~1"=="/backd"         goto backD
if /i "%~1"=="/backe"         goto backE

:: Bluetooth
if /i "%~1"=="/btd"         goto btD
if /i "%~1"=="/bte"         goto btE

:: HDD Prefetching
if /i "%~1"=="/hddd"         goto hddD
if /i "%~1"=="/hdde"         goto hddE

:: DEP (nx)
if /i "%~1"=="/depE"         goto depE
if /i "%~1"=="/depD"         goto depD

:: Start Menu
if /i "%~1"=="/ssD"         goto SearchStart
if /i "%~1"=="/ssE"         goto enableStart
if /i "%~1"=="/openshell"         goto openshellInstall

:: Remove UWP
if /i "%~1"=="/uwp"			goto uwp
if /i "%~1"=="/uwpE"			goto uwpE
if /i "%~1"=="/mite"			goto mitE

:: Remove Start Menu layout (allow tiles in Start Menu)
if /i "%~1"=="/stico"          goto startlayout

:: Sleep States
if /i "%~1"=="/sleepD"         goto sleepD
if /i "%~1"=="/sleepE"         goto sleepE

:: CPU Idle
if /i "%~1"=="/idled"          goto idleD
if /i "%~1"=="/idlee"          goto idleE

:: Process Explorer
if /i "%~1"=="/procexpd"          goto procexpD
if /i "%~1"=="/procexpe"          goto procexpE

:: Xbox
if /i "%~1"=="/xboxU"         goto xboxU

:: Reinstall VC++ Redistributables
if /i "%~1"=="/vcreR"         goto vcreR

:: User Account Control
if /i "%~1"=="/uacD"		goto uacD
if /i "%~1"=="/uacE"		goto uacE
if /i "%~1"=="/uacSettings" goto uacSettings

:: Workstation Service (SMB)
if /i "%~1"=="/workD"		goto workstationD
if /i "%~1"=="/workE"		goto workstationE

:: Windows Firewall
if /i "%~1"=="/firewallD"		goto firewallD
if /i "%~1"=="/firewallE"		goto firewallE

:: Printing
if /i "%~1"=="/printD"		goto printD
if /i "%~1"=="/printE"		goto printE

:: Network
if /i "%~1"=="/netWinDefault"		goto netWinDefault
if /i "%~1"=="/netAtlasDefault"		goto netAtlasDefault

:: Clipboard History Service (also required for Snip and Sketch to copy correctly)
if /i "%~1"=="/cbdhsvcD"    goto cbdhsvcD
if /i "%~1"=="/cbdhsvcE"    goto cbdhsvcE

:: VPN
if /i "%~1"=="/vpnD"    goto vpnD
if /i "%~1"=="/vpnE"    goto vpnE

:: Scoop and Chocolatey
if /i "%~1"=="/scoop" goto scoop
if /i "%~1"=="/choco" goto choco
if /i "%~1"=="/altsoftwarescoop" goto altSoftwarescoop
if /i "%~1"=="/altsoftwarechoco" goto altSoftwarechoco
if /i "%~1"=="/removescoopcache" goto scoopCache

:: NVIDIA P-State 0
if /i "%~1"=="/nvpstateD" goto NVPstate
if /i "%~1"=="/nvpstateE" goto revertNVPState

:: HDCP
if /i "%~1"=="/hdcpD" goto hdcpD
if /i "%~1"=="/hdcpE" goto hdcpE

:: DSCP
if /i "%~1"=="/dscpauto" goto DSCPauto

:: Display Scaling
if /i "%~1"=="/displayscalingd" goto displayScalingD

:: Static IP
if /i "%~1"=="/staticip" goto staticIP

:: Windows Media Player
if /i "%~1"=="/wmpd" goto wmpD

:: Internet Explorer
if /i "%~1"=="/ied" goto ieD

:: Task Scheduler
if /i "%~1"=="/scheduled"  goto scheduleD
if /i "%~1"=="/schedulee"  goto scheduleE

:: Event Log
if /i "%~1"=="/eventlogd" goto eventlogD
if /i "%~1"=="/eventloge" goto eventlogE

:: NVIDIA Display Container LS - he3als
if /i "%~1"=="/nvcontainerD" goto nvcontainerD
if /i "%~1"=="/nvcontainerE" goto nvcontainerE
if /i "%~1"=="/nvcontainerCMD" goto nvcontainerCMD
if /i "%~1"=="/nvcontainerCME" goto nvcontainerCME

:: Network Sharing
if /i "%~1"=="/networksharingE" goto networksharingE

:: Diagnostics
if /i "%~1"=="/diagd" goto diagD
if /i "%~1"=="/diage" goto diagE

:: Safe Mode
if /i "%~1"=="/safee" goto safeE
if /i "%~1"=="/safec" goto safeC
if /i "%~1"=="/safen" goto safeN
if /i "%~1"=="/safe" goto safe

:: debugging purposes only
if /i "%~1"=="/test"         goto TestPrompt

:argumentFAIL
echo atlas-config had no arguements passed to it, either you are launching atlas-config directly or the "%~nx0" script is broken.
echo Please report this to the Atlas Discord server or Github.
pause & exit

:TestPrompt
set /p c="Test with echo on?"
if %c% equ Y echo on
set /p argPrompt="Which script would you like to test? E.g. (:testScript)"
goto %argPrompt%
echo You should not reach this message!
pause & exit

:startup
:: create log directory for troubleshooting
mkdir %WinDir%\AtlasModules\logs
cls & echo Please wait, this may take a moment.
setx path "%path%;%WinDir%\AtlasModules;" -m  > nul 2>nul
IF %ERRORLEVEL%==0 (echo %date% - %time% Atlas Modules path set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set Atlas Modules path! >> %WinDir%\AtlasModules\logs\install.log)

:: breaks setting keyboard language
:: rundll32.exe advapi32.dll,ProcessIdleTasks
break > C:\Users\Public\success.txt
echo false > C:\Users\Public\success.txt

:auto
SETLOCAL EnableDelayedExpansion
%WinDir%\AtlasModules\vcredist.exe /ai
if %ERRORLEVEL%==0 (echo %date% - %time% Visual C++ Runtimes installed...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to install Visual C++ Runtimes! >> %WinDir%\AtlasModules\logs\install.log)

:: change ntp server from windows server to pool.ntp.org
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
sc queryex "w32time" | find "STATE" | find /v "RUNNING" || (
    net stop w32time
    net start w32time
) > nul 2>nul

:: resync time to pool.ntp.org
w32tm /config /update
w32tm /resync
sc stop W32Time
%setSvc% W32Time 4
if %ERRORLEVEL%==0 (echo %date% - %time% NTP server set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set NTP server! >> %WinDir%\AtlasModules\logs\install.log)

cls & echo Please wait. This may take a moment.

:: optimize ntfs parameters
:: disable last access information on directories, performance/privacy
fsutil behavior set disablelastaccess 1

:: disable the creation of 8.3 character-length file names on FAT- and NTFS-formatted volumes
:: https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security
fsutil behavior set disable8dot3 1

:: enable delete notifications (aka trim or unmap)
:: should be enabled by default but it is here to be sure
fsutil behavior set disabledeletenotify 0

:: disable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "0" /f

if %ERRORLEVEL%==0 (echo %date% - %time% File system optimized...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to optimize file system! >> %WinDir%\AtlasModules\logs\install.log)

:: attempt to fix language packs issue
:: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/language-packs-known-issue
:: schtasks /Change /Disable /TN "\Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" > nul 2>nul
:: reg add "HKLM\SOFTWARE\Policies\Microsoft\Control Panel\International" /v "BlockCleanupOfUnusedPreinstalledLangPacks" /t REG_DWORD /d "1" /f

:: disable unneeded scheduled tasks

:: breaks setting lock screen
:: schtasks /Change /Disable /TN "\Microsoft\Windows\Shell\CreateObjectTask"

for %%a in (
    "\Microsoft\Windows\ApplicationData\appuriverifierdaily"
    "\Microsoft\Windows\ApplicationData\appuriverifierinstall"
    "\Microsoft\Windows\ApplicationData\DsSvcCleanup"
    "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
    "\Microsoft\Windows\Application Experience\StartupAppTask"
    "\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask"
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "\Microsoft\Windows\Defrag\ScheduledDefrag"
    "\Microsoft\Windows\Device Information\Device"
    "\Microsoft\Windows\Device Setup\Metadata Refresh"
    "\Microsoft\Windows\Diagnosis\Scheduled"
    "\Microsoft\Windows\DiskCleanup\SilentCleanup"
    "\Microsoft\Windows\DiskFootprint\Diagnostics"
    "\Microsoft\Windows\InstallService\ScanForUpdates"
    "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser"
    "\Microsoft\Windows\InstallService\SmartRetry"
    "\Microsoft\Windows\Management\Provisioning\Cellular"
    "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents"
    "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic"
    "\Microsoft\Windows\MUI\LPRemove"
    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
    "\Microsoft\Windows\Printing\EduPrintProv"
    "\Microsoft\Windows\PushToInstall\LoginCheck"
    "\Microsoft\Windows\Ras\MobilityManager"
    "\Microsoft\Windows\Registry\RegIdleBackup"
    "\Microsoft\Windows\RetailDemo\CleanupOfflineContent"
    "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"
    "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork"
    "\Microsoft\Windows\StateRepository\MaintenanceTasks"
    "\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime"
    "\Microsoft\Windows\Time Synchronization\SynchronizeTime"
    "\Microsoft\Windows\Time Zone\SynchronizeTimeZone"
    "\Microsoft\Windows\UpdateOrchestrator\Report policies"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    "\Microsoft\Windows\UPnP\UPnPHostConfig"
    "\Microsoft\Windows\WaaSMedic\PerformRemediation"
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange"
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "\Microsoft\Windows\Wininet\CacheTask"
    "\Microsoft\XblGameSave\XblGameSaveTask"
) do (
	schtasks /change /disable /TN %%a > nul
)

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled scheduled tasks...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable scheduled tasks! >> %WinDir%\AtlasModules\logs\install.log)
cls & echo Please wait. This may take a moment.

:: enable MSI mode on USB controllers
:: second command for each device deletes device priorty, setting it to undefined
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>nul
)

:: enable MSI mode on GPU
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>nul
)

:: enable MSI mode on network adapters
:: undefined priority on some virtual machines may break connection
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
:: if e.g. VMWare is used, skip setting to undefined
wmic computersystem get manufacturer /format:value | findstr /i /C:VMWare && goto vmGO
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>nul
)
goto noVM

:vmGO
:: set to normal priority
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2"  /f
)

:noVM
:: enable MSI mode on SATA controllers
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>nul
)
if %ERRORLEVEL%==0 (echo %date% - %time% MSI mode set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set MSI mode! >> %WinDir%\AtlasModules\logs\install.log)

cls & echo Please wait. This may take a moment.

:: --- Hardening and Miscellaneous ---

:: delete defaultuser0 account used during oobe
net user defaultuser0 /delete > nul 2>nul

:: set PowerShell execution policy to unrestricted
PowerShell -NoProfile -Command "Set-ExecutionPolicy Unrestricted -force"

:: disable automatic repair
bcdedit /set recoveryenabled no > nul 2>nul
fsutil repair set C: 0 > nul 2>nul

:: disable powershell telemetry
:: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_telemetry?view=powershell-7.3
setx POWERSHELL_TELEMETRY_OPTOUT 1

:: disable hibernation and fast startup
powercfg -h off

:: disable sleep study
wevtutil set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false

:: hide useless windows immersive control panel pages
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:quiethours;tabletmode;project;crossdevice;remotedesktop;mobile-devices;network-cellular;network-wificalling;network-airplanemode;nfctransactions;maps;sync;speech;easeofaccess-magnifier;easeofaccess-narrator;easeofaccess-speechrecognition;easeofaccess-eyecontrol;privacy-speech;privacy-general;privacy-speechtyping;privacy-feedback;privacy-activityhistory;privacy-location;privacy-callhistory;privacy-eyetracker;privacy-messaging;privacy-automaticfiledownloads;windowsupdate;delivery-optimization;windowsdefender;backup;recovery;findmydevice;windowsinsider" /f

:: disable and delete adobe font type manager
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Font Drivers" /v "Adobe Type Manager" /f > nul 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "DisableATMFD" /t REG_DWORD /d "1" /f

:: disable USB autorun/play
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d "1" /f

:: disable lock screen camera
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d "1" /f

:: restrict anonymous access to named pipes and shares
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220932
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" /v "RestrictNullSessAccess" /t REG_DWORD /d "1" /f

:: disable smb compression (possible smbghost vulnerability workaround)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" /v "DisableCompression" /t REG_DWORD /d "1" /f

:: disable smb bandwidth throttling
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "DisableBandwidthThrottling" /t REG_DWORD /d "1" /f

:: block anonymous enumeration of sam accounts
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220929
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RestrictAnonymousSAM" /t REG_DWORD /d "1" /f

:: restrict anonymous enumeration of shares
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220930
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RestrictAnonymous" /t REG_DWORD /d "1" /f

:: netbios hardening
:: netbios is disabled. if it manages to become enabled, protect against NBT-NS poisoning attacks
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NodeType" /t REG_DWORD /d "2" /f

:: mitigate against hivenightmare/serious sam
icacls %WinDir%\system32\config\*.* /inheritance:e > nul

:: set strong cryptography on 64 bit and 32 bit .net framework (version 4 and above) to fix a scoop installation issue
:: https://github.com/ScoopInstaller/Scoop/issues/2040#issuecomment-369686748
reg add "HKLM\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" /v "SchUseStrongCrypto" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" /v "SchUseStrongCrypto" /t REG_DWORD /d "1" /f

:: disable network navigation pane in file explorer
reg add "HKCR\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder" /v "Attributes" /t REG_DWORD /d "2962489444" /f

:: set active power scheme to high performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

:: remove power saver power scheme
powercfg /delete a1841308-3541-4fab-bc81-f71556f20b4a

:: set current power scheme to Atlas
powercfg /changename 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c "Atlas Power Scheme" "Power scheme optimized for optimal latency and performance (v0.1)"

rem Turn off hard disk after 0 seconds
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0

rem Turn off Secondary NVMe Idle Timeout
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0

rem Turn off Primary NVMe Idle Timeout
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0

rem Turn off NVMe NOPPME
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0

rem Set slide show to paused
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1

rem Turn off system unattended sleep timeout
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0

rem Disable allow wake timers
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0

rem Disable Hub Selective Suspend Timeout
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0

rem Disable USB selective suspend setting
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

rem Set USB 3 Link Power Mangement to Maximum Performance
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0

rem Disable deep sleep
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2e601130-5351-4d9d-8e04-252966bad054 d502f7ee-1dc7-4efd-a55d-f04b6f5c0545 0

rem Disable allow throttle states
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 54533251-82be-4824-96c1-47b60b740d00 3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb 0

rem Turn off display after 0 seconds
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0

rem Disable critical battery notification
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c e73a048d-bf27-4f12-9731-8b2076e8891f 5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f 0

rem Disable critical battery action
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 0

rem Set low battery level to 0
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 0

rem Set critical battery level to 0
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 0

rem Disable low battery notification
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c e73a048d-bf27-4f12-9731-8b2076e8891f bcded951-187b-4d05-bccc-f7e51960c258 0

rem Set reserve battery level to 0
powercfg /setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c e73a048d-bf27-4f12-9731-8b2076e8891f f3c5027d-cd16-4930-aa6b-90db844a8f00 0

:: set the active scheme as the current scheme
powercfg /setactive scheme_current

if %ERRORLEVEL%==0 (echo %date% - %time% Power scheme configured...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to configure power scheme! >> %WinDir%\AtlasModules\logs\install.log)

:: set service split treshold
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set /a RAM=%%i+102400
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%RAM%" /f
if %ERRORLEVEL%==0 (echo %date% - %time% Service split treshold set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set service split treshold! >> %WinDir%\AtlasModules\logs\install.log)

:: disable drivers power savings
for /f "tokens=*" %%i in ('wmic path Win32_PnPEntity GET DeviceID ^| findstr "USB\VID_"') do (   
    for %%a in (
    	"AllowIdleIrpInD3"
        "D3ColdSupported"
        "DeviceSelectiveSuspended"
        "EnableIdlePowerManagement"
        "EnableSelectiveSuspend"
        "EnhancedPowerManagementEnabled"
        "IdleInWorkingState"
        "SelectiveSuspendEnabled"
        "SelectiveSuspendOn"
        "WaitWakeEnabled"
        "WakeEnabled"
        "WdfDirectedPowerTransitionEnable"
    ) do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters" /v "%%a" /t REG_DWORD /d "0" /f
    )
)

:: disable pnp power savings
PowerShell -NoProfile -Command "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $False; $power_device.psbase.put()}}}}"
if %ERRORLEVEL%==0 (echo %date% - %time% Disabled power savings...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable power savings! >> %WinDir%\AtlasModules\logs\install.log)

:: disable netbios over tcp/ip
:: works only when services are enabled
for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%b" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)
if %ERRORLEVEL%==0 (echo %date% - %time% Disabled netbios over tcp/ip...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable netbios over tcp/ip! >> %WinDir%\AtlasModules\logs\install.log)

:: make certain applications in the AtlasModules folder request UAC
:: although these applications may already request UAC, setting this compatibility flag ensures they are ran as administrator
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%WinDir%\AtlasModules\serviwin.exe" /t REG_SZ /d "~ RUNASADMIN" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%WinDir%\AtlasModules\DevManView.exe" /t REG_SZ /d "~ RUNASADMIN" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%WinDir%\AtlasModules\NSudo.exe" /t REG_SZ /d "~ RUNASADMIN" /f

cls & echo Please wait. This may take a moment.

:: unhide power scheme attributes
:: credits: eugene muzychenko; modified by Xyueta
for /f "tokens=1-9* delims=\ " %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings" /s /f "Attributes" /e') do (
    if /i "%%A" == "HKLM" (
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
                set Ident=!Group!:!Setting!
            ) else (
                set Ident=!Group!
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
            powercfg /attributes !Ident::= ! -attrib_hide
        )
    )
)
if %ERRORLEVEL%==0 (echo %date% - %time% Enabled hidden power scheme attributes...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to enable hidden power scheme attributes! >> %WinDir%\AtlasModules\logs\install.log)

:: disable nagle's algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%i in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: set default power saving mode for all network cards to disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "DefaultPnPCapabilities" /t REG_DWORD /d "24" /f

:: configure nic settings
:: modified by Xyueta
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    for %%b in (
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
        for /f %%c in ('reg query "%%a" /v "%%b" ^| findstr "HKEY"') do (
            reg add "%%c" /v "%%b" /t REG_SZ /d "0" /f
        )
    )
)

:: configure netsh settings
netsh int tcp set heuristics=disabled
netsh int tcp set supplemental Internet congestionprovider=ctcp
netsh int tcp set global rsc=disabled
for /f "tokens=1" %%i in ('netsh int ip show interfaces ^| findstr [0-9]') do (
	netsh int ip set interface %%i routerdiscovery=disabled store=persistent
)

if %ERRORLEVEL%==0 (echo %date% - %time% Network optimized...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to optimize network! >> %WinDir%\AtlasModules\logs\install.log)

:: fix explorer whitebar bug
start explorer.exe
taskkill /f /im explorer.exe
start explorer.exe

:: disable network adapters
:: IPv6, Client for Microsoft Networks, File and Printer Sharing, LLDP Protocol, Link-Layer Topology Discovery Mapper, Link-Layer Topology Discovery Responder
PowerShell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6, ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr"

:: disable system devices
DevManView.exe /disable "AMD PSP"
DevManView.exe /disable "AMD SMBus"
DevManView.exe /disable "Base System Device"
DevManView.exe /disable "Composite Bus Enumerator"
DevManView.exe /disable "High precision event timer"
DevManView.exe /disable "Intel Management Engine"
DevManView.exe /disable "Intel SMBus"
DevManView.exe /disable "Microsoft Hyper-V NT Kernel Integration VSP"
DevManView.exe /disable "Microsoft Hyper-V PCI Server"
DevManView.exe /disable "Microsoft Hyper-V Virtual Disk Server"
DevManView.exe /disable "Microsoft Hyper-V Virtual Machine Bus Provider"
DevManView.exe /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"
DevManView.exe /disable "Microsoft Kernel Debug Network Adapter"
DevManView.exe /disable "Microsoft RRAS Root Enumerator"
:: DevManView.exe /disable "Microsoft Virtual Drive Enumerator" < breaks ISO mount
DevManView.exe /disable "Motherboard resources"
DevManView.exe /disable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /disable "Numeric Data Processor"
DevManView.exe /disable "PCI Data Acquisition and Signal Processing Controller"
DevManView.exe /disable "PCI Encryption/Decryption Controller"
DevManView.exe /disable "PCI Memory Controller"
DevManView.exe /disable "PCI Simple Communications Controller"
:: DevManView.exe /disable "Programmable Interrupt Controller"
DevManView.exe /disable "SM Bus Controller"
DevManView.exe /disable "System CMOS/real time clock"
DevManView.exe /disable "System Speaker"
DevManView.exe /disable "System Timer"
DevManView.exe /disable "UMBus Root Bus Enumerator"

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled devices...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable devices! >> %WinDir%\AtlasModules\logs\install.log)

if %branch%=="1803" NSudo.exe -U:C -P:E %WinDir%\AtlasModules\1803.bat
if %branch%=="20H2" NSudo.exe -U:C -P:E %WinDir%\AtlasModules\20H2.bat
if %branch%=="22H2" NSudo.exe -U:C -P:E %WinDir%\AtlasModules\22H2.bat

:: backup default windows services
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows services.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "skip=1" %%i in ('wmic service get Name ^| findstr "[a-z]" ^| findstr /V "TermService"') do (
	    set svc=%%i
	    set svc=!svc: =!
	    for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
            set /a start=%%i
            echo !start!
            echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
            echo "Start"=dword:0000000!start! >> %filename%
            echo] >> %filename%
	    )
) > nul 2>&1

:: backup default windows drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "delims=," %%i in ('driverquery /FO CSV') do (
	set svc=%%~i
	for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%i
		echo !start!
		echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) > nul 2>&1

:: services
%setSvc% AppIDSvc 4
%setSvc% AppVClient 4
%setSvc% AppXSvc 3
%setSvc% BthAvctpSvc 4
%setSvc% cbdhsvc 4
%setSvc% CDPSvc 4
%setSvc% CryptSvc 3
%setSvc% defragsvc 3
%setSvc% diagnosticshub.standardcollector.service 4
%setSvc% diagsvc 4
%setSvc% DispBrokerDesktopSvc 4
%setSvc% DisplayEnhancementService 4
%setSvc% DoSvc 3
%setSvc% DPS 4
%setSvc% DsmSvc 3
:: %setSvc% DsSvc 4 < can cause issues with snip and sketch
%setSvc% Eaphost 3
%setSvc% EFS 3
%setSvc% fdPHost 4
%setSvc% FDResPub 4
%setSvc% FontCache 4
%setSvc% FontCache3.0.0.0 4
%setSvc% gcs 4
%setSvc% hvhost 4
%setSvc% icssvc 4
%setSvc% IKEEXT 4
%setSvc% InstallService 3
%setSvc% iphlpsvc 4
%setSvc% IpxlatCfgSvc 4
:: %setSvc% KeyIso 4 < causes issues with nvcleanstall's driver telemetry tweak
%setSvc% KtmRm 4
%setSvc% LanmanServer 4
%setSvc% LanmanWorkstation 4
%setSvc% lmhosts 4
%setSvc% MSDTC 4
%setSvc% NetTcpPortSharing 4
%setSvc% PcaSvc 4
%setSvc% PhoneSvc 4
%setSvc% QWAVE 4
%setSvc% RasMan 4
%setSvc% SharedAccess 4
%setSvc% ShellHWDetection 4
%setSvc% SmsRouter 4
%setSvc% Spooler 4
%setSvc% sppsvc 3
%setSvc% SSDPSRV 4
%setSvc% SstpSvc 4
%setSvc% SysMain 4
%setSvc% Themes 4
%setSvc% UsoSvc 3
%setSvc% VaultSvc 4
%setSvc% vmcompute 4
%setSvc% vmicguestinterface 4
%setSvc% vmicheartbeat 4
%setSvc% vmickvpexchange 4
%setSvc% vmicrdv 4
%setSvc% vmicshutdown 4
%setSvc% vmictimesync 4
%setSvc% vmicvmsession 4
%setSvc% vmicvss 4
%setSvc% W32Time 4
%setSvc% WarpJITSvc 4
%setSvc% WdiServiceHost 4
%setSvc% WdiSystemHost 4
%setSvc% Wecsvc 4
%setSvc% WEPHOSTSVC 4
%setSvc% WinHttpAutoProxySvc 4
%setSvc% WPDBusEnum 4
%setSvc% WSearch 4
%setSvc% wuauserv 3

:: drivers
%setSvc% 3ware 4
%setSvc% ADP80XX 4
%setSvc% AmdK8 4
%setSvc% arcsas 4
%setSvc% AsyncMac 4
%setSvc% Beep 4
%setSvc% bindflt 4
%setSvc% bttflt 4
%setSvc% buttonconverter 4
%setSvc% CAD 4
%setSvc% cdfs 4
%setSvc% CimFS 4
%setSvc% circlass 4
%setSvc% cnghwassist 4
%setSvc% CompositeBus 4
%setSvc% Dfsc 4
%setSvc% ErrDev 4
%setSvc% fdc 4
%setSvc% flpydisk 4
%setSvc% fvevol 4
:: %setSvc% FileInfo 4 < breaks installing microsoft store apps to different disk (now disabled via store script)
:: %setSvc% FileCrypt 4 < Breaks installing microsoft store apps to different disk (now disabled via store script)
%setSvc% gencounter 4
%setSvc% GpuEnergyDrv 4
%setSvc% hvcrash 4
%setSvc% hvservice 4
%setSvc% hvsocketcontrol 4
%setSvc% KSecPkg 4
%setSvc% mrxsmb 4
%setSvc% mrxsmb20 4
%setSvc% NdisVirtualBus 4
%setSvc% nvraid 4
%setSvc% passthruparser 4
:: %setSvc% PEAUTH 4 < breaks uwp streaming apps like netflix, manual mode does not fix
%setSvc% pvhdparser 4
%setSvc% QWAVEdrv 4
:: set rdbss to manual instead of disabling (fixes wsl), thanks phlegm
%setSvc% rdbss 3
%setSvc% rdyboost 4
%setSvc% sfloppy 4
%setSvc% SiSRaid2 4
%setSvc% SiSRaid4 4
%setSvc% spaceparser 4
%setSvc% srv2 4
%setSvc% storflt 4
%setSvc% Tcpip6 4
%setSvc% tcpipreg 4
%setSvc% Telemetry 4
%setSvc% udfs 4
%setSvc% umbus 4
%setSvc% VerifierExt 4
%setSvc% vhdparser 4
%setSvc% Vid 4
%setSvc% vkrnlintvsc 4
%setSvc% vkrnlintvsp 4
%setSvc% vmbus 4
%setSvc% vmbusr 4
%setSvc% vmgid 4
:: %setSvc% volmgrx 4 < breaks dynamic disks
%setSvc% vpci 4
%setSvc% vsmraid 4
%setSvc% VSTXRAID 4
:: %setSvc% wcifs 4 < breaks various microsoft store games, erroring with "filter not found"
%setSvc% wcnfs 4
%setSvc% WindowsTrustedRTProxy 4

:: remove dependencies
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dhcp" /v "DependOnService" /t REG_MULTI_SZ /d "NSI\0Afd" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache" /v "DependOnService" /t REG_MULTI_SZ /d "nsi" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\rdyboost" /v "DependOnService" /t REG_MULTI_SZ /d "" /f

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ  /d "" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ  /d "" /f

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled services...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable services! >> %WinDir%\AtlasModules\logs\install.log)

:: backup default Atlas services
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas services.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "skip=1" %%i in ('wmic service get Name ^| findstr "[a-z]" ^| findstr /V "TermService"') do (
	set svc=%%i
	set svc=!svc: =!
	for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%i
		echo !start!
		echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) > nul 2>&1

:: backup default Atlas drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "delims=," %%i in ('driverquery /FO CSV') do (
	set svc=%%~i
	for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%i
		echo !start!
		echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) > nul 2>&1

:: Registry
:: done through script now, HKCU\... keys often do not integrate correctly

:: bsod quality of life
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "AutoReboot" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "LogEvent" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "DisplayParameters" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry" /v "DeviceDumpEnabled" /t REG_DWORD /d "0" /f

:: gpo for start menu (tiles)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "%WinDir%\layout.xml" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "%WinDir%\layout.xml" /f

:: configure start menu settings
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d "1" /f

:: disable startup delay of running startup apps
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d "0" /f

:: reduce menu show delay time 
:: automatically close any apps and continue to restart, shut down, or sign out of windows
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f

:: enable dark mode and disable transparency
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f

:: configure visual effect settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f

:: disable desktop wallpaper import quality reduction
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f

:: disable acrylic blur effect on sign-in screen background
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableAcrylicBackgroundOnLogon" /t REG_DWORD /d "1" /f

:: disable animate windows when minimizing and maximizing
%currentuser% reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f

:: enable window colorization
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableWindowColorization" /t REG_DWORD /d "1" /f

:: configure desktop window manager
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "Composition" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableWindowColorization" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f

:: disable auto download of microsoft store apps
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d "2" /f

:: users can not add microsoft accounts
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "NoConnectedUser" /t REG_DWORD /d "1" /f

:: disable fast user switching
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "HideFastUserSwitching" /t REG_DWORD /d "1" /f

:: disable website access to language list
%currentuser% reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f

:: disable onedrive
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f

:: disable require hello sign-in for microsoft accounts
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" /v "DevicePasswordLessBuildVersion" /t REG_DWORD /d "0" /f

:: may cause issues with language packs/microsoft store
:: if you are planning to revert, remove reg add "HKLM\SOFTWARE\Policies\Microsoft\InternetManagement" /v "RestrictCommunication" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d "1" /f

:: disable speech model updates
reg add "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d "0" /f

:: disable online speech recognition 
reg add "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization" /t REG_DWORD /d "0" /f

:: disable windows insider and build previews
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableConfigFlighting" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "AllowBuildPreview" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableExperimentation" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /v "HideInsiderPage" /t REG_DWORD /d "1" /f

:: disable ceip
reg add "HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM" /v "OptIn" /t REG_DWORD /d "0" /f

:: disable activity feed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d "0" /f

:: disable windows media DRM internet access
reg add "HKLM\SOFTWARE\Policies\Microsoft\WMDRM" /v "DisableOnline" /t REG_DWORD /d "1" /f

:: disable windows media player wizard on first run
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "AcceptedPrivacyStatement" /t REG_DWORD /d "1" /f

:: enable always show all icons and notifications on the taskbar
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "EnableAutoTray" /t REG_DWORD /d "0" /f

:: configure search settings
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d "0" /f

:: disable search suggestions
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d "1" /f

:: set search as icon on taskbar
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f

:: configure snap settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapAssist" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "JointResize" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapFill" /t REG_DWORD /d "0" /f

:: configure file explorer settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "LinkResolveIgnoreLinkInfo" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ClearRecentDocsOnExit" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInternetOpenWith" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontUsePowerShellOnWinX" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "AutoCheckSelect" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SharingWizardOn" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarBadges" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d "1" /f

:: run explorer as this pc
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f

:: old alt tab
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "AltTabSettings" /t REG_DWORD /d "1" /f

:: disable suggested content in settings app (immersive control panel)
:: disable fun facts, tips, tricks on windows spotlight
:: disable start menu suggestions
for %%i in (
    "SubscribedContent-338393Enabled"
    "SubscribedContent-353694Enabled"
    "SubscribedContent-353696Enabled"
    "SubscribedContent-338387Enabled"
    "SubscribedContent-338388Enabled"
) do (
    %currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "%%i" /t REG_DWORD /d "0" /f
)

:: disable windows spotlight features
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d "1" /f

:: disable tips for settings app (immersive control panel)
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowOnlineTips" /v "value" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "AllowOnlineTips" /t REG_DWORD /d "0" /f

:: disable suggest ways I can finish setting up my device
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d "0" /f

:: disable automatically restart apps after sign in
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "RestartApps" /t REG_DWORD /d "0" /f

:: disable disk quota
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DiskQuota" /v "Enable" /t REG_DWORD /d "0" /f

:: do not allow pinning microsoft store app to taskbar
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoPinningStoreToTaskbar" /t REG_DWORD /d "1" /f

:: add atlas' webstite as start page in internet explorer
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "https://atlasos.net" /f

:: disable devicecensus.exe telemetry process
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\'DeviceCensus.exe'" /v "Debugger" /t REG_SZ /d "%WinDir%\System32\taskkill.exe" /f

:: disable microsoft compatibility appraiser telemetry process
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\'CompatTelRunner.exe'" /v "Debugger" /t REG_SZ /d "%WinDir%\System32\taskkill.exe" /f

:: disable program compatibility assistant
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableEngine" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d "1" /f

:: disable open file - security warning message
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Security" /v "DisableSecuritySettingsCheck" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\0" /v "1806" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\0" /v "1806" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1" /v "1806" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1" /v "1806" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1806" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1806" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v "1806" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v "1806" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4" /v "1806" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4" /v "1806" /t REG_DWORD /d "0" /f

:: disable enhance pointer precison
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "0" /f

:: configure ease of access settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Ease of Access" /v "selfvoice" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Ease of Access" /v "selfscan" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility" /v "Sound on Activation" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility" /v "Warning Sounds" /t REG_DWORD /d "0" /f

:: disable annoying keyboard features
%currentuser% reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\MouseKeys" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_DWORD /d "0" /f

:: configure language bar
%currentuser% reg add "HKCU\Keyboard Layout\Toggle" /v "Layout Hotkey" /t REG_SZ /d "3" /f
%currentuser% reg add "HKCU\Keyboard Layout\Toggle" /v "Language Hotkey" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\Keyboard Layout\Toggle" /v "Hotkey" /t REG_DWORD /d "3" /f

:: restrict windows' access to internet resources
:: enables various other GPOs that limit access on specific windows services
reg add "HKLM\SOFTWARE\Policies\Microsoft\InternetManagement" /v "RestrictCommunication" /t REG_DWORD /d "1" /f

:: disable text/ink/handwriting telemetry
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v "PreventHandwritingDataSharing" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d "1" /f

:: disable spell checking
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableSpellchecking" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnablePredictionSpaceInsertion" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutocorrection" /t REG_DWORD /d "0" /f

:: disable typing insights
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Input\Settings" /v "InsightsEnabled" /t REG_DWORD /d "0" /f

:: disable windows error reporting
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d "1" /f

:: lock UserAccountControlSettings.exe - users can enable UAC from there without luafv and appinfo enabled, which breaks uac completely and causes issues
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /t REG_SZ /d "C:\Windows\AtlasModules\atlas-config.bat /uacSettings /skipAdminCheck" /f

:: disable data collection
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d "0" /f

:: disable nvidia telemetry
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d "0" /f

:: configure app permissions/privacy in settings app (immersive control panel)
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" /v "Value" /t REG_SZ /d "Deny" /f

:: configure voice activation settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationOnLockScreenEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationLastUsed" /t REG_DWORD /d "0" /f

:: disable smartscreen
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d "0" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /f > nul 2>nul

:: disable experimentation
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" /v "Value" /t REG_DWORD /d "0" /f

:: miscellaneous
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v "ShowedToastAtLevel" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d "0" /f

:: disable advertising info
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable cloud optimized taskbars
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d "1" /f

:: disable license telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d "1" /f

:: disable windows feedback
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d "0" /f 
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /f > nul 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f

:: disable settings sync
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSync" /t REG_DWORD /d "2" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSyncUserOverride" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" /v "SyncPolicy" /t REG_DWORD /d "5" /f

:: power
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d "0" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EventProcessorEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f

:: location tracking
reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v "LocationSyncEnabled" /t REG_DWORD /d "0" /f

:: remove readyboost tab
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f > nul 2>nul

:: hide meet now button on taskbar
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f

:: hide people on taskbar
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HidePeopleBar" /t REG_DWORD /d "1" /f

:: hide task view button on taskbar
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView" /v "Enabled" /f > nul 2>nul
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /D "0" /f

:: disable news and interests
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f

:: disable shared experiences
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d "0" /f

:: show all tasks on control panel, credits to tenforums
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "InfoTip" /t REG_SZ /d "View list of all Control Panel tasks" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "System.ControlPanel.Category" /t REG_SZ /d "5" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\DefaultIcon" /ve /t REG_SZ /d "%%WinDir%%\System32\imageres.dll,-27" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\Shell\Open\Command" /ve /t REG_SZ /d "explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f

:: disable hyper-v and vbs as default
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecuritye
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "EnableVirtualizationBasedSecurity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "RequirePlatformSecurityFeatures" /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HypervisorEnforcedCodeIntegrity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HVCIMATRequired" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "LsaCfgFlags" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "ConfigureSystemGuardLaunch" /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: memory management
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableCfg" /t REG_DWORD /d "0" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /t REG_DWORD /d "0" /f

:: configure paging settings
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePageCombining" /t REG_DWORD /d "1" /f

:: disable spectre and meltdown
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f

:: disable fault tolerant heap
:: https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
:: doc listed as only affected in windows 7, is also in 7+
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d "0" /f

:: https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#structured-exception-handling-overwrite-protection
:: not found in ntoskrnl strings, very likely depracated or never existed. it is also disabled in MitigationOptions below
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "KernelSEHOPEnabled" /t REG_DWORD /d "0" /f

:: exists in ntoskrnl strings, keep for now
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "1" /f

:: find correct mitigation values for different Windows versions - AMIT
:: initialize bit mask in registry by disabling a random mitigation
PowerShell -NoProfile -Command "Set-ProcessMitigation -System -Disable CFG"

:: get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set "mitigation_mask=%%a"
)

:: set all bits to 2 (disable all mitigations)
for /l %%a in (0,1,9) do (
    set "mitigation_mask=!mitigation_mask:%%a=2!"
)

:: apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f

:: disable TsX
:: https://www.intel.com/content/www/us/en/support/articles/000059422/processors.html
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f

:: disable virtualization-based protection of code integrity
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable write cache buffer on all drives
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI" ^| findstr "HKEY"') do (
	for /f "tokens=*" %%a in ('reg query "%%i" ^| findstr "HKEY"') do (
		reg add "%%a\Device Parameters\Disk" /v "CacheIsPowerProtected" /t REG_DWORD /d "1" /f
		reg add "%%a\Device Parameters\Disk" /v "UserWriteCacheSetting" /t REG_DWORD /d "1" /f	
	)
)

:: configure multimedia class scheduler
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "10" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "10000" /f

:: configure gamebar/fullscreen exclusive
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /t REG_DWORD /d "2" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f

:: make sure game mode is disabled
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f

:: disallow background apps
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f

:: set Win32PrioritySeparation to short variable 1:1, no foreground boost
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "36" /f

:: disable notifications/action center
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoTileApplicationNotification" /t REG_DWORD /d "1" /f

:: disable autoplay and autorun
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d "255" /f 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoAutoplayfornonVolume" /t REG_DWORD /d "1" /f

:: requires testing
:: https://djdallmann.github.io/GamingPCSetup/CONTENT/RESEARCH/FINDINGS/registrykeys_dwm.txt
:: reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "AnimationAttributionEnabled" /t REG_DWORD /d "0" /f

:: apply the default account picture to all users
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "UseDefaultTile" /t REG_DWORD /d "1" /f

:: hide frequently and recently used files/folders in quick access
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f

:: disable notify about usb issues
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Shell\USB" /v "NotifyOnUsbErrors" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Shell\USB" /v "NotifyOnWeakCharger" /t REG_DWORD /d "0" /f

:: disable folders in this pc
:: credit: https://www.tenforums.com/tutorials/6015-add-remove-folders-pc-windows-10-a.html
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f

:: enable legacy photo viewer
for %%i in (tif tiff bmp dib gif jfif jpe jpeg jpg jxr png) do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".%%~i" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
)

:: set legacy photo viewer as default
for %%i in (tif tiff bmp dib gif jfif jpe jpeg jpg jxr png) do (
    %currentuser% reg add "HKCU\SOFTWARE\Classes\.%%~i" /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
)

:: disable gamebar presence writer
reg add "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d "0" /f

:: disable maintenance
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "1" /f

:: do not reduce sounds while in a call
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio" /v "UserDuckingPreference" /t REG_DWORD /d "3" /f

:: do not show hidden/disconnected devices in sound settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl" /v "ShowDisconnectedDevices" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl" /v "ShowHiddenDevices" /t REG_DWORD /d "0" /f

:: set sound scheme to no sounds
PowerShell -NoProfile -Command "New-ItemProperty -Path HKCU:\AppEvents\Schemes -Name '(Default)' -Value '.None' -Force | Out-Null"
PowerShell -NoProfile -Command "Get-ChildItem -Path 'HKCU:\AppEvents\Schemes\Apps' | Get-ChildItem | Get-ChildItem | Where-Object {$_.PSChildName -eq '.Current'} | Set-ItemProperty -Name '(Default)' -Value ''"

:: disable audio excludive mode on all devices
for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"') do (
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"') do (
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

:: install cab context menu
reg delete "HKCR\CABFolder\Shell\RunAs" /f > nul 2>nul
reg add "HKCR\CABFolder\Shell\RunAs" /ve /t REG_SZ /d "Install" /f
reg add "HKCR\CABFolder\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\CABFolder\Shell\RunAs\Command" /ve /t REG_SZ /d "cmd /k DISM /online /add-package /packagepath:\"%%1\"" /f

:: merge as trusted installer for registry files
reg add "HKCR\regfile\Shell\RunAs" /ve /t REG_SZ /d "Merge As TrustedInstaller" /f
reg add "HKCR\regfile\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "1" /f
reg add "HKCR\regfile\Shell\RunAs\Command" /ve /t REG_SZ /d "NSudo.exe -U:T -P:E reg import "%%1"" /f

:: remove restore previous versions
:: from context menu and file' properties
reg delete "HKCR\AllFilesystemObjects\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Directory\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "NoPreviousVersionsPage" /f > nul 2>nul
%currentuser% reg delete "HKCU\SOFTWARE\Policies\Microsoft\PreviousVersions" /v "DisableLocalPage" /f > nul 2>nul

:: remove give access to from context menu
reg delete "HKCR\*\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\Directory\Background\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul

:: remove cast to device from context menu
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{7AD84985-87B4-4a16-BE58-8B72A5B390F7}" /t REG_SZ /d "" /f

:: remove share in context menu
reg delete "HKCR\*\shellex\ContextMenuHandlers\ModernSharing" /f > nul 2>nul

:: remove bitmap image from the 'New' context menu
reg delete "HKCR\.bmp\ShellNew" /f > nul 2>nul

:: remove rich text document from 'New' context menu
reg delete "HKCR\.rtf\ShellNew" /f > nul 2>nul

:: remove include in library context menu
reg delete "HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location" /f > nul 2>nul
reg delete "HKLM\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" /f > nul 2>nul

:: remove troubleshooting compatibility in context menu
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{1d27f844-3a1f-4410-85ac-14651078412d}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{1d27f844-3a1f-4410-85ac-14651078412d}" /t REG_SZ /d "" /f

:: remove '- Shortcut' text added onto shortcuts
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "link" /t REG_BINARY /d "00000000" /f

:: add .bat, .cmd, .reg and .ps1 to the 'New' context menu
reg add "HKLM\Software\Classes\.bat\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6002" /f
reg add "HKLM\Software\Classes\.bat\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\Software\Classes\.cmd\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\Software\Classes\.cmd\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6003" /f
reg add "HKLM\Software\Classes\.ps1\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\Software\Classes\.ps1\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "New file"
reg add "HKLM\Software\Classes\.reg\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\Software\Classes\.reg\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\regedit.exe,-309" /f

:: double click to import power schemes
reg add "HKLM\SOFTWARE\Classes\powerplan\DefaultIcon" /ve /t REG_SZ /d "%%WinDir%%\System32\powercpl.dll,1" /f
reg add "HKLM\SOFTWARE\Classes\powerplan\Shell\open\command" /ve /t REG_SZ /d "powercfg /import \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\.pow" /ve /t REG_SZ /d "powerplan" /f
reg add "HKLM\SOFTWARE\Classes\.pow" /v "FriendlyTypeName" /t REG_SZ /d "Power Plan" /f

if %ERRORLEVEL%==0 (echo %date% - %time% Registry configuration applied...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to apply registry configuration! >> %WinDir%\AtlasModules\logs\install.log)

:: disable dma remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
	reg add "%%i" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)
echo %date% - %time% Disabled dma remapping...>> %WinDir%\AtlasModules\logs\install.log

if %ERRORLEVEL%==0 (echo %date% - %time% Process priorities set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set priorities! >> %WinDir%\AtlasModules\logs\install.log)

:: lowering dual boot choice time
:: no, this does not affect single OS boot time.
:: this is directly shown in microsoft docs https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--timeout#parameters
bcdedit /timeout 10

:: setting to "no" provides worse results, delete the value instead.
:: this is here as a safeguard incase of user error
bcdedit /deletevalue useplatformclock > nul 2>nul

:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /set disabledynamictick Yes

:: disable data execution prevention
:: may need to enable for faceit, valorant, and other anti-cheats
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOff

:: use legacy boot menu
bcdedit /set bootmenupolicy Legacy

:: make dual boot menu more descriptive
bcdedit /set description Atlas %branch% %ver%

:: disable hyper-v and vbs
bcdedit /set hypervisorlaunchtype off
bcdedit /set vm no
bcdedit /set vmslaunchtype Off
bcdedit /set loadoptions DISABLE-LSA-ISO,DISABLE-VBS

echo %date% - %time% BCD Options Set...>> %WinDir%\AtlasModules\logs\install.log

:: write to script log file
echo This log keeps track of which scripts have been run. This is never transfered to an online resource and stays local. > %WinDir%\AtlasModules\logs\userScript.log
echo -------------------------------------------------------------------------------------------------------------------- >> %WinDir%\AtlasModules\logs\userScript.log

:: clear false value
break > C:\Users\Public\success.txt
echo true > C:\Users\Public\success.txt
echo %date% - %time% Post-Install Finished Redirecting to sub script...>> %WinDir%\AtlasModules\logs\install.log
exit

:notiD
sc config WpnService start=disabled
sc stop WpnService > nul 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
if %ERRORLEVEL%==0 echo %date% - %time% Notifications disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:notiE
sc config WpnUserService start=auto
sc config WpnService start=auto
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Notifications enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:indexD
sc config WSearch start=disabled
sc stop WSearch > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Search Indexing disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:indexE
sc config WSearch start=delayed-auto
sc start WSearch > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Search Indexing enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:wifiD
echo Applications like Microsoft Store and Spotify may not function correctly when disabled. If this is a problem, enable the Wi-Fi and restart the computer.
sc config WlanSvc start=disabled
sc config vwififlt start=disabled
set /P c="Would you like to disable the network icon? (disables two extra services) [Y/N]: "
if /I "%c%" EQU "N" goto wifiDskip
sc config netprofm start=disabled
sc config NlaSvc start=disabled

:wifiDskip
if %ERRORLEVEL%==0 echo %date% - %time% Wi-Fi disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1"=="int" goto :EOF
goto finish

:wifiE
sc config netprofm start=demand
sc config NlaSvc start=auto
sc config WlanSvc start=demand
sc config vwififlt start=system
:: if Wi-Fi is still not working, set wlansvc to auto
ping -n 1 -4 1.1.1.1 | find "Failure" | (
    sc config WlanSvc start=auto
)
if %ERRORLEVEL%==0 echo %date% - %time% Wi-Fi enabled...>> %WinDir%\AtlasModules\logs\userScript.log
sc config eventlog start=auto
echo %date% - %time% EventLog enabled as Wi-Fi dependency...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:hyperD
:: credit: he3als
:: bcdedit commands
bcdedit /set hypervisorlaunchtype off > nul
bcdedit /set vm no > nul
bcdedit /set vmslaunchtype Off > nul
bcdedit /set loadoptions DISABLE-LSA-ISO,DISABLE-VBS > nul

:: disable hyper-v with dism
DISM /Online /Disable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart

:: apply registry changes
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecuritye
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "EnableVirtualizationBasedSecurity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "RequirePlatformSecurityFeatures" /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HypervisorEnforcedCodeIntegrity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HVCIMATRequired" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "LsaCfgFlags" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "ConfigureSystemGuardLaunch" /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable drivers
for %%a in (
    "hvcrash"
    "hvservice"
    "vhdparser"
    "vkrnlintvsc"
    "vkrnlintvsp"
    "vmbus"
    "Vid"
    "bttflt"
    "gencounter"
    "hvsocketcontrol"
    "passthruparser"
    "pvhdparser"
    "spaceparser"
    "storflt"
    "vmgid"
    "vmbusr"
    "vpci"
) do (
    sc config %%a start=disabled > nul
)

:: disable services
for %%a in (
    "gcs"
    "hvhost"
    "vmcompute"
    "vmicguestinterface"
    "vmicheartbeat"
    "vmickvpexchange"
    "vmicrdv"
    "vmicshutdown"
    "vmictimesync"
    "vmicvmsession"
    "vmicvss"
) do (
    sc config %%a start=disabled > nul
)

:: disable devices
DevManView.exe /disable "Microsoft Hyper-V NT Kernel Integration VSP"
DevManView.exe /disable "Microsoft Hyper-V PCI Server"
DevManView.exe /disable "Microsoft Hyper-V Virtual Disk Server"
DevManView.exe /disable "Microsoft Hyper-V Virtual Machine Bus Provider"
DevManView.exe /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"

if %ERRORLEVEL%==0 echo %date% - %time% Hyper-V and VBS disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hyperE
:: credit: he3als
:: bcdedit commands
bcdedit /set hypervisorlaunchtype auto > nul
bcdedit /deletevalue vm > nul
bcdedit /set vsmlaunchtype Auto > nul
bcdedit /deletevalue loadoptions > nul

:: enable hyper-v with dism
DISM /Online /Enable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart

:: apply registry changes
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecuritye
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "RequirePlatformSecurityFeatures" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HypervisorEnforcedCodeIntegrity" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HVCIMATRequired" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "LsaCfgFlags" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "ConfigureSystemGuardLaunch" /f

:: found this to be the default
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "1" /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /f

:: enable drivers
:: default for hvcrash is disabled
sc config hvcrash start=disabled > nul
sc config hvservice start=manual > nul
sc config vhdparser start=manual > nul
sc config vmbus start=boot > nul
sc config Vid start=system > nul
sc config bttflt start=boot > nul
sc config gencounter start=manual > nul
sc config hvsocketcontrol start=manual > nul
sc config passthruparser start=manual > nul
sc config pvhdparser start=manual > nul
sc config spaceparser start=manual > nul
sc config storflt start=boot > nul
sc config vmgid start=manual > nul
sc config vmbusr start=manual > nul
sc config vpci start=boot > nul

:: enable services
sc config gcs start=manual > nul
sc config hvhost start=manual > nul
sc config vmcompute start=manual > nul
sc config vmicguestinterface start=manual > nul
sc config vmicheartbeat start=manual > nul
sc config vmickvpexchange start=manual > nul
sc config vmicrdv start=manual > nul
sc config vmicshutdown start=manual > nul
sc config vmictimesync start=manual > nul
sc config vmicvmsession start=manual > nul
sc config vmicvss start=manual > nul

:: enable devices
DevManView.exe /enable "Microsoft Hyper-V NT Kernel Integration VSP"
DevManView.exe /enable "Microsoft Hyper-V PCI Server"
DevManView.exe /enable "Microsoft Hyper-V Virtual Disk Server"
DevManView.exe /enable "Microsoft Hyper-V Virtual Machine Bus Provider"
DevManView.exe /enable "Microsoft Hyper-V Virtualization Infrastructure Driver"

if %ERRORLEVEL%==0 echo %date% - %time% Hyper-V and VBS enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:storeD
echo This will break a majority of UWP apps and their deployment.
echo Extra note: This breaks the "about" page in settings. If you require it, enable the AppX service.
:: this includes windows firewall, i only see the point in keeping it because of microsoft store
:: if you notice something else breaks when firewall/microsoft store is disabled please open an issue
pause

:: detect if user is using a microsoft account
PowerShell -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" > nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( sc config wlidsvc start=disabled ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )

:: disable the option for microsoft store in the "open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f

:: block access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
sc config InstallService start=disabled

:: insufficent permissions to disable
%setSvc% WinHttpAutoProxySvc 4
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
if %ERRORLEVEL%==0 echo %date% - %time% Microsoft Store disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:storeE
:: enable the option for microsoft store in the "open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f

:: allow access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
sc config InstallService start=demand

:: insufficent permissions to enable through SC
%setSvc% WinHttpAutoProxySvc 3
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
if %ERRORLEVEL%==0 echo %date% - %time% Microsoft Store enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:backD
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Background Apps disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:backE
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "1" /f
if %ERRORLEVEL%==0 echo %date% - %time% Background Apps enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:btD
sc config BthAvctpSvc start=disabled
sc stop BthAvctpSvc > nul 2>nul
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f "CDPUserSvc" ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
  sc stop %%~nI
)
sc config CDPSvc start=disabled
if %ERRORLEVEL%==0 echo %date% - %time% Bluetooth disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:btE
sc config BthAvctpSvc start=auto
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f "CDPUserSvc" ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "2" /f
)
sc config CDPSvc start=auto
if %ERRORLEVEL%==0 echo %date% - %time% Bluetooth enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:cbdhsvcD
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f "cbdhsvc" ^| find /i "cbdhsvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
)
:: to do: check if service can be set to demand
sc config DsSvc start=disabled
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Clipboard History disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:cbdhsvcE
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f "cbdhsvc" ^| find /i "cbdhsvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "3" /f
)
sc config DsSvc start=auto
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "1" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /f > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Clipboard History enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hddD
sc config SysMain start=disabled
sc config FontCache start=disabled
if %ERRORLEVEL%==0 echo %date% - %time% Hard Drive Prefetching disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hddE
:: disable memory compression and page combining when sysmain is enabled
PowerShell -NoProfile -Command "Disable-MMAgent -MemoryCompression -PageCombining"
sc config SysMain start=auto
sc config FontCache start=auto
if %ERRORLEVEL%==0 echo %date% - %time% Hard Drive Prefetch enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:depE
PowerShell -NoProfile -Command "Set-ProcessMitigation -System -Enable DEP, EmulateAtlThunks"
bcdedit /set nx Optin
:: enable cfg for valorant related processes
for %%i in (valorant valorant-win64-shipping vgtray vgc) do (
    PowerShell -NoProfile -Command "Set-ProcessMitigation -Name %%i.exe -Enable CFG"
)
if %ERRORLEVEL%==0 echo %date% - %time% DEP enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:depD
echo If you get issues with some anti-cheats, please re-enable DEP.
PowerShell -NoProfile -Command "Set-ProcessMitigation -System -Disable DEP, EmulateAtlThunks"
bcdedit /set nx AlwaysOff
if %ERRORLEVEL%==0 echo %date% - %time% DEP disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:SearchStart
IF EXIST "C:\Program Files\Open-Shell" goto existS
IF EXIST "C:\Program Files (x86)\StartIsBack" goto existS
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the Start Menu being removed.
pause

:existS
set /P c=This will disable SearchApp and StartMenuExperienceHost, are you sure you want to continue [Y/N]?
if /I "%c%" EQU "Y" goto continSS
if /I "%c%" EQU "N" exit

:continSS
:: rename start menu
chdir /d %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy

:restartStart
taskkill /f /im StartMenuExperienceHost*
ren StartMenuExperienceHost.exe StartMenuExperienceHost.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto restartStart

:: rename search
chdir /d %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy

:restartSearch
taskkill /f /im SearchApp*  > nul 2>nul
ren SearchApp.exe SearchApp.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto restartSearch

:: search icon
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:enableStart
:: rename start menu
chdir /d %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
ren StartMenuExperienceHost.old StartMenuExperienceHost.exe

:: rename search
chdir /d %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy
ren SearchApp.old SearchApp.exe

:: search icon
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:openshellInstall
curl -L --output %WinDir%\AtlasModules\Open-Shell.exe https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.182/OpenShellSetup_4_4_182.exe
IF EXIST "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" goto existOS
IF EXIST "%WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" goto existOS
goto rmSSOS

:existOS
set /P c=It appears search and start are installed, would you like to disable them also? [Y/N]?
if /I "%c%" EQU "Y" goto rmSSOS
if /I "%c%" EQU "N" goto skipRM

:rmSSOS
:: rename start menu
chdir /d %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy

:OSrestartStart
taskkill /f /im StartMenuExperienceHost*
ren StartMenuExperienceHost.exe StartMenuExperienceHost.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto OSrestartStart

:: rename search
chdir /d %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy

:OSrestartSearch
taskkill /f /im SearchApp*  > nul 2>nul
ren SearchApp.exe SearchApp.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto OSrestartSearch

:: search icon
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu removed...>> %WinDir%\AtlasModules\logs\userScript.log

:skipRM
:: install silently
echo]
echo Open-Shell is installing...
"Open-Shell.exe" /qn ADDLOCAL=StartMenu
curl -L https://github.com/bonzibudd/Fluent-Metro/releases/download/v1.5.3/Fluent-Metro_1.5.3.zip -o skin.zip
7z.exe -aoa -r e "skin.zip" -o"C:\Program Files\Open-Shell\Skins"
del /F /Q skin.zip > nul 2>nul
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Open-Shell installed...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:uwp
IF EXIST "C:\Program Files\Open-Shell" goto uwpD
IF EXIST "C:\Program Files (x86)\StartIsBack" goto uwpD
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the startmenu being removed.
pause & exit
:uwpD
echo This will remove all UWP packages that are currently installed. This will break multiple features that WILL NOT be supported while disabled.
echo A reminder of a few things this may break.
echo - Searching in file explorer
echo - Microsoft Store
echo - Xbox app
echo - Immersive control panel (Settings app)
echo - Adobe XD
echo - Start context menu
echo - Wi-Fi menu
echo - Microsoft accounts
echo Please PROCEED WITH CAUTION, you are doing this at your own risk.
pause

:: detect if user is using a microsoft account
PowerShell -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" > nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( sc config wlidsvc start=disabled ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )
choice /c yn /m "Last warning, continue? [Y/N]" /n
sc stop TabletInputService
sc config TabletInputService start=disabled

:: disable the option for microsoft store in the "open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f

:: block access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
sc config InstallService start=disabled

:: insufficent permissions to disable
%setSvc% WinHttpAutoProxySvc 4
sc config mpssvc start=disabled
sc config AppXSvc start=disabled
sc config BFE start=disabled
sc config TokenBroker start=disabled
sc config LicenseManager start=disabled
sc config ClipSVC start=disabled

taskkill /f /im StartMenuExperienceHost*  > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old
taskkill /f /im SearchApp*  > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy Microsoft.Windows.Search_cw5n1h2txyewy.old
ren %WinDir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old
ren %WinDir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old

taskkill /f /im RuntimeBroker*  > nul 2>nul
ren %WinDir%\System32\RuntimeBroker.exe RuntimeBroker.exe.old
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% UWP disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish
pause

:uwpE
sc config TabletInputService start=demand
:: disable the option for microsoft store in the "open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f

:: block access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
sc config InstallService start=demand

:: insufficent permissions to disable
%setSvc% WinHttpAutoProxySvc 3
sc config mpssvc start=auto
sc config wlidsvc start=demand
sc config AppXSvc start=demand
sc config BFE start=auto
sc config TokenBroker start=demand
sc config LicenseManager start=demand
sc config ClipSVC start=demand

taskkill /f /im StartMenuExperienceHost*  > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
taskkill /f /im SearchApp*  > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy.old Microsoft.Windows.Search_cw5n1h2txyewy
ren %WinDir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old Microsoft.XboxGameCallableUI_cw5n1h2txyewy
ren %WinDir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe
taskkill /f /im RuntimeBroker*  > nul 2>nul
ren %WinDir%\System32\RuntimeBroker.exe.old RuntimeBroker.exe
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% UWP enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:mitE
PowerShell -NoProfile -Command "Set-ProcessMitigation -System -Enable DEP, EmulateAtlThunks, RequireInfo, BottomUp, HighEntropy, StrictHandle, CFG, StrictCFG, SuppressExports, SEHOP, AuditSEHOP, SEHOPTelemetry, ForceRelocateImages"
goto finish

:startlayout
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f > nul 2>nul
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f > nul 2>nul
%currentuser% reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /f > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Start Menu layout policy removed...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:sleepD
:: disable away mode policy
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0

:: disable idle states
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0

:: disable hybrid sleep
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Sleep States disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:sleepE
:: enable away mode policy
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1

:: enable idle states
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1

:: enable hybrid sleep
powercfg /setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
powercfg /setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Sleep States enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:idleD
echo THIS WILL CAUSE YOUR CPU USAGE TO *DISPLAY* AS 100% IN TASK MANAGER. ENABLE IDLE IF THIS IS AN ISSUE.
powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Idle disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:idleE
powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 0
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Idle enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:harden
:: LARGELY based on https://gist.github.com/ricardojba/ecdfe30dadbdab6c514a530bc5d51ef6
:: to do:
:: - make it extremely clear that this is not aimed to maintain performance

:: - harden process mitigations (lower compatibilty for legacy apps)
PowerShell -NoProfile -Command "Set-ProcessMitigation -System -Enable DEP, EmulateAtlThunks, RequireInfo, BottomUp, HighEntropy, StrictHandle, CFG, StrictCFG, SuppressExports, SEHOP, AuditSEHOP, SEHOPTelemetry, ForceRelocateImages"
:: - open scripts in notepad to preview instead of executing when clicking
for %%a in (
    "batfile"
    "chmfile"
    "cmdfile"
    "htafile"
    "jsefile"
    "jsfile"
    "regfile"
    "sctfile"
    "urlfile"
    "vbefile"
    "vbsfile"
    "wscfile"
    "wsffile"
    "wsfile"
    "wshfile"
) do (
    ftype %%a="%WinDir%\System32\notepad.exe" "%1"
)

:: - ElamDrivers?
:: - block unsigned processes running from USBS
:: - Kerebos Hardening
:: - UAC Enable

:: Firewall rules
netsh Advfirewall set allprofiles state on
%firewallBlockExe% "calc.exe" "%WinDir%\System32\calc.exe"
%firewallBlockExe% "certutil.exe" "%WinDir%\System32\certutil.exe"
%firewallBlockExe% "cmstp.exe" "%WinDir%\System32\cmstp.exe"
%firewallBlockExe% "cscript.exe" "%WinDir%\System32\cscript.exe"
%firewallBlockExe% "esentutl.exe" "%WinDir%\System32\esentutl.exe"
%firewallBlockExe% "expand.exe" "%WinDir%\System32\expand.exe"
%firewallBlockExe% "extrac32.exe" "%WinDir%\System32\extrac32.exe"
%firewallBlockExe% "findstr.exe" "%WinDir%\System32\findstr.exe"
%firewallBlockExe% "hh.exe" "%WinDir%\System32\hh.exe"
%firewallBlockExe% "makecab.exe" "%WinDir%\System32\makecab.exe"
%firewallBlockExe% "mshta.exe" "%WinDir%\System32\mshta.exe"
%firewallBlockExe% "msiexec.exe" "%WinDir%\System32\msiexec.exe"
%firewallBlockExe% "nltest.exe" "%WinDir%\System32\nltest.exe"
%firewallBlockExe% "Notepad.exe" "%WinDir%\System32\notepad.exe"
%firewallBlockExe% "pcalua.exe" "%WinDir%\System32\pcalua.exe"
%firewallBlockExe% "print.exe" "%WinDir%\System32\print.exe"
%firewallBlockExe% "regsvr32.exe" "%WinDir%\System32\regsvr32.exe"
%firewallBlockExe% "replace.exe" "%WinDir%\System32\replace.exe"
%firewallBlockExe% "rundll32.exe" "%WinDir%\System32\rundll32.exe"
%firewallBlockExe% "runscripthelper.exe" "%WinDir%\System32\runscripthelper.exe"
%firewallBlockExe% "scriptrunner.exe" "%WinDir%\System32\scriptrunner.exe"
%firewallBlockExe% "SyncAppvPublishingServer.exe" "%WinDir%\System32\SyncAppvPublishingServer.exe"
%firewallBlockExe% "wmic.exe" "%WinDir%\System32\wbem\wmic.exe"
%firewallBlockExe% "wscript.exe" "%WinDir%\System32\wscript.exe"
%firewallBlockExe% "regasm.exe" "%WinDir%\System32\regasm.exe"
%firewallBlockExe% "odbcconf.exe" "%WinDir%\System32\odbcconf.exe"

%firewallBlockExe% "regasm.exe" "%WinDir%\SysWOW64\regasm.exe"
%firewallBlockExe% "odbcconf.exe" "%WinDir%\SysWOW64\odbcconf.exe"
%firewallBlockExe% "calc.exe" "%WinDir%\SysWOW64\calc.exe"
%firewallBlockExe% "certutil.exe" "%WinDir%\SysWOW64\certutil.exe"
%firewallBlockExe% "cmstp.exe" "%WinDir%\SysWOW64\cmstp.exe"
%firewallBlockExe% "cscript.exe" "%WinDir%\SysWOW64\cscript.exe"
%firewallBlockExe% "esentutl.exe" "%WinDir%\SysWOW64\esentutl.exe"
%firewallBlockExe% "expand.exe" "%WinDir%\SysWOW64\expand.exe"
%firewallBlockExe% "extrac32.exe" "%WinDir%\SysWOW64\extrac32.exe"
%firewallBlockExe% "findstr.exe" "%WinDir%\SysWOW64\findstr.exe"
%firewallBlockExe% "hh.exe" "%WinDir%\SysWOW64\hh.exe"
%firewallBlockExe% "makecab.exe" "%WinDir%\SysWOW64\makecab.exe"
%firewallBlockExe% "mshta.exe" "%WinDir%\SysWOW64\mshta.exe"
%firewallBlockExe% "msiexec.exe" "%WinDir%\SysWOW64\msiexec.exe"
%firewallBlockExe% "nltest.exe" "%WinDir%\SysWOW64\nltest.exe"
%firewallBlockExe% "Notepad.exe" "%WinDir%\SysWOW64\notepad.exe"
%firewallBlockExe% "pcalua.exe" "%WinDir%\SysWOW64\pcalua.exe"
%firewallBlockExe% "print.exe" "%WinDir%\SysWOW64\print.exe"
%firewallBlockExe% "regsvr32.exe" "%WinDir%\SysWOW64\regsvr32.exe"
%firewallBlockExe% "replace.exe" "%WinDir%\SysWOW64\replace.exe"
%firewallBlockExe% "rpcping.exe" "%WinDir%\SysWOW64\rpcping.exe"
%firewallBlockExe% "rundll32.exe" "%WinDir%\SysWOW64\rundll32.exe"
%firewallBlockExe% "runscripthelper.exe" "%WinDir%\SysWOW64\runscripthelper.exe"
%firewallBlockExe% "scriptrunner.exe" "%WinDir%\SysWOW64\scriptrunner.exe"
%firewallBlockExe% "SyncAppvPublishingServer.exe" "%WinDir%\SysWOW64\SyncAppvPublishingServer.exe"
%firewallBlockExe% "wmic.exe" "%WinDir%\SysWOW64\wbem\wmic.exe"
%firewallBlockExe% "wscript.exe" "%WinDir%\SysWOW64\wscript.exe"

:: disable TsX to mitigate zombieload
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f

:: - static arp entry

:: lsass hardening
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\lsass.exe" /v "AuditLevel" /t REG_DWORD /d "8" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" /v "AllowProtectedCreds" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "DisableRestrictedAdminOutboundCreds" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "DisableRestrictedAdmin" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RunAsPPL" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v "Negotiate" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v "UseLogonCredential" /t REG_DWORD /d "0" /f

:procexpD
if exist "%WinDir%\procexp.exe" del /f /q "%WinDir%\procexp.exe" > nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /f > nul 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pcw" /v "Start" /t REG_DWORD /d "0" /f
goto finish

:procexpE
if not exist "%WinDir%\procexp.exe" copy "%WinDir%\AtlasModules\procexp.exe" "%WinDir%"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "%WinDir%\procexp.exe" /f
goto finish

:xboxU
set /P c=This is IRREVERSIBLE (A reinstall is required to restore these components), continue? [Y/N]
if /I "%c%" EQU "N" exit
if /I "%c%" EQU "Y" goto :xboxConfirm
exit

:xboxConfirm
echo Removing via PowerShell...
NSudo.exe -U:C -ShowWindowMode:Hide -Wait PowerShell -NoProfile -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage" > nul 2>nul

echo Disabling services...
sc config XblAuthManager start=disabled
sc config XblGameSave start=disabled
sc config XboxGipSvc start=disabled
sc config XboxNetApiSvc start=disabled
%setSvc% BcastDVRUserService 4
if %ERRORLEVEL%==0 echo %date% - %time% Xbox related apps and services removed...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:vcreR
echo Uninstalling Visual C++ Runtimes...
%WinDir%\AtlasModules\vcredist.exe /aiR
echo Finished uninstalling!
echo]
echo Opening Visual C++ Runtimes installer, simply click next.
%WinDir%\AtlasModules\vcredist.exe
echo Installation Finished or Cancelled.
if %ERRORLEVEL%==0 echo %date% - %time% Visual C++ Runtimes reinstalled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:uacD
echo Disabling UAC breaks fullscreen on certain UWP applications, one of them being Minecraft Windows 10 Edition.
echo It may also break drag and dropping between certain applications.
echo It is also less secure to disable UAC, as every application you run has complete access to your computer.
echo]
echo With UAC disabled, everything runs as admin, and you can not change that without enabling UAC.
echo]
choice /c:yn /n /m "Do you want to continue? [Y/N] "
if %errorlevel%==1 goto uacDconfirm
if %errorlevel%==2 exit 1

:uacDconfirm
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "0" /f > nul
:: lock UserAccountControlSettings.exe - users can enable UAC from there without luafv and appinfo enabled, which breaks UAC completely and causes issues
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /t REG_SZ /d "C:\Windows\AtlasModules\atlas-config.bat /uacSettings /skipAdminCheck" /f > nul
%setSvc% luafv 4
%setSvc% Appinfo 4
if %ERRORLEVEL%==0 echo %date% - %time% UAC disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:uacE
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "5" /f > nul
:: unlock UserAccountControlSettings.exe
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /f > nul 2>nul
%setSvc% luafv 2
%setSvc% Appinfo 3
if %ERRORLEVEL%==0 echo %date% - %time% UAC enabled...>> %WinDir%\AtlasModules\logs\userScript.log
echo Note: The regular Windows UAC settings have now been unlocked, as this script enabled the required services for UAC.
echo]
goto finish

:uacSettings
mode con:cols=46 lines=14
chcp 65001 >nul
echo]
echo [32m                 Enabling UAC
echo   ──────────────────────────────────────────[0m
echo   Atlas disables some services that are
echo   needed for UAC to work, and enabling UAC
echo   through the typical UAC settings will
echo   cause issues.
echo]
echo   You [1mneed to enable UAC using the Atlas
echo   script[0m to unlock the typical UAC
echo   configuration panel.
echo]
echo         [1m[33mPress any key to enable UAC...      [?25l
pause > nul
NSudo.exe -U:T -P:E -UseCurrentConsole -Wait %WinDir%\AtlasModules\atlas-config.bat /uacE
exit

:firewallD
%setSvc% mpssvc 4
%setSvc% BFE 4
if %ERRORLEVEL%==0 echo %date% - %time% Firewall disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:firewallE
%setSvc% mpssvc 2
%setSvc% BFE 2
if %ERRORLEVEL%==0 echo %date% - %time% Firewall enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:aniE
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /f > nul 2>nul
%currentuser% reg delete "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /f > nul 2>nul
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9e3e078012000000" /f
if %ERRORLEVEL%==0 echo %date% - %time% Animations enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:aniD
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f
if %ERRORLEVEL%==0 echo %date% - %time% Animations disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:workstationD
%setSvc% rdbss 4
%setSvc% KSecPkg 4
%setSvc% mrxsmb20 4
%setSvc% mrxsmb 4
%setSvc% srv2 4
%setSvc% LanmanWorkstation 4
DISM /Online /Disable-Feature /FeatureName:SmbDirect /norestart
if %ERRORLEVEL%==0 echo %date% - %time% Workstation disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:workstationE
%setSvc% rdbss 3
%setSvc% KSecPkg 0
%setSvc% mrxsmb20 3
%setSvc% mrxsmb 3
%setSvc% srv2 3
%setSvc% LanmanWorkstation 2
DISM /Online /Enable-Feature /FeatureName:SmbDirect /norestart
if %ERRORLEVEL%==0 echo %date% - %time% Workstation enabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:printE
echo You may be vulnerable to Print Nightmare Exploits while printing is enabled. 
set /P c=Would you like to add Group Policies to protect against them? [Y/N]
if /I "%c%" EQU "Y" goto nightmareGPO
if /I "%c%" EQU "N" goto printECont
goto nightmareGPO

:nightmareGPO
echo The spooler will not accept client connections nor allow users to share printers.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /t REG_DWORD /d "2" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "Restricted" /t REG_DWORD /d "1" /f

:: prevent print drivers over HTTP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d "1" /f

:: disable printing over HTTP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d "1" /f

:printECont
%setSvc% Spooler 2
if %ERRORLEVEL%==0 echo %date% - %time% Printing enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish
:printD
%setSvc% Spooler 4
if %ERRORLEVEL%==0 echo %date% - %time% Printing disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:netWinDefault
netsh int ip reset
netsh winsock reset
:: extremely awful way to do this
for /f "tokens=3* delims=: " %%i in ('pnputil /enum-devices /class Net /connected ^| findstr "Device Description:"') do (
	DevManView.exe /uninstall "%%i %%j"
)
pnputil /scan-devices
if %ERRORLEVEL%==0 echo %date% - %time% Network setting reset to Windows' default...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:netAtlasDefault
:: disable nagle's algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%i in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: set default power saving mode for all network cards to disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "DefaultPnPCapabilities" /t REG_DWORD /d "24" /f

:: configure nic settings
:: modified by Xyueta
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    for %%b in (
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
        for /f %%c in ('reg query "%%a" /v "%%b" ^| findstr "HKEY"') do (
            reg add "%%c" /v "%%b" /t REG_SZ /d "0" /f
        )
    )
)

:: configure netsh settings
netsh int tcp set heuristics=disabled
netsh int tcp set supplemental Internet congestionprovider=ctcp
netsh int tcp set global rsc=disabled
for /f "tokens=1" %%i in ('netsh int ip show interfaces ^| findstr [0-9]') do (
	netsh int ip set interface %%i routerdiscovery=disabled store=persistent
)
if %ERRORLEVEL%==0 echo %date% - %time% Network settings reset to Atlas default...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:debugProfile
systeminfo > %WinDir%\AtlasModules\logs\systemInfo.log
goto finish

:vpnD
DevManView.exe /disable "WAN Miniport (IKEv2)"
DevManView.exe /disable "WAN Miniport (IP)"
DevManView.exe /disable "WAN Miniport (IPv6)"
DevManView.exe /disable "WAN Miniport (L2TP)"
DevManView.exe /disable "WAN Miniport (Network Monitor)"
DevManView.exe /disable "WAN Miniport (PPPOE)"
DevManView.exe /disable "WAN Miniport (PPTP)"
DevManView.exe /disable "WAN Miniport (SSTP)"
DevManView.exe /disable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /disable "Microsoft RRAS Root Enumerator"
%setSvc% IKEEXT 4
%setSvc% WinHttpAutoProxySvc 4
%setSvc% RasMan 4
%setSvc% SstpSvc 4
%setSvc% iphlpsvc 4
%setSvc% NdisVirtualBus 4
%setSvc% Eaphost 4
if %ERRORLEVEL%==0 echo %date% - %time% VPN disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:vpnE
DevManView.exe /enable "WAN Miniport (IKEv2)"
DevManView.exe /enable "WAN Miniport (IP)"
DevManView.exe /enable "WAN Miniport (IPv6)"
DevManView.exe /enable "WAN Miniport (L2TP)"
DevManView.exe /enable "WAN Miniport (Network Monitor)"
DevManView.exe /enable "WAN Miniport (PPPOE)"
DevManView.exe /enable "WAN Miniport (PPTP)"
DevManView.exe /enable "WAN Miniport (SSTP)"
DevManView.exe /enable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /enable "Microsoft RRAS Root Enumerator"
%setSvc% IKEEXT 3
%setSvc% BFE 2
%setSvc% WinHttpAutoProxySvc 3
%setSvc% RasMan 3
%setSvc% SstpSvc 3
%setSvc% iphlpsvc 3
%setSvc% NdisVirtualBus 3
%setSvc% Eaphost 3
if %ERRORLEVEL%==0 echo %date% - %time% VPN enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:wmpD
DISM /Online /Disable-Feature /FeatureName:WindowsMediaPlayer /norestart
goto finish

:ieD
DISM /Online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /norestart
goto finish

:eventlogD
echo This may break some features:
echo - CapFrameX
echo - Network menu/icon
echo If you experience random issues, please enable Event Log again.
sc config EventLog start=disabled
if %ERRORLEVEL%==0 echo %date% - %time% Event Log disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:eventlogE
sc config EventLog start=auto
if %ERRORLEVEL%==0 echo %date% - %time% Event Log enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:scheduleD
echo Disabling Task Scheduler will break some features:
echo - MSI Afterburner startup/updates
echo - UWP typing (e.g. Search bar)
sc config Schedule start=disabled
if %ERRORLEVEL%==0 echo %date% - %time% Task Scheduler disabled...>> %WinDir%\AtlasModules\logs\userScript.log
echo If you experience random issues, please enable Task Scheduler again.
goto finish

:scheduleE
sc config Schedule start=auto
if %ERRORLEVEL%==0 echo %date% - %time% Task Scheduler enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:scoop
echo Installing Scoop...
set /P c="Review install script before executing? [Y/N]: "
if /I "%c%" EQU "Y" curl "https://raw.githubusercontent.com/ScoopInstaller/install/master/install.ps1" -o %WinDir%\AtlasModules\install.ps1 && notepad %WinDir%\AtlasModules\install.ps1
if /I "%c%" EQU "N" curl "https://raw.githubusercontent.com/ScoopInstaller/install/master/install.ps1" -o %WinDir%\AtlasModules\install.ps1
PowerShell -NoProfile -Command "%WinDir%\AtlasModules\install.ps1 -RunAsAdmin"
echo Refreshing environment for Scoop...
call %WinDir%\AtlasModules\refreshenv.bat
echo]
echo Installing git...
:: using scoop install in batch file requires script re-run
:: otherwise it will break the whole script if a warning or error shows up
cmd /c scoop install git -g
call %WinDir%\AtlasModules\refreshenv.bat
echo .
echo Adding extras and games bucket...
cmd /c scoop bucket add extras
cmd /c scoop bucket add games
echo If this did not install Scoop, instead you can try installing via the install guide: https://scoop.sh
goto finish

:choco
echo Installing Chocolatey
set /P c="Review install script before executing? [Y/N]: "
if /I "%c%" EQU "Y" curl "https://community.chocolatey.org/install.ps1" -o %WinDir%\AtlasModules\install.ps1 && notepad %WinDir%\AtlasModules\install.ps1
if /I "%c%" EQU "N" curl "https://community.chocolatey.org/install.ps1" -o %WinDir%\AtlasModules\install.ps1
PowerShell -NoProfile -Command "%WinDir%\AtlasModules\install.ps1"
echo Refreshing environment for Chocolatey...
call %WinDir%\AtlasModules\refreshenv.bat
echo]
echo Installing git...
cmd /c choco install git
call %WinDir%\AtlasModules\refreshenv.bat
echo If this did not install Chocolatey, instead you can try installing via the install guide: https://chocolatey.org/install
goto finish

:altSoftwarescoop
for /f "tokens=*" %%i in ('%WinDir%\AtlasModules\multichoice.exe "Common Software" "Install Common Software" "discord;webcord;czkawka-gui;bleachbit;notepadplusplus;onlyoffice-desktopeditors;libreoffice;geekuninstaller;bitwarden;keepassxc;sharex;qbittorrent;everything;msiafterburner;rtss;thunderbird;foobar2000;irfanview;nomacs;git;mpv;mpv-git;vlc;vscode;putty;ditto;heroic-games-launcher;playnite;legendary"') do (
	set spacedelimited=%%i
	set spacedelimited=!spacedelimited:;= !
	cmd /c scoop install !spacedelimited! -g
)
goto finish

:altSoftwarechoco
for /f "tokens=*" %%i in ('%WinDir%\AtlasModules\multichoice.exe "Common Software" "Install Common Software" "discord;discord-canary;steam;steamcmd;playnite;bleachbit;notepadplusplus;msiafterburner;thunderbird;foobar2000;irfanview;git;mpv;vlc;vscode;putty;ditto;7zip"') do (
	set spacedelimited=%%i
	set spacedelimited=!spacedelimited:;= !
	cmd /c choco install !spacedelimited!
)
goto finish

:scoopCache
echo Removing cache from Scoop...
scoop cache rm *
goto finish

:staticIP
call :netcheck
set /P dns1="Set DNS Server (e.g. 1.1.1.1): "
for /f "tokens=4" %%i in ('netsh int show interface ^| find "Connected"') do set devicename=%%i
:: for /f "tokens=2 delims=[]" %%i in ('ping -4 -n 1 %ComputerName% ^| findstr [') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name^="%devicename%" ^| findstr "IP Address:"') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name^="%devicename%" ^| findstr "Default Gateway:"') do set DHCPGateway=%%i
for /f "tokens=2 delims=()" %%i in ('netsh int ip show config name^="Ethernet" ^| findstr "Subnet Prefix:"') do for /f "tokens=2" %%a in ("%%i") do set DHCPSubnetMask=%%a
netsh int ipv4 set address name="%devicename%" static %LocalIP% %DHCPSubnetMask% %DHCPGateway%
PowerShell -NoProfile -Command "Set-DnsClientServerAddress -InterfaceAlias "%devicename%" -ServerAddresses %dns1%"
echo %date% - %time% Static IP set! (%LocalIP%)(%DHCPGateway%)(%DHCPSubnetMask%) >> %WinDir%\AtlasModules\logs\userScript.log

echo Private IP: %LocalIP%
echo Gateway: %DHCPGateway%
echo Subnet Mask: %DHCPSubnetMask%
echo If this information appears to be incorrect or is blank, please report it on Discord (preferred) or Github.
goto finish
:: %setSvc% Dhcp 4
:: %setSvc% NlaSvc 4
:: %setSvc% netprofm 4

:displayScalingD
for /f %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /s /f "Scaling" ^| find /i "Configuration\"') do (
	reg add "%%i" /v "Scaling" /t REG_DWORD /d "1" /f
)
if %ERRORLEVEL%==0 echo %date% - %time% Display Scaling disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:DSCPauto
for /f "tokens=* delims=\" %%i in ('%WinDir%\AtlasModules\filepicker.exe exe') do (
    if "%%i"=="cancelled by user" exit
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Application Name" /t REG_SZ /d "%%~ni%%~xi" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Version" /t REG_SZ /d "1.0" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Protocol" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local Port" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local IP" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote Port" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote IP" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "DSCP Value" /t REG_SZ /d "46" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Throttle Rate" /t REG_SZ /d "-1" /f
)
goto finish

:NVPstate
:: credits to timecard
:: https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if errorlevel 1 (
    echo You do not have NVIDIA GPU drivers installed.
    pause
    exit /B
)
echo This will force P0 on your NVIDIA card AT ALL TIMES, it will always run at full power.
echo It is not recommended if you leave your computer on while idle, have bad cooling or use a laptop.
pause

for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg add "%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f
)
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Dynamic P-States disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:revertNVPState
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg delete "%%i" /v "DisableDynamicPstate" /f > nul 2>nul
)
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Dynamic P-States enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hdcpD
:: credits to timecard
:: https://github.com/djdallmann/GamingPCSetup/blob/master/CONTENT/RESEARCH/WINDRIVERS/README.md#q-are-there-any-configuration-options-that-allow-you-to-disable-hdcp-when-using-nvidia-based-graphics-cards
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if errorlevel 1 (
    echo You do not have NVIDIA GPU drivers installed.
    pause
    exit /B
)

for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg add "%%i" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f
)

if %ERRORLEVEL%==0 echo %date% - %time% HDCP disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hdcpE
:: credits to timecard
:: https://github.com/djdallmann/GamingPCSetup/blob/master/CONTENT/RESEARCH/WINDRIVERS/README.md#q-are-there-any-configuration-options-that-allow-you-to-disable-hdcp-when-using-nvidia-based-graphics-cards
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if errorlevel 1 (
    echo You do not have NVIDIA GPU drivers installed.
    pause
    exit /B
)

for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg add "%%i" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "0" /f
)

if %ERRORLEVEL%==0 echo %date% - %time% HDCP enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:nvcontainerD
:: check if the service exists
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %errorlevel%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)

echo Disabling the 'NVIDIA Display Container LS' service will stop the NVIDIA Control Panel from working.
echo It will most likely break other NVIDIA driver features as well.
echo These scripts are aimed at users that have a stripped driver, and people that barely touch the NVIDIA Control Panel.
echo]
echo You can enable the NVIDIA Control Panel and the service again by running the enable script.
echo Additionally, you can add a context menu to the desktop with another script in the Atlas folder.
echo]
echo Read README.txt for more info.
pause

sc config NVDisplay.ContainerLocalSystem start=disabled > nul
sc stop NVDisplay.ContainerLocalSystem > nul
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:nvcontainerE
:: check if the service exists
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)

sc config NVDisplay.ContainerLocalSystem start=auto > nul
sc start NVDisplay.ContainerLocalSystem > nul
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:nvcontainerCME
:: cm = context menu
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %errorlevel%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)
echo Explorer will be restarted to ensure that the context menu works.
pause

reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Icon" /t REG_SZ /d "%WinDir%\AtlasModules\NVIDIA.ico,0" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "MUIVerb" /t REG_SZ /d "NVIDIA Container" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Position" /t REG_SZ /d "Bottom" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "SubCommands" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "MUIVerb" /t REG_SZ /d "Enable NVIDIA Display Container LS" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001\command" /ve /t REG_SZ /d "%WinDir%\AtlasModules\NSudo.exe -U:T -P:E -UseCurrentConsole -Wait %WinDir%\AtlasModules\atlas-config.bat /nvcontainerE" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "MUIVerb" /t REG_SZ /d "Disable NVIDIA Display Container LS" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002\command" /ve /t REG_SZ /d "%WinDir%\AtlasModules\NSudo.exe -U:T -P:E -UseCurrentConsole -Wait %WinDir%\AtlasModules\atlas-config.bat /nvcontainerD" /f
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS context menu enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:nvcontainerCMD
:: cm = context menu
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)
reg query "HKCR\DesktopBackground\shell\NVIDIAContainer" > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The context menu does not exist, you can not continue.
    pause
    exit /b 1
)

echo Explorer will be restarted to ensure that the context menu is removed.
pause

reg delete "HKCR\DesktopBackground\Shell\NVIDIAContainer" /f > nul 2>nul

:: delete icon exe
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS context menu disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:networksharingE
echo Enabling Workstation as a dependency...
call :workstationE "int"
sc config eventlog start=auto
echo %date% - %time% EventLog enabled as Network Sharing dependency...>> %WinDir%\AtlasModules\logs\userscript.log
%setSvc% NlaSvc 2
%setSvc% lmhosts 3
%setSvc% netman 3
echo %date% - %time% Network Sharing enabled...>> %WinDir%\AtlasModules\logs\userscript.log
echo To complete, enable Network Sharing in control panel.
goto finish

:diagD
%setSvc% DPS 4
%setSvc% WdiServiceHost 4
%setSvc% WdiSystemHost 4
echo %date% - %time% Diagnotics disabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:diagE
%setSvc% DPS 2
%setSvc% WdiServiceHost 3
%setSvc% WdiSystemHost 3
echo %date% - %time% Diagnotics enabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:safeE
bcdedit /deletevalue {current} safeboot
bcdedit /deletevalue {current} safebootalternateshell
echo %date% - %time% Exit safe mode...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:safeC
bcdedit /set {current} safeboot minimal
bcdedit /set {current} safebootalternateshell yes
echo %date% - %time% Safe mode with command prompt enabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:safeN
bcdedit /set {current} safeboot network
echo %date% - %time% Safe mode with networking enabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:safe
bcdedit /set {current} safeboot minimal
echo %date% - %time% Safe mode enabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto finish

:: Batch Functions

:invalidInput <label>
if "%c%"=="" echo Empty input! Please enter Y or N. & goto %~1
if "%c%" NEQ "Y" if "%c%" NEQ "N" echo Invalid input! Please enter Y or N. & goto %~1
goto :EOF

:netcheck
ping -n 1 -4 1.1.1.1 | find "time=" > nul 2>nul || (
    echo Network is not connected! Please connect to a network before continuing.
	pause
	goto netcheck
) > nul 2>nul
goto :EOF

:FDel <location>
:: with NSudo, should not need things like icacls/takeown
if exist "%~1" del /F /Q "%~1"
goto :EOF

:setSvc
:: example: %setSvc% AppInfo 4
:: last argument is the startup type: 0, 1, 2, 3, 4, 5
if [%~1]==[] (echo You need to run this with a service/driver to disable. & exit /b 1)
if [%~2]==[] (echo You need to run this with an argument ^(1-5^) to configure the service's startup. & exit /b 1)
if %~2 LSS 0 (echo Invalid start value ^(%~2^) for %~1. & exit /b 1)
if %~2 GTR 5 (echo Invalid start value ^(%~2^) for %~1. & exit /b 1)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" > nul 2>&1 || (echo The specified service/driver ^(%~1^) is not found. & exit /b 1)
if "%system%"=="false" (
	if not "%setSvcWarning%"=="false" (
		echo WARNING: Not running as System, could fail modifying some services/drivers with an access denied error.
	)
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f > nul || (
	if "%system%"=="false" (echo Failed to set service %~1 with start value %~2! Not running as System, access denied?) else (
	echo Failed to set service %~1 with start value %~2! Unknown error.)
)
exit /b 0

:firewallBlockExe
:: usage: %fireBlockExe% "[NAME]" "[EXE]"
:: example: %fireBlockExe% "Calculator" "%WinDir%\System32\calc.exe"
:: have both in quotes

:: get rid of any old rules (prevents duplicates)
netsh advfirewall firewall delete rule name="Block %~1" protocol=any dir=in > nul 2>&1
netsh advfirewall firewall delete rule name="Block %~1" protocol=any dir=out > nul 2>&1
netsh advfirewall firewall add rule name="Block %~1" program=%2 protocol=any dir=in enable=yes action=block profile=any > nul
netsh advfirewall firewall add rule name="Block %~1" program=%2 protocol=any dir=out enable=yes action=block profile=any > nul
exit /b

:permFAIL
	echo Permission grants failed. Please try again by launching the script through the respected scripts, which will give it the correct permissions.
	pause & exit
:finish
	echo Finished, please reboot for changes to apply.
	pause & exit
:finishNRB
	echo Finished, changes have been applied.
	pause & exit
