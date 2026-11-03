[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions',
    '',
    Justification = 'These commands are explicit install-state transitions; WhatIf would break their durability contract.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseApprovedVerbs',
    '',
    Justification = 'Commit is the precise public transition from captured to immutable run state.'
)]
param()

Set-StrictMode -Version 3.0

# Mode resolution reads Atlas Manager's record of a Windows move.
. (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Preparation\WindowsTransition.ps1')

# Completion publishes the install facts into the machine state document.
$stateDocumentManifest = Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.State\Atlas.State.psd1'
if (-not (Test-Path -LiteralPath $stateDocumentManifest -PathType Leaf)) {
    throw "Required Atlas.State manifest '$stateDocumentManifest' is missing."
}
Import-Module -Name $stateDocumentManifest -ErrorAction Stop

$script:AtlasInstallStateSchemaVersion = 1
$script:AtlasInstallStateMutexName = 'Global\AtlasOS.InstallState.v1'
$script:AtlasInstallStateMutexTimeoutMilliseconds = 30000
$script:AtlasInstallStateFields = @(
    'schemaVersion'
    'targetVersion'
    'transactionId'
    'status'
    'mode'
    'isOobe'
    'options'
    'userSid'
    'userSessionId'
    'captureNonce'
    'completedSteps'
    'lastError'
)
# How an update treats the choices the PC has. Kept out of the required fields, so
# an install state written before the update path existed still loads; it keeps.
$script:AtlasInstallChoices = @('Keep', 'ChooseAgain')

function Get-AtlasInstallStatePath {
    [CmdletBinding()]
    param([string]$RootPath)

    if ([string]::IsNullOrWhiteSpace($RootPath)) {
        $RootPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) `
            -ChildPath 'AtlasOS\Install'
    }

    return Join-Path -Path ([IO.Path]::GetFullPath($RootPath)) -ChildPath 'active.json'
}

function Get-AtlasInstallWorkRoot {
    [CmdletBinding()]
    param([string]$RootPath)

    if ([string]::IsNullOrWhiteSpace($RootPath)) {
        $RootPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) `
            -ChildPath 'AtlasOS\Install'
    }

    return Join-Path -Path ([IO.Path]::GetFullPath($RootPath)) -ChildPath 'work'
}

function Resolve-AtlasInstallStatePath {
    param([string]$StatePath)

    if ([string]::IsNullOrWhiteSpace($StatePath)) {
        return Get-AtlasInstallStatePath
    }

    return [IO.Path]::GetFullPath($StatePath)
}

function Assert-AtlasInstallName {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or
        $Value.Length -gt 128 -or
        $Value -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._:/-]*$') {
        throw "Invalid $Label '$Value'."
    }
}

function Assert-AtlasInstallStateDocument {
    param([Parameter(Mandatory = $true)][object]$State)

    $propertyNames = @($State.PSObject.Properties.Name)
    foreach ($field in $script:AtlasInstallStateFields) {
        if ($propertyNames -notcontains $field) {
            throw "Install state is missing required field '$field'."
        }
    }
    if ($State.schemaVersion -ne $script:AtlasInstallStateSchemaVersion) {
        throw "Unsupported install-state schema version '$($State.schemaVersion)'."
    }
    if ($State.targetVersion -isnot [string] -or
        [string]::IsNullOrWhiteSpace($State.targetVersion) -or
        $State.targetVersion.Length -gt 128) {
        throw 'Install state has an invalid targetVersion.'
    }

    $transactionId = [Guid]::Empty
    if ($State.transactionId -isnot [string] -or
        -not [Guid]::TryParse($State.transactionId, [ref]$transactionId)) {
        throw 'Install state has an invalid transactionId.'
    }
    if (@('Capturing', 'Running', 'Completed') -notcontains $State.status) {
        throw "Install state has an invalid status '$($State.status)'."
    }
    if (@('Fresh', 'Upgrade', 'Reapply', 'Rebase') -notcontains $State.mode) {
        throw "Install state has an invalid mode '$($State.mode)'."
    }
    if ($State.isOobe -isnot [bool]) {
        throw 'Install state isOobe must be a Boolean.'
    }
    if ($State.options -isnot [Array]) {
        throw 'Install state options must be an array.'
    }
    foreach ($option in @($State.options)) {
        if ($option -isnot [string]) {
            throw 'Install state options must contain strings.'
        }
        Assert-AtlasInstallName -Value $option -Label 'option name'
    }
    if ($null -ne $State.userSid -and
        ($State.userSid -isnot [string] -or
            $State.userSid -notmatch '^S-\d-\d+(?:-\d+)+$')) {
        throw 'Install state has an invalid userSid.'
    }
    if ($null -ne $State.userSessionId -and
        (($State.userSessionId -isnot [int] -and $State.userSessionId -isnot [long]) -or
            [long]$State.userSessionId -lt 0)) {
        throw 'Install state has an invalid userSessionId.'
    }
    if ($State.captureNonce -isnot [string] -or
        [string]::IsNullOrWhiteSpace($State.captureNonce) -or
        $State.captureNonce.Length -gt 256) {
        throw 'Install state has an invalid captureNonce.'
    }
    if ($State.completedSteps -isnot [Array]) {
        throw 'Install state completedSteps must be an array.'
    }
    foreach ($step in @($State.completedSteps)) {
        if ($step -isnot [string]) {
            throw 'Install state completedSteps must contain strings.'
        }
        Assert-AtlasInstallName -Value $step -Label 'step name'
    }
    if ($null -ne $State.lastError -and
        ($State.lastError -isnot [string] -or $State.lastError.Length -gt 4096)) {
        throw 'Install state has an invalid lastError.'
    }
    $choices = $State.PSObject.Properties['choices']
    if ($null -ne $choices -and
        ($choices.Value -isnot [string] -or $script:AtlasInstallChoices -cnotcontains $choices.Value)) {
        throw "Install state has an invalid choices value '$($choices.Value)'."
    }
    # Only last.json has it: what the PC had for each choice when the run completed.
    $recorded = $State.PSObject.Properties['recordedOptions']
    if ($null -ne $recorded) {
        if ($recorded.Value -isnot [Array]) {
            throw 'Install state recordedOptions must be an array.'
        }
        foreach ($option in @($recorded.Value)) {
            if ($option -isnot [string]) {
                throw 'Install state recordedOptions must contain strings.'
            }
            Assert-AtlasInstallName -Value $option -Label 'option name'
        }
    }
}

function Read-AtlasInstallStateFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [IO.File]::Exists($Path)) {
        return $null
    }

    try {
        $state = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Install state '$Path' is malformed: $($_.Exception.Message)"
    }

    Assert-AtlasInstallStateDocument -State $state
    return $state
}

