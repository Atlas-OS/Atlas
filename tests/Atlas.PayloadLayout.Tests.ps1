BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:executablesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables'
}

Describe 'Paired registry assets stay in lockstep' {
    # The toggle engine imports the Scripts\Registry copy and the standalone Toolbox flows
    # use the Toolbox copy, so the two must not drift apart.
    It 'includes byte-identical content for <Name>' -TestCases @(
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

Describe 'CBS package hash manifest stays in lockstep with the included CABs' {
    # Assert-AtlasCbsHash checks every CAB against this manifest before install, so a stale
    # entry would reject the real package on every machine.
    It 'records the correct SHA256 for every included .cab and lists no stale entries' {
        $pkgDir = Join-Path -Path $script:executablesRoot -ChildPath 'AtlasModules\Packages'
        $manifestPath = Join-Path -Path $pkgDir -ChildPath 'Atlas-CbsHashes.psd1'
        Test-Path -LiteralPath $manifestPath -PathType Leaf | Should -BeTrue
        $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath

        $cabs = @(Get-ChildItem -LiteralPath $pkgDir -Filter '*.cab' -File)
        $cabs.Count | Should -BeGreaterThan 0

        foreach ($cab in $cabs) {
            $manifest.Keys | Should -Contain $cab.Name
            (Get-FileHash -LiteralPath $cab.FullName -Algorithm SHA256).Hash | Should -Be $manifest[$cab.Name]
        }
        foreach ($listed in $manifest.Keys) {
            $cabs.Name | Should -Contain $listed
        }
    }
}
