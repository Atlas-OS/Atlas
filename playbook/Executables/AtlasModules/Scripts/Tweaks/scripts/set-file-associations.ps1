# Companion of set-file-associations.psd1. The tweak engine runs this script in
# the intended non-elevated user's session, so CurrentUser is the only writable
# registry boundary used by the implementation. The remaining handler
# registrations are identical for every browser selection; defaults are left to
# Windows Settings or documented provisioning policy.
$ErrorActionPreference = 'Stop'

$windowsRoot = [Environment]::GetFolderPath('Windows')
$implementation = Join-Path -Path $windowsRoot -ChildPath 'AtlasModules\Scripts\Internal\Set-FileAssociations.ps1'

Write-Warning 'Protected browser defaults remain user-controlled. Use Windows Default Apps Settings or documented managed-device/first-sign-in provisioning.'
& $implementation -AssociationProfile 'Base'
