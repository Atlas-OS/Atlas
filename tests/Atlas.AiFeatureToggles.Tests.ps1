BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $modulesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Appx\Atlas.Appx.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $togglesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Toggles'
    $null = Get-AtlasToggleDefinition -Name Copilot -TogglesRoot $togglesRoot
    $null = Get-AtlasToggleDefinition -Name Widgets -TogglesRoot $togglesRoot
    $generalRoot = Join-Path $togglesRoot 'General'
    $script:copilot = & (Join-Path $generalRoot 'Copilot.ps1')
    $script:widgets = & (Join-Path $generalRoot 'Widgets.ps1')

    $script:scriptsPath = Join-Path $TestDrive 'Scripts'
    @(
        'Internal'
        'Modules\Atlas.Appx'
        'Modules\Atlas.Registry'
    ) | ForEach-Object {
        New-Item -Path (Join-Path $script:scriptsPath $_) -ItemType Directory -Force |
            Out-Null
    }
    @(
        'Internal\Download-Integrity.ps1'
        'Internal\Initialize-PowerShellTrust.ps1'
        'Internal\Remove-Edge.ps1'
        'Modules\Atlas.Appx\Atlas.Appx.psd1'
        'Modules\Atlas.Registry\Atlas.Registry.psd1'
    ) | ForEach-Object {
        Set-Content -LiteralPath (Join-Path $script:scriptsPath $_) -Value '' -Encoding Ascii
    }

    $script:fakeWinget = Join-Path $TestDrive 'winget.exe'
    Set-Content -LiteralPath $script:fakeWinget -Value '' -Encoding Ascii

    function Get-AtlasTrustedWingetPath { throw 'Test stub was not mocked.' }
    function Assert-AtlasTrustedWingetSource {
        param($WingetPath, $Name)
        $null = $WingetPath, $Name
        throw 'Test stub was not mocked.'
    }
}

Describe 'Copilot toggle' {
    BeforeEach {
        Mock Import-Module
        Mock Invoke-AtlasAppxRemovalPlan
        Mock Set-AtlasRegistryValue
        Mock Remove-AtlasRegistryValue
        Mock Get-ItemPropertyValue
        Mock Get-AtlasTrustedWingetPath { $script:fakeWinget }
        Mock Assert-AtlasTrustedWingetSource
        Mock Invoke-AtlasToggleNativeCommand
    }

    It 'keeps machine and current-user disable work in the privileged split' {
        $state = $script:copilot.States.Disable
        $context = [pscustomobject]@{
            ScriptsPath = $script:scriptsPath
            Silent      = $true
        }

        & $state.MachineAction $context
        & $state.UserAction $context

        $state.StateRecordScope | Should -BeExactly 'Machine'
        Should -Invoke Invoke-AtlasAppxRemovalPlan -Times 1 -Exactly -ParameterFilter {
            $Definition.Count -eq 1 -and
                $Definition[0].Name -ceq 'Microsoft.Copilot*' -and
                -not $Definition[0].IgnoreErrors
        }
        Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -and
                $Name -ceq 'ShowCopilotButton' -and $Type -ceq 'DWord' -and $Data -eq 0
        }
        Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -and
                $Name -ceq 'TurnOffWindowsCopilot' -and $Type -ceq 'DWord' -and $Data -eq 1
        }
    }

    It 'installs the Store app only through the trusted msstore source' {
        Mock Get-ItemPropertyValue { 0 }
        $context = [pscustomobject]@{
            ScriptsPath = $script:scriptsPath
            Silent      = $true
        }

        & $script:copilot.States.Enable.UserAction $context

        Should -Invoke Assert-AtlasTrustedWingetSource -Times 1 -Exactly -ParameterFilter {
            $WingetPath -ceq $script:fakeWinget -and $Name -ceq 'msstore'
        }
        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 1 -Exactly -ParameterFilter {
            $FilePath -ceq $script:fakeWinget -and
                ($ArgumentList -join '|') -ceq
                    'install|--exact|--id|9NHT9RB2F4HD|--source|msstore|--uninstall-previous|--silent|--accept-source-agreements|--accept-package-agreements|--disable-interactivity' -and
                $AllowedExitCodes.Count -eq 1 -and $AllowedExitCodes[0] -eq 0
        }
        Should -Not -Invoke Set-AtlasRegistryValue
        Should -Invoke Remove-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -and
                $Name -ceq 'TurnOffWindowsCopilot'
        }
    }

    It 'does not remove the blocking policy when Store installation fails' {
        Mock Get-ItemPropertyValue { 0 }
        Mock Invoke-AtlasToggleNativeCommand { throw 'simulated winget failure' }
        $context = [pscustomobject]@{
            ScriptsPath = $script:scriptsPath
            Silent      = $true
        }

        { & $script:copilot.States.Enable.UserAction $context } |
            Should -Throw '*simulated winget failure*'

        Should -Not -Invoke Remove-AtlasRegistryValue
    }
}

