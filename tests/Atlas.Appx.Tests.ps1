BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module -Name (Join-Path -Path $script:AtlasTestModulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $script:AtlasTestModulesRoot -ChildPath 'Atlas.Appx\Atlas.Appx.psd1') -Force

    # A key of its own: other test files share and delete AtlasRewriteTest, and may run
    # at the same time.
    $script:testRoot = "HKCU:\Software\AtlasAppxTest-$([guid]::NewGuid().ToString('N'))"
    $script:deprovisionedKey = "$script:testRoot\Deprovisioned"
}

AfterAll {
    Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Get-AtlasAppxRemovedPackage' {
    It 'returns only families present in the snapshot but no longer installed' {
        InModuleScope Atlas.Appx {
            $removed = Get-AtlasAppxRemovedPackage `
                -Snapshot @('Pkg.A_abc', '', 'Pkg.B_abc', $null, 'Pkg.C_abc') `
                -Current @('Pkg.B_abc', 'Pkg.D_abc')
            $removed | Should -Be @('Pkg.A_abc', 'Pkg.C_abc')

            $removed = Get-AtlasAppxRemovedPackage -Snapshot @('Pkg.A_abc') -Current @('Pkg.A_abc', 'Pkg.B_abc')
            @($removed).Count | Should -Be 0
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

    It 'also registers matched families that are still listed, so a feature update cannot bring them back' {
        $snapshotPath = Join-Path -Path $TestDrive -ChildPath 'AtlasPackagesOld.txt'
        Set-Content -LiteralPath $snapshotPath -Value @('Pkg.Removed_abc', 'Pkg.StaleAccount_abc', 'Pkg.Kept_abc')

        Set-AtlasAppxDeprovisioned -SnapshotPath $snapshotPath `
            -DeprovisionedKeyPath $script:deprovisionedKey `
            -CurrentPackages @('Pkg.StaleAccount_abc', 'Pkg.Kept_abc') `
            -MatchedFamilies @('Pkg.StaleAccount_abc', 'Pkg.ProvisionedOnly_abc', 'pkg.removed_ABC')

        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.Removed_abc" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.StaleAccount_abc" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.ProvisionedOnly_abc" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.Kept_abc" | Should -BeFalse
        # A family both removed and matched is registered and logged once.
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Message -like '*Pkg.Removed_abc*' -or $Message -like '*pkg.removed_ABC*'
        }
    }

    It 'registers by default the provisioned family a removal plan matched, once' {
        Mock Test-AtlasOption -ModuleName Atlas.Appx -MockWith { $true }
        Mock Get-AtlasAppxRemovalAccount -ModuleName Atlas.Appx -MockWith {
            [pscustomobject]@{ Sid = 'S-1-5-21-1000-1000-1000-1001'; Description = 'the installing user'; Absence = $null }
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith {
            $script:testDeprovisionProvisionedCalls++
            if ($script:testDeprovisionProvisionedCalls -eq 1) {
                return @([pscustomobject]@{
                        DisplayName = 'Contoso.Provisioned'; PackageName = 'Contoso.Provisioned_1.0.0.0_neutral__abc123'
                    })
            }
            return @()
        }
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx
        $script:testDeprovisionProvisionedCalls = 0
        Invoke-AtlasAppxRemovalPlan -Definition @(
            [pscustomobject]@{ Name = 'Contoso.Provisioned*'; Option = $null; IgnoreErrors = $false }
        )

        $snapshotPath = Join-Path -Path $TestDrive -ChildPath 'AtlasPackagesOld.txt'
        Set-Content -LiteralPath $snapshotPath -Value @('Pkg.Kept_abc')
        Set-AtlasAppxDeprovisioned -SnapshotPath $snapshotPath `
            -DeprovisionedKeyPath $script:deprovisionedKey `
            -CurrentPackages @('Pkg.Kept_abc')

        Test-Path -LiteralPath "$script:deprovisionedKey\Contoso.Provisioned_abc123" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Pkg.Kept_abc" | Should -BeFalse

        # The matched families are spent: a later run that matched nothing adds none.
        Remove-Item -LiteralPath "$script:deprovisionedKey\Contoso.Provisioned_abc123" -Recurse -Force
        Set-Content -LiteralPath $snapshotPath -Value @('Pkg.Kept_abc')
        Set-AtlasAppxDeprovisioned -SnapshotPath $snapshotPath `
            -DeprovisionedKeyPath $script:deprovisionedKey `
            -CurrentPackages @('Pkg.Kept_abc')

        Test-Path -LiteralPath "$script:deprovisionedKey\Contoso.Provisioned_abc123" | Should -BeFalse
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

    It 'empties TempState and *Cache* folders while keeping SettingsCache.txt, other data and other profiles' {
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

        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'TempState\temp.dat') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\cache.dat') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\WebCache\SettingsCache.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:packageRoot -ChildPath 'LocalState\Data\keep.dat') | Should -BeTrue
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
        try {
            New-Item -Path $junctionPath -ItemType Junction -Target $outside `
                -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because "Directory junctions are unavailable: $($_.Exception.Message)"
            return
        }

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

    It 'rejects <Case>' -TestCases @(
        @{
            Case = 'a child whose SID differs from the install state'
            UserSid = 'S-1-5-21-1000-1000-1000-1002'; IsAdministrator = $false; RegisteredLeaf = 'InstallingUser'
            Message = '*SID differs from the install-state-bound user*'
        }
        @{
            Case = 'an administrator token even when the SID matches'
            UserSid = $null; IsAdministrator = $true; RegisteredLeaf = 'InstallingUser'
            Message = '*not an exact unelevated user process*'
        }
        @{
            Case = 'a profile path that disagrees with protected registration'
            UserSid = $null; IsAdministrator = $false; RegisteredLeaf = 'DifferentUser'
            Message = '*differs from the protected SID-to-profile registration*'
        }
    ) {
        $evidence = [pscustomobject]@{
            UserSid               = if ($UserSid) { $UserSid } else { $script:cacheUserSid }
            IsAdministrator       = $IsAdministrator
            ProfileRoot           = $script:cacheProfile
            RegisteredProfileRoot = Join-Path -Path $TestDrive -ChildPath "Users\$RegisteredLeaf"
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
        } | Should -Throw -ExpectedMessage $Message
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

    It 'fails when a stopped same-session package process misses the time-limited exit postcondition' {
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
            -ChildPath 'Scripts\Operations\Clear-AtlasUserAppxCache.ps1'
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

    It 'names the session-helper stage and the likely cause when the quiesce child exits 12' {
        {
            InModuleScope Atlas.Appx -Parameters @{ Context = $script:launcherContext } {
                param($Context)
                Invoke-AtlasUserAppxCacheCleanupCore -Context $Context `
                    -Mode AppxQuiesce -Launcher { return 12 }
            }
        } | Should -Throw -ExpectedMessage '*AppxQuiesce AppX step*during process stop (exit code 12)*Teams or Windows Search*'
    }

    It 'rejects a reparse point in the protected child script ancestry before launch' {
        $junctionWindows = Join-Path -Path $TestDrive -ChildPath 'JunctionWindows'
        $junctionPowerShell = Join-Path -Path $junctionWindows `
            -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $junctionModules = Join-Path -Path $junctionWindows -ChildPath 'AtlasModules'
        $scriptsPath = Join-Path -Path $junctionModules -ChildPath 'Scripts'
        $outsideOperations = Join-Path -Path $TestDrive -ChildPath 'OutsideOperations'
        New-Item -Path (Split-Path -Parent $junctionPowerShell) -ItemType Directory -Force | Out-Null
        New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
        New-Item -Path $outsideOperations -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $junctionPowerShell -Value 'test executable'
        Set-Content -LiteralPath (Join-Path $outsideOperations 'Clear-AtlasUserAppxCache.ps1') `
            -Value 'redirected script'
        try {
            New-Item -Path (Join-Path $scriptsPath 'Operations') -ItemType Junction `
                -Target $outsideOperations -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because "Directory junctions are unavailable: $($_.Exception.Message)"
            return
        }
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

Describe 'Exact-user AppX cache child script' {
    It 'exits <ExitCode> in <Mode> mode when the session step <Outcome>' -TestCases @(
        @{ Mode = 'AppxQuiesce'; Outcome = 'fails'; ExitCode = 12; CacheCleared = $false }
        @{ Mode = 'AppxSupport'; Outcome = 'fails'; ExitCode = 12; CacheCleared = $false }
        @{ Mode = 'AppxSupport'; Outcome = 'succeeds'; ExitCode = 0; CacheCleared = $true }
    ) {
        $scripts = Join-Path $TestDrive "child-$Mode-$Outcome\Scripts"
        $operations = Join-Path $scripts 'Operations'
        $appx = Join-Path $scripts 'Modules\Atlas.Appx'
        New-Item -Path $operations, $appx -ItemType Directory -Force | Out-Null
        Copy-Item (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') $scripts
        Copy-Item (Join-Path $script:AtlasTestScriptsRoot 'Operations\Clear-AtlasUserAppxCache.ps1') $operations
        $helper = 'param([string]$Operation, [string]$ExpectedUserSid)'
        if ($Outcome -eq 'fails') {
            # The real helper reports a failed process stop this way.
            $helper += "`ntrap { exit 12 }`nthrow 'fixture process stop failure'"
        }
        Set-Content (Join-Path $operations 'Invoke-AtlasUserShellRefresh.ps1') $helper
        $marker = Join-Path $TestDrive "cache-$Mode-$Outcome.txt"
        Set-Content (Join-Path $appx 'Atlas.Appx.psd1') "@{ RootModule = 'Atlas.Appx.psm1'; ModuleVersion = '1.0.0' }"
        Set-Content (Join-Path $appx 'Atlas.Appx.psm1') (
            'function Clear-AtlasAppxCache { param($Mode, $ExpectedUserSid) ' +
            "Set-Content -LiteralPath '$marker' -Value `$Mode }"
        )

        & (Join-Path $PSHOME 'powershell.exe') -NoProfile -NonInteractive -ExecutionPolicy Bypass `
            -File (Join-Path $operations 'Clear-AtlasUserAppxCache.ps1') `
            -Mode $Mode -ExpectedUserSid 'S-1-5-21-1000-1000-1000-1001'

        $LASTEXITCODE | Should -Be $ExitCode
        Test-Path -LiteralPath $marker | Should -Be $CacheCleared
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
        Should -Invoke Get-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $AllUsers -and "$PackageTypeFilter" -match 'Bundle' -and "$PackageTypeFilter" -match 'Main'
        }
    }

    It 'keeps the snapshot with the install''s work during an install, which file replacement leaves alone: install state <Backed>' -TestCases @(
        @{ Backed = $true; Expected = 'C:\Windows\AtlasOS\Install\work\AtlasPackagesOld.txt' }
        @{ Backed = $false; Expected = 'C:\Windows\AtlasModules\AtlasPackagesOld.txt' }
    ) {
        param($Backed, $Expected)
        $context = [pscustomobject]@{ WinDir = 'C:\Windows'; AtlasModulesPath = 'C:\Windows\AtlasModules'; IsInstallStateBacked = $Backed }
        Mock Get-AtlasContext -ModuleName Atlas.Appx -MockWith { $context }.GetNewClosure()
        InModuleScope Atlas.Appx { Get-AtlasAppxSnapshotPath } | Should -BeExactly $Expected
    }

    It 'deprovisions on a resumed install what an interrupted attempt removed after its snapshot' {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Mock Get-AtlasContext -ModuleName Atlas.Appx { [pscustomobject]@{ IsInstallStateBacked = $true } }
        Mock Get-AppxPackage -ModuleName Atlas.Appx { [pscustomobject]@{ PackageFamilyName = 'Contoso.Kept_abc' } }
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
        $snapshotPath = Join-Path -Path $TestDrive -ChildPath "resumed-$([guid]::NewGuid().ToString('N'))\AtlasPackagesOld.txt"
        $null = New-Item -Path (Split-Path -Parent $snapshotPath) -ItemType Directory
        # The attempt's snapshot, taken before it removed Snipping Tool and stopped.
        Set-Content -LiteralPath $snapshotPath -Value @('Contoso.Kept_abc', 'Microsoft.ScreenSketch_8wekyb3d8bbwe')

        Save-AtlasAppxSnapshot -Path $snapshotPath
        @(Get-Content -LiteralPath $snapshotPath) | Should -Be @('Contoso.Kept_abc', 'Microsoft.ScreenSketch_8wekyb3d8bbwe')
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Message -like "*keeping the families an interrupted attempt's snapshot listed that are gone now: Microsoft.ScreenSketch_8wekyb3d8bbwe."
        }

        Set-AtlasAppxDeprovisioned -SnapshotPath $snapshotPath -DeprovisionedKeyPath $script:deprovisionedKey `
            -CurrentPackages @('Contoso.Kept_abc') -MatchedFamilies @()
        Test-Path -LiteralPath "$script:deprovisionedKey\Microsoft.ScreenSketch_8wekyb3d8bbwe" | Should -BeTrue
        Test-Path -LiteralPath "$script:deprovisionedKey\Contoso.Kept_abc" | Should -BeFalse
    }

    It 'replaces a snapshot left outside an install' {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Mock Get-AtlasContext -ModuleName Atlas.Appx { [pscustomobject]@{ IsInstallStateBacked = $false } }
        Mock Get-AppxPackage -ModuleName Atlas.Appx { [pscustomobject]@{ PackageFamilyName = 'Contoso.Kept_abc' } }
        $snapshotPath = Join-Path -Path $TestDrive -ChildPath "toggle-$([guid]::NewGuid().ToString('N'))\AtlasPackagesOld.txt"
        $null = New-Item -Path (Split-Path -Parent $snapshotPath) -ItemType Directory
        Set-Content -LiteralPath $snapshotPath -Value @('Contoso.Kept_abc', 'Contoso.LongGone_abc')

        Save-AtlasAppxSnapshot -Path $snapshotPath
        @(Get-Content -LiteralPath $snapshotPath) | Should -Be @('Contoso.Kept_abc')
    }
}

Describe 'AppX removal policy' {
    It 'declares the removal option gates and warning-only families' {
        $definitions = @(Get-AtlasAppxRemovalDefinition)

        @($definitions | Where-Object Option -eq 'uninstall-edge').Name | Should -Be @(
            'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
            'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
            'Microsoft.Edge.GameAssist*'
        )
        @($definitions | Where-Object Option -eq 'remove-snipping-tool').Name |
            Should -Be @('Microsoft.ScreenSketch*')

        [xml]$playbook = [IO.File]::ReadAllText((Join-Path $script:AtlasTestRepoRoot 'playbook\playbook.conf'))
        $featureOptions = @($playbook.SelectNodes('/Playbook/FeaturePages/*/Options/*/Name') | ForEach-Object { $_.InnerText })
        foreach ($option in @($definitions | Where-Object Option | ForEach-Object Option)) {
            $option | Should -BeIn $featureOptions
        }

        # Ordered: WebExperience must be removed before the runtime it depends on.
        @($definitions | Where-Object IgnoreErrors).Name | Should -Be @(
            'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
            'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
            'Microsoft.Edge.GameAssist*'
            'MicrosoftWindows.Client.WebExperience*'
            'Microsoft.WidgetsPlatformRuntime*'
        )
    }

    It 'never matches a package that Windows, the Store or winget needs' {
        $protected = @(
            'Microsoft.WindowsStore', 'Microsoft.DesktopAppInstaller', 'Microsoft.SecHealthUI'
            'Microsoft.Windows.ShellExperienceHost', 'Microsoft.Windows.StartMenuExperienceHost'
            'Microsoft.VCLibs.140.00', 'Microsoft.UI.Xaml.2.8', 'Microsoft.WindowsAppRuntime.1.5'
        )
        InModuleScope Atlas.Appx -Parameters @{ Protected = $protected } {
            param($Protected)
            $definitions = @(Get-AtlasAppxRemovalDefinition)
            foreach ($family in $Protected) {
                $package = [pscustomobject]@{ Name = $family; PackageFamilyName = "$($family)_8wekyb3d8bbwe" }
                @($definitions | Where-Object { Test-AtlasAppxFamilyMatch -Package $package -Name $_.Name }) |
                    Should -BeNullOrEmpty -Because $family
            }
        }
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

    It 'lists the families Windows provisions once each, from DISM''s package names' {
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith {
            [pscustomobject]@{ DisplayName = 'Microsoft.ScreenSketch'; PackageName = 'Microsoft.ScreenSketch_2022.2307.52.0_neutral_~_8wekyb3d8bbwe' }
            [pscustomobject]@{ DisplayName = 'Microsoft.ScreenSketch'; PackageName = 'Microsoft.ScreenSketch_2022.2308.1.0_neutral_~_8wekyb3d8bbwe' }
            [pscustomobject]@{ DisplayName = 'MSTeams'; PackageName = 'MSTeams_1.0.0.0_x64__8wekyb3d8bbwe' }
            [pscustomobject]@{ DisplayName = 'Unnamed'; PackageName = 'not-a-package-name' }
        }

        @(Get-AtlasAppxProvisionedFamily) | Should -Be @('Microsoft.ScreenSketch_8wekyb3d8bbwe', 'MSTeams_8wekyb3d8bbwe')
    }

    It 'throws when what Windows provisions can''t be read' {
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { throw 'DISM is busy' }

        { Get-AtlasAppxProvisionedFamily } | Should -Throw 'DISM is busy'
    }
}

Describe 'Get-AtlasAppxRemovalAccount' {
    It 'returns <Expected> for <Case>' -TestCases @(
        @{
            Case = 'an install with a recorded user'; Expected = 'the recorded SID'
            State = @{ IsInstallStateBacked = $true; IsOobe = $false; InteractiveUserSid = 'S-1-5-21-1000-1000-1000-1001' }
            Sid = 'S-1-5-21-1000-1000-1000-1001'; Absence = $null
        }
        @{
            Case = 'an install during OOBE'; Expected = 'no account'
            State = @{ IsInstallStateBacked = $true; IsOobe = $true; InteractiveUserSid = 'S-1-5-21-1000-1000-1000-1001' }
            Sid = $null; Absence = "During OOBE there's no installing user to check it against"
        }
        @{
            Case = 'an install that recorded no user'; Expected = 'no account'
            State = @{ IsInstallStateBacked = $true; IsOobe = $false; InteractiveUserSid = $null }
            Sid = $null; Absence = 'The install recorded no installing user to check it against'
        }
    ) {
        $context = [pscustomobject]$State
        Mock Get-AtlasContext -ModuleName Atlas.Appx -MockWith { $context }.GetNewClosure()

        $actual = InModuleScope Atlas.Appx { Get-AtlasAppxRemovalAccount }

        $actual.Sid | Should -Be $Sid
        $actual.Description | Should -Be 'the installing user'
        $actual.Absence | Should -Be $Absence
    }

    It 'uses the account running a toggle outside an install' {
        $context = [pscustomobject]@{ IsInstallStateBacked = $false; IsOobe = $false; InteractiveUserSid = $null }
        Mock Get-AtlasContext -ModuleName Atlas.Appx -MockWith { $context }.GetNewClosure()

        $actual = InModuleScope Atlas.Appx { Get-AtlasAppxRemovalAccount }

        $actual.Sid | Should -Be ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
        $actual.Description | Should -Be 'this account'
    }

    It 'rejects an install-state user SID that <Case>, as the cache cleanup does' -TestCases @(
        @{ Case = 'is not a SID'; Value = 'not-a-sid'; Expected = '*AppX removal user SID is not a valid SID.' }
        @{ Case = 'is SYSTEM'; Value = 'S-1-5-18'; Expected = '*AppX removal user SID is not a canonical user account SID.' }
    ) {
        $context = [pscustomobject]@{ IsInstallStateBacked = $true; IsOobe = $false; InteractiveUserSid = $Value }
        Mock Get-AtlasContext -ModuleName Atlas.Appx -MockWith { $context }.GetNewClosure()

        { InModuleScope Atlas.Appx { Get-AtlasAppxRemovalAccount } } |
            Should -Throw -ExpectedMessage $Expected
    }
}

Describe 'Get-AtlasAppxRegistrationKind' {
    # The states Get-AppxPackage -AllUsers reports, with the suffix it adds to a
    # registration whose removal Windows has accepted.
    It 'classifies <State> as <Kind>' -TestCases @(
        @{ State = 'Installed'; Kind = 'Installed' }
        @{ State = 'Paused'; Kind = 'Installed' }
        @{ State = ''; Kind = 'Installed' }
        @{ State = 'Installed(pending removal)'; Kind = 'PendingRemoval' }
        @{ State = 'Staged'; Kind = 'NotInstalled' }
        @{ State = 'NotInstalled'; Kind = 'NotInstalled' }
        @{ State = 'Staged(pending removal)'; Kind = 'NotInstalled' }
        @{ State = 'NotInstalled(pending removal)'; Kind = 'NotInstalled' }
    ) {
        InModuleScope Atlas.Appx -Parameters @{ State = $State } {
            param($State)
            Get-AtlasAppxRegistrationKind -InstallState $State
        } | Should -Be $Kind
    }
}

Describe 'Get-AtlasAppxParentInstalledPackage' {
    It 'keeps a Main package whose version no bundle of its family has, when there are several' {
        InModuleScope Atlas.Appx {
            $packages = @(
                [pscustomobject]@{ Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_1.0_neutral_~_abc'; Version = '1.0'; IsBundle = $true }
                [pscustomobject]@{ Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_1.0_x64__abc'; Version = '1.0'; IsBundle = $false }
                [pscustomobject]@{ Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_2.0_neutral_~_abc'; Version = '2.0'; IsBundle = $true }
                [pscustomobject]@{ Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_3.0_x64__abc'; Version = '3.0'; IsBundle = $false }
            )

            @(Get-AtlasAppxParentInstalledPackage -Package $packages).PackageFullName | Should -Be @(
                'D.App_1.0_neutral_~_abc', 'D.App_2.0_neutral_~_abc', 'D.App_3.0_x64__abc'
            )
        }
    }

    It 'gives a Main package to its family''s only bundle, whatever their versions' {
        # Calculator's 2021.x bundle holds an 11.x app.
        InModuleScope Atlas.Appx {
            $packages = @(
                [pscustomobject]@{
                    Name = 'Microsoft.WindowsCalculator'; PackageFamilyName = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'
                    PackageFullName = 'Microsoft.WindowsCalculator_2021.2607.0.0_neutral_~_8wekyb3d8bbwe'; Version = '2021.2607.0.0'; IsBundle = $true
                }
                [pscustomobject]@{
                    Name = 'Microsoft.WindowsCalculator'; PackageFamilyName = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'
                    PackageFullName = 'Microsoft.WindowsCalculator_11.2607.0.0_x64__8wekyb3d8bbwe'; Version = '11.2607.0.0'; IsBundle = $false
                }
            )

            @(Get-AtlasAppxParentInstalledPackage -Package $packages).PackageFullName |
                Should -Be 'Microsoft.WindowsCalculator_2021.2607.0.0_neutral_~_8wekyb3d8bbwe'
        }
    }
}

Describe 'Invoke-AtlasAppxRemovalPlan' {
    BeforeAll {
        $script:installingSid = 'S-1-5-21-1000-1000-1000-1001'
        $script:otherSid = 'S-1-5-21-1000-1000-1000-1000'

        function New-TestRegistration {
            param([string]$Sid, [string]$State = 'Installed', [string]$UserName = $Sid)
            [pscustomobject]@{
                UserSecurityId = [pscustomobject]@{ Sid = $Sid; Username = $UserName }
                InstallState   = $State
            }
        }
    }

    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Mock Test-AtlasOption -ModuleName Atlas.Appx -MockWith { $true }
        Mock Start-Sleep -ModuleName Atlas.Appx
        $account = [pscustomobject]@{ Sid = $script:installingSid; Description = 'the installing user'; Absence = $null }
        Mock Get-AtlasAppxRemovalAccount -ModuleName Atlas.Appx -MockWith { $account }.GetNewClosure()
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

        # Mock bodies run in this file's session state, so their counters live here.
        $script:testInstalledInventoryCalls = 0
        $script:testProvisionedInventoryCalls = 0
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

        # Removing the Main child after its bundle parent reports a false failure.
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Package -ceq 'Bundled.App_2.0_neutral_~_abc' -and $AllUsers
        }
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

    It 'defers an IgnoreErrors removal error to final inventory and warns once when the package remains' {
        $definition = [pscustomobject]@{ Name = 'Optional.App*'; Option = $null; IgnoreErrors = $true }
        $installed = [pscustomobject]@{
            Name = 'Optional.App'; PackageFamilyName = 'Optional.App_abc'; PackageFullName = 'Optional.App_1.0_x64__abc'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx -MockWith { throw 'access denied' }

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter { $AllUsers }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -ne 'Warning' -and $Level -ne 'Error' -and
            $Message -like "*'Optional.App_1.0_x64__abc'; deferring to final inventory: access denied"
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "Ignoring AppX removal failure for 'Optional.App*':*"
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter {
            $Level -eq 'Error'
        }
    }

    It 'attempts every required family and aggregates failures after verification' {
        $definitions = @(
            [pscustomobject]@{ Name = 'Required.One*'; Option = $null; IgnoreErrors = $false }
            [pscustomobject]@{ Name = 'Required.Two*'; Option = $null; IgnoreErrors = $false }
        )
        $installed = @(
            [pscustomobject]@{
                Name = 'Required.One'; PackageFullName = 'Required.One_1.0_x64__abc'
                PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
            }
        )
        $provisioned = @(
            [pscustomobject]@{ DisplayName = 'Required.Two'; PackageName = 'Required.Two_1.0_neutral__abc' }
        )
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @($provisioned) }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx -MockWith { throw "failed $Package" }
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -MockWith { throw "failed $PackageName" }

        $thrown = $null
        try { Invoke-AtlasAppxRemovalPlan -Definition $definitions } catch { $thrown = $_.Exception.Message }

        $thrown | Should -Be (
            "AppX removal completed with 2 required failure(s): Required.One*: 'Required.One_1.0_x64__abc' is still " +
            "installed for the installing user ($script:installingSid). | Required.Two*: Still provisioned for new " +
            "accounts: 'Required.Two_1.0_neutral__abc'. An app still installed for you can be uninstalled in " +
            'Settings > Apps before you try again.'
        )
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter { $AllUsers }
        Should -Invoke Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -Times 1 -Exactly
        # Atlas Manager names the apps from these lines.
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Error' -and $Message -like "AppX removal failed for 'Required.One*': *"
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Error' -and $Message -like "AppX removal failed for 'Required.Two*': *"
        }
    }

    It 'accepts a provisioned-package error when final inventory confirms removal' {
        $definition = [pscustomobject]@{ Name = 'Stale.App*'; Option = $null; IgnoreErrors = $false }
        $script:testStaleProvisionedCalls = 0
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith {
            $script:testStaleProvisionedCalls++
            if ($script:testStaleProvisionedCalls -eq 1) {
                return @([pscustomobject]@{
                        DisplayName = 'Stale.App'; PackageName = 'Stale.App_1.0_neutral__abc'
                    })
            }
            return @()
        }
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -MockWith { throw 'path not found' }

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Remove-AppxProvisionedPackage -ModuleName Atlas.Appx -Times 1 -Exactly
    }

    It 'fails when a cmdlet reports success but a required package remains installed for the installing user' {
        $definition = [pscustomobject]@{ Name = 'Stubborn.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Stubborn.App'; PackageFamilyName = 'Stubborn.App_abc'; PackageFullName = 'Stubborn.App_1.0_x64__abc'
            Status = 'Ok'; IsPartiallyStaged = $false; NonRemovable = $false; SignatureKind = 'Store'
            PackageUserInformation = @(
                New-TestRegistration -Sid $script:otherSid
                New-TestRegistration -Sid $script:installingSid -UserName 'InstallingUser'
            )
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } |
            Should -Throw -ExpectedMessage (
                "AppX removal completed with 1 required failure(s): Stubborn.App*: 'Stubborn.App_1.0_x64__abc' " +
                "is still installed for the installing user ($script:installingSid). An app still installed for " +
                'you can be uninstalled in Settings > Apps before you try again.'
            )

        # One more removal for each account it is installed for, then a second look.
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Package -eq 'Stubborn.App_1.0_x64__abc' -and $User -eq $script:installingSid
        }
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Package -eq 'Stubborn.App_1.0_x64__abc' -and $User -eq $script:otherSid
        }
        Should -Invoke Start-Sleep -ModuleName Atlas.Appx -Times 1 -Exactly
        Should -Invoke Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -Times 3 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -ne 'Warning' -and $Level -ne 'Error' -and
            $Message -eq (
                "AppX package 'Stubborn.App_1.0_x64__abc' for 'Stubborn.App*' is still registered: Status=Ok, " +
                'IsPartiallyStaged=False, NonRemovable=False, SignatureKind=Store; accounts: ' +
                "$($script:otherSid): Installed; $($script:installingSid) (InstallingUser): Installed."
            )
        }
    }

    It 'warns and continues when a leftover is held only by other accounts, SYSTEM or deleted accounts' {
        $definition = [pscustomobject]@{ Name = 'MSTeams*'; Option = $null; IgnoreErrors = $false }
        $deletedSid = 'S-1-5-21-1000-1000-1000-1003'
        $pendingSid = 'S-1-5-21-1000-1000-1000-1004'
        $installed = [pscustomobject]@{
            Name = 'MSTeams'; PackageFamilyName = 'MSTeams_8wekyb3d8bbwe'
            PackageFullName = 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'
            PackageUserInformation = @(
                New-TestRegistration -Sid $script:otherSid
                New-TestRegistration -Sid 'S-1-5-18'
                New-TestRegistration -Sid $deletedSid -UserName ''
                New-TestRegistration -Sid ''
                New-TestRegistration -Sid $pendingSid -State 'Installed(pending removal)'
                New-TestRegistration -Sid $script:installingSid -State 'Staged'
            )
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx -MockWith {
            if ($User) { throw 'The user is not found.' }
        }

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $User -eq $script:otherSid
        }
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $User -eq 'S-1-5-18'
        }
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $User -eq 'S-1-5-21-1000-1000-1000-1003'
        }
        # Only installed registrations of a known account get the extra removal: not the
        # staged one, the pending removal or the entry without a SID.
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 4 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -eq (
                "AppX package 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe' for 'MSTeams*' is still registered, " +
                "but not installed for the installing user ($($script:otherSid): Installed; S-1-5-18: Installed; " +
                "$($deletedSid): Installed; (unknown account): Installed; $($pendingSid): Installed(pending removal); " +
                "$($script:installingSid): Staged), so Atlas continues."
            )
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -ne 'Warning' -and
            $Message -like "Removing AppX package 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe' for account '$($script:otherSid)' reported an error: The user is not found."
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter { $Level -eq 'Error' }
    }

    It 'warns and continues when a leftover is staged with no account registration' {
        $definition = [pscustomobject]@{ Name = 'Staged.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Staged.App'; PackageFamilyName = 'Staged.App_abc'; PackageFullName = 'Staged.App_1.0_x64__abc'
            IsPartiallyStaged = $true
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and
            $Message -like "AppX package 'Staged.App_1.0_x64__abc'*not installed for the installing user (no account has it registered)*"
        }
    }

    It 'fails when a required family stays provisioned, naming the package' {
        $definition = [pscustomobject]@{ Name = 'Provisioned.App*'; Option = $null; IgnoreErrors = $false }
        $provisioned = [pscustomobject]@{
            DisplayName = 'Provisioned.App'; PackageName = 'Provisioned.App_1.0_neutral__abc'
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @($provisioned) }
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } |
            Should -Throw -ExpectedMessage (
                "*Provisioned.App*: Still provisioned for new accounts: 'Provisioned.App_1.0_neutral__abc'.*"
            )
        Should -Invoke Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -Times 3 -Exactly
    }

    It 'without an installing user, fails on a provisioned leftover and only warns on the rest' {
        Mock Get-AtlasAppxRemovalAccount -ModuleName Atlas.Appx -MockWith {
            [pscustomobject]@{
                Sid = $null; Description = 'the installing user'
                Absence = "During OOBE there's no installing user to check it against"
            }
        }
        $definitions = @(
            [pscustomobject]@{ Name = 'Installed.App*'; Option = $null; IgnoreErrors = $false }
            [pscustomobject]@{ Name = 'Provisioned.App*'; Option = $null; IgnoreErrors = $false }
        )
        $installed = [pscustomobject]@{
            Name = 'Installed.App'; PackageFamilyName = 'Installed.App_abc'; PackageFullName = 'Installed.App_1.0_x64__abc'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        $provisioned = [pscustomobject]@{
            DisplayName = 'Provisioned.App'; PackageName = 'Provisioned.App_1.0_neutral__abc'
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @($provisioned) }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx
        Mock Remove-AppxProvisionedPackage -ModuleName Atlas.Appx

        $thrown = $null
        try { Invoke-AtlasAppxRemovalPlan -Definition $definitions } catch { $thrown = $_.Exception.Message }

        # Nobody can uninstall a provisioned package in Settings, so no such advice.
        $thrown | Should -Be "AppX removal completed with 1 required failure(s): Provisioned.App*: Still provisioned for new accounts: 'Provisioned.App_1.0_neutral__abc'."
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -eq (
                "AppX package 'Installed.App_1.0_x64__abc' for 'Installed.App*' is still registered " +
                "($($script:installingSid): Installed). During OOBE there's no installing user to check it against, " +
                'so Atlas continues.'
            )
        }
    }

    It 'warns and continues when the installing user''s registration is <Case>' -TestCases @(
        @{
            Case = 'pending removal'; State = 'Installed(pending removal)'
            Expected = "but Windows finishes removing it for the installing user when the app closes or the account signs out (S-1-5-21-1000-1000-1000-1001: Installed(pending removal)), so Atlas continues."
        }
        @{
            Case = 'staged and pending removal'; State = 'Staged(pending removal)'
            Expected = 'but not installed for the installing user (S-1-5-21-1000-1000-1000-1001: Staged(pending removal)), so Atlas continues.'
        }
    ) {
        $definition = [pscustomobject]@{ Name = 'MSTeams*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'MSTeams'; PackageFamilyName = 'MSTeams_8wekyb3d8bbwe'
            PackageFullName = 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid -State $State)
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }.GetNewClosure()
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        # Windows already accepted the removal, so removing it again changes nothing.
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter { $User }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -eq (
                "AppX package 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe' for 'MSTeams*' is still registered, $Expected"
            )
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter { $Level -eq 'Error' }
    }

    It 'names the account running a toggle as this account' {
        $account = [pscustomobject]@{ Sid = $script:installingSid; Description = 'this account'; Absence = $null }
        Mock Get-AtlasAppxRemovalAccount -ModuleName Atlas.Appx -MockWith { $account }.GetNewClosure()
        $definition = [pscustomobject]@{ Name = 'Microsoft.Copilot*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Microsoft.Copilot'; PackageFamilyName = 'Microsoft.Copilot_8wekyb3d8bbwe'
            PackageFullName = 'Microsoft.Copilot_1.0_x64__8wekyb3d8bbwe'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } |
            Should -Throw -ExpectedMessage "*'Microsoft.Copilot_1.0_x64__8wekyb3d8bbwe' is still installed for this account ($script:installingSid).*"
    }

    It 'judges each bundle version by its own registrations when an account is on another version' {
        $definition = [pscustomobject]@{ Name = 'D.App*'; Option = $null; IgnoreErrors = $false }
        $installed = @(
            [pscustomobject]@{
                Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_1.0_neutral_~_abc'; Version = '1.0'; IsBundle = $true
            }
            [pscustomobject]@{
                Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_1.0_x64__abc'; Version = '1.0'; IsBundle = $false
                PackageUserInformation = @(New-TestRegistration -Sid 'S-1-5-18' -State 'Staged')
            }
            [pscustomobject]@{
                Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_2.0_neutral_~_abc'; Version = '2.0'; IsBundle = $true
            }
            [pscustomobject]@{
                Name = 'D.App'; PackageFamilyName = 'D.App_abc'; PackageFullName = 'D.App_2.0_x64__abc'; Version = '2.0'; IsBundle = $false
                PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
            }
        )
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { $installed }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        $thrown = $null
        try { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } catch { $thrown = $_.Exception.Message }

        $thrown | Should -BeLike (
            "AppX removal completed with 1 required failure(s): D.App*: 'D.App_2.0_neutral_~_abc' is still " +
            "installed for the installing user ($script:installingSid).*"
        )
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter { $User }
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Package -eq 'D.App_2.0_neutral_~_abc' -and $User -eq $script:installingSid
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -eq (
                "AppX package 'D.App_1.0_neutral_~_abc' for 'D.App*' is still registered, but not installed " +
                'for the installing user (S-1-5-18: Staged), so Atlas continues.'
            )
        }
    }

    It 'fails when the second inventory cannot be read, still naming what the first found' {
        $definition = [pscustomobject]@{ Name = 'Stubborn.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Stubborn.App'; PackageFamilyName = 'Stubborn.App_abc'; PackageFullName = 'Stubborn.App_1.0_x64__abc'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        $script:testFailingInventoryCalls = 0
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith {
            $script:testFailingInventoryCalls++
            if ($script:testFailingInventoryCalls -le 2) { return @($installed) }
            throw 'The service is busy'
        }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        $thrown = $null
        try { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } catch { $thrown = $_.Exception.Message }

        $thrown | Should -BeLike (
            'AppX removal completed with 2 required failure(s): Installed-package verification failed: The service is busy. | ' +
            "Stubborn.App*: 'Stubborn.App_1.0_x64__abc' is still installed for the installing user*"
        )
    }

    It 'accepts a removal when only the first look again failed to read the inventory' {
        $definition = [pscustomobject]@{ Name = 'Slow.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Slow.App'; PackageFamilyName = 'Slow.App_abc'; PackageFullName = 'Slow.App_1.0_x64__abc'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        $script:testTransientInventoryCalls = 0
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith {
            $script:testTransientInventoryCalls++
            if ($script:testTransientInventoryCalls -eq 1) { return @($installed) }
            if ($script:testTransientInventoryCalls -eq 2) { throw 'The service is busy' }
            return @()
        }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Start-Sleep -ModuleName Atlas.Appx -Times 1 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -eq 'Installed-package verification failed: The service is busy. Atlas looks again shortly.'
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter { $Level -eq 'Error' }
    }

    It 'counts a bundle and its Main child as one leftover' {
        $definition = [pscustomobject]@{ Name = 'Microsoft.Windows.DevHome*'; Option = $null; IgnoreErrors = $false }
        $bundle = [pscustomobject]@{
            Name = 'Microsoft.Windows.DevHome'; PackageFamilyName = 'Microsoft.Windows.DevHome_8wekyb3d8bbwe'
            PackageFullName = 'Microsoft.Windows.DevHome_2024.401.618.0_neutral_~_8wekyb3d8bbwe'; IsBundle = $true
        }
        $main = [pscustomobject]@{
            Name = 'Microsoft.Windows.DevHome'; PackageFamilyName = 'Microsoft.Windows.DevHome_8wekyb3d8bbwe'
            PackageFullName = 'Microsoft.Windows.DevHome_2024.401.618.0_x64__8wekyb3d8bbwe'; IsBundle = $false
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($bundle, $main) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        $thrown = $null
        try { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } catch { $thrown = $_.Exception.Message }

        # The child's registration decides for its bundle, and the message names the bundle.
        $thrown | Should -BeLike (
            "AppX removal completed with 1 required failure(s): Microsoft.Windows.DevHome*: " +
            "'Microsoft.Windows.DevHome_2024.401.618.0_neutral_~_8wekyb3d8bbwe' is still installed for the installing user*"
        )
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Package -eq 'Microsoft.Windows.DevHome_2024.401.618.0_neutral_~_8wekyb3d8bbwe' -and $User -eq $script:installingSid
        }
        # Both packages are still described in the log.
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 2 -Exactly -ParameterFilter {
            $Level -ne 'Warning' -and $Level -ne 'Error' -and $Message -like "AppX package 'Microsoft.Windows.DevHome_*' for '*' is still registered: *"
        }
    }

    It 'accepts a removal that shows in the second inventory' {
        $definition = [pscustomobject]@{ Name = 'Slow.App*'; Option = $null; IgnoreErrors = $false }
        $installed = [pscustomobject]@{
            Name = 'Slow.App'; PackageFamilyName = 'Slow.App_abc'; PackageFullName = 'Slow.App_1.0_x64__abc'
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        $script:testSlowInventoryCalls = 0
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith {
            $script:testSlowInventoryCalls++
            if ($script:testSlowInventoryCalls -le 2) { return @($installed) }
            return @()
        }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Start-Sleep -ModuleName Atlas.Appx -Times 1 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -or $Level -eq 'Error'
        }
    }

    It 'does not wait or remove again when nothing is left' {
        $definition = [pscustomobject]@{ Name = 'Gone.App*'; Option = $null; IgnoreErrors = $false }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        Invoke-AtlasAppxRemovalPlan -Definition @($definition)

        Should -Invoke Start-Sleep -ModuleName Atlas.Appx -Times 0 -Exactly
        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 0 -Exactly
    }

    It 'never removes a NonRemovable leftover again for each account' {
        $definition = [pscustomobject]@{ Name = 'System.App*'; Option = $null; IgnoreErrors = $true }
        $installed = [pscustomobject]@{
            Name = 'System.App'; PackageFamilyName = 'System.App_abc'; PackageFullName = 'System.App_1.0_neutral__abc'
            NonRemovable = $true
            PackageUserInformation = @(New-TestRegistration -Sid $script:installingSid)
        }
        Mock Get-AtlasAppxInstalledInventory -ModuleName Atlas.Appx -MockWith { @($installed) }
        Mock Get-AtlasAppxProvisionedInventory -ModuleName Atlas.Appx -MockWith { @() }
        Mock Remove-AppxPackage -ModuleName Atlas.Appx

        { Invoke-AtlasAppxRemovalPlan -Definition @($definition) } | Should -Not -Throw

        Should -Invoke Remove-AppxPackage -ModuleName Atlas.Appx -Times 0 -Exactly -ParameterFilter { $User }
    }
}

Describe 'Install-AtlasGameBar' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Appx
        Mock Assert-AtlasTrustedWingetSource -ModuleName Atlas.Appx
        $script:wingetLog = Join-Path $TestDrive 'winget-args.txt'
        $script:fakeWinget = Join-Path $TestDrive 'winget.cmd'
        Mock Get-AtlasTrustedWingetPath -ModuleName Atlas.Appx { $script:fakeWinget }
        $script:gameBar = @()
        Mock Get-AppxPackage -ModuleName Atlas.Appx { $script:gameBar }
    }

    It 'leaves a Game Bar this account already has alone, without WinGet or the Store' {
        $script:gameBar = @([pscustomobject]@{ Name = 'Microsoft.XboxGamingOverlay'; Status = 'Ok' })

        Install-AtlasGameBar

        Should -Invoke Get-AppxPackage -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'Microsoft.XboxGamingOverlay' -and -not $AllUsers
        }
        Should -Not -Invoke Get-AtlasTrustedWingetPath -ModuleName Atlas.Appx
        Should -Not -Invoke Assert-AtlasTrustedWingetSource -ModuleName Atlas.Appx
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Message -like '*already installed for this account*'
        }
    }

    It 'installs a Game Bar this account has but Windows reports broken' {
        $script:gameBar = @([pscustomobject]@{ Name = 'Microsoft.XboxGamingOverlay'; Status = 'NeedsRemediation' })
        Set-Content -LiteralPath $script:fakeWinget -Encoding Ascii -Value '@exit /b 0'

        Install-AtlasGameBar

        Should -Invoke Get-AtlasTrustedWingetPath -ModuleName Atlas.Appx -Times 1 -Exactly
    }

    It 'installs the Store package through the trusted client with exact arguments' {
        Set-Content -LiteralPath $script:fakeWinget -Encoding Ascii -Value @(
            "@echo %*> `"$script:wingetLog`""
            '@exit /b 0'
        )

        Install-AtlasGameBar

        (Get-Content -LiteralPath $script:wingetLog -Raw).Trim() | Should -BeExactly (
            'install --exact --id 9NZKPSTSNW4P --source msstore ' +
            '--accept-package-agreements --accept-source-agreements --disable-interactivity --silent'
        )
        Should -Invoke Assert-AtlasTrustedWingetSource -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $WingetPath -eq $script:fakeWinget -and $Name -eq 'msstore'
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 0
    }

    It 'treats the no-applicable-upgrade result as already installed' {
        Set-Content -LiteralPath $script:fakeWinget -Encoding Ascii -Value '@exit /b -1978335189'

        { Install-AtlasGameBar } | Should -Not -Throw
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Appx -Times 1 -Exactly -ParameterFilter {
            $Message -like '*already installed*'
        }
    }

    It 'fails on any other WinGet exit code' {
        Set-Content -LiteralPath $script:fakeWinget -Encoding Ascii -Value '@exit /b 3'

        { Install-AtlasGameBar } | Should -Throw '*exit code 3*'
    }
}
