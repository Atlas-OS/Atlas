BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Appx\Atlas.Appx.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:deprovisionedKey = "$script:testRoot\Deprovisioned"
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Get-AtlasAppxRemovedPackage' {
    It 'returns only families present in the snapshot but no longer installed' {
        InModuleScope Atlas.Appx {
            $removed = Get-AtlasAppxRemovedPackage `
                -Snapshot @('Pkg.A_abc', 'Pkg.B_abc', 'Pkg.C_abc') `
                -Current @('Pkg.B_abc', 'Pkg.D_abc')

            $removed | Should -Be @('Pkg.A_abc', 'Pkg.C_abc')
        }
    }

    It 'returns nothing when no packages were removed' {
        InModuleScope Atlas.Appx {
            $removed = Get-AtlasAppxRemovedPackage -Snapshot @('Pkg.A_abc') -Current @('Pkg.A_abc', 'Pkg.B_abc')

            @($removed).Count | Should -Be 0
        }
    }

    It 'ignores empty snapshot lines' {
        InModuleScope Atlas.Appx {
            $removed = Get-AtlasAppxRemovedPackage -Snapshot @('Pkg.A_abc', '', $null) -Current @()

            $removed | Should -Be @('Pkg.A_abc')
        }
    }
}

Describe 'Set-AtlasAppxDeprovisioned' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'registers removed package families under the deprovisioned key and deletes the snapshot' {
        $snapshotPath = Join-Path -Path $TestDrive -ChildPath 'AtlasPackagesOld.txt'
        Set-Content -LiteralPath $snapshotPath -Value @('Pkg.Removed_abc', 'Pkg.Kept_abc')

        Set-AtlasAppxDeprovisioned -SnapshotPath $snapshotPath `
            -DeprovisionedKeyPath $script:deprovisionedKey `
            -CurrentPackages @('Pkg.Kept_abc')

        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.Removed_abc" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.Kept_abc" | Should -BeFalse
        Test-Path -LiteralPath $snapshotPath | Should -BeFalse
    }

    It 'throws when the snapshot is missing' {
        $missingSnapshot = Join-Path -Path $TestDrive -ChildPath 'DoesNotExist.txt'

        { Set-AtlasAppxDeprovisioned -SnapshotPath $missingSnapshot -DeprovisionedKeyPath $script:deprovisionedKey } |
            Should -Throw -ExpectedMessage '*was not found*'
    }
}

Describe 'Clear-AtlasAppxCache' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Appx

        $script:usersRoot = Join-Path -Path $TestDrive -ChildPath 'Users'
        $script:packageRoot = Join-Path -Path $script:usersRoot -ChildPath 'TestUser\AppData\Local\Packages\TestPkg.Client_abc123'
        New-Item -Path (Join-Path -Path $script:packageRoot -ChildPath 'TempState') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data') -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'TempState\temp.dat') -Value 'x'
        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\cache.dat') -Value 'x'
        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\SettingsCache.txt') -Value 'x'
        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data\keep.dat') -Value 'x'
    }

    It 'empties TempState and *Cache* folders while keeping SettingsCache.txt and other data' {
        Clear-AtlasAppxCache -Name '*TestPkg.Client*' -UsersRoot $script:usersRoot

        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState\temp.dat') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\cache.dat') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\SettingsCache.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data\keep.dat') | Should -BeTrue
    }

    It 'leaves packages that do not match the pattern alone' {
        Clear-AtlasAppxCache -Name '*NoSuchPackage*' -UsersRoot $script:usersRoot

        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState\temp.dat') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\cache.dat') | Should -BeTrue
    }
}

Describe 'Save-AtlasAppxSnapshot' {
    It 'writes the snapshot file, creating the parent directory when missing' {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        $snapshotPath = Join-Path -Path $TestDrive -ChildPath 'snapshot\AtlasPackagesOld.txt'

        Save-AtlasAppxSnapshot -Path $snapshotPath

        # No content assertion: the installed package set (possibly empty on CI
        # runners) is environment-dependent.
        Test-Path -LiteralPath $snapshotPath | Should -BeTrue
    }
}