Describe 'Widgets toggle' {
    BeforeEach {
        Mock Import-Module
        Mock Set-AtlasRegistryValue
        Mock Remove-AtlasRegistryValue
        Mock Invoke-AtlasToggleNativeCommand
        Mock Read-Host { 'Yes' }
        Mock Start-Sleep
        Mock Start-Process
    }

    It 'writes and removes the two machine policies without direct shell mutation' {
        $context = [pscustomobject]@{
            ScriptsPath = $script:scriptsPath
            Silent      = $true
        }

        & $script:widgets.States.Disable.Action $context
        & $script:widgets.States.Enable.Action $context

        Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -and
                $Name -ceq 'EnableFeeds' -and $Type -ceq 'DWord' -and $Data -eq 0
        }
        Should -Invoke Set-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -and
                $Name -ceq 'AllowNewsAndInterests' -and $Type -ceq 'DWord' -and $Data -eq 0
        }
        Should -Invoke Remove-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -and
                $Name -ceq 'EnableFeeds'
        }
        Should -Invoke Remove-AtlasRegistryValue -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -and
                $Name -ceq 'AllowNewsAndInterests'
        }
        Should -Not -Invoke Invoke-AtlasToggleNativeCommand
        Should -Not -Invoke Start-Process
    }

    It 'uses the bundled helper and inbox Windows PowerShell in interactive mode' {
        $context = [pscustomobject]@{
            ScriptsPath = $script:scriptsPath
            Silent      = $false
            WinDir      = $env:SystemRoot
        }
        $expectedPowerShell = [IO.Path]::Combine(
            $env:SystemRoot,
            'System32\WindowsPowerShell\v1.0\powershell.exe'
        )
        $expectedHelper = Join-Path $script:scriptsPath 'Internal\Remove-Edge.ps1'

        & $script:widgets.States.Enable.Action $context

        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 1 -Exactly -ParameterFilter {
            $FilePath -ceq $expectedPowerShell -and
                $ArgumentList -contains '-InstallWebView' -and
                $ArgumentList[([array]::IndexOf($ArgumentList, '-File') + 1)] -ceq $expectedHelper -and
                $AllowedExitCodes.Count -eq 1 -and $AllowedExitCodes[0] -eq 0
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -ceq 'ms-settings:taskbar' -and $ErrorAction -ceq 'Stop'
        }
    }

    It 'leaves the policies untouched when the Edge helper fails' {
        Mock Invoke-AtlasToggleNativeCommand { throw 'simulated Edge helper failure' }
        $context = [pscustomobject]@{
            ScriptsPath = $script:scriptsPath
            Silent      = $false
            WinDir      = $env:SystemRoot
        }

        { & $script:widgets.States.Enable.Action $context } |
            Should -Throw '*simulated Edge helper failure*'

        Should -Not -Invoke Remove-AtlasRegistryValue
        Should -Not -Invoke Start-Process
    }
}
