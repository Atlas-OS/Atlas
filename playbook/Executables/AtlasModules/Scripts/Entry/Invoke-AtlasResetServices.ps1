<#
.SYNOPSIS
    Restores Atlas service defaults through the typed TrustedInstaller broker.
.DESCRIPTION
    The broker always applies the closed Atlas service-default plan first. An optional
    fixed Windows or Atlas snapshot is imported afterward. No command text, path, or
    caller-authored registry data crosses the privileged boundary.

    Interactive runs present themselves through the Atlas.Core console vocabulary and
    own the single exit pause; -Silent keeps the one-line output its callers capture.
#>
[CmdletBinding()]
param(
    [switch]$Silent,

    [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
    [string]$RestoreSource = 'ToggleDefaults',

    [switch]$NoRestartPrompt
)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) { throw "The PowerShell bootstrap is missing at '$bootstrap'." }
. $bootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$coreManifest = Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1'
Import-Module -Name $coreManifest -Force -ErrorAction Stop

$title = 'Set services to defaults'
$completionText = 'Atlas service defaults were restored. A restart is required to apply every change.'

if (-not $Silent) {
    Set-AtlasLogConsoleStyle -Style Interactive
    Write-AtlasTitle -Text $title -Explanation @(
        'Restores the service configuration exposed in the Atlas folder. It can repair'
        'features broken by disabled services.'
    )

    if (-not (Read-AtlasYesNo -Question 'Restore the Atlas service defaults now?')) {
        Write-AtlasNote -Text 'Nothing was changed.'
        Wait-AtlasExit
        return
    }

    if (-not $PSBoundParameters.ContainsKey('RestoreSource')) {
        $windowsRoot = [Environment]::GetFolderPath('Windows')
        $otherRoot = Join-Path -Path $windowsRoot -ChildPath 'AtlasModules\Other'
        $windowsSnapshot = Join-Path -Path $otherRoot -ChildPath 'winServices.reg'
        $atlasSnapshot = Join-Path -Path $otherRoot -ChildPath 'atlasServices.reg'
        if ((Test-Path -LiteralPath $windowsSnapshot -PathType Leaf) -and
            (Test-Path -LiteralPath $atlasSnapshot -PathType Leaf)) {
            $snapshotChoice = Read-AtlasChoice `
                -Question 'Also apply a fixed service snapshot after the defaults?' `
                -Option @(
                    'The Windows service snapshot'
                    'The Atlas service snapshot'
                    'No snapshot, only the Atlas defaults'
                ) `
                -DefaultIndex 3
            $RestoreSource = @('WindowsBackup', 'AtlasBackup', 'ToggleDefaults')[$snapshotChoice - 1]
        }
    }
}

try {
    if (-not (Test-AtlasAdmin)) {
        $context = Get-AtlasContext
        $powershellPath = Join-Path $context.WinDir 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $argumentString = ConvertTo-AtlasWindowsArgumentString -ArgumentList @(
            '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $PSCommandPath,
            '-Silent', '-NoRestartPrompt', '-RestoreSource', $RestoreSource
        )
        if (-not $Silent) {
            Write-AtlasStep -Text 'Asking for administrator permission...'
        }
        try {
            $elevatedProcess = Start-Process -FilePath $powershellPath -ArgumentList $argumentString `
                -Verb RunAs -Wait -PassThru
        }
        catch [ComponentModel.Win32Exception] {
            if ($_.Exception.NativeErrorCode -eq 1223) {
                throw 'The administrator permission prompt was cancelled, so nothing was changed.'
            }
            throw
        }
        if ($elevatedProcess.ExitCode -ne 0) {
            throw "The elevated service reset exited with code $($elevatedProcess.ExitCode)."
        }
    }
    else {
        if (-not $Silent) {
            Write-AtlasStep -Text 'Restoring the Atlas service defaults...'
        }
        Invoke-AtlasTrustedInstaller `
            -Operation ResetServices `
            -RestoreSource $RestoreSource | Out-Null
    }
}
catch {
    if ($Silent) {
        throw
    }
    Write-AtlasLog -Level Error -Message "Resetting services failed: $($_.Exception.Message)" -ErrorRecord $_ -NoConsole
    Write-AtlasNotApplied -Title $title -Reason $_.Exception.Message -DetailsPath (Get-AtlasInstallLogPath)
    Wait-AtlasExit
    exit 1
}

if ($Silent) {
    Write-Output $completionText
    return
}

Write-AtlasCompletion -Title $title
if (-not $NoRestartPrompt) {
    Write-AtlasRestartNotice -Kind Required
    if (Read-AtlasYesNo -Question 'Restart Windows now?') {
        $windowsRoot = [Environment]::GetFolderPath('Windows')
        $shutdown = Join-Path -Path $windowsRoot -ChildPath 'System32\shutdown.exe'
        Write-AtlasStep -Text 'Restarting Windows...'
        & $shutdown /r /t 0
        if ($LASTEXITCODE -ne 0) {
            throw "shutdown.exe failed with exit code $LASTEXITCODE."
        }
    }
}
Wait-AtlasExit
