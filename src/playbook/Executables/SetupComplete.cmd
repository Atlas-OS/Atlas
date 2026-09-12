@echo off
REM ============================================================================
REM  SetupComplete.cmd  -  place in C:\Windows\Setup\Scripts\ in the image.
REM  Runs once at the end of Windows Setup (SYSTEM context, before first logon).
REM  Assumes the EBOS scripts were staged into C:\EBOS during image build
REM  (via your answer file / provisioning step). Idempotent and failure-tolerant.
REM ============================================================================
if not exist "C:\EBOS" mkdir "C:\EBOS"

REM Use pwsh (PS7) when available, fall back to Windows PowerShell 5.1 (always present in Setup).
set "PSH=pwsh.exe"
where pwsh.exe >nul 2>&1
if errorlevel 1 set "PSH=powershell.exe"

REM 1. Set the .apbx file icon machine-wide (copies playbook.ico to ProgramData)
if exist "C:\EBOS\Set-ApbkIcon.ps1" (
    "%PSH%" -NoProfile -ExecutionPolicy Bypass -File "C:\EBOS\Set-ApbkIcon.ps1" -Deploy >> "C:\EBOS\icon-setup.log" 2>&1
)

REM 2. Install Windhawk + transparent taskbar - OPT-IN ONLY.
REM Runs only when Stage-ImageFiles.ps1 -IncludeWindhawk created the marker.
REM (SetupComplete runs before the AME Wizard choice is known, so an unconditional
REM install would contradict the wizard default of unchecked. The playbook option
REM 'windhawk-transparency' installs on demand anyway when selected later.)
if exist "C:\EBOS\include-windhawk.txt" (
    if exist "C:\EBOS\Install-WindhawkTransparentTaskbar.ps1" (
        "%PSH%" -NoProfile -ExecutionPolicy Bypass -File "C:\EBOS\Install-WindhawkTransparentTaskbar.ps1" >> "C:\EBOS\windhawk-setup.log" 2>&1
    )
)

REM 3. Stage the playbook onto the desktop (it shows the EBOS icon via the
REM    file-type registration performed in step 1, so no extra shortcut is needed)
if exist "C:\EBOS\EBOS Release.apbx" (
    copy /Y "C:\EBOS\EBOS Release.apbx" "%PUBLIC%\Desktop\EBOS Release.apbx" >nul 2>&1
)

REM 4. Final marker
echo EBOS post-install complete: %DATE% %TIME% >> "C:\EBOS\setupcomplete.log"

exit /b 0
