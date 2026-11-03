# Atlas.State - the machine state document.
#
# C:\Windows\AtlasOS\state.json is the one document that describes what Atlas has done to
# this machine: the installed version, how it got there, what the PC has for each install
# choice, and the current AtlasDesktop toggle choices. Install completion writes the
# install facts; the toggle engine mirrors every recorded toggle state into it, and the
# toggles that change an install choice keep that choice in step between installs.
# Post-install tools, the health check, support bundles and the Toolbox app read this
# document.
#
# Writes take one global mutex and replace the file atomically. The document is size-limited
# and schema-checked on every read so a malformed file is reported, never trusted.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions',
    '',
    Justification = 'These commands are explicit state-document transitions; WhatIf would break their durability contract.'
)]
param()

Set-StrictMode -Version 3.0

$script:AtlasStateSchemaVersion = 1
$script:AtlasStateMutexName = 'Global\AtlasOS.State.v1'
$script:AtlasStateMutexTimeoutMilliseconds = 30000
$script:AtlasStateFields = @(
    'schemaVersion', 'installedVersion', 'installedAt', 'mode', 'isOobe', 'isInteractive',
    'options', 'history', 'toggles'
)
$script:AtlasStateNamePattern = '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$'

# The install choices that can change between installs, grouped as playbook.conf groups
# them: a radio group holds exactly one of its options, and a checkbox stands alone.
$script:AtlasStateRadioChoices = @{
    Defender         = @('defender-enable', 'defender-disable')
    Mitigations      = @('mitigations-default', 'mitigations-disable')
    AutomaticUpdates = @('auto-updates-disable', 'auto-updates-default')
    Keyboard         = @('keyboard-shortcuts', 'keyboard-selector', 'keyboard-single')
}
$script:AtlasStateCheckboxChoices = @(
    'disable-hibernation', 'disable-power-saving', 'disable-core-isolation', 'uninstall-edge'
)

# The choice toggles: the install choice each recorded state stands for.
$script:AtlasStateToggleRadioChoices = @{
    Mitigations       = @{ 0 = 'mitigations-disable'; 1 = 'mitigations-default'; 2 = 'mitigations-default' }
    AutomaticUpdates  = @{ 0 = 'auto-updates-disable'; 1 = 'auto-updates-default' }
    KeyboardShortcuts = @{ 0 = 'keyboard-selector'; 1 = 'keyboard-shortcuts' }
}
# Disable (0) ticks these and Enable (1) clears them.
$script:AtlasStateToggleCheckboxChoices = @{
    Hibernation = 'disable-hibernation'
    PowerSaving = 'disable-power-saving'
    VbsState    = 'disable-core-isolation'
}

function Get-AtlasStatePath {
    <#
    .SYNOPSIS
        Returns the fixed machine state document path, or resolves an explicit override
        used by tests.
    #>
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasOS\state.json'
}

function New-AtlasStateDocument {
    return [pscustomobject][ordered]@{
        schemaVersion    = $script:AtlasStateSchemaVersion
        installedVersion = $null
        installedAt      = $null
        mode             = $null
        isOobe           = $false
        isInteractive    = $false
        options          = @()
        history          = @()
        toggles          = [pscustomobject]@{}
    }
}

function Assert-AtlasStateDocument {
    param([Parameter(Mandatory = $true)][object]$State)

    foreach ($field in $script:AtlasStateFields) {
        if ($null -eq $State.PSObject.Properties[$field]) {
            throw "The Atlas state document is missing '$field'."
        }
    }
    foreach ($property in $State.PSObject.Properties) {
        if ($script:AtlasStateFields -cnotcontains $property.Name) {
            throw "The Atlas state document has an unknown field '$($property.Name)'."
        }
    }
    if ([int]$State.schemaVersion -ne $script:AtlasStateSchemaVersion) {
        throw "The Atlas state document schema version $($State.schemaVersion) is not supported."
    }
    if ($null -ne $State.mode -and [string]$State.mode -cnotin @('Fresh', 'Upgrade', 'Reapply', 'Rebase')) {
        throw "The Atlas state document mode '$($State.mode)' is invalid."
    }
    foreach ($option in @($State.options)) {
        if ([string]$option -cnotmatch $script:AtlasStateNamePattern) {
            throw "The Atlas state document option '$option' is invalid."
        }
    }
    foreach ($property in $State.toggles.PSObject.Properties) {
        if ($property.Name -cnotmatch $script:AtlasStateNamePattern) {
            throw "The Atlas state document toggle name '$($property.Name)' is invalid."
        }
        if ($null -eq $property.Value.PSObject.Properties['state'] -or $property.Value.state -isnot [int] -and $property.Value.state -isnot [long]) {
            throw "The Atlas state document toggle '$($property.Name)' has no integer state."
        }
    }
}

