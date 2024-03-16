@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo Enabling printing...
echo]

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

echo Enabling services...
call setSvc.cmd Spooler 2
call setSvc.cmd PrintWorkFlowUserSvc 3

echo Unhiding Settings pages...
set "pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
reg query "!pageKey!" /v "SettingsPageVisibility" > nul 2>&1
if %ERRORLEVEL% == 0 call :enableSettingsPage

echo Enabling capabilities...
for %%a in (
    "Print.Fax.Scan~~~~0.0.1.0",
    "Print.Management.Console~~~~0.0.1.0"
) do (
    dism /Online /Add-Capability /CapabilityName:"%%a" /NoRestart > nul
)

echo Enabling features...
for %%a in (
    "Printing-Foundation-Features"
    "Printing-Foundation-InternetPrinting-Client"
    "Printing-XPSServices-Features"
    "Printing-PrintToPDFServices-Features"
) do (
    dism /Online /Enable-Feature /FeatureName:"%%a" /NoRestart > nul
)

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b

:enableSettingsPage
for /f "usebackq tokens=3" %%a in (`reg query "!pageKey!" /v "SettingsPageVisibility"`) do (set "currentPages=%%a")
reg add "!pageKey!" /v "SettingsPageVisibility" /t REG_SZ /d "!currentPages:printers;=!" /f > nul
exit /b