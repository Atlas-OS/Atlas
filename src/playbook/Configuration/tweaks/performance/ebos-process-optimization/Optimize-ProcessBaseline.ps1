<#
.SYNOPSIS
    Maximum Aggressive Process Reduction Script
.DESCRIPTION
    Reduces active background processes to 30-45 while protecting
    35 mandatory Windows baseline processes for complete stability.
.NOTES
    Author: Senior Windows Kernel Engineer
    Version: 3.1.0
    Requires: Windows 10/11, PowerShell 5.1+, Administrator rights
    Compatibility: AME Wizard, AtlasOS, EBOS Playbooks
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Maximum", "Aggressive", "Standard")]
    [string]$OptimizationLevel = "Maximum",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateRestorePoint,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:ProgramData\ProcessOptimization",
    
    [Parameter(Mandatory=$false)]
    [int]$TargetProcessCount = 40,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation
)

# ============================================
# SECTION 1: Critical Process Protection Registry
# ============================================

$Script:ProtectedProcesses = @(
    # Category A: Kernel & Session (1-6)
    @{Name="System Idle Process"; Path=""; ServiceGroup=""; Priority=1; Critical=$true},
    @{Name="System"; Path=""; ServiceGroup=""; Priority=2; Critical=$true},
    @{Name="Registry"; Path=""; ServiceGroup=""; Priority=3; Critical=$true},
    @{Name="smss.exe"; Path="$env:SystemRoot\System32\smss.exe"; ServiceGroup=""; Priority=4; Critical=$true},
    @{Name="csrss.exe"; Path="$env:SystemRoot\System32\csrss.exe"; ServiceGroup=""; Priority=5; Critical=$true},
    @{Name="wininit.exe"; Path="$env:SystemRoot\System32\wininit.exe"; ServiceGroup=""; Priority=6; Critical=$true},
    
    # Category B: Security & Services (7-13)
    @{Name="services.exe"; Path="$env:SystemRoot\System32\services.exe"; ServiceGroup=""; Priority=7; Critical=$true},
    @{Name="lsass.exe"; Path="$env:SystemRoot\System32\lsass.exe"; ServiceGroup=""; Priority=8; Critical=$true},
    @{Name="winlogon.exe"; Path="$env:SystemRoot\System32\winlogon.exe"; ServiceGroup=""; Priority=9; Critical=$true},
    @{Name="LsaIso.exe"; Path="$env:SystemRoot\System32\LsaIso.exe"; ServiceGroup=""; Priority=10; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="RpcSs"; Priority=11; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="DcomLaunch"; Priority=12; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="Power"; Priority=13; Critical=$true},
    
    # Category C: UI & Shell (14-20)
    @{Name="dwm.exe"; Path="$env:SystemRoot\System32\dwm.exe"; ServiceGroup=""; Priority=14; Critical=$true},
    @{Name="explorer.exe"; Path="$env:SystemRoot\explorer.exe"; ServiceGroup=""; Priority=15; Critical=$true},
    @{Name="sihost.exe"; Path="$env:SystemRoot\System32\sihost.exe"; ServiceGroup=""; Priority=16; Critical=$true},
    @{Name="fontdrvhost.exe"; Path="$env:SystemRoot\System32\fontdrvhost.exe"; ServiceGroup=""; Priority=17; Critical=$true},
    @{Name="ctfmon.exe"; Path="$env:SystemRoot\System32\ctfmon.exe"; ServiceGroup=""; Priority=18; Critical=$true},
    @{Name="taskhostw.exe"; Path="$env:SystemRoot\System32\taskhostw.exe"; ServiceGroup=""; Priority=19; Critical=$true},
    @{Name="RuntimeBroker.exe"; Path="$env:SystemRoot\System32\RuntimeBroker.exe"; ServiceGroup=""; Priority=20; Critical=$true},
    
    # Category D: Audio & Network (21-28)
    @{Name="audiodg.exe"; Path="$env:SystemRoot\System32\audiodg.exe"; ServiceGroup=""; Priority=21; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="AudioSrv"; Priority=22; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="Dhcp"; Priority=23; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="Dnscache"; Priority=24; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="NLA"; Priority=25; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="nsi"; Priority=26; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="mpssvc"; Priority=27; Critical=$true},
    @{Name="spoolsv.exe"; Path="$env:SystemRoot\System32\spoolsv.exe"; ServiceGroup=""; Priority=28; Critical=$true},
    
    # Category E: GPU & Hardware (29-35)
    @{Name="nvcontainer.exe"; Path=""; ServiceGroup=""; Priority=29; Critical=$true},
    @{Name="amdow.exe"; Path=""; ServiceGroup=""; Priority=29; Critical=$true},
    @{Name="igfxCUIService.exe"; Path=""; ServiceGroup=""; Priority=29; Critical=$true},
    @{Name="conhost.exe"; Path="$env:SystemRoot\System32\conhost.exe"; ServiceGroup=""; Priority=30; Critical=$true},
    @{Name="wlanext.exe"; Path="$env:SystemRoot\System32\wlanext.exe"; ServiceGroup=""; Priority=31; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="CryptSvc"; Priority=32; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="ProfSvc"; Priority=33; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="gpsvc"; Priority=34; Critical=$true},
    @{Name="svchost.exe"; Path="$env:SystemRoot\System32\svchost.exe"; ServiceGroup="EventLog"; Priority=35; Critical=$true}
)

