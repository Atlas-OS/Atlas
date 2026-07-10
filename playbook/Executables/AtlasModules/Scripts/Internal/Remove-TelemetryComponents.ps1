$ProgressPreference = 'SilentlyContinue'

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"

function Write-BulletPoint($message) {
    Write-Host " - " -ForegroundColor Green -NoNewline
    Write-Host $message
}
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

$packageInstall = "$windir\AtlasModules\Scripts\Install-AtlasPackage.ps1"
if (!(Test-Path $packageInstall)) {
    Write-Host "Missing package install script, can't continue."
    Read-Pause
    exit 1
}
$packagePowerShell = Join-Path -Path ([Environment]::GetFolderPath('System')) `
    -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'

$package = "*Z-Atlas-NoTelemetry-Package*"

try {
    $packages = (Get-WindowsPackage -online | Where-Object { $_.PackageName -like $package }).PackageName
} catch {
    if (!$?) {
        Write-Host "Failed to get packages! $_" -ForegroundColor Red
        Read-Pause
        exit 1
    }
}
if ($null -eq $packages) {
    $TelemetryEnabled = '(current)'
} else {
    $TelemetryDisabled = '(current)'
}

function Menu {
    Clear-Host
    $ColourDisable = $ColourEnable = 'White'
    if ($TelemetryDisabled) {$ColourDisable = 'Gray'} else {$ColourEnable = 'Gray'}

    Write-Host "This script adds or removes Atlas' NoTelemetry package, which removes certain telemetry components in Windows.`n" -ForegroundColor Cyan

    Write-BulletPoint @"
Removing the package restores the telemetry components, which can aid in troubleshooting. If
   resolving the issue involves removing the package, please report this as an issue to Atlas.`n
"@
    Write-BulletPoint @"
Atlas retains policies that should disable telemetry even after the package removal. These policies
   do not work on Windows Home edition.
"@

    Write-BulletPoint @"
This package isn't needed on Education or Enterprise-based editions.
"@

    Write-Host "`n---------------------------------------------------------------------------------------------------------`n" -ForegroundColor Magenta

    Write-Host "1) Add the NoTelemetry package $TelemetryDisabled" -ForegroundColor $ColourDisable
    Write-Host "2) Remove the NoTelemetry package $TelemetryEnabled`n" -ForegroundColor $ColourEnable

    Write-Host "Choose 1/2: " -NoNewline -ForegroundColor Yellow
    $pageInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

    switch ($pageInput.Character) {
        # Add NoTelemetry package
        1 {
            if ($TelemetryDisabled) {Menu}
            Clear-Host
            Write-Host "Adding the NoTelemetry package... This will take a moment." -ForegroundColor Yellow

            & $packagePowerShell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $packageInstall -InstallPackages @($package)
            $packageExitCode = $LASTEXITCODE
            if ($packageExitCode -ne 0) {
                throw "Package installation failed with exit code $packageExitCode."
            }
            return
        }

        # Remove NoTelemetry package
        2 {
            if ($TelemetryEnabled) { Menu }

            Clear-Host
            Write-Host "Removing the NoTelemetry package... This will take a moment." -ForegroundColor Yellow

            & $packagePowerShell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $packageInstall -UninstallPackages @($package)
            $packageExitCode = $LASTEXITCODE
            if ($packageExitCode -ne 0) {
                throw "Package removal failed with exit code $packageExitCode."
            }
            return
        }

        # Do nothing
        default {
            Menu
        }
    }
}

Menu
