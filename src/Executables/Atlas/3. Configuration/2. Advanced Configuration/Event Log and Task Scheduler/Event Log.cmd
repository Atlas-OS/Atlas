@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Disabling Event log will break some features:
echo - CapFrameX
echo - Network menu/icon
echo If you experience random issues, please enable Event Log again.
echo]
echo [1] Disable Event log
echo [2] Enable Event log (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
call setSvc.cmd EventLog 4
goto finish

:enable
echo]
call setSvc.cmd EventLog 2
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b
