# Pre-install phase: removes obsolete Atlas elevation artifacts and starts best-effort
# cleanup. Runs as TrustedInstaller in every install mode, once Atlas's files are in
# place; the installing user's half of each step runs in that user's own process.

Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked) {
    throw 'Pre-install requires active Atlas install state.'
}
if ([string]::IsNullOrWhiteSpace([string]$context.InteractiveUserSid)) {
    throw 'Pre-install requires the install-state user.'
}

$scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

# Required, so an update doesn't keep the old RunAsTI elevation entry points.
$legacyMigration = Join-Path $scriptsRoot 'Install\Compat\Remove-AtlasLegacyElevationArtifacts.ps1'
if (-not [IO.File]::Exists($legacyMigration)) {
    throw "Required legacy elevation migration is missing at '$legacyMigration'."
}
& $legacyMigration -Scope Machine | Out-Null
Invoke-AtlasPreInstallUserScript -Path $legacyMigration `
    -Arguments ('-Scope CurrentUser -ExpectedUserSid "{0}"' -f $context.InteractiveUserSid) `
    -Description 'Current-user legacy elevation migration'

# Cleanup is useful but must not turn an otherwise valid install into a failure.
try {
    $diskCleanup = Join-Path $scriptsRoot 'Install\Tasks\Invoke-DiskCleanup.ps1'
    & $diskCleanup -Scope Machine
    Invoke-AtlasPreInstallUserScript -Path $diskCleanup `
        -Arguments ('-Scope CurrentUser -ExpectedUserSid "{0}"' -f $context.InteractiveUserSid) `
        -Description 'Current-user TEMP cleanup'
}
catch {
    Write-AtlasLog -Level Warning -Message "Disk cleanup failed: $($_.Exception.Message)"
}
