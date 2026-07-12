BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:helperPath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-NetworkDefaults.ps1'
    $script:togglePath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Toggles\Troubleshooting\DefaultAtlasNetwork.ps1'

    . $script:helperPath
}

Describe 'Network-default toggle' {
    It 'routes both states to the shared helper with the requested mode' {
        $internal = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'Internal')
        $modeLog = Join-Path $TestDrive 'modes.txt'
        @'
param([string]$Mode)
Add-Content -LiteralPath (Join-Path $PSScriptRoot '..\modes.txt') -Value $Mode
'@ | Set-Content -LiteralPath (Join-Path $internal.FullName 'Set-NetworkDefaults.ps1') `
            -Encoding UTF8

        $definition = & $script:togglePath
        $toggle = [pscustomobject]@{ ScriptsPath = $TestDrive; Silent = $true }
        foreach ($stateName in @('AtlasDefault', 'WindowsDefault')) {
            $action = $definition.States[$stateName].Action
            & $action $toggle
        }

        Get-Content -LiteralPath $modeLog | Should -Be @('Atlas', 'Windows')
    }
}

Describe 'Network-default dispatch' {
    It 'requires administrator privileges before either mode runs' {
        Mock Test-AtlasNetworkAdministrator { $false }
        Mock Invoke-AtlasNetworkAdapterDefault { throw 'must not apply Atlas defaults' }
        Mock Invoke-AtlasWindowsNetworkDefault { throw 'must not reset Windows networking' }

        { Invoke-AtlasNetworkDefault -Mode Atlas } |
            Should -Throw '*Administrator privileges are required*'
        Should -Invoke Invoke-AtlasNetworkAdapterDefault -Times 0
        Should -Invoke Invoke-AtlasWindowsNetworkDefault -Times 0
    }

    It 'dispatches each accepted mode once' {
        Mock Test-AtlasNetworkAdministrator { $true }
        Mock Invoke-AtlasNetworkAdapterDefault {
            [pscustomobject]@{ AdapterClassKeyCount = 1; ChangedValueCount = 2 }
        }
        Mock Invoke-AtlasWindowsNetworkDefault {
            [pscustomobject]@{ NetshCommandCount = 5; RemovedDeviceCount = 1 }
        }

        (Invoke-AtlasNetworkDefault -Mode Atlas).ChangedValueCount | Should -Be 2
        (Invoke-AtlasNetworkDefault -Mode Windows).NetshCommandCount | Should -Be 5
        Should -Invoke Invoke-AtlasNetworkAdapterDefault -Times 1 -Exactly
        Should -Invoke Invoke-AtlasWindowsNetworkDefault -Times 1 -Exactly
    }
}

