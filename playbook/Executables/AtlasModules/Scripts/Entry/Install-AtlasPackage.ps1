#Requires -RunAsAdministrator

# GPL-3.0-only license
# Modified from: https://github.com/he3als/online-sxs
#
# Interactive shell around the Atlas.Software CBS package engine
# (Install-AtlasCbsPackage / Uninstall-AtlasCbsPackage). This script stays at this
# exact path because toolbox flows (Atlas.Security's Set-AtlasDefenderState,
# Atlas.Privacy's Remove-AtlasTelemetryComponents) invoke it. Install phases call the module
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
$scriptsRoot = Split-Path -Parent $PSScriptRoot
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
$cbsRetryScript = Join-Path -Path $scriptsRoot -ChildPath 'Operations\CbsRetry.ps1'
if (!(Test-Path -LiteralPath $cbsRetryScript -PathType Leaf)) {
	throw "Required CBS retry helper '$cbsRetryScript' is missing."
}
$helperItem = Get-Item -LiteralPath $cbsRetryScript -Force -ErrorAction Stop
if (($helperItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
	throw "Required CBS retry helper '$cbsRetryScript' is a reparse point."
}
. $cbsRetryScript -LibraryOnly

. (Join-Path -Path $scriptsRoot -ChildPath 'Initialize-AtlasPowerShell.ps1')
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
function Restart {
	shutdown /f /r /t 0 *>$null
	Start-Sleep 2
	Restart-Computer
	Start-Sleep 2
	Write-AtlasFailure -Text 'Windows did not restart automatically. Restart it yourself to finish.'
	if (!$NoInteraction) { Wait-AtlasExit }
	exit 9000
}

function Finish($failedPackages) {
	$failedPackages = @($failedPackages | Where-Object { $_ })

	Write-Host ''
	if ($failedPackages.Count -gt 0) {
		Write-AtlasPartial -Text "$($failedPackages.Count) package(s) failed to install:"
		Write-AtlasNote -Text ([string[]]@($failedPackages | ForEach-Object { "  - $_" }))

		function NoRestart {
			Write-AtlasRestartNotice -Kind Required
			Write-AtlasNote -Text 'Packages that did install apply after the next restart.'
			if (!$NoInteraction) { Wait-AtlasExit }
		}

		if (@($script:retryPackages).Count -eq 0) {
			Write-AtlasNote -Text 'The failed packages are not eligible for a Safe Mode retry.'
			NoRestart
			exit $script:errorLevel
		}
		if ($NoInteraction) {
			NoRestart
			exit $script:errorLevel
		}
		if (Read-AtlasYesNo -Question 'Arm a Safe Mode retry for the failed packages and restart now?') {
			$retryPaths = @($script:retryPackages | ForEach-Object { [string]$_.Path })
			[void](Enable-AtlasCbsRetry -Packages $retryPaths)
			Write-AtlasNextStep -Text 'Safe Mode retry armed. Run CbsRetry.ps1 -Recover from the Safe Mode command prompt.'
			Write-AtlasStep -Text 'Restarting Windows...'
			Restart
		} else {
			NoRestart
		}

		exit $script:errorLevel
	}

	if ($script:warningLevel -gt 0) {
		Write-AtlasPartial -Text "The package change completed with $script:warningLevel warning(s); see above."
	} else {
		Write-AtlasSuccess -Text 'The package change completed.'
	}
	if ($NoInteraction) { exit $script:errorLevel }
	Write-AtlasRestartNotice -Kind Required
	if (Read-AtlasYesNo -Question 'Restart Windows now?') {
		Write-AtlasStep -Text 'Restarting Windows...'
		Restart
	} else {
		Wait-AtlasExit
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
	Write-AtlasTitle -Text 'Install CBS package' -Explanation 'Installs the CBS packages you choose online, into the running Windows installation.'
	Wait-AtlasContinue

	Write-AtlasStep -Text 'Opening the file dialog to choose CBS package files...'
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
	Write-AtlasFailure -Text $_.Exception.Message
	$script:errorLevel++
	if (!$NoInteraction) { Wait-AtlasExit }
	exit $script:errorLevel
}

$script:errorLevel += @($installResult.FailedPackages).Count
$script:warningLevel += @($installResult.UnmatchedPatterns).Count
$script:retryPackages = @($installResult.RetryPackages)

# ======================================================================================================================= #
# RESTART                                                                                                                 #
# ======================================================================================================================= #
Finish $installResult.FailedPackages
