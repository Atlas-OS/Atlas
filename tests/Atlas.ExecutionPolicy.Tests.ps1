Describe 'Windows PowerShell execution policy ownership' {
    BeforeAll {
        $script:phasePath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Phases\Invoke-EnvironmentPhase.ps1'
        $tokens = $null
        $errors = $null
        $script:ast = [Management.Automation.Language.Parser]::ParseFile(
            $script:phasePath, [ref]$tokens, [ref]$errors
        )
        @($errors).Count | Should -Be 0
    }

    It 'sets RemoteSigned only on fresh installs' {
        $source = $script:ast.Extent.Text

        $source | Should -Match 'if \(-not \$context\.IsUpgrade\)'
        $source | Should -Match 'Set-AtlasWindowsPowerShellExecutionPolicy'
        $source | Should -Match "'RemoteSigned'"
        $source | Should -Match 'Preserving the existing Windows PowerShell execution policy during upgrade or reapply'
    }

    It 'writes both registry views on a 64-bit operating system' {
        $function = $script:ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Set-AtlasWindowsPowerShellExecutionPolicy'
            }, $true)
        $source = $function.Extent.Text

        $function | Should -Not -BeNullOrEmpty
        $source | Should -Match 'RegistryView\]::Registry64'
        $source | Should -Match 'RegistryView\]::Registry32'
        $source | Should -Match 'RegistryView\]::Default'
        $source | Should -Match 'RegistryHive\]::LocalMachine'
    }

    It 'reads the persisted value back before continuing' {
        $source = $script:ast.Extent.Text

        $source | Should -Match "GetValue\('ExecutionPolicy', \$null\)"
        $source | Should -Match "\$actual -cne 'RemoteSigned'"
    }
}