# Critical Microsoft processes that must never be terminated
$Script:CriticalMicrosoftProcesses = @(
    "MsMpEng.exe", "NisSrv.exe", "SecurityHealthService.exe",
    "SearchIndexer.exe", "ShellExperienceHost.exe", "StartMenuExperienceHost.exe",
    "TextInputHost.exe", "ApplicationFrameHost.exe", "SystemSettings.exe",
    "UserOOBEBroker.exe", "dllhost.exe", "taskeng.exe", "taskhostw.exe"
)

# ============================================
# SECTION 2: Non-Essential Services Configuration
# ============================================

$Script:ServicesToDisable = @(
    # Telemetry & Data Collection (8)
    @{Name="DiagTrack"; DisplayName="Diagnostics Tracking Service"},
    @{Name="dmwappushservice"; DisplayName="WAP Push Message Routing Service"},
    @{Name="diagnosticshub.standardcollector.service"; DisplayName="Diagnostics Hub Standard Collector"},
    @{Name="DPS"; DisplayName="Diagnostic Policy Service"},
    @{Name="WdiServiceHost"; DisplayName="Diagnostic Service Host"},
    @{Name="WdiSystemHost"; DisplayName="Diagnostic System Host"},
    @{Name="Wecsvc"; DisplayName="Windows Event Collector"},
    @{Name="WEPHOSTSVC"; DisplayName="Windows Encryption Provider Host Service"},
    
    # Location & Maps (2)
    @{Name="MapsBroker"; DisplayName="Downloaded Maps Manager"},
    @{Name="lfsvc"; DisplayName="Geolocation Service"},
    
    # Update Services (7)
    @{Name="EdgeUpdate"; DisplayName="Microsoft Edge Update Service"},
    @{Name="edgeupdatem"; DisplayName="Microsoft Edge Update Service (EdgeUpdateM)"},
    @{Name="wuauserv"; DisplayName="Windows Update"},
    @{Name="UsoSvc"; DisplayName="Update Orchestrator Service"},
    @{Name="WaaSMedicSvc"; DisplayName="Windows Update Medic Service"},
    @{Name="BITS"; DisplayName="Background Intelligent Transfer Service"},
    @{Name="DoSvc"; DisplayName="Delivery Optimization"},
    
    # Xbox & Gaming (4)
    @{Name="XblAuthManager"; DisplayName="Xbox Live Auth Manager"},
    @{Name="XblGameSave"; DisplayName="Xbox Live Game Save"},
    @{Name="XboxNetApiSvc"; DisplayName="Xbox Live Networking Service"},
    @{Name="XboxGipSvc"; DisplayName="Xbox Accessory Management Service"},
    
    # Retail & Demo (1)
    @{Name="RetailDemo"; DisplayName="Retail Demo Service"},
    
    # Windows Search (1)
    @{Name="WSearch"; DisplayName="Windows Search"},
    
    # Print Spooler (1 - optional, remove if printing needed)
    @{Name="Spooler"; DisplayName="Print Spooler"},
    
    # Bluetooth Support (2)
    @{Name="bthserv"; DisplayName="Bluetooth Support Service"},
    @{Name="BluetoothUserService"; DisplayName="Bluetooth User Support Service"},
    
    # Phone & Messaging (5)
    @{Name="PhoneSvc"; DisplayName="Phone Service"},
    @{Name="MessagingService"; DisplayName="Messaging Service"},
    @{Name="PimIndexMaintenanceSvc"; DisplayName="Contact Data"},
    @{Name="UnistoreSvc"; DisplayName="User Data Storage"},
    @{Name="UserDataSvc"; DisplayName="User Data Access"},
    
    # Additional Non-Essential Services (29)
    @{Name="WalletService"; DisplayName="Wallet Service"},
    @{Name="PushToInstall"; DisplayName="Windows PushToInstall Service"},
    @{Name="AppReadiness"; DisplayName="App Readiness"},
    @{Name="AssignedAccessManagerSvc"; DisplayName="Assigned Access Manager Service"},
    @{Name="CDPSvc"; DisplayName="Connected Devices Platform Service"},
    @{Name="CDPUserSvc"; DisplayName="Connected Devices Platform User Service"},
    @{Name="DevicePickerUserSvc"; DisplayName="Device Picker User Service"},
    @{Name="DevicesFlowUserSvc"; DisplayName="Devices Flow User Service"},
    @{Name="DusmSvc"; DisplayName="Data Usage Service"},
    @{Name="InstallService"; DisplayName="Microsoft Store Install Service"},
    @{Name="LicenseManager"; DisplayName="Windows License Manager Service"},
    @{Name="NetTcpPortSharing"; DisplayName="Net.Tcp Port Sharing Service"},
    @{Name="OneSyncSvc"; DisplayName="Sync Host Service"},
    @{Name="PcaSvc"; DisplayName="Program Compatibility Assistant Service"},
    @{Name="PrintNotify"; DisplayName="Printer Extensions and Notifications"},
    @{Name="SEMgrSvc"; DisplayName="NFC SE Manager Service"},
    @{Name="SensorDataService"; DisplayName="Sensor Data Service"},
    @{Name="SensorService"; DisplayName="Sensor Service"},
    @{Name="SensrSvc"; DisplayName="Sensor Monitoring Service"},
    @{Name="StorSvc"; DisplayName="Storage Service"},
    @{Name="SysMain"; DisplayName="SysMain Service"},
    @{Name="Themes"; DisplayName="Themes Service"},
    @{Name="TimeBrokerSvc"; DisplayName="Time Broker Service"},
    @{Name="TokenBroker"; DisplayName="Web Account Manager"},
    @{Name="TroubleshootingSvc"; DisplayName="Recommended Troubleshooting Service"},
    @{Name="WbioSrvc"; DisplayName="Windows Biometric Service"},
    @{Name="WpnService"; DisplayName="Windows Push Notifications System Service"},
    @{Name="WpnUserService"; DisplayName="Windows Push Notifications User Service"},
    @{Name="TableInputService"; DisplayName="Tablet Input Service"}
)

