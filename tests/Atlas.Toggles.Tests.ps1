BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:repoRoot = $script:AtlasTestRepoRoot
    $modulesRoot = $script:AtlasTestModulesRoot

    Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    $script:ToolsHost = $script:AtlasTestToolsHost

    $script:StateRoot = 'HKCU:\Software\AtlasRewriteTest\Services'
    $script:ShippedTogglesRoot = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Toggles'

    # Writes a definition (and optional companion) into a scratch toggles tree.
    function New-TestToggle {
        param(
            [Parameter(Mandatory = $true)][string]$Root,
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $true)][string]$Definition,
            [string]$Companion,
            [string]$Group = 'TestGroup'
        )

        $groupDirectory = Join-Path $Root $Group
        New-Item -Path $groupDirectory -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $groupDirectory "$Name.psd1"), $Definition, [Text.UTF8Encoding]::new($false))
        if ($PSBoundParameters.ContainsKey('Companion')) {
            [IO.File]::WriteAllText((Join-Path $groupDirectory "$Name.ps1"), $Companion, [Text.UTF8Encoding]::new($false))
        }
    }

    # Companion functions record what ran through marker files under $env:AtlasToggleTestDir.
    $script:MarkerCompanion = @'
function Write-AtlasTestMarker {
    param([string]$Name, [string]$Value)
    [IO.File]::WriteAllText((Join-Path $env:AtlasToggleTestDir "$Name.txt"), $Value)
}

function Invoke-AtlasTestContext {
    param($Toggle)
    Write-AtlasTestMarker -Name 'context' -Value $Toggle.State
}

function Invoke-AtlasTestLocal {
    param($Toggle)
    Write-AtlasTestMarker -Name 'local' -Value "$($Toggle.Name):$($Toggle.State):$($Toggle.StateValue)"
}

function Invoke-AtlasTestMachine {
    param($Toggle)
    Write-AtlasTestMarker -Name 'machine' -Value "$($Toggle.Name):$($Toggle.State):$($Toggle.StateValue):silent=$($Toggle.Silent)"
}

function Invoke-AtlasTestUser {
    param($Toggle)
    Write-AtlasTestMarker -Name 'user' -Value "$($Toggle.Name):$($Toggle.State)"
}

function Invoke-AtlasTestFailure {
    param($Toggle)
    throw 'deliberate failure'
}

function Invoke-AtlasTestPowerShellError {
    param($Toggle)
    Write-Error 'ordinary action error'
}

function Invoke-AtlasTestIgnoredError {
    param($Toggle)
    Write-Error 'intentionally ignored' -ErrorAction Ignore
    Write-AtlasTestMarker -Name 'ignored-error' -Value 'continued'
}

function Invoke-AtlasTestContextFailure {
    param($Toggle)
    throw 'deliberate context failure'
}

function Test-AtlasTestReplayApplicable {
    param($Toggle)
    return [bool]$env:AtlasToggleTestReplayApplicable
}
'@
}

