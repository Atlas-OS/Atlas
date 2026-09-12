<#
.SYNOPSIS
    Test Script for EBOS Process Optimization Module
.DESCRIPTION
    Verifies that all optimization components are properly configured and functional.
    This script does not make changes - it only validates the current state.
.NOTES
    Author: Senior Windows Kernel Engineer
    Version: 3.1.0
    Requires: Windows 10/11, PowerShell 5.1+, Administrator rights
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput
)

# ============================================
# Test Results Storage
# ============================================

$TestResults = @()
$TestPass = 0
$TestFail = 0
$TestWarn = 0

function Add-TestResult {
    param(
        [string]$TestName,
        [ValidateSet("PASS", "FAIL", "WARN")]
        [string]$Status,
        [string]$Message
    )
    
    $script:TestResults += [PSCustomObject]@{
        TestName = $TestName
        Status = $Status
        Message = $Message
    }
    
    switch ($Status) {
        "PASS" { $script:TestPass++ }
        "FAIL" { $script:TestFail++ }
        "WARN" { $script:TestWarn++ }
    }
    
    if ($DetailedOutput) {
        switch ($Status) {
            "PASS" { Write-Host "[PASS] $TestName : $Message" -ForegroundColor Green }
            "FAIL" { Write-Host "[FAIL] $TestName : $Message" -ForegroundColor Red }
            "WARN" { Write-Host "[WARN] $TestName : $Message" -ForegroundColor Yellow }
        }
    }
}

# ============================================
# Test Functions
# ============================================

function Test-ModuleFiles {
    Write-Host "Testing module files..." -ForegroundColor Cyan
    
    $modulePath = "$PSScriptRoot"
    $requiredFiles = @(
        "ServiceGroupingConsolidation.reg",
        "Optimize-ProcessBaseline.ps1",
        "ProcessProtection.xml",
        "InjectionConfig.yaml",
        "OptimizationConfig.yaml",
        "ExecuteOptimization.cmd",
        "Deploy-Optimization.cmd",
        "Backup-Optimization.ps1",
        "Restore-Optimization.ps1",
        "Monitor-Optimization.ps1",
        "Test-Optimization.ps1",
        "README.md"
    )
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $modulePath $file
        if (Test-Path $filePath) {
            $fileInfo = Get-Item $filePath
            if ($fileInfo.Length -gt 0) {
                Add-TestResult -TestName "File: $file" -Status "PASS" -Message "Exists ($($fileInfo.Length) bytes)"
            } else {
                Add-TestResult -TestName "File: $file" -Status "FAIL" -Message "File exists but is empty"
            }
        } else {
            Add-TestResult -TestName "File: $file" -Status "FAIL" -Message "File not found"
        }
    }
}

function Test-RegistryOptimizations {
    Write-Host "Testing registry optimizations..." -ForegroundColor Cyan
    
    $regTests = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Name = "SvcHostSplitThresholdInKB"; Expected = 4294967295; Description = "Service host consolidation" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "DisablePagingExecutive"; Expected = 1; Description = "Disable paging executive" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "LargeSystemCache"; Expected = 0; Description = "Small system cache (desktop)" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "Win32PrioritySeparation"; Expected = 38; Description = "Process priority separation" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "MaxUserPort"; Expected = 65534; Description = "Max ephemeral port" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpTimedWaitDelay"; Expected = 30; Description = "TCP TIME_WAIT delay" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "DefaultTTL"; Expected = 64; Description = "Default TTL" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"; Name = "MaxCacheTtl"; Expected = 3600; Description = "DNS max cache TTL" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"; Name = "MaxNegativeCacheTtl"; Expected = 5; Description = "DNS negative cache TTL" }
    )
    
    foreach ($test in $regTests) {
        try {
            $actual = Get-ItemProperty -Path $test.Path -Name $test.Name -ErrorAction SilentlyContinue
            if ($actual) {
                $actualValue = $actual.$($test.Name)
                if ($actualValue -eq $test.Expected) {
                    Add-TestResult -TestName "Reg: $($test.Description)" -Status "PASS" -Message "$($test.Name) = $actualValue"
                } else {
                    Add-TestResult -TestName "Reg: $($test.Description)" -Status "WARN" -Message "$($test.Name) = $actualValue (expected $($test.Expected))"
                }
            } else {
                Add-TestResult -TestName "Reg: $($test.Description)" -Status "FAIL" -Message "Registry key not found: $($test.Path)\$($test.Name)"
            }
        } catch {
            Add-TestResult -TestName "Reg: $($test.Description)" -Status "FAIL" -Message "Error: $($_.Exception.Message)"
        }
    }
}

