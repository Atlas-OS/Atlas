# Pins Windows Update to the currently installed Windows product and release version
# (TargetReleaseVersionInfo) so feature updates are not offered.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Tasks\Set-FeatureUpdateTarget.ps1')
