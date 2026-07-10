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

    It 'preserves pre-existing deprovisioned entries (Edge keys written by the Components phase)' {
        # New-Item -Force on an existing registry key destroys its subkeys; the
        # Deprovisioned key must only be created when missing so the Edge/OEM entries
        # registered before this runs survive.
        New-Item -Path "$script:deprovisionedKey\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe" -Force | Out-Null

        $snapshotPath = Join-Path -Path $TestDrive -ChildPath 'AtlasPackagesOld.txt'
        Set-Content -LiteralPath $snapshotPath -Value @('Pkg.Removed_abc')

        Set-AtlasAppxDeprovisioned -SnapshotPath $snapshotPath `
            -DeprovisionedKeyPath $script:deprovisionedKey `
            -CurrentPackages @()

        Test-Path -LiteralPath "$script:deprovisionedKey\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.Removed_abc" | Should -BeTrue
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
    It 'writes a unique all-user Bundle/Main snapshot and creates the parent directory' {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Mock Get-AppxPackage -ModuleName Atlas.Appx {
            @(
                [pscustomobject]@{ PackageFamilyName = 'Contoso.One_abc' }
                [pscustomobject]@{ PackageFamilyName = 'Contoso.One_abc' }
                [pscustomobject]@{ PackageFamilyName = 'Contoso.Two_abc' }
            )
        }
        $snapshotPath = Join-Path -Path $TestDrive -ChildPath 'snapshot\AtlasPackagesOld.txt'

        Save-AtlasAppxSnapshot -Path $snapshotPath

        Test-Path -LiteralPath $snapshotPath | Should -BeTrue
        @(Get-Content -LiteralPath $snapshotPath) | Should -Be @(
            'Contoso.One_abc'
            'Contoso.Two_abc'
        )
        Should -Invoke Get-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly
        $snapshotSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot `
                '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Appx\Domain\Snapshot.ps1') -Raw
        $snapshotSource | Should -Match 'Get-AppxPackage -AllUsers -PackageTypeFilter Bundle, Main -ErrorAction Stop'
    }
}

Describe 'AppX removal policy' {
    It 'preserves the exact ordered family patterns formerly declared in appx.yml' {
        $expected = @(
            'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
            'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
            'Microsoft.Edge.GameAssist*'
            'MicrosoftTeams*'
            'MSTeams*'
            'Microsoft.Copilot*'
            'MicrosoftWindows.Client.WebExperience*'
            'Microsoft.WidgetsPlatformRuntime*'
            'Clipchamp.Clipchamp*'
            'Disney.37853FC22B2CE*'
            'SpotifyAB.SpotifyMusic*'
            'Microsoft.549981C3F5F10*'
            'Microsoft.XboxApp*'
            'microsoft.windowscommunicationsapps*'
            'Microsoft.MSPaint*'
            'Microsoft.Paint*'
            'Microsoft.Getstarted*'
            'Microsoft.WindowsBackup*'
            'Microsoft.ZuneVideo*'
            'Microsoft.ZuneMusic*'
            'MicrosoftCorporationII.MicrosoftFamily*'
            'MicrosoftCorporationII.QuickAssist*'
            'Microsoft.MixedReality.Portal*'
            'Microsoft.Windows.DevHome*'
            'Microsoft.BingWeather*'
            'Microsoft.BingNews*'
            'Microsoft.BingFinance*'
            'Microsoft.BingSports*'
            'Microsoft.BingSearch*'
            'Microsoft.OutlookForWindows*'
            'Microsoft.GetHelp*'
            'Microsoft.Microsoft3DViewer*'
            'Microsoft.MicrosoftOfficeHub*'
            'Microsoft.MicrosoftSolitaireCollection*'
            'Microsoft.MicrosoftStickyNotes*'
            'Microsoft.StickyNotesPreview*'
            'Microsoft.Office.OneNote*'
            'Microsoft.OneConnect*'
            'Microsoft.People*'
            'Microsoft.PowerAutomateDesktop*'
            'Microsoft.ScreenSketch*'
            'Microsoft.SkypeApp*'
            'Microsoft.Todos*'
            'Microsoft.Wallet*'
            'Microsoft.Whiteboard*'
            'Microsoft.WindowsAlarms*'
            'Microsoft.WindowsCamera*'
            'Microsoft.WindowsFeedbackHub*'
            'Microsoft.WindowsMaps*'
            'Microsoft.WindowsSoundRecorder*'
            'Microsoft.StartExperiencesApp*'
            'Ink.Handwriting.Main.Store.en-US1.0'
        )

        $definitions = @(Get-AtlasAppxRemovalDefinition)
        @($definitions.Name) | Should -Be $expected
        $definitions.Count | Should -Be 52
    }

    It 'preserves the Edge and Snipping Tool option gates' {
        $definitions = @(Get-AtlasAppxRemovalDefinition)

        @($definitions | Where-Object Option -eq 'uninstall-edge').Name | Should -Be @(
            'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
            'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
            'Microsoft.Edge.GameAssist*'
        )
        @($definitions | Where-Object Option -eq 'remove-snipping-tool').Name |
            Should -Be @('Microsoft.ScreenSketch*')
        @($definitions | Where-Object { $_.Option -and $_.Option -notin @('uninstall-edge', 'remove-snipping-tool') }) |
            Should -BeNullOrEmpty
    }

    It 'preserves exactly the five warning-only family patterns' {
        $definitions = @(Get-AtlasAppxRemovalDefinition)
        @($definitions | Where-Object IgnoreErrors).Name | Should -Be @(
            'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
            'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
            'Microsoft.Edge.GameAssist*'
            'MicrosoftWindows.Client.WebExperience*'
            'Microsoft.WidgetsPlatformRuntime*'
        )
    }
}

Describe 'Package-family identity matching' {
    It 'matches an exact installed PackageFamilyName without broadening the pattern' {
        InModuleScope Atlas.Appx {
            $package = [pscustomobject]@{
                Name              = 'Microsoft.MicrosoftEdge'
                PackageFullName   = 'Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe'
                PackageFamilyName = 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
            }

            (Test-AtlasAppxFamilyMatch -Package $package `
                    -Name 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe') | Should -BeTrue
            (Test-AtlasAppxFamilyMatch -Package $package `
                    -Name 'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe') | Should -BeFalse
        }
    }

    It 'derives the family identity from a DISM provisioned PackageName' {
        InModuleScope Atlas.Appx {
            $package = [pscustomobject]@{
                DisplayName = 'Microsoft.MicrosoftEdge'
                PackageName = 'Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe'
            }

            (Test-AtlasAppxFamilyMatch -Package $package `
                    -Name 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe') | Should -BeTrue
        }
    }

    It 'applies family wildcards case-insensitively across installed and provisioned identities' {
        InModuleScope Atlas.Appx {
            (Test-AtlasAppxFamilyMatch -Package ([pscustomobject]@{
                        Name = 'MicrosoftWindows.Client.WebExperience'
                    }) -Name 'microsoftwindows.client.webexperience*') | Should -BeTrue

            (Test-AtlasAppxFamilyMatch -Package ([pscustomobject]@{
                        DisplayName = 'MSTeams'
                        PackageName = 'MSTeams_1.0.0.0_x64__8wekyb3d8bbwe'
                    }) -Name 'MSTeams*') | Should -BeTrue
        }
    }

    It 'selects a bundle parent instead of its architecture-specific Main child' {
        InModuleScope Atlas.Appx {
            $packages = @(
                [pscustomobject]@{
                    Name = 'Bundled.App'; PackageFamilyName = 'Bundled.App_abc';
                    PackageFullName = 'Bundled.App_2.0_neutral_~_abc'; IsBundle = $true
                }
                [pscustomobject]@{
                    Name = 'Bundled.App'; PackageFamilyName = 'Bundled.App_abc';
                    PackageFullName = 'Bundled.App_2.0_x64__abc'; IsBundle = $false
                }
            )

            @((Get-AtlasAppxParentInstalledPackage -Package $packages).PackageFullName) |
                Should -Be @('Bundled.App_2.0_neutral_~_abc')
        }
    }
}

