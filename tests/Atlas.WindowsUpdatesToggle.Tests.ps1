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

    function Invoke-WindowsUpdateToggle([string]$State, [string]$FunctionName) {
        $toggle = [pscustomobject]@{ Name = 'ToggleWindowsUpdates'; State = $State; Silent = $true }
        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleFunction -Definition $d -FunctionName $f -Toggle $t -Label 'test'
        } -Parameters @{ d = $script:windowsUpdates; f = $FunctionName; t = $toggle }
    }
}

Describe 'Enable Windows Updates' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[string]]::new()
        $script:serviceManager = 'Synced'
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Set-AtlasSettingsPageVisibility -ModuleName Atlas.Toggles
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Toggles {
            $script:calls.Add("startup $Name $StartupType")
            [pscustomobject]@{ Name = $Name; Applied = $true; StartupType = $StartupType; ServiceManager = $script:serviceManager }
        }
        Mock Get-ScheduledTask -ModuleName Atlas.Toggles { @() }
        Mock Get-Service -ModuleName Atlas.Toggles {
            [pscustomobject]@{ Name = $Name; Status = [System.ServiceProcess.ServiceControllerStatus]::Stopped }
        }
        Mock Start-Service -ModuleName Atlas.Toggles { $script:calls.Add("start $Name") }
    }

    It 'starts each service once the service manager holds it as manual' {
        # The service manager refuses to start a service it still holds as disabled
        # (error 1058) until Windows restarts; the startup helper tells it first.
        Invoke-WindowsUpdateToggle Enable 'Enable-AtlasWindowsUpdates'

        $script:calls | Should -Be @(
            'startup wuauserv 3', 'start wuauserv'
            'startup UsoSvc 3', 'start UsoSvc'
            'startup WaaSMedicSvc 3', 'start WaaSMedicSvc'
        )
    }

    It 'finishes without starting a service whose startup type the service manager kept' {
        $script:serviceManager = 'Refused'

        { Invoke-WindowsUpdateToggle Enable 'Enable-AtlasWindowsUpdates' } | Should -Not -Throw

        Should -Not -Invoke Start-Service -ModuleName Atlas.Toggles
        Should -Invoke Get-ScheduledTask -ModuleName Atlas.Toggles -Times 1 -Exactly
    }
}

Describe 'Disable Windows Updates' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[string]]::new()
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Set-AtlasSettingsPageVisibility -ModuleName Atlas.Toggles
        Mock Get-ScheduledTask -ModuleName Atlas.Toggles { @() }
        Mock Get-Service -ModuleName Atlas.Toggles {
            [pscustomobject]@{ Name = $Name; Status = [System.ServiceProcess.ServiceControllerStatus]::Running }
        }
        Mock Stop-Service -ModuleName Atlas.Toggles { $script:calls.Add("stop $Name") }
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Toggles { $script:calls.Add("startup $Name $StartupType") }
    }

    It 'stops each service, then disables it through the startup helper, which tells the service manager' {
        Invoke-WindowsUpdateToggle Disable 'Disable-AtlasWindowsUpdates'

        $script:calls | Should -Be @(
            'stop wuauserv', 'startup wuauserv 4'
            'stop UsoSvc', 'startup UsoSvc 4'
            'stop WaaSMedicSvc', 'startup WaaSMedicSvc 4'
        )
    }
}
