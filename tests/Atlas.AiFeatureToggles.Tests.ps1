BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $modulesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force
    # The companions resolve these commands after Import-AtlasModule (mocked below); load
    # the real modules once so the mocks have a command to shadow inside Atlas.Toggles.
    Import-Module (Join-Path $modulesRoot 'Atlas.Appx\Atlas.Appx.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Download\Atlas.Download.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $togglesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Toggles'
    $script:copilot = Get-AtlasToggleDefinition -Name Copilot -TogglesRoot $togglesRoot
    $script:widgets = Get-AtlasToggleDefinition -Name Widgets -TogglesRoot $togglesRoot

    # Companions reach Operations scripts through $Toggle.OperationsPath only.
    $script:operationsPath = Join-Path $TestDrive 'Operations'
    New-Item -Path $script:operationsPath -ItemType Directory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $script:operationsPath 'Remove-Edge.ps1') -Value '' -Encoding Ascii

    $script:fakeWinget = Join-Path $TestDrive 'winget.exe'
    Set-Content -LiteralPath $script:fakeWinget -Value '' -Encoding Ascii

    # Builds the $Toggle context the engine hands to a companion function.
    function New-ToggleContext {
        param(
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $true)][string]$State,
            [bool]$Silent = $true
        )

        return [pscustomobject]@{
            Name              = $Name
            State             = $State
            StateValue        = $null
            Silent            = $Silent
            JustContext       = $false
            NoExplorerRestart = $false
            ResetServices     = $false
            StateRoot         = 'HKCU:\Software\AtlasRewriteTest\Services'
            LauncherPath      = $null
            WinDir            = $env:SystemRoot
            AtlasModulesPath  = $TestDrive
            ScriptsPath       = (Join-Path $TestDrive 'Scripts')
            ModulesPath       = (Join-Path $TestDrive 'Scripts\Modules')
            OperationsPath    = $script:operationsPath
            WindowsBuild      = 26100
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

    function Find-RegistryEntry {
        param(
            [Parameter(Mandatory = $true)]$State,
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name
        )

        # The comma keeps a single matching hashtable wrapped as an array.
        return , @($State['Registry'] | Where-Object { $_.Path -ceq $Path -and $_.Name -ceq $Name })
    }
}

