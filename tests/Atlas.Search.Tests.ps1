[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Module-scoped mock bodies cannot see test-file variables, so shared fixture state is staged as global variables.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    # A bare Windows PowerShell 5.1 host has not loaded the service controller types.
    Add-Type -AssemblyName System.ServiceProcess
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Search\Atlas.Search.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:entryPath = Join-Path $script:AtlasTestScriptsRoot 'Entry\Set-IndexConfiguration.ps1'
    $script:launcherPath = Join-Path $script:AtlasTestScriptsRoot 'Entry\Set-IndexConfiguration.cmd'
}

AfterAll {
    Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name AtlasSearchTestCalls, AtlasSearchTestService, AtlasSearchTestUsersRoot `
        -Scope Global -ErrorAction SilentlyContinue
}

Describe 'Index path behavior' {
    BeforeAll {
        # Point the module's fixed HKLM roots at the scratch hive for the duration
        # of this block so policy lists run against a real registry.
        $script:savedRoots = InModuleScope Atlas.Search {
            [pscustomobject]@{
                Paths    = $script:AtlasIndexPathRoots
                Policies = $script:AtlasIndexPolicyRoots
            }
        }
        InModuleScope Atlas.Search {
            $script:AtlasIndexPathRoots = @{
                Include = 'HKCU:\Software\AtlasRewriteTest\Search\Paths'
                Exclude = 'HKCU:\Software\AtlasRewriteTest\Search\Exclusions'
            }
            $script:AtlasIndexPolicyRoots = @(
                $script:AtlasIndexPathRoots.Include
                $script:AtlasIndexPathRoots.Exclude
            )
        }
    }

    AfterAll {
        InModuleScope Atlas.Search {
            $script:AtlasIndexPathRoots = $saved.Paths
            $script:AtlasIndexPolicyRoots = $saved.Policies
        } -Parameters @{ saved = $script:savedRoots }
    }

    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Search
        Mock Test-AtlasAdmin -ModuleName Atlas.Search { $true }
    }

    AfterEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'preserves literal path data and accepts drive and UNC absolute paths' {
        $drivePath = Join-Path $TestDrive 'Index %ATLAS_PERCENT% & !ATLAS_BANG! Folder'
        InModuleScope Atlas.Search { ConvertTo-AtlasIndexPath -Candidate $candidate } -Parameters @{ candidate = $drivePath } |
            Should -BeExactly ([IO.Path]::GetFullPath($drivePath))

        $uncPath = '\\server\share\Index %ATLAS_PERCENT% & !ATLAS_BANG! Folder'
        InModuleScope Atlas.Search { ConvertTo-AtlasIndexPath -Candidate $candidate } -Parameters @{ candidate = $uncPath } |
            Should -BeExactly ([IO.Path]::GetFullPath($uncPath))
    }

    It 'rejects relative, root-relative, incomplete UNC, and wildcard paths' {
        foreach ($candidate in @(
                '.\relative',
                '\root-relative',
                'C:drive-relative',
                '\\server-only',
                (Join-Path $TestDrive 'wild*card'),
                (Join-Path $TestDrive 'wild?card')
            )) {
            { InModuleScope Atlas.Search { ConvertTo-AtlasIndexPath -Candidate $candidate } -Parameters @{ candidate = $candidate } } |
                Should -Throw
        }
    }

    It 'writes policy URLs as REG_SZ value names and data without creating Gather-style children' {
        $includeRoot = 'HKCU:\Software\AtlasRewriteTest\Search\Paths'
        Set-AtlasIndexConfiguration -Operation Include -IndexPath 'C:\Wanted\..\Wanted\'
        $url = 'file:///C:\Wanted\'
        $entry = Get-Item -LiteralPath $includeRoot
        $entry.GetValueNames() | Should -Be @($url)
        $entry.GetValue($url) | Should -BeExactly $url
        $entry.GetValueKind($url) | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
        @(Get-ChildItem -LiteralPath $includeRoot).Count | Should -Be 0
    }

    It 'reuses a case-insensitive matching entry without allocating another key' {
        $excludeRoot = 'HKCU:\Software\AtlasRewriteTest\Search\Exclusions'
        Set-AtlasIndexConfiguration -Operation Exclude -IndexPath 'c:\wanted\'
        Set-AtlasIndexConfiguration -Operation Exclude -IndexPath 'C:\Wanted'
        $entry = Get-Item -LiteralPath $excludeRoot
        @($entry.GetValueNames()).Count | Should -Be 1
        $entry.GetValue('file:///C:\Wanted\*') | Should -BeExactly 'file:///C:\Wanted\*'
        @(Get-ChildItem -LiteralPath $excludeRoot).Count | Should -Be 0
    }

    It 'preserves literal characters and formats UNC exclusions' {
        $path = '\\server\share\Index %ATLAS_PERCENT% & !ATLAS_BANG! Folder'
        Set-AtlasIndexConfiguration -Operation Exclude -IndexPath $path
        $url = 'file://server\share\Index %ATLAS_PERCENT% & !ATLAS_BANG! Folder\*'
        $entry = Get-Item -LiteralPath 'HKCU:\Software\AtlasRewriteTest\Search\Exclusions'
        $entry.GetValue($url) | Should -BeExactly $url
    }

    It 'clears only policy lists, preserving Search-owned scope and policy caches' {
        $internalRoot = 'HKCU:\Software\AtlasRewriteTest\Search\Gather'
        $cacheRoot = 'HKCU:\Software\AtlasRewriteTest\Search\CurrentPolicies'
        foreach ($root in @($internalRoot, $cacheRoot)) {
            New-Item -Path "$root\Stale" -Force | Out-Null
            Set-ItemProperty -LiteralPath $root -Name Included -Value 1 -Type DWord
        }
        New-Item -Path 'HKCU:\Software\AtlasRewriteTest\Search\Paths\0' -Force | Out-Null

        Set-AtlasIndexConfiguration -Operation CleanPolicies

        foreach ($root in @(
                'HKCU:\Software\AtlasRewriteTest\Search\Paths'
                'HKCU:\Software\AtlasRewriteTest\Search\Exclusions'
            )) {
            Test-Path -LiteralPath $root | Should -BeTrue
            @(Get-ChildItem -Path $root).Count | Should -Be 0
            @((Get-Item -Path $root).GetValueNames()).Count | Should -Be 0
        }
        foreach ($root in @($internalRoot, $cacheRoot)) {
            Test-Path -LiteralPath "$root\Stale" | Should -BeTrue
            (Get-Item -LiteralPath $root).GetValue('Included') | Should -Be 1
        }
    }

    It 'stages presets under Atlas and cleans the two legacy RC policy lists' {
        @($script:savedRoots.Policies).Count | Should -Be 4
        $script:savedRoots.Paths.Include | Should -BeExactly 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\Search\IncludedPaths'
        $script:savedRoots.Paths.Exclude | Should -BeExactly 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\Search\ExcludedPaths'
    }

    It 'commits the complete staged preset and propagates effective-scope verification failure' {
        Set-AtlasIndexConfiguration -Operation Include -IndexPath 'C:\Windows\AtlasDesktop'
        Set-AtlasIndexConfiguration -Operation Exclude -IndexPath 'C:\Users'
        Mock Invoke-AtlasSearchScopeNative -ModuleName Atlas.Search { throw 'effective scope differs' }
        { InModuleScope Atlas.Search { Complete-AtlasIndexScope } } | Should -Throw '*effective scope differs*'
        Should -Invoke Invoke-AtlasSearchScopeNative -ModuleName Atlas.Search -Times 1 -Exactly -ParameterFilter {
            $Includes.Count -eq 1 -and $Includes[0] -ceq 'file:///C:\Windows\AtlasDesktop\' -and
            $Excludes.Count -eq 1 -and $Excludes[0] -ceq 'file:///C:\Users\*'
        }
    }

    It 'does not reset the current scope when there is no staged preset' {
        Mock Invoke-AtlasSearchScopeNative -ModuleName Atlas.Search { throw 'must not reset' }
        InModuleScope Atlas.Search { Complete-AtlasIndexScope }
        Should -Invoke Invoke-AtlasSearchScopeNative -ModuleName Atlas.Search -Times 0
    }

    It 'rejects corrupt staged rules before native scope changes' {
        $root = 'HKCU:\Software\AtlasRewriteTest\Search\Paths'
        New-Item -Path $root -Force | Out-Null
        Set-ItemProperty -LiteralPath $root -Name bad -Value 'relative-path' -Type String
        Mock Invoke-AtlasSearchScopeNative -ModuleName Atlas.Search { throw 'must not apply' }
        { InModuleScope Atlas.Search { Complete-AtlasIndexScope } } | Should -Throw '*Invalid staged*'
        Should -Invoke Invoke-AtlasSearchScopeNative -ModuleName Atlas.Search -Times 0
    }
}

Describe 'Set-AtlasIndexConfiguration' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Search
        Mock Test-AtlasAdmin -ModuleName Atlas.Search { $true }
        $global:AtlasSearchTestCalls = New-Object 'System.Collections.Generic.List[string]'
        Mock Get-AtlasIndexNativePaths -ModuleName Atlas.Search {
            [pscustomobject]@{
                GpUpdate = 'C:\Windows\System32\gpupdate.exe'
                Sc       = 'C:\Windows\System32\sc.exe'
            }
        }
    }

    It 'configures and moves WSearch to the requested runtime state' {
        $service = [pscustomobject]@{
            Status = [ServiceProcess.ServiceControllerStatus]::Stopped
        }
        $service | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
        $service | Add-Member -MemberType ScriptMethod -Name Start -Value {
            [void]$global:AtlasSearchTestCalls.Add('Start')
            $this.Status = [ServiceProcess.ServiceControllerStatus]::Running
        }
        $service | Add-Member -MemberType ScriptMethod -Name Stop -Value {
            [void]$global:AtlasSearchTestCalls.Add('Stop')
            $this.Status = [ServiceProcess.ServiceControllerStatus]::Stopped
        }
        $service | Add-Member -MemberType ScriptMethod -Name Continue -Value {
            [void]$global:AtlasSearchTestCalls.Add('Continue')
            $this.Status = [ServiceProcess.ServiceControllerStatus]::Running
        }
        $service | Add-Member -MemberType ScriptMethod -Name WaitForStatus -Value {
            param($RequestedStatus, $Timeout)
            [void]$Timeout
            [void]$global:AtlasSearchTestCalls.Add("Wait:$RequestedStatus")
            $this.Status = $RequestedStatus
        }
        $service | Add-Member -MemberType ScriptMethod -Name Dispose -Value {
            [void]$global:AtlasSearchTestCalls.Add('Dispose')
        }
        $global:AtlasSearchTestService = $service
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add("native:$($ArgumentList -join ',')")
        }
        Mock Get-Service -ModuleName Atlas.Search { $global:AtlasSearchTestService }

        InModuleScope Atlas.Search { Set-AtlasSearchServiceState -State Running }
        $global:AtlasSearchTestService.Status = [ServiceProcess.ServiceControllerStatus]::Running
        InModuleScope Atlas.Search { Set-AtlasSearchServiceState -State Stopped }

        @($global:AtlasSearchTestCalls) | Should -Be @(
            'native:config,WSearch,start=,delayed-auto'
            'Start'
            'Wait:Running'
            'Dispose'
            'native:config,WSearch,start=,disabled'
            'Stop'
            'Wait:Stopped'
            'Dispose'
        )
        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Search -Times 2 -Exactly `
            -ParameterFilter { $Wait -and $FilePath -eq 'C:\Windows\System32\sc.exe' }
    }

    It 'starts WSearch, commits and verifies the scope, then reveals settings' {
        Mock Set-AtlasSearchServiceState -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add("service:$State")
        }
        Mock Set-AtlasIndexSettingsVisibility -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add("hidden:$Hidden")
        }
        Mock Complete-AtlasIndexScope -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add('scope:verified')
        }
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add(
                "native:$([IO.Path]::GetFileName($FilePath)):$($ArgumentList -join ','):wait=$Wait"
            )
        }

        Set-AtlasIndexConfiguration -Operation Start

        @($global:AtlasSearchTestCalls) | Should -Be @(
            'service:Running'
            'scope:verified'
            'hidden:False'
        )
    }

    It 'hides settings before stopping WSearch' {
        Mock Set-AtlasIndexSettingsVisibility -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add("hidden:$Hidden")
        }
        Mock Set-AtlasSearchServiceState -ModuleName Atlas.Search {
            [void]$global:AtlasSearchTestCalls.Add("service:$State")
        }

        Set-AtlasIndexConfiguration -Operation Stop

        @($global:AtlasSearchTestCalls) | Should -Be @(
            'hidden:True'
            'service:Stopped'
        )
    }

    It 'writes the two supported DWORD settings with their product values' {
        Mock Set-AtlasIndexDword -ModuleName Atlas.Search {}

        Set-AtlasIndexConfiguration -Operation SetRespectPowerModes -SettingValue 1
        Set-AtlasIndexConfiguration -Operation ResetSetupCompleted

        Should -Invoke Set-AtlasIndexDword -ModuleName Atlas.Search -Times 1 -Exactly -ParameterFilter {
            $KeyPath -eq 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex' -and
            $Name -eq 'RespectPowerModes' -and $Value -eq 1
        }
        Should -Invoke Set-AtlasIndexDword -ModuleName Atlas.Search -Times 1 -Exactly -ParameterFilter {
            $KeyPath -eq 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search' -and
            $Name -eq 'SetupCompletedSuccessfully' -and $Value -eq 0
        }
    }

    It 'rejects operation-specific arguments before checking administrator rights' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Search { throw 'administrator check should not run' }

        { Set-AtlasIndexConfiguration -Operation Include } |
            Should -Throw '*requires a fully qualified index path*'
        { Set-AtlasIndexConfiguration -Operation Stop -IndexPath 'C:\Unexpected' } |
            Should -Throw '*does not accept an index path*'
        { Set-AtlasIndexConfiguration -Operation SetRespectPowerModes } |
            Should -Throw '*requires an explicit setting value*'
        { Set-AtlasIndexConfiguration -Operation Start -SettingValue 1 } |
            Should -Throw '*does not accept a setting value*'

        Should -Invoke Test-AtlasAdmin -ModuleName Atlas.Search -Times 0 -Exactly
    }

    It 'requires administrator rights before mutating anything' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Search { $false }
        Mock Set-AtlasIndexDword -ModuleName Atlas.Search { throw 'must not write' }

        { Set-AtlasIndexConfiguration -Operation ResetSetupCompleted } |
            Should -Throw '*Administrator privileges are required*'
        Should -Invoke Set-AtlasIndexDword -ModuleName Atlas.Search -Times 0
    }
}

