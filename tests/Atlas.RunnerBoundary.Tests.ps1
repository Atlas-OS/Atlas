BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
    $script:ConfigurationRoot = Join-Path -Path $script:RepoRoot -ChildPath 'playbook\Configuration'
    $script:CustomYamlPath = Join-Path -Path $script:ConfigurationRoot -ChildPath 'custom.yml'
    $script:CustomYaml = [IO.File]::ReadAllText($script:CustomYamlPath)
    $script:ConfigurationFiles = @(Get-ChildItem -LiteralPath $script:ConfigurationRoot -Filter '*.yml' -File -Recurse)

    function Get-AtlasYamlAction {
        param([Parameter(Mandatory = $true)][IO.FileInfo]$File)

        $lines = [IO.File]::ReadAllLines($File.FullName)
        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -notmatch '^\s*-\s+!(?<Type>[A-Za-z]+)\s*:') {
                continue
            }
            $type = $Matches.Type

            $end = $index + 1
            while ($end -lt $lines.Count -and $lines[$end] -notmatch '^\s*-\s+![A-Za-z]+\s*:') {
                $end++
            }

            [pscustomobject]@{
                File         = $File
                RelativePath = $File.FullName.Substring($script:ConfigurationRoot.Length + 1)
                Line         = $index + 1
                Type         = $type
                Text         = $lines[$index..($end - 1)] -join "`n"
            }
        }
    }

    $script:Actions = @($script:ConfigurationFiles | ForEach-Object { Get-AtlasYamlAction -File $_ })
}

Describe 'AME runner boundary' {
    It 'keeps only the reviewed runner action types' {
        $actual = @($script:Actions.Type | Sort-Object -Unique)
        $expected = @('appx', 'powerShell', 'registryKey', 'task', 'writeStatus')

        Compare-Object -ReferenceObject $expected -DifferenceObject $actual | Should -BeNullOrEmpty

        @($script:Actions | Where-Object Type -eq 'appx' |
            Where-Object RelativePath -ne 'atlas\appx.yml') | Should -BeNullOrEmpty
    }

    It 'contains no generic runner process or registry-value mutations' {
        $configurationText = ($script:ConfigurationFiles | ForEach-Object {
                [IO.File]::ReadAllText($_.FullName)
            }) -join "`n"

        $configurationText | Should -Not -Match '(?m)^\s*-\s+!(?:taskKill|run|registryValue)\s*:'
    }

    It 'retains only the exact task-composition includes' {
        $tasks = @($script:Actions | Where-Object Type -eq 'task')
        $taskPaths = @($tasks | ForEach-Object {
                if ($_.Text -notmatch 'path:\s*["''](?<Path>[^"'']+)["'']') {
                    throw "Task action at $($_.RelativePath):$($_.Line) has no quoted path."
                }
                $Matches.Path
            })

        Compare-Object -ReferenceObject @(
            'atlas\start.yml'
            'atlas\appx.yml'
            'atlas\default.yml'
            'tweaks.yml'
        ) -DifferenceObject $taskPaths | Should -BeNullOrEmpty
        $taskPaths.Count | Should -Be 4
        $script:CustomYaml | Should -Not -Match 'atlas[\\/]components\.yml'
        (Join-Path -Path $script:ConfigurationRoot -ChildPath 'atlas\components.yml') | Should -Not -Exist
    }

    It 'retains one ISO-only registry mutation for the offline WdBoot key' {
        $registryActions = @($script:Actions | Where-Object Type -eq 'registryKey')
        $registryActions.Count | Should -Be 1
        $registryActions[0].RelativePath | Should -BeExactly 'custom.yml'
        $registryActions[0].Text | Should -Match ([regex]::Escape('HKLM\OfflineSys\ControlSet001\Services\WdBoot'))
        $registryActions[0].Text | Should -Match '(?m)^\s+operation:\s+delete\s*$'
        $registryActions[0].Text | Should -Match '(?m)^\s+option:\s+[''\"]defender-disable[''\"]\s*$'
        $registryActions[0].Text | Should -Match '(?m)^\s+iso:\s+only\s*$'
        $registryActions[0].Text | Should -Match '(?m)^\s+onUpgrade:\s+false\s*$'
    }

    It 'halts on every remaining PowerShell mutation failure' {
        $powerShellActions = @($script:Actions | Where-Object Type -eq 'powerShell')
        $unchecked = @($powerShellActions | Where-Object {
                $_.Text -notmatch 'handleExitCodes\s*:\s*\{\s*["'']!0["'']\s*:\s*halt\s*\}'
            } | ForEach-Object { "$($_.RelativePath):$($_.Line)" })

        $unchecked | Should -BeNullOrEmpty `
            -Because 'all current PowerShell actions mutate install state and must surface failure to AME'
    }

    It 'turns inline and native command failures into nonzero PowerShell outcomes' {
        $flagActions = @($script:Actions | Where-Object {
                $_.Type -eq 'powerShell' -and $_.Text -match 'AtlasModules\\Flags'
            })
        $flagActions.Count | Should -BeGreaterThan 1
        @($flagActions | Where-Object {
                $_.Text -notmatch '\$ErrorActionPreference\s*=\s*''''Stop'''''
            }) | Should -BeNullOrEmpty

        $hiveActions = @($script:Actions | Where-Object {
                $_.Type -eq 'powerShell' -and $_.Text -match 'reg\.exe.+?(?:load|unload)\s+HKU\\AME_UserHive_Default'
            })
        $hiveActions.Count | Should -Be 2
        @($hiveActions | Where-Object {
                $_.Text -notmatch '\$LASTEXITCODE\s+-ne\s+0' -or $_.Text -notmatch '\bthrow\b'
            }) | Should -BeNullOrEmpty `
            -Because 'native failures do not set powershell.exe exit status unless the shim throws explicitly'
    }
}

