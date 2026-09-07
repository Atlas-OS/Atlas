BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Hardware\Atlas.Hardware.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $script:atlas = '11111111-1111-1111-1111-111111111111'
    $script:custom = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
    $script:powerCfg = 'C:\Windows\System32\powercfg.exe'

    $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    $script:PowerSaving = Get-AtlasToggleDefinition -Name PowerSaving -TogglesRoot $togglesRoot
    $script:Bluetooth = Get-AtlasToggleDefinition -Name Bluetooth -TogglesRoot $togglesRoot
    $script:PowerTweakScript = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\scripts\set-power-settings.ps1'

    function New-ToggleContext {
        param(
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $true)][string]$State,
            [bool]$Silent = $true
        )

        return [pscustomobject]@{
            Name           = $Name
            State          = $State
            StateValue     = $null
            Silent         = $Silent
            OperationsPath = Join-Path $TestDrive 'Operations'
        }
    }

    # Runs one companion function exactly as the engine does (dot-sourced into the
    # module scope under strict mode), so module-scoped mocks apply to it.
    function Invoke-CompanionFunction {
        param(
            [Parameter(Mandatory = $true)]$Definition,
            [Parameter(Mandatory = $true)][string]$FunctionName,
            [Parameter(Mandatory = $true)]$Toggle
        )

        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleFunction -Definition $d -FunctionName $f -Toggle $t -Label 'test'
        } -Parameters @{ d = $Definition; f = $FunctionName; t = $Toggle }
    }

    # Runs the private power-scheme core inside the module so module-scoped mocks apply.
    function Invoke-PowerSavingCore {
        param([Parameter(Mandatory = $true)][string]$Mode)

        InModuleScope Atlas.Hardware {
            Invoke-AtlasPowerSavingState -RequestedMode $m -PowerCfgPath $p
        } -Parameters @{ m = $Mode; p = $script:powerCfg }
    }

    function New-PnpDevice {
        param(
            [Parameter(Mandatory = $true)][AllowEmptyString()][string]$FriendlyName,
            [Parameter(Mandatory = $true)][string]$InstanceId
        )

        return [pscustomobject]@{ FriendlyName = $FriendlyName; InstanceId = $InstanceId }
    }
}

