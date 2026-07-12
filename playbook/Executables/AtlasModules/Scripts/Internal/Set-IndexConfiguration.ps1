[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'Include',
        'Exclude',
        'CleanPolicies',
        'Start',
        'Stop',
        'SetRespectPowerModes',
        'ResetSetupCompleted'
    )]
    [string]$Operation,

    [string]$IndexPath,

    [ValidateSet(0, 1)]
    [int]$SettingValue,

    [switch]$InProcess
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$coreManifest = Join-Path $PSScriptRoot '..\Modules\Atlas.Core\Atlas.Core.psd1'
Import-Module -Name $coreManifest -ErrorAction Stop

$script:AtlasIndexPathRoots = @{
    Include = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths'
    Exclude = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions'
}
$script:AtlasIndexPolicyRoots = @(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\CurrentPolicies\DefaultExcludedPaths'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\CurrentPolicies\DefaultIndexedPaths'
    $script:AtlasIndexPathRoots.Include
    $script:AtlasIndexPathRoots.Exclude
)

function ConvertTo-AtlasIndexPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Candidate
    )

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        throw 'The index path cannot be empty.'
    }
    if ($Candidate.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or
        $Candidate.Contains('*') -or $Candidate.Contains('?')) {
        throw "The index path '$Candidate' contains invalid or wildcard characters."
    }

    $driveAbsolute = $Candidate -match '^[A-Za-z]:[\\/]'
    $uncAbsolute = $Candidate -match '^\\\\(?![?.]\\)[^\\]+\\[^\\]+(?:\\|$)'
    if (-not [IO.Path]::IsPathRooted($Candidate) -or
        -not ($driveAbsolute -or $uncAbsolute)) {
        throw "The index path '$Candidate' must be fully qualified."
    }

    return [IO.Path]::GetFullPath($Candidate)
}

function Get-AtlasFirstFreeIndexEntryName {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ExistingNames
    )

    for ($index = 0; $index -lt 1000000; $index++) {
        $candidate = [string]$index
        if ($ExistingNames -notcontains $candidate) {
            return $candidate
        }
    }
    throw 'No free numeric Windows Search index entry is available.'
}

