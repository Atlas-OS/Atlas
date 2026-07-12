BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:helperPath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-IndexConfiguration.ps1'
    $script:launcherPath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Set-IndexConfiguration.cmd'
    $script:machineStatePath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-AtlasIndexingMachineState.ps1'

    # Load the production functions through a harmless validation failure. The script has
    # no library/test mode: relative paths fail before the administrator or mutation paths.
    $loadFailure = $null
    try {
        . $script:helperPath -Operation Include -IndexPath '.\relative' -InProcess
    }
    catch {
        $loadFailure = $_
    }
    if ($null -eq $loadFailure -or
        $loadFailure.Exception.Message -notlike '*fully qualified*') {
        throw 'The IndexConfiguration test fixture did not stop at path validation.'
    }
}

Describe 'Index path behavior' {
    It 'preserves literal path data and accepts drive and UNC absolute paths' {
        $drivePath = Join-Path $TestDrive `
            'Index %ATLAS_PERCENT% & !ATLAS_BANG! Folder'
        ConvertTo-AtlasIndexPath -Candidate $drivePath |
            Should -BeExactly ([IO.Path]::GetFullPath($drivePath))

        $uncPath = '\\server\share\Index %ATLAS_PERCENT% & !ATLAS_BANG! Folder'
        ConvertTo-AtlasIndexPath -Candidate $uncPath |
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
            { ConvertTo-AtlasIndexPath -Candidate $candidate } | Should -Throw
        }
    }

    It 'creates the first free entry with the normalized path as REG_SZ' {
        Get-AtlasFirstFreeIndexEntryName -ExistingNames @() | Should -BeExactly '0'
        Get-AtlasFirstFreeIndexEntryName -ExistingNames @('0', '1', '3', 'custom') |
            Should -BeExactly '2'

        $existingEntry = [pscustomobject]@{
            PSChildName = '0'
            PSPath      = 'Registry::existing\0'
            StoredPath  = 'C:\Other'
        }
        $existingEntry | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
            param($Name, $DefaultValue, $Options)
            [void]$Name
            [void]$DefaultValue
            [void]$Options
            return $this.StoredPath
        }
        Mock Test-Path { $true }
        Mock Get-ChildItem { @($existingEntry) }
        Mock New-Item {}
        Mock Set-ItemProperty {}

        $result = Add-AtlasIndexPath -Mode Include -Path 'C:\Wanted'

        $result.EntryName | Should -BeExactly '1'
        $result.Existing | Should -BeFalse
        Should -Invoke New-Item -Times 1 -Exactly -ParameterFilter {
            $Path -like 'Registry::*\1'
        }
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -like 'Registry::*\1' -and
            $Name -eq 'Path' -and
            $Value -eq 'C:\Wanted' -and
            $Type -eq 'String'
        }
    }

    It 'reuses a case-insensitive matching entry without allocating another key' {
        $existingEntry = [pscustomobject]@{
            PSChildName = '4'
            PSPath      = 'Registry::existing\4'
            StoredPath  = 'c:\wanted'
        }
        $existingEntry | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
            param($Name, $DefaultValue, $Options)
            [void]$Name
            [void]$DefaultValue
            [void]$Options
            return $this.StoredPath
        }
        Mock Test-Path { $true }
        Mock Get-ChildItem { @($existingEntry) }
        Mock New-Item {}
        Mock Set-ItemProperty {}

        $result = Add-AtlasIndexPath -Mode Exclude -Path 'C:\Wanted'

        $result.EntryName | Should -BeExactly '4'
        $result.Existing | Should -BeTrue
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'Registry::existing\4' -and
            $Value -eq 'C:\Wanted' -and
            $Type -eq 'String'
        }
    }
}

Describe 'Index operation behavior' {
    BeforeEach {
        Mock Test-AtlasAdmin { $true }
    }

    It 'recreates every Windows Search policy and path root' {
        Mock Test-Path { $true }
        Mock Remove-Item {}
        Mock New-Item {}

        Clear-AtlasIndexPolicyRoots

        Should -Invoke Remove-Item -Times 6 -Exactly
        Should -Invoke New-Item -Times 6 -Exactly
    }

    It 'configures and moves WSearch to the requested runtime state' {
        $script:serviceCalls = [Collections.Generic.List[string]]::new()
        $script:nativeCalls = [Collections.Generic.List[string]]::new()
        $service = [pscustomobject]@{
            Status = [ServiceProcess.ServiceControllerStatus]::Stopped
        }
        $service | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
        $service | Add-Member -MemberType ScriptMethod -Name Start -Value {
            [void]$script:serviceCalls.Add('Start')
            $this.Status = [ServiceProcess.ServiceControllerStatus]::Running
        }
        $service | Add-Member -MemberType ScriptMethod -Name Stop -Value {
            [void]$script:serviceCalls.Add('Stop')
            $this.Status = [ServiceProcess.ServiceControllerStatus]::Stopped
        }
        $service | Add-Member -MemberType ScriptMethod -Name Continue -Value {
            [void]$script:serviceCalls.Add('Continue')
            $this.Status = [ServiceProcess.ServiceControllerStatus]::Running
        }
        $service | Add-Member -MemberType ScriptMethod -Name WaitForStatus -Value {
            param($RequestedStatus, $Timeout)
            [void]$Timeout
            [void]$script:serviceCalls.Add("Wait:$RequestedStatus")
            $this.Status = $RequestedStatus
        }
        $service | Add-Member -MemberType ScriptMethod -Name Dispose -Value {
            [void]$script:serviceCalls.Add('Dispose')
        }

        Mock Get-AtlasIndexNativePaths {
            [pscustomobject]@{
                GpUpdate = 'C:\Windows\System32\gpupdate.exe'
                Sc       = 'C:\Windows\System32\sc.exe'
            }
        }
        Mock Invoke-AtlasHiddenProcess {
            [void]$script:nativeCalls.Add(($ArgumentList -join ','))
        }
        Mock Get-Service { $service }

        Set-AtlasSearchServiceState -State Running
        $service.Status = [ServiceProcess.ServiceControllerStatus]::Running
        Set-AtlasSearchServiceState -State Stopped

        @($script:nativeCalls) | Should -Be @(
            'config,WSearch,start=,delayed-auto'
            'config,WSearch,start=,disabled'
        )
        @($script:serviceCalls) | Should -Be @(
            'Start'
            'Wait:Running'
            'Dispose'
            'Stop'
            'Wait:Stopped'
            'Dispose'
        )
        Should -Invoke Invoke-AtlasHiddenProcess -Times 2 -Exactly `
            -ParameterFilter { $Wait }
    }

    It 'starts WSearch, reveals settings, and performs a checked computer policy refresh' {
        $script:indexSequence = [Collections.Generic.List[string]]::new()
        Mock Set-AtlasSearchServiceState {
            [void]$script:indexSequence.Add("service:$State")
        }
        Mock Set-AtlasIndexSettingsVisibility {
            [void]$script:indexSequence.Add("hidden:$Hidden")
        }
        Mock Get-AtlasIndexNativePaths {
            [pscustomobject]@{
                GpUpdate = 'C:\Windows\System32\gpupdate.exe'
                Sc       = 'C:\Windows\System32\sc.exe'
            }
        }
        Mock Invoke-AtlasHiddenProcess {
            [void]$script:indexSequence.Add(
                "native:$([IO.Path]::GetFileName($FilePath)):$($ArgumentList -join ','):wait=$Wait"
            )
        }

        Invoke-AtlasIndexConfiguration -RequestedOperation Start `
            -SettingValueWasBound $false

        @($script:indexSequence) | Should -Be @(
            'service:Running'
            'hidden:False'
            'native:gpupdate.exe:/target:computer,/force,/wait:600:wait=True'
        )
    }

    It 'hides settings before stopping WSearch' {
        $script:indexSequence = [Collections.Generic.List[string]]::new()
        Mock Set-AtlasIndexSettingsVisibility {
            [void]$script:indexSequence.Add("hidden:$Hidden")
        }
        Mock Set-AtlasSearchServiceState {
            [void]$script:indexSequence.Add("service:$State")
        }

        Invoke-AtlasIndexConfiguration -RequestedOperation Stop `
            -SettingValueWasBound $false

        @($script:indexSequence) | Should -Be @(
            'hidden:True'
            'service:Stopped'
        )
    }

    It 'writes the two supported DWORD settings with their product values' {
        Mock Set-AtlasIndexDword {}

        Invoke-AtlasIndexConfiguration -RequestedOperation SetRespectPowerModes `
            -RequestedSettingValue 1 -SettingValueWasBound $true
        Invoke-AtlasIndexConfiguration -RequestedOperation ResetSetupCompleted `
            -SettingValueWasBound $false

        Should -Invoke Set-AtlasIndexDword -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'RespectPowerModes' -and $Value -eq 1
        }
        Should -Invoke Set-AtlasIndexDword -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'SetupCompletedSuccessfully' -and $Value -eq 0
        }
    }

    It 'rejects operation-specific arguments before requesting elevation' {
        Mock Test-AtlasAdmin { throw 'administrator check should not run' }

        {
            Invoke-AtlasIndexConfiguration -RequestedOperation Include `
                -SettingValueWasBound $false
        } | Should -Throw '*requires a fully qualified index path*'
        {
            Invoke-AtlasIndexConfiguration -RequestedOperation Stop `
                -RequestedPath 'C:\Unexpected' -SettingValueWasBound $false
        } | Should -Throw '*does not accept an index path*'
        {
            Invoke-AtlasIndexConfiguration -RequestedOperation SetRespectPowerModes `
                -SettingValueWasBound $false
        } | Should -Throw '*requires an explicit setting value*'
        {
            Invoke-AtlasIndexConfiguration -RequestedOperation Start `
                -RequestedSettingValue 1 -SettingValueWasBound $true
        } | Should -Throw '*does not accept a setting value*'

        Should -Invoke Test-AtlasAdmin -Times 0 -Exactly
    }
}

