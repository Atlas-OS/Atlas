Describe 'File Explorer Home configuration' {
    BeforeAll {
        $script:tweakPath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Tweaks\qol\explorer\disable-home.psd1'
        $script:togglePath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Toggles\Interface\Home.ps1'
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
        $definition = & $script:togglePath
        $disable = $definition.States.Disable.UserAction.ToString()
        $enable = $definition.States.Enable.UserAction.ToString()

        $disable | Should -Match 'System\.IsPinnedToNameSpaceTree'
        $disable | Should -Match 'Set-AtlasRegistryValue[\s\S]*-Data 0'
        $enable | Should -Match 'Remove-AtlasRegistryValue[\s\S]*System\.IsPinnedToNameSpaceTree'
    }
}
