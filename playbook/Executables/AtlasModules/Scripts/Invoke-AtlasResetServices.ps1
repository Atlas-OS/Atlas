<#
.SYNOPSIS
    Restores Atlas service defaults through the typed TrustedInstaller broker.
.DESCRIPTION
    The broker always applies the closed Atlas service-default plan first. An optional
    fixed Windows or Atlas snapshot is imported afterward. No command text, path, or
    caller-authored registry data crosses the privileged boundary.
#>
[CmdletBinding()]
param(
    [switch]$Silent,

    [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
    [string]$RestoreSource = 'ToggleDefaults',

    [switch]$NoRestartPrompt
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Read-AtlasResetChoice {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Caption,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [Management.Automation.Host.ChoiceDescription[]]$Choices,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$DefaultChoice = 0
    )

    return $Host.UI.PromptForChoice($Caption, $Message, $Choices, $DefaultChoice)
}

if (-not $Silent) {
    $continueChoices = @(
        (New-Object Management.Automation.Host.ChoiceDescription `
            '&Yes', 'Restore the Atlas service defaults.'),
        (New-Object Management.Automation.Host.ChoiceDescription `
            '&No', 'Leave the current service configuration unchanged.')
    )
    $confirmed = Read-AtlasResetChoice `
        -Caption 'Reset services' `
        -Message ('This restores the service configuration exposed in the Atlas folder. ' +
            'It can repair features broken by disabled services. Continue?') `
        -Choices $continueChoices `
        -DefaultChoice 1
    if ($confirmed -ne 0) {
        return
    }

    if (-not $PSBoundParameters.ContainsKey('RestoreSource')) {
        $windowsRoot = [Environment]::GetFolderPath('Windows')
        $otherRoot = Join-Path -Path $windowsRoot -ChildPath 'AtlasModules\Other'
        $windowsSnapshot = Join-Path -Path $otherRoot -ChildPath 'winServices.reg'
        $atlasSnapshot = Join-Path -Path $otherRoot -ChildPath 'atlasServices.reg'
        if ((Test-Path -LiteralPath $windowsSnapshot -PathType Leaf) -and
            (Test-Path -LiteralPath $atlasSnapshot -PathType Leaf)) {
            $snapshotChoices = @(
                (New-Object Management.Automation.Host.ChoiceDescription `
                    '&Windows', 'Apply the fixed Windows service snapshot after Atlas defaults.'),
                (New-Object Management.Automation.Host.ChoiceDescription `
                    '&Atlas', 'Apply the fixed Atlas service snapshot after Atlas defaults.'),
                (New-Object Management.Automation.Host.ChoiceDescription `
                    '&None', 'Apply only the Atlas service defaults.')
            )
            $snapshotChoice = Read-AtlasResetChoice `
                -Caption 'Full services restoration' `
                -Message 'Choose an optional fixed snapshot to apply after the defaults.' `
                -Choices $snapshotChoices `
                -DefaultChoice 2
            $RestoreSource = @('WindowsBackup', 'AtlasBackup', 'ToggleDefaults')[$snapshotChoice]
        }
    }
}

$coreManifest = Join-Path -Path $PSScriptRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1'
Import-Module -Name $coreManifest -Force -ErrorAction Stop
if (-not (Test-AtlasAdmin)) {
    $context = Get-AtlasContext
    $powershellPath = Join-Path $context.WinDir 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $argumentString = ConvertTo-AtlasWindowsArgumentString -ArgumentList @(
        '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', $PSCommandPath,
        '-Silent', '-NoRestartPrompt', '-RestoreSource', $RestoreSource
    )
    try {
        $elevatedProcess = Start-Process -FilePath $powershellPath -ArgumentList $argumentString `
            -Verb RunAs -Wait -PassThru
    }
    catch [ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            throw 'Administrator elevation was cancelled by the user.'
        }
        throw
    }
    if ($elevatedProcess.ExitCode -ne 0) {
        throw "The elevated service reset exited with code $($elevatedProcess.ExitCode)."
    }
}
else {
    Invoke-AtlasTrustedInstaller `
        -Operation ResetServices `
        -RestoreSource $RestoreSource | Out-Null
}

Write-Output 'Atlas service defaults were restored. A restart is required to apply every change.'
if (-not $Silent -and -not $NoRestartPrompt) {
    $restartChoices = @(
        (New-Object Management.Automation.Host.ChoiceDescription `
            '&Yes', 'Restart Windows now.'),
        (New-Object Management.Automation.Host.ChoiceDescription `
            '&No', 'Restart later.')
    )
    $restart = Read-AtlasResetChoice `
        -Caption 'Restart required' `
        -Message 'Would you like to restart now?' `
        -Choices $restartChoices `
        -DefaultChoice 1
    if ($restart -eq 0) {
        $windowsRoot = [Environment]::GetFolderPath('Windows')
        $shutdown = Join-Path -Path $windowsRoot -ChildPath 'System32\shutdown.exe'
        & $shutdown /r /t 0
        if ($LASTEXITCODE -ne 0) {
            throw "shutdown.exe failed with exit code $LASTEXITCODE."
        }
    }
}
