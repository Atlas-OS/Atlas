BeforeAll {
    $script:protocolPath = Join-Path -Path $PSScriptRoot -ChildPath `
        '..\playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Domain\ElevationProtocol.ps1'
    . $script:protocolPath

    $script:requestId = '11111111222233334444555555555555'
    $script:requesterSid = 'S-1-5-21-100-200-300-1001'
    $script:requesterProcessId = 4242
    $script:requesterCreationFileTime = [Convert]::ToInt64('01DB000000000000', 16)
    $script:utf8 = New-Object Text.UTF8Encoding($false, $true)
    $script:unicodeInput = ([char]0x5165).ToString() + [char]0x529B
    $script:unicodeArgument = $script:unicodeInput + '-' + [char]0x0394

    function New-TestElevationDocument {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'This test helper only returns an in-memory protocol document.'
        )]
        param(
            [string]$Operation = 'Toggle',
            $OperationData
        )

        if ($null -eq $OperationData) {
            $OperationData = [ordered]@{
                name              = 'Indexing'
                state             = 'Disable'
                silent            = $true
                justContext       = $false
                noExplorerRestart = $true
            }
        }

        return New-AtlasElevationRequestDocument -Operation $Operation -OperationData $OperationData `
            -RequesterSid $script:requesterSid -RequesterProcessId $script:requesterProcessId `
            -RequesterCreationFileTime $script:requesterCreationFileTime -RequesterSessionId 7 `
            -TimeoutMilliseconds 900000 `
            -RequestId $script:requestId
    }

    function ConvertTo-TestRequestBytes {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseSingularNouns',
            '',
            Justification = 'Bytes is the established protocol term for the test byte sequence.'
        )]
        param([string]$Json)

        return ,([byte[]]$script:utf8.GetBytes($Json))
    }

    if (-not ('AtlasElevationProtocolArgvTest' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class AtlasElevationProtocolArgvTest
{
    [DllImport("shell32.dll", EntryPoint = "CommandLineToArgvW", ExactSpelling = true,
        CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CommandLineToArgvW(
        [MarshalAs(UnmanagedType.LPWStr)] string commandLine,
        out int argumentCount);

    [DllImport("kernel32.dll", EntryPoint = "LocalFree", ExactSpelling = true,
        SetLastError = true)]
    private static extern IntPtr LocalFree(IntPtr memory);

    public static string[] Parse(string commandLine)
    {
        int count;
        IntPtr values = CommandLineToArgvW(commandLine, out count);
        if (values == IntPtr.Zero)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        try
        {
            string[] result = new string[count];
            for (int index = 0; index < count; index++)
            {
                IntPtr value = Marshal.ReadIntPtr(values, index * IntPtr.Size);
                result[index] = Marshal.PtrToStringUni(value);
            }
            return result;
        }
        finally
        {
            LocalFree(values);
        }
    }
}
'@
    }
}

Describe 'Atlas elevation canonical request protocol' {
    It 'pins exact v2 canonical JSON and uppercase SHA-256 for every closed operation' {
        $cases = @(
            @{
                Operation = 'Toggle'
                Data = [ordered]@{
                    name              = 'Indexing'
                    state             = 'Disable'
                    silent            = $true
                    justContext       = $false
                    noExplorerRestart = $true
                }
                Json = '{"protocolVersion":2,"requestId":"11111111222233334444555555555555","requesterSid":"S-1-5-21-100-200-300-1001","requesterProcessId":4242,"requesterCreationFileTime":"01DB000000000000","requesterSessionId":7,"operation":"Toggle","operationData":{"name":"Indexing","state":"Disable","silent":true,"justContext":false,"noExplorerRestart":true},"timeoutMilliseconds":900000,"windowMode":"NonInteractive"}'
            },
            @{
                Operation = 'ResetServices'
                Data = [ordered]@{ restoreSource = 'ToggleDefaults' }
                Json = '{"protocolVersion":2,"requestId":"11111111222233334444555555555555","requesterSid":"S-1-5-21-100-200-300-1001","requesterProcessId":4242,"requesterCreationFileTime":"01DB000000000000","requesterSessionId":7,"operation":"ResetServices","operationData":{"restoreSource":"ToggleDefaults"},"timeoutMilliseconds":900000,"windowMode":"NonInteractive"}'
            },
            @{
                Operation = 'SafeModeRecovery'
                Data = [ordered]@{ operationId = '1234567890abcdef1234567890abcdef' }
                Json = '{"protocolVersion":2,"requestId":"11111111222233334444555555555555","requesterSid":"S-1-5-21-100-200-300-1001","requesterProcessId":4242,"requesterCreationFileTime":"01DB000000000000","requesterSessionId":7,"operation":"SafeModeRecovery","operationData":{"operationId":"1234567890abcdef1234567890abcdef"},"timeoutMilliseconds":900000,"windowMode":"NonInteractive"}'
            }
        )

        foreach ($case in $cases) {
            $document = New-TestElevationDocument -Operation $case.Operation -OperationData $case.Data
            $bytes = ConvertTo-AtlasElevationRequestBytes -Request $document
            $hash = Get-AtlasElevationSha256 -Bytes $bytes

            $bytes.GetType().FullName | Should -BeExactly 'System.Byte[]'
            $script:utf8.GetString($bytes) | Should -BeExactly $case.Json
            $hash | Should -Match '^[0-9A-F]{64}$'

            $imported = ConvertFrom-AtlasElevationRequestBytes -Bytes $bytes `
                -ExpectedRequestId $script:requestId -ExpectedSha256 $hash
            $imported.operation | Should -BeExactly $case.Operation
        }
    }

    It 'emits strict UTF-8 without a BOM and preserves Unicode as UTF-8 rather than JSON escapes' {
        $json = ConvertTo-AtlasCanonicalJsonString -Value $script:unicodeInput
        $bytes = [byte[]]$script:utf8.GetBytes($json)

        $bytes.GetType().FullName | Should -BeExactly 'System.Byte[]'
        @($bytes[0..2]) -join ',' | Should -Not -BeExactly '239,187,191'
        $script:utf8.GetString($bytes) | Should -BeExactly $json
        $json | Should -Match ([regex]::Escape($script:unicodeInput))
        $json | Should -Not -Match '\\u5165|\\u529b'
    }

    It 'is stable under a non-English process culture' {
        $originalCulture = [Globalization.CultureInfo]::CurrentCulture
        $originalUiCulture = [Globalization.CultureInfo]::CurrentUICulture
        try {
            $baselineBytes = ConvertTo-AtlasElevationRequestBytes -Request (New-TestElevationDocument)
            $baselineHash = Get-AtlasElevationSha256 -Bytes $baselineBytes
            [Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('fr-FR')
            [Globalization.CultureInfo]::CurrentUICulture = [Globalization.CultureInfo]::GetCultureInfo('fr-FR')
            $localizedBytes = ConvertTo-AtlasElevationRequestBytes -Request (New-TestElevationDocument)
            $localizedHash = Get-AtlasElevationSha256 -Bytes $localizedBytes

            $localizedBytes | Should -Be $baselineBytes
            $localizedHash | Should -BeExactly $baselineHash
        }
        finally {
            [Globalization.CultureInfo]::CurrentCulture = $originalCulture
            [Globalization.CultureInfo]::CurrentUICulture = $originalUiCulture
        }
    }

    It 'uses one deterministic JSON escaping form' {
        $value = 'quote" slash\' + [char]8 + [char]9 + [char]10 + [char]12 + [char]13 + [char]1
        ConvertTo-AtlasCanonicalJsonString -Value $value |
            Should -BeExactly '"quote\" slash\\\b\t\n\f\r\u0001"'
    }
}

