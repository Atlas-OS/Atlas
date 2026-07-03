BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Software\Atlas.Software.psd1') -Force
}

Describe 'Select-AtlasCbsPackage' {
    It 'matches CABs by pattern and architecture' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'C:\Packages\Z-Atlas-NoTelemetry-Package-arm64-1.cab'
                'C:\Packages\Z-Atlas-NoTelemetry-Package-amd64-1.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-1.cab'
            )
            $patterns = @('*Z-Atlas-NoDefender-Package*', '*Z-Atlas-NoTelemetry-Package*')

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns $patterns -Architecture 'amd64' -SingleUsePatterns

            $result.Matched | Should -Be @(
                'C:\Packages\Z-Atlas-NoTelemetry-Package-amd64-1.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-1.cab'
            )
            @($result.UnmatchedPatterns).Count | Should -Be 0
        }
    }

    It 'reports patterns that matched nothing for the architecture' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab'
            )
            $patterns = @('*Z-Atlas-NoDefender-Package*', '*Z-Atlas-NoTelemetry-Package*')

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns $patterns -Architecture 'arm64' -SingleUsePatterns

            $result.Matched | Should -Be @('C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab')
            $result.UnmatchedPatterns | Should -Be @('*Z-Atlas-NoTelemetry-Package*')
        }
    }

    It 'consumes each pattern on its first match with -SingleUsePatterns (CAB install semantics)' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-2.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-1.cab'
            )

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns @('*Z-Atlas-NoDefender-Package*') -Architecture 'amd64' -SingleUsePatterns

            $result.Matched | Should -Be @('C:\Packages\Z-Atlas-NoDefender-Package-amd64-2.cab')
        }
    }

    It 'lets one pattern match multiple candidates without -SingleUsePatterns (uninstall semantics)' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'Z-Atlas-NoDefender-Package~amd64~~1.0.0.0'
                'Z-Atlas-NoDefender-Package~amd64~~2.0.0.0'
            )

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns @('*Z-Atlas-NoDefender-Package*') -Architecture 'amd64'

            @($result.Matched).Count | Should -Be 2
            @($result.UnmatchedPatterns).Count | Should -Be 0
        }
    }

    It 'matches nothing when the architecture differs' {
        InModuleScope Atlas.Software {
            $result = Select-AtlasCbsPackage -Candidates @('C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab') `
                -Patterns @('*Z-Atlas-NoDefender-Package*') -Architecture 'amd64' -SingleUsePatterns

            @($result.Matched).Count | Should -Be 0
            $result.UnmatchedPatterns | Should -Be @('*Z-Atlas-NoDefender-Package*')
        }
    }
}

Describe 'Get-AtlasSoftwareComponentMap' {
    It 'maps every Install-AtlasSoftware component to an existing installer function' {
        InModuleScope Atlas.Software {
            $map = Get-AtlasSoftwareComponentMap
            $expectedComponents = @('SevenZip', 'VCRedist', 'DirectX', 'Brave', 'Firefox', 'LibreWolf', 'Chrome', 'Toolbox')

            @($map.Keys) | Sort-Object | Should -Be ($expectedComponents | Sort-Object)
            foreach ($function in $map.Values) {
                Get-Command -Name $function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Install-AtlasSoftware' {
    It 'rejects unknown components' {
        { Install-AtlasSoftware -Component 'NotARealComponent' } | Should -Throw
    }
}

Describe 'Get-AtlasSoftwarePickerItem' {
    It 'offers StartAllBack on Windows 11 builds' {
        InModuleScope Atlas.Software {
            $items = Get-AtlasSoftwarePickerItem -WindowsBuild 22631

            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartAllBack' }).Count | Should -Be 1
            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartIsBack' }).Count | Should -Be 0
        }
    }

    It 'offers StartIsBack on Windows 10 builds' {
        InModuleScope Atlas.Software {
            $items = Get-AtlasSoftwarePickerItem -WindowsBuild 19045

            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartIsBack' }).Count | Should -Be 1
            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartAllBack' }).Count | Should -Be 0
        }
    }

    It 'keeps the full catalog with display names and package ids' {
        InModuleScope Atlas.Software {
            $items = @(Get-AtlasSoftwarePickerItem -WindowsBuild 22631)

            $items.Count | Should -Be 40
            foreach ($item in $items) {
                $item.Text | Should -Not -BeNullOrEmpty
                $item.Package | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Get-AtlasCbsSafeModeListPath' {
    It 'points at the path packageInstall.ps1 uses for the Safe Mode retry list' {
        InModuleScope Atlas.Software {
            Get-AtlasCbsSafeModeListPath | Should -Be (Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'safeModePackagesToInstall.atlasmodule')
        }
    }
}
