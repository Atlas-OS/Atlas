<#
.SYNOPSIS
    Applies the machine-owned portion of the Atlas Location toggle.
.DESCRIPTION
    Service state, Find My Device policy, and Settings-page visibility live here so
    installation and the public toggle use the same fail-stop operation. User consent
    and the optional Find My Device prompt remain in the toggle definition.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Disable', 'Enable')]
    [string]$State
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$modulesRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Modules'))
$moduleManifests = @(
    (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1')
    (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1')
    (Join-Path $modulesRoot 'Atlas.Services\Atlas.Services.psd1')
)
$settingsHelper = Join-Path $PSScriptRoot 'Set-SettingsPageVisibility.ps1'

foreach ($requiredFile in @($moduleManifests) + $settingsHelper) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required Location dependency is missing: '$requiredFile'."
    }
}
foreach ($manifest in $moduleManifests) {
    Import-Module -Name $manifest -ErrorAction Stop
}

if (Test-AtlasTrustedInstaller) {
    Assert-AtlasPrivilege -TrustedInstaller
}
else {
    Assert-AtlasPrivilege -Administrator
}

function Invoke-AtlasLocationServiceState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('lfsvc', 'MapsBroker')]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, 4)]
        [int]$StartupType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Running', 'Stopped')]
        [string]$Status
    )

    Set-AtlasServiceStartup -Name $Name -StartupType $StartupType

    $desiredStatus = if ($Status -ceq 'Running') {
        [System.ServiceProcess.ServiceControllerStatus]::Running
    }
    else {
        [System.ServiceProcess.ServiceControllerStatus]::Stopped
    }

    $service = [System.ServiceProcess.ServiceController]::new($Name)
    try {
        $service.Refresh()
        if ($service.Status -ne $desiredStatus) {
            if ($desiredStatus -eq
                [System.ServiceProcess.ServiceControllerStatus]::Running) {
                $service.Start()
            }
            else {
                $service.Stop()
            }
            $service.WaitForStatus($desiredStatus, [TimeSpan]::FromSeconds(30))
        }
    }
    finally {
        $service.Dispose()
    }
}

if ($State -ceq 'Disable') {
    Invoke-AtlasLocationServiceState `
        -Name lfsvc -StartupType 4 -Status Stopped
    Invoke-AtlasLocationServiceState `
        -Name MapsBroker -StartupType 4 -Status Stopped

    $findMyDevicePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
    foreach ($valueName in @('AllowFindMyDevice', 'LocationSyncEnabled')) {
        Set-AtlasRegistryValue -Path $findMyDevicePolicy -Name $valueName `
            -Type DWord -Data 0
    }

    & $settingsHelper hide privacy-location -Silent -NoProcessCleanup
    & $settingsHelper hide findmydevice -Silent -NoProcessCleanup
}
else {
    Invoke-AtlasLocationServiceState `
        -Name lfsvc -StartupType 3 -Status Running
    Invoke-AtlasLocationServiceState `
        -Name MapsBroker -StartupType 2 -Status Running

    # Find My Device stays locked unless the interactive public toggle opts in.
    & $settingsHelper unhide privacy-location -Silent -NoProcessCleanup
}