Describe 'Set-AtlasIndexingMachineState' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Search
        $global:AtlasSearchTestCalls = New-Object 'System.Collections.Generic.List[object]'
        Mock Set-AtlasIndexConfiguration -ModuleName Atlas.Search {
            $global:AtlasSearchTestCalls.Add([pscustomobject]@{
                    Operation         = $Operation
                    IndexPath         = $IndexPath
                    SettingValue      = $SettingValue
                    SettingValueBound = $PesterBoundParameters.ContainsKey('SettingValue')
                })
        }
    }

    It 'stops indexing only for the Disable state' {
        Set-AtlasIndexingMachineState -State Disable

        @($global:AtlasSearchTestCalls.Operation) | Should -Be @('Stop')
    }

    It 'rejects RespectPowerModes outside the Full state' {
        { Set-AtlasIndexingMachineState -State Minimal -RespectPowerModes 1 } |
            Should -Throw '*does not accept RespectPowerModes*'
        $global:AtlasSearchTestCalls.Count | Should -Be 0
    }

    It 'preserves an independent power-mode preference when replaying full indexing' {
        Mock Get-ChildItem -ModuleName Atlas.Search { @() }
        Set-AtlasIndexingMachineState -State Full -PreservePowerModes
        @($global:AtlasSearchTestCalls.Operation) | Should -Contain 'Start'
        @($global:AtlasSearchTestCalls.Operation) | Should -Not -Contain 'SetRespectPowerModes'
    }

    It 'rejects contradictory power-mode requests before touching indexing' {
        { Set-AtlasIndexingMachineState -State Full -RespectPowerModes 0 -PreservePowerModes } | Should -Throw '*PreservePowerModes requires*'
        $global:AtlasSearchTestCalls.Count | Should -Be 0
    }

    It 'emits the minimal-indexing plan with forced power-mode respect' {
        Set-AtlasIndexingMachineState -State Minimal
        $operations = $global:AtlasSearchTestCalls.ToArray()
        $windows = [IO.Path]::GetFullPath([Environment]::GetFolderPath('Windows'))

        @($operations.Operation) | Should -Be @(
            'Stop',
            'CleanPolicies',
            'Include',
            'Include',
            'Exclude',
            'Start',
            'SetRespectPowerModes'
        )
        $operations[2].IndexPath | Should -BeExactly ([IO.Path]::Combine(
                [IO.Path]::GetFullPath([Environment]::GetFolderPath('CommonApplicationData')),
                'Microsoft', 'Windows', 'Start Menu', 'Programs'))
        $operations[3].IndexPath | Should -BeExactly ([IO.Path]::Combine($windows, 'AtlasDesktop'))
        $operations[4].IndexPath | Should -BeExactly ([IO.Path]::Combine([IO.Path]::GetPathRoot($windows), 'Users'))
        $operations[-1].SettingValueBound | Should -BeTrue
        $operations[-1].SettingValue | Should -Be 1
    }

    It 'emits the full-indexing plan, excludes each profile AppData and passes the requested power mode' {
        $usersRoot = Join-Path $TestDrive 'Users'
        New-Item -Path (Join-Path $usersRoot 'alice\AppData') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $usersRoot 'bob\MicrosoftEdgeBackups') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $usersRoot 'carol') -ItemType Directory -Force | Out-Null
        $global:AtlasSearchTestUsersRoot = $usersRoot
        Mock Get-ChildItem -ModuleName Atlas.Search -ParameterFilter { $Directory -and $LiteralPath -like '*\Users' } {
            [IO.DirectoryInfo[]]@(
                [IO.DirectoryInfo]::new((Join-Path $global:AtlasSearchTestUsersRoot 'alice'))
                [IO.DirectoryInfo]::new((Join-Path $global:AtlasSearchTestUsersRoot 'bob'))
                [IO.DirectoryInfo]::new((Join-Path $global:AtlasSearchTestUsersRoot 'carol'))
            )
        }

        Set-AtlasIndexingMachineState -State Full -RespectPowerModes 0
        $operations = $global:AtlasSearchTestCalls.ToArray()

        @($operations.Operation) | Should -Be @(
            'Stop',
            'CleanPolicies',
            'Include',
            'Include',
            'Include',
            'Exclude',
            'Exclude',
            'Start',
            'SetRespectPowerModes'
        )
        $operations[5].IndexPath | Should -BeExactly (Join-Path $usersRoot 'alice\AppData')
        $operations[6].IndexPath | Should -BeExactly (Join-Path $usersRoot 'bob\MicrosoftEdgeBackups')
        $operations[-1].SettingValueBound | Should -BeTrue
        $operations[-1].SettingValue | Should -Be 0
    }

    It 'stops at the first failed index operation' {
        Mock Set-AtlasIndexConfiguration -ModuleName Atlas.Search {
            $global:AtlasSearchTestCalls.Add([pscustomobject]@{ Operation = $Operation })
            if ($Operation -eq 'CleanPolicies') {
                throw 'policy reset failed'
            }
        }

        { Set-AtlasIndexingMachineState -State Minimal } | Should -Throw '*policy reset failed*'
        @($global:AtlasSearchTestCalls.Operation) | Should -Be @('Stop', 'CleanPolicies')
    }
}

