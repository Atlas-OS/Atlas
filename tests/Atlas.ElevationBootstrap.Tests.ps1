BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:NativeRoot = Join-Path $script:RepoRoot 'tools\native\Atlas.ElevationBootstrap'
    $script:SourcePath = Join-Path $script:NativeRoot 'Atlas.ElevationBootstrap.cpp'
    $script:ManifestPath = Join-Path $script:NativeRoot 'Atlas.ElevationBootstrap.manifest'
    $script:ResourcePath = Join-Path $script:NativeRoot 'Atlas.ElevationBootstrap.rc'
    $script:BuildPath = Join-Path $script:RepoRoot 'tools\build\Build-AtlasElevationBootstrap.ps1'
    $script:VerifierPath = Join-Path $script:RepoRoot 'tools\build\Test-AtlasElevationBootstrap.ps1'
    $script:HashManifestPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Tools\Atlas-ElevationBootstrapHashes.psd1'
    $script:TrustedInstallerProcessPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Domain\TrustedInstallerProcess.ps1'
    $script:BrokerPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Invoke-AtlasTrustedInstallerBroker.ps1'
    $script:Source = Get-Content -LiteralPath $script:SourcePath -Raw
    $script:ProductionSource = [regex]::Split(
        $script:Source,
        '#if defined\(ATLAS_BOOTSTRAP_CONTRACT_HARNESS\)',
        2
    )[0]
    $script:Manifest = Get-Content -LiteralPath $script:ManifestPath -Raw
    $script:Resource = Get-Content -LiteralPath $script:ResourcePath -Raw
    $script:Build = Get-Content -LiteralPath $script:BuildPath -Raw
    $script:Verifier = Get-Content -LiteralPath $script:VerifierPath -Raw
    $script:TrustedInstallerProcess = Get-Content -LiteralPath `
        $script:TrustedInstallerProcessPath -Raw
    $script:Broker = Get-Content -LiteralPath $script:BrokerPath -Raw

    $buildTokens = $null
    $buildParseErrors = $null
    $buildAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:BuildPath,
        [ref]$buildTokens,
        [ref]$buildParseErrors
    )
    $buildParseErrors.Count | Should -Be 0
    $directoryEvidenceFunction = $buildAst.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -ceq 'Get-DirectoryEvidence'
        }, $true)
    $directoryEvidenceFunction | Should -Not -BeNullOrEmpty
    . ([scriptblock]::Create($directoryEvidenceFunction.Extent.Text))

    function Invoke-TestAtlasBootstrapBuild {
        param(
            [Parameter(Mandatory = $true)]
            [ValidateSet('all', 'amd64', 'arm64')]
            [string]$Architecture,
            [Parameter(Mandatory = $true)][string]$OutputDirectory,
            [string]$HashManifestPath,
            [switch]$RunContractHarness
        )

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            return & $script:BuildPath @PSBoundParameters
        }

        $pwsh = (Get-Command pwsh.exe -CommandType Application -ErrorAction Stop).Source
        $quotedBuildPath = "'{0}'" -f $script:BuildPath.Replace("'", "''")
        $quotedArchitecture = "'{0}'" -f $Architecture.Replace("'", "''")
        $quotedOutputDirectory = "'{0}'" -f $OutputDirectory.Replace("'", "''")
        $childCommand = "& $quotedBuildPath -Architecture $quotedArchitecture " +
            "-OutputDirectory $quotedOutputDirectory"
        if ($PSBoundParameters.ContainsKey('HashManifestPath')) {
            $quotedHashManifestPath = "'{0}'" -f $HashManifestPath.Replace("'", "''")
            $childCommand += " -HashManifestPath $quotedHashManifestPath"
        }
        if ($RunContractHarness) {
            $childCommand += ' -RunContractHarness'
        }

        $encodedCommand = [Convert]::ToBase64String(
            [Text.Encoding]::Unicode.GetBytes($childCommand))
        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $pwsh
        $startInfo.Arguments = '-NoLogo -NoProfile -NonInteractive -EncodedCommand ' +
            $encodedCommand
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        try {
            if (-not $process.Start()) {
                throw 'The PowerShell 7 test bridge did not start.'
            }
            $standardOutput = $process.StandardOutput.ReadToEndAsync()
            $standardError = $process.StandardError.ReadToEndAsync()
            $process.WaitForExit()
            $outputText = $standardOutput.GetAwaiter().GetResult()
            $errorText = $standardError.GetAwaiter().GetResult()
            if ($process.ExitCode -ne 0) {
                throw (($outputText + [Environment]::NewLine + $errorText).Trim())
            }
            return @($outputText, $errorText) | Where-Object { $_ }
        }
        finally {
            $process.Dispose()
        }
    }
}

Describe 'Atlas native elevation bootstrap payload contract' {
    It 'verifies both committed PE files against the machine-readable inventory' {
        { & $script:VerifierPath | Out-Null } | Should -Not -Throw
    }

    It 'ships a closed schema-v3 provenance inventory for exactly amd64 and arm64' {
        $hashes = Import-PowerShellDataFile -LiteralPath $script:HashManifestPath
        $hashes.SchemaVersion | Should -Be 3
        @($hashes.Keys | Sort-Object) | Should -Be @(
            'Artifacts',
            'Build',
            'Harness',
            'Inputs',
            'SchemaVersion',
            'Source',
            'Toolchain'
        )
        $hashes.Source | Should -BeExactly 'tools/native/Atlas.ElevationBootstrap'
        @($hashes.Build.Keys | Sort-Object) | Should -Be @(
            'Reproducibility',
            'Runtime'
        )
        $hashes.Build.Runtime | Should -BeExactly 'none'
        $hashes.Build.Reproducibility | Should -BeExactly `
            'Two independent unsigned builds compared byte-for-byte per architecture'

        @($hashes.Toolchain.Keys | Sort-Object) | Should -Be @(
            'ClangCl',
            'ClangResourceDirectory',
            'IncludeDirectories',
            'Libraries',
            'LldLink',
            'MsvcCompiler',
            'MsvcTools',
            'ResourceCompiler',
            'ResourceCompilerDependencies',
            'WindowsSdk'
        )
        $hashes.Toolchain.MsvcTools | Should -BeExactly '14.51.36231'
        $hashes.Toolchain.WindowsSdk | Should -BeExactly '10.0.26100.0'
        foreach ($tool in @(
                @{ Name = 'ClangCl'; FileName = 'clang-cl.exe'; Pinned = $true },
                @{ Name = 'LldLink'; FileName = 'lld-link.exe'; Pinned = $true },
                @{ Name = 'MsvcCompiler'; FileName = 'cl.exe'; Pinned = $false },
                @{ Name = 'ResourceCompiler'; FileName = 'rc.exe'; Pinned = $false }
            )) {
            $entry = $hashes.Toolchain[$tool.Name]
            @($entry.Keys | Sort-Object) | Should -Be @(
                'FileName', 'Length', 'SHA256', 'Version'
            )
            $entry.FileName | Should -BeExactly $tool.FileName
            [uint64]$entry.Length | Should -BeGreaterThan 0
            $entry.SHA256 | Should -Match '^[0-9A-F]{64}$'
            [string]::IsNullOrWhiteSpace([string]$entry.Version) | Should -BeFalse
            if ($tool.Pinned) {
                $entry.Version | Should -Match '(?<!\d)22\.1\.8(?!\d)'
            }
        }

        @($hashes.Toolchain.ClangResourceDirectory.Keys | Sort-Object) |
            Should -Be @('FileCount', 'RelativePath', 'SHA256', 'Version')
        $hashes.Toolchain.ClangResourceDirectory.RelativePath |
            Should -BeExactly 'lib/clang/22/include'
        $hashes.Toolchain.ClangResourceDirectory.Version | Should -BeExactly '22'
        [uint64]$hashes.Toolchain.ClangResourceDirectory.FileCount |
            Should -BeGreaterThan 0
        $hashes.Toolchain.ClangResourceDirectory.SHA256 |
            Should -Match '^[0-9A-F]{64}$'

        @($hashes.Toolchain.IncludeDirectories.Keys | Sort-Object) |
            Should -Be @(
                'Msvc',
                'WindowsSdkShared',
                'WindowsSdkUcrt',
                'WindowsSdkUm'
            )
        $expectedIncludeDirectories = [ordered]@{
            Msvc = @{
                RelativePath = 'VC/Tools/MSVC/14.51.36231/include'
                Version = '14.51.36231'
            }
            WindowsSdkShared = @{
                RelativePath = 'Include/10.0.26100.0/shared'
                Version = '10.0.26100.0'
            }
            WindowsSdkUcrt = @{
                RelativePath = 'Include/10.0.26100.0/ucrt'
                Version = '10.0.26100.0'
            }
            WindowsSdkUm = @{
                RelativePath = 'Include/10.0.26100.0/um'
                Version = '10.0.26100.0'
            }
        }
        foreach ($includeName in $expectedIncludeDirectories.Keys) {
            $include = $hashes.Toolchain.IncludeDirectories[$includeName]
            @($include.Keys | Sort-Object) | Should -Be @(
                'FileCount', 'RelativePath', 'SHA256', 'Version'
            )
            $include.RelativePath | Should -BeExactly `
                $expectedIncludeDirectories[$includeName].RelativePath
            $include.Version | Should -BeExactly `
                $expectedIncludeDirectories[$includeName].Version
            [uint64]$include.FileCount | Should -BeGreaterThan 0
            $include.SHA256 | Should -Match '^[0-9A-F]{64}$'
        }

        @($hashes.Toolchain.ResourceCompilerDependencies.Keys | Sort-Object) |
            Should -Be @('RCDLL.dll', 'ServicingCommon.dll')
        foreach ($dependency in $hashes.Toolchain.ResourceCompilerDependencies.Values) {
            @($dependency.Keys | Sort-Object) | Should -Be @('FileName', 'Length', 'SHA256')
            [uint64]$dependency.Length | Should -BeGreaterThan 0
            $dependency.SHA256 | Should -Match '^[0-9A-F]{64}$'
        }

        @($hashes.Toolchain.Libraries.Keys | Sort-Object) |
            Should -Be @('amd64', 'arm64')
        $expectedLibraries = @(
            'advapi32.lib', 'bcrypt.lib', 'BufferOverflowU.lib', 'kernel32.lib',
            'shell32.lib'
        )
        foreach ($architecture in @('amd64', 'arm64')) {
            @($hashes.Toolchain.Libraries[$architecture].Keys | Sort-Object) |
                Should -Be $expectedLibraries
            foreach ($libraryName in $expectedLibraries) {
                $library = $hashes.Toolchain.Libraries[$architecture][$libraryName]
                @($library.Keys | Sort-Object) |
                    Should -Be @('FileName', 'Length', 'SHA256')
                $library.FileName | Should -BeExactly $libraryName
                [uint64]$library.Length | Should -BeGreaterThan 0
                $library.SHA256 | Should -Match '^[0-9A-F]{64}$'
            }
        }

        @($hashes.Harness.Keys | Sort-Object) | Should -Be @(
            'BuiltArchitectures',
            'ExecutedArchitectures',
            'HostArchitecture',
            'Passed',
            'Requested',
            'TimeoutMilliseconds'
        )
        $hashes.Harness.Requested | Should -BeTrue
        @($hashes.Harness.BuiltArchitectures) | Should -Be @('amd64', 'arm64')
        $hashes.Harness.HostArchitecture | Should -Match '^(amd64|arm64)$'
        @($hashes.Harness.ExecutedArchitectures) |
            Should -Be @($hashes.Harness.HostArchitecture)
        $hashes.Harness.Passed | Should -BeTrue
        [uint64]$hashes.Harness.TimeoutMilliseconds | Should -Be 30000

        @($hashes.Inputs.Keys | Sort-Object) | Should -Be @(
            'tools/build/Build-AtlasElevationBootstrap.ps1',
            'tools/build/Test-AtlasElevationBootstrap.ps1',
            'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.cpp',
            'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.manifest',
            'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.rc',
            'tools/native/Atlas.ElevationBootstrap/resource.h'
        )
        foreach ($entry in $hashes.Inputs.Values) {
            @($entry.Keys | Sort-Object) | Should -Be @('Length', 'SHA256')
            [uint64]$entry.Length | Should -BeGreaterThan 0
            $entry.SHA256 | Should -Match '^[0-9A-F]{64}$'
        }
        @($hashes.Artifacts.Keys | Sort-Object) | Should -Be @(
            'AtlasElevationBootstrap-amd64.exe',
            'AtlasElevationBootstrap-arm64.exe'
        )
        foreach ($entry in $hashes.Artifacts.Values) {
            @($entry.Keys | Sort-Object) |
                Should -Be @('Architecture', 'Length', 'Machine', 'SHA256')
            $entry.Architecture | Should -Match '^(amd64|arm64)$'
            [uint64]$entry.Length | Should -BeGreaterThan 0
            $entry.SHA256 | Should -Match '^[0-9A-F]{64}$'
        }
        $hashes.Artifacts['AtlasElevationBootstrap-amd64.exe'].Machine | Should -Be 0x8664
        $hashes.Artifacts['AtlasElevationBootstrap-arm64.exe'].Machine | Should -Be 0xaa64
    }

    It 'embeds requireAdministrator as RT_MANIFEST ID 1 without a linker merge' {
        $script:Manifest | Should -Match `
            'requestedExecutionLevel\s+level="requireAdministrator"\s+uiAccess="false"'
        $script:Resource | Should -Match `
            'IDR_ATLAS_ELEVATION_BOOTSTRAP_MANIFEST\s+RT_MANIFEST'
        $script:Build | Should -Match "'/manifest:no'"
    }
}