Describe 'Atlas adapter defaults' {
    BeforeEach {
        $script:classGuid = '{4d36e972-e325-11ce-bfc1-08002be10318}'
    }

    It 'resolves every PCI adapter class key and ignores non-PCI adapters' {
        Mock Get-AtlasNetworkAdapter {
            @(
                [pscustomobject]@{
                    PNPDeviceID = 'PCI\VEN_8086&DEV_1111&SUBSYS_00000001\3&11111111&0&00'
                }
                [pscustomobject]@{ PNPDeviceID = 'USB\VID_1234&PID_5678\ABC' }
                [pscustomobject]@{
                    PNPDeviceID = 'PCI\VEN_10EC&DEV_2222&REV_01\4&22222222&0&01'
                }
            )
        }
        Mock Get-AtlasRegistryString {
            param($KeyPath, $Name)
            $null = $Name
            if ($KeyPath -like '*VEN_8086*') { return "$($script:classGuid)\0001" }
            return "$($script:classGuid)\0007"
        }
        Mock Test-AtlasRegistryKey { $true }

        @(Get-AtlasPciNetworkClassKey) | Should -Be @(
            "SYSTEM\CurrentControlSet\Control\Class\$($script:classGuid)\0001"
            "SYSTEM\CurrentControlSet\Control\Class\$($script:classGuid)\0007"
        )
        Should -Invoke Get-AtlasRegistryString -Times 2 -Exactly
        Should -Invoke Test-AtlasRegistryKey -Times 2 -Exactly
    }

    It 'rejects malformed PCI identifiers and non-network driver keys' {
        $script:adapterCase = 'Malformed'
        Mock Get-AtlasNetworkAdapter {
            if ($script:adapterCase -eq 'Malformed') {
                return [pscustomobject]@{
                    PNPDeviceID = 'PCI\VEN_8086&DEV_1234\..\Injected'
                }
            }
            return [pscustomobject]@{
                PNPDeviceID = 'PCI\VEN_8086&DEV_1234\3&11111111&0&00'
            }
        }
        Mock Get-AtlasRegistryString {
            '{4d36e968-e325-11ce-bfc1-08002be10318}\0001'
        }
        Mock Test-AtlasRegistryKey { $true }

        { Get-AtlasPciNetworkClassKey } | Should -Throw '*not canonical*'
        $script:adapterCase = 'WrongClass'
        { Get-AtlasPciNetworkClassKey } | Should -Throw '*invalid class key*'
    }

    It 'writes every present standard and starred managed setting as zero' {
        $keyOne = "SYSTEM\CurrentControlSet\Control\Class\$($script:classGuid)\0001"
        $keyTwo = "SYSTEM\CurrentControlSet\Control\Class\$($script:classGuid)\0002"
        Mock Get-AtlasPciNetworkClassKey { @($keyOne, $keyTwo) }
        Mock Get-AtlasRegistryValueName {
            param($KeyPath)
            if ($KeyPath -eq $keyOne) {
                return @('AutoDisableGigabit', '*DMACoalescing', 'Unmanaged')
            }
            return @('*SipsEnabled', 'ReduceSpeedOnPowerDown')
        }
        $script:writes = New-Object 'System.Collections.Generic.List[object]'
        Mock Write-AtlasRegistryString {
            param($KeyPath, $Name, $Value)
            $script:writes.Add([pscustomobject]@{
                    KeyPath = $KeyPath
                    Name    = $Name
                    Value   = $Value
                })
        }

        $result = Invoke-AtlasNetworkAdapterDefault

        $result.AdapterClassKeyCount | Should -Be 2
        $result.ChangedValueCount | Should -Be 4
        @($script:writes.Name) | Should -Be @(
            'AutoDisableGigabit'
            '*DMACoalescing'
            '*SipsEnabled'
            'ReduceSpeedOnPowerDown'
        )
        @($script:writes.Value | Select-Object -Unique) | Should -Be @('0')
    }

    It 'propagates a registry write failure immediately' {
        Mock Get-AtlasPciNetworkClassKey { 'SYSTEM\CurrentControlSet\Control\Class\key' }
        Mock Get-AtlasRegistryValueName { @('AutoDisableGigabit', 'SipsEnabled') }
        Mock Write-AtlasRegistryString { throw 'registry write failed' }

        { Invoke-AtlasNetworkAdapterDefault } | Should -Throw '*registry write failed*'
        Should -Invoke Write-AtlasRegistryString -Times 1 -Exactly
    }

    It 'fails when no PCI adapter or no managed setting is present' {
        Mock Get-AtlasNetworkAdapter { @() }
        { Get-AtlasPciNetworkClassKey } |
            Should -Throw '*No applicable PCI network-adapter class keys*'

        Mock Get-AtlasPciNetworkClassKey { 'SYSTEM\CurrentControlSet\Control\Class\key' }
        Mock Get-AtlasRegistryValueName { @('UnmanagedProperty') }
        Mock Write-AtlasRegistryString { throw 'must not write' }
        { Invoke-AtlasNetworkAdapterDefault } |
            Should -Throw '*exposed none of the Atlas-managed advanced properties*'
        Should -Invoke Write-AtlasRegistryString -Times 0
    }
}

