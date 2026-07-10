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

    It 'ships a default state seed with no executable path values' {
        $seedPath = Join-Path $repoRoot 'playbook\Executables\DEFAULT.reg'
        $seedBytes = [IO.File]::ReadAllBytes($seedPath)
        $seedBytes[0..1] | Should -Be @(0xFF, 0xFE)
        $seedText = [Text.Encoding]::Unicode.GetString($seedBytes, 2, $seedBytes.Length - 2)

        $seedText | Should -Not -Match '(?m)^"path"='
    }

    It 'hardens the state root before the fresh registry seed is imported' {
        $defaultsConfig = Get-Content -LiteralPath (Join-Path $repoRoot 'playbook\Configuration\atlas\default.yml') -Raw
        $phaseIndex = $defaultsConfig.IndexOf("Invoke-AtlasInstall.ps1'') -Phase Defaults", [System.StringComparison]::Ordinal)
        $seedIndex = $defaultsConfig.IndexOf('import ".\DEFAULT.reg"', [System.StringComparison]::Ordinal)

        $phaseIndex | Should -BeGreaterOrEqual 0
        $seedIndex | Should -BeGreaterThan $phaseIndex
    }
}

Describe 'Invoke-AtlasToggleReapply' {
    BeforeEach {
        # Reapply routes its operational output through Write-AtlasLog; mock it so the
        # tests never touch the real install-log directory.
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        Remove-Item -Path $StateRoot -Recurse -Force -ErrorAction SilentlyContinue

        $script:ReapplyTogglesRoot = Join-Path $TestDrive 'ReapplyToggles'
        Remove-Item -Path $script:ReapplyTogglesRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:ReapplyTogglesRoot -ItemType Directory -Force | Out-Null

        # The installed definition records that it ran. A separate launcher records any
        # unsafe replay of the legacy attacker-controlled registry path.
        $script:ReapplyMarker = Join-Path $TestDrive 'reapply-marker.txt'
        Remove-Item -Path $script:ReapplyMarker -Force -ErrorAction SilentlyContinue
        $env:AtlasToggleReplayMarker = $script:ReapplyMarker

        $script:UntrustedMarker = Join-Path $TestDrive 'untrusted-replay-marker.txt'
        Remove-Item -Path $script:UntrustedMarker -Force -ErrorAction SilentlyContinue
        $script:UntrustedLauncher = Join-Path $TestDrive 'UntrustedLauncher.ps1'
        Set-Content -Path $script:UntrustedLauncher -Value "param([switch]`$Silent)`nSet-Content -Path '$script:UntrustedMarker' -Value 'unsafe'" -Encoding Ascii

        New-TestToggleDefinition -Root $script:ReapplyTogglesRoot -Group 'TestGroup' -FileName 'ReplayToggle.ps1' -Content @'
@{
    Name      = 'ReplayToggle'
    Elevation = 'None'
    States    = [ordered]@{
        On = @{
            StateValue = 1
            Action = {
                param($Toggle)
                Set-Content -Path $env:AtlasToggleReplayMarker -Value 'trusted-definition'
            }
        }
        Off = @{
            StateValue = 0
            Action = {
                param($Toggle)
                Set-Content -Path $env:AtlasToggleReplayMarker -Value 'unexpected-zero-replay'
            }
        }
    }
}
'@
    }

    AfterAll {
        Remove-Item Env:\AtlasToggleReplayMarker -ErrorAction SilentlyContinue
    }

    It 'replays a known non-zero state exclusively through its installed definition' {
        Set-AtlasToggleState -Name 'ReplayToggle' -State 1 -StateRoot $StateRoot
        $recordPath = Join-Path $StateRoot 'ReplayToggle'
        New-ItemProperty -LiteralPath $recordPath -Name 'path' -Value $script:UntrustedLauncher -PropertyType String -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeTrue
        Get-Content -LiteralPath $script:ReapplyMarker | Should -Be 'trusted-definition'
        Test-Path -LiteralPath $script:UntrustedMarker | Should -BeFalse
        @((Get-Item -LiteralPath $recordPath).GetValueNames()) | Should -Not -Contain 'path'
        Test-Path -LiteralPath (Join-Path $StateRoot 'ReplayToggle') | Should -BeTrue
    }

    It 'does not replay state 0' {
        Set-AtlasToggleState -Name 'ReplayToggle' -State 0 -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeFalse
    }

    It 'scrubs an unknown record without executing its legacy raw path' {
        Set-AtlasToggleState -Name 'GhostToggle' -State 1 -StateRoot $StateRoot
        $recordPath = Join-Path $StateRoot 'GhostToggle'
        New-ItemProperty -LiteralPath $recordPath -Name 'path' -Value $script:UntrustedLauncher -PropertyType String -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:UntrustedMarker | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $StateRoot 'GhostToggle') | Should -BeFalse
    }

    It 'scrubs a known record whose numeric state is not defined' {
        Set-AtlasToggleState -Name 'ReplayToggle' -State 99 -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $StateRoot 'ReplayToggle') | Should -BeFalse
    }

    It 'scrubs a numeric state stored with the wrong registry type without executing its legacy raw path' {
        Set-AtlasToggleState -Name 'ReplayToggle' -State 1 -StateRoot $StateRoot
        $recordPath = Join-Path $StateRoot 'ReplayToggle'
        New-ItemProperty -LiteralPath $recordPath -Name 'state' -Value '1' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $recordPath -Name 'path' -Value $script:UntrustedLauncher -PropertyType String -Force | Out-Null

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeFalse
        Test-Path -LiteralPath $script:UntrustedMarker | Should -BeFalse
        Test-Path -LiteralPath $recordPath | Should -BeFalse
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

        Set-AtlasToggleState -Name 'NoRecordToggle' -State 3 -StateRoot $StateRoot

        Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot

        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $StateRoot 'NoRecordToggle') | Should -BeFalse
    }

    It 'continues replaying every record, then throws one aggregate with all failures' {
        New-TestToggleDefinition -Root $script:ReapplyTogglesRoot -Group 'TestGroup' -FileName 'AReplayFailure.ps1' -Content @'
@{
    Name      = 'AReplayFailure'
    Elevation = 'None'
    States    = [ordered]@{
        On = @{
            StateValue = 1
            Action = {
                param($Toggle)
                throw 'first replay failure'
            }
        }
    }
}
'@

        New-TestToggleDefinition -Root $script:ReapplyTogglesRoot -Group 'TestGroup' -FileName 'ZReplayFailure.ps1' -Content @'
@{
    Name      = 'ZReplayFailure'
    Elevation = 'None'
    States    = [ordered]@{
        On = @{
            StateValue = 1
            Action = {
                param($Toggle)
                throw 'second replay failure'
            }
        }
    }
}
'@

        Set-AtlasToggleState -Name 'AReplayFailure' -State 1 -StateRoot $StateRoot
        Set-AtlasToggleState -Name 'ReplayToggle' -State 1 -StateRoot $StateRoot
        Set-AtlasToggleState -Name 'ZReplayFailure' -State 1 -StateRoot $StateRoot

        $replayError = $null
        try {
            Invoke-AtlasToggleReapply -StateRoot $StateRoot -TogglesRoot $script:ReapplyTogglesRoot
        }
        catch {
            $replayError = $_
        }

        $replayError | Should -Not -BeNullOrEmpty
        $replayError.Exception.Message | Should -Match 'failed for 2 toggle\(s\)'
        $replayError.Exception.Message | Should -Match "'AReplayFailure': first replay failure"
        $replayError.Exception.Message | Should -Match "'ZReplayFailure': second replay failure"
        Test-Path -LiteralPath $script:ReapplyMarker | Should -BeTrue
        Get-Content -LiteralPath $script:ReapplyMarker | Should -Be 'trusted-definition'
    }
}

