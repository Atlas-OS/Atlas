[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester BeforeAll variables are consumed from child test scopes.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:ModulesRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path $script:ModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path $script:ModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:CoreModule = Get-Module Atlas.Core
    $script:TogglesModule = Get-Module Atlas.Toggles
    & $script:CoreModule { Initialize-AtlasNativeType }

    $script:ToggleRoot = Join-Path $TestDrive 'Toggles'
    $definitionRoot = Join-Path $script:ToggleRoot 'Privilege'
    New-Item -Path $definitionRoot -ItemType Directory -Force | Out-Null

    $script:EventPath = Join-Path $TestDrive 'privilege-events.txt'
    $env:ATLAS_PRIVILEGE_TEST_EVENTS = $script:EventPath

    $companion = @'
function Invoke-AtlasPrivilegeNoop {
    param($Toggle)
}

function Write-AtlasPrivilegeMachineEvent {
    param($Toggle)
    [IO.File]::AppendAllText($env:ATLAS_PRIVILEGE_TEST_EVENTS, "machine`n")
}

function Write-AtlasPrivilegeUserEvent {
    param($Toggle)
    [IO.File]::AppendAllText($env:ATLAS_PRIVILEGE_TEST_EVENTS, "user`n")
}
'@
    $plainTemplate = @'
@{
    Name          = '__NAME__'
    Elevation     = '__ELEVATION__'
    NoStateRecord = $true
    Script        = '__NAME__.ps1'
    States        = @(
        @{ Name = 'Enable'; Launcher = 'Privilege\__NAME__.cmd'; Reboot = 'None'; MachineAction = 'Invoke-AtlasPrivilegeNoop' }
    )
}
'@
    $splitTemplate = @'
@{
    Name          = '__NAME__'
    Elevation     = '__ELEVATION__'
    Warning       = 'Confirm split action.'
    NoStateRecord = $true
    Script        = '__NAME__.ps1'
    States        = @(
        @{ Name = 'Enable'; Launcher = 'Privilege\__NAME__.cmd'; Reboot = 'None'; MachineAction = 'Write-AtlasPrivilegeMachineEvent'; UserAction = 'Write-AtlasPrivilegeUserEvent' }
    )
}
'@
    foreach ($definition in @(
            @{ Name = 'AdminOnly'; Elevation = 'Admin'; Template = $plainTemplate }
            @{ Name = 'TrustedOnly'; Elevation = 'TrustedInstaller'; Template = $plainTemplate }
            @{ Name = 'SplitAdmin'; Elevation = 'Admin'; Template = $splitTemplate }
            @{ Name = 'SplitTrusted'; Elevation = 'TrustedInstaller'; Template = $splitTemplate }
        )) {
        $content = $definition.Template.Replace('__NAME__', $definition.Name).
            Replace('__ELEVATION__', $definition.Elevation)
        Set-Content -LiteralPath (Join-Path $definitionRoot "$($definition.Name).psd1") `
            -Value $content -Encoding Ascii
        Set-Content -LiteralPath (Join-Path $definitionRoot "$($definition.Name).ps1") `
            -Value $companion -Encoding Ascii
    }
}

AfterAll {
    Remove-Item Env:\ATLAS_PRIVILEGE_TEST_EVENTS -ErrorAction SilentlyContinue
}

