@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

echo You may be vulnerable to Print Nightmare Exploits while printing is enabled.
set /P c="Would you like to add Group Policies to protect against them? [Y/N] "
if /I "!c!" == "Y" goto nightmareGPO
if /I "!c!" == "N" goto printECont
goto nightmareGPO

:nightmareGPO
echo The spooler will not accept client connections nor allow users to share printers.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /t REG_DWORD /d "2" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "1" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "Restricted" /t REG_DWORD /d "1" /f > nul 2>&1

:: prevent print drivers over HTTP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d "1" /f > nul 2>&1

:: disable printing over HTTP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d "1" /f > nul 2>&1

:printECont
:: add print to context menu
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

!setSvcScript! Spooler 2

echo Finished, please reboot your device for changes to apply.
pause
exit /b