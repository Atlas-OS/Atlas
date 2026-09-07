# Atlas.State - the machine state document.
#
# C:\Windows\AtlasOS\state.json is the one document that describes what Atlas has done to
# this machine: the installed version, how it got there, the options that were selected,
# and the current AtlasDesktop toggle choices. Install completion writes the install
# facts; the toggle engine mirrors every recorded toggle state into it. Post-install
# tools, the health check, support bundles and the Toolbox app read this document.
#
# Writes take one global mutex and replace the file atomically. The document is bounded
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
    if ($null -ne $State.mode -and [string]$State.mode -cnotin @('Fresh', 'Upgrade', 'Reapply')) {
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

function Set-AtlasStateInstall {
    <#
    .SYNOPSIS
        Records a completed install from its final install-state document.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$InstallState,
        [string]$Path
    )

    $completedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $version = [string]$InstallState.targetVersion
    $mode = [string]$InstallState.mode
    $isOobe = [bool]$InstallState.isOobe
    $options = @($InstallState.options | ForEach-Object { [string]$_ })
    $transactionId = [string]$InstallState.transactionId

    return Update-AtlasState -Path $Path -Action {
        param($state)
        $state.installedVersion = $version
        $state.installedAt = $completedAt
        $state.mode = $mode
        $state.isOobe = $isOobe
        $state.isInteractive = -not $isOobe
        $state.options = $options
        $state.history = @($state.history) + @([pscustomobject][ordered]@{
                version       = $version
                mode          = $mode
                completedAt   = $completedAt
                transactionId = $transactionId
            })
    }.GetNewClosure()
}

function Set-AtlasStateToggle {
    <#
    .SYNOPSIS
        Mirrors one recorded toggle state into the document.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')][string]$Name,
        [Parameter(Mandatory = $true)][int]$State,
        [string]$Path
    )

    $updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    return Update-AtlasState -Path $Path -Action {
        param($document)
        $record = [pscustomobject][ordered]@{ state = $State; updatedAt = $updatedAt }
        if ($null -ne $document.toggles.PSObject.Properties[$Name]) {
            $document.toggles.$Name = $record
        }
        else {
            $document.toggles | Add-Member -NotePropertyName $Name -NotePropertyValue $record
        }
    }.GetNewClosure()
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
    return Update-AtlasState -Path $Path -Action {
        param($document)
        $toggles = [ordered]@{}
        foreach ($name in @($Records.Keys | Sort-Object)) {
            $existing = $document.toggles.PSObject.Properties[[string]$name]
            $stamp = $updatedAt
            if ($null -ne $existing -and [int]$existing.Value.state -eq [int]$Records[$name]) {
                $stamp = [string]$existing.Value.updatedAt
            }
            $toggles[[string]$name] = [pscustomobject][ordered]@{ state = [int]$Records[$name]; updatedAt = $stamp }
        }
        $document.toggles = [pscustomobject]$toggles
    }.GetNewClosure()
}

Export-ModuleMember -Function @(
    'Get-AtlasStatePath', 'Get-AtlasState', 'Update-AtlasState',
    'Set-AtlasStateInstall', 'Set-AtlasStateToggle', 'Sync-AtlasStateToggles'
)
