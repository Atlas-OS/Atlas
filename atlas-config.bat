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

for /f "usebackq tokens=3,4,5" %%i in (`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName`) DO set winprod=%%k
if /i "%winprod%"=="Pro" goto ProdCheckGood
if /i "%winprod%"=="Home" goto ProdCheckGood
echo It seems you are using a Windows Product version that is not supported. This script only supports Pro and Home
:ProdCheckGood

:updatecheck
:: set script version, not OS
set ver=1.0.0
set workdir=Atlas-%devbranch%
set devbranch=update-test1-NOMERGE

if exist "ver.txt" del /f /q "ver.txt" >nul 2>&1
aria2c https://raw.githubusercontent.com/Atlas-OS/Atlas/%devbranch%/ver.txt
cls

:: read from ver.txt
for /f "tokens=*" %%i in (ver.txt) do set gitver=%%i
:: checking if the current version number is less than git version
if /i %ver% LSS %gitver% (
    echo An update is available for atlas-config 
    echo Current version:   %ver%
    echo Available Version:    %gitver%
    choice /c yn /m "Update? [y/n]" /n /t 100 /d y
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
:permFAIL
	echo Permission grants failed. Please try again by launching the script through the respected scripts, which will give it the correct permissions.
	pause&exit
:finish
echo Finished, please reboot for changes to apply.
:finishNRB
echo Finished, changes have been applied.
pause