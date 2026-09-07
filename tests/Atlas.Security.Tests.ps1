BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Security\Atlas.Security.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:deviceGuardPath = "$script:testRoot\DeviceGuard"
    $script:hvciPath = "$script:deviceGuardPath\Scenarios\HypervisorEnforcedCodeIntegrity"
    $script:policyPath = "$script:testRoot\Policies\DeviceGuard"

    $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    $script:VbsState = Get-AtlasToggleDefinition -Name VbsState -TogglesRoot $togglesRoot
    $script:ConfigVbs = Get-AtlasToggleDefinition -Name ConfigVBS -TogglesRoot $togglesRoot
    $script:ToggleDefender = Get-AtlasToggleDefinition -Name ToggleDefender -TogglesRoot $togglesRoot
    $script:FixErrors = Get-AtlasToggleDefinition -Name FixErrors2502and2503 -TogglesRoot $togglesRoot
    $script:TweakPath = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\scripts\disable-core-isolation.psd1'

    function Set-TestDword {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $true)][int]$Value
        )

        New-Item -Path $Path -Force | Out-Null
        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type DWord
    }

    function Get-TestValueState {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            return $null
        }
        $key = Get-Item -LiteralPath $Path
        if (@($key.GetValueNames()) -notcontains $Name) {
            return $null
        }
        return [pscustomobject]@{
            Kind  = $key.GetValueKind($Name)
            Value = $key.GetValue($Name)
        }
    }

    function New-ToggleContext {
        param(
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $true)][string]$State,
            [bool]$Silent = $true
        )

        return [pscustomobject]@{
            Name           = $Name
            State          = $State
            StateValue     = $null
            Silent         = $Silent
            OperationsPath = Join-Path $TestDrive 'Operations'
        }
    }

    # Runs one companion function exactly as the engine does (dot-sourced into the
    # module scope under strict mode), so module-scoped mocks apply to it.
    function Invoke-CompanionFunction {
        param(
            [Parameter(Mandatory = $true)]$Definition,
            [Parameter(Mandatory = $true)][string]$FunctionName,
            [Parameter(Mandatory = $true)]$Toggle
        )

        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleFunction -Definition $d -FunctionName $f -Toggle $t -Label 'test'
        } -Parameters @{ d = $Definition; f = $FunctionName; t = $Toggle }
    }
}

