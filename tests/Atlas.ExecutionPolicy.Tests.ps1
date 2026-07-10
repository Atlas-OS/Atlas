Describe 'Windows PowerShell execution policy ownership' {
    BeforeAll {
        $script:repoRoot = Split-Path -Parent $PSScriptRoot
        $script:environmentPhase = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Phases\Invoke-EnvironmentPhase.ps1'
        $script:rootConfiguration = Join-Path $script:repoRoot 'playbook\Configuration\custom.yml'
    }

    It 'does not mutate machine execution policy from the Environment phase' {
        $source = Get-Content -LiteralPath $script:environmentPhase -Raw

        $source | Should -Not -Match '(?i)Set-ExecutionPolicy|ShellIds\\Microsoft\.PowerShell|[''\"]ExecutionPolicy[''\"]'
    }

    It 'does not overwrite machine execution policy at the end of the AME graph' {
        $source = Get-Content -LiteralPath $script:rootConfiguration -Raw

        $source | Should -Not -Match '(?i)ShellIds\\Microsoft\.PowerShell|value:\s*[''\"]?ExecutionPolicy'
    }
}
