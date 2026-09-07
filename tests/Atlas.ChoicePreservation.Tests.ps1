BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Search\Atlas.Search.psd1') -Force
    $script:choiceRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    . (Join-Path $script:choiceRoot 'General\WebSearch.ps1')
    . (Join-Path $script:choiceRoot 'General\PhoneLink.ps1')
    . (Join-Path $script:choiceRoot 'General\Sleep.ps1')
    . (Join-Path $script:choiceRoot 'General\Indexing.ps1')
}

Describe 'Independent choices survive toggle replay' {
    BeforeEach {
        Mock Import-AtlasModule {}
        Mock Read-AtlasYesNo { throw 'Silent work must not prompt.' }
        Mock Set-AtlasRegistryValue {}
        Mock Remove-AtlasRegistryValue {}
        Mock Set-AtlasSettingsPageVisibility {}
        Mock Get-Service { [pscustomobject]@{ Status = 'Stopped' } }
        Mock Set-AtlasIndexingMachineState {}
        Mock Set-AtlasToggleState {}
    }

    It 'preserves search location and disabled indexing in silent Web Search enable' {
        Enable-AtlasWebSearchMachine -Toggle ([pscustomobject]@{ Silent = $true })
        Should -Invoke Set-AtlasRegistryValue -Times 0 -Exactly
        Should -Invoke Remove-AtlasRegistryValue -Times 0 -Exactly
        Should -Invoke Set-AtlasIndexingMachineState -Times 0 -Exactly
        Should -Invoke Read-AtlasYesNo -Times 0 -Exactly
        Should -Invoke Set-AtlasToggleState -Times 0 -Exactly
    }

    It 'records indexing only after an explicit successful indexing change' {
        Mock Read-AtlasYesNo { $true }
        Enable-AtlasWebSearchMachine -Toggle ([pscustomobject]@{ Silent = $false; StateRoot = 'HKCU:\Unused' })
        Should -Invoke Set-AtlasIndexingMachineState -Times 1 -Exactly -ParameterFilter { $State -eq 'Full' -and $PreservePowerModes }
        Should -Invoke Set-AtlasToggleState -Times 1 -Exactly -ParameterFilter { $Name -eq 'Indexing' -and $State -eq 2 }
    }

    It 'preserves power-mode handling when full indexing is replayed' {
        Enable-AtlasSearchIndexing -Toggle ([pscustomobject]@{ Silent = $true })
        Should -Invoke Set-AtlasIndexingMachineState -Times 1 -Exactly -ParameterFilter { $State -eq 'Full' -and $PreservePowerModes }
        Should -Not -Invoke Read-AtlasYesNo
    }

    It 'preserves independent account consumer and Store policies in silent Phone Link enable' {
        $definition = Get-AtlasToggleDefinition -Name PhoneLink -TogglesRoot $script:choiceRoot
        @($definition.States.Enable.Registry | Where-Object {
            $_.Name -in @('NoConnectedUser', 'DisableWindowsConsumerFeatures', 'AutoDownload')
        }) | Should -HaveCount 0
        Enable-AtlasPhoneLinkMachine -Toggle ([pscustomobject]@{ Silent = $true })
        Should -Invoke Set-AtlasRegistryValue -Times 0 -Exactly
        Should -Invoke Remove-AtlasRegistryValue -Times 0 -Exactly
        Should -Invoke Read-AtlasYesNo -Times 0 -Exactly
    }

    It 'does not change hibernation when its optional change is declined' {
        Mock Read-AtlasYesNo { $false }
        Mock Test-Path { $true }
        Mock Invoke-AtlasToggleNativeCommand {}
        Mock Invoke-AtlasToggleMachineState {}
        Set-AtlasSleepState -Toggle ([pscustomobject]@{
            Silent = $false; State = 'Disable'; WinDir = $env:SystemRoot; StateRoot = 'HKCU:\Unused'
        })
        Should -Invoke Invoke-AtlasToggleMachineState -Times 0 -Exactly
    }

    It 'does not change broader policies when every Phone Link enable dependency is declined' {
        Mock Read-AtlasYesNo { $false }
        Enable-AtlasPhoneLinkMachine -Toggle ([pscustomobject]@{ Silent = $false })
        Should -Invoke Set-AtlasRegistryValue -Times 0 -Exactly
        Should -Invoke Remove-AtlasRegistryValue -Times 0 -Exactly
    }

    It 'does not record indexing if the explicitly requested change fails' {
        Mock Read-AtlasYesNo { $true }
        Mock Set-AtlasIndexingMachineState { throw 'indexing failed' }
        { Enable-AtlasWebSearchMachine -Toggle ([pscustomobject]@{ Silent = $false; StateRoot = 'HKCU:\Unused' }) } | Should -Throw '*indexing failed*'
        Should -Invoke Set-AtlasToggleState -Times 0 -Exactly
    }

    It 'retains user tracking preferences when recent items are unlocked' {
        $definition = Get-AtlasToggleDefinition -Name RecentItems -TogglesRoot $script:choiceRoot
        @($definition.States.Unlock.Registry | Where-Object {
            $_.Name -in @('Start_TrackProgs', 'Start_TrackDocs')
        }) | Should -HaveCount 0
    }

    It 'leaves administrator update policies outside the unpause operation' {
        $definition = Get-AtlasToggleDefinition -Name PauseUpdates -TogglesRoot $script:choiceRoot
        @($definition.States.Unpause.Registry | Where-Object {
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

