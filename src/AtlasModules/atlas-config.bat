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
set branch="20H2"
set ver="v0.5.2"

:: other variables (do not touch)
set "currentuser=%WinDir%\AtlasModules\NSudo.exe -U:C -P:E -Wait"
set "setSvc=call :setSvc"
set "firewallBlockExe=call :firewallBlockExe"

:: check for administrator privileges
fltmc >nul 2>&1 || (
    goto permFAIL
)

:: check for trusted installer priviliges
whoami /user | find /i "S-1-5-18" >nul 2>&1
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

:: Microsoft Store
if /i "%~1"=="/ds"         goto storeD
if /i "%~1"=="/es"         goto storeE

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

:: Idle
if /i "%~1"=="/idled"          goto idleD
if /i "%~1"=="/idlee"          goto idleE

:: Xbox
if /i "%~1"=="/xboxU"         goto xboxU

:: Reinstall VC++ Redistributables
if /i "%~1"=="/vcreR"         goto vcreR

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

:: Clipboard History Service (also required for Snip and Sketch to copy correctly)
if /i "%~1"=="/cbdhsvcD"    goto cbdhsvcD
if /i "%~1"=="/cbdhsvcE"    goto cbdhsvcE

:: VPN
if /i "%~1"=="/vpnD"    goto vpnD
if /i "%~1"=="/vpnE"    goto vpnE

:: Scoop and Chocolatey
if /i "%~1"=="/scoop" goto scoop
if /i "%~1"=="/choco" goto choco
if /i "%~1"=="/browserscoop" goto browserscoop
if /i "%~1"=="/altsoftwarescoop" goto altSoftwarescoop
if /i "%~1"=="/browserchoco" goto browserchoco
if /i "%~1"=="/altsoftwarechoco" goto altSoftwarechoco

:: NVIDIA P-State 0
if /i "%~1"=="/nvpstateD" goto NVPstate
if /i "%~1"=="/nvpstateE" goto revertNVPState

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

:: debugging purposes only
if /i "%~1"=="/test"         goto TestPrompt

:argumentFAIL
echo atlas-config had no arguements passed to it, either you are launching atlas-config directly or the "%~nx0" script is broken.
echo Please report this to the Atlas Discord or Github.
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
setx path "%path%;%WinDir%\AtlasModules;" -m  >nul 2>nul
IF %ERRORLEVEL%==0 (echo %date% - %time% Atlas Modules path set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set Atlas Modules path! >> %WinDir%\AtlasModules\logs\install.log)

:: breaks setting keyboard language
:: Rundll32.exe advapi32.dll,ProcessIdleTasks
break > C:\Users\Public\success.txt
echo false > C:\Users\Public\success.txt

:auto
SETLOCAL EnableDelayedExpansion
%WinDir%\AtlasModules\vcredist.exe /ai
if %ERRORLEVEL%==0 (echo %date% - %time% Visual C++ Runtimes installed...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to install Visual C++ Runtimes! >> %WinDir%\AtlasModules\logs\install.log)

:: change ntp server from windows server to pool.ntp.org
sc config W32Time start=demand >nul 2>nul
sc start W32Time >nul 2>nul
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
sc queryex "w32time" | find "STATE" | find /v "RUNNING" || (
    net stop w32time
    net start w32time
) >nul 2>nul

:: resync time to pool.ntp.org
w32tm /config /update
w32tm /resync
sc stop W32Time
sc config W32Time start=disabled
if %ERRORLEVEL%==0 (echo %date% - %time% NTP server set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set NTP server! >> %WinDir%\AtlasModules\logs\install.log)

cls & echo Please wait. This may take a moment.

:: optimize NTFS parameters
:: disable last access information on directories, performance/privacy
fsutil behavior set disableLastAccess 1

:: https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security
fsutil behavior set disable8dot3 1

:: enable delete notifications (aka trim or unmap)
:: should be enabled by default but it is here to be sure
fsutil behavior set disabledeletenotify 0

:: disable file system mitigations
reg add "HKLM\System\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "0" /f

if %ERRORLEVEL%==0 (echo %date% - %time% File system optimized...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to optimize file system! >> %WinDir%\AtlasModules\logs\install.log)

:: attempt to fix language packs issue
:: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/language-packs-known-issue
schtasks /Change /Disable /TN "\Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" >nul 2>nul
reg add "HKLM\Software\Policies\Microsoft\Control Panel\International" /v "BlockCleanupOfUnusedPreinstalledLangPacks" /t REG_DWORD /d "1" /f

:: disable unneeded scheduled tasks

:: breaks setting lock screen
:: schtasks /Change /Disable /TN "\Microsoft\Windows\Shell\CreateObjectTask"

for %%a in (
	"\MicrosoftEdgeUpdateTaskMachineCore"
	"\MicrosoftEdgeUpdateTaskMachineUA"
	"\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
	"\Microsoft\Windows\Windows Error Reporting\QueueReporting"
	"\Microsoft\Windows\DiskFootprint\Diagnostics"
	"\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
	"\Microsoft\Windows\Application Experience\StartupAppTask"
	"\Microsoft\Windows\Autochk\Proxy"
	"\Microsoft\Windows\Application Experience\PcaPatchDbTask"
	"\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask"
	"\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
	"\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
	"\Microsoft\Windows\Defrag\ScheduledDefrag"
	"\Microsoft\Windows\DiskFootprint\StorageSense"
	"\MicrosoftEdgeUpdateBrowserReplacementTask"
	"\Microsoft\Windows\Registry\RegIdleBackup"
	"\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange"
	"\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"
	"\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork"
	"\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon"
	"\Microsoft\Windows\StateRepository\MaintenanceTasks"
	"\Microsoft\Windows\UpdateOrchestrator\Report policies"
	"\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
	"\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
	"\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
	"\Microsoft\Windows\UpdateOrchestrator\Schedule Work"
	"\Microsoft\Windows\UPnP\UPnPHostConfig"
	"\Microsoft\Windows\RetailDemo\CleanupOfflineContent"
	"\Microsoft\Windows\Shell\FamilySafetyMonitor"
	"\Microsoft\Windows\InstallService\ScanForUpdates"
	"\Microsoft\Windows\InstallService\ScanForUpdatesAsUser"
	"\Microsoft\Windows\InstallService\SmartRetry"
	"\Microsoft\Windows\International\Synchronize Language Settings"
	"\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents"
	"\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic"
	"\Microsoft\Windows\Multimedia\Microsoft\Windows\Multimedia"
	"\Microsoft\Windows\Printing\EduPrintProv"
	"\Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask"
	"\Microsoft\Windows\Ras\MobilityManager"
	"\Microsoft\Windows\PushToInstall\LoginCheck"
	"\Microsoft\Windows\Time Synchronization\SynchronizeTime"
	"\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime"
	"\Microsoft\Windows\Time Zone\SynchronizeTimeZone"
	"\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
	"\Microsoft\Windows\WaaSMedic\PerformRemediation"
	"\Microsoft\Windows\DiskCleanup\SilentCleanup"
	"\Microsoft\Windows\Diagnosis\Scheduled"
	"\Microsoft\Windows\Wininet\CacheTask"
	"\Microsoft\Windows\Device Setup\Metadata Refresh"
	"\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser"
	"\Microsoft\Windows\WindowsUpdate\Scheduled Start"
) do (
	schtasks /Change /Disable /TN %%a > nul
)

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled scheduled tasks...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable scheduled tasks! >> %WinDir%\AtlasModules\logs\install.log)
cls & echo Please wait. This may take a moment.

