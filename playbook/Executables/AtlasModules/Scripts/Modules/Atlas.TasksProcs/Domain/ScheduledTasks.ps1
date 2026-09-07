# Atlas.TasksProcs domain: scheduled tasks.
#
# schtasks.exe is used instead of the ScheduledTasks CIM cmdlets because it behaves
# consistently under TrustedInstaller and against protected Microsoft tasks. The
# scheduler COM API checks existence and enabled state without localized text parsing.

function Get-AtlasSchtasksPath {
    # Fixed System32 location so PATH resolution can never select another binary.
    return Join-Path -Path ([Environment]::GetFolderPath('Windows')) `
        -ChildPath 'System32\schtasks.exe'
}

function Invoke-AtlasScheduledTaskCommand {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OperationLabel,

        [switch]$IgnoreMissing
    )

    $before = Get-AtlasScheduledTaskState -Path $Path
    if ($before -ceq 'Missing') {
        if (-not $IgnoreMissing) {
            Write-AtlasLog -Level Warning -Message "Scheduled task '$Path' was not found; nothing to $OperationLabel."
        }
        return
    }
    $schtasksPath = Get-AtlasSchtasksPath
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $schtasksPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        $details = (@($output) | ForEach-Object { "$_" }) -join ' '
        throw "Couldn't $OperationLabel scheduled task '$Path' (schtasks.exe exited with code ${exitCode}): $details"
    }
    $expected = switch ($OperationLabel) {
        'disable' { 'Disabled' }
        'enable' { 'Enabled' }
        'delete' { 'Missing' }
        default { throw "Unknown scheduled task operation '$OperationLabel'." }
    }
    $after = Get-AtlasScheduledTaskState -Path $Path
    if ($after -cne $expected) {
        throw "Scheduled task '$Path' remained '$after' after $OperationLabel; expected '$expected'."
    }
    Write-AtlasLog -Message "Verified scheduled task '$Path': $before -> $after."
}

function Disable-AtlasScheduledTask {
    <#
    .SYNOPSIS
        Disables a scheduled task by path (e.g. '\Microsoft\Windows\Defrag\ScheduledDefrag').
        A missing task logs a warning unless -IgnoreMissing is passed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$IgnoreMissing
    )

    Invoke-AtlasScheduledTaskCommand -Path $Path -OperationLabel 'disable' -IgnoreMissing:$IgnoreMissing `
        -Arguments @('/Change', '/TN', $Path, '/DISABLE')
}

function Enable-AtlasScheduledTask {
    <#
    .SYNOPSIS
        Enables a scheduled task by path. A missing task logs a warning unless
        -IgnoreMissing is passed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$IgnoreMissing
    )

    Invoke-AtlasScheduledTaskCommand -Path $Path -OperationLabel 'enable' -IgnoreMissing:$IgnoreMissing `
        -Arguments @('/Change', '/TN', $Path, '/ENABLE')
}

function Remove-AtlasScheduledTask {
    <#
    .SYNOPSIS
        Deletes a scheduled task by path. A missing task logs a warning unless
        -IgnoreMissing is passed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$IgnoreMissing
    )

    Invoke-AtlasScheduledTaskCommand -Path $Path -OperationLabel 'delete' -IgnoreMissing:$IgnoreMissing `
        -Arguments @('/Delete', '/TN', $Path, '/F')
}

function Invoke-AtlasBestEffortScheduledTaskEnd {
    param(
        [Parameter(Mandatory = $true)][string]$SchtasksPath,
        [Parameter(Mandatory = $true)][string]$TaskName
    )

    # /End is only a fallback after the CIM stop above. The task may disappear
    # between enumeration and this call, and Windows PowerShell promotes native
    # stderr to an ErrorRecord before redirection when ErrorActionPreference=Stop.
    # Keep every outcome best-effort; payload replacement verifies the actual
    # executable/process postconditions separately.
    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $SchtasksPath /End /TN $TaskName 1>$null 2>$null
    }
    catch {
        $null = $_
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
}

