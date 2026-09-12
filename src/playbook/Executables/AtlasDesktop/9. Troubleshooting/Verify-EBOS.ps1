<#
.SYNOPSIS
    EBOS Verification Script
.DESCRIPTION
    Verifies all EBOS optimizations are properly applied.
    This script checks all the settings that were failing in the test.
.NOTES
    Author: EBOS Team
    Version: 2.1.0
    Requires: Windows 10/11, PowerShell 5.1+, Administrator rights
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput,
    
    [Parameter(Mandatory=$false)]
    [switch]$FixIssues
)

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and $FixIssues) {
    Write-Host "WARNING: Not running as Administrator. HKLM registry changes will be skipped." -ForegroundColor Yellow
    Write-Host "Some fixes require elevation. Re-run with 'Run as Administrator' for full fixes." -ForegroundColor Yellow
    Write-Host ""
}

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
# Fix Functions
# ============================================

function Fix-GamingOptimizations {
    Write-Host "Fixing gaming optimizations..." -ForegroundColor Yellow
    
    # Game Mode (HKCU - no admin needed)
    $gameBarPath = 'HKCU:\SOFTWARE\Microsoft\GameBar'
    if (-not (Test-Path $gameBarPath)) {
        New-Item -Path $gameBarPath -Force | Out-Null
    }
    Set-ItemProperty -Path $gameBarPath -Name 'GameModeEnabled' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $gameBarPath -Name 'AllowAutoGameMode' -Value 1 -Type DWord -Force
    Write-Host "  Game Mode enabled" -ForegroundColor Green
    
    if ($isAdmin) {
        # Ndu (HKLM - needs admin)
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' -Name 'Start' -Value 4 -Type DWord -Force
        Write-Host "  Ndu disabled" -ForegroundColor Green
        
        # SysMain (HKLM - needs admin)
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' -Name 'Start' -Value 3 -Type DWord -Force
        Write-Host "  SysMain set to manual" -ForegroundColor Green
        
        # WSearch (HKLM - needs admin)
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WSearch' -Name 'Start' -Value 3 -Type DWord -Force
        Write-Host "  WSearch set to manual" -ForegroundColor Green
        
        # GPU Scheduling (HKLM - needs admin)
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Value 2 -Type DWord -Force
        Write-Host "  GPU scheduling enabled" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] HKLM services (requires admin)" -ForegroundColor Gray
    }
}

function Fix-PrivacySettings {
    Write-Host "Fixing privacy settings..." -ForegroundColor Yellow
    
    if ($isAdmin) {
        # Edge Telemetry (HKLM - needs admin)
        $edgePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
        if (-not (Test-Path $edgePath)) {
            New-Item -Path $edgePath -Force | Out-Null
        }
        Set-ItemProperty -Path $edgePath -Name 'MetricsReportingEnabled' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $edgePath -Name 'SendSiteInfoToImproveServices' -Value 0 -Type DWord -Force
        Write-Host "  Edge telemetry disabled" -ForegroundColor Green
        
        # SmartScreen (HKLM - needs admin)
        $systemPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
        if (-not (Test-Path $systemPath)) {
            New-Item -Path $systemPath -Force | Out-Null
        }
        Set-ItemProperty -Path $systemPath -Name 'AllowSmartScreen' -Value 0 -Type DWord -Force
        Write-Host "  SmartScreen disabled" -ForegroundColor Green
        
        # Search Suggestions (HKLM - needs admin)
        $searchPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
        if (-not (Test-Path $searchPath)) {
            New-Item -Path $searchPath -Force | Out-Null
        }
        Set-ItemProperty -Path $searchPath -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $searchPath -Name 'AllowSearchToUseLocation' -Value 0 -Type DWord -Force
        Write-Host "  Search suggestions disabled" -ForegroundColor Green
        
        # Clipboard (HKLM - needs admin)
        Set-ItemProperty -Path $systemPath -Name 'AllowClipboardHistory' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $systemPath -Name 'AllowCrossDeviceClipboard' -Value 0 -Type DWord -Force
        Write-Host "  Clipboard history disabled" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] HKLM privacy settings (requires admin)" -ForegroundColor Gray
    }
}