Describe 'Index configuration process contracts' {
    It 'throws in-process and returns a checked standalone failure' {
        {
            & $script:helperPath -Operation Include `
                -IndexPath '.\relative' -InProcess
        } | Should -Throw '*fully qualified*'
        $PID | Should -BeGreaterThan 0

        $hostPath = if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Join-Path $PSHOME 'powershell.exe'
        }
        else {
            Join-Path $PSHOME 'pwsh.exe'
        }

        $savedErrorPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & $hostPath -NoProfile -NoLogo -NonInteractive `
                -File $script:helperPath -Operation SetRespectPowerModes 2>&1
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

Describe 'Indexing product state plans' {
    BeforeEach {
        $script:machineTestRoot = Join-Path $TestDrive 'Internal'
        New-Item -Path $script:machineTestRoot -ItemType Directory -Force | Out-Null
        $script:machineTestScript = Join-Path $script:machineTestRoot `
            'Set-AtlasIndexingMachineState.ps1'
        Copy-Item -LiteralPath $script:machineStatePath `
            -Destination $script:machineTestScript
        $script:operationLog = Join-Path $TestDrive 'operations.jsonl'
        Remove-Item -LiteralPath $script:operationLog `
            -Force -ErrorAction SilentlyContinue
        $env:ATLAS_INDEX_TEST_LOG = $script:operationLog

        @'
param(
    [string]$Operation,
    [string]$IndexPath,
    [int]$SettingValue,
    [switch]$InProcess
)
[pscustomobject]@{
    Operation         = $Operation
    IndexPath         = $IndexPath
    SettingValue      = $SettingValue
    SettingValueBound = $PSBoundParameters.ContainsKey('SettingValue')
    InProcess         = [bool]$InProcess
} | ConvertTo-Json -Compress | Add-Content -LiteralPath $env:ATLAS_INDEX_TEST_LOG
'@ | Set-Content -LiteralPath (Join-Path $script:machineTestRoot `
                'Set-IndexConfiguration.ps1') -Encoding UTF8
    }

    AfterEach {
        Remove-Item Env:ATLAS_INDEX_TEST_LOG -ErrorAction SilentlyContinue
    }

    It 'emits the unchanged minimal-indexing plan' {
        & $script:machineTestScript -State Minimal
        $operations = @(Get-Content -LiteralPath $script:operationLog |
                ForEach-Object { $_ | ConvertFrom-Json })

        @($operations.Operation) | Should -Be @(
            'Stop',
            'CleanPolicies',
            'Include',
            'Include',
            'Exclude',
            'Start',
            'ResetSetupCompleted',
            'SetRespectPowerModes'
        )
        $operations[-1].SettingValueBound | Should -BeTrue
        $operations[-1].SettingValue | Should -Be 1
        @($operations | Where-Object { -not $_.InProcess }).Count | Should -Be 0
    }

    It 'emits the unchanged full-indexing plan and requested power mode' {
        & $script:machineTestScript -State Full -RespectPowerModes 1
        $operations = @(Get-Content -LiteralPath $script:operationLog |
                ForEach-Object { $_ | ConvertFrom-Json })

        @($operations[0..4].Operation) | Should -Be @(
            'Stop',
            'CleanPolicies',
            'Include',
            'Include',
            'Include'
        )
        @($operations[-3..-1].Operation) | Should -Be @(
            'Start',
            'ResetSetupCompleted',
            'SetRespectPowerModes'
        )
        $operations[-1].SettingValueBound | Should -BeTrue
        $operations[-1].SettingValue | Should -Be 1
    }
}
