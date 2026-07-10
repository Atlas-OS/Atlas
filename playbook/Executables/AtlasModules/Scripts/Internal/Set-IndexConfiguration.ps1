[CmdletBinding(DefaultParameterSetName = 'Execute')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Execute')]
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

    [Parameter(ParameterSetName = 'Execute')]
    [string]$IndexPath,

    [Parameter(ParameterSetName = 'Execute')]
    [ValidateSet(0, 1)]
    [int]$SettingValue,

    [Parameter(ParameterSetName = 'Execute')]
    [switch]$InProcess,

    [Parameter(Mandatory = $true, ParameterSetName = 'Library')]
    [switch]$LibraryOnly
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:AtlasIndexExitCodeKey = 'Atlas.IndexConfiguration.ExitCode'
$script:AtlasIndexPathRoots = @{
    Include = 'SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths'
    Exclude = 'SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions'
}
$script:AtlasIndexPolicyRoots = @(
    'SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths'
    'SOFTWARE\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths'
    'SOFTWARE\Microsoft\Windows Search\CurrentPolicies\DefaultExcludedPaths'
    'SOFTWARE\Microsoft\Windows Search\CurrentPolicies\DefaultIndexedPaths'
    $script:AtlasIndexPathRoots.Include
    $script:AtlasIndexPathRoots.Exclude
)

function New-AtlasIndexOperationException {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 2147483647)]
        [int]$ExitCode
    )

    $exception = New-Object System.InvalidOperationException($Message)
    $exception.Data[$script:AtlasIndexExitCodeKey] = $ExitCode
    return $exception
}

function ConvertTo-AtlasWindowsCommandLineArgument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }

    # Apply the CommandLineToArgvW quoting rules. Native children receive the
    # original typed argv without involving cmd.exe or another shell.
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append([char]34)
    $backslashCount = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]92) {
            $backslashCount++
            continue
        }
        if ($character -eq [char]34) {
            [void]$builder.Append([char]92, (($backslashCount * 2) + 1))
            [void]$builder.Append([char]34)
            $backslashCount = 0
            continue
        }
        if ($backslashCount -gt 0) {
            [void]$builder.Append([char]92, $backslashCount)
            $backslashCount = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashCount -gt 0) {
        [void]$builder.Append([char]92, ($backslashCount * 2))
    }
    [void]$builder.Append([char]34)
    return $builder.ToString()
}

function Invoke-AtlasIndexNativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description
    )

    if (-not [IO.File]::Exists($FilePath)) {
        throw "The protected executable for $Description is missing at '$FilePath'."
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = (@($ArgumentList | ForEach-Object {
                ConvertTo-AtlasWindowsCommandLineArgument -Value $_
            }) -join ' ')
    $startInfo.WorkingDirectory = [IO.Path]::GetDirectoryName($FilePath)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "$Description could not be started."
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result
        $exitCode = $process.ExitCode
    }
    finally {
        $process.Dispose()
    }

    $output = @($stdout, $stderr | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($exitCode -ne 0) {
        $detail = (($output | Out-String).Trim())
        $message = "$Description failed with exit code $exitCode."
        if (-not [string]::IsNullOrWhiteSpace($detail)) {
            $message += " $detail"
        }
        $reportedExitCode = if ($exitCode -gt 0) { [int]$exitCode } else { 1 }
        throw (New-AtlasIndexOperationException -Message $message -ExitCode $reportedExitCode)
    }

    return $output
}

function Get-AtlasIndexNativePathSet {
    [CmdletBinding()]
    param()

    $systemDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
    if ([string]::IsNullOrWhiteSpace($systemDirectory) -or -not [IO.Directory]::Exists($systemDirectory)) {
        throw 'The protected Windows system directory could not be resolved.'
    }

    return [pscustomobject]@{
        GpUpdate = [IO.Path]::Combine($systemDirectory, 'gpupdate.exe')
        Sc       = [IO.Path]::Combine($systemDirectory, 'sc.exe')
    }
}

