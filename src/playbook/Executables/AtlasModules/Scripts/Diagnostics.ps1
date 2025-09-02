[CmdletBinding()]
param (
    [string]$OutputPath,
    [switch]$NoConsole,
    [string]$JsonPath
)

Set-StrictMode -Version Latest # Catch undefined vars during development.
$ErrorActionPreference = 'Stop'

# Initialize buffer for collected output.
$script:_lines = @()

# Returns Atlas logs directory or creates it.
function Get-LogsDir {
    $dir = Join-Path -Path (Join-Path $Env:WINDIR 'AtlasModules') -ChildPath 'Logs'
    try { New-Item -Path $dir -ItemType Directory -Force | Out-Null } catch {}
    return $dir
}

# Appends a line to the in‑memory buffer and writes to console unless -NoConsole.
function Write-Line {
    param([string]$Text)
    if (-not $script:_lines) { $script:_lines = @() }
    $script:_lines += $Text
    if (-not $NoConsole) { Write-Host $Text }
}

# Reads a registry value, returns the provided default when missing.
function Read-RegistryValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name,
        [object]$Default = $null
    )
    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -EA Stop
        return $item.$Name
    } catch {
        return $Default
    }
}

# Returns the Atlas version string written by the playbook OEM step.
function Get-AtlasVersionInfo {
    $org = Read-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'RegisteredOrganization'
    $oemModel = Read-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Model'
    if ($org -is [string] -and $org -match 'Atlas Playbook') { return $org }
    if ($oemModel -is [string] -and $oemModel -match 'Atlas Playbook') { return $oemModel }
    return 'Atlas Version: Unknown'
}

# Returns basic OS information via CIM.
function Get-OSInfo {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        return [PSCustomObject]@{
            Caption = $os.Caption
            Version = $os.Version
            Build   = $os.BuildNumber
            InstallDate = $os.InstallDate
        }
    } catch {
        return $null
    }
}

# Parses the active power scheme from `powercfg /GETACTIVESCHEME` output.
function Get-ActivePowerScheme {
    try {
        $out = & powercfg /GETACTIVESCHEME 2>$null
        # 11111111-1111-1111-1111-111111111111.
        if ($out -match 'Power Scheme GUID:\s*([\w-]+)\s*\((.+)\)') {
            return [PSCustomObject]@{ Guid = $Matches[1]; Name = $Matches[2] }
        }
    } catch {}
    return $null
}

# Returns Windows Update policy/config keys relevant to Atlas.
function Get-WindowsUpdateState {
    $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    $wuPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $obj = [PSCustomObject]@{
        AUOptions = Read-RegistryValue -Path $auPath -Name 'AUOptions'
        NoAutoRebootWithLoggedOnUsers = Read-RegistryValue -Path $auPath -Name 'NoAutoRebootWithLoggedOnUsers'
        AUPowerManagement = Read-RegistryValue -Path $wuPath -Name 'AUPowerManagement'
        TargetReleaseVersion = Read-RegistryValue -Path $wuPath -Name 'TargetReleaseVersion'
        ProductVersion = Read-RegistryValue -Path $wuPath -Name 'ProductVersion'
    }
    return $obj
}

# Returns WinDefend presence and state.
function Get-DefenderState {
    $svc = Get-Service -Name 'WinDefend' -EA SilentlyContinue
    if (-not $svc) {
        return [PSCustomObject]@{ Present = $false; Status = 'Removed/Unavailable'; StartType = 'N/A' }
    }
    return [PSCustomObject]@{
        Present = $true
        Status = [string]$svc.Status
        StartType = [string]$svc.StartType
    }
}

# Reads Memory Management mitigation flags used by the Atlas mitigations script.
function Get-MitigationsState {
    $mmPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $override = Read-RegistryValue -Path $mmPath -Name 'FeatureSettingsOverride' -Default 0
    $mask     = Read-RegistryValue -Path $mmPath -Name 'FeatureSettingsOverrideMask' -Default 0
    # Atlas disables by setting both to 3 in the provided script
    $disabled = ($override -eq 3 -and $mask -eq 3)
    return [PSCustomObject]@{ Disabled = $disabled; FeatureSettingsOverride = $override; FeatureSettingsOverrideMask = $mask }
}

# Reads Core Isolation (HVCI / Memory Integrity) state when available.
function Get-CoreIsolationState {
    $hvcPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
    $enabled = Read-RegistryValue -Path $hvcPath -Name 'Enabled'
    if ($null -eq $enabled) { return $null }
    return [PSCustomObject]@{ MemoryIntegrityEnabled = [int]$enabled }
}