Describe 'Atlas power-saving state' {
    BeforeEach {
        $script:activeQueue = New-Object 'Collections.Generic.Queue[string]'
        Mock Get-AtlasActivePowerScheme -ModuleName Atlas.Hardware { $script:activeQueue.Dequeue() }
        Mock Get-AtlasPowerSchemeInventory -ModuleName Atlas.Hardware { @($script:balanced, $script:custom) }
        Mock Get-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware { $null }
        Mock Save-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware { $SchemeGuid }
        Mock Clear-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware
        Mock Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware { @() }
    }

    It 'creates the Atlas plan from Balanced and applies only the four reviewed AC settings' {
        $script:activeQueue.Enqueue($script:custom)
        $script:activeQueue.Enqueue($script:atlas)

        Invoke-PowerSavingCore -Mode Atlas

        Should -Invoke Save-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware -Times 1 -Exactly `
            -ParameterFilter { $SchemeGuid -ceq $script:custom }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/duplicatescheme' -and
                $ArgumentList[1] -ceq $script:balanced -and
                $ArgumentList[2] -ceq $script:atlas
        }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 4 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setacvalueindex'
        }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:atlas
        }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 0 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/delete'
        }
    }

    It 'recreates an existing Atlas plan without saving Atlas as the rollback target' {
        Mock Get-AtlasPowerSchemeInventory -ModuleName Atlas.Hardware {
            @($script:balanced, $script:atlas)
        }
        $script:activeQueue.Enqueue($script:atlas)
        $script:activeQueue.Enqueue($script:atlas)

        Invoke-PowerSavingCore -Mode Atlas

        Should -Invoke Save-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware -Times 1 -Exactly `
            -ParameterFilter { $SchemeGuid -ceq $script:balanced }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:balanced
        }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/delete' -and
                $ArgumentList[1] -ceq $script:atlas
        }
    }

    It 'restores an installed saved plan and then removes the Atlas plan' {
        Mock Get-AtlasPowerSchemeInventory -ModuleName Atlas.Hardware {
            @($script:balanced, $script:custom, $script:atlas)
        }
        Mock Get-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware { $script:custom }
        $script:activeQueue.Enqueue($script:custom)

        Invoke-PowerSavingCore -Mode Default

        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:custom
        }
        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/delete' -and
                $ArgumentList[1] -ceq $script:atlas
        }
        Should -Invoke Clear-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware -Times 1 -Exactly `
            -ParameterFilter { $ExpectedSchemeGuid -ceq $script:custom }
    }

    It 'falls back to Balanced when the saved plan is no longer installed' {
        Mock Get-AtlasPowerSchemeInventory -ModuleName Atlas.Hardware {
            @($script:balanced, $script:atlas)
        }
        Mock Get-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware { $script:custom }
        $script:activeQueue.Enqueue($script:balanced)

        Invoke-PowerSavingCore -Mode Default

        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -ceq '/setactive' -and
                $ArgumentList[1] -ceq $script:balanced
        }
    }

    It 'keeps the saved plan when the final active-plan check fails' {
        Mock Get-AtlasPowerSchemeInventory -ModuleName Atlas.Hardware {
            @($script:balanced, $script:custom, $script:atlas)
        }
        Mock Get-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware { $script:custom }
        $script:activeQueue.Enqueue($script:balanced)

        { Invoke-PowerSavingCore -Mode Default } | Should -Throw '*expected*'

        Should -Invoke Clear-AtlasPreviousPowerScheme -ModuleName Atlas.Hardware -Times 0 -Exactly
    }

    It 'fails when the Windows Balanced scheme is missing' {
        Mock Get-AtlasPowerSchemeInventory -ModuleName Atlas.Hardware { @($script:custom) }

        { Invoke-PowerSavingCore -Mode Atlas } | Should -Throw '*Balanced power scheme is not installed*'

        Should -Invoke Invoke-AtlasPowerCfg -ModuleName Atlas.Hardware -Times 0 -Exactly
    }

}

Describe 'powercfg helpers' {
    It 'propagates a nonzero powercfg exit code' {
        $commandProcessor = Join-Path -Path ([Environment]::SystemDirectory) `
            -ChildPath 'cmd.exe'

        {
            InModuleScope Atlas.Hardware {
                Invoke-AtlasPowerCfg -FilePath $c -ArgumentList @('/d', '/c', 'exit 7')
            } -Parameters @{ c = $commandProcessor }
        } | Should -Throw "*exit code '7'*"
    }

    It 'parses scheme GUIDs independently of localized powercfg labels' {
        $result = InModuleScope Atlas.Hardware {
            Get-AtlasPowerSchemeGuidFromOutput -Output @(
                ''
                "Localized label: $b"
                "Another label: $c"
            )
        } -Parameters @{ b = $script:balanced; c = $script:custom }

        $result | Should -Be @($script:balanced, $script:custom)
    }
}

Describe 'Set-AtlasPowerSavingState' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Hardware
        Mock Write-AtlasStep -ModuleName Atlas.Hardware
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Hardware
        Mock Invoke-AtlasPowerSavingState -ModuleName Atlas.Hardware
    }

    It 'requires Administrator rights before any powercfg work' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Hardware { throw '[privilege] This operation requires Administrator rights.' }

        { Set-AtlasPowerSavingState -Mode Atlas -Silent } | Should -Throw '*requires Administrator*'

        Should -Invoke Invoke-AtlasPowerSavingState -ModuleName Atlas.Hardware -Times 0 -Exactly
    }

    It 'applies the requested mode through the exact System32 powercfg and reports progress unless silent' {
        Set-AtlasPowerSavingState -Mode Default

        $expected = [IO.Path]::Combine([Environment]::SystemDirectory, 'powercfg.exe')
        Should -Invoke Invoke-AtlasPowerSavingState -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $RequestedMode -ceq 'Default' -and $PowerCfgPath -eq $expected
        }
        Should -Invoke Write-AtlasStep -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $Text -like 'Restoring the previous power plan*'
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $Message -like "*'Default'*"
        }

        Set-AtlasPowerSavingState -Mode Atlas -Silent

        Should -Invoke Invoke-AtlasPowerSavingState -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $RequestedMode -ceq 'Atlas'
        }
        Should -Invoke Write-AtlasStep -ModuleName Atlas.Hardware -Times 1 -Exactly
    }

    It 'releases the transaction lock when the operation fails' {
        Mock Invoke-AtlasPowerSavingState -ModuleName Atlas.Hardware { throw 'simulated powercfg failure' }

        { Set-AtlasPowerSavingState -Mode Atlas -Silent } | Should -Throw '*simulated powercfg failure*'

        $mutex = New-Object Threading.Mutex($false, 'Global\AtlasOS.PowerSaving.Transaction.v1')
        try {
            $mutex.WaitOne([TimeSpan]::FromSeconds(1)) | Should -BeTrue
            [void]$mutex.ReleaseMutex()
        }
        finally {
            $mutex.Dispose()
        }
    }

    It 'rejects modes outside Atlas and Default' {
        { Set-AtlasPowerSavingState -Mode Balanced } | Should -Throw
    }
}