AfterAll {
    # Only remove the Services subtree; other test files share the AtlasRewriteTest root.
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest\Services' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Toggle definition loading and validation' {
    BeforeAll {
        $script:TogglesRoot = Join-Path $TestDrive 'Toggles'

        New-TestToggle -Root $TogglesRoot -Name 'GoodToggle' -Definition @'
@{
    Name      = 'GoodToggle'
    Elevation = 'Admin'
    Script    = 'GoodToggle.ps1'
    States    = @(
        @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasTestMachine'; UserAction = 'Invoke-AtlasTestUser' }
        @{ Name = 'Off'; StateValue = 0; Launcher = 'A\Off.cmd'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\AtlasRewriteTest'; Name = 'x'; Type = 'DWord'; Data = 0 } ) }
    )
}
'@ -Companion $script:MarkerCompanion

        New-TestToggle -Root $TogglesRoot -Name 'ScriptBlockToggle' -Definition @'
@{
    Name      = 'ScriptBlockToggle'
    Elevation = 'None'
    States    = @( @{ Name = 'On'; Launcher = 'A\On.cmd'; Action = { param($Toggle) } } )
}
'@
        New-TestToggle -Root $TogglesRoot -Name 'MissingFunction' -Definition @'
@{
    Name      = 'MissingFunction'
    Elevation = 'Admin'
    Script    = 'MissingFunction.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasNotDefined' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $TogglesRoot -Name 'SideEffectCompanion' -Definition @'
@{
    Name      = 'SideEffectCompanion'
    Elevation = 'Admin'
    Script    = 'SideEffectCompanion.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasTestMachine' } )
}
'@ -Companion ("Set-Content -Path (Join-Path `$env:TEMP 'atlas-side-effect.txt') -Value 'ran'`n" + $script:MarkerCompanion)
        New-TestToggle -Root $TogglesRoot -Name 'ElevatedAction' -Definition @'
@{
    Name      = 'ElevatedAction'
    Elevation = 'Admin'
    Script    = 'ElevatedAction.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Action = 'Invoke-AtlasTestLocal' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $TogglesRoot -Name 'UnelevatedMachine' -Definition @'
@{
    Name          = 'UnelevatedMachine'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = @( @{ Name = 'On'; Launcher = 'A\On.cmd'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\X'; Name = 'y'; Type = 'DWord'; Data = 1 } ) } )
}
'@
        New-TestToggle -Root $TogglesRoot -Name 'UnelevatedRecord' -Definition @'
@{
    Name      = 'UnelevatedRecord'
    Elevation = 'None'
    Script    = 'UnelevatedRecord.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Action = 'Invoke-AtlasTestLocal' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $TogglesRoot -Name 'UserPolicy' -Definition @'
@{
    Name      = 'UserPolicy'
    Elevation = 'Admin'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Registry = @( @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\X'; Name = 'y'; Type = 'DWord'; Data = 1 } ) } )
}
'@
        New-TestToggle -Root $TogglesRoot -Name 'DuplicateValue' -Definition @'
@{
    Name      = 'DuplicateValue'
    Elevation = 'Admin'
    States    = @(
        @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\X'; Name = 'y'; Type = 'DWord'; Data = 1 } ) }
        @{ Name = 'Off'; StateValue = 1; Launcher = 'A\Off.cmd'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\X'; Name = 'y'; Type = 'DWord'; Data = 0 } ) }
    )
}
'@
        New-TestToggle -Root $TogglesRoot -Name 'WrongName' -Definition @'
@{
    Name      = 'SomethingElse'
    Elevation = 'Admin'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\X'; Name = 'y'; Type = 'DWord'; Data = 1 } ) } )
}
'@
        New-TestToggle -Root $TogglesRoot -Name 'UnknownKey' -Definition @'
@{
    Name      = 'UnknownKey'
    Elevation = 'Admin'
    Sideload  = $true
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\X'; Name = 'y'; Type = 'DWord'; Data = 1 } ) } )
}
'@
    }

    It 'loads a well-formed definition as an ordered state dictionary with its companion functions' {
        $definition = Get-AtlasToggleDefinition -Name 'GoodToggle' -TogglesRoot $TogglesRoot

        $definition.Name | Should -Be 'GoodToggle'
        @($definition.States.Keys) | Should -Be @('On', 'Off')
        $definition.States['On']['StateValue'] | Should -Be 1
        $definition.ScriptPath | Should -Be (Join-Path $TogglesRoot 'TestGroup\GoodToggle.ps1')
        $definition.Functions | Should -Contain 'Invoke-AtlasTestMachine'
    }

    It 'classifies machine and user work from the declarations' {
        $definition = Get-AtlasToggleDefinition -Name 'GoodToggle' -TogglesRoot $TogglesRoot

        $on = Get-AtlasToggleStateWork -Definition $definition -StateEntry $definition.States['On']
        $on.Machine | Should -BeTrue
        $on.User | Should -BeTrue
        $on.Local | Should -BeFalse

        $off = Get-AtlasToggleStateWork -Definition $definition -StateEntry $definition.States['Off']
        $off.Machine | Should -BeTrue
        $off.User | Should -BeFalse
    }

    It 'never executes definition code: a scriptblock in a data file is rejected' {
        { Get-AtlasToggleDefinition -Name 'ScriptBlockToggle' -TogglesRoot $TogglesRoot } | Should -Throw
    }

    It 'rejects a definition that names a function its companion does not define' {
        { Get-AtlasToggleDefinition -Name 'MissingFunction' -TogglesRoot $TogglesRoot } |
            Should -Throw "*Invoke-AtlasNotDefined*does not define*"
    }

    It 'rejects a companion with top-level statements without running them' {
        Remove-Item -LiteralPath (Join-Path $env:TEMP 'atlas-side-effect.txt') -Force -ErrorAction SilentlyContinue

        { Get-AtlasToggleDefinition -Name 'SideEffectCompanion' -TogglesRoot $TogglesRoot } |
            Should -Throw '*must contain only function definitions*'
        Join-Path $env:TEMP 'atlas-side-effect.txt' | Should -Not -Exist
    }

    It 'rejects the shape problems the schema forbids' -TestCases @(
        @{ Name = 'ElevatedAction'; Message = "*declares 'Action'; elevated toggles*" }
        @{ Name = 'UnelevatedMachine'; Message = '*machine registry paths without elevation*' }
        @{ Name = 'UnelevatedRecord'; Message = '*declare NoStateRecord*' }
        @{ Name = 'UserPolicy'; Message = '*protected HKCU policy path*' }
        @{ Name = 'DuplicateValue'; Message = '*reuses StateValue*' }
        @{ Name = 'WrongName'; Message = "*declares Name 'SomethingElse'*" }
        @{ Name = 'UnknownKey'; Message = "*unknown top-level key 'Sideload'*" }
    ) {
        { Get-AtlasToggleDefinition -Name $Name -TogglesRoot $TogglesRoot } | Should -Throw $Message
    }

    It 'throws when no definition with the given name exists' {
        { Get-AtlasToggleDefinition -Name 'Missing' -TogglesRoot $TogglesRoot } |
            Should -Throw "*No toggle definition named 'Missing'*"
    }

    It 'reports every problem of a tree through Test-AtlasToggleDefinition' {
        $problems = @(Test-AtlasToggleDefinition -Path $TogglesRoot)

        @($problems | Where-Object { $_.Path -like '*GoodToggle.psd1' }).Count | Should -Be 0
        @($problems | Where-Object { $_.Path -like '*UnknownKey.psd1' }).Count | Should -Be 1
        @($problems | Where-Object { $_.Path -like '*DuplicateValue.psd1' }).Count | Should -Be 1
    }
}

Describe 'Shipped toggle definitions' {
    It 'all validate without running any toggle code' {
        $problems = @(Test-AtlasToggleDefinition -Path $script:ShippedTogglesRoot)
        ($problems | ForEach-Object { "$($_.Path): $($_.Problem)" }) -join "`n" | Should -BeNullOrEmpty
    }

    It 'contain no scriptblocks and no HKCU policy writes' {
        foreach ($file in Get-ChildItem -LiteralPath $script:ShippedTogglesRoot -Recurse -File -Filter '*.psd1') {
            $data = Import-AtlasDataFile -LiteralPath $file.FullName
            foreach ($state in @($data.States)) {
                if (-not $state.ContainsKey('Registry')) {
                    continue
                }
                foreach ($entry in @($state['Registry'])) {
                    [string]$entry['Path'] | Should -Not -Match '(?i)^HKCU.*\\Policies' -Because $file.Name
                }
            }
        }
    }

    It 'declare exactly the closed service-defaults set with one (default) state each' {
        InModuleScope Atlas.Toggles {
            $servicesRoot = Join-Path $ShippedTogglesRoot 'Services'
            $expected = @($script:AtlasServiceDefaultResetStates.Keys | ForEach-Object { [string]$_ })
            @(Get-ChildItem -LiteralPath $servicesRoot -File -Filter '*.psd1' | Sort-Object Name | ForEach-Object { $_.BaseName }) |
                Should -Be @($expected | Sort-Object)

            foreach ($name in $expected) {
                $definition = Get-AtlasToggleDefinition -Name $name -TogglesRoot $servicesRoot
                (Get-AtlasToggleElevation -Definition $definition) | Should -Be 'Admin'
                $defaults = @($definition.States.Keys | Where-Object {
                        [string]$definition.States[$_]['Launcher'] -like '*(default)*'
                    })
                $defaults | Should -Be @([string]$script:AtlasServiceDefaultResetStates[$name])
            }
        } -Parameters @{ ShippedTogglesRoot = $script:ShippedTogglesRoot }
    }
}

Describe 'Set-AtlasToggleState / Get-AtlasToggleState' {
    It 'records only the declarative state under the state root' {
        Set-AtlasToggleState -Name 'TestSetting' -State 1 -LauncherPath 'C:\Fake\Launcher.cmd' -StateRoot $StateRoot

        $recorded = Get-AtlasToggleState -Name 'TestSetting' -StateRoot $StateRoot
        $recorded.State | Should -Be 1
        $recorded.PSObject.Properties.Name | Should -Not -Contain 'Path'
    }

    It 'writes state as REG_DWORD and never persists the legacy launcher path' {
        Set-AtlasToggleState -Name 'KindCheck' -State 2 -LauncherPath 'C:\Fake\Kind.cmd' -StateRoot $StateRoot

        $key = Get-Item -LiteralPath (Join-Path $StateRoot 'KindCheck')
        $key.GetValueKind('state') | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
        @($key.GetValueNames()) | Should -Not -Contain 'path'
    }

    It 'overwrites state and scrubs a legacy raw path from an existing record' {
        $keyPath = Join-Path $StateRoot 'TestSetting'
        New-Item -Path $keyPath -Force | Out-Null
        New-ItemProperty -LiteralPath $keyPath -Name 'path' -Value 'C:\Attacker\payload.ps1' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $keyPath -Name 'days' -Value 14 -PropertyType DWord -Force | Out-Null

        Set-AtlasToggleState -Name 'TestSetting' -State 0 -LauncherPath 'C:\Fake\Other.cmd' -StateRoot $StateRoot

        $recorded = Get-AtlasToggleState -Name 'TestSetting' -StateRoot $StateRoot
        $recorded.State | Should -Be 0
        @(Get-Item -LiteralPath $keyPath).GetValueNames() | Should -Not -Contain 'path'
        (Get-ItemProperty -LiteralPath $keyPath -Name 'days').days | Should -Be 14
    }

    It 'returns $null for a toggle that was never recorded' {
        Get-AtlasToggleState -Name 'NeverRecorded' -StateRoot $StateRoot | Should -BeNullOrEmpty
    }
}

Describe 'Initialize-AtlasToggleStateStore' {
    It 'removes legacy executable paths while preserving non-replay product metadata' {
        $keyPath = Join-Path $StateRoot 'PauseUpdates'
        New-Item -Path $keyPath -Force | Out-Null
        New-ItemProperty -LiteralPath $keyPath -Name 'state' -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -LiteralPath $keyPath -Name 'path' -Value 'C:\Attacker\payload.ps1' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $keyPath -Name 'days' -Value 356000 -PropertyType DWord -Force | Out-Null

        Initialize-AtlasToggleStateStore -StateRoot $StateRoot

        $key = Get-Item -LiteralPath $keyPath
        @($key.GetValueNames()) | Should -Not -Contain 'path'
        (Get-ItemProperty -LiteralPath $keyPath -Name 'days').days | Should -Be 356000
    }

}

Describe 'Atlas toggle production state ACL' {
    It 'uses a protected DACL with writes limited to privileged Windows principals' {
        InModuleScope Atlas.Toggles {
            $acl = New-AtlasToggleStateAcl
            $acl.AreAccessRulesProtected | Should -BeTrue
            $acl.GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'

            $rules = @($acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier]))
            $fullControlSids = @($rules | Where-Object {
                    ($_.RegistryRights -band [System.Security.AccessControl.RegistryRights]::FullControl) -eq
                    [System.Security.AccessControl.RegistryRights]::FullControl
                } | ForEach-Object { $_.IdentityReference.Value })

            $fullControlSids | Should -Contain 'S-1-5-18'
            $fullControlSids | Should -Contain 'S-1-5-32-544'
            $fullControlSids | Should -Contain 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
            $fullControlSids | Should -Not -Contain 'S-1-5-32-545'

            $usersRule = @($rules | Where-Object { $_.IdentityReference.Value -eq 'S-1-5-32-545' })
            $usersRule.Count | Should -Be 1
            $usersRule[0].RegistryRights | Should -Be ([System.Security.AccessControl.RegistryRights]::ReadKey)
        }
    }

    It 'protects the production root before migrating its existing children' {
        InModuleScope Atlas.Toggles {
            $productionRoot = 'HKLM:\SOFTWARE\AtlasOS\Services'
            $childPath = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\Services\Example'
            $script:aclTargets = @()

            Mock Test-Path { $true }
            Mock Get-ChildItem { @([pscustomobject]@{ PSPath = $childPath }) }
            Mock Set-Acl { $script:aclTargets += $LiteralPath }

            Protect-AtlasToggleStateRoot -StateRoot $productionRoot -IncludeChildren

            $script:aclTargets | Should -Be @($productionRoot, $childPath)
        }
    }
}

Describe 'Replay of recorded states' {
    BeforeAll {
        $script:ReplayRoot = Join-Path $TestDrive 'ReplayToggles'
        $script:ReplayWork = Join-Path $TestDrive 'ReplayWork'
        New-Item -Path $script:ReplayWork -ItemType Directory -Force | Out-Null

        New-TestToggle -Root $script:ReplayRoot -Name 'SplitToggle' -Definition @'
@{
    Name      = 'SplitToggle'
    Elevation = 'Admin'
    Script    = 'SplitToggle.ps1'
    States    = @(
        @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasTestMachine'; UserAction = 'Invoke-AtlasTestUser' }
        @{ Name = 'Off'; StateValue = 0; Launcher = 'A\Off.cmd'; MachineAction = 'Invoke-AtlasTestMachine'; UserAction = 'Invoke-AtlasTestUser' }
    )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:ReplayRoot -Name 'UserOnlyToggle' -Definition @'
@{
    Name      = 'UserOnlyToggle'
    Elevation = 'Admin'
    Script    = 'UserOnlyToggle.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; UserAction = 'Invoke-AtlasTestUser' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:ReplayRoot -Name 'ApplicableToggle' -Definition @'
@{
    Name      = 'ApplicableToggle'
    Elevation = 'Admin'
    Script    = 'ApplicableToggle.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasTestMachine'; ReplayApplicable = 'Test-AtlasTestReplayApplicable' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:ReplayRoot -Name 'NoRecordToggle' -Definition @'
@{
    Name          = 'NoRecordToggle'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'NoRecordToggle.ps1'
    States        = @( @{ Name = 'Run'; Launcher = 'A\Run.cmd'; MachineAction = 'Invoke-AtlasTestMachine' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:ReplayRoot -Name 'FailingToggle' -Definition @'
@{
    Name      = 'FailingToggle'
    Elevation = 'Admin'
    Script    = 'FailingToggle.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasTestFailure' } )
}
'@ -Companion $script:MarkerCompanion
    }

    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Toggles
        Mock Invoke-AtlasRegistryEntries -ModuleName Atlas.Toggles
        Remove-Item -Path $StateRoot -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path $script:ReplayWork -Filter '*.txt' | Remove-Item -Force
        $env:AtlasToggleTestDir = $script:ReplayWork
        $env:AtlasToggleTestReplayApplicable = '1'
    }

    AfterAll {
        Remove-Item Env:\AtlasToggleTestDir -ErrorAction SilentlyContinue
        Remove-Item Env:\AtlasToggleTestReplayApplicable -ErrorAction SilentlyContinue
    }

    It 'replays only the machine part of a recorded state, silently, and keeps the record' {
        Set-AtlasToggleState -Name 'SplitToggle' -State 0 -StateRoot $StateRoot
        $recordPath = Join-Path $StateRoot 'SplitToggle'
        New-ItemProperty -LiteralPath $recordPath -Name 'path' -Value 'C:\Attacker\payload.ps1' -PropertyType String -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        Get-Content (Join-Path $script:ReplayWork 'machine.txt') | Should -Be 'SplitToggle:Off:0:silent=True'
        Join-Path $script:ReplayWork 'user.txt' | Should -Not -Exist
        @((Get-Item -LiteralPath $recordPath).GetValueNames()) | Should -Not -Contain 'path'
        (Get-AtlasToggleState -Name 'SplitToggle' -StateRoot $StateRoot).State | Should -Be 0
    }

    It 'leaves a record that has only user work for first sign-in replay' {
        Set-AtlasToggleState -Name 'UserOnlyToggle' -State 1 -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        Join-Path $script:ReplayWork 'user.txt' | Should -Not -Exist
        (Get-AtlasToggleState -Name 'UserOnlyToggle' -StateRoot $StateRoot).State | Should -Be 1
    }

    It 'removes a recorded state whose ReplayApplicable check fails without running it' {
        Set-AtlasToggleState -Name 'ApplicableToggle' -State 1 -StateRoot $StateRoot
        $env:AtlasToggleTestReplayApplicable = ''

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        Join-Path $script:ReplayWork 'machine.txt' | Should -Not -Exist
        Test-Path -LiteralPath (Join-Path $StateRoot 'ApplicableToggle') | Should -BeFalse
    }

    It 'scrubs stale records: no definition, NoStateRecord, unknown value, wrong value kind' {
        Set-AtlasToggleState -Name 'Vanished' -State 1 -StateRoot $StateRoot
        Set-AtlasToggleState -Name 'NoRecordToggle' -State 1 -StateRoot $StateRoot
        Set-AtlasToggleState -Name 'SplitToggle' -State 9 -StateRoot $StateRoot
        $wrongKind = Join-Path $StateRoot 'ApplicableToggle'
        New-Item -Path $wrongKind -Force | Out-Null
        New-ItemProperty -LiteralPath $wrongKind -Name 'state' -Value '1' -PropertyType String -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        foreach ($name in 'Vanished', 'NoRecordToggle', 'SplitToggle', 'ApplicableToggle') {
            Test-Path -LiteralPath (Join-Path $StateRoot $name) | Should -BeFalse -Because $name
        }
        Join-Path $script:ReplayWork 'machine.txt' | Should -Not -Exist
    }

    It 'preserves metadata-only keys without warning or replay in either scope' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $false }
        $metadataPath = Join-Path $StateRoot 'PowerSaving'
        $previousScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
        New-Item -Path $metadataPath -Force | Out-Null
        New-ItemProperty -LiteralPath $metadataPath -Name PreviousPowerSchemeGuid `
            -Value $previousScheme -PropertyType String -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot
        Invoke-AtlasToggleUserReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        (Get-ItemProperty -LiteralPath $metadataPath).PreviousPowerSchemeGuid | Should -Be $previousScheme
        (Get-AtlasToggleState -Name PowerSaving -StateRoot $StateRoot).State | Should -BeNullOrEmpty
        Join-Path $script:ReplayWork 'machine.txt' | Should -Not -Exist
        Join-Path $script:ReplayWork 'user.txt' | Should -Not -Exist
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 0 -Exactly -ParameterFilter { $Level -eq 'Warning' }
    }

    It 'removes stale replay values without deleting unrelated metadata or child keys' {
        Set-AtlasToggleState -Name 'SplitToggle' -State 9 -StateRoot $StateRoot
        $recordPath = Join-Path $StateRoot 'SplitToggle'
        New-ItemProperty -LiteralPath $recordPath -Name PreviousPowerSchemeGuid `
            -Value '381b4222-f694-41f0-9685-ff5bb260df2e' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $recordPath -Name path -Value 'C:\Old\Launcher.cmd' -PropertyType String -Force | Out-Null
        New-Item -Path (Join-Path $recordPath 'Metadata') -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        $key = Get-Item -LiteralPath $recordPath
        @($key.GetValueNames()) | Should -Be @('PreviousPowerSchemeGuid')
        $key.GetValue('PreviousPowerSchemeGuid') | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
        Test-Path -LiteralPath (Join-Path $recordPath 'Metadata') | Should -BeTrue
        Join-Path $script:ReplayWork 'machine.txt' | Should -Not -Exist
    }

    It 'continues past a failing replay, preserves its record, then throws one aggregate' {
        Set-AtlasToggleState -Name 'FailingToggle' -State 1 -StateRoot $StateRoot
        Set-AtlasToggleState -Name 'SplitToggle' -State 1 -StateRoot $StateRoot

        { Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot } |
            Should -Throw '*failed for 1 toggle(s)*FailingToggle*deliberate failure*'

        (Get-AtlasToggleState -Name 'FailingToggle' -StateRoot $StateRoot).State | Should -Be 1
        Get-Content (Join-Path $script:ReplayWork 'machine.txt') | Should -Be 'SplitToggle:On:1:silent=True'
    }

    It 'asserts strict TrustedInstaller before touching the replay tree' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Toggles { throw '[privilege] TrustedInstaller required' }

        { Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot } |
            Should -Throw '*TrustedInstaller required*'
    }

    It 'replays only the user part of recorded states for the non-elevated account' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $false }
        Set-AtlasToggleState -Name 'SplitToggle' -State 1 -StateRoot $StateRoot
        Set-AtlasToggleState -Name 'ApplicableToggle' -State 1 -StateRoot $StateRoot

        Invoke-AtlasToggleUserReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot

        Get-Content (Join-Path $script:ReplayWork 'user.txt') | Should -Be 'SplitToggle:On'
        Join-Path $script:ReplayWork 'machine.txt' | Should -Not -Exist
    }

    It 'refuses per-user replay from an elevated process' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }

        { Invoke-AtlasToggleUserReapply -StateRoot $StateRoot -TogglesRoot $script:ReplayRoot } |
            Should -Throw '*non-elevated*'
    }
}

Describe 'Invoke-AtlasToggle' {
    BeforeAll {
        $script:TogglesRoot = Join-Path $TestDrive 'EngineToggles'
        $script:WorkDir = Join-Path $TestDrive 'EngineWork'
        New-Item -Path $script:WorkDir -ItemType Directory -Force | Out-Null
        function script:Get-Marker {
            param([string]$Name)
            $path = Join-Path $script:WorkDir "$Name.txt"
            if (Test-Path -LiteralPath $path) { return [IO.File]::ReadAllText($path) }
            return $null
        }

        New-TestToggle -Root $script:TogglesRoot -Name 'LocalToggle' -Definition @'
@{
    Name          = 'LocalToggle'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'LocalToggle.ps1'
    States        = @(
        @{ Name = 'On'; Launcher = 'A\On.cmd'; Reboot = 'None'; ContextAction = 'Invoke-AtlasTestContext'; Action = 'Invoke-AtlasTestLocal' }
        @{ Name = 'Failing'; Launcher = 'A\Failing.cmd'; Reboot = 'None'; Action = 'Invoke-AtlasTestFailure' }
        @{ Name = 'PowerShellError'; Launcher = 'A\PowerShellError.cmd'; Reboot = 'None'; Action = 'Invoke-AtlasTestPowerShellError' }
        @{ Name = 'IgnoredError'; Launcher = 'A\IgnoredError.cmd'; Reboot = 'None'; Action = 'Invoke-AtlasTestIgnoredError' }
        @{ Name = 'ContextFailure'; Launcher = 'A\ContextFailure.cmd'; Reboot = 'None'; ContextAction = 'Invoke-AtlasTestContextFailure'; Action = 'Invoke-AtlasTestLocal' }
    )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:TogglesRoot -Name 'MachineToggle' -Definition @'
@{
    Name      = 'MachineToggle'
    Elevation = 'Admin'
    Script    = 'MachineToggle.ps1'
    States    = @(
        @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Reboot = 'None'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\AtlasRewriteTest'; Name = 'on'; Type = 'DWord'; Data = 1 } ); Services = @( @{ Name = 'FakeSvc'; StartupType = 4 } ); MachineAction = 'Invoke-AtlasTestMachine' }
        @{ Name = 'Failing'; StateValue = 2; Launcher = 'A\Failing.cmd'; Reboot = 'None'; MachineAction = 'Invoke-AtlasTestFailure' }
    )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:TogglesRoot -Name 'SplitToggle' -Definition @'
@{
    Name      = 'SplitToggle'
    Elevation = 'Admin'
    Script    = 'SplitToggle.ps1'
    States    = @(
        @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Reboot = 'None'; Registry = @( @{ Path = 'HKLM:\SOFTWARE\AtlasRewriteTest'; Name = 'm'; Type = 'DWord'; Data = 1 }; @{ Path = 'HKCU:\Software\AtlasRewriteTest\ToggleUser'; Name = 'u'; Type = 'DWord'; Data = 1 } ); MachineAction = 'Invoke-AtlasTestMachine'; UserAction = 'Invoke-AtlasTestUser' }
    )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:TogglesRoot -Name 'UserOnlyToggle' -Definition @'
@{
    Name      = 'UserOnlyToggle'
    Elevation = 'Admin'
    Script    = 'UserOnlyToggle.ps1'
    States    = @(
        @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; Reboot = 'None'; UserAction = 'Invoke-AtlasTestUser' }
        @{ Name = 'Failing'; StateValue = 2; Launcher = 'A\Failing.cmd'; Reboot = 'None'; UserAction = 'Invoke-AtlasTestFailure' }
    )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:TogglesRoot -Name 'BrokerToggle' -Definition @'
@{
    Name          = 'BrokerToggle'
    Elevation     = 'TrustedInstaller'
    Warning       = 'Confirm privileged action.'
    NoStateRecord = $true
    Script        = 'BrokerToggle.ps1'
    States        = @( @{ Name = 'Run'; Launcher = 'A\Run.cmd'; Reboot = 'Recommend'; MachineAction = 'Invoke-AtlasTestMachine' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:TogglesRoot -Name 'MenuToggle' -Definition @'
@{
    Name          = 'MenuToggle'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = 'A\Menu.cmd'
    SilentDefault = 'Enable'
    Script        = 'MenuToggle.ps1'
    States        = @(
        @{ Name = 'Disable'; StateValue = 0; MenuLabel = 'Disable it'; Reboot = 'None'; MachineAction = 'Invoke-AtlasTestMachine' }
        @{ Name = 'Enable'; StateValue = 1; MenuLabel = 'Enable it'; Reboot = 'None'; MachineAction = 'Invoke-AtlasTestMachine' }
    )
}
'@ -Companion $script:MarkerCompanion
    }

    AfterAll {
        Remove-Item Env:\AtlasToggleTestDir -ErrorAction SilentlyContinue
        Remove-Item Env:\ATLAS_USER_CONTEXT -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $env:AtlasToggleTestDir = $script:WorkDir
        Remove-Item Env:\ATLAS_USER_CONTEXT -ErrorAction SilentlyContinue
        Get-ChildItem -Path $script:WorkDir -Filter '*.txt' | Remove-Item -Force
        Remove-Item -Path $StateRoot -Recurse -Force -ErrorAction SilentlyContinue
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Write-AtlasTitle -ModuleName Atlas.Toggles
        Mock Wait-AtlasContinue -ModuleName Atlas.Toggles
        Mock Wait-AtlasExit -ModuleName Atlas.Toggles
        Mock Write-AtlasCompletion -ModuleName Atlas.Toggles
        Mock Invoke-AtlasRegistryEntries -ModuleName Atlas.Toggles
        Mock Invoke-AtlasServiceEntries -ModuleName Atlas.Toggles
        Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $false }
        $script:launcher = Join-Path $script:WorkDir 'fake-launcher.cmd'
    }

    Context 'unelevated (Elevation None) toggles' {
        It 'runs ContextAction then Action in-process and records nothing' {
            Invoke-AtlasToggle -Name 'LocalToggle' -State 'On' -Silent -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'context' | Should -Be 'On'
            Get-Marker 'local' | Should -Be 'LocalToggle:On:'
            Get-AtlasToggleState -Name 'LocalToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
            Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -ParameterFilter { $Message -like "*LocalToggle*applied local state 'On'*" }
        }

        It 'stops after ContextAction with -JustContext' {
            Invoke-AtlasToggle -Name 'LocalToggle' -State 'On' -Silent -JustContext -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'context' | Should -Be 'On'
            Get-Marker 'local' | Should -BeNullOrEmpty
        }

        It 'propagates failures and logs them' -TestCases @(
            @{ State = 'Failing'; Message = '*deliberate failure*'; Label = 'action' }
            @{ State = 'PowerShellError'; Message = '*ordinary action error*'; Label = 'action' }
            @{ State = 'ContextFailure'; Message = '*deliberate context failure*'; Label = 'context action' }
        ) {
            { Invoke-AtlasToggle -Name 'LocalToggle' -State $State -Silent -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw $Message

            Get-Marker 'local' | Should -BeNullOrEmpty
            Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like "*Toggle 'LocalToggle' $Label*failed*"
            }
        }

        It 'honors an explicit error override inside a companion function' {
            Invoke-AtlasToggle -Name 'LocalToggle' -State 'IgnoredError' -Silent -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'ignored-error' | Should -Be 'continued'
        }

        It 'throws on an unknown state and on a missing state for a non-menu toggle' {
            { Invoke-AtlasToggle -Name 'LocalToggle' -State 'Bogus' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } |
                Should -Throw "*Unknown state 'Bogus'*"
            { Invoke-AtlasToggle -Name 'LocalToggle' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } |
                Should -Throw '*without a -State*'
        }
    }

    Context 'machine-only elevated toggles' {
        It 'applies registry, services and the machine function in order, then records the state' {
            Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }
            $script:order = @()
            Mock Invoke-AtlasRegistryEntries -ModuleName Atlas.Toggles { $script:order += "registry:${Scope}:$($Entries.Count)" }
            Mock Invoke-AtlasServiceEntries -ModuleName Atlas.Toggles { $script:order += "services:$($Entries[0].Name)" }

            Invoke-AtlasToggle -Name 'MachineToggle' -State 'On' -Silent -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            $script:order | Should -Be @('registry:Machine:1', 'services:FakeSvc')
            Get-Marker 'machine' | Should -Be 'MachineToggle:On:1:silent=True'
            (Get-AtlasToggleState -Name 'MachineToggle' -StateRoot $StateRoot).State | Should -Be 1
        }

        It 'does not record a state whose machine function failed' {
            Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }

            { Invoke-AtlasToggle -Name 'MachineToggle' -State 'Failing' -Silent -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*deliberate failure*'

            Get-AtlasToggleState -Name 'MachineToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        }

        It 'refuses to prompt for elevation in silent mode' {
            { Invoke-AtlasToggle -Name 'MachineToggle' -State 'On' -Silent -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*requires Administrator rights*'
            Get-Marker 'machine' | Should -BeNullOrEmpty
        }

        It 'relaunches through UAC when interactive and unelevated, without running the work locally' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles

            Invoke-AtlasToggle -Name 'MachineToggle' -State 'On' -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Should -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'MachineToggle' -and ($ArgumentList -join ' ') -like '*-State "On"*' -and ($ArgumentList -join ' ') -notlike '*-MachineOnly*'
            }
            Get-Marker 'machine' | Should -BeNullOrEmpty
        }

        It 'preserves the elevated child exit code for the CLI boundary' {
            Mock Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles { [pscustomobject]@{ ExitCode = 5 } }

            $failure = $null
            try {
                Invoke-AtlasToggle -Name 'MachineToggle' -State 'On' -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot
            }
            catch {
                $failure = $_.Exception
            }

            $failure | Should -Not -BeNullOrEmpty
            $failure.Data['Atlas.Toggle.AdminChildExitCode'] | Should -Be 5
        }

        It 'replays nothing at first sign-in because it has no per-user work' {
            $env:ATLAS_USER_CONTEXT = '1'

            Invoke-AtlasToggle -Name 'MachineToggle' -State 'On' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'machine' | Should -BeNullOrEmpty
            Get-AtlasToggleState -Name 'MachineToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        }

        Context 'menu resolution' {
            BeforeEach { Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true } }

            It 'accepts an explicit -State without showing the menu' {
                Invoke-AtlasToggle -Name 'MenuToggle' -State 'Disable' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot
                Get-Marker 'machine' | Should -Be 'MenuToggle:Disable:0:silent=True'
            }

            It 'silently re-applies the recorded state when -State is omitted' {
                Set-AtlasToggleState -Name 'MenuToggle' -State 0 -StateRoot $StateRoot
                Invoke-AtlasToggle -Name 'MenuToggle' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot
                Get-Marker 'machine' | Should -Be 'MenuToggle:Disable:0:silent=True'
            }

            It 'falls back to SilentDefault when nothing is recorded' {
                Invoke-AtlasToggle -Name 'MenuToggle' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot
                Get-Marker 'machine' | Should -Be 'MenuToggle:Enable:1:silent=True'
            }
        }
    }

    Context 'toggles with machine and user work' {
        BeforeEach {
            Mock Get-AtlasToggleUserCallerBinding -ModuleName Atlas.Toggles { [pscustomobject]@{ Sid = 'S-1-5-21-1-2-3-1001'; SessionId = 1 } }
        }

        It 'does not dispatch a state record when a user-only action fails' {
            Set-AtlasToggleState -Name 'UserOnlyToggle' -State 0 -StateRoot $StateRoot
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles
            Mock Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles

            { Invoke-AtlasToggle -Name 'UserOnlyToggle' -State 'Failing' -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*deliberate failure*'

            Should -Not -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles
            Should -Not -Invoke Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles
            (Get-AtlasToggleState -Name 'UserOnlyToggle' -StateRoot $StateRoot).State | Should -Be 0
        }

        It 'finishes user-only work before its existing privileged recording child and final follow-up' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles {
                [IO.File]::ReadAllText((Join-Path $env:AtlasToggleTestDir 'user.txt')) | Should -Be 'UserOnlyToggle:On'
                [IO.File]::WriteAllText((Join-Path $env:AtlasToggleTestDir 'record-dispatched.txt'), 'yes')
            }
            Mock Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles {
                Test-Path -LiteralPath (Join-Path $env:AtlasToggleTestDir 'record-dispatched.txt') | Should -BeTrue
            }

            Invoke-AtlasToggle -Name 'UserOnlyToggle' -State 'On' -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Should -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles -Times 1 -Exactly
            Should -Invoke Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles -Times 1 -Exactly
            Get-Marker 'user' | Should -Be 'UserOnlyToggle:On'
        }

        It 'defers only completion for a nested user choice while retaining its recording child' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles {
                [IO.File]::ReadAllText((Join-Path $env:AtlasToggleTestDir 'user.txt')) | Should -Be 'UserOnlyToggle:On'
            }
            Mock Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles

            Invoke-AtlasToggle -Name 'UserOnlyToggle' -State 'On' -DeferPostAction `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Should -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles -Times 1 -Exactly
            Should -Not -Invoke Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles
            Get-Marker 'user' | Should -Be 'UserOnlyToggle:On'
        }

        It 'does not swallow a nested choice recording failure' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles { throw 'recording cancelled' }
            { Invoke-AtlasToggle -Name 'UserOnlyToggle' -State 'On' -DeferPostAction `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*recording cancelled*'
        }

        It 'rejects deferred completion for machine work before dispatching it' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles
            { Invoke-AtlasToggle -Name 'SplitToggle' -State 'On' -DeferPostAction `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*user-only choice*'
            Should -Not -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles
            Get-Marker 'user' | Should -BeNullOrEmpty
        }

        It 'does not run the final follow-up if recording a successful user-only action fails' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles { throw 'recording cancelled' }
            Mock Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles

            { Invoke-AtlasToggle -Name 'UserOnlyToggle' -State 'On' -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*recording cancelled*'

            Get-Marker 'user' | Should -Be 'UserOnlyToggle:On'
            Should -Not -Invoke Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles
        }

        It 'preserves interactive prerequisites in the Administrator child, then runs user work locally' {
            $script:scopes = @()
            Mock Invoke-AtlasRegistryEntries -ModuleName Atlas.Toggles { $script:scopes += $Scope }
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles

            Invoke-AtlasToggle -Name 'SplitToggle' -State 'On' -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Should -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                ($ArgumentList -join ' ') -like '*-MachineOnly*' -and ($ArgumentList -join ' ') -notlike '*/silent*'
            }
            Get-Marker 'machine' | Should -BeNullOrEmpty
            Get-Marker 'user' | Should -Be 'SplitToggle:On'
            $script:scopes | Should -Be @('CurrentUser')
            Get-AtlasToggleState -Name 'SplitToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        }

        It 'as the interactive -MachineOnly child applies and records only the machine part without a final pause' {
            Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }
            $script:scopes = @()
            Mock Invoke-AtlasRegistryEntries -ModuleName Atlas.Toggles { $script:scopes += $Scope }

            Invoke-AtlasToggle -Name 'SplitToggle' -State 'On' -MachineOnly -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'machine' | Should -Be 'SplitToggle:On:1:silent=False'
            Get-Marker 'user' | Should -BeNullOrEmpty
            $script:scopes | Should -Be @('Machine')
            (Get-AtlasToggleState -Name 'SplitToggle' -StateRoot $StateRoot).State | Should -Be 1
            Should -Invoke Wait-AtlasExit -ModuleName Atlas.Toggles -Times 0 -Exactly
            Should -Invoke Write-AtlasCompletion -ModuleName Atlas.Toggles -Times 0 -Exactly
        }

        It 'refuses to start from an elevated process so user work cannot inherit the token' {
            Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }

            { Invoke-AtlasToggle -Name 'SplitToggle' -State 'On' -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*non-elevated user process*'
        }

        It 'refuses the caller when its identity changes across the privileged child' {
            Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles
            $script:bindingCalls = 0
            Mock Get-AtlasToggleUserCallerBinding -ModuleName Atlas.Toggles {
                $script:bindingCalls++
                [pscustomobject]@{ Sid = "S-1-5-21-1-2-3-100$script:bindingCalls"; SessionId = 1 }
            }

            { Invoke-AtlasToggle -Name 'SplitToggle' -State 'On' -LauncherPath $script:launcher `
                    -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } | Should -Throw '*identity or Windows session changed*'
            Get-Marker 'user' | Should -BeNullOrEmpty
        }

        It 'replays only the user part at first sign-in without recording' {
            $env:ATLAS_USER_CONTEXT = '1'
            $script:scopes = @()
            Mock Invoke-AtlasRegistryEntries -ModuleName Atlas.Toggles { $script:scopes += $Scope }

            Invoke-AtlasToggle -Name 'SplitToggle' -State 'On' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'user' | Should -Be 'SplitToggle:On'
            Get-Marker 'machine' | Should -BeNullOrEmpty
            $script:scopes | Should -Be @('CurrentUser')
            Get-AtlasToggleState -Name 'SplitToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        }
    }

    Context 'TrustedInstaller toggles' {
        BeforeEach {
            Mock Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles { [pscustomobject]@{ ExitCode = 0 } }
        }

        It 'routes an Administrator caller through the typed broker only, confirming first' {
            Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }

            Invoke-AtlasToggle -Name 'BrokerToggle' -State 'Run' -NoExplorerRestart -LauncherPath $script:launcher `
                -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Should -Invoke Wait-AtlasContinue -ModuleName Atlas.Toggles -Times 1 -Exactly
            Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
                $Operation -eq 'Toggle' -and $Name -eq 'BrokerToggle' -and $State -eq 'Run' -and $Silent -eq $true
            }
            Get-Marker 'machine' | Should -BeNullOrEmpty
        }

        It 'runs in-process only with strict TrustedInstaller evidence' {
            Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles { $true }

            Invoke-AtlasToggle -Name 'BrokerToggle' -State 'Run' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot

            Get-Marker 'machine' | Should -Be 'BrokerToggle:Run::silent=True'
            Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 0
        }

        It 'rejects LocalSystem without TrustedInstaller evidence' {
            Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $true }

            { Invoke-AtlasToggle -Name 'BrokerToggle' -State 'Run' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } |
                Should -Throw '*LocalSystem without strict TrustedInstaller*'
        }

        It 'rejects a non-TrustedInstaller definition inside a TrustedInstaller process' {
            Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles { $true }

            { Invoke-AtlasToggle -Name 'MachineToggle' -State 'On' -Silent -TogglesRoot $script:TogglesRoot -StateRoot $StateRoot } |
                Should -Throw '*does not declare exact TrustedInstaller elevation*'
        }
    }
}

Describe 'Invoke-AtlasToggleMachineState' {
    BeforeAll {
        $script:DependencyRoot = Join-Path $TestDrive 'DependencyToggles'
        $script:DependencyWork = Join-Path $TestDrive 'DependencyWork'
        New-Item -Path $script:DependencyWork -ItemType Directory -Force | Out-Null
        New-TestToggle -Root $script:DependencyRoot -Name 'Dependency' -Definition @'
@{
    Name      = 'Dependency'
    Elevation = 'Admin'
    Script    = 'Dependency.ps1'
    States    = @( @{ Name = 'On'; StateValue = 1; Launcher = 'A\On.cmd'; MachineAction = 'Invoke-AtlasTestMachine'; UserAction = 'Invoke-AtlasTestUser' } )
}
'@ -Companion $script:MarkerCompanion
        New-TestToggle -Root $script:DependencyRoot -Name 'Local' -Definition @'
@{
    Name          = 'Local'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'Local.ps1'
    States        = @( @{ Name = 'On'; Launcher = 'A\On.cmd'; Action = 'Invoke-AtlasTestLocal' } )
}
'@ -Companion $script:MarkerCompanion
    }

    BeforeEach {
        $env:AtlasToggleTestDir = $script:DependencyWork
        Get-ChildItem -Path $script:DependencyWork -Filter '*.txt' | Remove-Item -Force
        Remove-Item -Path $StateRoot -Recurse -Force -ErrorAction SilentlyContinue
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Toggles
    }

    AfterAll {
        Remove-Item Env:\AtlasToggleTestDir -ErrorAction SilentlyContinue
    }

    It 'applies and records only the machine part from a privileged caller' {
        Invoke-AtlasToggleMachineState -Name 'Dependency' -State 'On' -StateRoot $StateRoot -TogglesRoot $script:DependencyRoot

        Should -Invoke Assert-AtlasPrivilege -ModuleName Atlas.Toggles -ParameterFilter { $Administrator }
        [IO.File]::ReadAllText((Join-Path $script:DependencyWork 'machine.txt')) | Should -Be 'Dependency:On:1:silent=True'
        Join-Path $script:DependencyWork 'user.txt' | Should -Not -Exist
        (Get-AtlasToggleState -Name 'Dependency' -StateRoot $StateRoot).State | Should -Be 1
    }

    It 'rejects an unelevated toggle and an unknown state' {
        { Invoke-AtlasToggleMachineState -Name 'Local' -State 'On' -StateRoot $StateRoot -TogglesRoot $script:DependencyRoot } |
            Should -Throw '*does not declare Admin or TrustedInstaller*'
        { Invoke-AtlasToggleMachineState -Name 'Dependency' -State 'Off' -StateRoot $StateRoot -TogglesRoot $script:DependencyRoot } |
            Should -Throw "*does not define exact state 'Off'*"
    }
}

Describe 'Generated launchers' {
    BeforeAll {
        $script:GeneratorScript = Join-Path $script:repoRoot 'tools\dev\New-ToggleLaunchers.ps1'
        $script:LauncherBody = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd'
    }

    It 'match their definitions exactly' {
        # Repository tooling runs under PowerShell 7, like the build.
        $output = & $script:ToolsHost -NoProfile -File $script:GeneratorScript -Validate 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }

    It 'are two-line stubs that hand the toggle name, state and their own path to the shared body' {
        $stub = Get-Content -LiteralPath (Join-Path $script:repoRoot 'playbook\Executables\AtlasDesktop\2. Drivers\Run Update Drivers.cmd')
        $stub.Count | Should -Be 2
        $stub[0] | Should -Be '@echo off'
        $stub[1] | Should -Be 'call "%__APPDIR__%..\AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd" UpdateDrivers Run "%~f0" %*'

        $menuStub = Get-Content -LiteralPath (Join-Path $script:repoRoot 'playbook\Executables\AtlasDesktop\6. Advanced Configuration\Toggle Windows Updates\Toggle Windows Updates.cmd')
        $menuStub[1] | Should -Match ' ToggleWindowsUpdates - "%~f0" %\*$'
    }

    It 'canonicalizes only the supported launcher flags before reaching PowerShell' {
        $bodyLines = @(Get-Content -LiteralPath $script:LauncherBody)
        $parserStart = [array]::IndexOf($bodyLines, 'set "AtlasLauncherSilent="')
        $parserEnd = [array]::IndexOf($bodyLines, ':run')
        $parserStart | Should -BeGreaterThan -1
        $parserEnd | Should -BeGreaterThan $parserStart

        $probePath = Join-Path -Path $TestDrive -ChildPath 'launcher-argument-probe.cmd'
        $probeLines = @(
            '@echo off'
            'setlocal EnableExtensions DisableDelayedExpansion'
        ) + @($bodyLines[$parserStart..$parserEnd]) + @(
            'echo SINK silent=%AtlasLauncherSilent% justcontext=%AtlasLauncherJustContext% noaction=%AtlasLauncherNoAction%'
            'exit /b 0'
        )
        [IO.File]::WriteAllText($probePath, (($probeLines -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        $allowed = & $commandHost /d /e:on /v:off /c "call `"$probePath`" /quiet -justcontext /noaction" 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($allowed -join "`n")
        ($allowed -join "`n") | Should -Match '(?m)^SINK silent=/silent justcontext=/justcontext noaction=/noaction$'

        $rejected = & $commandHost /d /e:on /v:off /c "call `"$probePath`" /silent /unsupported" 2>&1
        $LASTEXITCODE | Should -Be 87 -Because ($rejected -join "`n")
        $rejected | Should -Not -Match '^SINK '
    }

    It 'propagate the shared body exit code through the two-line stub, including negative values' {
        $body = Join-Path $TestDrive 'body.cmd'
        [IO.File]::WriteAllText($body, "@echo off`r`nexit /b %~1`r`n", [Text.Encoding]::ASCII)
        $stub = Join-Path $TestDrive 'stub.cmd'
        [IO.File]::WriteAllText($stub, "@echo off`r`ncall `"%~dp0body.cmd`" %*`r`n", [Text.Encoding]::ASCII)

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        foreach ($code in 0, 37, -1) {
            & $commandHost /d /c "`"$stub`" $code" | Out-Null
            $LASTEXITCODE | Should -Be $code
        }
    }
}

Describe 'Get-AtlasToggleRelaunchArgumentList' {
    BeforeEach {
        Mock Get-AtlasContext -ModuleName Atlas.Toggles {
            [pscustomobject]@{ AtlasModulesPath = 'C:\Windows\AtlasModules' }
        }
    }

    It 'quotes every dynamic value in the joined Windows command line' {
        InModuleScope Atlas.Toggles {
            $list = Get-AtlasToggleRelaunchArgumentList -Name 'My Toggle' -State 'Enable Now' -LauncherPath 'C:\Program Files\x.cmd'
            $joined = $list -join ' '

            $joined | Should -Match '-File "C:\\Windows\\AtlasModules\\Scripts\\Entry\\Invoke-Toggle.ps1"'
            $joined | Should -Match '-Name "My Toggle"'
            $joined | Should -Match '-State "Enable Now"'
            $joined | Should -Match '-LauncherPath "C:\\Program Files\\x.cmd"'
        }
    }
}

Describe 'Operating-system protected toggle values' {
    It 'accepts AllowOsProtected on a state registry entry' {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-TestToggle -Root $root -Name 'Protected' -Definition @'
@{
    Name      = 'Protected'
    Elevation = 'Admin'
    States    = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = 'Group\Disable.cmd'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Test'; Name = 'Policy'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
            )
        }
    )
}
'@
        @(Test-AtlasToggleDefinition -Path $root).Count | Should -Be 0
    }

    It 'declares the widget policy values Windows can refuse' {
        $definition = Get-AtlasToggleDefinition -Name 'Widgets' -TogglesRoot $script:ShippedTogglesRoot
        $entries = @($definition['States']['Disable']['Registry'])
        @($entries | ForEach-Object { $_['Name'] }) | Should -Be @(
            'AllowNewsAndInterests', 'DisableWidgetsOnLockScreen', 'DisableWidgetsBoard')
        @($entries | Where-Object { $_['AllowOsProtected'] }).Count | Should -Be 2
        @($entries | Where-Object { $_['UseGroupPolicy'] }).Count | Should -Be 1
    }
}

