[CmdletBinding(DefaultParameterSetName = 'Report')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Configure')]
    [ValidateSet('Enable', 'Disable')]
    [string]$State
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Supported registry contract:
# https://learn.microsoft.com/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity
# LSA protection, Credential Guard, kernel shadow stacks, and optional Windows features
# are separate controls and are deliberately outside this helper's ownership.
$script:AtlasVbsDeviceGuardPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
$script:AtlasVbsHvciPath =
    'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
$script:AtlasVbsPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard'

function Get-AtlasVbsDwordState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container -ErrorAction Stop)) {
        return [pscustomobject]@{ Exists = $false; Value = $null }
    }

    $key = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (@($key.GetValueNames()) -notcontains $Name) {
        return [pscustomobject]@{ Exists = $false; Value = $null }
    }
    if ($key.GetValueKind($Name) -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
        throw "VBS value '$Name' at '$Path' is not REG_DWORD."
    }

    return [pscustomobject]@{
        Exists = $true
        Value  = [int]$key.GetValue(
            $Name,
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
    }
}

function Assert-AtlasVbsDwordValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet(0, 1, 2, 3)][int]$Value
    )

    $actual = Get-AtlasVbsDwordState -Path $Path -Name $Name
    if (-not $actual.Exists -or [int]$actual.Value -ne $Value) {
        throw "VBS registry readback failed for '$Path\\$Name'; expected DWORD $Value."
    }
}

function Import-AtlasVbsDependencies {
    $modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
    foreach ($relativeManifest in @(
            'Atlas.Core\Atlas.Core.psd1'
            'Atlas.Registry\Atlas.Registry.psd1'
        )) {
        $manifestPath = [IO.Path]::GetFullPath(
            (Join-Path -Path $modulesRoot -ChildPath $relativeManifest)
        )
        if (-not [IO.File]::Exists($manifestPath) -or
            (([IO.File]::GetAttributes($manifestPath) -band
                    [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "Required protected VBS dependency is missing or a reparse point: '$manifestPath'."
        }
        Import-Module -Name $manifestPath -Force -ErrorAction Stop
    }
}

function Assert-AtlasVbsLocalConfigurationAuthority {
    foreach ($policyValueName in @(
            'EnableVirtualizationBasedSecurity'
            'HypervisorEnforcedCodeIntegrity'
            'RequirePlatformSecurityFeatures'
            'LsaCfgFlags'
            'ConfigureSystemGuardLaunch'
            'KernelShadowStacks'
        )) {
        $policyState = Get-AtlasVbsDwordState `
            -Path $script:AtlasVbsPolicyPath `
            -Name $policyValueName
        if ($policyState.Exists) {
            throw "VBS is managed by policy value '$policyValueName'; Atlas will not overwrite local runtime state."
        }
    }
}

function Set-AtlasVbsState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$RequestedState
    )

    Import-AtlasVbsDependencies
    Assert-AtlasPrivilege -Administrator
    Assert-AtlasVbsLocalConfigurationAuthority

    $deviceGuardLock = Get-AtlasVbsDwordState `
        -Path $script:AtlasVbsDeviceGuardPath -Name 'Locked'
    $hvciLock = Get-AtlasVbsDwordState -Path $script:AtlasVbsHvciPath -Name 'Locked'
    foreach ($lock in @($deviceGuardLock, $hvciLock)) {
        if ($lock.Exists -and [int]$lock.Value -notin @(0, 1)) {
            throw 'A VBS lock value has an unsupported value; refusing to guess its semantics.'
        }
    }

    if ($RequestedState -ceq 'Disable' -and
        (($deviceGuardLock.Exists -and [int]$deviceGuardLock.Value -eq 1) -or
            ($hvciLock.Exists -and [int]$hvciLock.Value -eq 1))) {
        throw 'VBS or memory integrity is protected by UEFI lock and cannot be disabled by a registry-only action.'
    }

    $entries = if ($RequestedState -ceq 'Enable') {
        @(
            @{ Path = $script:AtlasVbsDeviceGuardPath; Name = 'RequirePlatformSecurityFeatures'; Type = 'DWord'; Data = 1 }
            @{ Path = $script:AtlasVbsDeviceGuardPath; Name = 'Locked'; Type = 'DWord'; Data = if ($deviceGuardLock.Exists) { [int]$deviceGuardLock.Value } else { 0 } }
            @{ Path = $script:AtlasVbsDeviceGuardPath; Name = 'EnableVirtualizationBasedSecurity'; Type = 'DWord'; Data = 1 }
            @{ Path = $script:AtlasVbsHvciPath; Name = 'Locked'; Type = 'DWord'; Data = if ($hvciLock.Exists) { [int]$hvciLock.Value } else { 0 } }
            @{ Path = $script:AtlasVbsHvciPath; Name = 'Enabled'; Type = 'DWord'; Data = 1 }
        )
    }
    else {
        @(
            @{ Path = $script:AtlasVbsHvciPath; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
            @{ Path = $script:AtlasVbsDeviceGuardPath; Name = 'EnableVirtualizationBasedSecurity'; Type = 'DWord'; Data = 0 }
        )
    }

    foreach ($entry in $entries) {
        Set-AtlasRegistryValue -Path $entry.Path -Name $entry.Name `
            -Type $entry.Type -Data $entry.Data
        Assert-AtlasVbsDwordValue -Path $entry.Path -Name $entry.Name -Value $entry.Data
    }

    Write-Host (
        "VBS and memory integrity are configured to {0}; restart Windows to measure the running state." -f
        $RequestedState.ToLowerInvariant()
    )
}

