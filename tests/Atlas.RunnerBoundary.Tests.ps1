BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ConfigurationRoot = Join-Path $script:RepoRoot 'playbook\Configuration'
    $script:CustomYamlPath = Join-Path $script:ConfigurationRoot 'custom.yml'
    $script:PowerShellPrefix = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass'
    $script:StateScript = '.\AtlasModules\Scripts\Entry\Initialize-AtlasInstallState.ps1'

    . (Join-Path $script:RepoRoot 'tools\build\AtlasBuild\AtlasYamlAction.ps1')
    $script:Actions = @(Get-AtlasYamlAction -Path $script:CustomYamlPath `
            -RelativePath 'custom.yml')

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
    It 'commits state before the one PowerShell-owned install run' {
        $commitArguments = New-AtlasFileArgument -Path $script:StateScript `
            -Tail '-Operation Commit'
        $runArguments = New-AtlasFileArgument `
            -Path '.\AtlasModules\Scripts\Entry\Invoke-AtlasInstall.ps1' -Tail '-Run'
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

        $afterCommit = @($script:Actions | Where-Object {
                $_.Line -gt $commit[0].Line -and $_.Type -cne 'writeStatus'
        })
        $afterCommit.Count | Should -Be 1
        @($afterCommit.Type) | Should -Be @('run')
        $afterCommit[0].Line | Should -Be $install[0].Line
    }
}

Describe 'Restricted Atlas YAML action parsing' {
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