function Assert-AtlasIndexAdministrator {
    [CmdletBinding()]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Administrator privileges are required to configure Windows Search indexing.'
        }
    }
    finally {
        if ($null -ne $identity) {
            $identity.Dispose()
        }
    }
}

function ConvertTo-AtlasIndexPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Candidate
    )

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        throw 'The index path cannot be empty.'
    }
    if ($Candidate.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or
        $Candidate.IndexOf('*', [StringComparison]::Ordinal) -ge 0 -or
        $Candidate.IndexOf('?', [StringComparison]::Ordinal) -ge 0) {
        throw "The index path '$Candidate' contains invalid or wildcard characters."
    }
    $isDriveAbsolute = $Candidate -match '^[A-Za-z]:[\\/]'
    $isUncAbsolute = $Candidate -match '^\\\\(?![?.]\\)[^\\]+\\[^\\]+(?:\\|$)'
    if (-not [IO.Path]::IsPathRooted($Candidate) -or
        -not ($isDriveAbsolute -or $isUncAbsolute)) {
        throw "The index path '$Candidate' must be fully qualified."
    }

    $fullPath = [IO.Path]::GetFullPath($Candidate)
    if ([string]::IsNullOrWhiteSpace($fullPath)) {
        throw 'The normalized index path is empty.'
    }
    return $fullPath
}