Describe 'Atlas elevation strict decoding and binding' {
    BeforeAll {
        $script:validRequestBytes = ConvertTo-AtlasElevationRequestBytes -Request (New-TestElevationDocument)
        $script:validRequestHash = Get-AtlasElevationSha256 -Bytes $script:validRequestBytes
        $script:validJson = $script:utf8.GetString($script:validRequestBytes)
    }

    It 'rejects alternate but parseable JSON representations' {
        $reordered = $script:validJson -replace `
            '^\{"protocolVersion":2,"requestId":"([^"]+)"',
            '{"requestId":"$1","protocolVersion":2'
        $variants = @(
            $script:validJson.Replace(',', ', '),
            $reordered,
            $script:validJson.Replace('{"protocolVersion":2', '{"protocolVersion":2,"protocolVersion":2'),
            $script:validJson.Replace('"protocolVersion"', '"ProtocolVersion"'),
            $script:validJson.Replace('{"protocolVersion":2', '{"command":"whoami","protocolVersion":2'),
            $script:validJson.Replace(',"windowMode":"NonInteractive"', ''),
            $script:validJson.Replace('Indexing', 'Index\u0069ng'),
            $script:validJson.Replace('"protocolVersion":2', '"protocolVersion":2.0'),
            $script:validJson.Replace('"protocolVersion":2', '"protocolVersion":2e0')
        )

        foreach ($variant in $variants) {
            { ConvertFrom-AtlasElevationRequestBytes -Bytes (ConvertTo-TestRequestBytes $variant) } |
                Should -Throw
        }
    }

    It 'rejects a BOM, malformed UTF-8, empty input, and oversized bytes' {
        $withBom = [byte[]](@(0xEF, 0xBB, 0xBF) + @($script:validRequestBytes))
        { ConvertFrom-AtlasElevationRequestBytes -Bytes $withBom } | Should -Throw
        { ConvertFrom-AtlasElevationRequestBytes -Bytes ([byte[]](0xC3, 0x28)) } | Should -Throw
        { ConvertFrom-AtlasElevationRequestBytes -Bytes ([byte[]]@()) } | Should -Throw
        { ConvertFrom-AtlasElevationRequestBytes -Bytes (New-Object byte[] 16385) } | Should -Throw
    }

    It 'requires one nonzero lowercase 32-hex request ID and uppercase SHA-256 binding' {
        $invalidIds = @(
            '',
            ('0' * 32),
            ('a' * 31),
            ('a' * 33),
            ('A' * 32),
            ('g' * 32),
            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
        )
        $wrongHash = '00' * 32

        foreach ($invalidId in $invalidIds) {
            { ConvertFrom-AtlasElevationRequestBytes -Bytes $script:validRequestBytes `
                    -ExpectedRequestId $invalidId -ExpectedSha256 $script:validRequestHash } |
                Should -Throw
        }
        { ConvertFrom-AtlasElevationRequestBytes -Bytes $script:validRequestBytes `
                -ExpectedRequestId $script:requestId -ExpectedSha256 $wrongHash } |
            Should -Throw
        { ConvertFrom-AtlasElevationRequestBytes -Bytes $script:validRequestBytes `
                -ExpectedRequestId $script:requestId -ExpectedSha256 '' } | Should -Throw
        { ConvertFrom-AtlasElevationRequestBytes -Bytes $script:validRequestBytes `
                -ExpectedRequestId $script:requestId `
                -ExpectedSha256 $script:validRequestHash.ToLowerInvariant() } | Should -Throw
    }
}

