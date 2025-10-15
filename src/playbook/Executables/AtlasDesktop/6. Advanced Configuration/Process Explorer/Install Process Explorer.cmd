@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=ProcessExplorer"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=1"
set "scriptPath=%~f0"

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

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

:: End of state and path update

:: Check if WinGet is functional or not
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd"
if %ERRORLEVEL% NEQ 0 exit /b 1

echo Installing Process Explorer...
winget install -e --id Microsoft.Sysinternals.ProcessExplorer --uninstall-previous -l "%windir%\AtlasModules\Apps\ProcessExplorer" -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity > nul
if %ERRORLEVEL% NEQ 0 (
    echo error: Process Explorer installation with WinGet failed.
    pause
    exit /b 1
)

echo Creating the Start menu shortcut...
PowerShell -NoP -C "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut("""$([Environment]::GetFolderPath('CommonStartMenu'))\Programs\Process Explorer.lnk"""); $Shortcut.TargetPath = """$([Environment]::GetFolderPath('Windows'))\AtlasModules\Apps\ProcessExplorer\procexp.exe"""; $Shortcut.Save()" > nul
if %ERRORLEVEL% NEQ 0 (
	echo Process Explorer shortcut could not be created in the start menu!
)

echo Configuring Process Explorer...
:: Run Process Explorer only in one instance
reg add "HKCU\SOFTWARE\Sysinternals\Process Explorer" /v "OneInstance" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "%windir%\AtlasModules\Apps\ProcessExplorer\procexp.exe" /f > nul

echo]
echo The 'pcw' service in Windows is needed for Task Manager and performance counters.
echo Disabling it matters less as you have Process Explorer, but software and Windows might have unexpected issues.
choice /c:yn /n /m "Would you like to disable it? [Y/N] "
sc config pcw start=disabled > nul

echo]
echo Finished, changes have been applied.
pause
exit /b