function Test-ProtectedProcesses {
    Write-Host "Testing protected processes..." -ForegroundColor Cyan
    
    $protectedProcesses = @(
        "System Idle Process", "System", "Registry", "smss", "csrss",
        "wininit", "services", "lsass", "winlogon", "LsaIso",
        "svchost", "dwm", "explorer", "sihost", "fontdrvhost",
        "ctfmon", "taskhostw", "RuntimeBroker", "audiodg",
        "spoolsv", "conhost", "wlanext"
    )
    
    $runningProcesses = Get-Process | Select-Object -ExpandProperty ProcessName -Unique
    
    $missingCount = 0
    $runningCount = 0
    foreach ($process in $protectedProcesses) {
        if ($process -in $runningProcesses) {
            $runningCount++
        } else {
            $missingCount++
            if ($DetailedOutput) {
                Add-TestResult -TestName "Proc: $process" -Status "WARN" -Message "Not currently running"
            }
        }
    }
    
    if ($missingCount -eq 0) {
        Add-TestResult -TestName "Protected Processes" -Status "PASS" -Message "All $runningCount protected processes running"
    } else {
        Add-TestResult -TestName "Protected Processes" -Status "WARN" -Message "$runningCount running, $missingCount not running (may be normal)"
    }
}

function Test-Services {
    Write-Host "Testing disabled services..." -ForegroundColor Cyan
    
    $servicesToCheck = @(
        "DiagTrack", "dmwappushservice", "DPS", "WdiServiceHost",
        "MapsBroker", "lfsvc", "wuauserv", "UsoSvc", "WaaSMedicSvc",
        "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "XboxGipSvc",
        "PhoneSvc", "MessagingService", "RetailDemo", "WSearch",
        "bthserv", "BluetoothUserService", "SysMain", "Ndu"
    )
    
    $disabledCount = 0
    foreach ($service in $servicesToCheck) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.StartType -eq 'Disabled') {
                $disabledCount++
            } else {
                Add-TestResult -TestName "Svc: $service" -Status "WARN" -Message "StartType = $($svc.StartType) (expected Disabled)"
            }
        } else {
            $disabledCount++
        }
    }
    
    Add-TestResult -TestName "Disabled Services" -Status $(if ($disabledCount -eq $servicesToCheck.Count) { "PASS" } else { "WARN" }) -Message "$disabledCount of $($servicesToCheck.Count) disabled"
}

function Test-ScheduledTasks {
    Write-Host "Testing scheduled tasks..." -ForegroundColor Cyan
    
    $tasksToCheck = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    )
    
    $disabledCount = 0
    foreach ($task in $tasksToCheck) {
        $taskObj = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        if ($taskObj) {
            if ($taskObj.State -eq 'Disabled') {
                $disabledCount++
            } else {
                Add-TestResult -TestName "Task: $(Split-Path $task -Leaf)" -Status "WARN" -Message "State = $($taskObj.State) (expected Disabled)"
            }
        } else {
            $disabledCount++
        }
    }
    
    Add-TestResult -TestName "Scheduled Tasks" -Status $(if ($disabledCount -eq $tasksToCheck.Count) { "PASS" } else { "WARN" }) -Message "$disabledCount of $($tasksToCheck.Count) disabled"
}

function Test-TelemetryBlocking {
    Write-Host "Testing telemetry blocking..." -ForegroundColor Cyan
    
    $telemetryTests = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Expected = 0 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Expected = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Expected = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsRunInBackground"; Expected = 2 }
    )
    
    $blockedCount = 0
    foreach ($test in $telemetryTests) {
        $actual = Get-ItemProperty -Path $test.Path -Name $test.Name -ErrorAction SilentlyContinue
        if ($actual -and $actual.$($test.Name) -eq $test.Expected) {
            $blockedCount++
        } else {
            Add-TestResult -TestName "Telemetry: $($test.Name)" -Status "WARN" -Message "Not set or incorrect value"
        }
    }
    
    Add-TestResult -TestName "Telemetry Blocking" -Status $(if ($blockedCount -eq $telemetryTests.Count) { "PASS" } else { "WARN" }) -Message "$blockedCount of $($telemetryTests.Count) blocked"
}

