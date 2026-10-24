BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = $script:AtlasTestModulesRoot

    Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:AtlasModulesPath = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules'
    $script:NVidiaServiceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem'
}

# Runs the real reset core against the installed Services definitions and their real
# applicability checks; only the work each default would do is replaced.
Describe 'Invoke-AtlasServiceDefaultsReset' {
    BeforeEach {
        $script:applied = [Collections.Generic.List[string]]::new()
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Toggles
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Get-AtlasContext -ModuleName Atlas.Toggles {
            [pscustomobject]@{
                WinDir           = [Environment]::GetFolderPath('Windows')
                AtlasModulesPath = $script:AtlasModulesPath
                WindowsBuild     = 26100
            }
        }
        Mock Invoke-AtlasToggleScopedWork -ModuleName Atlas.Toggles {
            $script:applied.Add("$($Toggle.Name):$($Toggle.State)")
        }
        Mock Invoke-AtlasToggleFunction -ModuleName Atlas.Toggles -ParameterFilter { $Label -eq 'context action' }
        Mock Set-AtlasToggleState -ModuleName Atlas.Toggles
    }

    It 'skips the NVIDIA service default on a PC without the NVIDIA driver and applies the rest' {
        Mock Test-Path -ModuleName Atlas.Toggles { $false } -ParameterFilter { $LiteralPath -eq $script:NVidiaServiceKey }

        InModuleScope Atlas.Toggles { Invoke-AtlasServiceDefaultsReset }

        $script:applied | Should -Be @(
            'Bluetooth:Enable'
            'LanmanWorkstation:Enable'
            'NetworkDiscovery:Enable'
            'NVidiaDisplayContainerContextMenu:Disable'
            'Printing:Enable'
            'SuperFetch:Enable'
        )
        Should -Invoke Set-AtlasToggleState -ModuleName Atlas.Toggles -Times 0 -Exactly -ParameterFilter {
            $Name -eq 'NVidiaDisplayContainer'
        }
        Should -Invoke Set-AtlasToggleState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'SuperFetch' -and $State -eq 1
        }
    }

    It 'applies the NVIDIA service default when the driver is installed' {
        Mock Test-Path -ModuleName Atlas.Toggles { $true } -ParameterFilter { $LiteralPath -eq $script:NVidiaServiceKey }

        InModuleScope Atlas.Toggles { Invoke-AtlasServiceDefaultsReset }

        $script:applied | Should -Contain 'NVidiaDisplayContainer:Enable'
        $script:applied.Count | Should -Be 7
    }
}
