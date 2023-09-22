# https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox

$progressPreference = 'SilentlyContinue'
$wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {$getLatest = $true} else {
	$currentVersion = winget -v
	$latestVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -TimeoutSec 60 | Select-Object -ExpandProperty tag_name
	if ($latestVersion -ne $currentVersion) {$getLatest = $true}
}

if ($getLatest) {
	# Make temporary directory
	$tempDir = Join-Path -Path $env:TEMP -ChildPath $([System.IO.Path]::GetRandomFileName())
	New-Item $tempDir -ItemType Directory -Force | Out-Null
	Set-Location $tempDir

	Write-Host "Installing WinGet..." -ForegroundColor 
	# Download WinGet
	Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile '.\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -UseBasicParsing

	# Get dependencies
	if ($null -eq (Get-AppxPackage 'Microsoft.VCLibs.140.00.UWPDesktop')) {
		Write-Host "Installing VCLibs..."

		Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '.\Microsoft.VCLibs.x64.14.00.Desktop.appx' -UseBasicParsing
		Add-AppxProvisionedPackage -Online -PackagePath ".\Microsoft.VCLibs.x64.14.00.Desktop.appx" -SkipLicense
	}
	if ($null -eq (Get-AppxPackage 'Microsoft.VCLibs.140.00.UWPDesktop')) {
		Write-Information "Installing Microsoft.UI.Xaml 2.7.3..."

		Invoke-WebRequest -Uri 'https://nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3' -OutFile '.\Microsoft.UI.Xaml.2.7.zip' -UseBasicParsing
		Expand-Archive 'Microsoft.UI.Xaml.2.7.zip' -Force
		if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { $arch = 'x64' } elseif ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $arch = 'arm64' }
		Copy-Item -Path ".\Microsoft.UI.Xaml.2.7\tools\AppX\$arch\Release\Microsoft.UI.Xaml.2.7.appx" -Destination "."

		Add-AppxProvisionedPackage -Online -PackagePath ".\Microsoft.UI.Xaml.2.7.appx" -SkipLicense
	}

	# Get license for LTSC and other SKUs
	# Uses GitHub API, so it will not work in some regions, but LTSC is not officially supported anyways
	$license = (Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest -UseBasicParsing -TimeoutSec 60).Assets | Where-Object { $_.name -like "*License*.xml" }
	if ($?) { Invoke-WebRequest -UseBasicParsing -OutFile "license.xml" $license.browser_download_url }
	if (Test-Path '.\license.xml') { $license = @{LicensePath = ".\license.xml"} }

	# Install WinGet
	Add-AppxProvisionedPackage -Online -PackagePath .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle @license
}

$attempts = 0
while(!(Test-Path $wingetPath) -or ($(winget -v) -eq $currentVersion)) {
	Start-Sleep 2
	$attempts =+ 1

	# if after 5 mins it's still not there, fail
	if ($attempts -gt 250) {
		Write-Host "WinGet installation failed, GitHub is likely unreachable and user is probably on LTSC."
		exit 1
	}
}

$wingetExtraArgs = '--ignore-local-archive-malware-scan --ignore-security-hash --disable-interactivity'
if ($latestVersion -ne $currentVersion) {$wingetExtraArgs = $null}

if ($wingetExtraArgs) {
	Write-Information "Configuring WinGet..."
	# This is only temporary to ensure reliability, it's reverted after all WinGet actions
	winget settings --enable InstallerHashOverride
	winget settings --enable LocalArchiveMalwareScanOverride
}

Write-Information "Installing dependencies with WinGet..."
$installList = @(
	# Visual C++ Redistributables
	"Microsoft.VCRedist.2005.x64",
	"Microsoft.VCRedist.2008.x64",
	"Microsoft.VCRedist.2010.x64",
	"Microsoft.VCRedist.2012.x64",
	"Microsoft.VCRedist.2013.x64",
	"Microsoft.VCRedist.2015+.x64",
	# Runtime libries for legacy DirectX SDK runtimes
	# Useful for old games
	"Microsoft.DirectX",
	"7zip.7zip"
)

foreach ($app in $installList) {
	& winget install -e --id $app --accept-package-agreements --accept-source-agreements --force -h $wingetArgs
}

Remove-Item -Path $tempDir -Force -Recurse *>$null