function Stop-AtlasScheduledTaskUnderRoot {
    param(
        [string[]]$RootsLower,

        # Named tasks additionally ended via schtasks /End, because the CIM-based stop
        # can fail under TrustedInstaller in session 0. Defaults to the Atlas timer
        # resolution task, whose running executable blocks payload replacement.
        [string[]]$EndTaskName = @('Force Timer Resolution', '\Force Timer Resolution')
    )

    try {
        Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        # Module may not be available on older systems; continue with fallbacks.
        $null = $_
    }

    $tasks = @()
    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop
    }
    catch {
        $tasks = @()
    }

    foreach ($task in $tasks) {
        $matchesRoot = $false

        foreach ($action in $task.Actions) {
            $execute = $null
            if ($action.PSObject.Properties.Match('Execute').Count) {
                $execute = $action.Execute
            }
            elseif ($action.PSObject.Properties.Match('Path').Count) {
                $execute = $action.Path
            }

            if (-not $execute) { continue }

            $executeLower = try {
                ([System.IO.Path]::GetFullPath($execute)).ToLowerInvariant()
            }
            catch {
                $null
            }

            if (-not $executeLower) { continue }

            foreach ($root in $RootsLower) {
                if ($executeLower.StartsWith($root)) {
                    $matchesRoot = $true
                    break
                }
            }

            if ($matchesRoot) { break }
        }

        if (-not $matchesRoot) { continue }

        try {
            Stop-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore and fall back to schtasks below.
            $null = $_
        }
    }

    $schtasksPath = Get-AtlasSchtasksPath
    foreach ($candidate in @($EndTaskName)) {
        Invoke-AtlasBestEffortScheduledTaskEnd `
            -SchtasksPath $schtasksPath -TaskName $candidate
    }
}

function Invoke-AtlasScheduledTaskEntries {
    <#
    .SYNOPSIS
        Applies a ScheduledTasks entry array. Each entry is a hashtable with Path and an
        Operation of 'Disable' (default) or 'Enable'. A missing task is tolerated with a
        warning because stock tasks vary by Windows edition and build; IgnoreErrors
        additionally turns a malformed entry or a failed change into a logged warning.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    foreach ($entry in $Entries) {
        $ignoreErrors = $entry.ContainsKey('IgnoreErrors') -and [bool]$entry['IgnoreErrors']
        $entryPath = if ($entry.ContainsKey('Path')) { [string]$entry['Path'] } else { '<no path>' }
        try {
            if (-not $entry.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
                throw 'Scheduled task entry has no Path.'
            }
            $taskPath = [string]$entry['Path']

            $operation = 'Disable'
            if ($entry.ContainsKey('Operation') -and $entry['Operation']) {
                $operation = [string]$entry['Operation']
            }
            switch ($operation) {
                'Disable' { Disable-AtlasScheduledTask -Path $taskPath }
                'Enable' { Enable-AtlasScheduledTask -Path $taskPath }
                default { throw "Unknown scheduled task operation '$operation'." }
            }
        }
        catch {
            if ($ignoreErrors) {
                Write-AtlasLog -Message "Ignored scheduled task entry failure (task: '$entryPath'): $($_.Exception.Message)" -Level Warning
                continue
            }
            throw
        }
    }
}

function Get-AtlasTaskSchedulerService {
    $service = New-Object -ComObject 'Schedule.Service'
    try {
        $service.Connect()
        return $service
    }
    catch {
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($service)
        throw
    }
}

function Get-AtlasScheduledTaskState {
    <#
    .SYNOPSIS
        Returns 'Missing', 'Disabled' or 'Enabled' using the scheduler's Enabled
        property. Only file/path-not-found HRESULTs mean missing; access and RPC
        failures must not be mistaken for an absent task.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $service = $null
    $folder = $null
    $task = $null
    try {
        $service = Get-AtlasTaskSchedulerService
        $folder = $service.GetFolder('\')
        try {
            $task = $folder.GetTask($Path)
        }
        catch {
            $cause = $_.Exception
            while ($null -ne $cause.InnerException) { $cause = $cause.InnerException }
            if ($cause.HResult -in @(-2147024894, -2147024893)) {
                return 'Missing'
            }
            throw
        }
        if ($task.Enabled) { return 'Enabled' }
        return 'Disabled'
    }
    finally {
        foreach ($comObject in @($task, $folder, $service)) {
            if ($null -ne $comObject -and [Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
            }
        }
    }
}

function Test-AtlasScheduledTaskEntries {
    <#
    .SYNOPSIS
        Reports every ScheduledTasks entry whose task is present but not in the declared
        state. Missing tasks are tolerated, as they are when the entries are applied.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    $drift = @()
    foreach ($entry in $Entries) {
        if (-not $entry.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
            continue
        }
        $operation = if ($entry.ContainsKey('Operation') -and $entry['Operation']) { [string]$entry['Operation'] } else { 'Disable' }
        $expected = if ($operation -ceq 'Enable') { 'Enabled' } else { 'Disabled' }
        $actual = Get-AtlasScheduledTaskState -Path ([string]$entry['Path'])
        if ($actual -ceq 'Missing' -or $actual -ceq $expected) {
            continue
        }
        $drift += [pscustomobject]@{ Task = [string]$entry['Path']; Expected = $expected; Actual = $actual; Reason = 'task state differs' }
    }
    return $drift
}
