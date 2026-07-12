BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Atlas.Registry.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'

    function New-TestContextMock {
        param(
            [bool]$IsArm64 = $false,
            [bool]$IsUpgrade = $false,
            [bool]$IsOobe = $false,
            [int]$WindowsBuild = 26100,
            [bool]$IsInstallStateBacked = $false,
            [string]$InteractiveUserSid = 'S-1-5-21-1-2-3-1001'
        )

        [pscustomobject]@{
            WinDir           = 'C:\Windows'
            AtlasModulesPath = 'C:\Windows\AtlasModules'
            FlagsPath        = 'C:\Windows\AtlasModules\Flags'
            LogsPath         = Join-Path -Path $TestDrive -ChildPath 'Logs'
            IsArm64          = $IsArm64
            WindowsBuild     = $WindowsBuild
            IsUpgrade        = $IsUpgrade
            IsOobe           = $IsOobe
            IsInstallStateBacked = $IsInstallStateBacked
            InteractiveUserSid = $InteractiveUserSid
        }
    }
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Test-AtlasTweakSchema' {
    It 'accepts a fully-populated valid tweak' {
        $companion = Join-Path -Path $TestDrive -ChildPath 'companion.ps1'
        Set-Content -Path $companion -Value 'Write-Output "companion"'

        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'valid.psd1'
        @'
@{
    Name           = 'Valid Tweak'
    Description    = 'A tweak exercising every schema key.'
    Option         = 'defender-disable'
    Arch           = 'X64'
    OnUpgrade      = 'Both'
    Oobe           = $false
    MinBuild       = 22000
    MaxBuild       = 26200
    Registry       = @(
        @{ Path = 'HKLM:\SOFTWARE\Test'; Name = 'Value'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\Software\Test'; Name = 'Old'; Operation = 'Delete'; IgnoreErrors = $true }
        @{ Path = 'HKLM:\SOFTWARE\TestKey'; Operation = 'AddKey'; Arch = 'ARM64' }
        @{ Path = 'HKLM:\SOFTWARE\Marker'; Name = 'Flag'; Type = 'None' }
    )
    PostUserRegistryRefresh = 'ExplorerRefresh'
    Services       = @(
        @{ Name = 'TestSvc'; StartupType = 4; IgnoreErrors = $false }
        @{ Name = 'TestSvc'; Operation = 'Stop' }
    )
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Test\Task'; Operation = 'Disable'; IgnoreErrors = $false }
    )
    Run            = @(
        @{ Exe = 'C:\Windows\System32\whoami.exe'; Args = @('/all'); Wait = $true; IgnoreErrors = $false }
        @{ Exe = '{windir}\System32\dism.exe'; Args = @('/Online'); AllowedExitCodes = @(0, 3010) }
    )
    RemovePaths    = @(
        @{ Path = '{windir}\Test'; Arch = 'X64'; IgnoreErrors = $false }
    )
    Script         = 'companion.ps1'
}
'@ | Set-Content -Path $tweakFile

        $problems = @(Test-AtlasTweakSchema -Path $tweakFile)
        $problems | Should -BeNullOrEmpty
    }

    It 'reports problems for an invalid tweak' {
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'invalid.psd1'
        @'
@{
    Description = 'No name, bad option, broken entries.'
    Option      = 'not-a-real-option'
    Arch        = 'X86'
    OnUpgrade   = 'Sometimes'
    Oobe        = $true
    RunAs       = 'UserElevated'
    MinBuild    = 'notanumber'
    Bogus       = $true
    PostUserRegistryRefresh = 'explorerrefresh'
    Registry    = @(
        @{ Name = 'MissingPath'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Test'; Name = 'BadType'; Type = 'SuperString' }
        @{ Path = 'HKLM:\SOFTWARE\Test'; Name = 'NoData'; Type = 'DWord' }
    )
    Services    = @(
        @{ StartupType = 9; IgnoreErrors = 'yes' }
    )
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Test\Task'; IgnoreErrors = 'yes' }
    )
    Run         = @(
        @{ Exe = 'C:\Windows\System32\whoami.exe'; Args = '/all'; AllowedExitCodes = @('0', 1641); RunAs = 'UserElevated' }
        @{ Exe = 'tool.exe'; RunAs = 'User'; Wait = $false; IgnoreErrors = $true }
    )
    RemovePaths = @(
        @{ Path = 'C:\Test'; IgnoreErrors = 'yes' }
    )
    Script      = 'does-not-exist.ps1'
}
'@ | Set-Content -Path $tweakFile

        $problems = @(Test-AtlasTweakSchema -Path $tweakFile)
        $problemText = @($problems | ForEach-Object { $_.Problem }) -join "`n"

        $problemText | Should -Match "Unknown top-level key 'Bogus'"
        $problemText | Should -Match "Missing or empty 'Name'"
        $problemText | Should -Match "Unknown 'Option'"
        $problemText | Should -Match "'Arch' must be"
        $problemText | Should -Match "'OnUpgrade' must be"
        $problemText | Should -Match "'MinBuild' must be an integer"
        $problemText | Should -Match "'RunAs' must be 'User'"
        $problemText | Should -Match "'PostUserRegistryRefresh' must be exactly one of"
        $problemText | Should -Match "requires 'Oobe = \`$false'"
        $problemText | Should -Match 'requires at least one ambient HKCU Registry entry'
        $problemText | Should -Match 'Registry entry is missing its Path'
        $problemText | Should -Match "needs a Type"
        $problemText | Should -Match "is missing its Data"
        $problemText | Should -Match 'Service entry is missing its Name'
        $problemText | Should -Match 'integer StartupType between 0 and 4'
        $problemText | Should -Match "Service entry 'IgnoreErrors' must be a boolean"
        $problemText | Should -Match "ScheduledTasks entry 'IgnoreErrors' must be a boolean"
        $problemText | Should -Match "Run entry 'Args' must be an array"
        $problemText | Should -Match "AllowedExitCodes.*unique integer exit-code set"
        $problemText | Should -Match "AllowedExitCodes.*only supported for the exact.*dism\.exe"
        $problemText | Should -Match "AllowedExitCodes.*cannot be combined with.*RunAs"
        $problemText | Should -Match "Run entry 'RunAs=User' requires 'Wait = \`$true'"
        $problemText | Should -Match "Run entry 'RunAs=User' cannot ignore"
        $problemText | Should -Match "Run entry 'RunAs' must be exactly 'User'"
        $problemText | Should -Match "RemovePaths entry 'IgnoreErrors' must be a boolean"
        $problemText | Should -Match 'does not exist next to the tweak file'
    }

    It 'reports a file that does not parse as a data file' {
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'broken.psd1'
        Set-Content -Path $tweakFile -Value '@{ Name = "Broken"; Code = (Get-Date) }'

        $problems = @(Test-AtlasTweakSchema -Path $tweakFile)
        @($problems).Count | Should -BeGreaterThan 0
        $problems[0].Problem | Should -Match 'does not load'
    }

    It 'validates a directory recursively and skips the manifest' {
        $tweaksDir = Join-Path -Path $TestDrive -ChildPath 'TweaksDir\sub'
        New-Item -Path $tweaksDir -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path -Path $tweaksDir -ChildPath 'bad.psd1') -Value '@{ Description = "no name" }'
        Set-Content -Path (Join-Path -Path $TestDrive -ChildPath 'TweaksDir\tweaks.manifest.psd1') -Value '@{ Categories = @() }'

        $problems = @(Test-AtlasTweakSchema -Path (Join-Path -Path $TestDrive -ChildPath 'TweaksDir'))
        @($problems).Count | Should -Be 1
        $problems[0].Path | Should -Match 'bad\.psd1$'
    }
}