Describe 'Atlas process privilege decisions' {
    It 'reads enabled and deny-only groups without duplicating the token' {
        $nativeType = [Atlas.Native.TrustedInstallerProcess]
        $openToken = $nativeType.GetMethod('OpenProcessToken', [Reflection.BindingFlags]'Static,NonPublic')
        $hasGroup = $nativeType.GetMethod('HasEnabledGroup', [Reflection.BindingFlags]'Static,NonPublic')
        $closeHandle = $nativeType.GetMethod('CloseHandle', [Reflection.BindingFlags]'Static,NonPublic')
        $openArguments = [object[]]@([Diagnostics.Process]::GetCurrentProcess().Handle, [uint32]8, [IntPtr]::Zero)
        $openToken.Invoke($null, $openArguments) | Should -BeTrue
        $token = $openArguments[2]
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        try {
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            foreach ($sid in @('S-1-5-32-545', 'S-1-5-32-544', 'S-1-5-32-9999')) {
                $expected = $principal.IsInRole([Security.Principal.SecurityIdentifier]::new($sid))
                $hasGroup.Invoke($null, @($token, $sid)) | Should -Be $expected
            }
        }
        finally {
            $identity.Dispose()
            [void]$closeHandle.Invoke($null, @($token))
        }
    }

    It 'reads fixed-size elevation and session values from the real current token' {
        $nativeType = [Atlas.Native.TrustedInstallerProcess]
        $informationClass = $nativeType.GetNestedType('TOKEN_INFORMATION_CLASS', [Reflection.BindingFlags]'NonPublic')
        $readScalar = $nativeType.GetMethod('ReadTokenInt32', [Reflection.BindingFlags]'Static,NonPublic')
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        try {
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            $expectedElevation = [int]$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            $readScalar.Invoke($null, @($identity.Token, [Enum]::Parse($informationClass, 'TokenElevation'))) |
                Should -Be $expectedElevation
            $readScalar.Invoke($null, @($identity.Token, [Enum]::Parse($informationClass, 'TokenSessionId'))) |
                Should -Be ([Diagnostics.Process]::GetCurrentProcess().SessionId)
        }
        finally { $identity.Dispose() }
    }

    It 'classifies the real current token without treating Administrator or SYSTEM as TrustedInstaller' {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        try {
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            $expectedAdmin = $principal.IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator
            )
            $expectedSystem = $identity.User.Value -ceq 'S-1-5-18'
        }
        finally {
            $identity.Dispose()
        }
        $tokenEvidence = [Atlas.Native.TrustedInstallerProcess]::GetCurrentTokenEvidence()

        Test-AtlasAdmin | Should -Be $expectedAdmin
        Test-AtlasSystem | Should -Be $expectedSystem
        Test-AtlasTrustedInstaller | Should -Be ([bool]$tokenEvidence.IsTrustedInstaller)

        if ($expectedAdmin) {
            { Assert-AtlasPrivilege -Administrator } | Should -Not -Throw
        }
        else {
            { Assert-AtlasPrivilege -Administrator } | Should -Throw '*Administrator rights*'
        }
        if ($tokenEvidence.IsTrustedInstaller) {
            { Assert-AtlasPrivilege -TrustedInstaller } | Should -Not -Throw
        }
        else {
            { Assert-AtlasPrivilege -TrustedInstaller } | Should -Throw '*TrustedInstaller service token*'
        }
    }

    It 'accepts only the strict TrustedInstaller token shape' -TestCases @(
        @{ Sid = 'S-1-5-18'; Present = $true; Attributes = [uint32]0x4; Integrity = 0x4000; Expected = $true }
        @{ Sid = 'S-1-5-21-1-2-3-1001'; Present = $true; Attributes = [uint32]0x4; Integrity = 0x4000; Expected = $false }
        @{ Sid = 'S-1-5-18'; Present = $false; Attributes = [uint32]0x0; Integrity = 0x4000; Expected = $false }
        @{ Sid = 'S-1-5-18'; Present = $true; Attributes = [uint32]0x14; Integrity = 0x4000; Expected = $false }
        @{ Sid = 'S-1-5-18'; Present = $true; Attributes = [uint32]0x4; Integrity = 0x3000; Expected = $false }
    ) {
        param($Sid, $Present, $Attributes, $Integrity, $Expected)

        [Atlas.Native.TrustedInstallerProcess]::IsStrictTrustedInstallerEvidence(
            $Sid,
            [bool]$Present,
            [uint32]$Attributes,
            [int]$Integrity
        ) | Should -Be $Expected
    }
}

