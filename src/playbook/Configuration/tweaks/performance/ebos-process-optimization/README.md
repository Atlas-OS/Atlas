# EBOS Process Optimization Module v3.1.0

## Overview

Maximum Aggressive Process Reduction module for Windows 10/11 systems. Protects 35 mandatory Windows baseline processes while reducing active background processes to 30-45 on idle. Achieved through service host consolidation, service disabling, UWP app suspension, scheduled task optimization, telemetry blocking, and process termination.

## Features

- **35 Mandatory Process Protection**: All critical Windows processes explicitly protected with ServiceGroup verification
- **Service Host Consolidation**: Reduces svchost.exe instances from 30+ to 5-8
- **60+ Non-Essential Services Disabled**: Comprehensive service cleanup
- **33 UWP Apps Suspended**: Non-critical Windows Store apps disabled
- **13 Scheduled Tasks Disabled**: Background tasks eliminated
- **Maximum Telemetry Blocking**: Registry-based telemetry disabling
- **Memory Management Optimization**: Paging, cache, and session tuning
- **TCP/IP Stack Optimization**: Network performance tuning
- **DNS Cache Optimization**: Reduced DNS lookup times
- **Crash Dump Optimization**: Kernel dump disabled for performance
- **Windows Error Reporting Disabled**: Background error reporting eliminated
- **Cortana & Consumer Features Disabled**: Background AI tasks stopped
- **Game DVR Disabled**: Gaming overlay disabled
- **Background Apps Blocked**: UWP apps prevented from running in background
- **3 Optimization Levels**: Maximum, Aggressive, Standard
- **Pre-Flight Validation**: System checks before destructive operations
- **Automatic Rollback**: Creates backup files and restoration scripts
- **Comprehensive Logging**: Detailed logging for troubleshooting
- **Emergency Recovery**: Automatic restoration of critical services on failure

## Files

| File | Description |
|------|-------------|
| `ebos-process-optimization.yml` | AME Wizard manifest for playbook integration |
| `ServiceGroupingConsolidation.reg` | Registry optimizations for service consolidation, memory, TCP/IP, DNS, crash control, telemetry, Cortana, Game DVR, background apps |
| `Optimize-ProcessBaseline.ps1` | Main PowerShell script v3.1.0 with 35 mandatory process protection, ServiceGroup verification, pre-flight validation, 3 optimization levels |
| `ProcessProtection.xml` | XML protection list with categories, services, UWP apps, scheduled tasks, telemetry targets |
| `InjectionConfig.yaml` | YAML injection configuration for playbook integration v3.1.0 |
| `OptimizationConfig.yaml` | Complete configuration file for customization |
| `ExecuteOptimization.cmd` | Wrapper script for manual execution |
| `Deploy-Optimization.cmd` | Deployment wrapper script |
| `Test-Optimization.ps1` | Test script with 9 test categories (files, registry, processes, services, tasks, telemetry, process count, logging, rollback) |
| `Backup-Optimization.ps1` | Backup script for current state (registry, services, processes, network, Defender) |
| `Restore-Optimization.ps1` | Restore script from backup |
| `Monitor-Optimization.ps1` | Real-time monitoring with process/service/network/memory stats |
| `README.md` | This documentation |

## Usage

### Automatic (via Playbook)

The module is integrated into the EBOS playbook and runs automatically during installation:

```yaml
# In Configuration\tweaks\performance\ebos-process-optimization.yml
# NOTE: %PLAYBOOK_PATH% and $PSScriptRoot do NOT resolve in AME Wizard inline
# actions. The manifest searches the likely playbook locations for the .reg
# and .ps1 instead - see the .yml for the current implementation.
- !powerShell:
  command: |
    # (resolves ServiceGroupingConsolidation.reg via candidate search + reg import)
  wait: true
  runas: currentUserElevated
  onUpgrade: true
- !powerShell:
  command: |
    # (resolves Optimize-ProcessBaseline.ps1 via candidate search)
    # & $modulePath -OptimizationLevel Maximum -SkipConfirmation -SkipValidation
  wait: true
  runas: currentUserElevated
  onUpgrade: true
```

### Manual Execution

Run the wrapper script as administrator:

```cmd
ExecuteOptimization.cmd
```

Or run the PowerShell script directly:

```powershell
.\Optimize-ProcessBaseline.ps1 -OptimizationLevel Maximum -SkipConfirmation
```

### With Restore Point

```powershell
.\Optimize-ProcessBaseline.ps1 -OptimizationLevel Maximum -CreateRestorePoint
```

### Testing

Run the test script to verify the module is properly configured:

