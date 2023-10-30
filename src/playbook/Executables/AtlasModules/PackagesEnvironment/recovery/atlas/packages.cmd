@echo off
cd /d "%~dp0"
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

    :: Make Windows Recovery Registry key for variables
    :: Also would mount the WinRE partition
    start /min %SystemDrive%\sources\recovery\RecEnv.exe
    :recEnvGetKey
    reg query HKLM\SOFTWARE\Microsoft\RecoveryEnvironment > nul 2>&1
    if %errorlevel% NEQ 0 goto recEnvGetKey
    echo INFO: Killing RecEnv...
    wmic process where "name='RecEnv.exe'" call terminate > nul

    :: Set drive letters
    for /f "usebackq tokens=3 delims=\ " %%a in (`reg query "HKLM\SOFTWARE\Microsoft\RecoveryEnvironment" /v "SourceDrive"`) do (
        set "recoveryDrive=%%a"
    )
    for /f "usebackq tokens=3 delims=\ " %%a in (`reg query "HKLM\SOFTWARE\Microsoft\RecoveryEnvironment" /v "AssociatedOSDriveLetter"`) do (
        set "targetDrive=%%a"
    )
    
    :: Notify VBS on what to do
    set "bitlockerKeyPath=%recoveryDrive%\bitlockerAtlas.txt"
    if exist "%recoveryDrive%\AtlasComponentPackageInstallation" (
        echo] > "%systemdrive%\AtlasComponentPackageInstallation"
        del /f /q "%recoveryDrive%\AtlasComponentPackageInstallation"
    ) else (
        echo] > "%systemdrive%\AtlasNormalWindowsRecovery"
        del /f /q %bitlockerKeyPath%
        exit
    )

    :: BitLocker
    if exist "%targetDrive%\Windows" goto afterBitLocker
    if not exist "%bitlockerKeyPath%" goto :setError 1
    for /f "tokens=*" %%a in (%bitlockerKeyPath%) do (set "bitlockerKey=%%a")
    manage-bde -unlock %targetDrive% -RecoveryPassword %bitlockerKey%
    if not exist "%targetDrive%\Windows" goto :setError 2

    :afterBitLocker
    :: Delete BitLocker key
    set "bitlockerKey=nu-uh" & del /f /q "%bitlockerKeyPath%"

    :: HTA
    set "htaFolderPath=%cd%\hta"
    set "htaPath=%htaFolderPath%\hta.html"
    set "dataPath=%htaFolderPath%\data.css"

    :: Target disk variables
    set "packagesList=%targetDrive%\Windows\AtlasModules\packagestoInstall"
    set "atlasLogDirectory=%targetDrive%\Windows\AtlasModules\Logs"

    :: Other variables
    set "percentage=1"

    :: Set log file
    echo INFO: Setting log file...
    if not exist "%atlasLogDirectory%" mkdir "%atlasLogDirectory%" & echo Made Atlas log directory...
    :makeLogDirectoryAndFile
    set /a logNum += 1
    set "logDirPath=%atlasLogDirectory%\%logNum%-AtlasPackageInstall-%date:/=-%"
    if exist "%logDirPath%" (goto makeLogDirectoryAndFile) else (
        mkdir "%logDirPath%"
        set "logPath=%logDirPath%\dism.log"
    )

    echo INFO: Starting debug console...
    start /i /d "%targetDrive%\Windows" /min "Atlas Debug Console" cmd /k set "log=notepad %logPath%" ^& cls ^& echo Type %%log%% to open the log.

:: -------------------------------------------------------------------------------------------------------- ::
:: Start looping through packages                                                                           ::
:: -------------------------------------------------------------------------------------------------------- ::

    for /f "usebackq" %%a in (`type "%packagesList%" ^| find "" /v /c`) do set packageCount=%%a
    %log% "INFO: Installing %packageCount% packages from %packagesList%..."
    set /a percentageSteps=100/%packageCount%
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
    wpeutil reboot

:: ======================================================================================================================= ::
:: FUNCTIONS                                                                                                               ::
:: ======================================================================================================================= ::
    exit /b

    :addPackage [packagePath]
    set /a packageNum += 1
    set /a halfWayPercentage = %percentage% + ( %percentageSteps% / 2 )
    
    set "dismCurrentLog=%logDirPath%\dismTemp%random%.txt"
    set "dismCommand=dism /image:%targetDrive%\ /add-package:"%targetDrive%\%~1" /logpath:"%dismCurrentLog%""
    %log% "%dismCommand%"
    %setInfo% "Adding package %packageNum%" "%halfWayPercentage%"

    %dismCommand%
    set dismErrorlevel=%errorlevel%
    if %dismErrorlevel%==0 (
        %log% "SUCCESS: Successfully deployed %~1..."
        type "%dismCurrentLog%" >> "%logPath%"
    ) else (
        %log% "ERROR: Failed to deploy %~1. Exit code %dismErrorLevel%."
        set error=%dismErrorlevel%
    )
    del /f /q "%dismCurrentLog%"

    set /a percentage=%percentage% + %percentageSteps%
    %setInfo% "Adding package %packageNum%" "%percentage%"
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

    :setError [message]
    echo .dataButton::after{content:"ERROR;%~1"} > "%dataPath%"
    exit /b

    :wait [seconds]
    cscript %cd%\sleep.vbs %~1 //B
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