function Read-AtlasStateFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [IO.File]::Exists($Path)) {
        return $null
    }
    if (([IO.File]::GetAttributes($Path) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The Atlas state document '$Path' is a reparse point."
    }

    try {
        $state = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "The Atlas state document '$Path' is malformed: $($_.Exception.Message)"
    }
    Assert-AtlasStateDocument -State $state
    return $state
}

function Write-AtlasStateFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$State
    )

    Assert-AtlasStateDocument -State $State
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(($State | ConvertTo-Json -Depth 8))

    $directory = [IO.Path]::GetDirectoryName($Path)
    [void][IO.Directory]::CreateDirectory($directory)
    $temporaryPath = Join-Path -Path $directory -ChildPath ('.state.{0}.tmp' -f [Guid]::NewGuid().ToString('N'))
    try {
        $stream = New-Object IO.FileStream($temporaryPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        }
        finally {
            $stream.Dispose()
        }

        if ([IO.File]::Exists($Path)) {
            $replaced = "$temporaryPath.replaced"
            [IO.File]::Replace($temporaryPath, $Path, $replaced, $true)
            [IO.File]::Delete($replaced)
        }
        else {
            [IO.File]::Move($temporaryPath, $Path)
        }
        $temporaryPath = $null
    }
    finally {
        if ($null -ne $temporaryPath -and [IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}

function Invoke-AtlasStateLocked {
    # Named LockedAction so a caller's own $Action parameter is never resolved through
    # dynamic scope from inside the locked block.
    param([Parameter(Mandatory = $true)][scriptblock]$LockedAction)

    $createdNew = $false
    $mutex = New-Object Threading.Mutex($false, $script:AtlasStateMutexName, [ref]$createdNew)
    $lockTaken = $false
    try {
        try {
            $lockTaken = $mutex.WaitOne($script:AtlasStateMutexTimeoutMilliseconds)
        }
        catch [Threading.AbandonedMutexException] {
            $lockTaken = $true
        }
        if (-not $lockTaken) {
            throw 'Timed out waiting for the Atlas state-document lock.'
        }
        return & $LockedAction
    }
    finally {
        if ($lockTaken) {
            $mutex.ReleaseMutex()
        }
        $mutex.Dispose()
    }
}

function Get-AtlasState {
    <#
    .SYNOPSIS
        Returns the machine state document, or $null when Atlas has never completed an
        install on this machine.
    #>
    [CmdletBinding()]
    param([string]$Path)

    $resolvedPath = Get-AtlasStatePath -Path $Path
    return Invoke-AtlasStateLocked { Read-AtlasStateFile -Path $resolvedPath }
}

function Update-AtlasState {
    <#
    .SYNOPSIS
        Applies one change to the state document under the lock. The action receives
        the current document (a new one when none exists) and returns nothing; the
        modified document is written back atomically.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [string]$Path
    )

    # Callers pass closures (GetNewClosure) so their captured variables are bound
    # lexically and never resolved through this block's own locals.
    $resolvedPath = Get-AtlasStatePath -Path $Path
    $update = $Action
    return Invoke-AtlasStateLocked {
        $current = Read-AtlasStateFile -Path $resolvedPath
        if ($null -eq $current) {
            $current = New-AtlasStateDocument
        }
        & $update $current
        Write-AtlasStateFile -Path $resolvedPath -State $current
        return $current
    }
}

function Merge-AtlasStateChoice {
    <#
    .SYNOPSIS
        Returns the options with one install choice set. A radio option takes the place
        of its group's chosen option; a checkbox is added at the end, or removed with
        -Absent. The other options keep their order.
    #>
    param(
        [string[]]$Options = @(),
        [Parameter(Mandatory = $true)][string]$Option,
        [switch]$Absent
    )

    $group = $null
    foreach ($radio in $script:AtlasStateRadioChoices.Values) {
        if ($radio -ccontains $Option) { $group = $radio }
    }
    if ($null -ne $group) {
        if ($Absent) {
            throw "Install choice '$Option' is one answer of several, so it can't be cleared; set another answer instead."
        }
        $placed = $false
        foreach ($existing in @($Options)) {
            if ($group -cnotcontains $existing) {
                $existing
            }
            elseif (-not $placed) {
                $Option
                $placed = $true
            }
        }
        if (-not $placed) { $Option }
        return
    }

    if ($script:AtlasStateCheckboxChoices -cnotcontains $Option) {
        throw "'$Option' isn't an install choice Atlas keeps in step between installs."
    }
    if ($Absent) {
        return @($Options | Where-Object { $_ -cne $Option })
    }
    $Options
    if (@($Options) -cnotcontains $Option) { $Option }
}

function Merge-AtlasStateToggleChoice {
    <#
    .SYNOPSIS
        Returns the options with the install choice a choice toggle's recorded state
        stands for. Any other toggle or state leaves them as they are.
    #>
    param(
        [string[]]$Options = @(),
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$State
    )

    if ($script:AtlasStateToggleCheckboxChoices.ContainsKey($Name) -and $State -in @(0, 1)) {
        return Merge-AtlasStateChoice -Options $Options -Option $script:AtlasStateToggleCheckboxChoices[$Name] -Absent:($State -eq 1)
    }
    if (-not $script:AtlasStateToggleRadioChoices.ContainsKey($Name) -or
        -not $script:AtlasStateToggleRadioChoices[$Name].ContainsKey($State)) {
        return $Options
    }
    $option = [string]$script:AtlasStateToggleRadioChoices[$Name][$State]
    # Keyboard selector and single turn the shortcuts off alike, so the one already
    # chosen stays.
    if ($option -ceq 'keyboard-selector' -and @($Options | Where-Object { $_ -cin @('keyboard-selector', 'keyboard-single') }).Count -gt 0) {
        return $Options
    }
    return Merge-AtlasStateChoice -Options $Options -Option $option
}

function Get-AtlasStateToggleStamp {
    # A record keeps its time while its state stays the same, so updatedAt says when
    # the toggle was set to that state and a replay doesn't move it.
    param($Existing, [int]$State, [string]$Now)

    if ($null -ne $Existing -and [int]$Existing.Value.state -eq $State -and
        $null -ne $Existing.Value.PSObject.Properties['updatedAt']) {
        return [string]$Existing.Value.updatedAt
    }
    return $Now
}

function Set-AtlasStateInstall {
    <#
    .SYNOPSIS
        Records a completed install from its final install-state document.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$InstallState,
        [string]$Path,

        # What the PC has for each install choice, when completion has read it. Without
        # it, or with $null, the install state's requested options are recorded; an
        # empty set records none.
        [string[]]$Options,

        # The options of each choice the install tried to apply that the PC doesn't
        # have as requested, when completion has read it, kept in this install's history
        # entry as notApplied. Without it, or with $null, the entry has none.
        [string[]]$NotApplied
    )

    $completedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $version = [string]$InstallState.targetVersion
    $mode = [string]$InstallState.mode
    $isOobe = [bool]$InstallState.isOobe
    $recordedOptions = @($InstallState.options | ForEach-Object { [string]$_ })
    # $null too, so a caller can pass on an optional set it never received.
    if ($null -ne $Options) {
        $recordedOptions = @($Options)
    }
    $transactionId = [string]$InstallState.transactionId
    $entry = [ordered]@{
        version       = $version
        mode          = $mode
        completedAt   = $completedAt
        transactionId = $transactionId
    }
    if ($null -ne $NotApplied) {
        $entry.notApplied = @($NotApplied)
    }

    return Update-AtlasState -Path $Path -Action {
        param($state)
        $state.installedVersion = $version
        $state.installedAt = $completedAt
        $state.mode = $mode
        $state.isOobe = $isOobe
        $state.isInteractive = -not $isOobe
        $state.options = @($recordedOptions)
        $state.history = @($state.history) + @([pscustomobject]$entry)
    }.GetNewClosure()
}

