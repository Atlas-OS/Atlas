[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Module-scoped mock bodies cannot see test-file variables, so shared fixture state is staged as global variables.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Network\Atlas.Network.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:classGuid = '{4d36e972-e325-11ce-bfc1-08002be10318}'
    $script:classRoot = 'SYSTEM\CurrentControlSet\Control\Class'
}

AfterAll {
    Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name AtlasNetworkTestCalls, AtlasNetworkTestState -Scope Global -ErrorAction SilentlyContinue
}

Describe 'Network-default toggle' {
    BeforeAll {
        Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:networkDefinition = Get-AtlasToggleDefinition -Name DefaultAtlasNetwork `
            -TogglesRoot (Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles')
    }

    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
    }

    It 'runs both states as machine work, never in the user context' {
        # Definition validation allows a UserAction under Admin elevation, but the reset
        # needs the elevated machine context.
        foreach ($state in @($script:networkDefinition.States['Enable'], $script:networkDefinition.States['Disable'])) {
            $work = Get-AtlasToggleStateWork -Definition $script:networkDefinition -StateEntry $state
            $work.Machine | Should -BeTrue
            $work.User | Should -BeFalse
            $work.Local | Should -BeFalse
        }
    }

    It 'routes both states to Set-AtlasNetworkDefaults with the requested mode' {
        $global:AtlasNetworkTestCalls = New-Object 'System.Collections.Generic.List[string]'
        Mock Set-AtlasNetworkDefaults -ModuleName Atlas.Toggles {
            $global:AtlasNetworkTestCalls.Add($Mode)
            [pscustomobject]@{ AdapterClassKeyCount = 0; ChangedValueCount = 0 }
        }

        foreach ($stateName in @('Enable', 'Disable')) {
            $toggle = [pscustomobject]@{
                Name       = 'DefaultAtlasNetwork'
                State      = $stateName
                StateValue = $script:networkDefinition.States[$stateName]['StateValue']
                Silent     = $true
            }
            InModuleScope Atlas.Toggles {
                Invoke-AtlasToggleFunction -Definition $d -FunctionName 'Set-AtlasNetworkDefaultState' -Toggle $t -Label 'test'
            } -Parameters @{ d = $script:networkDefinition; t = $toggle }
        }

        @($global:AtlasNetworkTestCalls) | Should -Be @('Atlas', 'Windows')
    }
}

Describe 'Set-AtlasNetworkDefaults' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Network
    }

    It 'requires administrator privileges before either mode runs' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Network { $false }
        Mock Invoke-AtlasNetworkAdapterDefault -ModuleName Atlas.Network { throw 'must not apply Atlas defaults' }
        Mock Invoke-AtlasWindowsNetworkDefault -ModuleName Atlas.Network { throw 'must not reset Windows networking' }

        { Set-AtlasNetworkDefaults -Mode Atlas } |
            Should -Throw '*Administrator privileges are required*'
        { Set-AtlasNetworkDefaults -Mode Windows } |
            Should -Throw '*Administrator privileges are required*'
        Should -Invoke Invoke-AtlasNetworkAdapterDefault -ModuleName Atlas.Network -Times 0
        Should -Invoke Invoke-AtlasWindowsNetworkDefault -ModuleName Atlas.Network -Times 0
    }

    It 'runs only the <Mode> implementation and returns its summary' -TestCases @(
        @{ Mode = 'Atlas'; Runs = 'Invoke-AtlasNetworkAdapterDefault'; Skips = 'Invoke-AtlasWindowsNetworkDefault' }
        @{ Mode = 'Windows'; Runs = 'Invoke-AtlasWindowsNetworkDefault'; Skips = 'Invoke-AtlasNetworkAdapterDefault' }
    ) {
        # The other mode would reset real networking or rewrite real adapter settings.
        Mock Test-AtlasAdmin -ModuleName Atlas.Network { $true }
        Mock -CommandName $Runs -ModuleName Atlas.Network {
            [pscustomobject]@{ AdapterClassKeyCount = 1; ChangedValueCount = 2; NetshCommandCount = 5; RemovedDeviceCount = 1 }
        }
        Mock -CommandName $Skips -ModuleName Atlas.Network { throw 'must not run' }

        (Set-AtlasNetworkDefaults -Mode $Mode).ChangedValueCount | Should -Be 2
        Should -Invoke -CommandName $Runs -ModuleName Atlas.Network -Times 1 -Exactly
    }
}

Describe 'Atlas adapter defaults' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Network
        Mock Test-AtlasAdmin -ModuleName Atlas.Network { $true }
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Network { throw 'must not reset Windows networking' }
    }

    It 'resolves every PCI adapter class key and ignores non-PCI adapters' {
        Mock Get-AtlasNetworkAdapter -ModuleName Atlas.Network {
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
        Mock Get-AtlasNetworkRegistryString -ModuleName Atlas.Network {
            if ($KeyPath -like '*VEN_8086*') {
                return '{4d36e972-e325-11ce-bfc1-08002be10318}\0001'
            }
            return '{4d36e972-e325-11ce-bfc1-08002be10318}\0007'
        }
        Mock Test-AtlasNetworkRegistryKey -ModuleName Atlas.Network { $true }

        $classKeys = InModuleScope Atlas.Network { @(Get-AtlasPciNetworkClassKey) }

        @($classKeys) | Should -Be @(
            "$($script:classRoot)\$($script:classGuid)\0001"
            "$($script:classRoot)\$($script:classGuid)\0007"
        )
        Should -Invoke Get-AtlasNetworkRegistryString -ModuleName Atlas.Network -Times 2 -Exactly `
            -ParameterFilter { $KeyPath -like 'SYSTEM\CurrentControlSet\Enum\PCI\VEN_*' -and $Name -eq 'Driver' }
        Should -Invoke Test-AtlasNetworkRegistryKey -ModuleName Atlas.Network -Times 2 -Exactly
    }

    It 'rejects malformed PCI identifiers and non-network driver keys' {
        $global:AtlasNetworkTestState = 'Malformed'
        Mock Get-AtlasNetworkAdapter -ModuleName Atlas.Network {
            if ($global:AtlasNetworkTestState -eq 'Malformed') {
                return [pscustomobject]@{
                    PNPDeviceID = 'PCI\VEN_8086&DEV_1234\..\Injected'
                }
            }
            return [pscustomobject]@{
                PNPDeviceID = 'PCI\VEN_8086&DEV_1234\3&11111111&0&00'
            }
        }
        Mock Get-AtlasNetworkRegistryString -ModuleName Atlas.Network {
            '{4d36e968-e325-11ce-bfc1-08002be10318}\0001'
        }
        Mock Test-AtlasNetworkRegistryKey -ModuleName Atlas.Network { $true }

        { InModuleScope Atlas.Network { Get-AtlasPciNetworkClassKey } } | Should -Throw '*not canonical*'
        $global:AtlasNetworkTestState = 'WrongClass'
        { InModuleScope Atlas.Network { Get-AtlasPciNetworkClassKey } } | Should -Throw '*invalid class key*'
    }

    It 'writes every present standard and starred managed setting as zero' {
        Mock Get-AtlasPciNetworkClassKey -ModuleName Atlas.Network {
            @(
                'SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001'
                'SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002'
            )
        }
        Mock Get-AtlasNetworkRegistryValueName -ModuleName Atlas.Network {
            if ($KeyPath -like '*\0001') {
                return @('AutoDisableGigabit', '*DMACoalescing', 'Unmanaged')
            }
            return @('*SipsEnabled', 'ReduceSpeedOnPowerDown')
        }
        Mock Write-AtlasNetworkRegistryString -ModuleName Atlas.Network {}

        $result = Set-AtlasNetworkDefaults -Mode Atlas

        $result.AdapterClassKeyCount | Should -Be 2
        $result.ChangedValueCount | Should -Be 4
        Should -Invoke Write-AtlasNetworkRegistryString -ModuleName Atlas.Network -Times 4 -Exactly `
            -ParameterFilter { $Value -eq '0' }
        foreach ($expectedName in @('AutoDisableGigabit', '*DMACoalescing', '*SipsEnabled', 'ReduceSpeedOnPowerDown')) {
            Should -Invoke Write-AtlasNetworkRegistryString -ModuleName Atlas.Network -Times 1 -Exactly `
                -ParameterFilter { $Name -ceq $expectedName }
        }
        Should -Invoke Write-AtlasNetworkRegistryString -ModuleName Atlas.Network -Times 0 `
            -ParameterFilter { $Name -eq 'Unmanaged' }
    }

    It 'propagates a registry write failure immediately' {
        Mock Get-AtlasPciNetworkClassKey -ModuleName Atlas.Network { 'SYSTEM\CurrentControlSet\Control\Class\key' }
        Mock Get-AtlasNetworkRegistryValueName -ModuleName Atlas.Network { @('AutoDisableGigabit', 'SipsEnabled') }
        Mock Write-AtlasNetworkRegistryString -ModuleName Atlas.Network { throw 'registry write failed' }

        { Set-AtlasNetworkDefaults -Mode Atlas } | Should -Throw '*registry write failed*'
        Should -Invoke Write-AtlasNetworkRegistryString -ModuleName Atlas.Network -Times 1 -Exactly
    }

    It 'skips adapters that expose no applicable Atlas settings' {
        Mock Get-AtlasNetworkAdapter -ModuleName Atlas.Network { @() }
        @(InModuleScope Atlas.Network { Get-AtlasPciNetworkClassKey }) | Should -BeNullOrEmpty

        Mock Get-AtlasPciNetworkClassKey -ModuleName Atlas.Network { 'SYSTEM\CurrentControlSet\Control\Class\key' }
        Mock Get-AtlasNetworkRegistryValueName -ModuleName Atlas.Network { @('UnmanagedProperty') }
        Mock Write-AtlasNetworkRegistryString -ModuleName Atlas.Network { throw 'must not write' }
        $result = Set-AtlasNetworkDefaults -Mode Atlas

        $result.AdapterClassKeyCount | Should -Be 1
        $result.ChangedValueCount | Should -Be 0
        Should -Invoke Write-AtlasNetworkRegistryString -ModuleName Atlas.Network -Times 0
    }
}

Describe 'Windows network defaults' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Network
        Mock Test-AtlasAdmin -ModuleName Atlas.Network { $true }
        $global:AtlasNetworkTestCalls = New-Object 'System.Collections.Generic.List[object]'
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Network {
            $global:AtlasNetworkTestCalls.Add([pscustomobject]@{
                    FilePath        = $FilePath
                    Arguments       = @($ArgumentList)
                    AllowedExitCode = @($AllowedExitCode)
                    Wait            = [bool]$Wait
                    CaptureOutput   = [bool]$CaptureOutput
                })
            [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' }
        }
    }

    It 'runs the fixed reset sequence, removes each present device once, and scans' {
        Mock Get-AtlasPresentNetworkDevice -ModuleName Atlas.Network {
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
                # The Wi-Fi Direct virtual adapter's enumerator is a braced GUID.
                [pscustomobject]@{
                    InstanceId = '{5D624F94-8850-40C3-A3FA-A4FD2080BAF3}\VWIFIMP_WFD\5&1A2B3C4D&0&11'
                }
            )
        }

        $result = Set-AtlasNetworkDefaults -Mode Windows
        $system32 = Join-Path `
            ([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)) `
            'System32'
        $calls = $global:AtlasNetworkTestCalls.ToArray()

        $result.NetshCommandCount | Should -Be 5
        $result.RemovedDeviceCount | Should -Be 3
        $result.ScanCompleted | Should -BeTrue
        $calls.Count | Should -Be 9
        @($calls[0..4].FilePath | Select-Object -Unique) |
            Should -Be @((Join-Path $system32 'netsh.exe'))
        @($calls[5..8].FilePath | Select-Object -Unique) |
            Should -Be @((Join-Path $system32 'pnputil.exe'))
        @($calls.Wait | Select-Object -Unique) | Should -Be @($true)
        @($calls[0..4].CaptureOutput | Select-Object -Unique) | Should -Be @($true)
        @($calls[0].Arguments) | Should -Be @('int', 'ip', 'reset')
        @($calls[4].Arguments) | Should -Be @('winsock', 'reset')
        @($calls[5].Arguments) | Should -Be @(
            '/remove-device', 'PCI\VEN_8086&DEV_1111\3&11111111&0&00'
        )
        @($calls[6].Arguments) | Should -Be @(
            '/remove-device', 'SWD\DAFUPNPPROVIDER\UUID:ABCDEF'
        )
        @($calls[7].Arguments) | Should -Be @(
            '/remove-device', '{5D624F94-8850-40C3-A3FA-A4FD2080BAF3}\VWIFIMP_WFD\5&1A2B3C4D&0&11'
        )
        @($calls[8].Arguments) | Should -Be @('/scan-devices')
        foreach ($ipReset in $calls[0..2]) {
            @($ipReset.AllowedExitCode) | Should -Be @(0, 1)
        }
        @($calls[3].AllowedExitCode) | Should -Be @(0)
        @($calls[4].AllowedExitCode) | Should -Be @(0)
        @($calls[5].AllowedExitCode) | Should -Be @(0, 3010)
        @($calls[8].AllowedExitCode) | Should -Be @(0, 3010)
    }

    It 'continues past the exit code 1 every ip reset reports and logs each reset''s output' {
        Mock Get-AtlasPresentNetworkDevice -ModuleName Atlas.Network {
            [pscustomobject]@{ InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' }
        }
        # Mirrors netsh: the shared ipv4/ipv6 reset handler exits 1 even when it succeeds.
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Network {
            $global:AtlasNetworkTestCalls.Add([pscustomobject]@{ Arguments = @($ArgumentList) })
            $command = $ArgumentList -join ' '
            $exitCode = if ($command -in @('int ip reset', 'interface ipv4 reset', 'interface ipv6 reset')) { 1 } else { 0 }
            if ($AllowedExitCode -notcontains $exitCode) {
                throw "exited with disallowed code $exitCode"
            }
            [pscustomobject]@{
                ExitCode       = $exitCode
                StandardOutput = "Resetting Interface, OK!`r`nResetting , failed.`r`nAccess is denied.`r`n`r`n"
                StandardError  = ''
            }
        }

        $result = Set-AtlasNetworkDefaults -Mode Windows

        $result.RemovedDeviceCount | Should -Be 1
        $global:AtlasNetworkTestCalls.Count | Should -Be 7
        @($global:AtlasNetworkTestCalls[6].Arguments) | Should -Be @('/scan-devices')
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Network -Times 1 -Exactly -ParameterFilter {
            $Message -ceq 'netsh int ip reset exited with code 1. Resetting Interface, OK! | Resetting , failed. | Access is denied.'
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Network -Times 5 -Exactly -ParameterFilter {
            $Message -clike 'netsh * exited with code *'
        }
    }

    It 'stops at the first failing netsh command before removing any device' {
        Mock Get-AtlasPresentNetworkDevice -ModuleName Atlas.Network {
            [pscustomobject]@{ InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00' }
        }
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Network {
            $global:AtlasNetworkTestCalls.Add([pscustomobject]@{ Arguments = @($ArgumentList) })
            throw 'native exit code 5'
        }

        { Set-AtlasNetworkDefaults -Mode Windows } | Should -Throw '*native exit code 5*'
        $global:AtlasNetworkTestCalls.Count | Should -Be 1
        @($global:AtlasNetworkTestCalls[0].Arguments) | Should -Be @('int', 'ip', 'reset')
    }

    It 'rejects a malformed device identifier before the network stack is reset' {
        Mock Get-AtlasPresentNetworkDevice -ModuleName Atlas.Network {
            [pscustomobject]@{ InstanceId = '/scan-devices' }
        }

        { Set-AtlasNetworkDefaults -Mode Windows } | Should -Throw '*not canonical*'
        $global:AtlasNetworkTestCalls.Count | Should -Be 0
    }

    It 'propagates a device-removal failure without scanning' {
        Mock Get-AtlasPresentNetworkDevice -ModuleName Atlas.Network {
            [pscustomobject]@{
                InstanceId = 'PCI\VEN_8086&DEV_1111\3&11111111&0&00'
            }
        }
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Network {
            $global:AtlasNetworkTestCalls.Add([pscustomobject]@{
                    FilePath  = $FilePath
                    Arguments = @($ArgumentList)
                })
            if ($ArgumentList[0] -eq '/remove-device') {
                throw 'device removal failed with exit code 31'
            }
            [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' }
        }

        { Set-AtlasNetworkDefaults -Mode Windows } | Should -Throw '*exit code 31*'
        $global:AtlasNetworkTestCalls.Count | Should -Be 6
        @($global:AtlasNetworkTestCalls | ForEach-Object { @($_.Arguments) -join '|' }) |
            Should -Not -Contain '/scan-devices'
    }
}

Describe 'File Sharing machine state' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Network
        Mock Write-AtlasLog -ModuleName Atlas.Services
        Mock Write-AtlasStep -ModuleName Atlas.Network
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { throw 'must not prompt in silent mode' }

        $script:interfacesRoot = "$script:testRoot\NetBT\Interfaces"
        $script:servicesRoot = "$script:testRoot\Services"
        New-Item -Path "$script:interfacesRoot\Tcpip_{A}" -Force | Out-Null
        Set-ItemProperty -Path "$script:interfacesRoot\Tcpip_{A}" -Name NetbiosOptions -Value 0 -Type DWord
        New-Item -Path "$script:interfacesRoot\Tcpip_{B}" -Force | Out-Null
        New-Item -Path "$script:servicesRoot\NetBT" -Force | Out-Null

        # Adapter bindings, connection profiles and firewall rules are modelled as
        # shared state that the mocked Net* cmdlets read and change.
        $global:AtlasNetworkTestState = @{
            BindingsEnabled = $true
            ProfileCategory = 'Private'
            RuleEnabled     = 1
            RuleProfiles    = 2
            Copies          = @{}
        }
        Mock Get-NetAdapterBinding -ModuleName Atlas.Network {
            @(
                [pscustomobject]@{ Name = 'Ethernet'; ComponentID = 'ms_server'; Enabled = $global:AtlasNetworkTestState.BindingsEnabled }
                [pscustomobject]@{ Name = 'Ethernet'; ComponentID = 'ms_msclient'; Enabled = $global:AtlasNetworkTestState.BindingsEnabled }
            )
        }
        Mock Enable-NetAdapterBinding -ModuleName Atlas.Network { $global:AtlasNetworkTestState.BindingsEnabled = $true }
        Mock Disable-NetAdapterBinding -ModuleName Atlas.Network { $global:AtlasNetworkTestState.BindingsEnabled = $false }
        # The Net* cmdlets bind their InputObject parameters by CIM class type name, so
        # the fakes are client-only instances of the real classes rather than plain objects.
        Mock Get-NetConnectionProfile -ModuleName Atlas.Network {
            New-CimInstance -ClassName MSFT_NetConnectionProfile -ClientOnly -Property @{
                Name            = 'Home'
                InterfaceIndex  = 7
                NetworkCategory = $global:AtlasNetworkTestState.ProfileCategory
            }
        }
        Mock Set-NetConnectionProfile -ModuleName Atlas.Network {
            $global:AtlasNetworkTestState.ProfileCategory = [string]$NetworkCategory
        }
        # Firewall rule fakes carry the raw MSFT_NetFirewallRule fields (InstanceID,
        # RuleGroup, Profiles flags, Enabled 1 = True / 2 = False) that the inbox type
        # extensions project as Name, Group, Profile and Enabled.
        Mock Get-NetFirewallRule -ModuleName Atlas.Network {
            param($Name)
            $rules = @(
                New-CimInstance -ClassName MSFT_NetFirewallRule -ClientOnly -Property @{
                    InstanceID   = 'FPS-SMB-In-TCP'
                    RuleGroup    = '@FirewallAPI.dll,-28502'
                    DisplayGroup = 'File and Printer Sharing'
                    Profiles     = [uint16]$global:AtlasNetworkTestState.RuleProfiles
                    Enabled      = [uint16]$global:AtlasNetworkTestState.RuleEnabled
                }
                New-CimInstance -ClassName MSFT_NetFirewallRule -ClientOnly -Property @{
                    InstanceID   = 'Unrelated-Public'
                    RuleGroup    = '@FirewallAPI.dll,-1'
                    DisplayGroup = 'Other'
                    Profiles     = [uint16]4
                    Enabled      = [uint16]1
                }
            )
            $rules += @($global:AtlasNetworkTestState.Copies.Values)
            if ($Name) {
                return @($rules | Where-Object { $_.InstanceID -in @($Name) })
            }
            return $rules
        }
        Mock Disable-NetFirewallRule -ModuleName Atlas.Network {
            foreach ($rule in $InputObject) {
                if ($global:AtlasNetworkTestState.Copies.ContainsKey([string]$rule.InstanceID)) {
                    $global:AtlasNetworkTestState.Copies[[string]$rule.InstanceID].Enabled = [uint16]2
                }
                else { $global:AtlasNetworkTestState.RuleEnabled = 2 }
            }
        }
        Mock Enable-NetFirewallRule -ModuleName Atlas.Network {
            foreach ($rule in $InputObject) {
                if ($global:AtlasNetworkTestState.Copies.ContainsKey([string]$rule.InstanceID)) {
                    $global:AtlasNetworkTestState.Copies[[string]$rule.InstanceID].Enabled = [uint16]1
                }
                else { $global:AtlasNetworkTestState.RuleEnabled = 1 }
            }
        }
        Mock Copy-NetFirewallRule -ModuleName Atlas.Network {
            param($InputObject, $NewName, [switch]$PassThru)
            if ($global:AtlasNetworkTestState.Copies.ContainsKey($NewName)) { throw 'duplicate rule' }
            $copy = New-CimInstance -ClassName MSFT_NetFirewallRule -ClientOnly -Property @{
                InstanceID = $NewName
                RuleGroup = $InputObject[0].RuleGroup
                DisplayGroup = $InputObject[0].DisplayGroup
                Profiles = [uint16]$InputObject[0].Profiles
                Enabled = [uint16]$InputObject[0].Enabled
            }
            $global:AtlasNetworkTestState.Copies[$NewName] = $copy
            # Windows 11's PassThru result can identify the source, not the copy.
            if ($PassThru) { $InputObject[0] }
        }
        Mock Set-NetFirewallRule -ModuleName Atlas.Network {
            foreach ($rule in $InputObject) {
                $global:AtlasNetworkTestState.Copies[[string]$rule.InstanceID].Profiles = [uint16]2
                $global:AtlasNetworkTestState.Copies[[string]$rule.InstanceID].Enabled = [uint16]2
            }
        }
        Mock Remove-AtlasRegistryKey -ModuleName Atlas.Network {}
        Mock Test-Path -ModuleName Atlas.Network { $false } -ParameterFilter {
            $LiteralPath -like 'HKLM:\SOFTWARE\Classes\*ContextMenuHandlers\Sharing'
        }
        Mock Invoke-AtlasToggleMachineState -ModuleName Atlas.Network {}
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Network {}
    }

    AfterEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'disables bindings, NetBIOS, NetBT, forces Public profiles, disables sharing rules and removes the context menu' {
        Disable-AtlasFileSharing -Silent -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot

        $global:AtlasNetworkTestState.BindingsEnabled | Should -BeFalse
        Should -Invoke Disable-NetAdapterBinding -ModuleName Atlas.Network -Times 2 -Exactly
        (Get-ItemProperty -Path "$script:interfacesRoot\Tcpip_{A}" -Name NetbiosOptions).NetbiosOptions | Should -Be 2
        (Get-Item -Path "$script:interfacesRoot\Tcpip_{B}").GetValueNames() | Should -Not -Contain 'NetbiosOptions'
        (Get-ItemProperty -Path "$script:servicesRoot\NetBT" -Name Start).Start | Should -Be 4
        $global:AtlasNetworkTestState.ProfileCategory | Should -BeExactly 'Public'
        Should -Invoke Set-NetConnectionProfile -ModuleName Atlas.Network -Times 1 -Exactly
        $global:AtlasNetworkTestState.RuleEnabled | Should -Be 2
        Should -Invoke Remove-AtlasRegistryKey -ModuleName Atlas.Network -Times 6 -Exactly -ParameterFilter {
            $Path -like 'HKLM:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\Sharing'
        }
        Should -Invoke Write-AtlasStep -ModuleName Atlas.Network -Times 0
    }

    It 'disables interactively with only the step line, leaving the closing line to the toggle engine' {
        { Disable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot } |
            Should -Not -Throw

        $global:AtlasNetworkTestState.BindingsEnabled | Should -BeFalse
        Should -Invoke Write-AtlasStep -ModuleName Atlas.Network -Times 1 -Exactly
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Network -Times 0
    }

    It 'fails when a managed binding stays enabled after the disable' {
        Mock Disable-NetAdapterBinding -ModuleName Atlas.Network {}

        { Disable-AtlasFileSharing -Silent -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot } |
            Should -Throw '*left a managed adapter binding enabled*'
        (Get-Item -Path "$script:servicesRoot\NetBT").GetValueNames() | Should -Not -Contain 'Start'
    }

    It 'fails when a context-menu key survives removal' {
        Mock Test-Path -ModuleName Atlas.Network { $true } -ParameterFilter {
            $LiteralPath -like 'HKLM:\SOFTWARE\Classes\Drive\*Sharing'
        }

        { Disable-AtlasFileSharing -Silent -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot } |
            Should -Throw '*left the context-menu key*Drive*'
    }

    It 'enables bindings, NetBIOS, NetBT and the Network Discovery machine state silently' {
        $global:AtlasNetworkTestState.BindingsEnabled = $false
        $stateRoot = "$script:testRoot\ToggleState"

        Enable-AtlasFileSharing -Silent -StateRoot $stateRoot `
            -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot

        $global:AtlasNetworkTestState.BindingsEnabled | Should -BeTrue
        Should -Invoke Enable-NetAdapterBinding -ModuleName Atlas.Network -Times 2 -Exactly
        (Get-ItemProperty -Path "$script:interfacesRoot\Tcpip_{A}" -Name NetbiosOptions).NetbiosOptions | Should -Be 1
        (Get-ItemProperty -Path "$script:servicesRoot\NetBT" -Name Start).Start | Should -Be 1
        Should -Invoke Invoke-AtlasToggleMachineState -ModuleName Atlas.Network -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'NetworkDiscovery' -and $State -ceq 'Enable' -and $StateRoot -eq "HKCU:\Software\AtlasRewriteTest\ToggleState"
        }
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Network -Times 0
        Should -Invoke Set-NetConnectionProfile -ModuleName Atlas.Network -Times 0
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Network -Times 0
    }

    It 'uses the toggle engine default state store when none is given' {
        $global:AtlasNetworkTestState.BindingsEnabled = $false

        Enable-AtlasFileSharing -Silent -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot

        Should -Invoke Invoke-AtlasToggleMachineState -ModuleName Atlas.Network -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'NetworkDiscovery' -and -not $PesterBoundParameters.ContainsKey('StateRoot')
        }
    }

    It 'interactively switches profiles to Private, enables sharing rules and restores the context menu on consent' {
        $global:AtlasNetworkTestState.BindingsEnabled = $false
        $global:AtlasNetworkTestState.ProfileCategory = 'Public'
        $global:AtlasNetworkTestState.RuleEnabled = 2
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { $true }

        Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot

        $global:AtlasNetworkTestState.ProfileCategory | Should -BeExactly 'Private'
        $global:AtlasNetworkTestState.RuleEnabled | Should -Be 1
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Network -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' -and $Name -eq 'AutoSetup' -and $Data -eq 1
        }
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Network -Times 6 -Exactly -ParameterFilter {
            $Path -like 'Registry::HKEY_CLASSES_ROOT\*ContextMenuHandlers\Sharing' -and $Data -eq '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
        }
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Network -Times 2 -Exactly
    }

    It 'leaves profiles, rules and the context menu untouched when consent is refused' {
        $global:AtlasNetworkTestState.BindingsEnabled = $false
        $global:AtlasNetworkTestState.ProfileCategory = 'Public'
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { $false }

        Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot

        $global:AtlasNetworkTestState.ProfileCategory | Should -BeExactly 'Public'
        Should -Invoke Enable-NetFirewallRule -ModuleName Atlas.Network -Times 0
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Network -Times 0
    }

    It 'enables only a Private copy of disabled combined-profile sharing rules and reuses it' -TestCases @(
        @{ Profiles = 6 } # Private + Public, observed on Windows 11 25H2.
        @{ Profiles = 0 } # Any.
        @{ Profiles = 3 } # Domain + Private.
    ) {
        param($Profiles)
        $global:AtlasNetworkTestState.RuleProfiles = $Profiles
        $global:AtlasNetworkTestState.RuleEnabled = 2
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { $true }

        Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot
        Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot

        $global:AtlasNetworkTestState.RuleEnabled | Should -Be 2
        $global:AtlasNetworkTestState.RuleProfiles | Should -Be $Profiles
        $copy = $global:AtlasNetworkTestState.Copies['Atlas-Private-FPS-SMB-In-TCP']
        $copy.Profiles | Should -Be 2
        $copy.Enabled | Should -Be 1
        Should -Invoke Copy-NetFirewallRule -ModuleName Atlas.Network -Times 1 -Exactly
        Should -Invoke Enable-NetFirewallRule -ModuleName Atlas.Network -Times 0 -ParameterFilter {
            @($InputObject | Where-Object { $_.InstanceID -eq 'FPS-SMB-In-TCP' }).Count -gt 0
        }

        Disable-AtlasFileSharing -Silent -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot
        $copy.Enabled | Should -Be 2
    }

    It 'does not alter already enabled combined-profile coverage' {
        $global:AtlasNetworkTestState.RuleProfiles = 6
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { $true }
        Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot
        $global:AtlasNetworkTestState.RuleEnabled | Should -Be 1
        $global:AtlasNetworkTestState.RuleProfiles | Should -Be 6
        Should -Invoke Copy-NetFirewallRule -ModuleName Atlas.Network -Times 0
        Should -Invoke Enable-NetFirewallRule -ModuleName Atlas.Network -Times 0
    }

    It 'finishes a disabled combined-profile copy left by an interrupted run without copying it again' {
        $global:AtlasNetworkTestState.RuleProfiles = 6
        $global:AtlasNetworkTestState.RuleEnabled = 2
        $global:AtlasNetworkTestState.Copies['Atlas-Private-FPS-SMB-In-TCP'] =
            New-CimInstance -ClassName MSFT_NetFirewallRule -ClientOnly -Property @{
                InstanceID = 'Atlas-Private-FPS-SMB-In-TCP'
                RuleGroup = '@FirewallAPI.dll,-28502'
                DisplayGroup = 'File and Printer Sharing'
                Profiles = [uint16]6
                Enabled = [uint16]2
            }
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { $true }
        Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot
        $global:AtlasNetworkTestState.RuleProfiles | Should -Be 6
        $global:AtlasNetworkTestState.RuleEnabled | Should -Be 2
        $global:AtlasNetworkTestState.Copies.Count | Should -Be 1
        $global:AtlasNetworkTestState.Copies['Atlas-Private-FPS-SMB-In-TCP'].Profiles | Should -Be 2
        $global:AtlasNetworkTestState.Copies['Atlas-Private-FPS-SMB-In-TCP'].Enabled | Should -Be 1
        Should -Invoke Copy-NetFirewallRule -ModuleName Atlas.Network -Times 0
    }

    It 'does not enable a combined-profile copy if narrowing its scope failed' {
        $global:AtlasNetworkTestState.RuleProfiles = 6
        $global:AtlasNetworkTestState.RuleEnabled = 2
        Mock Read-AtlasYesNo -ModuleName Atlas.Network { $true }
        Mock Set-NetFirewallRule -ModuleName Atlas.Network {}
        { Enable-AtlasFileSharing -NetBtInterfacesRoot $script:interfacesRoot -ServicesRoot $script:servicesRoot } |
            Should -Throw '*disabled Private scope*'
        $global:AtlasNetworkTestState.RuleEnabled | Should -Be 2
        $global:AtlasNetworkTestState.Copies['Atlas-Private-FPS-SMB-In-TCP'].Enabled | Should -Be 2
        Should -Invoke Enable-NetFirewallRule -ModuleName Atlas.Network -Times 0
    }
}
