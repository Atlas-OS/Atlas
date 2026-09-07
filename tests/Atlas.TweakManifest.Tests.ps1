BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
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

    It 'ships the registry-file RunAs verb as a fixed Administrator reg import' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $qol = @($manifest.Categories | Where-Object { $_.Name -eq 'qol' })[0]
        $relativeRoot = 'qol\explorer\add-context-menus'
        $definitionPath = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath "$relativeRoot\merge-as-administrator.psd1"
        $scriptPath = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath "$relativeRoot\merge-as-administrator.ps1"
        $legacyDefinition = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath "$relativeRoot\merge-as-trustedinstaller.psd1"
        $legacyScript = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath "$relativeRoot\merge-as-trustedinstaller.ps1"

        @($qol.Tweaks) | Should -Contain 'explorer/add-context-menus/merge-as-administrator'
        @($qol.Tweaks) | Should -Not -Contain 'explorer/add-context-menus/merge-as-trustedinstaller'
        $definitionPath | Should -Exist
        $scriptPath | Should -Exist
        $legacyDefinition | Should -Not -Exist
        $legacyScript | Should -Not -Exist

        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath
        $definition.Name | Should -BeExactly "Add 'Merge as administrator' to Context Menu"
        $definition.Script | Should -BeExactly 'merge-as-administrator.ps1'
        $definition.Description | Should -Match 'UAC-backed Administrator merge command'
        $definition.ContainsKey('Registry') | Should -BeFalse
        (@($definition.Keys | Sort-Object) -join ',') | Should -BeExactly 'Description,Name,Script'

    }

    It 'keeps category parent modes aligned with fresh and upgrade plans' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        . (Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Install\Install-Plan.ps1')
        $freshKeys = @((Get-AtlasInstallPlan -Mode Fresh -IsOobe $false).Key)
        $upgradeKeys = @((Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false).Key)

        foreach ($category in @($manifest.Categories)) {
            @($category.ParentModes) | Should -Be @('Fresh', 'Upgrade')
            $freshKeys | Should -Contain "Tweaks/$($category.Name)"
            $upgradeKeys | Should -Contain "Tweaks/$($category.Name)"
        }
    }

    It 'routes the upgrade-only theme as its own plan step directly after the Defaults phase' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $qol = @($manifest.Categories | Where-Object { $_.Name -eq 'qol' })[0]
        $themeRoute = @($manifest.Standalone | Where-Object { $_.Slug -eq 'qol/appearance/atlas-theme-upgrade' })
        $planScript = Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Install\Install-Plan.ps1'
        . $planScript
        $upgradeKeys = @((Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false).Key)
        $defaultsIndex = [Array]::IndexOf($upgradeKeys, 'Defaults')

        @($qol.Tweaks) | Should -Not -Contain 'appearance/atlas-theme-upgrade'
        @($themeRoute).Count | Should -Be 1
        @($themeRoute[0].ParentModes) | Should -Be @('Upgrade')
        $defaultsIndex | Should -BeGreaterOrEqual 0
        $upgradeKeys[$defaultsIndex + 1] | Should -BeExactly 'Tweak/qol/appearance/atlas-theme-upgrade'
        @((Get-AtlasInstallPlan -Mode Fresh -IsOobe $false).Key) |
            Should -Not -Contain 'Tweak/qol/appearance/atlas-theme-upgrade'
    }

    It 'keeps every standalone classification aligned with its PowerShell route' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $orchestrator = Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Entry\Invoke-AtlasInstall.ps1'
        . $orchestrator

        $expectedModes = @{
            'qol/set-hidden-settings-pages'          = 'Fresh'
            'scripts/set-power-settings'             = 'Fresh'
            'qol/appearance/atlas-theme-upgrade'     = 'Upgrade'
        }
        foreach ($entry in @($manifest.Standalone)) {
            $expectedModes.ContainsKey([string]$entry.Slug) | Should -BeTrue
            (@($entry.ParentModes) -join ',') | Should -Be $expectedModes[[string]$entry.Slug]
        }
        @($manifest.Standalone).Count | Should -Be $expectedModes.Count

        # Every standalone slug is a 'Tweak/<slug>' plan step in exactly the modes its
        # manifest route declares, and the orchestrator dispatches it to the Tweaks phase.
        . (Join-Path $script:repositoryRoot `
                'playbook\Executables\AtlasModules\Scripts\Install\Install-Plan.ps1')
        foreach ($entry in @($manifest.Standalone)) {
            $slug = [string]$entry.Slug
            foreach ($mode in @('Fresh', 'Upgrade', 'Reapply')) {
                $keys = @((Get-AtlasInstallPlan -Mode $mode -IsOobe $false).Key)
                $expected = if (@($entry.ParentModes) -ccontains $mode) { 1 } else { 0 }
                @($keys | Where-Object { $_ -ceq "Tweak/$slug" }).Count |
                    Should -Be $expected -Because "'$slug' routes through modes $(@($entry.ParentModes) -join ',')"
            }

            $dispatched = New-Object Collections.Generic.List[object]
            $runner = {
                param($Path, $Parameters)
                $dispatched.Add([pscustomobject]@{ Path = $Path; Parameters = $Parameters })
            }.GetNewClosure()
            Invoke-AtlasInstallAction -Step ([pscustomobject]@{ Key = "Tweak/$slug"; Replay = 'Once' }) `
                -ScriptsRoot $TestDrive -SourceScriptsRoot $TestDrive -ScriptRunner $runner `
                -PhaseStarter {} -PhaseStopper {}
            $dispatched.Count | Should -Be 1
            $dispatched[0].Path | Should -Be ([IO.Path]::Combine(
                    [IO.Path]::GetFullPath($TestDrive), 'Install\Phases\Invoke-TweaksPhase.ps1'))
            $dispatched[0].Parameters.Slug | Should -BeExactly $slug
        }

        # The former lifecycle checkpoints for these tweaks no longer exist.
        foreach ($removed in @('HiddenSettingsPages', 'PowerSettings')) {
            {
                Get-AtlasInstallCheckpointAction -Target $removed `
                    -ScriptsRoot $TestDrive -SourceScriptsRoot $TestDrive
            } | Should -Throw "*Unsupported install checkpoint '$removed'*"
        }
    }
}

Describe 'Send-To install-time execution boundary' {
    It 'runs the Atlas.Shell companion directly as the current user' {
        $definitionPath = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath 'qol\explorer\debloat-send-to.psd1'
        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath

        $definition.Script | Should -BeExactly 'debloat-send-to.ps1'
        $definition.RunAs | Should -BeExactly 'User'
        $definition.Oobe | Should -BeFalse
        $definition.ContainsKey('Run') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path (Split-Path -Path $definitionPath -Parent) `
                -ChildPath $definition.Script) -PathType Leaf | Should -BeTrue
    }
}

Describe 'News and Interests install-time execution boundary' {
    It 'applies and records the Widgets toggle instead of duplicating its policy writes' {
        $definitionPath = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath 'qol\taskbar\disable-news-and-interests.psd1'
        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath

        @($definition.Toggle).Count | Should -Be 1
        $definition.Toggle[0].Name | Should -BeExactly 'Widgets'
        $definition.Toggle[0].State | Should -BeExactly 'Disable'

        # The device policy covers the taskbar as well as the Widgets board.
        $definition.ContainsKey('Registry') | Should -BeFalse
    }
}
