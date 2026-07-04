BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $modulesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Scripts\Modules'

    Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:StateRoot = 'HKCU:\Software\AtlasRewriteTest\Services'

    function New-TestToggleDefinition {
        param(
            [Parameter(Mandatory = $true)][string]$Root,
            [Parameter(Mandatory = $true)][string]$Group,
            [Parameter(Mandatory = $true)][string]$FileName,
            [Parameter(Mandatory = $true)][string]$Content
        )

        $groupDirectory = Join-Path $Root $Group
        New-Item -Path $groupDirectory -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $groupDirectory $FileName) -Value $Content -Encoding Ascii
    }
}

AfterAll {
    # Only remove the Services subtree; other test files share the AtlasRewriteTest root.
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest\Services' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Get-AtlasToggleDefinition' {
    BeforeAll {
        $script:TogglesRoot = Join-Path $TestDrive 'Toggles'

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'GoodToggle.ps1' -Content @'
@{
    Name      = 'GoodToggle'
    Elevation = 'None'
    States    = [ordered]@{
        On  = @{ StateValue = 1; Action = { param($Toggle) } }
        Off = @{ StateValue = 0; Action = { param($Toggle) } }
    }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'NoName.ps1' -Content @'
@{
    States = @{ On = @{ StateValue = 1; Action = { param($Toggle) } } }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'NoStates.ps1' -Content @'
@{
    Name = 'NoStates'
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'NoAction.ps1' -Content @'
@{
    Name   = 'NoAction'
    States = @{ On = @{ StateValue = 1 } }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'NoStateValue.ps1' -Content @'
@{
    Name   = 'NoStateValue'
    States = @{ On = @{ Action = { param($Toggle) } } }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'WrongName.ps1' -Content @'
@{
    Name   = 'SomethingElse'
    States = @{ On = @{ StateValue = 1; Action = { param($Toggle) } } }
}
'@
    }

    It 'loads and validates a well-formed definition' {
        $definition = Get-AtlasToggleDefinition -Name 'GoodToggle' -TogglesRoot $TogglesRoot
        $definition.Name | Should -Be 'GoodToggle'
        @($definition.States.Keys) | Should -Be @('On', 'Off')
        $definition.States['On'].Action | Should -BeOfType [scriptblock]
    }

    It 'throws when no definition with the given name exists' {
        { Get-AtlasToggleDefinition -Name 'DoesNotExist' -TogglesRoot $TogglesRoot } |
            Should -Throw "*No toggle definition named 'DoesNotExist'*"
    }

    It 'throws when the definition is missing Name' {
        { Get-AtlasToggleDefinition -Name 'NoName' -TogglesRoot $TogglesRoot } |
            Should -Throw "*missing the required 'Name' key*"
    }

    It 'throws when the definition is missing States' {
        { Get-AtlasToggleDefinition -Name 'NoStates' -TogglesRoot $TogglesRoot } |
            Should -Throw "*missing a non-empty 'States' hashtable*"
    }

    It 'throws when a state has no Action scriptblock' {
        { Get-AtlasToggleDefinition -Name 'NoAction' -TogglesRoot $TogglesRoot } |
            Should -Throw "*missing an 'Action' scriptblock*"
    }

    It 'throws when a state has no StateValue and no NoStateRecord' {
        { Get-AtlasToggleDefinition -Name 'NoStateValue' -TogglesRoot $TogglesRoot } |
            Should -Throw "*missing 'StateValue'*"
    }

    It 'throws when the declared Name does not match the file name' {
        { Get-AtlasToggleDefinition -Name 'WrongName' -TogglesRoot $TogglesRoot } |
            Should -Throw "*declares Name 'SomethingElse'*"
    }
}

Describe 'Set-AtlasToggleState / Get-AtlasToggleState' {
    It 'records state and launcher path under the state root' {
        Set-AtlasToggleState -Name 'TestSetting' -State 1 -LauncherPath 'C:\Fake\Launcher.cmd' -StateRoot $StateRoot

        $recorded = Get-AtlasToggleState -Name 'TestSetting' -StateRoot $StateRoot
        $recorded.State | Should -Be 1
        $recorded.Path | Should -Be 'C:\Fake\Launcher.cmd'
    }

    It 'writes state as REG_DWORD and path as REG_SZ (schema contract)' {
        Set-AtlasToggleState -Name 'KindCheck' -State 2 -LauncherPath 'C:\Fake\Kind.cmd' -StateRoot $StateRoot

        $key = Get-Item -LiteralPath (Join-Path $StateRoot 'KindCheck')
        $key.GetValueKind('state') | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
        $key.GetValueKind('path') | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
    }

    It 'overwrites an existing recorded state' {
        Set-AtlasToggleState -Name 'TestSetting' -State 0 -LauncherPath 'C:\Fake\Other.cmd' -StateRoot $StateRoot

        $recorded = Get-AtlasToggleState -Name 'TestSetting' -StateRoot $StateRoot
        $recorded.State | Should -Be 0
        $recorded.Path | Should -Be 'C:\Fake\Other.cmd'
    }

    It 'returns $null for a toggle that was never recorded' {
        Get-AtlasToggleState -Name 'NeverRecorded' -StateRoot $StateRoot | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-AtlasToggleReapply' {
    BeforeEach {
        Remove-Item -Path $StateRoot -Recurse -Force -ErrorAction SilentlyContinue

        $script:ReapplyTogglesRoot = Join-Path $TestDrive 'ReapplyToggles'
        Remove-Item -Path $script:ReapplyTogglesRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:ReapplyTogglesRoot -ItemType Directory -Force | Out-Null

        # A launcher that records that it ran, so tests can assert replay vs skip.
        $script:ReapplyMarker = Join-Path $TestDrive 'reapply-marker.txt'
        Remove-Item -Path $script:ReapplyMarker -Force -ErrorAction SilentlyContinue
        $script:ReapplyLauncher = Join-Path $TestDrive 'ReapplyLauncher.ps1'
        Set-Content -Path $script:ReapplyLauncher -Value "param([switch]`$Silent)`nSet-Content -Path '$script:ReapplyMarker' -Value 'ran'" -Encoding Ascii
    }

    It 'replays a recorded non-zero state through its launcher' {
        Set-AtlasToggleState -Name 'ReplayToggle' -State 1 -LauncherPath $script:ReapplyLauncher -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $StateRoot 'ReplayToggle') | Should -BeTrue
    }

    It 'does not replay state 0' {
        Set-AtlasToggleState -Name 'ReplayToggle' -State 0 -LauncherPath $script:ReapplyLauncher -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeFalse
    }

    It 'cleans up a record whose launcher no longer exists' {
        Set-AtlasToggleState -Name 'GhostToggle' -State 1 -LauncherPath (Join-Path $TestDrive 'gone.cmd') -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath (Join-Path $StateRoot 'GhostToggle') | Should -BeFalse
    }

    It 'cleans up and never replays a record for a NoStateRecord toggle (stale SafeMode hazard)' {
        # Regression: a stale recorded state (e.g. SafeMode = 3 from an older Atlas)
        # must not be re-applied on upgrade - the machine would boot into safe mode.
        New-TestToggleDefinition -Root $script:ReapplyTogglesRoot -Group 'TestGroup' -FileName 'NoRecordToggle.ps1' -Content @'
@{
    Name          = 'NoRecordToggle'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Enter = @{ StateValue = 3; Action = { param($Toggle) } }
        Exit  = @{ StateValue = 0; Action = { param($Toggle) } }
    }
}
'@

        Set-AtlasToggleState -Name 'NoRecordToggle' -State 3 -LauncherPath $script:ReapplyLauncher -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $StateRoot 'NoRecordToggle') | Should -BeFalse
    }
}

Describe 'Invoke-AtlasToggle' {
    BeforeAll {
        $script:TogglesRoot = Join-Path $TestDrive 'Toggles'
        $script:WorkDir = Join-Path $TestDrive 'Work'
        New-Item -Path $WorkDir -ItemType Directory -Force | Out-Null
        $env:AtlasToggleTestDir = $WorkDir

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'MarkerToggle.ps1' -Content @'
@{
    Name      = 'MarkerToggle'
    Elevation = 'None'
    States    = [ordered]@{
        On = @{
            StateValue    = 1
            Reboot        = 'None'
            ContextAction = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'context-marker.txt') -Value $Toggle.State
            }
            Action        = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'action-marker.txt') -Value "$($Toggle.Name):$($Toggle.State):$($Toggle.StateValue)"
            }
        }
        Off = @{
            StateValue = 0
            Reboot     = 'None'
            Action     = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'off-marker.txt') -Value $Toggle.State
            }
        }
    }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'MenuToggle.ps1' -Content @'
@{
    Name          = 'MenuToggle'
    Elevation     = 'None'
    Menu          = $true
    SilentDefault = 'Enable'
    States        = [ordered]@{
        Disable = @{
            StateValue = 0
            Action     = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'menu-marker.txt') -Value 'Disable'
            }
        }
        Enable  = @{
            StateValue = 1
            Action     = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'menu-marker.txt') -Value 'Enable'
            }
        }
    }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'NoRecordToggle.ps1' -Content @'
