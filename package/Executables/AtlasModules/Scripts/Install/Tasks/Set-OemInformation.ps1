# Names the boot entry and the OEM model after this Atlas version, which the build stamps
# over AtlasVersionUndefined as v<version>. Windows shows the model and the registered
# organisation, 'Atlas v<version>', in winver and Settings. The misc tweak category's
# config-oem-information companion runs it as TrustedInstaller.
$ErrorActionPreference = 'Stop'

$version = 'AtlasVersionUndefined'
$bootDescription = "AtlasOS 11 $version"
$bcdEditPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'bcdedit.exe')

if (-not [IO.File]::Exists($bcdEditPath)) {
    throw "The inbox bcdedit executable is missing at '$bcdEditPath'."
}

Write-Output 'Setting boot entry name...'
& $bcdEditPath /set description $bootDescription | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "bcdedit.exe failed to set the boot entry description to '$bootDescription' with exit code $LASTEXITCODE."
}

Write-Output 'Setting other versioned OEM information...'
$reportedVersion = "Atlas $version"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' `
    -Name 'Model' -Value $reportedVersion -Type String -Force -ErrorAction Stop
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
    -Name 'RegisteredOrganization' -Value $reportedVersion -Type String -Force -ErrorAction Stop