Describe 'Atlas elevation requester process binding' {
    It 'binds PID and creation FILETIME in addition to same-user session identity' {
        $request = New-TestElevationDocument
        $evidence = [pscustomobject]@{
            ProcessId        = $script:requesterProcessId
            CreationFileTime = $script:requesterCreationFileTime
            UserSid          = $script:requesterSid
            SessionId        = 7
        }
        Test-AtlasElevationRequesterBinding -Request $request -Evidence $evidence | Should -BeTrue

        $reusedPidEvidence = $evidence | Select-Object *
        $reusedPidEvidence.ProcessId = $script:requesterProcessId + 1
        Test-AtlasElevationRequesterBinding -Request $request -Evidence $reusedPidEvidence | Should -BeFalse

        $recreatedProcessEvidence = $evidence | Select-Object *
        $recreatedProcessEvidence.CreationFileTime = $script:requesterCreationFileTime + 1
        Test-AtlasElevationRequesterBinding -Request $request -Evidence $recreatedProcessEvidence | Should -BeFalse

        $differentSidEvidence = $evidence | Select-Object *
        $differentSidEvidence.UserSid = 'S-1-5-18'
        Test-AtlasElevationRequesterBinding -Request $request -Evidence $differentSidEvidence | Should -BeFalse

        $differentSessionEvidence = $evidence | Select-Object *
        $differentSessionEvidence.SessionId = 8
        Test-AtlasElevationRequesterBinding -Request $request -Evidence $differentSessionEvidence | Should -BeFalse

        $missingSessionEvidence = [pscustomobject]@{
            ProcessId        = $evidence.ProcessId
            CreationFileTime = $evidence.CreationFileTime
            UserSid          = $evidence.UserSid
        }
        Test-AtlasElevationRequesterBinding -Request $request -Evidence $missingSessionEvidence | Should -BeFalse
    }
}

