@echo off

fltmc > nul 2>&1 || (echo You must run this script as admin. & exit /b)
set ___settings=call "%windir%\AtlarModules\Scripts\settingsPages.cmd"


:: Check args
set ___policy=
if "%~1"=="" goto help
echo %1 | find "clude" > nul && (
    if "%~2"=="" goto help
    set ___policy=true
)

:: /include & /exclude
if defined ___policy (
    call :addIndexPath %~1 "%~2"
)

if "%~1"=="/cleanpolicies" (
    echo Cleaning policies...
    for %%a in (
        "HKLM\Software\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths"
        "HKLM\Software\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths"
        "HKLM\Software\Microsoft\Windows Search\CurrentPolicies\DefaultExcludedPaths"
        "HKLM\Software\Microsoft\Windows Search\CurrentPolicies\DefaultIndexedPaths"
    ) do (
        reg delete %%a /f > nul 2>&1
        reg add %%a /f > nul
    )
)

if "%~1"=="/start" (
    echo Starting the indexer...
    sc config WSearch start=delayed-auto > nul
    sc start WSearch > nul

    %___settings% /unhide cortana-windowssearch

    echo Updating policy... ^(this might take a moment^)
    gpupdate > nul
)

if "%~1"=="/stop" (
    echo Stopping the indexer...

    %___settings% /hide cortana-windowssearch

    rem Kill the search index Control Panel pane
    powershell -NoP -NonI -C "Stop-Process -Id (gcim Win32_Process | ? { $_.CommandLine -match 'srchadmin.dll' }).ProcessId -Force"
    
    sc config WSearch start=disabled > nul
    sc stop WSearch > nul 2>&1
)

exit /b



:help
    echo You must use one (not in combination)
    echo -------------------------------------
    echo /include [full folder path]
    echo /exclude [full folder path]
    echo /cleanpolicies
    echo /start
    echo /stop
    exit /b


:addIndexPath
    echo Configuring indexer path...
    set policy=DefaultIndexedPaths
    if "%~1"=="/exclude" set policy=DefaultExcludedPaths

    set "searchPath1=%~2"
    set "searchPath=file:///%searchPath1%\*"
    reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Search\%policy%" /v "%searchPath%" /t REG_SZ /d "%searchPath%" /f > nul
    reg add "HKLM\Software\Microsoft\Windows Search\CurrentPolicies\%policy%" /v "%searchPath%" /t REG_SZ /d "%searchPath%" /f > nul
    exit /b


:cleanPolicies
    for %%a in (
        "HKLM\Software\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths"
        "HKLM\Software\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths"
        "HKLM\Software\Microsoft\Windows Search\CurrentPolicies\DefaultExcludedPaths"
        "HKLM\Software\Microsoft\Windows Search\CurrentPolicies\DefaultIndexedPaths"
    ) do (
        reg delete %%a /f > nul 2>&1
        reg add %%a /f > nul 2>&1
    )
    exit /b