function Set-AtlasStateToggle {
    <#
    .SYNOPSIS
        Mirrors one recorded toggle state into the document. With -SyncChoice, a choice
        toggle also sets the install choice its state stands for, in the same write,
        once an install has completed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        # The range includes both cases; ValidatePattern's default IgnoreCase is culture-sensitive.
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$', Options = [Text.RegularExpressions.RegexOptions]::None)]
        [string]$Name,
        [Parameter(Mandatory = $true)][int]$State,
        [string]$Path,

        # Only between installs: during one, completion records what the PC has.
        [switch]$SyncChoice
    )

    $updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    # A closure doesn't see this module's own functions, so it calls them through these.
    $stamp = ${function:Get-AtlasStateToggleStamp}
    $mergeChoice = ${function:Merge-AtlasStateToggleChoice}
    return Update-AtlasState -Path $Path -Action {
        param($document)
        $existing = $document.toggles.PSObject.Properties[$Name]
        $record = [pscustomobject][ordered]@{
            state     = $State
            updatedAt = (& $stamp -Existing $existing -State $State -Now $updatedAt)
        }
        if ($null -ne $existing) {
            $document.toggles.$Name = $record
        }
        else {
            $document.toggles | Add-Member -NotePropertyName $Name -NotePropertyValue $record
        }
        if ($SyncChoice -and -not [string]::IsNullOrWhiteSpace([string]$document.installedVersion)) {
            $document.options = @(& $mergeChoice -Options @($document.options) -Name $Name -State $State)
        }
    }.GetNewClosure()
}

