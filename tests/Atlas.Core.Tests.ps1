BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
}

Describe 'Get-AtlasUserProcessCommandLine' {
    It 'quotes a path with spaces and adds nothing else when there are no arguments' {
        Get-AtlasUserProcessCommandLine -FilePath 'C:\Program Files\x.exe' |
            Should -BeExactly '"C:\Program Files\x.exe"'
    }

    It 'appends the raw argument string after a single separating space' {
        Get-AtlasUserProcessCommandLine -FilePath 'C:\x.exe' -Arguments '-Flag "va lue"' |
            Should -BeExactly '"C:\x.exe" -Flag "va lue"'
    }

    It 'emits no trailing space when the argument string is empty' {
        Get-AtlasUserProcessCommandLine -FilePath 'C:\x.exe' -Arguments '' |
            Should -BeExactly '"C:\x.exe"'
    }
}

Describe 'Invoke-AtlasAsUser' {
    # Mocks only - the token/CreateProcessAsUser machinery is VM-only by design and must
    # never launch anything from the test suite.
    It 'throws when the caller is not SYSTEM/TrustedInstaller' {
        Mock Test-AtlasTrustedInstaller { $false } -ModuleName Atlas.Core

        { Invoke-AtlasAsUser -FilePath 'C:\Windows\System32\cmd.exe' } |
            Should -Throw -ExpectedMessage '*must run as SYSTEM/TrustedInstaller*'
    }

    It 'documents that it returns the child process exit code' {
        # Callers (e.g. Atlas.Tweaks) treat a nonzero return as failure; pin the
        # documented contract textually since OutputType is not enforced in PS.
        (Get-Help Invoke-AtlasAsUser).Synopsis | Should -Match 'exit code'
    }
}

Describe 'Invoke-AtlasTrustedInstaller' {
    # The successful-relaunch branch invokes "$env:ComSpec" via the call operator; it is
    # deliberately left untested rather than mocking the call operator.
    It 'returns $false without relaunching when already running as TrustedInstaller' {
        Mock Test-AtlasTrustedInstaller { $true } -ModuleName Atlas.Core

        Invoke-AtlasTrustedInstaller -CommandLine 'echo test' | Should -BeFalse
    }

    It 'throws when RunAsTI.cmd is missing' {
        Mock Test-AtlasTrustedInstaller { $false } -ModuleName Atlas.Core
        Mock Get-AtlasContext { @{ AtlasModulesPath = "$TestDrive\AtlasModules" } } -ModuleName Atlas.Core

        { Invoke-AtlasTrustedInstaller -CommandLine 'echo test' } |
            Should -Throw -ExpectedMessage '*RunAsTI.cmd not found*'
    }
}
