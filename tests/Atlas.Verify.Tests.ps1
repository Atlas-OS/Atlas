BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = $script:AtlasTestModulesRoot
    foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Services', 'Atlas.TasksProcs', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath "$module\$module.psd1") -Force
    }

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest\Verify'
    $script:testRootPath = 'HKCU\Software\AtlasRewriteTest\Verify'
    New-Item -Path $script:testRoot -Force | Out-Null

    function New-TestContextMock {
        param([bool]$IsArm64 = $false, [int]$WindowsBuild = 26100)
        [pscustomobject]@{
            WinDir               = 'C:\Windows'
            AtlasModulesPath     = 'C:\Windows\AtlasModules'
            IsArm64              = $IsArm64
            WindowsBuild         = $WindowsBuild
            IsUpgrade            = $false
            IsOobe               = $false
            IsInstallStateBacked = $true
            Options              = @()
        }
    }
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Test-AtlasRegistryEntries' {
    BeforeEach {
        Remove-Item -Path "$script:testRoot\Reg" -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path "$script:testRoot\Reg" -Force | Out-Null
        New-ItemProperty -Path "$script:testRoot\Reg" -Name 'Number' -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path "$script:testRoot\Reg" -Name 'Text' -Value 'atlas' -PropertyType String -Force | Out-Null
    }

    It 'reports nothing when every declaration holds' {
        $entries = @(
            @{ Path = "$script:testRootPath\Reg"; Name = 'Number'; Type = 'DWord'; Data = 1 }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Text'; Type = 'String'; Data = 'atlas' }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Gone'; Operation = 'Delete' }
            @{ Path = "$script:testRootPath\Reg"; Operation = 'AddKey' }
            @{ Path = "$script:testRootPath\Missing"; Operation = 'DeleteKey' }
        )
        @(Test-AtlasRegistryEntries -Entries $entries -IsArm64 $false).Count | Should -Be 0
    }

    It 'reports a missing value, differing data and a wrong kind with distinct reasons' {
        $entries = @(
            @{ Path = "$script:testRootPath\Reg"; Name = 'Absent'; Type = 'DWord'; Data = 1 }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Number'; Type = 'DWord'; Data = 2 }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Text'; Type = 'DWord'; Data = 1 }
        )
        $drift = @(Test-AtlasRegistryEntries -Entries $entries -IsArm64 $false)
        $drift.Count | Should -Be 3
        ($drift | Where-Object Name -eq 'Absent').Reason | Should -Be 'value is missing'
        ($drift | Where-Object Name -eq 'Number').Reason | Should -Be 'value data differs'
        ($drift | Where-Object Name -eq 'Text').Reason | Should -Match 'value kind is String'
    }

    It 'reports lingering values and keys for Delete, DeleteKey and AddKey' {
        $entries = @(
            @{ Path = "$script:testRootPath\Reg"; Name = 'Number'; Operation = 'Delete' }
            @{ Path = "$script:testRootPath\Reg"; Operation = 'DeleteKey' }
            @{ Path = "$script:testRootPath\Missing"; Operation = 'AddKey' }
        )
        $drift = @(Test-AtlasRegistryEntries -Entries $entries -IsArm64 $false)
        @($drift.Reason) | Should -Be @('value still exists', 'key still exists', 'key is missing')
    }

    It 'honours the scope and architecture filters' {
        $entries = @(
            @{ Path = 'HKLM\SOFTWARE\AtlasRewriteTest\NeverCreated'; Name = 'X'; Type = 'DWord'; Data = 1 }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Absent'; Type = 'DWord'; Data = 1; Arch = 'ARM64' }
        )
        @(Test-AtlasRegistryEntries -Entries $entries -Scope CurrentUser -IsArm64 $false).Count | Should -Be 0
        @(Test-AtlasRegistryEntries -Entries $entries -Scope CurrentUser -IsArm64 $true).Count | Should -Be 1
    }

    It 'applies transient entries but skips their verification while retaining neighbouring drift' {
        $entries = @(
            @{ Path = "$script:testRootPath\Reg"; Name = 'Initial'; Type = 'DWord'; Data = 7; SkipVerification = 'Windows owns the subsequent value.' }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Durable'; Type = 'DWord'; Data = 1 }
        )
        Invoke-AtlasRegistryEntries -Entries $entries -IsArm64 $false
        (Get-ItemProperty -Path "$script:testRoot\Reg" -Name Initial).Initial | Should -Be 7
        Set-ItemProperty -Path "$script:testRoot\Reg" -Name Initial -Value 8
        Set-ItemProperty -Path "$script:testRoot\Reg" -Name Durable -Value 2
        $drift = @(Test-AtlasRegistryEntries -Entries $entries -IsArm64 $false)
        @($drift.Name) | Should -Be @('Durable')
    }

    It 'requires a reason to exclude verification' -TestCases @(
        @{ Reason = $true }; @{ Reason = '' }; @{ Reason = ' ' }
    ) {
        param($Reason)
        $entry = @{ Path = "$script:testRootPath\Reg"; Operation = 'DeleteKey'; SkipVerification = $Reason }
        { Test-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false } | Should -Throw '*non-empty reason string*'
    }

    It 'still reports refused OS-protected values as drift' {
        $entry = @{ Path = "$script:testRootPath\Reg"; Name = 'Absent'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
        @(Test-AtlasRegistryEntries -Entries @($entry) -IsArm64 $false).Reason | Should -Be 'value is missing'
    }

    It 'compares binary and multi-string data element by element' {
        New-ItemProperty -Path "$script:testRoot\Reg" -Name 'Bytes' -Value ([byte[]](1, 2)) -PropertyType Binary -Force | Out-Null
        New-ItemProperty -Path "$script:testRoot\Reg" -Name 'Lines' -Value ([string[]]('a', 'b')) -PropertyType MultiString -Force | Out-Null
        $entries = @(
            @{ Path = "$script:testRootPath\Reg"; Name = 'Bytes'; Type = 'Binary'; Data = [byte[]](1, 2) }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Lines'; Type = 'MultiString'; Data = @('a', 'b') }
            @{ Path = "$script:testRootPath\Reg"; Name = 'Lines'; Type = 'MultiString'; Data = @('a') }
        )
        @(Test-AtlasRegistryEntries -Entries $entries -IsArm64 $false).Count | Should -Be 1
    }
}

