# Atlas.Security domain: Virtualization-Based Security and memory integrity.
#
# The registry values Microsoft documents:
# https://learn.microsoft.com/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity
# LSA protection, Credential Guard, kernel shadow stacks, and optional Windows features
# are separate controls and are deliberately outside this domain's ownership.

$script:AtlasVbsDeviceGuardPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
$script:AtlasVbsHvciRelativePath = 'Scenarios\HypervisorEnforcedCodeIntegrity'
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

function Get-AtlasVbsPolicyConflict {
    <#
    .SYNOPSIS
        Names the Device Guard policy values that would override the requested state.
        Policy that already agrees, such as "Turn On Virtualization Based Security" set
        to Disabled (EnableVirtualizationBasedSecurity = 0) or a guide's
        LsaCfgFlags = 0, is not a conflict.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Enable', 'Disable')][string]$State,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PolicyPath
    )

    # The data each value takes in Windows' DeviceGuard.admx. RequirePlatformSecurityFeatures
    # and HVCIMATRequired only qualify a feature the policy turns on, so they never conflict.
    $meanings = [ordered]@{
        EnableVirtualizationBasedSecurity = @{ On = @(1); Off = @(0); Unset = @() }
        HypervisorEnforcedCodeIntegrity   = @{ On = @(1, 2); Off = @(0); Unset = @(3) }
        LsaCfgFlags                       = @{ On = @(1, 2); Off = @(0); Unset = @(3) }
        MachineIdentityIsolation          = @{ On = @(1, 2); Off = @(0); Unset = @(3) }
        ConfigureSystemGuardLaunch        = @{ On = @(1); Off = @(2); Unset = @(0) }
        ConfigureKernelShadowStacksLaunch = @{ On = @(1, 2); Off = @(3); Unset = @(0) }
    }
    # Enabling needs VBS and memory integrity; every other feature runs on VBS, so any
    # of them turned on by policy keeps VBS from being disabled.
    $blocksEnable = @('EnableVirtualizationBasedSecurity', 'HypervisorEnforcedCodeIntegrity')

    $conflicts = New-Object 'Collections.Generic.List[string]'
    foreach ($name in $meanings.Keys) {
        $policy = Get-AtlasVbsDwordState -Path $PolicyPath -Name $name
        if (-not $policy.Exists) { continue }
        $meaning = $meanings[$name]
        $value = [int]$policy.Value
        $known = $meaning.On + $meaning.Off + $meaning.Unset
        $conflicting = if ($value -notin $known) { $true }
        elseif ($State -ceq 'Disable') { $value -in $meaning.On }
        else { $name -in $blocksEnable -and $value -in $meaning.Off }
        if ($conflicting) { $conflicts.Add("$name = $value") }
    }
    return [string[]]$conflicts.ToArray()
}

function Set-AtlasVbsConfiguration {
    <#
    .SYNOPSIS
        Enables or disables VBS and memory integrity through Microsoft's documented
        runtime registry values, refusing when policy overrides the requested state or
        a UEFI lock protects the current state. Every written value is read back.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$State,

        # Log a warning and change nothing when policy overrides the requested state,
        # instead of failing. Installs use it so a PC's own policy can't stop them.
        [switch]$SkipWhenPolicyConflicts,

        # Tests point these at a scratch key.
        [ValidateNotNullOrEmpty()]
        [string]$DeviceGuardPath = $script:AtlasVbsDeviceGuardPath,

        [ValidateNotNullOrEmpty()]
        [string]$PolicyPath = $script:AtlasVbsPolicyPath
    )

    Assert-AtlasPrivilege -Administrator
    $conflicts = @(Get-AtlasVbsPolicyConflict -State $State -PolicyPath $PolicyPath)
    if ($conflicts.Count -gt 0) {
        $message = "Policy under '$PolicyPath' overrides this change ($($conflicts -join ', ')); Atlas leaves VBS as the policy sets it."
        if (-not $SkipWhenPolicyConflicts) { throw $message }
        Write-AtlasLog -Level Warning -Message "VBS and memory integrity not configured to $($State.ToLowerInvariant()). $message"
        return
    }

    $hvciPath = Join-Path -Path $DeviceGuardPath -ChildPath $script:AtlasVbsHvciRelativePath
    $deviceGuardLock = Get-AtlasVbsDwordState -Path $DeviceGuardPath -Name 'Locked'
    $hvciLock = Get-AtlasVbsDwordState -Path $hvciPath -Name 'Locked'
    foreach ($lock in @($deviceGuardLock, $hvciLock)) {
        if ($lock.Exists -and [int]$lock.Value -notin @(0, 1)) {
            throw 'A VBS lock value has an unsupported value; refusing to guess its semantics.'
        }
    }

    if ($State -ceq 'Disable' -and
        (($deviceGuardLock.Exists -and [int]$deviceGuardLock.Value -eq 1) -or
            ($hvciLock.Exists -and [int]$hvciLock.Value -eq 1))) {
        throw 'VBS or memory integrity is protected by UEFI lock and cannot be disabled by a registry-only action.'
    }

    $entries = if ($State -ceq 'Enable') {
        @(
            @{ Path = $DeviceGuardPath; Name = 'RequirePlatformSecurityFeatures'; Type = 'DWord'; Data = 1 }
            @{ Path = $DeviceGuardPath; Name = 'Locked'; Type = 'DWord'; Data = if ($deviceGuardLock.Exists) { [int]$deviceGuardLock.Value } else { 0 } }
            @{ Path = $DeviceGuardPath; Name = 'EnableVirtualizationBasedSecurity'; Type = 'DWord'; Data = 1 }
            @{ Path = $hvciPath; Name = 'Locked'; Type = 'DWord'; Data = if ($hvciLock.Exists) { [int]$hvciLock.Value } else { 0 } }
            @{ Path = $hvciPath; Name = 'Enabled'; Type = 'DWord'; Data = 1 }
        )
    }
    else {
        @(
            @{ Path = $hvciPath; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
            @{ Path = $DeviceGuardPath; Name = 'EnableVirtualizationBasedSecurity'; Type = 'DWord'; Data = 0 }
        )
    }

    foreach ($entry in $entries) {
        Set-AtlasRegistryValue -Path $entry.Path -Name $entry.Name `
            -Type $entry.Type -Data $entry.Data
        Assert-AtlasVbsDwordValue -Path $entry.Path -Name $entry.Name -Value $entry.Data
    }

    Write-AtlasLog -Message "VBS and memory integrity configured to $($State.ToLowerInvariant())."
    Write-AtlasSuccess -Text (
        "VBS and memory integrity are configured to {0}. The running state can be checked after a restart." -f
        $State.ToLowerInvariant()
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

function Get-AtlasVbsConfiguration {
    <#
    .SYNOPSIS
        Reports the running VBS state from the Win32_DeviceGuard provider: status,
        configured and running security services, and required and available
        platform security properties, as readable names.
    #>
    [CmdletBinding()]
    param()

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
