# Atlas.TasksProcs domain: scheduled tasks.
#
# schtasks.exe is used instead of the ScheduledTasks CIM cmdlets because it behaves
# consistently under TrustedInstaller and against protected Microsoft tasks. Exit code
# 1 means the task does not exist, which is expected on many Windows editions/builds
# and therefore only logged as a warning (or silenced with -IgnoreMissing).

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

    $schtasksPath = Get-AtlasSchtasksPath
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $schtasksPath @Arguments 2>&1
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($LASTEXITCODE -eq 1) {
        if (-not $IgnoreMissing) {
            Write-AtlasLog -Level Warning -Message "Scheduled task '$Path' was not found; nothing to $OperationLabel."
        }
    }
    elseif ($LASTEXITCODE -ne 0) {
        $details = (@($output) | ForEach-Object { "$_" }) -join ' '
        Write-AtlasLog -Level Warning -Message "Couldn't $OperationLabel scheduled task '$Path' (schtasks.exe exited with code $LASTEXITCODE): $details"
    }
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