function Fix-BootAnimation {
    Write-Host "Fixing boot animation..." -ForegroundColor Yellow
    
    if ($isAdmin) {
        # Registry (HKLM - needs admin)
        $bootPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation'
        if (-not (Test-Path $bootPath)) {
            New-Item -Path $bootPath -Force | Out-Null
        }
        Set-ItemProperty -Path $bootPath -Name 'DisableBootAnimation' -Value 1 -Type DWord -Force
        Write-Host "  Boot animation disabled via registry" -ForegroundColor Green
        
        # bcdedit (needs admin)
        bcdedit /set {default} disablebootanimation yes 2>&1 | Out-Null
        Write-Host "  Boot animation disabled via bcdedit" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] Boot animation (requires admin)" -ForegroundColor Gray
    }
}

function Fix-PowerPlan {
    Write-Host "Fixing power plan..." -ForegroundColor Yellow
    
    $planName = "EBOS High Performance"
    $existing = powercfg /list | Select-String -Pattern $planName
    
    if (-not $existing) {
        # Create new plan
        $newGuid = powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        $guid = $newGuid.Split()[3]
        powercfg /changename $guid "$planName" "EBOS Optimized High Performance Plan" | Out-Null
        Write-Host "  Created power plan" -ForegroundColor Green
    } else {
        $line = $existing.Line
        $m = [regex]::Match("$line", '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}')
        if (-not $m.Success) { throw "Could not parse power scheme GUID from: $line" }
        $guid = $m.Value
        Write-Host "  Found existing power plan" -ForegroundColor Green
    }
    
    # Apply optimizations
    powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
    powercfg /setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
    powercfg /setacvalueindex $guid SUB_PROCESSOR SYSCOOLPOL 0 | Out-Null
    powercfg /setacvalueindex $guid SUB_VIDEO VIDEOIDLE 0 | Out-Null
    powercfg /setacvalueindex $guid SUB_SLEEP STANDBYIDLE 0 | Out-Null
    powercfg /setactive $guid | Out-Null
    Write-Host "  Power plan activated" -ForegroundColor Green
}

function Fix-Theme {
    Write-Host "Fixing theme..." -ForegroundColor Yellow
    
    $themePath = "$env:SystemRoot\Resources\Themes\ebos-cyan.theme"
    if (Test-Path $themePath) {
        # Set theme via registry
        $themeManagerPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ThemeManager'
        Set-ItemProperty -Path $themeManagerPath -Name 'DllName' -Value "%SystemRoot%\Resources\Themes\ebos-cyan.theme" -Force -ErrorAction SilentlyContinue
        Write-Host "  Theme applied" -ForegroundColor Green
    } else {
        Write-Host "  Theme file not found" -ForegroundColor Yellow
    }
}

function Fix-OEMBootEntry {
    Write-Host "Fixing OEM boot entry..." -ForegroundColor Yellow
    if ($isAdmin) {
        # BCD (needs admin). {current} identifier is required - bare
        # 'bcdedit /set description' fails.
        $osVersion = [System.Environment]::OSVersion.Version.Build
        $winVersion = if ($osVersion -ge 22000) { '11' } else { '10' }
        # Single source of truth: <Version> in playbook.conf (token replaced at build).
        $description = "EBOS $winVersion %%EBOS_VERSION%%"
        bcdedit /set '{current}' description "$description" 2>&1 | Out-Null
        Write-Host "  Boot entry set to: $description" -ForegroundColor Green
        
        # OEM Information (HKLM - needs admin)
        $oemPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
        if (-not (Test-Path $oemPath)) {
            New-Item -Path $oemPath -Force | Out-Null
        }
        Set-ItemProperty -Path $oemPath -Name 'Manufacturer' -Value 'EBOS Team' -Force
        Set-ItemProperty -Path $oemPath -Name 'SupportURL' -Value 'https://discord.gg/ebos' -Force
        Write-Host "  OEM information configured" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] OEM boot entry (requires admin)" -ForegroundColor Gray
    }
}

