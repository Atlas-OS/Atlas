[CmdletBinding()]
param()

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$ErrorActionPreference = 'Stop'

# Runs before the payload copy on upgrades, so the module is imported from the
# extracted playbook directory rather than the (stale) copy in %windir%.
$executablesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$coreModule = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1'
if (-not (Test-Path -LiteralPath $coreModule -PathType Leaf)) {
    throw "Atlas core module '$coreModule' is missing."
}

Import-Module $coreModule -Force

$tasksProcsModule = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\Scripts\Modules\Atlas.TasksProcs\Atlas.TasksProcs.psd1'
if (-not (Test-Path -LiteralPath $tasksProcsModule -PathType Leaf)) {
    throw "Atlas tasks/processes module '$tasksProcsModule' is missing."
}

Import-Module $tasksProcsModule -Force

$windir = [Environment]::GetFolderPath('Windows')
$targetRoots = @(
    Join-Path -Path $windir -ChildPath 'AtlasModules'
    Join-Path -Path $windir -ChildPath 'AtlasDesktop'
) | ForEach-Object {
    try {
        ([System.IO.Path]::GetFullPath($_)).TrimEnd('\')
    }
    catch {
        $null
    }
} | Where-Object { $_ }

if (-not $targetRoots) {
    return
}

$rootsLower = $targetRoots | ForEach-Object { ($_ + '\').ToLowerInvariant() }
# This helper runs as TrustedInstaller in session 0. Interactive Atlas tools in
# another Windows session are not cleanup targets; open handles will make replacement fail.
Stop-AtlasProcessUnderRoot -RootsLower $rootsLower -SessionId 0
Stop-AtlasScheduledTaskUnderRoot -RootsLower $rootsLower

$timerExePath = Join-Path -Path $windir -ChildPath 'AtlasModules\Tools\SetTimerResolution.exe'
if (Test-Path -LiteralPath $timerExePath -PathType Leaf) {
    try {
        $stream = [System.IO.File]::Open($timerExePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Dispose()
    }
    catch {
        Stop-AtlasProcessUnderRoot -RootsLower $rootsLower -SessionId 0
        Start-Sleep -Milliseconds 500
    }
}
