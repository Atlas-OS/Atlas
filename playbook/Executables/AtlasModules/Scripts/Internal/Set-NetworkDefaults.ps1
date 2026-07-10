param (
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
$script:AtlasNetworkLoaderEnvironmentNames = @(
    'COR_ENABLE_PROFILING'
    'COR_PROFILER'
    'COR_PROFILER_PATH'
    'COR_PROFILER_PATH_32'
    'COR_PROFILER_PATH_64'
    'COR_PROFILER_PATH_ARM32'
    'COR_PROFILER_PATH_ARM64'
    'COR_PROFILER_PATH_X86'
    'COR_PROFILER_PATH_AMD64'
    'CORECLR_ENABLE_PROFILING'
    'CORECLR_PROFILER'
    'CORECLR_PROFILER_PATH'
    'CORECLR_PROFILER_PATH_32'
    'CORECLR_PROFILER_PATH_64'
    'CORECLR_PROFILER_PATH_ARM64'
    'CORECLR_PROFILER_PATH_X86'
    'DOTNET_STARTUP_HOOKS'
    'DOTNET_ADDITIONAL_DEPS'
    'DOTNET_SHARED_STORE'
    'DOTNET_ROOT'
    'DOTNET_ROOT_X86'
    'DOTNET_ROOT_X64'
    'DOTNET_ROOT_ARM64'
    'DOTNET_HOST_PATH'
    'DOTNET_BUNDLE_EXTRACT_BASE_DIR'
    'APPDOMAIN_MANAGER_ASM'
    'APPDOMAIN_MANAGER_TYPE'
    'APPDOMAIN_MANAGER_APP_CONFIG'
    'APPDOMAIN_MANAGER_INITIALIZATION_OPTIONS'
    'COMPLUS_APPDOMAINMANAGERASSEMBLY'
    'COMPLUS_APPDOMAINMANAGERTYPE'
    'COMPLUS_APPLICATIONMIGRATIONRUNTIMEACTIVATIONCONFIGPATH'
    'COMPLUS_INSTALLROOT'
    'COMPLUS_VERSION'
    'COMPLUS_TPALIST'
    'COMPLUS_JITNAME'
    'COMPLUS_JITPATH'
    'COMPLUS_ALTJIT'
    'COMPLUS_ALTJITNAME'
    'COMPLUS_ALTJITPATH'
)

function Get-AtlasNetworkProtectedPathSet {
    [CmdletBinding()]
    param (
        [string]$WindowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows),
        [string]$SystemDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
    )

    if ([string]::IsNullOrWhiteSpace($WindowsRoot) -or [string]::IsNullOrWhiteSpace($SystemDirectory)) {
        throw 'Windows did not return its protected Windows and System directories.'
    }

    $canonicalWindowsRoot = [IO.Path]::GetFullPath($WindowsRoot).TrimEnd('\')
    $canonicalSystemDirectory = [IO.Path]::GetFullPath($SystemDirectory).TrimEnd('\')
    $expectedSystemDirectory = [IO.Path]::GetFullPath((Join-Path $canonicalWindowsRoot 'System32')).TrimEnd('\')
    if (-not [string]::Equals(
            $canonicalSystemDirectory,
            $expectedSystemDirectory,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The current process is not using the protected System32 directory '$expectedSystemDirectory'."
    }

    $moduleRoot = Join-Path $canonicalSystemDirectory 'WindowsPowerShell\v1.0\Modules'
    return [pscustomobject]@{
        WindowsRoot       = $canonicalWindowsRoot
        SystemDirectory   = $canonicalSystemDirectory
        PowerShellPath    = Join-Path $canonicalSystemDirectory 'WindowsPowerShell\v1.0\powershell.exe'
        ModuleRoot        = $moduleRoot
        CimManifestPath   = Join-Path $moduleRoot 'CimCmdlets\CimCmdlets.psd1'
        PnpManifestPath   = Join-Path $moduleRoot 'PnpDevice\PnpDevice.psd1'
        NetshPath         = Join-Path $canonicalSystemDirectory 'netsh.exe'
        PnpUtilPath       = Join-Path $canonicalSystemDirectory 'pnputil.exe'
    }
}

function Get-AtlasNetworkEnvironmentPlan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Paths
    )

    $plan = [ordered]@{
        SystemRoot   = [string]$Paths.WindowsRoot
        windir       = [string]$Paths.WindowsRoot
        ComSpec      = Join-Path ([string]$Paths.SystemDirectory) 'cmd.exe'
        PATHEXT      = '.COM;.EXE;.BAT;.CMD'
        PATH         = @(
            [string]$Paths.SystemDirectory
            [string]$Paths.WindowsRoot
            (Join-Path ([string]$Paths.SystemDirectory) 'Wbem')
            (Join-Path ([string]$Paths.SystemDirectory) 'WindowsPowerShell\v1.0')
        ) -join ';'
        PSModulePath = [string]$Paths.ModuleRoot
    }

    foreach ($name in $script:AtlasNetworkLoaderEnvironmentNames) {
        $plan[$name] = $null
    }

    return $plan
}

function Initialize-AtlasNetworkDefaultsEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Paths,

        [scriptblock]$EnvironmentSetter
    )

    if ($null -eq $EnvironmentSetter) {
        $EnvironmentSetter = {
            param($Name, $Value)
            [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
        }
    }

    $plan = Get-AtlasNetworkEnvironmentPlan -Paths $Paths
    foreach ($entry in $plan.GetEnumerator()) {
        & $EnvironmentSetter ([string]$entry.Key) $entry.Value
    }
}

function Assert-AtlasNetworkProtectedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ProtectedRoot
    )

    $canonicalPath = [IO.Path]::GetFullPath($Path)
    $canonicalRoot = [IO.Path]::GetFullPath($ProtectedRoot).TrimEnd('\') + '\'
    if (-not $canonicalPath.StartsWith($canonicalRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The required file '$canonicalPath' is outside protected root '$canonicalRoot'."
    }

    $item = Get-Item -LiteralPath $canonicalPath -Force -ErrorAction Stop
    if ($item.PSIsContainer -or (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "The required file '$canonicalPath' is not a normal file."
    }
    if (-not [string]::Equals(
            [IO.Path]::GetFullPath($item.FullName),
            $canonicalPath,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The required file '$canonicalPath' did not resolve to its expected path."
    }

    return $canonicalPath
}

function Import-AtlasNetworkInboxCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    $trustedManifest = Assert-AtlasNetworkProtectedFile -Path $ManifestPath -ProtectedRoot $ModuleRoot
    $expectedModuleBase = [IO.Path]::GetDirectoryName($trustedManifest)
    $modules = @(Import-Module -Name $trustedManifest -Force -PassThru -ErrorAction Stop)
    if ($modules.Count -ne 1) {
        throw "Inbox module '$ModuleName' did not import as one exact module."
    }

    $module = $modules[0]
    if (-not [string]::Equals([string]$module.Name, $ModuleName, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals(
            [IO.Path]::GetFullPath([string]$module.ModuleBase),
            [IO.Path]::GetFullPath($expectedModuleBase),
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Inbox module '$ModuleName' resolved outside its protected module directory."
    }

    $command = Get-Command -Name ("{0}\{1}" -f $ModuleName, $CommandName) -ErrorAction Stop
    if (-not [string]::Equals([string]$command.ModuleName, $ModuleName, [StringComparison]::OrdinalIgnoreCase) -or
        $null -eq $command.Module -or
        -not [string]::Equals(
            [IO.Path]::GetFullPath([string]$command.Module.ModuleBase),
            [IO.Path]::GetFullPath($expectedModuleBase),
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Command '$CommandName' did not resolve from the protected '$ModuleName' module."
    }
}

function Test-AtlasNetworkAdministrator {
    [CmdletBinding()]
    param ()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    finally {
        $identity.Dispose()
    }
}

function Get-AtlasLocalMachineRegistryValue {
    [CmdletBinding()]
    param (
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
        $matchedName = @($key.GetValueNames() | Where-Object {
                [string]::Equals($_, $Name, [StringComparison]::OrdinalIgnoreCase)
            })
        if ($matchedName.Count -ne 1) {
            throw "Registry value 'HKEY_LOCAL_MACHINE\$KeyPath\$Name' was not found exactly once."
        }

        return [pscustomobject]@{
            Value = $key.GetValue(
                $matchedName[0],
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
            Kind  = [string]$key.GetValueKind($matchedName[0])
        }
    }
    finally {
        $key.Dispose()
    }
}

function Get-AtlasLocalMachineRegistryValueName {
    [CmdletBinding()]
    param (
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

function Test-AtlasLocalMachineRegistryKey {
    [CmdletBinding()]
    param (
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

function Write-AtlasLocalMachineRegistryString {
    [CmdletBinding()]
    param (
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

function Get-AtlasStrictScalar {
    [CmdletBinding()]
    param (
        $Value,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    $items = @($Value)
    if ($items.Count -ne 1 -or $null -eq $items[0]) {
        throw "$Operation did not return one exact result."
    }

    return $items[0]
}

function Assert-AtlasRegistryValueRecord {
    [CmdletBinding()]
    param (
        $Record,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    $scalar = Get-AtlasStrictScalar -Value $Record -Operation $Operation
    if ($null -eq $scalar.PSObject.Properties['Value'] -or
        $null -eq $scalar.PSObject.Properties['Kind']) {
        throw "$Operation returned an invalid registry value record."
    }

    return $scalar
}

function Get-AtlasPciNetworkClassKey {
    [CmdletBinding()]
    param (
        [scriptblock]$AdapterProvider,
        [scriptblock]$RegistryValueReader,
        [scriptblock]$RegistryKeyTester
    )

    if ($null -eq $AdapterProvider) {
        $AdapterProvider = {
            CimCmdlets\Get-CimInstance -ClassName Win32_NetworkAdapter -ErrorAction Stop
        }
    }
    if ($null -eq $RegistryValueReader) {
        $RegistryValueReader = {
            param($KeyPath, $Name)
            Get-AtlasLocalMachineRegistryValue -KeyPath $KeyPath -Name $Name
        }
    }
    if ($null -eq $RegistryKeyTester) {
        $RegistryKeyTester = {
            param($KeyPath)
            Test-AtlasLocalMachineRegistryKey -KeyPath $KeyPath
        }
    }

    $classKeys = New-Object 'System.Collections.Generic.List[string]'
    $seenClassKeys = @{}
    foreach ($adapter in @(& $AdapterProvider)) {
        if ($null -eq $adapter) {
            throw 'The network adapter provider returned a null adapter record.'
        }

        $pnpProperty = $adapter.PSObject.Properties['PNPDeviceID']
        if ($null -eq $pnpProperty -or [string]::IsNullOrWhiteSpace([string]$pnpProperty.Value)) {
            continue
        }

        $pnpDeviceId = [string]$pnpProperty.Value
        if ($pnpDeviceId -notmatch '(?i)^PCI\\VEN_') {
            continue
        }
        if ($pnpDeviceId -notmatch '(?i)^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&[A-Z0-9_]+)*\\[A-Z0-9&_.{}-]+$') {
            throw "PCI network adapter identifier '$pnpDeviceId' is not canonical."
        }

        # This value is deliberately reset for every adapter. A failed lookup can
        # never inherit a class key discovered for an earlier adapter.
        $driver = $null
        $enumKey = "SYSTEM\CurrentControlSet\Enum\$pnpDeviceId"
        $driverRecord = Assert-AtlasRegistryValueRecord `
            -Record (& $RegistryValueReader $enumKey 'Driver') `
            -Operation "Reading the Driver value for '$pnpDeviceId'"
        if (-not [string]::Equals([string]$driverRecord.Kind, 'String', [StringComparison]::Ordinal)) {
            throw "The Driver value for '$pnpDeviceId' is not REG_SZ."
        }
        $driver = [string]$driverRecord.Value
        if ($driver -notmatch ('(?i)^' + [regex]::Escape($script:AtlasNetworkClassGuid) + '\\[0-9]{4}$')) {
            throw "Network adapter '$pnpDeviceId' resolved to invalid class key '$driver'."
        }

        $classKey = "SYSTEM\CurrentControlSet\Control\Class\$driver"
        $keyTest = Get-AtlasStrictScalar `
            -Value (& $RegistryKeyTester $classKey) `
            -Operation "Validating class key '$classKey'"
        if ($keyTest -isnot [bool] -or -not $keyTest) {
            throw "Network adapter class key 'HKEY_LOCAL_MACHINE\$classKey' does not exist."
        }

        $dedupeKey = $classKey.ToUpperInvariant()
        if (-not $seenClassKeys.ContainsKey($dedupeKey)) {
            $seenClassKeys[$dedupeKey] = $true
            $classKeys.Add($classKey)
        }
    }

    return $classKeys.ToArray()
}

function Invoke-AtlasNetworkAdapterDefault {
    [CmdletBinding()]
    param (
        [scriptblock]$AdapterProvider,
        [scriptblock]$RegistryValueReader,
        [scriptblock]$RegistryKeyTester,
        [scriptblock]$RegistryValueNameReader,
        [scriptblock]$RegistryValueWriter
    )

    if ($null -eq $RegistryValueReader) {
        $RegistryValueReader = {
            param($KeyPath, $Name)
            Get-AtlasLocalMachineRegistryValue -KeyPath $KeyPath -Name $Name
        }
    }
    if ($null -eq $RegistryValueNameReader) {
        $RegistryValueNameReader = {
            param($KeyPath)
            Get-AtlasLocalMachineRegistryValueName -KeyPath $KeyPath
        }
    }
    if ($null -eq $RegistryValueWriter) {
        $RegistryValueWriter = {
            param($KeyPath, $Name, $Value)
            Write-AtlasLocalMachineRegistryString -KeyPath $KeyPath -Name $Name -Value $Value
        }
    }

    $classKeys = @(Get-AtlasPciNetworkClassKey `
            -AdapterProvider $AdapterProvider `
            -RegistryValueReader $RegistryValueReader `
            -RegistryKeyTester $RegistryKeyTester)
    $changedValues = 0

    foreach ($classKey in $classKeys) {
        $existingNames = @(& $RegistryValueNameReader $classKey)
        $nameIndex = @{}
        foreach ($existingName in $existingNames) {
            if ($null -eq $existingName -or [string]::IsNullOrWhiteSpace([string]$existingName)) {
                throw "Class key 'HKEY_LOCAL_MACHINE\$classKey' returned an invalid value name."
            }
            $nameIndex[[string]$existingName] = [string]$existingName
        }

        foreach ($setting in $script:AtlasNetworkSettingNames) {
            foreach ($candidateName in @($setting, "*$setting")) {
                if (-not $nameIndex.ContainsKey($candidateName)) {
                    continue
                }

                $actualName = [string]$nameIndex[$candidateName]
                & $RegistryValueWriter $classKey $actualName '0'
                $postcondition = Assert-AtlasRegistryValueRecord `
                    -Record (& $RegistryValueReader $classKey $actualName) `
                    -Operation "Reading back 'HKEY_LOCAL_MACHINE\$classKey\$actualName'"
                if (-not [string]::Equals([string]$postcondition.Kind, 'String', [StringComparison]::Ordinal) -or
                    -not [string]::Equals([string]$postcondition.Value, '0', [StringComparison]::Ordinal)) {
                    throw "Registry postcondition failed for 'HKEY_LOCAL_MACHINE\$classKey\$actualName'."
                }
                $changedValues++
            }
        }
    }

    return [pscustomobject]@{
        AdapterClassKeyCount = $classKeys.Count
        ChangedValueCount    = $changedValues
    }
}

function Invoke-AtlasNetworkNativeProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& $FilePath @ArgumentList 2>&1)
    $exitCode = [int]$LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Invoke-AtlasCheckedNetworkCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ProcessInvoker
    )

    $result = Get-AtlasStrictScalar `
        -Value (& $ProcessInvoker $FilePath $ArgumentList) `
        -Operation $Operation
    $exitCodeProperty = $result.PSObject.Properties['ExitCode']
    if ($null -eq $exitCodeProperty) {
        throw "$Operation returned no exit code."
    }

    try {
        $exitCode = [Convert]::ToInt32($exitCodeProperty.Value, [Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        throw "$Operation returned an invalid exit code."
    }

    if ($exitCode -ne 0) {
        throw "$Operation failed with exit code $exitCode."
    }
}

function Invoke-AtlasWindowsNetworkDefault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NetshPath,

        [Parameter(Mandatory = $true)]
        [string]$PnpUtilPath,

        [scriptblock]$DeviceProvider,
        [scriptblock]$ProcessInvoker
    )

    if ($null -eq $DeviceProvider) {
        $DeviceProvider = {
            PnpDevice\Get-PnpDevice -Class Net -Status OK -ErrorAction Stop
        }
    }
    if ($null -eq $ProcessInvoker) {
        $ProcessInvoker = {
            param($FilePath, $ArgumentList)
            Invoke-AtlasNetworkNativeProcess -FilePath $FilePath -ArgumentList $ArgumentList
        }
    }

    $netshCommands = @(
        [pscustomobject]@{ Name = 'IPv4 and IPv6 IP stack reset'; Arguments = @('int', 'ip', 'reset') }
        [pscustomobject]@{ Name = 'IPv4 interface reset'; Arguments = @('interface', 'ipv4', 'reset') }
        [pscustomobject]@{ Name = 'IPv6 interface reset'; Arguments = @('interface', 'ipv6', 'reset') }
        [pscustomobject]@{ Name = 'TCP interface reset'; Arguments = @('interface', 'tcp', 'reset') }
        [pscustomobject]@{ Name = 'Winsock reset'; Arguments = @('winsock', 'reset') }
    )
    foreach ($command in $netshCommands) {
        Invoke-AtlasCheckedNetworkCommand `
            -FilePath $NetshPath `
            -ArgumentList $command.Arguments `
            -Operation ([string]$command.Name) `
            -ProcessInvoker $ProcessInvoker
    }

    $deviceIds = New-Object 'System.Collections.Generic.List[string]'
    $seenDeviceIds = @{}
    foreach ($device in @(& $DeviceProvider)) {
        if ($null -eq $device) {
            throw 'The network device provider returned a null device record.'
        }

        $instanceProperty = $device.PSObject.Properties['InstanceId']
        if ($null -eq $instanceProperty -or [string]::IsNullOrWhiteSpace([string]$instanceProperty.Value)) {
            throw 'An active network device has no instance identifier.'
        }

        $instanceId = [string]$instanceProperty.Value
        if ($instanceId.Length -gt 200 -or
            $instanceId -notmatch '(?i)^[A-Z0-9_]{1,32}\\[^\x00-\x1F"]{1,199}$' -or
            $instanceId.IndexOfAny([char[]]@("`r", "`n", [char]0)) -ge 0) {
            throw "Network device identifier '$instanceId' is not canonical."
        }

        $dedupeKey = $instanceId.ToUpperInvariant()
        if (-not $seenDeviceIds.ContainsKey($dedupeKey)) {
            $seenDeviceIds[$dedupeKey] = $true
            $deviceIds.Add($instanceId)
        }
    }

    foreach ($instanceId in $deviceIds) {
        Invoke-AtlasCheckedNetworkCommand `
            -FilePath $PnpUtilPath `
            -ArgumentList @('/remove-device', $instanceId) `
            -Operation "Removing network device '$instanceId'" `
            -ProcessInvoker $ProcessInvoker
    }
    Invoke-AtlasCheckedNetworkCommand `
        -FilePath $PnpUtilPath `
        -ArgumentList @('/scan-devices') `
        -Operation 'Scanning for network devices' `
        -ProcessInvoker $ProcessInvoker

    return [pscustomobject]@{
        NetshCommandCount = $netshCommands.Count
        RemovedDeviceCount = $deviceIds.Count
        ScanCompleted = $true
    }
}

function Invoke-AtlasNetworkDefault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Atlas', 'Windows')]
        [string]$Mode,

        $Paths,
        [scriptblock]$AdapterProvider,
        [scriptblock]$RegistryValueReader,
        [scriptblock]$RegistryKeyTester,
        [scriptblock]$RegistryValueNameReader,
        [scriptblock]$RegistryValueWriter,
        [scriptblock]$DeviceProvider,
        [scriptblock]$ProcessInvoker
    )

    if ($Mode -eq 'Atlas') {
        return Invoke-AtlasNetworkAdapterDefault `
            -AdapterProvider $AdapterProvider `
            -RegistryValueReader $RegistryValueReader `
            -RegistryKeyTester $RegistryKeyTester `
            -RegistryValueNameReader $RegistryValueNameReader `
            -RegistryValueWriter $RegistryValueWriter
    }

    if ($null -eq $Paths) {
        throw 'Protected system paths are required for Windows network defaults.'
    }
    return Invoke-AtlasWindowsNetworkDefault `
        -NetshPath ([string]$Paths.NetshPath) `
        -PnpUtilPath ([string]$Paths.PnpUtilPath) `
        -DeviceProvider $DeviceProvider `
        -ProcessInvoker $ProcessInvoker
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        if (-not $PSBoundParameters.ContainsKey('Mode')) {
            throw 'A network-default mode is required.'
        }

        $protectedPaths = Get-AtlasNetworkProtectedPathSet
        Initialize-AtlasNetworkDefaultsEnvironment -Paths $protectedPaths
        if (-not (Test-AtlasNetworkAdministrator)) {
            throw 'Administrator privileges are required to change network defaults.'
        }

        if ($Mode -eq 'Atlas') {
            Import-AtlasNetworkInboxCommand `
                -ManifestPath $protectedPaths.CimManifestPath `
                -ModuleRoot $protectedPaths.ModuleRoot `
                -ModuleName 'CimCmdlets' `
                -CommandName 'Get-CimInstance'
        }
        else {
            [void](Assert-AtlasNetworkProtectedFile `
                    -Path $protectedPaths.NetshPath `
                    -ProtectedRoot $protectedPaths.SystemDirectory)
            [void](Assert-AtlasNetworkProtectedFile `
                    -Path $protectedPaths.PnpUtilPath `
                    -ProtectedRoot $protectedPaths.SystemDirectory)
            Import-AtlasNetworkInboxCommand `
                -ManifestPath $protectedPaths.PnpManifestPath `
                -ModuleRoot $protectedPaths.ModuleRoot `
                -ModuleName 'PnpDevice' `
                -CommandName 'Get-PnpDevice'
        }

        $result = Invoke-AtlasNetworkDefault -Mode $Mode -Paths $protectedPaths
        if ($Mode -eq 'Atlas') {
            Write-Output ("Applied Atlas network defaults to {0} adapter class key(s); {1} registry value(s) changed." -f `
                    $result.AdapterClassKeyCount, $result.ChangedValueCount)
        }
        else {
            Write-Output ("Completed {0} network reset command(s), removed {1} network device(s), and rescanned devices." -f `
                    $result.NetshCommandCount, $result.RemovedDeviceCount)
        }
        exit 0
    }
    catch {
        Write-Error ("Network defaults operation failed: {0}" -f $_.Exception.Message)
        exit 1
    }
}