Describe 'Atlas native elevation bootstrap protocol boundary' {
    It 'accepts only one nonzero 32-character lowercase-hex request ID' {
        $script:Source | Should -Match 'argumentCount\s*!=\s*2'
        $script:Source | Should -Match 'StringLength\(value\)\s*!=\s*32'
        $script:Source | Should -Match "current\s*>=\s*L'0'.+current\s*<=\s*L'9'"
        $script:Source | Should -Match "current\s*>=\s*L'a'.+current\s*<=\s*L'f'"
        $script:Source | Should -Match "current\s*!=\s*L'0'"
    }

    It 'uses the frozen 64-byte ATLASTI2 v2 Request Ready Result frame contract' {
        $script:Source | Should -Match `
            "kFrameMagic\[8\]\s*=\s*\{\s*'A',\s*'T',\s*'L',\s*'A',\s*'S',\s*'T',\s*'I',\s*'2'\s*\}"
        $script:Source | Should -Match 'kFrameHeaderLength\s*=\s*64'
        $script:Source | Should -Match 'kFrameVersion\s*=\s*2'
        $script:Source | Should -Match 'kFrameRequest\s*=\s*1'
        $script:Source | Should -Match 'kFrameReady\s*=\s*2'
        $script:Source | Should -Match 'kFrameResult\s*=\s*3'
        $script:Source | Should -Not -Match 'kFrameError'
        $script:Source | Should -Match 'ReadUInt16\(frame->header \+ 8\)'
        $script:Source | Should -Match 'ReadUInt16\(frame->header \+ 10\)'
        $script:Source | Should -Match 'ReadUInt32\(frame->header \+ 12\)'
        $script:Source | Should -Match 'frame->header \+ 16, requestId, 16'
        $script:Source | Should -Match 'frame->header \+ 32, 32'
        $script:Source | Should -Match 'kRequestMaximum\s*=\s*16u \* 1024u'
        $script:Source | Should -Match 'kReadyMaximum\s*=\s*4u \* 1024u'
        $script:Source | Should -Match 'kResultMaximum\s*=\s*64u \* 1024u'
        $script:Source | Should -Match 'payloadLength\s*==\s*0 \|\| payloadLength\s*>\s*maximumPayload'
    }

    It 'connects as the elevated client to the caller-owned first-instance pipe' {
        $script:ProductionSource | Should -Match `
            '(?s)CreateFileW\(name, GENERIC_READ \| GENERIC_WRITE.+?FILE_FLAG_OVERLAPPED \| SECURITY_SQOS_PRESENT \| SECURITY_IDENTIFICATION'
        $script:ProductionSource | Should -Match 'GetNamedPipeServerProcessId'
        $script:ProductionSource | Should -Match 'GetNamedPipeServerSessionId'
        $script:ProductionSource | Should -Not -Match 'CreateNamedPipeW'
        $script:ProductionSource | Should -Not -Match 'ConnectNamedPipe'
        $script:ProductionSource | Should -Not -Match 'GetNamedPipeClientProcessId'
    }

    It 'binds requester identity and gives the broker a dedicated owner liveness pipe' {
        $script:Source | Should -Match 'OpenProcess\(PROCESS_QUERY_LIMITED_INFORMATION \| SYNCHRONIZE'
        $script:Source | Should -Match 'QueryProcessCreationTime'
        $script:Source | Should -Match 'ConvertSidToStringSidW'
        $script:Source | Should -Match 'ProcessIdToSessionId'
        $script:Source | Should -Match `
            'CreatePipe\(&childLivenessRead\.value, &parentLivenessWrite\.value'
        $script:Source | Should -Match `
            'SetHandleInformation\(parentLivenessWrite\.value, HANDLE_FLAG_INHERIT, 0\)'
        $script:Source | Should -Match `
            '(?s)HANDLE inheritedHandles\[4\].+?childLivenessRead\.value, childJob\.value'
        $script:Source | Should -Match `
            '\*bootstrapLivenessWrite = parentLivenessWrite'
        $script:Source | Should -Not -Match `
            'DuplicateHandle\(GetCurrentProcess\(\), externalPipe'
    }

    It 'checks administrator membership through an impersonation duplicate of the primary token' {
        $script:Source | Should -Match `
            'DuplicateToken\(primaryToken, SecurityIdentification, &impersonationToken\.value\)'
        $script:Source | Should -Match `
            'QueryPrimaryTokenMembership\(token\.value, adminSidBuffer, &isAdministrator\)'
        $script:Source | Should -Not -Match `
            'CheckTokenMembership\(token\.value, adminSidBuffer'
        $script:Source | Should -Match 'TestHarnessPrimaryTokenMembership\(\)'
    }

    It 'does not parse JSON execute UAC or invoke a command shell' {
        $script:Source | Should -Not -Match '(?i)json'
        $script:Source | Should -Not -Match 'ShellExecute'
        $script:Source | Should -Not -Match '(?i)\brunas\b'
        $script:Source | Should -Not -Match '(?i)cmd\.exe'
        $script:Source | Should -Not -Match 'CreateProcessW\([^,]+,\s*nullptr'
    }
}

