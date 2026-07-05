# Atlas.TasksProcs domain: scheduled tasks.
#
# schtasks.exe is used instead of the ScheduledTasks CIM cmdlets because it behaves
# consistently under TrustedInstaller and against protected Microsoft tasks. Exit code
# 1 means the task does not exist, which is expected on many Windows editions/builds
# and therefore only logged as a warning (or silenced with -IgnoreMissing).

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

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & schtasks.exe @Arguments 2>&1
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

function Stop-AtlasScheduledTaskUnderRoot {
    param([string[]]$RootsLower)

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

    foreach ($candidate in @('Force Timer Resolution', '\Force Timer Resolution')) {
        & schtasks.exe /End /TN $candidate 1>$null 2>$null
    }
}
