@echo off

if "%~1"=="/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
:: Remove print from context menu
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

call %windir%\AtlasModules\Scripts\setSvc.cmd Spooler 4
call %windir%\AtlasModules\Scripts\setSvc.cmd PrintWorkFlowUserSvc 4

:: Hide Settings page
if not "%~1"=="/silent" (
    set "pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    reg query "%pageKey%" /v "SettingsPageVisibility" > nul 2>&1
    if "%errorlevel%"=="0" (
        for /f "usebackq tokens=3" %%a in (`reg query "%pageKey%" /v "SettingsPageVisibility"`) do (
            reg add "%pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "%%a;printers;" /f > nul
        )
    ) else (
        reg add "%pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "hide:printers;" /f > nul
    )
)

DISM /Online /Disable-Feature /FeatureName:"Printing-Foundation-Features" /NoRestart > nul
DISM /Online /Disable-Feature /FeatureName:"Printing-Foundation-InternetPrinting-Client" /NoRestart > nul
DISM /Online /Disable-Feature /FeatureName:"Printing-XPSServices-Features" /NoRestart > nul

if "%~1"=="/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b