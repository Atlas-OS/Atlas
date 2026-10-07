# Moving Windows to a newer release through Windows Update, and putting back the
# Windows Update settings changed for it. Function definitions only: the update
# worker, the install checkpoint, the front door, the pin tweak and the toggle entry
# all dot-source this file, and none of them may inherit a side effect from it.
# Windows PowerShell 5.1.

# The journal lives under HKLM, which only administrators and SYSTEM can write, so a
# standard user cannot plant values for a restore to write back.
function Get-AtlasWindowsTransitionRoot { 'SOFTWARE\AtlasOS\WindowsTransition' }

function New-AtlasTransitionFailure([string]$Message, [string]$Reason, [hashtable]$Detail = @{}) {
    $failure = [Exception]::new($Message)
    if ($Reason) { $failure.Data['reason'] = $Reason }
    foreach ($key in $Detail.Keys) { $failure.Data[$key] = [string]$Detail[$key] }
    return $failure
}

# Steps go to the evidence log the caller chose (the worker's, or none), so a
# failed or refused move can be followed afterwards.
function Write-AtlasTransitionEvidence([string]$Text) {
    $path = Get-Variable -Name AtlasTransitionEvidencePath -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if (-not $path) { return }
    $line = '{0:yyyy-MM-ddTHH:mm:ssZ} {1}' -f [DateTime]::UtcNow, $Text
    try {
        $file = [IO.FileInfo]::new($path)
        # Keep one older log, so the history can't grow without limit.
        if ($file.Exists -and $file.Length -gt 1MB) {
            [IO.File]::Copy($path, "$path.old", $true)
            [IO.File]::WriteAllText($path, '')
        }
        [IO.File]::AppendAllText($path, $line + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    }
    catch {
        Write-Verbose "The transition evidence log could not be written: $_"
    }
}

# The only registry values, services and scheduled tasks a transition may change or
# restore. A journal entry for anything else is refused. Rules: nonzero (a DWORD
# other than 0 blocks), disabled (a service Start of 4 blocks), future (a pause end
# date still ahead blocks), paused (lifted only while the pause blocks), task (a
# disabled task, turned on only with the rest of Windows Update), pin (never lifted;
# retargeted by Set-AtlasFeatureUpdateTarget).
# Atlas 0.5.0's "Disable Windows Updates" disables wuauserv and the sih and sihboot
# tasks, which 25H2 and later no longer have: an absent task is recorded as absent
# and left alone. Its deferral launcher sets the Defer* policies. The policies, UsoSvc and the
# pause values are what Atlas 0.6's own toggles, or a user's tools, set.
function Get-AtlasWindowsTransitionItem {
    $policy = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $pause = 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
    $ux = 'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    $services = 'SYSTEM\CurrentControlSet\Services'
    # A leading comma keeps each row an array of its own.
    $rows = @(
        ,@('policy.DisableWindowsUpdateAccess', 'off', $policy, 'DisableWindowsUpdateAccess', 'DWord', $null, 'ToggleWindowsUpdates', 'A', 'nonzero')
        ,@('policy.DoNotConnectToWindowsUpdateInternetLocations', 'off', $policy, 'DoNotConnectToWindowsUpdateInternetLocations', 'DWord', $null, 'ToggleWindowsUpdates', 'B', 'nonzero')
        ,@('policy.AU.NoAutoUpdate', 'off', "$policy\AU", 'NoAutoUpdate', 'DWord', $null, 'ToggleWindowsUpdates', 'B', 'nonzero')
        ,@('service.wuauserv', 'off', "$services\wuauserv", 'Start', 'DWord', 3, 'ToggleWindowsUpdates', 'A', 'disabled')
        ,@('service.UsoSvc', 'off', "$services\UsoSvc", 'Start', 'DWord', 3, 'ToggleWindowsUpdates', 'A', 'disabled')
        ,@('task.sih', 'off', 'Microsoft\Windows\WindowsUpdate', 'sih', 'Task', 'Enabled', 'ToggleWindowsUpdates', 'A', 'task')
        ,@('task.sihboot', 'off', 'Microsoft\Windows\WindowsUpdate', 'sihboot', 'Task', 'Enabled', 'ToggleWindowsUpdates', 'A', 'task')
        ,@('policy.DeferQualityUpdates', 'delayed', $policy, 'DeferQualityUpdates', 'DWord', $null, $null, 'A', 'nonzero')
        ,@('policy.DeferQualityUpdatesPeriodInDays', 'delayed', $policy, 'DeferQualityUpdatesPeriodInDays', 'DWord', $null, $null, 'A', 'nonzero')
        ,@('pause.PausedFeatureStatus', 'paused', $pause, 'PausedFeatureStatus', 'DWord', 0, 'PauseUpdates', 'B', 'nonzero')
        ,@('pause.PausedQualityStatus', 'paused', $pause, 'PausedQualityStatus', 'DWord', 0, 'PauseUpdates', 'B', 'nonzero')
        ,@('pause.PauseFeatureUpdatesStartTime', 'paused', $ux, 'PauseFeatureUpdatesStartTime', 'String', $null, 'PauseUpdates', 'B', 'paused')
        ,@('pause.PauseFeatureUpdatesEndTime', 'paused', $ux, 'PauseFeatureUpdatesEndTime', 'String', $null, 'PauseUpdates', 'B', 'future')
        ,@('pause.PauseQualityUpdatesStartTime', 'paused', $ux, 'PauseQualityUpdatesStartTime', 'String', $null, 'PauseUpdates', 'B', 'paused')
        ,@('pause.PauseQualityUpdatesEndTime', 'paused', $ux, 'PauseQualityUpdatesEndTime', 'String', $null, 'PauseUpdates', 'B', 'future')
        ,@('pause.PauseUpdatesStartTime', 'paused', $ux, 'PauseUpdatesStartTime', 'String', $null, 'PauseUpdates', 'B', 'paused')
        ,@('pause.PauseUpdatesExpiryTime', 'paused', $ux, 'PauseUpdatesExpiryTime', 'String', $null, 'PauseUpdates', 'B', 'future')
        ,@('pause.FlightSettingsMaxPauseDays', 'paused', $ux, 'FlightSettingsMaxPauseDays', 'DWord', $null, 'PauseUpdates', 'B', 'paused')
        ,@('pin.TargetReleaseVersion', 'pin', $policy, 'TargetReleaseVersion', 'DWord,String', $null, $null, 'transition', 'pin')
        ,@('pin.ProductVersion', 'pin', $policy, 'ProductVersion', 'String', $null, $null, 'transition', 'pin')
        ,@('pin.TargetReleaseVersionInfo', 'pin', $policy, 'TargetReleaseVersionInfo', 'String', $null, $null, 'transition', 'pin')
    )
    foreach ($row in $rows) {
        [pscustomobject][ordered]@{
            Id = $row[0]; Group = $row[1]; Path = $row[2]; Name = $row[3]
            Kinds = @($row[4] -split ','); Lift = $row[5]; Owner = $row[6]; Tier = $row[7]; Rule = $row[8]
        }
    }
}

function ConvertTo-AtlasTransitionDword($Value) {
    # RegistryKey returns REG_DWORD as a signed Int32; keep it as the unsigned value.
    return [int64][BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$Value), 0)
}

# Registry and service access goes through these few functions, so tests can stand
# in for the machine and the code that decides never touches it directly.
function Get-AtlasTransitionValue([string]$Path, [string]$Name) {
    $absent = [pscustomobject]@{ Present = $false; Kind = $null; Data = $null }
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Path, $false)
    if ($null -eq $key) { return $absent }
    try {
        if (@($key.GetValueNames()) -notcontains $Name) { return $absent }
        $kind = [string]$key.GetValueKind($Name)
        $data = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($kind -eq 'DWord') { $data = ConvertTo-AtlasTransitionDword $data }
        return [pscustomobject]@{ Present = $true; Kind = $kind; Data = $data }
    }
    finally { $key.Dispose() }
}

function Set-AtlasTransitionValue([string]$Path, [string]$Name, [ValidateSet('DWord', 'String')][string]$Kind, $Data) {
    $key = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($Path)
    try {
        if ($Kind -eq 'DWord') {
            $value = [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$Data), 0)
            $key.SetValue($Name, $value, [Microsoft.Win32.RegistryValueKind]::DWord)
        }
        else { $key.SetValue($Name, [string]$Data, [Microsoft.Win32.RegistryValueKind]::String) }
    }
    finally { $key.Dispose() }
}

function Remove-AtlasTransitionValue([string]$Path, [string]$Name) {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Path, $true)
    if ($null -eq $key) { return }
    try { $key.DeleteValue($Name, $false) }
    finally { $key.Dispose() }
}

function Test-AtlasTransitionKey([string]$Path) {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Path, $false)
    if ($null -eq $key) { return $false }
    $key.Dispose()
    return $true
}

# sc.exe changes what the service manager holds as well as the registry, so the
# change applies without a restart.
function Set-AtlasTransitionServiceStart([string]$Name, [ValidateRange(2, 4)][int]$Start) {
    $mode = @{ 2 = 'auto'; 3 = 'demand'; 4 = 'disabled' }[$Start]
    $output = & ([IO.Path]::Combine([Environment]::SystemDirectory, 'sc.exe')) config $Name start= $mode 2>&1
    if ($LASTEXITCODE -ne 0) { throw "sc.exe could not set $Name to $mode ($LASTEXITCODE): $output" }
}