Describe 'PowerShell orchestration replacements' {
    It 'runs the checked ShellRefresh phase between PreInstall and Environment' {
        $preInstall = $script:CustomYaml.IndexOf('-Phase PreInstall', [StringComparison]::Ordinal)
        $shellRefresh = $script:CustomYaml.IndexOf('-Phase ShellRefresh', [StringComparison]::Ordinal)
        $environment = $script:CustomYaml.IndexOf('-Phase Environment', [StringComparison]::Ordinal)

        $preInstall | Should -BeGreaterOrEqual 0
        $shellRefresh | Should -BeGreaterThan $preInstall
        $environment | Should -BeGreaterThan $shellRefresh
    }

    It 'stops both shell processes and restarts Explorer unelevated as the user' {
        $phase = [IO.File]::ReadAllText((Join-Path $script:RepoRoot `
                    'playbook\Executables\AtlasModules\Scripts\Phases\Invoke-ShellRefreshPhase.ps1'))

        $phase | Should -Match 'Stop-AtlasProcess\s+-Name\s+["'']explorer["'']\s*,\s*["'']ShellExperienceHost["'']'
        $phase | Should -Match 'Invoke-AtlasAsUser\s+-FilePath\s+\$explorerPath\s+-Wait:\$false'
        $phase | Should -Not -Match 'Invoke-AtlasAsUser[^\r\n]*-Elevated'
    }

    It 'keeps Edge removal and Chat policy inside the TrustedInstaller Components phase' {
        $phase = [IO.File]::ReadAllText((Join-Path $script:RepoRoot `
                    'playbook\Executables\AtlasModules\Scripts\Phases\Invoke-ComponentsPhase.ps1'))
        $appx = [IO.File]::ReadAllText((Join-Path $script:ConfigurationRoot 'atlas\appx.yml'))

        $phase | Should -Match '(?s)Test-AtlasOption\s+-Name\s+[''\"]uninstall-edge[''\"].+?Invoke-AtlasAsUser.+?-Elevated'
        $phase | Should -Match 'Remove-Edge\.ps1 failed with exit code'
        $phase | Should -Match 'Set-ItemProperty[^\r\n]+ConfigureChatAutoInstall[^\r\n]+-Type\s+DWord'
        $appx | Should -Not -Match 'ConfigureChatAutoInstall'

        $interactiveRemoval = $phase.IndexOf('Invoke-AtlasAsUser -FilePath $powerShellExe', [StringComparison]::Ordinal)
        $firstLiveMutation = $phase.IndexOf("Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE", [StringComparison]::Ordinal)
        $interactiveRemoval | Should -BeGreaterOrEqual 0
        $firstLiveMutation | Should -BeGreaterThan $interactiveRemoval `
            -Because 'interactive Edge removal must retain its ordering before every live-system Components mutation'
    }
}
