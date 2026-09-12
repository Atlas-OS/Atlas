<#
.SYNOPSIS
    Monitoring Script for EBOS Process Optimization Module
.DESCRIPTION
    Monitors the optimization process in real-time and provides status updates.
    This script can be run alongside the optimization to track progress.
.NOTES
    Author: Senior Windows Kernel Engineer
    Version: 3.1.0
    Requires: Windows 10/11, PowerShell 5.1+
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [int]$RefreshInterval = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$LogToFile,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:ProgramData\ProcessOptimization"
)

# ============================================
# Configuration
# ============================================

$MonitorLog = Join-Path $LogPath "Monitor.log"
$ProcessHistory = @()
$ServiceHistory = @()

# ============================================
# Functions
# ============================================

function Write-MonitorLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($LogToFile) {
        Add-Content -Path $MonitorLog -Value $logEntry
    }
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

function Get-ProcessStats {
    $processes = Get-Process
    $stats = [PSCustomObject]@{
        Total = $processes.Count
        Svchost = ($processes | Where-Object { $_.ProcessName -eq "svchost.exe" }).Count
        Microsoft = ($processes | Where-Object { $_.Company -like "*Microsoft*" }).Count
        User = ($processes | Where-Object { $_.Company -notlike "*Microsoft*" -and $_.Company -ne "" }).Count
        Unknown = ($processes | Where-Object { $_.Company -eq "" }).Count
    }
    return $stats
}

function Get-ServiceStats {
    $services = Get-Service
    $stats = [PSCustomObject]@{
        Total = $services.Count
        Running = ($services | Where-Object { $_.Status -eq "Running" }).Count
        Stopped = ($services | Where-Object { $_.Status -eq "Stopped" }).Count
        Disabled = ($services | Where-Object { $_.StartType -eq "Disabled" }).Count
    }
    return $stats
}

function Get-NetworkStats {
    try {
        $stats = [PSCustomObject]@{
            Connections = (Get-NetTCPConnection -ErrorAction SilentlyContinue).Count
            Listening = (Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue).Count
            Established = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
        }
        return $stats
    } catch {
        return [PSCustomObject]@{
            Connections = 0
            Listening = 0
            Established = 0
        }
    }
}

function Get-MemoryStats {
    $os = Get-CimInstance Win32_OperatingSystem
    $stats = [PSCustomObject]@{
        TotalMemory = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        FreeMemory = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        UsedMemory = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
        UsagePercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
    }
    return $stats
}

function Display-Status {
    Clear-Host
    
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "EBOS Process Optimization Monitor" -ForegroundColor Cyan
    Write-Host "Version: 3.1.0" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    $processStats = Get-ProcessStats
    $serviceStats = Get-ServiceStats
    $networkStats = Get-NetworkStats
    $memoryStats = Get-MemoryStats
    
    Write-Host "Process Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Processes: $($processStats.Total)" -ForegroundColor White
    Write-Host "  Svchost Instances: $($processStats.Svchost)" -ForegroundColor White
    Write-Host "  Microsoft Processes: $($processStats.Microsoft)" -ForegroundColor White
    Write-Host "  User Processes: $($processStats.User)" -ForegroundColor White
    Write-Host "  Unknown Processes: $($processStats.Unknown)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Service Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Services: $($serviceStats.Total)" -ForegroundColor White
    Write-Host "  Running: $($serviceStats.Running)" -ForegroundColor Green
    Write-Host "  Stopped: $($serviceStats.Stopped)" -ForegroundColor Red
    Write-Host "  Disabled: $($serviceStats.Disabled)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Network Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Connections: $($networkStats.Connections)" -ForegroundColor White
    Write-Host "  Listening: $($networkStats.Listening)" -ForegroundColor White
    Write-Host "  Established: $($networkStats.Established)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Memory Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Memory: $($memoryStats.TotalMemory) GB" -ForegroundColor White
    Write-Host "  Used Memory: $($memoryStats.UsedMemory) GB" -ForegroundColor White
    Write-Host "  Free Memory: $($memoryStats.FreeMemory) GB" -ForegroundColor Green
    Write-Host "  Usage: $($memoryStats.UsagePercent)%" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Monitoring Status:" -ForegroundColor Yellow
    Write-Host "  Refresh Interval: $RefreshInterval seconds" -ForegroundColor White
    Write-Host "  Press Ctrl+C to stop monitoring" -ForegroundColor White
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Last Updated: $timestamp" -ForegroundColor Gray
}

function Monitor-Optimization {
    Write-MonitorLog "Starting optimization monitoring..." -Level "INFO"
    
    while ($true) {
        Display-Status
        
        # Track history
        $processStats = Get-ProcessStats
        $serviceStats = Get-ServiceStats
        
        $script:ProcessHistory += [PSCustomObject]@{
            Timestamp = Get-Date
            Total = $processStats.Total
            Svchost = $processStats.Svchost
        }
        
        $script:ServiceHistory += [PSCustomObject]@{
            Timestamp = Get-Date
            Running = $serviceStats.Running
            Disabled = $serviceStats.Disabled
        }
        
        # Keep only last 100 entries
        if ($script:ProcessHistory.Count -gt 100) {
            $script:ProcessHistory = $script:ProcessHistory[-100..-1]
        }
        if ($script:ServiceHistory.Count -gt 100) {
            $script:ServiceHistory = $script:ServiceHistory[-100..-1]
        }
        
        Start-Sleep -Seconds $RefreshInterval
    }
}

function Show-History {
    Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Process History (Last 10 entries)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
    
    $script:ProcessHistory | Select-Object -Last 10 | Format-Table -AutoSize
    
    Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Service History (Last 10 entries)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
    
    $script:ServiceHistory | Select-Object -Last 10 | Format-Table -AutoSize
}

# ============================================
# Main Execution
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "EBOS Process Optimization Monitor" -ForegroundColor Cyan
Write-Host "Version: 2.0.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Options:" -ForegroundColor Yellow
Write-Host "  1. Start real-time monitoring" -ForegroundColor White
Write-Host "  2. Show current status" -ForegroundColor White
Write-Host "  3. Show history" -ForegroundColor White
Write-Host "  4. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Select an option (1-4)"

switch ($choice) {
    "1" {
        Monitor-Optimization
    }
    "2" {
        Display-Status
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    "3" {
        Show-History
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    "4" {
        Write-Host "Exiting..." -ForegroundColor Yellow
    }
    default {
        Write-Host "Invalid option. Exiting..." -ForegroundColor Red
    }
}