# Atlas.TasksProcs domain: processes.

function Invoke-AtlasProcessStop {
    param([Parameter(Mandatory = $true)][object]$Process)

    Stop-Process -InputObject $Process -Force -ErrorAction Stop
}

function Wait-AtlasProcessExit {
    param(
        [Parameter(Mandatory = $true)][object]$Process,
        [Parameter(Mandatory = $true)][int]$TimeoutMilliseconds
    )

    if (-not [bool]$Process.WaitForExit($TimeoutMilliseconds) -or
        -not [bool]$Process.HasExited) {
        throw "Process '$($Process.ProcessName)' (PID $($Process.Id)) did not exit within $TimeoutMilliseconds milliseconds."
    }
}

function Stop-AtlasProcess {
    <#
    .SYNOPSIS
        Force-stops processes by name. Names support wildcards (e.g. 'msteams*') and
        are given without the .exe extension. Processes that are not running are
        skipped; stop failures warn unless StopOnError is set.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Callers control prompting; this helper performs the requested process stop.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$SessionId,

        [switch]$StopOnError,

        [switch]$PassThru,

        [ValidateRange(1, 30000)]
        [int]$WaitTimeoutMilliseconds
    )

    foreach ($pattern in $Name) {
        foreach ($process in @(Get-Process -Name $pattern -ErrorAction SilentlyContinue)) {
            $processName = try { [string]$process.ProcessName } catch { '<unknown>' }
            $processId = try { [int]$process.Id } catch { 0 }
            $processSessionId = $null
            if ($PSBoundParameters.ContainsKey('SessionId')) {
                $processSessionId = try {
                    [int]$process.SessionId
                }
                catch {
                    if ($StopOnError) {
                        throw "Couldn't bind process '$processName' (PID $processId) to a Windows session: $($_.Exception.Message)"
                    }
                    Write-AtlasLog -Level Warning -Message "Couldn't bind process '$processName' (PID $processId) to a Windows session: $($_.Exception.Message)"
                    continue
                }
                if ($processSessionId -ne $SessionId) {
                    continue
                }
            }

            try {
                # Keep the already selected Process object for both operations so a
                # reused PID or a same-name process is never picked up after filtering.
                Invoke-AtlasProcessStop -Process $process
                if ($PSBoundParameters.ContainsKey('WaitTimeoutMilliseconds')) {
                    Wait-AtlasProcessExit -Process $process `
                        -TimeoutMilliseconds $WaitTimeoutMilliseconds
                }
                if ($PassThru) {
                    [pscustomobject]@{
                        ProcessName = $processName
                        Id          = $processId
                        SessionId   = $processSessionId
                    }
                }
            }
            catch {
                $alreadyExited = try {
                    [bool]$process.HasExited
                }
                catch {
                    $false
                }
                if ($alreadyExited) {
                    continue
                }
                if ($StopOnError) {
                    throw
                }
                Write-AtlasLog -Level Warning -Message "Couldn't stop process '$processName' (PID $processId): $($_.Exception.Message)"
            }
        }
    }
}

function Get-AtlasShellWindowProcessId {
    if ($null -eq ('Atlas.TasksProcs.ShellWindow' -as [type])) {
        Add-Type -Namespace Atlas.TasksProcs -Name ShellWindow -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern System.IntPtr GetShellWindow();

[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(System.IntPtr window, out uint processId);
'@ -ErrorAction Stop
    }

    $window = [Atlas.TasksProcs.ShellWindow]::GetShellWindow()
    if ($window -eq [IntPtr]::Zero) { return 0 }

    [uint32]$processId = 0
    if ([Atlas.TasksProcs.ShellWindow]::GetWindowThreadProcessId(
            $window, [ref]$processId) -eq 0 -or $processId -gt [int]::MaxValue) {
        return 0
    }
    return [int]$processId
}

function Wait-AtlasExplorerShellRecovery {
    <#
    .SYNOPSIS
        Waits for Explorer to own the shell window in one exact session.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$SessionId,

        [ValidateRange(1, 120)]
        [int]$TimeoutSeconds = 15
    )

    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
            $shellProcessId = Get-AtlasShellWindowProcessId
            $process = if ($shellProcessId -gt 0) {
                Get-Process -Id $shellProcessId -ErrorAction SilentlyContinue
            }
            if ($null -ne $process) {
                try {
                    if (-not [bool]$process.HasExited -and
                        [string]$process.ProcessName -ieq 'explorer' -and
                        [int]$process.SessionId -eq $SessionId) {
                        return [pscustomobject]@{
                            ProcessName = [string]$process.ProcessName
                            Id          = [int]$process.Id
                            SessionId   = [int]$process.SessionId
                        }
                    }
                }
                catch {
                    Write-Verbose 'Explorer changed while its shell state was being read.'
                }
                finally {
                    if ($process -is [IDisposable]) {
                        $process.Dispose()
                    }
                }
            }
            Start-Sleep -Milliseconds 100
        }
    }
    finally {
        $timer.Stop()
    }

    throw "Explorer did not become ready in Windows session $SessionId within $TimeoutSeconds seconds."
}

function Stop-AtlasProcessUnderRoot {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This internal cleanup helper is called from a non-interactive install phase.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$RootsLower,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$SessionId
    )

    $roots = @($RootsLower | ForEach-Object {
            [IO.Path]::GetFullPath($_).TrimEnd([char[]]@('\', '/')) + '\'
        })

    foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
        if ($PSBoundParameters.ContainsKey('SessionId')) {
            $processSessionId = try {
                [int]$proc.SessionId
            }
            catch {
                continue
            }
            if ($processSessionId -ne $SessionId) {
                continue
            }
        }
        if (-not $proc.Path) { continue }

        $procPath = try {
            [IO.Path]::GetFullPath($proc.Path)
        }
        catch {
            continue
        }

        foreach ($root in $roots) {
            if ($procPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                try {
                    Invoke-AtlasProcessStop -Process $proc
                    Wait-AtlasProcessExit -Process $proc -TimeoutMilliseconds 5000
                }
                catch {
                    continue
                }

                break
            }
        }
    }
}
