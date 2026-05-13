$ErrorActionPreference = 'Stop'

$windowsUpdatePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
New-Item -Path $windowsUpdatePath -Force | Out-Null

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

New-ItemProperty -Path $windowsUpdatePath -Name 'ProductVersion' -Value $productVersion -PropertyType String -Force | Out-Null
New-ItemProperty -Path $windowsUpdatePath -Name 'TargetReleaseVersionInfo' -Value $currentVersion.DisplayVersion -PropertyType String -Force | Out-Null
