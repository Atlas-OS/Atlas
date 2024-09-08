#Requires -RunAsAdministrator

# GPL-3.0-only license
# 🦆 Modified from: https://github.com/he3als/online-sxs

param (
	[array]$InstallPackages,
	[array]$UninstallPackages,
	[string]$PackagesPath = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Packages",
	[switch]$NoInteraction,
	[switch]$SafeMode,
	[switch]$FailMessage
)

if (!([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18')) {
	throw "This script must be ran as TrustedInstaller/SYSTEM."
}

# ======================================================================================================================= #
# INITIAL VARIABLES                                                                                                       #
# ======================================================================================================================= #
$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"
$sys32 = [Environment]::GetFolderPath('System')
$safeModePackageList = "$sys32\safeModePackagesToInstall.atlasmodule"
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$errorLevel = $warningLevel = 0

$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$arch = if ($arm) {'arm64'} else {'amd64'}

$safeModeStatus = (Get-CimInstance -Class Win32_ComputerSystem).BootupState -ne 'Normal boot'

# ======================================================================================================================= #
# FUNCTIONS                                                                                                               #
# ======================================================================================================================= #
function Write-BulletPoint($message) {
	$message | Foreach-Object {
		Write-Host " - " -ForegroundColor Green -NoNewline
		Write-Host $_
	}
	Write-Host ""
}

function SafeMode {
	param (
		[switch]$Enable,
		[switch]$FailMessage,
		[array]$FailedPackageList,
		[string]$FailedPackageListPath = $safeModePackageList
	)

	if ($Enable) {
		$bcdeditArgs = '/set {current} safeboot minimal'
		$shellValue = "explorer.exe,cmd /c RunAsTI powershell -NoP -EP Unrestricted -File `"$PSCommandPath`" -SafeMode"

		if ($FailedPackageList) {
			Set-Content -Path $FailedPackageListPath -Value $FailedPackageList
		}
	} else {
		$bcdeditArgs = '/deletevalue {current} safeboot'
		$shellValue = 'explorer.exe'
	}

	if ($bcdeditArgs) { Start-Process -FilePath "bcdedit" -ArgumentList $bcdeditArgs -WindowStyle Hidden }
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
	if (!$NoInteraction) { Read-Pause }
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
		Write-BulletPoint $failedPackages

		if ($NoInteraction) {
			Write-Host "Setting error message box next boot as NoInteraction is enabled."
			Set-Content -Path $safeModePackageList -Value $failedPackages

			$failedMsgTitle = 'AtlasFailedComponentMsgBox'
			$failedMsgArgs = "/c title Finalizing Installation - Atlas & echo Do not close this window. & schtasks /delete /tn `"$failedMsgTitle`" /f > nul & " `
			+ "PowerShell -NoP -NonI -W Hidden -EP Bypass -C `"& '$PSCommandPath' -FailMessage`""
			$failedMsg = @{
				'TaskName'    = $failedMsgTitle
				'Settings'    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
				'Trigger'     = New-ScheduledTaskTrigger -AtLogOn
				'User'        = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
				'Force'       = $true
				'RunLevel'    = 'Highest'
				'Action'      = New-ScheduledTaskAction -Execute 'cmd' -Argument $failedMsgArgs
			}
			Register-ScheduledTask @failedMsg	

			exit $script:errorLevel
		}

		function NoRestart {
			Write-Host "`nIf any packages installed successfully, they will apply next restart." -ForegroundColor Yellow
			Read-Pause
		}

		if ($safeModeStatus) {
			Write-Host "Please report this to the Atlas team, as there's no automatic fallbacks past Safe Mode." -ForegroundColor Magenta
			choice /c yn /n /m "Would you like to restart out of Safe Mode? [Y/N] "
			if ($lastexitcode -eq 1) {
				Restart
			} else {
				NoRestart
			}
		} else {
			choice /c yn /n /m "Would you like to boot into Safe Mode and attempt to install them? [Y/N] "
			if ($lastexitcode -eq 1) {
				SafeMode -Enable -FailedPackageList $failedPackages
				Restart
			} else {
				NoRestart
			}
		}

		exit $script:errorLevel
	}

	if ($NoInteraction) { exit $script:errorLevel }
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {
		Restart
	} else {
		Write-Host "`nChanges will apply next restart." -ForegroundColor Yellow
		Read-Pause
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
			if (($_ -like $package) -and ($_ -match "$arch")) {
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
	(Get-ChildItem $PackagesPath -File -Filter "*.cab").FullName | Sort-Object -Descending | ForEach-Object {
		foreach ($package in $notMatchedPackages) {
			if (($_ -like $package) -and ($_ -match "$arch")) {
				$matchedPackages += $_
				$notMatchedPackages = $notMatchedPackages -ne $package
				break
			}
		}
	}

	if ($matchedPackages.Count -eq 0) {
		Write-Host "[ERROR] The specified CABs ($InstallPackages) to install weren't found." -ForegroundColor Red
		if (!$NoInteraction) { Read-Pause }
		exit 1
	}
	if ($notMatchedPackages.Count -gt 0) {
		Write-Host "[WARN] These CABs to install weren't found: $notMatchedPackages" -ForegroundColor Yellow
		$script:warningLevel++
	}
}

if ($SafeMode) {
	function ExitSafeModePrompt {
		choice /c yn /n /m "Would you like to restart to get out of Safe Mode? [Y/N] "
		if ($lastexitcode -eq 1) {
			Restart
		} else {
			exit 1
		}
	}

	$matchedPackages = Get-Content $safeModePackageList

	if ($matchedPackages.Count -le 0) {
		Write-Host "[ERROR] Safe Mode package list not found! Please report this to Atlas." -ForegroundColor Red
		ExitSafeModePrompt
	}

	$packagesThatDontExist = $matchedPackages | ForEach-Object { if (!(Test-Path $_ -PathType Leaf)) { $_ } }
	if ($packagesThatDontExist) {
		Write-Host "[ERROR] Some Safe Mode packages weren't found. Please report this to Atlas." -ForegroundColor Red
		Write-BulletPoint $packagesThatDontExist
		ExitSafeModePrompt
	}
}

if ($FailMessage) {
	$body = @"
It appears that there was an issue while attempting to disable certain Windows components.

Would you like Atlas to restart your system into Safe Mode and try again? This process shouldn't take much time.

Please note that if you chose to disable Windows Defender, it may still remain enabled if you select 'No'. However, you can always try disabling it later in the Atlas folder.
"@

	if ((Read-MessageBox -Title "Atlas - Component Modification" -Body $body -Icon Question) -eq 'Yes') {
		SafeMode -Enable
		Restart
	}

	exit
}

# ======================================================================================================================= #
# UI - SELECT PACKAGES                                                                                                    #
# ======================================================================================================================= #
if (!$matchedPackages) {
	Write-Host "This will install specified CBS packages online, meaning live on your current install of Windows." -ForegroundColor Yellow
	Read-Pause "Press Enter to continue"
	
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
	$filePath = Split-Path $cabPath -Leaf
	Write-Host "`nInstalling $filePath..." -ForegroundColor Cyan
	Write-Host ("-" * 84) -ForegroundColor Magenta

	Write-Host "[INFO] Checking certificate..."
	try {
		$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
		if ($cert.Extensions.EnhancedKeyUsages.Value -ne "1.3.6.1.4.1.311.10.3.6") {
			Write-Host "[ERROR] Cert doesn't have proper key usages, can't continue." -ForegroundColor Red
			$script:errorLevel++
			return $false
		}

		# add test cert
		# isn't cleared later as it's required for the alt repair source
		$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344"
		if (!(Test-Path "$certRegPath")) {
			New-Item -Path $certRegPath -Force | Out-Null
		}
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

	Write-Host "[INFO] Completed sucessfully."
	return $true
}

# Fixes RestoreHealth/SFC 'Sources' error
# https://learn.microsoft.com/windows-hardware/manufacture/desktop/configure-a-windows-repair-source
# https://github.com/Atlas-OS/Atlas/issues/1103
function MakeRepairSource {
	$version = '38655.38527.65535.65535'
	$srcPath = "$windir\AtlasModules\Packages\WinSxS"

	Write-Host "`nMaking repair source..." -ForegroundColor Cyan
	Write-Host ("-" * 84) -ForegroundColor Magenta

	# get list of Atlas manifests
	Write-Host "[INFO] Getting manifests..."
	$manifests = Get-ChildItem "$windir\WinSxS\Manifests" -File -Filter "*$version*"
	if ($manifests.Count -eq 0) {
		Write-Host "[WARN] No manifests found! Can't create repair source." -ForegroundColor Yellow
		return $false
	}

	# create new repair source folder
	if (Test-Path $srcPath -PathType Container) {
		Write-Host "[INFO] Deleting old RepairSrc..."
		Remove-Item $srcPath -Force -Recurse
	}
	Write-Host "[INFO] Creating RepairSrc path..."
	New-Item "$srcPath\Manifests" -Force -ItemType Directory | Out-Null

	# hardlink all the manifests to the repair source
	Write-Host "[INFO] Hard linking manifests..."
	foreach ($manifest in $manifests) {
		New-Item -ItemType HardLink -Path "$srcPath\Manifests\$manifest" -Target $manifest.FullName | Out-Null
	}

	# adds the repair source policy
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name LocalSourcePath -Value "$srcPath" -Type ExpandString | Out-Null
}

if ($matchedPackages) {
	$packagesToProcess = $matchedPackages
} else {
	$packagesToProcess = $openFileDialog.FileNames
}

$successPackages = @()
$failedPackages = @()
$packagesToProcess | ForEach-Object {
	if (ProcessCab $_) {
		$successPackages += $_
	} else {
		$failedPackages += $_
	}
}

if ($successPackages.Count -ne 0) {
	MakeRepairSource
}

# ======================================================================================================================= #
# RESTART                                                                                                                 #
# ======================================================================================================================= #
Finish $failedPackages