function Fix-ServiceConsistency {
    Write-Host "Fixing service consistency..." -ForegroundColor Yellow

    if ($isAdmin) {
        # Must match ebos-service-optimizations.yml + ebos-gaming-optimizations.yml
        $targets = @{
            'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' = 3
            'HKLM:\SYSTEM\CurrentControlSet\Services\ClipSVC'  = 3
        }
        foreach ($path in $targets.Keys) {
            Set-ItemProperty -Path $path -Name 'Start' -Value $targets[$path] -Type DWord -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  SysMain/ClipSVC set to Manual (3)" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] Service consistency (requires admin)" -ForegroundColor Gray
    }
}

function Fix-SecurityHardening {
    Write-Host "Fixing security hardening..." -ForegroundColor Yellow

    # NoViewContextMenu must NOT exist (it kills all right-click menus)
    foreach ($userHive in @('HKCU:')) {
        $val = Get-ItemProperty -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name 'NoViewContextMenu' -ErrorAction SilentlyContinue
        if ($val) {
            Remove-ItemProperty -Path "$userHive\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name 'NoViewContextMenu' -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed NoViewContextMenu" -ForegroundColor Green
        }
    }
    $machineVal = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoViewContextMenu' -ErrorAction SilentlyContinue
    if ($machineVal -and $isAdmin) {
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoViewContextMenu' -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed machine NoViewContextMenu" -ForegroundColor Green
    }

    if ($isAdmin) {
        # UAC (real path)
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        # Spotlight kill-switch (real path)
        $ccPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
        if (-not (Test-Path $ccPath)) { New-Item -Path $ccPath -Force | Out-Null }
        Set-ItemProperty -Path $ccPath -Name 'DisableWindowsSpotlightFeatures' -Value 1 -Type DWord -Force
        # Telemetry kill-switch (real path)
        $dcPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
        if (-not (Test-Path $dcPath)) { New-Item -Path $dcPath -Force | Out-Null }
        Set-ItemProperty -Path $dcPath -Name 'AllowTelemetry' -Value 0 -Type DWord -Force
        Write-Host "  UAC/Spotlight/Telemetry policies applied" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] HKLM security policies (requires admin)" -ForegroundColor Gray
    }
}

function Fix-QoLRegistry {
    Write-Host "Fixing QoL registry..." -ForegroundColor Yellow

    # Startup delay off (current user + default profile need admin for HKU)
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' -Name 'StartupDelayInMSec' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    if ($isAdmin -and (Test-Path 'HKU:\AME_UserHive_Default')) {
        $duPath = 'HKU:\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
        if (-not (Test-Path $duPath)) { New-Item -Path $duPath -Force | Out-Null }
        Set-ItemProperty -Path $duPath -Name 'StartupDelayInMSec' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    # Taskbar search = icon
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    # Per-user web search off
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "  Startup delay / taskbar search / Bing search applied" -ForegroundColor Green
}

# ============================================
# Test Functions
# ============================================

