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
            [int]$WindowsBuild = 26100
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
    Services       = @(
        @{ Name = 'TestSvc'; StartupType = 4 }
        @{ Name = 'TestSvc'; Operation = 'Stop' }
    )
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Test\Task'; Operation = 'Disable' }
    )
    StopProcesses  = @('test*')
    Run            = @(
        @{ Exe = 'cmd.exe'; Args = '/c exit 0'; Wait = $true; IgnoreErrors = $false }
    )
    RemovePaths    = @(
        @{ Path = '{windir}\Test'; Arch = 'X64' }
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
    MinBuild    = 'notanumber'
    Bogus       = $true
    Registry    = @(
        @{ Name = 'MissingPath'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Test'; Name = 'BadType'; Type = 'SuperString' }
        @{ Path = 'HKLM:\SOFTWARE\Test'; Name = 'NoData'; Type = 'DWord' }
    )
    Services    = @(
        @{ StartupType = 9 }
    )
    Run         = @(
        @{ Args = '/c exit 0' }
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
        $problemText | Should -Match 'Registry entry is missing its Path'
        $problemText | Should -Match "needs a Type"
        $problemText | Should -Match "is missing its Data"
        $problemText | Should -Match 'Service entry is missing its Name'
        $problemText | Should -Match 'integer StartupType between 0 and 4'
        $problemText | Should -Match 'Run entry is missing its Exe'
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

    It 'runs a RunAs=User companion script via Invoke-AtlasAsUser instead of in-process' {
        Mock -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -MockWith { 0 }
        $companion = Join-Path -Path $TestDrive -ChildPath 'runas.ps1'
        'New-Item -Path (Join-Path $env:TEMP "atlas-runas-should-not-exist.txt") -Force | Out-Null' | Set-Content -Path $companion
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'runas-tweak.psd1'
        @'
@{
    Name   = 'RunAs Tweak'
    RunAs  = 'User'
    Script = 'runas.ps1'
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        # The engine must delegate to Invoke-AtlasAsUser (mocked) and NOT dot-source the
        # companion into the current process.
        Should -Invoke -CommandName Invoke-AtlasAsUser -ModuleName Atlas.Tweaks -Times 1
        Test-Path (Join-Path $env:TEMP 'atlas-runas-should-not-exist.txt') | Should -BeFalse
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
    }

    It 'expands {windir} in Run entry Exe and Args' {
        $marker = Join-Path -Path $TestDrive -ChildPath 'windir-out.txt'
        $tweakFile = Join-Path -Path $TestDrive -ChildPath 'run-tweak.psd1'
        @"
@{
    Name = 'Run Tweak'
    Run  = @(
        @{ Exe = 'cmd.exe'; Args = '/c echo {windir}> "$marker"' }
    )
}
"@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile

        Test-Path $marker | Should -BeTrue
        (Get-Content $marker -Raw).Trim() | Should -Be ([Environment]::GetFolderPath('Windows'))
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

    It 'runs the companion script after the other keys' {
        $tweakDir = Join-Path -Path $TestDrive -ChildPath 'WithScript'
        New-Item -Path $tweakDir -ItemType Directory -Force | Out-Null

        $marker = Join-Path -Path $TestDrive -ChildPath 'script-ran.txt'
        Set-Content -Path (Join-Path -Path $tweakDir -ChildPath 'companion.ps1') -Value "Set-Content -Path '$marker' -Value 'ran'"

        $tweakFile = Join-Path -Path $tweakDir -ChildPath 'script-tweak.psd1'
        @'
@{
    Name   = 'Script Tweak'
    Script = 'companion.ps1'
}
'@ | Set-Content -Path $tweakFile

        Invoke-AtlasTweak -Path $tweakFile
        Test-Path -Path $marker | Should -BeTrue
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

    It 'throws on a missing manifest' {
        { Get-AtlasTweakManifest -Path (Join-Path -Path $TestDrive -ChildPath 'nope.psd1') } | Should -Throw '*not found*'
    }

    It 'applies every tweak in the category and logs missing files as errors' {
        Invoke-AtlasTweakCategory -Name 'testing' -TweaksRoot $script:tweaksRoot

        $key = Get-Item -Path "$script:testRoot\Category"
        $key.GetValue('First') | Should -Be 1
        $key.GetValue('Second') | Should -Be 2

        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Tweaks -Times 1 -Exactly -ParameterFilter { $Level -eq 'Error' -and $Message -like '*missing-tweak*' }
    }

    It 'throws on an unknown category' {
        { Invoke-AtlasTweakCategory -Name 'nope' -TweaksRoot $script:tweaksRoot } | Should -Throw '*not defined*'
    }
}
