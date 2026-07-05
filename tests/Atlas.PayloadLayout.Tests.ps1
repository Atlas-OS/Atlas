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

Describe 'Paired registry assets stay in lockstep' {
    # Some .reg payloads ship twice: once under AtlasModules\Scripts\Registry (imported by the
    # toggle engine) and once under AtlasModules\Toolbox (consumed by the standalone Atlas
    # Toolbox flows). See playbook/Executables/AtlasModules/Scripts/Registry/README.md.
    # This guard fails the moment a pair diverges; edit both copies together.
    It 'ships byte-identical content for <Name>' -TestCases @(
        @{ Name = 'SecurityHealthTray disable/RemoveTray'
           A    = 'AtlasModules\Scripts\Registry\SecurityHealthTray\disable.reg'
           B    = 'AtlasModules\Toolbox\Scripts\SecurityHealthTray\RemoveTray.reg' }
        @{ Name = 'SecurityHealthTray enable/AddTray'
           A    = 'AtlasModules\Scripts\Registry\SecurityHealthTray\enable.reg'
           B    = 'AtlasModules\Toolbox\Scripts\SecurityHealthTray\AddTray.reg' }
    ) {
        $pathA = Join-Path -Path $script:executablesRoot -ChildPath $A
        $pathB = Join-Path -Path $script:executablesRoot -ChildPath $B
        Test-Path -LiteralPath $pathA -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $pathB -PathType Leaf | Should -BeTrue
        $hashA = (Get-FileHash -LiteralPath $pathA -Algorithm SHA256).Hash
        $hashB = (Get-FileHash -LiteralPath $pathB -Algorithm SHA256).Hash
        $hashB | Should -Be $hashA -Because 'the Toolbox copy must match its Scripts/Registry source; edit both together'
    }
}