Describe 'Test-AtlasServiceEntries' {
    BeforeAll {
        $script:servicesRoot = "$script:testRoot\Services"
        New-Item -Path "$script:servicesRoot\Present" -Force | Out-Null
        New-ItemProperty -Path "$script:servicesRoot\Present" -Name 'Start' -Value 4 -PropertyType DWord -Force | Out-Null
    }

    It 'reports only Change entries whose Start value differs' {
        $entries = @(
            @{ Name = 'Present'; StartupType = 4 }
            @{ Name = 'Present'; StartupType = 2 }
            @{ Name = 'Present'; Operation = 'Stop' }
        )
        $drift = @(Test-AtlasServiceEntries -Entries $entries -ServicesRoot $script:servicesRoot)
        $drift.Count | Should -Be 1
        $drift[0].Expected | Should -Be 2
        $drift[0].Actual | Should -Be 4
    }

    It 'treats a missing service as drift unless AllowMissing is declared' {
        @(Test-AtlasServiceEntries -Entries @(@{ Name = 'Nope'; StartupType = 4 }) -ServicesRoot $script:servicesRoot).Reason | Should -Be 'service is missing'
        @(Test-AtlasServiceEntries -Entries @(@{ Name = 'Nope'; StartupType = 4; AllowMissing = $true }) -ServicesRoot $script:servicesRoot).Count | Should -Be 0
    }
}

