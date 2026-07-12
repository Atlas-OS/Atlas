[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester BeforeAll variables are consumed from child test scopes.'
)]
param()

BeforeAll {
    $script:ModulesRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path $script:ModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path $script:ModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:CoreModule = Get-Module Atlas.Core
    $script:TogglesModule = Get-Module Atlas.Toggles
    & $script:CoreModule { Initialize-AtlasTrustedInstallerNativeType }

    $script:ToggleRoot = Join-Path $TestDrive 'Toggles'
    $definitionRoot = Join-Path $script:ToggleRoot 'Privilege'
    New-Item -Path $definitionRoot -ItemType Directory -Force | Out-Null

    $script:EventPath = Join-Path $TestDrive 'privilege-events.txt'
    $env:ATLAS_PRIVILEGE_TEST_EVENTS = $script:EventPath

    $plainTemplate = @'
@{
    Name          = '__NAME__'
    Elevation     = '__ELEVATION__'
    NoStateRecord = $true
    States        = [ordered]@{
        Enable = @{
            StateValue = 1
            Reboot     = 'None'
            Action     = { param($Toggle) }
        }
    }
}
'@
    foreach ($definition in @(
            @{ Name = 'AdminOnly'; Elevation = 'Admin' }
            @{ Name = 'TrustedOnly'; Elevation = 'TrustedInstaller' }
        )) {
        $content = $plainTemplate.Replace('__NAME__', $definition.Name).
            Replace('__ELEVATION__', $definition.Elevation)
        Set-Content -LiteralPath (Join-Path $definitionRoot "$($definition.Name).ps1") `
            -Value $content -Encoding Ascii
    }

    $splitTemplate = @'
@{
    Name          = '__NAME__'
    Elevation     = '__ELEVATION__'
    NoStateRecord = $true
    States        = [ordered]@{
        Enable = @{
            StateValue       = 1
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = {
                param($Toggle)
                [IO.File]::AppendAllText($env:ATLAS_PRIVILEGE_TEST_EVENTS, "machine`n")
            }
            UserAction       = {
                param($Toggle)
                [IO.File]::AppendAllText($env:ATLAS_PRIVILEGE_TEST_EVENTS, "user`n")
            }
        }
    }
}
'@
    foreach ($definition in @(
            @{ Name = 'SplitAdmin'; Elevation = 'Admin' }
            @{ Name = 'SplitTrusted'; Elevation = 'TrustedInstaller' }
        )) {
        $content = $splitTemplate.Replace('__NAME__', $definition.Name).
            Replace('__ELEVATION__', $definition.Elevation)
        Set-Content -LiteralPath (Join-Path $definitionRoot "$($definition.Name).ps1") `
            -Value $content -Encoding Ascii
    }
}

AfterAll {
    Remove-Item Env:\ATLAS_PRIVILEGE_TEST_EVENTS -ErrorAction SilentlyContinue
}

Describe 'Atlas process privilege decisions' {
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
        $tokenEvidence = [Atlas.TrustedInstallerProcessNative]::GetCurrentTokenEvidence()

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

        [Atlas.TrustedInstallerProcessNative]::IsStrictTrustedInstallerEvidence(
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
        Mock -CommandName Read-Pause -ModuleName Atlas.Toggles
        Mock -CommandName Write-Title -ModuleName Atlas.Toggles
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

    It 'replays only MachineAction from a split privileged state' {
        $definition = Get-AtlasToggleDefinition -Name SplitTrusted `
            -TogglesRoot $script:ToggleRoot

        & $script:TogglesModule {
            param($Definition, $StateRoot)
            Invoke-AtlasToggleTrustedReapplyState `
                -Definition $Definition `
                -StateName Enable `
                -StateRoot $StateRoot
        } $definition $TestDrive

        Get-Content -LiteralPath $script:EventPath | Should -Be @('machine')
        Should -Invoke -CommandName Assert-AtlasPrivilege -ModuleName Atlas.Toggles `
            -Times 1 -Exactly -ParameterFilter { $TrustedInstaller }
    }
}
