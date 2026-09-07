<#
.SYNOPSIS
    Collects one text report of what Atlas installed on this machine, what no longer
    holds, and the machine state around it, for sending back with a bug report.
.DESCRIPTION
    Run this on a machine that has Atlas installed. It reads only; it changes nothing.

    The report has two kinds of section. The authoritative one is the drift check: the
    shipped health check reads every recorded toggle state and every applicable install
    tweak back from this machine and reports what no longer holds. Everything else is
    context that the drift check cannot cover, because that work is imperative rather
    than declared, or because it describes the machine rather than Atlas:

      1. Machine, under a summary of the findings.
      2. Atlas install state: the state document, the last install transaction and its
         completed steps, and the recorded toggle states.
      3. The toggle state registry store.
      4. Drift, from AtlasModules\Scripts\Entry\Test-AtlasHealth.ps1.
      5. Spot checks: Edge, Defender, Atlas CBS packages, payload tree, appearance.
      6. Services and drivers, with their startup types.
      7. Installed applications and AppX packages.
      8. Scheduled tasks.
      9. Startup entries and pending-reboot state.
     10. Event log errors and warnings since the install.
     11. The tail of the Atlas install logs and this account's user-setup transcript.

    Every section is independent. One that cannot be collected records why, and the
    report still completes.
.PARAMETER OutputPath
    Where to write the report. Defaults to a timestamped file on the current user's
    Desktop.
.PARAMETER LogLines
    How many lines to keep from the end of each log file.
.PARAMETER EventCount
    How many recent event log entries to list per log, after the counts by source.
.PARAMETER RcDiagnostics
    Also collects Search registry configuration, PCA task definition/history, and
    OneDrive shell-extension permissions and loaded-module owners, WebView2 runtime
    files/registration, local policy processing, effective Search scope and BITS
    failure diagnostics. Read-only; does
    not enable event logs, reapply settings, stop processes, or restart Windows.
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1
.NOTES
    Run it from an elevated Windows PowerShell prompt, as the account that installed
    Atlas. Elevation makes every machine read succeed, and the per-user checks are only
    meaningful for that account.
#>
[CmdletBinding()]
param(
    [string]$OutputPath,

    [ValidateRange(1, 500)]
    [int]$LogLines = 40,

    [ValidateRange(1, 500)]
    [int]$EventCount = 60,

    [switch]$RcDiagnostics
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $OutputPath) {
    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = $env:USERPROFILE
    }
    $OutputPath = Join-Path -Path $desktop -ChildPath ('atlas-install-report-{0:yyyyMMdd-HHmmss}.txt' -f (Get-Date))
}

# The collectors below run as scriptblocks, so their inputs are bound at script scope.
$script:LogTailLines = $LogLines
$script:EventListCount = $EventCount
$script:Summary = New-Object System.Collections.Generic.List[string]

$windir = [Environment]::GetFolderPath('Windows')
$atlasModules = Join-Path -Path $windir -ChildPath 'AtlasModules'
$atlasDesktop = Join-Path -Path $windir -ChildPath 'AtlasDesktop'
$atlasState = Join-Path -Path $windir -ChildPath 'AtlasOS'
$report = New-Object System.Collections.Generic.List[string]

function Add-Line {
    param([string]$Text = '')
    $report.Add($Text)
}

function Add-Summary {
    param([Parameter(Mandatory = $true)][string]$Text)
    $script:Summary.Add($Text)
}

function Add-Section {
    <#
    .SYNOPSIS
        Runs one collector and records its output, or the reason it produced none.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Collector
    )

    Write-Host "Collecting: $Title"
    Add-Line ''
    Add-Line ('=' * 78)
    Add-Line $Title
    Add-Line ('=' * 78)
    try {
        $output = & $Collector
        $lines = @($output | ForEach-Object { "$_" })
        if ($lines.Count -eq 0) {
            Add-Line '(nothing to report)'
            return
        }
        foreach ($line in $lines) {
            Add-Line $line
        }
    }
    catch {
        Add-Line "COLLECTION FAILED: $($_.Exception.Message)"
        Add-Summary "Section '$Title' could not be collected: $($_.Exception.Message)"
    }
}

function Get-RegistryValueOrNull {
    <#
    .SYNOPSIS
        Reads one registry value, returning $null when the key or the value is absent.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $item = Get-ItemProperty -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $item -or @($item.PSObject.Properties.Name) -notcontains $Name) {
        return $null
    }
    return $item.$Name
}

function Get-FileTail {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Count
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return "(missing: $Path)"
    }
    $lines = @(Get-Content -LiteralPath $Path -Tail $Count -ErrorAction Stop)
    return @("--- last $($lines.Count) line(s) of $Path ---") + $lines
}

function Test-PathState {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $exists = Test-Path -LiteralPath $Path
    return ('{0,-46} {1}  {2}' -f $Label, $(if ($exists) { 'PRESENT' } else { 'absent ' }), $Path)
}

# The install time bounds the event log queries; without it, fall back to this boot.
$script:InstalledAt = $null
$statePath = Join-Path -Path $atlasState -ChildPath 'state.json'
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    try {
        $stateDocument = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $script:InstalledAt = [datetime]::Parse([string]$stateDocument.installedAt)
    }
    catch {
        $script:InstalledAt = $null
    }
}