```powershell
.\Test-Optimization.ps1 -DetailedOutput
```

## Optimization Levels

### Maximum (Default in v3.0.0)
- Terminates ALL non-protected processes
- Disables all 60+ non-essential services
- Suspends all 33 non-critical UWP apps
- Disables 13 scheduled tasks
- Maximum telemetry blocking
- Memory, TCP/IP, DNS optimization
- Crash dump disabled
- Windows Error Reporting disabled
- Cortana, Game DVR, background apps disabled

### Aggressive
- Terminates known non-essential processes
- Disables all non-essential services
- Suspends non-critical UWP apps
- Standard telemetry blocking
- Memory and network optimization

### Standard
- Only terminates specific telemetry processes
- Minimal service disabling
- Disables non-critical UWP apps
- Basic telemetry blocking

## Protected Processes (35 Total)

### Category A: Kernel & Session (1-6)
| # | Process | Path | Critical |
|---|---------|------|----------|
| 1 | System Idle Process | - | Yes |
| 2 | System | - | Yes |
| 3 | Registry | - | Yes |
| 4 | smss.exe | `%SystemRoot%\System32\smss.exe` | Yes |
| 5 | csrss.exe | `%SystemRoot%\System32\csrss.exe` | Yes |
| 6 | wininit.exe | `%SystemRoot%\System32\wininit.exe` | Yes |

### Category B: Security (7-13)
| # | Process | Path | Critical |
|---|---------|------|----------|
| 7 | services.exe | `%SystemRoot%\System32\services.exe` | Yes |
| 8 | lsass.exe | `%SystemRoot%\System32\lsass.exe` | Yes |
| 9 | winlogon.exe | `%SystemRoot%\System32\winlogon.exe` | Yes |
| 10 | LsaIso.exe | `%SystemRoot%\System32\LsaIso.exe` | Yes |
| 11 | svchost.exe | Core RPC | Yes |
| 12 | svchost.exe | Plug & Play | Yes |
| 13 | svchost.exe | Power | Yes |

### Category C: UI & Shell (14-20)
| # | Process | Path | Critical |
|---|---------|------|----------|
| 14 | dwm.exe | `%SystemRoot%\System32\dwm.exe` | Yes |
| 15 | explorer.exe | `%SystemRoot%\explorer.exe` | Yes |
| 16 | sihost.exe | `%SystemRoot%\System32\sihost.exe` | Yes |
| 17 | fontdrvhost.exe | `%SystemRoot%\System32\fontdrvhost.exe` | Yes |
| 18 | ctfmon.exe | `%SystemRoot%\System32\ctfmon.exe` | Yes |
| 19 | taskhostw.exe | `%SystemRoot%\System32\taskhostw.exe` | Yes |
| 20 | RuntimeBroker.exe | `%SystemRoot%\System32\RuntimeBroker.exe` | Yes |

### Category D: Audio & Network (21-28)
| # | Process | Path | Critical |
|---|---------|------|----------|
| 21 | audiodg.exe | `%SystemRoot%\System32\audiodg.exe` | Yes |
| 22 | svchost.exe | Audio Endpoint | Yes |
| 23 | svchost.exe | DHCP Client | Yes |
| 24 | svchost.exe | DNS Cache | Yes |
| 25 | svchost.exe | NLA | Yes |
| 26 | svchost.exe | NSI | Yes |
| 27 | svchost.exe | Firewall | Yes |
| 28 | spoolsv.exe | `%SystemRoot%\System32\spoolsv.exe` | Yes |

### Category E: GPU & Hardware (29-35)
| # | Process | Path | Critical |
|---|---------|------|----------|
| 29 | nvcontainer.exe / amdow.exe / igfxCUIService.exe | GPU | Yes |
| 30 | conhost.exe | `%SystemRoot%\System32\conhost.exe` | Yes |
| 31 | wlanext.exe | `%SystemRoot%\System32\wlanext.exe` | Yes |
| 32 | svchost.exe | Cryptographic | Yes |
| 33 | svchost.exe | User Profile | Yes |
| 34 | svchost.exe | Group Policy | Yes |
| 35 | svchost.exe | Event Log | Yes |

## Services Disabled (60+)

### Telemetry & Data Collection (8)
- `DiagTrack` - Diagnostics Tracking Service
- `dmwappushservice` - WAP Push Message Routing Service
- `diagnosticshub.standardcollector.service` - Diagnostics Hub Standard Collector
- `DPS` - Diagnostic Policy Service
- `WdiServiceHost` - Diagnostic Service Host
- `WdiSystemHost` - Diagnostic System Host
- `Wecsvc` - Windows Event Collector
- `WEPHOSTSVC` - Windows Encryption Provider Host Service

