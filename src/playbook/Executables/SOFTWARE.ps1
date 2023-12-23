param (
	[switch]$Chrome,
	[switch]$Brave,
	[switch]$Firefox,
	[switch]$MPV,
	[switch]$MPCHC,
	[switch]$VLC,
	[switch]$NotepadPlusPlus,
	[switch]$VisualStudioCode,
	[switch]$VSCodium
)

# ----------------------------------------------------------------------------------------------------------- #
# Software is no longer installed with a package manager anymore to be as fast and as reliable as possible.   #
# ----------------------------------------------------------------------------------------------------------- #

# Create temporary directory
$tempDir = Join-Path -Path $env:TEMP -ChildPath $([System.Guid]::NewGuid())
New-Item $tempDir -ItemType Directory -Force | Out-Null
Push-Location $tempDir

# Brave
if ($Brave) {
	Write-Host "Installing Brave..."
	& curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" -o "$tempDir\BraveSetup.exe"
	if (!$?) {
		Write-Error "Downloading Brave failed."
		exit 1
	}

	& "$tempDir\BraveSetup.exe" /silent /install 2>&1 | Out-Null

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

# Firefox
if ($Firefox) {
	Write-Host "Installing Firefox..."
	& curl.exe -LSs "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -o "$tempDir\firefox.exe"
	Start-Process -FilePath "$tempDir\firefox.exe" -WindowStyle Hidden -ArgumentList '/S /ALLUSERS=1' -Wait 2>&1 | Out-Null
	exit
}

# Chrome
if ($Chrome) {
	Write-Host "Installing Google Chrome..."
	& curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -o "$tempDir\chrome.msi"
	Start-Process -FilePath "$tempDir\chrome.msi" -WindowStyle Hidden -ArgumentList '/qn' -Wait 2>&1 | Out-Null
	exit
}

#################
##    MEDIA    ##
#################

# mpv
# if ($mpv) {
#	Write-Host "Installing mpv..."
#	& curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -o "$tempDir\chrome.msi"
#	Start-Process -FilePath "$tempDir\chrome.msi" -WindowStyle Hidden -ArgumentList '/qn' -Wait 2>&1 | Out-Null
#	exit
#}

# MPC-HC
if ($mpchc) {
	Write-Host "Installing MPC-HC..."
	$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/clsid2/mpc-hc/releases/latest"
	$link = $latestRelease.assets | Where-Object { $_.browser_download_url -like "*x64.exe" } | Select-Object -ExpandProperty browser_download_url
	& curl.exe -LSs "$link" -o "$tempDir\mpc-hc.exe"
	Start-Process -FilePath "$tempDir\mpc-hc.exe" -WindowStyle Hidden -ArgumentList '/VERYSILENT /NORESTART' -Wait 2>&1 | Out-Null
	exit
}

# VLC
if ($vlc) {
	Write-Host "Installing VLC..."
	$baseUrl = "https://get.videolan.org/vlc/last/win64/"
	$fileName = $((Invoke-WebRequest -Uri $baseUrl -UseBasicParsing).Links | Where-Object { $_.Href -like 'vlc*.exe' } | Select-Object -First 1 -ExpandProperty Href)
	& curl.exe -LSs "$baseUrl$fileName" -o "$tempDir\vlc.exe"
	Start-Process -FilePath "$tempDir\vlc.exe" -WindowStyle Hidden -ArgumentList '/S' -Wait 2>&1 | Out-Null
	exit
}

# Notepad++
if ($npp) {
	Write-Host "Installing Notepad++..."
	$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest"
	$link = $latestRelease.assets | Where-Object { $_.browser_download_url -like "*x64.exe" } | Select-Object -ExpandProperty browser_download_url
	& curl.exe -LSs "$link" -o "$tempDir\npp.exe"
	Start-Process -FilePath "$tempDir\npp.exe" -WindowStyle Hidden -ArgumentList '/S' -Wait 2>&1 | Out-Null
	exit
}

# VSCode
if ($vscode) {
	Write-Host "Installing VSCode..."
	& curl.exe -LSs "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -o "$tempDir\vscode.exe"
	Start-Process -FilePath "$tempDir\vscode.exe" -WindowStyle Hidden -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode' -Wait 2>&1 | Out-Null
	exit
}
 
# VSCodium
if ($vscodium) {
	Write-Host "Installing VSCodium..."
	$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
	$link = $latestRelease.assets | Where-Object { $_.browser_download_url -like "*VSCodiumSetup-x64*" -and $_.browser_download_url -like "*.exe" } | Select-Object -ExpandProperty browser_download_url
	& curl.exe -LSs "$link" -o "$tempDir\vscodium.exe"
	Start-Process -FilePath "$tempDir\vscodium.exe" -WindowStyle Hidden -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode' -Wait 2>&1 | Out-Null
	exit
}

####################
##    Software    ##
####################

# Visual C++ Runtimes (referred to as vcredists for short)
# https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist
$legacyArgs1 = '/Q'
$legacyArgs2 = '/q /norestart'
$modernArgs = "/install /quiet /norestart"

$vcredists = @{
	# 2005 - version 8.0.50727.6195 (MSI 8.0.61000/8.0.61001) SP1
	"https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe" = $legacyArgs1
	"https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe" = $legacyArgs1
	# 2008 - version 9.0.30729.6161 (EXE 9.0.30729.5677) SP1
	"https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe" = $legacyArgs1
	"https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" = $legacyArgs1
	# 2010 - version 10.0.40219.325 SP1
	"https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe" = $legacyArgs2
	"https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe" = $legacyArgs2
	# 2012 - version 11.0.61030.0
	"https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" = $modernArgs
	"https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe" = $modernArgs
	# 2013 - version 12.0.40664.0
	"https://aka.ms/highdpimfc2013x64enu" = $modernArgs
	"https://aka.ms/highdpimfc2013x86enu" = $modernArgs
	# 2015-2022 (2015+) - latest version
	"https://aka.ms/vs/17/release/vc_redist.x64.exe" = $modernArgs
	"https://aka.ms/vs/17/release/vc_redist.x86.exe" = $modernArgs
}
$num = 0; foreach ($a in $vcredists.GetEnumerator()) {
	$num++; $vcredist = "$tempDir\vcredist$num.exe"
	# curl is faster than Invoke-WebRequest
	Write-Host "Installing Visual C++ Runtime $num..."
	& curl.exe -LSs "$($a.Name)" -o "$vcredist"
	Start-Process -FilePath $vcredist -WindowStyle Hidden -ArgumentList $a.Value -Wait 2>&1 | Out-Null
}

# 7-Zip
$website = 'https://7-zip.org/'
$download = $website + ((Invoke-WebRequest $website -UseBasicParsing).Links.href | Where-Object { $_ -like "a/7z2301-x64.exe" })
& curl.exe -LSs $download -o "$tempDir\7zip.exe"
Start-Process -FilePath "$tempDir\7zip.exe" -WindowStyle Hidden -ArgumentList '/S' -Wait 2>&1 | Out-Null

# Legacy DirectX runtimes
& curl.exe -LSs "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -o "$tempDir\directx.exe"
Write-Host "Extracting legacy DirectX runtimes..."
Start-Process -FilePath "$tempDir\directx.exe" -WindowStyle Hidden -ArgumentList "/q /c /t:`"$tempDir\directx`"" -Wait 2>&1 | Out-Null
Write-Host "Installing legacy DirectX runtimes..."
Start-Process -FilePath "$tempDir\directx\dxsetup.exe" -WindowStyle Hidden -ArgumentList '/silent' -Wait 2>&1 | Out-Null

# Remove temporary directory
Pop-Location
Remove-Item -Path $tempDir -Force -Recurse *>$null