Describe 'Shipped tweak definitions' {
    BeforeAll {
        $script:shippedTweaksRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Tweaks')).Path
    }

    It 'every shipped tweak passes schema validation' {
        $problems = @(Test-AtlasTweakSchema -Path $script:shippedTweaksRoot)
        $report = @($problems | ForEach-Object { "$($_.Path): $($_.Problem)" }) -join "`n"
        $report | Should -BeNullOrEmpty
    }

}

Describe 'Test-AtlasTweakApplicable' {
    BeforeEach {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock }
        Mock -CommandName Test-AtlasOption -ModuleName Atlas.Tweaks -MockWith { $true }
    }

    It 'applies a tweak with no gates' {
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T' } | Should -BeTrue
    }

    It 'gates on the selected option' {
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Option = 'defender-disable' } | Should -BeTrue

        Mock -CommandName Test-AtlasOption -ModuleName Atlas.Tweaks -MockWith { $false }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Option = 'defender-disable' } | Should -BeFalse
    }

    It 'gates on architecture' {
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Arch = 'X64' } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Arch = 'ARM64' } | Should -BeFalse

        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -IsArm64 $true }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Arch = 'ARM64' } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Arch = 'X64' } | Should -BeFalse
    }

    It 'defaults OnUpgrade to Both, matching legacy YAML semantics' {
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T' } | Should -BeTrue

        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -IsUpgrade $true }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T' } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; OnUpgrade = 'Skip' } | Should -BeFalse
    }

    It 'honors OnUpgrade Only and Both' {
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; OnUpgrade = 'Only' } | Should -BeFalse
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; OnUpgrade = 'Both' } | Should -BeTrue

        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -IsUpgrade $true }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; OnUpgrade = 'Only' } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; OnUpgrade = 'Both' } | Should -BeTrue
    }

    It 'skips Oobe = $false tweaks during OOBE only' {
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Oobe = $false } | Should -BeTrue

        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -IsOobe $true }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Oobe = $false } | Should -BeFalse
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; Oobe = $true } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T' } | Should -BeTrue
    }

    It 'gates on MinBuild inclusively (legacy builds: [>=N])' {
        # Windows 11 22H2 build; a MinBuild = 22000 tweak applies, a MinBuild = 26200 does not.
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 22621 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 22000 } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 26200 } | Should -BeFalse

        # Exactly at the boundary still applies (inclusive).
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 22000 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 22000 } | Should -BeTrue

        # Windows 10 build is below the gate.
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 19045 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 22000 } | Should -BeFalse
    }

    It "maps the end-task 'builds: [>22000]' gate via MinBuild = 22001" {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 22000 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 22001 } | Should -BeFalse

        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 22621 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 22001 } | Should -BeTrue
    }

    It 'gates on MaxBuild inclusively (legacy builds: [<N] / [<=N])' {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 19045 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MaxBuild = 21999 } | Should -BeTrue

        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 22621 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MaxBuild = 21999 } | Should -BeFalse
    }

    It 'does not enforce build gates when the build could not be read (WindowsBuild = 0)' {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock -WindowsBuild 0 }
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MinBuild = 22000 } | Should -BeTrue
        Test-AtlasTweakApplicable -Tweak @{ Name = 'T'; MaxBuild = 19999 } | Should -BeTrue
    }
}