:: enable MSI mode on USB controllers
:: second command for each device deletes device priorty, setting it to undefined
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
)

:: enable MSI mode on GPU
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
)

:: enable MSI mode on network adapters
:: undefined priority on some virtual machines may break connection
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
:: if e.g. VMWare is used, skip setting to undefined
wmic computersystem get manufacturer /format:value | findstr /i /C:VMWare && goto vmGO
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
)
goto noVM

:vmGO
:: set to normal priority
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2"  /f
)

:noVM
:: enable MSI mode on SATA controllers
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
)
for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID ^| findstr /L "PCI\VEN_"') do (
    reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
)
if %ERRORLEVEL%==0 (echo %date% - %time% MSI mode set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set MSI mode! >> %WinDir%\AtlasModules\logs\install.log)

cls & echo Please wait. This may take a moment.

:: --- Hardening ---

:: delete defaultuser0 account
:: used during OOBE
net user defaultuser0 /delete >nul 2>nul

:: disable "administrator" account
:: used in oem situations to install oem-specific programs when a user is not yet created
net user administrator /active:no

:: delete adobe font type manager
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Font Drivers" /v "Adobe Type Manager" /f

:: disable USB autorun/play
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d "1" /f

:: disable camera access when locked
reg add "HKLM\Software\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d "1" /f

:: disable remote assistance
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowFullControl" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v "fEnableChatControl" /t REG_DWORD /d "0" /f

:: hardening of smb
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220932
reg add "HKLM\System\CurrentControlSet\Services\LanManServer\Parameters" /v "RestrictNullSessAccess" /t REG_DWORD /d "1" /f

:: disable smb compression (possible smbghost vulnerability workaround)
reg add "HKLM\System\CurrentControlSet\Services\LanManServer\Parameters" /v "DisableCompression" /t REG_DWORD /d "1" /f

:: restrict enumeration of anonymous sam accounts
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220929
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v "RestrictAnonymousSAM" /t REG_DWORD /d "1" /f

:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220930
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v "RestrictAnonymous" /t REG_DWORD /d "1" /f

:: hardening of netbios
:: netbios is disabled. if it manages to become enabled, protect against NBT-NS poisoning attacks
reg add "HKLM\System\CurrentControlSet\Services\NetBT\Parameters" /v "NodeType" /t REG_DWORD /d "2" /f

:: mitigate against hivenightmare/serious sam
icacls %WinDir%\system32\config\*.* /inheritance:e

:: set strong cryptography on 64 bit and 32 bit .net framework (version 4 and above) to fix a scoop installation issue
:: https://github.com/ScoopInstaller/Scoop/issues/2040#issuecomment-369686748
reg add "HKLM\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" /v "SchUseStrongCrypto" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" /v "SchUseStrongCrypto" /t REG_DWORD /d "1" /f

:: disable network navigation pane in file explorer
reg add "HKCR\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder" /v "Attributes" /t REG_DWORD /d "2962489444" /f

:: import the power scheme
powercfg -import "%WinDir%\AtlasModules\Atlas.pow" 11111111-1111-1111-1111-111111111111

:: set current power scheme to Atlas
powercfg /s 11111111-1111-1111-1111-111111111111
if %ERRORLEVEL%==0 (echo %date% - %time% Power scheme imported...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to import power scheme! >> %WinDir%\AtlasModules\logs\install.log)

:: set service split treshold
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set /a ram=%%i+102400
reg add "HKLM\System\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f
if %ERRORLEVEL%==0 (echo %date% - %time% Service split treshold set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set service split treshold! >> %WinDir%\AtlasModules\logs\install.log)

:: disable drivers power savings
for /f "tokens=*" %%i in ('wmic PATH Win32_PnPEntity GET DeviceID ^| findstr "USB\VID_"') do (   
    for %%a in (
        "EnhancedPowerManagementEnabled"
        "AllowIdleIrpInD3"
        "EnableSelectiveSuspend"
        "DeviceSelectiveSuspended"
        "SelectiveSuspendEnabled"
        "SelectiveSuspendOn"
        "WaitWakeEnabled"
        "D3ColdSupported"
        "WdfDirectedPowerTransitionEnable"
        "EnableIdlePowerManagement"
        "IdleInWorkingState"
    ) do (
        reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters" /v "%%a" /t REG_DWORD /d "0" /f
    )
)

:: disable pnp power savings
PowerShell.exe -NoProfile -Command "$devices = Get-WmiObject Win32_PnPEntity; $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($p in $powerMgmt){$IN = $p.InstanceName.ToUpper(); foreach ($h in $devices){$PNPDI = $h.PNPDeviceID; if ($IN -like \"*$PNPDI*\"){$p.enable = $False; $p.psbase.put()}}}" >nul 2>nul
if %ERRORLEVEL%==0 (echo %date% - %time% Disabled power savings...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to disable power savings! >> %WinDir%\AtlasModules\logs\install.log)

:: make certain applications in the AtlasModules folder request UAC
:: although these applications may already request UAC, setting this compatibility flag ensures they are ran as administrator
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%WinDir%\AtlasModules\serviwin.exe" /t REG_SZ /d "~ RUNASADMIN" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%WinDir%\AtlasModules\DevManView.exe" /t REG_SZ /d "~ RUNASADMIN" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%WinDir%\AtlasModules\NSudo.exe" /t REG_SZ /d "~ RUNASADMIN" /f

cls & echo Please wait. This may take a moment.

:: unhide powerplan attributes
:: credits: https://gist.github.com/Velocet/7ded4cd2f7e8c5fa475b8043b76561b5
PowerShell.exe -NoProfile -Command "(gci 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings' -Recurse).Name -notmatch '\bDefaultPowerSchemeValues|(\\[0-9]|\b255)$' | % {sp $_.Replace('HKEY_LOCAL_MACHINE','HKLM:') -Name 'Attributes' -Value 2 -Force}"
if %ERRORLEVEL%==0 (echo %date% - %time% Enabled hidden power scheme attributes...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Enable hidden power scheme attributes! >> %WinDir%\AtlasModules\logs\install.log)

:: residual file cleanup
:: files are removed in the official iso
for %%a in (
    "GameBarPresenceWriter.exe"
    "mobsync.exe"
    "mcupdate_genuineintel.dll"
    "mcupdate_authenticamd.dll"
) do (
    del /f /q "%WinDir%\System32\%%a" >nul 2>nul
)

