BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Search\Atlas.Search.psd1') -Force
    $script:choiceRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'

    # Runs a state's machine action the way the engine does: with the engine's own
    # $Toggle context, dot-sourced inside Atlas.Toggles under strict mode, so
    # module-scoped mocks apply and a strict-mode failure shows up here too.
    function Invoke-MachineAction {
        param(
            [Parameter(Mandatory = $true)][string]$Toggle,
            [Parameter(Mandatory = $true)][string]$State,
            [bool]$Silent = $true
        )

        $definition = Get-AtlasToggleDefinition -Name $Toggle -TogglesRoot $script:choiceRoot
        InModuleScope Atlas.Toggles {
            $context = New-AtlasToggleContext -Definition $d -StateName $s -Silent:$silent -StateRoot 'HKCU:\Unused'
            Invoke-AtlasToggleFunction -Definition $d -FunctionName ([string]$d['States'][$s]['MachineAction']) `
                -Toggle $context -Label 'test'
        } -Parameters @{ d = $definition; s = $State; silent = $Silent }
    }
}

Describe 'Independent choices survive toggle replay' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Write-AtlasStep -ModuleName Atlas.Toggles
        Mock Write-AtlasWarning -ModuleName Atlas.Toggles
        Mock Write-AtlasSuccess -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { throw 'Silent work must not prompt.' }
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Set-AtlasSettingsPageVisibility -ModuleName Atlas.Toggles
        Mock Get-Service -ModuleName Atlas.Toggles { [pscustomobject]@{ Status = 'Stopped' } }
        Mock Set-AtlasIndexingMachineState -ModuleName Atlas.Toggles
        Mock Set-AtlasToggleState -ModuleName Atlas.Toggles
    }

    It 'preserves search location and disabled indexing in silent Web Search enable' {
        Invoke-MachineAction -Toggle WebSearch -State Enable
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Set-AtlasIndexingMachineState -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Set-AtlasToggleState -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'records indexing only after an explicit successful indexing change' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }
        Invoke-MachineAction -Toggle WebSearch -State Enable -Silent $false
        Should -Invoke Set-AtlasIndexingMachineState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -eq 'Full' -and $PreservePowerModes
        }
        Should -Invoke Set-AtlasToggleState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Indexing' -and $State -eq 2 -and $StateRoot -ceq 'HKCU:\Unused'
        }
    }

    It 'preserves power-mode handling when full indexing is replayed' {
        Invoke-MachineAction -Toggle Indexing -State Enable
        Should -Invoke Set-AtlasIndexingMachineState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -eq 'Full' -and $PreservePowerModes
        }
        Should -Not -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles
    }

    It 'preserves independent account consumer and Store policies in silent Phone Link enable' {
        $definition = Get-AtlasToggleDefinition -Name PhoneLink -TogglesRoot $script:choiceRoot
        @($definition.States.Enable.Registry | Where-Object {
            $_.Name -in @('NoConnectedUser', 'DisableWindowsConsumerFeatures', 'AutoDownload')
        }) | Should -HaveCount 0
        Invoke-MachineAction -Toggle PhoneLink -State Enable
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'does not change hibernation when its optional change is declined' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $false }
        Mock Test-Path -ModuleName Atlas.Toggles { $true } -ParameterFilter { $LiteralPath -like '*\powercfg.exe' }
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles
        Mock Invoke-AtlasToggleMachineState -ModuleName Atlas.Toggles
        Invoke-MachineAction -Toggle Sleep -State Disable -Silent $false
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Invoke-AtlasToggleMachineState -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'does not change broader policies when every Phone Link enable dependency is declined' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $false }
        Invoke-MachineAction -Toggle PhoneLink -State Enable -Silent $false
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 3 -Exactly
        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'does not record indexing if the explicitly requested change fails' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }
        Mock Set-AtlasIndexingMachineState -ModuleName Atlas.Toggles { throw 'indexing failed' }
        { Invoke-MachineAction -Toggle WebSearch -State Enable -Silent $false } | Should -Throw '*indexing failed*'
        Should -Invoke Set-AtlasToggleState -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'retains user tracking preferences when recent items are unlocked' {
        $definition = Get-AtlasToggleDefinition -Name RecentItems -TogglesRoot $script:choiceRoot
        @($definition.States.Enable.Registry | Where-Object {
            $_.Name -in @('Start_TrackProgs', 'Start_TrackDocs')
        }) | Should -HaveCount 0
    }

    It 'leaves administrator update policies outside the unpause operation' {
        $definition = Get-AtlasToggleDefinition -Name PauseUpdates -TogglesRoot $script:choiceRoot
        @($definition.States.Disable.Registry | Where-Object {
            $_.Path -like '*\Policies\Microsoft\Windows\WindowsUpdate'
        }) | Should -HaveCount 0
    }

    It 'rejects old full-network-repair records before resolving any executable work' {
        $definition = Get-AtlasToggleDefinition -Name DefaultAtlasNetwork -TogglesRoot $script:choiceRoot
        InModuleScope Atlas.Toggles -Parameters @{ root = $script:choiceRoot; definition = $definition } {
            foreach ($state in $definition.States.Values) {
                Test-AtlasToggleRecordsState -Definition $definition -StateEntry $state | Should -BeFalse
            }
            Mock Get-ItemProperty { [pscustomobject]@{ state = 0 } }
            Mock Get-AtlasToggleReplayDefinition { $definition }
            Mock Get-AtlasToggleStateWork { throw 'Network repair must never resolve to replay work.' }
            $key = [pscustomobject]@{ PSPath = 'HKCU:\Unused'; PSChildName = 'DefaultAtlasNetwork' }
            $key | Add-Member ScriptMethod GetValueKind {
                param($name)
                if ($name -ne 'state') { throw 'Unexpected registry value queried.' }
                [Microsoft.Win32.RegistryValueKind]::DWord
            }
            try {
                Resolve-AtlasToggleReplayRecord -Subkey $key -TogglesRoot $root
                throw 'Expected a stale record.'
            }
            catch {
                $_.Exception.Data['AtlasToggleReplayRecordDisposition'] | Should -BeExactly 'Stale' -Because $_.Exception.Message
            }
            Should -Invoke Get-AtlasToggleStateWork -Times 0 -Exactly
        }
    }
}