AfterAll {
    Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Set-AtlasVbsConfiguration' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Security
        Mock Write-AtlasSuccess -ModuleName Atlas.Security
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Security
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:testRoot -Force | Out-Null
    }

    AfterEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'disables by writing only the two documented runtime values' {
        Set-AtlasVbsConfiguration -State Disable `
            -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath

        $enabled = Get-TestValueState -Path $script:hvciPath -Name 'Enabled'
        $enabled.Kind | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
        $enabled.Value | Should -Be 0
        $vbs = Get-TestValueState -Path $script:deviceGuardPath -Name 'EnableVirtualizationBasedSecurity'
        $vbs.Kind | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
        $vbs.Value | Should -Be 0
        @((Get-Item -LiteralPath $script:deviceGuardPath).GetValueNames()) |
            Should -Be @('EnableVirtualizationBasedSecurity')
        @((Get-Item -LiteralPath $script:hvciPath).GetValueNames()) | Should -Be @('Enabled')
        Should -Invoke Assert-AtlasPrivilege -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter { $Administrator }
        Should -Invoke Write-AtlasSuccess -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Text -like '*configured to disable*'
        }
    }

    It 'enables with platform security features and preserves existing lock values' {
        Set-TestDword -Path $script:deviceGuardPath -Name 'Locked' -Value 1

        Set-AtlasVbsConfiguration -State Enable `
            -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath

        (Get-TestValueState -Path $script:deviceGuardPath -Name 'RequirePlatformSecurityFeatures').Value | Should -Be 1
        (Get-TestValueState -Path $script:deviceGuardPath -Name 'Locked').Value | Should -Be 1
        (Get-TestValueState -Path $script:deviceGuardPath -Name 'EnableVirtualizationBasedSecurity').Value | Should -Be 1
        (Get-TestValueState -Path $script:hvciPath -Name 'Locked').Value | Should -Be 0
        (Get-TestValueState -Path $script:hvciPath -Name 'Enabled').Value | Should -Be 1
        foreach ($name in @('RequirePlatformSecurityFeatures', 'Locked', 'EnableVirtualizationBasedSecurity')) {
            (Get-TestValueState -Path $script:deviceGuardPath -Name $name).Kind |
                Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord) -Because $name
        }
    }

    It 'refuses to disable when a UEFI lock protects the current state' {
        Set-TestDword -Path $script:hvciPath -Name 'Locked' -Value 1

        { Set-AtlasVbsConfiguration -State Disable `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw '*UEFI lock*'

        Get-TestValueState -Path $script:hvciPath -Name 'Enabled' | Should -BeNullOrEmpty
        Test-Path -LiteralPath $script:deviceGuardPath | Should -BeTrue
        @((Get-Item -LiteralPath $script:deviceGuardPath).GetValueNames()) | Should -BeNullOrEmpty
    }

    It 'still enables under a UEFI lock and keeps the lock' {
        Set-TestDword -Path $script:hvciPath -Name 'Locked' -Value 1

        Set-AtlasVbsConfiguration -State Enable `
            -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath

        (Get-TestValueState -Path $script:hvciPath -Name 'Locked').Value | Should -Be 1
        (Get-TestValueState -Path $script:hvciPath -Name 'Enabled').Value | Should -Be 1
    }

    It 'refuses to overwrite a policy-managed configuration' -TestCases @(
        @{ PolicyValue = 'EnableVirtualizationBasedSecurity' }
        @{ PolicyValue = 'LsaCfgFlags' }
        @{ PolicyValue = 'KernelShadowStacks' }
    ) {
        Set-TestDword -Path $script:policyPath -Name $PolicyValue -Value 0

        { Set-AtlasVbsConfiguration -State Disable `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw "*managed by policy value '$PolicyValue'*"

        Test-Path -LiteralPath $script:deviceGuardPath | Should -BeFalse
    }

    It 'refuses lock values it cannot interpret' {
        Set-TestDword -Path $script:deviceGuardPath -Name 'Locked' -Value 2

        { Set-AtlasVbsConfiguration -State Enable `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw '*unsupported value*'

        Get-TestValueState -Path $script:deviceGuardPath -Name 'EnableVirtualizationBasedSecurity' |
            Should -BeNullOrEmpty
    }

    It 'refuses a lock value that is not REG_DWORD' {
        New-Item -Path $script:deviceGuardPath -Force | Out-Null
        Set-ItemProperty -LiteralPath $script:deviceGuardPath -Name 'Locked' -Value '1' -Type String

        { Set-AtlasVbsConfiguration -State Disable `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw '*not REG_DWORD*'
    }

    It 'requires Administrator rights before reading or writing anything' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Security { throw '[privilege] This operation requires Administrator rights.' }

        { Set-AtlasVbsConfiguration -State Disable `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw '*requires Administrator*'

        Test-Path -LiteralPath $script:deviceGuardPath | Should -BeFalse
    }

    It 'rejects states outside Enable and Disable' {
        { Set-AtlasVbsConfiguration -State Off } | Should -Throw
    }
}

Describe 'Get-AtlasVbsConfiguration' {
    It 'reports the current provider state with readable names' {
        Mock Get-CimInstance -ModuleName Atlas.Security -MockWith {
            [pscustomobject]@{
                VirtualizationBasedSecurityStatus = 2
                SecurityServicesConfigured        = @(1, 2, 7)
                SecurityServicesRunning           = @(2)
                RequiredSecurityProperties        = @(0)
                AvailableSecurityProperties       = @(1, 2, 8, 99)
            }
        }

        $report = Get-AtlasVbsConfiguration
        $report.VbsStatus | Should -BeExactly 'Enabled and running'
        @($report.ConfiguredServices) | Should -Be @(
            'Credential Guard'
            'Memory integrity (HVCI)'
            'Hypervisor-Enforced Paging Translation'
        )
        @($report.RunningServices) | Should -Be @('Memory integrity (HVCI)')
        @($report.RequiredProperties) | Should -Be @('None')
        @($report.AvailableProperties) | Should -Be @(
            'Base virtualization support'
            'Secure Boot'
            'APIC virtualization'
            'Unknown (99)'
        )
        Should -Invoke Get-CimInstance -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $ClassName -ceq 'Win32_DeviceGuard' -and $Namespace -ceq 'root\Microsoft\Windows\DeviceGuard'
        }
    }

    It 'fails when the provider does not return exactly one instance' {
        Mock Get-CimInstance -ModuleName Atlas.Security -MockWith { @() }

        { Get-AtlasVbsConfiguration } | Should -Throw '*exactly one Win32_DeviceGuard*'
    }
}

Describe 'Windows Defender state' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Security
        Mock Write-AtlasStep -ModuleName Atlas.Security
        Mock Write-AtlasNote -ModuleName Atlas.Security
        Mock Write-AtlasWarning -ModuleName Atlas.Security
        Mock Wait-AtlasContinue -ModuleName Atlas.Security
        Mock Get-AtlasDefenderPackageInstaller -ModuleName Atlas.Security {
            [pscustomobject]@{ ScriptPath = 'C:\Windows\AtlasModules\Scripts\Entry\Install-AtlasPackage.ps1'; PowerShellPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' }
        }
        Mock Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security { 0 }
        Mock Read-AtlasDefenderMenuChoice -ModuleName Atlas.Security { throw 'the menu must not be shown' }
        Mock Get-AtlasDefenderPackageNames -ModuleName Atlas.Security { @() }
    }

    It 'reports Enabled without the NoDefender package and Disabled with it' {
        Get-AtlasDefenderState | Should -BeExactly 'Enabled'

        Mock Get-AtlasDefenderPackageNames -ModuleName Atlas.Security { @('Z-Atlas-NoDefender-Package~amd64~~1.0.0.0') }
        Get-AtlasDefenderState | Should -BeExactly 'Disabled'
    }

    It 'installs the NoDefender package silently to disable Defender' {
        Set-AtlasDefenderState -State Disable -Silent

        Should -Invoke Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Operation -ceq 'Install' -and $NoInteraction
        }
        Should -Invoke Wait-AtlasContinue -ModuleName Atlas.Security -Times 0 -Exactly
        Should -Invoke Read-AtlasDefenderMenuChoice -ModuleName Atlas.Security -Times 0 -Exactly
    }

    It 'confirms interactively and removes the package to enable Defender' {
        Mock Get-AtlasDefenderPackageNames -ModuleName Atlas.Security { @('Z-Atlas-NoDefender-Package~amd64~~1.0.0.0') }

        Set-AtlasDefenderState -State Enable

        Should -Invoke Wait-AtlasContinue -ModuleName Atlas.Security -Times 1 -Exactly
        Should -Invoke Write-AtlasWarning -ModuleName Atlas.Security -Times 0 -Exactly
        Should -Invoke Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Operation -ceq 'Uninstall' -and -not $NoInteraction
        }
    }

    It 'lets the menu choose the change when no state is given' {
        Mock Read-AtlasDefenderMenuChoice -ModuleName Atlas.Security { 'Disable' }

        Set-AtlasDefenderState

        Should -Invoke Read-AtlasDefenderMenuChoice -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $CurrentState -ceq 'Enabled'
        }
        Should -Invoke Write-AtlasWarning -ModuleName Atlas.Security -Times 1 -Exactly
        Should -Invoke Wait-AtlasContinue -ModuleName Atlas.Security -Times 1 -Exactly
        Should -Invoke Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Operation -ceq 'Install'
        }
    }

    It 'requires a state when running silently' {
        { Set-AtlasDefenderState -Silent } | Should -Throw '*requires -State*'

        Should -Invoke Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security -Times 0 -Exactly
    }

    It 'changes nothing when Defender is already in the requested state' {
        Set-AtlasDefenderState -State Enable -Silent

        Should -Invoke Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security -Times 0 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Message -like '*already enabled*'
        }
    }

    It 'propagates a failing package installer exit code' {
        Mock Invoke-AtlasDefenderPackageInstaller -ModuleName Atlas.Security { 7 }

        { Set-AtlasDefenderState -State Disable -Silent } | Should -Throw '*Package installation failed with exit code 7*'
    }

}