:: remove microsoft edge
rd /s /q "C:\Program Files (x86)\Microsoft" >nul 2>nul

:: remove residual registry keys
reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>nul
reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f >nul 2>nul
reg delete "HKLM\Software\Classes\MSEdgeHTM" /f >nul 2>nul
reg delete "HKLM\System\CurrentControlSet\Services\EventLog\Application\edgeupdate" /f >nul 2>nul
reg delete "HKLM\System\CurrentControlSet\Services\EventLog\Application\edgeupdatem" /f >nul 2>nul
reg delete "HKLM\Software\WOW6432Node\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>nul
reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>nul
reg delete "HKLM\Software\WOW6432Node\Microsoft\EdgeUpdate" /f >nul 2>nul
reg delete "HKLM\Software\WOW6432Node\Microsoft\Edge" /f >nul 2>nul
reg delete "HKLM\Software\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Device Metadata" /f >nul 2>nul

:: not checking for %errorlevel%, as these are often deleted in the first place. so if it were to error it would only cause confusion
echo %date% - %time% Residule files deleted...>> %WinDir%\AtlasModules\logs\install.log

:: disable nagle's algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%i in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
    reg add "HKLM\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
:: reg add "HKLM\System\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: configure nic settings
:: get nic driver settings path by querying for dword
:: if you see a way to optimize this segment, feel free to open a pull request
for /f %%a in ('reg query "HKLM\System\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    :: check if the value exists, to prevent errors and uneeded settings
    for /f %%i in ('reg query "%%a" /v "GigaLite" ^| findstr "HKEY"') do (
        :: add the value
        :: if the value does not exist, it will silently error
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
if %ERRORLEVEL%==0 (echo %date% - %time% Network optimized...>> %windir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to optimize network! >> %windir%\AtlasModules\logs\install.log)

:: windows server update client id
sc stop wuauserv >nul 2>nul

:: reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientIdValidation" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v "SusClientId" /t REG_SZ /d "00000000-0000-0000-0000-000000000000" /f

:: disable hibernation
powercfg -h off

:: fix explorer whitebar bug
start explorer.exe
taskkill /f /im explorer.exe
start explorer.exe

:: disable network adapters
:: IPv6, Client for Microsoft Networks, QoS Packet Scheduler, File and Printer Sharing
PowerShell.exe -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6, ms_msclient, ms_pacer, ms_server" >nul 2>&1

:: disable system devices
DevManView.exe /disable "System Speaker"
DevManView.exe /disable "System Timer"
DevManView.exe /disable "UMBus Root Bus Enumerator"
DevManView.exe /disable "Microsoft System Management BIOS Driver"
:: DevManView.exe /disable "Programmable Interrupt Controller"
DevManView.exe /disable "High Precision Event Timer"
DevManView.exe /disable "PCI Encryption/Decryption Controller"
DevManView.exe /disable "AMD PSP"
DevManView.exe /disable "Intel SMBus"
DevManView.exe /disable "Intel Management Engine"
DevManView.exe /disable "PCI Memory Controller"
DevManView.exe /disable "PCI standard RAM Controller"
DevManView.exe /disable "Composite Bus Enumerator"
DevManView.exe /disable "Microsoft Kernel Debug Network Adapter"
DevManView.exe /disable "SM Bus Controller"
DevManView.exe /disable "NDIS Virtual Network Adapter Enumerator"
:: DevManView.exe /disable "Microsoft Virtual Drive Enumerator" < breaks ISO mounts
DevManView.exe /disable "Numeric Data Processor"
DevManView.exe /disable "Microsoft RRAS Root Enumerator"
if %ERRORLEVEL%==0 (echo %date% - %time% Disabled devices...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to Disable devices! >> %WinDir%\AtlasModules\logs\install.log)

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
            set /A start=%%i
            echo !start!
            echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
            echo "Start"=dword:0000000!start! >> %filename%
            echo] >> %filename%
	    )
) >nul 2>&1

:: backup default windows drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "delims=," %%i in ('driverquery /FO CSV') do (
	set svc=%%~i
	for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /A start=%%i
		echo !start!
		echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) >nul 2>&1

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
%setSvc% edgeupdate 4
%setSvc% edgeupdatem 4
%setSvc% EFS 3
%setSvc% fdPHost 4
%setSvc% FDResPub 4
%setSvc% FontCache 4
%setSvc% FontCache3.0.0.0 4
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
%setSvc% GpuEnergyDrv 4
%setSvc% mrxsmb 4
%setSvc% mrxsmb20 4
%setSvc% NdisVirtualBus 4
%setSvc% nvraid 4
:: %setSvc% PEAUTH 4 < breaks uwp streaming apps like netflix, manual mode does not fix
%setSvc% QWAVEdrv 4
:: set to manual instead of disabling (fixes wsl), thanks phlegm
%setSvc% rdbss 3
%setSvc% rdyboost 4
%setSvc% KSecPkg 4
%setSvc% mrxsmb20 4
%setSvc% mrxsmb 4
%setSvc% srv2 4
%setSvc% sfloppy 4
%setSvc% SiSRaid2 4
%setSvc% SiSRaid4 4
%setSvc% Tcpip6 4
%setSvc% tcpipreg 4
%setSvc% Telemetry 4
%setSvc% udfs 4
%setSvc% umbus 4
%setSvc% VerifierExt 4
:: %setSvc% volmgrx 4 < breaks dynamic disks
%setSvc% vsmraid 4
%setSvc% VSTXRAID 4
:: %setSvc% wcifs 4 < breaks various microsoft store games, erroring with "filter not found"
%setSvc% wcnfs 4
%setSvc% WindowsTrustedRTProxy 4

:: remove dependencies
reg add "HKLM\System\CurrentControlSet\Services\Dhcp" /v "DependOnService" /t REG_MULTI_SZ /d "NSI\0Afd" /f
reg add "HKLM\System\CurrentControlSet\Services\Dnscache" /v "DependOnService" /t REG_MULTI_SZ /d "nsi" /f
reg add "HKLM\System\CurrentControlSet\Services\rdyboost" /v "DependOnService" /t REG_MULTI_SZ /d "" /f

reg add "HKLM\System\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ  /d "" /f
reg add "HKLM\System\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ  /d "" /f

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
		set /A start=%%i
		echo !start!
		echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) >nul 2>&1

