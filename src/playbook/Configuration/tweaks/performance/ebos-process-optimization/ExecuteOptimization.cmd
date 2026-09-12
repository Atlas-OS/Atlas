@echo off
:: ============================================
:: EBOS Process Optimization Wrapper Script
:: Purpose: Execute the complete optimization module
:: Effect: Applies all registry and PowerShell optimizations
:: ============================================

echo ============================================
echo EBOS Process Optimization Module
echo Version: 3.1.0
echo ============================================
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

echo [1/3] Applying registry optimizations...
regedit /s "%~dp0ServiceGroupingConsolidation.reg"
if %errorLevel% equ 0 (
    echo      Registry optimizations applied successfully.
) else (
    echo      WARNING: Some registry optimizations may have failed.
)

echo.
echo [2/3] Executing PowerShell optimization script...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Optimize-ProcessBaseline.ps1" -OptimizationLevel Aggressive -SkipWarnings
if %errorLevel% equ 0 (
    echo      PowerShell optimization completed successfully.
) else (
    echo      WARNING: PowerShell optimization encountered errors.
)

echo.
echo [3/3] Optimization complete!
echo.
echo ============================================
echo Summary:
echo - Registry optimizations applied
echo - 35 mandatory processes protected
echo - Non-essential services disabled
echo - UWP apps disabled
echo - Telemetry blocking enabled
echo - Automatic rollback script created
echo ============================================
echo.
echo Rollback script location: %ProgramData%\ProcessOptimization\Rollback_Script.ps1
echo Optimization log: %ProgramData%\ProcessOptimization\Optimization.log
echo.
pause