# A scheduled task as the journal records it: Enabled or Disabled.
function Get-AtlasTransitionTask([string]$Path, [string]$Name) {
    $task = Get-ScheduledTask -TaskPath "\$Path\" -TaskName $Name -ErrorAction SilentlyContinue
    if ($null -eq $task) { return [pscustomobject]@{ Present = $false; Kind = $null; Data = $null } }
    $state = if ([string]$task.State -eq 'Disabled') { 'Disabled' } else { 'Enabled' }
    return [pscustomobject]@{ Present = $true; Kind = 'Task'; Data = $state }
}

function Set-AtlasTransitionTask([string]$Path, [string]$Name, [ValidateSet('Enabled', 'Disabled')][string]$State) {
    if ($State -eq 'Enabled') { Enable-ScheduledTask -TaskPath "\$Path\" -TaskName $Name -ErrorAction Stop | Out-Null }
    else { Disable-ScheduledTask -TaskPath "\$Path\" -TaskName $Name -ErrorAction Stop | Out-Null }
}

function Start-AtlasTransitionService([string]$Name) {
    Start-Service -Name $Name -ErrorAction Stop
}

# Windows Update is never stopped while it installs something; turned off, it
# stays stopped from the next start.
function Stop-AtlasTransitionService([string]$Name) {
    if ($Name -eq 'wuauserv' -and (New-Object -ComObject Microsoft.Update.Installer).IsBusy) {
        throw 'Windows Update is installing something, so it stops at the next restart instead'
    }
    Stop-Service -Name $Name -Force -ErrorAction Stop
}

# Creates the journal key with an explicit descriptor: SYSTEM and Administrators
# full control, Users read. A key someone else owns is never trusted.
function New-AtlasTransitionJournalKey([string]$Path = (Get-AtlasWindowsTransitionRoot)) {
    $trusted = @('S-1-5-18', 'S-1-5-32-544')
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Path, $false)
    if ($null -ne $key) {
        try { $owner = $key.GetAccessControl().GetOwner([Security.Principal.SecurityIdentifier]).Value }
        finally { $key.Dispose() }
        if ($trusted -notcontains $owner) {
            throw (New-AtlasTransitionFailure "The Windows Update record key is owned by $owner, not by SYSTEM or Administrators." 'feature-journal')
        }
        return
    }
    $security = New-Object Security.AccessControl.RegistrySecurity
    $security.SetSecurityDescriptorSddlForm('O:BAG:BAD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)(A;CI;KR;;;BU)')
    $created = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($Path, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, $security)
    $created.Dispose()
}

# A toggle's recorded choice, which its replay acts on. A key whose state an
# older record left cleared holds no choice.
function Get-AtlasTransitionOwnerRecord([string]$Toggle) {
    if (-not $Toggle) { return $false }
    $state = Get-AtlasTransitionValue "SOFTWARE\AtlasOS\Services\$Toggle" 'state'
    return [bool]($state.Present -and $state.Kind -eq 'DWord')
}

function Test-AtlasTransitionString([string]$Text, [int]$Limit) {
    return $Text.Length -le $Limit -and $Text -notmatch '[\x00-\x1f\x7f]'
}

# Whether one recorded value may be written back for this item: a kind the table
# allows, and a well-formed value within its length limit.
function Test-AtlasTransitionItemValue($Item, $Entry) {
    if ($Entry.present -isnot [bool]) { return $false }
    if (-not $Entry.present) { return $true }
    $kind = [string]$Entry.kind
    if ($Item.Kinds -cnotcontains $kind) { return $false }
    if ($kind -eq 'Task') { return @('Enabled', 'Disabled') -ccontains [string]$Entry.data }
    if ($kind -eq 'DWord') {
        if ($Entry.data -isnot [int] -and $Entry.data -isnot [long] -and $Entry.data -isnot [int64]) { return $false }
        $number = [int64]$Entry.data
        if ($number -lt 0 -or $number -gt 4294967295) { return $false }
        if ($Item.Name -eq 'Start' -and $number -gt 4) { return $false }
        if ($Item.Id -eq 'pin.TargetReleaseVersion' -and $number -gt 1) { return $false }
        return $true
    }
    if ($Entry.data -isnot [string]) { return $false }
    switch ($Item.Id) {
        'pin.TargetReleaseVersion' { return $Entry.data -imatch '^\d{2}H\d$' }
        'pin.TargetReleaseVersionInfo' { return $Entry.data -imatch '^(\d{2}H\d)?$' }
        'pin.ProductVersion' { return Test-AtlasTransitionString $Entry.data 25 }
        default { return Test-AtlasTransitionString $Entry.data 64 }
    }
}

# Refuses the whole journal when anything in it is unexpected: nothing is then
# changed or restored on its strength.
function Test-AtlasWindowsTransitionJournal($Journal) {
    try { return (Test-AtlasWindowsTransitionJournalShape $Journal) }
    catch {
        # Under strict mode a missing property throws on its own; whatever the
        # check trips on, the record is refused as not valid.
        if ([string]$_.Exception.Data['reason'] -eq 'feature-journal') { throw }
        throw (New-AtlasTransitionFailure "The Windows Update record is not valid: $($_.Exception.Message)" 'feature-journal')
    }
}

function Test-AtlasWindowsTransitionJournalShape($Journal) {
    $fail = { param($Why) throw (New-AtlasTransitionFailure "The Windows Update record is not valid: $Why" 'feature-journal') }
    foreach ($name in @('schema', 'kind', 'phase', 'items', 'source', 'createdAt')) {
        if ($null -eq $Journal.PSObject.Properties[$name]) { & $fail "missing $name" }
    }
    if ($Journal.schema -ne 1) { & $fail "schema $($Journal.schema)" }
    if (@('transition', 'access') -cnotcontains $Journal.kind) { & $fail "kind $($Journal.kind)" }
    if (@('lifted', 'targeted', 'installed', 'on-target') -cnotcontains $Journal.phase) { & $fail "phase $($Journal.phase)" }
    if ($Journal.kind -eq 'transition') {
        $target = $Journal.PSObject.Properties['target']
        if ($null -eq $target -or $null -eq $target.Value -or [string]$target.Value.release -cnotmatch '^\d{2}H\d$' -or
            [string]$target.Value.kb -cnotmatch '^(\d{7}(,\d{7})*)?$' -or $target.Value.build -isnot [int]) { & $fail 'target' }
    }
    $offer = $Journal.PSObject.Properties['offer']
    if ($null -ne $offer -and $null -ne $offer.Value) {
        $value = $offer.Value
        if ([string]$value.kb -cnotmatch '^(\d{7}(,\d{7})*)?$' -or [string]$value.updateId -cnotmatch '^[0-9A-Za-z-]{1,64}$' -or
            $value.revision -isnot [int] -or -not (Test-AtlasTransitionString ([string]$value.title) 200)) { & $fail 'offer' }
    }
    $table = @{}
    foreach ($item in Get-AtlasWindowsTransitionItem) { $table[$item.Id] = $item }
    $seen = @{}
    foreach ($entry in @($Journal.items)) {
        $id = [string]$entry.id
        if (-not $table.ContainsKey($id) -or $seen.ContainsKey($id)) { & $fail "item $id" }
        $seen[$id] = $true
        if (-not (Test-AtlasTransitionItemValue $table[$id] $entry)) { & $fail "value of $id" }
        if ($entry.lifted -isnot [bool] -or $entry.ownerRecord -isnot [bool]) { & $fail "flags of $id" }
        if ($Journal.kind -eq 'access' -and $table[$id].Group -eq 'pin' -and $entry.lifted) { & $fail "pin in access record" }
    }
    $packages = $Journal.PSObject.Properties['atlasPackages']
    if ($null -ne $packages) {
        foreach ($package in @($packages.Value)) {
            if ([string]$package -cnotmatch '^Z-Atlas-[A-Za-z0-9-]+~[0-9a-f]{16}~[a-z0-9]+~[a-zA-Z-]*~[0-9.]+$') { & $fail 'package name' }
        }
    }
    $carry = $Journal.PSObject.Properties['carry']
    if ($null -ne $carry -and -not (Test-AtlasTransitionCarry $carry.Value)) { & $fail 'carry' }
    $rebuild = $Journal.PSObject.Properties['rebuild']
    if ($null -ne $rebuild -and $null -ne $rebuild.Value) {
        if ($rebuild.Value.rebuilt -isnot [bool]) { & $fail 'rebuild' }
        foreach ($signal in @($rebuild.Value.signals)) {
            if (@('windows-old', 'setup-folder', 'setup-log', 'packages-missing', 'atlas-files-missing') -cnotcontains [string]$signal) { & $fail 'rebuild signal' }
        }
    }
    return $true
}

# A copy of the record beside Atlas Manager's recovery files under Program Files,
# which only administrators write. A Windows that rebuilds itself keeps Program
# Files, but may not keep the registry key that holds the record.
function Get-AtlasTransitionCopyPath {
    return [IO.Path]::Combine([Environment]::GetFolderPath('ProgramFiles'), 'Atlas Setup Recovery\WindowsTransition\journal.json')
}

function Write-AtlasTransitionCopy([string]$Json) {
    $path = Get-AtlasTransitionCopyPath
    $directory = [IO.Path]::GetDirectoryName($path)
    if (-not [IO.Directory]::Exists($directory)) {
        $security = New-Object Security.AccessControl.DirectorySecurity
        $security.SetSecurityDescriptorSddlForm('O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;BU)')
        [void][IO.Directory]::CreateDirectory($directory, $security)
    }
    $temporary = "$path.tmp"
    [IO.File]::WriteAllText($temporary, $Json, [Text.UTF8Encoding]::new($false))
    if ([IO.File]::Exists($path)) { [IO.File]::Replace($temporary, $path, [NullString]::Value) }
    else { [IO.File]::Move($temporary, $path) }
}

# The copy's text, or $null without one. A copy someone other than SYSTEM,
# Administrators or TrustedInstaller owns is never trusted.
function Read-AtlasTransitionCopy {
    $path = Get-AtlasTransitionCopyPath
    if (-not [IO.File]::Exists($path)) { return $null }
    $file = [IO.FileInfo]::new($path)
    $owner = $file.GetAccessControl().GetOwner([Security.Principal.SecurityIdentifier]).Value
    if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $file.Length -gt 512KB -or
        @('S-1-5-18', 'S-1-5-32-544', 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464') -notcontains $owner) {
        throw (New-AtlasTransitionFailure "The copy of the Windows Update record at $path can't be trusted." 'feature-journal')
    }
    return [IO.File]::ReadAllText($path)
}

function Remove-AtlasTransitionCopy {
    $path = Get-AtlasTransitionCopyPath
    if ([IO.File]::Exists($path)) { [IO.File]::Delete($path) }
}

# $null when there is no journal; throws feature-journal for one that cannot be
# trusted, so no caller acts on it. Without the registry record, its copy stands in.
function Read-AtlasWindowsTransition([string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    $value = Get-AtlasTransitionValue $Root 'Journal'
    if ($value.Present) {
        if ($value.Kind -ne 'String') { throw (New-AtlasTransitionFailure 'The Windows Update record has an unexpected registry type.' 'feature-journal') }
        $text = [string]$value.Data
    }
    else {
        $text = Read-AtlasTransitionCopy
        if ($null -eq $text) { return $null }
        Write-AtlasTransitionEvidence 'the registry record is gone; read its copy under Program Files'
    }
    try { $journal = $text | ConvertFrom-Json -ErrorAction Stop }
    catch { throw (New-AtlasTransitionFailure "The Windows Update record is not readable: $($_.Exception.Message)" 'feature-journal') }
    [void](Test-AtlasWindowsTransitionJournal $journal)
    return $journal
}

function Write-AtlasWindowsTransition($Journal, [string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    [void](Test-AtlasWindowsTransitionJournal $Journal)
    $json = $Journal | ConvertTo-Json -Depth 8 -Compress
    New-AtlasTransitionJournalKey $Root
    Set-AtlasTransitionValue $Root 'Journal' 'String' $json
    # Only a rebuilt Windows needs the copy; failing to write it stops nothing.
    try { Write-AtlasTransitionCopy $json }
    catch { Write-AtlasTransitionEvidence "the copy of the record could not be written: $($_.Exception.Message)" }
}

# The copy goes first, so a copy left behind can never bring back a closed record.
function Remove-AtlasWindowsTransition([string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    Remove-AtlasTransitionCopy
    Remove-AtlasTransitionValue $Root 'Journal'
}

# Kind, target and phase of an open journal, without acting on it. Unreadable
# journals are reported as such, never as absent.
function Test-AtlasWindowsTransitionOpen([string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    try { $journal = Read-AtlasWindowsTransition $Root }
    catch { return [pscustomobject]@{ Readable = $false; Kind = $null; Phase = $null; TargetBuild = 0; Rebuild = $null; Error = $_.Exception.Message } }
    if ($null -eq $journal) { return $null }
    $build = if ($journal.kind -eq 'transition') { [int]$journal.target.build } else { 0 }
    # How Windows moved, as Atlas Manager decided once on the target build:
    # 'rebuilt', 'in-place', or 'components-lost' when Atlas's components were
    # gone without Setup rebuilding Windows. $null until it has checked. The
    # decision is read back, never made again: the install changes the packages.
    $rebuild = $null
    $recorded = $journal.PSObject.Properties['rebuild']
    if ($null -ne $recorded -and $null -ne $recorded.Value) {
        $lost = @(@($recorded.Value.signals) | Where-Object { $_ -in @('packages-missing', 'atlas-files-missing') }).Count -gt 0
        $rebuild = if ($recorded.Value.rebuilt) { 'rebuilt' } elseif ($lost) { 'components-lost' } else { 'in-place' }
    }
    return [pscustomobject]@{ Readable = $true; Kind = [string]$journal.kind; Phase = [string]$journal.phase; TargetBuild = $build; Rebuild = $rebuild; Error = $null }
}

function Add-AtlasTransitionHistory($Journal, [string]$Step, [string]$Detail = '') {
    $entries = @()
    if ($null -ne $Journal.PSObject.Properties['history']) { $entries = @($Journal.history) }
    $now = [DateTime]::UtcNow.ToString('o')
    $last = if ($entries.Count) { $entries[-1] } else { $null }
    # Looking again while Windows Update has yet to offer the release repeats the
    # same outcome; one entry counts the repeats, with the first and last times.
    if ($Step -ceq 'outcome' -and $null -ne $last -and [string]$last.event -ceq 'outcome' -and [string]$last.detail -ceq $Detail) {
        $count = if ($null -ne $last.PSObject.Properties['count']) { [int]$last.count } else { 1 }
        $last | Add-Member -NotePropertyName count -NotePropertyValue ($count + 1) -Force
        $last | Add-Member -NotePropertyName lastAt -NotePropertyValue $now -Force
    }
    else { $entries += [pscustomobject][ordered]@{ at = $now; event = $Step; detail = $Detail } }
    # The newest entries matter most; the record stays small.
    if ($entries.Count -gt 40) { $entries = $entries[($entries.Count - 40)..($entries.Count - 1)] }
    if ($null -eq $Journal.PSObject.Properties['history']) { $Journal | Add-Member -NotePropertyName history -NotePropertyValue @() }
    $Journal.history = @($entries)
    Write-AtlasTransitionEvidence "$Step $Detail"
}

function Get-AtlasTransitionLive($Item) {
    if ($Item.Kinds -ccontains 'Task') { return Get-AtlasTransitionTask $Item.Path $Item.Name }
    return Get-AtlasTransitionValue $Item.Path $Item.Name
}

function Test-AtlasTransitionFutureDate([string]$Text, [DateTime]$Now) {
    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParse($Text, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AdjustToUniversal -bor [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        return $false
    }
    return $parsed -gt $Now
}

# Which fixed-table items hold Windows Update back right now, read only. Each has
# its group (off, paused, delayed) and whether its owner toggle has a record.
function Get-AtlasWindowsUpdateBlocker([DateTime]$Now = [DateTime]::UtcNow) {
    $items = @(Get-AtlasWindowsTransitionItem | Where-Object Group -ne 'pin')
    $live = @{}
    foreach ($item in $items) { $live[$item.Id] = Get-AtlasTransitionLive $item }
    $blocking = {
        param($Item, $Value)
        if (-not $Value.Present) { return $false }
        switch ($Item.Rule) {
            'nonzero' { return $Value.Kind -eq 'DWord' -and [int64]$Value.Data -ne 0 }
            'disabled' { return $Value.Kind -eq 'DWord' -and [int64]$Value.Data -eq 4 }
            'future' { return $Value.Kind -eq 'String' -and (Test-AtlasTransitionFutureDate ([string]$Value.Data) $Now) }
            default { return $false }
        }
    }
    $pauseActive = $false
    foreach ($item in $items | Where-Object Group -eq 'paused') {
        if (& $blocking $item $live[$item.Id]) { $pauseActive = $true }
    }
    $offActive = $false
    foreach ($item in $items | Where-Object { $_.Group -eq 'off' -and $_.Rule -ne 'task' }) {
        if (& $blocking $item $live[$item.Id]) { $offActive = $true }
    }
    foreach ($item in $items) {
        $value = $live[$item.Id]
        # While updates are paused, every pause date goes with the pause, past
        # ones included; Windows reads them together. The update tasks come
        # back with the service that runs them.
        $blocks = if ($item.Rule -in @('paused', 'future')) { $pauseActive -and $value.Present }
        elseif ($item.Rule -eq 'task') { $offActive -and $value.Present -and $value.Data -eq 'Disabled' }
        else { & $blocking $item $value }
        if ($blocks) {
            [pscustomobject]@{
                Id = $item.Id; Group = $item.Group; Owner = $item.Owner
                OwnerRecord = Get-AtlasTransitionOwnerRecord $item.Owner; Live = $value
            }
        }
    }
}

function Get-AtlasTransitionFreeSpace {
    return [int64]([IO.DriveInfo]::new([IO.Path]::GetPathRoot([Environment]::SystemDirectory)).AvailableFreeSpace)
}

function Get-AtlasTransitionImageHealth {
    Import-Module -Name Dism -ErrorAction Stop
    return [string](Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop).ImageHealthState
}

# The end of the servicing log, where Windows writes what its last store check
# found. Read without locking out Windows, which keeps the file open.
function Get-AtlasTransitionCbsLogTail([int64]$Bytes = 16MB) {
    $path = [IO.Path]::Combine([Environment]::GetFolderPath('Windows'), 'Logs\CBS\CBS.log')
    if (-not [IO.File]::Exists($path)) { return @() }
    $stream = [IO.FileStream]::new($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]'ReadWrite, Delete')
    try {
        $start = [Math]::Max(0, $stream.Length - $Bytes)
        [void]$stream.Seek($start, [IO.SeekOrigin]::Begin)
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8)
        $text = $reader.ReadToEnd()
    }
    finally { $stream.Dispose() }
    return ($text -split "`r?`n")
}

# The newest store check's findings in servicing log lines: the corrupt items
# it lists and its counts by kind. $null when the lines hold no complete check.
function Get-AtlasTransitionStoreFinding([string[]]$Lines) {
    $start = -1
    for ($i = $Lines.Count - 1; $i -ge 0; $i--) {
        if ($Lines[$i] -match 'Checking System Update Readiness\.') { $start = $i; break }
    }
    if ($start -lt 0) { return $null }
    $items = @(); $counts = [ordered]@{}; $total = $null
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line -match 'Total Operation Time') { break }
        if ($line -match '\(p\)\t([^\t]+)\t\([a-z]+\)\t+(\S.*?)\s*$') {
            $items += [pscustomobject]@{ Kind = $Matches[1].Trim(); Path = $Matches[2] }
        }
        elseif ($line -match 'Total Detected Corruption:\s*(\d+)') { $total = [int]$Matches[1] }
        elseif ($null -ne $total -and $line -match '\t((?:CBS|CSI) [A-Za-z ]+(?:Corruption|Corrupt)):\s*(\d+)') {
            $counts[$Matches[1]] = [int]$Matches[2]
        }
    }
    if ($null -eq $total) { return $null }
    return [pscustomobject]@{ Total = $total; Counts = $counts; Items = @($items) }
}

# Whether a store check's findings are the pattern Atlas's NoTelemetry package is
# known to leave: a component store cleanup rebuilds the replaced Application
# Experience (AppInv) 10.0.26100.1591 component from its baseline without
# aeinvext.dll and Microsoft.Management.Deployment.winmd. A label for the log
# only: a repair moves the findings to other 1591-baseline files, so no decision
# rests on it.
function Test-AtlasTransitionKnownStoreDamage($Finding, [string[]]$AtlasPackages) {
    if ($null -eq $Finding -or $Finding.Total -lt 1) { return $false }
    if (@($AtlasPackages | Where-Object { $_ -like 'Z-Atlas-NoTelemetry-Package*' }).Count -eq 0) { return $false }
    $known = '^[a-z0-9]+_microsoft-windows-a\.\.n-experience-appinv_31bf3856ad364e35_10\.0\.26100\.1591_[^\\]+\\(aeinvext\.dll|Microsoft\.Management\.Deployment\.winmd)$'
    if (@($Finding.Items).Count -ne $Finding.Total) { return $false }
    foreach ($item in @($Finding.Items)) {
        if ($item.Kind -ne 'CSI Payload Corrupt' -or $item.Path -notmatch $known) { return $false }
    }
    foreach ($kind in @($Finding.Counts.Keys)) {
        $expected = if ($kind -eq 'CSI Payload Corruption') { $Finding.Total } else { 0 }
        if ($Finding.Counts[$kind] -ne $expected) { return $false }
    }
    return $Finding.Counts.Contains('CSI Payload Corruption')
}

# An organisation's update server owns this PC's updates; Atlas does not
# override where updates come from.
function Test-AtlasWindowsUpdateManaged {
    $server = Get-AtlasTransitionValue 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer'
    Write-AtlasTransitionEvidence "read AU\UseWUServer: $(Format-AtlasTransitionValue $server)"
    if ($server.Present -and $server.Kind -eq 'DWord' -and [int64]$server.Data -eq 1) {
        throw (New-AtlasTransitionFailure 'This PC gets updates from an update server its organisation runs.' 'feature-managed')
    }
}

# What Windows Update needs to work at all and Atlas will not change itself.
# Read only; the first problem ends it, before anything changes.
function Test-AtlasWindowsTransitionPreflight([int64]$MinimumFreeBytes = 6GB) {
    Test-AtlasWindowsUpdateManaged
    foreach ($service in @('BITS', 'CryptSvc', 'TrustedInstaller')) {
        $start = Get-AtlasTransitionValue "SYSTEM\CurrentControlSet\Services\$service" 'Start'
        Write-AtlasTransitionEvidence "read $service Start: $(if ($start.Present) { $start.Data } else { 'absent' })"
        if (-not $start.Present -or ($start.Kind -eq 'DWord' -and [int64]$start.Data -eq 4)) {
            throw (New-AtlasTransitionFailure "The $service service is turned off or missing." 'feature-blocked' @{ setting = $service })
        }
    }
    $free = Get-AtlasTransitionFreeSpace
    $drive = ([IO.Path]::GetPathRoot([Environment]::SystemDirectory)).TrimEnd('\')
    Write-AtlasTransitionEvidence "read free space on ${drive}: $free bytes (needs $MinimumFreeBytes)"
    if ($free -lt $MinimumFreeBytes) {
        throw (New-AtlasTransitionFailure "Drive $drive has $free bytes free; Windows needs $MinimumFreeBytes." 'feature-disk-space' @{
                drive = $drive; freeGb = [Math]::Floor($free / 1GB); neededGb = [Math]::Ceiling($MinimumFreeBytes / 1GB) })
    }
    try {
        $health = Get-AtlasTransitionImageHealth
        Write-AtlasTransitionEvidence "read component store health: $health"
    }
    catch {
        # A check that cannot run is not evidence of damage, and the build after
        # the restart decides whether Windows moved.
        Write-AtlasTransitionEvidence ("component store health could not be read (0x{0:X8}): {1}; going on" -f $_.Exception.HResult, $_.Exception.Message)
        $health = 'Unknown'
    }
    if ($health -eq 'Repairable') {
        # Atlas PCs can read as repairable from the packages' supersedence, which
        # a repair doesn't fully clear, and Windows Update installs on such a
        # store. So it is recorded and the move goes on; whether Windows moved
        # is decided after the restart. The servicing log says what Windows's
        # last full check found.
        $finding = Get-AtlasTransitionStoreFinding @(Get-AtlasTransitionCbsLogTail)
        $listed = if ($null -ne $finding) { (@($finding.Items | ForEach-Object { "$($_.Kind) $($_.Path)" }) -join '; ') } else { 'no store check in the servicing log' }
        $pattern = if (Test-AtlasTransitionKnownStoreDamage $finding @(Get-AtlasInstalledAtlasPackage)) { 'the known Atlas package pattern' } else { 'other' }
        Write-AtlasTransitionEvidence "component store is repairable ($pattern): $listed; going on"
    }
    elseif ($health -eq 'NonRepairable') {
        throw (New-AtlasTransitionFailure "Windows reports that its component store is $health." 'feature-servicing')
    }
}

# Installed Atlas CBS packages, from the servicing registry (CurrentState 112 is
# Installed). Read only and fast enough to run on every resume.
function Get-AtlasInstalledAtlasPackage {
    $root = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($root, $false)
    if ($null -eq $key) { return }
    try {
        foreach ($name in @($key.GetSubKeyNames() | Where-Object { $_ -like 'Z-Atlas-*' } | Sort-Object)) {
            $state = Get-AtlasTransitionValue "$root\$name" 'CurrentState'
            if ($state.Present -and $state.Kind -eq 'DWord' -and [int64]$state.Data -eq 112) { $name }
        }
    }
    finally { $key.Dispose() }
}

# What this PC's Atlas install was, read before Windows moves: if Windows rebuilds
# itself instead of switching releases, the Atlas install afterwards needs it to
# put Atlas back with the same choices, even when the registry it came from is gone.
# Read only. Each source is its own function so tests can stand in for the machine.
function Get-AtlasTransitionStateDocument {
    $path = [IO.Path]::Combine([Environment]::GetFolderPath('Windows'), 'AtlasOS\state.json')
    if (-not [IO.File]::Exists($path)) { return $null }
    try { return [IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop }
    catch {
        Write-AtlasTransitionEvidence "the Atlas state document could not be read: $($_.Exception.Message)"
        return $null
    }
}

function Get-AtlasTransitionLegacyVersion {
    foreach ($marker in @(
            @('SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation', 'Model'),
            @('SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'RegisteredOrganization'))) {
        $value = Get-AtlasTransitionValue $marker[0] $marker[1]
        if ($value.Present -and [string]$value.Data -match '^Atlas Playbook v?(\d+\.\d+\.\d+)$') { $Matches[1] }
    }
}

function Get-AtlasTransitionToggleRecord {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\AtlasOS\Services', $false)
    if ($null -eq $key) { return }
    try {
        foreach ($name in @($key.GetSubKeyNames())) {
            $state = Get-AtlasTransitionValue "SOFTWARE\AtlasOS\Services\$name" 'state'
            if (-not $state.Present -or $state.Kind -ne 'DWord') { continue }
            $value = [int64]$state.Data
            if ($name -eq 'AutomaticUpdates' -and $value -eq 1) {
                $launcher = Get-AtlasTransitionValue "SOFTWARE\AtlasOS\Services\$name" 'path'
                if ($launcher.Present -and $launcher.Kind -eq 'String') {
                    $file = ([string]$launcher.Data -split '[\\/]')[-1]
                    if ($file -in @('Add Idle Toggle in Desktop Context Menu.cmd', 'Remove Idle Toggle in Desktop Context Menu (default).cmd')) {
                        $value = Get-AtlasTransitionAutomaticUpdatesPolicyState
                        if ($null -eq $value) { continue }
                    }
                }
            }
            [pscustomobject][ordered]@{ name = $name; state = $value }
        }
    }
    finally { $key.Dispose() }
}

function Get-AtlasTransitionAutomaticUpdatesPolicyState {
    $policy = Get-AtlasTransitionValue 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions'
    if (-not $policy.Present) { return 1 }
    if ($policy.Kind -ne 'DWord') { return $null }
    if ([int64]$policy.Data -eq 2) { return 0 }
    if ([int64]$policy.Data -in @(3, 4, 5)) { return 1 }
    return $null
}

function Get-AtlasTransitionAppxName {
    try { return @(Get-AppxPackage -AllUsers -ErrorAction Stop | ForEach-Object { [string]$_.PackageFamilyName } | Sort-Object -Unique) }
    catch {
        Write-AtlasTransitionEvidence "installed apps could not be listed: $($_.Exception.Message)"
        return @()
    }
}

function Test-AtlasTransitionPath([string]$Path) { return [IO.File]::Exists($Path) -or [IO.Directory]::Exists($Path) }

$script:AtlasProfileList = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

# The accounts of the people who use this PC, from Windows's profile list; the
# system's own service profiles are left out.
function Get-AtlasTransitionProfileSid {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($script:AtlasProfileList, $false)
    if ($null -eq $key) { return }
    try { @($key.GetSubKeyNames() | Where-Object { $_ -like 'S-1-5-21-*' }) }
    finally { $key.Dispose() }
}

function Get-AtlasTransitionProfilePath {
    foreach ($sid in @(Get-AtlasTransitionProfileSid)) {
        $path = Get-AtlasTransitionValue "$script:AtlasProfileList\$sid" 'ProfileImagePath'
        if ($path.Present -and $path.Kind -in @('String', 'ExpandString') -and [string]$path.Data) {
            [Environment]::ExpandEnvironmentVariables([string]$path.Data)
        }
    }
}

# OneDrive installed for the whole PC or by any account on it, not only the one
# running Atlas: a Rebase then leaves it, so nobody's OneDrive is uninstalled
# because Windows moved. Only whether the program file exists is read.
function Test-AtlasTransitionOneDrive {
    $paths = @(
        [IO.Path]::Combine([Environment]::GetFolderPath('ProgramFiles'), 'Microsoft OneDrive\OneDrive.exe'),
        [IO.Path]::Combine([Environment]::GetFolderPath('LocalApplicationData'), 'Microsoft\OneDrive\OneDrive.exe')
    ) + @(Get-AtlasTransitionProfilePath | ForEach-Object { [IO.Path]::Combine($_, 'AppData\Local\Microsoft\OneDrive\OneDrive.exe') })
    foreach ($path in $paths) {
        if (Test-AtlasTransitionPath $path) { return $true }
    }
    return $false
}

function Get-AtlasTransitionMachineFact {
    $windows = [Environment]::GetFolderPath('Windows')
    $x86 = [Environment]::GetFolderPath('ProgramFilesX86')
    $browser = Get-AtlasTransitionValue 'SOFTWARE\AtlasOS\SetupOptions' 'browser'
    return [pscustomobject]@{
        State = Get-AtlasTransitionStateDocument
        LegacyVersions = @(Get-AtlasTransitionLegacyVersion | Sort-Object -Unique)
        Toggles = @(Get-AtlasTransitionToggleRecord)
        Browser = if ($browser.Present -and $browser.Kind -eq 'String') { [string]$browser.Data } else { $null }
        AtlasModules = Test-AtlasTransitionPath ([IO.Path]::Combine($windows, 'AtlasModules\Scripts'))
        Edge = Test-AtlasTransitionPath ([IO.Path]::Combine($x86, 'Microsoft\Edge\Application\msedge.exe'))
        OneDrive = Test-AtlasTransitionOneDrive
        Defender = Test-AtlasTransitionKey 'SYSTEM\CurrentControlSet\Services\WinDefend'
        Appx = @(Get-AtlasTransitionAppxName)
        # The Atlas Toolbox installer's own record.
        Toolbox = Test-AtlasTransitionKey 'SOFTWARE\AtlasOS\Toolbox'
        CoreIsolationOff = Test-AtlasTransitionCoreIsolationOff
        Browsers = @(Get-AtlasTransitionBrowser)
    }
}

# What Atlas 0.5.0's "Disable Core Isolation" (ConfigVBS.ps1 -DisableAllVBS)
# leaves under Control\DeviceGuard, not the policy path: virtualization-based
# security set off, and memory integrity off where Windows had its key. Without
# that key the script's write of it failed and only the first value was set, so
# memory integrity may be absent, but not on. Turning memory integrity off in
# Windows Security alone doesn't set the first.
function Test-AtlasTransitionCoreIsolationOff {
    $vbs = Get-AtlasTransitionValue 'SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity'
    $hvci = Get-AtlasTransitionValue 'SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled'
    $vbsOff = $vbs.Present -and $vbs.Kind -eq 'DWord' -and [int64]$vbs.Data -eq 0
    $hvciOn = $hvci.Present -and $hvci.Kind -eq 'DWord' -and [int64]$hvci.Data -ne 0
    return $vbsOff -and -not $hvciOn
}

# The browsers Atlas offers that are installed, by option name.
function Get-AtlasTransitionBrowser {
    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    foreach ($browser in @(
            @('browser-brave', 'BraveSoftware\Brave-Browser\Application\brave.exe'),
            @('browser-firefox', 'Mozilla Firefox\firefox.exe'),
            @('browser-chrome', 'Google\Chrome\Application\chrome.exe'),
            @('browser-librewolf', 'LibreWolf\librewolf.exe'))) {
        if (Test-AtlasTransitionPath ([IO.Path]::Combine($programFiles, $browser[1]))) { $browser[0] }
    }
}

# The install options a recorded or observed choice gives, for an Atlas without a
# state document (0.5.x and 0.4.1): the Defender package, the toggle records the
# choices left, and what was removed. A choice nothing shows is left out, never
# guessed; Atlas Manager asks for it again.
function Get-AtlasTransitionObservedOption($Facts, [string[]]$AtlasPackages) {
    $records = @{}
    foreach ($record in @($Facts.Toggles)) { $records[[string]$record.name] = [int64]$record.state }
    if (@($AtlasPackages | Where-Object { $_ -like 'Z-Atlas-NoDefender-Package*' }).Count -gt 0) { 'defender-disable' }
    elseif (@($AtlasPackages).Count -gt 0) { 'defender-enable' }
    if ($records.ContainsKey('Mitigations')) { if ($records['Mitigations'] -eq 0) { 'mitigations-disable' } else { 'mitigations-default' } }
    if ($records.ContainsKey('AutomaticUpdates')) { if ($records['AutomaticUpdates'] -eq 0) { 'auto-updates-disable' } else { 'auto-updates-default' } }
    if ($records.ContainsKey('Hibernation') -and $records['Hibernation'] -eq 0) { 'disable-hibernation' }
    if ($records.ContainsKey('PowerSaving') -and $records['PowerSaving'] -eq 0) { 'disable-power-saving' }
    if (-not $Facts.Edge) { 'uninstall-edge' }
    if (@($Facts.Appx).Count -gt 0 -and @($Facts.Appx | Where-Object { $_ -like 'Microsoft.ScreenSketch_*' }).Count -eq 0) { 'remove-snipping-tool' }
    $fact = { param($Name) $property = $Facts.PSObject.Properties[$Name]; if ($null -ne $property) { $property.Value } }
    if (& $fact 'CoreIsolationOff') { 'disable-core-isolation' }
    if (& $fact 'Toolbox') { 'install-toolbox' }
    # The taskbar pin record names the browser chosen. Atlas 0.5.0 records
    # LibreWolf as an empty name, so then the one browser installed decides.
    $browser = switch ([string]$Facts.Browser) {
        'Brave' { 'browser-brave' }
        'Firefox' { 'browser-firefox' }
        'Google Chrome' { 'browser-chrome' }
        'LibreWolf' { 'browser-librewolf' }
        default {
            $installed = @(& $fact 'Browsers')
            if ($null -ne $Facts.Browser -and $installed.Count -eq 1) { $installed[0] }
        }
    }
    if ($browser) { 'install-another-browser'; $browser }
}

function ConvertTo-AtlasTransitionCarry($Facts, [string[]]$AtlasPackages = @()) {
    $state = $Facts.State
    $version = $null
    $options = @()
    $source = 'none'
    if ($null -ne $state -and $null -ne $state.PSObject.Properties['installedVersion'] -and [string]$state.installedVersion -match '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$') {
        $version = [string]$state.installedVersion
        if ($null -ne $state.PSObject.Properties['options']) { $options = @($state.options | ForEach-Object { [string]$_ } | Where-Object { $_ -match '^[a-z0-9-]{1,64}$' }) }
        $source = 'recorded'
    }
    elseif (@($Facts.LegacyVersions).Count -eq 1) {
        $version = [string]@($Facts.LegacyVersions)[0]
        $options = @(Get-AtlasTransitionObservedOption $Facts $AtlasPackages)
        $source = 'observed'
    }
    return [pscustomobject][ordered]@{
        atlasVersion = $version; options = @($options); optionSource = $source
        toggles = @($Facts.Toggles | Where-Object { [string]$_.name -match '^[A-Za-z0-9]{1,64}$' -and [int64]$_.state -ge 0 -and [int64]$_.state -le 1000 } | Select-Object -First 400)
        browser = if ($Facts.Browser -and (Test-AtlasTransitionString $Facts.Browser 32)) { $Facts.Browser } else { $null }
        atlasModules = [bool]$Facts.AtlasModules; edge = [bool]$Facts.Edge; oneDrive = [bool]$Facts.OneDrive; defender = [bool]$Facts.Defender
        appx = @($Facts.Appx | Where-Object { $_ -match '^[A-Za-z0-9._-]{1,128}$' } | Select-Object -First 800)
    }
}

function Get-AtlasTransitionCarry([string[]]$AtlasPackages = @()) {
    $carry = ConvertTo-AtlasTransitionCarry (Get-AtlasTransitionMachineFact) $AtlasPackages
    Write-AtlasTransitionEvidence "recorded the Atlas install: version $(if ($carry.atlasVersion) { $carry.atlasVersion } else { 'none' }), options ($($carry.optionSource)) $($carry.options -join ','), $(@($carry.toggles).Count) toggle records, $(@($carry.appx).Count) apps, Atlas files $($carry.atlasModules), Edge $($carry.edge), OneDrive $($carry.oneDrive), Defender $($carry.defender)"
    return $carry
}

function Test-AtlasTransitionCarry($Carry) {
    if ($null -eq $Carry) { return $true }
    if ($null -ne $Carry.atlasVersion -and [string]$Carry.atlasVersion -cnotmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$') { return $false }
    if (@('recorded', 'observed', 'none') -cnotcontains [string]$Carry.optionSource) { return $false }
    foreach ($option in @($Carry.options)) { if ([string]$option -cnotmatch '^[a-z0-9-]{1,64}$') { return $false } }
    foreach ($record in @($Carry.toggles)) {
        if ([string]$record.name -cnotmatch '^[A-Za-z0-9]{1,64}$' -or ($record.state -isnot [int] -and $record.state -isnot [long]) -or [int64]$record.state -lt 0 -or [int64]$record.state -gt 1000) { return $false }
    }
    if (@($Carry.toggles).Count -gt 400 -or @($Carry.appx).Count -gt 800) { return $false }
    foreach ($name in @($Carry.appx)) { if ([string]$name -cnotmatch '^[A-Za-z0-9._-]{1,128}$') { return $false } }
    if ($null -ne $Carry.browser -and -not (Test-AtlasTransitionString ([string]$Carry.browser) 32)) { return $false }
    foreach ($flag in @('atlasModules', 'edge', 'oneDrive', 'defender')) { if ($Carry.$flag -isnot [bool]) { return $false } }
    return $true
}

# Whether Windows rebuilt itself instead of switching releases, from what a rebuild
# leaves: a populated Windows.old, Setup's working folder or a Setup log written
# during the move, and Atlas's components gone. A cumulative update can leave an
# empty Windows.old, so no single sign decides.
function Get-AtlasTransitionRebuildFact([DateTime]$Since, [string]$WindowsPath = [Environment]::GetFolderPath('Windows')) {
    # Windows.old and Setup's working folder sit beside the Windows folder.
    $drive = [IO.Path]::GetDirectoryName($WindowsPath.TrimEnd('\'))
    $old = [IO.Path]::Combine($drive, 'Windows.old\Windows')
    $panther = [IO.Path]::Combine($WindowsPath, 'Panther\setupact.log')
    $oldFilled = $false
    if ([IO.Directory]::Exists($old)) {
        try { $oldFilled = @([IO.Directory]::EnumerateFileSystemEntries($old) | Select-Object -First 1).Count -gt 0 }
        catch { $oldFilled = $true }
    }
    return [pscustomobject]@{
        WindowsOld = $oldFilled
        SetupFolder = [IO.Directory]::Exists([IO.Path]::Combine($drive, '$WINDOWS.~BT'))
        PantherWritten = [IO.File]::Exists($panther) -and [IO.File]::GetLastWriteTimeUtc($panther) -ge $Since
        AtlasModules = [IO.Directory]::Exists([IO.Path]::Combine($WindowsPath, 'AtlasModules\Scripts'))
    }
}

function Resolve-AtlasTransitionRebuild($Journal, $Facts, [string[]]$PresentPackages) {
    $carry = if ($null -ne $Journal.PSObject.Properties['carry']) { $Journal.carry } else { $null }
    $missing = @(@($Journal.atlasPackages) | Where-Object { $PresentPackages -notcontains $_ })
    $modulesLost = $null -ne $carry -and [bool]$carry.atlasModules -and -not $Facts.AtlasModules
    $signals = @()
    if ($Facts.WindowsOld) { $signals += 'windows-old' }
    if ($Facts.SetupFolder) { $signals += 'setup-folder' }
    if ($Facts.PantherWritten) { $signals += 'setup-log' }
    if ($missing.Count -gt 0) { $signals += 'packages-missing' }
    if ($modulesLost) { $signals += 'atlas-files-missing' }
    $setup = $Facts.WindowsOld -and ($Facts.SetupFolder -or $Facts.PantherWritten)
    $lost = $missing.Count -gt 0 -or $modulesLost
    return [pscustomobject][ordered]@{
        rebuilt = $setup -and $lost; setup = [bool]$setup; lost = [bool]$lost
        signals = @($signals); missing = @($missing); checkedAt = [DateTime]::UtcNow.ToString('o')
    }
}

# A service backup from the Windows that Setup replaced, back beside Atlas's new
# files: it describes the services before Atlas first changed them, which the
# rebuilt Windows can no longer show. Only a plain file of a service backup's size
# is copied, and an existing backup is kept.
function Copy-AtlasRebaseServiceBackup([string]$Name, [string]$WindowsPath = [Environment]::GetFolderPath('Windows')) {
    $destination = [IO.Path]::Combine($WindowsPath, 'AtlasModules\Other', $Name)
    if ([IO.File]::Exists($destination)) { return "kept the existing ${Name}" }
    $source = [IO.Path]::Combine([IO.Path]::GetDirectoryName($WindowsPath.TrimEnd('\')), 'Windows.old\Windows\AtlasModules\Other', $Name)
    if (-not [IO.File]::Exists($source)) { return "no ${Name} to bring back" }
    $file = [IO.FileInfo]::new($source)
    if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return "left ${Name}: it is a link" }
    for ($directory = $file.Directory; $null -ne $directory -and $null -ne $directory.Parent; $directory = $directory.Parent) {
        if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return "left ${Name}: '$($directory.FullName)' is a link" }
    }
    if ($file.Length -gt 32MB) { return "left ${Name}: larger than a service backup" }
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
    [IO.File]::Copy($source, $destination, $false)
    return "brought back ${Name} from Windows.old"
}

# The recorded choices, back from the record of the move when the rebuilt Windows
# lost the registry that held them. Choices Windows kept are never replaced.
# Get-AtlasToggleStateRecords and Set-AtlasToggleState come from Atlas.Toggles.
function Restore-AtlasRebaseChoice($Carry) {
    $records = Get-AtlasToggleStateRecords
    if ($records.Count -gt 0) { "kept the $($records.Count) recorded choices Windows kept" }
    else {
        $restored = 0
        foreach ($record in @($Carry.toggles)) {
            Set-AtlasToggleState -Name ([string]$record.name) -State ([int]$record.state)
            $restored++
        }
        "brought back $restored recorded choices from the record of the move"
    }
    if ($Carry.browser) {
        $browser = Get-AtlasTransitionValue 'SOFTWARE\AtlasOS\SetupOptions' 'browser'
        if (-not $browser.Present) {
            Set-AtlasTransitionValue 'SOFTWARE\AtlasOS\SetupOptions' 'browser' 'String' ([string]$Carry.browser)
            "brought back the recorded browser choice '$($Carry.browser)'"
        }
    }
}

# The app removals a Rebase repeats: only families nothing had installed before
# Windows moved. One that was there was kept or put back by the user, and removing
# it would delete its data.
function Select-AtlasRebaseAppxRemoval($Definition, [AllowEmptyCollection()][string[]]$Before) {
    # Windows always has apps, so an empty list means they couldn't be listed
    # when the move was recorded: no removal is known to be safe, so none runs.
    $unknown = @($Before).Count -eq 0
    foreach ($item in @($Definition)) {
        $pattern = [string]$item.Name
        $kept = $unknown -or @($Before | Where-Object { $_ -like $pattern -or ($_ -split '_')[0] -like $pattern }).Count -gt 0
        [pscustomobject]@{ Definition = $item; Kept = $kept }
    }
}

# The Atlas install's view of an open move after which Windows rebuilt itself:
# the version and choices recorded before it. $null when there is none.
function Get-AtlasWindowsTransitionRebase([string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    $journal = Read-AtlasWindowsTransition $Root
    if ($null -eq $journal -or $journal.kind -ne 'transition') { return $null }
    $rebuild = $journal.PSObject.Properties['rebuild']
    if ($null -eq $rebuild -or $null -eq $rebuild.Value -or -not [bool]$rebuild.Value.rebuilt) { return $null }
    $carry = if ($null -ne $journal.PSObject.Properties['carry']) { $journal.carry } else { $null }
    if ($null -eq $carry -or -not $carry.atlasVersion) { return $null }
    return [pscustomobject]@{ AtlasVersion = [string]$carry.atlasVersion; Options = @($carry.options); Carry = $carry; Rebuild = $rebuild.Value }
}

# One item as it is now, for the journal, or nothing when its value is of a kind
# or shape the table does not allow (it is then never changed or restored).
function New-AtlasTransitionEntry($Item, [bool]$Lift) {
    $value = Get-AtlasTransitionLive $Item
    # The move rewrites the pin, so a pin value the record can't hold stops it
    # before anything changes.
    if ($Item.Group -eq 'pin' -and $value.Present -and
        -not (Test-AtlasTransitionItemValue $Item ([pscustomobject]@{ present = $true; kind = $value.Kind; data = $value.Data }))) {
        Write-AtlasTransitionEvidence "refused: $($Item.Id) is $(Format-AtlasTransitionValue $value)"
        throw (New-AtlasTransitionFailure "The feature-update policy value $($Item.Name) has a value Atlas can't put back later." 'feature-pin' @{ setting = $Item.Name })
    }
    if ($value.Present -and $Item.Kinds -cnotcontains $value.Kind) {
        Write-AtlasTransitionEvidence "left $($Item.Id): unexpected kind $($value.Kind)"
        return
    }
    if ($value.Present -and $value.Kind -eq 'String' -and -not (Test-AtlasTransitionString ([string]$value.Data) 64)) {
        Write-AtlasTransitionEvidence "left $($Item.Id): value is not plain text"
        return
    }
    return [pscustomobject][ordered]@{
        id = $Item.Id; present = [bool]$value.Present; kind = $value.Kind; data = $value.Data
        ownerRecord = [bool](Get-AtlasTransitionOwnerRecord $Item.Owner); lifted = $Lift
    }
}

# Something can hold Windows Update back after the record was made, such as a
# launcher from an earlier Atlas. Its value now is what to put back later.
function Update-AtlasTransitionLiftSet($Journal, [string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    $table = @{}
    foreach ($item in Get-AtlasWindowsTransitionItem) { $table[$item.Id] = $item }
    $entries = [Collections.ArrayList]::new()
    foreach ($entry in @($Journal.items)) { [void]$entries.Add($entry) }
    $added = @()
    foreach ($blocker in @(Get-AtlasWindowsUpdateBlocker)) {
        $index = -1
        for ($i = 0; $i -lt $entries.Count; $i++) { if ([string]$entries[$i].id -eq $blocker.Id) { $index = $i } }
        if ($index -ge 0 -and $entries[$index].lifted) { continue }
        $entry = New-AtlasTransitionEntry $table[$blocker.Id] $true
        if ($null -eq $entry) { continue }
        if ($index -ge 0) { $entries[$index] = $entry } else { [void]$entries.Add($entry) }
        $added += $blocker.Id
    }
    if ($added.Count -eq 0) { return }
    $Journal.items = @($entries)
    Add-AtlasTransitionHistory $Journal 'new-blocker' ($added -join ',')
    Write-AtlasWindowsTransition $Journal $Root
}

# Records every table item as it is now, before the first change, with whether it
# will be lifted. An existing journal is kept: a resumed run must never record
# lifted values as the originals.
function Save-AtlasWindowsTransitionSnapshot {
    param(
        [ValidateSet('transition', 'access')][string]$Kind,
        $Source, $Target, [string]$UserSid, [string[]]$AtlasPackages = @(), $Carry = $null,
        [string]$Root = (Get-AtlasWindowsTransitionRoot)
    )
    $existing = Read-AtlasWindowsTransition $Root
    if ($null -ne $existing) {
        if ($existing.kind -eq 'access' -and $Kind -eq 'transition') {
            # A plain update before this one never touched the pin, so its
            # values now are the originals.
            $pins = @(foreach ($item in Get-AtlasWindowsTransitionItem | Where-Object Group -eq 'pin') { New-AtlasTransitionEntry $item $false })
            $existing.items = @($existing.items) + $pins
            $existing.kind = 'transition'
            $existing | Add-Member -NotePropertyName target -NotePropertyValue $Target -Force
            $existing.atlasPackages = @($AtlasPackages)
            if ($null -ne $Carry) { $existing | Add-Member -NotePropertyName carry -NotePropertyValue $Carry -Force }
            Add-AtlasTransitionHistory $existing 'became-transition' $Target.release
            Write-AtlasWindowsTransition $existing $Root
        }
        return $existing
    }
    $lift = @{}
    foreach ($blocker in @(Get-AtlasWindowsUpdateBlocker)) { $lift[$blocker.Id] = $true }
    $items = foreach ($item in Get-AtlasWindowsTransitionItem) {
        if ($Kind -eq 'access' -and $item.Group -eq 'pin') { continue }
        New-AtlasTransitionEntry $item ([bool]$lift.ContainsKey($item.Id))
    }
    $journal = [pscustomobject][ordered]@{
        schema = 1; kind = $Kind; phase = 'lifted'; source = $Source
        userSid = $UserSid; createdAt = [DateTime]::UtcNow.ToString('o')
        items = @($items); atlasPackages = @($AtlasPackages)
        installed = $null; commitBoot = $null; commitRetried = $false; history = @()
    }
    if ($Kind -eq 'transition') {
        $journal | Add-Member -NotePropertyName target -NotePropertyValue $Target
        if ($null -ne $Carry) { $journal | Add-Member -NotePropertyName carry -NotePropertyValue $Carry }
    }
    foreach ($entry in @($items)) {
        $shown = if ($entry.present) { "$($entry.kind) $($entry.data)" } else { 'absent' }
        Write-AtlasTransitionEvidence "recorded $($entry.id): $shown$(if ($entry.lifted) { ' (will lift)' })$(if ($entry.ownerRecord) { ' (owner record)' })"
    }
    Add-AtlasTransitionHistory $journal 'snapshot' "kind=$Kind"
    Write-AtlasWindowsTransition $journal $Root
    return $journal
}

function Format-AtlasTransitionValue($Value) {
    if ($null -eq $Value -or -not $Value.Present) { return 'absent' }
    return "$($Value.Kind) $($Value.Data)"
}

# Applies the lifted value of every item the journal marks lifted, then reads each
# back. Running it again changes nothing. A value that does not stay put is being
# set by something Atlas does not control, such as an organisation's policy.
function Invoke-AtlasWindowsUpdateLift($Journal) {
    $table = @{}
    foreach ($item in Get-AtlasWindowsTransitionItem) { $table[$item.Id] = $item }
    foreach ($entry in @($Journal.items | Where-Object { $_.lifted })) {
        $item = $table[[string]$entry.id]
        $before = Get-AtlasTransitionLive $item
        if ($item.Rule -eq 'task') {
            # Windows Update searches and installs without these tasks, so one
            # that can't be turned on doesn't stop the update.
            if ($before.Present -and $before.Data -ne $item.Lift) {
                try { Set-AtlasTransitionTask $item.Path $item.Name $item.Lift }
                catch { Write-AtlasTransitionEvidence "could not turn on task $($item.Name): $($_.Exception.Message)" }
            }
            Write-AtlasTransitionEvidence "lifted $($item.Id): $(Format-AtlasTransitionValue $before) -> $(Format-AtlasTransitionValue (Get-AtlasTransitionLive $item))"
            continue
        }
        if ($item.Id -like 'service.*') {
            $service = $item.Path.Split('\')[-1]
            if (-not ($before.Present -and [int64]$before.Data -eq $item.Lift)) {
                Set-AtlasTransitionServiceStart $service $item.Lift
            }
            try { Start-AtlasTransitionService $service }
            catch { Write-AtlasTransitionEvidence "could not start ${service}: $($_.Exception.Message)" }
        }
        elseif ($null -eq $item.Lift) {
            if ($before.Present) { Remove-AtlasTransitionValue $item.Path $item.Name }
        }
        elseif (-not ($before.Present -and $before.Kind -eq 'DWord' -and [int64]$before.Data -eq $item.Lift)) {
            Set-AtlasTransitionValue $item.Path $item.Name 'DWord' $item.Lift
        }
        $after = Get-AtlasTransitionLive $item
        Write-AtlasTransitionEvidence "lifted $($item.Id): $(Format-AtlasTransitionValue $before) -> $(Format-AtlasTransitionValue $after)"
        $stuck = if ($null -eq $item.Lift) { $after.Present } else { -not ($after.Present -and [int64]$after.Data -eq $item.Lift) }
        if ($stuck) {
            throw (New-AtlasTransitionFailure "$($item.Id) went back to $(Format-AtlasTransitionValue $after) after Atlas changed it." 'feature-policy' @{ setting = $item.Name })
        }
    }
}

# The one writer of the feature-update target, for the worker and the Atlas pin
# tweak. It retargets; it never removes the pin and never touches safeguard
# policies. The key is created only when missing: recreating it would drop the
# other policy values beside it.
function Set-AtlasFeatureUpdateTarget([Parameter(Mandatory = $true)][ValidatePattern('^\d{2}H\d$')][string]$Release) {
    $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name 'TargetReleaseVersion' -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name 'ProductVersion' -Value 'Windows 11' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $path -Name 'TargetReleaseVersionInfo' -Value $Release -PropertyType String -Force | Out-Null
    $written = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
    $names = @($written.PSObject.Properties.Name)
    if ($names -notcontains 'TargetReleaseVersion' -or $written.TargetReleaseVersion -ne 1 -or
        $names -notcontains 'ProductVersion' -or $written.ProductVersion -cne 'Windows 11' -or
        $names -notcontains 'TargetReleaseVersionInfo' -or $written.TargetReleaseVersionInfo -cne $Release) {
        throw "Windows did not keep the feature-update target $Release."
    }
}

function Test-AtlasTransitionLiveMatches($Item, $Live, $Entry) {
    if (-not $Entry.present) { return -not $Live.Present }
    return $Live.Present -and $Live.Kind -eq $Entry.kind -and [string]$Live.Data -ceq [string]$Entry.data
}

# Puts back what the journal says Atlas changed, deciding item by item from the
# code table, never from the journal alone:
#   Installed: the Atlas install has replayed the user's recorded toggles, so items
#     whose owner had a record are left to it; the pin stays as the install wrote it.
#   Moved: Windows has moved; everything else comes back and the new pin stays.
#   Abandoned: Windows did not move; everything comes back, the pin exactly.
# An item is restored only while it still holds the lifted value: if something else
# changed it since, that change stays. The journal goes last, then the result.
function Restore-AtlasWindowsTransition {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Installed', 'Moved', 'Abandoned')][string]$Outcome,
        [string]$Root = (Get-AtlasWindowsTransitionRoot)
    )
    $journal = Read-AtlasWindowsTransition $Root
    if ($null -eq $journal) { return $null }
    $entries = @{}
    foreach ($entry in @($journal.items)) { $entries[[string]$entry.id] = $entry }
    $restored = @(); $changed = @(); $owned = @(); $failed = @()
    foreach ($item in Get-AtlasWindowsTransitionItem | Where-Object Group -ne 'pin') {
        if (-not $entries.ContainsKey($item.Id)) { continue }
        $entry = $entries[$item.Id]
        if (-not $entry.lifted) { continue }
        if ($Outcome -eq 'Installed' -and $entry.ownerRecord -and (Get-AtlasTransitionOwnerRecord $item.Owner)) {
            $owned += $item.Id
            Write-AtlasTransitionEvidence "left $($item.Id) to the replayed $($item.Owner) choice"
            continue
        }
        $live = Get-AtlasTransitionLive $item
        $holdsLift = if ($null -eq $item.Lift) { -not $live.Present }
        elseif ($item.Rule -eq 'task') { $live.Present -and $live.Data -eq $item.Lift }
        else { $live.Present -and [int64]$live.Data -eq $item.Lift }
        if (-not $holdsLift) {
            $changed += $item.Id
            Write-AtlasTransitionEvidence "left $($item.Id): changed since to $(Format-AtlasTransitionValue $live)"
            continue
        }
        # One item that can't be put back doesn't stop the others, and only it
        # stays in the record. A task follows its service, as when lifting: one
        # that can't be put back is logged and left.
        try {
            if ($item.Rule -eq 'task') {
                if ($entry.present) { Set-AtlasTransitionTask $item.Path $item.Name ([string]$entry.data) }
            }
            elseif ($item.Id -like 'service.*') {
                $service = $item.Path.Split('\')[-1]
                if ($entry.present) {
                    Set-AtlasTransitionServiceStart $service ([int]$entry.data)
                    if ([int]$entry.data -eq 4) {
                        try { Stop-AtlasTransitionService $service }
                        catch { Write-AtlasTransitionEvidence "could not stop ${service}: $($_.Exception.Message)" }
                    }
                }
            }
            elseif ($entry.present) { Set-AtlasTransitionValue $item.Path $item.Name ([string]$entry.kind) $entry.data }
            else { Remove-AtlasTransitionValue $item.Path $item.Name }
        }
        catch {
            Write-AtlasTransitionEvidence "could not put back $($item.Id): $($_.Exception.Message)"
            if ($item.Rule -ne 'task') { $failed += $item.Id }
            continue
        }
        # A later try puts back only what this one couldn't.
        $entry.lifted = $false
        $restored += $item.Id
        Write-AtlasTransitionEvidence "restored $($item.Id): $(Format-AtlasTransitionValue $live) -> $(if ($entry.present) { "$($entry.kind) $($entry.data)" } else { 'absent' })"
    }
    if ($failed.Count -gt 0) {
        Add-AtlasTransitionHistory $journal 'restore' "outcome=$Outcome restored=$($restored.Count) failed=$($failed -join ',')"
        Write-AtlasWindowsTransition $journal $Root
        throw (New-AtlasTransitionFailure "Atlas couldn't put back $($failed -join ', ')." 'feature-restore' @{ setting = $failed -join ', ' })
    }
    $pin = 'kept'
    if ($Outcome -eq 'Abandoned' -and $journal.kind -eq 'transition') {
        $pinItems = @(Get-AtlasWindowsTransitionItem | Where-Object Group -eq 'pin')
        $live = @{}; foreach ($item in $pinItems) { $live[$item.Id] = Get-AtlasTransitionLive $item }
        $original = $true
        foreach ($item in $pinItems) {
            if ($entries.ContainsKey($item.Id) -and -not (Test-AtlasTransitionLiveMatches $item $live[$item.Id] $entries[$item.Id])) { $original = $false }
        }
        $ours = $live['pin.TargetReleaseVersion'].Present -and $live['pin.TargetReleaseVersion'].Kind -eq 'DWord' -and [int64]$live['pin.TargetReleaseVersion'].Data -eq 1 -and
            [string]$live['pin.ProductVersion'].Data -ceq 'Windows 11' -and [string]$live['pin.TargetReleaseVersionInfo'].Data -ceq [string]$journal.target.release
        if ($original) { $pin = 'unchanged' }
        elseif (-not $ours) {
            $pin = 'changed'
            Write-AtlasTransitionEvidence 'left the feature-update target: changed since'
        }
        else {
            foreach ($item in $pinItems) {
                if (-not $entries.ContainsKey($item.Id)) { continue }
                $entry = $entries[$item.Id]
                if ($entry.present) { Set-AtlasTransitionValue $item.Path $item.Name ([string]$entry.kind) $entry.data }
                else { Remove-AtlasTransitionValue $item.Path $item.Name }
                Write-AtlasTransitionEvidence "restored $($item.Id): $(Format-AtlasTransitionValue $live[$item.Id]) -> $(if ($entry.present) { "$($entry.kind) $($entry.data)" } else { 'absent' })"
            }
            $pin = 'restored'
        }
    }
    Add-AtlasTransitionHistory $journal 'restore' "outcome=$Outcome restored=$($restored.Count) changed=$($changed.Count) owned=$($owned.Count) pin=$pin"
    $windows = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $result = [pscustomobject][ordered]@{
        schema = 1; closedAt = [DateTime]::UtcNow.ToString('o'); outcome = $Outcome; kind = [string]$journal.kind
        restored = @($restored); changed = @($changed); owned = @($owned); pin = $pin
        build = if ($windows) { [int]$windows.CurrentBuildNumber } else { 0 }
        ubr = if ($windows -and $null -ne $windows.PSObject.Properties['UBR']) { [int]$windows.UBR } else { 0 }
        history = @($journal.history)
    }
    Remove-AtlasWindowsTransition $Root
    Set-AtlasTransitionValue $Root 'LastResult' 'String' ($result | ConvertTo-Json -Depth 6 -Compress)
    return $result
}

# The install's closing step: after the Atlas install has replayed the user's
# choices and written its own pin, everything else comes back.
function Complete-AtlasWindowsTransition([string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    $open = Test-AtlasWindowsTransitionOpen $Root
    if ($null -eq $open) { return 'No Windows Update settings were changed for an update; nothing to put back.' }
    if (-not $open.Readable) { throw "The Windows Update record could not be read, so nothing was put back: $($open.Error)" }
    $result = Restore-AtlasWindowsTransition -Outcome Installed -Root $Root
    "Windows Update settings put back: $(@($result.restored) -join ', ')"
    if (@($result.owned).Count -gt 0) { "Left as the replayed choices set them: $(@($result.owned) -join ', ')" }
    if (@($result.changed).Count -gt 0) { "Left because they changed since: $(@($result.changed) -join ', ')" }
}

# Toggling Windows Update or its pause by hand while Atlas has it turned on for an
# update would mix a new choice into what the restore puts back. The install's own
# replay does not come through here.
function Assert-AtlasToggleAllowedDuringTransition([string]$Name, [string]$Root = (Get-AtlasWindowsTransitionRoot)) {
    if (@('ToggleWindowsUpdates', 'PauseUpdates') -notcontains $Name) { return }
    if ($null -ne (Test-AtlasWindowsTransitionOpen $Root)) {
        throw 'Atlas Manager is updating Windows and has turned Windows Update on for now. Finish or stop that update in Atlas Manager, then change this setting.'
    }
}
