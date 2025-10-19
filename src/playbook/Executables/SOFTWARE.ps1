param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$Toolbox
)

.\AtlasModules\initPowerShell.ps1

# ----------------------------------------------------------------------------------------------------------- #
# Software is no longer installed with a package manager anymore to be as fast and as reliable as possible.   #
# ----------------------------------------------------------------------------------------------------------- #

$timeouts = @("--connect-timeout", "10", "--retry", "5", "--retry-delay", "0", "--retry-all-errors")
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"
$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')

# Create a temporary directory
function Remove-TempDirectory { Pop-Location; Remove-Item -Path $tempDir -Force -Recurse -EA 0 }
$tempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Push-Location $tempDir

# Toolbox
if ($Toolbox) {
	& curl.exe -LSs "https://github.com/Atlas-OS/atlas-toolbox/releases/latest/download/AtlasToolbox-Setup.exe" -o "$tempDir\toolbox.exe" $timeouts
	if (!$?) {
		Write-Error "Downloading Toolbox failed."
		exit 1
	}

	Write-Output "Installing Toolbox..."
	$toolboxProcess = Start-Process -FilePath "$tempDir\toolbox.exe" -WindowStyle Hidden -ArgumentList '/verysilent /install /MERGETASKS="desktopicon"' -Wait -PassThru
	if ($toolboxProcess.ExitCode -ne 0) {
		Write-Error "Atlas Toolbox installer exited with code $($toolboxProcess.ExitCode)."
		Remove-TempDirectory
		exit $toolboxProcess.ExitCode
	}

	Remove-TempDirectory

	exit
}


# Brave
if ($Brave) {
    Write-Output "Downloading Brave..."
    & curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" -o "$tempDir\BraveSetup.exe" $timeouts
    if (!$?) {
        Write-Error "Downloading Brave failed."
        exit 1
    }

    Write-Output "Installing Brave..."
    Start-Process -FilePath "$tempDir\BraveSetup.exe" -WindowStyle Hidden -ArgumentList '/silent /install'

    do {
        $processesFound = Get-Process | Where-Object { "BraveSetup" -contains $_.Name } | Select-Object -ExpandProperty Name
        if ($processesFound) {
            Write-Output "Still running BraveSetup."
            Start-Sleep -Seconds 2
        }
        else {
            Remove-TempDirectory
        }
    } until (!$processesFound)

    Stop-Process -Name "brave" -Force -EA 0

    exit
}


# Firefox
if ($Firefox) {
    $firefoxArch = ('win64', 'win64-aarch64')[$arm]

    Write-Output "Downloading Firefox..."
    & curl.exe -LSs "https://download.mozilla.org/?product=firefox-latest-ssl&os=$firefoxArch&lang=en-US" -o "$tempDir\firefox.exe" $timeouts
    Write-Output "Installing Firefox..."
    Start-Process -FilePath "$tempDir\firefox.exe" -WindowStyle Hidden -ArgumentList '/S /ALLUSERS=1' -Wait

    Remove-TempDirectory
    exit
}

# Chrome
if ($Chrome) {
    Write-Output "Downloading Google Chrome..."
    $chromeArch = ('64', '_Arm64')[$arm]
    & curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi" -o "$tempDir\chrome.msi" $timeouts
    Write-Output "Installing Google Chrome..."
    Start-Process -FilePath "$tempDir\chrome.msi" -WindowStyle Hidden -ArgumentList '/qn' -Wait

    Remove-TempDirectory
    exit
}

#####################
##    Utilities    ##
#####################

# Visual C++ Runtimes (referred to as vcredists for short)
# https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist
$legacyArgs = '/q /norestart'
$modernArgs = "/install /quiet /norestart"

$vcredists = [ordered] @{
    # 2005 - version 8.0.50727.6195 (MSI 8.0.61000/8.0.61001) SP1
    "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe"       = @("2005-x64", "/c /q /t:")
    "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe"       = @("2005-x86", "/c /q /t:")
    # 2008 - version 9.0.30729.6161 (EXE 9.0.30729.5677) SP1
    "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"       = @("2008-x64", "/q /extract:")
    "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"       = @("2008-x86", "/q /extract:")
    # 2010 - version 10.0.40219.325 SP1
    "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"       = @("2010-x64", $legacyArgs)
    "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"       = @("2010-x86", $legacyArgs)
    # 2012 - version 11.0.61030.0
    "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" = @("2012-x64", $modernArgs)
    "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe" = @("2012-x86", $modernArgs)
    # 2013 - version 12.0.40664.0
    "https://aka.ms/highdpimfc2013x64enu"                                                                       = @("2013-x64", $modernArgs)
    "https://aka.ms/highdpimfc2013x86enu"                                                                       = @("2013-x86", $modernArgs)
    # 2015-2022 (2015+) - latest version
    "https://aka.ms/vs/17/release/vc_redist.x64.exe"                                                            = @("2015+-x64", $modernArgs)
    "https://aka.ms/vs/17/release/vc_redist.x86.exe"                                                            = @("2015+-x86", $modernArgs)
}
foreach ($a in $vcredists.GetEnumerator()) {
    $vcName = $a.Value[0]
    $vcArgs = $a.Value[1]
    $vcUrl = $a.Name
    $vcExePath = "$tempDir\vcredist-$vcName.exe"

    # curl is faster than Invoke-WebRequest
    Write-Output "Downloading and installing Visual C++ Runtime $vcName..."
    & curl.exe -LSs "$vcUrl" -o "$vcExePath" $timeouts

    if ($vcArgs -match ":") {
        $msiDir = "$tempDir\vcredist-$vcName"
        Start-Process -FilePath $vcExePath -ArgumentList "$vcArgs`"$msiDir`"" -Wait -WindowStyle Hidden

        $msiPaths = (Get-ChildItem -Path $msiDir -Filter *.msi -EA 0).FullName
        if (!$msiPaths) {
            Write-Output "Failed to extract MSI for $vcName, not installing."
        }
        else {
            $msiPaths | ForEach-Object {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/log `"$msiDir\logfile.log`" /i `"$_`" $msiArgs" -WindowStyle Hidden -Wait
            }
        }
    }
    else {
        Start-Process -FilePath $vcExePath -ArgumentList $vcArgs -Wait -WindowStyle Hidden
    }
}


