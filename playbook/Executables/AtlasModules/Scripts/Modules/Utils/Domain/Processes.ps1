# Utility domain functions: Processes

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
