@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=Printing"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=1"
set "scriptPath=%~f0"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%*"=="" pause
        exit /b 1
    )
    exit /b
)

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if /i not "%~1"=="/silent" if /i not "%~1"=="/justcontext" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

setlocal EnableDelayedExpansion

if "%~1"=="/silent" goto main

echo Enabling printing...
echo]
choice /c:yn /n /m "Would you like to add 'Print' to the context menu? [Y/N] "
if "%errorlevel%" neq "1" goto :main

echo Adding 'Print' to context menu...
reg delete "HKCR\SystemFileAssociations\image\shell\print" /v "ProgrammaticAccessOnly" /f > nul 2>&1
for %%a in (
    "batfile"
    "cmdfile"
    "docxfile"
    "fonfile"
    "htmlfile"
    "inffile"
    "inifile"
    "JSEFile"
    "otffile"
    "pfmfile"
    "regfile"
    "rtffile"
    "ttcfile"
    "ttffile"
    "txtfile"
    "VBEFile"
    "VBSFile"
    "WSFFile"
) do (
    reg delete "HKCR\%%~a\shell\print" /v "ProgrammaticAccessOnly" /f > nul 2>&1
)
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a GEQ 22000 (
        reg delete "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print" /v "LegacyDisable" /f > nul 2>&1
        reg delete "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print" /v "ProgrammaticAccessOnly" /f > nul 2>&1
        reg delete "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print" /v "HideBasedOnVelocityId" /f > nul 2>&1
        reg delete "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo" /v "LegacyDisable" /f > nul 2>&1
        reg delete "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo" /v "ProgrammaticAccessOnly" /f > nul 2>&1
        reg delete "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo" /v "HideBasedOnVelocityId" /f > nul 2>&1
    )
)

:main
echo Enabling services...
call setSvc.cmd Spooler 2
call setSvc.cmd PrintWorkFlowUserSvc 3

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide printers

echo Enabling features...
for %%a in (
    "Printing-Foundation-Features"
    "Printing-Foundation-InternetPrinting-Client"
    "Printing-XPSServices-Features"
    "Printing-PrintToPDFServices-Features"
) do (
    dism /Online /Enable-Feature /FeatureName:"%%a" /NoRestart > nul
)

echo Enabling capabilities (this might take a while)...
dism /Online /Add-Capability /CapabilityName:"Print.Management.Console~~~~0.0.1.0" /NoRestart > nul

if "%~1"=="/silent" exit /b

choice /c:yn /n /m "Would you want to enable Fax and Scan functionality? [Y/N] "
if "%errorlevel%"=="1" dism /Online /Add-Capability /CapabilityName:"Print.Fax.Scan~~~~0.0.1.0" /NoRestart > nul

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b