Describe 'Atlas elevation closed operation schemas' {
    It 'has no Base64Url request-envelope API or alternate transport artifact' {
        $source = Get-Content -LiteralPath $script:protocolPath -Raw
        $source | Should -Not -Match 'Base64Url|RequestBase64Url|ConvertFrom-AtlasElevationRequestEnvelope'
        foreach ($functionName in @(
                'ConvertTo-AtlasBase64Url',
                'ConvertFrom-AtlasBase64Url',
                'ConvertFrom-AtlasElevationRequestEnvelope'
            )) {
            Get-Command -Name $functionName -ErrorAction SilentlyContinue |
                Should -BeNullOrEmpty
        }

        $envelope = New-AtlasElevationRequestEnvelope `
            -Operation Toggle `
            -OperationData ([ordered]@{
                name              = 'Indexing'
                state             = 'Disable'
                silent            = $true
                justContext       = $false
                noExplorerRestart = $true
            }) `
            -RequesterSid $script:requesterSid `
            -RequesterProcessId $script:requesterProcessId `
            -RequesterCreationFileTime $script:requesterCreationFileTime `
            -RequesterSessionId 7 `
            -RequestId $script:requestId
        @($envelope.PSObject.Properties.Name) | Should -Be @('Request', 'Bytes', 'Sha256')
    }

    It 'uses one request ID for transport correlation and keeps operation IDs inside typed payloads' {
        $document = New-TestElevationDocument -Operation SafeModeRecovery `
            -OperationData ([ordered]@{ operationId = '1234567890abcdef1234567890abcdef' })

        @($document.PSObject.Properties.Name) | Should -Be @(
            'protocolVersion', 'requestId', 'requesterSid', 'requesterProcessId',
            'requesterCreationFileTime', 'requesterSessionId', 'operation',
            'operationData', 'timeoutMilliseconds', 'windowMode'
        )
        $document.requestId | Should -BeExactly $script:requestId
        $document.requestId | Should -Match '^[0-9a-f]{32}$'
        $document.requestId | Should -Not -BeExactly ('0' * 32)
        $document.operationData.operationId | Should -Not -BeExactly $document.requestId
    }

    It 'accepts ordinary hashtables but emits canonical property order' {
        $data = @{
            noExplorerRestart = $false
            justContext       = $true
            silent            = $true
            state             = 'Enable'
            name              = 'Indexing'
        }
        $document = New-TestElevationDocument -Operation Toggle -OperationData $data
        @($document.operationData.PSObject.Properties.Name) |
            Should -Be @('name', 'state', 'silent', 'justContext', 'noExplorerRestart')
    }

    It 'rejects raw command, executable, script, scriptblock, and argv properties' {
        foreach ($rawName in @('command', 'commandLine', 'arguments', 'argv', 'executable', 'scriptPath', 'scriptblock')) {
            $data = [ordered]@{
                name              = 'Indexing'
                state             = 'Disable'
                silent            = $true
                justContext       = $false
                noExplorerRestart = $true
            }
            $data.Add($rawName, 'whoami')
            { New-TestElevationDocument -Operation Toggle -OperationData $data } | Should -Throw
        }
    }

    It 'rejects interactive, empty, path-like, NUL, and scriptblock toggle data' {
        $baseline = [ordered]@{
            name              = 'Indexing'
            state             = 'Disable'
            silent            = $true
            justContext       = $false
            noExplorerRestart = $true
        }

        $interactive = [ordered]@{} + $baseline
        $interactive.silent = $false
        { New-TestElevationDocument -Operation Toggle -OperationData $interactive } | Should -Throw

        $empty = [ordered]@{} + $baseline
        $empty.state = ''
        { New-TestElevationDocument -Operation Toggle -OperationData $empty } | Should -Throw

        $pathLike = [ordered]@{} + $baseline
        $pathLike.name = '..\Indexing'
        { New-TestElevationDocument -Operation Toggle -OperationData $pathLike } | Should -Throw

        $nul = [ordered]@{} + $baseline
        $nul.state = 'Disable' + [char]0
        { New-TestElevationDocument -Operation Toggle -OperationData $nul } | Should -Throw

        $code = [ordered]@{} + $baseline
        $code.state = { whoami }
        { New-TestElevationDocument -Operation Toggle -OperationData $code } | Should -Throw
    }

    It 'pins ResetServices to one noninteractive restoreSource enum' {
        foreach ($source in @('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')) {
            (New-TestElevationDocument -Operation ResetServices `
                    -OperationData ([ordered]@{ restoreSource = $source })).operationData.restoreSource |
                Should -BeExactly $source
        }

        { New-TestElevationDocument -Operation ResetServices `
                -OperationData ([ordered]@{ restoreSource = 'Prompt' }) } | Should -Throw
        { New-TestElevationDocument -Operation ResetServices `
                -OperationData ([ordered]@{ restoreSource = 'ToggleDefaults'; silent = $true }) } |
            Should -Throw
    }

    It 'pins SafeModeRecovery to one nonzero lowercase 32-hex operation ID' {
        $valid = New-TestElevationDocument -Operation SafeModeRecovery `
            -OperationData ([ordered]@{ operationId = '1234567890abcdef1234567890abcdef' })
        @($valid.operationData.PSObject.Properties.Name) | Should -Be @('operationId')
        $valid.operationData.operationId | Should -BeExactly '1234567890abcdef1234567890abcdef'

        foreach ($invalid in @(
                ('0' * 32),
                '1234567890ABCDEF1234567890ABCDEF',
                '1234567890abcdef1234567890abcde',
                '1234567890abcdef1234567890abcdef0',
                '..\Recover-AtlasSafeMode.ps1',
                '1234567890abcdef1234567890abcdeg'
            )) {
            { New-TestElevationDocument -Operation SafeModeRecovery `
                    -OperationData ([ordered]@{ operationId = $invalid }) } | Should -Throw
        }

        { New-TestElevationDocument -Operation SafeModeRecovery -OperationData ([ordered]@{
                    operationId = '1234567890abcdef1234567890abcdef'
                    scriptPath = 'C:\untrusted.ps1'
                }) } | Should -Throw
    }

    It 'removes RegistryImport rather than transporting caller-authored privileged mutations' {
        { New-TestElevationDocument -Operation RegistryImport -OperationData ([ordered]@{
                    sourcePath = 'C:\Atlas\input.reg'
                }) } | Should -Throw
    }

    It 'rejects stale versions, malformed identities, degenerate IDs, and noninteractive mode aliases' {
        $baseline = New-TestElevationDocument
        $maximumFileTime = New-AtlasElevationRequestDocument -Operation Toggle `
            -OperationData $baseline.operationData `
            -RequesterSid $script:requesterSid `
            -RequesterProcessId $script:requesterProcessId `
            -RequesterCreationFileTime ([long]::MaxValue) `
            -RequesterSessionId 7 `
            -TimeoutMilliseconds 900000 `
            -RequestId $script:requestId
        $maximumFileTime.requesterCreationFileTime | Should -BeExactly '7FFFFFFFFFFFFFFF'
        { ConvertTo-AtlasElevationRequestBytes -Request $maximumFileTime } | Should -Not -Throw

        foreach ($mutation in @(
                @{ Name = 'protocolVersion'; Value = 1 },
                @{ Name = 'protocolVersion'; Value = 3 },
                @{ Name = 'requestId'; Value = ('0' * 32) },
                @{ Name = 'requestId'; Value = ('A' * 32) },
                @{ Name = 'requestId'; Value = ('a' * 31) },
                @{ Name = 'requesterSid'; Value = 'not-a-sid' },
                @{ Name = 'requesterProcessId'; Value = 0 },
                @{ Name = 'requesterCreationFileTime'; Value = '01db000000000000' },
                @{ Name = 'requesterCreationFileTime'; Value = '0000000000000000' },
                @{ Name = 'requesterCreationFileTime'; Value = '8000000000000000' },
                @{ Name = 'requesterCreationFileTime'; Value = 'FFFFFFFFFFFFFFFF' },
                @{ Name = 'requesterSessionId'; Value = -1 },
                @{ Name = 'operation'; Value = 'RegistryImport' },
                @{ Name = 'windowMode'; Value = 'Hidden' }
            )) {
            $copy = $baseline | Select-Object *
            $copy.($mutation.Name) = $mutation.Value
            { ConvertTo-AtlasElevationRequestBytes -Request $copy } | Should -Throw
        }
    }
}

Describe 'Atlas Windows argv quoting' {
    It 'repeats argv[0] and round-trips pathological tokens through CommandLineToArgvW' {
        $application = 'C:\Program Files\Windows PowerShell\powershell.exe'
        $arguments = @(
            '',
            'plain',
            'two words',
            "tab`tvalue",
            'embedded"quote',
            'C:\trailing\',
            'C:\space and trailing\\',
            '\\server\share\',
            $script:unicodeArgument,
            '-leadingSwitch',
            '&|<>^%!',
            'back\\slash"quote'
        )
        $commandLine = New-AtlasWindowsCommandLine -ApplicationPath $application -ArgumentList $arguments
        $parsed = [AtlasElevationProtocolArgvTest]::Parse($commandLine)

        $parsed.Count | Should -Be ($arguments.Count + 1)
        $parsed[0] | Should -BeExactly $application
        for ($index = 0; $index -lt $arguments.Count; $index++) {
            $parsed[$index + 1] | Should -BeExactly $arguments[$index]
        }
    }

    It 'keeps ProcessStartInfo arguments separate from native argv[0]' {
        Join-AtlasWindowsArguments -ArgumentList @('-NoProfile', '-File', 'C:\Atlas Scripts\broker.ps1') |
            Should -BeExactly '-NoProfile -File "C:\Atlas Scripts\broker.ps1"'
        New-AtlasWindowsCommandLine -ApplicationPath 'C:\Windows\powershell.exe' `
            -ArgumentList @('-NoProfile') |
            Should -BeExactly 'C:\Windows\powershell.exe -NoProfile'
    }

    It 'rejects nulls, too many tokens, NUL, and an oversized command line' {
        { Join-AtlasWindowsArguments -ArgumentList @('one', $null) } | Should -Throw
        { Join-AtlasWindowsArguments -ArgumentList ([string[]](1..129 | ForEach-Object { 'x' })) } |
            Should -Throw
        { New-AtlasWindowsCommandLine -ApplicationPath 'C:\x.exe' `
                -ArgumentList ([string[]](1..128 | ForEach-Object { 'x' })) } | Should -Throw
        { Join-AtlasWindowsArguments -ArgumentList @('before' + [char]0 + 'after') } | Should -Throw
        { New-AtlasWindowsCommandLine -ApplicationPath 'C:\x.exe' -ArgumentList @('x' * 32760) } |
            Should -Throw
    }

    It 'binds a real Windows PowerShell 5.1 -File invocation without injecting argv[0]' {
        $fixturePath = Join-Path -Path $TestDrive -ChildPath 'argv fixture.ps1'
        $outputPath = Join-Path -Path $TestDrive -ChildPath 'argv-result.txt'
        @'
param(
    [string]$OutputPath,
    [string]$Scalar,
    [switch]$Enabled,
    [AllowEmptyString()]
    [string]$Tail
)
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllLines($OutputPath, @($Scalar, ([bool]$Enabled).ToString(), $Tail), $utf8)
'@ | Set-Content -LiteralPath $fixturePath -Encoding UTF8

        $scalar = 'spaces " quotes \ &|<>^%! ' + $script:unicodeInput
        $arguments = @(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $fixturePath,
            '-OutputPath', $outputPath,
            '-Scalar', $scalar,
            '-Enabled',
            '-Tail', ''
        )
        $startInfo = New-Object Diagnostics.ProcessStartInfo
        $startInfo.FileName = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        $startInfo.Arguments = Join-AtlasWindowsArguments -ArgumentList $arguments
        $startInfo.WorkingDirectory = "$env:SystemRoot\System32"
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        $process = [Diagnostics.Process]::Start($startInfo)
        try {
            $process.WaitForExit(10000) | Should -BeTrue
            $process.ExitCode | Should -Be 0
        }
        finally {
            if (-not $process.HasExited) {
                $process.Kill()
            }
            $process.Dispose()
        }

        $lines = [IO.File]::ReadAllLines($outputPath, $script:utf8)
        $lines[0] | Should -BeExactly $scalar
        $lines[1] | Should -BeExactly 'True'
        $lines[2] | Should -BeExactly ''
    }
}

Describe 'Atlas elevation v2 relay frame protocol' {
    It 'uses only the bounded asynchronous write completion point and never an unbounded Flush' {
        $source = Get-Content -LiteralPath $script:protocolPath -Raw
        $source | Should -Match '(?s)BeginWrite\(.+?WaitOne\(\$remaining\).+?EndWrite\(\$pending\)'
        $source | Should -Not -Match '\$Stream\.Flush\('
    }

    It 'pins the exact native wire header layout and kind values byte-for-byte' {
        $wireRequestId = '00112233445566778899aabbccddeeff'
        $expectedRequestIdBytes = [byte[]]@(
            0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
            0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF
        )
        $expectedPayloadHash = '559AEAD08264D5795D3909718CDD05ABD49572E84FE55590EEF31A88A08FDFFD'
        $kindValues = [ordered]@{ Request = 1; Ready = 2; Result = 3 }

        foreach ($entry in $kindValues.GetEnumerator()) {
            $bytes = ConvertTo-AtlasElevationFrame -Kind $entry.Key -RequestId $wireRequestId `
                -Payload ([byte[]]@(0x41))

            $bytes.Length | Should -Be 65
            $bytes[0..7] | Should -Be ([Text.Encoding]::ASCII.GetBytes('ATLASTI2'))
            $bytes[8..15] | Should -Be ([byte[]]@(
                    0x02, 0x00, [byte]$entry.Value, 0x00, 0x01, 0x00, 0x00, 0x00
                ))
            $bytes[16..31] | Should -Be $expectedRequestIdBytes
            (($bytes[32..63] | ForEach-Object { $_.ToString('X2') }) -join '') |
                Should -BeExactly $expectedPayloadHash
            $bytes[64] | Should -Be 0x41
        }
    }

    It 'round-trips only Request, Ready, and Result with one exact request ID and payload hash' {
        foreach ($kind in @('Request', 'Ready', 'Result')) {
            $payload = [byte[]]$script:utf8.GetBytes("$kind payload")
            $bytes = ConvertTo-AtlasElevationFrame -Kind $kind -RequestId $script:requestId -Payload $payload
            $frame = ConvertFrom-AtlasElevationFrame -Bytes $bytes

            @($frame.PSObject.Properties.Name) |
                Should -Be @('Kind', 'RequestId', 'Payload', 'PayloadSha256')
            $frame.Kind | Should -BeExactly $kind
            $frame.RequestId | Should -BeExactly $script:requestId
            $frame.Payload | Should -Be $payload
            $frame.PayloadSha256 | Should -Match '^[0-9A-F]{64}$'
        }

        { ConvertTo-AtlasElevationFrame -Kind Error -RequestId $script:requestId `
                -Payload ([byte[]](1)) } | Should -Throw
    }

    It 'accepts the exact per-kind caps while rejecting empty and cap-plus-one payloads' {
        $caps = @{
            Request = 16KB
            Ready   = 4KB
            Result  = 64KB
        }
        foreach ($entry in $caps.GetEnumerator()) {
            $maximumPayload = New-Object byte[] $entry.Value
            $maximumFrame = ConvertTo-AtlasElevationFrame -Kind $entry.Key `
                -RequestId $script:requestId -Payload $maximumPayload
            $decoded = ConvertFrom-AtlasElevationFrame -Bytes $maximumFrame `
                -ExpectedKind $entry.Key -ExpectedRequestId $script:requestId
            $decoded.Payload.Length | Should -Be $entry.Value

            $stream = New-Object IO.MemoryStream
            try {
                Write-AtlasElevationFrame -Stream $stream -Kind $entry.Key `
                    -RequestId $script:requestId -Payload $maximumPayload
                $stream.Position = 0
                $streamFrame = Read-AtlasElevationFrame -Stream $stream -ExpectedKind $entry.Key `
                    -ExpectedRequestId $script:requestId
                $streamFrame.Payload.Length | Should -Be $entry.Value
            }
            finally {
                $stream.Dispose()
            }

            { ConvertTo-AtlasElevationFrame -Kind $entry.Key -RequestId $script:requestId `
                    -Payload ([byte[]]@()) } | Should -Throw
            { ConvertTo-AtlasElevationFrame -Kind $entry.Key -RequestId $script:requestId `
                    -Payload (New-Object byte[] ($entry.Value + 1)) } | Should -Throw
        }
    }

    It 'rejects malformed IDs, header corruption, binding mismatch, hash mismatch, and noncanonical length' {
        foreach ($invalidId in @(
                ('0' * 32), ('A' * 32), ('a' * 31), ('a' * 33), ('g' * 32),
                'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
            )) {
            { ConvertTo-AtlasElevationFrame -Kind Request -RequestId $invalidId `
                    -Payload ([byte[]](1)) } | Should -Throw
        }

        $valid = ConvertTo-AtlasElevationFrame -Kind Request -RequestId $script:requestId `
            -Payload ([byte[]](1, 2, 3, 4))
        $badMagic = [byte[]]$valid.Clone()
        $badMagic[0] = $badMagic[0] -bxor 0xFF
        { ConvertFrom-AtlasElevationFrame -Bytes $badMagic } | Should -Throw

        $badVersion = [byte[]]$valid.Clone()
        [Array]::Copy([BitConverter]::GetBytes([uint16]1), 0, $badVersion, 8, 2)
        { ConvertFrom-AtlasElevationFrame -Bytes $badVersion } | Should -Throw

        $badKind = [byte[]]$valid.Clone()
        [Array]::Copy([BitConverter]::GetBytes([uint16]4), 0, $badKind, 10, 2)
        { ConvertFrom-AtlasElevationFrame -Bytes $badKind } | Should -Throw

        $zeroRequestId = [byte[]]$valid.Clone()
        [Array]::Clear($zeroRequestId, 16, 16)
        { ConvertFrom-AtlasElevationFrame -Bytes $zeroRequestId } | Should -Throw

        $badHash = [byte[]]$valid.Clone()
        $badHash[$badHash.Length - 1] = $badHash[$badHash.Length - 1] -bxor 0x01
        { ConvertFrom-AtlasElevationFrame -Bytes $badHash } | Should -Throw

        foreach ($declaredLength in @([uint32]0, [uint32]3, [uint32]5)) {
            $badLength = [byte[]]$valid.Clone()
            [Array]::Copy([BitConverter]::GetBytes($declaredLength), 0, $badLength, 12, 4)
            { ConvertFrom-AtlasElevationFrame -Bytes $badLength } | Should -Throw
        }

        { ConvertFrom-AtlasElevationFrame -Bytes ([byte[]](@($valid) + 0)) } | Should -Throw
        { ConvertFrom-AtlasElevationFrame -Bytes ([byte[]](@($valid) + @($valid))) } | Should -Throw
        { ConvertFrom-AtlasElevationFrame -Bytes $valid[0..($valid.Length - 2)] } | Should -Throw
        { ConvertFrom-AtlasElevationFrame -Bytes $valid -ExpectedKind Ready } | Should -Throw
        { ConvertFrom-AtlasElevationFrame -Bytes $valid `
                -ExpectedRequestId 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' } | Should -Throw
    }

    It 'bounds a declared stream length before allocation and fails closed on premature EOF' {
        $valid = ConvertTo-AtlasElevationFrame -Kind Request -RequestId $script:requestId `
            -Payload ([byte[]](1, 2, 3, 4))
        $oversizedHeader = [byte[]]$valid[0..63]
        [Array]::Copy([BitConverter]::GetBytes([uint32](16KB + 1)), 0, $oversizedHeader, 12, 4)
        $oversizedStream = New-Object IO.MemoryStream(, $oversizedHeader)
        try {
            {
                Read-AtlasElevationFrame -Stream $oversizedStream -ExpectedKind Request `
                    -ExpectedRequestId $script:requestId
            } | Should -Throw
        }
        finally {
            $oversizedStream.Dispose()
        }

        $truncatedStream = New-Object IO.MemoryStream(, ([byte[]]$valid[0..($valid.Length - 2)]))
        try {
            {
                Read-AtlasElevationFrame -Stream $truncatedStream -ExpectedKind Request `
                    -ExpectedRequestId $script:requestId
            } | Should -Throw
        }
        finally {
            $truncatedStream.Dispose()
        }
    }

    It 'writes and reads one bounded frame without changing the correlation fields' {
        $stream = New-Object IO.MemoryStream
        try {
            $payload = [byte[]]$script:utf8.GetBytes('{"protocolVersion":2}')
            Write-AtlasElevationFrame -Stream $stream -Kind Ready `
                -RequestId $script:requestId -Payload $payload
            $stream.Position = 0
            $frame = Read-AtlasElevationFrame -Stream $stream -ExpectedKind Ready `
                -ExpectedRequestId $script:requestId

            $frame.Kind | Should -BeExactly 'Ready'
            $frame.RequestId | Should -BeExactly $script:requestId
            $frame.Payload | Should -Be $payload
            $stream.Position | Should -Be $stream.Length
        }
        finally {
            $stream.Dispose()
        }
    }

    It 'requires exact bounded EOF after the terminal frame' {
        $closed = New-Object IO.MemoryStream
        try {
            { Assert-AtlasElevationStreamEof -Stream $closed -TimeoutMilliseconds 1000 } |
                Should -Not -Throw
        }
        finally {
            $closed.Dispose()
        }

        $trailing = New-Object IO.MemoryStream(, ([byte[]]@(0x41)))
        try {
            { Assert-AtlasElevationStreamEof -Stream $trailing -TimeoutMilliseconds 1000 } |
                Should -Throw -ExpectedMessage '*trailing bytes*'
        }
        finally {
            $trailing.Dispose()
        }
    }

    It 'cancels and joins a timed-out real pipe read before returning' {
        $pipeName = 'AtlasElevationProtocolTimeout.' + [guid]::NewGuid().ToString('N')
        $server = New-Object IO.Pipes.NamedPipeServerStream(
            $pipeName,
            [IO.Pipes.PipeDirection]::InOut,
            1,
            [IO.Pipes.PipeTransmissionMode]::Byte,
            [IO.Pipes.PipeOptions]::Asynchronous
        )
        $client = New-Object IO.Pipes.NamedPipeClientStream(
            '.',
            $pipeName,
            [IO.Pipes.PipeDirection]::InOut,
            [IO.Pipes.PipeOptions]::Asynchronous
        )
        $pendingConnection = $server.BeginWaitForConnection($null, $null)
        try {
            $client.Connect(5000)
            $server.EndWaitForConnection($pendingConnection)
            $timer = [Diagnostics.Stopwatch]::StartNew()
            try {
                { Assert-AtlasElevationStreamEof -Stream $server -TimeoutMilliseconds 100 } |
                    Should -Throw -ExpectedMessage '*exceeded its bounded deadline*'
            }
            finally {
                $timer.Stop()
            }
            $timer.ElapsedMilliseconds | Should -BeLessThan 6000
        }
        finally {
            $pendingConnection.AsyncWaitHandle.Close()
            $client.Dispose()
            $server.Dispose()
        }
    }
}
