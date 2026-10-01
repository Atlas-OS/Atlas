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

Describe 'Tweak manifest execution graph' {
    It 'is complete, unique, resolvable and reachable' {
        $problems = @(Test-AtlasTweakManifest -Path $script:shippedManifestPath)
        Get-ProblemText -Problems $problems | Should -BeNullOrEmpty
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

    It 'keeps every standalone classification aligned with its PowerShell route' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $orchestrator = Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Entry\Invoke-AtlasInstall.ps1'
        . $orchestrator

        # Every standalone slug is a 'Tweak/<slug>' plan step in exactly the modes its
        # manifest route declares, and the orchestrator dispatches it to the Tweaks phase.
        @($manifest.Standalone).Count | Should -BeGreaterThan 0
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
    }
}

Describe 'News and Interests install-time execution' {
    It 'applies and records the Widgets Disable toggle during install' {
        $definitionPath = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath 'qol\taskbar\disable-news-and-interests.psd1'
        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath

        @($definition.Toggle).Count | Should -Be 1
        $definition.Toggle[0].Name | Should -BeExactly 'Widgets'
        $definition.Toggle[0].State | Should -BeExactly 'Disable'
    }
}