Describe 'Invoke-AtlasTweak' {
    BeforeEach {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock }
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith { New-TestContextMock }
        Mock -CommandName Test-AtlasOption -ModuleName Atlas.Tweaks -MockWith { $true }
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Tweaks
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Registry
    }

    It 'applies a registry-only tweak through the ambient HKCU path when unelevated' {
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'registry-tweak.psd1'
        @'
@{
    Name     = 'Registry Tweak'
    Registry = @(
        @{ Path = 'HKCU:\Software\AtlasRewriteTest\Tweak'; Name = 'Applied'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU:\Software\AtlasRewriteTest\Tweak'; Name = 'ArmOnly'; Type = 'DWord'; Data = 2; Arch = 'ARM64' }
    )
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        $key = Get-Item -Path "$script:testRoot\Tweak"
        $key.GetValue('Applied') | Should -Be 1
        $key.GetValue('ArmOnly', $null) | Should -BeNullOrEmpty
    }

    It 'uses the passed option snapshot without rereading machine install state in the user pass' {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith {
            throw 'The exact-user registry pass must not reread machine install state.'
        }
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith {
            throw 'Atlas.Registry must receive architecture explicitly in the exact-user pass.'
        }
        Mock -CommandName Test-AtlasOption -ModuleName Atlas.Tweaks -MockWith {
            throw 'Option gates must use the injected protected snapshot.'
        }

        $marker = Join-Path -Path $TestDrive -ChildPath 'registry-only-script.txt'
        $companion = Join-Path -Path $TestDrive -ChildPath 'registry-only.ps1'
        "Set-Content -LiteralPath '$marker' -Value 'unexpected'" | Set-Content -Path $companion
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'explicit-context.psd1'
        @'
@{
    Name     = 'Explicit Context Tweak'
    Option   = 'selected-option'
    Registry = @(
        @{ Path = 'HKCU:\Software\AtlasRewriteTest\ExplicitContext'; Name = 'Applied'; Type = 'DWord'; Data = 1 }
    )
    Script   = 'registry-only.ps1'
}
'@ | Set-Content -Path $tweakFile

        $explicitContext = [pscustomobject]@{
            WinDir = 'C:\Windows'; AtlasModulesPath = 'C:\Windows\AtlasModules'
            IsArm64 = $false; WindowsBuild = 26100; IsUpgrade = $false; IsOobe = $false
            IsInstallStateBacked = $true; Options = @('selected-option')
        }
        Invoke-AtlasTweak -Path $tweakFile -RegistryScope CurrentUser `
            -RegistryOnly -Context $explicitContext

        (Get-Item "$script:testRoot\ExplicitContext").GetValue('Applied') | Should -Be 1
        Test-Path -LiteralPath $marker | Should -BeFalse
        Should -Invoke Get-AtlasContext -ModuleName Atlas.Tweaks -Times 0 -Exactly
        Should -Invoke Get-AtlasContext -ModuleName Atlas.Registry -Times 0 -Exactly
        Should -Invoke Test-AtlasOption -ModuleName Atlas.Tweaks -Times 0 -Exactly
    }

    It 'runs a RunAs=User companion script via Invoke-AtlasAsUser instead of in-process' {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith {
            New-TestContextMock -IsInstallStateBacked $true
        }
        Mock -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -MockWith { 0 }
        $companion = Join-Path -Path $TestDrive -ChildPath 'runas.ps1'
        'New-Item -Path (Join-Path $env:TEMP "atlas-runas-should-not-exist.txt") -Force | Out-Null' | Set-Content -Path $companion
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'runas-tweak.psd1'
        @'
@{
    Name   = 'RunAs Tweak'
    Oobe   = $false
    RunAs  = 'User'
    Script = 'runas.ps1'
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        # The engine must delegate to Invoke-AtlasAsUser (mocked) and NOT dot-source the
        # companion into the current process.
        Should -Invoke -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -Times 1 `
            -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('Elevated') -and
                $Arguments -match '-ExpectedUserSid S-1-5-21-1-2-3-1001$'
            }
        Test-Path (Join-Path $env:TEMP 'atlas-runas-should-not-exist.txt') | Should -BeFalse

        Mock -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -MockWith { 9 }
        { Invoke-AtlasTweak -Path $tweakFile } | Should -Throw '*exited with code 9*'
    }

    It 'runs a companion without RunAs in-process' {
        Mock -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -MockWith { 0 }
        $marker = Join-Path -Path $TestDrive -ChildPath 'inproc.txt'
        $companion = Join-Path -Path $TestDrive -ChildPath 'inproc.ps1'
        "New-Item -Path '$marker' -Force | Out-Null" | Set-Content -Path $companion
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'inproc-tweak.psd1'
        @'
@{
    Name   = 'In-Process Tweak'
    Script = 'inproc.ps1'
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        Should -Invoke -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -Times 0
        Test-Path $marker | Should -BeTrue

        "throw 'companion failure marker'" | Set-Content -Path $companion
        { Invoke-AtlasTweak -Path $tweakFile } | Should -Throw '*companion failure marker*'

        "@{ Name = 'Bad authority'; RunAs = 'UserElevated'; Script = 'inproc.ps1' }" |
            Set-Content -Path $tweakFile
        { Invoke-AtlasTweak -Path $tweakFile } | Should -Throw '*unsupported companion RunAs*'
    }

    It 'expands {windir} independently in exact Run entry argv elements' {
        [AppDomain]::CurrentDomain.SetData('AtlasTweaksExpandedRun', $null)
        Mock -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks -MockWith {
            [AppDomain]::CurrentDomain.SetData('AtlasTweaksExpandedRun', [pscustomobject]@{
                FilePath        = $FilePath
                ArgumentList    = [string[]]$ArgumentList
                AllowedExitCode = [int[]]$AllowedExitCode
            })
        }
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'run-tweak.psd1'
        @'
@{
    Name = 'Run Tweak'
    Run  = @(
        @{ Exe = '{windir}\System32\example.exe'; Args = @('{windir}\path with spaces\', 'embedded"quote', '') }
    )
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        $captured = [AppDomain]::CurrentDomain.GetData('AtlasTweaksExpandedRun')
        $captured.FilePath | Should -Be `
            (Join-Path ([Environment]::GetFolderPath('Windows')) 'System32\example.exe')
        @($captured.ArgumentList) | Should -Be @(
            (Join-Path ([Environment]::GetFolderPath('Windows')) 'path with spaces\')
            'embedded"quote'
            ''
        )
        @($captured.AllowedExitCode) | Should -Be @(0)
    }

    It 'passes the narrowly declared reboot-required exit contract only to DISM' {
        Mock -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'dism-exit-contract.psd1'
        @'
@{
    Name = 'DISM exit contract'
    Run = @(
        @{ Exe = '{windir}\System32\dism.exe'; Args = @('/Online'); AllowedExitCodes = @(0, 3010) }
    )
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        Should -Invoke -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks `
            -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq 'C:\Windows\System32\dism.exe' -and
                @($AllowedExitCode).Count -eq 2 -and
                $AllowedExitCode -contains 0 -and
                $AllowedExitCode -contains 3010
            }

        $wrongExeFile = Join-Path -Path $TestDrive -ChildPath 'wrong-exe-exit-contract.psd1'
        "@{ Name = 'Wrong executable'; Run = @( @{ Exe = 'C:\Windows\System32\whoami.exe'; AllowedExitCodes = @(0, 3010) } ) }" |
            Set-Content -Path $wrongExeFile
        { Invoke-AtlasTweak -Path $wrongExeFile } |
            Should -Throw '*AllowedExitCodes is restricted*'
    }

    It 'runs a User-scoped entry through the exact-user launcher and never ignores its failure' {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith {
            New-TestContextMock -IsInstallStateBacked $true
        }
        Mock -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -MockWith { 0 }
        Mock -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'user-run-tweak.psd1'
        @'
@{
    Name = 'User Run Tweak'
    Run = @(
        @{ Exe = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'; Args = @('-File', 'C:\Windows\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1', '-DebloatDefaults'); Wait = $true; RunAs = 'User'; IgnoreErrors = $true }
    )
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        Should -Invoke -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -Times 1 -Exactly `
            -ParameterFilter {
                $FilePath -eq 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -and
                $Arguments -eq '-File C:\Windows\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1 -DebloatDefaults -ExpectedUserSid S-1-5-21-1-2-3-1001'
            }
        Should -Invoke -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks -Times 0

        Mock -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -MockWith { 5 }
        { Invoke-AtlasTweak -Path $tweakFile } | Should -Throw '*exited with code 5*'
    }

    It 'propagates a required machine Run failure by default' {
        Mock -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks -MockWith {
            throw "'C:\Windows\System32\failure.exe' exited with disallowed code 17."
        }
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'failed-machine-run.psd1'
        @'
@{
    Name = 'Failed Machine Run'
    Run = @(
        @{ Exe = 'C:\Windows\System32\failure.exe'; Wait = $true }
    )
}
'@ | Set-Content -Path $tweakFile

        { Invoke-AtlasTweak -Path $tweakFile } |
            Should -Throw '*disallowed code 17*'
    }

    It 'retains explicit IgnoreErrors for a reviewed optional machine Run' {
        Mock -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks -MockWith {
            throw "'C:\Windows\System32\optional.exe' exited with disallowed code 17."
        }
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'optional-machine-run.psd1'
        @'
@{
    Name = 'Optional Machine Run'
    Run = @(
        @{ Exe = 'C:\Windows\System32\optional.exe'; Wait = $true; IgnoreErrors = $true }
    )
}
'@ | Set-Content -Path $tweakFile

        { Invoke-AtlasTweak -Path $tweakFile } | Should -Not -Throw
        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Tweaks -Times 1 -Exactly `
            -ParameterFilter {
                $Level -eq 'Warning' -and
                $Message -like "Ignored Run entry failure (executable: 'C:\Windows\System32\optional.exe'):*disallowed code 17*"
            }
    }

    It 'uses exact System32 schtasks and propagates its checked failure' {
        Mock -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks -MockWith {
            throw "'C:\Windows\System32\schtasks.exe' exited with disallowed code 5."
        }
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'failed-scheduled-task.psd1'
        @'
@{
    Name = 'Failed Scheduled Task'
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Test\RequiredTask' }
    )
}
'@ | Set-Content -Path $tweakFile

        { Invoke-AtlasTweak -Path $tweakFile } |
            Should -Throw '*schtasks.exe*disallowed code 5*'
        Should -Invoke -CommandName Invoke-AtlasHiddenProcess -ModuleName Atlas.Tweaks `
            -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq 'C:\Windows\System32\schtasks.exe' -and
                $ArgumentList[0] -eq '/Change'
            }
    }

    It 'bounds RemovePaths to the Windows directory and propagates required removal failures' {
        $targetPath = Join-Path -Path $TestDrive -ChildPath 'protected-removal'
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
        Mock -CommandName Remove-Item -ModuleName Atlas.Tweaks -MockWith {
            throw 'path access denied'
        } -ParameterFilter { $LiteralPath -eq $targetPath }
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'failed-removal.psd1'
        @'
@{
    Name = 'Failed RemovePaths'
    RemovePaths = @(
        @{ Path = '{windir}\protected-removal' }
    )
}
'@ | Set-Content -Path $tweakFile

        $context = New-TestContextMock
        $context.WinDir = $TestDrive
        { Invoke-AtlasTweak -Path $tweakFile -Context $context } |
            Should -Throw '*path access denied*'

        $outsideTweak = Join-Path -Path $TestDrive -ChildPath 'outside-removal.psd1'
        @'
@{
    Name = 'Outside RemovePaths'
    RemovePaths = @(
        @{ Path = '{windir}\..\outside' }
    )
}
'@ | Set-Content -Path $outsideTweak

        { Invoke-AtlasTweak -Path $outsideTweak -Context $context } |
            Should -Throw '*resolves outside the Windows directory*'
    }

    It 'skips a tweak whose option is not selected' {
        Mock -CommandName Test-AtlasOption -ModuleName Atlas.Tweaks -MockWith { $false }

        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'gated-tweak.psd1'
        @'
@{
    Name     = 'Gated Tweak'
    Option   = 'defender-disable'
    Registry = @(
        @{ Path = 'HKCU:\Software\AtlasRewriteTest\Gated'; Name = 'Applied'; Type = 'DWord'; Data = 1 }
    )
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        Test-Path -Path "$script:testRoot\Gated" | Should -BeFalse
        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Tweaks -Times 1 -Exactly -ParameterFilter { $Message -like "Skipping tweak 'Gated Tweak'*" }
    }

    It 'throws on a missing tweak file' {
        { Invoke-AtlasTweak -Path (Join-Path -Path $TestDrive -ChildPath 'missing.psd1') } | Should -Throw '*not found*'
    }

    It 'throws on a tweak without a Name' {
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'nameless.psd1'
        Set-Content -Path $tweakFile -Value '@{ Description = "nameless" }'
        { Invoke-AtlasTweak -Path $tweakFile } | Should -Throw "*no 'Name' key*"
    }
}

Describe 'Get-AtlasTweakManifest and Invoke-AtlasTweakCategory' {
    BeforeEach {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Tweaks -MockWith { New-TestContextMock }
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith { New-TestContextMock }
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Tweaks
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Registry

        $script:tweaksRoot = Join-Path -Path $TestDrive -ChildPath 'Tweaks'
        $categoryDir = Join-Path -Path $script:tweaksRoot -ChildPath 'testing\sub'
        New-Item -Path $categoryDir -ItemType Directory -Force | Out-Null

        @'
@{
    Categories = @(
        @{
            Name   = 'testing'
            Tweaks = @(
                'first-tweak'
                'sub/second-tweak'
                'missing-tweak'
            )
        }
    )
}
'@ | Set-Content -Path (Join-Path -Path $script:tweaksRoot -ChildPath 'tweaks.manifest.psd1')

        @'
@{
    Name     = 'First Tweak'
    Registry = @(
        @{ Path = 'HKCU:\Software\AtlasRewriteTest\Category'; Name = 'First'; Type = 'DWord'; Data = 1 }
    )
}
'@ | Set-Content -Path (Join-Path -Path $script:tweaksRoot -ChildPath 'testing\first-tweak.psd1')

        @'
@{
    Name     = 'Second Tweak'
    Registry = @(
        @{ Path = 'HKCU:\Software\AtlasRewriteTest\Category'; Name = 'Second'; Type = 'DWord'; Data = 2 }
    )
}
'@ | Set-Content -Path (Join-Path -Path $script:tweaksRoot -ChildPath 'testing\sub\second-tweak.psd1')
    }

    It 'loads the manifest and validates its shape' {
        $manifest = Get-AtlasTweakManifest -Path (Join-Path -Path $script:tweaksRoot -ChildPath 'tweaks.manifest.psd1')
        @($manifest.Categories).Count | Should -Be 1
        @($manifest.Categories)[0].Name | Should -Be 'testing'
    }

    It 'resolves only applicable post-user-registry refreshes in declaration order without duplicates' {
        @'
@{
    Categories = @(
        @{
            Name = 'testing'
            Tweaks = @('first-tweak', 'sub/second-tweak', 'third-tweak')
        }
    )
}
'@ | Set-Content -Path (Join-Path $script:tweaksRoot 'tweaks.manifest.psd1')

        '@{ Name = ''First''; Oobe = $false; PostUserRegistryRefresh = ''ExplorerRefresh'' }' |
            Set-Content -Path (Join-Path $script:tweaksRoot 'testing\first-tweak.psd1')
        '@{ Name = ''Upgrade''; Oobe = $false; OnUpgrade = ''Only''; PostUserRegistryRefresh = ''SearchShellRefresh'' }' |
            Set-Content -Path (Join-Path $script:tweaksRoot 'testing\sub\second-tweak.psd1')
        '@{ Name = ''Duplicate''; Oobe = $false; PostUserRegistryRefresh = ''ExplorerRefresh'' }' |
            Set-Content -Path (Join-Path $script:tweaksRoot 'testing\third-tweak.psd1')

        $fresh = @(Get-AtlasTweakCategoryPostUserRegistryRefresh -Name testing `
                -TweaksRoot $script:tweaksRoot -Context (New-TestContextMock))
        $upgrade = @(Get-AtlasTweakCategoryPostUserRegistryRefresh -Name testing `
                -TweaksRoot $script:tweaksRoot -Context (New-TestContextMock -IsUpgrade $true))

        $fresh | Should -Be @('ExplorerRefresh')
        $upgrade | Should -Be @('ExplorerRefresh', 'SearchShellRefresh')
    }

    It 'throws on a missing manifest' {
        { Get-AtlasTweakManifest -Path (Join-Path -Path $TestDrive -ChildPath 'nope.psd1') } | Should -Throw '*not found*'
    }

    It 'applies a category in order and fails when a manifest-listed tweak is missing' {
        { Invoke-AtlasTweakCategory -Name 'testing' -TweaksRoot $script:tweaksRoot } |
            Should -Throw '*Tweak file not found*missing-tweak.psd1*'

        $key = Get-Item -Path "$script:testRoot\Category"
        $key.GetValue('First') | Should -Be 1
        $key.GetValue('Second') | Should -Be 2
    }

    It 'throws on an unknown category' {
        { Invoke-AtlasTweakCategory -Name 'nope' -TweaksRoot $script:tweaksRoot } | Should -Throw '*not defined*'
    }

}

Describe 'Invoke-RevertPhase optional theme refresh' {
    It 'warns and continues when the upgrade-only theme tweak fails' {
        Mock -CommandName Assert-AtlasPrivilege
        Mock -CommandName Import-Module
        Mock -CommandName Get-AtlasContext -MockWith {
            [pscustomobject]@{
                IsUpgrade       = $true
                AtlasModulesPath = $TestDrive
            }
        }
        Mock -CommandName Test-Path -MockWith { $false }
        Mock -CommandName Invoke-AtlasTweak -MockWith { throw 'theme failure marker' }
        Mock -CommandName Write-AtlasLog

        $phase = Join-Path -Path $PSScriptRoot -ChildPath `
            '..\playbook\Executables\AtlasModules\Scripts\Phases\Invoke-RevertPhase.ps1'
        { . $phase } | Should -Not -Throw

        Should -Invoke -CommandName Invoke-AtlasTweak -Times 1 -Exactly
        Should -Invoke -CommandName Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and
            $Message -like '*optional upgrade theme policy*theme failure marker*'
        }
    }
}
