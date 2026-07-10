# Revert phase (upgrade-only).
# Runs StoreFixer to undo Microsoft Store breakage left by older Atlas versions. Requires
# TrustedInstaller; the shim gates this on upgrades, and it is a no-op on fresh installs.
Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext
if (-not $context.IsUpgrade) {
    Write-AtlasLog -Message 'Revert phase: fresh install, nothing to revert.'
    return
}
$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force -ErrorAction Stop

$storeFixer = Join-Path -Path $context.AtlasModulesPath -ChildPath 'Tools\StoreFixer.exe'
if (-not (Test-Path -LiteralPath $storeFixer -PathType Leaf)) {
    Write-AtlasLog -Message "Revert phase: StoreFixer.exe not found at '$storeFixer'." -Level Warning
    return
}

Write-AtlasLog -Message 'Reverting old Store changes with StoreFixer.'
$process = Start-Process -FilePath $storeFixer -WorkingDirectory (Split-Path -Path $storeFixer -Parent) -ArgumentList 'silent', 'isSetScheduledTaskOnCrash', 'noRestart' -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    Write-AtlasLog -Message "StoreFixer exited with code $($process.ExitCode)." -Level Warning
}
