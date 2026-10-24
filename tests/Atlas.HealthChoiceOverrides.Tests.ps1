BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$module\$module.psd1") -Force
    }
    $script:choiceContext = [pscustomobject]@{
        IsArm64 = $false; WindowsBuild = 26200; IsUpgrade = $false
        IsOobe = $false; IsInstallStateBacked = $true; Options = @()
    }
    $script:choiceFile = Join-Path $TestDrive 'choice.psd1'
    $healthPath = Join-Path $script:AtlasTestScriptsRoot 'Entry\Test-AtlasHealth.ps1'
    $healthAst = [System.Management.Automation.Language.Parser]::ParseFile($healthPath, [ref]$null, [ref]$null)
    foreach ($functionName in 'Get-AtlasHealthReport', 'Get-AtlasHealthStandaloneTweakPath') {
        $function = $healthAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName
        }, $false)
        . ([scriptblock]::Create($function.Extent.Text))
    }
    $script:healthDocument = [pscustomobject]@{
        installedVersion = 'test'; installedAt = 'test'; mode = 'Reapply'
        options = @(); history = @(); toggles = [pscustomobject]@{}
    }
    @'
@{
    Name = 'Choice fixture'
    Registry = @(
        @{ Path = 'HKLM\SOFTWARE\AtlasHealthFixture'; Name = 'Location'; Type = 'String'; Data = 'Deny'; VerifyWithToggle = @{ Name = 'Location'; State = 1; Type = 'String'; Data = 'Allow' } }
        @{ Path = 'HKLM\SOFTWARE\AtlasHealthFixture'; Name = 'Copilot'; Type = 'DWord'; Data = 1; VerifyWithToggle = @{ Name = 'Copilot'; State = 1; Operation = 'Delete' } }
        @{ Path = 'HKLM\SOFTWARE\AtlasHealthFixture'; Name = 'Unrelated'; Type = 'String'; Data = 'Deny' }
    )
}
'@ | Set-Content -LiteralPath $script:choiceFile
}

