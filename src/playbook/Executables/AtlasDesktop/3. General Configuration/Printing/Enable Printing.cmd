@echo off
setlocal EnableDelayedExpansion

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

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide printers

echo Enabling capabilities (this might take a while)...
for %%a in (
    "Print.Fax.Scan~~~~0.0.1.0"
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