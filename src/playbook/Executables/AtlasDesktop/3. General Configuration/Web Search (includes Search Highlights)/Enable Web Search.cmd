@echo off
set "settingName=WebSearch"
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

reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

call "%windir%\AtlasModules\Scripts\wingetCheck.cmd"
if %errorlevel% neq 0 exit /b 1

echo Enabling Web Search ^& Search Highlights...

echo]
set key="HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation
choice /c:yn /n /m "Would you like web search to use your location for results? [Y/N] "
if %errorlevel%==1 reg delete %key% /f > nul 2>&1
if %errorlevel%==2 reg add %key% /t REG_DWORD /d 0 /f > nul

:: Enable search indexing to prevent a visual bug
for /f "tokens=6 delims=[.] " %%a in ('ver') do (if %%a GEQ 22000 sc query wsearch | find "STOPPED" > nul && call :searchIndexBug)

:: Install the Bing search provider
echo]
echo Installing the Bing search provider...
winget install -e --id 9NZBF4GT040C --uninstall-previous -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity > nul

:: Main settings
call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide search-permissions /silent
(
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /f
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /f
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /f
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /f
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /f
	reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /f
	reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /f
	reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /f
	reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /f
	reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d "1" /f
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "2" /f
    taskkill /f /im explorer.exe
    taskkill /f /im SearchHost.exe
	start explorer.exe
) > nul 2>&1

echo]
echo Finished, you should be able to use Web Search and Search Highlights.
echo Press any key to exit...
pause > nul
exit /b

:searchIndexBug
echo]
echo On Windows 11, having search indexing disabled causes a graphical bug in web search.
choice /c:yn /n /m "Would you like to enable search indexing to fix it? [Y/N] "
if %errorlevel%==1 call "%windir%\AtlasDesktop\3. General Configuration\Search Indexing\Enable Search Indexing.cmd" /silent & set ____restart=true
exit /b