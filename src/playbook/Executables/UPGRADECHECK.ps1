param ( [switch]$SetVersion )

$version = 'v0.5.0 (dev)'
$upgradableFrom = 'v0.4.0' `
    -replace '[^0-9]' -replace '^0+'

$oemInfo = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
if ($SetVersion) {
    Set-ItemProperty $oemInfo -Name "Model" -Value "AtlasOS $version" -Force
    exit [int]$?
}

################################################################################

# Kill AME and its processes
function KillAme {
    $ameProcesses = Get-Process | Where-Object {
            ($_.Company -like 'Ameliorated LLC*' -and $_.Description -like 'AME*') -or
            $_.Name -like '*TrustedUninstaller*'
        }

    if ($null -eq $ameProcesses) {
        Write-Error "No AME processes found!"
        while ($true) { Start-Sleep 999999999 }
    }

    $ameProcesses | Stop-Process -Force
    
    exit 1
}

$version = [int]($version -replace '[^0-9]' -replace '^0+')

# Check if Atlas is installed
$model = (Get-ItemProperty $oemInfo -Name "Model" -EA 0).Model
$guide = "Follow our installation guide: https://docs.atlasos.net/getting-started/installation/"
if ($model -notlike "*Atlas*") {
    Write-Output "Model doesn't contain Atlas, Atlas doesn't seem to be installed currently."
    if (20 -lt ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).InstallDate).Days) {
        @"
Windows seems to have been installed a while ago. A full Windows reinstall is highly recommended to ensure your initial install of Atlas works without problems.

Atlas will install anyways, but remember this if there's issues.

$guide
"@ | msg *
    }
    exit 2
}
$installedVersion = [int]($model -replace '[^0-9]' -replace '^0+')

# Check if you can upgrade
if ($upgradableFrom -gt $installedVersion) {
    @"
You can't upgrade from your current version of Atlas to this newer version. Only upgrades from Atlas v0.4.0 and onwards are supported.

We are sorry for the inconvenience.

$guide
"@ | msg *

    KillAme
}

# Check if user is trying to downgrade
if ($installedVersion -gt $version) {
    @"
You can't downgrade from your current version of Atlas to this older version.

If there's an issue with the newest release, consider filing an issue on GitHub: https://github.com/Atlas-OS/Atlas/issues
"@ | msg *

    KillAme
}