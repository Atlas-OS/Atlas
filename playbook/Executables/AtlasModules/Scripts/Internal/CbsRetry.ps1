[CmdletBinding()]
param(
    [switch]$Recover,
    [switch]$LibraryOnly
)

Set-StrictMode -Version 3.0
$script:AtlasCbsRetryMutexName = 'Global\AtlasOS.CbsRetry'

function Get-AtlasCbsRetryStatePath {
    Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Recovery\CbsRetry.json'
}

function Get-AtlasLegacyCbsRetryStatePath {
    Join-Path ([Environment]::GetFolderPath('Windows')) `
        'System32\safeModePackagesToInstall.atlasmodule'
}

function Read-AtlasCbsRetryState {
    param(
        [string]$Path = (Get-AtlasCbsRetryStatePath),
        [string]$LegacyPath
    )
    if (![IO.File]::Exists($Path)) {
        if ([string]::IsNullOrEmpty($LegacyPath) -and [string]::Equals(
                [IO.Path]::GetFullPath($Path), [IO.Path]::GetFullPath((Get-AtlasCbsRetryStatePath)),
                [StringComparison]::OrdinalIgnoreCase)) {
            $LegacyPath = Get-AtlasLegacyCbsRetryStatePath
        }
        if ([string]::IsNullOrEmpty($LegacyPath) -or ![IO.File]::Exists($LegacyPath)) { return $null }
        $packages = @(Get-Content -LiteralPath $LegacyPath -ErrorAction Stop |
            ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ })
        if ($packages.Count -eq 0) { throw "Legacy CBS retry state '$LegacyPath' is empty." }
        $state = Write-AtlasCbsRetryState -Phase Pending -Packages $packages -Path $Path
        try { [IO.File]::Delete($LegacyPath) }
        catch {
            Clear-AtlasCbsRetryState -Path $Path
            throw
        }
        return $state
    }
    $state = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($state.Version -ne 1 -or [string]$state.Phase -notin @('Pending', 'Armed') -or
        @($state.Packages).Count -eq 0) {
        throw "CBS retry state '$Path' is invalid."
    }
    foreach ($package in @($state.Packages)) {
        if ([string]::IsNullOrWhiteSpace([string]$package) -or ![IO.Path]::IsPathRooted([string]$package)) {
            throw "CBS retry state '$Path' contains a non-absolute package path."
        }
    }
    return $state
}

function Write-AtlasCbsRetryState {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Pending', 'Armed')][string]$Phase,
        [Parameter(Mandatory = $true)][string[]]$Packages,
        [string]$Path = (Get-AtlasCbsRetryStatePath)
    )
    if ($Packages.Count -eq 0) { throw 'At least one CBS package is required.' }
    $absolute = @($Packages | ForEach-Object {
        if (![IO.Path]::IsPathRooted($_)) { throw "CBS package path '$_' is not absolute." }
        [IO.Path]::GetFullPath($_)
    })
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    $state = [ordered]@{
        Version = 1; Phase = $Phase; Packages = $absolute
        UpdatedUtc = [DateTime]::UtcNow.ToString('o')
    }
    [IO.File]::WriteAllText($Path, ($state | ConvertTo-Json -Compress),
        (New-Object Text.UTF8Encoding($false)))
    return [pscustomobject]$state
}

function Clear-AtlasCbsRetryState {
    param([string]$Path = (Get-AtlasCbsRetryStatePath))
    if ([IO.File]::Exists($Path)) { [IO.File]::Delete($Path) }
}

function Invoke-WithAtlasCbsRetryLock {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)
    $mutex = New-Object Threading.Mutex($false, $script:AtlasCbsRetryMutexName)
    $held = $false
    try {
        try { $held = $mutex.WaitOne([TimeSpan]::FromSeconds(30)) }
        catch [Threading.AbandonedMutexException] { $held = $true }
        if (!$held) { throw 'Timed out waiting for the Atlas CBS retry lock.' }
        & $Action
    }
    finally {
        if ($held) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Invoke-AtlasCbsRetrySafeMode {
    param([ValidateSet('CommandPrompt', 'Exit')][string]$Mode)
    $requestedMode = $Mode
    if ($null -eq (Get-Command Set-AtlasSafeMode -CommandType Function -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot 'SafeMode.ps1') -LibraryOnly
    }
    Set-AtlasSafeMode -Mode $requestedMode -AllowCbsRetryPending:($requestedMode -ceq 'CommandPrompt')
}

function Invoke-AtlasCbsRetryInstaller {
    param([string[]]$Packages, [scriptblock]$Installer)
    if ($Installer) {
        $result = & $Installer -Packages $Packages -LiteralPaths
    }
    else {
        $command = Get-Command Install-AtlasCbsPackage -CommandType Function -ErrorAction SilentlyContinue
        if ($null -eq $command) {
            $modulePath = Join-Path ([Environment]::GetFolderPath('Windows')) `
                'AtlasModules\Scripts\Modules\Atlas.Software\Atlas.Software.psd1'
            if (![IO.File]::Exists($modulePath)) {
                throw "The installed Atlas.Software module is unavailable at '$modulePath'."
            }
            Import-Module -Name $modulePath -Force -ErrorAction Stop
            $command = Get-Command Install-AtlasCbsPackage -CommandType Function -ErrorAction Stop
        }
        $result = & $command -Packages $Packages -LiteralPaths
    }
    if ($null -ne $result -and $null -ne $result.PSObject.Properties['FailedPackages'] -and
        @($result.FailedPackages).Count -ne 0) {
        throw "CBS packages still failed in Safe Mode: $(@($result.FailedPackages) -join ', ')"
    }
    return $result
}

