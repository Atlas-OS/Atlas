@echo off
set "currentDirectory=%~dp0"
cd /d "%currentDirectory%"
for %%a in (
    log
    setInfo
    wait
    addPackage
) do (
    set %%a=call :%%a
)
:: Set to 'High Performance' power plan
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

:: ======================================================================================================================= ::
:: VARIABLES                                                                                                               ::
:: ======================================================================================================================= ::

    echo INFO: Setting variables...

    set "sourceDriveCommand=reg query "HKLM\SOFTWARE\Microsoft\RecoveryEnvironment" /v "SourceDrive""
    set "associatedOSDriveLetterCommand=reg query "HKLM\SOFTWARE\Microsoft\RecoveryEnvironment" /v "AssociatedOSDriveLetter""

    :: Make Windows Recovery Registry key for variables
    :: Also would mount the WinRE partition
    start /min %SystemDrive%\sources\recovery\RecEnv.exe
    :recEnvGetKey
    %sourceDriveCommand% > nul 2>&1 || goto recEnvGetKey
    %associatedOSDriveLetterCommand% > nul 2>&1 || goto recEnvGetKey
    :: Set drive letters
    for /f "usebackq tokens=3 delims=\ " %%a in (`%sourceDriveCommand%`) do (
        set "recoveryDrive=%%a"
    )
    for /f "usebackq tokens=3 delims=\ " %%a in (`%associatedOSDriveLetterCommand%`) do (
        set "targetDrive=%%a"
    )
    :: Notify VBS on what to do
    set "focusPath=%currentDirectory%\FocusMSHTA"
    if exist "%recoveryDrive%\AtlasComponentPackageInstallation" (
        echo] > "%systemdrive%\AtlasComponentPackageInstallation"
        del /f /q "%recoveryDrive%\AtlasComponentPackageInstallation"
    ) else (
        echo] > "%systemdrive%\AtlasNormalWindowsRecovery"
        call :deleteBitlockerInfo
        exit
    )
    :: Allow enough time for RecEnv to properly initialize
    %wait% 7000
    del /f /q "%focusPath%"
    echo INFO: Killing RecEnv...
    wmic process where "name='RecEnv.exe'" call terminate > nul

    :: BitLocker
    if exist "%targetDrive%\Windows" goto afterBitLocker
    if not exist "%bitlockerKeyPath%" goto :setError "BitLocker" "error 1"
    for /f "tokens=*" %%a in (%bitlockerKeyPath%) do (set "bitlockerKey=%%a")
    manage-bde -unlock %targetDrive% -RecoveryPassword %bitlockerKey%
    if not exist "%targetDrive%\Windows" goto :setError "BitLocker" "error 2"

    :afterBitLocker
    :: Delete BitLocker key
    call :deleteBitlockerInfo

    :: HTA
    set "htaFolderPath=%cd%\hta"
    set "htaPath=%htaFolderPath%\hta.html"
    set "dataPath=%htaFolderPath%\data.css"

    :: Target disk variables
    set "packagesList=%targetDrive%\Windows\AtlasModules\winrePackagesToInstall"
    set "atlasLogDirectory=%targetDrive%\Windows\AtlasModules\Logs"

    :: Other variables
    set "percentage=1"
    set "dontRestartPath=%systemdrive%\AtlasDontRestart"

    :: Set log file
    echo INFO: Setting log file...
    if not exist "%atlasLogDirectory%" mkdir "%atlasLogDirectory%" & echo INFO: Made Atlas log directory...
    for /f "skip=1" %%a in ('wmic os get localdatetime') do if not defined unformattedDate set unformattedDate=%%a
    set formattedDate=%unformattedDate:~6,2%-%unformattedDate:~4,2%-%unformattedDate:~0,4%
    :makeLogDirectoryAndFile
    set /a logNum += 1
    set "logDirPath=%atlasLogDirectory%\%logNum%-AtlasWinRE-PackageInstall-%formattedDate%"
    if exist "%logDirPath%" (goto makeLogDirectoryAndFile) else (
        mkdir "%logDirPath%"
        set "logPath=%logDirPath%\dism.log"
    )

    echo INFO: Starting debug console...
    start /i /d "%targetDrive%\Windows" /min "Atlas Debug Console" cmd /k %currentDirectory%debug.cmd "%logPath%" "%dontRestartPath%" "%focusPath%"