:: backup default Atlas drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "delims=," %%i in ('driverquery.exe /FO CSV') do (
	set svc=%%~i
	for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /A start=%%i
		echo !start!
		echo [HKLM\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) >nul 2>&1

:: Registry
:: done through script now, HKCU\... keys often do not integrate correctly

:: bsod quality of life
reg add "HKLM\System\CurrentControlSet\Control\CrashControl" /v "AutoReboot" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\CrashControl" /v "DisplayParameters" /t REG_DWORD /d "1" /f

:: gpo for start menu (tiles)
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "%WinDir%\layout.xml" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "%WinDir%\layout.xml" /f

:: enable dark mode, disable transparency
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f

:: disable windows updates
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableDualScan" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AUPowerManagement" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAutoRestartNotificationDisable" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ManagePreviewBuilds" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ManagePreviewBuildsPolicyValue" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdates" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "BranchReadinessLevel" /t REG_DWORD /d "20" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d "365" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdates" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d "4" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d "2" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUAsDefaultShutdownOption" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d "2" /f

:: may cause issues with language packs/microsoft store
:: if planning to revert, remove reg add "HKLM\Software\Policies\Microsoft\InternetManagement" /v "RestrictCommunication" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d "1" /f

:: disable speech model updates
reg add "HKLM\Software\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d "0" /f

:: disable windows insider and build previews
reg add "HKLM\Software\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableConfigFlighting" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\PreviewBuilds" /v "AllowBuildPreview" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableExperimentation" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\WindowsSelfHost\UI\Visibility" /v "HideInsiderPage" /t REG_DWORD /d "1" /f

:: pause maps updates/downloads
reg add "HKLM\Software\Policies\Microsoft\Windows\Maps" /v "AutoDownloadAndUpdateMapData" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d "0" /f

:: disable ceip
%currentuser% reg add "HKCU\Software\Policies\Microsoft\Messenger\Client" /v "CEIP" /t REG_DWORD /d "2" /f
reg add "HKLM\Software\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d "0" /f

:: disable windows media player drm online access
reg add "HKLM\Software\Policies\Microsoft\WMDRM" /v "DisableOnline" /t REG_DWORD /d "1" /f

:: disable web in search
reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0" /f

:: data queue sizes
:: set to half of default
reg add "HKLM\System\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d "50" /f
reg add "HKLM\System\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d "50" /f

:: explorer
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "LinkResolveIgnoreLinkInfo" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInternetOpenWith" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d "1" /f

:: old alt tab
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "AltTabSettings" /t REG_DWORD /d "1" /f

:: application compatability
reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableEngine" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d "1" /f

:: disable mouse acceleration
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f

:: disable annoying keyboard features
%currentuser% reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_DWORD /d "0" /f

:: disable connection checking (pings microsoft servers)
:: may cause internet icon to show it is disconnected
reg add "HKLM\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d "0" /f

:: restrict windows' access to internet resources
:: enables various other GPOs that limit access on specific windows services
reg add "HKLM\Software\Policies\Microsoft\InternetManagement" /v "RestrictCommunication" /t REG_DWORD /d "1" /f

:: disable text/ink/handwriting telemetry
reg add "HKLM\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\TabletPC" /v "PreventHandwritingDataSharing" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d "1" /f

:: disable windows error reporting
reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d "0" /f

:: disable data collection
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d "0" /f

:: miscellaneous
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v "ShowedToastAtLevel" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d "0" /f

:: disable content delivery manager
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314563Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d "0" /f

:: disable advertising info
reg add "HKLM\Software\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable sleep study
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Power" /v "SleepStudyDisabled" /t REG_DWORD /d "1" /f

:: opt-out of sending kms client activation data to microsoft automatically
:: enabling this setting prevents this computer from sending data to microsoft regarding its activation state
reg add "HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d "1" /f

:: disable feedback
%currentuser% reg add "HKCU\Software\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d "0" /f

:: disable settings sync
reg add "HKLM\Software\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSync" /t REG_DWORD /d "2" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSyncUserOverride" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\SettingSync" /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync" /v "SyncPolicy" /t REG_DWORD /d "5" /f

:: power
reg add "HKLM\System\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d "0" /f
:: reg add "HKLM\System\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Power" /v "EventProcessorEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f

:: location tracking
reg add "HKLM\Software\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\FindMyDevice" /v "LocationSyncEnabled" /t REG_DWORD /d "0" /f

:: remove readyboost tab
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f >nul 2>nul

:: hide meet now button, for future proofing
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f

:: disable shared experiences
reg add "HKLM\Software\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d "0" /f

:: show all tasks on control panel, credits to tenforums
reg add "HKLM\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f
reg add "HKLM\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "InfoTip" /t REG_SZ /d "View list of all Control Panel tasks" /f
reg add "HKLM\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "System.ControlPanel.Category" /t REG_SZ /d "5" /f
reg add "HKLM\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\DefaultIcon" /ve /t REG_SZ /d "%%WinDir%%\System32\imageres.dll,-27" /f
reg add "HKLM\Software\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\Shell\Open\Command" /ve /t REG_SZ /d "explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f

:: memory management
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f
:: reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableCfg" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePageCombining" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
:: reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /t REG_DWORD /d "0" /f
:: reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d "1" /f

:: disable fault tolerant heap
:: https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
:: doc listed as only affected in windows 7, is also in 7+
reg add "HKLM\Software\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d "0" /f

:: https://docs.microsoft.com/en-us/windows/security/threat-protection/overview-of-threat-mitigations-in-windows-10#structured-exception-handling-overwrite-protection
:: not found in ntoskrnl strings, very likely depracated or never existed. it is also disabled in MitigationOptions below
:: reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "KernelSEHOPEnabled" /t REG_DWORD /d "0" /f

:: exists in ntoskrnl strings, keep for now
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "1" /f

:: find correct mitigation values for different Windows versions - AMIT
:: initialize bit mask in registry by disabling a random mitigation
PowerShell.exe -NoProfile -Command Set-ProcessMitigation -System -Disable CFG
:: get bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set mitigation_mask=%%a
)
:: set all bits to 2 (disable)
for /l %%a in (0,1,9) do (
    set mitigation_mask=!mitigation_mask:%%a=2!
)
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f

:: https://www.intel.com/content/www/us/en/support/articles/000059422/processors.html
:: reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f

:: disable virtualization-based protection of code integrity
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity
reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: configure multimedia class scheduler
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d "10" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "10" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "10000" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Latency Sensitive" /t REG_SZ /d "True" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "NoLazyMode" /t REG_DWORD /d "1" /f

:: configure gamebar/fse
%currentuser% reg add "HKCU\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /t REG_DWORD /d "2" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f

:: disallow background apps
reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f

:: set Win32PrioritySeparation short 26 hex/38 dec
reg add "HKLM\System\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "38" /f

:: disable notification/action center
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoTileApplicationNotification" /t REG_DWORD /d "1" /f

:: hung apps, wait to kill, quality of life
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "8" /f
reg add "HKLM\System\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9A12038010000000" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f

:: configure windows visuals
%currentuser% reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f

:: configure desktop window manager
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "Composition" /t REG_DWORD /d "0" /f

:: requires testing
:: https://djdallmann.github.io/GamingPCSetup/CONTENT/RESEARCH/FINDINGS/registrykeys_dwm.txt
:: reg add "HKLM\Software\Microsoft\Windows\Dwm" /v "AnimationAttributionEnabled" /t REG_DWORD /d "0" /f

:: add batch to new file menu
reg add "HKLM\Software\Classes\.bat\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@%WinDir%\System32\acppage.dll,-6002" /f
reg add "HKLM\Software\Classes\.bat\ShellNew" /v "NullFile" /t REG_SZ /d "" /f

