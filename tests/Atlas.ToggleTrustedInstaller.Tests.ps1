BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $modulesRoot = Join-Path -Path $repoRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Modules'
    $script:enginePath = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Toggles\Domain\Engine.ps1'
    $script:brokerPath = Join-Path -Path $repoRoot -ChildPath `
        'playbook\Executables\AtlasModules\Scripts\Internal\Invoke-AtlasTrustedInstallerBroker.ps1'
    $script:launcherGeneratorPath = Join-Path -Path $repoRoot -ChildPath `
        'tools\dev\New-ToggleLaunchers.ps1'
    $script:engineSource = Get-Content -LiteralPath $script:enginePath -Raw
    $script:brokerSource = Get-Content -LiteralPath $script:brokerPath -Raw
    $script:launcherGeneratorSource = Get-Content -LiteralPath $script:launcherGeneratorPath -Raw

    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:toggleRoot = Join-Path -Path $TestDrive -ChildPath 'Toggles'
    $toggleGroup = Join-Path -Path $script:toggleRoot -ChildPath 'Security'
    [void](New-Item -Path $toggleGroup -ItemType Directory -Force)
    $script:actionMarker = Join-Path -Path $TestDrive -ChildPath 'toggle-action-ran.txt'
    $escapedMarker = $script:actionMarker.Replace("'", "''")

    $definitionTemplate = @'
