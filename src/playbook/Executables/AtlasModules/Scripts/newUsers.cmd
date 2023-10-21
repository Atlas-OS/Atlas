@echo off

set title=Preparing Atlas user settings...
title %title%

echo %title%
echo --------------------------------------------------------------------------------------
echo You'll be logged out, and once you login again, your new account will be ready for use.

(
taskkill /f /im explorer.exe
call "%windir%\AtlasDesktop\3. Configuration\Visual Effects\Atlas Visual Effects (default).cmd" /silent
reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f
timeout /nobreak /t 10
logoff
) > nul

exit