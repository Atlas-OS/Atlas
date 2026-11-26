BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Network\Atlas.Network.psd1') -Force
    $script:DevicesTweakScript = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\scripts\disable-pnp.ps1'

    # Disable-NetAdapterBinding binds InputObject by CIM class type name, so the fakes are
    # client-only instances of the real class.
    function New-TestAdapterBinding {
        param([string]$Name, [string]$ComponentID, [bool]$Enabled)
        New-CimInstance -ClassName MSFT_NetAdapterBindingSettingData -ClientOnly -Property @{
            Name = $Name; ComponentID = $ComponentID; Enabled = $Enabled
        }
    }
}

Describe 'disable-pnp install tweak' {
    BeforeEach {
        Mock Write-AtlasLog
    }

    # A Rebase runs this tweak after Defaults has replayed a recorded File Sharing choice.
    It 'leaves the File Sharing bindings to their toggle' {
        Mock Get-NetAdapterBinding {
            $sharing = @(InModuleScope Atlas.Network { $script:AtlasFileSharingBindingComponents })
            if ($sharing.Count -eq 0) { throw 'Atlas.Network lists no File Sharing bindings.' }
            foreach ($component in @('ms_lldp') + $sharing) {
                New-TestAdapterBinding -Name 'Ethernet' -ComponentID $component -Enabled $true
            }
        }
        Mock Disable-NetAdapterBinding
        Mock Get-PnpDevice
        Mock Disable-PnpDevice

        & $script:DevicesTweakScript

        Should -Not -Invoke Write-AtlasLog
        Should -Invoke Disable-NetAdapterBinding -Times 1 -Exactly
        Should -Invoke Disable-NetAdapterBinding -Times 1 -Exactly -ParameterFilter {
            @($InputObject).Count -eq 1 -and $InputObject[0].Name -ceq 'Ethernet' -and
            $InputObject[0].ComponentID -ceq 'ms_lldp'
        }
    }

    # -Name is a wildcard, and VPN adapters such as ZeroTier's put brackets in their names.
    It 'disables LLDP on an adapter whose name has wildcard brackets' {
        Mock Get-NetAdapterBinding {
            New-TestAdapterBinding -Name 'ZeroTier One [0123456789abcdef]' -ComponentID 'ms_lldp' -Enabled $true
        }
        Mock Disable-NetAdapterBinding
        Mock Get-PnpDevice
        Mock Disable-PnpDevice

        & $script:DevicesTweakScript

        Should -Not -Invoke Write-AtlasLog
        Should -Invoke Disable-NetAdapterBinding -Times 1 -Exactly -ParameterFilter {
            -not $PesterBoundParameters.ContainsKey('Name') -and
            $InputObject[0].Name -ceq 'ZeroTier One [0123456789abcdef]'
        }
    }

    It 'disables every listed device, logging each refusal and carrying on' {
        Mock Get-NetAdapterBinding {
            New-TestAdapterBinding -Name 'Ethernet' -ComponentID 'ms_lldp' -Enabled $true
            New-TestAdapterBinding -Name 'Wi-Fi' -ComponentID 'ms_lldp' -Enabled $true
            New-TestAdapterBinding -Name 'Ethernet 2' -ComponentID 'ms_lldp' -Enabled $false
        }
        Mock Disable-NetAdapterBinding { if ($InputObject[0].Name -ceq 'Wi-Fi') { throw 'binding refused' } }
        Mock Get-PnpDevice {
            [pscustomobject]@{ FriendlyName = 'System timer'; InstanceId = 'ACPI\PNP0100\4&1' }
            [pscustomobject]@{ FriendlyName = 'System Speaker'; InstanceId = 'ACPI\PNP0800\4&1' }
            [pscustomobject]@{ FriendlyName = 'Intel(R) Ethernet Connection'; InstanceId = 'PCI\VEN_8086\3&1' }
            [pscustomobject]@{ FriendlyName = $null; InstanceId = 'ROOT\NONAME\0000' }
        }
        Mock Disable-PnpDevice { if (@($InstanceId) -ceq 'ACPI\PNP0100\4&1') { throw 'device refused' } }

        & $script:DevicesTweakScript

        Should -Invoke Disable-NetAdapterBinding -Times 2 -Exactly
        Should -Invoke Disable-PnpDevice -Times 2 -Exactly
        Should -Invoke Disable-PnpDevice -Times 1 -Exactly -ParameterFilter { @($InstanceId) -ceq 'ACPI\PNP0800\4&1' }
        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
            $Level -ceq 'Warning' -and $Message -like "*LLDP binding on adapter 'Wi-Fi'*binding refused*"
        }
        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
            $Level -ceq 'Warning' -and $Message -like "*device 'System timer' (ACPI\PNP0100\4&1)*device refused*"
        }
    }

    It 'logs a listing failure instead of failing the install' {
        Mock Get-NetAdapterBinding { throw 'binding provider failed' }
        Mock Disable-NetAdapterBinding
        Mock Get-PnpDevice { throw 'device provider failed' }
        Mock Disable-PnpDevice

        { & $script:DevicesTweakScript } | Should -Not -Throw

        Should -Not -Invoke Disable-NetAdapterBinding
        Should -Not -Invoke Disable-PnpDevice
        Should -Invoke Write-AtlasLog -Times 2 -Exactly -ParameterFilter { $Level -ceq 'Warning' }
    }
}