Describe 'Windows Defender package installer boundary' {
    It 'resolves the installer only beneath the Atlas modules root' {
        $script:defenderModulesRoot = Join-Path $TestDrive 'AtlasModules'
        $entryRoot = New-Item -ItemType Directory -Path (Join-Path $script:defenderModulesRoot 'Scripts\Entry') -Force
        $expectedScript = Join-Path $entryRoot.FullName 'Install-AtlasPackage.ps1'
        Mock Get-AtlasContext -ModuleName Atlas.Security { [pscustomobject]@{ AtlasModulesPath = $script:defenderModulesRoot } }

        { InModuleScope Atlas.Security { Get-AtlasDefenderPackageInstaller } } | Should -Throw '*Install-AtlasPackage.ps1*missing*'

        Set-Content -LiteralPath $expectedScript -Value '' -Encoding Ascii
        $installer = InModuleScope Atlas.Security { Get-AtlasDefenderPackageInstaller }
        $installer.ScriptPath | Should -BeExactly $expectedScript
        [IO.File]::Exists($installer.PowerShellPath) | Should -BeTrue
    }

    It 'runs the installer through Windows PowerShell with the package pattern and returns its exit code' {
        $script:defenderCallRecord = Join-Path $TestDrive 'installer-call.txt'
        $fakeInstaller = Join-Path $TestDrive 'Install-AtlasPackage.ps1'
        @"
param([string[]]`$InstallPackages, [string[]]`$UninstallPackages, [switch]`$NoInteraction)
Set-Content -LiteralPath '$script:defenderCallRecord' -Value @(
    "install=`$(`$InstallPackages -join '|')"
    "uninstall=`$(`$UninstallPackages -join '|')"
    "nointeraction=`$NoInteraction"
)
exit 3
"@ | Set-Content -LiteralPath $fakeInstaller -Encoding UTF8
        $installer = [pscustomobject]@{
            ScriptPath     = $fakeInstaller
            PowerShellPath = Join-Path $PSHOME 'powershell.exe'
        }

        $exitCode = InModuleScope Atlas.Security {
            Invoke-AtlasDefenderPackageInstaller -Operation Uninstall -Installer $i -NoInteraction
        } -Parameters @{ i = $installer }

        $exitCode | Should -Be 3
        Get-Content -LiteralPath $script:defenderCallRecord | Should -Be @(
            'install='
            'uninstall=*Z-Atlas-NoDefender-Package*'
            'nointeraction=True'
        )
    }
}

Describe 'Repair-AtlasWindowsTempPermissions' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Security
    }

    AfterEach {
        # The default TEMP rule set grants the test user no read access; hand the
        # directory back to the current user so the test drive can be cleaned.
        if ($script:aclTarget -and (Test-Path -LiteralPath $script:aclTarget)) {
            $acl = Get-Acl -LiteralPath $script:aclTarget
            $acl.SetAccessRuleProtection($false, $false)
            foreach ($rule in @($acl.Access)) {
                [void]$acl.RemoveAccessRuleSpecific($rule)
            }
            $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                        [Security.Principal.WindowsIdentity]::GetCurrent().User,
                        [Security.AccessControl.FileSystemRights]::FullControl,
                        ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit),
                        [Security.AccessControl.PropagationFlags]::None,
                        [Security.AccessControl.AccessControlType]::Allow)))
            (New-Object IO.DirectoryInfo($script:aclTarget)).SetAccessControl($acl)
            $script:aclTarget = $null
        }
    }

    It 'replaces a directory DACL with exactly the four default TEMP rules' {
        $target = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'TempRoot') -Force
        $script:aclTarget = $target.FullName
        $null = New-Item -ItemType File -Path (Join-Path $target.FullName 'existing.txt') -Force

        InModuleScope Atlas.Security { Set-AtlasWindowsTempRootAcl -Path $p } -Parameters @{ p = $target.FullName }

        $acl = Get-Acl -LiteralPath $target.FullName
        $acl.AreAccessRulesProtected | Should -BeTrue
        $rules = @($acl.Access)
        $rules.Count | Should -Be 4
        @($rules | ForEach-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } | Sort-Object) |
            Should -Be @('S-1-3-0', 'S-1-5-18', 'S-1-5-32-544', 'S-1-5-32-545')
        $users = $rules | Where-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -ceq 'S-1-5-32-545' }
        [int]$users.FileSystemRights | Should -Be ([int](
                [Security.AccessControl.FileSystemRights]::Synchronize -bor
                [Security.AccessControl.FileSystemRights]::WriteData -bor
                [Security.AccessControl.FileSystemRights]::AppendData -bor
                [Security.AccessControl.FileSystemRights]::ExecuteFile))
        $users.InheritanceFlags | Should -Be ([Security.AccessControl.InheritanceFlags]::ContainerInherit)
        $creatorOwner = $rules | Where-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -ceq 'S-1-3-0' }
        $creatorOwner.PropagationFlags | Should -Be ([Security.AccessControl.PropagationFlags]::InheritOnly)
        # Existing content is untouched and the repair is idempotent.
        Test-Path -LiteralPath (Join-Path $target.FullName 'existing.txt') | Should -BeTrue
        { InModuleScope Atlas.Security { Set-AtlasWindowsTempRootAcl -Path $p } -Parameters @{ p = $target.FullName } } |
            Should -Not -Throw
    }

    It 'requires Administrator rights before touching the Windows TEMP directory' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Security { throw '[privilege] This operation requires Administrator rights.' }
        Mock Set-AtlasWindowsTempRootAcl -ModuleName Atlas.Security

        { Repair-AtlasWindowsTempPermissions } | Should -Throw '*requires Administrator*'

        Should -Invoke Set-AtlasWindowsTempRootAcl -ModuleName Atlas.Security -Times 0 -Exactly
    }

    It 'repairs exactly the fixed Windows TEMP root' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Security
        Mock Set-AtlasWindowsTempRootAcl -ModuleName Atlas.Security

        Repair-AtlasWindowsTempPermissions

        $expected = Join-Path ([Environment]::GetFolderPath('Windows')) 'Temp'
        Should -Invoke Set-AtlasWindowsTempRootAcl -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Path -eq $expected
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Security -Times 1 -Exactly
    }
}

