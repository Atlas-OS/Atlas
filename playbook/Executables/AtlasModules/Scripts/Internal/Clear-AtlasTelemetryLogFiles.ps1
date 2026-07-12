<#
.SYNOPSIS
    Removes Atlas's two fixed DiagTrack log-file sets during an active install.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$coreManifest = Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1'
Import-Module -Name $coreManifest -Force -ErrorAction Stop

Assert-AtlasPrivilege -TrustedInstaller
$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked) {
    throw 'Telemetry-log cleanup requires active Atlas install state.'
}

$programData = [Environment]::GetFolderPath('CommonApplicationData')
if ([string]::IsNullOrWhiteSpace($programData) -or
    -not [IO.Path]::IsPathRooted($programData)) {
    throw 'Windows did not return a rooted common application-data directory.'
}

$etlLogsRoot = [IO.Path]::Combine(
    [IO.Path]::GetFullPath($programData),
    'Microsoft\Diagnosis\ETLLogs'
)
$logDirectories = @(
    [IO.Path]::Combine($etlLogsRoot, 'AutoLogger')
    [IO.Path]::Combine($etlLogsRoot, 'ShutdownLogger')
)

foreach ($directoryPath in $logDirectories) {
    if (-not [IO.Directory]::Exists($directoryPath)) {
        continue
    }

    $directory = Get-Item -LiteralPath $directoryPath -Force -ErrorAction Stop
    if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Telemetry-log directory '$directoryPath' is a reparse point."
    }

    $files = @(Get-ChildItem -LiteralPath $directoryPath `
            -Filter 'DiagTrack*' -File -Force -ErrorAction Stop)
    foreach ($file in $files) {
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Telemetry-log file '$($file.FullName)' is a reparse point."
        }

        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
    }
}
