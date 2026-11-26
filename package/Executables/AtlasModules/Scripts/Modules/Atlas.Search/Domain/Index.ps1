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
    # Older Atlas versions could write these inactive policy lists; selecting a preset
    # removes them.
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths'
)

function ConvertTo-AtlasIndexPath {
    <#
    .SYNOPSIS
        Normalises a fully qualified drive or UNC path for an index entry, rejecting
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

    $driveAbsolute = $Candidate -cmatch '^[A-Za-z]:[\\/]'
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
        owns the materialised Gather and CurrentPolicies keys.
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
    <#
    .SYNOPSIS
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

$script:AtlasSearchStartTimeout = [TimeSpan]::FromMinutes(2)
$script:AtlasSearchRetryTimeout = [TimeSpan]::FromMinutes(5)

function Get-AtlasSearchServiceExitState {
    <#
    .SYNOPSIS
        Returns WSearch's Win32 and service-specific exit codes and its process ID, as
        the service manager reports them.
    #>
    $service = @(CimCmdlets\Get-CimInstance -ClassName Win32_Service -Filter "Name='WSearch'" -ErrorAction Stop)
    if ($service.Count -ne 1) {
        throw 'The service manager does not list Windows Search (WSearch).'
    }
    return [pscustomobject]@{
        Win32ExitCode           = [int64]$service[0].ExitCode
        ServiceSpecificExitCode = [int64]$service[0].ServiceSpecificExitCode
        ProcessId               = [int]$service[0].ProcessId
    }
}

function Get-AtlasSearchServiceProcessPath {
    <#
    .SYNOPSIS
        Returns the executable path of a process, or an empty string when Windows doesn't
        list it or won't say.
    #>
    param([Parameter(Mandatory = $true)][int]$ProcessId)

    $process = @(CimCmdlets\Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$ProcessId" -ErrorAction Stop)
    if ($process.Count -ne 1) {
        return ''
    }
    return [string]$process[0].ExecutablePath
}

function Format-AtlasSearchServiceExit {
    param([Parameter(Mandatory = $true)]$ExitState)

    $win32 = [int64]$ExitState.Win32ExitCode
    $text = "Win32 exit code $win32"
    if ($win32 -ge 0 -and $win32 -le [int]::MaxValue) {
        $text += " ($((New-Object ComponentModel.Win32Exception ([int]$win32)).Message.TrimEnd('.')))"
    }
    return ('{0}, service-specific exit code 0x{1:X8}' -f $text, [uint32]$ExitState.ServiceSpecificExitCode)
}

function Wait-AtlasSearchServiceRunning {
    <#
    .SYNOPSIS
        Waits for WSearch to reach Running. Returns Running, Stopped when it stopped and
        the service manager won't start it again, or Pending when the time runs out.
    .DESCRIPTION
        ServiceController.WaitForStatus waits out its whole timeout for a service that
        has already stopped. A service whose process ended unexpectedly (1067,
        ERROR_PROCESS_ABORTED) is still waited for, because WSearch's recovery actions
        start it again.
    #>
    param(
        [Parameter(Mandatory = $true)]$Service,
        [Parameter(Mandatory = $true)][TimeSpan]$Timeout
    )

    $clock = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        $Service.Refresh()
        $status = [string]$Service.Status
        if ($status -ceq 'Running') { return 'Running' }
        if ($status -ceq 'Stopped' -and [int64](Get-AtlasSearchServiceExitState).Win32ExitCode -ne 1067) {
            return 'Stopped'
        }
        if ($clock.Elapsed -ge $Timeout) { return 'Pending' }
        Start-Sleep -Milliseconds 500
    }
}

function Restart-AtlasSearchService {
    <#
    .SYNOPSIS
        Stops WSearch, ending its SearchIndexer.exe process when it's still starting and
        can't take a stop request, then starts it.
    #>
    param([Parameter(Mandatory = $true)]$Service)

    $Service.Refresh()
    if ([string]$Service.Status -cne 'Stopped') {
        try {
            $Service.Stop()
        }
        catch {
            $stopFailure = $_.Exception.Message
            $processId = [int](Get-AtlasSearchServiceExitState).ProcessId
            if ($processId -le 0) { throw }
            # WSearch runs in its own SearchIndexer.exe process. A process with any other
            # image could be a host that other services share, so it's never ended.
            $indexerPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'SearchIndexer.exe')
            $processPath = [string](Get-AtlasSearchServiceProcessPath -ProcessId $processId)
            if (-not $processPath.Equals($indexerPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw ("Windows Search couldn't take a stop request ($stopFailure), and its process $processId " +
                    "runs '$processPath', not '$indexerPath', so Atlas doesn't end it.")
            }
            Write-AtlasLog -Message "Windows Search couldn't take a stop request ($stopFailure); ending its process $processId."
            Stop-Process -Id $processId -Force -ErrorAction Stop
        }
        try {
            $Service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromMinutes(1))
        }
        catch {
            throw "Windows Search didn't stop within a minute to start again: $($_.Exception.Message)"
        }
    }
    try {
        $Service.Start()
    }
    catch {
        # The recovery actions can start a service whose process was ended first.
        $Service.Refresh()
        if ([string]$Service.Status -cnotin @('StartPending', 'Running')) { throw }
    }
}

function Set-AtlasSearchServiceState {
    <#
    .SYNOPSIS
        Configures WSearch as delayed-auto (Running) or disabled (Stopped) and moves
        the service to the requested runtime state, waiting out pending transitions.
    .DESCRIPTION
        A WSearch that stops while starting fails at once, with its exit codes. One that
        is still starting after two minutes gets its index reset, which makes Windows
        Search rebuild it, and one more start with a longer wait.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Running', 'Stopped')]
        [string]$State
    )

    $nativePaths = Get-AtlasIndexNativePaths
    $startMode = if ($State -eq 'Running') { 'delayed-auto' } else { 'disabled' }
    # Invoke-AtlasHiddenProcess throws unless sc.exe exits with 0.
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
            $outcome = Wait-AtlasSearchServiceRunning -Service $service -Timeout $script:AtlasSearchStartTimeout
            $reset = $false
            if ($outcome -ceq 'Pending') {
                $reset = $true
                Write-AtlasLog -Level Warning -Message (
                    "Windows Search is still '$($service.Status)' after $($script:AtlasSearchStartTimeout.TotalMinutes) " +
                    'minutes. Resetting its index, which Windows Search then rebuilds, and starting it again.'
                )
                Set-AtlasIndexConfiguration -Operation ResetSetupCompleted
                Restart-AtlasSearchService -Service $service
                $outcome = Wait-AtlasSearchServiceRunning -Service $service -Timeout $script:AtlasSearchRetryTimeout
            }
            if ($outcome -cne 'Running') {
                $what = if ($outcome -ceq 'Stopped') { 'stopped while starting' }
                elseif ($reset) { "is still '$($service.Status)' after its index was reset and it was started again" }
                $exitText = Format-AtlasSearchServiceExit -ExitState (Get-AtlasSearchServiceExitState)
                throw ("Windows Search (WSearch) $what, with $exitText. Atlas's indexing settings need it " +
                    'running. Repair Windows, for example with DISM /RestoreHealth and sfc /scannow, ' +
                    'restart, and try again.')
            }
            if ($reset) {
                Write-AtlasLog -Message 'Windows Search started after its index was reset.'
            }
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