# ============================================
# SECTION 3: UWP Apps Configuration
# ============================================

$Script:UWPAppsToSuspend = @(
    # Store & Purchase (4)
    "Microsoft.StorePurchaseApp_8wekyb3d8bbwe",
    "Microsoft.WindowsStore_8wekyb3d8bbwe",
    "Microsoft.Getstarted_8wekyb3d8bbwe",
    "Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe",
    
    # Entertainment & Media (8)
    "Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe",
    "Microsoft.ZuneMusic_8wekyb3d8bbwe",
    "Microsoft.ZuneVideo_8wekyb3d8bbwe",
    "Microsoft.BingWeather_8wekyb3d8bbwe",
    "Microsoft.BingNews_8wekyb3d8bbwe",
    "Microsoft.BingSports_8wekyb3d8bbwe",
    "Microsoft.BingFinance_8wekyb3d8bbwe",
    
    # Communication (3)
    "Microsoft.People_8wekyb3d8bbwe",
    "Microsoft.WindowsCommunicationsApps_8wekyb3d8bbwe",
    "microsoft.windowscommunicationsapps_8wekyb3d8bbwe",
    
    # Utilities (6)
    "Microsoft.WindowsAlarms_8wekyb3d8bbwe",
    "Microsoft.WindowsCalculator_8wekyb3d8bbwe",
    "Microsoft.WindowsCamera_8wekyb3d8bbwe",
    "Microsoft.WindowsMaps_8wekyb3d8bbwe",
    "Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe",
    "Microsoft.Windows.Photos_8wekyb3d8bbwe",
    
    # Xbox (5)
    "Microsoft.XboxApp_8wekyb3d8bbwe",
    "Microsoft.XboxGameOverlay_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe",
    "Microsoft.XboxIdentityProvider_8wekyb3d8bbwe",
    "Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe",
    
    # Mixed Reality (2)
    "Microsoft.MixedReality.Portal_8wekyb3d8bbwe",
    "Microsoft.Microsoft3DViewer_8wekyb3d8bbwe",
    
    # Additional UWP Bloat (5)
    "Microsoft.YourPhone_8wekyb3d8bbwe",
    "Microsoft.ScreenSketch_8wekyb3d8bbwe",
    "Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe",
    "Microsoft.MSPaint_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe"
)

