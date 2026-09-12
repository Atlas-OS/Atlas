<#
.SYNOPSIS
    Backup Script for EBOS Process Optimization Module
.DESCRIPTION
    Creates a comprehensive backup of the current system state before optimization.
    This includes registry, services, processes, and configuration files.
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
    [string]$BackupPath = "$env:ProgramData\ProcessOptimization\Backup",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateSystemRestorePoint
)

# ============================================
# Configuration
# ============================================

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFolder = Join-Path $BackupPath $Timestamp

# Critical registry paths to backup
$RegistryPaths = @(
    "HKLM\SYSTEM\CurrentControlSet\Control",
    "HKLM\SYSTEM\CurrentControlSet\Services",
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo",
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
)

# Critical services to monitor
$CriticalServices = @(
    "RpcSs", "DcomLaunch", "Power", "AudioSrv", "AudioEndpointBuilder",
    "Dhcp", "Dnscache", "NLA", "nsi", "mpssvc",
    "WinDefend", "MpsSvc", "WSearch", "Spooler"
)

# ============================================
# Functions
# ============================================

function Write-BackupLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path "$BackupFolder\Backup.log" -Value $logEntry
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

function Backup-Registry {
    Write-BackupLog "Starting registry backup..." -Level "INFO"
    
    foreach ($path in $RegistryPaths) {
        $fileName = $path -replace '\\', '_' -replace ':', ''
        $backupFile = Join-Path $BackupFolder "Registry_$fileName.reg"
        
        try {
            $regPath = $path -replace '\\', '\'
            if ($regPath -match "^HKLM\\") {
                $regPath = $regPath -replace "^HKLM\\", "HKEY_LOCAL_MACHINE\"
            }
            
            $result = reg export "$regPath" "$backupFile" /y 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-BackupLog "Backed up: $path" -Level "SUCCESS"
            } else {
                Write-BackupLog "Failed to backup: $path - $result" -Level "WARNING"
            }
        } catch {
            Write-BackupLog "Error backing up $path : $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

function Backup-Services {
    Write-BackupLog "Starting services backup..." -Level "INFO"
    
    $servicesFile = Join-Path $BackupFolder "Services_Backup.txt"
    
    # Get all services with their configurations
    $services = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, StartMode, State, PathName, StartName
    if ($services) {
        $services | Format-Table -AutoSize | Out-File $servicesFile
    } else {
        "No services found" | Out-File $servicesFile
    }
    
    # Get specific service configurations
    $serviceDetails = @()
    foreach ($service in $CriticalServices) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            $serviceDetails += [PSCustomObject]@{
                Name = $service
                DisplayName = $svc.DisplayName
                Status = $svc.Status
                StartType = $svc.StartType
            }
        }
    }
    
    $serviceDetails | Format-Table -AutoSize | Out-File (Join-Path $BackupFolder "Critical_Services.txt")
    
    Write-BackupLog "Services backup completed" -Level "SUCCESS"
}

function Backup-Processes {
    Write-BackupLog "Starting processes backup..." -Level "INFO"
    
    $processesFile = Join-Path $BackupFolder "Processes_Backup.txt"
    
    # Get all running processes with details
    $processes = Get-Process | Select-Object Id, ProcessName, Path, Company, Description, StartTime
    $processes | Format-Table -AutoSize | Out-File $processesFile
    
    # Get process count
    $processCount = $processes.Count
    Write-BackupLog "Current process count: $processCount" -Level "INFO"
    
    # Get svchost instances
    $svchostCount = ($processes | Where-Object { $_.ProcessName -eq "svchost.exe" }).Count
    Write-BackupLog "Current svchost instances: $svchostCount" -Level "INFO"
    
    Write-BackupLog "Processes backup completed" -Level "SUCCESS"
}

function Backup-SystemRestorePoint {
    Write-BackupLog "Creating system restore point..." -Level "INFO"
    
    try {
        # Enable System Restore on C: drive
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        
        # Create restore point
        Checkpoint-Computer -Description "EBOS Process Optimization Backup" -RestorePointType MODIFY_SETTINGS
        
        Write-BackupLog "System restore point created successfully" -Level "SUCCESS"
    } catch {
        Write-BackupLog "Failed to create system restore point: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Backup-ConfigurationFiles {
    Write-BackupLog "Starting configuration files backup..." -Level "INFO"
    
    $configFiles = @(
        "$env:SystemRoot\System32\drivers\etc\hosts",
        "$env:SystemRoot\System32\drivers\etc\lmhosts.sam",
        "$env:SystemRoot\System32\drivers\etc\networks",
        "$env:SystemRoot\System32\drivers\etc\protocol",
        "$env:SystemRoot\System32\drivers\etc\services"
    )
    
    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            $destFile = Join-Path $BackupFolder (Split-Path $file -Leaf)
            Copy-Item -Path $file -Destination $destFile -Force -ErrorAction SilentlyContinue
            Write-BackupLog "Backed up: $file" -Level "SUCCESS"
        }
    }
}