function ConvertTo-AtlasVbsPropertyNames {
    param(
        [AllowEmptyCollection()][object[]]$Value = @(),
        [Parameter(Mandatory = $true)][hashtable]$Map
    )

    $resolved = New-Object 'Collections.Generic.List[string]'
    foreach ($rawValue in @($Value)) {
        $number = [int]$rawValue
        if ($number -eq 0) {
            continue
        }
        if ($Map.ContainsKey($number)) {
            $resolved.Add([string]$Map[$number])
        }
        else {
            $resolved.Add("Unknown ($number)")
        }
    }
    if ($resolved.Count -eq 0) {
        $resolved.Add('None')
    }
    return $resolved.ToArray()
}

function Get-AtlasVbsReport {
    $instances = @(Get-CimInstance -ClassName Win32_DeviceGuard `
            -Namespace 'root\Microsoft\Windows\DeviceGuard' -ErrorAction Stop)
    if ($instances.Count -ne 1) {
        throw "Expected exactly one Win32_DeviceGuard instance, but received $($instances.Count)."
    }

    $instance = $instances[0]
    $statusMap = @{
        0 = 'Disabled'
        1 = 'Enabled but not running'
        2 = 'Enabled and running'
    }
    $serviceMap = @{
        1 = 'Credential Guard'
        2 = 'Memory integrity (HVCI)'
        3 = 'Secure Launch'
        4 = 'SMM Firmware Measurement'
        5 = 'Kernel-mode Hardware-enforced Stack Protection'
        6 = 'Kernel-mode Hardware-enforced Stack Protection (Audit mode)'
        7 = 'Hypervisor-Enforced Paging Translation'
    }
    $propertyMap = @{
        1 = 'Base virtualization support'
        2 = 'Secure Boot'
        3 = 'DMA protection'
        4 = 'Secure memory overwrite'
        5 = 'UEFI code read-only'
        6 = 'SMM security mitigations 1.0'
        7 = 'Mode-based execution control'
        8 = 'APIC virtualization'
    }

    $status = [int]$instance.VirtualizationBasedSecurityStatus
    return [pscustomobject]@{
        PSTypeName          = 'Atlas.VbsConfigurationReport'
        VbsStatus           = if ($statusMap.ContainsKey($status)) { $statusMap[$status] } else { "Unknown ($status)" }
        ConfiguredServices  = [string[]](ConvertTo-AtlasVbsPropertyNames -Value $instance.SecurityServicesConfigured -Map $serviceMap)
        RunningServices     = [string[]](ConvertTo-AtlasVbsPropertyNames -Value $instance.SecurityServicesRunning -Map $serviceMap)
        RequiredProperties  = [string[]](ConvertTo-AtlasVbsPropertyNames -Value $instance.RequiredSecurityProperties -Map $propertyMap)
        AvailableProperties = [string[]](ConvertTo-AtlasVbsPropertyNames -Value $instance.AvailableSecurityProperties -Map $propertyMap)
    }
}

if ($PSCmdlet.ParameterSetName -ceq 'Configure') {
    Set-AtlasVbsState -RequestedState $State
}
else {
    Get-AtlasVbsReport
}
