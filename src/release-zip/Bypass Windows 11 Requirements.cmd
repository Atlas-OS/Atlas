@echo off

title Bypass Windows 11 Requirements
cd /d "%~dp0"

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

:: set ANSI escape characters
cd /d "%~dp0"
for /f %%a in ('forfiles /m "%~nx0" /c "cmd /c echo 0x1B"') do set "ESC=%%a"
set "right=%ESC%[<x>C"
set "bullet= %ESC%[34m-%ESC%[0m"

:main
mode con: cols=51 lines=18
chcp 65001 > nul
echo]
echo %ESC%[31m   Are you sure you want to bypass requirements?
echo   ───────────────────────────────────────────────%ESC%[0m
echo   Bypassing Windows 11 requirements %ESC%[4misn't%ESC%[0m
echo   %ESC%[4mrecommended%ESC%[0m, and you could encounter issues in
echo   the future, e.g. anticheats or other features.
echo]
echo   %ESC%[7mSoftware that needs the requirements:%ESC%[0m
echo   %bullet% Vanguard/VALORANT
echo   %bullet% Core isolation
echo   %bullet% Windows Hello
echo   %bullet% BitLocker
echo]
echo   This list could expand in the future and might
echo   not cover everything.
echo]
<nul set /p=%right:<x>=2%%ESC%[1m%ESC%[33mType 'I understand' to continue: %ESC%[0m

:: This forces the user to type 'I understand' on the same line
setlocal EnableDelayedExpansion
set "str=I understand"
for /l %%a in (0 1 12) do (
    if not "!str:~%%a,1!" == "" call :xcopyInput "!str:~%%a,1!"
)
endlocal
echo]
echo %ESC%[2A%ESC%[?25l

:runCommands
reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f > nul

echo %ESC%[32m  Completed! %ESC%[0mPress any key to exit...                 %ESC%[1A
pause > nul
exit /b

:::::::::::::::::::::::::::::::::::::::::::::
:: -------------- FUNCTIONS -------------- ::
:::::::::::::::::::::::::::::::::::::::::::::

:xcopyInput <"key">
set "key="
for /f "delims=" %%a in ('2^>nul xcopy.exe /w /l "%~f0" "%~f0"') do if not defined key set "key=%%a"
set "key=%key:~-1%"
if /i "%key%" == "%~1" (
    if "%~1" == " " (
        <nul set /p=%right:<x>=1%
    ) else <nul set /p=%~1
) else goto :xcopyInput
exit /b