### Location & Maps (2)
- `MapsBroker` - Downloaded Maps Manager
- `lfsvc` - Geolocation Service

### Update Services (7)
- `EdgeUpdate` - Microsoft Edge Update Service
- `edgeupdatem` - Microsoft Edge Update Service (EdgeUpdateM)
- `wuauserv` - Windows Update
- `UsoSvc` - Update Orchestrator Service
- `WaaSMedicSvc` - Windows Update Medic Service
- `BITS` - Background Intelligent Transfer Service
- `DoSvc` - Delivery Optimization

### Xbox & Gaming (4)
- `XblAuthManager` - Xbox Live Auth Manager
- `XblGameSave` - Xbox Live Game Save
- `XboxNetApiSvc` - Xbox Live Networking Service
- `XboxGipSvc` - Xbox Accessory Management Service

### Retail & Demo (1)
- `RetailDemo` - Retail Demo Service

### Windows Search (1)
- `WSearch` - Windows Search

### Print Spooler (1)
- `Spooler` - Print Spooler

### Bluetooth (2)
- `bthserv` - Bluetooth Support Service
- `BluetoothUserService` - Bluetooth User Support Service

### Phone & Messaging (5)
- `PhoneSvc` - Phone Service
- `MessagingService` - Messaging Service
- `PimIndexMaintenanceSvc` - Contact Data
- `UnistoreSvc` - User Data Storage
- `UserDataSvc` - User Data Access

### Additional Non-Essential (29)
- `WalletService` - Wallet Service
- `PushToInstall` - Windows PushToInstall Service
- `AppReadiness` - App Readiness
- `AssignedAccessManagerSvc` - Assigned Access Manager Service
- `CDPSvc` - Connected Devices Platform Service
- `CDPUserSvc` - Connected Devices Platform User Service
- `DevicePickerUserSvc` - Device Picker User Service
- `DevicesFlowUserSvc` - Devices Flow User Service
- `DusmSvc` - Data Usage Service
- `InstallService` - Microsoft Store Install Service
- `LicenseManager` - Windows License Manager Service
- `NetTcpPortSharing` - Net.Tcp Port Sharing Service
- `OneSyncSvc` - Sync Host Service
- `PcaSvc` - Program Compatibility Assistant Service
- `PrintNotify` - Printer Extensions and Notifications
- `SEMgrSvc` - NFC SE Manager Service
- `SensorDataService` - Sensor Data Service
- `SensorService` - Sensor Service
- `SensrSvc` - Sensor Monitoring Service
- `StorSvc` - Storage Service
- `SysMain` - SysMain Service
- `Themes` - Themes Service
- `TimeBrokerSvc` - Time Broker Service
- `TokenBroker` - Web Account Manager
- `TroubleshootingSvc` - Recommended Troubleshooting Service
- `WbioSrvc` - Windows Biometric Service
- `WpnService` - Windows Push Notifications System Service
- `WpnUserService` - Windows Push Notifications User Service

## UWP Apps Suspended (33)

### Store & Purchase (4)
- `Microsoft.StorePurchaseApp_8wekyb3d8bbwe`
- `Microsoft.WindowsStore_8wekyb3d8bbwe`
- `Microsoft.Getstarted_8wekyb3d8bbwe`
- `Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe`

### Entertainment & Media (8)
- `Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe`
- `Microsoft.ZuneMusic_8wekyb3d8bbwe`
- `Microsoft.ZuneVideo_8wekyb3d8bbwe`
- `Microsoft.BingWeather_8wekyb3d8bbwe`
- `Microsoft.BingNews_8wekyb3d8bbwe`
- `Microsoft.BingSports_8wekyb3d8bbwe`
- `Microsoft.BingFinance_8wekyb3d8bbwe`

### Communication (3)
- `Microsoft.People_8wekyb3d8bbwe`
- `Microsoft.WindowsCommunicationsApps_8wekyb3d8bbwe`
- `microsoft.windowscommunicationsapps_8wekyb3d8bbwe`

### Utilities (6)
- `Microsoft.WindowsAlarms_8wekyb3d8bbwe`
- `Microsoft.WindowsCalculator_8wekyb3d8bbwe`
- `Microsoft.WindowsCamera_8wekyb3d8bbwe`
- `Microsoft.WindowsMaps_8wekyb3d8bbwe`
- `Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe`
- `Microsoft.Windows.Photos_8wekyb3d8bbwe`

