@echo off
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

 @REM set "script=%windir%\AtlasModules\Scripts\installToolbox.ps1"
set "script=C:\Users\TheyCreeper\Documents\Dev\Atlas\src\playbook\Executables\AtlasModules\Scripts\installToolbox.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	pause
	exit /b 1
)
powershell -EP Bypass -NoP ^& """$env:script""" %*