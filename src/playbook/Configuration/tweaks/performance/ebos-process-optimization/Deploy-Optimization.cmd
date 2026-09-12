@echo off
:: ============================================
:: EBOS Process Optimization Deployment Script
:: Purpose: Deploy the optimization module to target systems
:: Version: 3.1.0
:: ============================================

setlocal enabledelayedexpansion

echo ============================================
echo EBOS Process Optimization Deployment
echo Version: 3.1.0
echo ============================================
echo.

:: Configuration
set "MODULE_SOURCE=%~dp0"
set "LOG_PATH=%ProgramData%\ProcessOptimization"
set "BACKUP_PATH=%ProgramData%\ProcessOptimization\Backup"
set "DEPLOY_LOG=%LOG_PATH%\Deploy.log"

:: Create directories
if not exist "%LOG_PATH%" mkdir "%LOG_PATH%"
if not exist "%BACKUP_PATH%" mkdir "%BACKUP_PATH%"

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

echo [%date% %time%] Starting deployment... >> "%DEPLOY_LOG%"

:: Step 1: Backup current state
echo [1/5] Creating backup of current state...
echo [%date% %time%] Creating backup... >> "%DEPLOY_LOG%"

:: Backup registry
reg export "HKLM\SYSTEM\CurrentControlSet\Control" "%BACKUP_PATH%\Control_Backup.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services" "%BACKUP_PATH%\Services_Backup.reg" /y >nul 2>&1
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "%BACKUP_PATH%\DataCollection_Backup.reg" /y >nul 2>&1

:: Backup services
sc query state= all > "%BACKUP_PATH%\Services_State.txt" 2>&1

echo      Backup created at: %BACKUP_PATH%
echo [%date% %time%] Backup completed >> "%DEPLOY_LOG%"

:: Step 2: Copy module files
echo [2/5] Copying module files...
echo [%date% %time%] Copying module files... >> "%DEPLOY_LOG%"

set "TARGET_PATH=%ProgramFiles%\EBOS\ProcessOptimization"
if not exist "%TARGET_PATH%" mkdir "%TARGET_PATH%"

copy /y "%MODULE_SOURCE%ServiceGroupingConsolidation.reg" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%Optimize-ProcessBaseline.ps1" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%ProcessProtection.xml" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%InjectionConfig.yaml" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%OptimizationConfig.yaml" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%ExecuteOptimization.cmd" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%Test-Optimization.ps1" "%TARGET_PATH%\" >nul 2>&1
copy /y "%MODULE_SOURCE%README.md" "%TARGET_PATH%\" >nul 2>&1

echo      Module files copied to: %TARGET_PATH%
echo [%date% %time%] Module files copied >> "%DEPLOY_LOG%"

:: Step 3: Apply registry optimizations
echo [3/5] Applying registry optimizations...
echo [%date% %time%] Applying registry optimizations... >> "%DEPLOY_LOG%"

regedit /s "%TARGET_PATH%\ServiceGroupingConsolidation.reg"
if %errorLevel% equ 0 (
    echo      Registry optimizations applied successfully.
    echo [%date% %time%] Registry optimizations applied successfully >> "%DEPLOY_LOG%"
) else (
    echo      WARNING: Some registry optimizations may have failed.
    echo [%date% %time%] WARNING: Some registry optimizations failed >> "%DEPLOY_LOG%"
)

:: Step 4: Execute PowerShell optimization
echo [4/5] Executing PowerShell optimization...
echo [%date% %time%] Executing PowerShell optimization... >> "%DEPLOY_LOG%"

powershell.exe -ExecutionPolicy Bypass -File "%TARGET_PATH%\Optimize-ProcessBaseline.ps1" -OptimizationLevel Aggressive -SkipWarnings
if %errorLevel% equ 0 (
    echo      PowerShell optimization completed successfully.
    echo [%date% %time%] PowerShell optimization completed successfully >> "%DEPLOY_LOG%"
) else (
    echo      WARNING: PowerShell optimization encountered errors.
    echo [%date% %time%] WARNING: PowerShell optimization encountered errors >> "%DEPLOY_LOG%"
)

:: Step 5: Verify deployment
echo [5/5] Verifying deployment...
echo [%date% %time%] Verifying deployment... >> "%DEPLOY_LOG%"

:: Check if critical services are running
set "SERVICES_OK=1"
for %%s in (RpcSs DcomLaunch Power AudioSrv Dhcp Dnscache) do (
    sc query %%s >nul 2>&1
    if !errorLevel! neq 0 (
        set "SERVICES_OK=0"
        echo      WARNING: Service %%s is not running
        echo [%date% %time%] WARNING: Service %%s is not running >> "%DEPLOY_LOG%"
    )
)

if "%SERVICES_OK%"=="1" (
    echo      All critical services are running.
    echo [%date% %time%] All critical services are running >> "%DEPLOY_LOG%"
)

:: Check process count
for /f "tokens=2 delims=," %%a in ('tasklist /fi "STATUS eq running" ^| find /c ","') do (
    set "PROCESS_COUNT=%%a"
)
echo      Current process count: %PROCESS_COUNT%
echo [%date% %time%] Current process count: %PROCESS_COUNT% >> "%DEPLOY_LOG%"

echo.
echo ============================================
echo Deployment Complete!
echo ============================================
echo.
echo Summary:
echo - Backup created at: %BACKUP_PATH%
echo - Module installed at: %TARGET_PATH%
echo - Registry optimizations applied
echo - PowerShell optimization executed
echo - Process count: %PROCESS_COUNT%
echo.
echo Log file: %DEPLOY_LOG%
echo.
pause