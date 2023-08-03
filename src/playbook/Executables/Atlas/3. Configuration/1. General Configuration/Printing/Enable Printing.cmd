@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Add print to context menu
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

call setSvc.cmd Spooler 2

echo Finished, please reboot your device for changes to apply.
pause
exit /b