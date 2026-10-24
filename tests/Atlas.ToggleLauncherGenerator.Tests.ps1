BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:GeneratorScript = Join-Path $script:AtlasTestRepoRoot 'tools\dev\New-ToggleLaunchers.ps1'

    # A minimal repository: one toggle whose launcher name needs '+', plus a listed
    # hand-written launcher the generator must leave alone.
    function New-LauncherFixture {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $toggles = Join-Path $root 'playbook\Executables\AtlasModules\Toggles\Troubleshooting'
        $desktop = Join-Path $root 'playbook\Executables\AtlasDesktop'
        $toolbox = Join-Path $root 'playbook\Executables\AtlasModules\Toolbox'
        New-Item -Path $toggles, (Join-Path $desktop '9. Troubleshooting'), $toolbox -ItemType Directory -Force | Out-Null
        $definition = "@{ Name = 'Repair'; States = @(@{ Name = 'Run'; Launcher = '9. Troubleshooting\Fix Visual C++ Errors.cmd' }) }"
        [IO.File]::WriteAllText((Join-Path $toggles 'Repair.psd1'), $definition, [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $desktop '9. Troubleshooting\Set services to defaults.cmd'), "@echo off`r`n", [Text.Encoding]::ASCII)
        return $root
    }

    function Invoke-LauncherGenerator {
        param([string]$Root, [switch]$Validate)
        $arguments = @('-NoProfile', '-File', $script:GeneratorScript, '-RepoRoot', $Root)
        if ($Validate) {
            $arguments += '-Validate'
        }
        # Repository tooling runs under PowerShell 7, like the build.
        $output = & $script:AtlasTestToolsHost @arguments 2>&1
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }
}

Describe 'Launcher generator' {
    It 'generates and validates a launcher whose path contains +, beside a listed hand-written launcher' {
        $root = New-LauncherFixture
        $generated = Invoke-LauncherGenerator -Root $root
        $generated.ExitCode | Should -Be 0 -Because $generated.Output
        Join-Path $root 'playbook\Executables\AtlasDesktop\9. Troubleshooting\Fix Visual C++ Errors.cmd' |
            Should -Exist

        $validated = Invoke-LauncherGenerator -Root $root -Validate
        $validated.ExitCode | Should -Be 0 -Because $validated.Output
    }

    It 'rejects a hand-written launcher that is not listed: <Tree>' -ForEach @(
        @{ Tree = 'AtlasDesktop'; Relative = 'playbook\Executables\AtlasDesktop\Extra.cmd' }
        @{ Tree = 'Toolbox'; Relative = 'playbook\Executables\AtlasModules\Toolbox\Scripts\Extra.cmd' }
    ) {
        $root = New-LauncherFixture
        (Invoke-LauncherGenerator -Root $root).ExitCode | Should -Be 0
        $extra = Join-Path $root $Relative
        New-Item -Path (Split-Path -Parent $extra) -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($extra, "@echo off`r`necho hand-written`r`n", [Text.Encoding]::ASCII)

        $validated = Invoke-LauncherGenerator -Root $root -Validate
        $validated.ExitCode | Should -Be 1
        $validated.Output | Should -BeLike "*Unlisted launcher: '$extra'*"
    }
}