function Add-AtlasIndexPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Include', 'Exclude')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $normalizedPath = ConvertTo-AtlasIndexPath -Candidate $Path
    $rootPath = $script:AtlasIndexPathRoots[$Mode]
    if (-not (Test-Path -LiteralPath $rootPath -PathType Container -ErrorAction Stop)) {
        New-Item -Path $rootPath -Force -ErrorAction Stop | Out-Null
    }

    $entries = @(Get-ChildItem -LiteralPath $rootPath -ErrorAction Stop)
    foreach ($entry in $entries) {
        $storedPath = $entry.GetValue(
            'Path',
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        if ($storedPath -is [string] -and [string]::Equals(
                $storedPath,
                $normalizedPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            Set-ItemProperty -LiteralPath $entry.PSPath -Name Path `
                -Value $normalizedPath -Type String -ErrorAction Stop
            return [pscustomobject]@{
                EntryName = [string]$entry.PSChildName
                Existing  = $true
                Path      = $normalizedPath
            }
        }
    }

    $entryName = Get-AtlasFirstFreeIndexEntryName `
        -ExistingNames @($entries | ForEach-Object { [string]$_.PSChildName })
    $entryPath = Join-Path $rootPath $entryName
    New-Item -Path $entryPath -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -LiteralPath $entryPath -Name Path `
        -Value $normalizedPath -Type String -ErrorAction Stop

    return [pscustomobject]@{
        EntryName = $entryName
        Existing  = $false
        Path      = $normalizedPath
    }
}

function Clear-AtlasIndexPolicyRoots {
    foreach ($rootPath in $script:AtlasIndexPolicyRoots) {
        if (Test-Path -LiteralPath $rootPath -ErrorAction Stop) {
            Remove-Item -LiteralPath $rootPath -Recurse -Force -ErrorAction Stop
        }
        New-Item -Path $rootPath -Force -ErrorAction Stop | Out-Null
    }
}

function Set-AtlasIndexDword {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet(0, 1)]
        [int]$Value
    )

    if (-not (Test-Path -LiteralPath $KeyPath -PathType Container -ErrorAction Stop)) {
        New-Item -Path $KeyPath -Force -ErrorAction Stop | Out-Null
    }
    Set-ItemProperty -LiteralPath $KeyPath -Name $Name -Value $Value `
        -Type DWord -ErrorAction Stop
}

function Get-AtlasIndexNativePaths {
    $systemDirectory = [Environment]::GetFolderPath(
        [Environment+SpecialFolder]::System
    )
    if ([string]::IsNullOrWhiteSpace($systemDirectory)) {
        throw 'The Windows system directory could not be resolved.'
    }

    return [pscustomobject]@{
        GpUpdate = [IO.Path]::Combine($systemDirectory, 'gpupdate.exe')
        Sc       = [IO.Path]::Combine($systemDirectory, 'sc.exe')
    }
}

function Set-AtlasSearchServiceState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Running', 'Stopped')]
        [string]$State
    )

    $nativePaths = Get-AtlasIndexNativePaths
    $startMode = if ($State -eq 'Running') { 'delayed-auto' } else { 'disabled' }
    Invoke-AtlasHiddenProcess -FilePath $nativePaths.Sc `
        -ArgumentList @('config', 'WSearch', 'start=', $startMode) -Wait | Out-Null

    $service = Get-Service -Name WSearch -ErrorAction Stop
    try {
        $service.Refresh()
        if ($State -eq 'Running') {
            if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::StopPending) {
                $service.WaitForStatus(
                    [ServiceProcess.ServiceControllerStatus]::Stopped,
                    [TimeSpan]::FromMinutes(2)
                )
                $service.Refresh()
            }
            if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Paused) {
                $service.Continue()
            }
            elseif ($service.Status -notin @(
                    [ServiceProcess.ServiceControllerStatus]::Running,
                    [ServiceProcess.ServiceControllerStatus]::StartPending
                )) {
                $service.Start()
            }
            $service.WaitForStatus(
                [ServiceProcess.ServiceControllerStatus]::Running,
                [TimeSpan]::FromMinutes(2)
            )
        }
        else {
            if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::StartPending) {
                $service.WaitForStatus(
                    [ServiceProcess.ServiceControllerStatus]::Running,
                    [TimeSpan]::FromMinutes(2)
                )
                $service.Refresh()
            }
            if ($service.Status -notin @(
                    [ServiceProcess.ServiceControllerStatus]::Stopped,
                    [ServiceProcess.ServiceControllerStatus]::StopPending
                )) {
                $service.Stop()
            }
            $service.WaitForStatus(
                [ServiceProcess.ServiceControllerStatus]::Stopped,
                [TimeSpan]::FromMinutes(2)
            )
        }
    }
    finally {
        $service.Dispose()
    }
}

function Set-AtlasIndexSettingsVisibility {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Hidden
    )

    $settingsScript = Join-Path $PSScriptRoot 'Set-SettingsPageVisibility.ps1'
    if (-not [IO.File]::Exists($settingsScript)) {
        throw "The Settings-page visibility helper is missing at '$settingsScript'."
    }

    $visibilityOperation = if ($Hidden) { 'hide' } else { 'unhide' }
    & $settingsScript -Operation $visibilityOperation `
        -Page 'cortana-windowssearch' -Silent -NoProcessCleanup
}

function Invoke-AtlasIndexConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Include',
            'Exclude',
            'CleanPolicies',
            'Start',
            'Stop',
            'SetRespectPowerModes',
            'ResetSetupCompleted'
        )]
        [string]$RequestedOperation,

        [string]$RequestedPath,

        [int]$RequestedSettingValue,

        [bool]$SettingValueWasBound
    )

    $requiresPath = $RequestedOperation -in @('Include', 'Exclude')
    if ($requiresPath) {
        if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
            throw "$RequestedOperation requires a fully qualified index path."
        }
        $RequestedPath = ConvertTo-AtlasIndexPath -Candidate $RequestedPath
    }
    elseif (-not [string]::IsNullOrEmpty($RequestedPath)) {
        throw "$RequestedOperation does not accept an index path."
    }

    $requiresSettingValue = $RequestedOperation -eq 'SetRespectPowerModes'
    if ($requiresSettingValue -and -not $SettingValueWasBound) {
        throw 'SetRespectPowerModes requires an explicit setting value.'
    }
    if (-not $requiresSettingValue -and $SettingValueWasBound) {
        throw "$RequestedOperation does not accept a setting value."
    }
    if (-not (Test-AtlasAdmin)) {
        throw 'Administrator privileges are required to configure Windows Search indexing.'
    }

    switch ($RequestedOperation) {
        'Include' {
            Add-AtlasIndexPath -Mode Include -Path $RequestedPath | Out-Null
        }
        'Exclude' {
            Add-AtlasIndexPath -Mode Exclude -Path $RequestedPath | Out-Null
        }
        'CleanPolicies' {
            Clear-AtlasIndexPolicyRoots
        }
        'Start' {
            Set-AtlasSearchServiceState -State Running
            Set-AtlasIndexSettingsVisibility -Hidden $false
            $nativePaths = Get-AtlasIndexNativePaths
            Invoke-AtlasHiddenProcess -FilePath $nativePaths.GpUpdate `
                -ArgumentList @('/target:computer', '/force', '/wait:600') `
                -Wait | Out-Null
        }
        'Stop' {
            Set-AtlasIndexSettingsVisibility -Hidden $true
            Set-AtlasSearchServiceState -State Stopped
        }
        'SetRespectPowerModes' {
            Set-AtlasIndexDword `
                -KeyPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex' `
                -Name RespectPowerModes -Value $RequestedSettingValue
        }
        'ResetSetupCompleted' {
            Set-AtlasIndexDword `
                -KeyPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search' `
                -Name SetupCompletedSuccessfully -Value 0
        }
    }
}

try {
    Invoke-AtlasIndexConfiguration `
        -RequestedOperation $Operation `
        -RequestedPath $IndexPath `
        -RequestedSettingValue $SettingValue `
        -SettingValueWasBound ($PSBoundParameters.ContainsKey('SettingValue'))
}
catch {
    if ($InProcess) {
        throw
    }
    Write-Error -ErrorRecord $_ -ErrorAction Continue
    exit 1
}

if (-not $InProcess) {
    exit 0
}
