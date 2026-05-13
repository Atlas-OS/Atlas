$ErrorActionPreference = 'Stop'

$version = 'AtlasVersionUndefined'
$windowsMajor = if ([Environment]::OSVersion.Version.Build -ge 22000) { '11' } else { '10' }
$bootDescription = "AtlasOS $windowsMajor $version"

Write-Output 'Setting boot entry name...'
& bcdedit.exe /set description $bootDescription | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "bcdedit.exe failed to set the boot entry description to '$bootDescription' with exit code $LASTEXITCODE."
}

Write-Output 'Setting other versioned OEM information...'
$reportedVersion = "Atlas Playbook $version"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Model' -Value $reportedVersion -Force -ErrorAction Stop
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'RegisteredOrganization' -Value $reportedVersion -Force -ErrorAction Stop
