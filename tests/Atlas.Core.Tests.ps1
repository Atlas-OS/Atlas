BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    & (Get-Module -Name Atlas.Core) { Initialize-AtlasRunAsUserType }
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

    It 'keeps waiting bounded for existing callers that omit the timeout' {
        $command = Get-Command -Name Invoke-AtlasAsUser
        $timeoutParameter = $command.ScriptBlock.Ast.Body.ParamBlock.Parameters |
            Where-Object { $_.Name.VariablePath.UserPath -eq 'TimeoutSeconds' }

        $timeoutParameter | Should -Not -BeNullOrEmpty
        $timeoutParameter.DefaultValue.SafeGetValue() | Should -Be 900
    }
}

Describe 'Atlas.UserProcess native interop contract' {
    It 'uses the Unicode STARTUPINFO layout and CreateProcessAsUserW entry point' {
        $nestedTypeFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public
        $nativeMethodFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static
        $startupInfoType = [Atlas.UserProcess].GetNestedType('STARTUPINFO', $nestedTypeFlags)
        $startupInfoType | Should -Not -BeNullOrEmpty
        $startupInfoType.StructLayoutAttribute.CharSet |
            Should -Be ([System.Runtime.InteropServices.CharSet]::Unicode)

        $createProcessMethod = [Atlas.UserProcess].GetMethod('CreateProcessAsUser', $nativeMethodFlags)
        $dllImport = $createProcessMethod.GetCustomAttributes([System.Runtime.InteropServices.DllImportAttribute], $false)[0]
        $dllImport.EntryPoint | Should -BeExactly 'CreateProcessAsUserW'
        $dllImport.CharSet | Should -Be ([System.Runtime.InteropServices.CharSet]::Unicode)
    }

    It 'marshals TOKEN_LINKED_TOKEN as a structure containing an owned handle' {
        $nestedTypeFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public
        $nativeMethodFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static
        $linkedTokenType = [Atlas.UserProcess].GetNestedType('TOKEN_LINKED_TOKEN', $nestedTypeFlags)
        $linkedTokenType | Should -Not -BeNullOrEmpty
        $linkedTokenType.GetField('LinkedToken').FieldType | Should -Be ([IntPtr])

        $getTokenInformation = [Atlas.UserProcess].GetMethod('GetTokenInformation', $nativeMethodFlags)
        $bufferParameter = $getTokenInformation.GetParameters()[2].ParameterType
        $bufferParameter.IsByRef | Should -BeTrue
        $bufferParameter.GetElementType() | Should -Be $linkedTokenType

        $runAsUserSource = Get-Content -LiteralPath (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Domain\RunAsUser.ps1') -Raw
        $runAsUserSource | Should -Not -Match 'Marshal\.(ReadIntPtr|FreeHGlobal)\(info\)'
    }

    It 'fails closed when an elevated linked token is unavailable' {
        $runAsUserSource = Get-Content -LiteralPath (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Domain\RunAsUser.ps1') -Raw
        $runAsUserSource | Should -Match '(?s)if \(!GetTokenInformation\(.+?\)\)\s*\{.+?throw new Win32Exception'
        $runAsUserSource | Should -Match '(?s)if \(linkedToken == IntPtr\.Zero\)\s*\{.+?throw new InvalidOperationException'
    }

    It 'treats failure to create the interactive user environment as fatal' {
        $runAsUserSource = Get-Content -LiteralPath (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Domain\RunAsUser.ps1') -Raw
        $runAsUserSource | Should -Match '(?s)if \(!CreateEnvironmentBlock\(.+?\)\)\s*\{.+?throw new Win32Exception'
        $runAsUserSource | Should -Not -Match 'non-fatal; fall back to no explicit environment'
    }

    It 'checks bounded process waiting and exit-code retrieval failures' {
        $runAsUserSource = Get-Content -LiteralPath (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Domain\RunAsUser.ps1') -Raw
        $runAsUserSource | Should -Not -Match 'WaitForSingleObject\(pi\.hProcess, INFINITE\)'
        $runAsUserSource | Should -Match 'WaitForSingleObject\(pi\.hProcess, timeoutMilliseconds\)'
        $runAsUserSource | Should -Match '(?s)WAIT_TIMEOUT.+?throw new TimeoutException'
        $runAsUserSource | Should -Match '(?s)WAIT_FAILED.+?throw new Win32Exception'
        $runAsUserSource | Should -Match '(?s)if \(!GetExitCodeProcess\(.+?\)\)\s*\{.+?throw new Win32Exception'
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
