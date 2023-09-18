# Credit: https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox

$progressPreference = 'SilentlyContinue'
$wingetPath = "$env:localappdata\Microsoft\WindowsApps\winget.exe"

# Make temporary directory
$tempDir = Join-Path -Path $env:TEMP -ChildPath $([System.IO.Path]::GetRandomFileName())
New-Item $tempDir -ItemType Directory -Force | Out-Null

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {$getLatest = $true} else {
	$latestVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" | Select-Object -ExpandProperty tag_name
	if ($latestVersion -ne $(winget -v)) {$getLatest = $true}
}

if ($getLatest) {
	Set-Location $tempDir
	$oldTimeUpdated = (Get-Item $wingetPath).LastWriteTime

	Write-Information "Downloading WinGet and its dependencies..."
	Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -UseBasicParsing
	Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
	Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile Microsoft.UI.Xaml.2.7.x64.appx
	# Get license for LTSC
	$license = (Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest -UseBasicParsing).Assets | Where-Object { $_.name -like "*License*.xml" }
	Invoke-WebRequest -UseBasicParsing -OutFile "license.xml" $license.browser_download_url

	Write-Information "Installing WinGet and its dependencies..."
	Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
	Add-AppxPackage Microsoft.UI.Xaml.2.7.x64.appx
	Add-AppxProvisionedPackage -Online -PackagePath .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -LicensePath .\license.xml
}

$attempts = 0
while(!(Test-Path $wingetPath) -or ($oldTimeUpdated -eq (Get-Item $wingetPath).LastWriteTime)) {
	Start-Sleep 2
	$attempts =+ 1

	# if after 5 mins it's still not there, fail
	if ($attempts -gt 250) {
		exit
	}
}
winget -v

Write-Information "Configuring WinGet..."
# This is only temporary to ensure reliability, it's reverted after all WinGet actions
winget settings --enable InstallerHashOverride
winget settings --enable LocalArchiveMalwareScanOverride

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
	& winget install -e --id $app --accept-package-agreements --accept-source-agreements --disable-interactivity --force -h --ignore-local-archive-malware-scan --ignore-security-hash
}