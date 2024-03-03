#Requires -RunAsAdministrator

# GPL-3.0-only license
# 🦆 Modified from: https://github.com/he3als/online-sxs

param (
	[array]$InstallPackages,
	[array]$UninstallPackages,
	[string]$PackagesPath = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Packages",
	[switch]$NoInteraction,
	[switch]$SafeMode
)

# ======================================================================================================================= #
# INITIAL VARIABLES                                                                                                       #
# ======================================================================================================================= #
$sys32 = [Environment]::GetFolderPath('System')
$safeModePackageList = "$sys32\safeModePackagesToInstall.atlasmodule"
$env:path = "$([Environment]::GetFolderPath('Windows'));$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates"
$errorLevel = $warningLevel = 0

$arm = ((Get-CimInstance -Class Win32_OperatingSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$armString = if ($arm) {'arm64'} else {'amd64'}

$safeModeStatus = (Get-CimInstance -Class Win32_ComputerSystem).BootupState -ne 'Normal boot'

# ======================================================================================================================= #
# FUNCTIONS                                                                                                               #
# ======================================================================================================================= #
function Pause ($message = "Press Enter to exit") {
	$null = Read-Host $message
}

function SafeMode {
    param (
        [switch]$Enable
    )

    if ($Enable) {
        $bcdeditArgs = '/set {current} safeboot minimal'
        $shellValue = "cmd /c start explorer.exe & powershell -NoP -EP Unrestricted -File `"$PSCommandPath`" -SafeMode"
    } else {
        $bcdeditArgs = '/deletevalue {current} safeboot'
        $shellValue = 'explorer.exe'
    }

    bcdedit $bcdeditArgs | Out-Null
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value $shellValue -Force
}
if (
	($safeModeStatus -and
	(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell).Shell -like "*$PSCommandPath*") -or
	$SafeMode
) {
	SafeMode
}

function Restart {
	shutdown /f /r /t 0 *>$null
    Start-Sleep 2
    Restart-Computer
    Start-Sleep 2
    Write-Host "Something seems to have went wrong restarting automatically, restart manually." -ForegroundColor Red
    if (!$NoInteraction) { Pause }
    exit 9000
}

function Finish($failedPackages) {
	function GenerateText($text, $dashCount = 84) {
		$seperator = "[ $('-' * $dashCount) ]"
		$text = "[ $text $(' ' * ($dashCount - $text.Length - 1)) ]"
		return @"
$seperator
$text
$seperator
"@
	}

	Write-Host "`n$(GenerateText "Completed! Errors: $script:errorLevel | Warnings: $script:warningLevel")`n" -ForegroundColor Green

	if ($failedPackages.Count -gt 0) {
		Write-Host "Some packages failed to install:" -ForegroundColor Red
		$failedPackages | % {
			Write-Host " - '$_'"
		}
		Write-Host ""

		if ($NoInteraction) {
			Write-Host "Setting Safe Mode automatically as NoInteraction is enabled."
			SafeMode
			exit $script:errorLevel
		}

		if ($safeModeStatus) {
			Write-Host "Please report this to the Atlas team, as nothing else can be done past Safe Mode."
			Write-Host "."
		}
		choice /c yn /n /m "Would you like to boot into Safe mode and attempt to install them? [Y/N] "
		if ($lastexitcode -eq 1) {
			SafeMode -Enable
			Restart
		} else {
			Write-Host "`nIf any packages installed successfully, they will apply next restart." -ForegroundColor Yellow
			Pause
			exit $script:errorLevel
		}
	}

	if ($NoInteraction) { exit $script:errorLevel }
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {
		Restart
	} else {
		Write-Host "`nChanges will apply next restart." -ForegroundColor Yellow
		Pause
		exit $script:errorLevel
	}
}

# ======================================================================================================================= #
# UNINSTALL PACKAGES                                                                                                      #
# ======================================================================================================================= #
if ($UninstallPackages) {
	$installedPackages = @()
	$notInstalledPackages = $UninstallPackages
	(Get-WindowsPackage -Online).PackageName | ForEach-Object {
		foreach ($package in $UninstallPackages) {
			if (($_ -like $package) -and ($_ -like "*$armString*")) {
				$installedPackages += $_
				$notInstalledPackages = $notInstalledPackages -ne $package
				break
			}
		}
	}

	if ($installedPackages.Count -eq 0) {
		Write-Host "[WARN] '$UninstallPackages' matched no installed packages, nothing to do." -ForegroundColor Yellow
		$script:warningLevel++
	} else {
		if ($notMatchedPackages.Count -gt 0) {
			Write-Host "[WARN] Some packages not found to uninstall: $notMatchedPackages" -ForegroundColor Yellow
			$script:warningLevel++
		}

		foreach ($package in $installedPackages) {
			try {
				Write-Host "[INFO] Uninstalling '$package'..."
				Remove-WindowsPackage -Online -PackageName $package -NoRestart -LogLevel 1 *>$null
			} catch {
				Write-Host "[ERROR] $package failed to uninstall: $_" -ForegroundColor Red
				$script:errorLevel++
			}
		}
	}

	if (!$InstallPackages) {
		Finish
	}
}

# ======================================================================================================================= #
# PARSE $InstallPackages ARG                                                                                                     #
# ======================================================================================================================= #
if ($InstallPackages) {
	$matchedPackages = @()
	$notMatchedPackages = $InstallPackages
	(Get-ChildItem $PackagesPath -File -Filter "*.cab").FullName | ForEach-Object {
		foreach ($package in $InstallPackages) {
			if (($_ -like $package) -and ($_ -like "*$armString*")) {
				$matchedPackages += $_
				$notMatchedPackages = $notMatchedPackages -ne $package
				break
			}
		}
	}

	if ($matchedPackages.Count -eq 0) {
		Write-Host "[ERROR] The specified CABs ($InstallPackages) to install weren't found." -ForegroundColor Red
		if (!$NoInteraction) { Pause }
		exit 1
	}
	if ($notMatchedPackages.Count -gt 0) {
		Write-Host "[WARN] These CABs to install weren't found: $notMatchedPackages" -ForegroundColor Yellow
		$script:warningLevel++
	}
}

if ($SafeMode) {
	$matchedPackages = Get-Content $safeModePackageList
	if ((Test-Path $matchedPackages -PathType Leaf) -contains $false) {
		Write-Host "[ERROR] Some Safe Mode packages weren't found. Please report this to Atlas.`n$matchedPackages`n" -ForegroundColor Red
		choice /c yn /n /m "Would you like to restart to get out of Safe Mode? [Y/N] "
		if ($lastexitcode -eq 1) {
			Restart
		} else {
			exit 1
		}
	}
}

# ======================================================================================================================= #
# UI - SELECT PACKAGES                                                                                                    #
# ======================================================================================================================= #
if (!$matchedPackages) {
	Write-Host "This will install specified CBS packages online, meaning live on your current install of Windows." -ForegroundColor Yellow
	Pause "Press Enter to continue"
	
	Write-Host "`n[INFO] Opening file dialog to select CBS package CAB..."
	Add-Type -AssemblyName System.Windows.Forms
	$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$openFileDialog.Multiselect = $true
	$openFileDialog.Filter = "CBS Package Files (*.cab)|*.cab"
	$openFileDialog.Title = "Select a CBS Package File"
	if ($openFileDialog.ShowDialog() -ne 'OK') {
		exit
	}
}

# ======================================================================================================================= #
# PROCESS PACKAGES                                                                                                        #
# ======================================================================================================================= #
function ProcessCab($cabPath) {
	try {
		$filePath = Split-Path $cabPath -Leaf
		Write-Host "`nInstalling $filePath..." -ForegroundColor Cyan
		Write-Host ("-" * 84) -ForegroundColor Magenta

		Write-Host "[INFO] Importing and checking certificate..."
		try {
			$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
			foreach ($usage in $cert.Extensions.EnhancedKeyUsages) {
				if ($usage.Value -ne "1.3.6.1.4.1.311.10.3.6") {
					$correctUsage = $true
					break
				}
			}
			if (!$correctUsage) {
				Write-Host "[ERROR] Cert doesn't have Windows System Component Verification, can't continue." -ForegroundColor Red
				$scr:errorLevel++
				return $false
			}
			
			$certPath = [System.IO.Path]::GetTempFileName()
			[System.IO.File]::WriteAllBytes($certPath, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
			Import-Certificate $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
			Copy-Item -Path "$certRegPath\$($cert.Thumbprint)" "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force | Out-Null
		} catch {
			Write-Host "[ERROR] Cert error from '$cabPath': $_" -ForegroundColor Red
			$script:errorLevel++
			return $false
		}

		Write-Host "[INFO] Adding package..."
		try {
			Add-WindowsPackage -Online -PackagePath $cabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
		} catch {
			Write-Host "[ERROR] Error when adding package '$cabPath': $_" -ForegroundColor Red
			$script:errorLevel++
			return $false
		}
	} finally {
		Write-Host "[INFO] Cleaning up certificates..."
		Get-ChildItem "Cert:\LocalMachine\Root\$($cert.Thumbprint)" | Remove-Item -Force | Out-Null
		Remove-Item "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force -Recurse | Out-Null
	}

	return $true
}

if ($matchedPackages) {
	$packagesToProcess = $matchedPackages
} else {
	$packagesToProcess = $openFileDialog.FileNames
}

$failedPackages = @()
$packagesToProcess | ForEach-Object {
	if (!(ProcessCab $_)) {
		$failedPackages += $_
	}
}

# ======================================================================================================================= #
# RESTART                                                                                                                 #
# ======================================================================================================================= #
Finish $failedPackages