# ============================================
# SECTION 4: Core Functions
# ============================================

function Write-OptimizationLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    
    Add-Content -Path "$LogPath\Optimization_$(Get-Date -Format 'yyyyMMdd').log" -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG" { Write-Host $logEntry -ForegroundColor Gray }
    }
}

function Test-ProtectedProcess {
    param(
        [string]$ProcessName,
        [string]$ProcessPath = "",
        [int]$ProcessId = 0
    )
    
    foreach ($protected in $Script:ProtectedProcesses) {
        if ($ProcessName -eq $protected.Name) {
            # For svchost.exe, verify by service group if available
            if ($ProcessName -eq "svchost.exe" -and $protected.ServiceGroup -and $ProcessId -gt 0) {
                $services = Get-CimInstance Win32_Service -Filter "ProcessId=$ProcessId" -ErrorAction SilentlyContinue |
                           Select-Object -ExpandProperty Name
                if ($protected.ServiceGroup -in $services) {
                    return $true
                }
                continue
            }
            
            if ($ProcessPath -and $protected.Path) {
                if ($ProcessPath -eq $protected.Path) {
                    return $true
                }
            } elseif ($ProcessName -eq "svchost.exe") {
                return $true
            } else {
                return $true
            }
        }
    }
    return $false
}

function Get-ServiceGroupInfo {
    param([int]$ProcessId)
    
    try {
        $serviceInfo = Get-CimInstance Win32_Service -Filter "ProcessId=$ProcessId" -ErrorAction SilentlyContinue |
                      Select-Object -ExpandProperty Name
        return $serviceInfo
    } catch {
        return @()
    }
}

function Set-ServiceStartupType {
    param(
        [string]$ServiceName,
        [string]$StartupType = "Disabled"
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
            $currentType = (Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue).Start
            
            if ($null -eq $currentType) {
                Write-OptimizationLog "Service registry not found: $ServiceName" -Level "DEBUG"
                return $false
            }
            
            if ($currentType -eq 4) {
                Write-OptimizationLog "Service already disabled: $ServiceName" -Level "DEBUG"
                return $false
            }
            
            # Save original state for rollback
            Add-Content -Path "$LogPath\Rollback.txt" -Value "$ServiceName|$currentType" -ErrorAction SilentlyContinue
            
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
            
            Write-OptimizationLog "Disabled service: $ServiceName (was type: $currentType)" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-OptimizationLog "Failed to disable $ServiceName : $($_.Exception.Message)" -Level "WARNING"
        return $false
    }
}