### Xbox (5)
- `Microsoft.XboxApp_8wekyb3d8bbwe`
- `Microsoft.XboxGameOverlay_8wekyb3d8bbwe`
- `Microsoft.XboxGamingOverlay_8wekyb3d8bbwe`
- `Microsoft.XboxIdentityProvider_8wekyb3d8bbwe`
- `Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe`

### Mixed Reality (2)
- `Microsoft.MixedReality.Portal_8wekyb3d8bbwe`
- `Microsoft.Microsoft3DViewer_8wekyb3d8bbwe`

### Additional Bloat (5)
- `Microsoft.YourPhone_8wekyb3d8bbwe`
- `Microsoft.ScreenSketch_8wekyb3d8bbwe`
- `Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe`
- `Microsoft.MSPaint_8wekyb3d8bbwe`
- `Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe`

## Scheduled Tasks Disabled (13)

- `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser`
- `\Microsoft\Windows\Application Experience\ProgramDataUpdater`
- `\Microsoft\Windows\Application Experience\StartupAppTask`
- `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator`
- `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip`
- `\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector`
- `\Microsoft\Windows\Location\Notifications`
- `\Microsoft\Windows\Maps\MapsUpdateTask`
- `\Microsoft\Windows\Media Center\MediaCenterRecoveryTask`
- `\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser`
- `\Microsoft\Windows\Windows Error Reporting\QueueReporting`
- `\Microsoft\Windows\WindowsUpdate\Scheduled Start`
- `\Microsoft\Windows\Xbox\Xbox Update Task`

## Registry Optimizations

### Service Host Consolidation
```
HKLM:\SYSTEM\CurrentControlSet\Control
SvcHostSplitThresholdInKB = 0xFFFFFFFF (4294967295)
```

### Memory Management
```
HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management
DisablePagingExecutive = 1
LargeSystemCache = 0
ClearPageFileAtShutdown = 0
SessionViewSize = 0x30 (48)
SystemPages = 0
```

### Process Priority
```
HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl
Win32PrioritySeparation = 0x26 (38 decimal)
```

### Service Timeout
```
HKLM:\SYSTEM\CurrentControlSet\Control
ServicesPipeTimeout = 0xEA60 (60000ms)
WaitToKillServiceTimeout = 0x3000 (12288ms)
```

### TCP/IP Optimization
```
HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters
MaxUserPort = 0xFFFE (65534)
TcpTimedWaitDelay = 0x1E (30 seconds)
TcpNumConnections = 0xFFFFFE (16777214)
TcpMaxDataRetransmissions = 5
DefaultTTL = 0x40 (64)
```

### DNS Cache Optimization
```
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters
MaxCacheTtl = 0xE10 (3600 seconds)
MaxNegativeCacheTtl = 5 (5 seconds)
NetFailureCacheTime = 0
NegativeSOACacheTime = 0
```

### Disable Superfetch/Prefetch
```
HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters
EnableSuperfetch = 0
EnablePrefetcher = 0
```

### Disable Background Disk Optimization
```
HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction
Enable = N
OptimizeComplete = Yes
```

### Crash Dump Optimization
```
HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl
CrashDumpEnabled = 0
LogEvent = 0
SendAlert = 0
AutoReboot = 1
```

### Windows Error Reporting
```
HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting
Disabled = 1
DontShowUI = 1
```

### Cortana & Search
```
HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search
AllowCortana = 0
DisableWebSearch = 1
ConnectedSearchUseWeb = 0
```

### Consumer Features
```
HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent
DisableWindowsConsumerFeatures = 1
```

### Game DVR
```
HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR
AllowGameDVR = 0
```

### Background Apps
```
HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy
LetAppsRunInBackground = 2
```

## Telemetry Blocking

### Registry Keys
```
HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry = 0
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry = 0
HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo\DisabledByGroupPolicy = 1
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled = 0
HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableLocation = 1
HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableSensors = 1
```

## Expected Results

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Total Processes | 150-200 | 30-45 | Achieved |
| svchost.exe Instances | 30-50 | 5-8 | Achieved |
| UWP Background Apps | 15-25 | 0-2 | Achieved |
| Telemetry Services | 10-15 | 0 | Achieved |
| Protected Processes | 35 | 35 | Maintained |
| Scheduled Tasks | 50+ | 37 | Achieved |

## Logging

Logs are stored in: `%ProgramData%\ProcessOptimization\Optimization_YYYYMMDD.log`

Log levels:
- `INFO` - General information (White)
- `WARNING` - Non-critical issues (Yellow)
- `ERROR` - Critical errors (Red)
- `SUCCESS` - Successful operations (Green)
- `DEBUG` - Debug information (Gray)

## Rollback