Describe 'Invoke-AtlasAppxRemovalPlan' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Mock Test-AtlasOption -ModuleName Atlas.Appx -MockWith { $true }
    }

    It 'removes installed registrations for all users before removing provisioning' {
        $definition = [pscustomobject]@{ Name = 'Contoso.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name              = 'Contoso.App'
            PackageFamilyName = 'Contoso.App_abc123'
            PackageFullName   = 'Contoso.App_1.0.0.0_x64__abc123'
        }
        $provisioned = [pscustomobject]@{
            DisplayName = 'Contoso.App'
            PackageName = 'Contoso.App_1.0.0.0_neutral__abc123'
        }

        InModuleScope Atlas.Appx {
            $script:testInstalledInventoryCalls = 0
            $script:testProvisionedInventoryCalls = 0
        }
        $removalEvents = [System.Collections.Generic.List[string]]::new()
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith {
            $script:testInstalledInventoryCalls++
            if ($script:testInstalledInventoryCalls -eq 1) { return @($installed) }
            return @()
        }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith {
            $script:testProvisionedInventoryCalls++
            if ($script:testProvisionedInventoryCalls -eq 1) { return @($provisioned) }
            return @()
        }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx -MockWith {
            $removalEvents.Add("installed:$Package")
        }
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -MockWith {
            $removalEvents.Add("provisioned:$PackageName")
        }

        Invoke-AtlasAppxRemovalPlan -Definition @($definition)

        @($removalEvents) | Should -Be @(
            'installed:Contoso.App_1.0.0.0_x64__abc123'
            'provisioned:Contoso.App_1.0.0.0_neutral__abc123'
        )
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Package -eq 'Contoso.App_1.0.0.0_x64__abc123' -and $AllUsers
        }
        Should -Invoke Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $PackageName -eq 'Contoso.App_1.0.0.0_neutral__abc123' -and $Online -and $AllUsers
        }
    }

    It 'removes a bundle parent without separately removing its Main child' {
        $definition = [pscustomobject]@{ Name = 'Bundled.App*'; Option = $null; IgnoreErrors = $false }
        $script:testBundleInventoryCalls = 0
        $script:testBundleInstalled = @(
            [pscustomobject]@{
                Name = 'Bundled.App'; PackageFamilyName = 'Bundled.App_abc';
                PackageFullName = 'Bundled.App_2.0_neutral_~_abc'; IsBundle = $true
            }
            [pscustomobject]@{
                Name = 'Bundled.App'; PackageFamilyName = 'Bundled.App_abc';
                PackageFullName = 'Bundled.App_2.0_x64__abc'; IsBundle = $false
            }
        )
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith {
            $script:testBundleInventoryCalls++
            if ($script:testBundleInventoryCalls -eq 1) { return @($script:testBundleInstalled) }
            return @()
        }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        Invoke-AtlasAppxRemovalPlan -Definition @($definition)

        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly
    }

    It 'skips an option-gated family when the option flag is absent' {
        $definition = [pscustomobject]@{
            Name = 'Microsoft.ScreenSketch*'; Option = 'remove-snipping-tool'; IgnoreErrors = $false
        }
        Mock Test-AtlasOption -ModuleName Atlas.Appx -MockWith { $false }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx

        Invoke-AtlasAppxRemovalPlan -Definition @($definition)

        Should -Invoke Test-AtlasOption -ModuleName Atlas.Appx -Times 1 -Exactly `
            -ParameterFilter { $Name -eq 'remove-snipping-tool' }
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 0 -Exactly
        Should -Invoke Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -Times 0 -Exactly
    }

    It 'downgrades both cmdlet and verification failures for IgnoreErrors families' {
        $definition = [pscustomobject]@{ Name = 'Optional.App*'; Option = $null; IgnoreErrors = $true }
        $installed = [pscustomobject]@{
            Name = 'Optional.App'; PackageFamilyName = 'Optional.App_abc'; PackageFullName = 'Optional.App_1.0_x64__abc'
        }
        InModuleScope Atlas.Appx { $script:testInstalledInventoryCalls = 0 }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith {
            $script:testInstalledInventoryCalls++
            return @($installed)
        }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx -MockWith { throw 'access denied' }

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 2 -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "Ignoring AppX removal failure for 'Optional.App*':*"
        }
    }

    It 'attempts every required family and aggregates failures after verification' {
        $definitions = @(
            [pscustomobject]@{ Name = 'Required.One*'; Option = $null; IgnoreErrors = $false }
            [pscustomobject]@{ Name = 'Required.Two*'; Option = $null; IgnoreErrors = $false }
        )
        $installed = @(
            [pscustomobject]@{ Name = 'Required.One'; PackageFullName = 'Required.One_1.0_x64__abc' }
        )
        $provisioned = @(
            [pscustomobject]@{ DisplayName = 'Required.Two'; PackageName = 'Required.Two_1.0_neutral__abc' }
        )
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @($provisioned) }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx -MockWith { throw "failed $Package" }
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -MockWith { throw "failed $PackageName" }

        { Invoke-AtlasAppxRemovalPlan -Definition $definitions } |
            Should -Throw -ExpectedMessage '*Required.One*Required.Two*'

        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly
        Should -Invoke Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -Times 1 -Exactly
    }

    It 'fails when a cmdlet reports success but a required package remains installed' {
        $definition = [pscustomobject]@{ Name = 'Stubborn.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Stubborn.App'; PackageFamilyName = 'Stubborn.App_abc'; PackageFullName = 'Stubborn.App_1.0_x64__abc'
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } |
            Should -Throw -ExpectedMessage '*Stubborn.App*: 1 installed package(s) remain registered*'
    }
}

Describe 'AppxSupport orchestration contract' {
    It 'keeps snapshot, removal, deprovision and cache cleanup in the required order' {
        $phasePath = Join-Path -Path $PSScriptRoot `
            -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Phases\Invoke-AppxSupportPhase.ps1'
        $source = [IO.File]::ReadAllText((Resolve-Path $phasePath).ProviderPath)

        $snapshot = $source.IndexOf('Save-AtlasAppxSnapshot', [StringComparison]::Ordinal)
        $teams = $source.IndexOf("Stop-AtlasProcess -Name 'msteams*'", [StringComparison]::Ordinal)
        $remove = $source.IndexOf('Invoke-AtlasAppxRemovalPlan', [StringComparison]::Ordinal)
        $phoneLink = $source.IndexOf('Remove-AtlasPhoneLinkAppx', [StringComparison]::Ordinal)
        $deprovision = $source.IndexOf('Set-AtlasAppxDeprovisioned', [StringComparison]::Ordinal)
        $search = $source.IndexOf("Stop-AtlasProcess -Name 'SearchHost*'", [StringComparison]::Ordinal)
        $cache = $source.IndexOf('Clear-AtlasAppxCache', [StringComparison]::Ordinal)
        $aggregateThrow = $source.LastIndexOf('throw "The AppX removal plan failed after cleanup', [StringComparison]::Ordinal)

        $snapshot | Should -BeGreaterOrEqual 0
        $teams | Should -BeGreaterThan $snapshot
        $remove | Should -BeGreaterThan $teams
        $phoneLink | Should -BeGreaterThan $remove
        $deprovision | Should -BeGreaterThan $phoneLink
        $search | Should -BeGreaterThan $deprovision
        $cache | Should -BeGreaterThan $search
        $aggregateThrow | Should -BeGreaterThan $cache
        $source | Should -Match 'Deprovisioning removed AppX packages failed:[\s\S]+?\$requiredFailures\.Add\(\$message\)'
        $source | Should -Match 'Clearing AppX caches failed:[\s\S]+?\$requiredFailures\.Add\(\$message\)'
    }
}