:: add reg to new file menu
reg add "HKLM\Software\Classes\.reg\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@%WinDir%\regedit.exe,-309" /f
reg add "HKLM\Software\Classes\.reg\ShellNew" /v "NullFile" /t REG_SZ /d "" /f

:: disable storage sense
reg add "HKLM\Software\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d "0" /f

:: disable maintenance
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "1" /f

:: do not reduce sounds while in a call
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio" /v "UserDuckingPreference" /t REG_DWORD /d "3" /f

:: configure microsoft edge
reg add "HKLM\Software\Policies\Microsoft\Windows\EdgeUI" /v "DisableMFUTracking" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d "0" /f

:: install cab context menu
reg delete "HKCR\CABFolder\Shell\RunAs" /f >nul 2>nul
reg add "HKCR\CABFolder\Shell\RunAs" /ve /t REG_SZ /d "Install" /f
reg add "HKCR\CABFolder\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\CABFolder\Shell\RunAs\Command" /ve /t REG_SZ /d "cmd /k dism /online /add-package /packagepath:\"%%1\"" /f

:: merge as trustedinstaller for .regs
reg add "HKCR\regfile\Shell\RunAs" /ve /t REG_SZ /d "Merge As TrustedInstaller" /f
reg add "HKCR\regfile\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "1" /f
reg add "HKCR\regfile\Shell\RunAs\Command" /ve /t REG_SZ /d "NSudo.exe -U:T -P:E reg import "%%1"" /f

:: add run with priority context menu
reg add "HKCR\exefile\shell\Priority" /v "MUIVerb" /t REG_SZ /d "Run with priority" /f
reg add "HKCR\exefile\shell\Priority" /v "SubCommands" /t REG_SZ /d "" /f
reg add "HKCR\exefile\Shell\Priority\shell\001flyout" /ve /t REG_SZ /d "Realtime" /f
reg add "HKCR\exefile\Shell\Priority\shell\001flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /Realtime \"%%1\"" /f
reg add "HKCR\exefile\Shell\Priority\shell\002flyout" /ve /t REG_SZ /d "High" /f
reg add "HKCR\exefile\Shell\Priority\shell\002flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /High \"%%1\"" /f
reg add "HKCR\exefile\Shell\Priority\shell\003flyout" /ve /t REG_SZ /d "Above normal" /f
reg add "HKCR\exefile\Shell\Priority\shell\003flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /AboveNormal \"%%1\"" /f
reg add "HKCR\exefile\Shell\Priority\shell\004flyout" /ve /t REG_SZ /d "Normal" /f
reg add "HKCR\exefile\Shell\Priority\shell\004flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /Normal \"%%1\"" /f
reg add "HKCR\exefile\Shell\Priority\shell\005flyout" /ve /t REG_SZ /d "Below normal" /f
reg add "HKCR\exefile\Shell\Priority\shell\005flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /BelowNormal \"%%1\"" /f
reg add "HKCR\exefile\Shell\Priority\shell\006flyout" /ve /t REG_SZ /d "Low" /f
reg add "HKCR\exefile\Shell\Priority\shell\006flyout\command" /ve /t REG_SZ /d "cmd.exe /c start \"\" /Low \"%%1\"" /f

:: remove include in library context menu
reg delete "HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location" /f >nul 2>nul
reg delete "HKLM\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" /f >nul 2>nul

:: remove share in context menu
reg delete "HKCR\*\shellex\ContextMenuHandlers\ModernSharing" /f >nul 2>nul

:: double click to import power plans
reg add "HKLM\Software\Classes\powerplan\DefaultIcon" /ve /t REG_SZ /d "%%WinDir%%\System32\powercpl.dll,1" /f
reg add "HKLM\Software\Classes\powerplan\Shell\open\command" /ve /t REG_SZ /d "powercfg /import \"%%1\"" /f
reg add "HKLM\Software\Classes\.pow" /ve /t REG_SZ /d "powerplan" /f
reg add "HKLM\Software\Classes\.pow" /v "FriendlyTypeName" /t REG_SZ /d "PowerPlan" /f

if %ERRORLEVEL%==0 (echo %date% - %time% Registry configuration applied...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to apply registry configuration! >> %WinDir%\AtlasModules\logs\install.log)

:: disable dma remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f DmaRemappingCompatible ^| find /i "Services\" ') do (
	reg add "%%i" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)
echo %date% - %time% Disabled dma remapping...>> %WinDir%\AtlasModules\logs\install.log

:: set system processes priority below normal
for %%i in (lsass sppsvc SearchIndexer fontdrvhost sihost ctfmon) do (
  reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "5" /f
)

:: set background apps priority below normal
for %%i in (OriginWebHelperService ShareX EpicWebHelper SocialClubHelper steamwebhelper) do (
  reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "5" /f
)

:: set desktop window manager priority to normal
:: wmic process where name="dwm.exe" CALL setpriority "normal"

if %ERRORLEVEL%==0 (echo %date% - %time% Process priorities set...>> %WinDir%\AtlasModules\logs\install.log
) ELSE (echo %date% - %time% Failed to set priorities! >> %WinDir%\AtlasModules\logs\install.log)

:: lowering dual boot choice time
:: no, this does not affect single OS boot time.
:: this is directly shown in microsoft docs https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--timeout#parameters
bcdedit /timeout 10

:: setting to "no" provides worse results, delete the value instead.
:: this is here as a safeguard incase of user error
bcdedit /deletevalue useplatformclock >nul 2>nul

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
sc stop WpnService >nul 2>nul
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
if %ERRORLEVEL%==0 echo %date% - %time% Notifications disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:notiE
sc config WpnUserService start=auto
sc config WpnService start=auto
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Notifications enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:indexD
sc config WSearch start=disabled
sc stop WSearch >nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Search Indexing disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:indexE
sc config WSearch start=delayed-auto
sc start WSearch >nul 2>nul
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

:storeD
echo This will break a majority of UWP apps and their deployment.
echo Extra note: This breaks the "about" page in settings. If you require it, enable the AppX service.
:: this includes windows firewall, i only see the point in keeping it because of microsoft store
:: if you notice something else breaks when firewall/microsoft store is disabled please open an issue
pause

:: detect if user is using a microsoft account
PowerShell.exe -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" >nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( sc config wlidsvc start=disabled ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )

:: disable the option for microsoft store in the "open with" dialog
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f

:: block access to microsoft store
reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
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
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f

:: allow access to microsoft store
reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
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

