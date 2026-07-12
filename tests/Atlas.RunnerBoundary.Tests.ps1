BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ConfigurationRoot = Join-Path $script:RepoRoot 'playbook\Configuration'
    $script:CustomYamlPath = Join-Path $script:ConfigurationRoot 'custom.yml'
    $script:CustomYaml = [IO.File]::ReadAllText($script:CustomYamlPath)
    $script:PowerShellExe = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
    $script:PowerShellPrefix = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass'
    $script:StateScript = '.\AtlasModules\Scripts\Initialize-AtlasInstallState.ps1'
    $script:ApplicabilityProperties = @(
        'iso', 'oobe', 'option', 'options', 'builds', 'cpuArch',
        'onUpgrade', 'onUpgradeVersions', 'previousOption'
    )

    . (Join-Path $script:RepoRoot 'tools\build\AtlasBuild\AtlasYamlAction.ps1')
    $script:Actions = @(Get-AtlasYamlAction -Path $script:CustomYamlPath `
            -RelativePath 'custom.yml')

    [xml]$playbook = [IO.File]::ReadAllText((Join-Path $script:RepoRoot 'playbook\playbook.conf'))
    $script:PlaybookVersion = [string]$playbook.Playbook.Version
    $script:FeatureOptions = @($playbook.SelectNodes('/Playbook/FeaturePages/*/Options/*/Name') |
        ForEach-Object { $_.InnerText } | Sort-Object -Unique)

    function New-AtlasFileArgument {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [string]$Tail
        )

        $arguments = "$script:PowerShellPrefix -File `"$Path`""
        if (-not [string]::IsNullOrWhiteSpace($Tail)) {
            $arguments += " $Tail"
        }
        return $arguments
    }
}

