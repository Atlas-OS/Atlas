BeforeAll {
    $script:repositoryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $script:modulesRoot = Join-Path -Path $script:repositoryRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $script:modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $script:modulesRoot -ChildPath 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force

    $script:shippedTweaksRoot = Join-Path -Path $script:repositoryRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Tweaks'
    $script:shippedManifestPath = Join-Path -Path $script:shippedTweaksRoot -ChildPath 'tweaks.manifest.psd1'

    function New-TweakManifestFixture {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Manifest,

            [hashtable]$Definitions = @{}
        )

        $root = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString('N'))
        New-Item -Path $root -ItemType Directory -Force | Out-Null
        foreach ($slug in @($Definitions.Keys)) {
            $definitionPath = Join-Path -Path $root -ChildPath (($slug -replace '/', '\') + '.psd1')
            New-Item -Path (Split-Path -Path $definitionPath -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -LiteralPath $definitionPath -Value $Definitions[$slug] -Encoding UTF8
        }
        Set-Content -LiteralPath (Join-Path -Path $root -ChildPath 'tweaks.manifest.psd1') -Value $Manifest -Encoding UTF8
        return $root
    }

    function Get-ProblemText {
        param([object[]]$Problems)
        return (@($Problems | ForEach-Object { $_.Problem }) -join "`n")
    }

    function Get-YamlPowerShellAction {
        param(
            [string]$Yaml,
            [string]$CommandFragment
        )

        $actionPattern = '(?ms)^  - !powerShell:\s*\r?\n(?:(?!^  - !).)*(?=^  - !|\z)'
        return @([regex]::Matches($Yaml, $actionPattern) |
            Where-Object { $_.Value -like "*$CommandFragment*" } |
            ForEach-Object { $_.Value })
    }
}

Describe 'Test-AtlasTweakManifest shape and graph validation' {
    It 'rejects unknown keys and scalar values where arrays are required' {
        $root = New-TweakManifestFixture -Manifest @'
@{
    Categories = 'networking'
    Standalone = @()
    Disabled   = @()
    Unexpected = $true
}
'@

        $problemText = Get-ProblemText -Problems @(Test-AtlasTweakManifest -Path (Join-Path $root 'tweaks.manifest.psd1'))

        $problemText | Should -Match "unknown key 'Unexpected'"
        $problemText | Should -Match 'Manifest Categories must be an array'
    }

    It 'rejects duplicate categories and enabled slugs and reports missing definitions' {
        $root = New-TweakManifestFixture -Definitions @{
            'qol/one' = "@{ Name = 'One' }"
        } -Manifest @'
@{
    Categories = @(
        @{ Name = 'qol'; ParentModes = @('Fresh'); Tweaks = @('one', 'missing') }
        @{ Name = 'qol'; ParentModes = @('Fresh'); Tweaks = @('one') }
    )
    Standalone = @()
    Disabled   = @()
}
'@

        $problemText = Get-ProblemText -Problems @(Test-AtlasTweakManifest -Path (Join-Path $root 'tweaks.manifest.psd1'))

        $problemText | Should -Match "Duplicate category name 'qol'"
        $problemText | Should -Match "Tweak slug 'qol/one' is classified more than once"
        $problemText | Should -Match "Enabled tweak 'qol/missing' does not resolve"
    }

    It 'requires every definition to be uniquely enabled or disabled with a reason' {
        $root = New-TweakManifestFixture -Definitions @{
            'qol/enabled'      = "@{ Name = 'Enabled' }"
            'qol/standalone'   = "@{ Name = 'Standalone' }"
            'qol/disabled'     = "@{ Name = 'Disabled' }"
            'qol/unclassified' = "@{ Name = 'Unclassified' }"
        } -Manifest @'
@{
    Categories = @(
        @{ Name = 'qol'; ParentModes = @('Fresh'); Tweaks = @('enabled') }
    )
    Standalone = @(
        @{ Slug = 'qol/standalone'; ParentModes = @('Fresh') }
    )
    Disabled = @(
        @{ Slug = 'qol/disabled'; Reason = '' }
    )
}
'@

        $problemText = Get-ProblemText -Problems @(Test-AtlasTweakManifest -Path (Join-Path $root 'tweaks.manifest.psd1'))

        $problemText | Should -Match "Disabled tweak 'qol/disabled' must record a non-empty Reason"
        $problemText | Should -Match "Tweak definition 'qol/unclassified' is unclassified"
    }

    It 'rejects an enabled tweak whose parent route and OnUpgrade gates cannot intersect' {
        $root = New-TweakManifestFixture -Definitions @{
            'qol/upgrade-only' = "@{ Name = 'Upgrade only'; OnUpgrade = 'Only' }"
        } -Manifest @'
@{
    Categories = @(
        @{ Name = 'qol'; ParentModes = @('Fresh'); Tweaks = @('upgrade-only') }
    )
    Standalone = @()
    Disabled   = @()
}
'@

        $problemText = Get-ProblemText -Problems @(Test-AtlasTweakManifest -Path (Join-Path $root 'tweaks.manifest.psd1'))

        $problemText | Should -Match "Enabled tweak 'qol/upgrade-only' is unreachable"
        $problemText | Should -Match 'parent modes \[Fresh\]'
        $problemText | Should -Match "OnUpgrade 'Only'"
    }

    It 'accepts matching fresh, upgrade and both-mode routes' {
        $root = New-TweakManifestFixture -Definitions @{
            'qol/fresh-only'   = "@{ Name = 'Fresh only'; OnUpgrade = 'Skip' }"
            'qol/upgrade-only' = "@{ Name = 'Upgrade only'; OnUpgrade = 'Only' }"
            'qol/both'         = "@{ Name = 'Both'; OnUpgrade = 'Both' }"
        } -Manifest @'
@{
    Categories = @(
        @{ Name = 'qol'; ParentModes = @('Fresh'); Tweaks = @('fresh-only') }
    )
    Standalone = @(
        @{ Slug = 'qol/upgrade-only'; ParentModes = @('Upgrade') }
        @{ Slug = 'qol/both'; ParentModes = @('Fresh', 'Upgrade') }
    )
    Disabled = @()
}
'@

        $problems = @(Test-AtlasTweakManifest -Path (Join-Path $root 'tweaks.manifest.psd1'))
        Get-ProblemText -Problems $problems | Should -BeNullOrEmpty
    }
}

Describe 'Shipped tweak manifest execution graph' {
    It 'is complete, unique, resolvable and reachable' {
        $problems = @(Test-AtlasTweakManifest -Path $script:shippedManifestPath)
        Get-ProblemText -Problems $problems | Should -BeNullOrEmpty
    }

    It 'keeps category parent modes aligned with the fresh-only tweaks YAML route' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $tweaksYaml = Get-Content -LiteralPath (Join-Path $script:repositoryRoot 'playbook\Configuration\tweaks.yml') -Raw

        $tweaksYaml | Should -Match '(?m)^onUpgrade:\s*false\s*$'
        foreach ($category in @($manifest.Categories)) {
            @($category.ParentModes) | Should -Be @('Fresh')
            $escapedCategory = [regex]::Escape([string]$category.Name)
            @([regex]::Matches($tweaksYaml, "-Phase Tweaks -Category $escapedCategory(?:'|\s)")).Count | Should -Be 1
        }
    }

    It 'routes the upgrade-only theme through the upgrade-only PowerShell Revert phase' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $qol = @($manifest.Categories | Where-Object { $_.Name -eq 'qol' })[0]
        $themeRoute = @($manifest.Standalone | Where-Object { $_.Slug -eq 'qol/appearance/atlas-theme-upgrade' })
        $revertPhase = Get-Content -LiteralPath (Join-Path $script:repositoryRoot 'playbook\Executables\AtlasModules\Scripts\Phases\Invoke-RevertPhase.ps1') -Raw
        $customYaml = Get-Content -LiteralPath (Join-Path $script:repositoryRoot 'playbook\Configuration\custom.yml') -Raw
        $revertAction = @(Get-YamlPowerShellAction -Yaml $customYaml -CommandFragment '-Phase Revert')

        @($qol.Tweaks) | Should -Not -Contain 'appearance/atlas-theme-upgrade'
        @($themeRoute).Count | Should -Be 1
        @($themeRoute[0].ParentModes) | Should -Be @('Upgrade')
        @($revertAction).Count | Should -Be 1
        $revertAction[0] | Should -Match '(?m)^\s+onUpgrade:\s*true\s*$'
        $revertPhase | Should -Match 'if \(-not \$context\.IsUpgrade\)'
        $revertPhase | Should -Match "Scripts\\Tweaks\\qol\\appearance\\atlas-theme-upgrade\.psd1"
        $revertPhase | Should -Match 'Invoke-AtlasTweak -Path \$themeUpgrade'
    }

    It 'keeps every standalone classification aligned with its PowerShell route' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $customYaml = Get-Content -LiteralPath (Join-Path $script:repositoryRoot 'playbook\Configuration\custom.yml') -Raw
        $tweaksYaml = Get-Content -LiteralPath (Join-Path $script:repositoryRoot 'playbook\Configuration\tweaks.yml') -Raw

        $expectedModes = @{
            'qol/set-hidden-settings-pages'          = 'Fresh,Upgrade'
            'scripts/set-power-settings'             = 'Fresh'
            'misc/enable-notifications'              = 'Fresh,Upgrade'
            'qol/appearance/atlas-theme-upgrade'     = 'Upgrade'
        }
        foreach ($entry in @($manifest.Standalone)) {
            $expectedModes.ContainsKey([string]$entry.Slug) | Should -BeTrue
            (@($entry.ParentModes) -join ',') | Should -Be $expectedModes[[string]$entry.Slug]
        }
        @($manifest.Standalone).Count | Should -Be $expectedModes.Count

        $setHidden = @(Get-YamlPowerShellAction -Yaml $customYaml -CommandFragment 'qol\set-hidden-settings-pages.psd1')
        @($setHidden).Count | Should -Be 1
        $setHidden[0] | Should -Not -Match '(?m)^\s+onUpgrade:'

        @([regex]::Matches($tweaksYaml, [regex]::Escape('scripts\set-power-settings.psd1'))).Count | Should -Be 1
        @([regex]::Matches($tweaksYaml, [regex]::Escape('misc\enable-notifications.psd1'))).Count | Should -Be 1

        $upgradeNotifications = @(Get-YamlPowerShellAction -Yaml $customYaml -CommandFragment 'misc\enable-notifications.psd1')
        @($upgradeNotifications).Count | Should -Be 1
        $upgradeNotifications[0] | Should -Match '(?m)^\s+onUpgrade:\s*true\s*$'
    }
}
