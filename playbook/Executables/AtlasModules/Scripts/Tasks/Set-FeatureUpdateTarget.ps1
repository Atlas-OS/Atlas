$ErrorActionPreference = 'Stop'

$windowsUpdatePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
# Create only when missing: New-Item -Force recreates the key and wipes values other
# tweaks wrote here first (TargetReleaseVersion, the Insider ManagePreviewBuilds set).
if (-not (Test-Path -LiteralPath $windowsUpdatePath)) {
    New-Item -Path $windowsUpdatePath -Force | Out-Null
}

$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
if ($os.Caption -match 'Windows 11') {
    $productVersion = 'Windows 11'
}
else {
    $productVersion = 'Windows 10'
}

$currentVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
if ([string]::IsNullOrWhiteSpace($currentVersion.DisplayVersion)) {
    throw 'Windows DisplayVersion was empty; cannot set TargetReleaseVersionInfo.'
}

# TargetReleaseVersionInfo is only honoured when TargetReleaseVersion=1, so assert it
# here too (the declarative tweak sets it, but keep this self-contained).
New-ItemProperty -Path $windowsUpdatePath -Name 'TargetReleaseVersion' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $windowsUpdatePath -Name 'ProductVersion' -Value $productVersion -PropertyType String -Force | Out-Null
New-ItemProperty -Path $windowsUpdatePath -Name 'TargetReleaseVersionInfo' -Value $currentVersion.DisplayVersion -PropertyType String -Force | Out-Null