Describe 'Windows network defaults' {
    BeforeEach {
        $script:calls = New-Object 'System.Collections.Generic.List[object]'
        Mock Invoke-AtlasNetworkCommand {
            param($FilePath, $ArgumentList, $AllowedExitCode)
            $script:calls.Add([pscustomobject]@{
                    FilePath        = $FilePath
                    Arguments       = @($ArgumentList)
                    AllowedExitCode = @($AllowedExitCode)
                })
        }
    }

    It 'runs the fixed reset sequence, removes each present device once, and scans' {
        Mock Get-AtlasPresentNetworkDevice {
            @(
                [pscustomobject]@{
                    InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00'
                }
                [pscustomobject]@{
                    InstanceId = 'SWD\DAFUPNPPROVIDER\UUID:ABCDEF'
                }
                [pscustomobject]@{
                    InstanceId = 'pci\ven_8086&dev_1111\3&11111111&0&00'
                }
            )
        }

        $result = Invoke-AtlasWindowsNetworkDefault
        $system32 = Join-Path `
            ([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)) `
            'System32'

        $result.NetshCommandCount | Should -Be 5
        $result.RemovedDeviceCount | Should -Be 2
        $result.ScanCompleted | Should -BeTrue
        $script:calls.Count | Should -Be 8
        @($script:calls[0..4].FilePath | Select-Object -Unique) |
            Should -Be @((Join-Path $system32 'netsh.exe'))
        @($script:calls[0].Arguments) | Should -Be @('int', 'ip', 'reset')
        @($script:calls[4].Arguments) | Should -Be @('winsock', 'reset')
        @($script:calls[5].Arguments) | Should -Be @(
            '/remove-device', 'PCI\VEN_8086&DEV_1111\3&11111111&0&00'
        )
        @($script:calls[6].Arguments) | Should -Be @(
            '/remove-device', 'SWD\DAFUPNPPROVIDER\UUID:ABCDEF'
        )
        @($script:calls[7].Arguments) | Should -Be @('/scan-devices')
        @($script:calls[0].AllowedExitCode) | Should -Be @(0)
        @($script:calls[5].AllowedExitCode) | Should -Be @(0, 3010)
        @($script:calls[7].AllowedExitCode) | Should -Be @(0, 3010)
    }

    It 'stops before device enumeration when the first netsh command fails' {
        Mock Invoke-AtlasNetworkCommand {
            $script:calls.Add([pscustomobject]@{ Arguments = @($ArgumentList) })
            throw 'native exit code 5'
        }
        Mock Get-AtlasPresentNetworkDevice { throw 'must not enumerate devices' }

        { Invoke-AtlasWindowsNetworkDefault } | Should -Throw '*native exit code 5*'
        $script:calls.Count | Should -Be 1
        @($script:calls[0].Arguments) | Should -Be @('int', 'ip', 'reset')
        Should -Invoke Get-AtlasPresentNetworkDevice -Times 0
    }

    It 'rejects a malformed device identifier before pnputil receives it' {
        Mock Get-AtlasPresentNetworkDevice {
            [pscustomobject]@{ InstanceId = '/scan-devices' }
        }

        { Invoke-AtlasWindowsNetworkDefault } | Should -Throw '*not canonical*'
        $script:calls.Count | Should -Be 5
    }

    It 'propagates a device-removal failure without scanning' {
        Mock Get-AtlasPresentNetworkDevice {
            [pscustomobject]@{
                InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00'
            }
        }
        Mock Invoke-AtlasNetworkCommand {
            param($FilePath, $ArgumentList, $AllowedExitCode)
            $null = $AllowedExitCode
            $script:calls.Add([pscustomobject]@{
                    FilePath  = $FilePath
                    Arguments = @($ArgumentList)
                })
            if ($ArgumentList[0] -eq '/remove-device') {
                throw 'device removal failed with exit code 31'
            }
        }

        { Invoke-AtlasWindowsNetworkDefault } | Should -Throw '*exit code 31*'
        $script:calls.Count | Should -Be 6
        @($script:calls.Arguments | ForEach-Object { $_ -join '|' }) |
            Should -Not -Contain '/scan-devices'
    }
}
