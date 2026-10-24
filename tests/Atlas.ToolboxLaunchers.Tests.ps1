BeforeDiscovery {
    # Atlas Toolbox releases before 0.2.0 open these files by these exact paths
    # (docs/compatibility.md). The launcher generator's check only compares the stubs
    # with the toggle definitions, so a renamed or dropped declaration passes there.
    $script:ToolboxLaunchers = @(
        @{ Path = 'Scripts\toggleDefender.cmd'; Toggle = 'ToggleDefender'; State = 'Run' }
        @{ Path = 'Scripts\vbsCurrentConfig.cmd'; Toggle = 'ConfigVBS'; State = 'Run' }
        @{ Path = 'Scripts\viewBootValues.cmd'; Toggle = 'ViewCurrentValues'; State = 'View' }
        @{ Path = 'Scripts\NVidia\DisableNVIDIADisplayContainerLS.cmd'; Toggle = 'NVidiaDisplayContainer'; State = 'Disable' }
        @{ Path = 'Scripts\NVidia\EnableNVIDIADisplayContainerLS.cmd'; Toggle = 'NVidiaDisplayContainer'; State = 'Enable' }
        @{ Path = 'Scripts\SuperFetch\DisableSuperFetch.cmd'; Toggle = 'SuperFetch'; State = 'Disable' }
        @{ Path = 'Scripts\Troubleshooting\Fix Errors 2502 and 2503.cmd'; Toggle = 'FixErrors2502and2503'; State = 'Run' }
        @{ Path = 'Scripts\Troubleshooting\Repair Windows Components.cmd'; Toggle = 'RepairWindowsComponents'; State = 'Run' }
        @{ Path = 'Scripts\Troubleshooting\Telemetry Components.cmd'; Toggle = 'TelemetryComponents'; State = 'Run' }
        @{ Path = 'Scripts\Troubleshooting\TroubleshootingNetwork\AtlasDefault.cmd'; Toggle = 'DefaultAtlasNetwork'; State = 'Enable' }
        @{ Path = 'Scripts\Troubleshooting\TroubleshootingNetwork\WindowsDefault.cmd'; Toggle = 'DefaultAtlasNetwork'; State = 'Disable' }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:ToolboxRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toolbox'
}

Describe 'Paths kept for Toolbox releases before 0.2.0' {
    It 'runs <Toggle> <State> from <Path>' -ForEach $script:ToolboxLaunchers {
        $file = Join-Path $script:ToolboxRoot $Path
        Test-Path -LiteralPath $file -PathType Leaf | Should -BeTrue
        $call = "Invoke-AtlasToggleLauncher.cmd`" $Toggle $State `"%~f0`""
        Get-Content -LiteralPath $file -Raw | Should -Match ([regex]::Escape($call))
    }

    It 'holds only those launchers and the Security Center tray pair' -TestCases @(
        @{ Launchers = @($script:ToolboxLaunchers | ForEach-Object { $_.Path }) }
    ) {
        $expected = @($Launchers) + @('Scripts\SecurityHealthTray\AddTray.reg', 'Scripts\SecurityHealthTray\RemoveTray.reg')
        $actual = @(Get-ChildItem -LiteralPath $script:ToolboxRoot -Recurse -File -Force |
                ForEach-Object { $_.FullName.Substring($script:ToolboxRoot.Length + 1) })
        @($actual | Sort-Object) | Should -Be @($expected | Sort-Object) `
            -Because 'adding or removing a Toolbox path changes the contract in docs/compatibility.md'
    }
}