function Get-AtlasFirstFreeIndexEntryName {
    [CmdletBinding()]
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
    [CmdletBinding()]
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
    $rootKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($rootPath)
    if ($null -eq $rootKey) {
        throw "Windows Search index root 'HKLM\$rootPath' could not be opened for writing."
    }

    $entryName = $null
    $existingEntry = $false
    try {
        $existingNames = @($rootKey.GetSubKeyNames())
        foreach ($name in $existingNames) {
            $entryKey = $rootKey.OpenSubKey($name, $true)
            if ($null -eq $entryKey) {
                throw "Windows Search index entry 'HKLM\$rootPath\$name' could not be reopened."
            }
            try {
                $existingPath = $entryKey.GetValue(
                    'Path',
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                if ($existingPath -is [string] -and
                    [string]::Equals($existingPath, $normalizedPath, [StringComparison]::OrdinalIgnoreCase)) {
                    $existingKind = $entryKey.GetValueKind('Path')
                    if ($existingKind -eq [Microsoft.Win32.RegistryValueKind]::String) {
                        return [pscustomobject]@{
                            EntryName = $name
                            Existing  = $true
                            Path      = $normalizedPath
                        }
                    }

                    # Repair a matching legacy REG_EXPAND_SZ (or other wrong type)
                    # instead of returning success without the required REG_SZ state.
                    $entryKey.SetValue('Path', $normalizedPath, [Microsoft.Win32.RegistryValueKind]::String)
                    $entryName = $name
                    $existingEntry = $true
                }
            }
            finally {
                $entryKey.Dispose()
            }
            if ($null -ne $entryName) {
                break
            }
        }

        if ($null -eq $entryName) {
            $entryName = Get-AtlasFirstFreeIndexEntryName -ExistingNames $existingNames
            $entryKey = $rootKey.CreateSubKey($entryName)
            if ($null -eq $entryKey) {
                throw "Windows Search index entry 'HKLM\$rootPath\$entryName' could not be created."
            }
            try {
                $currentPath = $entryKey.GetValue(
                    'Path',
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                if ($null -ne $currentPath -and
                    -not [string]::Equals([string]$currentPath, $normalizedPath, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Windows Search index entry 'HKLM\$rootPath\$entryName' was populated concurrently."
                }
                $entryKey.SetValue('Path', $normalizedPath, [Microsoft.Win32.RegistryValueKind]::String)
            }
            finally {
                $entryKey.Dispose()
            }
        }
    }
    finally {
        $rootKey.Dispose()
    }

    $verifyRoot = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($rootPath, $false)
    if ($null -eq $verifyRoot) {
        throw "Windows Search index root 'HKLM\$rootPath' disappeared after the write."
    }
    try {
        $verifyEntry = $verifyRoot.OpenSubKey($entryName, $false)
        if ($null -eq $verifyEntry) {
            throw "Windows Search index entry 'HKLM\$rootPath\$entryName' is missing after the write."
        }
        try {
            $verifiedPath = $verifyEntry.GetValue(
                'Path',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
            $verifiedKind = $verifyEntry.GetValueKind('Path')
            if ($verifiedKind -ne [Microsoft.Win32.RegistryValueKind]::String -or
                -not [string]::Equals([string]$verifiedPath, $normalizedPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Windows Search index entry 'HKLM\$rootPath\$entryName' failed its postcondition."
            }
        }
        finally {
            $verifyEntry.Dispose()
        }
    }
    finally {
        $verifyRoot.Dispose()
    }

    return [pscustomobject]@{
        EntryName = $entryName
        Existing  = $existingEntry
        Path      = $normalizedPath
    }
}

function Clear-AtlasIndexPolicyRootSet {
    [CmdletBinding()]
    param()

    foreach ($rootPath in $script:AtlasIndexPolicyRoots) {
        [Microsoft.Win32.Registry]::LocalMachine.DeleteSubKeyTree($rootPath, $false)
        $createdKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($rootPath)
        if ($null -eq $createdKey) {
            throw "Windows Search registry root 'HKLM\$rootPath' could not be recreated."
        }
        $createdKey.Dispose()

        $verifyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($rootPath, $false)
        if ($null -eq $verifyKey) {
            throw "Windows Search registry root 'HKLM\$rootPath' is missing after recreation."
        }
        try {
            if (@($verifyKey.GetSubKeyNames()).Count -ne 0 -or @($verifyKey.GetValueNames()).Count -ne 0) {
                throw "Windows Search registry root 'HKLM\$rootPath' is not empty after recreation."
            }
        }
        finally {
            $verifyKey.Dispose()
        }
    }
}

function Assert-AtlasSearchServiceConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('DelayedAutomatic', 'Disabled')]
        [string]$Configuration
    )

    $servicePath = 'SYSTEM\CurrentControlSet\Services\WSearch'
    $serviceKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($servicePath, $false)
    if ($null -eq $serviceKey) {
        throw 'The WSearch service registry key is missing.'
    }
    try {
        $startKind = $serviceKey.GetValueKind('Start')
        $startValue = [int]$serviceKey.GetValue('Start', -1)
        $delayedValue = [int]$serviceKey.GetValue('DelayedAutoStart', 0)
        if ($startKind -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
            throw "WSearch Start has unexpected registry kind '$startKind'."
        }
        if ($Configuration -eq 'DelayedAutomatic') {
            $delayedKind = $serviceKey.GetValueKind('DelayedAutoStart')
            if ($delayedKind -ne [Microsoft.Win32.RegistryValueKind]::DWord -or
                $startValue -ne 2 -or $delayedValue -ne 1) {
                throw "WSearch start configuration is invalid: Start=$startValue, DelayedAutoStart=$delayedValue."
            }
        }
        elseif ($startValue -ne 4) {
            throw "WSearch is not disabled after configuration: Start=$startValue."
        }
    }
    finally {
        $serviceKey.Dispose()
    }
}

function Assert-AtlasSearchServiceState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Running', 'Stopped')]
        [string]$State
    )

    $service = New-Object System.ServiceProcess.ServiceController('WSearch')
    try {
        $service.Refresh()
        if ([string]$service.Status -ne $State) {
            throw "WSearch failed its service-state postcondition: expected $State, got $($service.Status)."
        }
    }
    finally {
        $service.Dispose()
    }
}