function Test-GamingOptimizations {
    Write-Host "Testing gaming optimizations..." -ForegroundColor Cyan
    
    # Game Mode
    $gameMode = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'GameModeEnabled' -ErrorAction SilentlyContinue
    if ($gameMode -and $gameMode.GameModeEnabled -eq 1) {
        Add-TestResult -TestName "Game Mode" -Status "PASS" -Message "Game Mode is enabled"
    } else {
        Add-TestResult -TestName "Game Mode" -Status "FAIL" -Message "Game Mode is not enabled"
    }
    
    # Ndu
    $ndu = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' -Name 'Start' -ErrorAction SilentlyContinue
    if ($ndu -and $ndu.Start -eq 4) {
        Add-TestResult -TestName "Ndu Service" -Status "PASS" -Message "Ndu is disabled"
    } else {
        Add-TestResult -TestName "Ndu Service" -Status "FAIL" -Message "Ndu is not disabled"
    }
    
    # SysMain
    $sysmain = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' -Name 'Start' -ErrorAction SilentlyContinue
    if ($sysmain -and $sysmain.Start -eq 3) {
        Add-TestResult -TestName "SysMain Service" -Status "PASS" -Message "SysMain is set to manual"
    } else {
        Add-TestResult -TestName "SysMain Service" -Status "FAIL" -Message "SysMain is not set to manual"
    }
    
    # WSearch
    $wsearch = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WSearch' -Name 'Start' -ErrorAction SilentlyContinue
    if ($wsearch -and $wsearch.Start -eq 3) {
        Add-TestResult -TestName "WSearch Service" -Status "PASS" -Message "WSearch is set to manual"
    } else {
        Add-TestResult -TestName "WSearch Service" -Status "FAIL" -Message "WSearch is not set to manual"
    }
    
    # GPU Scheduling
    $gpu = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -ErrorAction SilentlyContinue
    if ($gpu -and $gpu.HwSchMode -eq 2) {
        Add-TestResult -TestName "GPU Scheduling" -Status "PASS" -Message "GPU scheduling is enabled"
    } else {
        Add-TestResult -TestName "GPU Scheduling" -Status "FAIL" -Message "GPU scheduling is not enabled"
    }
}

function Test-PrivacySettings {
    Write-Host "Testing privacy settings..." -ForegroundColor Cyan
    
    # Edge Telemetry
    $edge = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'MetricsReportingEnabled' -ErrorAction SilentlyContinue
    if ($edge -and $edge.MetricsReportingEnabled -eq 0) {
        Add-TestResult -TestName "Edge Telemetry" -Status "PASS" -Message "Edge telemetry is disabled"
    } else {
        Add-TestResult -TestName "Edge Telemetry" -Status "FAIL" -Message "Edge telemetry is not disabled"
    }
    
    # SmartScreen
    $smartscreen = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowSmartScreen' -ErrorAction SilentlyContinue
    if ($smartscreen -and $smartscreen.AllowSmartScreen -eq 0) {
        Add-TestResult -TestName "SmartScreen" -Status "PASS" -Message "SmartScreen is disabled"
    } else {
        Add-TestResult -TestName "SmartScreen" -Status "FAIL" -Message "SmartScreen is not disabled"
    }
    
    # Search Suggestions
    $search = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableSearchBoxSuggestions' -ErrorAction SilentlyContinue
    if ($search -and $search.DisableSearchBoxSuggestions -eq 1) {
        Add-TestResult -TestName "Search Suggestions" -Status "PASS" -Message "Search suggestions are disabled"
    } else {
        Add-TestResult -TestName "Search Suggestions" -Status "FAIL" -Message "Search suggestions are not disabled"
    }
    
    # Clipboard History
    $clipboard = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowClipboardHistory' -ErrorAction SilentlyContinue
    if ($clipboard -and $clipboard.AllowClipboardHistory -eq 0) {
        Add-TestResult -TestName "Clipboard History" -Status "PASS" -Message "Clipboard history is disabled"
    } else {
        Add-TestResult -TestName "Clipboard History" -Status "FAIL" -Message "Clipboard history is not disabled"
    }
    
    # Cross-Device Clipboard
    $crossdevice = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowCrossDeviceClipboard' -ErrorAction SilentlyContinue
    if ($crossdevice -and $crossdevice.AllowCrossDeviceClipboard -eq 0) {
        Add-TestResult -TestName "Cross-Device Clipboard" -Status "PASS" -Message "Cross-device clipboard is disabled"
    } else {
        Add-TestResult -TestName "Cross-Device Clipboard" -Status "FAIL" -Message "Cross-device clipboard is not disabled"
    }
}

