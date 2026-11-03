BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.State\Atlas.State.psd1') -Force

    # A completed install with these options, as completion records it.
    function Install-TestState {
        param([string[]]$Options = @())

        $install = [pscustomobject]@{
            targetVersion = '0.6.0'; mode = 'Fresh'; isOobe = $false
            options = $Options; transactionId = '11111111-1111-4111-8111-111111111111'
        }
        Set-AtlasStateInstall -InstallState $install -Path $script:DocumentPath | Out-Null
    }

    function Get-TestOption {
        return @((Get-AtlasState -Path $script:DocumentPath).options)
    }
}

Describe 'Machine state document' {
    BeforeEach {
        $script:DocumentPath = Join-Path $TestDrive 'AtlasOS\state.json'
        Remove-Item -LiteralPath $script:DocumentPath -Force -ErrorAction SilentlyContinue
    }

    It 'is absent until an install completes, then records it and appends history on upgrade' {
        Get-AtlasState -Path $script:DocumentPath | Should -BeNullOrEmpty

        $fresh = [pscustomobject]@{
            targetVersion = '0.6.0'; mode = 'Fresh'; isOobe = $false
            options = @('defender-enable', 'browser-brave'); transactionId = '11111111-1111-4111-8111-111111111111'
        }
        Set-AtlasStateInstall -InstallState $fresh -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        $document.installedVersion | Should -Be '0.6.0'
        $document.mode | Should -Be 'Fresh'
        $document.isInteractive | Should -BeTrue
        @($document.options) | Should -Be @('defender-enable', 'browser-brave')
        @($document.history).Count | Should -Be 1

        $upgrade = [pscustomobject]@{
            targetVersion = '0.7.0'; mode = 'Upgrade'; isOobe = $true
            options = @('defender-disable'); transactionId = '22222222-2222-4222-8222-222222222222'
        }
        Set-AtlasStateInstall -InstallState $upgrade -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        $document.installedVersion | Should -Be '0.7.0'
        $document.isOobe | Should -BeTrue
        $document.isInteractive | Should -BeFalse
        @($document.history | ForEach-Object { $_.version }) | Should -Be @('0.6.0', '0.7.0')
    }

    It 'records the options completion read from the PC instead of the requested ones: <Case>' -ForEach @(
        @{ Case = 'some'; Options = @('defender-disable', 'mitigations-default') }
        @{ Case = 'one'; Options = @('uninstall-edge') }
        @{ Case = 'none'; Options = @() }
    ) {
        $install = [pscustomobject]@{
            targetVersion = '0.6.1'; mode = 'Reapply'; isOobe = $false
            options = @('defender-enable', 'mitigations-disable'); transactionId = '33333333-3333-4333-8333-333333333333'
        }
        Set-AtlasStateInstall -InstallState $install -Options $Options -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        @($document.options) | Should -Be $Options
        $document.installedVersion | Should -Be '0.6.1'
        @($document.history).Count | Should -Be 1
    }

    It 'records the requested options when -Options is passed on as <Case>' -ForEach @(
        @{ Case = 'null'; Typed = $false }
        @{ Case = 'an unset [string[]]'; Typed = $true }
    ) {
        $install = [pscustomobject]@{
            targetVersion = '0.6.1'; mode = 'Reapply'; isOobe = $false
            options = @('defender-enable', 'mitigations-disable'); transactionId = '33333333-3333-4333-8333-333333333333'
        }
        # How a completion with no -RecordedOptions of its own would forward it.
        [string[]]$recorded = $null
        if ($Typed) {
            Set-AtlasStateInstall -InstallState $install -Options $recorded -Path $script:DocumentPath | Out-Null
        }
        else {
            Set-AtlasStateInstall -InstallState $install -Options $null -Path $script:DocumentPath | Out-Null
        }

        @((Get-AtlasState -Path $script:DocumentPath).options) | Should -Be @('defender-enable', 'mitigations-disable')
    }

    It 'mirrors toggle records and rebuilds the toggle view from the store' {
        Set-AtlasStateToggle -Name 'Bluetooth' -State 0 -Path $script:DocumentPath | Out-Null
        Set-AtlasStateToggle -Name 'Bluetooth' -State 1 -Path $script:DocumentPath | Out-Null
        Set-AtlasStateToggle -Name 'Printing' -State 1 -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        $document.toggles.Bluetooth.state | Should -Be 1
        $document.toggles.Printing.state | Should -Be 1
        $document.installedVersion | Should -BeNullOrEmpty

        Sync-AtlasStateToggles -Records @{ Printing = 0; SuperFetch = 1 } -Path $script:DocumentPath | Out-Null

        $document = Get-AtlasState -Path $script:DocumentPath
        @($document.toggles.PSObject.Properties.Name | Sort-Object) | Should -Be @('Printing', 'SuperFetch')
        $document.toggles.Printing.state | Should -Be 0
    }

    It 'keeps a toggle''s time while its state stays the same, so a replay doesn''t move it' {
        $old = '2026-01-01T00:00:00.0000000+00:00'
        Set-AtlasStateToggle -Name 'Mitigations' -State 2 -Path $script:DocumentPath | Out-Null
        Update-AtlasState -Path $script:DocumentPath -Action {
            param($document)
            $document.toggles.Mitigations.updatedAt = '2026-01-01T00:00:00.0000000+00:00'
        } | Out-Null

        Set-AtlasStateToggle -Name 'Mitigations' -State 2 -Path $script:DocumentPath | Out-Null
        (Get-AtlasState -Path $script:DocumentPath).toggles.Mitigations.updatedAt | Should -BeExactly $old
        Sync-AtlasStateToggles -Records @{ Mitigations = 2 } -Path $script:DocumentPath | Out-Null
        (Get-AtlasState -Path $script:DocumentPath).toggles.Mitigations.updatedAt | Should -BeExactly $old

        Set-AtlasStateToggle -Name 'Mitigations' -State 1 -Path $script:DocumentPath | Out-Null
        (Get-AtlasState -Path $script:DocumentPath).toggles.Mitigations.updatedAt | Should -Not -Be $old
    }

    It 'rejects a malformed document instead of trusting it' {
        New-Item -Path (Split-Path $script:DocumentPath) -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $script:DocumentPath -Value '{"schemaVersion":1,"toggles":{}}'
        { Get-AtlasState -Path $script:DocumentPath } | Should -Throw '*missing*'

        Set-Content -LiteralPath $script:DocumentPath -Value 'not json'
        { Get-AtlasState -Path $script:DocumentPath } | Should -Throw '*malformed*'
    }

    It 'rejects toggle names outside the record grammar' {
        { Set-AtlasStateToggle -Name 'bad name' -State 1 -Path $script:DocumentPath } | Should -Throw
        { Sync-AtlasStateToggles -Records @{ 'bad\name' = 1 } -Path $script:DocumentPath } | Should -Throw '*invalid*'
    }

    It 'replaces the file atomically and leaves no temporary files behind' {
        Set-AtlasStateToggle -Name 'A' -State 1 -Path $script:DocumentPath | Out-Null
        Set-AtlasStateToggle -Name 'B' -State 1 -Path $script:DocumentPath | Out-Null

        @(Get-ChildItem -LiteralPath (Split-Path $script:DocumentPath) -Force | ForEach-Object { $_.Name }) | Should -Be @('state.json')
    }
}

