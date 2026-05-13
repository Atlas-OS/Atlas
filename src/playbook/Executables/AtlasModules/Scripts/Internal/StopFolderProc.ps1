$ErrorActionPreference = 'Stop'

$executablesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$utilsModule = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\Scripts\Modules\Utils\Utils.psm1'
if (-not (Test-Path -LiteralPath $utilsModule -PathType Leaf)) {
    throw "Atlas utility module '$utilsModule' is missing."
}

Import-Module $utilsModule -Force

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
Stop-ProcessesUnderRoots -RootsLower $rootsLower
Stop-TasksUnderRoots -RootsLower $rootsLower

$timerExePath = Join-Path -Path $windir -ChildPath 'AtlasModules\Tools\SetTimerResolution.exe'
if (Test-Path -LiteralPath $timerExePath -PathType Leaf) {
    try {
        $stream = [System.IO.File]::Open($timerExePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Dispose()
    }
    catch {
        Stop-ProcessesUnderRoots -RootsLower $rootsLower
        Start-Sleep -Milliseconds 500
    }
}