Describe 'Test-AtlasScheduledTaskEntries' {
    It 'reports present tasks in the wrong state and tolerates missing ones' {
        Mock -ModuleName Atlas.TasksProcs Get-AtlasScheduledTaskState {
            switch ($Path) {
                '\Atlas\Enabled' { 'Enabled' }
                '\Atlas\Disabled' { 'Disabled' }
                default { 'Missing' }
            }
        }
        $entries = @(
            @{ Path = '\Atlas\Enabled' }
            @{ Path = '\Atlas\Disabled' }
            @{ Path = '\Atlas\Disabled'; Operation = 'Enable' }
            @{ Path = '\Atlas\Nowhere' }
        )
        $drift = @(Test-AtlasScheduledTaskEntries -Entries $entries)
        @($drift.Task) | Should -Be @('\Atlas\Enabled', '\Atlas\Disabled')
        @($drift.Expected) | Should -Be @('Disabled', 'Enabled')
    }

    It 'reads the enabled property without localized status text' -ForEach @(
        @{ Enabled = $true; Expected = 'Enabled' }
        @{ Enabled = $false; Expected = 'Disabled' }
    ) {
        Mock -ModuleName Atlas.TasksProcs Get-AtlasTaskSchedulerService {
            $scheduler = [pscustomobject]@{ Enabled = $Enabled }
            $scheduler | Add-Member ScriptMethod GetFolder { param($Path) $Path | Should -BeExactly '\'; return $this }
            $scheduler | Add-Member ScriptMethod GetTask { param($Path) $Path | Should -BeExactly '\Atlas\Task'; return $this }
            return $scheduler
        }
        InModuleScope Atlas.TasksProcs { Get-AtlasScheduledTaskState -Path '\Atlas\Task' } | Should -Be $Expected
    }

    It 'tolerates only missing-task HRESULTs and propagates permission and RPC failures' -ForEach @(
        @{ Code = -2147024894; Missing = $true }
        @{ Code = -2147024893; Missing = $true }
        @{ Code = -2147024891; Missing = $false }
        @{ Code = -2147023174; Missing = $false }
    ) {
        Mock -ModuleName Atlas.TasksProcs Get-AtlasTaskSchedulerService {
            $scheduler = [pscustomobject]@{ FailureCode = $Code }
            $scheduler | Add-Member ScriptMethod GetFolder { param($Path) $Path | Should -BeExactly '\'; return $this }
            $scheduler | Add-Member ScriptMethod GetTask {
                param($Path)
                $Path | Should -BeExactly '\Atlas\Task'
                throw [Runtime.InteropServices.COMException]::new('Task lookup failed', $this.FailureCode)
            }
            return $scheduler
        }
        if ($Missing) {
            InModuleScope Atlas.TasksProcs { Get-AtlasScheduledTaskState -Path '\Atlas\Task' } | Should -Be 'Missing'
        }
        else {
            { InModuleScope Atlas.TasksProcs { Get-AtlasScheduledTaskState -Path '\Atlas\Task' } } | Should -Throw '*Task lookup failed*'
        }
    }
}

Describe 'Toggle verification' {
    BeforeAll {
        $script:togglesRoot = Join-Path $TestDrive 'Toggles'
        $script:stateRoot = "$script:testRoot\ToggleState"
        New-Item -Path (Join-Path $script:togglesRoot 'Group') -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:togglesRoot 'Group\Verified.psd1'), @"
@{
    Name = 'Verified'
    Description = 'Verification fixture.'
    Elevation = 'Admin'
    States = @(
        @{
            Name = 'Enable'
            StateValue = 1
            Launcher = 'Group\Enable.cmd'
            Registry = @(
                @{ Path = '$script:testRootPath\Toggle'; Name = 'Machine'; Type = 'DWord'; Data = 1 }
            )
            Services = @(
                @{ Name = 'Present'; StartupType = 4 }
            )
        }
        @{
            Name = 'Disable'
            StateValue = 0
            Launcher = 'Group\Disable.cmd'
            Registry = @(
                @{ Path = '$script:testRootPath\Toggle'; Name = 'Machine'; Type = 'DWord'; Data = 0 }
            )
        }
    )
}
"@, [Text.UTF8Encoding]::new($false))
        New-Item -Path "$script:testRoot\Toggle" -Force | Out-Null
        New-ItemProperty -Path "$script:testRoot\Toggle" -Name 'Machine' -Value 1 -PropertyType DWord -Force | Out-Null
        $script:definition = Get-AtlasToggleDefinition -Name 'Verified' -TogglesRoot $script:togglesRoot
    }

    It 'reports nothing for a state that holds and drift for the other state' {
        # HKCU paths are user scope, so verify the user scope of the fixture.
        @(Test-AtlasToggleState -Definition $script:definition -StateName 'Enable' -Scope User).Count | Should -Be 0
        $drift = @(Test-AtlasToggleState -Definition $script:definition -StateName 'Disable' -Scope User)
        $drift.Count | Should -Be 1
        $drift[0].Toggle | Should -Be 'Verified'
        $drift[0].Kind | Should -Be 'Registry'
        $drift[0].Reason | Should -Be 'value data differs'
    }

    It 'checks services only in machine scope' {
        Mock -ModuleName Atlas.Toggles Test-AtlasServiceEntries { @([pscustomobject]@{ Service = 'Present'; Expected = 4; Actual = 2; Reason = 'startup type differs' }) }
        @(Test-AtlasToggleState -Definition $script:definition -StateName 'Enable' -Scope User).Count | Should -Be 0
        $drift = @(Test-AtlasToggleState -Definition $script:definition -StateName 'Enable' -Scope Machine)
        @($drift.Kind) | Should -Contain 'Service'
    }

    It 'rejects an unknown state name' {
        { Test-AtlasToggleState -Definition $script:definition -StateName 'Nope' -Scope Machine } | Should -Throw '*does not define state*'
    }

    It 'verifies every recorded state and flags records without a definition' {
        Set-AtlasToggleState -Name 'Verified' -State 0 -StateRoot $script:stateRoot
        Set-AtlasToggleState -Name 'Orphan' -State 1 -StateRoot $script:stateRoot
        $drift = @(Test-AtlasToggleDrift -Scope User -StateRoot $script:stateRoot -TogglesRoot $script:togglesRoot)
        ($drift | Where-Object Toggle -eq 'Verified').Reason | Should -Be 'value data differs'
        ($drift | Where-Object Toggle -eq 'Orphan').Kind | Should -Be 'Definition'

        Set-AtlasToggleState -Name 'Verified' -State 1 -StateRoot $script:stateRoot
        $drift = @(Test-AtlasToggleDrift -Scope User -StateRoot $script:stateRoot -TogglesRoot $script:togglesRoot)
        @($drift.Toggle) | Should -Be @('Orphan')
    }

    It 'flags a recorded value that matches no state' {
        Remove-Item -Path "$script:stateRoot\Orphan" -Recurse -Force
        Set-AtlasToggleState -Name 'Verified' -State 9 -StateRoot $script:stateRoot
        $drift = @(Test-AtlasToggleDrift -Scope User -StateRoot $script:stateRoot -TogglesRoot $script:togglesRoot)
        $drift.Count | Should -Be 1
        $drift[0].Reason | Should -Match 'matches no installed state'
    }

    It 'reports nothing when nothing is recorded' {
        @(Test-AtlasToggleDrift -StateRoot "$script:testRoot\EmptyState" -TogglesRoot $script:togglesRoot).Count | Should -Be 0
    }
}

Describe 'Tweak verification' {
    BeforeAll {
        $script:tweaksRoot = Join-Path $TestDrive 'Tweaks'
        New-Item -Path (Join-Path $script:tweaksRoot 'Cat') -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:tweaksRoot 'tweaks.manifest.psd1'), @"
@{
    Categories = @(
        @{ Name = 'Cat'; Description = 'Fixture'; Tweaks = @('holds', 'drifts', 'arm-only') }
    )
}
"@, [Text.UTF8Encoding]::new($false))
        $tweaks = @{
            'holds'    = "@{ Name = 'holds'; Description = 'x'; Registry = @(@{ Path = '$script:testRootPath\Tweak'; Name = 'Value'; Type = 'DWord'; Data = 5 }) }"
            'drifts'   = "@{ Name = 'drifts'; Description = 'x'; Registry = @(@{ Path = '$script:testRootPath\Tweak'; Name = 'Value'; Type = 'DWord'; Data = 6 }); Services = @(@{ Name = 'Present'; StartupType = 4 }) }"
            'arm-only' = "@{ Name = 'arm-only'; Description = 'x'; Arch = 'ARM64'; Registry = @(@{ Path = '$script:testRootPath\Tweak'; Name = 'Missing'; Type = 'DWord'; Data = 1 }) }"
        }
        foreach ($name in $tweaks.Keys) {
            [IO.File]::WriteAllText((Join-Path $script:tweaksRoot "Cat\$name.psd1"), $tweaks[$name], [Text.UTF8Encoding]::new($false))
        }
        New-Item -Path "$script:testRoot\Tweak" -Force | Out-Null
        New-ItemProperty -Path "$script:testRoot\Tweak" -Name 'Value' -Value 5 -PropertyType DWord -Force | Out-Null
        Mock -ModuleName Atlas.Tweaks Test-AtlasServiceEntries { @() }
    }

    It 'verifies one tweak for the current-user scope' {
        $context = New-TestContextMock
        @(Test-AtlasTweak -Path (Join-Path $script:tweaksRoot 'Cat\holds.psd1') -RegistryScope CurrentUser -Context $context).Count | Should -Be 0
        $drift = @(Test-AtlasTweak -Path (Join-Path $script:tweaksRoot 'Cat\drifts.psd1') -RegistryScope CurrentUser -Context $context)
        $drift.Count | Should -Be 1
        $drift[0].Tweak | Should -Be 'drifts'
        $drift[0].Target | Should -Be "$script:testRootPath\Tweak\Value"
    }

    It 'skips tweaks that do not apply to the context' {
        @(Test-AtlasTweak -Path (Join-Path $script:tweaksRoot 'Cat\arm-only.psd1') -RegistryScope CurrentUser -Context (New-TestContextMock)).Count | Should -Be 0
        @(Test-AtlasTweak -Path (Join-Path $script:tweaksRoot 'Cat\arm-only.psd1') -RegistryScope CurrentUser -Context (New-TestContextMock -IsArm64 $true)).Reason | Should -Be 'value is missing'
    }

    It 'checks services only in machine scope' {
        Mock -ModuleName Atlas.Tweaks Test-AtlasServiceEntries { @([pscustomobject]@{ Service = 'Present'; Expected = 4; Actual = 2; Reason = 'startup type differs' }) }
        $drift = @(Test-AtlasTweak -Path (Join-Path $script:tweaksRoot 'Cat\drifts.psd1') -RegistryScope Machine -Context (New-TestContextMock))
        @($drift.Kind) | Should -Be @('Service')
        Should -Invoke -ModuleName Atlas.Tweaks Test-AtlasServiceEntries -Times 1 -Exactly
    }

    It 'walks a manifest category and rejects unknown ones' {
        $drift = @(Test-AtlasTweakCategory -Name 'Cat' -TweaksRoot $script:tweaksRoot -RegistryScope CurrentUser -Context (New-TestContextMock))
        @($drift.Tweak) | Should -Be @('drifts')
        { Test-AtlasTweakCategory -Name 'Nope' -TweaksRoot $script:tweaksRoot -Context (New-TestContextMock) } | Should -Throw '*not defined*'
    }

    It 'rejects a missing tweak file' {
        { Test-AtlasTweak -Path (Join-Path $script:tweaksRoot 'Cat\none.psd1') -Context (New-TestContextMock) } | Should -Throw '*not found*'
    }
}

Describe 'Test-AtlasHealth entry script' {
    BeforeAll {
        $script:healthScript = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Scripts\Entry\Test-AtlasHealth.ps1'
    }

    It 'parses and documents its exit codes' {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script:healthScript, [ref]$tokens, [ref]$errors) | Out-Null
        @($errors).Count | Should -Be 0
        (Get-Content -LiteralPath $script:healthScript -Raw) | Should -Match 'Exit codes: 0 no drift, 1 drift found, 2'
    }

    It 'ships as an AtlasDesktop launcher that records no state' {
        $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
        $definition = Get-AtlasToggleDefinition -Name 'AtlasHealth' -TogglesRoot $togglesRoot
        $definition['NoStateRecord'] | Should -BeTrue
        $definition['Elevation'] | Should -Be 'Admin'
        @(Test-AtlasToggleDefinition -Path (Join-Path $togglesRoot 'Troubleshooting\AtlasHealth.psd1')).Count | Should -Be 0
        Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasDesktop\9. Troubleshooting\Check Atlas Health.cmd' | Should -Exist
    }
}