Describe 'Security toggle companions' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Write-AtlasNote -ModuleName Atlas.Toggles
        Mock Write-AtlasStep -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
    }

    It 'VbsState routes both recorded machine states to the module' {
        Mock Set-AtlasVbsConfiguration -ModuleName Atlas.Toggles

        $definition = $script:VbsState
        foreach ($stateName in @('Disable', 'Enable')) {
            $state = $definition.States[$stateName]
            $state['MachineAction'] | Should -BeExactly 'Set-AtlasVbsState'
            Invoke-CompanionFunction -Definition $definition -FunctionName 'Set-AtlasVbsState' `
                -Toggle (New-ToggleContext -Name 'VbsState' -State $stateName)
        }

        Should -Invoke Set-AtlasVbsConfiguration -ModuleName Atlas.Toggles -Times 2 -Exactly
        Should -Invoke Set-AtlasVbsConfiguration -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $State -ceq 'Disable' }
        Should -Invoke Set-AtlasVbsConfiguration -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $State -ceq 'Enable' }
        Should -Invoke Import-AtlasModule -ModuleName Atlas.Toggles -Times 2 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Security' }
        $definition.States['Disable']['StateValue'] | Should -Be 0
        $definition.States['Enable']['StateValue'] | Should -Be 1
        # Both states are recorded machine work: replayed on upgrade, never per user.
        foreach ($stateName in @('Disable', 'Enable')) {
            $work = Get-AtlasToggleStateWork -Definition $definition -StateEntry $definition.States[$stateName]
            $work.Machine | Should -BeTrue -Because $stateName
            $work.User | Should -BeFalse -Because $stateName
            $work.Local | Should -BeFalse -Because $stateName
        }
        @($definition.States.Values | ForEach-Object { $_['Reboot'] } | Select-Object -Unique) |
            Should -Be @('Recommend')
    }

    It 'ConfigVBS shows the report locally without elevation or a state record' {
        Mock Get-AtlasVbsConfiguration -ModuleName Atlas.Toggles {
            [pscustomobject]@{
                VbsStatus           = 'Enabled and running'
                ConfiguredServices  = @('Memory integrity (HVCI)')
                RunningServices     = @('Memory integrity (HVCI)')
                RequiredProperties  = @('None')
                AvailableProperties = @('Secure Boot')
            }
        }

        $definition = $script:ConfigVbs
        $run = $definition.States['Run']
        $definition.Elevation | Should -BeExactly 'None'
        $definition.NoStateRecord | Should -BeTrue
        $run['Action'] | Should -BeExactly 'Show-AtlasVbsConfiguration'
        $work = Get-AtlasToggleStateWork -Definition $definition -StateEntry $run
        $work.Local | Should -BeTrue
        $work.Machine | Should -BeFalse

        Invoke-CompanionFunction -Definition $definition -FunctionName 'Show-AtlasVbsConfiguration' `
            -Toggle (New-ToggleContext -Name 'ConfigVBS' -State 'Run' -Silent $false)

        Should -Invoke Get-AtlasVbsConfiguration -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Write-AtlasNote -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Text -contains 'VBS status: Enabled and running' -and
                $Text -contains 'Running services: Memory integrity (HVCI)'
        }
    }

    It 'ToggleDefender chooses in the administrator process and crosses the broker as a fixed state' {
        Mock Set-AtlasDefenderState -ModuleName Atlas.Toggles
        Mock Read-AtlasDefenderStateChoice -ModuleName Atlas.Toggles { 'Disable' }

        $definition = $script:ToggleDefender
        $definition.Elevation | Should -BeExactly 'TrustedInstaller'
        $definition.NoStateRecord | Should -BeTrue
        $run = $definition.States['Run']
        $run['InteractiveState'] | Should -BeExactly 'Select-AtlasDefenderToggleState'
        $run['Reboot'] | Should -BeExactly 'Prompt'
        foreach ($internal in @('Disable', 'Enable')) {
            $definition.States[$internal]['Internal'] | Should -BeTrue
            $definition.States[$internal]['NoStateRecord'] | Should -BeTrue
            (Get-AtlasToggleStateWork -Definition $definition -StateEntry $definition.States[$internal]).User | Should -BeFalse
        }

        # The selector only runs interactively and returns the confirmed internal state.
        Invoke-CompanionFunction -Definition $definition -FunctionName 'Select-AtlasDefenderToggleState' `
            -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Run' -Silent $false) | Should -BeExactly 'Disable'
        { Invoke-CompanionFunction -Definition $definition -FunctionName 'Select-AtlasDefenderToggleState' `
                -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Run' -Silent $true) } |
            Should -Throw '*interactive window*'
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 0 -Exactly

        # The internal states apply the chosen change silently inside the broker.
        Invoke-CompanionFunction -Definition $definition -FunctionName 'Disable-AtlasDefenderToggle' `
            -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Disable' -Silent $true)
        Invoke-CompanionFunction -Definition $definition -FunctionName 'Enable-AtlasDefenderToggle' `
            -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Enable' -Silent $true)
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $Silent -and $State -ceq 'Disable' }
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $Silent -and $State -ceq 'Enable' }

        # A silent request for the public state has no choice to apply.
        { Invoke-CompanionFunction -Definition $definition -FunctionName 'Invoke-AtlasDefenderToggle' `
                -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Run' -Silent $true) } |
            Should -Throw '*interactive window*'
    }

    It 'FixErrors2502and2503 runs the TEMP repair as recorded-free TrustedInstaller machine work' {
        Mock Repair-AtlasWindowsTempPermissions -ModuleName Atlas.Toggles

        $definition = $script:FixErrors
        $definition.Elevation | Should -BeExactly 'TrustedInstaller'
        $definition.NoStateRecord | Should -BeTrue
        $definition.States['Run']['MachineAction'] | Should -BeExactly 'Invoke-AtlasWindowsTempPermissionsRepair'

        Invoke-CompanionFunction -Definition $definition -FunctionName 'Invoke-AtlasWindowsTempPermissionsRepair' `
            -Toggle (New-ToggleContext -Name 'FixErrors2502and2503' -State 'Run' -Silent $false)

        Should -Invoke Repair-AtlasWindowsTempPermissions -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Write-AtlasStep -ModuleName Atlas.Toggles -Times 1 -Exactly
    }
}

Describe 'disable-core-isolation install tweak' {
    It 'is a checked, single-purpose option whose companion disables VBS through the module' {
        $definition = Import-PowerShellDataFile -LiteralPath $script:TweakPath
        $definition.Option | Should -BeExactly 'disable-core-isolation'
        $definition.Script | Should -BeExactly 'disable-core-isolation.ps1'
        $definition.Keys | Should -Not -Contain 'Run'
        $definition.Keys | Should -Not -Contain 'RemovePaths'
        $definition.Description | Should -Match 'preserved'

        Mock Import-AtlasModule
        Mock Set-AtlasVbsConfiguration

        & (Join-Path (Split-Path -Parent $script:TweakPath) $definition.Script)

        Should -Invoke Import-AtlasModule -Times 1 -Exactly -ParameterFilter { $Name -ceq 'Atlas.Security' }
        Should -Invoke Set-AtlasVbsConfiguration -Times 1 -Exactly -ParameterFilter { $State -ceq 'Disable' }
    }
}