Describe 'Local Group Policy declarations in toggle schemas' {
    It 'rejects user policy and non-boolean declarations' -TestCases @(
        @{ Path = 'HKLM:\Software\Policies\Test'; Flag = '$true'; Valid = $true }
        @{ Path = 'HKCU:\Software\Policies\Test'; Flag = '$true'; Valid = $false }
        @{ Path = 'HKLM:\Software\Policies\Test'; Flag = "'false'"; Valid = $false }
    ) {
        param($Path, $Flag, $Valid)
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-TestToggle -Root $root -Name 'Policy' -Definition @"
@{
    Name = 'Policy'
    Elevation = 'Admin'
    States = @(@{
        Name = 'Disable'; StateValue = 0; Launcher = 'Group\Disable.cmd'
        Registry = @(@{ Path = '$Path'; Name = 'Policy'; Type = 'DWord'; Data = 0; UseGroupPolicy = $Flag })
    })
}
"@
        $problems = @(Test-AtlasToggleDefinition -Path $root)
        if ($Valid) { $problems.Count | Should -Be 0 }
        else { ($problems.Problem -join '; ') | Should -Match 'UseGroupPolicy' }
    }
}

Describe 'Registry verification exclusions in toggle schemas' {
    It 'requires a non-empty reason string' -TestCases @(
        @{ Value = "'Windows recreates this cache.'"; Valid = $true }
        @{ Value = '$true'; Valid = $false }
        @{ Value = "''"; Valid = $false }
        @{ Value = "' '"; Valid = $false }
    ) {
        param($Value, $Valid)
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-TestToggle -Root $root -Name 'Transient' -Definition @"
@{
    Name = 'Transient'
    Elevation = 'Admin'
    States = @(
        @{
            Name = 'Disable'; StateValue = 0; Launcher = 'Group\Disable.cmd'
            Registry = @(@{ Path = 'HKCU:\Software\Test'; Operation = 'DeleteKey'; SkipVerification = $Value })
        }
    )
}
"@
        $problems = @(Test-AtlasToggleDefinition -Path $root)
        if ($Valid) { $problems.Count | Should -Be 0 }
        else { ($problems.Problem -join '; ') | Should -Match 'non-empty reason string' }
    }
}