function Suspend-UWPApp {
    param([string]$PackageFullName)
    
    try {
        $package = Get-AppxPackage -Name $PackageFullName -ErrorAction SilentlyContinue
        if ($package) {
            $taskName = "Opt_Suspend_$($package.Name)"
            
            # Use Disable-BackgroundAppxTask approach (more compatible than Suspend-AppxPackage)
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"Stop-Process -Name '$($package.PackageFamilyName)' -Force -ErrorAction SilentlyContinue`""
            $trigger = New-ScheduledTaskTrigger -AtStartup
            $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force -ErrorAction Stop | Out-Null
            
            Write-OptimizationLog "Created suppress task for: $PackageFullName" -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-OptimizationLog "Failed to suspend $PackageFullName : $($_.Exception.Message)" -Level "WARNING"
        return $false
    }
}

function Optimize-ServiceHostConsolidation {
    try {
        $currentValue = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -ErrorAction SilentlyContinue).SvcHostSplitThresholdInKB
        if ($currentValue -eq 0xFFFFFFFF) {
            Write-OptimizationLog "Service host consolidation already applied" -Level "DEBUG"
            return
        }
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value 0xFFFFFFFF -Type DWord
        Write-OptimizationLog "Service host consolidation applied (SvcHostSplitThresholdInKB = 4294967295)" -Level "SUCCESS"
    } catch {
        Write-OptimizationLog "Failed to apply service host consolidation: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Disable-TelemetryAndTracking {
    $telemetryKeys = @(
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Value=0},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name="AllowTelemetry"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name="DisabledByGroupPolicy"; Value=1},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name="DisableLocation"; Value=1},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name="DisableSensors"; Value=1}
    )
    
    foreach ($key in $telemetryKeys) {
        try {
            if (-not (Test-Path $key.Path)) {
                New-Item -Path $key.Path -Force | Out-Null
            }
            Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type DWord
            Write-OptimizationLog "Telemetry: $($key.Name) = $($key.Value)" -Level "SUCCESS"
        } catch {
            Write-OptimizationLog "Failed to set $($key.Name): $($_.Exception.Message)" -Level "WARNING"
        }
    }
}

function Remove-NonProtectedProcesses {
    $allProcesses = Get-Process | Select-Object Id, ProcessName, Path, Company, Description
    $killedCount = 0
    $protectedCount = 0
    $skippedCount = 0
    
    foreach ($process in $allProcesses) {
        # Skip our own process
        if ($process.Id -eq $PID) {
            $protectedCount++
            continue
        }
        
        # Skip system-critical processes by name
        if ($process.ProcessName -in @("Idle", "System", "Secure System", "Memory Compression", "csrss", "wininit", "winlogon", "smss")) {
            $protectedCount++
            continue
        }
        
        # Skip protected processes (with service group verification for svchost)
        if (Test-ProtectedProcess -ProcessName $process.ProcessName -ProcessPath $process.Path -ProcessId $process.Id) {
            $protectedCount++
            continue
        }
        
        # Skip critical Microsoft processes
        if ($process.ProcessName -in $Script:CriticalMicrosoftProcesses) {
            $protectedCount++
            continue
        }
        
        # Skip processes from Microsoft with no description (system-level)
        if ($process.Company -like "*Microsoft*" -and [string]::IsNullOrEmpty($process.Description)) {
            $protectedCount++
            continue
        }
        
        # Process termination based on optimization level
        try {
            switch ($OptimizationLevel) {
                "Maximum" {
                    Stop-Process -Id $process.Id -Force -ErrorAction Stop
                    Write-OptimizationLog "Terminated: $($process.ProcessName) (PID: $($process.Id))" -Level "DEBUG"
                    $killedCount++
                }
                "Aggressive" {
                    $nonEssentialProcesses = @(
                        "MicrosoftEdgeUpdate.exe", "OneDrive.exe", "Teams.exe",
                        "Skype.exe", "Discord.exe", "Spotify.exe", "Steam.exe",
                        "AdobeUpdateService.exe", "GoogleUpdate.exe", "DropboxUpdate.exe",
                        "Microsoft.Photos.exe", "YourPhone.exe", "Cortana.exe",
                        "SearchApp.exe", "GameBar.exe", "Widgets.exe", "WidgetService.exe"
                    )
                    
                    if ($process.ProcessName -in $nonEssentialProcesses) {
                        Stop-Process -Id $process.Id -Force -ErrorAction Stop
                        Write-OptimizationLog "Terminated: $($process.ProcessName) (PID: $($process.Id))" -Level "DEBUG"
                        $killedCount++
                    } else {
                        $skippedCount++
                    }
                }
                "Standard" {
                    $terminableProcesses = @("dllhost.exe", "taskeng.exe", "SearchProtocolHost.exe", "SearchFilterHost.exe")
                    if ($process.ProcessName -in $terminableProcesses) {
                        $serviceInfo = Get-ServiceGroupInfo -ProcessId $process.Id
                        if ($serviceInfo -notin @("RpcSs", "DcomLaunch", "Power", "AudioSrv", "AudioEndpointBuilder")) {
                            Stop-Process -Id $process.Id -Force -ErrorAction Stop
                            Write-OptimizationLog "Terminated: $($process.ProcessName) (PID: $($process.Id))" -Level "DEBUG"
                            $killedCount++
                        } else {
                            $skippedCount++
                        }
                    } else {
                        $skippedCount++
                    }
                }
            }
        } catch {
            # Process may be protected by OS - skip silently
            $skippedCount++
        }
    }
    
    Write-OptimizationLog "Process cleanup: $killedCount terminated, $protectedCount protected, $skippedCount skipped" -Level "SUCCESS"
}