function Set-AtlasSearchServiceState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Running', 'Stopped')]
        [string]$State
    )

    $nativePaths = Get-AtlasIndexNativePathSet
    $configuration = if ($State -eq 'Running') { 'DelayedAutomatic' } else { 'Disabled' }
    $startArgument = if ($State -eq 'Running') { 'delayed-auto' } else { 'disabled' }
    [void](Invoke-AtlasIndexNativeCommand -FilePath $nativePaths.Sc `
            -ArgumentList @('config', 'WSearch', 'start=', $startArgument) `
            -Description "configuring WSearch as $configuration")
    Assert-AtlasSearchServiceConfiguration -Configuration $configuration

    $service = New-Object System.ServiceProcess.ServiceController('WSearch')
    try {
        $service.Refresh()
        if ($State -eq 'Running') {
            if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::StopPending) {
                $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromMinutes(2))
                $service.Refresh()
            }
            if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Paused) {
                $service.Continue()
            }
            elseif ($service.Status -ne [ServiceProcess.ServiceControllerStatus]::Running -and
                $service.Status -ne [ServiceProcess.ServiceControllerStatus]::StartPending) {
                $service.Start()
            }
            $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromMinutes(2))
        }
        else {
            if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::StartPending) {
                $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromMinutes(2))
                $service.Refresh()
            }
            if ($service.Status -ne [ServiceProcess.ServiceControllerStatus]::Stopped -and
                $service.Status -ne [ServiceProcess.ServiceControllerStatus]::StopPending) {
                $service.Stop()
            }
            $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromMinutes(2))
        }
    }
    finally {
        $service.Dispose()
    }
    Assert-AtlasSearchServiceState -State $State
}

function Set-AtlasIndexRegistryDword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet(0, 1)]
        [int]$Value
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($KeyPath)
    if ($null -eq $key) {
        throw "Registry key 'HKLM\$KeyPath' could not be opened for writing."
    }
    try {
        $key.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]::DWord)
    }
    finally {
        $key.Dispose()
    }

    $verifyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath, $false)
    if ($null -eq $verifyKey) {
        throw "Registry key 'HKLM\$KeyPath' is missing after setting '$Name'."
    }
    try {
        $verifiedKind = $verifyKey.GetValueKind($Name)
        $verifiedValue = [Convert]::ToInt32($verifyKey.GetValue($Name, -1))
        if ($verifiedKind -ne [Microsoft.Win32.RegistryValueKind]::DWord -or $verifiedValue -ne $Value) {
            throw "Registry value 'HKLM\$KeyPath\$Name' failed its REG_DWORD postcondition."
        }
    }
    finally {
        $verifyKey.Dispose()
    }
}

function Assert-AtlasIndexSettingsVisibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Hidden
    )

    $policyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $policyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($policyPath, $false)
    $currentValue = $null
    if ($null -ne $policyKey) {
        try {
            $currentValue = $policyKey.GetValue(
                'SettingsPageVisibility',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
        }
        finally {
            $policyKey.Dispose()
        }
    }

    $pages = @()
    if ($currentValue -is [string] -and -not [string]::IsNullOrWhiteSpace($currentValue)) {
        $valueText = [string]$currentValue
        if ($valueText.StartsWith('hide:', [StringComparison]::OrdinalIgnoreCase)) {
            $valueText = $valueText.Substring(5)
        }
        $pages = @($valueText.Split(';') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    $containsSearchPage = @($pages | Where-Object {
            [string]::Equals($_, 'cortana-windowssearch', [StringComparison]::OrdinalIgnoreCase)
        }).Count -gt 0
    if ($containsSearchPage -ne $Hidden) {
        throw "The Windows Search Settings-page visibility postcondition failed (Hidden=$Hidden)."
    }
}

function Set-AtlasIndexSettingsVisibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Hidden
    )

    $windowsDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    $settingsScript = [IO.Path]::Combine(
        $windowsDirectory,
        'AtlasModules',
        'Scripts',
        'Internal',
        'Set-SettingsPageVisibility.ps1'
    )
    if (-not [IO.File]::Exists($settingsScript)) {
        throw "The protected Settings-page visibility script is missing at '$settingsScript'."
    }

    $visibilityOperation = if ($Hidden) { '/hide' } else { '/unhide' }
    & $settingsScript -Operation $visibilityOperation -Page 'cortana-windowssearch' -Silent
    Assert-AtlasIndexSettingsVisibility -Hidden $Hidden
}

