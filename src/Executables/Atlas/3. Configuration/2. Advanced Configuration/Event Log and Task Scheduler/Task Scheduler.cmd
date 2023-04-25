@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Disabling Task Scheduler will break some features:
echo - MSI Afterburner startup/updates
echo - UWP typing (e.g. Search bar)
echo If you experience random issues, please enable Task Scheduler again.
echo]
echo [1] Disable Task Scheduler
echo [2] Enable Task Scheduler (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
call setSvc.cmd Schedule 4 > nul 2>&1
goto finish

:enable
echo]
call setSvc.cmd Schedule 2 > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b