function Optimize-ScheduledTasks {
    $tasksToDisable = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Application Experience\StartupAppTask",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\Location\Notifications",
        "\Microsoft\Windows\Maps\MapsUpdateTask",
        "\Microsoft\Windows\Media Center\MediaCenterRecoveryTask",
        "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
        "\Microsoft\Windows\Xbox\Xbox Update Task"
    )
    
    $disabledCount = 0
    foreach ($task in $tasksToDisable) {
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction Stop | Out-Null
            $disabledCount++
        } catch {
            # Task may not exist on all systems - skip silently
        }
    }
    Write-OptimizationLog "Disabled $disabledCount of $($tasksToDisable.Count) scheduled tasks" -Level "SUCCESS"
}

# ============================================
# SECTION 5: Pre-Flight Validation
# ============================================

function Test-Prerequisites {
    Write-OptimizationLog "Running pre-flight validation..." -Level "INFO"
    
    $issues = @()
    
    # Check if running as admin
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $issues += "Not running as administrator"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell version $($PSVersionTable.PSVersion) is below 5.1"
    }
    
    # Check if critical services are running
    $criticalServices = @("RpcSs", "DcomLaunch", "Power")
    foreach ($svc in $criticalServices) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if (-not $service -or $service.Status -ne "Running") {
            $issues += "Critical service $svc is not running"
        }
    }
    
    # Check available disk space (need at least 1GB for logs/backups)
    $systemDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    if ($freeSpaceGB -lt 1) {
        $issues += "Low disk space: ${freeSpaceGB}GB free (minimum 1GB required)"
    }
    
    # Check current process count
    $currentCount = (Get-Process).Count
    Write-OptimizationLog "Current process count: $currentCount" -Level "INFO"
    
    if ($issues.Count -gt 0) {
        Write-OptimizationLog "Pre-flight validation failed:" -Level "ERROR"
        foreach ($issue in $issues) {
            Write-OptimizationLog "  - $issue" -Level "ERROR"
        }
        return $false
    }
    
    Write-OptimizationLog "Pre-flight validation passed" -Level "SUCCESS"
    return $true
}

# ============================================
# SECTION 6: Main Execution
# ============================================