Describe 'Atlas toggle privilege routing' {
    BeforeEach {
        Remove-Item -LiteralPath $script:EventPath -Force -ErrorAction SilentlyContinue

        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $false }
        Mock -CommandName Wait-AtlasContinue -ModuleName Atlas.Toggles
        Mock -CommandName Wait-AtlasExit -ModuleName Atlas.Toggles
        Mock -CommandName Write-AtlasTitle -ModuleName Atlas.Toggles
        Mock -CommandName Write-AtlasCompletion -ModuleName Atlas.Toggles
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Toggles
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{
                WinDir           = [Environment]::GetFolderPath('Windows')
                AtlasModulesPath = 'C:\AtlasModules'
                WindowsBuild     = 26100
            }
        }
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{ ExitCode = 0 }
        }
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{ ExitCode = 0 }
        }
    }

    It 'rejects LocalSystem without strict TrustedInstaller evidence before broker dispatch' {
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Toggles -MockWith { $true }

        {
            Invoke-AtlasToggle -Name TrustedOnly -State Enable -Silent `
                -TogglesRoot $script:ToggleRoot
        } | Should -Throw '*LocalSystem without strict TrustedInstaller token evidence*'

        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
    }

    It 'runs the machine child before the user action when SID and session remain exact' {
        $script:CallerBindings = [Collections.Generic.Queue[object]]::new()
        foreach ($unused in 1..2) {
            $script:CallerBindings.Enqueue([pscustomobject]@{
                    Sid       = 'S-1-5-21-111-222-333-1001'
                    SessionId = 7
                })
        }
        Mock -CommandName Get-AtlasToggleUserCallerBinding -ModuleName Atlas.Toggles -MockWith {
            $script:CallerBindings.Dequeue()
        }
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [IO.File]::AppendAllText($script:EventPath, "machine-child`n")
            [pscustomobject]@{ ExitCode = 0 }
        }

        Invoke-AtlasToggle -Name SplitAdmin -State Enable -NoExplorerRestart `
            -TogglesRoot $script:ToggleRoot

        Get-Content -LiteralPath $script:EventPath | Should -Be @('machine-child', 'user')
        Should -Invoke -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter { $ArgumentList -contains '-MachineOnly' }
        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        Should -Invoke -CommandName Wait-AtlasContinue -ModuleName Atlas.Toggles -Times 1 -Exactly
    }

    It 'routes a normal split TrustedInstaller caller through Administrator and the TI broker before the bound user action' {
        $script:CallerBindings = [Collections.Generic.Queue[object]]::new()
        foreach ($unused in 1..2) {
            $script:CallerBindings.Enqueue([pscustomobject]@{
                    Sid       = 'S-1-5-21-111-222-333-1001'
                    SessionId = 7
                })
        }
        $script:InElevatedChild = $false
        Mock -CommandName Get-AtlasToggleUserCallerBinding -ModuleName Atlas.Toggles -MockWith {
            $script:CallerBindings.Dequeue()
        }
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith {
            $script:InElevatedChild
        }
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [IO.File]::AppendAllText($script:EventPath, "admin-child`n")
            $script:InElevatedChild = $true
            try {
                Invoke-AtlasToggle -Name SplitTrusted -State Enable -Silent -MachineOnly `
                    -TogglesRoot $script:ToggleRoot
            }
            finally {
                $script:InElevatedChild = $false
            }
            [pscustomobject]@{ ExitCode = 0 }
        }
        Mock -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith {
            [IO.File]::AppendAllText($script:EventPath, "ti-broker`n")
            [pscustomobject]@{ ExitCode = 0 }
        }

        Invoke-AtlasToggle -Name SplitTrusted -State Enable -NoExplorerRestart `
            -TogglesRoot $script:ToggleRoot

        Get-Content -LiteralPath $script:EventPath | Should -Be @(
            'admin-child'
            'ti-broker'
            'user'
        )
        Should -Invoke -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter { $ArgumentList -contains '-MachineOnly' }
        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter {
                $Operation -ceq 'Toggle' -and
                    $Name -ceq 'SplitTrusted' -and
                    $State -ceq 'Enable' -and
                    $Silent -and
                    $NoExplorerRestart -and
                    $MachineOnly
            }
        Should -Invoke -CommandName Wait-AtlasContinue -ModuleName Atlas.Toggles -Times 1 -Exactly
    }

    It 'rejects an already-elevated top-level split toggle before either scope runs' -TestCases @(
        @{ Name = 'SplitAdmin' }
        @{ Name = 'SplitTrusted' }
    ) {
        Mock -CommandName Test-AtlasAdmin -ModuleName Atlas.Toggles -MockWith { $true }

        {
            Invoke-AtlasToggle -Name $Name -State Enable -NoExplorerRestart `
                -TogglesRoot $script:ToggleRoot
        } | Should -Throw '*must be launched from a non-elevated user process*'

        $script:EventPath | Should -Not -Exist
        Should -Not -Invoke -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles
        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
        Should -Not -Invoke -CommandName Wait-AtlasContinue -ModuleName Atlas.Toggles
    }

    It 'blocks the user action when the caller SID or session changes' -TestCases @(
        @{ Sid = 'S-1-5-21-111-222-333-1002'; SessionId = 7 }
        @{ Sid = 'S-1-5-21-111-222-333-1001'; SessionId = 8 }
    ) {
        param($Sid, $SessionId)

        $script:CallerBindings = [Collections.Generic.Queue[object]]::new()
        $script:CallerBindings.Enqueue([pscustomobject]@{
                Sid       = 'S-1-5-21-111-222-333-1001'
                SessionId = 7
            })
        $script:CallerBindings.Enqueue([pscustomobject]@{
                Sid       = $Sid
                SessionId = $SessionId
            })
        Mock -CommandName Get-AtlasToggleUserCallerBinding -ModuleName Atlas.Toggles -MockWith {
            $script:CallerBindings.Dequeue()
        }
        Mock -CommandName Start-AtlasToggleAdminRelaunch -ModuleName Atlas.Toggles -MockWith {
            [IO.File]::AppendAllText($script:EventPath, "machine-child`n")
            [pscustomobject]@{ ExitCode = 0 }
        }

        {
            Invoke-AtlasToggle -Name SplitAdmin -State Enable -NoExplorerRestart `
                -TogglesRoot $script:ToggleRoot
        } | Should -Throw '*caller identity or Windows session changed*'

        Get-Content -LiteralPath $script:EventPath | Should -Be @('machine-child')
    }

    It 'lets a strict TrustedInstaller child run only the declared machine action' {
        Mock -CommandName Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles -MockWith { $true }

        Invoke-AtlasToggle -Name SplitTrusted -State Enable -Silent -MachineOnly `
            -TogglesRoot $script:ToggleRoot

        Get-Content -LiteralPath $script:EventPath | Should -Be @('machine')
        Should -Not -Invoke -CommandName Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles

        {
            Invoke-AtlasToggle -Name AdminOnly -State Enable -Silent `
                -TogglesRoot $script:ToggleRoot
        } | Should -Throw '*does not declare exact TrustedInstaller elevation*'
    }
}

Describe 'Atlas trusted replay scope' {
    BeforeEach {
        Remove-Item -LiteralPath $script:EventPath -Force -ErrorAction SilentlyContinue
        Mock -CommandName Assert-AtlasPrivilege -ModuleName Atlas.Toggles
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Toggles -MockWith {
            [pscustomobject]@{
                WinDir           = [Environment]::GetFolderPath('Windows')
                AtlasModulesPath = 'C:\AtlasModules'
                WindowsBuild     = 26100
            }
        }
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Toggles
    }

    It 'replays only the machine part of a split privileged state' {
        $definition = Get-AtlasToggleDefinition -Name SplitTrusted `
            -TogglesRoot $script:ToggleRoot

        & $script:TogglesModule {
            param($Definition, $StateRoot)
            Invoke-AtlasToggleInProcess -Definition $Definition -StateName Enable -Scope Machine `
                -Silent -NoExplorerRestart -SkipPreamble -StateRoot $StateRoot
        } $definition 'HKCU:\Software\AtlasRewriteTest\PrivilegeReplay'

        Get-Content -LiteralPath $script:EventPath | Should -Be @('machine')
    }
}
