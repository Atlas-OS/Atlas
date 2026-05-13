$ErrorActionPreference = 'Stop'

$windowsPath = [Environment]::GetFolderPath('Windows')
if ([string]::IsNullOrWhiteSpace($windowsPath) -or -not (Test-Path -LiteralPath $windowsPath -PathType Container)) {
    throw "Windows directory '$windowsPath' is not available."
}

foreach ($folderName in @('AtlasModules', 'AtlasDesktop')) {
    $source = Join-Path -Path (Get-Location).Path -ChildPath $folderName
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Required playbook payload folder '$source' is missing."
    }

    Copy-Item -LiteralPath $source -Destination $windowsPath -Force -Recurse -ErrorAction Stop
}

$themesSourceRoot = Join-Path -Path (Get-Location).Path -ChildPath 'Themes'
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
