BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:HelperPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-VbsConfiguration.ps1'
    $script:TogglePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Toggles\Security\VbsState.ps1'
    $script:TweakPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Tweaks\scripts\disable-core-isolation.psd1'
}

Describe 'VBS configuration boundary' {
    It 'routes both manual states to the shared helper' {
        $caseRoot = Join-Path $TestDrive 'manual'
        $internal = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'Internal') `
            -Force
        $stateLog = Join-Path $caseRoot 'states.txt'
        @'
param([string]$State)
Add-Content -LiteralPath (Join-Path $PSScriptRoot '..\states.txt') -Value $State
'@ | Set-Content -LiteralPath (Join-Path $internal.FullName 'Set-VbsConfiguration.ps1') `
            -Encoding UTF8

        $definition = & $script:TogglePath
        $toggle = [pscustomobject]@{ ScriptsPath = $caseRoot }
        foreach ($stateName in @('Disable', 'Enable')) {
            & $definition.States[$stateName].Action $toggle
        }

        Get-Content -LiteralPath $stateLog | Should -Be @('Disable', 'Enable')
        $definition.States.Disable.StateValue | Should -Be 0
        $definition.States.Enable.StateValue | Should -Be 1
        @($definition.States.Values.ReplayScope | Select-Object -Unique) |
            Should -Be @('Machine')
        @($definition.States.Values.Reboot | Select-Object -Unique) |
            Should -Be @('Recommend')
    }

    It 'keeps the install option checked, single-purpose, and free of feature removal' {
        $definition = Import-PowerShellDataFile -LiteralPath $script:TweakPath
        @($definition.Run).Count | Should -Be 1
        $definition.Run[0].Exe | Should -BeExactly `
            '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'
        @($definition.Run[0].Args) | Should -Be @(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', '{windir}\AtlasModules\Scripts\Internal\Set-VbsConfiguration.ps1',
            '-State', 'Disable'
        )
        $definition.Description | Should -Match 'preserved'
    }

    It 'reports the current provider state' {
        Mock -CommandName Get-CimInstance -MockWith {
            [pscustomobject]@{
                VirtualizationBasedSecurityStatus = 2
                SecurityServicesConfigured        = @(1, 2, 7)
                SecurityServicesRunning           = @(2)
                RequiredSecurityProperties        = @(0)
                AvailableSecurityProperties       = @(1, 2, 8, 99)
            }
        }

        $report = & $script:HelperPath
        $report.VbsStatus | Should -BeExactly 'Enabled and running'
        @($report.ConfiguredServices) | Should -Be @(
            'Credential Guard'
            'Memory integrity (HVCI)'
            'Hypervisor-Enforced Paging Translation'
        )
        @($report.RunningServices) | Should -Be @('Memory integrity (HVCI)')
        @($report.RequiredProperties) | Should -Be @('None')
        @($report.AvailableProperties) | Should -Be @(
            'Base virtualization support'
            'Secure Boot'
            'APIC virtualization'
            'Unknown (99)'
        )
    }
}
