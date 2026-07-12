param(
    [ValidateSet('Atlas', 'Windows')]
    [string]$Mode
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:AtlasNetworkClassGuid = '{4d36e972-e325-11ce-bfc1-08002be10318}'
$script:AtlasNetworkSettingNames = @(
    'AutoDisableGigabit'
    'ApCompatMode'
    'SipsEnabled'
    'ReduceSpeedOnPowerDown'
    'DMACoalescing'
)

function Test-AtlasNetworkAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    finally {
        $identity.Dispose()
    }
}

function Get-AtlasNetworkAdapter {
    CimCmdlets\Get-CimInstance -ClassName Win32_NetworkAdapter -ErrorAction Stop
}

function Get-AtlasPresentNetworkDevice {
    PnpDevice\Get-PnpDevice -Class Net -PresentOnly -ErrorAction Stop
}

function Get-AtlasRegistryString {
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

function Test-AtlasRegistryKey {
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

function Get-AtlasRegistryValueName {
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

function Write-AtlasRegistryString {
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
        $driver = Get-AtlasRegistryString -KeyPath $enumKey -Name 'Driver'
        if ($driver -notmatch
            ('(?i)^' + [regex]::Escape($script:AtlasNetworkClassGuid) + '\\[0-9]{4}$')) {
            throw "Network adapter '$pnpDeviceId' resolved to invalid class key '$driver'."
        }

        $classKey = "SYSTEM\CurrentControlSet\Control\Class\$driver"
        if (-not (Test-AtlasRegistryKey -KeyPath $classKey)) {
            throw "Network adapter class key 'HKEY_LOCAL_MACHINE\$classKey' does not exist."
        }

        if (-not $seen.ContainsKey($classKey)) {
            $seen[$classKey] = $true
            $classKeys.Add($classKey)
        }
    }

    if ($classKeys.Count -eq 0) {
        throw 'No applicable PCI network-adapter class keys were found.'
    }
    return $classKeys.ToArray()
}

function Invoke-AtlasNetworkAdapterDefault {
    $classKeys = @(Get-AtlasPciNetworkClassKey)
    $managedNames = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($setting in $script:AtlasNetworkSettingNames) {
        [void]$managedNames.Add($setting)
        [void]$managedNames.Add("*$setting")
    }

    $changedValues = 0
    foreach ($classKey in $classKeys) {
        foreach ($valueName in @(Get-AtlasRegistryValueName -KeyPath $classKey)) {
            if ($managedNames.Contains([string]$valueName)) {
                Write-AtlasRegistryString `
                    -KeyPath $classKey `
                    -Name ([string]$valueName) `
                    -Value '0'
                $changedValues++
            }
        }
    }

    if ($changedValues -eq 0) {
        throw 'Applicable PCI network adapters exposed none of the Atlas-managed advanced properties.'
    }
    return [pscustomobject]@{
        AdapterClassKeyCount = $classKeys.Count
        ChangedValueCount    = $changedValues
    }
}

function Invoke-AtlasNetworkCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [int[]]$AllowedExitCode
    )

    $coreManifest = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot `
                -ChildPath '..\Modules\Atlas.Core\Atlas.Core.psd1'))
    if (-not [IO.File]::Exists($coreManifest)) {
        throw "Atlas.Core is missing at '$coreManifest'."
    }
    $coreRoot = [IO.Path]::GetDirectoryName($coreManifest)
    if (-not @(Get-Module -Name Atlas.Core | Where-Object {
                [string]::Equals(
                    $_.ModuleBase,
                    $coreRoot,
                    [StringComparison]::OrdinalIgnoreCase
                )
            })) {
        Import-Module -Name $coreManifest -ErrorAction Stop
    }

    Atlas.Core\Invoke-AtlasHiddenProcess `
        -FilePath $FilePath `
        -ArgumentList ([object[]]$ArgumentList) `
        -Wait `
        -AllowedExitCode $AllowedExitCode | Out-Null
}

function Invoke-AtlasWindowsNetworkDefault {
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
        Invoke-AtlasNetworkCommand `
            -FilePath $netshPath `
            -ArgumentList $command.Arguments `
            -AllowedExitCode ([int[]]@(0))
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
        Invoke-AtlasNetworkCommand `
            -FilePath $pnpUtilPath `
            -ArgumentList ([string[]]@('/remove-device', $instanceId)) `
            -AllowedExitCode ([int[]]@(0, 3010))
    }
    Invoke-AtlasNetworkCommand `
        -FilePath $pnpUtilPath `
        -ArgumentList ([string[]]@('/scan-devices')) `
        -AllowedExitCode ([int[]]@(0, 3010))

    return [pscustomobject]@{
        NetshCommandCount  = $netshCommands.Count
        RemovedDeviceCount = $deviceIds.Count
        ScanCompleted      = $true
    }
}

function Invoke-AtlasNetworkDefault {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Atlas', 'Windows')]
        [string]$Mode
    )

    if (-not (Test-AtlasNetworkAdministrator)) {
        throw 'Administrator privileges are required to change network defaults.'
    }
    if ($Mode -eq 'Atlas') {
        return Invoke-AtlasNetworkAdapterDefault
    }
    return Invoke-AtlasWindowsNetworkDefault
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        if (-not $PSBoundParameters.ContainsKey('Mode')) {
            throw 'A network-default mode is required.'
        }
        $result = Invoke-AtlasNetworkDefault -Mode $Mode
        if ($Mode -eq 'Atlas') {
            Write-Output ("Applied Atlas network defaults to {0} adapter class key(s); {1} registry value(s) changed." -f `
                    $result.AdapterClassKeyCount, $result.ChangedValueCount)
        }
        else {
            Write-Output ("Completed {0} network reset command(s), removed {1} network device(s), and rescanned devices." -f `
                    $result.NetshCommandCount, $result.RemovedDeviceCount)
        }
    }
    catch {
        throw (New-Object InvalidOperationException(
                ("Network defaults operation failed: {0}" -f $_.Exception.Message),
                $_.Exception
            ))
    }
}