Describe 'Set-AtlasDeviceState' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Hardware
        Mock Write-AtlasSuccess -ModuleName Atlas.Hardware
        Mock Write-AtlasNote -ModuleName Atlas.Hardware
        Mock Import-AtlasPnpDeviceModule -ModuleName Atlas.Hardware
        Mock Get-AtlasPresentPnpDevice -ModuleName Atlas.Hardware {
            @(
                (New-PnpDevice -FriendlyName 'Intel Bluetooth Adapter' -InstanceId 'USB\VID_8087&PID_0026\BT1')
                (New-PnpDevice -FriendlyName 'Bluetooth Device (RFCOMM)' -InstanceId 'BTH\MS_RFCOMM\BT2')
                (New-PnpDevice -FriendlyName 'USB Root Hub' -InstanceId 'USB\ROOT_HUB30\HUB1')
                (New-PnpDevice -FriendlyName '' -InstanceId 'ACPI\NAMELESS\1')
            )
        }
        Mock Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware { @(0) }
    }

    It 'disables every present device matching a pattern and nothing else' {
        Set-AtlasDeviceState -State Disable -Devices '*Bluetooth*' -Silent

        Should -Invoke Import-AtlasPnpDeviceModule -ModuleName Atlas.Hardware -Times 1 -Exactly
        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 2 -Exactly
        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $InstanceId -ceq 'USB\VID_8087&PID_0026\BT1' -and $State -ceq 'Disable'
        }
        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $InstanceId -ceq 'BTH\MS_RFCOMM\BT2' -and $State -ceq 'Disable'
        }
        Should -Invoke Write-AtlasSuccess -ModuleName Atlas.Hardware -Times 0 -Exactly
        Should -Invoke Write-AtlasNote -ModuleName Atlas.Hardware -Times 0 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $Message -like 'Disabled 2 matched device(s)*'
        }
    }

    It 'enables with several patterns and lists the devices when not silent' {
        Set-AtlasDeviceState -State Enable -Devices @('*RFCOMM*', 'USB Root*')

        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 2 -Exactly -ParameterFilter {
            $State -ceq 'Enable'
        }
        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 0 -Exactly -ParameterFilter {
            $InstanceId -like '*BT1'
        }
        Should -Invoke Write-AtlasSuccess -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $Text -ceq 'Enabled 2 device(s):'
        }
        Should -Invoke Write-AtlasNote -ModuleName Atlas.Hardware -Times 1 -Exactly -ParameterFilter {
            $Text -contains '  - USB Root Hub'
        }
    }

    It 'fails without a match unless AllowNoMatch is given' {
        { Set-AtlasDeviceState -State Disable -Devices '*Thunderbolt*' -Silent } |
            Should -Throw '*No present devices matched: *Thunderbolt*'

        { Set-AtlasDeviceState -State Disable -Devices '*Thunderbolt*' -Silent -AllowNoMatch } |
            Should -Not -Throw

        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 0 -Exactly
    }

    It 'never matches a device with a blank friendly name' {
        Set-AtlasDeviceState -State Disable -Devices '*' -Silent

        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 3 -Exactly
        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 0 -Exactly -ParameterFilter {
            $InstanceId -like 'ACPI*'
        }
    }

    It 'reports a nonzero provider result and stops at that device' {
        Mock Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware { @(5) }

        { Set-AtlasDeviceState -State Disable -Devices '*Bluetooth*' -Silent } |
            Should -Throw "*Disabling device 'Intel Bluetooth Adapter'*returned WMI result '5'*"

        Should -Invoke Set-AtlasPnpDeviceState -ModuleName Atlas.Hardware -Times 1 -Exactly
    }

    It 'surfaces an enumeration failure instead of treating it as no match' {
        Mock Get-AtlasPresentPnpDevice -ModuleName Atlas.Hardware { throw 'RPC server unavailable' }

        { Set-AtlasDeviceState -State Disable -Devices '*Bluetooth*' -Silent -AllowNoMatch } |
            Should -Throw '*RPC server unavailable*'
    }

    It 'rejects blank or oversized patterns before enumerating' {
        { Set-AtlasDeviceState -State Disable -Devices @('*Bluetooth*', '   ') -Silent } |
            Should -Throw '*nonempty and at most 256 characters*'
        { Set-AtlasDeviceState -State Disable -Devices ('a' * 257) -Silent } |
            Should -Throw '*nonempty and at most 256 characters*'
        { Set-AtlasDeviceState -State Disable -Devices @() -Silent } | Should -Throw

        Should -Invoke Get-AtlasPresentPnpDevice -ModuleName Atlas.Hardware -Times 0 -Exactly
    }
}

