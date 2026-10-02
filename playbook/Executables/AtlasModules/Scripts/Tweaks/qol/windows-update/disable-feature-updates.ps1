# Pins Windows Update to the installed Windows 11 release, so it offers no feature
# update. Atlas Manager moves Windows between releases by retargeting this pin.
$ErrorActionPreference = 'Stop'
. ([IO.Path]::Combine($PSScriptRoot, '..', '..', '..', 'Preparation', 'WindowsTransition.ps1'))

$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
if ($os.Caption -notmatch 'Windows 11') {
    throw "Refusing to pin the feature-update target: OS caption '$($os.Caption)' is not Windows 11."
}

$currentVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
if ([string]::IsNullOrWhiteSpace($currentVersion.DisplayVersion)) {
    throw 'Windows DisplayVersion was empty; cannot set TargetReleaseVersionInfo.'
}

Set-AtlasFeatureUpdateTarget -Release $currentVersion.DisplayVersion
