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

Describe 'Partial legacy choice capture' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        . (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Import-AtlasLegacyChoices.ps1') -LibraryOnly
    }
    BeforeEach {
        $script:CapturedChoices = @{}
        $script:ChoiceContext = [pscustomobject]@{ AtlasModulesPath = $TestDrive; InteractiveUserSid = 'S-1-5-21-1-2-3-1001'; IsArm64 = $false }
        Mock Initialize-AtlasToggleStateStore {}
        Mock Get-AtlasToggleStateRecords { @{ Existing = 0; RecentItems = 0; Sleep = 0 } }
        Mock Get-ChildItem { @('Existing', 'Missing', 'Absent', 'Ambiguous') | ForEach-Object { [pscustomobject]@{ BaseName = $_ } } }
        Mock Get-AtlasToggleDefinition {
            $states = @{ Enable = @{ Name = 'Enable'; StateValue = 1; Registry = @(@{ Path = 'HKLM\Example'; Name = $Name; Type = 'DWord'; Data = 1 }) } }
            if ($Name -eq 'Ambiguous') { $states.Disable = @{ Name = 'Disable'; StateValue = 0; Registry = @(@{ Path = 'HKLM\Example'; Name = $Name; Data = 1 }) } }
            @{ Name = $Name; States = $states }
        }
        Mock Test-AtlasArchMatch { $true }
        Mock Get-ItemPropertyValue { '01234567-0123-0123-0123-012345678901' }
        Mock Read-AtlasLegacyRegistryValue {
            if ($Name -in @('Missing', 'Ambiguous', 'Start_TrackDocs', 'ACSettingIndex')) {
                return @{ KeyExists = $true; Exists = $true; Kind = 'DWord'; Value = 1 }
            }
            return @{ KeyExists = $false; Exists = $false; Value = $null }
        }
        Mock Set-AtlasToggleState { $script:CapturedChoices[$Name] = $State }
        Mock Write-AtlasLog {}
    }
    It 'captures a missing observable choice even when other choices are recorded' {
        Import-AtlasLegacyChoices -Context $script:ChoiceContext
        $script:CapturedChoices.Count | Should -Be 1
        $script:CapturedChoices.Missing | Should -Be 1
        Should -Invoke Get-AtlasToggleDefinition -Times 4
        Should -Invoke Read-AtlasLegacyRegistryValue -Times 0 -ParameterFilter { $Name -eq 'Existing' }
    }
    It 'never replaces recorded Recent Items or Sleep choices with live observations' {
        Import-AtlasLegacyChoices -Context $script:ChoiceContext
        $script:CapturedChoices.ContainsKey('RecentItems') | Should -BeFalse
        $script:CapturedChoices.ContainsKey('Sleep') | Should -BeFalse
    }
    It 'does not invent a choice from absent values or two matching states' {
        Import-AtlasLegacyChoices -Context $script:ChoiceContext
        $script:CapturedChoices.ContainsKey('Absent') | Should -BeFalse
        $script:CapturedChoices.ContainsKey('Ambiguous') | Should -BeFalse
    }
    It 'reads the installing user hive instead of the privileged process user' {
        Import-AtlasLegacyChoices -Context $script:ChoiceContext
        Should -Invoke Read-AtlasLegacyRegistryValue -Times 1 -ParameterFilter {
            $Name -eq 'Start_TrackDocs' -and $UserSid -eq 'S-1-5-21-1-2-3-1001'
        }
    }
    It 'does not infer a DWORD choice from a string with the same text' {
        Mock Read-AtlasLegacyRegistryValue { @{ KeyExists = $true; Exists = $true; Kind = 'String'; Value = '1' } }
        Import-AtlasLegacyChoices -Context $script:ChoiceContext
        $script:CapturedChoices.ContainsKey('Missing') | Should -BeFalse
    }
    It 'tolerates an absent active power plan when capturing missing choices' {
        Mock Get-AtlasToggleStateRecords { @{ Existing = 0; RecentItems = 0 } }
        { Import-AtlasLegacyChoices -Context $script:ChoiceContext } | Should -Not -Throw
        $script:CapturedChoices.ContainsKey('Sleep') | Should -BeFalse
    }
}