@{
    Name          = '__NAME__'
    Elevation     = '__ELEVATION__'
    NoStateRecord = $true
    States        = [ordered]@{
        Enable = @{
            StateValue = 1
            Reboot     = 'None'
            Action     = {
                param($Toggle)
                [IO.File]::WriteAllText('__MARKER__', 'ran')
            }
        }
    }
}
'@
    foreach ($definition in @(
            @{ Name = 'BrokerToggle'; Elevation = 'TrustedInstaller' }
            @{ Name = 'AdminToggle'; Elevation = 'Admin' }
            @{ Name = 'CaseShiftedElevation'; Elevation = 'trustedinstaller' }
        )) {
        $content = $definitionTemplate.Replace('__NAME__', $definition.Name).
            Replace('__ELEVATION__', $definition.Elevation).
            Replace('__MARKER__', $escapedMarker)
        Set-Content -LiteralPath (Join-Path -Path $toggleGroup -ChildPath "$($definition.Name).ps1") `
            -Encoding Ascii -Value $content
    }
}

AfterAll {
    Remove-Item -LiteralPath $script:actionMarker -Force -ErrorAction SilentlyContinue
}

Describe 'TrustedInstaller toggle broker boundary' {
    BeforeEach {
        Remove-Item -LiteralPath $script:actionMarker -Force -ErrorAction SilentlyContinue
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $true }
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject][ordered]@{
                status         = 'Completed'
                exitCodeUInt32 = [uint64]0
                error          = $null
            }
        }
    }

    It 'uses only the typed closed Toggle operation and never runs the action in the caller' {
        Invoke-AtlasToggle -Name BrokerToggle -State Enable -JustContext -NoExplorerRestart `
            -TogglesRoot $script:toggleRoot

        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter {
                $Operation -ceq 'Toggle' -and
                $Name -ceq 'BrokerToggle' -and
                $State -ceq 'Enable' -and
                $Silent -eq $true -and
                $JustContext -eq $true -and
                $NoExplorerRestart -eq $true
            }
        $script:actionMarker | Should -Not -Exist

        $script:engineSource | Should -Match 'Invoke-AtlasTrustedInstaller\s+`[\s\S]+?-Operation Toggle'
        $script:engineSource | Should -Not -Match 'Invoke-AtlasTrustedInstaller\s+-CommandLine'
        $script:engineSource | Should -Not -Match '(?m)^\s*\$commandLine\s*='
    }

    It 'rejects noncanonical toggle-name casing before privileged dispatch' {
        {
            Invoke-AtlasToggle -Name brokertoggle -State Enable -Silent `
                -TogglesRoot $script:toggleRoot
        } | Should -Throw '*No toggle definition named*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
        $script:engineSource | Should -Match 'Where-Object \{ \$_\.BaseName -ceq \$Name \}'
        $script:launcherGeneratorSource | Should -Match `
            '\$toggleName -cne \$definitionFile\.BaseName'
        $script:brokerSource | Should -Match `
            '\[string\]\$definition\.Name -cne \[string\]\$request\.operationData\.name'
    }

    It 'rejects noncanonical state casing before privileged dispatch' {
        {
            Invoke-AtlasToggle -Name BrokerToggle -State enable -Silent `
                -TogglesRoot $script:toggleRoot
        } | Should -Throw '*Unknown state*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
        $script:engineSource | Should -Match '\$validStates -cnotcontains \$State'
        $script:brokerSource | Should -Match `
            '@\(\$definition\.States\.Keys\) -cnotcontains \[string\]\$request\.operationData\.state'
    }

    It 'uses only ordinal comparisons at the TrustedInstaller routing decisions' {
        $script:engineSource | Should -Match '\$elevation -ceq ''TrustedInstaller'''
        $script:engineSource | Should -Not -Match '\$elevation -eq ''TrustedInstaller'''
        $script:engineSource | Should -Match `
            '-Name \(\[string\]\$definition\.Name\)'
    }

    It 'rejects case-shifted TrustedInstaller metadata before privileged dispatch' {
        {
            Invoke-AtlasToggle -Name CaseShiftedElevation -State Enable -Silent `
                -TogglesRoot $script:toggleRoot
        } | Should -Throw '*invalid Elevation*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
    }

    It 'refuses LocalSystem without strict TrustedInstaller evidence before broker dispatch' {
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Toggles -MockWith { $true }

        {
            Invoke-AtlasToggle -Name BrokerToggle -State Enable -Silent -TogglesRoot $script:toggleRoot
        } | Should -Throw '*LocalSystem without strict TrustedInstaller token evidence*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
    }

    It 'blocks a non-TrustedInstaller definition at the strict TrustedInstaller sink' {
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $true }

        {
            Invoke-AtlasToggle -Name AdminToggle -State Enable -Silent -TogglesRoot $script:toggleRoot
        } | Should -Throw '*does not declare exact TrustedInstaller elevation*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
    }

    It 'runs in process only when strict TrustedInstaller evidence succeeds' {
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $true }

        Invoke-AtlasToggle -Name BrokerToggle -State Enable -Silent -TogglesRoot $script:toggleRoot

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Exist
    }

    It 'refuses a silent TrustedInstaller request from a non-admin caller' {
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $false }

        {
            Invoke-AtlasToggle -Name BrokerToggle -State Enable -Silent -TogglesRoot $script:toggleRoot
        } | Should -Throw '*current process is not elevated*refusing to elevate in silent mode*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        $script:actionMarker | Should -Not -Exist
    }

    It 'fails closed on a non-completed structured broker result' {
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject][ordered]@{
                status         = 'ConsentDenied'
                exitCodeUInt32 = $null
                error          = 'The user declined TrustedInstaller elevation.'
            }
        }

        {
            Invoke-AtlasToggle -Name BrokerToggle -State Enable -TogglesRoot $script:toggleRoot
        } | Should -Throw '*status ''ConsentDenied''*declined TrustedInstaller elevation*'

        $script:actionMarker | Should -Not -Exist
    }

    It 'fails closed when the TrustedInstaller child reports a nonzero exit code' {
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject][ordered]@{
                status         = 'Completed'
                exitCodeUInt32 = [uint64]5
                error          = $null
            }
        }

        {
            Invoke-AtlasToggle -Name BrokerToggle -State Enable -TogglesRoot $script:toggleRoot
        } | Should -Throw '*exited with code 5*'

        $script:actionMarker | Should -Not -Exist
    }
}

Describe 'Closed ResetServices toggle-default boundary' {
    BeforeEach {
        InModuleScope Atlas.Toggles {
            $script:AtlasResetTestPlan = [ordered]@{
                Bluetooth                        = 'Enable'
                LanmanWorkstation                = 'Enable'
                NetworkDiscovery                 = 'Enable'
                NVidiaDisplayContainer           = 'Enable'
                NVidiaDisplayContainerContextMenu = 'Remove'
                Printing                         = 'Enable'
                SuperFetch                       = 'Enable'
            }
            $script:AtlasResetObserved = New-Object 'Collections.Generic.List[string]'

            Mock -CommandName Assert-AtlasPrivilege -MockWith {}
            Mock -CommandName Get-AtlasContext -MockWith {
                [pscustomobject]@{
                    AtlasModulesPath = 'C:\AtlasModules'
                    WinDir           = 'C:\Windows'
                    WindowsBuild     = 26100
                }
            }
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem -MockWith {
                @($script:AtlasResetTestPlan.Keys | ForEach-Object {
                    [pscustomobject]@{
                        BaseName = [string]$_
                        Name     = "$_.ps1"
                    }
                })
            }
            Mock -CommandName Get-AtlasToggleDefinition -MockWith {
                $stateName = [string]$script:AtlasResetTestPlan[$Name]
                $states = [ordered]@{}
                $states[$stateName] = @{
                    StateValue = 1
                    Launcher   = "$Name $stateName (default).cmd"
                    Reboot     = 'None'
                    Action     = {}
                }
                return @{
                    Name      = $Name
                    Elevation = 'Admin'
                    States    = $states
                }
            }
            Mock -CommandName Invoke-AtlasToggle -MockWith {
                throw 'The public typed Toggle boundary must not run during ResetServices.'
            }
            Mock -CommandName Invoke-AtlasToggleInProcess -MockWith {
                [void]$script:AtlasResetObserved.Add(
                    "$($Definition.Name):${StateName}:$([bool]$Silent):" +
                    "$([bool]$NoExplorerRestart):$([bool]$ResetServices)"
                )
            }
        }
    }

    AfterEach {
        InModuleScope Atlas.Toggles {
            Remove-Variable -Name AtlasResetTestPlan -Scope Script -ErrorAction SilentlyContinue
            Remove-Variable -Name AtlasResetObserved -Scope Script -ErrorAction SilentlyContinue
        }
    }

    It 'keeps the reset entry private, parameterless, and outside public Toggle parameters' {
        Get-Command -Name Invoke-AtlasServiceDefaultsReset -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty

        $tokens = $null
        $parseErrors = $null
        $engineAst = [Management.Automation.Language.Parser]::ParseFile(
            $script:enginePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $parseErrors.Count | Should -Be 0
        $resetFunction = $engineAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasServiceDefaultsReset'
            }, $true)
        $resetFunction | Should -Not -BeNullOrEmpty
        @($resetFunction.Body.ParamBlock.Parameters).Count | Should -Be 0

        $publicParameters = (Get-Command Invoke-AtlasToggle).Parameters.Keys
        foreach ($forbidden in @('ResetServices', 'SkipElevation', 'Definition', 'DefinitionName')) {
            $publicParameters | Should -Not -Contain $forbidden
        }
    }

    It 'executes the exact fixed plan in order through only the private core' {
        $observed = InModuleScope Atlas.Toggles {
            Invoke-AtlasServiceDefaultsReset
            return @($script:AtlasResetObserved)
        }

        $observed | Should -Be @(
            'Bluetooth:Enable:True:True:True'
            'LanmanWorkstation:Enable:True:True:True'
            'NetworkDiscovery:Enable:True:True:True'
            'NVidiaDisplayContainer:Enable:True:True:True'
            'NVidiaDisplayContainerContextMenu:Remove:True:True:True'
            'Printing:Enable:True:True:True'
            'SuperFetch:Enable:True:True:True'
        )
        Should -Invoke -CommandName Assert-AtlasPrivilege -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter { $TrustedInstaller }
        Should -Invoke -CommandName Invoke-AtlasToggleInProcess -ModuleName Atlas.Toggles `
            -Times 7 -Exactly
        Should -Not -Invoke -CommandName Invoke-AtlasToggle -ModuleName Atlas.Toggles
    }

    It 'stops on the first failure and never reaches the NetworkDiscovery dependency skip' {
        InModuleScope Atlas.Toggles {
            Mock -CommandName Invoke-AtlasToggleInProcess -MockWith {
                [void]$script:AtlasResetObserved.Add([string]$Definition.Name)
                if ([string]$Definition.Name -ceq 'LanmanWorkstation') {
                    throw 'simulated Lanman reset failure'
                }
            }

            { Invoke-AtlasServiceDefaultsReset } |
                Should -Throw '*simulated Lanman reset failure*'
            @($script:AtlasResetObserved) | Should -Be @('Bluetooth', 'LanmanWorkstation')
        }
        Should -Not -Invoke -CommandName Invoke-AtlasToggle -ModuleName Atlas.Toggles
    }
}
