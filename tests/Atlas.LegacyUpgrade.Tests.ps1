Describe 'Upgrade registry choice preservation' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        . (Join-Path $script:AtlasTestScriptsRoot 'Modules\Atlas.Tweaks\Domain\Invoke.ps1')
        function Get-AtlasToggleDefinition { param($Name) throw "Test must provide a definition for '$Name'." }
    }
    It 'keeps new policy entries and excludes an existing toggle target across path spellings' {
        Mock Get-AtlasToggleDefinition { @{ States = @{ Enabled = @{ StateValue = 1; Registry = @(@{ Path = 'HKCU:\\Software\\Example'; Name = 'Choice'; Data = 1 }) } } } }
        $entries = @(
            @{ Path = 'HKCU\Software\Example'; Name = 'Choice'; Type = 'DWord'; Data = 0 }
            @{ Path = 'HKLM\Software\Example'; Name = 'NewPolicy'; Type = 'DWord'; Data = 1 }
        )
        $result = @(Get-AtlasUpgradeRegistryEntries -Entries $entries -Records @{ Example = 1 })
        $result.Count | Should -Be 1
        $result[0].Name | Should -BeExactly 'NewPolicy'
    }
    It 'preserves a chosen value when a default would delete its parent key' {
        Mock Get-AtlasToggleDefinition { @{ States = @{ Enabled = @{ StateValue = 1; Registry = @(@{ Path = 'HKCU\Software\Example\Child'; Name = 'Choice'; Data = 1 }) } } } }
        $entries = @(
            @{ Path = 'HKCU\Software\Example'; Operation = 'DeleteKey' }
            @{ Path = 'HKCU\Software\ExampleSibling'; Operation = 'DeleteKey' }
        )
        $result = @(Get-AtlasUpgradeRegistryEntries -Entries $entries -Records @{ Example = 1 })
        $result.Count | Should -Be 1
        $result[0].Path | Should -BeExactly 'HKCU\Software\ExampleSibling'
    }
    It 'does not recreate descendants of a key owned by a chosen toggle' {
        Mock Get-AtlasToggleDefinition { @{ States = @{ Disabled = @{ StateValue = 0; Registry = @(@{ Path = 'HKCU\Software\Example'; Operation = 'DeleteKey' }) } } } }
        $entries = @(@{ Path = 'HKCU\Software\Example\Child'; Name = 'Value'; Type = 'DWord'; Data = 1 })
        @(Get-AtlasUpgradeRegistryEntries -Entries $entries -Records @{ Example = 0 }).Count | Should -Be 0
    }
    It 'honors an explicit unlock override instead of restoring a restrictive policy' {
        Mock Get-AtlasToggleDefinition { @{ States = @{ Enabled = @{ StateValue = 1 } } } }
        $entries = @(@{ Path = 'HKLM\Software\Example'; Name = 'Policy'; Type = 'DWord'; Data = 1; VerifyWithToggle = @{Name='Example';State=1;Operation='Delete'} })
        $result = @(Get-AtlasUpgradeRegistryEntries -Entries $entries -Records @{ Example = 1 })
        $result[0].Operation | Should -BeExactly 'Delete'
        $result[0].ContainsKey('Data') | Should -BeFalse
        $entries[0].Data | Should -Be 1
    }
    It 'applies new defaults when no choices were recorded' {
        Mock Get-AtlasToggleDefinition { throw 'No definition should be requested' }
        $entries = @(@{ Path = 'HKLM\Software\Example'; Name = 'NewPolicy'; Type = 'DWord'; Data = 1 })
        @(Get-AtlasUpgradeRegistryEntries -Entries $entries -Records @{}).Count | Should -Be 1
        Should -Invoke Get-AtlasToggleDefinition -Times 0
    }
}
Describe 'Upgrade plan coverage' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        . (Join-Path $script:AtlasTestScriptsRoot 'Install\Install-Plan.ps1')
    }
    It 'captures choices before applying defaults and configures existing and future users' {
        $keys = @(Get-AtlasInstallPlan -Mode Upgrade | ForEach-Object Key)
        [array]::IndexOf($keys, 'Checkpoint/LegacyChoices') | Should -BeLessThan ([array]::IndexOf($keys, 'Defaults'))
        foreach ($category in 'networking','performance','privacy','qol','security','debloat','scripts','misc') { $keys | Should -Contain "Tweaks/$category" }
        $keys | Should -Contain 'Checkpoint/InstallingUserSetup'
        $keys | Should -Not -Contain 'Tweak/scripts/set-power-settings'
        $keys | Should -Not -Contain 'Services'
    }
}

Describe 'Legacy registry reader on Windows PowerShell' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        $taskPath = Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Import-AtlasLegacyChoices.ps1'
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile($taskPath, [ref]$tokens, [ref]$errors)
        $reader = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Read-AtlasLegacyRegistryValue' }, $true)
        . ([scriptblock]::Create($reader.Extent.Text))
    }
    It 'reads an existing machine value without changing the registry' {
        $result = Read-AtlasLegacyRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName'
        $result.KeyExists | Should -BeTrue
        $result.Exists | Should -BeTrue
        $result.Value | Should -Not -BeNullOrEmpty
    }
    It 'distinguishes an absent value from an absent key' {
        $result = Read-AtlasLegacyRegistryValue -Path 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'AtlasLegacyReaderMissingValue-20260906'
        $result.KeyExists | Should -BeTrue
        $result.Exists | Should -BeFalse
        $result = Read-AtlasLegacyRegistryValue -Path 'HKLM\SOFTWARE\AtlasLegacyReaderMissingKey-20260906' -Name 'Missing'
        $result.KeyExists | Should -BeFalse
    }
    It 'rejects registry roots outside the migration scope' {
        Read-AtlasLegacyRegistryValue -Path 'HKU\OtherUser' -Name 'Value' | Should -BeNullOrEmpty
    }
}