function Backup-NetworkSettings {
    Write-BackupLog "Starting network settings backup..." -Level "INFO"
    
    $networkFile = Join-Path $BackupFolder "Network_Settings.txt"
    
    # Get network adapters
    $adapters = Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed
    $adapters | Format-Table -AutoSize | Out-File $networkFile
    
    # Get IP configuration
    $ipConfig = Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer
    $ipConfig | Format-Table -AutoSize | Out-File (Join-Path $BackupFolder "IP_Configuration.txt")
    
    # Get DNS client settings
    $dnsSettings = Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses
    $dnsSettings | Format-Table -AutoSize | Out-File (Join-Path $BackupFolder "DNS_Settings.txt")
    
    Write-BackupLog "Network settings backup completed" -Level "SUCCESS"
}

function Backup-WindowsDefender {
    Write-BackupLog "Starting Windows Defender backup..." -Level "INFO"
    
    try {
        $defenderStatus = Get-MpComputerStatus
        $defenderSettings = Get-MpPreference
        
        $defenderBackup = [PSCustomObject]@{
            RealTimeProtectionEnabled = $defenderStatus.RealTimeProtectionEnabled
            AntivirusEnabled = $defenderStatus.AntivirusEnabled
            AntispywareEnabled = $defenderStatus.AntispywareEnabled
            AntivirusSignatureLastUpdated = $defenderStatus.AntivirusSignatureLastUpdated
            DisableRealtimeMonitoring = $defenderSettings.DisableRealtimeMonitoring
            DisableBehaviorMonitoring = $defenderSettings.DisableBehaviorMonitoring
            DisableOnAccessProtection = $defenderSettings.DisableOnAccessProtection
            DisableScanOnRealtimeEnable = $defenderSettings.DisableScanOnRealtimeEnable
        }
        
        $defenderBackup | Format-Table -AutoSize | Out-File (Join-Path $BackupFolder "Windows_Defender.txt")
        
        Write-BackupLog "Windows Defender backup completed" -Level "SUCCESS"
    } catch {
        Write-BackupLog "Failed to backup Windows Defender settings: $($_.Exception.Message)" -Level "WARNING"
    }
}

# ============================================
# Main Execution
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "EBOS Process Optimization Backup" -ForegroundColor Cyan
Write-Host "Version: 3.1.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create backup folder
if (-not (Test-Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
}

Write-BackupLog "Backup started" -Level "INFO"
Write-BackupLog "Backup location: $BackupFolder" -Level "INFO"

# Execute backups
Backup-Registry
Backup-Services
Backup-Processes
Backup-ConfigurationFiles
Backup-NetworkSettings
Backup-WindowsDefender

if ($CreateSystemRestorePoint) {
    Backup-SystemRestorePoint
}

# Create backup summary
$summary = @"
EBOS Process Optimization Backup Summary
========================================
Date: $(Get-Date)
Backup Location: $BackupFolder

Contents:
- Registry backups (*.reg)
- Services backup (Services_Backup.txt)
- Critical services (Critical_Services.txt)
- Processes backup (Processes_Backup.txt)
- Configuration files
- Network settings
- Windows Defender settings
- Backup log (Backup.log)

To restore:
1. Import .reg files using regedit
2. Restore services using sc config commands
3. Use this backup as reference for manual restoration
"@

$summary | Out-File (Join-Path $BackupFolder "Backup_Summary.txt")

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Backup Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backup location: $BackupFolder" -ForegroundColor Green
Write-Host "Backup log: $BackupFolder\Backup.log" -ForegroundColor Green
Write-Host ""
Write-Host "Contents:" -ForegroundColor Yellow
Get-ChildItem $BackupFolder | ForEach-Object { Write-Host "  - $($_.Name) ($($_.Length) bytes)" -ForegroundColor White }
Write-Host ""