Describe 'Atlas toggle production state ACL' {
    It 'creates a missing production root with its DACL in the registry creation call' {
        $stateSource = Get-Content -LiteralPath (Join-Path $repoRoot `
                'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Toggles\Domain\State.ps1') -Raw

        $stateSource | Should -Match '(?s)\.CreateSubKey\(\s*''SOFTWARE\\AtlasOS\\Services''.*?RegistryKeyPermissionCheck\]::ReadWriteSubTree.*?RegistryOptions\]::None.*?\$acl\s*\)'
        $stateSource | Should -Match '(?s)New-AtlasToggleProductionStateRoot\s*\r?\n\s*}\s*\r?\n\s*\r?\n\s*#.*?Set-AtlasToggleStateKeyAcl -KeyPath \$StateRoot'
    }

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

    It 'keeps every production state-recording toggle on a privileged execution path' {
        $definitionsRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Toggles'
        $unprivilegedRecorders = @(Get-ChildItem -LiteralPath $definitionsRoot -Recurse -File -Filter '*.ps1' | ForEach-Object {
                $definition = & $_.FullName
                $elevation = if ($definition.Contains('Elevation') -and $definition.Elevation) {
                    [string]$definition.Elevation
                }
                else {
                    'None'
                }
                $definitionNoRecord = $definition.Contains('NoStateRecord') -and $definition.NoStateRecord
                $recordsAnyState = @($definition.States.Keys | Where-Object {
                        $state = $definition.States[$_]
                        -not $definitionNoRecord -and -not ($state.Contains('NoStateRecord') -and $state.NoStateRecord)
                    }).Count -gt 0

                if ($elevation -eq 'None' -and $recordsAnyState) {
                    [string]$definition.Name
                }
            })

        $unprivilegedRecorders | Should -BeNullOrEmpty
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

        New-TestToggleDefinition -Root $TogglesRoot -Group 'TestGroup' -FileName 'ContextFailingToggle.ps1' -Content @'
@{
    Name      = 'ContextFailingToggle'
    Elevation = 'None'
    States    = [ordered]@{
        On = @{
            StateValue    = 1
            Reboot        = 'None'
            ContextAction = {
                param($Toggle)
                throw 'deliberate context failure'
            }
            Action        = {
                param($Toggle)
                Set-Content -Path (Join-Path $env:AtlasToggleTestDir 'context-failure-action-marker.txt') -Value 'must-not-run'
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

    It 'runs the action and records only declarative state (happy path, silent)' {
        $launcher = Join-Path $WorkDir 'fake-launcher.cmd'
        Invoke-AtlasToggle -Name 'MarkerToggle' -State 'On' -LauncherPath $launcher -Silent `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        Join-Path $WorkDir 'action-marker.txt' | Should -Exist
        (Get-Content (Join-Path $WorkDir 'action-marker.txt')) | Should -Be 'MarkerToggle:On:1'

        $recorded = Get-AtlasToggleState -Name 'MarkerToggle' -StateRoot $StateRoot
        $recorded.State | Should -Be 1
        $recorded.PSObject.Properties.Name | Should -Not -Contain 'Path'
    }

    It 'logs the applied state change through Write-AtlasLog even when silent' {
        # A support bundle must be able to answer "what did this toggle do on this
        # machine" from the install log, so a silent apply records the state change.
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        Invoke-AtlasToggle -Name 'MarkerToggle' -State 'On' -Silent `
            -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
            -TogglesRoot $TogglesRoot -StateRoot $StateRoot

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles `
            -ParameterFilter { $Message -like "*MarkerToggle*applied*state 'On'*" }
    }

    It 'propagates an action failure and does not record state (upgrade re-apply must not replay a lie)' {
        # Recording before/despite a failed action would leave a record that
        # Invoke-AtlasToggleReapply replays on the next upgrade.
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        { Invoke-AtlasToggle -Name 'FailingToggle' -State 'On' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot } |
            Should -Throw '*deliberate failure*'

        Get-AtlasToggleState -Name 'FailingToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'Warning' -and $Message -like "*Toggle 'FailingToggle' action failed*" }
    }

    It 'propagates a context-action failure without running the action or recording state' {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        { Invoke-AtlasToggle -Name 'ContextFailingToggle' -State 'On' -Silent `
                -LauncherPath (Join-Path $WorkDir 'fake-launcher.cmd') `
                -TogglesRoot $TogglesRoot -StateRoot $StateRoot } |
            Should -Throw '*deliberate context failure*'

        Join-Path $WorkDir 'context-failure-action-marker.txt' | Should -Not -Exist
        Get-AtlasToggleState -Name 'ContextFailingToggle' -StateRoot $StateRoot | Should -BeNullOrEmpty
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'Warning' -and $Message -like "*Toggle 'ContextFailingToggle' context action failed*" }
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

Describe 'Invoke-AtlasToggleAction result contract' {
    # These tests pin the engine's result contract: a terminating error is logged and
    # rethrown, while completion without a terminating error is success.
    # Actions run non-strict with $ErrorActionPreference = 'Continue', so
    # non-terminating cmdlet errors are best-effort by design and still count as
    # success. If the maintainer later opts into stricter semantics, the
    # non-terminating-error and preference tests below must be consciously rewritten.
    # Invoke-AtlasToggleAction is module-private, hence InModuleScope.

    It 'rethrows and logs one warning when the action throws' {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        { InModuleScope Atlas.Toggles {
                $toggleContext = [pscustomobject]@{ Name = 'T' }
                Invoke-AtlasToggleAction -Action { throw 'deliberate failure' } `
                    -ToggleContext $toggleContext
            } } | Should -Throw '*deliberate failure*'

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'Warning' -and $Message -like "*Toggle 'T'*failed*" }
    }

    It 'treats non-terminating errors as success (documented best-effort contract)' {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        InModuleScope Atlas.Toggles {
            $toggleContext = [pscustomobject]@{ Name = 'T' }

            Invoke-AtlasToggleAction -Action { Write-Error 'non-terminating' -ErrorAction Continue } `
                -ToggleContext $toggleContext 2>$null
        }

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'reports success when the action completes cleanly' {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles

        InModuleScope Atlas.Toggles {
            $toggleContext = [pscustomobject]@{ Name = 'T' }

            Invoke-AtlasToggleAction -Action { } -ToggleContext $toggleContext
        }

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It "runs the action with `$ErrorActionPreference = 'Continue' (recording gates only on throw)" {
        # Guards against someone flipping the runner's preference (e.g. to 'Stop')
        # without noticing that it changes what upgrade re-apply records and replays.
        InModuleScope Atlas.Toggles {
            $toggleContext = [pscustomobject]@{ Name = 'T' }

            $observedPreference = Invoke-AtlasToggleAction -Action { [string]$ErrorActionPreference } `
                -ToggleContext $toggleContext

            $observedPreference | Should -Be 'Continue'
        }
    }
}

Describe 'New-ToggleLaunchers.ps1' {
    BeforeAll {
        $script:GeneratorRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:GeneratorScript = Join-Path $script:GeneratorRepoRoot 'tools\dev\New-ToggleLaunchers.ps1'
        $script:LauncherEnvironmentHelper = Join-Path $script:GeneratorRepoRoot `
            'playbook\Executables\AtlasModules\Scripts\Internal\Initialize-PowerShellLauncherEnvironment.cmd'

        $tokens = $null
        $parseErrors = $null
        $generatorAst = [Management.Automation.Language.Parser]::ParseFile(
            $script:GeneratorScript,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $parseErrors | Should -BeNullOrEmpty
        foreach ($functionName in @(
                'Assert-LauncherIdentifier'
                'Resolve-LauncherTargetPath'
                'New-LauncherContent'
            )) {
            $functionAst = $generatorAst.Find({
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq $functionName
                }, $true)
            Set-Variable -Scope Script -Name ($functionName.Replace('-', '') + 'Definition') `
                -Value ([scriptblock]::Create($functionAst.Extent.Text))
        }
    }

    It 'validates cleanly against the committed repo tree' {
        $output = & $GeneratorScript -Validate 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }

    It 'rejects unsafe Name and State metadata through the pure identifier seam' {
        . $script:AssertLauncherIdentifierDefinition

        Assert-LauncherIdentifier -Value 'SafeToggle1' -Kind Name -Source 'test' |
            Should -BeExactly 'SafeToggle1'
        foreach ($candidate in @(
                $null
                42
                ''
                ' leading'
                '-leading'
                'Has Space'
                'Has&Command'
                'Has%Expansion%'
                'Has!Expansion!'
                "Has`nNewline"
            )) {
            {
                Assert-LauncherIdentifier -Value $candidate -Kind State -Source 'negative test'
            } | Should -Throw
        }
    }

    It 'keeps launcher targets as safe .cmd files beneath their declared root' {
        . $script:ResolveLauncherTargetPathDefinition

        $root = Join-Path $TestDrive 'LauncherRoot'
        $null = New-Item -Path $root -ItemType Directory -Force
        $valid = Resolve-LauncherTargetPath `
            -RootPath $root `
            -LauncherRelative 'Folder (safe)\Toggle-1.cmd' `
            -Source 'positive test'
        $valid | Should -BeExactly ([IO.Path]::GetFullPath((Join-Path $root 'Folder (safe)\Toggle-1.cmd')))

        foreach ($candidate in @(
                'C:\outside.cmd'
                '..\outside.cmd'
                'Folder\..\outside.cmd'
                'Folder/forward.cmd'
                'Folder\not-a-command.ps1'
                'Folder\Bad&Command.cmd'
                'Folder\Bad%Expansion%.cmd'
                'Folder\\EmptySegment.cmd'
                'Folder.\TrailingDot.cmd'
                'CON.cmd'
                'LPT1.anything.cmd'
            )) {
            {
                Resolve-LauncherTargetPath `
                    -RootPath $root `
                    -LauncherRelative $candidate `
                    -Source 'negative test'
            } | Should -Throw
        }
    }

    It 'validates interpolated identifiers and emits no dynamic title command' {
        . $script:AssertLauncherIdentifierDefinition
        . $script:NewLauncherContentDefinition

        $content = New-LauncherContent -Name 'SafeToggle' -State 'Enable' -Source 'positive test'
        $content | Should -Match '-Name "SafeToggle" -State "Enable"'
        $content | Should -Match '"%AtlasNativePowerShell%"'
        $content | Should -Not -Match '(?im)^\s*title\b'
        {
            New-LauncherContent -Name 'Safe&whoami' -State Enable -Source 'negative test'
        } | Should -Throw
    }

    It 'delegates every generated launcher to the fixed native PowerShell environment helper' {
        $repoRoot = $script:GeneratorRepoRoot
        $launcherRoots = @(
            (Join-Path $repoRoot 'playbook\Executables\AtlasDesktop')
            (Join-Path $repoRoot 'playbook\Executables\AtlasModules\Toolbox')
        )
        $launchers = @(Get-ChildItem -LiteralPath $launcherRoots -Recurse -File -Filter '*.cmd' |
            Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'Invoke-Toggle\.ps1' })

        $launchers.Count | Should -Be 181
        foreach ($launcher in $launchers) {
            $content = Get-Content -LiteralPath $launcher.FullName -Raw
            $content | Should -Match '(?m)^setlocal EnableExtensions DisableDelayedExpansion\r?$'
            $content | Should -Match '(?m)^verify other 2>nul\r?\nsetlocal EnableExtensions DisableDelayedExpansion\r?\nif errorlevel 1 exit /b 1\r?$'
            $content | Should -Match '(?m)^cd /d "%__APPDIR__%"\r?\nif errorlevel 1 exit /b 1\r?$'
            $content | Should -Match 'for %%I in \("%__APPDIR__%\.\."\) do set "AtlasWindowsRoot=%%~fI"'
            $content | Should -Match `
                'set "launcherEnvironment=%AtlasWindowsRoot%\\AtlasModules\\Scripts\\Internal\\Initialize-PowerShellLauncherEnvironment\.cmd"'
            $content | Should -Match `
                '(?ms)^if not exist "%launcherEnvironment%" \(\r?\n    echo PowerShell launcher environment helper not found:.+\r?\n    exit /b 1\r?\n\)\r?\ncall "%launcherEnvironment%"\r?\nif errorlevel 1 exit /b 1\r?$'
            $content | Should -Not -Match `
                '(?im)^set "(?:SystemRoot|windir|ComSpec|PATH|PSModulePath|COR_|CORECLR_|DOTNET_|APPDOMAIN_|COMPLUS_)'
            $content | Should -Match '(?m)^set "AtlasLauncherSilent="\r?$'
            $content | Should -Match '(?m)^set "AtlasLauncherJustContext="\r?$'
            $content | Should -Match '(?m)^set "AtlasLauncherNoAction="\r?$'
            $content | Should -Match `
                '(?m)^if /i "%~1"=="/silent" goto AtlasLauncherFlagSilent\r?$'
            $content | Should -Match `
                '(?m)^if /i "%~1"=="-quiet" goto AtlasLauncherFlagSilent\r?$'
            $content | Should -Match `
                '(?m)^if /i "%~1"=="/justcontext" goto AtlasLauncherFlagJustContext\r?$'
            $content | Should -Match `
                '(?m)^if /i "%~1"=="-noaction" goto AtlasLauncherFlagNoAction\r?$'
            $content | Should -Match '(?m)^exit /b 87\r?\n:AtlasLauncherFlagSilent\r?$'
            ([regex]::Matches($content, '(?m)^shift /1\r?$')).Count | Should -Be 3
            $content | Should -Not -Match '(?m)^shift\r?$'
            $content | Should -Not -Match '(?im)^for /f|%ComSpec%|%\*'
            $content | Should -Match '"%AtlasNativePowerShell%"'
            $content | Should -Not -Match '%__APPDIR__%WindowsPowerShell|(?im)^\s*title\b'
            $content | Should -Match '-File "%AtlasWindowsRoot%\\AtlasModules\\Scripts\\Invoke-Toggle\.ps1"'
            $content | Should -Match '-Name "[A-Za-z][A-Za-z0-9]*"(?: -State "[A-Za-z][A-Za-z0-9]*")? -LauncherPath'
            $content | Should -Match `
                '%AtlasLauncherSilent% %AtlasLauncherJustContext% %AtlasLauncherNoAction%'
            $content | Should -Not -Match '%(?:SystemRoot|windir|ERRORLEVEL)%|(?im)^\s*powershell(?:\.exe)?\s'
            $content | Should -Match `
                '(?m)^if errorlevel 0 \(\r?\n    if errorlevel 1 exit /b\r?\n\) else \(\r?\n    exit /b 1\r?\n\)\r?\nexit /b 0\r?$'
        }
    }

    It 'canonicalizes only the supported launcher flags before reaching PowerShell' {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $driverLauncher = Join-Path -Path $repoRoot `
            -ChildPath 'playbook\Executables\AtlasDesktop\2. Drivers\Run Update Drivers.cmd'
        $launcherLines = @(Get-Content -LiteralPath $driverLauncher)
        $parserStart = [array]::IndexOf($launcherLines, 'set "AtlasLauncherSilent="')
        $parserEnd = [array]::IndexOf($launcherLines, ':AtlasLauncherRun')
        $parserStart | Should -BeGreaterThan -1
        $parserEnd | Should -BeGreaterThan $parserStart

        $probePath = Join-Path -Path $TestDrive -ChildPath 'launcher-argument-probe.cmd'
        $probeLines = @(
            '@echo off'
            'setlocal EnableExtensions DisableDelayedExpansion'
        ) + @($launcherLines[$parserStart..$parserEnd]) + @(
            'echo SINK silent=%AtlasLauncherSilent% justcontext=%AtlasLauncherJustContext% noaction=%AtlasLauncherNoAction%'
            'echo LAUNCHER=%~f0'
            'exit /b 0'
        )
        [IO.File]::WriteAllText(
            $probePath,
            (($probeLines -join "`r`n") + "`r`n"),
            [Text.Encoding]::ASCII
        )

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        $allowed = & $commandHost /d /e:on /v:off /c `
            "call `"$probePath`" /quiet -justcontext /noaction" 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($allowed -join "`n")
        ($allowed -join "`n") | Should -Match `
            '(?m)^SINK silent=/silent justcontext=/justcontext noaction=/noaction$'
        ($allowed -join "`n") | Should -Match `
            ('(?m)^LAUNCHER=' + [regex]::Escape($probePath) + '$')

        $rejected = & $commandHost /d /e:on /v:off /c `
            "call `"$probePath`" /silent /unsupported" 2>&1
        $LASTEXITCODE | Should -Be 87 -Because ($rejected -join "`n")
        $rejected | Should -Not -Match '^SINK '
    }

    It 'uses the fixed helper to select native PowerShell and sanitize a real cmd child' {
        $probePath = Join-Path $TestDrive 'launcher-probe.cmd'
        $helperEscaped = $script:LauncherEnvironmentHelper.Replace('%', '%%')
        $probeLines = @(
            '@echo off'
            'verify other 2>nul'
            'setlocal EnableExtensions DisableDelayedExpansion'
            'if errorlevel 1 exit /b 1'
            'cd /d "%__APPDIR__%"'
            'if errorlevel 1 exit /b 1'
            'for %%I in ("%__APPDIR__%..") do set "AtlasWindowsRoot=%%~fI"'
            ('call "{0}"' -f $helperEscaped)
            'if errorlevel 1 exit /b 12'
            'if defined COR_ENABLE_PROFILING (echo COR=present) else (echo COR=cleared)'
            'if defined COMPLUS_JITPATH (echo JIT=present) else (echo JIT=cleared)'
            'echo CWD=%CD%'
            'echo ROOT=%AtlasWindowsRoot%'
            'echo PATH=%PATH%'
            'echo COMSPEC=%ComSpec%'
            'echo PATHEXT=%PATHEXT%'
            'echo PSMODULEPATH=%PSModulePath%'
            'echo NATIVEPOWERSHELL=%AtlasNativePowerShell%'
            'exit /b 0'
        )
        [IO.File]::WriteAllText($probePath, (($probeLines -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        $startInfo = [Activator]::CreateInstance([Diagnostics.ProcessStartInfo])
        $startInfo.FileName = $commandHost
        $startInfo.Arguments = '/d /e:off /v:off /c call "' + $probePath + '"'
        $startInfo.WorkingDirectory = $TestDrive
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true

        $originalCor = $env:COR_ENABLE_PROFILING
        $originalJit = $env:COMPLUS_JITPATH
        try {
            $env:COR_ENABLE_PROFILING = '1'
            $env:COMPLUS_JITPATH = 'C:\untrusted\probe.dll'
            $probe = [Diagnostics.Process]::Start($startInfo)
            $stdout = $probe.StandardOutput.ReadToEnd()
            $stderr = $probe.StandardError.ReadToEnd()
            $probe.WaitForExit()

            $probe.ExitCode | Should -Be 0 -Because $stderr
            $stdout | Should -Match '(?m)^COR=cleared\r?$'
            $stdout | Should -Match '(?m)^JIT=cleared\r?$'
            $stdout | Should -Match ('(?m)^CWD=' + [regex]::Escape([Environment]::GetFolderPath('System')) + '\\?\r?$')
            $stdout | Should -Match ('(?m)^ROOT=' + [regex]::Escape([Environment]::GetFolderPath('Windows')) + '\\?\r?$')
            $expectedSystem = [Environment]::GetFolderPath('System')
            $expectedWindows = [Environment]::GetFolderPath('Windows')
            $expectedPath = "$expectedSystem;$expectedWindows;$expectedSystem\Wbem;$expectedSystem\WindowsPowerShell\v1.0"
            $stdout | Should -Match ('(?m)^PATH=' + [regex]::Escape($expectedPath) + '\r?$')
            $stdout | Should -Match ('(?m)^COMSPEC=' + [regex]::Escape((Join-Path $expectedSystem 'cmd.exe')) + '\r?$')
            $stdout | Should -Match '(?m)^PATHEXT=\.COM;\.EXE;\.BAT;\.CMD\r?$'
            $stdout | Should -Match `
                ('(?m)^PSMODULEPATH=' + [regex]::Escape((Join-Path $expectedSystem 'WindowsPowerShell\v1.0\Modules')) + '\r?$')
            $stdout | Should -Match `
                ('(?m)^NATIVEPOWERSHELL=' + [regex]::Escape((Join-Path $expectedSystem 'WindowsPowerShell\v1.0\powershell.exe')) + '\r?$')
        }
        finally {
            $env:COR_ENABLE_PROFILING = $originalCor
            $env:COMPLUS_JITPATH = $originalJit
        }
    }

    It 'propagates positive native exit 37 despite an inherited ERRORLEVEL variable' {
        $probePath = Join-Path $TestDrive 'launcher-exit-probe.cmd'
        $probeLines = @(
            '@echo off'
            'verify other 2>nul'
            'setlocal EnableExtensions DisableDelayedExpansion'
            'if errorlevel 1 exit /b 1'
            '"%__APPDIR__%cmd.exe" /d /c exit 37'
            'if errorlevel 0 ('
            '    if errorlevel 1 exit /b'
            ') else ('
            '    exit /b 1'
            ')'
            'exit /b 0'
        )
        [IO.File]::WriteAllText($probePath, (($probeLines -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        $startInfo = [Activator]::CreateInstance([Diagnostics.ProcessStartInfo])
        $startInfo.FileName = $commandHost
        $startInfo.Arguments = '/d /e:off /v:off /c call "' + $probePath + '"'
        $startInfo.UseShellExecute = $false

        $originalErrorLevel = $env:ERRORLEVEL
        try {
            $env:ERRORLEVEL = '0'
            $probe = [Diagnostics.Process]::Start($startInfo)
            $probe.WaitForExit()
            $probe.ExitCode | Should -Be 37
        }
        finally {
            $env:ERRORLEVEL = $originalErrorLevel
        }
    }

    It 'preserves a successful native exit as zero' {
        $probePath = Join-Path $TestDrive 'launcher-zero-exit-probe.cmd'
        $probeLines = @(
            '@echo off'
            'verify other 2>nul'
            'setlocal EnableExtensions DisableDelayedExpansion'
            'if errorlevel 1 exit /b 1'
            '"%__APPDIR__%cmd.exe" /d /c exit 0'
            'if errorlevel 0 ('
            '    if errorlevel 1 exit /b'
            ') else ('
            '    exit /b 1'
            ')'
            'exit /b 0'
        )
        [IO.File]::WriteAllText(
            $probePath,
            (($probeLines -join "`r`n") + "`r`n"),
            [Text.Encoding]::ASCII
        )

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        $startInfo = [Activator]::CreateInstance([Diagnostics.ProcessStartInfo])
        $startInfo.FileName = $commandHost
        $startInfo.Arguments = '/d /e:off /v:off /c call "' + $probePath + '"'
        $startInfo.UseShellExecute = $false

        $probe = [Diagnostics.Process]::Start($startInfo)
        $probe.WaitForExit()
        $probe.ExitCode | Should -Be 0
    }

    It 'normalizes a negative native exit to failure instead of reporting success' {
        $probePath = Join-Path $TestDrive 'launcher-negative-exit-probe.cmd'
        $probeLines = @(
            '@echo off'
            'verify other 2>nul'
            'setlocal EnableExtensions DisableDelayedExpansion'
            'if errorlevel 1 exit /b 1'
            '"%__APPDIR__%cmd.exe" /d /c exit /b -1'
            'if errorlevel 0 ('
            '    if errorlevel 1 exit /b'
            ') else ('
            '    exit /b 1'
            ')'
            'exit /b 0'
        )
        [IO.File]::WriteAllText(
            $probePath,
            (($probeLines -join "`r`n") + "`r`n"),
            [Text.Encoding]::ASCII
        )

        $commandHost = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
        $startInfo = [Activator]::CreateInstance([Diagnostics.ProcessStartInfo])
        $startInfo.FileName = $commandHost
        $startInfo.Arguments = '/d /e:off /v:off /c call "' + $probePath + '"'
        $startInfo.UseShellExecute = $false

        $probe = [Diagnostics.Process]::Start($startInfo)
        $probe.WaitForExit()
        $probe.ExitCode | Should -Be 1
    }
}

Describe 'Get-AtlasToggleRelaunchArgumentList' {
    # The relaunch argument list is space-joined by both consumers (Start-Process
    # and the TrustedInstaller cmd join), so every value that can contain a space
    # or shell metacharacter must be quoted. Get-AtlasToggleRelaunchArgumentList is
    # module-private, hence InModuleScope.

    BeforeEach {
        Mock Get-AtlasContext -ModuleName Atlas.Toggles {
            [pscustomobject]@{ AtlasModulesPath = 'C:\Windows\AtlasModules' }
        }
    }

    It 'quotes the -Name value so names with spaces survive the join' {
        InModuleScope Atlas.Toggles {
            $list = Get-AtlasToggleRelaunchArgumentList -Name 'My Toggle' -State 'Enable'

            $nameIndex = [array]::IndexOf($list, '-Name')
            $list[$nameIndex + 1] | Should -Be '"My Toggle"'
        }
    }

    It 'quotes the -State value when a state is supplied' {
        InModuleScope Atlas.Toggles {
            $list = Get-AtlasToggleRelaunchArgumentList -Name 'BackgroundApps' -State 'Disable'

            $stateIndex = [array]::IndexOf($list, '-State')
            $list[$stateIndex + 1] | Should -Be '"Disable"'
        }
    }

    It 'produces a joined command line with no unquoted space-bearing values' {
        InModuleScope Atlas.Toggles {
            $list = Get-AtlasToggleRelaunchArgumentList -Name 'My Toggle' -State 'Enable Now' -LauncherPath 'C:\Program Files\x.cmd'

            $joined = $list -join ' '

            # Every space in the joined string must fall inside a quoted region;
            # an odd number of quotes before any given space would reveal a bare gap.
            $joined | Should -Match '-Name "My Toggle"'
            $joined | Should -Match '-State "Enable Now"'
            $joined | Should -Match '-LauncherPath "C:\\Program Files\\x.cmd"'
        }
    }
}

Describe 'RecentItems policy semantics' {
    It 'uses the documented force-hide value for ShowOrHideMostUsedApps' {
        $definitionPath = Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Toggles\Interface\RecentItems.ps1'
        $source = Get-Content -LiteralPath $definitionPath -Raw

        $source | Should -Match '(?m)New-ItemProperty\s+-LiteralPath\s+\$hklmPolicies\s+-Name\s+''ShowOrHideMostUsedApps''\s+-Value\s+2\s+-PropertyType\s+DWord'
    }
}