:btD
sc config BthAvctpSvc start=disabled
sc stop BthAvctpSvc >nul 2>nul
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
  sc stop %%~nI
)
sc config CDPSvc start=disabled
if %ERRORLEVEL%==0 echo %date% - %time% Bluetooth disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:btE
sc config BthAvctpSvc start=auto
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "2" /f
)
sc config CDPSvc start=auto
if %ERRORLEVEL%==0 echo %date% - %time% Bluetooth enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:cbdhsvcD
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f cbdhsvc ^| find /i "cbdhsvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
)
:: to do: check if service can be set to demand
sc config DsSvc start=disabled
%currentuser% reg add "HKCU\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Clipboard History disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:cbdhsvcE
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f cbdhsvc ^| find /i "cbdhsvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "3" /f
)
sc config DsSvc start=auto
%currentuser% reg add "HKCU\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "1" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /f >nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Clipboard History enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hddD
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
sc config SysMain start=disabled
sc config FontCache start=disabled
if %ERRORLEVEL%==0 echo %date% - %time% Hard Drive Prefetching disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:hddE
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f
sc config SysMain start=auto
sc config FontCache start=auto
if %ERRORLEVEL%==0 echo %date% - %time% Hard Drive Prefetch enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:depE
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable DEP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable EmulateAtlThunks
bcdedit /set nx OptIn
:: enable cfg for valorant related processes
for %%i in (valorant valorant-win64-shipping vgtray vgc) do (
    PowerShell.exe -NoProfile -Command "Set-ProcessMitigation -Name %%i.exe -Enable CFG"
)
if %ERRORLEVEL%==0 echo %date% - %time% DEP enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:depD
echo If you get issues with some anti-cheats, please re-enable DEP.
PowerShell.exe -NoProfile set-ProcessMitigation -System -Disable DEP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Disable EmulateAtlThunks
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
taskkill /f /im SearchApp*  >nul 2>nul
ren SearchApp.exe SearchApp.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto restartSearch

:: search icon
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
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
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f
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
taskkill /f /im SearchApp*  >nul 2>nul
ren SearchApp.exe SearchApp.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto OSrestartSearch

:: search icon
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu removed...>> %WinDir%\AtlasModules\logs\userScript.log

:skipRM
:: install silently
echo]
echo Open-Shell is installing...
"Open-Shell.exe" /qn ADDLOCAL=StartMenu
curl -L https://github.com/bonzibudd/Fluent-Metro/releases/download/v1.5.3/Fluent-Metro_1.5.3.zip -o skin.zip
7z -aoa -r e "skin.zip" -o"C:\Program Files\Open-Shell\Skins"
del /F /Q skin.zip >nul 2>nul
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
echo - Immersive control panel (Settings)
echo - Adobe XD
echo - Start context menu
echo - Wi-Fi menu
echo - Microsoft accounts
echo Please PROCEED WITH CAUTION, you are doing this at your own risk.
pause

:: detect if user is using a microsoft account
PowerShell.exe -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" >nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( sc config wlidsvc start=disabled ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )
choice /c yn /m "Last warning, continue? [Y/N]" /n
sc stop TabletInputService
sc config TabletInputService start=disabled

:: disable the option for microsoft store in the "open With" dialog
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f

:: block access to microsoft store
reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
sc config InstallService start=disabled

:: insufficent permissions to disable
%setSvc% WinHttpAutoProxySvc 4
sc config mpssvc start=disabled
sc config AppXSvc start=disabled
sc config BFE start=disabled
sc config TokenBroker start=disabled
sc config LicenseManager start=disabled
sc config ClipSVC start=disabled

taskkill /f /im StartMenuExperienceHost*  >nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old
taskkill /f /im SearchApp*  >nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy Microsoft.Windows.Search_cw5n1h2txyewy.old
ren %WinDir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old
ren %WinDir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old

taskkill /f /im RuntimeBroker*  >nul 2>nul
ren %WinDir%\System32\RuntimeBroker.exe RuntimeBroker.exe.old
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% UWP disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish
pause

:uwpE
sc config TabletInputService start=demand
:: disable the option for microsoft store in the "open with" dialog
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f

:: block Access to microsoft store
reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
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

taskkill /f /im StartMenuExperienceHost*  >nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
taskkill /f /im SearchApp*  >nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy.old Microsoft.Windows.Search_cw5n1h2txyewy
ren %WinDir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old Microsoft.XboxGameCallableUI_cw5n1h2txyewy
ren %WinDir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe
taskkill /f /im RuntimeBroker*  >nul 2>nul
ren %WinDir%\System32\RuntimeBroker.exe.old RuntimeBroker.exe
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% UWP enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:mitE
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable DEP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable EmulateAtlThunks
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable RequireInfo
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable BottomUp
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable HighEntropy
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable StrictHandle
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable CFG
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable StrictCFG
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable SuppressExports
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable SEHOP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable AuditSEHOP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable SEHOPTelemetry
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable ForceRelocateImages
goto finish

:startlayout
reg delete "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f >nul 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f >nul 2>nul
reg delete "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /f >nul 2>nul
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
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable DEP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable EmulateAtlThunks
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable RequireInfo
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable BottomUp
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable HighEntropy
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable StrictHandle
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable CFG
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable StrictCFG
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable SuppressExports
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable SEHOP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable AuditSEHOP
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable SEHOPTelemetry
PowerShell.exe -NoProfile set-ProcessMitigation -System -Enable ForceRelocateImages

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
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f

:: - static arp entry

:: lsass hardening
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\lsass.exe" /v "AuditLevel" /t REG_DWORD /d "8" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\CredentialsDelegation" /v "AllowProtectedCreds" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v "DisableRestrictedAdminOutboundCreds" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v "DisableRestrictedAdmin" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v "RunAsPPL" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Control\SecurityProviders\WDigest" /v "Negotiate" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\SecurityProviders\WDigest" /v "UseLogonCredential" /t REG_DWORD /d "0" /f

:xboxU
set /P c=This is IRREVERSIBLE (A reinstall is required to restore these components), continue? [Y/N]
if /I "%c%" EQU "N" exit
if /I "%c%" EQU "Y" goto :xboxConfirm
exit

:xboxConfirm
echo Removing via PowerShell...
NSudo.exe -U:C -ShowWindowMode:Hide -Wait PowerShell.exe -NoProfile -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage" >nul 2>nul

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
echo Disabling UAC breaks fullscreen on certain UWP applications, one of them being Minecraft Windows 10 Edition. It is also less secure to disable UAC.
set /P c="Do you want to continue? [Y/N]: "
if /I "%c%" EQU "Y" goto uacDconfirm
if /I "%c%" EQU "N" exit
exit

:uacDconfirm
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "0" /f
%setSvc% luafv 4
%setSvc% Appinfo 4
if %ERRORLEVEL%==0 echo %date% - %time% UAC disabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:uacE
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "5" /f
%setSvc% luafv 2
%setSvc% Appinfo 3
if %ERRORLEVEL%==0 echo %date% - %time% UAC enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

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
reg delete "HKLM\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /f >nul 2>nul
%currentuser% reg delete "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /f >nul 2>nul
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9e3e078012000000" /f
if %ERRORLEVEL%==0 echo %date% - %time% Animations enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:aniD
reg add "HKLM\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f
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
dism /Online /Disable-Feature /FeatureName:SmbDirect /norestart
if %ERRORLEVEL%==0 echo %date% - %time% Workstation disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:workstationE
%setSvc% rdbss 3
%setSvc% KSecPkg 0
%setSvc% mrxsmb20 3
%setSvc% mrxsmb 3
%setSvc% srv2 3
%setSvc% LanmanWorkstation 2
dism /Online /Enable-Feature /FeatureName:SmbDirect /norestart
if %ERRORLEVEL%==0 echo %date% - %time% Workstation enabled...>> %WinDir%\AtlasModules\logs\userScript.log
if "%~1" EQU "int" goto :EOF
goto finish

