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

Describe 'Exact-user AppX cache deletion' {
    BeforeEach {
        Mock Get-AppxPackage -ModuleName Atlas.Appx -MockWith { @() }

        $script:profileRoot = Join-Path -Path $TestDrive -ChildPath 'Users\InstallingUser'
        $script:packageRoot = Join-Path -Path $script:profileRoot `
            -ChildPath 'AppData\Local\Packages\Microsoft.Windows.Search_abc123'
        New-Item -Path (Join-Path -Path $script:packageRoot -ChildPath 'TempState') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data') -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'TempState\temp.dat') -Value 'x'
        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\cache.dat') -Value 'x'
        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\SettingsCache.txt') -Value 'x'
        Set-Content -Path (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data\keep.dat') -Value 'x'
    }

    It 'empties TempState and *Cache* folders while keeping SettingsCache.txt and other data' {
        InModuleScope Atlas.Appx -Parameters @{ ProfileRoot = $script:profileRoot } {
            param($ProfileRoot)
            Clear-AtlasAppxCacheForProfile -Mode AppxSupport -ProfileRoot $ProfileRoot `
                -SessionId 7
        }

        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState\temp.dat') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\cache.dat') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\SettingsCache.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data\keep.dat') | Should -BeTrue
    }

    It 'does not inspect or mutate a sibling user profile' {
        $otherPackage = Join-Path -Path $TestDrive `
            -ChildPath 'Users\OtherUser\AppData\Local\Packages\Microsoft.Windows.Search_other\TempState'
        New-Item -Path $otherPackage -ItemType Directory -Force | Out-Null
        $otherSentinel = Join-Path -Path $otherPackage -ChildPath 'keep.dat'
        Set-Content -LiteralPath $otherSentinel -Value 'outside the selected profile'

        InModuleScope Atlas.Appx -Parameters @{ ProfileRoot = $script:profileRoot } {
            param($ProfileRoot)
            Clear-AtlasAppxCacheForProfile -Mode AppxSupport -ProfileRoot $ProfileRoot `
                -SessionId 7
        }

        Test-Path -LiteralPath $otherSentinel | Should -BeTrue
    }

    It 'fails before deleting cache siblings when the tree contains a junction' {
        $outside = Join-Path -Path $TestDrive -ChildPath 'OutsideCacheTarget'
        New-Item -Path $outside -ItemType Directory -Force | Out-Null
        $outsideSentinel = Join-Path -Path $outside -ChildPath 'must-remain.dat'
        Set-Content -LiteralPath $outsideSentinel -Value 'not cache data'
        $cacheSentinel = Join-Path -Path $script:packageRoot `
            -ChildPath 'LocalState\WebCache\ordinary.dat'
        Set-Content -LiteralPath $cacheSentinel -Value 'preflight must preserve this'
        $junctionPath = Join-Path -Path $script:packageRoot `
            -ChildPath 'LocalState\WebCache\Redirect'
        New-Item -Path $junctionPath -ItemType Junction -Target $outside | Out-Null

        {
            InModuleScope Atlas.Appx -Parameters @{ ProfileRoot = $script:profileRoot } {
                param($ProfileRoot)
                Clear-AtlasAppxCacheForProfile -Mode AppxSupport -ProfileRoot $ProfileRoot `
                    -SessionId 7
            }
        } | Should -Throw -ExpectedMessage '*reparse point*'

        Test-Path -LiteralPath $cacheSentinel | Should -BeTrue
        Test-Path -LiteralPath $outsideSentinel | Should -BeTrue
    }
}

Describe 'AppX cache child identity validation' {
    BeforeAll {
        $script:cacheUserSid = 'S-1-5-21-1000-1000-1000-1001'
        $script:cacheProfile = Join-Path -Path $TestDrive -ChildPath 'Users\InstallingUser'
    }

    It 'accepts only an exact non-administrator SID and matching registered profile' {
        $evidence = [pscustomobject]@{
            UserSid               = $script:cacheUserSid
            IsAdministrator       = $false
            ProfileRoot           = $script:cacheProfile
            RegisteredProfileRoot = $script:cacheProfile
        }
        $evidenceReader = { $evidence }.GetNewClosure()

        $actual = InModuleScope Atlas.Appx -Parameters @{
            ExpectedSid   = $script:cacheUserSid
            EvidenceReader = $evidenceReader
        } {
            param($ExpectedSid, $EvidenceReader)
            Assert-AtlasAppxCacheUserIdentity -ExpectedUserSid $ExpectedSid `
                -EvidenceReader $EvidenceReader
        }

        $actual | Should -Be ([IO.Path]::GetFullPath($script:cacheProfile))
    }

    It 'rejects a child whose SID differs from the install state' {
        $evidence = [pscustomobject]@{
            UserSid               = 'S-1-5-21-1000-1000-1000-1002'
            IsAdministrator       = $false
            ProfileRoot           = $script:cacheProfile
            RegisteredProfileRoot = $script:cacheProfile
        }
        $evidenceReader = { $evidence }.GetNewClosure()

        {
            InModuleScope Atlas.Appx -Parameters @{
                ExpectedSid    = $script:cacheUserSid
                EvidenceReader = $evidenceReader
            } {
                param($ExpectedSid, $EvidenceReader)
                Assert-AtlasAppxCacheUserIdentity -ExpectedUserSid $ExpectedSid `
                    -EvidenceReader $EvidenceReader
            }
        } | Should -Throw -ExpectedMessage '*SID differs from the install-state-bound user*'
    }

    It 'rejects an administrator token even when the SID matches' {
        $evidence = [pscustomobject]@{
            UserSid               = $script:cacheUserSid
            IsAdministrator       = $true
            ProfileRoot           = $script:cacheProfile
            RegisteredProfileRoot = $script:cacheProfile
        }
        $evidenceReader = { $evidence }.GetNewClosure()

        {
            InModuleScope Atlas.Appx -Parameters @{
                ExpectedSid    = $script:cacheUserSid
                EvidenceReader = $evidenceReader
            } {
                param($ExpectedSid, $EvidenceReader)
                Assert-AtlasAppxCacheUserIdentity -ExpectedUserSid $ExpectedSid `
                    -EvidenceReader $EvidenceReader
            }
        } | Should -Throw -ExpectedMessage '*not an exact unelevated user process*'
    }

    It 'rejects a profile path that disagrees with protected registration' {
        $evidence = [pscustomobject]@{
            UserSid               = $script:cacheUserSid
            IsAdministrator       = $false
            ProfileRoot           = $script:cacheProfile
            RegisteredProfileRoot = Join-Path -Path $TestDrive -ChildPath 'Users\DifferentUser'
        }
        $evidenceReader = { $evidence }.GetNewClosure()

        {
            InModuleScope Atlas.Appx -Parameters @{
                ExpectedSid    = $script:cacheUserSid
                EvidenceReader = $evidenceReader
            } {
                param($ExpectedSid, $EvidenceReader)
                Assert-AtlasAppxCacheUserIdentity -ExpectedUserSid $ExpectedSid `
                    -EvidenceReader $EvidenceReader
            }
        } | Should -Throw -ExpectedMessage '*differs from the protected SID-to-profile registration*'
    }

    It 'accepts only a nonzero current-process Windows session' {
        $actual = InModuleScope Atlas.Appx {
            Get-AtlasAppxCacheCurrentSessionId -ProcessReader {
                [pscustomobject]@{ SessionId = 7 }
            }
        }
        $actual | Should -Be 7

        {
            InModuleScope Atlas.Appx {
                Get-AtlasAppxCacheCurrentSessionId -ProcessReader {
                    [pscustomobject]@{ SessionId = 0 }
                }
            }
        } | Should -Throw -ExpectedMessage '*requires a nonzero interactive Windows session*'
    }
}

Describe 'Exact-session AppX package process stopping' {
    BeforeEach {
        $script:packageProcessRoot = Join-Path -Path $TestDrive -ChildPath 'InstalledAppx\Contoso.App'
        New-Item -Path $script:packageProcessRoot -ItemType Directory -Force | Out-Null
        $script:packageExecutable = Join-Path -Path $script:packageProcessRoot -ChildPath 'Contoso.App.exe'
        Set-Content -LiteralPath $script:packageExecutable -Value 'test executable'

        $sameSessionModule = New-MockObject -Type 'System.Diagnostics.ProcessModule' `
            -Properties @{ FileName = $script:packageExecutable }
        $otherSessionModule = New-MockObject -Type 'System.Diagnostics.ProcessModule' `
            -Properties @{ FileName = $script:packageExecutable }
        $script:sameSessionProcess = New-MockObject -Type 'System.Diagnostics.Process' `
            -Properties @{
                ProcessName = 'Contoso.App'
                Id          = 7101
                SessionId   = 7
                MainModule  = $sameSessionModule
                HasExited   = $true
            } -Methods @{
                WaitForExit = { return $true }
            }
        $script:otherSessionProcess = New-MockObject -Type 'System.Diagnostics.Process' `
            -Properties @{
                ProcessName = 'Contoso.App'
                Id          = 8101
                SessionId   = 8
                MainModule  = $otherSessionModule
                HasExited   = $false
            } -Methods @{
                WaitForExit = { return $false }
            }
        $processes = @($script:sameSessionProcess, $script:otherSessionProcess)
        $processReader = { $processes }.GetNewClosure()
        Mock Get-Process -ModuleName Atlas.Appx -MockWith $processReader
        Mock Stop-Process -ModuleName Atlas.Appx
    }

    It 'passes only the retained same-session process object to Stop-Process' {
        InModuleScope Atlas.Appx -Parameters @{ PackageRoot = $script:packageProcessRoot } {
            param($PackageRoot)
            Stop-AtlasAppxPackageProcess -PackageDirectory $PackageRoot -SessionId 7
        }

        Should -Invoke Stop-Process -ModuleName Atlas.Appx -Times 1 -Exactly `
            -ParameterFilter {
                $InputObject.Id -eq 7101 -and
                $InputObject.SessionId -eq 7 -and
                $InputObject.Path -eq $script:packageExecutable -and
                $Force -and
                $ErrorAction -eq 'Stop'
            }
        Should -Invoke Stop-Process -ModuleName Atlas.Appx -Times 0 -Exactly `
            -ParameterFilter { $InputObject.Id -eq 8101 }
        $script:sameSessionProcess._WaitForExit.Call | Should -Be 1
        $script:sameSessionProcess._WaitForExit.Arguments[0] | Should -Be 5000
        $script:otherSessionProcess._WaitForExit.Count | Should -Be 0
    }

    It 'fails when a stopped same-session package process misses the bounded exit postcondition' {
        $timeoutModule = New-MockObject -Type 'System.Diagnostics.ProcessModule' `
            -Properties @{ FileName = $script:packageExecutable }
        $timeoutProcess = New-MockObject -Type 'System.Diagnostics.Process' `
            -Properties @{
                ProcessName = 'Contoso.App'
                Id          = 7102
                SessionId   = 7
                MainModule  = $timeoutModule
                HasExited   = $false
            } -Methods @{
                WaitForExit = { return $false }
            }
        $processReader = { @($timeoutProcess) }.GetNewClosure()
        Mock Get-Process -ModuleName Atlas.Appx -MockWith $processReader

        {
            InModuleScope Atlas.Appx -Parameters @{ PackageRoot = $script:packageProcessRoot } {
                param($PackageRoot)
                Stop-AtlasAppxPackageProcess -PackageDirectory $PackageRoot -SessionId 7
            }
        } | Should -Throw -ExpectedMessage '*did not exit within 5 seconds*'

        Should -Invoke Stop-Process -ModuleName Atlas.Appx -Times 1 -Exactly `
            -ParameterFilter { $InputObject.Id -eq 7102 }
        $timeoutProcess._WaitForExit.Call | Should -Be 1
        $timeoutProcess._WaitForExit.Arguments[0] | Should -Be 5000
    }
}

Describe 'Install-state-bound AppX cache launcher' {
    BeforeEach {
        $script:launcherSid = 'S-1-5-21-1000-1000-1000-1001'
        $script:testWindows = Join-Path -Path $TestDrive -ChildPath 'Windows'
        $script:testModules = Join-Path -Path $script:testWindows -ChildPath 'AtlasModules'
        $script:testPowerShell = Join-Path -Path $script:testWindows `
            -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $script:testCacheScript = Join-Path -Path $script:testModules `
            -ChildPath 'Scripts\Internal\Clear-AtlasUserAppxCache.ps1'
        New-Item -Path (Split-Path -Parent $script:testPowerShell) -ItemType Directory -Force | Out-Null
        New-Item -Path (Split-Path -Parent $script:testCacheScript) -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $script:testPowerShell -Value 'test executable'
        Set-Content -LiteralPath $script:testCacheScript -Value 'test script'
        $script:launcherContext = [pscustomobject]@{
            IsInstallStateBacked = $true
            IsOobe             = $false
            InteractiveUserSid = $script:launcherSid
            WinDir             = $script:testWindows
            AtlasModulesPath   = $script:testModules
        }
    }

    It 'launches the fixed child with the exact protected PowerShell path, mode and SID' {
        $launchResult = InModuleScope Atlas.Appx -Parameters @{
            Context = $script:launcherContext
        } {
            param($Context)
            $script:cacheLaunch = $null
            $exitCode = Invoke-AtlasUserAppxCacheCleanupCore -Context $Context `
                -Mode AppxSupport -Launcher {
                    param($FilePath, $Arguments, $WorkingDirectory)
                    $script:cacheLaunch = [pscustomobject]@{
                        FilePath         = $FilePath
                        Arguments        = $Arguments
                        WorkingDirectory = $WorkingDirectory
                    }
                    return 0
                }
            [pscustomobject]@{ ExitCode = $exitCode; Launch = $script:cacheLaunch }
        }

        $launchResult.ExitCode | Should -Be 0
        $launchResult.Launch.FilePath | Should -Be ([IO.Path]::GetFullPath($script:testPowerShell))
        $launchResult.Launch.WorkingDirectory | Should -Be ([IO.Path]::GetFullPath($script:testWindows))
        $launchResult.Launch.Arguments | Should -Be (
            '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ' +
            "-File `"$([IO.Path]::GetFullPath($script:testCacheScript))`" " +
            "-Mode AppxSupport -ExpectedUserSid $script:launcherSid"
        )
    }

    It 'uses Atlas.Core Invoke-AtlasAsUser for the production SYSTEM wrapper' {
        $context = $script:launcherContext
        $expectedPowerShell = [IO.Path]::GetFullPath($script:testPowerShell)
        $expectedScript = [IO.Path]::GetFullPath($script:testCacheScript)
        Mock Test-AtlasSystem -ModuleName Atlas.Appx -MockWith { $true }
        Mock Get-AtlasContext -ModuleName Atlas.Appx -MockWith { $context }
        Mock Invoke-AtlasAsUser -ModuleName Atlas.Appx -MockWith { return 0 }
        Mock Write-AtlasLog -ModuleName Atlas.Appx

        Invoke-AtlasUserAppxCacheCleanup -Mode AppxSupport

        Should -Invoke Invoke-AtlasAsUser -ModuleName Atlas.Appx -Times 1 -Exactly `
            -ParameterFilter {
                $FilePath -eq $expectedPowerShell -and
                $Arguments -like "*-File `"$expectedScript`" -Mode AppxSupport -ExpectedUserSid $script:launcherSid" -and
                $WorkingDirectory -eq [IO.Path]::GetFullPath($script:testWindows) -and
                $Wait -eq $true -and
                $TimeoutSeconds -eq 900
            }
    }

    It 'rejects a non-SYSTEM production caller before reading install state' {
        Mock Test-AtlasSystem -ModuleName Atlas.Appx -MockWith { $false }
        Mock Get-AtlasContext -ModuleName Atlas.Appx
        Mock Invoke-AtlasAsUser -ModuleName Atlas.Appx

        { Invoke-AtlasUserAppxCacheCleanup -Mode AppxSupport } |
            Should -Throw -ExpectedMessage '*must be launched from SYSTEM*'

        Should -Invoke Get-AtlasContext -ModuleName Atlas.Appx -Times 0 -Exactly
        Should -Invoke Invoke-AtlasAsUser -ModuleName Atlas.Appx -Times 0 -Exactly
    }

    It 'skips user launch during OOBE while allowing machine AppX work to continue' {
        $oobeContext = [pscustomobject]@{ IsInstallStateBacked = $true; IsOobe = $true }
        Mock Test-AtlasSystem -ModuleName Atlas.Appx -MockWith { $true }
        Mock Get-AtlasContext -ModuleName Atlas.Appx -MockWith { $oobeContext }
        Mock Invoke-AtlasAsUser -ModuleName Atlas.Appx
        Mock Write-AtlasLog -ModuleName Atlas.Appx

        Invoke-AtlasUserAppxCacheCleanup -Mode AppxSupport

        Should -Invoke Invoke-AtlasAsUser -ModuleName Atlas.Appx -Times 0 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly `
            -ParameterFilter { $Message -eq 'Skipped AppxSupport AppX user cache cleanup during OOBE.' }
    }

    It 'rejects a context that is not backed by active install state' {
        $script:launcherContext.IsInstallStateBacked = $false

        {
            InModuleScope Atlas.Appx -Parameters @{ Context = $script:launcherContext } {
                param($Context)
                Invoke-AtlasUserAppxCacheCleanupCore -Context $Context `
                    -Mode AppxSupport -Launcher { return 0 }
            }
        } | Should -Throw -ExpectedMessage '*requires active Atlas install state*'
    }

    It 'propagates a failed pre-removal quiesce child as a checked failure' {
        {
            InModuleScope Atlas.Appx -Parameters @{ Context = $script:launcherContext } {
                param($Context)
                Invoke-AtlasUserAppxCacheCleanupCore -Context $Context `
                    -Mode AppxQuiesce -Launcher { return 23 }
            }
        } | Should -Throw -ExpectedMessage '*failed with exit code 23*'
    }

    It 'rejects a reparse point in the protected child script ancestry before launch' {
        $junctionWindows = Join-Path -Path $TestDrive -ChildPath 'JunctionWindows'
        $junctionPowerShell = Join-Path -Path $junctionWindows `
            -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $junctionModules = Join-Path -Path $junctionWindows -ChildPath 'AtlasModules'
        $scriptsPath = Join-Path -Path $junctionModules -ChildPath 'Scripts'
        $outsideInternal = Join-Path -Path $TestDrive -ChildPath 'OutsideInternal'
        New-Item -Path (Split-Path -Parent $junctionPowerShell) -ItemType Directory -Force | Out-Null
        New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
        New-Item -Path $outsideInternal -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $junctionPowerShell -Value 'test executable'
        Set-Content -LiteralPath (Join-Path $outsideInternal 'Clear-AtlasUserAppxCache.ps1') `
            -Value 'redirected script'
        New-Item -Path (Join-Path $scriptsPath 'Internal') -ItemType Junction `
            -Target $outsideInternal | Out-Null
        $context = [pscustomobject]@{
            IsInstallStateBacked = $true
            IsOobe             = $false
            InteractiveUserSid = $script:launcherSid
            WinDir             = $junctionWindows
            AtlasModulesPath   = $junctionModules
        }

        {
            InModuleScope Atlas.Appx -Parameters @{ Context = $context } {
                param($Context)
                Invoke-AtlasUserAppxCacheCleanupCore -Context $Context `
                    -Mode AppxSupport -Launcher { throw 'launcher must not run' }
            }
        } | Should -Throw -ExpectedMessage '*non-normal ancestor*'
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
