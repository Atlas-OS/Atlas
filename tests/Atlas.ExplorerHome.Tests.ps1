Describe 'File Explorer Home configuration' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        Import-Module -Name (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
        $script:tweakPath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Tweaks\qol\explorer\disable-home.psd1'
        Import-Module -Name (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:homeToggle = Get-AtlasToggleDefinition -Name Home `
            -TogglesRoot (Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Toggles')
    }

    It 'disables both Home namespace discovery paths during installation' {
        $definition = Import-PowerShellDataFile -LiteralPath $script:tweakPath
        $classId = '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
        $namespace = @($definition.Registry | Where-Object {
                $_.Path -ceq "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$classId"
            })
        $pin = @($definition.Registry | Where-Object {
                $_.Path -ceq "HKCU\Software\Classes\CLSID\$classId" -and
                $_.Name -ceq 'System.IsPinnedToNameSpaceTree'
            })

        $namespace | Should -HaveCount 1
        $namespace[0].Operation | Should -BeExactly 'DeleteKey'
        $pin | Should -HaveCount 1
        $pin[0].Type | Should -BeExactly 'DWord'
        $pin[0].Data | Should -Be 0
    }

    It 'round-trips the per-user navigation-tree override in the Home toggle' {
        $pinPath = 'HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
        $disable = $script:homeToggle.States['Disable']
        $enable = $script:homeToggle.States['Enable']

        $disablePin = @($disable['Registry'] | Where-Object {
                $_.Path -ceq $pinPath -and $_.Name -ceq 'System.IsPinnedToNameSpaceTree'
            })
        $disablePin | Should -HaveCount 1
        $disablePin[0].Type | Should -BeExactly 'DWord'
        $disablePin[0].Data | Should -Be 0

        $enablePin = @($enable['Registry'] | Where-Object {
                $_.Path -ceq $pinPath -and $_.Name -ceq 'System.IsPinnedToNameSpaceTree'
            })
        $enablePin | Should -HaveCount 1
        $enablePin[0].Operation | Should -BeExactly 'Delete'

        # The pin is per-user work beside the machine namespace key, so the engine runs
        # it in the launching user's own process and replays it at first sign-in.
        foreach ($state in @($disable, $enable)) {
            $work = Get-AtlasToggleStateWork -Definition $script:homeToggle -StateEntry $state
            $work.Machine | Should -BeTrue
            $work.User | Should -BeTrue
        }
        $disable['StateValue'] | Should -Be 0
        $enable['StateValue'] | Should -Be 1
    }
}
