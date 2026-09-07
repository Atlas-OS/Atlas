# Atlas.Network domain: Atlas adapter defaults and the Windows network stack reset.
#
# Atlas mode zeroes the adapter power-saving properties that Atlas manages on every
# PCI network adapter class key. Windows mode resets the IP, TCP and Winsock stacks
# and reinstalls every present network device.

$script:AtlasNetworkClassGuid = '{4d36e972-e325-11ce-bfc1-08002be10318}'
$script:AtlasNetworkSettingNames = @(
    'AutoDisableGigabit'
    'ApCompatMode'
    'SipsEnabled'
    'ReduceSpeedOnPowerDown'
    'DMACoalescing'
)

function Get-AtlasNetworkAdapter {
    CimCmdlets\Get-CimInstance -ClassName Win32_NetworkAdapter -ErrorAction Stop
}

function Get-AtlasPresentNetworkDevice {
    PnpDevice\Get-PnpDevice -Class Net -PresentOnly -ErrorAction Stop
}

function Get-AtlasNetworkRegistryString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath, $false)
    if ($null -eq $key) {
        throw "Registry key 'HKEY_LOCAL_MACHINE\$KeyPath' was not found."
    }

    try {
        $actualNames = @($key.GetValueNames() | Where-Object {
                [string]::Equals($_, $Name, [StringComparison]::OrdinalIgnoreCase)
            })
        if ($actualNames.Count -ne 1) {
            throw "Registry value 'HKEY_LOCAL_MACHINE\$KeyPath\$Name' was not found."
        }
        if ($key.GetValueKind($actualNames[0]) -ne
            [Microsoft.Win32.RegistryValueKind]::String) {
            throw "Registry value 'HKEY_LOCAL_MACHINE\$KeyPath\$Name' is not REG_SZ."
        }

        return [string]$key.GetValue(
            $actualNames[0],
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
    }
    finally {
        $key.Dispose()
    }
}

function Test-AtlasNetworkRegistryKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath, $false)
    if ($null -eq $key) {
        return $false
    }
    $key.Dispose()
    return $true
}

function Get-AtlasNetworkRegistryValueName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath, $false)
    if ($null -eq $key) {
        throw "Registry key 'HKEY_LOCAL_MACHINE\$KeyPath' was not found."
    }
    try {
        return @($key.GetValueNames())
    }
    finally {
        $key.Dispose()
    }
}

function Write-AtlasNetworkRegistryString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath, $true)
    if ($null -eq $key) {
        throw "Registry key 'HKEY_LOCAL_MACHINE\$KeyPath' could not be opened for writing."
    }
    try {
        $key.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        $key.Dispose()
    }
}

function Get-AtlasPciNetworkClassKey {
    <#
    .SYNOPSIS
        Resolves the distinct driver class keys of every PCI network adapter, refusing
        non-canonical device identifiers and keys outside the network adapter class.
    #>
    $classKeys = New-Object 'System.Collections.Generic.List[string]'
    $seen = @{}

    foreach ($adapter in @(Get-AtlasNetworkAdapter)) {
        if ($null -eq $adapter) {
            throw 'Network adapter enumeration returned a null record.'
        }

        $pnpDeviceId = [string]$adapter.PNPDeviceID
        if ([string]::IsNullOrWhiteSpace($pnpDeviceId) -or
            $pnpDeviceId -notmatch '(?i)^PCI\\VEN_') {
            continue
        }
        if ($pnpDeviceId -notmatch
            '(?i)^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&[A-Z0-9_]+)*\\[A-Z0-9&_.{}-]+$') {
            throw "PCI network adapter identifier '$pnpDeviceId' is not canonical."
        }

        $enumKey = "SYSTEM\CurrentControlSet\Enum\$pnpDeviceId"
        $driver = Get-AtlasNetworkRegistryString -KeyPath $enumKey -Name 'Driver'
        if ($driver -notmatch
            ('(?i)^' + [regex]::Escape($script:AtlasNetworkClassGuid) + '\\[0-9]{4}$')) {
            throw "Network adapter '$pnpDeviceId' resolved to invalid class key '$driver'."
        }

        $classKey = "SYSTEM\CurrentControlSet\Control\Class\$driver"
        if (-not (Test-AtlasNetworkRegistryKey -KeyPath $classKey)) {
            throw "Network adapter class key 'HKEY_LOCAL_MACHINE\$classKey' does not exist."
        }

        if (-not $seen.ContainsKey($classKey)) {
            $seen[$classKey] = $true
            $classKeys.Add($classKey)
        }
    }

    return $classKeys.ToArray()
}

