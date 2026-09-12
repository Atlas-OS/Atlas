$windir = [Environment]::GetFolderPath('Windows')
$targetRoots = @(
    Join-Path $windir 'AtlasModules'
    Join-Path $windir 'AtlasDesktop'
) | ForEach-Object {
    try {
        ([System.IO.Path]::GetFullPath($_)).TrimEnd('\')
    }
    catch {
        $null
    }
} | Where-Object { $_ }

if (-not $targetRoots) { return }

function Stop-ProcessesUnderRoots {
    param([string[]]$RootsLower)

    foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
        if (-not $proc.Path) { continue }

        $procPath = try {
            ([System.IO.Path]::GetFullPath($proc.Path)).ToLowerInvariant()
        }
        catch {
            continue
        }

        foreach ($root in $RootsLower) {
            if ($procPath.StartsWith($root)) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    Wait-Process -Id $proc.Id -ErrorAction SilentlyContinue -Timeout 5
                }
                catch {
                    continue
                }

                break
            }
        }
    }
}

function Stop-TasksUnderRoots {
    param([string[]]$RootsLower)

    try {
        Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        # Module may not be available on older systems; continue with fallbacks.
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
        }
    }

    foreach ($candidate in @('Force Timer Resolution', '\Force Timer Resolution')) {
        & schtasks.exe /End /TN $candidate 1>$null 2>$null
    }
}

$rootsLower = $targetRoots | ForEach-Object { ($_ + '\').ToLowerInvariant() }
Stop-ProcessesUnderRoots -RootsLower $rootsLower
Stop-TasksUnderRoots -RootsLower $rootsLower

$timerExePath = Join-Path $windir 'AtlasModules\Tools\SetTimerResolution.exe'
if (Test-Path $timerExePath) {
    try {
        $stream = [System.IO.File]::Open($timerExePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Dispose()
    }
    catch {
        Stop-ProcessesUnderRoots -RootsLower $rootsLower
        Start-Sleep -Milliseconds 500
    }
}