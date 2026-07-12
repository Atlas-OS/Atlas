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

    It 'keeps category parent modes aligned with the fresh install plan' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        . (Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Internal\Install-Plan.ps1')
        $freshKeys = @((Get-AtlasInstallPlan -Mode Fresh -IsOobe $false).Key)

        foreach ($category in @($manifest.Categories)) {
            @($category.ParentModes) | Should -Be @('Fresh')
            $freshKeys | Should -Contain "Tweaks/$($category.Name)"
        }
    }

    It 'routes the upgrade-only theme through the upgrade-only PowerShell Revert phase' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $qol = @($manifest.Categories | Where-Object { $_.Name -eq 'qol' })[0]
        $themeRoute = @($manifest.Standalone | Where-Object { $_.Slug -eq 'qol/appearance/atlas-theme-upgrade' })
        $planScript = Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Internal\Install-Plan.ps1'
        . $planScript
        $revertAction = @(Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false |
                Where-Object Key -CEQ 'Revert')

        @($qol.Tweaks) | Should -Not -Contain 'appearance/atlas-theme-upgrade'
        @($themeRoute).Count | Should -Be 1
        @($themeRoute[0].ParentModes) | Should -Be @('Upgrade')
        @($revertAction).Count | Should -Be 1
    }

    It 'keeps every standalone classification aligned with its PowerShell route' {
        $manifest = Get-AtlasTweakManifest -Path $script:shippedManifestPath
        $orchestrator = Join-Path $script:repositoryRoot `
            'playbook\Executables\AtlasModules\Scripts\Invoke-AtlasInstall.ps1'
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

        $hidden = Get-AtlasInstallCheckpointAction -Target HiddenSettingsPages `
            -ScriptsRoot $TestDrive -SourceScriptsRoot $TestDrive
        $power = Get-AtlasInstallCheckpointAction -Target PowerSettings `
            -ScriptsRoot $TestDrive -SourceScriptsRoot $TestDrive
        $hidden.Arguments.Slug | Should -BeExactly 'qol/set-hidden-settings-pages'
        $power.Arguments.Slug | Should -BeExactly 'scripts/set-power-settings'
    }
}

Describe 'Send-To install-time execution boundary' {
    It 'calls the fixed internal helper directly as the current user' {
        $definitionPath = Join-Path -Path $script:shippedTweaksRoot `
            -ChildPath 'qol\explorer\debloat-send-to.psd1'
        $definition = Import-PowerShellDataFile -LiteralPath $definitionPath
        $run = @($definition.Run)

        $run.Count | Should -Be 1
        $run[0].Exe | Should -BeExactly `
            '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
        @($run[0].Args) | Should -Be @(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', '{windir}\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1',
            '-DebloatDefaults'
        )
        $run[0].Wait | Should -BeTrue
        $run[0].RunAs | Should -BeExactly 'User'
        $definition.Oobe | Should -BeFalse
        $run[0].Exe | Should -Not -Match 'AtlasDesktop|\.cmd$'
        ($run[0].Args -is [array]) | Should -BeTrue
    }
}