:printE
set /P c=You may be vulnerable to Print Nightmare Exploits while printing is enabled. Would you like to add Group Policies to protect against them? [Y/N]
if /I "%c%" EQU "Y" goto nightmareGPO
if /I "%c%" EQU "N" goto printECont
goto nightmareGPO

:nightmareGPO
echo The spooler will not accept client connections nor allow users to share printers.
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /t REG_DWORD /d "2" /f
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "Restricted" /t REG_DWORD /d "1" /f

:: prevent print drivers over HTTP
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d "1" /f

:: disable printing over HTTP
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d "1" /f

:printECont
%setSvc% Spooler 2
if %ERRORLEVEL%==0 echo %date% - %time% Printing enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish
:printD
%setSvc% Spooler 4
if %ERRORLEVEL%==0 echo %date% - %time% Printing disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:dataQueueM
echo Mouse data queue sizes
echo This may affect stability and input latency. And if low enough may cause mouse skipping/mouse stutters.
echo There has been no well proven evidence of this having a beneficial effect on latency, only "feel". Use with that in mind.
echo]
echo Default: 100
echo Valid Value Range: 1-100
set /P c="Enter the size you want to set Mouse Data Queue Size to: "

:: filter to numbers only
echo %c%|findstr /r "[^0-9]" > nul
if %ERRORLEVEL%==1 goto dataQueueMSet
cls & echo Only values from 1-100 are allowed!
goto dataQueueM

:: checks for invalid values
:dataQueueMSet
reg add "HKLM\System\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d "%c%" /f
if %ERRORLEVEL%==0 echo %date% - %time% Mouse Data Queue Size set to %c%...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:dataQueueK
echo Keyboard data queue sizes
echo This may affect stability and input latency. And if low enough may cause general keyboard issues like ghosting.
echo There has been no well proven evidence of this having a beneficial effect on latency, only "feel". Use with that in mind.
echo]
echo Default: 100
echo Valid Value Range: 1-100
set /P c="Enter the size you want to set Keyboard data queue size to: "

:: filter to numbers only
echo %c%|findstr /r "[^0-9]" > nul
if %ERRORLEVEL%==1 goto dataQueueKSet
cls
echo Only values from 1-100 are allowed!
goto dataQueueK

:: checks for invalid values
:dataQueueKSet
reg add "HKLM\System\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d "%c%" /f
if %ERRORLEVEL%==0 echo %date% - %time% Keyboard Data Queue Size set to %c%...>> %WinDir%\AtlasModules\logs\userScript.log
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
  reg add "HKLM\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
  reg add "HKLM\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
  reg add "HKLM\System\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKLM\System\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
::reg add "HKLM\System\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKLM\Software\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: configure nic Setting
:: get nic driver settings path by querying for dword
:: if you see a way to optimize this segment, feel free to open a pull request
for /f %%a in ('reg query HKLM /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    :: check if the value exists, to prevent errors and uneeded settings
    for /f %%i in ('reg query "%%a" /v "GigaLite" ^| findstr "HKEY"') do (
        :: add the value
        :: if the value does not exist, it will silently error
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
dism /Online /Disable-Feature /FeatureName:WindowsMediaPlayer /norestart
goto finish

:ieD
dism /Online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /norestart
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
set /P c="Review Install script before executing? [Y/N]: "
if /I "%c%" EQU "Y" curl "https://raw.githubusercontent.com/lukesampson/scoop/master/bin/install.ps1" -o %WinDir%\AtlasModules\install.ps1 && notepad %WinDir%\AtlasModules\install.ps1
if /I "%c%" EQU "N" curl "https://raw.githubusercontent.com/lukesampson/scoop/master/bin/install.ps1" -o %WinDir%\AtlasModules\install.ps1
PowerShell.exe -NoProfile Set-ExecutionPolicy RemoteSigned -scope CurrentUser
PowerShell.exe -NoProfile %WinDir%\AtlasModules\install.ps1
echo Refreshing environment for Scoop...
call %WinDir%\AtlasModules\refreshenv.bat
echo]
echo Installing git...
:: scoop is not very nice with batch scripts and will break the whole script if a warning or error shows up
cmd /c scoop install git -g
call %WinDir%\AtlasModules\refreshenv.bat
echo .
echo Adding extras bucket...
cmd /c scoop bucket add extras
cmd /c scoop bucket add games
goto finish

:choco
echo Installing Chocolatey
set /P c="Review install script before executing? [Y/N]: "
if /I "%c%" EQU "Y" curl "https://community.chocolatey.org/install.ps1" -o %WinDir%\AtlasModules\install.ps1 && notepad %WinDir%\AtlasModules\install.ps1
if /I "%c%" EQU "N" curl "https://community.chocolatey.org/install.ps1" -o %WinDir%\AtlasModules\install.ps1
PowerShell.exe -NoProfile -EP Unrestricted -Command "%WinDir%\AtlasModules\install.ps1"
echo Refreshing environment for Chocolatey...
call %WinDir%\AtlasModules\refreshenv.bat
echo]
echo Installing git...
cmd /c choco install git
call %WinDir%\AtlasModules\refreshenv.bat
goto finish

:browserscoop
for /f "tokens=1 delims=;" %%i in ('%WinDir%\AtlasModules\multichoice.exe "Browser" "Pick a browser" "ungoogled-chromium;firefox;brave;googlechrome;librewolf;tor-browser"') do (
	set spacedelimited=%%i
	set spacedelimited=!spacedelimited:;= !
	cmd /c scoop install !spacedelimited! -g
)
:: has to launch in separate process, scoop seems to exit the whole script if not
goto finish

:browserchoco
for /f "tokens=1 delims=;" %%i in ('%WinDir%\AtlasModules\multichoice.exe "Browser" "Pick a browser" "ungoogled-chromium;firefox;brave;googlechrome;librewolf;tor-browser"') do (
	set spacedelimited=%%i
	set spacedelimited=!spacedelimited:;= !
	cmd /c choco install !spacedelimited!
)
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