Describe 'Disable-AtlasStoreSearchRecommendations' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Search
        Mock Invoke-AtlasHiddenProcess -ModuleName Atlas.Search {}
    }

    It 'creates the Store search database and denies Everyone access through icacls' {
        $localAppData = Join-Path $TestDrive 'Local'
        $expectedDb = Join-Path $localAppData 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db'

        Disable-AtlasStoreSearchRecommendations -LocalAppDataPath $localAppData

        Test-Path -LiteralPath $expectedDb -PathType Leaf | Should -BeTrue
        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Search -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq (Join-Path ([Environment]::SystemDirectory) 'icacls.exe') -and
            $Wait -and
            @($ArgumentList).Count -eq 3 -and
            $ArgumentList[0] -eq $expectedDb -and
            $ArgumentList[1] -eq '/deny' -and
            $ArgumentList[2] -eq '*S-1-1-0:F'
        }
    }

    It 'keeps an existing database file and still applies the deny rule' {
        $localAppData = Join-Path $TestDrive 'Local'
        $expectedDb = Join-Path $localAppData 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db'
        New-Item -Path (Split-Path $expectedDb -Parent) -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $expectedDb -Value 'existing' -Encoding ASCII

        Disable-AtlasStoreSearchRecommendations -LocalAppDataPath $localAppData

        (Get-Content -LiteralPath $expectedDb -Raw).Trim() | Should -BeExactly 'existing'
        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Search -Times 1 -Exactly
    }

    It 'fails without a local application-data directory' {
        { Disable-AtlasStoreSearchRecommendations -LocalAppDataPath '' } |
            Should -Throw '*LocalApplicationData is not available*'
        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Search -Times 0
    }
}

Describe 'Index configuration process contracts' {
    It 'returns a checked standalone failure from the compatibility entry script' {
        $hostPath = Join-Path $PSHOME 'powershell.exe'
        $savedErrorPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & $hostPath -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass `
                -File $script:entryPath -Operation SetRespectPowerModes 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $savedErrorPreference
        }

        $exitCode | Should -Be 1
        ($output | Out-String) | Should -Match 'requires an explicit setting value'
    }

    It 'rejects unsupported compatibility-launcher arguments with code 2' {
        $cmdPath = Join-Path ([Environment]::GetFolderPath('System')) 'cmd.exe'
        & $cmdPath /d /c "call `"$script:launcherPath`" /unsupported" *> $null
        $LASTEXITCODE | Should -Be 2

        & $cmdPath /d /c "call `"$script:launcherPath`" /include" *> $null
        $LASTEXITCODE | Should -Be 2
    }
}