function Test-BootAnimation {
    Write-Host "Testing boot animation..." -ForegroundColor Cyan
    
    $boot = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation' -Name 'DisableBootAnimation' -ErrorAction SilentlyContinue
    if ($boot -and $boot.DisableBootAnimation -eq 1) {
        Add-TestResult -TestName "Boot Animation" -Status "PASS" -Message "Boot animation is disabled"
    } else {
        Add-TestResult -TestName "Boot Animation" -Status "FAIL" -Message "Boot animation is not disabled"
    }
}

function Test-PowerPlan {
    Write-Host "Testing power plan..." -ForegroundColor Cyan
    
    $active = powercfg /getactivescheme
    if ($active -match "EBOS High Performance") {
        Add-TestResult -TestName "EBOS Power Plan" -Status "PASS" -Message "EBOS High Performance plan is active"
    } else {
        $exists = powercfg /list | Select-String -Pattern "EBOS High Performance"
        if ($exists) {
            Add-TestResult -TestName "EBOS Power Plan" -Status "WARN" -Message "EBOS plan exists but is not active"
        } else {
            Add-TestResult -TestName "EBOS Power Plan" -Status "FAIL" -Message "EBOS High Performance plan does not exist"
        }
    }
}

function Test-Theme {
    Write-Host "Testing theme..." -ForegroundColor Cyan
    
    $theme = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ThemeManager' -Name 'DllName' -ErrorAction SilentlyContinue
    if ($theme -and $theme.DllName -match "ebos-cyan") {
        Add-TestResult -TestName "EBOS Theme" -Status "PASS" -Message "EBOS theme is active"
    } else {
        Add-TestResult -TestName "EBOS Theme" -Status "FAIL" -Message "EBOS theme is not active"
    }
}

function Test-OEMBootEntry {
    Write-Host "Testing OEM boot entry..." -ForegroundColor Cyan
    
    $bcd = bcdedit /enum {current} 2>&1 | Select-String "description"
    if ($bcd -match "EBOS") {
        Add-TestResult -TestName "Boot Entry" -Status "PASS" -Message "Boot entry contains EBOS"
    } else {
        Add-TestResult -TestName "Boot Entry" -Status "FAIL" -Message "Boot entry does not contain EBOS"
    }
    
    $oem = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Manufacturer' -ErrorAction SilentlyContinue
    if ($oem -and $oem.Manufacturer -eq "EBOS Team") {
        Add-TestResult -TestName "OEM Information" -Status "PASS" -Message "OEM information is set"
    } else {
        Add-TestResult -TestName "OEM Information" -Status "FAIL" -Message "OEM information is not set"
    }
}

function Test-ServiceConsistency {
    Write-Host "Testing service consistency..." -ForegroundColor Cyan

    $sysmain = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' -Name 'Start' -ErrorAction SilentlyContinue
    if ($sysmain -and $sysmain.Start -eq 3) {
        Add-TestResult -TestName "SysMain Consistency" -Status "PASS" -Message "SysMain is Manual (matches playbook)"
    } else {
        Add-TestResult -TestName "SysMain Consistency" -Status "FAIL" -Message "SysMain is not Manual (3)"
    }

    $clip = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\ClipSVC' -Name 'Start' -ErrorAction SilentlyContinue
    if ($clip -and $clip.Start -eq 3) {
        Add-TestResult -TestName "ClipSVC Manual" -Status "PASS" -Message "ClipSVC is Manual (Store-safe)"
    } else {
        Add-TestResult -TestName "ClipSVC Manual" -Status "FAIL" -Message "ClipSVC is not Manual (3)"
    }
}