Add-Section -Title '1. Machine' -Collector {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $versionKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $elevated) {
        Add-Summary 'Collected without elevation, so some sections are incomplete.'
    }

    "Edition           : $($os.Caption)"
    "Version           : $(Get-RegistryValueOrNull -Path $versionKey -Name 'DisplayVersion') (build $(Get-RegistryValueOrNull -Path $versionKey -Name 'CurrentBuild').$(Get-RegistryValueOrNull -Path $versionKey -Name 'UBR'))"
    "Architecture      : $env:PROCESSOR_ARCHITECTURE"
    "Model             : $($computer.Manufacturer) $($computer.Model)"
    "Memory            : $([math]::Round($computer.TotalPhysicalMemory / 1GB, 1)) GB"
    "PowerShell        : $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
    "User              : $($identity.Name) [$($identity.User.Value)]"
    "Elevated          : $elevated"
    "OS install date   : $($os.InstallDate)"
    "Last boot         : $($os.LastBootUpTime)"
    "Atlas installed   : $(if ($script:InstalledAt) { $script:InstalledAt } else { '(unknown)' })"
}

Add-Section -Title '2. Atlas install state' -Collector {
    $lastPath = Join-Path -Path $atlasState -ChildPath 'Install\last.json'
    $lines = @()

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $lines += "state.json          : $statePath"
        $lines += "  installedVersion  : $($state.installedVersion)"
        $lines += "  installedAt       : $($state.installedAt)"
        $lines += "  mode              : $($state.mode)  (oobe=$($state.isOobe), interactive=$($state.isInteractive))"
        $lines += "  options           : $(@($state.options) -join ', ')"
        $lines += '  history           :'
        foreach ($entry in @($state.history)) {
            $lines += "    $($entry.version) $($entry.mode) $($entry.completedAt) [$($entry.transactionId)]"
        }
        $toggles = @($state.toggles.PSObject.Properties | Sort-Object -Property Name)
        $lines += "  recorded toggles  : $($toggles.Count)"
        foreach ($toggle in $toggles) {
            $lines += ('    {0,-32} state {1}  {2}' -f $toggle.Name, $toggle.Value.state, $toggle.Value.updatedAt)
        }
        Add-Summary "Atlas $($state.installedVersion) installed $($state.installedAt) ($($state.mode)), $($toggles.Count) recorded toggle(s)."
    }
    else {
        $lines += "state.json is missing at '$statePath'. Atlas is not installed here, or it was installed by a build that predates the state document."
        Add-Summary 'The Atlas machine state document is missing.'
    }

    $lines += ''
    if (Test-Path -LiteralPath $lastPath -PathType Leaf) {
        $last = Get-Content -LiteralPath $lastPath -Raw | ConvertFrom-Json
        $lines += "last.json           : $lastPath"
        $lines += "  status            : $($last.status)"
        $lines += "  targetVersion     : $($last.targetVersion)  mode $($last.mode)  oobe $($last.isOobe)"
        $lines += "  transactionId     : $($last.transactionId)"
        $lines += "  lastError         : $(if ($last.lastError) { $last.lastError } else { '(none)' })"
        $lines += "  completedSteps    : $(@($last.completedSteps).Count)"
        foreach ($step in @($last.completedSteps)) {
            $lines += "    $step"
        }
        Add-Summary "Last install transaction: $($last.status), $(@($last.completedSteps).Count) step(s) completed, lastError $(if ($last.lastError) { $last.lastError } else { 'none' })."
    }
    else {
        $lines += "last.json is missing at '$lastPath'."
    }
    $lines
}

Add-Section -Title '3. Toggle state registry store (HKLM\SOFTWARE\AtlasOS\Services)' -Collector {
    $storeRoot = 'HKLM:\SOFTWARE\AtlasOS\Services'
    if (-not (Test-Path -LiteralPath $storeRoot)) {
        return "The toggle state store is missing at '$storeRoot'."
    }
    foreach ($key in @(Get-ChildItem -LiteralPath $storeRoot | Sort-Object -Property PSChildName)) {
        $state = Get-RegistryValueOrNull -Path $key.PSPath -Name 'State'
        '{0,-32} {1}' -f $key.PSChildName, $(if ($null -eq $state) { '(no State value)' } else { $state })
    }
}

Add-Section -Title '4. Health check: every recorded toggle and applicable tweak, verified against this machine' -Collector {
    $healthScript = Join-Path -Path $atlasModules -ChildPath 'Scripts\Entry\Test-AtlasHealth.ps1'
    if (-not (Test-Path -LiteralPath $healthScript -PathType Leaf)) {
        Add-Summary 'The shipped health check is missing, so drift could not be verified.'
        return "The health check is missing at '$healthScript'. This Atlas build predates it."
    }

    $powerShell = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'
    $output = & $powerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $healthScript 2>&1 |
        ForEach-Object { "$_" }
    $exitCode = $LASTEXITCODE
    $meaning = switch ($exitCode) {
        0 { 'no drift' }
        1 { 'drift found, listed above' }
        2 { 'the check could not run' }
        default { 'unexpected exit code' }
    }
    Add-Summary "Health check: $meaning (exit code $exitCode)."
    @($output) + @('', "Health check exit code: $exitCode ($meaning)")
}

