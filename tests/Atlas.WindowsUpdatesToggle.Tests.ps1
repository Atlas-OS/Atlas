BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force
    # The companion resolves these commands after Import-AtlasModule (mocked below); load
    # the real modules once so the mocks have a command to shadow inside Atlas.Toggles.
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Services\Atlas.Services.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    Add-Type -AssemblyName System.ServiceProcess

    $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'package\Executables\AtlasModules\Toggles'
    $script:windowsUpdates = Get-AtlasToggleDefinition -Name ToggleWindowsUpdates -TogglesRoot $togglesRoot

    function Invoke-EnableWindowsUpdateToggle {
        $toggle = [pscustomobject]@{ Name = 'ToggleWindowsUpdates'; State = 'Enable'; Silent = $true }
        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleFunction -Definition $d -FunctionName 'Enable-AtlasWindowsUpdates' -Toggle $t -Label 'test'
        } -Parameters @{ d = $script:windowsUpdates; t = $toggle }
    }
}

Describe 'Enable Windows Updates' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[string]]::new()
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Set-AtlasSettingsPageVisibility -ModuleName Atlas.Toggles
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Toggles
        Mock Get-ScheduledTask -ModuleName Atlas.Toggles { @() }
        Mock Get-Service -ModuleName Atlas.Toggles {
            [pscustomobject]@{ Name = $Name; Status = [System.ServiceProcess.ServiceControllerStatus]::Stopped }
        }
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles { $script:calls.Add("sc $($ArgumentList[1])") }
        Mock Start-Service -ModuleName Atlas.Toggles { $script:calls.Add("start $Name") }
    }

    It 'tells the service manager about each startup change before it starts the service' {
        # The registry write doesn't reach the service manager, which keeps refusing to start
        # a service it holds as disabled (error 1058) until Windows restarts.
        Invoke-EnableWindowsUpdateToggle

        $script:calls | Should -Be @(
            'sc wuauserv', 'start wuauserv'
            'sc UsoSvc', 'start UsoSvc'
            'sc WaaSMedicSvc', 'start WaaSMedicSvc'
        )
    }

    It 'finishes without starting a service whose startup change the service manager refuses' {
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles { throw 'exit code 5' }

        { Invoke-EnableWindowsUpdateToggle } | Should -Not -Throw

        Should -Not -Invoke Start-Service -ModuleName Atlas.Toggles
        Should -Invoke Get-ScheduledTask -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 3 -Exactly -ParameterFilter { $Level -ceq 'Warning' }
    }
}
