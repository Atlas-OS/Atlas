[CmdletBinding()]
param()

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', 'Internal', 'Initialize-PowerShellTrust.ps1'
    ))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$ErrorActionPreference = 'Stop'

$windowsPath = [Environment]::GetFolderPath('Windows')
if ([string]::IsNullOrWhiteSpace($windowsPath) -or -not (Test-Path -LiteralPath $windowsPath -PathType Container)) {
    throw "Windows directory '$windowsPath' is not available."
}

$executablesRoot = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', '..', '..'
    ))

foreach ($folderName in @('AtlasModules', 'AtlasDesktop')) {
    $source = Join-Path -Path $executablesRoot -ChildPath $folderName
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Required playbook payload folder '$source' is missing."
    }

    Copy-Item -LiteralPath $source -Destination $windowsPath -Force -Recurse -ErrorAction Stop
}

$themesSourceRoot = Join-Path -Path $executablesRoot -ChildPath 'Themes'
if (-not (Test-Path -LiteralPath $themesSourceRoot -PathType Container)) {
    throw "Required Themes payload folder '$themesSourceRoot' is missing."
}

$themesDestination = Join-Path -Path $windowsPath -ChildPath 'Resources\Themes'
if (-not (Test-Path -LiteralPath $themesDestination -PathType Container)) {
    New-Item -Path $themesDestination -ItemType Directory -Force | Out-Null
}

Get-ChildItem -LiteralPath $themesSourceRoot -Force -ErrorAction Stop |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $themesDestination -Force -Recurse -ErrorAction Stop
    }