Describe 'Copilot toggle' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Invoke-AtlasAppxRemovalPlan -ModuleName Atlas.Toggles
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Get-ItemPropertyValue -ModuleName Atlas.Toggles
        Mock Get-AtlasTrustedWingetPath -ModuleName Atlas.Toggles { $script:fakeWinget }
        Mock Assert-AtlasTrustedWingetSource -ModuleName Atlas.Toggles
        $script:appInstalled = $false
        Mock Get-AppxPackage -ModuleName Atlas.Toggles { if ($script:appInstalled) { [pscustomobject]@{ Status = 'Ok' } } }
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles { $script:appInstalled = $true }
    }

    It 'declares the disable state as machine policy, per-user taskbar value and app removal' {
        $disable = $script:copilot.States['Disable']

        $policy = @(Find-RegistryEntry -State $disable `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'RemoveMicrosoftCopilotApp')
        $policy.Count | Should -Be 1
        $policy[0].Type | Should -BeExactly 'DWord'
        $policy[0].Data | Should -Be 1

        $button = @(Find-RegistryEntry -State $disable `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton')
        $button.Count | Should -Be 1
        $button[0].Type | Should -BeExactly 'DWord'
        $button[0].Data | Should -Be 0

        $disable['MachineAction'] | Should -BeExactly 'Remove-AtlasCopilotApp'
        $disable.Contains('UserAction') | Should -BeFalse
        $disable['StateValue'] | Should -Be 0

        $work = Get-AtlasToggleStateWork -Definition $script:copilot -StateEntry $disable
        $work.Machine | Should -BeTrue
        $work.User | Should -BeTrue
        $work.Local | Should -BeFalse
    }

    It 'removes only the Copilot app in the machine action and leaves registry work to the declarations' {
        $context = New-ToggleContext -Name 'Copilot' -State 'Disable'

        Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Remove-AtlasCopilotApp' -Toggle $context

        Should -Invoke Import-AtlasModule -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Appx' }
        Should -Invoke Invoke-AtlasAppxRemovalPlan -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Definition.Count -eq 1 -and
                $Definition[0].Name -ceq 'Microsoft.Copilot*' -and
                -not $Definition[0].IgnoreErrors
        }
        Should -Not -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Should -Not -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
    }

    It 'splits the enable state into a machine action and a user action' {
        $enable = $script:copilot.States['Enable']

        $enable['MachineAction'] | Should -BeExactly 'Enable-AtlasCopilotMachine'
        $enable['UserAction'] | Should -BeExactly 'Enable-AtlasCopilotUser'
        $enable['StateValue'] | Should -Be 1
        $script:copilot.Functions | Should -Contain 'Enable-AtlasCopilotMachine'
        $script:copilot.Functions | Should -Contain 'Enable-AtlasCopilotUser'

        $work = Get-AtlasToggleStateWork -Definition $script:copilot -StateEntry $enable
        $work.Machine | Should -BeTrue
        $work.User | Should -BeTrue
    }

    It 're-shows the taskbar button only on a legacy build with an affirmative marker' {
        Mock Get-ItemPropertyValue -ModuleName Atlas.Toggles { 1 }
        $context = New-ToggleContext -Name 'Copilot' -State 'Enable'
        $context.WindowsBuild = 22631

        Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Enable-AtlasCopilotUser' -Toggle $context

        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -and
                $Name -ceq 'ShowCopilotButton' -and $Type -ceq 'DWord' -and $Data -eq 1
        }
        Should -Not -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles
        Should -Not -Invoke Get-AtlasTrustedWingetPath -ModuleName Atlas.Toggles
    }

    It 'installs the Store app only through the trusted msstore source' {
        Mock Get-ItemPropertyValue -ModuleName Atlas.Toggles { 0 }
        $context = New-ToggleContext -Name 'Copilot' -State 'Enable'

        Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Enable-AtlasCopilotUser' -Toggle $context

        Should -Invoke Import-AtlasModule -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Download' }
        Should -Invoke Assert-AtlasTrustedWingetSource -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $WingetPath -ceq $script:fakeWinget -and $Name -ceq 'msstore'
        }
        Should -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $FilePath -ceq $script:fakeWinget -and
                ($ArgumentList -join '|') -ceq
                    'install|--exact|--id|9NHT9RB2F4HD|--source|msstore|--uninstall-previous|--silent|--accept-source-agreements|--accept-package-agreements|--disable-interactivity' -and
                $AllowedExitCodes.Count -eq 1 -and $AllowedExitCodes[0] -eq 0
        }
        Should -Not -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Should -Not -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
    }

    It 'checks the app when the legacy marker is absent' {
        $context = New-ToggleContext -Name 'Copilot' -State 'Enable'
        Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Enable-AtlasCopilotUser' -Toggle $context
        Should -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles -Times 1 -Exactly
    }

    It 'does not accept a successful installer exit without a healthy app' {
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles {}
        $context = New-ToggleContext -Name 'Copilot' -State 'Enable'
        { Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Enable-AtlasCopilotUser' -Toggle $context } | Should -Throw '*healthy*'
    }

    It 'leaves an already healthy app installed without running winget' {
        $script:appInstalled = $true
        $context = New-ToggleContext -Name 'Copilot' -State 'Enable'
        Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Enable-AtlasCopilotUser' -Toggle $context
        Should -Not -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles
    }

    It 'propagates Store installation failure without applying a partial user state' {
        Mock Get-ItemPropertyValue -ModuleName Atlas.Toggles { 0 }
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles { throw 'simulated winget failure' }
        $context = New-ToggleContext -Name 'Copilot' -State 'Enable'

        { Invoke-CompanionFunction -Definition $script:copilot -FunctionName 'Enable-AtlasCopilotUser' -Toggle $context } |
            Should -Throw '*simulated winget failure*'

        Should -Not -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Should -Not -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "*Copilot*Enable-AtlasCopilotUser*simulated winget failure*"
        }
    }
}

