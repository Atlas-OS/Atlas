<#
.SYNOPSIS
    Restore Script for EBOS Process Optimization Module
.DESCRIPTION
    Restores the system to its pre-optimization state using the backup created by Backup-Optimization.ps1.
    Supports restoring registry, services, processes, network settings, and scheduled tasks.
.NOTES
    Author: EBOS Team
    Version: 3.1.0
    Requires: Windows 10/11, PowerShell 5.1+, Administrator rights
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestoreRegistry,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestoreServices,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestoreProcesses,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestoreNetwork,
    
    [Parameter(Mandatory=$false)]
    [switch]$RestoreAll
)

# ============================================
# Configuration
# ============================================

$RestoreLog = Join-Path $BackupPath "Restore.log"

# ============================================
# Functions
# ============================================

function Write-RestoreLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $RestoreLog -Value $logEntry
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG" { Write-Host $logEntry -ForegroundColor Gray }
    }
}

function Restore-RegistryFromBackup {
    Write-RestoreLog "Starting registry restoration..." -Level "INFO"
    
    $regFiles = Get-ChildItem -Path $BackupPath -Filter "*.reg"
    
    if ($regFiles.Count -eq 0) {
        Write-RestoreLog "No registry backup files found" -Level "WARNING"
        return
    }
    
    foreach ($file in $regFiles) {
        Write-RestoreLog "Importing: $($file.Name)" -Level "INFO"
        
        try {
            $result = reg import "$($file.FullName)" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-RestoreLog "Successfully imported: $($file.Name)" -Level "SUCCESS"
            } else {
                Write-RestoreLog "Failed to import: $($file.Name) - $result" -Level "ERROR"
            }
        } catch {
            Write-RestoreLog "Error importing $($file.Name): $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

function Restore-ServicesFromBackup {
    Write-RestoreLog "Starting services restoration..." -Level "INFO"
    
    $servicesBackup = Join-Path $BackupPath "Services_Backup.csv"
    
    if (-not (Test-Path $servicesBackup)) {
        Write-RestoreLog "Services backup not found, trying Critical_Services.txt..." -Level "WARNING"
        
        $servicesBackup = Join-Path $BackupPath "Critical_Services.txt"
        if (-not (Test-Path $servicesBackup)) {
            Write-RestoreLog "No services backup found" -Level "WARNING"
            return
        }
    }
    
    # Parse the backup file (CSV format)
    $services = Import-Csv -Path $servicesBackup -ErrorAction SilentlyContinue
    
    if (-not $services) {
        # Try text format
        $services = Get-Content $servicesBackup | Where-Object { $_ -match "^\S+" } | ForEach-Object {
            $parts = $_ -split "\s{2,}"
            if ($parts.Count -ge 3) {
                [PSCustomObject]@{
                    Name = $parts[0].Trim()
                    StartType = $parts[3].Trim()
                }
            }
        }
    }
    
    foreach ($service in $services) {
        if ($service.Name -and $service.StartType) {
            Write-RestoreLog "Restoring service: $($service.Name) to $($service.StartType)" -Level "INFO"
            
            try {
                # Map the backup start type to PowerShell service start type
                $startType = switch ($service.StartType) {
                    "Auto" { "Automatic" }
                    "Manual" { "Manual" }
                    "Disabled" { "Disabled" }
                    default { "Automatic" }
                }
                
                Set-Service -Name $service.Name -StartupType $startType -ErrorAction Stop
                Write-RestoreLog "Successfully restored: $($service.Name)" -Level "SUCCESS"
            } catch {
                Write-RestoreLog "Failed to restore $($service.Name): $($_.Exception.Message)" -Level "ERROR"
            }
        }
    }
}

function Restore-NetworkFromBackup {
    Write-RestoreLog "Starting network settings restoration..." -Level "INFO"
    
    $networkBackup = Join-Path $BackupPath "Network_Backup.csv"
    
    if (-not (Test-Path $networkBackup)) {
        Write-RestoreLog "Network backup not found" -Level "WARNING"
        return
    }
    
    try {
        $networkSettings = Import-Csv -Path $networkBackup
        
        foreach ($setting in $networkSettings) {
            if ($setting.RegistryPath -and $setting.RegistryName) {
                Write-RestoreLog "Restoring network setting: $($setting.RegistryName)" -Level "INFO"
                
                try {
                    $regPath = $setting.RegistryPath -replace "HKLM:", "HKLM:\"
                    Set-ItemProperty -Path $regPath -Name $setting.RegistryName -Value $setting.RegistryValue -ErrorAction Stop
                    Write-RestoreLog "Successfully restored: $($setting.RegistryName)" -Level "SUCCESS"
                } catch {
                    Write-RestoreLog "Failed to restore $($setting.RegistryName): $($_.Exception.Message)" -Level "ERROR"
                }
            }
        }
    } catch {
        Write-RestoreLog "Error restoring network settings: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Restore-CriticalServices {
    Write-RestoreLog "Restoring critical services..." -Level "INFO"
    
    $criticalServices = @(
        "RpcSs", "DcomLaunch", "Power", "AudioSrv", "AudioEndpointBuilder",
        "Dhcp", "Dnscache", "NLA", "nsi", "mpssvc",
        "EventLog", "CryptSvc", "ProfSvc", "gpsvc"
    )
    
    foreach ($service in $criticalServices) {
        try {
            Set-Service -Name $service -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $service -ErrorAction Stop
            Write-RestoreLog "Restored and started: $service" -Level "SUCCESS"
        } catch {
            Write-RestoreLog "Failed to restore $service : $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

function Restore-ScheduledTasks {
    Write-RestoreLog "Restoring scheduled tasks..." -Level "INFO"
    
    $tasksBackup = Join-Path $BackupPath "ScheduledTasks_Backup.csv"
    
    if (-not (Test-Path $tasksBackup)) {
        Write-RestoreLog "Scheduled tasks backup not found" -Level "WARNING"
        return
    }
    
    try {
        $tasks = Import-Csv -Path $tasksBackup
        
        foreach ($task in $tasks) {
            if ($task.TaskPath -and $task.TaskName) {
                Write-RestoreLog "Enabling task: $($task.TaskPath)$($task.TaskName)" -Level "INFO"
                
                try {
                    Enable-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName -ErrorAction Stop
                    Write-RestoreLog "Successfully enabled: $($task.TaskName)" -Level "SUCCESS"
                } catch {
                    Write-RestoreLog "Failed to enable $($task.TaskName): $($_.Exception.Message)" -Level "ERROR"
                }
            }
        }
    } catch {
        Write-RestoreLog "Error restoring scheduled tasks: $($_.Exception.Message)" -Level "ERROR"
    }
}

# ============================================
# Main Execution
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "EBOS Process Optimization Restore" -ForegroundColor Cyan
Write-Host "Version: 3.1.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Validate backup path
if (-not (Test-Path $BackupPath)) {
    Write-Host "ERROR: Backup path not found: $BackupPath" -ForegroundColor Red
    exit 1
}

# Check for backup summary
$summaryFile = Join-Path $BackupPath "Backup_Summary.txt"
if (Test-Path $summaryFile) {
    Write-Host "Backup Summary:" -ForegroundColor Yellow
    Get-Content $summaryFile | Write-Host -ForegroundColor White
    Write-Host ""
}

# Confirm restore
$confirm = Read-Host "Are you sure you want to restore from this backup? (Y/N)"
if ($confirm -ne "Y") {
    Write-Host "Restore cancelled." -ForegroundColor Yellow
    exit 0
}

Write-RestoreLog "Starting system restore from: $BackupPath" -Level "INFO"

# Execute restore based on parameters
if ($RestoreAll -or $RestoreRegistry) {
    Restore-RegistryFromBackup
}

if ($RestoreAll -or $RestoreServices) {
    Restore-ServicesFromBackup
}

if ($RestoreAll -or $RestoreNetwork) {
    Restore-NetworkFromBackup
}

if ($RestoreAll -or $RestoreProcesses) {
    Restore-ScheduledTasks
}

# Always restore critical services
Restore-CriticalServices

Write-RestoreLog "System restore completed" -Level "SUCCESS"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Restore Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "A system restart is recommended to apply all changes." -ForegroundColor Yellow
Write-Host ""
Write-Host "Do you want to restart now? (Y/N)" -ForegroundColor Yellow
$restart = Read-Host
if ($restart -eq "Y") {
    Restart-Computer -Force
}
