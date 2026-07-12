# Pre-install phase: remove obsolete Atlas elevation artifacts and start best-effort cleanup.

Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked) {
    throw 'Pre-install requires active Atlas install state.'
}
if (-not $context.IsOobe -and
    [string]::IsNullOrWhiteSpace([string]$context.InteractiveUserSid)) {
    throw 'Pre-install requires the install-state user outside OOBE.'
}

$internalRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal'
$powerShellPath = Join-Path -Path ([Environment]::SystemDirectory) `
    -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'

function Invoke-AtlasPreInstallUserScript {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if (-not [IO.File]::Exists($Path)) {
        throw "$Description script is missing at '$Path'."
    }
    $commandLine = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" {1}' -f `
        $Path, $Arguments
    $exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath -Arguments $commandLine
    if ($exitCode -ne 0) {
        throw "$Description exited with code $exitCode."
    }
}

# This migration is required so upgrades do not retain the old RunAsTI surface.
$legacyMigration = Join-Path $internalRoot 'Remove-AtlasLegacyElevationArtifacts.ps1'
if (-not [IO.File]::Exists($legacyMigration)) {
    throw "Required legacy elevation migration is missing at '$legacyMigration'."
}
& $legacyMigration -Scope Machine | Out-Null
if (-not $context.IsOobe) {
    Invoke-AtlasPreInstallUserScript -Path $legacyMigration `
        -Arguments ('-Scope CurrentUser -ExpectedUserSid "{0}"' -f $context.InteractiveUserSid) `
        -Description 'Current-user legacy elevation migration'
}

# Cleanup is useful but must not turn an otherwise valid install into a failure.
try {
    $diskCleanup = Join-Path $internalRoot 'Invoke-DiskCleanup.ps1'
    & $diskCleanup -Scope Machine
    if (-not $context.IsOobe) {
        Invoke-AtlasPreInstallUserScript -Path $diskCleanup `
            -Arguments ('-Scope CurrentUser -ExpectedUserSid "{0}"' -f $context.InteractiveUserSid) `
            -Description 'Current-user TEMP cleanup'
    }
}
catch {
    Write-AtlasLog -Level Warning -Message "Disk cleanup failed: $($_.Exception.Message)"
}