Describe 'Install choices kept in step between installs' {
    BeforeEach {
        $script:DocumentPath = Join-Path $TestDrive 'AtlasOS\state.json'
        Remove-Item -LiteralPath (Split-Path $script:DocumentPath) -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'a choice toggle with -SyncChoice' {
        BeforeAll {
            # An RC install whose recorded options disagreed with its toggle records.
            $script:BaseOptions = @(
                'defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single'
                'disable-power-saving', 'uninstall-edge', 'install-toolbox'
            )
        }

        It 'sets <Expected> for <Name> state <State>' -ForEach @(
            @{ Name = 'Mitigations'; State = 2; Expected = 'mitigations-default replacing mitigations-disable'
                Options = @('defender-enable', 'mitigations-default', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'Mitigations'; State = 1; Expected = 'mitigations-default replacing mitigations-disable'
                Options = @('defender-enable', 'mitigations-default', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'Mitigations'; State = 0; Expected = 'mitigations-disable, as it was'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'AutomaticUpdates'; State = 1; Expected = 'auto-updates-default'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-default', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'AutomaticUpdates'; State = 0; Expected = 'auto-updates-disable, as it was'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'Hibernation'; State = 0; Expected = 'disable-hibernation ticked'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox', 'disable-hibernation') }
            @{ Name = 'Hibernation'; State = 1; Expected = 'disable-hibernation clear, as it was'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'PowerSaving'; State = 1; Expected = 'disable-power-saving cleared'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'PowerSaving'; State = 0; Expected = 'disable-power-saving ticked once, where it was'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'VbsState'; State = 0; Expected = 'disable-core-isolation ticked'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox', 'disable-core-isolation') }
            @{ Name = 'VbsState'; State = 1; Expected = 'disable-core-isolation clear'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'KeyboardShortcuts'; State = 1; Expected = 'keyboard-shortcuts replacing keyboard-single'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-shortcuts', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
            @{ Name = 'KeyboardShortcuts'; State = 0; Expected = 'keyboard-single kept, since state 0 means it too'
                Options = @('defender-enable', 'mitigations-disable', 'auto-updates-disable', 'keyboard-single', 'disable-power-saving', 'uninstall-edge', 'install-toolbox') }
        ) {
            Install-TestState -Options $script:BaseOptions

            Set-AtlasStateToggle -Name $Name -State $State -SyncChoice -Path $script:DocumentPath | Out-Null

            Get-TestOption | Should -Be $Options
            (Get-AtlasState -Path $script:DocumentPath).toggles.$Name.state | Should -Be $State
        }

        It 'gives keyboard-selector for KeyboardShortcuts state 0 when the shortcuts were chosen' {
            Install-TestState -Options @('defender-enable', 'keyboard-shortcuts')

            Set-AtlasStateToggle -Name 'KeyboardShortcuts' -State 0 -SyncChoice -Path $script:DocumentPath | Out-Null

            Get-TestOption | Should -Be @('defender-enable', 'keyboard-selector')
        }

        It 'adds the radio choice when the group had none' {
            Install-TestState -Options @('defender-enable')

            Set-AtlasStateToggle -Name 'Mitigations' -State 0 -SyncChoice -Path $script:DocumentPath | Out-Null

            Get-TestOption | Should -Be @('defender-enable', 'mitigations-disable')
        }

        It 'leaves the options alone for <Case>' -ForEach @(
            @{ Case = 'a toggle that isn''t an install choice'; Name = 'Widgets'; State = 0; Sync = $true }
            @{ Case = 'a state no choice stands for'; Name = 'Hibernation'; State = 2; Sync = $true }
            @{ Case = 'a write without -SyncChoice'; Name = 'Mitigations'; State = 2; Sync = $false }
        ) {
            Install-TestState -Options $script:BaseOptions

            Set-AtlasStateToggle -Name $Name -State $State -SyncChoice:$Sync -Path $script:DocumentPath | Out-Null

            Get-TestOption | Should -Be $script:BaseOptions
            (Get-AtlasState -Path $script:DocumentPath).toggles.$Name.state | Should -Be $State
        }

        It 'records only the toggle before any install has completed' {
            Set-AtlasStateToggle -Name 'Mitigations' -State 0 -SyncChoice -Path $script:DocumentPath | Out-Null

            $document = Get-AtlasState -Path $script:DocumentPath
            @($document.options).Count | Should -Be 0
            $document.toggles.Mitigations.state | Should -Be 0
        }
    }

    Context 'Set-AtlasStateChoice' {
        It 'replaces the radio group''s answer where it stood' {
            Install-TestState -Options @('defender-enable', 'mitigations-disable', 'uninstall-edge')

            $document = Set-AtlasStateChoice -Option 'defender-disable' -Path $script:DocumentPath

            @($document.options) | Should -Be @('defender-disable', 'mitigations-disable', 'uninstall-edge')
            Get-TestOption | Should -Be @('defender-disable', 'mitigations-disable', 'uninstall-edge')
        }

        It 'ticks a checkbox once and clears it with -Absent' {
            Install-TestState -Options @('defender-enable')

            Set-AtlasStateChoice -Option 'uninstall-edge' -Path $script:DocumentPath | Out-Null
            Set-AtlasStateChoice -Option 'uninstall-edge' -Path $script:DocumentPath | Out-Null
            Get-TestOption | Should -Be @('defender-enable', 'uninstall-edge')

            Set-AtlasStateChoice -Option 'uninstall-edge' -Absent -Path $script:DocumentPath | Out-Null
            Get-TestOption | Should -Be @('defender-enable')
        }

        It 'leaves the file untouched when the choice already matches' {
            Install-TestState -Options @('defender-disable')
            $before = (Get-Item -LiteralPath $script:DocumentPath).LastWriteTimeUtc
            Start-Sleep -Milliseconds 50

            Set-AtlasStateChoice -Option 'defender-disable' -Path $script:DocumentPath | Should -Not -BeNullOrEmpty

            (Get-Item -LiteralPath $script:DocumentPath).LastWriteTimeUtc | Should -Be $before
        }

        It 'does nothing while an install is active, whose completion records what the PC has' {
            Install-TestState -Options @('defender-enable')
            $activePath = Join-Path (Split-Path $script:DocumentPath) 'Install\active.json'
            New-Item -Path (Split-Path $activePath) -ItemType Directory -Force | Out-Null
            Set-Content -LiteralPath $activePath -Value '{}'
            $before = [IO.File]::ReadAllText($script:DocumentPath)

            Set-AtlasStateChoice -Option 'defender-disable' -Path $script:DocumentPath | Should -BeNullOrEmpty

            [IO.File]::ReadAllText($script:DocumentPath) | Should -BeExactly $before
        }

        It 'does nothing before an install has completed: <Case>' -ForEach @(
            @{ Case = 'no document'; Toggles = $false }
            @{ Case = 'only toggle records'; Toggles = $true }
        ) {
            if ($Toggles) { Set-AtlasStateToggle -Name 'Bluetooth' -State 0 -Path $script:DocumentPath | Out-Null }

            Set-AtlasStateChoice -Option 'defender-disable' -Path $script:DocumentPath | Should -BeNullOrEmpty

            if ($Toggles) { @((Get-AtlasState -Path $script:DocumentPath).options).Count | Should -Be 0 }
            else { Test-Path -LiteralPath $script:DocumentPath | Should -BeFalse }
        }

        It 'refuses <Case>' -ForEach @(
            @{ Case = 'a choice it doesn''t keep in step'; Option = 'install-toolbox'; Absent = $false; Message = "*isn't an install choice*" }
            @{ Case = 'clearing one answer of a radio group'; Option = 'defender-enable'; Absent = $true; Message = "*can't be cleared*" }
        ) {
            Install-TestState -Options @('defender-enable')

            { Set-AtlasStateChoice -Option $Option -Absent:$Absent -Path $script:DocumentPath } | Should -Throw $Message
            Get-TestOption | Should -Be @('defender-enable')
        }
    }
}

Describe 'Toggles that keep install choices in step' {
    BeforeAll {
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:TogglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
        $script:StateRoot = 'HKCU:\Software\AtlasRewriteTest\StateChoiceSync'
    }

    AfterAll {
        Remove-Item -Path $script:StateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $script:DocumentPath = Join-Path $TestDrive 'AtlasOS\state.json'
        Remove-Item -LiteralPath (Split-Path $script:DocumentPath) -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $script:StateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'a recorded toggle syncs its choice only while no install is active: active=<Active>' -ForEach @(
        @{ Active = $false; Sync = $true }
        @{ Active = $true; Sync = $false }
    ) {
        if ($Active) {
            $activePath = Join-Path (Split-Path $script:DocumentPath) 'Install\active.json'
            New-Item -Path (Split-Path $activePath) -ItemType Directory -Force | Out-Null
            Set-Content -LiteralPath $activePath -Value '{}'
        }
        InModuleScope Atlas.Toggles -Parameters @{ Root = $script:StateRoot; DocumentPath = $script:DocumentPath; Sync = $Sync } {
            # Stands in for the production root, whose records the document mirrors.
            Mock Test-AtlasToggleProductionStateRoot { $true }
            Mock Protect-AtlasToggleStateRoot {}
            Mock Set-AtlasToggleStateKeyAcl {}
            Mock Get-AtlasStatePath { $DocumentPath }
            Mock Set-AtlasStateToggle {}

            Set-AtlasToggleState -Name 'Mitigations' -State 2 -StateRoot $Root

            Should -Invoke Set-AtlasStateToggle -Times 1 -Exactly -ParameterFilter {
                $Name -ceq 'Mitigations' -and $State -eq 2 -and [bool]$SyncChoice -eq $Sync
            }
        }
    }

    Context 'Install or Remove Edge' {
        BeforeAll {
            $script:RemoveEdge = Get-AtlasToggleDefinition -Name RemoveEdge -TogglesRoot $script:TogglesRoot
            $script:OperationsPath = Join-Path $TestDrive 'Operations'
            New-Item -Path $script:OperationsPath -ItemType Directory -Force | Out-Null

            function Invoke-RemoveEdgeCompanion {
                param([int]$HelperExitCode)

                Set-Content -LiteralPath (Join-Path $script:OperationsPath 'Remove-Edge.ps1') -Value @(
                    'param([switch]$Embedded)'
                    "exit $HelperExitCode"
                )
                $toggle = [pscustomobject]@{
                    Name = 'RemoveEdge'; State = 'Run'; StateValue = $null; Silent = $false
                    OperationsPath = $script:OperationsPath; AtlasModulesPath = $script:AtlasModulesPath
                }
                InModuleScope Atlas.Toggles {
                    Invoke-AtlasToggleFunction -Definition $d -FunctionName 'Invoke-AtlasEdgeRemover' -Toggle $t -Label 'test'
                } -Parameters @{ d = $script:RemoveEdge; t = $toggle }
            }
        }

        BeforeEach {
            $script:AtlasModulesPath = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
            $script:EdgeFlag = Join-Path $script:AtlasModulesPath 'Flags\option-uninstall-edge.flag'
            Mock Import-AtlasModule -ModuleName Atlas.Toggles
            Mock Write-AtlasLog -ModuleName Atlas.Toggles
            # The document of a completed install, which took the choice.
            Mock Set-AtlasStateChoice -ModuleName Atlas.Toggles { [pscustomobject]@{ options = @() } }
        }

        It 'records uninstall-edge as <Recorded> when the helper leaves Edge <Edge>, and the flag a new account''s setup reads' -ForEach @(
            @{ Edge = 'installed'; Present = $true; Recorded = 'clear' }
            @{ Edge = 'removed'; Present = $false; Recorded = 'ticked' }
        ) {
            $script:edgePresent = $Present
            Mock Test-Path -ModuleName Atlas.Toggles -ParameterFilter { $LiteralPath -like '*\Microsoft\Edge\Application\msedge.exe' } {
                $script:edgePresent
            }
            # The flag an earlier install published for the opposite choice.
            if ($Present) {
                New-Item -ItemType Directory -Force -Path (Split-Path $script:EdgeFlag) | Out-Null
                [IO.File]::WriteAllText($script:EdgeFlag, '')
            }

            Invoke-RemoveEdgeCompanion -HelperExitCode 0

            Should -Invoke Set-AtlasStateChoice -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                $Option -ceq 'uninstall-edge' -and [bool]$Absent -eq $script:edgePresent
            }
            [IO.File]::Exists($script:EdgeFlag) | Should -Be (-not $Present) -Because 'new accounts clean Edge data only while Edge is removed'
            Invoke-RemoveEdgeCompanion -HelperExitCode 0
            [IO.File]::Exists($script:EdgeFlag) | Should -Be (-not $Present) -Because 'running it again changes nothing'
        }

        It 'leaves the flag to the install when the document took no choice, as while an install runs' {
            Mock Set-AtlasStateChoice -ModuleName Atlas.Toggles { }
            Mock Test-Path -ModuleName Atlas.Toggles -ParameterFilter { $LiteralPath -like '*\Microsoft\Edge\Application\msedge.exe' } { $false }

            Invoke-RemoveEdgeCompanion -HelperExitCode 0

            Test-Path -LiteralPath $script:EdgeFlag | Should -BeFalse
        }

        It 'records nothing when the helper didn''t complete' {
            { Invoke-RemoveEdgeCompanion -HelperExitCode 3 } | Should -Throw '*exit code 3*'

            Should -Invoke Set-AtlasStateChoice -ModuleName Atlas.Toggles -Times 0 -Exactly
            Test-Path -LiteralPath $script:EdgeFlag | Should -BeFalse
        }

        It 'still succeeds, with a warning, when Edge changed but the record can''t be written' {
            Mock Set-AtlasStateChoice -ModuleName Atlas.Toggles { throw 'The Atlas state document is malformed.' }

            { Invoke-RemoveEdgeCompanion -HelperExitCode 0 } | Should -Not -Throw

            Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like "Couldn't record whether Microsoft Edge is installed*malformed*"
            }
        }
    }
}