function Stop-AtlasIndexControlPanel {
    [CmdletBinding()]
    param()

    foreach ($process in @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
                $_.MainWindowTitle -like '*Indexing Options*'
            })) {
        try {
            $process.Kill()
            if (-not $process.WaitForExit(10000)) {
                throw "Indexing Options process $($process.Id) did not exit after termination."
            }
        }
        finally {
            $process.Dispose()
        }
    }
}

function Invoke-AtlasIndexConfiguration {
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
        [string]$RequestedOperation,

        [string]$RequestedPath,

        [int]$RequestedSettingValue,

        [bool]$SettingValueWasBound
    )

    $requiresPath = $RequestedOperation -in @('Include', 'Exclude')
    if ($requiresPath -and [string]::IsNullOrWhiteSpace($RequestedPath)) {
        throw "$RequestedOperation requires a fully qualified index path."
    }
    if (-not $requiresPath -and -not [string]::IsNullOrEmpty($RequestedPath)) {
        throw "$RequestedOperation does not accept an index path."
    }
    $requiresSettingValue = $RequestedOperation -eq 'SetRespectPowerModes'
    if ($requiresSettingValue -and -not $SettingValueWasBound) {
        throw 'SetRespectPowerModes requires an explicit setting value.'
    }
    if (-not $requiresSettingValue -and $SettingValueWasBound) {
        throw "$RequestedOperation does not accept a setting value."
    }

    Assert-AtlasIndexAdministrator
    switch ($RequestedOperation) {
        'Include' {
            [void](Add-AtlasIndexPath -Mode Include -Path $RequestedPath)
        }
        'Exclude' {
            [void](Add-AtlasIndexPath -Mode Exclude -Path $RequestedPath)
        }
        'CleanPolicies' {
            Clear-AtlasIndexPolicyRootSet
        }
        'Start' {
            Set-AtlasSearchServiceState -State Running
            Set-AtlasIndexSettingsVisibility -Hidden $false
            $nativePaths = Get-AtlasIndexNativePathSet
            [void](Invoke-AtlasIndexNativeCommand -FilePath $nativePaths.GpUpdate `
                    -ArgumentList @('/force', '/wait:600') `
                    -Description 'refreshing Group Policy')
            Assert-AtlasSearchServiceConfiguration -Configuration DelayedAutomatic
            Assert-AtlasSearchServiceState -State Running
            Assert-AtlasIndexSettingsVisibility -Hidden $false
        }
        'Stop' {
            Set-AtlasIndexSettingsVisibility -Hidden $true
            Stop-AtlasIndexControlPanel
            Set-AtlasSearchServiceState -State Stopped
        }
        'SetRespectPowerModes' {
            Set-AtlasIndexRegistryDword `
                -KeyPath 'SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex' `
                -Name 'RespectPowerModes' `
                -Value $RequestedSettingValue
        }
        'ResetSetupCompleted' {
            Set-AtlasIndexRegistryDword `
                -KeyPath 'SOFTWARE\Microsoft\Windows Search' `
                -Name 'SetupCompletedSuccessfully' `
                -Value 0
        }
    }
}

function Write-AtlasIndexError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $exitCode = 1
    if ($ErrorRecord.Exception.Data.Contains($script:AtlasIndexExitCodeKey)) {
        $exitCode = [int]$ErrorRecord.Exception.Data[$script:AtlasIndexExitCodeKey]
    }
    Write-Error -ErrorRecord $ErrorRecord -ErrorAction Continue
    return $exitCode
}

if ($LibraryOnly) {
    return
}

try {
    Invoke-AtlasIndexConfiguration `
        -RequestedOperation $Operation `
        -RequestedPath $IndexPath `
        -RequestedSettingValue $SettingValue `
        -SettingValueWasBound ($PSBoundParameters.ContainsKey('SettingValue'))
    if ($InProcess) {
        return
    }
    exit 0
}
catch {
    if ($InProcess) {
        throw
    }
    $exitCode = Write-AtlasIndexError -ErrorRecord $_
    exit $exitCode
}