@{
    Name          = 'NoRecordToggle'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Action = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'norecord-marker.txt') -Value 'ran'
            }
        }
    }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'FailingToggle.ps1' -Content @'
@{
    Name      = 'FailingToggle'
    Elevation = 'None'
    States    = [ordered]@{
        On = @{
            StateValue = 1
            Reboot     = 'None'
            Action     = {
                param($Toggle)
                throw 'deliberate failure'
            }
        }
    }
}
'@

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'AdminToggle.ps1' -Content @'
@{
    Name      = 'AdminToggle'
    Elevation = 'Admin'
    States    = [ordered]@{
        On = @{
            StateValue = 1
            Reboot     = 'None'
            Action     = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'admin-marker.txt') -Value 'ran'
            }
        }
    }
}
'@
    }

    AfterAll {
        Remove-Item Env:\AtlasToggleTestDir -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Get-ChildItem -Path $WorkDir -Filter '*.txt' | Remove-Item -Force
        Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest\Services' -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'runs the action and records state and launcher path (happy path, silent)' {
        $launcher = Join-Path $WorkDir 'fake-launcher.cmd'
        Invoke-AtlasToggle -Name 'MarkerToggle' -State 'On' -LauncherPath $launcher -Silent `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        Join-Path $WorkDir 'action-marker.txt' | Should -Exist
        (Get-Content (Join-Path $WorkDir 'action-marker.txt')) | Should -Be 'MarkerToggle:On:1'

        $recorded = Get-AtlasToggleState -Name 'MarkerToggle' -StateRoot $StateRoot
        $recorded.State | Should -Be 1
        $recorded.Path | Should -Be $launcher
    }

    It 'does not record state when the action fails (upgrade re-apply must not replay a lie)' {
        # Recording before/despite a failed action would leave a record that
        # Invoke-AtlasToggleReapply replays on the next upgrade.
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        Invoke-AtlasToggle -Name 'FailingToggle' -State 'On' -Silent `
            -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        Get-AtlasToggleState -Name 'FailingToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -ParameterFilter { $Message -like '*state was not recorded because its action failed*' }
    }

    It 'refuses an Admin toggle in silent mode when not elevated' {
        Mock Test-AtlasAdmin { $false } -ModuleName Atlas.Toggles

        { Invoke-AtlasToggle -Name 'AdminToggle' -State 'On' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot } |
            Should -Throw '*requires Administrator rights*'
        Join-Path $WorkDir 'admin-marker.txt' | Should -Not -Exist
    }

    It 'runs an Admin toggle unelevated without recording state under ATLAS_USER_CONTEXT (first-logon re-apply)' {
        # Initialize-NewUser.ps1 re-applies HKCU-only toggles as the new, non-elevated
        # user; the engine must run the action in-process and skip the HKLM state record.
        Mock Test-AtlasAdmin { $false } -ModuleName Atlas.Toggles

        $env:ATLAS_USER_CONTEXT = '1'
        try {
            Invoke-AtlasToggle -Name 'AdminToggle' -State 'On' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot
        }
        finally {
            Remove-Item Env:\ATLAS_USER_CONTEXT -ErrorAction SilentlyContinue
        }

        Join-Path $WorkDir 'admin-marker.txt' | Should -Exist
        Get-AtlasToggleState -Name 'AdminToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
    }

    It 'runs ContextAction before Action and stops after it with -JustContext' {
        Invoke-AtlasToggle -Name 'MarkerToggle' -State 'On' -Silent -JustContext `
            -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        Join-Path $WorkDir 'context-marker.txt' | Should -Exist
        Join-Path $WorkDir 'action-marker.txt' | Should -Not -Exist
    }

    It 'still records state with -JustContext (batch parity)' {
        Invoke-AtlasToggle -Name 'MarkerToggle' -State 'On' -Silent -JustContext `
            -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        (Get-AtlasToggleState -Name 'MarkerToggle' -StateRoot $StateRoot).State | Should -Be 1
    }

    It 'throws on an unknown state' {
        { Invoke-AtlasToggle -Name 'MarkerToggle' -State 'Bogus' -Silent `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot } |
            Should -Throw "*Unknown state 'Bogus'*"
    }

    It 'throws when -State is omitted for a non-menu toggle' {
        { Invoke-AtlasToggle -Name 'MarkerToggle' -Silent `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot } |
            Should -Throw '*without a -State*'
    }

    It 'does not record state for NoStateRecord definitions' {
        Invoke-AtlasToggle -Name 'NoRecordToggle' -State 'Run' -Silent `
            -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        Join-Path $WorkDir 'norecord-marker.txt' | Should -Exist
        Get-AtlasToggleState -Name 'NoRecordToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
    }

    Context 'Menu definitions (non-interactive resolution)' {
        It 'accepts an explicit -State without showing the menu' {
            Invoke-AtlasToggle -Name 'MenuToggle' -State 'Disable' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot

            (Get-Content (Join-Path $WorkDir 'menu-marker.txt')) | Should -Be 'Disable'
            (Get-AtlasToggleState -Name 'MenuToggle' -StateRoot $StateRoot).State | Should -Be 0
        }

        It 'silently re-applies the recorded state when -State is omitted' {
            Set-AtlasToggleState -Name 'MenuToggle' -State 0 -LauncherPath 'C:\Fake\Menu.cmd' -StateRoot $StateRoot

            Invoke-AtlasToggle -Name 'MenuToggle' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot

            (Get-Content (Join-Path $WorkDir 'menu-marker.txt')) | Should -Be 'Disable'
        }

        It 'falls back to SilentDefault when nothing is recorded' {
            Invoke-AtlasToggle -Name 'MenuToggle' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot

            (Get-Content (Join-Path $WorkDir 'menu-marker.txt')) | Should -Be 'Enable'
        }
    }
}

Describe 'New-ToggleLaunchers.ps1' {
    BeforeAll {
        $script:GeneratorScript = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'tools\dev\New-ToggleLaunchers.ps1'
    }

    It 'validates cleanly against the committed repo tree' {
        $output = & $GeneratorScript -Validate 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }
}
