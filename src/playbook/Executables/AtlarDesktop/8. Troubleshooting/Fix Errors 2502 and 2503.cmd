@echo off

:: Permissions taken from stock and functional Windows 11 for reference

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

set "folder=%windir%\Temp"

echo This script will fix errors 2502 and 2503 with Windows installers by resetting the Windows TEMP folder permissions.
echo This issue is not related to Atlas.
echo]
pause
echo]

echo Taking ownership of TEMP folder as SYSTEM...
takeown /f "%folder%" /r /d y > nul

echo Clearing all current permissions...
icacls "%folder%" /inheritance:e > nul
icacls "%folder%" /reset > nul
icacls "%folder%" /inheritance:r > nul

echo Setting default permissions...
:: (OI)(CI) - applies recursively
:: F - full control
:: AD - create folders / append data
:: X - traverse folder / execute file
:: WD - create files / write data
icacls "%windir%\Temp" /grant:r "*S-1-5-32-545:(OI)(CI)F" /grant:r "*S-1-5-18:(OI)(CI)F" /grant:r "*S-1-3-0:(OI)(CI)F" /grant:r "*S-1-5-11:(OI)(CI)(X,AD,WD)" /t > nul

echo Clearing Windows temporary files...
:: no error checking as some files and folders will be in use
del /s /f /q "%folder%\*.*" > nul 2>&1

echo]
echo Completed.
pause
exit /b