$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', '..', 'Initialize-AtlasPowerShell.ps1'
    ))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$ErrorActionPreference = 'Stop'

function Wait-AtlasChildProcess {
    param(
        [Parameter(Mandatory = $true)][object]$Process,
        [Parameter(Mandatory = $true)][ValidateRange(1, [int]::MaxValue)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if (-not $Process.WaitForExit($TimeoutMilliseconds)) {
        $timeoutSeconds = [Math]::Round($TimeoutMilliseconds / 1000)
        throw "$Description did not exit within $timeoutSeconds seconds. Child completion is unknown, so removing the old Atlas files is blocked."
    }

    return [int]$Process.ExitCode
}

$windowsPath = [Environment]::GetFolderPath('Windows')
$toggleStatePath = 'HKLM:\SOFTWARE\AtlasOS\Services\ProcessExplorer'
$preserveEnabledState = $false
if (Test-Path -LiteralPath $toggleStatePath) {
    $stateKey = Get-Item -LiteralPath $toggleStatePath -ErrorAction Stop
    if ($stateKey.GetValueNames() -contains 'state') {
        $preserveEnabledState = $stateKey.GetValueKind('state') -eq
            [Microsoft.Win32.RegistryValueKind]::DWord -and
            [int]$stateKey.GetValue('state') -eq 1
    }
}

# Use this package's own machine cleanup script, not an installed desktop launcher,
# which may expect a different privilege level than the installer's.
$cleanupScript = Join-Path -Path $PSScriptRoot -ChildPath 'Invoke-AtlasProcessExplorerCleanup.ps1'
$powerShellPath = Join-Path -Path $windowsPath -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
try {
    if (-not [IO.File]::Exists($cleanupScript)) { throw "Process Explorer cleanup helper is missing: '$cleanupScript'." }
    $uninstallProcess = Start-Process -FilePath $powerShellPath -ArgumentList @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', ('"' + $cleanupScript + '"')
    ) -WindowStyle Hidden -PassThru
    $uninstallExitCode = Wait-AtlasChildProcess -Process $uninstallProcess -TimeoutMilliseconds 300000 `
        -Description 'Process Explorer cleanup'
    if ($uninstallExitCode -ne 0) {
        throw "Process Explorer cleanup failed with exit code $uninstallExitCode."
    }
}
finally {
    if ($preserveEnabledState) {
        if (-not (Test-Path -LiteralPath $toggleStatePath)) {
            [void](New-Item -Path $toggleStatePath -Force -ErrorAction Stop)
        }
        New-ItemProperty -LiteralPath $toggleStatePath -Name state -PropertyType DWord `
            -Value 1 -Force -ErrorAction Stop | Out-Null
    }
}

# This runs in session 0, which cannot ask a Task Manager in the user's session to
# close, so end it. Kill only starts termination; the wait confirms it.
foreach ($taskManager in @(Get-Process -Name 'taskmgr' -ErrorAction SilentlyContinue)) {
    $killFailure = ''
    try { $taskManager.Kill() }
    catch { $killFailure = ": $($_.Exception.GetBaseException().Message.TrimEnd('.'))" }
    if (-not $taskManager.WaitForExit(10000)) {
        throw "Task Manager (process $($taskManager.Id)) didn't stop within ten seconds$killFailure. Close Task Manager, then try again."
    }
}

if (@(Get-Process -Name 'taskmgr' -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Task Manager opened again while Atlas was stopping it. Close Task Manager, then try again.'
}

$processExplorerRoot = Join-Path -Path $windowsPath -ChildPath 'AtlasModules\Apps\ProcessExplorer'
$normalizedProcessExplorerRoot = $processExplorerRoot.TrimEnd('\') + '\'
$blockingProcesses = foreach ($process in @(Get-Process -Name 'procexp', 'procexp64', 'procexp64a' -ErrorAction SilentlyContinue)) {
    $processPath = ''
    try {
        $processPath = [string]$process.Path
    }
    catch {
        $process
        continue
    }

    if ([string]::IsNullOrWhiteSpace($processPath)) {
        $process
        continue
    }

    if ($processPath.StartsWith($normalizedProcessExplorerRoot, [StringComparison]::OrdinalIgnoreCase)) {
        $process
    }
}

if (@($blockingProcesses).Count -gt 0) {
    $processList = (@($blockingProcesses) | ForEach-Object { "$($_.ProcessName) ($($_.Id))" }) -join ', '
    throw "Process Explorer is still running from the Atlas folder: $processList."
}

$taskManagerIfeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
$taskManagerConfiguration = Get-ItemProperty -LiteralPath $taskManagerIfeo -Name 'Debugger' -ErrorAction SilentlyContinue
$debugger = if ($null -eq $taskManagerConfiguration) { '' } else { [string]$taskManagerConfiguration.Debugger }
if (-not [string]::IsNullOrWhiteSpace($debugger) -and
    $debugger.IndexOf($processExplorerRoot, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
    throw "Task Manager still redirects to Atlas's Process Explorer: '$debugger'."
}