function Invoke-AtlasNetworkAdapterDefault {
    <#
    .SYNOPSIS
        Writes '0' to every managed power-saving property (plain or starred name) that
        a PCI adapter class key exposes.
    #>
    $classKeys = @(Get-AtlasPciNetworkClassKey)
    $managedNames = New-Object 'System.Collections.Generic.HashSet[string]' (
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($setting in $script:AtlasNetworkSettingNames) {
        [void]$managedNames.Add($setting)
        [void]$managedNames.Add("*$setting")
    }

    $changedValues = 0
    foreach ($classKey in $classKeys) {
        foreach ($valueName in @(Get-AtlasNetworkRegistryValueName -KeyPath $classKey)) {
            if ($managedNames.Contains([string]$valueName)) {
                Write-AtlasNetworkRegistryString `
                    -KeyPath $classKey `
                    -Name ([string]$valueName) `
                    -Value '0'
                $changedValues++
            }
        }
    }

    return [pscustomobject]@{
        AdapterClassKeyCount = $classKeys.Count
        ChangedValueCount    = $changedValues
    }
}

function Invoke-AtlasWindowsNetworkDefault {
    <#
    .SYNOPSIS
        Runs the fixed netsh reset sequence, removes every present network device
        once, and rescans devices so Windows reinstalls them with default settings.
    #>
    $windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    if ([string]::IsNullOrWhiteSpace($windowsRoot)) {
        throw 'Windows did not return its Windows directory.'
    }
    $systemDirectory = Join-Path -Path $windowsRoot -ChildPath 'System32'
    $netshPath = Join-Path -Path $systemDirectory -ChildPath 'netsh.exe'
    $pnpUtilPath = Join-Path -Path $systemDirectory -ChildPath 'pnputil.exe'

    $netshCommands = @(
        [pscustomobject]@{ Arguments = [string[]]@('int', 'ip', 'reset') }
        [pscustomobject]@{ Arguments = [string[]]@('interface', 'ipv4', 'reset') }
        [pscustomobject]@{ Arguments = [string[]]@('interface', 'ipv6', 'reset') }
        [pscustomobject]@{ Arguments = [string[]]@('interface', 'tcp', 'reset') }
        [pscustomobject]@{ Arguments = [string[]]@('winsock', 'reset') }
    )
    foreach ($command in $netshCommands) {
        Invoke-AtlasHiddenProcess `
            -FilePath $netshPath `
            -ArgumentList ([object[]]$command.Arguments) `
            -Wait `
            -AllowedExitCode ([int[]]@(0)) | Out-Null
    }

    $deviceIds = New-Object 'System.Collections.Generic.List[string]'
    $seen = @{}
    foreach ($device in @(Get-AtlasPresentNetworkDevice)) {
        if ($null -eq $device -or
            [string]::IsNullOrWhiteSpace([string]$device.InstanceId)) {
            throw 'An active network device has no instance identifier.'
        }

        $instanceId = [string]$device.InstanceId
        if ($instanceId.Length -gt 200 -or
            $instanceId -notmatch '(?i)^[A-Z0-9_]{1,32}\\[^\x00-\x1F"]{1,199}$') {
            throw "Network device identifier '$instanceId' is not canonical."
        }
        if (-not $seen.ContainsKey($instanceId)) {
            $seen[$instanceId] = $true
            $deviceIds.Add($instanceId)
        }
    }

    foreach ($instanceId in $deviceIds) {
        Invoke-AtlasHiddenProcess `
            -FilePath $pnpUtilPath `
            -ArgumentList ([object[]]@('/remove-device', $instanceId)) `
            -Wait `
            -AllowedExitCode ([int[]]@(0, 3010)) | Out-Null
    }
    Invoke-AtlasHiddenProcess `
        -FilePath $pnpUtilPath `
        -ArgumentList ([object[]]@('/scan-devices')) `
        -Wait `
        -AllowedExitCode ([int[]]@(0, 3010)) | Out-Null

    return [pscustomobject]@{
        NetshCommandCount  = $netshCommands.Count
        RemovedDeviceCount = $deviceIds.Count
        ScanCompleted      = $true
    }
}

function Set-AtlasNetworkDefaults {
    <#
    .SYNOPSIS
        Applies the Atlas adapter defaults (Mode 'Atlas') or resets networking to the
        Windows defaults (Mode 'Windows'). Requires administrator rights and returns
        the per-mode summary object.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Atlas', 'Windows')]
        [string]$Mode
    )

    if (-not (Test-AtlasAdmin)) {
        throw 'Administrator privileges are required to change network defaults.'
    }

    if ($Mode -eq 'Atlas') {
        $result = Invoke-AtlasNetworkAdapterDefault
        Write-AtlasLog -Message (
            "Applied Atlas network defaults to {0} adapter class key(s); {1} registry value(s) changed." -f
            $result.AdapterClassKeyCount, $result.ChangedValueCount
        )
        return $result
    }

    $result = Invoke-AtlasWindowsNetworkDefault
    Write-AtlasLog -Message (
        "Completed {0} network reset command(s), removed {1} network device(s), and rescanned devices." -f
        $result.NetshCommandCount, $result.RemovedDeviceCount
    )
    return $result
}