function Write-AtlasInstallStateFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$State,
        [switch]$CreateBackup
    )

    Assert-AtlasInstallStateDocument -State $State
    $json = $State | ConvertTo-Json -Depth 12 -Compress
    $encoding = New-Object Text.UTF8Encoding($false)
    $bytes = $encoding.GetBytes($json)

    $directory = [IO.Path]::GetDirectoryName($Path)
    if (-not [IO.Directory]::Exists($directory)) {
        [void][IO.Directory]::CreateDirectory($directory)
    }
    $temporaryPath = Join-Path -Path $directory -ChildPath `
        ('.{0}.{1}.tmp' -f [IO.Path]::GetFileName($Path), [Guid]::NewGuid().ToString('N'))
    $discardedBackupPath = $null

    try {
        $stream = New-Object IO.FileStream(
            $temporaryPath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        try {
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        } finally {
            $stream.Dispose()
        }

        if ([IO.File]::Exists($Path)) {
            if ($CreateBackup) {
                $backupPath = "$Path.bak"
            } else {
                $discardedBackupPath = "$temporaryPath.replaced"
                $backupPath = $discardedBackupPath
            }
            [IO.File]::Replace($temporaryPath, $Path, $backupPath, $true)
            if ($null -ne $discardedBackupPath) {
                [IO.File]::Delete($discardedBackupPath)
                $discardedBackupPath = $null
            }
        } else {
            [IO.File]::Move($temporaryPath, $Path)
        }
        $temporaryPath = $null
    } finally {
        if ($null -ne $temporaryPath -and [IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
        if ($null -ne $discardedBackupPath -and [IO.File]::Exists($discardedBackupPath)) {
            [IO.File]::Delete($discardedBackupPath)
        }
    }
}

function Invoke-AtlasInstallStateLocked {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)

    $createdNew = $false
    $mutex = New-Object Threading.Mutex($false, $script:AtlasInstallStateMutexName, [ref]$createdNew)
    $lockTaken = $false
    try {
        try {
            $lockTaken = $mutex.WaitOne($script:AtlasInstallStateMutexTimeoutMilliseconds)
        } catch [Threading.AbandonedMutexException] {
            $lockTaken = $true
        }
        if (-not $lockTaken) {
            throw 'Timed out waiting for the Atlas install-state lock.'
        }
        return & $Action
    } finally {
        if ($lockTaken) {
            $mutex.ReleaseMutex()
        }
        $mutex.Dispose()
    }
}

function Get-AtlasInstallStateUnlocked {
    param([Parameter(Mandatory = $true)][string]$StatePath)

    $backupPath = "$StatePath.bak"
    $primaryFailure = $null
    try {
        $state = Read-AtlasInstallStateFile -Path $StatePath
        if ($null -ne $state) {
            return $state
        }
    } catch {
        $primaryFailure = $_
    }

    try {
        $backup = Read-AtlasInstallStateFile -Path $backupPath
    } catch {
        if ($null -ne $primaryFailure) {
            throw "$($primaryFailure.Exception.Message) Backup recovery also failed: $($_.Exception.Message)"
        }
        throw
    }

    if ($null -eq $backup) {
        if ($null -ne $primaryFailure) {
            throw $primaryFailure
        }
        return $null
    }

    Write-AtlasInstallStateFile -Path $StatePath -State $backup
    return $backup
}

function Get-AtlasInstallState {
    [CmdletBinding()]
    param([string]$StatePath)

    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
    }
}

function Start-AtlasInstallState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$TargetVersion,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Fresh', 'Upgrade', 'Reapply', 'Rebase')]
        [string]$Mode,
        # How an update treats the choices the PC has (Resolve-AtlasInstallChoices).
        [ValidateSet('Keep', 'ChooseAgain')]
        [string]$Choices = 'Keep',
        [bool]$IsOobe = $false,
        [string]$CaptureNonce = ([Guid]::NewGuid().ToString('D')),
        [string]$StatePath
    )

    if ([string]::IsNullOrWhiteSpace($TargetVersion) -or $TargetVersion.Length -gt 128) {
        throw 'TargetVersion must be a non-empty string of at most 128 characters.'
    }
    if ([string]::IsNullOrWhiteSpace($CaptureNonce) -or $CaptureNonce.Length -gt 256) {
        throw 'CaptureNonce must be a non-empty string of at most 256 characters.'
    }
    $installMode = $Mode
    $installChoices = $Choices
    $oobeValue = $IsOobe
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $directory = [IO.Path]::GetDirectoryName($resolvedPath)
        $abandonedPath = Join-Path -Path $directory -ChildPath 'abandoned.json'

        # Completion removes transient work. Any later retry or older-RC recovery must
        # restore this invariant before option capture or Always checkpoints use it.
        [void][IO.Directory]::CreateDirectory((Join-Path -Path $directory -ChildPath 'work'))

        # A failed Fresh transaction may have been archived by an older RC when AME
        # reclassified the partially modified machine as Reapply. Restore it as the
        # active state so the reclassified-retry recovery below resumes that exact
        # Fresh step position and the remaining Fresh-only phases are not lost.
        if (-not [IO.File]::Exists($resolvedPath) -and
            $installMode -ceq 'Reapply' -and
            [IO.File]::Exists($abandonedPath)) {
            $abandoned = Read-AtlasInstallStateFile -Path $abandonedPath
            if ($abandoned.targetVersion -ceq $TargetVersion -and
                $abandoned.status -ceq 'Running' -and
                $abandoned.mode -ceq 'Fresh' -and
                -not [string]::IsNullOrWhiteSpace([string]$abandoned.lastError)) {
                Write-AtlasInstallStateFile -Path $resolvedPath -State $abandoned
                [IO.File]::Delete($abandonedPath)
            }
        }
        $existing = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -ne $existing) {
            if (-not [string]::Equals(
                    $existing.targetVersion,
                    $TargetVersion,
                    [StringComparison]::Ordinal
                )) {
                throw "An install state for target '$($existing.targetVersion)' is already active."
            }
            $changed = $false
            if ($existing.mode -cne $installMode -or
                [bool]$existing.isOobe -ne $oobeValue) {
                # A capture with completed steps is a recovered run whose capture was
                # interrupted before Commit, so the next retry recovers it again.
                $canRecoverFailedRun = (
                    $existing.status -ceq 'Running' -and
                    -not [string]::IsNullOrWhiteSpace([string]$existing.lastError)
                ) -or (
                    $existing.status -ceq 'Capturing' -and
                    @($existing.completedSteps).Count -gt 0
                )
                if (-not $canRecoverFailedRun) {
                    $began = if ([bool]$existing.isOobe) { ', begun during Windows setup,' } else { '' }
                    $article = if ($installMode -cmatch '^[AEIOU]') { 'an' } else { 'a' }
                    $requested = if ($oobeValue) { ' during Windows setup' } else { '' }
                    throw ("An unfinished Atlas $($existing.mode) installation of $($existing.targetVersion)$began is waiting to finish, " +
                        "so $article $installMode installation$requested can't start. Finish it first: in Atlas Manager, choose " +
                        "Finish installing Atlas $($existing.targetVersion), or run Install-Atlas.ps1 again with the options it started with.")
                }

                # AME can classify a retry differently after a partial install has
                # changed product state (for example Fresh -> Reapply). Resume the
                # original plan and completed steps; only refresh the interactive
                # identity before resuming.
                $existing.status = 'Capturing'
                $existing.userSid = $null
                $existing.userSessionId = $null
                $existing.captureNonce = $CaptureNonce
                $existing.lastError = $null
                $changed = $true
            }
            # AME records options one at a time, so a capture that starts again records
            # them afresh instead of adding this run's choices to an interrupted run's.
            # Completed steps hold a run to its original options.
            if ($existing.status -ceq 'Capturing' -and
                @($existing.completedSteps).Count -eq 0 -and
                @($existing.options).Count -gt 0) {
                $existing.options = @()
                $changed = $true
            }
            # The update path goes with the options: a capture that starts again takes
            # this run's, and a run whose steps began keeps the one it began with.
            if ($existing.status -ceq 'Capturing' -and @($existing.completedSteps).Count -eq 0) {
                $stored = $existing.PSObject.Properties['choices']
                if ($null -eq $stored) {
                    $existing | Add-Member -NotePropertyName choices -NotePropertyValue $installChoices
                    $changed = $true
                }
                elseif ([string]$stored.Value -cne $installChoices) {
                    $existing.choices = $installChoices
                    $changed = $true
                }
            }
            if ($changed) {
                Write-AtlasInstallStateFile -Path $resolvedPath -State $existing -CreateBackup
            }
            if (@('Capturing', 'Running') -contains $existing.status) {
                return $existing
            }
            throw "Install state '$resolvedPath' is not active."
        }

        $state = [pscustomobject][ordered]@{
            schemaVersion  = $script:AtlasInstallStateSchemaVersion
            targetVersion = $TargetVersion
            transactionId = [Guid]::NewGuid().ToString('D')
            status         = 'Capturing'
            mode           = $installMode
            isOobe         = $oobeValue
            options        = @()
            choices        = $installChoices
            userSid        = $null
            userSessionId  = $null
            captureNonce   = $CaptureNonce
            completedSteps = @()
            lastError      = $null
        }
        Write-AtlasInstallStateFile -Path $resolvedPath -State $state
        return $state
    }
}

function Get-AtlasInstallOptionLockMessage {
    # A resume must use the options its finished steps used, so the refusal names them.
    param([Parameter(Mandatory = $true)][object]$State)

    $began = @($State.options | ForEach-Object { [string]$_ })
    $list = if ($began.Count -gt 0) { $began -join ', ' } else { 'none' }
    return "This installation already started with other choices, and the steps it finished won't run again. Run it again with the choices it started with: $list."
}

function Set-AtlasInstallOptions {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Options, [string]$StatePath)

    foreach ($option in $Options) { Assert-AtlasInstallName -Value $option -Label 'option name' }
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state) { throw 'No Atlas install state is active.' }
        if ($state.status -ceq 'Running' -or @($state.completedSteps).Count -gt 0) {
            if ((@($state.options | Sort-Object) -join "`n") -cne (@($Options | Sort-Object) -join "`n")) {
                throw (Get-AtlasInstallOptionLockMessage -State $state)
            }
            return $state
        }
        if ($state.status -cne 'Capturing') { throw "Options cannot be set while install state is '$($state.status)'." }
        $state.options = @($Options)
        Write-AtlasInstallStateFile -Path $resolvedPath -State $state -CreateBackup
        return $state
    }
}

function Add-AtlasInstallOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$StatePath
    )

    Assert-AtlasInstallName -Value $Name -Label 'option name'
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state) {
            throw 'No Atlas install state is active.'
        }
        if ($state.status -eq 'Running' -or @($state.completedSteps).Count -gt 0) {
            if (@($state.options) -inotcontains $Name) {
                throw (Get-AtlasInstallOptionLockMessage -State $state)
            }
            return $state
        }
        if ($state.status -ne 'Capturing') {
            throw "Options cannot be added while install state is '$($state.status)'."
        }
        if (@($state.options) -inotcontains $Name) {
            $state.options = @($state.options) + $Name
            Write-AtlasInstallStateFile -Path $resolvedPath -State $state -CreateBackup
        }
        return $state
    }
}

function Set-AtlasInstallUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^S-\d-\d+(?:-\d+)+$')]
        [string]$UserSid,
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$UserSessionId,
        [string]$StatePath
    )

    $installUserSid = $UserSid
    $installUserSessionId = $UserSessionId
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state) {
            throw 'No Atlas install state is active.'
        }
        if (@('Capturing', 'Running') -notcontains $state.status) {
            throw "The install user cannot be changed while install state is '$($state.status)'."
        }
        if ($null -ne $state.userSid -and
            -not [string]::Equals(
                $state.userSid,
                $installUserSid,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw "Install state is already bound to user '$($state.userSid)'."
        }
        if ($state.status -eq 'Running' -and $null -eq $state.userSid) {
            throw 'The install user cannot be bound after capture has been committed.'
        }

        if ($null -eq $state.userSid -or $state.userSessionId -ne $installUserSessionId) {
            $state.userSid = $installUserSid
            $state.userSessionId = $installUserSessionId
            Write-AtlasInstallStateFile -Path $resolvedPath -State $state -CreateBackup
        }
        return $state
    }
}

function Commit-AtlasInstallState {
    [CmdletBinding()]
    param([string]$StatePath)

    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state) {
            throw 'No Atlas install state is active.'
        }
        if ($state.status -eq 'Running') {
            return $state
        }
        if ($state.status -ne 'Capturing') {
            throw "Install state cannot be committed from '$($state.status)'."
        }

        $state.status = 'Running'
        $state.lastError = $null
        Write-AtlasInstallStateFile -Path $resolvedPath -State $state -CreateBackup
        return $state
    }
}

function Invoke-AtlasInstallStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [ValidateSet('Always', 'Once')][string]$Mode = 'Once',
        [Parameter(Mandatory = $true)]
        [Alias('ScriptBlock')]
        [scriptblock]$Action,
        [string]$StatePath
    )

    Assert-AtlasInstallName -Value $Name -Label 'step name'
    $stepMode = $Mode
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    $decision = Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state) {
            throw 'No Atlas install state is active.'
        }
        if ($state.status -ne 'Running') {
            throw "Install steps cannot run while install state is '$($state.status)'."
        }

        $alreadyCompleted = @($state.completedSteps) -icontains $Name
        return [pscustomobject]@{
            transactionId = $state.transactionId
            shouldRun     = ($stepMode -eq 'Always' -or -not $alreadyCompleted)
        }
    }
    if (-not $decision.shouldRun) {
        return [pscustomobject]@{ Skipped = $true; Result = $null }
    }

    # Actions can launch a user process that reads this state. Never hold the
    # named state mutex while an action runs, so the parent and child cannot
    # deadlock while waiting on each other.
    try {
        $result = & $Action
    } catch {
        $actionFailure = $_
        $message = $_.Exception.Message
        if ($message.Length -gt 4096) {
            $message = $message.Substring(0, 4096)
        }
        # The action failure is what gets reported; recording lastError is best
        # effort once the state or its transaction has moved on.
        try {
            Invoke-AtlasInstallStateLocked {
                $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
                if ($null -eq $state -or
                    $state.status -ne 'Running' -or
                    -not [string]::Equals(
                        $state.transactionId,
                        $decision.transactionId,
                        [StringComparison]::Ordinal
                    )) {
                    throw "Install state changed while step '$Name' was running."
                }
                $state.lastError = $message
                Write-AtlasInstallStateFile -Path $resolvedPath -State $state -CreateBackup
            } | Out-Null
        } catch {
            Write-Warning ("Install step '$Name' failed and its lastError could not " +
                "be recorded: $($_.Exception.Message)")
        }
        throw $actionFailure
    }

    Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state -or
            $state.status -ne 'Running' -or
            -not [string]::Equals(
                $state.transactionId,
                $decision.transactionId,
                [StringComparison]::Ordinal
            )) {
            throw "Install state changed while step '$Name' was running."
        }
        if (@($state.completedSteps) -inotcontains $Name) {
            $state.completedSteps = @($state.completedSteps) + $Name
        }
        $state.lastError = $null
        Write-AtlasInstallStateFile -Path $resolvedPath -State $state -CreateBackup
    } | Out-Null
    return [pscustomobject]@{ Skipped = $false; Result = $result }
}

function Publish-AtlasInstallFlagSet {
    param(
        [Parameter(Mandatory = $true)][object]$State,
        [Parameter(Mandatory = $true)][string]$FlagsPath,
        # What the PC has for each choice, when completion read it; otherwise the
        # state's own options.
        [string[]]$Options
    )

    $names = @()
    if (@('Upgrade', 'Rebase') -ccontains [string]$State.mode) {
        $names += 'Upgrade.flag'
    }
    if (-not [bool]$State.isOobe) {
        $names += 'Interactive.flag'
    }
    $published = if ($null -ne $Options) { @($Options) } else { @($State.options) }
    foreach ($option in $published) {
        if ([string]$option -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
            throw "Install option '$option' cannot be published as a compatibility flag."
        }
        $names += "option-$option.flag"
    }

    $path = [IO.Path]::GetFullPath($FlagsPath)
    [void][IO.Directory]::CreateDirectory($path)
    foreach ($oldFlag in [IO.Directory]::GetFiles($path, '*.flag')) {
        [IO.File]::Delete($oldFlag)
    }
    foreach ($name in $names) {
        $stream = [IO.File]::Create((Join-Path $path $name))
        $stream.Dispose()
    }
}

function Complete-AtlasInstallState {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$RequiredSteps = @(),
        [Parameter(Mandatory = $true)][string]$FlagsPath,
        [string]$StatePath,
        [string]$StateDocumentPath,

        # What the PC has for each install choice now the plan has run
        # (Get-AtlasRecordedOption). The flags and the state document record it, so
        # neither names a choice that wasn't applied; last.json keeps the request
        # beside it. Without it, the request is recorded.
        [string[]]$RecordedOptions,

        # The options of each choice the plan tried to apply that the PC doesn't have
        # as requested (Get-AtlasRecordedOption), for the state document's record of
        # this install, which Atlas Manager names when it says the install finished.
        # Without it, that record says nothing of them.
        [string[]]$NotApplied
    )

    foreach ($requiredStep in $RequiredSteps) {
        Assert-AtlasInstallName -Value $requiredStep -Label 'required step name'
    }
    foreach ($set in @($RecordedOptions, $NotApplied)) {
        foreach ($option in @($set | Where-Object { $null -ne $_ })) {
            Assert-AtlasInstallName -Value $option -Label 'option name'
        }
    }

    $installFlagsPath = $FlagsPath
    $recordedSet = $RecordedOptions
    $notAppliedSet = $NotApplied
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $state = Get-AtlasInstallStateUnlocked -StatePath $resolvedPath
        if ($null -eq $state) {
            throw 'No Atlas install state is active.'
        }
        if ($state.status -ne 'Running') {
            throw "Install state cannot be completed from '$($state.status)'."
        }

        $missingSteps = @()
        foreach ($requiredStep in $RequiredSteps) {
            if (@($state.completedSteps) -inotcontains $requiredStep) {
                $missingSteps += $requiredStep
            }
        }
        if ($missingSteps.Count -gt 0) {
            throw "Install state is missing required steps: $($missingSteps -join ', ')."
        }

        # The state document is what post-install tools read; the flag set remains
        # only for machines and tools that predate it.
        Publish-AtlasInstallFlagSet -State $state -FlagsPath $installFlagsPath -Options $recordedSet
        $documentPath = $StateDocumentPath
        if ([string]::IsNullOrWhiteSpace($documentPath)) {
            # state.json lives in AtlasOS, one level above Install\active.json.
            $documentPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $resolvedPath -Parent) -Parent) -ChildPath 'state.json'
        }
        $null = Set-AtlasStateInstall -InstallState $state -Path $documentPath -Options $recordedSet -NotApplied $notAppliedSet
        $state.status = 'Completed'
        $state.lastError = $null
        if ($null -ne $recordedSet) {
            $state | Add-Member -NotePropertyName recordedOptions -NotePropertyValue @($recordedSet) -Force
        }
        $directory = [IO.Path]::GetDirectoryName($resolvedPath)
        $lastPath = Join-Path -Path $directory -ChildPath 'last.json'
        Write-AtlasInstallStateFile -Path $lastPath -State $state

        $workRoot = Join-Path -Path $directory -ChildPath 'work'
        if ([IO.Directory]::Exists($workRoot)) {
            [IO.Directory]::Delete($workRoot, $true)
        }
        if ([IO.File]::Exists("$resolvedPath.bak")) {
            [IO.File]::Delete("$resolvedPath.bak")
        }
        if ([IO.File]::Exists($resolvedPath)) {
            [IO.File]::Delete($resolvedPath)
        }
        return $state
    }
}

function Get-AtlasPlaybookDocument {
    <#
    .SYNOPSIS
        Loads playbook.conf from an explicit path or from the package this module is part of.
    #>
    param([string]$PlaybookPath)

    if ([string]::IsNullOrWhiteSpace($PlaybookPath)) {
        # Modules\Atlas.InstallState -> Modules -> Scripts -> AtlasModules -> Executables -> playbook
        $PlaybookPath = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\playbook.conf'))
    }
    if (-not [IO.File]::Exists($PlaybookPath)) {
        throw "Atlas playbook.conf was not found at '$PlaybookPath'."
    }
    [xml]$playbook = [IO.File]::ReadAllText($PlaybookPath)
    return $playbook.Playbook
}

function Get-AtlasPlaybookVersion {
    <#
    .SYNOPSIS
        Returns the package's own version, validated as a semantic version string.
    #>
    param([string]$PlaybookPath)

    $version = [string](Get-AtlasPlaybookDocument -PlaybookPath $PlaybookPath).Version
    if ($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
        throw "Atlas target version '$version' is invalid."
    }
    return $version
}

function Get-AtlasPlaybookOption {
    <#
    .SYNOPSIS
        Returns the FeaturePage option groups declared by playbook.conf: each group's
        option names, whether exactly one must be chosen, and the default.
    #>
    param([string]$PlaybookPath)

    $document = Get-AtlasPlaybookDocument -PlaybookPath $PlaybookPath
    $groups = @()
    foreach ($page in @($document.FeaturePages.ChildNodes | Where-Object { $_.NodeType -eq 'Element' })) {
        $names = @($page.SelectNodes('Options/*/Name') | ForEach-Object { [string]$_.InnerText })
        $isRadio = $page.LocalName -like 'Radio*'
        $default = if ($null -ne $page.Attributes['DefaultOption']) { [string]$page.Attributes['DefaultOption'].Value } else { $null }
        $dependsOn = if ($null -ne $page.Attributes['DependsOn']) { [string]$page.Attributes['DependsOn'].Value } else { $null }
        $groups += [pscustomobject][ordered]@{
            Page       = [string]$page.LocalName
            Options    = $names
            ExactlyOne = $isRadio
            Default    = $default
            DependsOn  = $dependsOn
        }
    }
    return $groups
}

function Get-AtlasPlaybookSupportedBuild {
    <#
    .SYNOPSIS
        Returns the Windows build numbers playbook.conf declares as supported.
    #>
    param([string]$PlaybookPath)

    $document = Get-AtlasPlaybookDocument -PlaybookPath $PlaybookPath
    return @($document.SupportedBuilds.string | ForEach-Object { [int]$_ })
}

function Get-AtlasInstalledVersion {
    <#
    .SYNOPSIS
        The Atlas version on this PC: the machine state document's, else the one the
        legacy OEM version markers name, else, after Windows rebuilt itself while
        Atlas Manager moved it, the one that move's record kept. $null when nothing
        names one.
    .PARAMETER Rebase
        That move's record (Get-AtlasWindowsTransitionRebase), when the caller has
        read it already.
    #>
    param(
        [string]$WindowsPath,
        [AllowNull()]$Rebase
    )

    if ([string]::IsNullOrWhiteSpace($WindowsPath)) {
        $WindowsPath = [Environment]::GetFolderPath('Windows')
    }
    if (-not $PSBoundParameters.ContainsKey('Rebase')) {
        $Rebase = Get-AtlasWindowsTransitionRebase
    }
    $document = Get-AtlasState -Path (Join-Path -Path $WindowsPath -ChildPath 'AtlasOS\state.json')
    $installedVersion = if ($null -ne $document) { [string]$document.installedVersion } else { '' }
    if ([string]::IsNullOrWhiteSpace($installedVersion)) {
        $legacyVersions = @(foreach ($marker in @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'; Name = 'Model' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; Name = 'RegisteredOrganization' }
            )) {
            $value = Get-ItemProperty -LiteralPath $marker.Path -Name $marker.Name -ErrorAction SilentlyContinue
            if ($null -ne $value -and [string]$value.($marker.Name) -match '^Atlas Playbook v?(\d+\.\d+\.\d+)$') {
                $Matches[1]
            }
        }) | Sort-Object -Unique
        if (@($legacyVersions).Count -gt 1) { throw 'Installed Atlas version markers disagree.' }
        if (@($legacyVersions).Count -eq 1) { $installedVersion = [string]@($legacyVersions)[0] }
    }
    if ([string]::IsNullOrWhiteSpace($installedVersion) -and $null -ne $Rebase) {
        $installedVersion = [string]$Rebase.AtlasVersion
    }
    if ([string]::IsNullOrWhiteSpace($installedVersion)) {
        return $null
    }
    return $installedVersion
}

function Resolve-AtlasInstallMode {
    <#
    .SYNOPSIS
        Decides whether an install of the target version is Fresh, an Upgrade, or a
        Reapply of the same version, from active install state, the machine state
        document or legacy OEM version markers. Upgrades must be declared in playbook.conf.
        Rebase puts an installed Atlas back on a Windows that rebuilt itself while
        Atlas Manager moved it to a newer release; the version can then come from
        that move's record when the markers are gone.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$TargetVersion,
        [string]$WindowsPath,
        [string]$PlaybookPath
    )

    if ([string]::IsNullOrWhiteSpace($WindowsPath)) {
        $WindowsPath = [Environment]::GetFolderPath('Windows')
    }
    $active = Get-AtlasInstallState -StatePath (Join-Path $WindowsPath 'AtlasOS\Install\active.json')
    if ($null -ne $active) {
        if ([string]$active.targetVersion -cne $TargetVersion) {
            throw "An install state for target '$($active.targetVersion)' is already active."
        }
        # An interrupted Fresh run can already have copied Atlas's files without
        # publishing a version. Its saved transaction retains the original mode.
        return [string]$active.mode
    }
    $rebase = Get-AtlasWindowsTransitionRebase
    $installedVersion = Get-AtlasInstalledVersion -WindowsPath $WindowsPath -Rebase $rebase
    if ($null -ne $installedVersion) {
        if ($installedVersion -ceq $TargetVersion) {
            if ($null -ne $rebase) { return 'Rebase' }
            return 'Reapply'
        }
        $playbook = Get-AtlasPlaybookDocument -PlaybookPath $PlaybookPath
        if (@($playbook.UpgradableFrom.string) -cnotcontains $installedVersion) {
            throw "Atlas $installedVersion is not a declared upgrade source for $TargetVersion. A fresh Windows installation is required."
        }
        if ($null -ne $rebase) { return 'Rebase' }
        return 'Upgrade'
    }

    # Atlas files without a version are not evidence of a supported upgrade source.
    if ([IO.Directory]::Exists((Join-Path -Path $WindowsPath -ChildPath 'AtlasModules\Scripts'))) {
        throw 'Atlas files exist but their installed version could not be established. A supported upgrade source is required.'
    }
    return 'Fresh'
}

function Resolve-AtlasInstallChoices {
    <#
    .SYNOPSIS
        How an install of this mode treats the choices the PC has: Keep, or
        ChooseAgain when the request asked for it. An unfinished install keeps the
        way it began, because the steps it finished won't run again. A first
        installation applies every choice, so it keeps. A Rebase first puts back
        the choices the PC had before Windows rebuilt itself, so it refuses to
        choose again.
    .OUTPUTS
        Choices, the way to store; Summary, the mode and that way in words; Note,
        why it isn't the way requested, or $null; and ResumedOptions, the options
        an unfinished install began with, which its resume must give as
        Set-AtlasInstallOptions requires, or $null when nothing holds this one.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$TargetVersion,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Fresh', 'Upgrade', 'Reapply', 'Rebase')]
        [string]$Mode,
        [ValidateSet('Keep', 'ChooseAgain')]
        [string]$Requested = 'Keep',
        [string]$StatePath
    )

    $describe = {
        param([string]$Choices)
        if ($Mode -ceq 'Fresh') { return $Mode }
        if ($Choices -ceq 'ChooseAgain') { return "$Mode, choosing again" }
        return "$Mode, keeping your choices"
    }
    $choices = $Requested
    $note = $null
    $active = Get-AtlasInstallState -StatePath $StatePath
    $held = $null -ne $active -and [string]$active.targetVersion -ceq $TargetVersion -and
        ([string]$active.status -ceq 'Running' -or @($active.completedSteps).Count -gt 0)
    $resumed = $null
    if ($held) { $resumed = @($active.options | ForEach-Object { [string]$_ }) }
    if ($Mode -ceq 'Fresh') {
        $choices = 'Keep'
        if ($Requested -ceq 'ChooseAgain') {
            $note = 'A first installation applies every choice, so -ChooseAgain changes nothing.'
        }
    }
    elseif ($held) {
        $stored = $active.PSObject.Properties['choices']
        $choices = if ($null -ne $stored) { [string]$stored.Value } else { 'Keep' }
        if ($choices -cne $Requested) {
            $way = if ($choices -ceq 'ChooseAgain') { 'choosing again' } else { 'keeping your choices' }
            $note = "Continuing the unfinished installation as it began, $way; its choices can't change now."
        }
    }
    elseif ($Mode -ceq 'Rebase' -and $Requested -ceq 'ChooseAgain') {
        throw ('Windows reinstalled itself while Atlas Manager moved it to a newer version, so this installation first ' +
            'puts back the choices you had. Run it again without -ChooseAgain; once it has finished, you can reinstall ' +
            'Atlas and choose again.')
    }
    return [pscustomobject]@{ Choices = $choices; Summary = (& $describe $choices); Note = $note; ResumedOptions = $resumed }
}

# What Atlas Manager calls each choice the PC can show (the groups of
# Get-AtlasTransitionChoiceGroup), for the lines that say which choices were taken
# from the PC instead of the request.
$script:AtlasChoiceLabels = @{
    defender      = 'Microsoft Defender'
    mitigations   = 'Processor protections'
    autoUpdates   = 'Windows Update'
    hibernation   = 'Turn off hibernation'
    powerSaving   = 'Turn off power saving'
    edge          = 'Remove Microsoft Edge'
    snippingTool  = 'Remove Snipping Tool'
    coreIsolation = 'Turn off virtualisation-based security (VBS)'
    toolbox       = 'Install Atlas Toolbox'
    browser       = 'Browser'
    keyboard      = 'Keyboard languages'
}

function Compare-AtlasInstallOption {
    <#
    .SYNOPSIS
        The install choices whose options differ between two sets, one for each
        choice the PC can show: its Group, its Label as Atlas Manager names it, and
        the options each set has for it, Requested and Options.
    #>
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Requested = @(),
        [AllowEmptyCollection()][string[]]$Recorded = @()
    )

    $groups = Get-AtlasTransitionChoiceGroup
    foreach ($name in $groups.Keys) {
        $patterns = @($groups[$name])
        $inGroup = {
            param([string[]]$Options)
            @($Options | Where-Object { $option = $_; @($patterns | Where-Object { $option -like $_ }).Count -gt 0 } | Sort-Object)
        }
        $before = @(& $inGroup $Requested)
        $after = @(& $inGroup $Recorded)
        if (($before -join ',') -cne ($after -join ',')) {
            [pscustomobject]@{ Group = $name; Label = $script:AtlasChoiceLabels[$name]; Requested = $before; Options = $after }
        }
    }
}

function Get-AtlasObservedOptionReason {
    # What the PC shows for one choice, worded for the line that says why its options
    # were taken from the PC. It follows the evidence Get-AtlasTransitionChoiceEvidence reads.
    param([string]$Group, $Facts, [string[]]$AtlasPackages = @(), [string[]]$Options = @())

    $record = {
        param([string]$Name)
        $found = @(Get-AtlasTransitionFactValue $Facts 'Toggles' | Where-Object { $null -ne $_ -and [string]$_.name -ceq $Name })
        if ($found.Count -gt 0) { return "the $Name toggle records state $([int64]$found[0].state)" }
        return $null
    }
    $has = { param([string]$Option) @($Options) -ccontains $Option }
    switch ($Group) {
        'defender' {
            $package = [string](Get-AtlasTransitionFactValue $Facts 'DefenderPackage')
            if (& $has 'defender-disable') {
                if ($package -ceq 'InstallPending') { return "Atlas's NoDefender package goes on at the restart" }
                return "Atlas's NoDefender package is installed"
            }
            if ($package -ceq 'UninstallPending') { return "Atlas's NoDefender package comes off at the restart" }
            if ($true -eq (Get-AtlasTransitionFactValue $Facts 'Defender')) { return 'Microsoft Defender is on this PC' }
            return "Atlas's packages are installed, and none of them removes Microsoft Defender"
        }
        'mitigations' { return & $record 'Mitigations' }
        'autoUpdates' { return & $record 'AutomaticUpdates' }
        'hibernation' { return & $record 'Hibernation' }
        'powerSaving' { return & $record 'PowerSaving' }
        'edge' { if (& $has 'uninstall-edge') { return "Microsoft Edge isn't installed" }; return 'Microsoft Edge is installed' }
        'snippingTool' { if (& $has 'remove-snipping-tool') { return 'no account has Snipping Tool' }; return 'Snipping Tool is installed' }
        'coreIsolation' { if (& $has 'disable-core-isolation') { return 'VBS is off' }; return 'VBS is on' }
        'toolbox' { if (& $has 'install-toolbox') { return 'Atlas Toolbox is installed' }; return "Atlas Toolbox isn't installed" }
        'browser' {
            $browser = @($Options | Where-Object { $_ -like 'browser-*' })
            if ($browser.Count -eq 0) { return "the chosen browser isn't installed" }
            if (@(Get-AtlasTransitionFactValue $Facts 'Browsers') -ccontains $browser[0]) { return "$($browser[0]) is installed" }
            return "Atlas's taskbar pin record names $(Get-AtlasTransitionFactValue $Facts 'Browser')"
        }
        'keyboard' {
            $shortcuts = & $record 'KeyboardShortcuts'
            if ($shortcuts) { return $shortcuts }
            if ([string](Get-AtlasTransitionFactValue $Facts 'LanguageHotkey') -ceq '3') { return "Alt+Shift doesn't switch keyboard languages" }
            return 'Alt+Shift switches keyboard languages'
        }
    }
    return $null
}

function Format-AtlasOptionChange {
    # The line for one choice taken from the PC instead of the request: -Kept at
    # Capture, which keeps the PC's choices, otherwise at completion, which records them.
    param([Parameter(Mandatory = $true)]$Change, [switch]$Kept)

    $quote = { param([string[]]$Names) "'" + ($Names -join "', '") + "'" }
    $taken = @($Change.Options)
    $asked = @($Change.Requested)
    $verb = if ($Kept) { 'Kept' } else { 'Recorded' }
    $line = if ($taken.Count -gt 0 -and $asked.Count -gt 0) {
        "$verb $(& $quote $taken) for $($Change.Label) instead of the requested $(& $quote $asked)"
    }
    elseif ($taken.Count -gt 0) {
        "$verb $(& $quote $taken) for $($Change.Label), which the request left out"
    }
    else {
        "$(if ($Kept) { 'Left out' } else { "Didn't record" }) the requested $(& $quote $asked) for $($Change.Label)"
    }
    if ($Change.Reason) { $line += ": $($Change.Reason)" }
    $line += '.'
    if ($Kept) { $line += ' Run again with -ChooseAgain to change it.' }
    return $line
}

function Get-AtlasObservedOptionChange {
    param(
        [AllowEmptyCollection()][string[]]$Requested = @(),
        [AllowEmptyCollection()][string[]]$Options = @(),
        $Facts,
        [AllowEmptyCollection()][string[]]$AtlasPackages = @(),
        [switch]$Kept
    )

    foreach ($change in @(Compare-AtlasInstallOption -Requested $Requested -Recorded $Options)) {
        $reason = Get-AtlasObservedOptionReason -Group $change.Group -Facts $Facts -AtlasPackages $AtlasPackages -Options $change.Options
        $change | Add-Member -NotePropertyName Reason -NotePropertyValue $reason
        $change | Add-Member -NotePropertyName Message -NotePropertyValue (Format-AtlasOptionChange -Change $change -Kept:$Kept)
        $change
    }
}

function Get-AtlasAttemptedChoiceGroup {
    <#
    .SYNOPSIS
        The install choices (the groups of Get-AtlasTransitionChoiceGroup) an install's
        plan tries to apply, from its mode, its update path and its options. A first
        installation and a Rebase apply every answer and every ticked box. An update
        that chooses again does too, and its Choices step also undoes Atlas's own answer
        to a box left clear, except for an app it can't put back. One that keeps the
        choices took them from the PC at Capture, so it only installs a ticked Toolbox
        or browser, as every install does; none uninstalls them.
    #>
    param(
        [string]$Mode,
        [string]$Choices = 'Keep',
        [AllowEmptyCollection()][string[]]$Options = @()
    )

    $groups = Get-AtlasTransitionChoiceGroup
    $choosingAgain = $Choices -ceq 'ChooseAgain' -and $Mode -cin @('Upgrade', 'Reapply')
    $applies = $choosingAgain -or $Mode -cin @('Fresh', 'Rebase')
    foreach ($name in $groups.Keys) {
        $patterns = @($groups[$name])
        $ticked = @($Options | Where-Object { $option = $_; @($patterns | Where-Object { $option -like $_ }).Count -gt 0 }).Count -gt 0
        if ($name -cin @('toolbox', 'browser')) {
            if ($ticked) { $name }
        }
        elseif ($applies -and ($ticked -or $name -cin @('defender', 'mitigations', 'autoUpdates', 'keyboard') -or
                ($choosingAgain -and $name -cin @('hibernation', 'powerSaving', 'coreIsolation')))) {
            $name
        }
    }
}

function Resolve-AtlasKeptOption {
    <#
    .SYNOPSIS
        The options an update that keeps the choices installs with: the request, with
        each choice the PC shows taken from the PC, so the record can't name a choice
        this PC doesn't have. Capture has no installing user yet and little time, so
        only machine evidence counts: Atlas's packages, the Defender service, the
        toggle records, the VBS settings, Edge, the Toolbox and the browsers. No app
        list and no account's keyboard settings are read, so Snipping Tool, the
        language hotkey and eclean keep the request.
    .OUTPUTS
        Options; Changes, one for each choice taken from the PC, with its Group,
        Label, Requested, Options, Reason and log Message; and Warnings.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Requested)

    try {
        $facts = Get-AtlasTransitionMachineFact -MachineOnly
        $packages = @(Get-AtlasInstalledAtlasPackage)
    }
    catch {
        return [pscustomobject]@{
            Options  = @($Requested)
            Changes  = @()
            Warnings = @("Couldn't read what this PC shows, so the requested choices are kept: $($_.Exception.Message)")
        }
    }
    $options = @(Merge-AtlasObservedOption $Requested $facts $packages)
    return [pscustomobject]@{
        Options  = $options
        Changes  = @(Get-AtlasObservedOptionChange -Requested $Requested -Options $options -Facts $facts -AtlasPackages $packages -Kept)
        Warnings = @()
    }
}

function Get-AtlasRecordedOption {
    <#
    .SYNOPSIS
        The options a completed install records: its request, with each choice the PC
        shows taken from the PC, read once the plan has run, so a choice that wasn't
        applied is never recorded. The installing user's keyboard settings and the
        apps installed for every account count. A Defender package Windows adds or
        takes off at the restart this install asks for already counts. A reader that
        fails leaves the request for the choices it shows, with a warning.
    .OUTPUTS
        Options; Changes (as Resolve-AtlasKeptOption gives them); NotApplied, the
        options that differ of each choice the plan tried to apply
        (Get-AtlasAttemptedChoiceGroup) and the PC doesn't have as requested, so a
        choice recorded otherwise only because nothing in the plan changes it, such
        as VBS already off on a first installation that left the box clear, isn't
        among them, or $null when nothing on the PC could be read; and Warnings.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$State)

    $requested = @($State.options | ForEach-Object { [string]$_ })
    $userSid = [string]$State.userSid
    # An install state written before the update path existed keeps the choices.
    $plan = @{ Options = $requested }
    foreach ($field in @('mode', 'choices')) {
        $property = $State.PSObject.Properties[$field]
        if ($null -ne $property -and $null -ne $property.Value) { $plan[$field] = [string]$property.Value }
    }
    $attempted = @(Get-AtlasAttemptedChoiceGroup @plan)
    $warnings = @()
    try {
        $packages = @(Get-AtlasInstalledAtlasPackage)
        $facts = Get-AtlasTransitionMachineFact -UserSid $userSid
        # An install during Windows setup has no user, and this process's own
        # keyboard settings are nobody's choice.
        if (-not $userSid) {
            $facts.LanguageHotkey = $null
            $facts.KeyboardLayouts = $null
        }
        # Windows always has apps, so an empty list means they couldn't be listed.
        if (@($facts.Appx).Count -eq 0) {
            $warnings += "Couldn't list this PC's apps, so the requested choice is recorded for $($script:AtlasChoiceLabels['snippingTool'])."
        }
    }
    catch {
        $failure = $_.Exception.Message
        try {
            $packages = @(Get-AtlasInstalledAtlasPackage)
            $facts = Get-AtlasTransitionMachineFact -MachineOnly
            $warnings += ("Couldn't read what this PC shows for $($script:AtlasChoiceLabels['keyboard']) and " +
                "$($script:AtlasChoiceLabels['snippingTool']), so the requested choices are recorded: $failure")
        }
        catch {
            # Nothing read says what took effect, so this install's record says
            # nothing of it either.
            return [pscustomobject]@{
                Options    = $requested
                Changes    = @()
                NotApplied = $null
                Warnings   = @("Couldn't read what this PC shows, so the requested choices are recorded: $($_.Exception.Message)")
            }
        }
    }
    $options = @(Merge-AtlasObservedOption $requested $facts $packages -AfterInstall)
    $changes = @(Get-AtlasObservedOptionChange -Requested $requested -Options $options -Facts $facts -AtlasPackages $packages)
    $notApplied = foreach ($change in @($changes | Where-Object { $attempted -ccontains $_.Group })) {
        foreach ($option in @($change.Requested) + @($change.Options)) {
            if (@($change.Requested) -cnotcontains $option -or @($change.Options) -cnotcontains $option) { $option }
        }
    }
    return [pscustomobject]@{
        Options    = $options
        Changes    = $changes
        NotApplied = @($notApplied | Sort-Object -Unique)
        Warnings   = $warnings
    }
}

# Atlas Toolbox 0.1.x and the Atlas 0.5.0 launchers both wrote choices under
# HKLM\SOFTWARE\AtlasOS\Services, not always as Atlas 0.6 reads them. A launcher
# always wrote its file name as 'path' beside the state; the Toolbox's
# multi-option pages never did, and they merged their choice from a folder no
# Atlas install has, so it never reached the PC, and wrote a value of their own
# when the Toolbox started without one. A few Toolbox records also use a name
# 0.6 spells differently.

function Get-AtlasToolboxServiceStart {
    param([string]$ServicesRoot, [string]$Name)

    $service = Get-ItemProperty -LiteralPath (Join-Path -Path $ServicesRoot -ChildPath $Name) -Name Start -ErrorAction SilentlyContinue
    if ($null -eq $service) { return $null }
    return [int]$service.Start
}

function Get-AtlasBcdHighestMode {
    # 1 when {globalsettings} has highestmode on, 0 without it, $null when it can't
    # be read. Element names read the same in every language; a yes or no worded in
    # another one leaves the value unread.
    $bcdEdit = [IO.Path]::Combine([Environment]::SystemDirectory, 'bcdedit.exe')
    $output = @(& $bcdEdit /enum '{globalsettings}' 2>$null)
    if ($LASTEXITCODE -ne 0) { return $null }
    foreach ($line in $output) {
        if ([string]$line -match '^\s*highestmode\s+(\S+)\s*$') {
            if ($Matches[1] -match '^(?i:yes|true|on)$') { return 1 }
            if ($Matches[1] -match '^(?i:no|false|off)$') { return 0 }
            return $null
        }
    }
    return 0
}

function Get-AtlasLoadedUserDword {
    # A DWORD every signed-in account's loaded hive that has it agrees on, or $null.
    # Capture has no installing user yet, so no one account's value may decide.
    param([Parameter(Mandatory = $true)][string]$SubKey, [Parameter(Mandatory = $true)][string]$Name)

    $users = [Microsoft.Win32.Registry]::Users
    $values = @(foreach ($sid in @($users.GetSubKeyNames() | Where-Object { $_ -match '^S-1-5-21-(?:\d+-){3}\d+$' })) {
            $key = $users.OpenSubKey("$sid\$SubKey", $false)
            if ($null -eq $key) { continue }
            try {
                if (@($key.GetValueNames()) -contains $Name -and $key.GetValueKind($Name) -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
                    [int]$key.GetValue($Name)
                }
            }
            finally { $key.Dispose() }
        }) | Sort-Object -Unique
    if (@($values).Count -eq 1) { return [int]@($values)[0] }
    return $null
}

function Set-AtlasToolboxRecordState {
    param([string]$StateRoot, [string]$Name, [int]$State)

    $keyPath = Join-Path -Path $StateRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $keyPath)) {
        New-Item -Path $keyPath -Force -ErrorAction Stop | Out-Null
    }
    New-ItemProperty -LiteralPath $keyPath -Name 'state' -Value $State -PropertyType DWord -Force -ErrorAction Stop | Out-Null
}

function Remove-AtlasToolboxRecord {
    # The state and its launcher path go; the key too, once nothing else is in it.
    param([string]$KeyPath)

    $key = Get-Item -LiteralPath $KeyPath -ErrorAction Stop
    foreach ($name in @('state', 'path')) {
        if (@($key.GetValueNames()) -contains $name) {
            Remove-ItemProperty -LiteralPath $KeyPath -Name $name -Force -ErrorAction Stop
        }
    }
    $key = Get-Item -LiteralPath $KeyPath -ErrorAction Stop
    if (@($key.GetValueNames()).Count -eq 0 -and $key.SubKeyCount -eq 0) {
        Remove-Item -LiteralPath $KeyPath -Force -ErrorAction Stop
    }
}

function Repair-AtlasToolboxRecord {
    <#
    .SYNOPSIS
        Turns the toggle records an Atlas older than 0.6, and the Atlas Toolbox
        beside it, left into what Atlas 0.6 means by them, and removes the ones that
        hold no choice this PC has, before anything reads the records. On 0.6
        and later, only an active Atlas power plan can repair its stale record.
    .PARAMETER InstalledVersion
        The Atlas version the update starts from (Get-AtlasInstalledVersion).
    .OUTPUTS
        One line for each record changed, for the install log.
    #>
    [CmdletBinding()]
    param(
        [string]$InstalledVersion,
        [string]$StateRoot = 'HKLM:\SOFTWARE\AtlasOS\Services',
        [string]$ClassesRoot = 'HKLM:\SOFTWARE\Classes',
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services',
        [string]$PowerSchemesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes'
    )

    # This also affects early 0.6 candidates: replaying a stale Enable record
    # removes the active Atlas plan. Repair it before options are captured or any
    # toggle is replayed. Never infer a default from a custom or unreadable plan.
    $active = Get-ItemProperty -LiteralPath $PowerSchemesRoot -Name ActivePowerScheme -ErrorAction SilentlyContinue
    if ($null -ne $active -and [string]$active.ActivePowerScheme -ieq '11111111-1111-1111-1111-111111111111') {
        $powerKey = Join-Path $StateRoot 'PowerSaving'
        $power = Get-ItemProperty -LiteralPath $powerKey -Name state -ErrorAction SilentlyContinue
        if ($null -eq $power -or $power.state -ne 0) {
            Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name PowerSaving -State 0
            "Set the 'PowerSaving' record to 0: the Atlas power plan is active."
        }
    }
    if (-not (Test-AtlasVersionBefore06 $InstalledVersion)) {
        return
    }
    if (-not (Test-Path -LiteralPath $StateRoot)) {
        return
    }
    # Keyed without regard to case, as the registry names them.
    $records = @{}
    foreach ($key in @(Get-ChildItem -LiteralPath $StateRoot -ErrorAction Stop)) {
        $names = @($key.GetValueNames())
        $path = if ($names -contains 'path') { $key.GetValue('path', $null) } else { $null }
        $records[[string]$key.PSChildName] = [pscustomobject]@{
            Name    = [string]$key.PSChildName
            KeyPath = [string]$key.PSPath
            State   = if ($names -contains 'state' -and $key.GetValueKind('state') -eq [Microsoft.Win32.RegistryValueKind]::DWord) { [int]$key.GetValue('state') } else { $null }
            File    = if ($path -is [string]) { ($path -split '[\\/]')[-1] } else { $null }
        }
    }
    $record = { param([string]$Name) if ($records.ContainsKey($Name) -and $null -ne $records[$Name].State) { $records[$Name] } }
    $neverApplied = "only the old Atlas Toolbox wrote it, and its choices never reached this PC"

    # A launcher's file name says which choice it applied, whatever the Toolbox
    # wrote over its state since. Without one, only the Toolbox wrote the record,
    # in its own numbering: it goes, and the PC stays as it is. Never translate it.
    # The record of a Windows move reads the records by the same table.
    foreach ($rule in @(Get-AtlasToolboxLauncherRule)) {
        $found = & $record $rule.Name
        if ($null -eq $found) { continue }
        if ($null -eq $found.File) {
            Remove-AtlasToolboxRecord -KeyPath $found.KeyPath
            "Removed the '$($found.Name)' record (state $($found.State)): $neverApplied."
        }
        elseif ($rule.Launchers.ContainsKey($found.File) -and $rule.Launchers[$found.File] -ne $found.State) {
            Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name $found.Name -State $rule.Launchers[$found.File]
            "Set the '$($found.Name)' record from $($found.State) to $($rule.Launchers[$found.File]), the choice its launcher '$($found.File)' applied."
        }
    }

    # The Toolbox numbers the terminal menu's choices differently, so a record it
    # wrote alone takes the menu this PC has. One with a launcher's path is
    # corrected later, from the same menu, by the legacy choices step. Both read
    # it as Get-AtlasLegacyToggleObservedState (Atlas.Toggles) does, so keep the
    # two in step.
    $terminals = & $record 'ContextMenuTerminals'
    if ($null -ne $terminals -and $null -eq $terminals.File) {
        $menu = Join-Path -Path $ClassesRoot -ChildPath 'Directory\shell\AtlasTerminals'
        $observed = $null
        try {
            if (-not (Test-Path -LiteralPath $menu)) { $observed = 0 }
            else {
                # Opened, because Test-Path also finds a key it can't read.
                $menuKey = Get-Item -LiteralPath $menu -ErrorAction Stop
                try {
                    $terminal = $menuKey.OpenSubKey('shell\Item1', $false)
                    if ($null -ne $terminal) { $terminal.Dispose(); $observed = 1 }
                    else { $observed = 2 }
                }
                finally { $menuKey.Dispose() }
            }
        }
        catch { $observed = $null }
        if ($null -eq $observed) {
            Remove-AtlasToolboxRecord -KeyPath $terminals.KeyPath
            "Removed the 'ContextMenuTerminals' record (state $($terminals.State)): only the old Atlas Toolbox wrote it, in its own numbering, and the terminal menu this PC has couldn't be read."
        }
        elseif ($observed -ne $terminals.State) {
            Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name $terminals.Name -State $observed
            "Set the 'ContextMenuTerminals' record from $($terminals.State) to $observed, the terminal menu this PC has: the old Atlas Toolbox numbered it differently."
        }
    }

    # The Toolbox's Enable File Sharing wrote 0, the same as Disable, and neither
    # ever ran; replaying it would turn off the file sharing that was asked for.
    $fileSharing = & $record 'FileSharing'
    if ($null -ne $fileSharing -and $fileSharing.State -eq 0 -and $fileSharing.File -ceq 'Enable File Sharing.cmd') {
        Remove-AtlasToolboxRecord -KeyPath $fileSharing.KeyPath
        "Removed the 'FileSharing' record (state 0): the old Atlas Toolbox wrote it for Enable File Sharing, and never changed this PC."
    }

    # Every Atlas 0.5.0 install recorded Printing 0 when it only took the print verbs
    # off the context menu. Only a Print Spooler that is off shows a full Disable.
    $printing = & $record 'Printing'
    if ($null -ne $printing -and $printing.State -eq 0 -and $printing.File -ceq 'Disable Printing.cmd' -and
        (Get-AtlasToolboxServiceStart -ServicesRoot $ServicesRoot -Name 'Spooler') -ne 4) {
        Remove-AtlasToolboxRecord -KeyPath $printing.KeyPath
        "Removed the 'Printing' record (state 0): the Print Spooler is on, so it only took printing off the context menu."
    }

    # The Toolbox's search indexing record contradicts its own labels, so only a
    # search service it turned off counts, and its raw value is never copied.
    $searchIndexing = $records['SearchIndexing']
    if ($null -ne $searchIndexing) {
        if ($searchIndexing.State -eq 1 -and (Get-AtlasToolboxServiceStart -ServicesRoot $ServicesRoot -Name 'WSearch') -eq 4) {
            Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name 'Indexing' -State 0
            "Set the 'Indexing' record to 0: the old Atlas Toolbox turned search indexing off."
        }
        Remove-Item -LiteralPath $searchIndexing.KeyPath -Recurse -Force -ErrorAction Stop
        "Removed the old Atlas Toolbox's 'SearchIndexing' record."
    }

    # Records the Toolbox kept under a name Atlas 0.6 spells otherwise. Both writers
    # applied these, so with both records the PC shows which ran last.
    foreach ($rule in @(
            @{ From = 'AppIconsThumbnail'; To = 'AppIconThumbnail'; Live = { Get-AtlasLoadedUserDword -SubKey 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTypeOverlay' } }
            @{ From = 'HightestMode'; To = 'HighestMode'; Live = { Get-AtlasBcdHighestMode } }
        )) {
        $from = $records[$rule.From]
        if ($null -eq $from) { continue }
        $to = & $record $rule.To
        if ($from.State -in @(0, 1)) {
            $state = $from.State
            if ($null -ne $to -and $to.State -ne $from.State) {
                $state = & $rule.Live
                if ($state -notin @(0, 1)) { $state = $to.State }
            }
            if ($null -eq $to -or $to.State -ne $state) {
                Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name $rule.To -State $state
                "Set the '$($rule.To)' record to $state from the old Atlas Toolbox's '$($rule.From)'."
            }
        }
        Remove-Item -LiteralPath $from.KeyPath -Recurse -Force -ErrorAction Stop
        "Removed the old Atlas Toolbox's '$($rule.From)' record."
    }

    # Registry names ignore case, but Atlas 0.6 matches its definitions' names
    # exactly, so a record named in other letter case would be removed as stale.
    # The key can only take the exact name by being made again.
    $recall = $records['Recall']
    if ($null -ne $recall -and $recall.Name -cne 'Recall') {
        Remove-Item -LiteralPath $recall.KeyPath -Recurse -Force -ErrorAction Stop
        if ($null -ne $recall.State) {
            Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name 'Recall' -State $recall.State
            "Renamed the old Atlas Toolbox's '$($recall.Name)' record to 'Recall'."
        }
        else { "Removed the old Atlas Toolbox's '$($recall.Name)' record." }
    }

    # The Toolbox's CPU Idle menu is its own key, whose commands run powercfg
    # directly. It goes, and a record lets the update add Atlas's menu instead.
    $idleMenu = Join-Path -Path $ClassesRoot -ChildPath 'DesktopBackground\Shell\Idle'
    $idleVerb = Get-ItemProperty -LiteralPath $idleMenu -Name MUIVerb -ErrorAction SilentlyContinue
    $toolboxMenu = $null -ne $idleVerb -and [string]$idleVerb.MUIVerb -ceq 'CPU Idle'
    $idle = $records['CpuIdleContextMenu']
    $atlasIdle = $null -ne $idle -and $idle.Name -ceq 'CpuIdleContextMenu' -and $null -ne $idle.State
    if ($toolboxMenu) {
        Remove-Item -LiteralPath $idleMenu -Recurse -Force -ErrorAction Stop
        "Removed the old Atlas Toolbox's CPU Idle desktop menu."
    }
    if ($null -ne $idle -and $idle.Name -cne 'CpuIdleContextMenu') {
        Remove-Item -LiteralPath $idle.KeyPath -Recurse -Force -ErrorAction Stop
        "Removed the old Atlas Toolbox's '$($idle.Name)' record."
    }
    if ($toolboxMenu -and -not $atlasIdle) {
        Set-AtlasToolboxRecordState -StateRoot $StateRoot -Name 'CpuIdleContextMenu' -State 1
        "Set the 'CpuIdleContextMenu' record to 1, so the update adds Atlas's CPU Idle menu in its place."
    }
}

Export-ModuleMember -Function @(
    'Get-AtlasInstallStatePath'
    'Get-AtlasInstallState'
    'Get-AtlasInstallWorkRoot'
    'Start-AtlasInstallState'
    'Add-AtlasInstallOption'
    'Set-AtlasInstallOptions'
    'Set-AtlasInstallUser'
    'Commit-AtlasInstallState'
    'Invoke-AtlasInstallStep'
    'Complete-AtlasInstallState'
    'Get-AtlasPlaybookVersion'
    'Get-AtlasPlaybookOption'
    'Get-AtlasPlaybookSupportedBuild'
    'Get-AtlasInstalledVersion'
    'Resolve-AtlasInstallMode'
    'Resolve-AtlasInstallChoices'
    'Compare-AtlasInstallOption'
    'Resolve-AtlasKeptOption'
    'Get-AtlasRecordedOption'
    'Repair-AtlasToolboxRecord'
)