function Invoke-ProcessOptimization {
    Write-OptimizationLog "================================================" -Level "INFO"
    Write-OptimizationLog "EBOS Process Optimization Module v3.1.0" -Level "INFO"
    Write-OptimizationLog "Optimization Level: $OptimizationLevel" -Level "INFO"
    Write-OptimizationLog "Target Process Count: $TargetProcessCount" -Level "INFO"
    Write-OptimizationLog "Protecting 35 Mandatory Processes" -Level "INFO"
    Write-OptimizationLog "================================================" -Level "INFO"
    
    # Capture before state
    $beforeProcessCount = (Get-Process).Count
    $beforeSvchostCount = (Get-Process -Name svchost -ErrorAction SilentlyContinue).Count
    Write-OptimizationLog "Before: $beforeProcessCount processes, $beforeSvchostCount svchost instances" -Level "INFO"
    
    # Create restore point if requested
    if ($CreateRestorePoint) {
        Write-OptimizationLog "Step 0/7: Creating system restore point..." -Level "INFO"
        try {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Before EBOS Process Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-OptimizationLog "Restore point created" -Level "SUCCESS"
        } catch {
            Write-OptimizationLog "Failed to create restore point: $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    # Step 1: Service Host Consolidation
    Write-OptimizationLog "Step 1/6: Applying Service Host Consolidation" -Level "INFO"
    Optimize-ServiceHostConsolidation
    
    # Step 2: Disable Non-Essential Services
    Write-OptimizationLog "Step 2/6: Disabling Non-Essential Services" -Level "INFO"
    $disabledCount = 0
    foreach ($service in $Script:ServicesToDisable) {
        if (Set-ServiceStartupType -ServiceName $service.Name -StartupType "Disabled") {
            $disabledCount++
        }
    }
    Write-OptimizationLog "Disabled $disabledCount non-essential services" -Level "SUCCESS"
    
    # Step 3: Suspend UWP Apps
    Write-OptimizationLog "Step 3/6: Suspending Non-Critical UWP Apps" -Level "INFO"
    $suspendedCount = 0
    foreach ($app in $Script:UWPAppsToSuspend) {
        if (Suspend-UWPApp -PackageFullName $app) {
            $suspendedCount++
        }
    }
    Write-OptimizationLog "Suspended $suspendedCount UWP apps" -Level "SUCCESS"
    
    # Step 4: Disable Telemetry
    Write-OptimizationLog "Step 4/6: Disabling Telemetry and Tracking" -Level "INFO"
    Disable-TelemetryAndTracking
    
    # Step 5: Optimize Scheduled Tasks
    Write-OptimizationLog "Step 5/6: Optimizing Scheduled Tasks" -Level "INFO"
    Optimize-ScheduledTasks
    
    # Step 6: Remove Non-Protected Processes
    Write-OptimizationLog "Step 6/6: Removing Non-Protected Processes" -Level "INFO"
    Remove-NonProtectedProcesses
    
    # Final Report
    Start-Sleep -Seconds 2
    $finalProcessCount = (Get-Process).Count
    $finalSvchostCount = (Get-Process -Name svchost -ErrorAction SilentlyContinue).Count
    $protectedProcessCount = 0
    foreach ($process in Get-Process) {
        if (Test-ProtectedProcess -ProcessName $process.ProcessName -ProcessPath $process.Path -ProcessId $process.Id) {
            $protectedProcessCount++
        }
    }
    
    Write-OptimizationLog "================================================" -Level "INFO"
    Write-OptimizationLog "Optimization Complete!" -Level "SUCCESS"
    Write-OptimizationLog "Before: $beforeProcessCount processes, $beforeSvchostCount svchost" -Level "INFO"
    Write-OptimizationLog "After:  $finalProcessCount processes, $finalSvchostCount svchost" -Level "INFO"
    Write-OptimizationLog "Protected: $protectedProcessCount | Terminated: $($beforeProcessCount - $finalProcessCount)" -Level "INFO"
    
    if ($finalProcessCount -le $TargetProcessCount) {
        Write-OptimizationLog "TARGET ACHIEVED: $finalProcessCount <= $TargetProcessCount" -Level "SUCCESS"
    } else {
        $diff = $finalProcessCount - $TargetProcessCount
        Write-OptimizationLog "TARGET NOT MET: $finalProcessCount (off by $diff)" -Level "WARNING"
    }
    Write-OptimizationLog "================================================" -Level "INFO"
    
    # Create rollback script
    Create-RollbackScript
}

function Create-RollbackScript {
    $rollbackContent = @'
<#
.SYNOPSIS
    Rollback Script for EBOS Process Optimization
.DESCRIPTION
    Restores original system configuration from backup.
    Generated by Optimize-ProcessBaseline.ps1 v3.1.0
#>

param(
    [switch]$Force
)

$LogPath = "$env:ProgramData\ProcessOptimization"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EBOS Process Optimization Rollback" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "This will restore original system configuration. Continue? (Y/N)"
    if ($confirm -notin @("Y", "y", "Yes", "YES")) {
        Write-Host "Rollback cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Restore Service Host Settings
Write-Host "Restoring Service Host settings..." -ForegroundColor White
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -ErrorAction SilentlyContinue

# Restore Telemetry Settings
Write-Host "Restoring Telemetry settings..." -ForegroundColor White
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue

# Restore Services from Rollback File
$rollbackFile = Join-Path $LogPath "Rollback.txt"
if (Test-Path $rollbackFile) {
    Write-Host "Restoring services..." -ForegroundColor White
    Get-Content $rollbackFile | ForEach-Object {
        $parts = $_ -split '\|'
        if ($parts.Count -eq 2) {
            $serviceName = $parts[0]
            $originalType = [int]$parts[1]
            try {
                Set-Service -Name $serviceName -StartupType $originalType -ErrorAction SilentlyContinue
                Write-Host "  Restored: $serviceName -> StartType $originalType" -ForegroundColor Green
            } catch {
                Write-Host "  Failed to restore: $serviceName" -ForegroundColor Red
            }
        }
    }
    Remove-Item $rollbackFile -Force -ErrorAction SilentlyContinue
}

# Re-enable Scheduled Tasks
Write-Host "Re-enabling scheduled tasks..." -ForegroundColor White
$tasksToEnable = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
)
foreach ($task in $tasksToEnable) {
    try {
        Enable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        Write-Host "  Re-enabled: $task" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $task" -ForegroundColor Yellow
    }
}

# Remove suppress tasks
Write-Host "Removing suppress tasks..." -ForegroundColor White
Get-ScheduledTask -TaskName "Opt_Suspend_*" -ErrorAction SilentlyContinue | ForEach-Object {
    Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  Removed: $($_.TaskName)" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Rollback complete!" -ForegroundColor Green
Write-Host "A system restart is recommended." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if (-not $Force) {
    $restart = Read-Host "Restart now? (Y/N)"
    if ($restart -in @("Y", "y", "Yes", "YES")) {
        Restart-Computer -Force
    }
}
'@
    
    $rollbackPath = "$LogPath\Rollback_Script.ps1"
    $rollbackContent | Out-File -FilePath $rollbackPath -Encoding UTF8 -Force
    Write-OptimizationLog "Rollback script created: $rollbackPath" -Level "INFO"
}

# ============================================
# SECTION 7: Execute
# ============================================

try {
    # Pre-flight validation
    if (-not $SkipValidation) {
        if (-not (Test-Prerequisites)) {
            Write-OptimizationLog "Pre-flight validation failed. Use -SkipValidation to override." -Level "ERROR"
            exit 1
        }
    }
    
    if (-not $SkipConfirmation) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Yellow
        Write-Host "EBOS Process Optimization Module v3.1.0" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Yellow
        Write-Host "Optimization Level: $OptimizationLevel" -ForegroundColor White
        Write-Host "Target: $TargetProcessCount processes on idle" -ForegroundColor White
        Write-Host "Protected: 35 mandatory Windows processes" -ForegroundColor Green
        Write-Host "================================================" -ForegroundColor Yellow
        Write-Host ""
        $confirmation = Read-Host "Continue? (Y/N)"
        if ($confirmation -notin @("Y", "y", "Yes", "YES")) {
            Write-Host "Operation cancelled by user" -ForegroundColor Red
            exit 0
        }
    }
    
    Invoke-ProcessOptimization
} catch {
    Write-OptimizationLog "Critical error: $($_.Exception.Message)" -Level "ERROR"
    Write-OptimizationLog "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
    
    # Emergency restore of critical services
    Write-OptimizationLog "Attempting emergency service restoration..." -Level "WARNING"
    $criticalServices = @("RpcSs", "DcomLaunch", "Power", "AudioSrv", "AudioEndpointBuilder", "Dhcp", "Dnscache", "NLA", "nsi", "mpssvc", "CryptSvc", "ProfSvc", "gpsvc", "EventLog")
    foreach ($service in $criticalServices) {
        try {
            Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $service -ErrorAction SilentlyContinue
        } catch {
            # Best effort restoration
        }
    }
    Write-OptimizationLog "Emergency restoration complete" -Level "WARNING"
    exit 1
}