function Test-ProcessCount {
    Write-Host "Testing process count..." -ForegroundColor Cyan
    
    $processCount = (Get-Process).Count
    $svchostCount = (Get-Process -Name svchost -ErrorAction SilentlyContinue).Count
    
    if ($processCount -le 45) {
        Add-TestResult -TestName "Process Count" -Status "PASS" -Message "$processCount processes (target: <=45)"
    } elseif ($processCount -le 75) {
        Add-TestResult -TestName "Process Count" -Status "WARN" -Message "$processCount processes (target: <=45, acceptable: <=75)"
    } else {
        Add-TestResult -TestName "Process Count" -Status "FAIL" -Message "$processCount processes (target: <=45)"
    }
    
    if ($svchostCount -le 10) {
        Add-TestResult -TestName "Svchost Count" -Status "PASS" -Message "$svchostCount instances (target: <=10)"
    } else {
        Add-TestResult -TestName "Svchost Count" -Status "WARN" -Message "$svchostCount instances (target: <=10)"
    }
}

function Test-Logging {
    Write-Host "Testing logging..." -ForegroundColor Cyan
    
    $logPath = "$env:ProgramData\ProcessOptimization"
    
    if (Test-Path $logPath) {
        Add-TestResult -TestName "Log Directory" -Status "PASS" -Message "$logPath exists"
        
        $logFiles = Get-ChildItem -Path $logPath -Filter "Optimization_*.log" -ErrorAction SilentlyContinue
        if ($logFiles.Count -gt 0) {
            $latest = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Add-TestResult -TestName "Log Files" -Status "PASS" -Message "$($logFiles.Count) log files, latest: $($latest.Name)"
        } else {
            Add-TestResult -TestName "Log Files" -Status "WARN" -Message "No optimization log files found"
        }
    } else {
        Add-TestResult -TestName "Log Directory" -Status "WARN" -Message "Directory not found (run optimization first)"
    }
}

function Test-Rollback {
    Write-Host "Testing rollback capability..." -ForegroundColor Cyan
    
    $rollbackPath = "$env:ProgramData\ProcessOptimization"
    $rollbackScript = "$rollbackPath\Rollback_Script.ps1"
    $rollbackData = "$rollbackPath\Rollback.txt"
    
    if (Test-Path $rollbackScript) {
        Add-TestResult -TestName "Rollback Script" -Status "PASS" -Message "Rollback_Script.ps1 exists"
        
        $rollbackContent = Get-Content $rollbackScript -Raw -ErrorAction SilentlyContinue
        if ($rollbackContent -match "SvcHostSplitThresholdInKB" -and $rollbackContent -match "AllowTelemetry" -and $rollbackContent -match "ScheduledTask") {
            Add-TestResult -TestName "Rollback Content" -Status "PASS" -Message "Contains restoration commands"
        } else {
            Add-TestResult -TestName "Rollback Content" -Status "WARN" -Message "May be incomplete"
        }
    } else {
        Add-TestResult -TestName "Rollback Script" -Status "WARN" -Message "Not found (run optimization first)"
    }
    
    if (Test-Path $rollbackData) {
        $serviceCount = (Get-Content $rollbackData | Measure-Object).Count
        Add-TestResult -TestName "Rollback Data" -Status "PASS" -Message "Rollback.txt has $serviceCount service entries"
    } else {
        Add-TestResult -TestName "Rollback Data" -Status "WARN" -Message "Rollback.txt not found"
    }
}

# ============================================
# Main Execution
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "EBOS Process Optimization Test Suite" -ForegroundColor Cyan
Write-Host "Version: 3.1.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running tests..." -ForegroundColor Yellow
Write-Host ""

Test-ModuleFiles
Test-RegistryOptimizations
Test-ProtectedProcesses
Test-Services
Test-ScheduledTasks
Test-TelemetryBlocking
Test-ProcessCount
Test-Logging
Test-Rollback

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestPass + $TestFail + $TestWarn)" -ForegroundColor White
Write-Host "Passed: $TestPass" -ForegroundColor Green
Write-Host "Failed: $TestFail" -ForegroundColor Red
Write-Host "Warnings: $TestWarn" -ForegroundColor Yellow
Write-Host ""

if ($TestFail -eq 0) {
    Write-Host "STATUS: All critical tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "STATUS: Some tests failed. Please review the results above." -ForegroundColor Red
    exit 1
}
