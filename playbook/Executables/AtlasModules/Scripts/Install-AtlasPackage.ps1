#Requires -RunAsAdministrator

# GPL-3.0-only license
# Modified from: https://github.com/he3als/online-sxs
#
# Interactive shell around the Atlas.Software CBS package engine
# (Install-AtlasCbsPackage / Uninstall-AtlasCbsPackage). This script stays at this
# exact path because toolbox scripts (Internal\Set-DefenderState.ps1,
# Internal\Remove-TelemetryComponents.ps1) invoke it. Install phases call the module
# functions directly instead.

param (
	[array]$InstallPackages,
	[array]$UninstallPackages,
	[string]$PackagesPath = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Packages",
	[switch]$NoInteraction
)

Set-StrictMode -Version 3.0

if (!([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18')) {
	throw 'This script must be run as TrustedInstaller or SYSTEM.'
}

# ======================================================================================================================= #
# INITIAL VARIABLES                                                                                                       #
# ======================================================================================================================= #
$windir = [Environment]::GetFolderPath('Windows')
$atlasModulesRoot = Split-Path -Parent $PSScriptRoot
$modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
$cbsRetryScript = Join-Path -Path $PSScriptRoot -ChildPath 'Internal\CbsRetry.ps1'
if (!(Test-Path -LiteralPath $cbsRetryScript -PathType Leaf)) {
	throw "Required CBS retry helper '$cbsRetryScript' is missing."
}
$helperItem = Get-Item -LiteralPath $cbsRetryScript -Force -ErrorAction Stop
if (($helperItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
	throw "Required CBS retry helper '$cbsRetryScript' is a reparse point."
}
. $cbsRetryScript -LibraryOnly

& (Join-Path -Path $atlasModulesRoot -ChildPath 'initPowerShell.ps1')
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force -ErrorAction Stop
$sys32 = [Environment]::GetFolderPath('System')
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$script:errorLevel = 0
$script:warningLevel = 0
$script:retryPackages = @()
$literalPackages = $null

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

		if (@($script:retryPackages).Count -eq 0) {
			Write-Host 'The failed packages are not eligible for a Safe Mode retry.' -ForegroundColor Red
			NoRestart
			exit $script:errorLevel
		}
		choice /c yn /n /m "Would you like to arm a Safe Mode retry? [Y/N] "
		if ($lastexitcode -eq 1) {
			$retryPaths = @($script:retryPackages | ForEach-Object { [string]$_.Path })
			[void](Enable-AtlasCbsRetry -Packages $retryPaths)
			Write-Host 'Safe Mode retry armed. Run CbsRetry.ps1 -Recover from the Safe Mode command prompt.' -ForegroundColor Yellow
			Restart
		} else {
			NoRestart
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
	# Zero CABs matched, or a NoInteraction failure after the module armed a retry.
	Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
	$script:errorLevel++
	if (!$NoInteraction) { Read-Pause }
	exit $script:errorLevel
}

$script:errorLevel += @($installResult.FailedPackages).Count
$script:warningLevel += @($installResult.UnmatchedPatterns).Count
$script:retryPackages = @($installResult.RetryPackages)

# ======================================================================================================================= #
# RESTART                                                                                                                 #
# ======================================================================================================================= #
Finish $installResult.FailedPackages