Describe 'Compact AME runner boundary' {
    It 'contains only the compact reviewed action surface' {
        $summary = Assert-AtlasConfigurationRunnerBoundary `
            -ConfigurationRoot $script:ConfigurationRoot
        $summary.Files | Should -Be 1
        $summary.Actions | Should -Be 29
        $summary.Runs | Should -Be 26

        $typeCounts = @($script:Actions | Group-Object Type | Sort-Object Name)
        @($typeCounts.Name) | Should -Be @('registryKey', 'run', 'writeStatus')
        @($typeCounts | ForEach-Object Count) | Should -Be @(1, 26, 2)
        $script:CustomYaml | Should -Not -Match '(?m)^\s*-\s*!(?:task|cmd|powerShell|taskKill|registryValue)\b'
        $script:CustomYaml | Should -Not -Match 'atlas[\\/]components\.yml'
    }

    It 'uses explicit direct-File process semantics on every run' {
        $runs = @($script:Actions | Where-Object Type -eq run)
        foreach ($action in $runs) {
            [string]$action.Properties.exe | Should -BeExactly $script:PowerShellExe
            [string]$action.Properties.args | Should -Match `
                ('^' + [regex]::Escape($script:PowerShellPrefix + ' -File ".\'))
            [string]$action.Properties.args | Should -Not -Match `
                '(?i)(?:^|\s)-(?:Command|C|EncodedCommand)(?:\s|$)'
            $action.Properties.showOutput | Should -BeTrue
            $action.Properties.showError | Should -BeTrue
            $action.Properties.exeDir | Should -BeTrue
            $action.Properties.wait | Should -BeTrue
            $action.Properties.weight | Should -Be 1
            [string]$action.Properties.handleExitCodes['!0'] | Should -BeExactly 'halt'
        }

        @($runs | Where-Object { $_.Properties.runas -ceq 'trustedInstaller' }).Count |
            Should -Be 25
        @($runs | Where-Object { $_.Properties.runas -ceq 'currentUser' }).Count |
            Should -Be 1
    }

    It 'preserves the six AME mode and OOBE selectors' {
        $prefix = New-AtlasFileArgument -Path $script:StateScript
        $expected = @(
            @{ Tail = '-Operation Begin -Mode Fresh'; Upgrade = $false; Oobe = $false }
            @{ Tail = '-Operation Begin -Mode Upgrade'; Upgrade = $true; Oobe = $false }
            @{ Tail = '-Operation Begin -Mode Reapply'; Upgrade = $true; Oobe = $false; Version = $script:PlaybookVersion }
            @{ Tail = '-Operation Begin -Mode Fresh -Oobe'; Upgrade = $false; Oobe = 'only' }
            @{ Tail = '-Operation Begin -Mode Upgrade -Oobe'; Upgrade = $true; Oobe = 'only' }
            @{ Tail = '-Operation Begin -Mode Reapply -Oobe'; Upgrade = $true; Oobe = 'only'; Version = $script:PlaybookVersion }
        )
        $beginActions = @($script:Actions | Where-Object {
                $_.Type -ceq 'run' -and
                ([string]$_.Properties.args).StartsWith(
                    "$prefix -Operation Begin ",
                    [StringComparison]::Ordinal
                )
            })
        $beginActions.Count | Should -Be 6

        foreach ($entry in $expected) {
            $matchingActions = @($beginActions | Where-Object {
                    [string]$_.Properties.args -ceq "$prefix $($entry.Tail)"
                })
            $matchingActions.Count | Should -Be 1
            $matchingActions[0].Properties.runas | Should -BeExactly 'trustedInstaller'
            $matchingActions[0].Properties.onUpgrade | Should -Be $entry.Upgrade
            $matchingActions[0].Properties.oobe | Should -Be $entry.Oobe
            if ($entry.ContainsKey('Version')) {
                @($matchingActions[0].Properties.onUpgradeVersions) |
                    Should -Be @([string]$entry.Version)
            }
            else {
                $matchingActions[0].Properties.Contains('onUpgradeVersions') | Should -BeFalse
            }
        }
    }

    It 'publishes the installing user exactly once outside OOBE' {
        $expectedArguments = New-AtlasFileArgument `
            -Path '.\AtlasModules\Scripts\Publish-AtlasInstallUser.ps1'
        $publishers = @($script:Actions | Where-Object {
                $_.Type -ceq 'run' -and $_.Properties.runas -ceq 'currentUser'
            })

        $publishers.Count | Should -Be 1
        [string]$publishers[0].Properties.args | Should -BeExactly $expectedArguments
        $publishers[0].Properties.oobe | Should -BeFalse
        foreach ($gate in @($script:ApplicabilityProperties | Where-Object { $_ -cne 'oobe' })) {
            $publishers[0].Properties.Contains($gate) | Should -BeFalse
        }
    }

    It 'captures every FeaturePage option through the same gated state operation' {
        $records = @($script:Actions | Where-Object {
                $_.Type -ceq 'run' -and
                [string]$_.Properties.args -match `
                    ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$'
            })
        $records.Count | Should -Be $script:FeatureOptions.Count

        $captured = foreach ($record in $records) {
            $match = [regex]::Match(
                [string]$record.Properties.args,
                ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$'
            )
            $name = $match.Groups['Option'].Value
            [string]$record.Properties.option | Should -BeExactly $name
            [string]$record.Properties.args | Should -BeExactly (
                New-AtlasFileArgument -Path $script:StateScript `
                    -Tail "-Operation RecordOption -Option $name"
            )
            $name
        }
        @($captured | Sort-Object) | Should -Be $script:FeatureOptions
        @($captured | Sort-Object -Unique).Count | Should -Be $script:FeatureOptions.Count
    }

    It 'commits state before the one PowerShell-owned install run' {
        $commitArguments = New-AtlasFileArgument -Path $script:StateScript `
            -Tail '-Operation Commit'
        $runArguments = New-AtlasFileArgument `
            -Path '.\AtlasModules\Scripts\Invoke-AtlasInstall.ps1' -Tail '-Run'
        $commit = @($script:Actions | Where-Object {
                $_.Type -ceq 'run' -and
                [string]$_.Properties.args -ceq $commitArguments
            })
        $install = @($script:Actions | Where-Object {
                $_.Type -ceq 'run' -and
                [string]$_.Properties.args -ceq $runArguments
            })

        $commit.Count | Should -Be 1
        $install.Count | Should -Be 1
        $install[0].Line | Should -BeGreaterThan $commit[0].Line
        $install[0].Properties.runas | Should -BeExactly 'trustedInstaller'
        foreach ($gate in $script:ApplicabilityProperties) {
            $install[0].Properties.Contains($gate) | Should -BeFalse
        }

        $afterCommit = @($script:Actions | Where-Object {
                $_.Line -gt $commit[0].Line -and $_.Type -cne 'writeStatus'
        })
        $afterCommit.Count | Should -Be 2
        @($afterCommit.Type) | Should -Be @('registryKey', 'run')
        $afterCommit[0].Line | Should -BeLessThan $install[0].Line
        $afterCommit[1].Line | Should -Be $install[0].Line
    }

    It 'retains only the mounted-image WdBoot mutation outside PowerShell' {
        $registry = @($script:Actions | Where-Object Type -eq registryKey)
        $registry.Count | Should -Be 1
        $registry[0].Properties.Count | Should -Be 5
        [string]$registry[0].Properties.path | Should -BeExactly `
            'HKLM\OfflineSys\ControlSet001\Services\WdBoot'
        [string]$registry[0].Properties.operation | Should -BeExactly 'delete'
        [string]$registry[0].Properties.option | Should -BeExactly 'defender-disable'
        [string]$registry[0].Properties.iso | Should -BeExactly 'only'
        $registry[0].Properties.onUpgrade | Should -BeFalse
    }

    It 'uses only coarse status messages owned by AME' {
        $statuses = @($script:Actions | Where-Object Type -eq writeStatus)
        $statuses.Count | Should -Be 2
        @($statuses | ForEach-Object { [string]$_.Properties.status }) |
            Should -Be @('Preparing AtlasOS installation', 'Installing AtlasOS')
        foreach ($status in $statuses) {
            $status.Properties.Count | Should -Be 1
        }
    }
}

Describe 'Bounded Atlas YAML action parsing' {
    It 'accepts a copied production runner contract' {
        $configuration = Join-Path $TestDrive 'publisher-accepted'
        New-Item -ItemType Directory -Path $configuration -Force | Out-Null
        Copy-Item -LiteralPath $script:CustomYamlPath `
            -Destination (Join-Path $configuration 'custom.yml')

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $configuration } |
            Should -Not -Throw
    }

    It 'rejects current-user execution for every other script' {
        $configuration = Join-Path $TestDrive 'publisher-rejected'
        New-Item -ItemType Directory -Path $configuration -Force | Out-Null
        $path = Join-Path $configuration 'custom.yml'
        Copy-Item -LiteralPath $script:CustomYamlPath -Destination $path
        $content = [IO.File]::ReadAllText($path)
        $marker = 'runas: trustedInstaller'
        $index = $content.LastIndexOf($marker, [StringComparison]::Ordinal)
        $index | Should -BeGreaterThan -1
        $content = $content.Remove($index, $marker.Length).Insert(
            $index,
            'runas: currentUser'
        )
        [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $configuration } |
            Should -Throw -ExpectedMessage `
                '*runas currentUser is reserved for the exact non-OOBE Publish-AtlasInstallUser.ps1 action*'
    }

    It 'rejects duplicate scalar keys in a block action' {
        $yaml = @'
title: Duplicate fixture
actions:
  - !run:
    exe: 'tool.exe'
    args: '-File ".\tool.ps1"'
    wait: true
    wait: false
'@

        { Get-AtlasYamlAction -Text $yaml -RelativePath 'duplicate.yml' } |
            Should -Throw -ExpectedMessage "*duplicate property 'wait'*"
    }
}
