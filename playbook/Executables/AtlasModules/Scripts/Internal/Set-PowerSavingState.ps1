[CmdletBinding()]
param(
    [ValidateSet('Atlas', 'Default')]
    [string]$Mode,

    [switch]$Silent,

    [switch]$LibraryOnly
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:AtlasPowerScheme = '11111111-1111-1111-1111-111111111111'
$script:BalancedPowerScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
$script:PowerStateSubKey = 'SOFTWARE\AtlasOS\Services\PowerSaving'
$script:PowerStateValue = 'PreviousPowerSchemeGuid'

function ConvertTo-AtlasPowerSchemeGuid {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )

    $guid = [guid]::Empty
    if (-not [guid]::TryParse($Value, [ref]$guid) -or $guid -eq [guid]::Empty) {
        throw "Invalid power-scheme GUID '$Value'."
    }
    return $guid.ToString('D').ToLowerInvariant()
}

function Invoke-AtlasPowerCfg {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& $FilePath @ArgumentList 2>&1)
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode -or [int]$exitCode -ne 0) {
        $detail = (@($output | ForEach-Object { [string]$_ }) -join ' ').Trim()
        throw "powercfg.exe $($ArgumentList -join ' ') failed with exit code '$exitCode'. $detail"
    }
    return [string[]]@($output | ForEach-Object { [string]$_ })
}

function Get-AtlasPowerSchemeGuidFromOutput {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Output,

        [switch]$RequireSingle
    )

    $text = $Output -join "`n"
    $guids = @([regex]::Matches(
            $text,
            '(?i)(?<![0-9a-f])[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}(?![0-9a-f])'
        ) | ForEach-Object {
            ConvertTo-AtlasPowerSchemeGuid -Value $_.Value
        } | Sort-Object -Unique)
    if ($RequireSingle -and $guids.Count -ne 1) {
        throw "Expected one power-scheme GUID, found $($guids.Count)."
    }
    return [string[]]$guids
}

function Get-AtlasActivePowerScheme {
    param([Parameter(Mandatory = $true)][string]$PowerCfgPath)

    return @(Get-AtlasPowerSchemeGuidFromOutput `
            -Output (Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @('/getactivescheme')) `
            -RequireSingle)[0]
}

