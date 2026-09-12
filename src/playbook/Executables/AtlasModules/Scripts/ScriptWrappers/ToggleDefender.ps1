$ProgressPreference = 'SilentlyContinue'

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"

function Restart {
	Write-Host "`nCompleted!" -ForegroundColor Green
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {
		Restart-Computer
	} else {
		Write-Host "`nChanges will apply after next restart." -ForegroundColor Yellow
		Read-Pause
	}
}

$packageInstall = "$windir\AtlasModules\Scripts\packageInstall.ps1"
if (!(Test-Path $packageInstall)) {
    Write-Host "Missing package install script, can't continue."
    if (!$args) { Read-Pause }
    exit 1
}

$package = "*Z-Atlas-NoDefender-Package*"

try {
	$packages = (Get-WindowsPackage -online | Where-Object { $_.PackageName -like "*NoDefender*" }).PackageName
} catch {
	if (!$?) {
		Write-Host "Failed to get packages! $_" -ForegroundColor Red
		Read-Pause
        exit 1
	}
}
if ($null -eq $packages) {
    $DefenderEnabled = '(current)'
} else {
    $DefenderDisabled = '(current)'
}

function Menu {
	Clear-Host
	$ColourDisable = $ColourEnable = 'White'
	if ($DefenderDisabled) {$ColourDisable = 'Gray'} else {$ColourEnable = 'Gray'}

	Write-Host "Only disable Defender if you've read the documentation first.`n" -ForegroundColor Cyan

	Write-Host "1) Disable Defender $DefenderDisabled" -ForegroundColor $ColourDisable
	Write-Host "2) Enable Defender $DefenderEnabled" -ForegroundColor $ColourEnable
    Write-Host "3) See documentation`n" -ForegroundColor White

	Write-Host "Choose 1/2/3: " -NoNewline -ForegroundColor Yellow
	$pageInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

	switch ($pageInput.Character) {
		# Disable Defender
		1 {
			if ($DefenderDisabled) {Menu}
			Clear-Host

			$text = "Are you sure that you want to disable Windows Defender?"
			Write-Host "$text`n$(('-' * $text.Length))" -ForegroundColor Red
			Write-Host "By continuing, you acknowledge that the security of`nyour computer will be worse, especially if you are`nprone to getting infected." -ForegroundColor Yellow

			Pause "`nPress Enter to continue anyways"
			
			Clear-Host
			Write-Host "Disabling Windows Defender... This will take a moment." -ForegroundColor Yellow

			& $packageInstall -InstallPackages @($package)
			exit $LASTEXITCODE
		}

		# Enable Defender
		2 {
			if ($DefenderEnabled) { Menu }
			Clear-Host
			Write-Host "After enabling Windows Defender and restarting, it is highly recommended to go through`nthe settings in Windows Security and enabling anything you need.`n" -ForegroundColor Yellow
			Pause "Press Enter to enable Windows Defender"

			Clear-Host
			Write-Host "Enabling Windows Defender... This will take a moment." -ForegroundColor Yellow

			& $packageInstall -UninstallPackages @($package)
			exit $LASTEXITCODE
		}

        # Documentation
        3 {
            Start-Process "https://docs.atlasos.net/getting-started/post-installation/atlas-folder/security/#defender"
			Menu
        }

		# Do nothing
		default {
			Menu
		}
	}
}

Menu