# NanaZip
function Install7Zip {
    $website = 'https://7-zip.org/'
    $7zipArch = ('x64', 'arm64')[$arm]
    $download = $website + ((Invoke-WebRequest $website -UseBasicParsing).Links.href | Where-Object { $_ -like "a/7z*-$7zipArch.exe" })
    Write-Output "Downloading 7-Zip..."
    & curl.exe -LSs $download -o "$tempDir\7zip.exe" $timeouts
    Write-Output "Installing 7-Zip..."
    Start-Process -FilePath "$tempDir\7zip.exe" -WindowStyle Hidden -ArgumentList '/S' -Wait
}

$githubApi = Invoke-RestMethod "https://api.github.com/repos/M2Team/NanaZip/releases/latest" -EA 0
$assets = @()
if ($githubApi -and $githubApi.Assets) {
    $assets = @($githubApi.Assets.browser_download_url | Where-Object { $_ -match '\.xml$' -or $_ -match '\.msixbundle$' } | Select-Object -Unique -First 2)
}
function InstallNanaZip {
    Write-Output "Downloading NanaZip..."
    $path = New-Item "$tempDir\nanazip" -ItemType Directory
    $assets | ForEach-Object {
        $filename = $_ -split '/' | Select-Object -Last 1
        Write-Output "Downloading '$filename'..."
        & curl.exe -LSs $_ -o "$path\$filename" $timeouts
    }

    Write-Output "Installing NanaZip..."
    try {
        $appxArgs = @{
            "PackagePath" = (Get-ChildItem $path -Filter "*.msixbundle" | Select-Object -First 1).FullName
            "LicensePath" = (Get-ChildItem $path -Filter "*.xml" | Select-Object -First 1).FullName
        }
        Add-AppxProvisionedPackage -Online @appxArgs | Out-Null

        Write-Output "Installed NanaZip!"
    }
    catch {
        Write-Error "Failed to install NanaZip! Getting 7-Zip instead. $_"
        Install7Zip
    }
}

if ($assets.Count -eq 2) {
    $7zipRegistry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip"
    if (Test-Path $7zipRegistry) {
        $Message = @'
Would you like to uninstall 7-Zip and replace it with NanaZip?

NanaZip is a fork of 7-Zip with an updated user interface and extra features.
'@

        if ((Read-MessageBox -Title 'Installing NanaZip - Atlas' -Body $Message -Icon Question) -eq 'Yes') {
			$7zipUninstall = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" -Name "QuietUninstallString" -EA 0).QuietUninstallString
			if ([string]::IsNullOrWhiteSpace($7zipUninstall)) {
				Write-Warning "7-Zip QuietUninstallString is missing; skipping automatic removal."
			}
			else {
				Write-Output "Uninstalling 7-Zip..."
				Start-Process -FilePath "cmd.exe" -WindowStyle Hidden -ArgumentList '/c', $7zipUninstall -Wait
			}
			InstallNanaZip
		}
	}
    else {
        InstallNanaZip
    }
}
else {
    Write-Error "Can't access GitHub API, downloading 7-Zip instead of NanaZip."
    Install7Zip
}

# Legacy DirectX runtimes
& curl.exe -LSs "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -o "$tempDir\directx.exe" $timeouts
Write-Output "Extracting legacy DirectX runtimes..."
Start-Process -FilePath "$tempDir\directx.exe" -WindowStyle Hidden -ArgumentList "/q /c /t:`"$tempDir\directx`"" -Wait
Write-Output "Installing legacy DirectX runtimes..."
Start-Process -FilePath "$tempDir\directx\dxsetup.exe" -WindowStyle Hidden -ArgumentList '/silent' -Wait

# Remove temporary directory
Remove-TempDirectory
