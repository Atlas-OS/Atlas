# Atlas.Search domain: single checked Windows Search index operations (path
# inclusion and exclusion, policy reset, WSearch start/stop, and the two DWORD
# settings the indexing machine states use).

$script:AtlasIndexPathRoots = @{
    Include = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\Search\IncludedPaths'
    Exclude = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\Search\ExcludedPaths'
}
$script:AtlasIndexPolicyRoots = @(
    $script:AtlasIndexPathRoots.Include
    $script:AtlasIndexPathRoots.Exclude
    # Remove the inactive policy lists written by earlier RCs when selecting a preset.
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths'
)

function ConvertTo-AtlasIndexPath {
    <#
    .SYNOPSIS
        Normalizes a fully qualified drive or UNC path for an index entry, rejecting
        relative, root-relative, incomplete UNC and wildcard candidates.
    #>
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

function Add-AtlasIndexPath {
    <#
    .SYNOPSIS
        Stages a file URL while Search is stopped. Start commits the complete preset
        through the Crawl Scope Manager and verifies the effective result. Search
        owns the materialized Gather and CurrentPolicies keys.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Include', 'Exclude')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $normalizedPath = ConvertTo-AtlasIndexPath -Candidate $Path
    $directoryPath = $normalizedPath.TrimEnd('\') + '\'
    $url = if ($directoryPath.StartsWith('\\')) {
        'file://' + $directoryPath.Substring(2)
    }
    else {
        'file:///' + $directoryPath
    }
    if ($Mode -eq 'Exclude') { $url += '*' }
    $rootPath = $script:AtlasIndexPathRoots[$Mode]
    if (-not (Test-Path -LiteralPath $rootPath -PathType Container -ErrorAction Stop)) {
        New-Item -Path $rootPath -Force -ErrorAction Stop | Out-Null
    }

    $root = Get-Item -LiteralPath $rootPath -ErrorAction Stop
    try {
        $existing = @($root.GetValueNames()) -contains $url
        # Literal value names preserve %, &, ! and wildcard suffixes as data.
        Set-ItemProperty -LiteralPath $rootPath -Name $url `
            -Value $url -Type String -ErrorAction Stop
    }
    finally {
        $root.Dispose()
    }

    return [pscustomobject]@{
        EntryName = $url
        Existing  = $existing
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

function Invoke-AtlasSearchScopeNative {
    param([string[]]$Includes, [string[]]$Excludes)

    Initialize-AtlasNativeType
    [Atlas.Native.SearchScope]::Apply($Includes, $Excludes)
}

function Complete-AtlasIndexScope {
    $urls = @{ Include = @(); Exclude = @() }
    foreach ($mode in @('Include', 'Exclude')) {
        $rootPath = $script:AtlasIndexPathRoots[$mode]
        if (-not (Test-Path -LiteralPath $rootPath)) { continue }
        $key = Get-Item -LiteralPath $rootPath -ErrorAction Stop
        try {
            foreach ($name in $key.GetValueNames()) {
                $value = $key.GetValue($name)
                $suffix = if ($mode -eq 'Exclude') { '\*' } else { '\' }
                if ($value -isnot [string] -or -not $value.StartsWith('file://') -or -not $value.EndsWith($suffix)) {
                    throw "Invalid staged Search scope entry '$name' at '$rootPath'."
                }
                $urls[$mode] += $value
            }
        }
        finally { $key.Dispose() }
    }
    if ($urls.Include.Count + $urls.Exclude.Count -eq 0) { return }
    Invoke-AtlasSearchScopeNative -Includes ([string[]]$urls.Include) -Excludes ([string[]]$urls.Exclude)
    Write-AtlasLog -Message 'Saved and verified the effective Windows Search crawl scope.'
}

function Get-AtlasIndexScopeState {
    <# .SYNOPSIS
        Reads effective inclusion for file paths without changing Search configuration.
    #>
    param([Parameter(Mandatory = $true)][string[]]$Path)

    $urls = foreach ($candidate in $Path) {
        $normalized = ConvertTo-AtlasIndexPath -Candidate $candidate
        if ($normalized.StartsWith('\\')) { 'file://' + $normalized.Substring(2) }
        else { 'file:///' + $normalized }
    }
    Initialize-AtlasNativeType
    $values = [Atlas.Native.SearchScope]::Read([string[]]$urls)
    for ($i = 0; $i -lt $Path.Count; $i++) {
        [pscustomobject]@{ Path = $Path[$i]; Included = $values[$i] }
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
        Sc       = [IO.Path]::Combine($systemDirectory, 'sc.exe')
    }
}

function Set-AtlasSearchServiceState {
    <#
    .SYNOPSIS
        Configures WSearch as delayed-auto (Running) or disabled (Stopped) and moves
        the service to the requested runtime state, waiting out pending transitions.
    #>
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
    <#
    .SYNOPSIS
        Hides or reveals the Searching Windows settings page.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Hidden
    )

    Import-AtlasModule -Name Atlas.Shell
    $visibilityOperation = if ($Hidden) { 'hide' } else { 'unhide' }
    Set-AtlasSettingsPageVisibility -Operation $visibilityOperation `
        -Page 'cortana-windowssearch' -NoProcessCleanup
}

function Set-AtlasIndexConfiguration {
    <#
    .SYNOPSIS
        Performs one checked Windows Search index operation. Include and Exclude need
        a fully qualified -IndexPath; SetRespectPowerModes needs an explicit
        -SettingValue; every other operation accepts neither. Requires administrator
        rights.
    #>
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
        [int]$SettingValue
    )

    $settingValueWasBound = $PSBoundParameters.ContainsKey('SettingValue')
    $requiresPath = $Operation -in @('Include', 'Exclude')
    if ($requiresPath) {
        if ([string]::IsNullOrWhiteSpace($IndexPath)) {
            throw "$Operation requires a fully qualified index path."
        }
        $IndexPath = ConvertTo-AtlasIndexPath -Candidate $IndexPath
    }
    elseif (-not [string]::IsNullOrEmpty($IndexPath)) {
        throw "$Operation does not accept an index path."
    }

    $requiresSettingValue = $Operation -eq 'SetRespectPowerModes'
    if ($requiresSettingValue -and -not $settingValueWasBound) {
        throw 'SetRespectPowerModes requires an explicit setting value.'
    }
    if (-not $requiresSettingValue -and $settingValueWasBound) {
        throw "$Operation does not accept a setting value."
    }
    if (-not (Test-AtlasAdmin)) {
        throw 'Administrator privileges are required to configure Windows Search indexing.'
    }

    switch ($Operation) {
        'Include' {
            Add-AtlasIndexPath -Mode Include -Path $IndexPath | Out-Null
        }
        'Exclude' {
            Add-AtlasIndexPath -Mode Exclude -Path $IndexPath | Out-Null
        }
        'CleanPolicies' {
            Clear-AtlasIndexPolicyRoots
        }
        'Start' {
            Set-AtlasSearchServiceState -State Running
            Complete-AtlasIndexScope
            Set-AtlasIndexSettingsVisibility -Hidden $false
        }
        'Stop' {
            Set-AtlasIndexSettingsVisibility -Hidden $true
            Set-AtlasSearchServiceState -State Stopped
        }
        'SetRespectPowerModes' {
            Set-AtlasIndexDword `
                -KeyPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex' `
                -Name RespectPowerModes -Value $SettingValue
        }
        'ResetSetupCompleted' {
            Set-AtlasIndexDword `
                -KeyPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search' `
                -Name SetupCompletedSuccessfully -Value 0
        }
    }
    Write-AtlasLog -Message "Completed Windows Search index operation '$Operation'."
}
