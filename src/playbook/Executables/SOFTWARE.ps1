param (
	[switch]$Chrome,
	[switch]$Brave
)

# ----------------------------------------------------------------------------------------------------------- #
# Software is no longer installed with a package manager anymore to be as fast and as reliable as possible.   #
# ----------------------------------------------------------------------------------------------------------- #

# Create temporary directory
$tempDir = Join-Path -Path $env:TEMP -ChildPath $([System.IO.Path]::GetRandomFileName())
New-Item $tempDir -ItemType Directory -Force | Out-Null
Set-Location $tempDir

# Chrome
if ($Chrome) {
	Write-Host "Installing Google Chrome..."
	& curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -o "$tempDir\chrome.msi"
	Start-Process -FilePath "$tempDir\chrome.msi" -WindowStyle Hidden -ArgumentList '/qn' -Wait
	exit
}

# Brave
if ($Brave) {
	Write-Host "Installing Brave..."
	& curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" -o "$tempDir\BraveSetup.exe"
	if (!$?) {
		Write-Error "Downloading Brave failed."
		exit 1
	}

	& "$tempDir\BraveSetup.exe" /silent /install

	do {
		$processesFound = Get-Process | Where-Object { "BraveSetup" -contains $_.Name } | Select-Object -ExpandProperty Name
		if ($processesFound) {
			Write-Host "Still running BraveSetup."
			Start-Sleep -Seconds 2
		} else {
			Remove-Item "$tempDir" -ErrorAction SilentlyContinue -Force -Recurse
		}
	} until (!$processesFound)

	Stop-Process -Name "brave" -Force -ErrorAction SilentlyContinue
	exit
}

####################
##    Software    ##
####################

# Visual C++ Runtimes (referred to as vcredists for short)
# https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist
$legacyArgs1 = '/q'
$legacyArgs2 = '/q /norestart'
$modernArgs = "/install /quiet /norestart"

$vcredists = @{
	# 2005 - version 8.0.50727.6195 (MSI 8.0.61000/8.0.61001)
	"https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe" = $legacyArgs1
	# 2008 - version 9.0.30729.6161 (EXE 9.0.30729.5677) SP1
	"https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe" = $legacyArgs1
	# 2010 - version 10.0.40219.473 SP1
	"https://download.microsoft.com/download/E/E/0/EE05C9EF-A661-4D9E-BCE2-6961ECDF087F/vcredist_x64.exe" = $legacyArgs2
	# 2012 - version 11.0.61030.0
	"https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" = $modernArgs
	# 2013 - version 12.0.40664.0
	"https://aka.ms/highdpimfc2013x64enu" = $modernArgs
	# 2015-2022 (2015+) - latest version
	"https://aka.ms/vs/17/release/vc_redist.x64.exe" = $modernArgs
}
$num = 0; foreach ($a in $vcredists.GetEnumerator()) {
	$num++; $vcredist = "$tempDir\vcredist$num.exe"
	# curl is faster than Invoke-WebRequest
	Write-Host "Installing Visual C++ Runtime $num..."
	& curl.exe -LSs "$($a.Name)" -o "$vcredist"
	Start-Process -FilePath $vcredist -WindowStyle Hidden -ArgumentList $a.Value -Wait
}

# 7-Zip
if ($env:PROCESSOR_ARCHITECTURE -eq 'amd64') {$arch = 'x64'} else {$arch = 'arm64'}
$website = 'https://7-zip.org/'
$download = $website + ((Invoke-WebRequest $website -UseBasicParsing).Links.href | Where-Object { $_ -like "a/7z2301-$arch.exe" })
& curl.exe -LSs $download -o "$tempDir\7zip.exe"
Start-Process -FilePath "$tempDir\7zip.exe" -WindowStyle Hidden -ArgumentList '/S' -Wait

# Legacy DirectX runtimes
& curl.exe -LSs "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -o "$tempDir\directx.exe"
Write-Host "Extracting legacy DirectX runtimes..."
Start-Process -FilePath "$tempDir\directx.exe" -WindowStyle Hidden -ArgumentList "/q /c /t:`"$tempDir\directx`"" -Wait
Write-Host "Installing legacy DirectX runtimes..."
Start-Process -FilePath "$tempDir\directx\dxsetup.exe" -WindowStyle Hidden -ArgumentList '/silent' -Wait

# Remove temporary directory
Remove-Item -Path $tempDir -Force -Recurse *>$null