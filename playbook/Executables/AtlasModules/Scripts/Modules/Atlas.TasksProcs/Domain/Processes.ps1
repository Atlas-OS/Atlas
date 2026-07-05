# Atlas.TasksProcs domain: processes.

function Stop-AtlasProcess {
    <#
    .SYNOPSIS
        Force-stops processes by name. Names support wildcards (e.g. 'msteams*') and
        are given without the .exe extension. Processes that are not running are
        silently skipped, matching the AME !taskKill ignoreErrors behavior.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    foreach ($pattern in $Name) {
        foreach ($process in @(Get-Process -Name $pattern -ErrorAction SilentlyContinue)) {
            try {
                Stop-Process -InputObject $process -Force -ErrorAction Stop
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Couldn't stop process '$($process.ProcessName)' (PID $($process.Id)): $($_.Exception.Message)"
            }
        }
    }
}

function Stop-AtlasProcessUnderRoot {
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