Add-Section -Title '5. Spot checks (imperative work the drift check cannot verify)' -Collector {
    $programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
    $lines = @()

    $lines += '-- Atlas payload --'
    $lines += Test-PathState -Label 'AtlasModules' -Path $atlasModules
    $lines += Test-PathState -Label 'AtlasDesktop' -Path $atlasDesktop
    $lines += Test-PathState -Label 'Toolbox' -Path (Join-Path $atlasModules 'Toolbox')
    $lines += Test-PathState -Label 'Services backup' -Path (Join-Path $atlasModules 'Other\atlasServices.reg')
    $lines += Test-PathState -Label 'Health check' -Path (Join-Path $atlasModules 'Scripts\Entry\Test-AtlasHealth.ps1')
    if (Test-Path -LiteralPath $atlasDesktop) {
        $launchers = @(Get-ChildItem -LiteralPath $atlasDesktop -Recurse -File -Filter '*.cmd')
        $lines += ('{0,-46} {1}' -f 'AtlasDesktop launcher count', $launchers.Count)
    }

    $lines += ''
    $lines += '-- Microsoft Edge --'
    $lines += Test-PathState -Label 'msedge.exe' -Path (Join-Path $programFilesX86 'Microsoft\Edge\Application\msedge.exe')
    try {
        $edgePackages = @(Get-AppxPackage -AllUsers -Name 'Microsoft.MicrosoftEdge*' -ErrorAction Stop)
        $lines += "Installed Edge AppX package count (all users): $($edgePackages.Count)"
        if ($edgePackages.Count -eq 0) {
            $lines += 'AppX packages matching Microsoft.MicrosoftEdge*: none'
        }
        foreach ($package in $edgePackages) {
            $lines += "AppX still registered: $($package.PackageFullName)"
            $lines += "  NonRemovable=$($package.NonRemovable); Status=$($package.Status); InstallLocation=$($package.InstallLocation)"
        }
    }
    catch {
        $lines += "AppX query failed: $($_.Exception.Message)"
    }
    try {
        $provisionedEdge = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop |
            Where-Object { $_.DisplayName -like 'Microsoft.MicrosoftEdge*' })
        $lines += "Provisioned Edge AppX package count: $($provisionedEdge.Count)"
        foreach ($package in $provisionedEdge) {
            $lines += "AppX still provisioned: $($package.PackageName)"
        }
    }
    catch {
        $lines += "Provisioned Edge AppX query failed: $($_.Exception.Message)"
    }
    $lines += 'Compare these current inventories with installer warnings after reboot and first sign-in; Windows may finish package removal during sign-in.'

    $lines += ''
    $lines += '-- Defender and security services --'
    foreach ($service in 'WinDefend', 'WdNisSvc', 'WdFilter', 'WdBoot', 'Sense', 'wscsvc', 'SecurityHealthService', 'mpssvc') {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$service"
        if (Test-Path -LiteralPath $key) {
            $lines += ('{0,-46} Start={1}' -f "service $service", (Get-RegistryValueOrNull -Path $key -Name 'Start'))
        }
        else {
            $lines += ('{0,-46} absent' -f "service $service")
        }
    }

    $lines += ''
    $lines += '-- Atlas CBS packages --'
    try {
        $packages = @(Get-WindowsPackage -Online -ErrorAction Stop | Where-Object { $_.PackageName -like '*Atlas*' })
        if ($packages.Count -eq 0) {
            $lines += 'none installed'
        }
        foreach ($package in $packages) {
            $lines += "$($package.PackageName) [$($package.PackageState)]"
        }
    }
    catch {
        $lines += "CBS package query failed: $($_.Exception.Message)"
    }

    $lines += ''
    $lines += '-- Current user appearance and setup --'
    foreach ($feature in 'HighContrast', 'Keyboard Response', 'MouseKeys', 'StickyKeys', 'ToggleKeys') {
        $flagValue = Get-RegistryValueOrNull -Path ("HKCU:\Control Panel\Accessibility\$feature") -Name Flags
        $lines += "Accessibility $feature Flags: $(if ($null -eq $flagValue) { '(missing)' } else { $flagValue })"
    }
    foreach ($value in 'WallPaper', 'WallpaperStyle') {
        $lines += ('{0,-46} {1}' -f $value, (Get-RegistryValueOrNull -Path 'HKCU:\Control Panel\Desktop' -Name $value))
    }
    $lines += ('{0,-46} {1}' -f 'CurrentTheme', (Get-RegistryValueOrNull -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes' -Name 'CurrentTheme'))
    $lines += Test-PathState -Label 'Atlas desktop shortcut' -Path (Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Atlas.lnk')
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $marker = Get-RegistryValueOrNull -Path 'HKCU:\SOFTWARE\AtlasOS\UserSetup' -Name $sid
    $lines += ('{0,-46} {1}' -f 'User setup marker (2 = complete)', $(if ($null -eq $marker) { '(none)' } else { $marker }))
    $lines
}

Add-Section -Title '6. Services and drivers' -Collector {
    $startNames = @{ 0 = 'Boot'; 1 = 'System'; 2 = 'Automatic'; 3 = 'Manual'; 4 = 'Disabled' }
    $servicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    $running = @{}
    foreach ($service in @(Get-Service -ErrorAction SilentlyContinue)) {
        $running[$service.Name] = [string]$service.Status
    }

    $rows = @()
    foreach ($key in @(Get-ChildItem -LiteralPath $servicesRoot -ErrorAction Stop)) {
        $name = [string]$key.PSChildName
        $start = Get-RegistryValueOrNull -Path $key.PSPath -Name 'Start'
        if ($null -eq $start) { continue }
        $type = Get-RegistryValueOrNull -Path $key.PSPath -Name 'Type'
        $isDriver = ($null -ne $type -and ([int]$type -band 0x0F) -le 2 -and ([int]$type -band 0x30) -eq 0)
        $startAs = if ($startNames.ContainsKey([int]$start)) { $startNames[[int]$start] } else { "($start)" }
        $rows += [pscustomobject]@{
            Name    = $name
            Kind    = $(if ($isDriver) { 'driver' } else { 'service' })
            StartAs = $startAs
            Status  = $(if ($running.ContainsKey($name)) { $running[$name] } else { '' })
        }
    }

    $lines = @()
    $lines += "Total entries: $($rows.Count)"
    foreach ($group in @($rows | Group-Object -Property StartAs | Sort-Object -Property Name)) {
        $lines += ('  {0,-12} {1}' -f $group.Name, $group.Count)
    }
    $lines += ''
    $lines += ('{0,-44} {1,-8} {2,-10} {3}' -f 'NAME', 'KIND', 'START', 'STATUS')
    foreach ($row in @($rows | Sort-Object -Property Name)) {
        $lines += ('{0,-44} {1,-8} {2,-10} {3}' -f $row.Name, $row.Kind, $row.StartAs, $row.Status)
    }
    $lines
}

Add-Section -Title '7. Installed applications and AppX packages' -Collector {
    $uninstallRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $applications = @()
    foreach ($root in $uninstallRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        foreach ($key in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
            $displayName = Get-RegistryValueOrNull -Path $key.PSPath -Name 'DisplayName'
            if (-not $displayName) { continue }
            if ((Get-RegistryValueOrNull -Path $key.PSPath -Name 'SystemComponent') -eq 1) { continue }
            $applications += [pscustomobject]@{
                Name      = [string]$displayName
                Version   = [string](Get-RegistryValueOrNull -Path $key.PSPath -Name 'DisplayVersion')
                Publisher = [string](Get-RegistryValueOrNull -Path $key.PSPath -Name 'Publisher')
            }
        }
    }

    $lines = @()
    $unique = @($applications | Sort-Object -Property Name, Version -Unique)
    $lines += "-- Uninstall entries: $($unique.Count) --"
    foreach ($application in $unique) {
        $lines += ('{0,-52} {1,-18} {2}' -f $application.Name, $application.Version, $application.Publisher)
    }

    $lines += ''
    try {
        $packages = @(Get-AppxPackage -ErrorAction Stop | Sort-Object -Property Name)
        $lines += "-- AppX packages for this user: $($packages.Count) --"
        foreach ($package in $packages) {
            $lines += ('{0,-58} {1}' -f $package.Name, $package.Version)
        }
    }
    catch {
        $lines += "AppX query failed: $($_.Exception.Message)"
    }

    $lines += ''
    try {
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Sort-Object -Property DisplayName)
        $lines += "-- Provisioned AppX packages: $($provisioned.Count) --"
        foreach ($package in $provisioned) {
            $lines += ('{0,-58} {1}' -f $package.DisplayName, $package.Version)
        }
    }
    catch {
        $lines += "Provisioned AppX query failed (needs elevation): $($_.Exception.Message)"
    }
    $lines
}

Add-Section -Title '8. Scheduled tasks' -Collector {
    $tasks = @(Get-ScheduledTask -ErrorAction Stop)
    $lines = @()
    $lines += "Total tasks: $($tasks.Count)"
    foreach ($group in @($tasks | Group-Object -Property State | Sort-Object -Property Name)) {
        $lines += ('  {0,-12} {1}' -f $group.Name, $group.Count)
    }

    $lines += ''
    $disabled = @($tasks | Where-Object { [string]$_.State -eq 'Disabled' } | Sort-Object -Property TaskPath, TaskName)
    $lines += "-- Disabled tasks: $($disabled.Count) --"
    foreach ($task in $disabled) {
        $lines += "$($task.TaskPath)$($task.TaskName)"
    }
    $lines
}

Add-Section -Title '9. Startup entries and pending reboot' -Collector {
    $lines = @()
    $runRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    )
    foreach ($root in $runRoots) {
        $lines += "-- $root --"
        if (-not (Test-Path -LiteralPath $root)) {
            $lines += '  (absent)'
            continue
        }
        $item = Get-ItemProperty -LiteralPath $root -ErrorAction SilentlyContinue
        $names = @($item.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | Sort-Object -Property Name)
        if ($names.Count -eq 0) {
            $lines += '  (empty)'
        }
        foreach ($value in $names) {
            $lines += ('  {0,-32} {1}' -f $value.Name, $value.Value)
        }
    }

    $lines += ''
    $lines += '-- Pending reboot --'
    $lines += ('{0,-52} {1}' -f 'CBS RebootPending', (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'))
    $lines += ('{0,-52} {1}' -f 'WindowsUpdate RebootRequired', (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'))
    $pendingRenames = Get-RegistryValueOrNull -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations'
    $lines += ('{0,-52} {1}' -f 'PendingFileRenameOperations', $(if ($pendingRenames) { "$(@($pendingRenames).Count) entry(s)" } else { 'none' }))
    $lines
}

Add-Section -Title '10. Event log errors and warnings since the install' -Collector {
    $since = if ($script:InstalledAt) {
        $script:InstalledAt.AddMinutes(-30)
    }
    else {
        (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    }
    $lines = @()
    $lines += "Window: since $since (critical, error and warning)"

    foreach ($logName in 'System', 'Application') {
        $lines += ''
        $lines += "-- $logName --"
        try {
            $events = @(Get-WinEvent -FilterHashtable @{ LogName = $logName; Level = 1, 2, 3; StartTime = $since } -ErrorAction Stop)
        }
        catch {
            $lines += "  (no matching events, or the log could not be read: $($_.Exception.Message))"
            continue
        }

        $lines += "  Total: $($events.Count)"
        $lines += '  By source and id:'
        foreach ($group in @($events | Group-Object -Property ProviderName, Id | Sort-Object -Property Count -Descending)) {
            $lines += ('    {0,-5} {1}' -f $group.Count, $group.Name)
        }
        $errorCount = @($events | Where-Object { $_.Level -le 2 }).Count
        if ($errorCount -gt 0) {
            Add-Summary "$logName log: $errorCount error or critical event(s) in the collection window beginning $since."
        }

        # One example per source and id, newest first. A machine that logs the same
        # event 150 times would otherwise fill the list with copies of it.
        $lines += ''
        $lines += "  Distinct events (up to $script:EventListCount), newest example of each:"
        $distinct = @($events |
                Group-Object -Property ProviderName, Id |
                ForEach-Object {
                    $newest = @($_.Group | Sort-Object -Property TimeCreated -Descending)[0]
                    [pscustomobject]@{ Count = $_.Count; Entry = $newest }
                } |
                Sort-Object -Property { $_.Entry.TimeCreated } -Descending |
                Select-Object -First $script:EventListCount)
        foreach ($item in $distinct) {
            $entry = $item.Entry
            $message = ([string]$entry.Message -replace '\s+', ' ')
            if ($message.Length -gt 300) {
                $message = $message.Substring(0, 300) + '...'
            }
            $lines += ('    {0:yyyy-MM-dd HH:mm:ss} {1,-9} x{2,-4} {3}/{4}: {5}' -f `
                    $entry.TimeCreated, $entry.LevelDisplayName, $item.Count, $entry.ProviderName, $entry.Id, $message)
        }
    }
    $lines
}

Add-Section -Title '11. Atlas logs' -Collector {
    $lines = @()
    $logRoot = Join-Path -Path $atlasModules -ChildPath 'Logs\install'
    if (Test-Path -LiteralPath $logRoot -PathType Container) {
        $logs = @(Get-ChildItem -LiteralPath $logRoot -File |
                Sort-Object -Property LastWriteTimeUtc -Descending | Select-Object -First 2)
        if ($logs.Count -eq 0) {
            $lines += "(no files under $logRoot)"
        }
        foreach ($log in $logs) {
            $lines += Get-FileTail -Path $log.FullName -Count $script:LogTailLines
            $lines += ''
        }
    }
    else {
        $lines += "(missing: $logRoot)"
    }

    $userLogRoot = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'AtlasOS\Logs'
    $userInstallLogRoot = Join-Path -Path $userLogRoot -ChildPath 'install'
    if (Test-Path -LiteralPath $userInstallLogRoot -PathType Container) {
        foreach ($log in @(Get-ChildItem -LiteralPath $userInstallLogRoot -File |
                    Sort-Object -Property LastWriteTimeUtc -Descending | Select-Object -First 2)) {
            $lines += Get-FileTail -Path $log.FullName -Count $script:LogTailLines
            $lines += ''
        }
    }
    if (Test-Path -LiteralPath $userLogRoot -PathType Container) {
        $userLog = @(Get-ChildItem -LiteralPath $userLogRoot -File -Filter '*-new-user-setup-*.log' |
                Sort-Object -Property LastWriteTimeUtc -Descending | Select-Object -First 1)
        foreach ($log in $userLog) {
            $lines += Get-FileTail -Path $log.FullName -Count $script:LogTailLines
        }
    }
    else {
        $lines += "(missing: $userLogRoot)"
    }
    $lines
}

if ($RcDiagnostics) {
    Add-Section -Title '12. RC diagnostics: Windows Search configuration' -Collector {
        $lines = @()
        $service = Get-Service -Name WSearch -ErrorAction Stop
        $lines += "WSearch status: $($service.Status)"
        $roots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows Search'
            'HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex'
            'HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost'
            'HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex'
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
            'HKLM:\SOFTWARE\Microsoft\Windows Search\CurrentPolicies'
            'HKLM:\SOFTWARE\AtlasOS\Services\PowerSaving'
            'HKLM:\SOFTWARE\AtlasOS\Search'
        )
        foreach ($root in $roots) {
            $lines += "-- $root --"
            if (-not (Test-Path -LiteralPath $root)) {
                $lines += '(missing)'
                continue
            }
            try {
                $keys = @(Get-Item -LiteralPath $root -ErrorAction Stop)
                # Root values include SetupCompletedSuccessfully. Limit the detailed
                # branch dumps to configuration rather than the whole Search store.
                if ($root -notin @($roots[0], $roots[1], $roots[6])) {
                    $children = @(Get-ChildItem -LiteralPath $root -Recurse -ErrorAction Stop | Select-Object -First 81)
                    if ($children.Count -gt 80) { $lines += '(branch truncated after 80 child keys)' }
                    $keys += @($children | Select-Object -First 80)
                }
                foreach ($key in $keys) {
                    try {
                        $lines += "[$($key.Name)]"
                        foreach ($name in @($key.GetValueNames() | Sort-Object)) {
                            $value = $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                            if ($value -is [byte[]]) {
                                $lines += ('  {0} (Binary) = {1} bytes' -f $name, $value.Length)
                                continue
                            }
                            $lines += ('  {0} ({1}) = {2}' -f $name, $key.GetValueKind($name), ($value | ConvertTo-Json -Compress -Depth 4))
                        }
                    }
                    finally { $key.Dispose() }
                }
            }
            catch { $lines += "(could not read branch: $($_.Exception.Message))" }
        }
        $lines
    }

    Add-Section -Title '13. RC diagnostics: PcaPatchDbTask' -Collector {
        $lines = @()
        $taskPath = '\Microsoft\Windows\Application Experience\'
        $taskName = 'PcaPatchDbTask'
        try {
            $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
            $info = Get-ScheduledTaskInfo -InputObject $task -ErrorAction Stop
            $lines += "State: $($task.State); Enabled: $($task.Settings.Enabled)"
            $lines += "Last run: $($info.LastRunTime); Result: $($info.LastTaskResult); Next run: $($info.NextRunTime)"
            $lines += Export-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
        }
        catch { $lines += "(task inspection failed: $($_.Exception.Message))" }
        $logName = 'Microsoft-Windows-TaskScheduler/Operational'
        try {
            $log = Get-WinEvent -ListLog $logName -ErrorAction Stop
            $lines += "Task Scheduler operational log enabled: $($log.IsEnabled)"
            # Collect only this task's recent history, retaining event data such as
            # update callers instead of the report's grouped/truncated messages.
            $xpath = "*[System[TimeCreated[timediff(@SystemTime) <= 86400000]]] and *[EventData[Data[@Name='TaskName']='${taskPath}${taskName}']]"
            $events = @(Get-WinEvent -LogName $logName -FilterXPath $xpath -MaxEvents $script:EventListCount -ErrorAction Stop)
            foreach ($taskEvent in $events) {
                $lines += $taskEvent.ToXml()
            }
        }
        catch { $lines += "(no matching task history, or history unavailable: $($_.Exception.Message))" }
        # Security events can include the client PID for task updates when auditing
        # was already enabled. Reading this log does not change audit policy.
        try {
            $xpath = "*[System[(EventID=4700 or EventID=4701 or EventID=4702) and TimeCreated[timediff(@SystemTime) <= 86400000]]] and *[EventData[Data[@Name='TaskName']='${taskPath}${taskName}']]"
            $events = @(Get-WinEvent -LogName Security -FilterXPath $xpath -MaxEvents $script:EventListCount -ErrorAction Stop)
            $lines += '-- Security task-change audit events --'
            foreach ($taskEvent in $events) { $lines += $taskEvent.ToXml() }
        }
        catch { $lines += "(no matching task audit events, or auditing unavailable: $($_.Exception.Message))" }
        $taskFile = Join-Path $windir 'System32\Tasks\Microsoft\Windows\Application Experience\PcaPatchDbTask'
        if (Test-Path -LiteralPath $taskFile -PathType Leaf) {
            $file = Get-Item -LiteralPath $taskFile -Force
            $lines += "Task file modified UTC: $($file.LastWriteTimeUtc.ToString('o'))"
        }
        $pca = Get-CimInstance -ClassName Win32_Service -Filter "Name='PcaSvc'" -ErrorAction Stop
        $lines += "PcaSvc: state=$($pca.State); start=$($pca.StartMode); PID=$($pca.ProcessId)"
        $disablePca = Get-RegistryValueOrNull -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' -Name DisablePCA
        $lines += "Machine DisablePCA policy: $disablePca"
        $lines
    }

    Add-Section -Title '14. RC diagnostics: OneDrive shell extension' -Collector {
        $lines = @()
        $root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Microsoft\OneDrive'
        $files = @()
        if (Test-Path -LiteralPath $root -PathType Container) {
            # The failure was in the version directory immediately below this root.
            foreach ($directory in @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction Stop)) {
                if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                $filePath = Join-Path $directory.FullName 'FileSyncShell64.dll'
                if (Test-Path -LiteralPath $filePath -PathType Leaf) {
                    $files += Get-Item -LiteralPath $filePath -Force -ErrorAction Stop
                }
            }
        }
        if ($files.Count -eq 0) { $lines += '(no FileSyncShell64.dll in the current user OneDrive version directories)' }
        foreach ($file in $files) {
            $lines += "File: $($file.FullName); Attributes: $($file.Attributes); Length: $($file.Length)"
            try {
                $acl = Get-Acl -LiteralPath $file.FullName -ErrorAction Stop
                $lines += "Owner: $($acl.Owner)"
                $lines += "SDDL: $($acl.Sddl)"
            }
            catch { $lines += "(ACL unavailable: $($_.Exception.Message))" }
        }
        $unreadable = 0
        $holders = 0
        foreach ($process in @(Get-Process -ErrorAction Stop)) {
            try {
                foreach ($module in @($process.Modules)) {
                    if ($module.ModuleName -ieq 'FileSyncShell64.dll') {
                        $holders++
                        $lines += "Loaded by $($process.ProcessName) PID=$($process.Id) session=$($process.SessionId): $($module.FileName)"
                    }
                }
            }
            catch { $unreadable++ }
            finally { $process.Dispose() }
        }
        $lines += "Loaded-module matches: $holders; processes whose modules could not be inspected: $unreadable"
        $lines += 'A loaded-module match can explain deletion denial. No match does not exclude an open file handle or an earlier lock.'
        $lines
    }

    Add-Section -Title '15. RC diagnostics: WebView2 runtime and Widgets' -Collector {
        $lines = @()
        # Microsoft documents pv under this client ID as Evergreen detection.
        # Edge Stable and Microsoft.Win32WebViewHost are not substitutes for it.
        $clientId = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
        foreach ($root in @(
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$clientId"
                "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$clientId"
                "HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$clientId"
            )) {
            $lines += "-- $root --"
            try {
                if (-not (Test-Path -LiteralPath $root)) { $lines += '(missing)'; continue }
                $key = Get-Item -LiteralPath $root -ErrorAction Stop
                try {
                    foreach ($name in @('pv', 'name', 'location')) {
                        $lines += ('  {0} = {1}' -f $name, $key.GetValue($name, '(missing)'))
                    }
                }
                finally { $key.Dispose() }
            }
            catch { $lines += "(registration read failed: $($_.Exception.Message))" }
        }
        $baseFolders = @(
            [Environment]::GetFolderPath('ProgramFilesX86')
            [Environment]::GetFolderPath('ProgramFiles')
            [Environment]::GetFolderPath('LocalApplicationData')
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        foreach ($baseFolder in $baseFolders) {
            $runtimeRoot = Join-Path $baseFolder 'Microsoft\EdgeWebView\Application'
            $lines += "-- $runtimeRoot --"
            try {
                if (-not (Test-Path -LiteralPath $runtimeRoot)) { $lines += '(missing)'; continue }
                $runtimeItem = Get-Item -LiteralPath $runtimeRoot -Force
                $lines += "Root attributes: $($runtimeItem.Attributes)"
                if ($runtimeItem.PSObject.Properties['Target']) { $lines += "Root target: $($runtimeItem.Target)" }
                $versions = @(Get-ChildItem -LiteralPath $runtimeRoot -Directory -ErrorAction Stop |
                        Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
                        Sort-Object Name -Descending | Select-Object -First 5)
                if ($versions.Count -eq 0) { $lines += '(no runtime version directories)' }
                foreach ($version in $versions) {
                    $lines += "Version directory: $($version.FullName); attributes: $($version.Attributes)"
                    if ($version.PSObject.Properties['Target']) { $lines += "Version target: $($version.Target)" }
                    foreach ($fileName in @('msedgewebview2.exe', 'msedge.dll', 'icudtl.dat')) {
                        $filePath = Join-Path $version.FullName $fileName
                        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                            $lines += "MISSING: $filePath"
                            continue
                        }
                        $file = Get-Item -LiteralPath $filePath -Force
                        $lines += "Present: $filePath; bytes=$($file.Length); version=$($file.VersionInfo.FileVersion)"
                        $lines += "ACL: $((Get-Acl -LiteralPath $filePath).Sddl)"
                    }
                }
            }
            catch { $lines += "(runtime inspection failed: $($_.Exception.Message))" }
        }
        try {
            $packages = @(Get-AppxPackage -AllUsers -ErrorAction Stop |
                    Where-Object { $_.Name -match 'WebExperience|WidgetsPlatformRuntime|StartExperiences' })
            if ($packages.Count -eq 0) { $lines += '(no Widgets packages registered)' }
            foreach ($package in $packages) {
                $lines += "Widget package: $($package.PackageFullName); status=$($package.Status)"
                $lines += "Install location: $($package.InstallLocation); partially staged=$($package.IsPartiallyStaged)"
                foreach ($registration in @($package.PackageUserInformation)) {
                    $lines += "User registration: $registration"
                }
                foreach ($dependency in @($package.Dependencies)) {
                    $lines += "Dependency: $($dependency.PackageFullName); status=$($dependency.Status)"
                }
            }
        }
        catch { $lines += "(widget package inspection failed: $($_.Exception.Message))" }
        foreach ($process in @(Get-Process -Name 'Widgets', 'WidgetService', 'msedgewebview2' -ErrorAction SilentlyContinue)) {
            try { $lines += "Process: $($process.ProcessName); PID=$($process.Id); session=$($process.SessionId); path=$($process.Path)" }
            catch { $lines += "(process inspection failed: $($_.Exception.Message))" }
            finally { $process.Dispose() }
        }
        foreach ($logPath in @(
                (Join-Path $windir 'Temp\msedge_installer.log')
                (Join-Path ([IO.Path]::GetTempPath()) 'msedge_installer.log')
                (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Microsoft\EdgeUpdate\Log\MicrosoftEdgeUpdate.log')
            ) | Select-Object -Unique) {
            $lines += Get-FileTail -Path $logPath -Count $script:LogTailLines
        }
        $lines += 'Registration and file presence do not prove the runtime can initialize. An install-time popup needs its timing or installer-log evidence to establish the cause.'
        $lines
    }

    Add-Section -Title '16. RC diagnostics: local Group Policy processing' -Collector {
        $lines = @()
        $since = if ($script:InstalledAt) {
            $script:InstalledAt.AddMinutes(-30)
        }
        else {
            (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        }
        $extension = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{7933F41E-56F8-41d6-A31C-4148A711EE93}'
        $lines += "-- Search policy extension: $extension --"
        if (Test-Path -LiteralPath $extension) {
            $key = Get-Item -LiteralPath $extension
            try {
                foreach ($name in $key.GetValueNames()) {
                    $lines += ('  {0} = {1}' -f $name, $key.GetValue($name))
                }
            }
            finally { $key.Dispose() }
        }
        else { $lines += '(missing)' }
        foreach ($relativePath in @('System32\GroupPolicy\Machine\Registry.pol', 'System32\GroupPolicy\gpt.ini')) {
            $policyPath = Join-Path $windir $relativePath
            if (Test-Path -LiteralPath $policyPath) {
                $file = Get-Item -LiteralPath $policyPath
                $lines += "Policy file: $policyPath; bytes=$($file.Length); modified=$($file.LastWriteTime.ToString('o'))"
                if ($file.Extension -eq '.ini') { $lines += Get-Content -LiteralPath $policyPath }
            }
            else { $lines += "Policy file missing: $policyPath" }
        }
        try {
            $events = @(Get-WinEvent -FilterHashtable @{
                    LogName = 'Microsoft-Windows-GroupPolicy/Operational'
                    StartTime = $since
                } -MaxEvents $script:EventListCount -ErrorAction Stop)
            foreach ($policyEvent in $events) {
                $lines += ('{0:o} ID={1}: {2}' -f $policyEvent.TimeCreated, $policyEvent.Id, $policyEvent.Message)
            }
        }
        catch { $lines += "(policy event collection unavailable: $($_.Exception.Message))" }
        $lines
    }

    Add-Section -Title '17. RC diagnostics: effective Search scope' -Collector {
        $manifest = Join-Path $atlasModules 'Scripts\Modules\Atlas.Search\Atlas.Search.psd1'
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
            return '(Atlas.Search module is missing)'
        }
        Import-Module -Name $manifest -ErrorAction Stop
        if (-not (Get-Command Get-AtlasIndexScopeState -ErrorAction SilentlyContinue)) {
            return '(this Atlas build does not expose the effective Search scope reader)'
        }
        $paths = @(
            (Join-Path $atlasDesktop '__atlas_scope_probe__.lnk')
            (Join-Path ([Environment]::GetFolderPath('CommonPrograms')) '__atlas_scope_probe__.lnk')
            (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Documents\__atlas_scope_probe__.txt')
            (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) '__atlas_scope_probe__.txt')
        )
        'Effective inclusion from Windows Search Crawl Scope Manager (probe files are not created):'
        Get-AtlasIndexScopeState -Path $paths | ForEach-Object {
            '  Included={0}: {1}' -f $_.Included, $_.Path
        }
        'Minimal expects AtlasDesktop/Start Menu included and both user paths excluded. Full expects Documents included and AppData excluded. Disabled Search may not answer.'
    }

    Add-Section -Title '18. RC diagnostics: BITS service failures' -Collector {
        $lines = @()
        $since = if ($script:InstalledAt) { $script:InstalledAt.AddMinutes(-30) }
        else { (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime }
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='BITS'" -ErrorAction Stop
        $lines += "BITS: state=$($service.State); start=$($service.StartMode); PID=$($service.ProcessId); exit=$($service.ExitCode); path=$($service.PathName)"
        $parameters = 'HKLM:\SYSTEM\CurrentControlSet\Services\BITS\Parameters'
        $dll = Get-RegistryValueOrNull -Path $parameters -Name ServiceDll
        $lines += "ServiceDll: $dll"
        if ($dll) {
            $dllPath = [Environment]::ExpandEnvironmentVariables([string]$dll)
            $lines += "ServiceDll exists: $([IO.File]::Exists($dllPath))"
        }
        foreach ($filter in @(
                @{ LogName = 'System'; ProviderName = 'Service Control Manager'; Id = @(7031, 7034); StartTime = $since }
                @{ LogName = 'Application'; Id = @(1000, 1001); StartTime = $since }
                @{ LogName = 'Microsoft-Windows-Bits-Client/Operational'; StartTime = $since }
            )) {
            $lines += "-- $($filter.LogName), since $($since.ToString('o')) --"
            try {
                if ($filter.LogName -like '*/Operational') {
                    $log = Get-WinEvent -ListLog $filter.LogName -ErrorAction Stop
                    $lines += "Log enabled: $($log.IsEnabled)"
                }
                foreach ($failureEvent in @(Get-WinEvent -FilterHashtable $filter -MaxEvents $script:EventListCount -ErrorAction Stop)) {
                    # Preserve timestamps, process IDs, faulting modules and event
                    # data for correlation with installer logs, without grouping.
                    $lines += $failureEvent.ToXml()
                    $lines += $failureEvent.Message
                }
            }
            catch { $lines += "(no matching events or log unavailable: $($_.Exception.Message))" }
        }
        $lines
    }
}

Add-Line ''
Add-Line ('=' * 78)
Add-Line 'End of report'

$header = New-Object System.Collections.Generic.List[string]
$header.Add('Atlas install report')
$header.Add(('Generated {0:yyyy-MM-dd HH:mm:ss} on {1}' -f (Get-Date), $env:COMPUTERNAME))
$header.Add('')
$header.Add('SUMMARY')
$header.Add(('-' * 78))
if ($script:Summary.Count -eq 0) {
    $header.Add('(nothing summarized)')
}
foreach ($line in $script:Summary) {
    $header.Add("- $line")
}

$directory = Split-Path -Path $OutputPath -Parent
if ($directory -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
    New-Item -Path $directory -ItemType Directory -Force | Out-Null
}
$allLines = @($header) + @($report)
[IO.File]::WriteAllLines($OutputPath, [string[]]$allLines, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host 'Atlas install report written to:'
Write-Host "  $OutputPath"
foreach ($line in $script:Summary) {
    Write-Host "  - $line"
}