Describe 'Health expectations for explicitly applied machine choices' {
    BeforeEach {
        Mock -ModuleName Atlas.Registry Get-AtlasRegistryValueState {
            param($Name)
            switch ($Name) {
                'Location' { [pscustomobject]@{ KeyExists = $true; ValueExists = $true; Kind = 'String'; Data = 'Allow' } }
                'Copilot' { [pscustomobject]@{ KeyExists = $true; ValueExists = $false; Kind = $null; Data = $null } }
                'Unrelated' { [pscustomobject]@{ KeyExists = $true; ValueExists = $true; Kind = 'String'; Data = 'Deny' } }
            }
        }
    }

    It 'returns an empty table when no toggle state was recorded' {
        $records = Get-AtlasToggleStateRecords -StateRoot (Join-Path $TestDrive 'missing-state')
        $records | Should -BeOfType [hashtable]
        $records.Count | Should -Be 0
    }

    It 'builds the entry-point report using public commands and forwards the recorded choices' {
        Mock Test-AtlasToggleDrift { @() }
        Mock Get-AtlasToggleStateRecords { @{ Location = 1; Copilot = 1 } }
        Mock Test-AtlasTweakCategory { @() }
        Mock Test-AtlasTweakCategory -ParameterFilter { $RegistryScope -eq 'CurrentUser' } {
            [pscustomobject]@{ Tweak = 'user-fixture'; Kind = 'Registry'; Target = 'HKCU\Fixture'; Reason = 'value is missing' }
        }
        $report = Get-AtlasHealthReport -Context $script:choiceContext -Document $script:healthDocument -Categories privacy
        $report.healthy | Should -BeFalse
        @($report.tweakDrift).Count | Should -Be 1
        $report.tweakDrift[0].Tweak | Should -Be 'user-fixture'
        Should -Invoke Get-AtlasToggleStateRecords -Times 1 -Exactly
        Should -Invoke Test-AtlasToggleDrift -Times 1 -Exactly -ParameterFilter {
            @($Scope) -contains 'Machine' -and @($Scope) -contains 'User'
        }
        Should -Invoke Test-AtlasTweakCategory -Times 3 -Exactly
        foreach ($scope in 'Machine', 'ProtectedCurrentUser', 'CurrentUser') {
            Should -Invoke Test-AtlasTweakCategory -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'privacy' -and $RegistryScope -ceq $scope -and
                $RecordedToggleStates.Location -eq 1 -and $RecordedToggleStates.Copilot -eq 1
            }
        }
    }

    It 'is not healthy when only a recorded toggle state drifted' {
        Mock Test-AtlasToggleDrift {
            [pscustomobject]@{ Toggle = 'Location'; State = 1; Scope = 'Machine'; Kind = 'Registry'; Target = 'HKLM\Fixture'; Reason = 'value data differs' }
        }
        Mock Get-AtlasToggleStateRecords { @{} }
        Mock Test-AtlasTweakCategory { @() }
        $report = Get-AtlasHealthReport -Context $script:choiceContext -Document $script:healthDocument -Categories privacy
        $report.healthy | Should -BeFalse
        @($report.toggleDrift).Count | Should -Be 1
        @($report.tweakDrift).Count | Should -Be 0
    }

    It 'checks the Standalone tweaks the install plan ran, in machine scope with the recorded choices' {
        $manifest = @{ Standalone = @(
                @{ Slug = 'scripts/fresh-only'; ParentModes = @('Fresh') }
                @{ Slug = 'qol/nested/upgrade-only'; ParentModes = @('Upgrade') }
            ) }
        $root = Join-Path $TestDrive 'Tweaks'
        @(Get-AtlasHealthStandaloneTweakPath -Context $script:choiceContext -Manifest $manifest -TweaksRoot $root) |
            Should -Be @(Join-Path $root 'scripts\fresh-only.psd1')
        $upgraded = $script:choiceContext.PSObject.Copy()
        $upgraded.IsUpgrade = $true
        @(Get-AtlasHealthStandaloneTweakPath -Context $upgraded -Manifest $manifest -TweaksRoot $root) |
            Should -Be @(Join-Path $root 'qol\nested\upgrade-only.psd1')

        # The fixture's HKLM entries drift only when read in machine scope.
        Mock Test-AtlasToggleDrift { @() }
        Mock Test-AtlasTweakCategory { @() }
        Mock Get-AtlasToggleStateRecords { @{} }
        $report = Get-AtlasHealthReport -Context $script:choiceContext -Document $script:healthDocument -Categories privacy `
            -StandaloneTweakPaths $script:choiceFile
        $report.healthy | Should -BeFalse
        @($report.tweakDrift | Where-Object Tweak -eq 'Choice fixture').Count | Should -Be 2

        Mock Get-AtlasToggleStateRecords { @{ Location = 1; Copilot = 1 } }
        $report = Get-AtlasHealthReport -Context $script:choiceContext -Document $script:healthDocument -Categories privacy `
            -StandaloneTweakPaths $script:choiceFile
        $report.healthy | Should -BeTrue
    }

    It 'reports <Expected> drifted values when the recorded choices are <Label>' -TestCases @(
        @{ Label = 'absent'; Recorded = @{}; Expected = 2 }
        @{ Label = 'enabled'; Recorded = @{ Location = 1; Copilot = 1 }; Expected = 0 }
        @{ Label = 'in another state'; Recorded = @{ Location = 0; Copilot = 0 }; Expected = 2 }
    ) {
        $drift = @(Test-AtlasTweak -Path $script:choiceFile -Context $script:choiceContext -RecordedToggleStates $Recorded)
        $drift.Count | Should -Be $Expected
        if ($Expected) {
            @($drift.Reason) | Should -Contain 'value data differs'
            @($drift.Reason) | Should -Contain 'value is missing'
        }
    }

    It 'still detects a wrong override value and unrelated drift' {
        Mock -ModuleName Atlas.Registry Get-AtlasRegistryValueState {
            [pscustomobject]@{ KeyExists = $true; ValueExists = $true; Kind = 'String'; Data = 'Wrong' }
        }
        $drift = @(Test-AtlasTweak -Path $script:choiceFile -Context $script:choiceContext -RecordedToggleStates @{ Location = 1; Copilot = 1 })
        $drift.Count | Should -Be 3
        ($drift | Where-Object Target -like '*\Copilot').Reason | Should -Be 'value still exists'
    }

    It 'passes recorded choices through manifest category verification' {
        $root = Join-Path $TestDrive 'tree'
        New-Item (Join-Path $root 'Cat') -ItemType Directory -Force | Out-Null
        Copy-Item $script:choiceFile (Join-Path $root 'Cat\choice.psd1')
        "@{ Categories = @( @{ Name = 'Cat'; Tweaks = @('choice') } ) }" | Set-Content (Join-Path $root 'tweaks.manifest.psd1')
        @(Test-AtlasTweakCategory -Name Cat -TweaksRoot $root -Context $script:choiceContext -RecordedToggleStates @{ Location = 1; Copilot = 1 }).Count | Should -Be 0
    }

    It 'validates the supported override declarations' {
        @(Test-AtlasTweakSchema -Path $script:choiceFile).Count | Should -Be 0
    }

    It 'rejects malformed or scope-ambiguous override metadata' -TestCases @(
        @{ Replacement = "VerifyWithToggle = 'Location'" }
        @{ Replacement = "VerifyWithToggle = @{ Name = 'Location'; State = '1'; Type = 'String'; Data = 'Allow' }" }
        @{ Replacement = "VerifyWithToggle = @{ Name = 'Location'; State = 1; Operation = 'DeleteKey' }" }
        @{ Replacement = "VerifyWithToggle = @{ Name = 'Location'; State = 1; Type = 'String' }" }
        @{ Replacement = "SkipVerification = 'Ignore'; VerifyWithToggle = @{ Name = 'Location'; State = 1; Type = 'String'; Data = 'Allow' }" }
    ) {
        param($Replacement)
        $invalid = Join-Path $TestDrive 'invalid.psd1'
        (Get-Content $script:choiceFile -Raw).Replace("VerifyWithToggle = @{ Name = 'Location'; State = 1; Type = 'String'; Data = 'Allow' }", $Replacement) | Set-Content $invalid
        (@(Test-AtlasTweakSchema -Path $invalid).Problem -join "`n") | Should -BeLike '*VerifyWithToggle*'
    }

    It 'verifies a replayed current-user choice in the requested user scope' {
        $userFile = Join-Path $TestDrive 'user.psd1'
        (Get-Content $script:choiceFile -Raw).Replace('HKLM\', 'HKCU\') | Set-Content $userFile
        @(Test-AtlasTweakSchema -Path $userFile).Count | Should -Be 0
        @(Test-AtlasTweak -Path $userFile -RegistryScope CurrentUser -Context $script:choiceContext).Count | Should -Be 2
        @(Test-AtlasTweak -Path $userFile -RegistryScope CurrentUser -Context $script:choiceContext -RecordedToggleStates @{ Location = 1; Copilot = 1 }).Count | Should -Be 0
        Should -Invoke -ModuleName Atlas.Registry Get-AtlasRegistryValueState -ParameterFilter { $Path -like 'HKLM*' } -Times 0 -Exactly
    }

    It 'rejects an override on a registry scope health cannot verify' {
        # The default-user hive is a valid tweak target, so only the override rule rejects this.
        $invalid = Join-Path $TestDrive 'default-user.psd1'
        (Get-Content $script:choiceFile -Raw).Replace(
            "Path = 'HKLM\SOFTWARE\AtlasHealthFixture'; Name = 'Location'",
            "Path = 'HKU\Atlas_DefaultUser\SOFTWARE\AtlasHealthFixture'; Name = 'Location'") | Set-Content $invalid
        (@(Test-AtlasTweakSchema -Path $invalid).Problem -join "`n") | Should -BeLike '*VerifyWithToggle*'
    }
}