Describe 'Widgets toggle' {
    BeforeEach {
        Mock Set-AtlasMachineDwordPolicy -ModuleName Atlas.Toggles
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }
        Mock Start-Process -ModuleName Atlas.Toggles
    }

    It 'declares the disable state as the widget machine policies without any function' {
        $disable = $script:widgets.States['Disable']

        $feeds = @($disable['Registry'] | Where-Object { $_.Name -eq 'EnableFeeds' })
        $feeds.Count | Should -Be 0

        $dsh = @(Find-RegistryEntry -State $disable `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests')
        $dsh.Count | Should -Be 1
        $dsh[0].Type | Should -BeExactly 'DWord'
        $dsh[0].Data | Should -Be 0
        $dsh[0].UseGroupPolicy | Should -BeTrue

        foreach ($valueName in 'DisableWidgetsOnLockScreen', 'DisableWidgetsBoard') {
            $board = @(Find-RegistryEntry -State $disable `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name $valueName)
            $board.Count | Should -Be 1
            $board[0].Data | Should -Be 1
        }

        # The stable policy is persisted through Group Policy and verified. Newer
        # optional policies retain their separate protected-value handling.
        @($disable['Registry'] | Where-Object { $_['AllowOsProtected'] }).Count | Should -Be 2

        @($disable['Registry']).Count | Should -Be 3
        $disable.Contains('MachineAction') | Should -BeFalse
        $disable.Contains('UserAction') | Should -BeFalse

        $work = Get-AtlasToggleStateWork -Definition $script:widgets -StateEntry $disable
        $work.Machine | Should -BeTrue
        $work.User | Should -BeFalse
    }

    It 'enables Widgets through local policy and removes the supplemental restrictions' {
        $script:widgets.States['Enable']['MachineAction'] | Should -BeExactly 'Enable-AtlasWidgetsMachine'
        $context = New-ToggleContext -Name 'Widgets' -State 'Enable' -Silent $true

        Invoke-CompanionFunction -Definition $script:widgets -FunctionName 'Enable-AtlasWidgetsMachine' -Toggle $context

        Should -Invoke Set-AtlasMachineDwordPolicy -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -and
                $Name -ceq 'AllowNewsAndInterests' -and $Data -eq 1
        }
        foreach ($valueName in 'DisableWidgetsOnLockScreen', 'DisableWidgetsBoard') {
            Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                $Path -ceq 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -and $Name -ceq $valueName
            }
        }
        Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 2 -Exactly -ParameterFilter {
            $AllowOsProtected
        }
        Should -Not -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Toggles
        Should -Not -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles
        Should -Not -Invoke Start-Process -ModuleName Atlas.Toggles
    }

    It 'uses the bundled helper and inbox Windows PowerShell in interactive mode' {
        $context = New-ToggleContext -Name 'Widgets' -State 'Enable' -Silent $false
        $expectedPowerShell = [IO.Path]::Combine(
            $env:SystemRoot,
            'System32\WindowsPowerShell\v1.0\powershell.exe'
        )
        $expectedHelper = Join-Path $script:operationsPath 'Remove-Edge.ps1'

        Invoke-CompanionFunction -Definition $script:widgets -FunctionName 'Enable-AtlasWidgetsMachine' -Toggle $context

        Should -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $FilePath -ceq $expectedPowerShell -and
                $ArgumentList -contains '-InstallWebView' -and
                $ArgumentList[([array]::IndexOf($ArgumentList, '-File') + 1)] -ceq $expectedHelper -and
                $AllowedExitCodes.Count -eq 1 -and $AllowedExitCodes[0] -eq 0
        }
        Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles -Times 2 -Exactly
        Should -Not -Invoke Start-Process -ModuleName Atlas.Toggles
    }

    It 'leaves the policies untouched when the Edge helper fails' {
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles { throw 'simulated Edge helper failure' }
        $context = New-ToggleContext -Name 'Widgets' -State 'Enable' -Silent $false

        { Invoke-CompanionFunction -Definition $script:widgets -FunctionName 'Enable-AtlasWidgetsMachine' -Toggle $context } |
            Should -Throw '*simulated Edge helper failure*'

        Should -Not -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Toggles
        Should -Not -Invoke Set-AtlasMachineDwordPolicy -ModuleName Atlas.Toggles
        Should -Not -Invoke Start-Process -ModuleName Atlas.Toggles
    }
}