Describe 'Atlas native elevation bootstrap process containment' {
    It 'passes only dedicated allowlisted inherited handles to a suspended fixed broker' {
        $script:Source | Should -Match 'PROC_THREAD_ATTRIBUTE_HANDLE_LIST'
        $script:Source | Should -Match 'PROC_THREAD_ATTRIBUTE_JOB_LIST'
        $script:Source | Should -Match 'HANDLE inheritedHandles\[4\]'
        $script:Source | Should -Match 'CreateProcessW\(paths\.powershell, command'
        $script:Source | Should -Match 'CREATE_SUSPENDED \| CREATE_UNICODE_ENVIRONMENT \| CREATE_NO_WINDOW'
        $script:Source | Should -Match 'EXTENDED_STARTUPINFO_PRESENT'
        $script:Source | Should -Match 'JOB_OBJECT_ASSIGN_PROCESS \| JOB_OBJECT_QUERY \| SYNCHRONIZE'
    }

    It 'uses the exact broker evidence-only command-line interface' {
        $switches = [regex]::Matches($script:Source,
            'AppendSwitch\(command, kMaximumCommandCharacters, L"(-[A-Za-z]+)"\)') |
            ForEach-Object { $_.Groups[1].Value }
        @($switches) | Should -Be @(
            '-ExpectedRequestId',
            '-RequestHandle',
            '-ResultHandle',
            '-LivenessHandle',
            '-OuterJobHandle',
            '-BootstrapProcessId',
            '-BootstrapCreationFileTime',
            '-RequesterProcessId',
            '-RequesterCreationFileTime',
            '-RequesterSid',
            '-RequesterSessionId'
        )
        $script:Source | Should -Match 'AppendHex16.+bootstrapCreation'
        $script:Source | Should -Match 'AppendHex16.+requester\.creationFileTime'
    }

    It 'enforces kill-on-close completion-port containment and bounded drain' {
        $script:Source | Should -Match 'JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE'
        $script:Source | Should -Match `
            '(?s)CreateContainment.+?containment->job.+?containment->ownerGuard'
        $script:Source | Should -Match 'JobObjectAssociateCompletionPortInformation'
        $script:Source | Should -Match 'JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO'
        $script:Source | Should -Match 'QueryJobIsDrained'
        $script:Source | Should -Match 'TerminateJobObject'
        $script:Source | Should -Match 'kDrainTimeoutMs\s*=\s*15u \* 1000u'
    }

    It 'fail-fast exits if a cancelled synchronous IO worker cannot be joined' {
        $script:Source | Should -Match `
            '(?s)cancelled\s*!=\s*WAIT_OBJECT_0.+FailFastContainment\(\)'
        $script:Source | Should -Match `
            '(?s)static void FailFastContainment\(\).+?TerminateJobObject\(job, kExitContainmentFailure\).+?ExitProcess\(kExitContainmentFailure\)'
    }

    It 'releases the broker outer-job duplicate before privileged child execution' {
        $script:TrustedInstallerProcess | Should -Match `
            '(?s)jobListBytes\s*=\s*checked\(IntPtr\.Size \* 2\).+?Marshal\.WriteIntPtr\(jobValue, 0, outerJobHandle\).+?Marshal\.WriteIntPtr\(jobValue, IntPtr\.Size, job\)'
        $script:TrustedInstallerProcess | Should -Match `
            '(?s)IsProcessInJob\(processInfo\.hProcess, outerJobHandle.+?IsProcessInJob\(processInfo\.hProcess, job.+?ReleaseOuterJobHandle\(request, ref outerJobHandle\).+?ThrowIfCancelled.+?ResumeThread'
        $script:TrustedInstallerProcess | Should -Match `
            '(?s)previousSuspendCount\s*=\s*ResumeThread.+?previousSuspendCount\s*!=\s*1'
        $script:TrustedInstallerProcess | Should -Match `
            '(?s)catch \{.+?ReleaseOuterJobHandle\(request, ref outerJobHandle\)'
        $script:TrustedInstallerProcess | Should -Match `
            '(?s)finally \{\s*ReleaseOuterJobHandle\(request, ref outerJobHandle\)'
        $script:Broker | Should -Match `
            '(?s)if \(\$outerJobLease -and -not \$outerJobLease\.IsClosed\).+?throw .+?retaining the broker outer-job duplicate'
    }

    It 'proves broker exit and job drain before the terminal Result commit' {
        $script:Source | Should -Match `
            '(?s)ReadAndValidateFrame\(pipes\.resultParentRead\.value, kFrameResult, kResultMaximum,\s*requestIdBytes, GetExternalInputMonitorEvent\(externalMonitor\),\s*requester\.process\.value, operationDeadline'
        $script:Source | Should -Match `
            '(?s)WaitForBrokerExitAndRelease\(&brokerProcess.+?DrainJob\(containment, kDrainTimeoutMs.+?StopExternalInputMonitor\(.+?terminalInput != ExternalInputCompletion::Stopped.+?WriteFrame\(externalPipe\.value, result, requester\.process\.value, nullptr,.+?Close\(&externalPipe\);\s*protocolComplete = true;\s*exitCode = brokerExit;'
        $resultRead = [regex]::Match($script:Source,
            '(?s)ReadAndValidateFrame\(pipes\.resultParentRead\.value, kFrameResult.+?&result\)')
        $resultRead.Success | Should -BeTrue
        $resultRead.Value | Should -Not -Match 'brokerProcess\.value'
        $script:Source | Should -Not -Match 'AfterResultRelay'
    }

    It 'arms one permanent caller-input monitor before broker setup and watches every later phase' {
        $script:Source | Should -Match `
            '(?s)ReadAndValidateFrame\(externalPipe\.value, kFrameRequest.+?NoAvailableInput\(externalPipe\.value\).+?StartExternalInputMonitor\(externalPipe\.value, &externalMonitor\).+?PrepareProtectedTemp'
        ([regex]::Matches($script:Source, 'NoAvailableInput\(')).Count | Should -Be 2
        $script:Source | Should -Match `
            '(?s)StartExternalInputMonitor.+?ReadFile\(pipe, &monitor->byte, 1.+?ERROR_IO_PENDING'
        $script:Source | Should -Match `
            '(?s)StopExternalInputMonitor.+?CancelIoEx\(pipe, &monitor->overlapped\).+?WaitForSingleObject\(monitor->event\.value, 5000\).+?GetOverlappedResult'
        foreach ($operation in @(
                'WriteFrame\(pipes\.requestParentWrite\.value, request',
                'ReadAndValidateFrame\(pipes\.resultParentRead\.value, kFrameReady',
                'WriteFrame\(externalPipe\.value, ready',
                'ReadAndValidateFrame\(pipes\.resultParentRead\.value, kFrameResult',
                'RequirePipeEof\(pipes\.resultParentRead\.value',
                'WaitForBrokerExitAndRelease\(&brokerProcess',
                'if \(!DrainJob\(containment, kDrainTimeoutMs,'
            )) {
            $match = [regex]::Match($script:Source, "(?s)$operation.+?;")
            $match.Success | Should -BeTrue
            $match.Value | Should -Match 'GetExternalInputMonitorEvent\(externalMonitor\)'
        }
        $script:Source | Should -Match 'CancelIoEx\(pipe, &overlapped\)'
        $script:Source | Should -Match 'CancelSynchronousIo\(thread\.value\)'
        $script:Source | Should -Match `
            '(?s)StopExternalInputMonitor\(\s*externalPipe\.value, &externalMonitor\).+?WriteFrame\(externalPipe\.value, result, requester\.process\.value, nullptr'
    }

    It 'uses independent bounded deadlines after the long-running operation result arrives' {
        $script:Source | Should -Match 'kTerminalPipeTimeoutMs\s*=\s*10u \* 1000u'
        $script:Source | Should -Match 'kTerminalDeliveryTimeoutMs\s*=\s*30u \* 1000u'
        $script:Source | Should -Match 'kBrokerExitTimeoutMs\s*=\s*10u \* 1000u'
        $script:Source | Should -Match `
            '(?s)RequirePipeEof\(pipes\.resultParentRead\.value.+?GetTickCount64\(\) \+ kTerminalPipeTimeoutMs'
        $script:Source | Should -Match `
            '(?s)WaitForBrokerExitAndRelease\(&brokerProcess,\s*GetTickCount64\(\) \+ kBrokerExitTimeoutMs'
        $script:Source | Should -Match 'DrainJob\(containment, kDrainTimeoutMs,'
        $script:Source | Should -Not -Match 'RemainingMilliseconds\(operationDeadline\)'
    }

    It 'loops partial writes so a header plus maximum 64KiB Result relays completely' {
        $script:Source | Should -Match 'kResultMaximum\s*=\s*64u \* 1024u'
        $script:Source | Should -Match `
            '(?s)static bool WriteExact.+?while \(offset < length\).+?offset \+= transferred'
        $script:Source | Should -Match `
            '(?s)WriteFrame\(externalPipe\.value, result.+?kTerminalDeliveryTimeoutMs, true\)'
    }

    It 'preflights bounded stale-cleanup bytes with checked high-low accumulation' {
        $script:Source | Should -Match `
            'kMaximumCleanupBytes\s*=\s*64ull \* 1024ull \* 1024ull'
        $script:Source | Should -Match `
            'static_cast<ULONGLONG>\(data\.nFileSizeHigh\) << 32'
        $script:Source | Should -Match `
            '\*byteCount > kMaximumCleanupBytes - fileBytes'
        $script:Source | Should -Match `
            '(?s)TraverseOwnedTree\(.+?false.+?TraverseOwnedTree\(.+?true'

        $cap = [uint64](64MB)
        ($cap -gt $cap -or [uint64]0 -gt ($cap - $cap)) | Should -BeFalse
        (($cap + 1) -gt $cap) | Should -BeTrue
        ([uint64]::MaxValue -gt $cap) | Should -BeTrue
    }

    It 'accepts protected zero-byte regular files during stale cleanup' {
        $script:Source | Should -Match `
            '(?s)const bool sizeValid = directory \|\| \(GetFileSizeEx.+?!requireNonEmpty \|\| size\.QuadPart > 0\)'
        $script:Source | Should -Match `
            '(?s)TraverseOwnedTree.+?ValidatePathObject\(child, false, false, false, trustedInstallerSid, nullptr\)'
        $script:Source | Should -Match `
            '(?s)ValidateProtectedHierarchy.+?last && !targetIsDirectory, trustedInstallerSid'

        $zeroByteTempFile = [pscustomobject]@{
            Directory       = $false
            ReparsePoint    = $false
            DeletePending   = $false
            ProtectedAcl    = $true
            Size            = [int64]0
            RequireNonEmpty = $false
        }
        ($zeroByteTempFile.Directory -eq $false -and
            $zeroByteTempFile.ReparsePoint -eq $false -and
            $zeroByteTempFile.DeletePending -eq $false -and
            $zeroByteTempFile.ProtectedAcl -and
            (-not $zeroByteTempFile.RequireNonEmpty -or $zeroByteTempFile.Size -gt 0)) |
            Should -BeTrue
    }

    It 'captures closes drains and propagates the exact uint32 broker exit pattern' {
        $script:Source | Should -Match `
            '(?s)WaitForBrokerExitAndRelease.+?GetExitCodeProcess\(brokerProcess->value, exitCode\).+?Close\(brokerProcess\)'
        $script:Source | Should -Match `
            '(?s)WaitForBrokerExitAndRelease\(&brokerProcess,.+?&brokerExit,.+?GetExternalInputMonitorEvent\(externalMonitor\)\).+?DrainJob\(containment, kDrainTimeoutMs,.+?protocolComplete = true;\s*exitCode = brokerExit;'
        $script:Source | Should -Not -Match 'brokerExit\s*!=\s*ERROR_SUCCESS'
        $script:Source | Should -Match 'ExitProcess\(AtlasBootstrap::Run\(\)\)'
        $script:Source | Should -Match `
            'const DWORD cases\[\] = \{ 0u, 5u, STILL_ACTIVE, 0x80000005u, 0xffffffffu \}'
    }

    It 'keeps failpoints availability-only and outside the broker environment' {
        $script:Source | Should -Match 'ATLAS_BOOTSTRAP_FAILPOINT'
        foreach ($name in @(
                'AfterPipeCreate', 'AfterClientBind', 'AfterRequestRelay',
                'AfterBrokerCreate', 'AfterReadyRelay', 'BeforeResultRelay',
                'ForceSynchronousIoNonJoin'
            )) {
            $script:Source | Should -Match $name
        }
        $sourceWithoutReader = $script:Source -replace `
            '(?s)static Failpoint ReadFailpoint\(\).*?\n\}', ''
        $sourceWithoutReader = $sourceWithoutReader -replace `
            '(?s)static bool ForceSynchronousIoNonJoinEnabled\(\).*?\n\}', ''
        $sourceWithoutReader | Should -Not -Match 'ATLAS_BOOTSTRAP_FAILPOINT'
    }
}

Describe 'Atlas native elevation bootstrap verifier hardening' {
    It 'requires a closed schema-v3 toolchain and executed-harness provenance contract' {
        $script:Verifier | Should -Match `
            "'SchemaVersion', 'Source', 'Build', 'Toolchain', 'Harness', 'Inputs', 'Artifacts'"
        $script:Verifier | Should -Match `
            '\$hashManifest\.SchemaVersion -isnot \[int\].+?SchemaVersion -ne 3'
        $script:Verifier | Should -Match `
            "'ClangCl', 'LldLink', 'ClangResourceDirectory', 'MsvcCompiler', 'MsvcTools'"
        $script:Verifier | Should -Match `
            "'WindowsSdk', 'IncludeDirectories', 'ResourceCompiler',"
        $script:Verifier | Should -Match `
            "'ResourceCompilerDependencies', 'Libraries'"
        foreach ($relativePath in @(
                'VC/Tools/MSVC/14.51.36231/include',
                'Include/10.0.26100.0/ucrt',
                'Include/10.0.26100.0/shared',
                'Include/10.0.26100.0/um'
            )) {
            $script:Verifier | Should -Match ([regex]::Escape($relativePath))
        }
        $script:Verifier | Should -Match ([regex]::Escape(
                '[string]$toolchain.MsvcTools -cne ''14.51.36231'''))
        $script:Verifier | Should -Match ([regex]::Escape(
                '[string]$toolchain.WindowsSdk -cne ''10.0.26100.0'''))
        $script:Verifier | Should -Match `
            '\[string\]\$toolchain\.ClangCl\.Version -notmatch.+?22\\\.1\\\.8'
        $script:Verifier | Should -Match `
            "'Requested', 'BuiltArchitectures', 'HostArchitecture', 'ExecutedArchitectures'"
        $script:Verifier | Should -Match `
            '\$executedArchitectures\[0\] -cne \[string\]\$harness\.HostArchitecture'
        $script:Verifier | Should -Match '\$harnessTimeout -ne 30000'
    }

    It 'maps only raw-backed RVAs and rejects ambiguous or writable executable layouts' {
        $script:Verifier | Should -Match `
            '(?s)function Convert-RvaToOffset.+?relative.+?VirtualSize.+?relative.+?RawSize'
        $script:Verifier | Should -Match "-Label 'PE section raw'"
        $script:Verifier | Should -Match "-Label 'PE section RVA'"
        $script:Verifier | Should -Match 'ranges overlap'
        $script:Verifier | Should -Match ([regex]::Escape(
                'throw "''$Path'' contains a writable executable section."'))
        $script:Verifier | Should -Match `
            "entry point is not in an executable non-writable section"
        $script:Verifier | Should -Match 'trailing data outside its PE sections'
    }

    It 'validates exact imports manifest semantics relocations and forbidden directories' {
        $script:Verifier | Should -Match ([regex]::Escape(
                '$expectedImports = @(''ADVAPI32.dll'', ''bcrypt.dll'', ''KERNEL32.dll'', ''SHELL32.dll'')'))
        $script:Verifier | Should -Match `
            '(?s)Read-PeImportThunkTable.+?TableRva \$originalThunk.+?TableRva \$firstThunk'
        $script:Verifier | Should -Match `
            'import lookup and address thunk sequences differ'
        $script:Verifier | Should -Match `
            '\$expectedImportSymbols = \[ordered\]@\{'
        $script:Verifier | Should -Match `
            'unexpected \$\(\$descriptor\.Name\) import-symbol set'
        $script:Verifier | Should -Match 'does not bind the complete declared IAT'
        $script:Verifier | Should -Match `
            '(?s)Get-ResourceDirectoryEntry.+?-Id 24.+?Get-ResourceDirectoryEntry.+?-Id 1'
        $script:Verifier | Should -Match `
            'exact VERSIONINFO/RT_MANIFEST resource type set'
        $script:Verifier | Should -Match `
            'must contain exactly one numeric RT_MANIFEST name'
        $script:Verifier | Should -Match `
            'must contain exactly one numeric manifest language'
        $script:Verifier | Should -Match '\$languageId -ne 0x0409'
        $script:Verifier | Should -Match ([regex]::Escape(
                '/asmv1:assembly/asmv3:trustInfo/asmv3:security/'))
        $script:Verifier | Should -Match ([regex]::Escape(
                '/asmv1:assembly/asmv3:application/asmv3:windowsSettings/'))
        $script:Verifier | Should -Match '\$xmlSettings\.DtdProcessing = \[Xml\.DtdProcessing\]::Prohibit'
        $script:Verifier | Should -Match `
            "GetAttribute\('level'\) -cne 'requireAdministrator'"
        $script:Verifier | Should -Match `
            "GetAttribute\('uiAccess'\) -cne 'false'"
        $script:Verifier | Should -Match ([regex]::Escape(
                '$longPathNodes[0].InnerText -cne ''true'''))
        $script:Verifier | Should -Match '\$type -ne 10'
        foreach ($directory in @('bound-import', 'TLS', 'delay-import', 'CLR')) {
            $script:Verifier | Should -Match ([regex]::Escape($directory))
        }
        $script:Verifier | Should -Match `
            'contains an unexpected debug-directory type'
        $script:Verifier | Should -Match `
            'lacks CET compatibility or the reproducible-build marker'
    }

    It 'binds load configuration to the cookie dependent-load and complete GuardCF evidence' {
        $script:Verifier | Should -Match '\$loadConfigSize -ne 0x148'
        $script:Verifier | Should -Match '\$internalLoadConfigSize -ne 0x148'
        $script:Verifier | Should -Match '\$dependentLoadFlags -ne 0x0800'
        $script:Verifier | Should -Match `
            'no nonzero cookie in writable non-executable image data'
        $script:Verifier | Should -Match `
            '\$guardCount -ne 7 -or \$guardFlags -ne 0x00010500'
        $script:Verifier | Should -Match `
            'GuardCF pointer whose target is not executable code'
        $script:Verifier | Should -Match `
            '\$guardFunctionRva -le \$previousGuardFunctionRva'
        $script:Verifier | Should -Match `
            'GuardCF target outside executable non-writable image data'
        $script:Verifier | Should -Match `
            'unexpected relocation inside the load configuration'
        $script:Verifier | Should -Match `
            'aliases distinct GuardCF handler targets'
    }

    It 'holds source manifest and artifact leases through final result validation' {
        $script:Verifier | Should -Match `
            "\`$artifactLeases = New-Object 'Collections\.Generic\.List\[object\]'"
        $script:Verifier | Should -Match `
            '(?s)Read-PeContract -Path \$path.+?-LeaseCollector \$artifactLeases'
        $script:Verifier | Should -Match `
            '(?s)finally \{.+?\$artifactLeases\[\$leaseIndex\]\.Dispose\(\).+?\$sourceLeases\[\$leaseIndex\]\.Dispose\(\).+?\$manifestLease\.Dispose\(\)'
        $script:Verifier | Should -Match 'GetFinalPathNameByHandleW'
        $script:Verifier | Should -Match 'Assert-AtlasVerifierPathIdentity'
    }
}

Describe 'Atlas native elevation bootstrap build hardening' {
    It 'requires PowerShell 7 before any native build logic runs' {
        $script:Build | Should -Match '^#requires -Version 7\.0\r?\n'
    }

    It 'builds each architecture twice and performs exact byte and SHA256 comparisons' {
        $script:Build | Should -Match "Invoke-OneBuild -BuildName 'A'"
        $script:Build | Should -Match "Invoke-OneBuild -BuildName 'B'"
        $script:Build | Should -Match 'Test-FilesByteEqual'
        $script:Build | Should -Match 'Get-FileHash.+SHA256'
    }

    It 'uses injective length-prefixed records for consumed directory evidence' {
        $leftRoot = Join-Path $TestDrive 'directory-evidence-left'
        $rightRoot = Join-Path $TestDrive 'directory-evidence-right'
        [void][IO.Directory]::CreateDirectory($leftRoot)
        [void][IO.Directory]::CreateDirectory($rightRoot)

        $d1 = [byte[]](0x44, 0x31)
        $c1 = [byte[]](0x43, 0x31)
        $c2 = [byte[]](0x43, 0x32)
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            $g1 = ([BitConverter]::ToString($sha256.ComputeHash($d1))).Replace('-', '')
            $h1 = ([BitConverter]::ToString($sha256.ComputeHash($c1))).Replace('-', '')
        }
        finally {
            $sha256.Dispose()
        }
        $literalNul = '`0'
        $literalNewline = '`n'
        $leftFirstName = 'a' + $literalNul + '2' + $literalNul + $g1 +
            $literalNewline + 'm'
        $rightSecondName = 'm' + $literalNul + '2' + $literalNul + $h1 +
            $literalNewline + 'z'

        [IO.File]::WriteAllBytes((Join-Path $leftRoot $leftFirstName), $c1)
        [IO.File]::WriteAllBytes((Join-Path $leftRoot 'z'), $c2)
        [IO.File]::WriteAllBytes((Join-Path $rightRoot 'a'), $d1)
        [IO.File]::WriteAllBytes((Join-Path $rightRoot $rightSecondName), $c2)

        @(Get-ChildItem -LiteralPath $leftRoot -Name) |
            Should -Not -BeExactly @(Get-ChildItem -LiteralPath $rightRoot -Name)
        $left = Get-DirectoryEvidence -Path $leftRoot -RelativePath 'left' -Version 'test'
        $right = Get-DirectoryEvidence -Path $rightRoot -RelativePath 'right' -Version 'test'
        $left.FileCount | Should -Be 2
        $right.FileCount | Should -Be 2
        $left.SHA256 | Should -Not -BeExactly $right.SHA256
        $script:Build | Should -Match '\[IO\.BinaryWriter\]::new'
        $script:Build | Should -Match '\$recordWriter\.Write\(\[long\]\$file\.Length\)'
    }

    It 'uses a common no-CRT hardened Clang LLD contract for amd64 and arm64' {
        foreach ($flag in @(
                '/GS', '/guard:cf', '/Brepro', '/Zl', '/EHs-c-', '/GR-',
                '/nodefaultlib', '/dynamicbase', '/nxcompat', '/highentropyva',
                '/cetcompat', '/dependentloadflag:0x800', '/manifest:no',
                '--no-default-config', '/lldignoreenv'
            )) {
            $script:Build | Should -Match ([regex]::Escape($flag))
        }
        $script:Build | Should -Match 'x86_64-pc-windows-msvc'
        $script:Build | Should -Match 'arm64-pc-windows-msvc'
        $script:Build | Should -Match 'BufferOverflowU\.lib'
        $script:Source | Should -Match `
            '(?s)__declspec\(safebuffers\) void WINAPI wWinMainCRTStartup\(\)\s*\{\s*__security_init_cookie\(\);\s*#if'
    }

    It 'pins one LLVM root MSVC and SDK and records exact toolchain evidence' {
        $script:Build | Should -Match `
            'clang-cl\.exe and lld-link\.exe must come from the same LLVM bin directory'
        $script:Build | Should -Match '\$clangResourceVersion = ''22'''
        $script:Build | Should -Match '\$msvcVersion = ''14\.51\.36231'''
        $script:Build | Should -Match '\$sdkVersion = ''10\.0\.26100\.0'''
        $script:Build | Should -Match 'function Get-FileEvidence'
        $script:Build | Should -Match 'function Get-DirectoryEvidence'
        $script:Build | Should -Match 'function Assert-EvidenceEqual'
        $script:Build | Should -Match `
            'ResourceCompilerDependencies = \$resourceCompilerDependencies'
        $script:Build | Should -Match 'RCDLL\.dll'
        $script:Build | Should -Match 'ServicingCommon\.dll'
        $script:Build | Should -Match `
            '(?s)& \$snapshotVerifierPath.+?-RepositoryRoot \$repoRoot'
    }

    It 'allows only the fixed hash-manifest child path' {
        $output = Join-Path $TestDrive 'manifest-path-policy'
        $outside = Join-Path $TestDrive 'outside\Atlas-ElevationBootstrapHashes.psd1'
        New-Item -Path $output -ItemType Directory -Force | Out-Null

        { Invoke-TestAtlasBootstrapBuild -Architecture amd64 `
                -OutputDirectory $output -HashManifestPath $outside | Out-Null } |
            Should -Throw '*exact canonical filename directly below the output directory*'
        $script:Build | Should -Match 'function Assert-NoPathAlias'
        $script:Build | Should -Match 'GetFinalPathNameByHandleW'
        $script:Build | Should -Match 'OpenDirectoryLease'
        $script:Build | Should -Match 'GetFileId'
        $script:Build | Should -Match '\$isCanonicalOutput'
        $script:Build | Should -Match `
            "'Atlas-ElevationBootstrapHashes\.psd1'"
    }

    It 'publishes verified files transactionally with rollback and the manifest last' {
        $script:Build | Should -Match 'function Publish-AtlasBootstrapFileSet'
        $script:Build | Should -Match '\[IO\.File\]::Replace\('
        $script:Build | Should -Match `
            '(?s)for \(\$index = \$operations\.Count - 1; \$index -ge 0; \$index--\).+?Invoke-PublicationOperationRollback'
        $script:Build | Should -Match `
            '(?s)\$operation\.Attempted = \$true.+?\[IO\.File\]::Replace.+?\$operation\.Attempted = \$true.+?\[IO\.File\]::Move'
        $script:Build | Should -Match 'Published output failed its final hash check'
        $script:Build | Should -Match 'RetainRecoveryPaths'
        $script:Build | Should -Match 'The attempted publication could not be restored'
        $script:Build | Should -Match `
            '(?s)Write-AtlasBootstrapHashManifest.+?\$publicationFiles.+?Publish-AtlasBootstrapFileSet'
        $script:Build | Should -Not -Match 'Format-Table'
    }

    It 'executes the same-source no-manifest native contract harness on the host architecture' `
            -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
        $hostTarget = if ([string][Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture `
                -eq 'Arm64') { 'arm64' } else { 'amd64' }
        $output = Join-Path $TestDrive 'native-contract-harness'
        New-Item -Path $output -ItemType Directory -Force | Out-Null
        $environmentNames = @('CL', 'LINK', 'CCC_OVERRIDE_OPTIONS')
        $processEnvironment = [Environment]::GetEnvironmentVariables('Process')
        $originalEnvironment = [ordered]@{}
        foreach ($name in $environmentNames) {
            $originalEnvironment[$name] = [pscustomobject]@{
                Present = $processEnvironment.Contains($name)
                Value   = [Environment]::GetEnvironmentVariable($name, 'Process')
            }
            [Environment]::SetEnvironmentVariable(
                $name, "atlas-bootstrap-test-$name", 'Process')
        }
        try {
            $buildResults = @(& $script:BuildPath -Architecture $hostTarget `
                -OutputDirectory $output -RunContractHarness)
            $buildResults.Count | Should -Be 1
            @($buildResults[0].Architectures) | Should -Be @($hostTarget)
            @($buildResults[0].HarnessExecutedArchitectures) |
                Should -Be @($hostTarget)
            @($buildResults[0].Artifacts).Count | Should -Be 1
            $artifact = @($buildResults[0].Artifacts)[0]
            $artifact.Architecture | Should -BeExactly $hostTarget
            $artifact.Length | Should -BeGreaterThan 0
            $artifact.SHA256 | Should -Match '^[0-9A-F]{64}$'
            Test-Path -LiteralPath $artifact.Path -PathType Leaf |
                Should -BeTrue
            $buildResults[0].HashManifestPath | Should -BeNullOrEmpty
            Test-Path -LiteralPath (Join-Path $output `
                'Atlas-ElevationBootstrapHashes.psd1') | Should -BeFalse
            foreach ($name in $environmentNames) {
                [Environment]::GetEnvironmentVariable($name, 'Process') |
                    Should -BeExactly "atlas-bootstrap-test-$name"
            }
        }
        finally {
            foreach ($name in $environmentNames) {
                $value = if ($originalEnvironment[$name].Present) {
                    $originalEnvironment[$name].Value
                } else {
                    $null
                }
                [Environment]::SetEnvironmentVariable($name, $value, 'Process')
            }
        }
        Test-Path -LiteralPath (Join-Path $output `
            "AtlasElevationBootstrap-$hostTarget.exe") | Should -BeTrue
        $script:Build | Should -Match '/DATLAS_BOOTSTRAP_CONTRACT_HARNESS=1'
        $script:Build | Should -Match '\$harnessTimeoutMilliseconds\s*=\s*30000'
        $script:Build | Should -Match `
            '(?s)WaitForExit\(\$harnessTimeoutMilliseconds\).+?Kill\('
        $script:Build | Should -Match `
            '(?s)\$harnessLinkArguments = @\(.+?/manifest:no.+?\$harnessObjectPath'
        $script:Build | Should -Match `
            '(?s)Invoke-NativeTool -Tool \$lldPath -Arguments \$harnessLinkArguments.+?Contract-harness PE link'
        $harnessLinkBlock = [regex]::Match($script:Build,
            '(?s)\$harnessLinkArguments = @\((?<Body>.*?)\r?\n\s*\)\r?\n\s*Invoke-NativeTool -Tool \$lldPath')
        $harnessLinkBlock.Success | Should -BeTrue
        $harnessLinkBlock.Groups['Body'].Value | Should -Not -Match '\$resourcePath'
    }

    It 'rolls back both executables when the manifest-last replacement cannot commit' `
            -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
        $output = Join-Path $TestDrive 'publication-rollback'
        New-Item -Path $output -ItemType Directory -Force | Out-Null
        $payloadRoot = Split-Path -Parent $script:HashManifestPath
        $names = @(
            'AtlasElevationBootstrap-amd64.exe',
            'AtlasElevationBootstrap-arm64.exe',
            'Atlas-ElevationBootstrapHashes.psd1'
        )
        $before = [ordered]@{}
        foreach ($name in $names) {
            $destination = Join-Path $output $name
            Copy-Item -LiteralPath (Join-Path $payloadRoot $name) `
                -Destination $destination
            $item = Get-Item -LiteralPath $destination
            $before[$name] = [pscustomobject]@{
                Length = [long]$item.Length
                SHA256 = (Get-FileHash -LiteralPath $item.FullName `
                    -Algorithm SHA256).Hash
            }
        }

        $lock = [IO.File]::Open(
            (Join-Path $output 'Atlas-ElevationBootstrapHashes.psd1'),
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )
        try {
            { & $script:BuildPath -Architecture all -OutputDirectory $output `
                    -RunContractHarness | Out-Null } | Should -Throw
        }
        finally {
            $lock.Dispose()
        }

        foreach ($name in $names) {
            $path = Join-Path $output $name
            $item = Get-Item -LiteralPath $path
            $item.Length | Should -Be $before[$name].Length
            (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash |
                Should -BeExactly $before[$name].SHA256
        }
        @(Get-ChildItem -LiteralPath $output -Force |
            Where-Object Name -Match '^\..*\.(publish|backup)$').Count |
            Should -Be 0
    }
}
