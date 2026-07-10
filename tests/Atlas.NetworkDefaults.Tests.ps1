BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:helperPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\Set-NetworkDefaults.ps1'
    $script:atlasLauncherPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Toolbox\Scripts\Troubleshooting\TroubleshootingNetwork\AtlasDefaults.cmd'
    $script:windowsLauncherPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Toolbox\Scripts\Troubleshooting\TroubleshootingNetwork\WindowsDefaults.cmd'

    . $script:helperPath

}

Describe 'Network defaults launcher boundary' {
    It 'keeps both launchers as thin fixed-path typed wrappers' {
        $atlas = Get-Content -LiteralPath $script:atlasLauncherPath -Raw
        $windows = Get-Content -LiteralPath $script:windowsLauncherPath -Raw

        foreach ($content in @($atlas, $windows)) {
            $content | Should -Match '(?m)^verify other 2>nul\r?$'
            $content | Should -Match '(?m)^setlocal EnableExtensions DisableDelayedExpansion\r?$'
            $content | Should -Match 'Initialize-PowerShellLauncherEnvironment\.cmd'
            $content | Should -Match 'AtlasModules\\Scripts\\Internal\\Set-NetworkDefaults\.ps1'
            $content | Should -Match '"%AtlasNativeFltmc%"'
            $content | Should -Match '"%AtlasNativePowerShell%"'
            $content | Should -Match '\$cmd=\$env:AtlasNativeCommandHost'
            $content | Should -Match '-WorkingDirectory \$env:AtlasNativeSystemDirectory'
            $content | Should -Match 'Start-Process .+ -Verb RunAs .+ -Wait -PassThru'
            $content | Should -Match 'exit \$p\.ExitCode'
            $content | Should -Match '(?m)^\s*if errorlevel 1 exit /b\r?$'
            ([regex]::Matches(
                    $content,
                    '(?ms)^\s*if errorlevel 0 \(\r?\n\s+if errorlevel 1 exit /b\r?\n\s*\) else \(\r?\n\s+exit /b 1\r?\n\s*\)\r?$'
                )).Count | Should -Be 2
            $content | Should -Not -Match '(?i)WaitForExit'
            $content | Should -Not -Match '(?i)%(?:windir|systemroot)%'
            $content | Should -Not -Match '%__APPDIR__%WindowsPowerShell|%__APPDIR__%fltmc'
            $content | Should -Not -Match '(?i)%ERRORLEVEL%|%\*|___args'
            $content | Should -Not -Match '(?im)^\s*(?:reg|netsh|pnputil)(?:\.exe)?\b'
            $content | Should -Not -Match '(?i)Get-(?:CimInstance|PnpDevice)'
        }

        $atlas | Should -Match '-File "%networkScript%" -Mode Atlas'
        $atlas | Should -Match 'if /i not "%~1"=="/silent" goto unsupportedArguments'
        $atlas | Should -Match 'if not "%~2"=="" goto unsupportedArguments'
        $atlas | Should -Not -Match '(?i)-Mode Windows'

        $windows | Should -Match '-File "%networkScript%" -Mode Windows'
        $windows | Should -Match 'if not "%~1"=="" goto unsupportedArguments'
        $windows | Should -Not -Match '(?i)-Mode Atlas'
    }

    It 'stores each CMD launcher with CRLF only' {
        foreach ($path in @($script:atlasLauncherPath, $script:windowsLauncherPath)) {
            $bytes = [IO.File]::ReadAllBytes($path)
            $bytes.Count | Should -BeGreaterThan 2
            for ($index = 0; $index -lt $bytes.Count; $index++) {
                if ($bytes[$index] -eq 10) {
                    $index | Should -BeGreaterThan 0
                    $bytes[$index - 1] | Should -Be 13
                }
            }
            $bytes[$bytes.Count - 2] | Should -Be 13
            $bytes[$bytes.Count - 1] | Should -Be 10
        }
    }

    It 'uses a typed helper contract and executes nothing when dot-sourced' {
        $content = Get-Content -LiteralPath $script:helperPath -Raw
        $content | Should -Match "\[ValidateSet\('Atlas', 'Windows'\)\]"
        $content | Should -Match 'if \(\$MyInvocation\.InvocationName -ne ''\.''\)'
        $content | Should -Match 'Test-AtlasNetworkAdministrator'
        $content | Should -Match 'CimCmdlets\\Get-CimInstance'
        $content | Should -Match 'PnpDevice\\Get-PnpDevice'
        $content | Should -Match 'Assert-AtlasNetworkProtectedFile'
        $content | Should -Not -Match '(?im)^\s*(?:netsh|pnputil)(?:\.exe)?\s'

        { Invoke-AtlasNetworkDefault -Mode Unsupported } | Should -Throw
    }
}

