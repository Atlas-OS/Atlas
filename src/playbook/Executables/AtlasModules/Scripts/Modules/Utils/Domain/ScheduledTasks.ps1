# Utility domain functions: ScheduledTasks

function Stop-TasksUnderRoots {
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
