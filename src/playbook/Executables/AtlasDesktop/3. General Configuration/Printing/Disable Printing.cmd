@echo off
setlocal EnableDelayedExpansion

if "%~1" == "/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
echo Disabling printing...
echo]

echo Removing 'Print' from context menu...
reg add "HKCR\SystemFileAssociations\image\shell\print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f > nul
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
    reg add "HKCR\%%~a\shell\print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f > nul
)
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a GEQ 22000 (
        reg add "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print" /v "LegacyDisable" /t REG_SZ /d "" /f > nul
        reg add "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f > nul
        reg add "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\Print" /v "HideBasedOnVelocityId" /t REG_DWORD /d "6527944" /f > nul
        reg add "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo" /v "LegacyDisable" /t REG_SZ /d "" /f > nul
        reg add "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f > nul
        reg add "HKCR\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\PrintTo" /v "HideBasedOnVelocityId" /t REG_DWORD /d "6527944" /f > nul
    )
)

echo Disabling services...
call "%windir%\AtlasModules\Scripts\setSvc.cmd" Spooler 4
call "%windir%\AtlasModules\Scripts\setSvc.cmd" PrintWorkFlowUserSvc 4

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide printing

echo Disabling capabilities...
for %%a in (
    "Print.Fax.Scan~~~~0.0.1.0"
    "Print.Management.Console~~~~0.0.1.0"
) do (
    dism /Online /Remove-Capability /CapabilityName:"%%a" /NoRestart > nul
)

echo Disabling features...
for %%a in (
    "Printing-Foundation-Features"
    "Printing-Foundation-InternetPrinting-Client"
    "Printing-XPSServices-Features"
    "Printing-PrintToPDFServices-Features"
) do (
    dism /Online /Disable-Feature /FeatureName:"%%a" /NoRestart > nul
)

if "%~1" == "/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b