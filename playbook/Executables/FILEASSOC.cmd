@echo off
set "script=%~dp0AtlasModules\Scripts\fileAssoc.cmd"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

call "%script%" %*
exit /b %errorlevel%
