BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    $coreManifest = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1'
    Import-Module -Name $coreManifest -Force -ErrorAction Stop

    $fixtureDirectory = Join-Path -Path $TestDrive -ChildPath 'process fixtures with spaces'
    New-Item -Path $fixtureDirectory -ItemType Directory -Force | Out-Null

    $frameworkRoot = Join-Path -Path ([Environment]::GetFolderPath('Windows')) `
        -ChildPath 'Microsoft.NET\Framework64\v4.0.30319'
    if (-not (Test-Path -LiteralPath $frameworkRoot -PathType Container)) {
        $frameworkRoot = Join-Path -Path ([Environment]::GetFolderPath('Windows')) `
            -ChildPath 'Microsoft.NET\Framework\v4.0.30319'
    }
    $compiler = Join-Path -Path $frameworkRoot -ChildPath 'csc.exe'
    $script:ArgvProbe = Join-Path -Path $fixtureDirectory -ChildPath 'Atlas.ArgvProbe.exe'
    $fixtureSource = Join-Path -Path $fixtureDirectory -ChildPath 'Atlas.ArgvProbe.cs'
    @'
using System;
using System.Globalization;
using System.Text;

internal static class AtlasArgvProbe {
    public static int Main(string[] arguments) {
        foreach (string argument in arguments) {
            Console.WriteLine(
                argument.Length.ToString(CultureInfo.InvariantCulture) + ":" +
                Convert.ToBase64String(Encoding.Unicode.GetBytes(argument)));
        }
        return 0;
    }
}
'@ | Set-Content -LiteralPath $fixtureSource -Encoding UTF8
    $compilerOutput = & $compiler /nologo /target:exe "/out:$($script:ArgvProbe)" `
        $fixtureSource 2>&1
    if ($LASTEXITCODE -ne 0 -or -not [IO.File]::Exists($script:ArgvProbe)) {
        throw "Could not compile the argv probe: $($compilerOutput -join ' ')"
    }

    $script:HostExecutable = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $script:FailureFixture = Join-Path -Path $fixtureDirectory -ChildPath 'failure.ps1'
    @'
[Console]::Out.Write('fixture stdout')
[Console]::Error.Write('fixture stderr')
exit 17
'@ | Set-Content -LiteralPath $script:FailureFixture -Encoding UTF8
    $script:FailureArguments = [string[]]@(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', $script:FailureFixture
    )
}

Describe 'ConvertTo-AtlasWindowsArgumentString' {
    It 'serializes empty, spaced, quoted, and trailing-backslash arguments' {
        $cases = @(
            @{ Input = [string[]]@(); Expected = '' }
            @{ Input = [string[]]@('plain'); Expected = 'plain' }
            @{ Input = [string[]]@(''); Expected = '""' }
            @{ Input = [string[]]@('with spaces'); Expected = '"with spaces"' }
            @{ Input = [string[]]@('embedded"quote'); Expected = '"embedded\"quote"' }
            @{ Input = [string[]]@('space and slash\'); Expected = '"space and slash\\"' }
        )

        foreach ($case in $cases) {
            ConvertTo-AtlasWindowsArgumentString -ArgumentList $case.Input |
                Should -BeExactly $case.Expected
        }
    }

    It 'rejects null, non-string, NUL, and oversized arguments' {
        { ConvertTo-AtlasWindowsArgumentString `
                -ArgumentList ([object[]]@('left', $null)) } |
            Should -Throw
        { ConvertTo-AtlasWindowsArgumentString `
                -ArgumentList ([object[]]@('left', 7)) } |
            Should -Throw '*must be a string*'
        { ConvertTo-AtlasWindowsArgumentString -ArgumentList @("left$([char]0)right") } |
            Should -Throw '*cannot contain NUL*'
        { ConvertTo-AtlasWindowsArgumentString -ArgumentList @(('x' * 32767)) } |
            Should -Throw '*exceeds 32,766*'
    }

    It 'round-trips Windows quoting edge cases through a real native child' {
        $expected = [string[]]@(
            'plain'
            'with spaces'
            ''
            'embedded"quote'
            'trailing\'
            'slashes before quote \"tail'
            "tab`tvalue"
        )

        $result = Invoke-AtlasHiddenProcess -FilePath $script:ArgvProbe `
            -ArgumentList $expected -Wait -CaptureOutput
        $actual = [string[]]@(
            foreach ($line in @($result.StandardOutput -split '\r?\n' |
                    Where-Object { $_ })) {
                $parts = $line.Split([char[]]@(':'), 2)
                [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($parts[1]))
            }
        )

        $result.ExitCode | Should -Be 0
        $result.StandardError | Should -BeNullOrEmpty
        $actual | Should -Be $expected
    }
}

Describe 'Invoke-AtlasHiddenProcess' {
    It 'requires an explicit existing executable and a waited launch' {
        { Invoke-AtlasHiddenProcess -FilePath 'powershell.exe' -Wait } |
            Should -Throw '*explicit absolute executable path*'
        { Invoke-AtlasHiddenProcess -FilePath (Join-Path $TestDrive 'missing.exe') -Wait } |
            Should -Throw '*does not exist or is not a file*'
        { Invoke-AtlasHiddenProcess -FilePath $script:HostExecutable -Wait:$false } |
            Should -Throw '*only waited launches*'
    }

    It 'returns captured output for an explicitly allowed nonzero exit code' {
        $result = Invoke-AtlasHiddenProcess -FilePath $script:HostExecutable `
            -ArgumentList $script:FailureArguments -Wait -CaptureOutput `
            -AllowedExitCode @(0, 17)

        $result.ExitCode | Should -Be 17
        $result.StandardOutput | Should -BeExactly 'fixture stdout'
        $result.StandardError | Should -BeExactly 'fixture stderr'
    }

    It 'does not expose output when capture was not requested' {
        $result = Invoke-AtlasHiddenProcess -FilePath $script:ArgvProbe `
            -ArgumentList @('value') -Wait

        $result.ExitCode | Should -Be 0
        $result.StandardOutput | Should -BeNullOrEmpty
        $result.StandardError | Should -BeNullOrEmpty
    }

    It 'throws with child diagnostics for a disallowed exit code' {
        { Invoke-AtlasHiddenProcess -FilePath $script:HostExecutable `
                -ArgumentList $script:FailureArguments -Wait -CaptureOutput } |
            Should -Throw '*disallowed code 17*fixture stdout*fixture stderr*'
    }
}
