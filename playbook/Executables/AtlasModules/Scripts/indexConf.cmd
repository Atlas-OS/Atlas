@echo off

fltmc > nul 2>&1 || (echo You must run this script as admin. & exit /b)
set ___settings=call "%windir%\AtlasModules\Scripts\settingsPages.cmd"


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
        "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths"
        "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions"
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
    gpupdate /force /wait:0 > nul 2>&1
)

if "%~1"=="/stop" (
    echo Stopping the indexer...

    %___settings% /hide cortana-windowssearch

    rem Kill the search index Control Panel pane
    powershell -NoP -NonI -C "Get-Process | Where-Object { $_.MainWindowTitle -like '*Indexing Options*' -or $_.CommandLine -match 'srchadmin.dll' } | Stop-Process -Force -ErrorAction SilentlyContinue"

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
    setlocal enabledelayedexpansion
    echo Configuring indexer path...

    if "%~1"=="/include" set "___root=HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths"
    if "%~1"=="/exclude" set "___root=HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions"

    if not defined ___root (endlocal & exit /b)

    set "___i=0"
    :checkExisting
    for /f "usebackq tokens=2*" %%a in (`reg query "!___root!\!___i!" /v "Path" 2^>nul`) do (
        if /I "%%b"=="%~2" (
            echo Path already exists in the index, skipping...
            endlocal & exit /b
        )
    )
    reg query "!___root!\!___i!" > nul 2>&1 && (
        set /a "___i+=1"
        goto checkExisting
    )

    reg add "!___root!\!___i!" /v "Path" /t REG_SZ /d "%~2" /f > nul
    endlocal
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