:staticIP
call :netcheck
set /P dns1="Set DNS Server (e.g. 1.1.1.1): "
for /f "tokens=4" %%i in ('netsh int show interface ^| find "Connected"') do set devicename=%%i
:: for /f "tokens=2 delims=[]" %%i in ('ping -4 -n 1 %ComputerName% ^| findstr [') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name^="%devicename%" ^| findstr "IP Address:"') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name^="%devicename%" ^| findstr "Default Gateway:"') do set DHCPGateway=%%i
for /f "tokens=2 delims=()" %%i in ('netsh int ip show config name^="Ethernet" ^| findstr "Subnet Prefix:"') do for /f "tokens=2" %%a in ("%%i") do set DHCPSubnetMask=%%a
netsh int ipv4 set address name="%devicename%" static %LocalIP% %DHCPSubnetMask% %DHCPGateway%
PowerShell.exe -NoProfile -Command "Set-DnsClientServerAddress -InterfaceAlias "%devicename%" -ServerAddresses %dns1%"
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
for /f %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /s /f Scaling ^| find /i "Configuration\"') do (
	reg add "%%i" /v "Scaling" /t REG_DWORD /d "1" /f
)
if %ERRORLEVEL%==0 echo %date% - %time% Display Scaling disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:DSCPauto
for /f "tokens=* delims=\" %%i in ('%WinDir%\AtlasModules\filepicker.exe exe') do (
    if "%%i"=="cancelled by user" exit
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Application Name" /t REG_SZ /d "%%~ni%%~xi" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Version" /t REG_SZ /d "1.0" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Protocol" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local Port" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local IP" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote Port" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote IP" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "DSCP Value" /t REG_SZ /d "46" /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Throttle Rate" /t REG_SZ /d "-1" /f
)
goto finish

:NVPstate
:: credits to Timecard
:: https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0
sc query NVDisplay.ContainerLocalSystem >nul 2>&1
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
    reg delete "%%i" /v "DisableDynamicPstate" /f
)
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Dynamic P-States enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finish

:nvcontainerD
:: check if the service exists
sc query NVDisplay.ContainerLocalSystem >nul 2>&1
if errorlevel 1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
    pause
    exit /B
)

echo Disabling the NVIDIA Display Container LS service will stop the NVIDIA Control Panel from working.
echo You can enable the NVIDIA Control Panel by running the other version of this script, which enables the service.
echo Read README.txt for more info.
pause

%setSvc% NVDisplay.ContainerLocalSystem 4
sc stop NVDisplay.ContainerLocalSystem > nul
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS disabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:nvcontainerE
:: check if the service exists
sc query NVDisplay.ContainerLocalSystem >nul 2>&1
if %errorlevel% 1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
    pause
    exit /B
)

%setSvc% NVDisplay.ContainerLocalSystem 2
sc start NVDisplay.ContainerLocalSystem > nul
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:nvcontainerCME
:: cm = context menu
sc query NVDisplay.ContainerLocalSystem >nul 2>&1
if %errorlevel% 1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
    pause
    exit /B
)
echo Explorer will be restarted to ensure that the context menu works.
pause

:: get icon exe
:: different for older/newer drivers
if not exist "C:\Program Files\NVIDIA Corporation\Display.NvContainer\" (
	cd /d %WinDir%\System32\DriverStore\FileRepository\nv_dispig.inf_?????_*\Display.NvContainer\
) else (
	cd /d C:\Program Files\NVIDIA Corporation\Display.NvContainer
)
copy "NVDisplay.Container.exe" "%WinDir%\System32\NvidiaIcon.exe" /B /Y
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Icon" /t REG_SZ /d "%WinDir%\System32\NvidiaIcon.exe,0" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "MUIVerb" /t REG_SZ /d "NVIDIA Container" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Position" /t REG_SZ /d "Bottom" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "SubCommands" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "MUIVerb" /t REG_SZ /d "Enable NVIDIA Container" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001\command" /ve /t REG_SZ /d "%WinDir%\AtlasModules\nsudo.exe -U:T -P:E -UseCurrentConsole -Wait %WinDir%\AtlasModules\atlas-config.bat /nvcontainerE" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "MUIVerb" /t REG_SZ /d "Disable NVIDIA Container" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002\command" /ve /t REG_SZ /d "%WinDir%\AtlasModules\nsudo.exe -U:T -P:E -UseCurrentConsole -Wait %WinDir%\AtlasModules\atlas-config.bat /nvcontainerD" /f
taskkill /f /im explorer.exe >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS Context Menu enabled...>> %WinDir%\AtlasModules\logs\userScript.log
goto finishNRB

:nvcontainerCMD
:: cm = context menu
sc query NVDisplay.ContainerLocalSystem >nul 2>&1
if %errorlevel% 1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
    pause
    exit /B
)
reg query "HKCR\DesktopBackground\shell\NVIDIAContainer" >nul 2>&1
if %errorlevel% 1 (
    echo The context menu does not exist, you can not continue.
    pause
    exit /B
)

echo Explorer will be restarted to ensure that the context menu is gone.
pause
reg delete "HKCR\DesktopBackground\Shell\NVIDIAContainer" /f

:: delete icon exe
erase /F /Q "%WinDir%\System32\NvidiaIcon.exe"
taskkill /f /im explorer.exe >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS Context Menu disabled...>> %WinDir%\AtlasModules\logs\userScript.log
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
goto :finish

:diagE
%setSvc% DPS 2
%setSvc% WdiServiceHost 3
%setSvc% WdiSystemHost 3
echo %date% - %time% Diagnotics enabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto :finish

:diagD
%setSvc% DPS 4
%setSvc% WdiServiceHost 4
%setSvc% WdiSystemHost 4
echo %date% - %time% Diagnotics disabled...>> %WinDir%\AtlasModules\logs\userscript.log
goto :finish

:: Begin Batch Functions

:invalidInput <label>
if "%c%"=="" echo Empty input! Please enter Y or N. & goto %~1
if "%c%" NEQ "Y" if "%c%" NEQ "N" echo Invalid input! Please enter Y or N. & goto %~1
goto :EOF

:netcheck
ping -n 1 -4 1.1.1.1 | find "time=" >nul 2>nul || (
    echo Network is not connected! Please connect to a network before continuing.
	pause
	goto netcheck
) >nul 2>nul
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
reg query "HKLM\System\CurrentControlSet\Services\%~1" >nul 2>&1 || (echo The specified service/driver ^(%~1^) is not found. & exit /b 1)
if "%system%"=="false" (
	if not "%setSvcWarning%"=="false" (
		echo WARNING: Not running as System, could fail modifying some services/drivers with an access denied error.
	)
)
reg add "HKLM\System\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f > nul || (
	if "%system%"=="false" (echo Failed to set service %~1 with start value %~2! Not running as System, access denied?) else (
	echo Failed to set service %~1 with start value %~2! Unknown error.)
)
exit /b 0

:firewallBlockExe
:: usage: %fireBlockExe% "[NAME]" "[EXE]"
:: example: %fireBlockExe% "Calculator" "%WinDir%\System32\calc.exe"
:: have both in quotes

:: get rid of any old rules (prevents duplicates)
netsh advfirewall firewall delete rule name="Block %~1" protocol=any dir=in >nul 2>&1
netsh advfirewall firewall delete rule name="Block %~1" protocol=any dir=out >nul 2>&1
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