Describe 'Hardware toggle companions' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Write-AtlasSuccess -ModuleName Atlas.Toggles
        Mock Write-AtlasStep -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
    }

    It 'PowerSaving maps both recorded states onto the power-saving modes' {
        Mock Set-AtlasPowerSavingState -ModuleName Atlas.Toggles

        $definition = $script:PowerSaving
        foreach ($stateName in @('Disable', 'Enable')) {
            $definition.States[$stateName]['MachineAction'] | Should -BeExactly 'Invoke-AtlasPowerSavingToggle'
        }
        $definition.States['Disable']['StateValue'] | Should -Be 0
        $definition.States['Enable']['StateValue'] | Should -Be 1

        Invoke-CompanionFunction -Definition $definition -FunctionName 'Invoke-AtlasPowerSavingToggle' `
            -Toggle (New-ToggleContext -Name 'PowerSaving' -State 'Disable' -Silent $true)
        Invoke-CompanionFunction -Definition $definition -FunctionName 'Invoke-AtlasPowerSavingToggle' `
            -Toggle (New-ToggleContext -Name 'PowerSaving' -State 'Enable' -Silent $false)

        Should -Invoke Set-AtlasPowerSavingState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Mode -ceq 'Atlas' -and $Silent
        }
        Should -Invoke Set-AtlasPowerSavingState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Mode -ceq 'Default' -and -not $Silent
        }
        Should -Invoke Import-AtlasModule -ModuleName Atlas.Toggles -Times 2 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Hardware' }
        Should -Invoke Write-AtlasSuccess -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Text -like 'The previous power plan*'
        }
    }

    It 'Bluetooth disables and enables the present Bluetooth devices tolerating absence' {
        Mock Set-AtlasDeviceState -ModuleName Atlas.Toggles

        $definition = $script:Bluetooth
        $definition.States['Disable']['MachineAction'] | Should -BeExactly 'Disable-AtlasBluetoothDevices'
        $definition.States['Enable']['MachineAction'] | Should -BeExactly 'Enable-AtlasBluetoothDevices'

        Invoke-CompanionFunction -Definition $definition -FunctionName 'Disable-AtlasBluetoothDevices' `
            -Toggle (New-ToggleContext -Name 'Bluetooth' -State 'Disable')
        Invoke-CompanionFunction -Definition $definition -FunctionName 'Enable-AtlasBluetoothDevices' `
            -Toggle (New-ToggleContext -Name 'Bluetooth' -State 'Enable')

        Should -Invoke Set-AtlasDeviceState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -ceq 'Disable' -and @($Devices) -ceq '*Bluetooth*' -and $AllowNoMatch -and $Silent
        }
        Should -Invoke Set-AtlasDeviceState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -ceq 'Enable' -and @($Devices) -ceq '*Bluetooth*' -and $AllowNoMatch -and $Silent
        }
        Should -Invoke Import-AtlasModule -ModuleName Atlas.Toggles -Times 2 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Hardware' }
    }
}

Describe 'set-power-settings install tweak' {
    It 'applies and records the power-saving choice through the toggle engine' {
        Mock Test-AtlasOption { $Name -ceq 'disable-power-saving' }
        Mock Import-AtlasModule
        Mock Invoke-AtlasToggleMachineState

        & $script:PowerTweakScript

        Should -Invoke Import-AtlasModule -Times 1 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Toggles' }
        Should -Invoke Invoke-AtlasToggleMachineState -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'PowerSaving' -and $State -ceq 'Disable'
        }
    }
}