function Test-SecurityHardening {
    Write-Host "Testing security hardening..." -ForegroundColor Cyan

    $ncm = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoViewContextMenu' -ErrorAction SilentlyContinue
    $ncu = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoViewContextMenu' -ErrorAction SilentlyContinue
    if (-not $ncm -and -not $ncu) {
        Add-TestResult -TestName "Context Menus Intact" -Status "PASS" -Message "NoViewContextMenu is absent"
    } else {
        Add-TestResult -TestName "Context Menus Intact" -Status "FAIL" -Message "NoViewContextMenu is set (breaks right-click)"
    }

    $lua = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -ErrorAction SilentlyContinue
    if ($lua -and $lua.EnableLUA -eq 1) {
        Add-TestResult -TestName "UAC Enabled" -Status "PASS" -Message "EnableLUA is 1 at the real path"
    } else {
        Add-TestResult -TestName "UAC Enabled" -Status "FAIL" -Message "EnableLUA is not 1"
    }

    $spot = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -ErrorAction SilentlyContinue
    if ($spot -and $spot.DisableWindowsSpotlightFeatures -eq 1) {
        Add-TestResult -TestName "Spotlight Off" -Status "PASS" -Message "Spotlight features are disabled"
    } else {
        Add-TestResult -TestName "Spotlight Off" -Status "FAIL" -Message "Spotlight features are not disabled"
    }

    $tel = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    if ($tel -and $tel.AllowTelemetry -eq 0) {
        Add-TestResult -TestName "Telemetry Policy" -Status "PASS" -Message "AllowTelemetry is 0"
    } else {
        Add-TestResult -TestName "Telemetry Policy" -Status "FAIL" -Message "AllowTelemetry is not 0"
    }
}

function Test-QoLRegistry {
    Write-Host "Testing QoL registry..." -ForegroundColor Cyan

    $sd = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' -Name 'StartupDelayInMSec' -ErrorAction SilentlyContinue
    if ($sd -and $sd.StartupDelayInMSec -eq 0) {
        Add-TestResult -TestName "Startup Delay" -Status "PASS" -Message "Startup delay is disabled"
    } else {
        Add-TestResult -TestName "Startup Delay" -Status "FAIL" -Message "Startup delay is not disabled"
    }

    $sb = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -ErrorAction SilentlyContinue
    if ($sb -and $sb.SearchboxTaskbarMode -eq 1) {
        Add-TestResult -TestName "Taskbar Search" -Status "PASS" -Message "SearchboxTaskbarMode is 1 (icon)"
    } else {
        Add-TestResult -TestName "Taskbar Search" -Status "FAIL" -Message "SearchboxTaskbarMode is not 1"
    }

    $bing = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -ErrorAction SilentlyContinue
    if ($bing -and $bing.BingSearchEnabled -eq 0) {
        Add-TestResult -TestName "Bing Search Off" -Status "PASS" -Message "Per-user Bing search is disabled"
    } else {
        Add-TestResult -TestName "Bing Search Off" -Status "FAIL" -Message "Per-user Bing search is not disabled"
    }
}

# ============================================
# Main Execution
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "EBOS Verification Script" -ForegroundColor Cyan
Write-Host "Version: 2.1.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($FixIssues) {
    Write-Host "Fixing all issues..." -ForegroundColor Yellow
    Write-Host ""
    
    Fix-GamingOptimizations
    Fix-PrivacySettings
    Fix-BootAnimation
    Fix-PowerPlan
    Fix-Theme
    Fix-OEMBootEntry
    Fix-ServiceConsistency
    Fix-SecurityHardening
    Fix-QoLRegistry
    
    Write-Host ""
    Write-Host "All fixes applied!" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Running verification tests..." -ForegroundColor Yellow
Write-Host ""

Test-GamingOptimizations
Test-PrivacySettings
Test-BootAnimation
Test-PowerPlan
Test-Theme
Test-OEMBootEntry
Test-ServiceConsistency
Test-SecurityHardening
Test-QoLRegistry

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Verification Results" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestPass + $TestFail + $TestWarn)" -ForegroundColor White
Write-Host "Passed: $TestPass" -ForegroundColor Green
Write-Host "Failed: $TestFail" -ForegroundColor Red
Write-Host "Warnings: $TestWarn" -ForegroundColor Yellow
Write-Host ""

if ($TestFail -eq 0) {
    Write-Host "STATUS: All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "STATUS: Some tests failed. Run with -FixIssues to fix." -ForegroundColor Red
    exit 1
}