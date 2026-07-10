#Requires -RunAsAdministrator

# GPL-3.0-only license
# Modified from: https://github.com/he3als/online-sxs
#
# Interactive shell around the Atlas.Software CBS package engine
# (Install-AtlasCbsPackage / Uninstall-AtlasCbsPackage). This script stays at this
# exact path because the Safe Mode Winlogon shell value, the AtlasFailedComponentMsgBox
# scheduled task and the toolbox scripts (Internal\Set-DefenderState.ps1,
# Internal\Remove-TelemetryComponents.ps1) all invoke it. The install phases call the module
# functions directly instead.

param (
	[array]$InstallPackages,
	[array]$UninstallPackages,
	[string]$PackagesPath = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Packages",
	[switch]$NoInteraction,
	[switch]$SafeMode,
	[switch]$FailMessage
)

Set-StrictMode -Version 3.0

if (!([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18')) {
	throw "This script must be ran as TrustedInstaller/SYSTEM."
}

# ======================================================================================================================= #
# INITIAL VARIABLES                                                                                                       #
# ======================================================================================================================= #
$windir = [Environment]::GetFolderPath('Windows')
$atlasModulesRoot = Split-Path -Parent $PSScriptRoot
$modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
& (Join-Path -Path $atlasModulesRoot -ChildPath 'initPowerShell.ps1')
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force -ErrorAction Stop
$sys32 = [Environment]::GetFolderPath('System')
$safeModePackageList = "$sys32\safeModePackagesToInstall.atlasmodule"
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$script:errorLevel = 0
$script:warningLevel = 0

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

function Set-AtlasSafeBoot {
	param (
		[switch]$Enable,
		[array]$FailedPackageList,
		[string]$FailedPackageListPath = $safeModePackageList
	)

	if ($Enable) {
		$bcdeditArgs = '/set {current} safeboot minimal'
		$shellValue = "explorer.exe,cmd /c RunAsTI powershell -NoP -EP RemoteSigned -File `"$PSCommandPath`" -SafeMode"

		if ($FailedPackageList) {
			Set-Content -Path $FailedPackageListPath -Value $FailedPackageList
		}
	} else {
		$bcdeditArgs = '/deletevalue {current} safeboot'
		$shellValue = 'explorer.exe'
	}

	if ($bcdeditArgs) { Start-Process -FilePath "bcdedit" -ArgumentList $bcdeditArgs -WindowStyle Hidden -Wait }
	Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value $shellValue -Force
}
if (
	($safeModeStatus -and
	(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell).Shell -like "*$PSCommandPath*") -or
	$SafeMode
) {
	Set-AtlasSafeBoot
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
	$failedPackages = @($failedPackages | Where-Object { $_ })

	function GenerateText($text, $dashCount = 84) {
		$separator = "[ $('-' * $dashCount) ]"
		$text = "[ $text $(' ' * ($dashCount - $text.Length - 1)) ]"
		return @"
$separator
$text
$separator
"@
	}

	Write-Host "`n$(GenerateText "Completed! Errors: $script:errorLevel | Warnings: $script:warningLevel")`n" -ForegroundColor Green

	if ($failedPackages.Count -gt 0) {
		Write-Host "Some packages failed to install:" -ForegroundColor Red
		Write-BulletPoint $failedPackages

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
				Set-AtlasSafeBoot -Enable -FailedPackageList $failedPackages
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
	$uninstallResult = Uninstall-AtlasCbsPackage -Packages $UninstallPackages
	$script:errorLevel += @($uninstallResult.FailedPackages).Count
	if ((@($uninstallResult.RemovedPackages).Count + @($uninstallResult.FailedPackages).Count) -eq 0) {
		$script:warningLevel++
	} elseif (@($uninstallResult.UnmatchedPatterns).Count -gt 0) {
		$script:warningLevel++
	}

	if (!$InstallPackages) {
		Finish
	}
}

# ======================================================================================================================= #
# SAFE MODE PACKAGE LIST                                                                                                  #
# ======================================================================================================================= #
$literalPackages = $null
if ($SafeMode) {
	function ExitSafeModePrompt {
		choice /c yn /n /m "Would you like to restart to get out of Safe Mode? [Y/N] "
		if ($lastexitcode -eq 1) {
			Restart
		} else {
			exit 1
		}
	}

	$literalPackages = @(Get-Content $safeModePackageList -ErrorAction SilentlyContinue)

	if ($literalPackages.Count -le 0) {
		Write-Host "[ERROR] Safe Mode package list not found! Please report this to Atlas." -ForegroundColor Red
		ExitSafeModePrompt
	}

	$packagesThatDontExist = $literalPackages | ForEach-Object { if (!(Test-Path $_ -PathType Leaf)) { $_ } }
	if ($packagesThatDontExist) {
		Write-Host "[ERROR] Some Safe Mode packages weren't found. Please report this to Atlas." -ForegroundColor Red
		Write-BulletPoint $packagesThatDontExist
		ExitSafeModePrompt
	}
}

# ======================================================================================================================= #
# FAIL MESSAGE                                                                                                            #
# ======================================================================================================================= #
if ($FailMessage) {
	$body = @"
It appears that there was an issue while attempting to disable certain Windows components.

Would you like Atlas to restart your system into Safe Mode and try again? This process shouldn't take much time.

Please note that if you chose to disable Windows Defender, it may still remain enabled if you select 'No'. However, you can always try disabling it later in the Atlas folder.
"@

	if ((Read-MessageBox -Title "Atlas - Component Modification" -Body $body -Icon Question) -eq 'Yes') {
		Set-AtlasSafeBoot -Enable
		Restart
	}

	exit
}

# ======================================================================================================================= #
# UI - SELECT PACKAGES                                                                                                    #
# ======================================================================================================================= #
if (!$InstallPackages -and !$literalPackages) {
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
	$literalPackages = @($openFileDialog.FileNames)
}

# ======================================================================================================================= #
# PROCESS PACKAGES                                                                                                        #
# ======================================================================================================================= #
try {
	if ($literalPackages) {
		$installResult = Install-AtlasCbsPackage -Packages $literalPackages -LiteralPaths -NonInteractive:$NoInteraction
	} else {
		$installResult = Install-AtlasCbsPackage -Packages $InstallPackages -PackagesPath $PackagesPath -NonInteractive:$NoInteraction
	}
} catch {
	# Zero CABs matched, or a NoInteraction failure (the module already registered the
	# Safe Mode retry fallback and the next-boot message box in that case).
	Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
	$script:errorLevel++
	if (!$NoInteraction) { Read-Pause }
	exit $script:errorLevel
}

$script:errorLevel += @($installResult.FailedPackages).Count
$script:warningLevel += @($installResult.UnmatchedPatterns).Count

# ======================================================================================================================= #
# RESTART                                                                                                                 #
# ======================================================================================================================= #
Finish $installResult.FailedPackages