# Returns targeted services/drivers status and startup configuration.
function Get-ServicesState {
    $names = @(
        'OneSyncSvc*',
        'TrkWks',
        'PcaSvc',
        'DiagTrack',
        'diagnosticshub.standardcollector.service',
        'WerSvc',
        'wercplsupport',
        'UCPD',
        'GpuEnergyDrv',
        'NetBT',
        'Telemetry'
    )
    $results = @()
    foreach ($n in $names) {
        $svcs = Get-Service -Name $n -EA SilentlyContinue
        if (-not $svcs) {
            # Tries service registry for drivers or missing items.
            $svcName = $n.TrimEnd('*')
            try {
                $reg = Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\$svcName" -EA Stop
                $start = (Get-ItemProperty $reg.PSPath -Name 'Start' -EA 0).Start
                $results += [PSCustomObject]@{ Name = $svcName; Present = $true; Status = 'Unknown'; Start = $start }
            } catch {
                $results += [PSCustomObject]@{ Name = $n; Present = $false; Status = 'NotFound'; Start = $null }
            }
            continue
        }
        foreach ($s in $svcs) {
            $start = $null
            try { $start = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$($s.Name)" -Name 'Start' -EA 0).Start } catch {}
            $results += [PSCustomObject]@{ Name = $s.Name; Present = $true; Status = [string]$s.Status; StartType = [string]$s.StartType; Start = $start }
        }
    }
    return $results
}

# Lists deprovisioned AppX.
function Get-DeprovisionedAppx {
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned'
    try {
        $keys = Get-ChildItem -Path $path -EA Stop
        return @($keys | Select-Object -ExpandProperty PSChildName | Sort-Object -Unique)
    } catch {
        return @()
    }
}

# Returns $true if any path in an array exists.
function Test-AnyPath {
    param([Parameter(Mandatory)][string[]]$Paths)
    foreach ($p in $Paths) { if (Test-Path $p) { return $true } }
    return $false
}

# Collect data for report.
$atlasVer = Get-AtlasVersionInfo
$os = Get-OSInfo
$scheme = Get-ActivePowerScheme
$wu = Get-WindowsUpdateState
$def = Get-DefenderState
$mit = Get-MitigationsState
$cis = Get-CoreIsolationState
$svcs = Get-ServicesState
$apps = Get-DeprovisionedAppx

# Render text report.
Write-Line ('='.PadRight(70, '='))
Write-Line ('Atlas Diagnostics Report - ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
Write-Line ('='.PadRight(70, '='))
Write-Line ""

Write-Line '[System]'
if ($os) {
    Write-Line ("OS: {0} (Build {1}, Version {2})" -f $os.Caption, $os.Build, $os.Version)
} else {
    Write-Line 'OS: Unknown'
}
Write-Line ("Atlas: {0}" -f $atlasVer)
if ($scheme) {
    Write-Line ("Power Plan: {0} ({1})" -f $scheme.Name, $scheme.Guid)
} else {
    Write-Line 'Power Plan: Unknown'
}
Write-Line ''

Write-Line '[Windows Update]'
$auOptions = if ($null -ne $wu.AUOptions) { $wu.AUOptions } else { 'Unset' }
$noRebootWithUsers = if ($null -ne $wu.NoAutoRebootWithLoggedOnUsers) { $wu.NoAutoRebootWithLoggedOnUsers } else { 'Unset' }
$auPower = if ($null -ne $wu.AUPowerManagement) { $wu.AUPowerManagement } else { 'Unset' }
Write-Line ("AUOptions: {0}" -f $auOptions)
Write-Line ("NoAutoRebootWithLoggedOnUsers: {0}" -f $noRebootWithUsers)
Write-Line ("AUPowerManagement: {0}" -f $auPower)
if ($wu.TargetReleaseVersion) { Write-Line ("TargetReleaseVersion: {0}" -f $wu.TargetReleaseVersion) }
if ($wu.ProductVersion) { Write-Line ("ProductVersion: {0}" -f $wu.ProductVersion) }
Write-Line ''

Write-Line '[Security]'
Write-Line ("Defender: {0}; StartType={1}" -f ($def.Status), ($def.StartType))
if ($mit) { Write-Line ("Mitigations Disabled: {0} (FSO={1}, Mask={2})" -f $mit.Disabled, $mit.FeatureSettingsOverride, $mit.FeatureSettingsOverrideMask) }
if ($cis) { Write-Line ("Memory Integrity (HVCI): {0}" -f $cis.MemoryIntegrityEnabled) }
Write-Line ''

Write-Line '[Services/Drivers]'
foreach ($s in ($svcs | Sort-Object Name)) {
    $startMap = @{ '0'='Boot'; '1'='System'; '2'='Automatic'; '3'='Manual'; '4'='Disabled' }
    $startText = $null
    if ($null -ne $s.Start) {
        $mapped = $startMap[[string]$s.Start]
        $startText = if ($null -ne $mapped) { $mapped } else { $s.Start }
    } else {
        $hasStartType = $s.PSObject.Properties.Match('StartType').Count -gt 0
        if ($hasStartType -and $null -ne $s.StartType) {
            $startText = $s.StartType
        } else {
            $startText = 'Unknown'
        }
    }
    $statusText = if ($null -ne $s.Status) { $s.Status } else { 'Unknown' }
    Write-Line ("{0,-40} Present={1,-5} Status={2,-10} Start={3}" -f $s.Name, $s.Present, $statusText, $startText)
}
Write-Line ''

Write-Line '[AppX Deprovisioned]'
if (@($apps).Count -gt 0) {
    foreach ($a in @($apps)) { Write-Line "- $a" }
} else {
    Write-Line '(none)'
}
Write-Line ''

# Persist both reports to text and JSON files.
try {
    $logsDir = Get-LogsDir

    # Build JSON report object for Atlas Toolbox.
    $startMap = @{ '0'='Boot'; '1'='System'; '2'='Automatic'; '3'='Manual'; '4'='Disabled' }
    $servicesForJson = @()
    foreach ($s in ($svcs | Sort-Object Name)) {
        $startCode = $null
        $startText = 'Unknown'
        if ($null -ne $s.Start) {
            $startCode = $s.Start
            $mapped = $startMap[[string]$s.Start]
            if ($null -ne $mapped) { $startText = $mapped } else { $startText = $s.Start }
        } elseif ($s.PSObject.Properties.Match('StartType').Count -gt 0 -and $null -ne $s.StartType) {
            $startText = [string]$s.StartType
        }
        $servicesForJson += [ordered]@{
            name = $s.Name
            present = [bool]$s.Present
            status = if ($null -ne $s.Status) { [string]$s.Status } else { 'Unknown' }
            start = $startText
            startCode = $startCode
        }
    }

    $systemObj = [ordered]@{
        caption = if ($os) { [string]$os.Caption } else { $null }
        version = if ($os) { [string]$os.Version } else { $null }
        build   = if ($os) { [string]$os.Build } else { $null }
        powerPlan = if ($scheme) { [ordered]@{ name = $scheme.Name; guid = $scheme.Guid } } else { $null }
        atlasVersion = $atlasVer
    }
    $updateObj = [ordered]@{
        AUOptions = $wu.AUOptions
        NoAutoRebootWithLoggedOnUsers = $wu.NoAutoRebootWithLoggedOnUsers
        AUPowerManagement = $wu.AUPowerManagement
        TargetReleaseVersion = $wu.TargetReleaseVersion
        ProductVersion = $wu.ProductVersion
    }
    $securityObj = [ordered]@{
        defender = [ordered]@{ status = $def.Status; startType = $def.StartType; present = $def.Present }
        mitigations = [ordered]@{ disabled = $mit.Disabled; featureSettingsOverride = $mit.FeatureSettingsOverride; featureSettingsOverrideMask = $mit.FeatureSettingsOverrideMask }
        memoryIntegrity = $cis.MemoryIntegrityEnabled
    }
    $report = [ordered]@{
        generatedAt = (Get-Date).ToString('o')
        system = $systemObj
        update = $updateObj
        security = $securityObj
        services = $servicesForJson
        appxDeprovisioned = @($apps)
    }

    # Write text report.
    $textPath = if ([string]::IsNullOrWhiteSpace($OutputPath)) { (Join-Path -Path $logsDir -ChildPath 'diagnostics.txt') } else { $OutputPath }
    $textDir = Split-Path -Path $textPath -Parent
    if (-not (Test-Path $textDir)) { New-Item -Path $textDir -ItemType Directory -Force | Out-Null }
    $script:_lines | Set-Content -Path $textPath -Encoding UTF8
    if (-not $NoConsole) { Write-Host ("Saved text to: {0}" -f $textPath) -ForegroundColor Green }

    # Write JSON report.
    $jsonPath = if ([string]::IsNullOrWhiteSpace($JsonPath)) { (Join-Path -Path $logsDir -ChildPath 'diagnostics.json') } else { $JsonPath }
    $jsonDir = Split-Path -Path $jsonPath -Parent
    if (-not (Test-Path $jsonDir)) { New-Item -Path $jsonDir -ItemType Directory -Force | Out-Null }
    $jsonText = $report | ConvertTo-Json -Depth 8
    $jsonText | Set-Content -Path $jsonPath -Encoding UTF8
    if (-not $NoConsole) { Write-Host ("Saved JSON to: {0}" -f $jsonPath) -ForegroundColor Green }
} catch {
    if (-not $NoConsole) { Write-Warning ("Failed to write diagnostics file(s): {0}" -f $_.Exception.Message) }
}