Describe 'Atlas adapter defaults' {
    BeforeEach {
        $script:networkClassGuid = '{4d36e972-e325-11ce-bfc1-08002be10318}'
    }

    It 'resolves every validated PCI adapter independently and ignores non-PCI adapters' {
        $adapters = @(
            [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_8086&DEV_1111&SUBSYS_00000001\3&11111111&0&00' }
            [pscustomobject]@{ PNPDeviceID = 'USB\VID_1234&PID_5678\ABC' }
            [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_10EC&DEV_2222&REV_01\4&22222222&0&01' }
        )
        $driverByEnumKey = @{
            'SYSTEM\CurrentControlSet\Enum\PCI\VEN_8086&DEV_1111&SUBSYS_00000001\3&11111111&0&00' = "$($script:networkClassGuid)\0001"
            'SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_2222&REV_01\4&22222222&0&01' = "$($script:networkClassGuid)\0007"
        }
        $queries = New-Object 'System.Collections.Generic.List[string]'
        $adapterProvider = { $adapters }.GetNewClosure()
        $valueReader = {
            param($KeyPath, $Name)
            $queries.Add("$KeyPath|$Name")
            [pscustomobject]@{ Value = $driverByEnumKey[$KeyPath]; Kind = 'String' }
        }.GetNewClosure()
        $keyTester = { param($KeyPath) $KeyPath -like '*\0001' -or $KeyPath -like '*\0007' }

        $keys = @(Get-AtlasPciNetworkClassKey `
                -AdapterProvider $adapterProvider `
                -RegistryValueReader $valueReader `
                -RegistryKeyTester $keyTester)

        $keys | Should -Be @(
            "SYSTEM\CurrentControlSet\Control\Class\$($script:networkClassGuid)\0001"
            "SYSTEM\CurrentControlSet\Control\Class\$($script:networkClassGuid)\0007"
        )
        $queries.Count | Should -Be 2
        $queries[0] | Should -Be 'SYSTEM\CurrentControlSet\Enum\PCI\VEN_8086&DEV_1111&SUBSYS_00000001\3&11111111&0&00|Driver'
        $queries[1] | Should -Be 'SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_2222&REV_01\4&22222222&0&01|Driver'
    }

    It 'fails closed instead of carrying a prior class key across a failed adapter lookup' {
        $adapters = @(
            [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' }
            [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_10EC&DEV_2222\4&22222222&0&01' }
        )
        $readCount = [pscustomobject]@{ Value = 0 }
        $networkClassGuid = $script:networkClassGuid
        $adapterProvider = { $adapters }.GetNewClosure()
        $valueReader = {
            param($KeyPath, $Name)
            $null = $Name
            $readCount.Value++
            if ($readCount.Value -eq 1) {
                return [pscustomobject]@{ Value = "$networkClassGuid\0001"; Kind = 'String' }
            }
            throw "Missing Driver for $KeyPath"
        }.GetNewClosure()

        {
            Get-AtlasPciNetworkClassKey `
                -AdapterProvider $adapterProvider `
                -RegistryValueReader $valueReader `
                -RegistryKeyTester { $true }
        } | Should -Throw '*Missing Driver*'
        $readCount.Value | Should -Be 2
    }

    It 'rejects malformed PCI identifiers and non-network class keys' {
        {
            Get-AtlasPciNetworkClassKey `
                -AdapterProvider { [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_8086&DEV_1234\..\Injected' } } `
                -RegistryValueReader { throw 'must not read the registry' } `
                -RegistryKeyTester { $true }
        } | Should -Throw '*not canonical*'

        {
            Get-AtlasPciNetworkClassKey `
                -AdapterProvider { [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_8086&DEV_1234\3&11111111&0&00' } } `
                -RegistryValueReader { [pscustomobject]@{ Value = '{4d36e968-e325-11ce-bfc1-08002be10318}\0001'; Kind = 'String' } } `
                -RegistryKeyTester { $true }
        } | Should -Throw '*invalid class key*'
    }

    It 'writes every present setting on every class key and verifies exact REG_SZ postconditions' {
        $classKeys = @(
            "SYSTEM\CurrentControlSet\Control\Class\$($script:networkClassGuid)\0001"
            "SYSTEM\CurrentControlSet\Control\Class\$($script:networkClassGuid)\0002"
        )
        $adapters = @(
            [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' }
            [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_10EC&DEV_2222\4&22222222&0&01' }
        )
        $driverByEnumKey = @{
            'SYSTEM\CurrentControlSet\Enum\PCI\VEN_8086&DEV_1111\3&11111111&0&00' = "$($script:networkClassGuid)\0001"
            'SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_2222\4&22222222&0&01' = "$($script:networkClassGuid)\0002"
        }
        $values = @{}
        foreach ($classKey in $classKeys) {
            $values["$classKey|AutoDisableGigabit"] = [pscustomobject]@{ Value = '1'; Kind = 'String' }
            $values["$classKey|*DMACoalescing"] = [pscustomobject]@{ Value = '1'; Kind = 'String' }
        }
        $adapterProvider = { $adapters }.GetNewClosure()
        $reader = {
            param($KeyPath, $Name)
            if ($Name -eq 'Driver') {
                return [pscustomobject]@{ Value = $driverByEnumKey[$KeyPath]; Kind = 'String' }
            }
            return $values["$KeyPath|$Name"]
        }.GetNewClosure()
        $nameReader = {
            param($KeyPath)
            $null = $KeyPath
            @('AutoDisableGigabit', '*DMACoalescing')
        }
        $writer = {
            param($KeyPath, $Name, $Value)
            $values["$KeyPath|$Name"] = [pscustomobject]@{ Value = $Value; Kind = 'String' }
        }.GetNewClosure()

        $result = Invoke-AtlasNetworkAdapterDefault `
            -AdapterProvider $adapterProvider `
            -RegistryValueReader $reader `
            -RegistryKeyTester { $true } `
            -RegistryValueNameReader $nameReader `
            -RegistryValueWriter $writer

        $result.AdapterClassKeyCount | Should -Be 2
        $result.ChangedValueCount | Should -Be 4
        foreach ($classKey in $classKeys) {
            $values["$classKey|AutoDisableGigabit"].Value | Should -Be '0'
            $values["$classKey|AutoDisableGigabit"].Kind | Should -Be 'String'
            $values["$classKey|*DMACoalescing"].Value | Should -Be '0'
            $values["$classKey|*DMACoalescing"].Kind | Should -Be 'String'
        }
    }

    It 'fails when a registry write does not satisfy its readback postcondition' {
        $adapter = [pscustomobject]@{ PNPDeviceID = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' }
        $driver = "$($script:networkClassGuid)\0001"
        $reader = {
            param($KeyPath, $Name)
            $null = $KeyPath
            if ($Name -eq 'Driver') {
                return [pscustomobject]@{ Value = $driver; Kind = 'String' }
            }
            return [pscustomobject]@{ Value = '1'; Kind = 'String' }
        }.GetNewClosure()
        $adapterProvider = { $adapter }.GetNewClosure()

        {
            Invoke-AtlasNetworkAdapterDefault `
                -AdapterProvider $adapterProvider `
                -RegistryValueReader $reader `
                -RegistryKeyTester { $true } `
                -RegistryValueNameReader { @('AutoDisableGigabit') } `
                -RegistryValueWriter {
                    param($KeyPath, $Name, $Value)
                    $null = $KeyPath, $Name, $Value
                }
        } | Should -Throw '*Registry postcondition failed*'
    }
}

Describe 'Windows network defaults' {
    It 'checks all five netsh operations, every device removal, and the final scan' {
        $calls = New-Object 'System.Collections.Generic.List[object]'
        $invoker = {
            param($FilePath, $ArgumentList)
            $calls.Add([pscustomobject]@{
                    FilePath = $FilePath
                    Arguments = @($ArgumentList)
                })
            [pscustomobject]@{ ExitCode = 0 }
        }.GetNewClosure()
        $devices = {
            @(
                [pscustomobject]@{ InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' }
                [pscustomobject]@{ InstanceId = 'SWD\DAFUPNPPROVIDER\UUID:ABCDEF' }
            )
        }

        $result = Invoke-AtlasWindowsNetworkDefault `
            -NetshPath 'C:\Windows\System32\netsh.exe' `
            -PnpUtilPath 'C:\Windows\System32\pnputil.exe' `
            -DeviceProvider $devices `
            -ProcessInvoker $invoker

        $result.NetshCommandCount | Should -Be 5
        $result.RemovedDeviceCount | Should -Be 2
        $result.ScanCompleted | Should -BeTrue
        $calls.Count | Should -Be 8
        @($calls | Select-Object -First 5 -ExpandProperty FilePath | Select-Object -Unique) | Should -Be @('C:\Windows\System32\netsh.exe')
        ($calls[0].Arguments -join '|') | Should -Be 'int|ip|reset'
        ($calls[4].Arguments -join '|') | Should -Be 'winsock|reset'
        ($calls[5].Arguments -join '|') | Should -Be '/remove-device|PCI\VEN_8086&DEV_1111\3&11111111&0&00'
        ($calls[6].Arguments -join '|') | Should -Be '/remove-device|SWD\DAFUPNPPROVIDER\UUID:ABCDEF'
        ($calls[7].Arguments -join '|') | Should -Be '/scan-devices'
    }

    It 'stops on the first failed netsh command' {
        $calls = New-Object 'System.Collections.Generic.List[string]'
        $invoker = {
            param($FilePath, $ArgumentList)
            $null = $FilePath
            $calls.Add(($ArgumentList -join '|'))
            [pscustomobject]@{ ExitCode = 5 }
        }.GetNewClosure()

        {
            Invoke-AtlasWindowsNetworkDefault `
                -NetshPath 'C:\Windows\System32\netsh.exe' `
                -PnpUtilPath 'C:\Windows\System32\pnputil.exe' `
                -DeviceProvider { throw 'device enumeration must not run' } `
                -ProcessInvoker $invoker
        } | Should -Throw '*exit code 5*'
        $calls | Should -Be @('int|ip|reset')
    }

    It 'stops on a failed device removal and does not report a completed scan' {
        $calls = New-Object 'System.Collections.Generic.List[string]'
        $invoker = {
            param($FilePath, $ArgumentList)
            $null = $FilePath
            $signature = $ArgumentList -join '|'
            $calls.Add($signature)
            if ($signature -like '/remove-device|*') {
                return [pscustomobject]@{ ExitCode = 31 }
            }
            return [pscustomobject]@{ ExitCode = 0 }
        }.GetNewClosure()

        {
            Invoke-AtlasWindowsNetworkDefault `
                -NetshPath 'C:\Windows\System32\netsh.exe' `
                -PnpUtilPath 'C:\Windows\System32\pnputil.exe' `
                -DeviceProvider { [pscustomobject]@{ InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' } } `
                -ProcessInvoker $invoker
        } | Should -Throw '*exit code 31*'
        $calls.Count | Should -Be 6
        $calls | Should -Not -Contain '/scan-devices'
    }

    It 'rejects non-canonical device identifiers before pnputil receives them' {
        $calls = New-Object 'System.Collections.Generic.List[string]'
        $invoker = {
            param($FilePath, $ArgumentList)
            $null = $FilePath
            $calls.Add(($ArgumentList -join '|'))
            [pscustomobject]@{ ExitCode = 0 }
        }.GetNewClosure()

        {
            Invoke-AtlasWindowsNetworkDefault `
                -NetshPath 'C:\Windows\System32\netsh.exe' `
                -PnpUtilPath 'C:\Windows\System32\pnputil.exe' `
                -DeviceProvider { [pscustomobject]@{ InstanceId = '/enum-devices' } } `
                -ProcessInvoker $invoker
        } | Should -Throw '*not canonical*'
        $calls.Count | Should -Be 5
    }
}

Describe 'Network defaults ambient environment' {
    It 'pins protected paths and clears managed loader hooks through an inert setter seam' {
        $paths = [pscustomobject]@{
            WindowsRoot     = 'C:\Windows'
            SystemDirectory = 'C:\Windows\System32'
            ModuleRoot      = 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules'
        }
        $captured = @{}
        $setter = {
            param($Name, $Value)
            $captured[$Name] = $Value
        }.GetNewClosure()

        Initialize-AtlasNetworkDefaultsEnvironment -Paths $paths -EnvironmentSetter $setter

        $captured.SystemRoot | Should -Be 'C:\Windows'
        $captured.ComSpec | Should -Be 'C:\Windows\System32\cmd.exe'
        $captured.PSModulePath | Should -Be 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules'
        $captured.PATH | Should -Be 'C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0'
        $captured.ContainsKey('COR_ENABLE_PROFILING') | Should -BeTrue
        $captured.COR_ENABLE_PROFILING | Should -BeNullOrEmpty
        $captured.ContainsKey('DOTNET_STARTUP_HOOKS') | Should -BeTrue
        $captured.DOTNET_STARTUP_HOOKS | Should -BeNullOrEmpty
        $captured.ContainsKey('COMPLUS_JITPATH') | Should -BeTrue
        $captured.COMPLUS_JITPATH | Should -BeNullOrEmpty
    }
}
