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
    $script:ToggleDefender = Get-AtlasToggleDefinition -Name ToggleDefender -TogglesRoot $togglesRoot
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

    It 'disables when policy already turns VBS off, as guides for disabling VBS leave it' {
        # The values an RC7 tester's PC had from such a guide.
        Set-TestDword -Path $script:policyPath -Name 'EnableVirtualizationBasedSecurity' -Value 0
        Set-TestDword -Path $script:policyPath -Name 'HVCIMATRequired' -Value 0
        Set-TestDword -Path $script:policyPath -Name 'LsaCfgFlags' -Value 0

        Set-AtlasVbsConfiguration -State Disable `
            -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath

        (Get-TestValueState -Path $script:deviceGuardPath -Name 'EnableVirtualizationBasedSecurity').Value | Should -Be 0
        (Get-TestValueState -Path $script:hvciPath -Name 'Enabled').Value | Should -Be 0
    }

    It 'refuses to <State> over policy value <Name> = <Value> and writes nothing' -TestCases @(
        @{ State = 'Disable'; Name = 'EnableVirtualizationBasedSecurity'; Value = 1 }
        @{ State = 'Disable'; Name = 'LsaCfgFlags'; Value = 2 }
        @{ State = 'Disable'; Name = 'ConfigureSystemGuardLaunch'; Value = 1 }
        @{ State = 'Disable'; Name = 'ConfigureKernelShadowStacksLaunch'; Value = 1 }
        @{ State = 'Disable'; Name = 'EnableVirtualizationBasedSecurity'; Value = 7 }
        @{ State = 'Enable'; Name = 'EnableVirtualizationBasedSecurity'; Value = 0 }
        @{ State = 'Enable'; Name = 'HypervisorEnforcedCodeIntegrity'; Value = 0 }
    ) {
        Set-TestDword -Path $script:policyPath -Name $Name -Value $Value

        { Set-AtlasVbsConfiguration -State $State `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw "*($Name = $Value)*"

        Test-Path -LiteralPath $script:deviceGuardPath | Should -BeFalse
    }

    It 'enables when policy only configures Credential Guard' {
        Set-TestDword -Path $script:policyPath -Name 'LsaCfgFlags' -Value 2

        Set-AtlasVbsConfiguration -State Enable `
            -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath

        (Get-TestValueState -Path $script:hvciPath -Name 'Enabled').Value | Should -Be 1
    }

    It 'logs a warning and writes nothing over conflicting policy when asked to skip' {
        Set-TestDword -Path $script:policyPath -Name 'EnableVirtualizationBasedSecurity' -Value 1

        Set-AtlasVbsConfiguration -State Disable -SkipWhenPolicyConflicts `
            -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath

        Test-Path -LiteralPath $script:deviceGuardPath | Should -BeFalse
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Security -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*EnableVirtualizationBasedSecurity = 1*'
        }
    }

    It 'refuses a <Kind> lock value it cannot interpret before writing anything' -TestCases @(
        @{ Kind = 'DWord'; Value = 2; State = 'Enable'; Message = '*unsupported value*' }
        @{ Kind = 'String'; Value = '1'; State = 'Disable'; Message = '*not REG_DWORD*' }
    ) {
        New-Item -Path $script:deviceGuardPath -Force | Out-Null
        Set-ItemProperty -LiteralPath $script:deviceGuardPath -Name 'Locked' -Value $Value -Type $Kind

        { Set-AtlasVbsConfiguration -State $State `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw $Message

        Get-TestValueState -Path $script:deviceGuardPath -Name 'EnableVirtualizationBasedSecurity' |
            Should -BeNullOrEmpty
    }

    It 'requires Administrator rights before reading or writing anything' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Security { throw '[privilege] This operation requires Administrator rights.' }

        { Set-AtlasVbsConfiguration -State Disable `
                -DeviceGuardPath $script:deviceGuardPath -PolicyPath $script:policyPath } |
            Should -Throw '*requires Administrator*'

        Test-Path -LiteralPath $script:deviceGuardPath | Should -BeFalse
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

    It 'ToggleDefender asks for the state only in an interactive administrator window' {
        Mock Set-AtlasDefenderState -ModuleName Atlas.Toggles
        Mock Read-AtlasDefenderStateChoice -ModuleName Atlas.Toggles { 'Disable' }

        Invoke-CompanionFunction -Definition $script:ToggleDefender -FunctionName 'Select-AtlasDefenderToggleState' `
            -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Run' -Silent $false) | Should -BeExactly 'Disable'
        { Invoke-CompanionFunction -Definition $script:ToggleDefender -FunctionName 'Select-AtlasDefenderToggleState' `
                -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Run' -Silent $true) } |
            Should -Throw '*interactive window*'
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'ToggleDefender applies the chosen <Chosen> state silently inside the broker' -TestCases @(
        @{ Chosen = 'Disable'; Companion = 'Disable-AtlasDefenderToggle' }
        @{ Chosen = 'Enable'; Companion = 'Enable-AtlasDefenderToggle' }
    ) {
        Mock Set-AtlasDefenderState -ModuleName Atlas.Toggles
        $script:defenderState = $Chosen

        Invoke-CompanionFunction -Definition $script:ToggleDefender -FunctionName $Companion `
            -Toggle (New-ToggleContext -Name 'ToggleDefender' -State $Chosen -Silent $true)
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Silent -and $State -ceq $script:defenderState
        }
    }

    It 'ToggleDefender refuses a silent request for its public state, which has no choice to apply' {
        Mock Set-AtlasDefenderState -ModuleName Atlas.Toggles

        { Invoke-CompanionFunction -Definition $script:ToggleDefender -FunctionName 'Invoke-AtlasDefenderToggle' `
                -Toggle (New-ToggleContext -Name 'ToggleDefender' -State 'Run' -Silent $true) } |
            Should -Throw '*interactive window*'
        Should -Invoke Set-AtlasDefenderState -ModuleName Atlas.Toggles -Times 0 -Exactly
    }
}

Describe 'disable-core-isolation install tweak' {
    It 'runs only when the user chose it' {
        (Import-PowerShellDataFile -LiteralPath $script:TweakPath).Option | Should -BeExactly 'disable-core-isolation' `
            -Because 'without the option gate every install would turn off VBS and memory integrity'
    }

    It 'finishes without changes when policy keeps VBS on' {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Security
        Mock Write-AtlasLog -ModuleName Atlas.Security
        Mock Import-AtlasModule {}
        Mock Get-AtlasVbsDwordState -ModuleName Atlas.Security -ParameterFilter { $Name -eq 'EnableVirtualizationBasedSecurity' } {
            [pscustomobject]@{ Exists = $Path -like '*Policies*'; Value = 1 }
        }
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Security { throw 'The tweak wrote a value.' }

        & ($script:TweakPath -replace '\.psd1$', '.ps1')

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Security -ParameterFilter { $Level -eq 'Warning' }
    }
}
