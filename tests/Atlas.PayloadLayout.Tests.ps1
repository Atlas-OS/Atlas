BeforeAll {
    $script:executablesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables'
}

Describe 'playbook Executables top-level layout' {
    It 'contains the Executables directory' {
        Test-Path -LiteralPath $script:executablesRoot -PathType Container | Should -BeTrue
    }

    It 'has no *.ps1 scripts directly under Executables' {
        $scripts = Get-ChildItem -LiteralPath $script:executablesRoot -Filter '*.ps1' -File -ErrorAction SilentlyContinue
        $scripts.Name | Should -BeNullOrEmpty
    }

    It 'has no *.cmd scripts directly under Executables' {
        $scripts = Get-ChildItem -LiteralPath $script:executablesRoot -Filter '*.cmd' -File -ErrorAction SilentlyContinue
        $scripts.Name | Should -BeNullOrEmpty
    }
}
