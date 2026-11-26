# Atlas.Hardware domain: the Atlas power scheme and device power saving.
#
# 'Atlas' duplicates the Windows Balanced scheme under a fixed GUID, applies three
# AC settings and activates it, remembering the previously active scheme in
# the Atlas services state key. 'Default' reactivates that remembered scheme (or
# Balanced when it is gone) and deletes the Atlas scheme. Every powercfg call is
# exit-code checked and the final active scheme is verified.

# The Atlas scheme's GUID is fixed so Atlas can always find, replace and verify its own plan.
# 381b4222-f694-41f0-9685-ff5bb260df2e is the Windows Balanced scheme (SCHEME_BALANCED).
$script:AtlasPowerScheme = '11111111-1111-1111-1111-111111111111'
$script:BalancedPowerScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
$script:PowerStateSubKey = 'SOFTWARE\AtlasOS\Services\PowerSaving'
$script:PowerStateValue = 'PreviousPowerSchemeGuid'
$script:PowerTransactionMutexName = 'Global\AtlasOS.PowerSaving.Transaction.v1'

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

    # Redirected stderr becomes an error record, which Stop would throw before the
    # exit code is read; keep it as output so the exit code decides.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $FilePath @ArgumentList 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
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
        [AllowEmptyString()]
        [string[]]$Output,

        [switch]$RequireSingle,

        [switch]$AllowUnset
    )

    $text = $Output -join "`n"
    $guids = @([regex]::Matches(
            $text,
            '(?i)(?<![0-9a-f])[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}(?![0-9a-f])'
        ) | ForEach-Object { $_.Value.ToLowerInvariant() } | Sort-Object -Unique)
    $unset = [string][guid]::Empty
    if (-not $RequireSingle) {
        return [string[]]@($guids -cne $unset)
    }
    if ($guids.Count -ne 1) {
        throw "Expected one power-scheme GUID, found $($guids.Count)."
    }
    if ($AllowUnset -and $guids[0] -ceq $unset) {
        return
    }
    return ConvertTo-AtlasPowerSchemeGuid -Value $guids[0]
}

function Get-AtlasActivePowerScheme {
    param([Parameter(Mandatory = $true)][string]$PowerCfgPath, [switch]$AllowUnset)

    return Get-AtlasPowerSchemeGuidFromOutput `
            -Output (Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @('/getactivescheme')) `
            -RequireSingle -AllowUnset:$AllowUnset
}