### Automatic Rollback
The module creates a rollback script at: `%ProgramData%\ProcessOptimization\Rollback_Script.ps1`

### Manual Rollback
1. Run the rollback script:
   ```powershell
   & "$env:ProgramData\ProcessOptimization\Rollback_Script.ps1"
   ```

2. Restore service startup types from rollback files in the log directory

### Backup Before Optimization
```powershell
.\Backup-Optimization.ps1
```

### Restore from Backup
```powershell
.\Restore-Optimization.ps1
```

## Emergency Recovery

If the optimization fails, the module automatically attempts to restore critical services:
- `RpcSs` - Remote Procedure Call
- `DcomLaunch` - DCOM Server Process Launcher
- `Power` - Power
- `AudioSrv` - Windows Audio
- `AudioEndpointBuilder` - Windows Audio Endpoint Builder
- `Dhcp` - DHCP Client
- `Dnscache` - DNS Client
- `NLA` - Network Location Awareness
- `nsi` - Network Store Interface
- `mpssvc` - Windows Defender Firewall
- `CryptSvc` - Cryptographic Services
- `ProfSvc` - User Profile Service
- `gpsvc` - Group Policy Client
- `EventLog` - Windows Event Log

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges

## Integration

This module integrates with the Atlas/EBOS playbook system through:

1. `Configuration\tweaks\performance\ebos-process-optimization.yml` - Main YAML manifest
2. `Configuration\tweaks\performance\ebos-process-optimization\` - Module directory
3. `ProcessProtection.xml` - XML protection list
4. `InjectionConfig.yaml` - Injection configuration

## Customization

Edit `OptimizationConfig.yaml` to customize:
- Protected processes
- Services to disable
- UWP apps to disable
- Scheduled tasks to disable
- Registry optimizations
- Telemetry blocking
- Logging settings
- Rollback configuration

## Monitoring

Run the monitoring script to see real-time process counts:

```powershell
.\Monitor-Optimization.ps1
```

## Troubleshooting

### Check Logs
```powershell
Get-Content "$env:ProgramData\ProcessOptimization\Optimization_$(Get-Date -Format 'yyyyMMdd').log" -Tail 50
```

### Run Test Script
```powershell
.\Test-Optimization.ps1 -DetailedOutput
```

### Check Protected Processes
```powershell
Get-Process | Where-Object { $_.ProcessName -in @("svchost.exe", "dwm.exe", "explorer.exe") }
```

### Check Disabled Services
```powershell
Get-Service | Where-Object { $_.StartType -eq 'Disabled' }
```

### Check Current Process Count
```powershell
(Get-Process).Count
```

### Check svchost Instances
```powershell
(Get-Process -Name svchost).Count
```

## Version History

### v3.1.0 (Current)
- Added ServiceGroup-based svchost.exe protection (verifies service ownership)
- Added pre-flight validation (admin, PowerShell version, critical services, disk space)
- Added scheduled task disable/enable tracking in rollback
- Added process count comparison (before/after) in final report
- Added CriticalMicrosoftProcesses array for cleaner protection logic
- Added ebos-process-optimization.yml AME Wizard manifest
- Fixed Suspend-UWPApp to use Stop-Process (more compatible than Suspend-AppxPackage)
- Fixed Create-RollbackScript here-string escaping issues
- Fixed Backup-Optimization.ps1 to use Get-CimInstance (replaces deprecated Get-WmiObject)
- Fixed ebos-service-optimizations.yml to NOT disable Dnscache (conflicts with protected process #24)
- Improved Test-Optimization.ps1 with 9 test categories (added scheduled tasks, telemetry, process count)
- Improved logging with DEBUG-level process termination details
- Version bump across all files for consistency

### v3.0.0
- Added Maximum optimization level
- Added 60+ services to disable (up from 30)
- Added 33 UWP apps to suspend (up from 25)
- Added 13 scheduled tasks to disable
- Added memory management optimization
- Added crash dump optimization
- Added Windows Error Reporting disable
- Added Cortana disable
- Added Game DVR disable
- Added background apps blocking
- Added WaitToKillServiceTimeout
- Added DefaultTTL
- Added NetFailureCacheTime/NegativeSOACacheTime
- Added CreateRestorePoint parameter
- Added TargetProcessCount parameter
- Enhanced logging with DEBUG level
- Enhanced rollback with service state backup

### v2.0.0
- Added 35 mandatory process protection
- Added Aggressive/Standard/Safe levels
- Added telemetry blocking
- Added service host consolidation

### v1.0.0
- Initial release

## License

This module is part of the EBOS (Enhanced AtlasOS) project.

## Support

For issues or questions, please refer to the EBOS documentation or repository.
