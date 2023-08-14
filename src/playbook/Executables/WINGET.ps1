# Credit: https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox

$progressPreference = 'silentlyContinue'

if ($null -eq $(cmd /c where winget)) {
	Set-Location "C:\Windows\Temp"
	
	Write-Information "Downloading WinGet and its dependencies..."
	Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -UseBasicParsing
	Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
	Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile Microsoft.UI.Xaml.2.7.x64.appx
	
	Write-Information "Installing WinGet and its dependencies..."
	Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
	Add-AppxPackage Microsoft.UI.Xaml.2.7.x64.appx
	Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
}

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