function Get-AtlasPowerSchemeInventory {
    param([Parameter(Mandatory = $true)][string]$PowerCfgPath)

    return @(Get-AtlasPowerSchemeGuidFromOutput `
            -Output (Invoke-AtlasPowerCfg -FilePath $PowerCfgPath -ArgumentList @('/l')))
}

function Test-AtlasPowerSchemeStored {
    <#
    .SYNOPSIS
        Returns whether Windows stores a power plan with the given GUID, listed or not.
    .DESCRIPTION
        Modern Standby PCs list only Balanced and plans copied from it, but an unlisted
        plan, such as the Ultimate Performance copy older Atlas versions made, still
        holds its GUID: /duplicatescheme then refuses it. Windows keeps each plan as a
        key under User\PowerSchemes.
    #>
    param([Parameter(Mandatory = $true)][string]$SchemeGuid)

    $scheme = ConvertTo-AtlasPowerSchemeGuid -Value $SchemeGuid
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $key = $null
    try {
        $key = $baseKey.OpenSubKey("SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$scheme", $false)
        return $null -ne $key
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        $baseKey.Dispose()
    }
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

function Restore-AtlasBalancedPowerScheme {
    Initialize-AtlasNativeType
    [Atlas.Native.PowerSchemes]::RestoreDefault([guid]$script:BalancedPowerScheme)
}

function Restore-AtlasMissingBalancedPowerScheme {
    <#
    .SYNOPSIS
        Restores the Windows Balanced plan that Windows doesn't store, checks that
        powercfg lists it, and returns the power-scheme inventory.
    #>
    param([Parameter(Mandatory = $true)][string]$PowerCfgPath)

    try {
        Restore-AtlasBalancedPowerScheme
    }
    catch {
        throw "The Windows Balanced power scheme is missing and could not be restored: $($_.Exception.Message)"
    }
    $installed = @(Get-AtlasPowerSchemeInventory -PowerCfgPath $PowerCfgPath)
    if ($installed -cnotcontains $script:BalancedPowerScheme) {
        throw 'Windows did not list the Balanced power scheme after restoring it.'
    }
    Write-AtlasLog -Message 'Restored the missing Windows Balanced power scheme.'
    return $installed
}

function Invoke-AtlasPowerTransaction {
    <#
    .SYNOPSIS
        Runs a power-plan change while holding the Atlas power mutex, so concurrent Atlas
        power operations are serialised.
    #>
    param([Parameter(Mandatory = $true)][scriptblock]$Operation)

    $mutex = New-Object Threading.Mutex($false, $script:PowerTransactionMutexName)
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
        & $Operation
    }
    finally {
        if ($ownsMutex) {
            [void]$mutex.ReleaseMutex()
        }
        $mutex.Dispose()
    }
}

function Get-AtlasPowerCfgPath {
    $powerCfgPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'powercfg.exe')
    if (-not [IO.File]::Exists($powerCfgPath)) {
        throw "Windows powercfg.exe was not found at '$powerCfgPath'."
    }
    return $powerCfgPath
}

function Enable-AtlasBalancedPowerScheme {
    <#
    .SYNOPSIS
        Makes the Windows Balanced power plan the active plan, restoring it first when
        Windows doesn't have it, and checks that it's active.
    .DESCRIPTION
        Tools outside Atlas can delete the Balanced plan, and powercfg then refuses to
        activate it with "Invalid Parameters". A plan Windows still stores but doesn't
        list is activated as it is. This leaves device power saving alone, unlike the
        PowerSaving toggle. Requires Administrator rights; concurrent Atlas power
        operations are serialised.
    #>
    [CmdletBinding()]
    param()

    Assert-AtlasPrivilege -Administrator
    $powerCfgPath = Get-AtlasPowerCfgPath
    Invoke-AtlasPowerTransaction -Operation {
        $installed = @(Get-AtlasPowerSchemeInventory -PowerCfgPath $powerCfgPath)
        if ($installed -cnotcontains $script:BalancedPowerScheme -and
            -not (Test-AtlasPowerSchemeStored -SchemeGuid $script:BalancedPowerScheme)) {
            [void](Restore-AtlasMissingBalancedPowerScheme -PowerCfgPath $powerCfgPath)
        }
        [void](Invoke-AtlasPowerCfg -FilePath $powerCfgPath `
                -ArgumentList @('/setactive', $script:BalancedPowerScheme))
        $active = Get-AtlasActivePowerScheme -PowerCfgPath $powerCfgPath
        if ($active -cne $script:BalancedPowerScheme) {
            throw "The Balanced power scheme did not become the active scheme (found '$active')."
        }
    }
    Write-AtlasLog -Message 'Activated the Windows Balanced power scheme.'
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
    $saved = $null
    $target = $null
    if ($RequestedMode -ceq 'Default') {
        $saved = Get-AtlasPreviousPowerScheme
        if ($null -ne $saved -and $saved -cne $script:AtlasPowerScheme -and $installed -ccontains $saved) {
            $target = $saved
        }
    }
    if ($null -eq $target -and $installed -cnotcontains $script:BalancedPowerScheme) {
        if (Test-AtlasPowerSchemeStored -SchemeGuid $script:BalancedPowerScheme) {
            throw 'Windows has a stored Balanced power scheme, but powercfg did not list it.'
        }
        $installed = @(Restore-AtlasMissingBalancedPowerScheme -PowerCfgPath $PowerCfgPath)
    }
    $atlasPresent = $installed -ccontains $script:AtlasPowerScheme -or
        (Test-AtlasPowerSchemeStored -SchemeGuid $script:AtlasPowerScheme)

    $savedToClear = $null
    if ($RequestedMode -ceq 'Atlas') {
        $active = Get-AtlasActivePowerScheme -PowerCfgPath $PowerCfgPath -AllowUnset
        if ($null -eq $active) {
            [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                    -ArgumentList @('/setactive', $script:BalancedPowerScheme))
            $active = Get-AtlasActivePowerScheme -PowerCfgPath $PowerCfgPath
            if ($active -cne $script:BalancedPowerScheme) {
                throw "Windows reported no active power scheme, and Balanced did not become active (found '$active')."
            }
            Write-AtlasLog -Message 'Windows reported no active power scheme. Activated Balanced before creating the Atlas plan.'
        }
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

        if ($atlasPresent) {
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

        # Subgroup GUID, setting GUID, AC value; docs/power-saving-policy.md lists each one:
        # Hard disk > NVMe NOPPME off; Processor power management > Allow Throttle States
        # off; Display > Turn off display after never.
        # The processor performance time check interval keeps Balanced's value: Windows
        # counts its performance, core-parking and hybrid-core decisions in these
        # intervals, so a longer one makes the CPU slower to respond to load.
        foreach ($setting in @(
                @('0012ee47-9041-4b5d-9b77-535fba8b1442', 'fc7372b6-ab2d-43ee-8797-15e9841f2cca', '0'),
                @('54533251-82be-4824-96c1-47b60b740d00', '3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb', '0'),
                @('7516b95f-f776-4464-8c53-06167f40cc99', '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e', '0')
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
        if ($null -eq $target) { $target = $script:BalancedPowerScheme }

        [void](Invoke-AtlasPowerCfg -FilePath $PowerCfgPath `
                -ArgumentList @('/setactive', $target))
        if ($atlasPresent) {
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

function Set-AtlasPowerSavingState {
    <#
    .SYNOPSIS
        Applies the Atlas AC power policy (Mode Atlas) or restores the previously
        active power plan and removes the Atlas plan (Mode Default). Requires
        Administrator rights; concurrent Atlas power operations are serialised.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Atlas', 'Default')]
        [string]$Mode,

        [switch]$Silent
    )

    Assert-AtlasPrivilege -Administrator

    $powerCfgPath = Get-AtlasPowerCfgPath
    Invoke-AtlasPowerTransaction -Operation {
        if (-not $Silent) {
            Write-AtlasStep -Text $(if ($Mode -ceq 'Atlas') {
                    'Applying the Atlas AC power policy...'
                }
                else {
                    'Restoring the previous power plan...'
                })
        }
        Invoke-AtlasPowerSavingState -RequestedMode $Mode -PowerCfgPath $powerCfgPath
    }

    Write-AtlasLog -Message "Power-saving mode '$Mode' applied."
}

# Device Manager's "Allow the computer to turn off this device to save power" check box is
# the MSPower_DeviceEnable WMI class, which each driver that offers the setting implements.
function Get-AtlasDevicePowerManagement {
    return @(CimCmdlets\Get-CimInstance -Namespace 'root/wmi' -ClassName 'MSPower_DeviceEnable' -ErrorAction Stop)
}

function Set-AtlasDevicePowerManagementInstance {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Instance,

        [Parameter(Mandatory = $true)]
        [bool]$Enable
    )

    CimCmdlets\Set-CimInstance -InputObject $Instance -Property @{ Enable = $Enable } -ErrorAction Stop | Out-Null
}

function Set-AtlasDevicePowerSaving {
    <#
    .SYNOPSIS
        Ticks (On) or clears (Off) "Allow the computer to turn off this device to save
        power" for every device whose driver offers it, and returns the instance names
        of the devices that refused. A device that refuses is logged and the rest still
        change; failing to read the devices at all is an error. Requires Administrator
        rights.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('On', 'Off')]
        [string]$State
    )

    Assert-AtlasPrivilege -Administrator

    $enable = $State -ceq 'On'
    $instances = @(Get-AtlasDevicePowerManagement)
    $changed = 0
    $refused = New-Object 'System.Collections.Generic.List[string]'
    foreach ($instance in $instances) {
        if ([bool]$instance.Enable -eq $enable) {
            continue
        }
        $name = [string]$instance.InstanceName
        try {
            Set-AtlasDevicePowerManagementInstance -Instance $instance -Enable $enable
            $changed++
        }
        catch {
            $refused.Add($name)
            Write-AtlasLog -Level Warning -ErrorRecord $_ -Message (
                "Device power saving couldn't be turned $($State.ToLowerInvariant()) for '$name': $($_.Exception.Message)")
        }
    }

    Write-AtlasLog -Message ("Device power saving {0}: changed {1} of {2} device(s), {3} refused." -f
        $State.ToLowerInvariant(), $changed, $instances.Count, $refused.Count)
    return [string[]]$refused.ToArray()
}
