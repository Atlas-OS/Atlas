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
        $Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:/-]*$') {
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
    if (@('Fresh', 'Upgrade', 'Reapply') -notcontains $State.mode) {
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
        [ValidateSet('Fresh', 'Upgrade', 'Reapply')]
        [string]$Mode,
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
    $oobeValue = $IsOobe
    $resolvedPath = Resolve-AtlasInstallStatePath -StatePath $StatePath
    return Invoke-AtlasInstallStateLocked {
        $directory = [IO.Path]::GetDirectoryName($resolvedPath)
        $abandonedPath = Join-Path -Path $directory -ChildPath 'abandoned.json'
        $existing = $null

        # Completion removes transient work. Any later retry or older-RC recovery must
        # restore this invariant before option capture or Always checkpoints use it.
        [void][IO.Directory]::CreateDirectory((Join-Path -Path $directory -ChildPath 'work'))

        # A failed Fresh transaction may have been archived by an older RC when AME
        # reclassified the partially modified machine as Reapply. Recover that exact
        # Fresh step boundary so the remaining Fresh-only phases are not silently lost.
        if (-not [IO.File]::Exists($resolvedPath) -and
            $installMode -ceq 'Reapply' -and
            [IO.File]::Exists($abandonedPath)) {
            $abandoned = Read-AtlasInstallStateFile -Path $abandonedPath
            if ($abandoned.targetVersion -ceq $TargetVersion -and
                $abandoned.status -ceq 'Running' -and
                $abandoned.mode -ceq 'Fresh' -and
                -not [string]::IsNullOrWhiteSpace([string]$abandoned.lastError)) {
                $existing = $abandoned
                $existing.status = 'Capturing'
                $existing.options = @()
                $existing.userSid = $null
                $existing.userSessionId = $null
                $existing.captureNonce = $CaptureNonce
                $existing.lastError = $null
                Write-AtlasInstallStateFile -Path $resolvedPath -State $existing
                [IO.File]::Delete($abandonedPath)
                return $existing
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
            if ($existing.mode -cne $installMode -or
                [bool]$existing.isOobe -ne $oobeValue) {
                $canRecoverFailedRun = (
                    $existing.status -ceq 'Running' -and
                    -not [string]::IsNullOrWhiteSpace([string]$existing.lastError)
                )
                if (-not $canRecoverFailedRun) {
                    throw "An active $($existing.mode) install state does not match the requested $installMode mode and OOBE scope."
                }

                # AME can classify a retry differently after a partial install has
                # changed product state (for example Fresh -> Reapply). Resume the
                # original plan and completed-step boundary, but return to capture so
                # the retry records the user's current option choices.
                $existing.status = 'Capturing'
                $existing.options = @()
                $existing.userSid = $null
                $existing.userSessionId = $null
                $existing.captureNonce = $CaptureNonce
                $existing.lastError = $null
                Write-AtlasInstallStateFile -Path $resolvedPath -State $existing `
                    -CreateBackup
            }
            if ($null -ne $existing) {
                if (@('Capturing', 'Running') -contains $existing.status) {
                    return $existing
                }
                throw "Install state '$resolvedPath' is not active."
            }
        }

        $state = [pscustomobject][ordered]@{
            schemaVersion  = $script:AtlasInstallStateSchemaVersion
            targetVersion = $TargetVersion
            transactionId = [Guid]::NewGuid().ToString('D')
            status         = 'Capturing'
            mode           = $installMode
            isOobe         = $oobeValue
            options        = @()
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
        if ($state.status -eq 'Running') {
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

    # Actions can launch a user process that reads this state. Keep the named
    # state mutex out of the action boundary so the parent and child cannot
    # deadlock while waiting on each other.
    try {
        $result = & $Action
    } catch {
        $actionFailure = $_
        $message = $_.Exception.Message
        if ($message.Length -gt 4096) {
            $message = $message.Substring(0, 4096)
        }
        # The action failure is the authoritative diagnostic; recording lastError is
        # best-effort once the state or its transaction has moved on.
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
        [Parameter(Mandatory = $true)][string]$FlagsPath
    )

    $names = @()
    if ([string]$State.mode -ceq 'Upgrade') {
        $names += 'Upgrade.flag'
    }
    if (-not [bool]$State.isOobe) {
        $names += 'Interactive.flag'
    }
    foreach ($option in @($State.options)) {
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
        [string]$StatePath
    )

    foreach ($requiredStep in $RequiredSteps) {
        Assert-AtlasInstallName -Value $requiredStep -Label 'required step name'
    }

    $installFlagsPath = $FlagsPath
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

        Publish-AtlasInstallFlagSet -State $state -FlagsPath $installFlagsPath
        $state.status = 'Completed'
        $state.lastError = $null
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

Export-ModuleMember -Function @(
    'Get-AtlasInstallStatePath'
    'Get-AtlasInstallState'
    'Get-AtlasInstallWorkRoot'
    'Start-AtlasInstallState'
    'Add-AtlasInstallOption'
    'Set-AtlasInstallUser'
    'Commit-AtlasInstallState'
    'Invoke-AtlasInstallStep'
    'Complete-AtlasInstallState'
)