:: -------------------------------------------------------------------------------------------------------- ::
:: Start looping through packages                                                                           ::
:: -------------------------------------------------------------------------------------------------------- ::

    for /f "usebackq" %%a in (`type "%packagesList%" ^| find "" /v /c`) do set totalCount=%%a
    for /f "usebackq" %%a in (`type "%packagesList%" ^| find ".cab" ^| find "" /v /c`) do set packageCount=%%a
    for /f "usebackq" %%a in (`type "%packagesList%" ^| find "disableFeature" ^| find "" /v /c`) do set disableFeatureCount=%%a
    %log% "INFO: Installing %totalCount% packages from %packagesList%..."
    set /a percentageSteps=100/%totalCount%
    for /f "tokens=* delims=" %%a in (%packagesList%) do (
        %addPackage% "%%a"
    )

:: -------------------------------------------------------------------------------------------------------- ::
:: Finsh up                                                                                                 ::
:: -------------------------------------------------------------------------------------------------------- ::

    echo INFO: Finishing up
    %setInfo% "Restarting" "100"

    if defined error echo "%logPath%" "%error%" > "%targetDrive%\Windows\System32\AtlasPackagesFailure"
    copy /y "%packagesList%" "%logDirPath%"
    del /f /q "%packagesList%"

    %wait% 6000
    if not exist "%dontRestartPath%" wpeutil reboot
    :infinitePause
    pause & goto infinitePause

:: ======================================================================================================================= ::
:: FUNCTIONS                                                                                                               ::
:: ======================================================================================================================= ::
    exit /b

    :addPackage [packagePath]
    echo]
    set /a halfWayPercentage = %percentage% + ( %percentageSteps% / 2 )
    set "dismCurrentLog=%systemDrive%\dismTemp%random%.txt"

    :: check if it's a disabled feature
    echo "%~1" | find "disableFeature" || goto makePackageCommand
    set /a disableFeatureNum += 1
    set "currentLine=%~1"
    set "featureName=%currentLine:disableFeature =%"
    set "dismCommand=dism /image:%targetDrive%\ /disable-feature /featurename:%featureName% /logpath:"%dismCurrentLog%""
    set "message=Configuring feature %disableFeatureNum%"
    goto runDismCommand

    :makePackageCommand
    :: check for either DISM cleanup or package addition
    set /a packageNum += 1
    if "%~1"=="dismCleanup" (
        set "dismCommand=dism /image:%targetDrive%\ /cleanup-image /startcomponentcleanup /logpath:"%dismCurrentLog%""
        set "message=Cleaning up"
    ) else (
        set "dismCommand=dism /image:%targetDrive%\ /add-package:"%targetDrive%\%~1" /logpath:"%dismCurrentLog%""
        set "message=Adding package %packageNum%"
    )

    :runDismCommand
    %setInfo% "%message%" "%halfWayPercentage%"
    %log% "%dismCommand%"

    %dismCommand%
    set dismErrorlevel=%errorlevel%
    if %dismErrorlevel%==0 (
        %log% "SUCCESS: Successfully deployed %~1..."
    ) else (
        %log% "ERROR: Failed to deploy %~1. Exit code %dismErrorLevel%."
        set error=%dismErrorlevel%
    )
    type "%dismCurrentLog%" >> "%logPath%"
    del /f /q "%dismCurrentLog%"

    set /a percentage=%percentage% + %percentageSteps%
    %setInfo% "%message%" "%percentage%"
    exit /b

    :log [text]
    (
        echo]
        echo ==================================================================================================================================
        echo %~1 
        echo ==================================================================================================================================
        echo]
    ) >> "%logPath%"
    echo %~1
    exit /b

    :setInfo [message] [percentage]
    echo .dataButton::after{content:"INFO;%~1;%~2"} > "%dataPath%"
    exit /b

    :setError [message] [error]
    echo .dataButton::after{content:"ERROR;%~2"} > "%dataPath%"
    call :deleteBitlockerInfo
    %wait% 8000
    if not exist "%dontRestartPath%" wpeutil reboot
    exit /b

    :wait [seconds]
    cscript %cd%\sleep.vbs %~1 //B
    exit /b

    :deleteBitlockerInfo
    set "bitlockerKey=nu-uh"
    del /f /q "%recoveryDrive%\bitlockerAtlas.txt" > nul 2>&1
    exit /b

    :strlen [strVar] [rtnVar]
    setlocal EnableDelayedExpansion
    set "s=#!%~1!"
    set "len=0"
    for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
        if "!s:~%%N,1!" neq "" (
        set /a "len+=%%N"
        set "s=!s:~%%N!"
        )
    )
    endlocal&if "%~2" neq "" (set %~2=%len%) else echo %len%
    exit /b