function Enable-AtlasCbsRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string[]]$Packages,
        [string]$StatePath = (Get-AtlasCbsRetryStatePath),
        [scriptblock]$SafeModeCommand
    )
    Invoke-WithAtlasCbsRetryLock {
        $packagesToArm = @($Packages | ForEach-Object {
            if (![IO.Path]::IsPathRooted($_)) { throw "CBS package path '$_' is not absolute." }
            [IO.Path]::GetFullPath($_)
        })
        $existing = Read-AtlasCbsRetryState -Path $StatePath
        if ($null -ne $existing) {
            if ([string]$existing.Phase -ceq 'Armed') { throw 'A CBS retry is already armed.' }
            $existingPackages = @($existing.Packages)
            $samePackages = $existingPackages.Count -eq $packagesToArm.Count
            for ($index = 0; $samePackages -and $index -lt $packagesToArm.Count; $index++) {
                $samePackages = [string]::Equals(
                    [string]$existingPackages[$index], $packagesToArm[$index],
                    [StringComparison]::OrdinalIgnoreCase)
            }
            if (!$samePackages) { throw 'A different CBS retry is already pending.' }
        }
        else {
            [void](Write-AtlasCbsRetryState -Phase Pending -Packages $packagesToArm -Path $StatePath)
        }
        if ($SafeModeCommand) { & $SafeModeCommand 'CommandPrompt' }
        else { Invoke-AtlasCbsRetrySafeMode -Mode CommandPrompt }
        Write-AtlasCbsRetryState -Phase Armed -Packages $packagesToArm -Path $StatePath
    }
}

function Invoke-AtlasCbsRetryRecovery {
    [CmdletBinding()]
    param(
        [string]$StatePath = (Get-AtlasCbsRetryStatePath),
        [scriptblock]$SafeModeCommand,
        [scriptblock]$Installer
    )
    Invoke-WithAtlasCbsRetryLock {
        $state = Read-AtlasCbsRetryState -Path $StatePath
        if ($null -eq $state) { throw 'No CBS retry is pending.' }
        if ([string]$state.Phase -cne 'Armed') {
            throw 'The CBS retry is pending but has not been armed for Safe Mode.'
        }
        if ($SafeModeCommand) { & $SafeModeCommand 'Exit' }
        else { Invoke-AtlasCbsRetrySafeMode -Mode Exit }
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages @($state.Packages) -Path $StatePath)
        [void](Invoke-AtlasCbsRetryInstaller -Packages @($state.Packages) -Installer $Installer)
        Clear-AtlasCbsRetryState -Path $StatePath
    }
}

if (!$LibraryOnly) {
    if (!$Recover) { throw 'Specify -Recover or use -LibraryOnly.' }
    Invoke-AtlasCbsRetryRecovery
}
