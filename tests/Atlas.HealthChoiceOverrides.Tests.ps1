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
    $reportFunction = $healthAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-AtlasHealthReport'
    }, $false)
    . ([scriptblock]::Create($reportFunction.Extent.Text))
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

    It 'exposes the recorded-choice reader through the actual module manifest' {
        $reader = Get-Command Get-AtlasToggleStateRecords -Module Atlas.Toggles -ErrorAction Stop
        $records = & $reader -StateRoot (Join-Path $TestDrive 'missing-state')
        $records | Should -BeOfType [hashtable]
        $records.Count | Should -Be 0
    }

    It 'builds the entry-point report using public commands and forwards the recorded choices' {
        Mock Test-AtlasToggleDrift { @() }
        Mock Get-AtlasToggleStateRecords { @{ Location = 1; Copilot = 1 } }
        Mock Test-AtlasTweakCategory { @() }
        $document = [pscustomobject]@{
            installedVersion = 'test'; installedAt = 'test'; mode = 'Reapply'
            options = @(); history = @(); toggles = [pscustomobject]@{}
        }
        $report = Get-AtlasHealthReport -Context $script:choiceContext -Document $document -Categories privacy
        $report.healthy | Should -BeTrue
        Should -Invoke Get-AtlasToggleStateRecords -Times 1 -Exactly
        Should -Invoke Test-AtlasTweakCategory -Times 2 -Exactly -ParameterFilter {
            $RecordedToggleStates.Location -eq 1 -and $RecordedToggleStates.Copilot -eq 1
        }
    }

    It 'checks the original defaults without a recorded override' {
        $drift = @(Test-AtlasTweak -Path $script:choiceFile -Context $script:choiceContext)
        $drift.Count | Should -Be 2
        @($drift.Reason) | Should -Contain 'value data differs'
        @($drift.Reason) | Should -Contain 'value is missing'
    }

    It 'accepts the actual enabled choices and leaves the data-file defaults unchanged' {
        @(Test-AtlasTweak -Path $script:choiceFile -Context $script:choiceContext -RecordedToggleStates @{ Location = 1; Copilot = 1 }).Count | Should -Be 0
        $definition = Import-PowerShellDataFile $script:choiceFile
        $definition.Registry[0].Data | Should -Be 'Deny'
        $definition.Registry[1].Data | Should -Be 1
        @(Test-AtlasTweak -Path $script:choiceFile -Context $script:choiceContext).Count | Should -Be 2
    }

    It 'does not treat any recorded state as an enabled choice' {
        @(Test-AtlasTweak -Path $script:choiceFile -Context $script:choiceContext -RecordedToggleStates @{ Location = 0; Copilot = 0 }).Count | Should -Be 2
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
        @(Test-AtlasTweakSchema -Path $invalid).Count | Should -BeGreaterThan 0
    }

    It 'verifies a replayed current-user choice in the requested user scope' {
        $userFile = Join-Path $TestDrive 'user.psd1'
        (Get-Content $script:choiceFile -Raw).Replace('HKLM\', 'HKCU\') | Set-Content $userFile
        @(Test-AtlasTweakSchema -Path $userFile).Count | Should -Be 0
        @(Test-AtlasTweak -Path $userFile -RegistryScope CurrentUser -Context $script:choiceContext).Count | Should -Be 2
        @(Test-AtlasTweak -Path $userFile -RegistryScope CurrentUser -Context $script:choiceContext -RecordedToggleStates @{ Location = 1; Copilot = 1 }).Count | Should -Be 0
        Should -Invoke -ModuleName Atlas.Registry Get-AtlasRegistryValueState -ParameterFilter { $Path -like 'HKLM*' } -Times 0 -Exactly
    }

    It 'rejects arbitrary loaded-user hives in override metadata' {
        $invalid = Join-Path $TestDrive 'other-user.psd1'
        (Get-Content $script:choiceFile -Raw).Replace('HKLM\', 'HKU\S-1-5-21-Other\') | Set-Content $invalid
        @(Test-AtlasTweakSchema -Path $invalid).Count | Should -BeGreaterThan 0
    }
}