function Get-AtlasPowerSchemeInventory {
    param([Parameter(Mandatory = $true)][string]$PowerCfgPath)

    return @(Get-AtlasPowerSchemeGuidFromOutput `
            -Output (Invoke-AtlasPowerCfg -FilePath $PowerCfgPath -ArgumentList @('/l')))
}

function Get-AtlasPreviousPowerScheme {
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $key = $null
    try {
        $key = $baseKey.OpenSubKey($script:PowerStateSubKey, $false)
        if ($null -eq $key -or
            -not @($key.GetValueNames()).Contains($script:PowerStateValue)) {
            return $null
        }
        if ($key.GetValueKind($script:PowerStateValue) -ne
            [Microsoft.Win32.RegistryValueKind]::String) {
            throw 'The saved Atlas power scheme has an unexpected registry type.'
        }
        return ConvertTo-AtlasPowerSchemeGuid -Value ([string]$key.GetValue(
                $script:PowerStateValue,
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            ))
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        $baseKey.Dispose()
    }
}

function Save-AtlasPreviousPowerScheme {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SchemeGuid
    )

    $existing = Get-AtlasPreviousPowerScheme
    if ($null -ne $existing) {
        return $existing
    }

    $scheme = ConvertTo-AtlasPowerSchemeGuid -Value $SchemeGuid
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $key = $null
    try {
        $key = $baseKey.CreateSubKey($script:PowerStateSubKey)
        $key.SetValue(
            $script:PowerStateValue,
            $scheme,
            [Microsoft.Win32.RegistryValueKind]::String
        )
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        $baseKey.Dispose()
    }

    $saved = Get-AtlasPreviousPowerScheme
    if ($saved -cne $scheme) {
        throw 'The previous power-scheme state was not saved.'
    }
    return $saved
}

function Clear-AtlasPreviousPowerScheme {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExpectedSchemeGuid
    )

    $expected = ConvertTo-AtlasPowerSchemeGuid -Value $ExpectedSchemeGuid
    $current = Get-AtlasPreviousPowerScheme
    if ($null -eq $current) {
        return
    }
    if ($current -cne $expected) {
        throw 'The saved power scheme changed before it could be cleared.'
    }

    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $key = $null
    try {
        $key = $baseKey.OpenSubKey($script:PowerStateSubKey, $true)
        if ($null -ne $key) {
            $key.DeleteValue($script:PowerStateValue, $false)
        }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        $baseKey.Dispose()
    }
}

function Invoke-AtlasPowerSavingState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Atlas', 'Default')]
        [string]$RequestedMode,

        [Parameter(Mandatory = $true)]
        [string]$PowerCfgPath
    )

    $installed = @(Get-AtlasPowerSchemeInventory -PowerCfgPath $PowerCfgPath)
    if ($installed -cnotcontains $script:BalancedPowerScheme) {
        throw 'The Windows Balanced power scheme is not installed.'
    }

    $savedToClear = $null
    if ($RequestedMode -ceq 'Atlas') {
        $active = Get-AtlasActivePowerScheme -PowerCfgPath $PowerCfgPath
        if ($installed -cnotcontains $active) {
            throw "The active power scheme '$active' is not installed."
        }
        $previous = if ($active -ceq $script:AtlasPowerScheme) {
            $script:BalancedPowerScheme
        }
        else {
            $active
        }
        [void](Save-AtlasPreviousPowerScheme -SchemeGuid $previous)

        if ($installed -ccontains $script:AtlasPowerScheme) {
            if ($active -ceq $script:AtlasPowerScheme) {
                [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                        -ArgumentList @('/setactive', $script:BalancedPowerScheme))
            }
            [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                    -ArgumentList @('/delete', $script:AtlasPowerScheme))
        }

        [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @('/duplicatescheme', $script:BalancedPowerScheme, $script:AtlasPowerScheme))
        [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @(
                    '/changename',
                    $script:AtlasPowerScheme,
                    'Atlas Power Scheme',
                    'Atlas AC power policy with documented Windows settings.'
                ))

        foreach ($setting in @(
                @('0012ee47-9041-4b5d-9b77-535fba8b1442', 'fc7372b6-ab2d-43ee-8797-15e9841f2cca', '0'),
                @('54533251-82be-4824-96c1-47b60b740d00', '3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb', '0'),
                @('7516b95f-f776-4464-8c53-06167f40cc99', '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e', '0'),
                @('54533251-82be-4824-96c1-47b60b740d00', '4d2b0152-7d5c-498b-88e2-34345392a2c5', '200')
            )) {
            [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                    -ArgumentList @(
                        '/setacvalueindex',
                        $script:AtlasPowerScheme,
                        $setting[0],
                        $setting[1],
                        $setting[2]
                    ))
        }
        [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @('/setactive', $script:AtlasPowerScheme))
        $expectedActive = $script:AtlasPowerScheme
    }
    else {
        $saved = Get-AtlasPreviousPowerScheme
        $target = if ($null -ne $saved -and
            $saved -cne $script:AtlasPowerScheme -and
            $installed -ccontains $saved) {
            $saved
        }
        else {
            $script:BalancedPowerScheme
        }

        [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @('/setactive', $target))
        if ($installed -ccontains $script:AtlasPowerScheme) {
            [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                    -ArgumentList @('/delete', $script:AtlasPowerScheme))
        }
        if ($null -ne $saved) {
            $savedToClear = $saved
        }
        $expectedActive = $target
    }

    $activeAfter = Get-AtlasActivePowerScheme -PowerCfgPath $PowerCfgPath
    if ($activeAfter -cne $expectedActive) {
        throw "The active power scheme is '$activeAfter'; expected '$expectedActive'."
    }
    if ($null -ne $savedToClear) {
        Clear-AtlasPreviousPowerScheme -ExpectedSchemeGuid $savedToClear
    }
}

if ($LibraryOnly) {
    return
}
if ([string]::IsNullOrWhiteSpace($Mode)) {
    throw 'Power Saving mode is required.'
}
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Power Saving changes require an elevated Administrator process.'
}

$powerCfgPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'powercfg.exe')
if (-not [IO.File]::Exists($powerCfgPath)) {
    throw "Windows powercfg.exe was not found at '$powerCfgPath'."
}

$mutex = [Threading.Mutex]::new($false, 'Global\AtlasOS.PowerSaving.Transaction.v1')
$ownsMutex = $false
try {
    try {
        $ownsMutex = $mutex.WaitOne([TimeSpan]::FromSeconds(30))
    }
    catch [Threading.AbandonedMutexException] {
        $ownsMutex = $true
    }
    if (-not $ownsMutex) {
        throw 'Timed out waiting for another Atlas power operation to finish.'
    }

    if (-not $Silent) {
        Write-Output $(if ($Mode -ceq 'Atlas') {
                'Applying the Atlas AC power policy...'
            }
            else {
                'Restoring the previous power plan...'
            })
    }
    Invoke-AtlasPowerSavingState -RequestedMode $Mode -PowerCfgPath $powerCfgPath
}
finally {
    if ($ownsMutex) {
        [void]$mutex.ReleaseMutex()
    }
    $mutex.Dispose()
}

if (-not $Silent) {
    [void](Read-Host 'Completed. Press Enter to exit')
}
