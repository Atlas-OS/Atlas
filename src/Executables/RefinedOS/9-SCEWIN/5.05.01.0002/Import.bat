@echo off
:: Request administrator privileges
fltmc >nul 2>&1 || (
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo error: right-click on the script and select "Run as administrator"
        pause
    )
    exit /b 1
)

pushd %~dp0

for %%a in ("amifldrv64.sys", "amigendrv64.sys", "nvram.txt") do (
    if not exist "%%~a" (
        echo error: %%~a not found in the current directory

        if "%%~a" == "nvram.txt" (
            echo Please rename your NVRAM script file to "nvram.txt" or run "Export.bat" to create it
        )

        pause
        exit /b 1    
    )    
)

SCEWIN_64.exe /I /S nvram.txt 2> log-file.txt
type log-file.txt
echo See log-file.txt for output messages
pause