function Set-AtlasStateChoice {
    <#
    .SYNOPSIS
        Sets one install choice in the document after a change made outside an install,
        such as Toggle Defender's: a radio option replaces its group's, and a checkbox is
        ticked, or cleared with -Absent. Returns the document, or nothing when there is
        no completed install to describe.
    .DESCRIPTION
        Does nothing while an install is active (Install\active.json beside the
        document), whose completion records what the PC has, or before an install has
        completed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$', Options = [Text.RegularExpressions.RegexOptions]::None)]
        [string]$Option,

        [switch]$Absent,

        [string]$Path
    )

    # Refused before the lock, so a wrong choice never waits for it.
    $null = Merge-AtlasStateChoice -Option $Option -Absent:$Absent
    $resolvedPath = Get-AtlasStatePath -Path $Path
    $activePath = [IO.Path]::Combine([IO.Path]::GetDirectoryName($resolvedPath), 'Install', 'active.json')
    return Invoke-AtlasStateLocked {
        # Checked under the lock: completion writes the document before it removes
        # active.json, so a choice is never set over an install's record.
        if ([IO.File]::Exists($activePath)) {
            return
        }
        $current = Read-AtlasStateFile -Path $resolvedPath
        if ($null -eq $current -or [string]::IsNullOrWhiteSpace([string]$current.installedVersion)) {
            return
        }
        $options = @(Merge-AtlasStateChoice -Options @($current.options) -Option $Option -Absent:$Absent)
        if (($options -join "`n") -cne (@($current.options) -join "`n")) {
            $current.options = $options
            Write-AtlasStateFile -Path $resolvedPath -State $current
        }
        return $current
    }
}

function Sync-AtlasStateToggles {
    <#
    .SYNOPSIS
        Replaces the document's toggle view with the complete set of recorded states
        from the toggle state store, so the two can never drift apart after an install.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][hashtable]$Records,
        [string]$Path
    )

    foreach ($name in @($Records.Keys)) {
        if ([string]$name -cnotmatch $script:AtlasStateNamePattern) {
            throw "Toggle record name '$name' is invalid."
        }
    }
    $updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $stamp = ${function:Get-AtlasStateToggleStamp}
    return Update-AtlasState -Path $Path -Action {
        param($document)
        $toggles = [ordered]@{}
        foreach ($name in @($Records.Keys | Sort-Object)) {
            $existing = $document.toggles.PSObject.Properties[[string]$name]
            $toggles[[string]$name] = [pscustomobject][ordered]@{
                state     = [int]$Records[$name]
                updatedAt = (& $stamp -Existing $existing -State ([int]$Records[$name]) -Now $updatedAt)
            }
        }
        $document.toggles = [pscustomobject]$toggles
    }.GetNewClosure()
}

Export-ModuleMember -Function @(
    'Get-AtlasStatePath', 'Get-AtlasState', 'Update-AtlasState',
    'Set-AtlasStateInstall', 'Set-AtlasStateToggle', 'Set-AtlasStateChoice', 'Sync-AtlasStateToggles'
)
