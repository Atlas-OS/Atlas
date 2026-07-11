[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester BeforeAll variables are consumed from child test scopes.'
)]
param()

BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    $coreManifest = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1'
    $coreRoot = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core'
    $scriptsRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts'
    Import-Module -Name $coreManifest -Force
    $coreModule = Get-Module Atlas.Core
    & $coreModule {
        Initialize-AtlasTrustedInstallerNativeType
        Initialize-AtlasElevationStorageType
    }
}

Describe 'Strict TrustedInstaller token evidence' {
    It 'requires SYSTEM, enabled non-deny-only TI SID, and System integrity' {
        $evaluate = [Atlas.TrustedInstallerProcessNative].GetMethod('IsStrictTrustedInstallerEvidence')
        $evaluate.Invoke($null, @('S-1-5-18', $false, [uint32]0, 0x4000)) | Should -BeFalse
        $evaluate.Invoke($null, @('S-1-5-18', $true, [uint32]0x4, 0x4000)) | Should -BeTrue
        $evaluate.Invoke($null, @('S-1-5-18', $true, [uint32]0x14, 0x4000)) | Should -BeFalse
        $evaluate.Invoke($null, @('S-1-5-21-1-2-3-1001', $true, [uint32]0x4, 0x4000)) | Should -BeFalse
        $evaluate.Invoke($null, @('S-1-5-18', $true, [uint32]0x10, 0x4000)) | Should -BeFalse
        $evaluate.Invoke($null, @('S-1-5-18', $true, [uint32]0, 0x4000)) | Should -BeFalse
        $evaluate.Invoke($null, @('S-1-5-18', $true, [uint32]0x4, 0x3000)) | Should -BeFalse
    }

    It 'loads native types idempotently and reports bounded current-process evidence' {
        { & $coreModule { Initialize-AtlasTrustedInstallerNativeType; Initialize-AtlasTrustedInstallerNativeType } } |
            Should -Not -Throw
        $evidence = [Atlas.TrustedInstallerProcessNative]::GetCurrentProcessEvidence()
        $evidence.ProcessId | Should -Be $PID
        $evidence.CreationFileTime | Should -BeGreaterThan 0
        $evidence.UserSid | Should -Match '^S-1-'
        $evidence.SessionId | Should -BeGreaterOrEqual 0
        [Atlas.TrustedInstallerProcessNative]::GetCurrentTokenEvidence().AuthenticationId |
            Should -Match '^[0-9A-F]{8}:[0-9A-F]{8}$'
    }
}

Describe 'Kernel-bound rendezvous pipe' {
    It 'enforces first-instance creation for the protected Atlas pipe name' {
        $requestId = '11111111222233334444555555555555'
        $binding = & $coreModule {
            param($id)
            New-AtlasElevationPipeServer -RequestId $id
        } $requestId
        try {
            $binding.Name | Should -BeExactly "AtlasOS.TrustedInstaller.$requestId"
            {
                $duplicate = [Atlas.ElevationPipeNative]::CreateFirstPipeServer(
                    $binding.Name,
                    [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
                )
                $duplicate.Dispose()
            } | Should -Throw
        }
        finally {
            $binding.Stream.Dispose()
        }
    }

    It 'rejects noncanonical request IDs before allocating a rendezvous pipe' {
        foreach ($invalidId in @(
                ('0' * 32), ('A' * 32), ('a' * 31), ('a' * 33), ('g' * 32),
                'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
            )) {
            $acceptedBinding = $null
            $rejected = $false
            try {
                $acceptedBinding = & $coreModule {
                    param($id)
                    New-AtlasElevationPipeServer -RequestId $id
                } $invalidId
            }
            catch {
                $rejected = $true
            }
            finally {
                if ($acceptedBinding) { $acceptedBinding.Stream.Dispose() }
            }
            $rejected | Should -BeTrue -Because 'a noncanonical request ID must throw before allocation'
            $acceptedBinding | Should -BeNullOrEmpty -Because 'the pipe name must use one canonical lowercase request ID'
        }
    }

    It 'derives the server PID, creation FILETIME, SID, and session from a real pipe handle' {
        $name = 'AtlasTest-' + [guid]::NewGuid().ToString('N')
        $server = New-Object IO.Pipes.NamedPipeServerStream(
            $name,
            [IO.Pipes.PipeDirection]::InOut,
            1,
            [IO.Pipes.PipeTransmissionMode]::Byte,
            [IO.Pipes.PipeOptions]::Asynchronous
        )
        $client = New-Object IO.Pipes.NamedPipeClientStream('.', $name, [IO.Pipes.PipeDirection]::InOut)
        try {
            $pending = $server.BeginWaitForConnection($null, $null)
            $client.Connect(2000)
            $server.EndWaitForConnection($pending)
            $evidence = [Atlas.TrustedInstallerProcessNative]::GetNamedPipeServerEvidence(
                $client.SafePipeHandle.DangerousGetHandle()
            )
            $evidence.ProcessId | Should -Be $PID
            $evidence.CreationFileTime | Should -BeGreaterThan 0
            $evidence.UserSid | Should -Be ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
            $evidence.SessionId | Should -Be ([Diagnostics.Process]::GetCurrentProcess().SessionId)

            $clientEvidence = [Atlas.ElevationPipeNative]::GetConnectedClientEvidence(
                $server.SafePipeHandle.DangerousGetHandle()
            )
            $clientEvidence.ProcessId | Should -Be $PID
            $clientEvidence.CreationFileTime | Should -Be $evidence.CreationFileTime
            [string]::Equals(
                [IO.Path]::GetFullPath($clientEvidence.ImagePath),
                [IO.Path]::GetFullPath([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName),
                [StringComparison]::OrdinalIgnoreCase
            ) | Should -BeTrue
            $clientEvidence.UserSid | Should -BeExactly $evidence.UserSid
            $clientEvidence.SessionId | Should -Be $evidence.SessionId
            $clientEvidence.IntegrityRid | Should -BeGreaterThan 0
            $clientEvidence.IsElevated | Should -BeOfType ([bool])
        }
        finally {
            $client.Dispose()
            $server.Dispose()
        }
    }

    It 'rejects any bootstrap peer that differs in generation, image, elevation, integrity, or session' {
        $imagePath = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $newEvidence = {
            return [pscustomobject]@{
                ProcessId        = 4242
                CreationFileTime = [long]123456789
                ImagePath        = $imagePath
                UserSid          = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
                SessionId        = 7
                IntegrityRid     = 0x3000
                IsElevated       = $true
            }
        }
        $spawned = & $newEvidence
        $connected = & $newEvidence
        {
            & $coreModule {
                param($spawnedEvidence, $connectedEvidence, $expectedPath)
                Assert-AtlasElevationBootstrapPeer `
                    -SpawnedEvidence $spawnedEvidence `
                    -ConnectedEvidence $connectedEvidence `
                    -ExpectedImagePath $expectedPath `
                    -ExpectedSessionId 7
            } $spawned $connected $imagePath
        } | Should -Not -Throw

        $mutations = @(
            @{ Property = 'ProcessId'; Value = 4243 },
            @{ Property = 'CreationFileTime'; Value = [long]123456790 },
            @{ Property = 'ImagePath'; Value = (Join-Path $TestDrive 'not-the-bootstrap.exe') },
            @{ Property = 'IsElevated'; Value = $false },
            @{ Property = 'IntegrityRid'; Value = 0x2000 },
            @{ Property = 'SessionId'; Value = 8 }
        )
        foreach ($mutation in $mutations) {
            $candidate = & $newEvidence
            $candidate.($mutation.Property) = $mutation.Value
            {
                & $coreModule {
                    param($spawnedEvidence, $connectedEvidence, $expectedPath)
                    Assert-AtlasElevationBootstrapPeer `
                        -SpawnedEvidence $spawnedEvidence `
                        -ConnectedEvidence $connectedEvidence `
                        -ExpectedImagePath $expectedPath `
                        -ExpectedSessionId 7
                } $spawned $candidate $imagePath
            } | Should -Throw -Because "$($mutation.Property) must match the fixed elevated bootstrap"
        }
    }
}

Describe 'Native noninteractive process source contract' {
    BeforeAll {
        $source = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\TrustedInstallerProcess.ps1') -Raw
    }

    It 'uses explicit application names, mutable command lines, and atomic parent plus inner-job attributes' {
        $source | Should -Match 'EntryPoint = "CreateProcessW"'
        $source | Should -Match 'CreateProcess\(string lpApplicationName, StringBuilder lpCommandLine'
        $source | Should -Match 'InitializeProcThreadAttributeList\(attributeList, 2'
        $source | Should -Match 'PROC_THREAD_ATTRIBUTE_PARENT_PROCESS'
        $source | Should -Match 'PROC_THREAD_ATTRIBUTE_JOB_LIST'
        $source | Should -Not -Match 'AssignProcessToJobObject'
    }

    It 'keeps the requester-session outer job on the broker and assigns only the dedicated inner job to the TrustedInstaller child' {
        $source | Should -Match `
            '(?s)IsProcessInJob\(GetCurrentProcess\(\), outerJobHandle, out brokerInOuterJob\).+?if \(!brokerInOuterJob\)'
        $source | Should -Match `
            '(?s)jobListBytes\s*=\s*checked\(IntPtr\.Size\);.+?Marshal\.WriteIntPtr\(jobValue, job\).+?UpdateProcThreadAttribute\(attributeList, 0, new UIntPtr\(PROC_THREAD_ATTRIBUTE_JOB_LIST\)'
        $source | Should -Not -Match 'jobListBytes\s*=\s*checked\(IntPtr\.Size \* 2\)'
        $source | Should -Not -Match `
            'Marshal\.WriteIntPtr\(jobValue,\s*(?:0,\s*)?outerJobHandle\)'
        $source | Should -Match `
            '(?s)IsProcessInJob\(processInfo\.hProcess, outerJobHandle, out inOuterJob\).+?if \(inOuterJob\).+?IsProcessInJob\(processInfo\.hProcess, job, out inAtlasJob\).+?if \(!inAtlasJob\).+?ReleaseOuterJobHandle\(request, ref outerJobHandle\).+?ThrowIfCancelled.+?ResumeThread'
        $source | Should -Match `
            '(?s)JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE.+?CreateProcess\(applicationPath, commandLine, IntPtr\.Zero, IntPtr\.Zero, false,.+?finally \{.+?if \(job != IntPtr\.Zero\) CloseHandle\(job\)'
    }

    It 'keeps native process argv quoting byte-for-byte aligned with the canonical protocol helper' {
        $application = 'C:\Program Files\Windows PowerShell\powershell.exe'
        $arguments = [string[]]@('', 'plain', 'two words', 'embedded"quote', 'C:\trailing\', '&|<>^%!', 'back\\slash"quote')
        $native = [Atlas.TrustedInstallerProcessNative]::BuildWindowsCommandLine($application, $arguments)
        $canonical = & $coreModule {
            param($file, $tokens)
            New-AtlasWindowsCommandLine -ApplicationPath $file -ArgumentList $tokens
        } $application $arguments
        $native | Should -BeExactly $canonical
    }

    It 'pins the supported 64-bit interop layouts and fails 32-bit before path or process work' {
        [IntPtr]::Size | Should -Be 8
        $flags = [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Public
        $nativeType = [Atlas.TrustedInstallerProcessNative]
        $sizeOfType = [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [type[]]@([type]))
        $sizeOfType.Invoke($null, @($nativeType.GetNestedType('STARTUPINFOEX', $flags))) | Should -Be 112
        $sizeOfType.Invoke($null, @($nativeType.GetNestedType('PROCESS_INFORMATION', $flags))) | Should -Be 24
        $sizeOfType.Invoke($null, @($nativeType.GetNestedType('JOBOBJECT_EXTENDED_LIMIT_INFORMATION', $flags))) | Should -Be 144
        $source | Should -Match '(?s)if \(IntPtr\.Size != 8\).+?GetNativeDirectory\(true\)'
    }

    It 'creates suspended, validates token/image/job, and only then resumes' {
        $source | Should -Match 'CREATE_SUSPENDED \| CREATE_UNICODE_ENVIRONMENT \| CREATE_NO_WINDOW \| EXTENDED_STARTUPINFO_PRESENT'
        $source | Should -Match '(?s)ValidateProcessImage\(processInfo\.hProcess.+?RequireTrustedInstaller\(childEvidence.+?IsProcessInJob.+?ResumeThread'
        $source | Should -Match 'childEvidence\.AuthenticationId, sourceEvidenceAgain\.AuthenticationId'
        $source | Should -Match 'childEvidence\.SessionId != sourceEvidenceAgain\.SessionId'
        $source | Should -Match 'JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE'
        $source | Should -Match 'JobObjectAssociateCompletionPortInformation'
        $source | Should -Match 'QueryInformationJobObject'
        $source | Should -Match 'TerminateJobObject'
        $source | Should -Match '!TerminateJobObject\(job, 0xC000013A\)'
        $source | Should -Match 'DrainTerminatedJob\(job, completionPort, 10000\)'
        $source | Should -Match 'could not authoritatively confirm that its privileged process tree drained'
        $source | Should -Not -Match 'DrainJobBestEffort'
        $source | Should -Match 'GetExitCodeProcess'
    }

    It 'releases root process references before using job accounting as the drain authority' {
        $source | Should -Match '(?s)GetExitCodeProcess\(processInfo\.hProcess, out exitCode\).+?rootExited = true;.+?CloseProcessInformationHandles\(ref processInfo\).+?UInt32 activeProcesses = QueryActiveProcesses\(job\)'
        $source | Should -Match '(?s)if \(rootExited && activeProcesses == 0\).+?JobDrained = true'
        $source | Should -Not -Match 'rootExited && sawActiveProcessZero'
        $source | Should -Match '(?s)try\s*{\s*if \(!TerminateJobObject\(job, 0xC000013A\)\).+?}\s*finally\s*{.+?CloseProcessInformationHandles\(ref processInfo\);\s*}\s*DrainTerminatedJob\(job, completionPort, 10000\)'
        $source | Should -Match '(?s)static void CloseProcessInformationHandles.+?processInfo\.hThread = IntPtr\.Zero.+?CloseHandle\(thread\).+?processInfo\.hProcess = IntPtr\.Zero.+?CloseHandle\(process\)'
        ([regex]::Matches($source, 'QueryActiveProcesses\(job\)')).Count | Should -Be 2
    }

    It 'uses only the SCM TrustedInstaller service with no generic SYSTEM-process fallback' {
        $source | Should -Match 'OpenService\(scm, "TrustedInstaller"'
        $source | Should -Match 'QueryServiceStatusEx'
        $source | Should -Match 'servicing", "TrustedInstaller\.exe"'
        $source | Should -Not -Match '(?i)lsass\.exe|winlogon\.exe|services\.exe'
        $source | Should -Not -Match 'GetProcessesByName'
    }

    It 'constructs an explicit environment and rejects inherited requester search paths' {
        $source | Should -Match 'BuildSanitizedEnvironment'
        $source | Should -Match 'SortedDictionary<string, string>\(StringComparer\.OrdinalIgnoreCase\)'
        $source | Should -Match 'environment\.Add\("TEMP", workingDirectory\)'
        $source | Should -Match 'environment\.Add\("PSModulePath"'
        $source | Should -Match 'environment\.Add\("PROCESSOR_ARCHITECTURE"'
        $source | Should -Match "block\.Append\('\\0'\)"
        $source | Should -Not -Match 'CreateEnvironmentBlock'
    }

    It 'uses a from-birth protected compiler directory whenever the importing host is privileged' {
        $source | Should -Match 'AtlasCompiler-'
        $source | Should -Match "GetMethod\(\s*'CreateDirectory'"
        $source | Should -Match 'A protected from-birth compiler directory is unavailable'
        $source | Should -Match 'Add-AtlasTrustedInstallerNativeType -TypeDefinition \$signature'
        (Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\ElevationStorage.ps1') -Raw) |
            Should -Match 'Add-AtlasTrustedInstallerNativeType -TypeDefinition \$signature'
        (Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\RunAsUser.ps1') -Raw) |
            Should -Match 'Add-AtlasTrustedInstallerNativeType -TypeDefinition \$signature'
    }

    It 'overlaps protected payload leases until the exact Ready frame is authenticated' {
        $brokerSource = Get-Content -LiteralPath (Join-Path $scriptsRoot 'Internal\Invoke-AtlasTrustedInstallerBroker.ps1') -Raw
        $privilegePath = Join-Path $coreRoot 'Domain\Privilege.ps1'
        $privilegeSource = Get-Content -LiteralPath $privilegePath -Raw
        $source | Should -Match 'ProtectedPayloadLease HoldFixedBrokerEntrypoint'
        $source | Should -Match 'AcquireProtectedPayloadLease\(atlasRoot\)'
        $source | Should -Match '"Scripts", "Toggles", "Tools", "Other"'
        $source | Should -Match 'new FileStream\(full, FileMode\.Open, FileAccess\.Read, FileShare\.Read\)'
        $source | Should -Match 'UInt32 shareMode = FILE_SHARE_READ \| \(allowDirectoryWrites \? FILE_SHARE_WRITE : 0\)'
        $source | Should -Not -Match 'FILE_SHARE_DELETE'

        $callerHold = $privilegeSource.IndexOf('HoldFixedBrokerEntrypoint', [StringComparison]::Ordinal)
        $callerReadyDecode = $privilegeSource.IndexOf(
            'ConvertFrom-AtlasElevationReadyBytes',
            [StringComparison]::Ordinal
        )
        $callerReadyBinding = $privilegeSource.IndexOf(
            'Assert-AtlasElevationReadyBinding',
            $callerReadyDecode,
            [StringComparison]::Ordinal
        )
        $callerLeaseRelease = $privilegeSource.IndexOf(
            '$heldBroker.Dispose()',
            $callerHold,
            [StringComparison]::Ordinal
        )
        $callerHold | Should -BeGreaterOrEqual 0
        $callerReadyDecode | Should -BeGreaterThan $callerHold
        $callerReadyBinding | Should -BeGreaterThan $callerReadyDecode
        $callerLeaseRelease | Should -BeGreaterThan $callerReadyBinding

        $brokerHold = $brokerSource.IndexOf(
            '$payloadLease = [Atlas.TrustedInstallerProcessNative]::HoldFixedBrokerEntrypoint',
            [StringComparison]::Ordinal
        )
        $brokerReadyWrite = $brokerSource.IndexOf(
            'Write-AtlasElevationFrame -Stream $stream -Kind Ready',
            $brokerHold,
            [StringComparison]::Ordinal
        )
        $brokerResultWrite = $brokerSource.IndexOf(
            'Write-AtlasElevationFrame -Stream $stream -Kind Result',
            $brokerReadyWrite,
            [StringComparison]::Ordinal
        )
        $brokerLeaseRelease = $brokerSource.IndexOf(
            '$payloadLease.Dispose()',
            $brokerHold,
            [StringComparison]::Ordinal
        )
        $brokerHold | Should -BeGreaterOrEqual 0
        $brokerReadyWrite | Should -BeGreaterThan $brokerHold
        $brokerResultWrite | Should -BeGreaterThan $brokerReadyWrite
        $brokerLeaseRelease | Should -BeGreaterThan $brokerResultWrite
    }

    It 'permits untrusted read-only payload access but rejects create, write, delete-child, or ACL mutation rights' {
        $validate = [Atlas.TrustedInstallerProcessNative].GetMethod(
            'ValidateFileSystemSecurity',
            [Reflection.BindingFlags]::Static -bor [Reflection.BindingFlags]::NonPublic
        )
        $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
        $users = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')
        $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
            [Security.AccessControl.InheritanceFlags]::ObjectInherit
        $allow = [Security.AccessControl.AccessControlType]::Allow

        $readOnly = New-Object Security.AccessControl.DirectorySecurity
        $readOnly.SetOwner($administrators)
        $readOnly.SetAccessRuleProtection($true, $false)
        [void]$readOnly.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
            $users,
            [Security.AccessControl.FileSystemRights]::ReadAndExecute,
            $inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            $allow
        )))
        { [void]$validate.Invoke($null, [object[]]@($readOnly.PSObject.BaseObject, 'read-only fixture')) } |
            Should -Not -Throw

        foreach ($unsafeRight in @(
            [Security.AccessControl.FileSystemRights]::WriteData,
            [Security.AccessControl.FileSystemRights]::AppendData,
            [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles,
            [Security.AccessControl.FileSystemRights]::ChangePermissions
        )) {
            $writable = New-Object Security.AccessControl.DirectorySecurity
            $writable.SetOwner($administrators)
            $writable.SetAccessRuleProtection($true, $false)
            [void]$writable.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                $users,
                $unsafeRight,
                $inheritance,
                [Security.AccessControl.PropagationFlags]::None,
                $allow
            )))
            { [void]$validate.Invoke($null, [object[]]@($writable.PSObject.BaseObject, 'write-capable fixture')) } |
                Should -Throw
        }
    }

    It 'contains no public arbitrary executable or argv request properties' {
        $requestType = [Atlas.TrustedInstallerLaunchRequest]
        $propertyNames = @($requestType.GetProperties().Name)
        foreach ($forbidden in @(
            'Executable', 'ApplicationPath', 'ScriptPath', 'Command', 'CommandLine',
                'Arguments', 'ArgumentList', 'Argv', 'InputPath',
                'RegistrySnapshotPath', 'ProtectedRequestPath', 'RequestPath', 'ResultPath',
                'StorageRoot', 'LivenessPipeName', 'TransportId'
            )) {
            $propertyNames | Should -Not -Contain $forbidden
        }
        @([Atlas.TrustedInstallerLaunchResult].GetProperties().Name) | Should -Be @(
            'Status', 'ExitCodeUInt32', 'RootProcessId', 'SourceProcessId',
            'SourceToken', 'ChildToken', 'RootExited', 'JobDrained'
        )
        $source | Should -Match 'The operation is outside the closed TrustedInstaller operation schema'
        $source | Should -Not -Match 'RegistryImport|reg\.exe'
    }

    It 'maps SafeModeRecovery only to the fixed protected carrier and one operation ID' {
        $requestType = [Atlas.TrustedInstallerLaunchRequest]
        @($requestType.GetProperties().Name) | Should -Contain 'SafeModeOperationId'

        $validateId = [Atlas.TrustedInstallerProcessNative].GetMethod(
            'RequireSafeModeOperationId',
            [Reflection.BindingFlags]::Static -bor [Reflection.BindingFlags]::NonPublic
        )
        $validateId.Invoke($null, @('1234567890abcdef1234567890abcdef')) |
            Should -BeExactly '1234567890abcdef1234567890abcdef'
        foreach ($invalid in @(('0' * 32), ('A' * 32), ('a' * 31), '..\carrier.ps1')) {
            { [void]$validateId.Invoke($null, @($invalid)) } | Should -Throw
        }

        $validateState = [Atlas.TrustedInstallerProcessNative].GetMethod(
            'ValidateSafeModeRecoveryStateBytes',
            [Reflection.BindingFlags]::Static -bor [Reflection.BindingFlags]::NonPublic
        )
        $encoding = New-Object Text.UTF8Encoding($false, $true)
        $validBytes = $encoding.GetBytes(
            "ATLAS-SAFE-MODE-STATE|2`r`nOperationId=1234567890abcdef1234567890abcdef`r`nPhase=Prepared`r`n"
        )
        { [void]$validateState.Invoke($null, [object[]]@($validBytes, '1234567890abcdef1234567890abcdef')) } |
            Should -Not -Throw
        $invalidStates = New-Object 'System.Collections.Generic.List[byte[]]'
        $invalidStates.Add($encoding.GetBytes(
                "ATLAS-SAFE-MODE-STATE|2`r`nOperationId=abcdefabcdefabcdefabcdefabcdefab`r`n"
            ))
        $invalidStates.Add($encoding.GetBytes(
                "ATLAS-SAFE-MODE-STATE|2`nOperationId=1234567890abcdef1234567890abcdef`n"
            ))
        $invalidStates.Add($encoding.GetBytes(
                "ATLAS-SAFE-MODE-STATE|1`r`nOperationId=1234567890abcdef1234567890abcdef`r`n"
            ))
        $invalidStates.Add([byte[]]@(0xEF, 0xBB, 0xBF, 0x41))
        $invalidStates.Add([byte[]]@(0xFF))
        $invalidStates.Add($encoding.GetBytes(
                "ATLAS-SAFE-MODE-STATE|2`r`nOperationId=1234567890abcdef1234567890abcdef`r`n$([char]0)`r`n"
            ))
        foreach ($invalidBytes in $invalidStates) {
            { [void]$validateState.Invoke($null, [object[]]@($invalidBytes, '1234567890abcdef1234567890abcdef')) } |
                Should -Throw
        }

        $source | Should -Match 'Path\.Combine\(windowsDirectory, "AtlasOS"\)'
        $source | Should -Match 'Path\.Combine\(protectedAtlasRoot, "SafeModeRecovery"\)'
        $source | Should -Match 'Path\.Combine\(recoveryRoot, "Recover-AtlasSafeMode\.ps1"\)'
        $source | Should -Match 'Path\.Combine\(recoveryRoot, "SafeMode-Recovery\.ps1"\)'
        $source | Should -Match 'Path\.Combine\(recoveryRoot, "transition\.state"\)'
        $source | Should -Match '(?s)OpenProtectedDirectory\(protectedAtlasRoot, true\).+?ValidateDirectorySecurity\(protectedAtlasRoot\).+?OpenProtectedDirectory\(recoveryRoot, false\).+?OpenProtectedFile\(carrierPath, true, recoveryRoot\).+?OpenProtectedFile\(helperPath, true, recoveryRoot\).+?ValidateSafeModeRecoveryStateBinding\(statePath, recoveryRoot, operationId\)'
        $source | Should -Match 'ATLAS-SAFE-MODE-STATE\|2\\r\\nOperationId='
        $source | Should -Match '(?s)"-File", carrierPath, "-OperationId", operationId'
        $source | Should -Not -Match '(?m)SafeModeRecovery.+(?:ApplicationPath|ScriptPath|ArgumentList|Arguments|Argv)'
    }
}

Describe 'Native relay storage contract' {
    BeforeAll {
        $storageSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\ElevationStorage.ps1') -Raw
        $privilegeSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\Privilege.ps1') -Raw
        $protocolSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\ElevationProtocol.ps1') -Raw
        $nativeSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\TrustedInstallerProcess.ps1') -Raw
        $brokerSource = Get-Content -LiteralPath (
            Join-Path $scriptsRoot 'Internal\Invoke-AtlasTrustedInstallerBroker.ps1'
        ) -Raw
    }

    It 'retains only first-instance pipe creation and exact peer-process evidence' {
        $storageSource | Should -Match 'FILE_FLAG_FIRST_PIPE_INSTANCE|FirstPipeInstance'
        $storageSource | Should -Match 'GetNamedPipeClientProcessId'
        $storageSource | Should -Match 'GetProcessTimes'
        $storageSource | Should -Match 'OpenProcessToken'
        $storageSource | Should -Match 'PIPE_REJECT_REMOTE_CLIENTS'
        $storageSource | Should -Match 'bInheritHandle\s*=\s*false'
        $storageSource | Should -Match 'D:P\(A;;FA;;;SY\)\(A;;FA;;;BA\)'
        $storageSource | Should -Match (
            'CreateNamedPipe\(.+?PIPE_REJECT_REMOTE_CLIENTS,\s*1,\s*65536,\s*65536'
        )
    }

    It 'contains no filesystem request, snapshot, sealed-result, or RegistryImport transport' {
        $allTransportSource = @(
            $storageSource, $privilegeSource, $protocolSource, $nativeSource, $brokerSource
        ) -join "`n"
        $allTransportSource | Should -Not -Match (
            '(?i)CreateRequest|WriteRequest|SnapshotRegistryInput|SealResult|' +
            'ReadAndValidateResult|Complete-AtlasElevationStorage|' +
            'Read-AtlasElevationStoredResult|Write-AtlasElevationStoredRequest|' +
            'New-AtlasElevationRegistrySnapshot'
        )
        $allTransportSource | Should -Not -Match (
            '(?i)request\.json|result\.(?:tmp|json)|input\.reg|' +
            '\b(?:ResultPath|RequestPath|RegistrySnapshotPath|ProtectedRequestPath|StorageRoot)\b'
        )
        $allTransportSource | Should -Not -Match '(?i)\bRegistryImport\b'
        ($storageSource + $privilegeSource + $protocolSource + $brokerSource) |
            Should -Not -Match '(?i)\b(?:Set-Content|Out-File|WriteAllText|WriteAllBytes|MoveFileEx)\b'
    }

    It 'uses one request ID correlation with no second transport ID or liveness pipe name' {
        foreach ($source in @(
                $storageSource, $privilegeSource, $protocolSource, $nativeSource, $brokerSource
            )) {
            $source | Should -Not -Match '(?i)\bTransportId\b|\bLivenessPipeName\b'
        }
        $privilegeSource | Should -Match (
            '(?s)New-AtlasElevationPipeServer\s+-RequestId\s+\$requestId.+?' +
            'StartElevationBootstrap\(.+?\$requestId.+?' +
            'Write-AtlasElevationFrame\s+-Stream\s+\$pipe\s+-Kind\s+Request\s+' +
            '-RequestId\s+\$requestId.+?' +
            'Read-AtlasElevationFrame\s+-Stream\s+\$pipe\s+-ExpectedKind\s+Ready.+?' +
            '-ExpectedRequestId\s+\$requestId.+?' +
            'Read-AtlasElevationFrame\s+-Stream\s+\$pipe\s+-ExpectedKind\s+Result.+?' +
            '-ExpectedRequestId\s+\$requestId'
        )
        $brokerSource | Should -Match '\$request\.requestId\s+-cne\s+\$ExpectedRequestId'
        $brokerSource | Should -Match '\}\s+\$requestStream\s+\$ExpectedRequestId'
        $brokerSource | Should -Match '\}\s+\$resultStream\s+\$ExpectedRequestId\s+\$readyBytes'
        $brokerSource | Should -Match '\}\s+\$resultStream\s+\$ExpectedRequestId\s+\$resultBytes'
    }
}

Describe 'Structured result binding and exit patterns' {
    BeforeAll {
        function New-TestElevationResultDocument {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
                'PSUseShouldProcessForStateChangingFunctions',
                '',
                Justification = 'This test helper only constructs an in-memory result document.'
            )]
            param(
                [uint64]$ExitCode = 0,
                [string]$Status = 'Completed',
                [AllowNull()][string]$CompletionState
            )

            if ([string]::IsNullOrEmpty($CompletionState)) {
                $CompletionState = if ($Status -ceq 'Completed') {
                    'Completed'
                }
                elseif ($Status -ceq 'CompletionUnknown') {
                    'CompletionUnknown'
                }
                else {
                    'NotStarted'
                }
            }

            $tiSid = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
            $newToken = {
                return [pscustomobject][ordered]@{
                    userSid                    = 'S-1-5-18'
                    trustedInstallerSid        = $tiSid
                    enabledTrustedInstallerSid = $true
                    integrityRid               = 0x4000
                    sessionId                  = 0
                    authenticationId           = '00000000:000003E7'
                }
            }
            return [pscustomobject][ordered]@{
                protocolVersion           = 2
                requestId                 = '11111111222233334444555555555555'
                requestSha256             = ('A' * 64)
                requesterSid              = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
                requesterProcessId        = $PID
                requesterCreationFileTime = '01DB000000000000'
                requesterSessionId        = 1
                bootstrapProcessId        = if (@('Completed', 'CompletionUnknown') -ccontains $Status) { 8 } else { $null }
                bootstrapCreationFileTime = if (@('Completed', 'CompletionUnknown') -ccontains $Status) { '01DB000000000001' } else { $null }
                brokerProcessId           = if (@('Completed', 'CompletionUnknown') -ccontains $Status) { 9 } else { $null }
                brokerCreationFileTime    = if (@('Completed', 'CompletionUnknown') -ccontains $Status) { '01DB000000000002' } else { $null }
                rootProcessId             = if ($Status -ceq 'Completed') { 10 } else { $null }
                sourceProcessId           = if ($Status -ceq 'Completed') { 11 } else { $null }
                sourceToken               = if ($Status -ceq 'Completed') { & $newToken } else { $null }
                childToken                = if ($Status -ceq 'Completed') { & $newToken } else { $null }
                startedUtc                = '2026-07-10T12:00:00.0000000Z'
                endedUtc                  = '2026-07-10T12:00:01.0000000Z'
                status                    = $Status
                completionState           = $CompletionState
                exitCodeUInt32            = if ($Status -ceq 'Completed') { [uint64]$ExitCode } else { $null }
                rootExited                = $Status -ceq 'Completed'
                jobDrained                = $Status -ceq 'Completed'
                error                     = if ($Status -ceq 'Completed') { $null } else { 'failed' }
            }
        }
    }

    It 'round-trips exact UInt32 target exit patterns only with Completed status' -ForEach @(
        [uint64]0,
        [uint64]5,
        [uint64]259,
        [uint64]2147483653,
        [uint64]4294967295
    ) {
        $code = [uint64]$_
        $result = & $coreModule {
            param($document)
            $bytes = ConvertTo-AtlasElevationResultBytes -Result $document
            return ConvertFrom-AtlasElevationResultBytes -Bytes $bytes
        } (New-TestElevationResultDocument -ExitCode $code)
        @($result.PSObject.Properties.Name) | Should -Be @(
            'protocolVersion', 'requestId', 'requestSha256',
            'requesterSid', 'requesterProcessId', 'requesterCreationFileTime', 'requesterSessionId',
            'bootstrapProcessId', 'bootstrapCreationFileTime',
            'brokerProcessId', 'brokerCreationFileTime', 'rootProcessId', 'sourceProcessId',
            'sourceToken', 'childToken', 'startedUtc', 'endedUtc',
            'status', 'completionState', 'exitCodeUInt32', 'rootExited', 'jobDrained', 'error'
        )
        [uint64]$result.exitCodeUInt32 | Should -Be $code
        $result.status | Should -BeExactly 'Completed'
        $result.completionState | Should -BeExactly 'Completed'
        $result.requestSha256 | Should -Match '^[0-9A-F]{64}$'
        $result.bootstrapCreationFileTime | Should -Match '^[0-9A-F]{16}$'
        $result.brokerCreationFileTime | Should -Match '^[0-9A-F]{16}$'
    }

    It 'rejects an exit code on a non-completed result' {
        $document = New-TestElevationResultDocument -Status CompletionUnknown
        $document.exitCodeUInt32 = 1
        {
            & $coreModule {
                param($candidate)
                ConvertTo-AtlasCanonicalElevationResult $candidate
            } $document
        } | Should -Throw -ExpectedMessage '*must not publish target, token, exit, or positive containment evidence*'
    }

    It 'rejects noncanonical result JSON and invalid result byte sequences' {
        $canonicalBytes = & $coreModule {
            param($document)
            ConvertTo-AtlasElevationResultBytes -Result $document
        } (New-TestElevationResultDocument)
        $canonicalJson = [Text.Encoding]::UTF8.GetString($canonicalBytes)
        $reorderedJson = $canonicalJson -replace `
            '^\{"protocolVersion":2,"requestId":', '{"requestId":'
        $reorderedJson = $reorderedJson -replace `
            ',"requestSha256":', ',"protocolVersion":2,"requestSha256":'
        $extraJson = $canonicalJson.Substring(0, $canonicalJson.Length - 1) + ',"diagnostic":"forbidden"}'
        $duplicateJson = $canonicalJson -replace `
            '^\{"protocolVersion":2,', '{"protocolVersion":2,"protocolVersion":2,'

        $invalidRecords = New-Object 'System.Collections.Generic.List[byte[]]'
        $invalidRecords.Add([byte[]]@())
        $invalidRecords.Add((New-Object byte[] (64KB + 1)))
        $invalidRecords.Add(([byte[]]@(0xEF, 0xBB, 0xBF) + $canonicalBytes))
        $invalidRecords.Add([byte[]]@(0xFF))
        $invalidRecords.Add([Text.Encoding]::UTF8.GetBytes($reorderedJson))
        $invalidRecords.Add([Text.Encoding]::UTF8.GetBytes($extraJson))
        $invalidRecords.Add([Text.Encoding]::UTF8.GetBytes($duplicateJson))
        $invalidRecords.Add(([byte[]]$canonicalBytes + [byte[]]@(0x20)))
        foreach ($invalidBytes in $invalidRecords) {
            {
                & $coreModule {
                    param($bytes)
                    ConvertFrom-AtlasElevationResultBytes -Bytes $bytes
                } ([byte[]]$invalidBytes)
            } | Should -Throw
        }
    }

    It 'pins exactly four public status and completion-state pairs' {
        $expectedStates = @{
            Completed         = 'Completed'
            ConsentDenied     = 'NotStarted'
            NotStarted        = 'NotStarted'
            CompletionUnknown = 'CompletionUnknown'
        }
        foreach ($status in @('Completed', 'ConsentDenied', 'NotStarted', 'CompletionUnknown')) {
            foreach ($state in @('NotStarted', 'Completed', 'CompletionUnknown')) {
                $candidate = New-TestElevationResultDocument -Status $status -CompletionState $state
                $operation = {
                    & $coreModule {
                        param($document)
                        ConvertTo-AtlasCanonicalElevationResult -Result $document
                    } $candidate
                }
                if ($state -ceq $expectedStates[$status]) {
                    $operation | Should -Not -Throw -Because "$status/$state is one of the four public outcomes"
                }
                else {
                    $operation | Should -Throw -Because "$status cannot publish $state"
                }
            }
        }

        foreach ($staleStatus in @(
                'LaunchFailure', 'BrokerCrashedOrProtocolFailure', 'TimedOut', 'Failed'
            )) {
            $candidate = New-TestElevationResultDocument -Status $staleStatus
            {
                & $coreModule {
                    param($document)
                    ConvertTo-AtlasCanonicalElevationResult -Result $document
                } $candidate
            } | Should -Throw -Because "$staleStatus is not a v2 public result status"
        }

        $ambiguousWithExit = New-TestElevationResultDocument -Status CompletionUnknown
        $ambiguousWithExit.exitCodeUInt32 = [uint64]0
        {
            & $coreModule {
                param($document)
                ConvertTo-AtlasCanonicalElevationResult -Result $document
            } $ambiguousWithExit
        } | Should -Throw -ExpectedMessage '*must not publish target, token, exit, or positive containment evidence*'

        foreach ($mutation in @(
                @{ Property = 'status'; Value = 'completed' },
                @{ Property = 'status'; Value = 'completionunknown' },
                @{ Property = 'completionState'; Value = 'completed' },
                @{ Property = 'completionState'; Value = 'completionunknown' },
                @{ Property = 'completionState'; Value = '' },
                @{ Property = 'completionState'; Value = 'UnknownValue' }
            )) {
            $candidate = New-TestElevationResultDocument
            $candidate.($mutation.Property) = $mutation.Value
            {
                & $coreModule {
                    param($document)
                    ConvertTo-AtlasCanonicalElevationResult -Result $document
                } $candidate
            } | Should -Throw -Because "$($mutation.Property) is an exact case-sensitive enum"
        }
    }

    It 'enforces the non-completed evidence and generation nullability matrix' {
        $completed = New-TestElevationResultDocument
        foreach ($status in @('ConsentDenied', 'NotStarted', 'CompletionUnknown')) {
            foreach ($mutation in @(
                    @{ Property = 'rootProcessId'; Value = 10 },
                    @{ Property = 'sourceProcessId'; Value = 11 },
                    @{ Property = 'sourceToken'; Value = $completed.sourceToken },
                    @{ Property = 'childToken'; Value = $completed.childToken },
                    @{ Property = 'exitCodeUInt32'; Value = [uint64]0 },
                    @{ Property = 'rootExited'; Value = $true },
                    @{ Property = 'jobDrained'; Value = $true },
                    @{ Property = 'error'; Value = $null },
                    @{ Property = 'error'; Value = '' },
                    @{ Property = 'error'; Value = " `t " }
                )) {
                $candidate = New-TestElevationResultDocument -Status $status
                $candidate.($mutation.Property) = $mutation.Value
                {
                    & $coreModule {
                        param($document)
                        ConvertTo-AtlasCanonicalElevationResult -Result $document
                    } $candidate
                } | Should -Throw -Because "$status cannot publish $($mutation.Property)='$($mutation.Value)'"
            }
        }

        $notStartedWithBootstrap = New-TestElevationResultDocument -Status NotStarted
        $notStartedWithBootstrap.bootstrapProcessId = 8
        $notStartedWithBootstrap.bootstrapCreationFileTime = '01DB000000000001'
        {
            & $coreModule {
                param($document)
                ConvertTo-AtlasCanonicalElevationResult -Result $document
            } $notStartedWithBootstrap
        } | Should -Not -Throw

        $unknownWithBootstrapOnly = New-TestElevationResultDocument -Status CompletionUnknown
        $unknownWithBootstrapOnly.brokerProcessId = $null
        $unknownWithBootstrapOnly.brokerCreationFileTime = $null
        {
            & $coreModule {
                param($document)
                ConvertTo-AtlasCanonicalElevationResult -Result $document
            } $unknownWithBootstrapOnly
        } | Should -Not -Throw

        $invalidGenerationCases = @()
        $candidate = New-TestElevationResultDocument -Status ConsentDenied
        $candidate.bootstrapProcessId = 8
        $candidate.bootstrapCreationFileTime = '01DB000000000001'
        $invalidGenerationCases += $candidate
        $candidate = New-TestElevationResultDocument -Status NotStarted
        $candidate.bootstrapProcessId = 8
        $candidate.bootstrapCreationFileTime = '01DB000000000001'
        $candidate.brokerProcessId = 9
        $candidate.brokerCreationFileTime = '01DB000000000002'
        $invalidGenerationCases += $candidate
        $candidate = New-TestElevationResultDocument -Status CompletionUnknown
        $candidate.bootstrapProcessId = $null
        $candidate.bootstrapCreationFileTime = $null
        $candidate.brokerProcessId = $null
        $candidate.brokerCreationFileTime = $null
        $invalidGenerationCases += $candidate
        $candidate = New-TestElevationResultDocument -Status CompletionUnknown
        $candidate.bootstrapCreationFileTime = $null
        $invalidGenerationCases += $candidate
        $candidate = New-TestElevationResultDocument -Status CompletionUnknown
        $candidate.bootstrapProcessId = $null
        $candidate.bootstrapCreationFileTime = $null
        $invalidGenerationCases += $candidate

        foreach ($invalidGeneration in $invalidGenerationCases) {
            {
                & $coreModule {
                    param($document)
                    ConvertTo-AtlasCanonicalElevationResult -Result $document
                } $invalidGeneration
            } | Should -Throw
        }
    }

    It 'keeps the broker wire schema narrower than the public outcome union' {
        foreach ($wireStatus in @('Completed', 'CompletionUnknown')) {
            $document = New-TestElevationResultDocument -Status $wireStatus
            {
                & $coreModule {
                    param($candidate)
                    $bytes = ConvertTo-AtlasElevationResultBytes -Result $candidate
                    ConvertFrom-AtlasElevationResultBytes -Bytes $bytes
                } $document
            } | Should -Not -Throw
        }

        foreach ($callerStatus in @('ConsentDenied', 'NotStarted')) {
            $document = New-TestElevationResultDocument -Status $callerStatus
            {
                & $coreModule {
                    param($candidate)
                    ConvertTo-AtlasElevationResultBytes -Result $candidate
                } $document
            } | Should -Throw -ExpectedMessage '*Broker wire results allow only*'
        }

        $bootstrapOnly = New-TestElevationResultDocument -Status CompletionUnknown
        $bootstrapOnly.brokerProcessId = $null
        $bootstrapOnly.brokerCreationFileTime = $null
        {
            & $coreModule {
                param($candidate)
                ConvertTo-AtlasCanonicalElevationResult -Result $candidate
            } $bootstrapOnly
        } | Should -Not -Throw
        {
            & $coreModule {
                param($candidate)
                ConvertTo-AtlasElevationResultBytes -Result $candidate
            } $bootstrapOnly
        } | Should -Throw -ExpectedMessage '*Broker wire results allow only*'
    }

    It 'rejects noncanonical hashes, LUIDs, generation FILETIMEs, IDs, and TI service SID evidence' {
        $maximumFileTime = New-TestElevationResultDocument
        $maximumFileTime.requesterCreationFileTime = '7FFFFFFFFFFFFFFF'
        $maximumFileTime.bootstrapCreationFileTime = '7FFFFFFFFFFFFFFF'
        $maximumFileTime.brokerCreationFileTime = '7FFFFFFFFFFFFFFF'
        {
            & $coreModule {
                param($document)
                ConvertTo-AtlasCanonicalElevationResult -Result $document
            } $maximumFileTime
        } | Should -Not -Throw

        $mutations = @(
            @{ Path = 'requestSha256'; Value = ('a' * 64) },
            @{ Path = 'requesterCreationFileTime'; Value = '0000000000000000' },
            @{ Path = 'requesterCreationFileTime'; Value = '8000000000000000' },
            @{ Path = 'bootstrapProcessId'; Value = 0 },
            @{ Path = 'bootstrapCreationFileTime'; Value = '0000000000000000' },
            @{ Path = 'bootstrapCreationFileTime'; Value = '8000000000000000' },
            @{ Path = 'bootstrapCreationFileTime'; Value = '01db000000000001' },
            @{ Path = 'brokerProcessId'; Value = 0 },
            @{ Path = 'brokerCreationFileTime'; Value = '0000000000000000' },
            @{ Path = 'brokerCreationFileTime'; Value = '8000000000000000' },
            @{ Path = 'brokerCreationFileTime'; Value = '01db000000000002' },
            @{ Path = 'sourceToken.authenticationId'; Value = '00000000:000003e7' },
            @{ Path = 'childToken.authenticationId'; Value = '00000000:000003E8' },
            @{ Path = 'childToken.authenticationId'; Value = '00000000:000003e7' },
            @{ Path = 'sourceToken.userSid'; Value = 'S-1-5-19' },
            @{ Path = 'childToken.enabledTrustedInstallerSid'; Value = $false },
            @{ Path = 'sourceToken.integrityRid'; Value = 0x3000 },
            @{ Path = 'childToken.sessionId'; Value = 1 },
            @{ Path = 'sourceToken.trustedInstallerSid'; Value = 'S-1-5-18' },
            @{ Path = 'childToken.trustedInstallerSid'; Value = 'S-1-5-18' }
        )

        foreach ($mutation in $mutations) {
            $candidate = New-TestElevationResultDocument
            $parts = $mutation.Path.Split('.')
            if ($parts.Count -eq 1) {
                $candidate.($parts[0]) = $mutation.Value
            }
            else {
                $candidate.($parts[0]).($parts[1]) = $mutation.Value
            }
            {
                & $coreModule {
                    param($document)
                    ConvertTo-AtlasCanonicalElevationResult $document
                } $candidate
            } | Should -Throw -Because "$($mutation.Path) must remain canonical and generation-bound"
        }
    }

    It 'binds a completed result to the exact request, requester, bootstrap, broker, and exit code' {
        $document = New-TestElevationResultDocument -ExitCode 37
        $expected = @{
            RequestId                    = $document.requestId
            RequestSha256                = $document.requestSha256
            RequesterSid                 = $document.requesterSid
            RequesterProcessId           = $document.requesterProcessId
            RequesterCreationFileTime    = [Convert]::ToInt64($document.requesterCreationFileTime, 16)
            RequesterSessionId           = $document.requesterSessionId
            BootstrapProcessId           = $document.bootstrapProcessId
            BootstrapCreationFileTime    = [Convert]::ToInt64($document.bootstrapCreationFileTime, 16)
            BrokerProcessId              = $document.brokerProcessId
            BrokerCreationFileTime       = [Convert]::ToInt64($document.brokerCreationFileTime, 16)
            BootstrapExitCodeUInt32      = [uint32]37
        }
        {
            & $coreModule {
                param($result, $bindings)
                Test-AtlasElevationResultBinding -Result $result @bindings
            } $document $expected
        } | Should -Not -Throw

        $differentRequesterSid = if ($document.requesterSid -eq 'S-1-5-18') {
            'S-1-5-19'
        }
        else {
            'S-1-5-18'
        }
        $mismatches = @(
            @{ Name = 'RequestId'; Value = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
            @{ Name = 'RequestSha256'; Value = ('B' * 64) },
            @{ Name = 'RequesterSid'; Value = $differentRequesterSid },
            @{ Name = 'RequesterProcessId'; Value = ($document.requesterProcessId + 1) },
            @{ Name = 'RequesterCreationFileTime'; Value = [long]1 },
            @{ Name = 'RequesterSessionId'; Value = 2 },
            @{ Name = 'BootstrapProcessId'; Value = 7 },
            @{ Name = 'BootstrapCreationFileTime'; Value = [long]2 },
            @{ Name = 'BrokerProcessId'; Value = 10 },
            @{ Name = 'BrokerCreationFileTime'; Value = [long]3 },
            @{ Name = 'BootstrapExitCodeUInt32'; Value = [uint32]38 }
        )
        foreach ($mismatch in $mismatches) {
            $candidate = @{} + $expected
            $candidate[$mismatch.Name] = $mismatch.Value
            {
                & $coreModule {
                    param($result, $bindings)
                    Test-AtlasElevationResultBinding -Result $result @bindings
                } $document $candidate
            } | Should -Throw -Because "$($mismatch.Name) must be bound to the exact live evidence"
        }
    }

    It 'requires a failed bootstrap exit for a non-completed broker result' {
        $document = New-TestElevationResultDocument -Status CompletionUnknown
        $bindings = @{
            RequestId                    = $document.requestId
            RequestSha256                = $document.requestSha256
            RequesterSid                 = $document.requesterSid
            RequesterProcessId           = $document.requesterProcessId
            RequesterCreationFileTime    = [Convert]::ToInt64($document.requesterCreationFileTime, 16)
            RequesterSessionId           = $document.requesterSessionId
            BootstrapProcessId           = $document.bootstrapProcessId
            BootstrapCreationFileTime    = [Convert]::ToInt64($document.bootstrapCreationFileTime, 16)
            BrokerProcessId              = $document.brokerProcessId
            BrokerCreationFileTime       = [Convert]::ToInt64($document.brokerCreationFileTime, 16)
            BootstrapExitCodeUInt32      = [uint32]1
        }
        {
            & $coreModule {
                param($result, $expected)
                Test-AtlasElevationResultBinding -Result $result @expected
            } $document $bindings
        } | Should -Not -Throw

        $bindings.BootstrapExitCodeUInt32 = [uint32]0
        {
            & $coreModule {
                param($result, $expected)
                Test-AtlasElevationResultBinding -Result $result @expected
            } $document $bindings
        } | Should -Throw -ExpectedMessage '*cannot bind to a successful bootstrap exit code*'
    }
}

Describe 'Canonical Ready binding record' {
    BeforeAll {
        function New-TestElevationReadyDocument {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
                'PSUseShouldProcessForStateChangingFunctions',
                '',
                Justification = 'This test helper only constructs an in-memory readiness document.'
            )]
            param()

            return [pscustomobject][ordered]@{
                protocolVersion           = 2
                requestId                 = '11111111222233334444555555555555'
                requestSha256             = ('A' * 64)
                bootstrapProcessId        = 8
                bootstrapCreationFileTime = '01DB000000000001'
                brokerProcessId           = 9
                brokerCreationFileTime    = '01DB000000000002'
            }
        }
    }

    It 'round-trips only the exact canonical request, bootstrap, and broker generation fields' {
        $ready = New-TestElevationReadyDocument
        $result = & $coreModule {
            param($document)
            $bytes = ConvertTo-AtlasElevationReadyBytes -Ready $document
            [pscustomobject]@{
                Bytes = $bytes
                Ready = ConvertFrom-AtlasElevationReadyBytes -Bytes $bytes
            }
        } $ready

        @($result.Ready.PSObject.Properties.Name) | Should -Be @(
            'protocolVersion', 'requestId', 'requestSha256',
            'bootstrapProcessId', 'bootstrapCreationFileTime',
            'brokerProcessId', 'brokerCreationFileTime'
        )
        $result.Ready.requestId | Should -BeExactly $ready.requestId
        $result.Ready.requestSha256 | Should -BeExactly $ready.requestSha256
        $result.Ready.bootstrapProcessId | Should -Be $ready.bootstrapProcessId
        $result.Ready.bootstrapCreationFileTime | Should -BeExactly $ready.bootstrapCreationFileTime
        $result.Ready.brokerProcessId | Should -Be $ready.brokerProcessId
        $result.Ready.brokerCreationFileTime | Should -BeExactly $ready.brokerCreationFileTime
        $result.Bytes.Length | Should -BeGreaterThan 0
        $result.Bytes.Length | Should -BeLessOrEqual 4KB
    }

    It 'rejects noncanonical request bindings and bootstrap or broker generations' {
        $maximumFileTime = New-TestElevationReadyDocument
        $maximumFileTime.bootstrapCreationFileTime = '7FFFFFFFFFFFFFFF'
        $maximumFileTime.brokerCreationFileTime = '7FFFFFFFFFFFFFFF'
        {
            & $coreModule {
                param($document)
                ConvertTo-AtlasElevationReadyBytes -Ready $document
            } $maximumFileTime
        } | Should -Not -Throw

        $mutations = @(
            @{ Property = 'protocolVersion'; Value = 1 },
            @{ Property = 'requestId'; Value = ('0' * 32) },
            @{ Property = 'requestId'; Value = ('A' * 32) },
            @{ Property = 'requestSha256'; Value = ('a' * 64) },
            @{ Property = 'bootstrapProcessId'; Value = 0 },
            @{ Property = 'bootstrapCreationFileTime'; Value = '0000000000000000' },
            @{ Property = 'bootstrapCreationFileTime'; Value = '8000000000000000' },
            @{ Property = 'bootstrapCreationFileTime'; Value = '01db000000000001' },
            @{ Property = 'brokerProcessId'; Value = 0 },
            @{ Property = 'brokerCreationFileTime'; Value = '0000000000000000' },
            @{ Property = 'brokerCreationFileTime'; Value = '8000000000000000' },
            @{ Property = 'brokerCreationFileTime'; Value = '01db000000000002' }
        )

        foreach ($mutation in $mutations) {
            $candidate = New-TestElevationReadyDocument
            $candidate.($mutation.Property) = $mutation.Value
            {
                & $coreModule {
                    param($document)
                    ConvertTo-AtlasElevationReadyBytes -Ready $document
                } $candidate
            } | Should -Throw -Because "$($mutation.Property) must remain canonical and generation-bound"
        }
    }

    It 'binds caller-known Ready fields to the exact request and bootstrap generation' {
        $ready = New-TestElevationReadyDocument
        $envelope = [pscustomobject]@{
            Request = [pscustomobject]@{ requestId = $ready.requestId }
            Sha256 = $ready.requestSha256
        }
        $bootstrapEvidence = [pscustomobject]@{
            ProcessId = $ready.bootstrapProcessId
            CreationFileTime = [Convert]::ToInt64($ready.bootstrapCreationFileTime, 16)
        }
        {
            & $coreModule {
                param($record, $requestEnvelope, $processEvidence)
                Assert-AtlasElevationReadyBinding -Ready $record -Envelope $requestEnvelope `
                    -BootstrapEvidence $processEvidence
            } $ready $envelope $bootstrapEvidence
        } | Should -Not -Throw

        $mutations = @(
            @{ Property = 'requestId'; Value = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
            @{ Property = 'requestSha256'; Value = ('B' * 64) },
            @{ Property = 'bootstrapProcessId'; Value = 7 },
            @{ Property = 'bootstrapCreationFileTime'; Value = '01DB000000000003' }
        )
        foreach ($mutation in $mutations) {
            $candidate = New-TestElevationReadyDocument
            $candidate.($mutation.Property) = $mutation.Value
            {
                & $coreModule {
                    param($record, $requestEnvelope, $processEvidence)
                    Assert-AtlasElevationReadyBinding -Ready $record -Envelope $requestEnvelope `
                        -BootstrapEvidence $processEvidence
                } $candidate $envelope $bootstrapEvidence
            } | Should -Throw -Because "$($mutation.Property) must match caller-known evidence"
        }
    }

    It 'rejects diagnostics, freeform text, extra fields, reordered JSON, and trailing bytes' {
        foreach ($extraProperty in @('schemaVersion', 'message', 'log', 'error')) {
            $candidate = New-TestElevationReadyDocument
            Add-Member -InputObject $candidate -MemberType NoteProperty -Name $extraProperty -Value 'forbidden'
            {
                & $coreModule {
                    param($document)
                    ConvertTo-AtlasElevationReadyBytes -Ready $document
                } $candidate
            } | Should -Throw
        }

        $canonicalBytes = & $coreModule {
            param($document)
            ConvertTo-AtlasElevationReadyBytes -Ready $document
        } (New-TestElevationReadyDocument)
        $canonicalJson = [Text.Encoding]::UTF8.GetString($canonicalBytes)
        $reorderedJson = $canonicalJson -replace '^\{"protocolVersion":2,"requestId":', '{"requestId":'
        $reorderedJson = $reorderedJson -replace ',"requestSha256":', ',"protocolVersion":2,"requestSha256":'
        {
            & $coreModule {
                param($bytes)
                ConvertFrom-AtlasElevationReadyBytes -Bytes $bytes
            } ([Text.Encoding]::UTF8.GetBytes($reorderedJson))
        } | Should -Throw
        {
            & $coreModule {
                param($bytes)
                ConvertFrom-AtlasElevationReadyBytes -Bytes $bytes
            } ([byte[]](@($canonicalBytes) + 0x20))
        } | Should -Throw
    }

    It 'rejects empty, oversized, BOM-prefixed, and malformed UTF-8 readiness bytes' {
        $canonicalBytes = & $coreModule {
            param($document)
            ConvertTo-AtlasElevationReadyBytes -Ready $document
        } (New-TestElevationReadyDocument)
        $invalidRecords = New-Object 'System.Collections.Generic.List[byte[]]'
        $invalidRecords.Add([byte[]]@())
        $invalidRecords.Add((New-Object byte[] (4KB + 1)))
        $invalidRecords.Add(([byte[]]@(0xEF, 0xBB, 0xBF) + $canonicalBytes))
        $invalidRecords.Add([byte[]]@(0xFF))
        foreach ($invalidBytes in $invalidRecords) {
            {
                & $coreModule {
                    param($bytes)
                    ConvertFrom-AtlasElevationReadyBytes -Bytes $bytes
                } ([byte[]]$invalidBytes)
            } | Should -Throw
        }
    }
}

Describe 'Fixed broker and CLI source contracts' {
    BeforeAll {
        $brokerPath = Join-Path $scriptsRoot 'Internal\Invoke-AtlasTrustedInstallerBroker.ps1'
        $brokerSource = Get-Content -LiteralPath $brokerPath -Raw
        $cliPath = Join-Path $scriptsRoot 'Invoke-AtlasTrustedInstaller.ps1'
        $cliSource = Get-Content -LiteralPath $cliPath -Raw
        $privilegePath = Join-Path $coreRoot 'Domain\Privilege.ps1'
        $privilegeSource = Get-Content -LiteralPath $privilegePath -Raw
        $protocolSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\ElevationProtocol.ps1') -Raw
        $resultSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\ElevationResult.ps1') -Raw
        $storageSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\ElevationStorage.ps1') -Raw
        $nativeSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\TrustedInstallerProcess.ps1') -Raw
        $enginePath = Join-Path $modulesRoot 'Atlas.Toggles\Domain\Engine.ps1'
        $engineSource = Get-Content -LiteralPath $enginePath -Raw
        $tokens = $null
        $parseErrors = $null
        $cliAst = [Management.Automation.Language.Parser]::ParseFile(
            $cliPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if ($parseErrors.Count -ne 0) { throw 'The TrustedInstaller CLI did not parse for AST validation.' }
        $tokens = $null
        $parseErrors = $null
        $engineAst = [Management.Automation.Language.Parser]::ParseFile(
            $enginePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if ($parseErrors.Count -ne 0) { throw 'The toggle engine did not parse for AST validation.' }
        $tokens = $null
        $parseErrors = $null
        $brokerAst = [Management.Automation.Language.Parser]::ParseFile(
            $brokerPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if ($parseErrors.Count -ne 0) { throw 'The fixed broker did not parse for AST validation.' }
        $tokens = $null
        $parseErrors = $null
        $privilegeAst = [Management.Automation.Language.Parser]::ParseFile(
            $privilegePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if ($parseErrors.Count -ne 0) { throw 'The privilege boundary did not parse for AST validation.' }
    }

    It 'contains no shell evaluation, registry transport, task/service broker, or AME runner' {
        foreach ($source in @($brokerSource, $privilegeSource)) {
            $source | Should -Not -Match '(?i)\biex\b|Invoke-Expression|schtasks|Register-ScheduledTask|New-Service|sc\.exe\s+create|Volatile Environment|TermsRunAsTI|RunAsTI\.cmd|!task'
        }
        $brokerSource | Should -Not -Match 'Start-Process|EncodedCommand|\s-Command\s'
    }

    It 'reads the opaque request and writes Ready then Result only through inherited relay handles' {
        @($brokerAst.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }) |
            Should -Be @(
                'ExpectedRequestId', 'RequestHandle', 'ResultHandle', 'LivenessHandle',
                'OuterJobHandle', 'BootstrapProcessId', 'BootstrapCreationFileTime',
                'RequesterProcessId', 'RequesterCreationFileTime', 'RequesterSid',
                'RequesterSessionId'
            )
        $brokerSource | Should -Match 'Import-Module -Name \$coreManifest'
        $brokerSource | Should -Match (
            '\[IO\.FileStream\]::new\(\$safeHandle,\s*\$Access,\s*1,\s*\$false\)'
        )
        $brokerSource | Should -Match '(?s)Read-AtlasElevationFrame.+?Request.+?Write-AtlasElevationFrame.+?Ready.+?Write-AtlasElevationFrame.+?Result'
        $brokerSource | Should -Not -Match 'RequestBase64Url|LivenessPipeName|New-AtlasElevationStorage'
        $brokerSource | Should -Not -Match 'Write-AtlasElevationStoredRequest|Complete-AtlasElevationStorage'
        $brokerSource | Should -Match '(?s)\$requestFrame\s*=.+?Read-AtlasElevationFrame.+?-ExpectedKind\s+Request'
        $brokerSource | Should -Match '\$requestHash\s*=\s*\[string\]\$requestFrame\.PayloadSha256'
        $brokerSource | Should -Match (
            '(?s)ConvertFrom-AtlasElevationRequestBytes\s+-Bytes\s+\$bytes.+?' +
            '-ExpectedSha256\s+\$hash\s+-ExpectedRequestId\s+\$requestId'
        )
        $brokerSource | Should -Match '\}\s+\$requestFrame\.Payload\s+\$requestHash\s+\$ExpectedRequestId'
        $brokerSource | Should -Match 'ConvertTo-AtlasElevationReadyBytes\s+-Ready\s+\$document'
        $brokerSource | Should -Match 'Write-AtlasElevationFrame\s+-Stream\s+\$stream\s+-Kind\s+Ready'
        $brokerSource | Should -Match '\}\s+\$resultStream\s+\$ExpectedRequestId\s+\$readyBytes'
        $brokerSource | Should -Match 'ConvertTo-AtlasElevationResultBytes\s+-Result\s+\$document'
        $brokerSource | Should -Match 'Write-AtlasElevationFrame\s+-Stream\s+\$stream\s+-Kind\s+Result'
        $brokerSource | Should -Match '\}\s+\$resultStream\s+\$ExpectedRequestId\s+\$resultBytes'
    }

    It 'uses one nonzero lowercase 32-hex request ID for the pipe and fixed bootstrap only' {
        $privilegeSource | Should -Match "ToString\('N'\)\.ToLowerInvariant\(\)"
        $privilegeSource | Should -Match 'AtlasOS\.TrustedInstaller\.'
        $privilegeSource | Should -Match 'AtlasElevationBootstrap-(?:amd64|arm64)\.exe'
        $privilegeSource | Should -Match "'\^\[0-9a-f\]\{32\}\$'"
        $privilegeSource | Should -Match "'0' \* 32"
        $privilegeSource | Should -Not -Match 'ProcessStartInfo|\.Verb\s*=\s*''runas'''
        $privilegeSource | Should -Not -Match 'Invoke-AtlasTrustedInstallerBroker\.ps1.+RequestBase64Url'
    }

    It 'accepts a terminal result only after exact bootstrap exit and bounded channel EOF' {
        $privilegeSource | Should -Match `
            '\$postTerminalBootstrapExitTimeoutMilliseconds\s*=\s*45000'
        $privilegeSource | Should -Match (
            '(?s)Read-AtlasElevationFrame\s+-Stream\s+\$pipe\s+-ExpectedKind\s+Result.+?' +
            '\$bootstrapProcess\.WaitForExit\(\$postTerminalBootstrapExitTimeoutMilliseconds\).+?' +
            '\$bootstrapExitCodeUInt32\s*=\s*\$bootstrapProcess\.GetExitCodeUInt32\(\).+?' +
            'Assert-AtlasElevationStreamEof\s+-Stream\s+\$pipe\s+-TimeoutMilliseconds\s+10000.+?' +
            'Test-AtlasElevationResultBinding'
        )
        $protocolSource | Should -Match (
            '(?s)function\s+Assert-AtlasElevationStreamEof.+?' +
            'Invoke-AtlasElevationStreamOperation.+?-Count\s+1.+?' +
            'if\s*\(\$read\s+-ne\s+0\)'
        )
        $protocolSource | Should -Match (
            '(?s)\$Stream\.Dispose\(\).+?' +
            '\$pending\.AsyncWaitHandle\.WaitOne\(5000\).+?' +
            '\$Stream\.End(?:Read|Write)\(\$pending\)'
        )
    }

    It 'allows native cancellation cleanup to acknowledge caller pipe disposal before terminating by exact handle' {
        $privilegeSource | Should -Match (
            '(?s)\$cancellationAcknowledgeTimeoutMilliseconds\s*=\s*30000.+?' +
            '\$pipe\.Dispose\(\).+?' +
            '\$bootstrapProcess\.WaitForExit\(\$cancellationAcknowledgeTimeoutMilliseconds\).+?' +
            '\$bootstrapProcess\.Terminate\(\$cancelExitCode\)'
        )
        $privilegeSource | Should -Match (
            '(?s)\$bootstrapProcess\.Terminate\(\$cancelExitCode\).+?' +
            'if\s*\(-not\s+\$bootstrapProcess\.WaitForExit\(5000\)\)'
        )
    }

    It 'binds canonical Ready evidence to the exact request, bootstrap, and broker generations' {
        foreach ($field in @(
                'requestId', 'requestSha256',
                'bootstrapProcessId', 'bootstrapCreationFileTime',
                'brokerProcessId', 'brokerCreationFileTime'
            )) {
            $brokerSource | Should -Match ([regex]::Escape($field))
            $privilegeSource | Should -Match ([regex]::Escape($field))
        }
        $privilegeSource | Should -Match '(?s)-RequesterProcessId \$requesterEvidence\.ProcessId.+?-RequesterCreationFileTime \$requesterEvidence\.CreationFileTime'
        $protocolSource | Should -Match "'requesterProcessId'"
        $protocolSource | Should -Match "'requesterCreationFileTime'"
        ($brokerSource + $privilegeSource) | Should -Not -Match '(?i)ready.+?(?:message|log|stdout|stderr|errorText)'
    }

    It 'keeps the Ready payload canonical, minimal, and free of diagnostic text' {
        $brokerSource | Should -Match (
            '(?s)Ready.+?protocolVersion.+?requestId.+?requestSha256.+?' +
            'bootstrapProcessId.+?bootstrapCreationFileTime.+?' +
            'brokerProcessId.+?brokerCreationFileTime'
        )
        foreach ($forbidden in @(
                'message', 'log', 'stdout', 'stderr', 'stackTrace', 'exception', 'commandLine'
            )) {
            $brokerSource | Should -Not -Match "(?is)Ready.{0,1200}\b$forbidden\b"
        }
    }

    It 'exposes only the typed operation parameters in the CLI' {
        @($cliAst.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }) |
            Should -Be @(
                'Operation', 'Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart',
                'RestoreSource', 'RecoveryOperationId', 'TimeoutSeconds'
            )
        $operationParameter = $cliAst.ParamBlock.Parameters |
            Where-Object { $_.Name.VariablePath.UserPath -eq 'Operation' }
        $operationValidateSet = $operationParameter.Attributes |
            Where-Object { $_.TypeName.FullName -eq 'ValidateSet' }
        @($operationValidateSet.PositionalArguments | ForEach-Object { $_.SafeGetValue() }) |
            Should -Be @('Toggle', 'ResetServices', 'SafeModeRecovery')
        $cliSource | Should -Not -Match 'RegistryImport'
        $cliSource | Should -Match '\$parameters\.RecoveryOperationId = \$RecoveryOperationId'
    }

    It 'rejects operation inputs outside the selected CLI schema before module import' {
        $fixtureRoot = Join-Path $TestDrive 'TrustedInstallerCli'
        $fixtureModuleRoot = Join-Path $fixtureRoot 'Modules\Atlas.Core'
        [void](New-Item -ItemType Directory -Path $fixtureModuleRoot -Force)
        $fixtureCliPath = Join-Path $fixtureRoot 'Invoke-AtlasTrustedInstaller.ps1'
        Copy-Item -LiteralPath $cliPath -Destination $fixtureCliPath
        $utf8NoBom = New-Object Text.UTF8Encoding($false, $true)
        [IO.File]::WriteAllText(
            (Join-Path $fixtureModuleRoot 'Atlas.Core.psd1'),
            @'
@{
    RootModule = 'Atlas.Core.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'd30396bf-22ea-42f4-a68d-2ad7a6f7dbd1'
    FunctionsToExport = @('Invoke-AtlasTrustedInstaller')
}
'@,
            $utf8NoBom
        )
        [IO.File]::WriteAllText(
            (Join-Path $fixtureModuleRoot 'Atlas.Core.psm1'),
            @'
function Invoke-AtlasTrustedInstaller {
    [CmdletBinding()]
    param(
        [string]$Operation,
        [string]$Name,
        [string]$State,
        [bool]$Silent,
        [switch]$JustContext,
        [switch]$NoExplorerRestart,
        [string]$RestoreSource,
        [string]$RecoveryOperationId,
        [int]$TimeoutSeconds
    )
    return [pscustomobject][ordered]@{
        protocolVersion = 2
        status = 'TestSafetySentinel'
        exitCodeUInt32 = $null
        error = 'Validation failed open into the isolated fake module.'
    }
}
Export-ModuleMember -Function Invoke-AtlasTrustedInstaller
'@,
            $utf8NoBom
        )

        $invalidInvocations = @(
            @('-Operation', 'Toggle', '-Name', 'Test', '-State', 'Enable', '-RestoreSource', 'ToggleDefaults'),
            @('-Operation', 'ResetServices', '-RestoreSource', 'ToggleDefaults', '-Name', 'Test'),
            @('-Operation', 'SafeModeRecovery', '-RecoveryOperationId', '1234567890abcdef1234567890abcdef', '-Name', 'Test'),
            @('-Operation', 'SafeModeRecovery', '-RecoveryOperationId', '1234567890abcdef1234567890abcdef', '-JustContext')
        )

        foreach ($invalidInvocation in $invalidInvocations) {
            $output = & ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) `
                -NoLogo -NoProfile -NonInteractive -File $fixtureCliPath @invalidInvocation
            $LASTEXITCODE | Should -Be 1
            $result = $output | ConvertFrom-Json
            @($result.PSObject.Properties.Name) | Should -Be @('schema', 'code', 'error')
            $result.schema | Should -BeExactly 'AtlasElevationCliError/1'
            $result.code | Should -BeExactly 'CallerValidationFailure'
            $result.PSObject.Properties.Name | Should -Not -Contain 'protocolVersion'
            $result.PSObject.Properties.Name | Should -Not -Contain 'status'
            $result.error | Should -Match 'does not accept the operation input'
        }
    }

    It 'dispatches SafeModeRecovery as ID-only data into the common contained native boundary' {
        $nativeSource = Get-Content -LiteralPath (Join-Path $coreRoot 'Domain\TrustedInstallerProcess.ps1') -Raw
        $brokerSource | Should -Match '(?s)''SafeModeRecovery''\s*\{\s*\$launchParameters\.RecoveryOperationId = \$request\.operationData\.operationId\s*\}'
        $privilegeSource | Should -Match '(?s)''SafeModeRecovery''\s*\{.+?operationId = \$RecoveryOperationId.+?\}'
        $nativeSource | Should -Match '(?s)String\.Equals\(request\.Operation, "SafeModeRecovery".+?"-File", carrierPath, "-OperationId", operationId.+?return;'
        $nativeSource | Should -Match '(?s)ResolveOperation\(.+?StartAndValidateTrustedInstallerService.+?CreateProcess\(.+?IsProcessInJob.+?ResumeThread'
        ($brokerSource + $cliSource + $privilegeSource + $nativeSource) |
            Should -Not -Match '(?m)^\s*(?:public\s+string|\[string\])\s+(?:RecoveryPath|CarrierPath|RecoveryArguments|RecoveryArgv)\b'
    }

    It 'leaves interactive terminal and unrelated privileged operations out of the closed enum' {
        $combined = $brokerSource + $cliSource + $privilegeSource
        $combined | Should -Not -Match 'TerminalPowerShell|SafeModePackageRecovery|InitializeNewUser'
    }

    It 'removes RegistryImport from every public, protocol, broker, and native boundary' {
        foreach ($source in @(
                $cliSource, $privilegeSource, $protocolSource, $nativeSource,
                $brokerSource, $storageSource
            )) {
            $source | Should -Not -Match 'RegistryImport'
        }
    }

    It 'pins the exact operation-specific parameter and payload allowlists' {
        $privilegeSource | Should -Match "Toggle\s*=\s*@\('Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart'\)"
        $privilegeSource | Should -Match "ResetServices\s*=\s*@\('RestoreSource'\)"
        $privilegeSource | Should -Match "SafeModeRecovery\s*=\s*@\('RecoveryOperationId'\)"
        $protocolSource | Should -Match "@\('name', 'state', 'silent', 'justContext', 'noExplorerRestart'\)"
        $protocolSource | Should -Match "@\('restoreSource'\)"
        $protocolSource | Should -Match "@\('operationId'\)"
        ($privilegeSource + $protocolSource + $brokerSource) | Should -Not -Match (
            '(?i)(?:\$request(?:\.operationData)?|\$operationData)\s*\.' +
            '(?:commandLine|executable|scriptPath|argumentList|arguments|argv)\b'
        )
    }

    It 'requires a Toggle definition to declare exactly TrustedInstaller before its action runs' {
        $engineFunction = $engineAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasToggle'
            }, $true)
        $engineFunction | Should -Not -BeNullOrEmpty
        $guards = @($engineFunction.Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.IfStatementAst] -and
                        $node.Extent.Text -match "Test-AtlasTrustedInstaller" -and
                        $node.Extent.Text -match '\[string\]\$definition\.Elevation\s+-cne\s+''TrustedInstaller'''
                }, $true))
        $guards.Count | Should -Be 1
        $guard = $guards[0]
        $guard.Parent | Should -BeOfType ([Management.Automation.Language.NamedBlockAst])
        @($guard.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.ThrowStatementAst]
                }, $true)).Count | Should -BeGreaterThan 0

        $coreCalls = @($engineFunction.Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                        $node.GetCommandName() -eq 'Invoke-AtlasToggleInProcess'
                }, $true))
        $coreCalls.Count | Should -Be 1
        $coreCalls[0].Extent.StartOffset | Should -BeGreaterThan $guard.Extent.EndOffset

        $coreFunction = $engineAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasToggleInProcess'
            }, $true)
        $coreFunction | Should -Not -BeNullOrEmpty
        $actionCalls = @($coreFunction.Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                        $node.GetCommandName() -eq 'Invoke-AtlasToggleAction'
                }, $true))
        $actionCalls.Count | Should -BeGreaterThan 0
    }

    It 'binds v2 result identity to canonical hashes, generations, and the exact TI service SID' {
        foreach ($field in @(
                'bootstrapProcessId', 'bootstrapCreationFileTime',
                'brokerProcessId', 'brokerCreationFileTime'
            )) {
            $resultSource | Should -Match ([regex]::Escape($field))
        }
        $resultSource | Should -Match "-cnotmatch\s+'\^\[0-9A-F\]\{64\}\$'"
        $resultSource | Should -Match "-cnotmatch\s+'\^\[0-9A-F\]\{8\}:\[0-9A-F\]\{8\}\$'"
        $resultSource | Should -Match ([regex]::Escape(
                'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
            ))
    }

    It 'classifies ambiguity after request transmission begins as CompletionUnknown and never retries' {
        $resultSource | Should -Match (
            "@\(\s*'Completed',\s*'ConsentDenied',\s*'NotStarted',\s*" +
            "'CompletionUnknown'\s*\)"
        )
        $privilegeSource | Should -Match (
            '(?s)\$requestTransmissionStarted\s*=\s*\$true\s*' +
            'Write-AtlasElevationFrame\s+-Stream\s+\$pipe\s+-Kind\s+Request'
        )
        $privilegeSource | Should -Match (
            '(?s)\$status\s*=\s*if\s*\(\$requestTransmissionStarted\)' +
            '\s*\{\s*''CompletionUnknown''\s*\}\s*else\s*' +
            '\{\s*''NotStarted''\s*\}'
        )
        $privilegeSource | Should -Not -Match '\$requestSent\b'
        $privilegeFunction = $privilegeAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasTrustedInstaller'
            }, $true)
        $bootstrapCalls = @($privilegeFunction.Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.InvokeMemberExpressionAst] -and
                        $node.Extent.Text -match '^\[Atlas\.ElevationPipeNative\]::StartElevationBootstrap\('
                }, $true))
        $bootstrapCalls.Count | Should -Be 1
        $ancestor = $bootstrapCalls[0].Parent
        while ($null -ne $ancestor -and $ancestor -ne $privilegeFunction) {
            ($ancestor -is [Management.Automation.Language.LoopStatementAst]) | Should -BeFalse
            $ancestor = $ancestor.Parent
        }
        @($privilegeFunction.Body.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                        $node.GetCommandName() -eq 'Invoke-AtlasTrustedInstaller'
                }, $true)).Count | Should -Be 0
        $resultSource | Should -Match 'completionState'
    }

    It 'maps ResetServices to PowerShell and every service definition has one declared default state' {
        $resetPath = Join-Path $scriptsRoot 'Internal\Invoke-AtlasResetServices.ps1'
        $resetSource = Get-Content -LiteralPath $resetPath -Raw
        $resetTokens = $null
        $resetParseErrors = $null
        $resetAst = [Management.Automation.Language.Parser]::ParseFile(
            $resetPath,
            [ref]$resetTokens,
            [ref]$resetParseErrors
        )
        $resetParseErrors.Count | Should -Be 0
        @($resetAst.ParamBlock.Parameters | ForEach-Object {
                $_.Name.VariablePath.UserPath
            }) | Should -Be @('RestoreSource')
        $resetSource | Should -Match 'Assert-AtlasPrivilege\s+-TrustedInstaller'
        $resetSource | Should -Not -Match `
            '(?i)Test-AtlasSystem|Assert-AtlasPrivilege\s+-System|RunAsTI|cmd\.exe|\.cmd''|\.cmd"|ComSpec'
        $resetSource | Should -Match `
            'Import-Module\s+-Name\s+\$togglesManifest\s+-Force\s+-PassThru'
        $resetSource | Should -Match `
            '\[IO\.Path\]::GetFullPath\(\[string\]\$togglesModule\.Path\)'
        $resetSource | Should -Match `
            '&\s+\$togglesModule\s+\{\s*Invoke-AtlasServiceDefaultsReset\s*\}'
        $resetSource | Should -Not -Match '\bInvoke-AtlasToggle\b'

        $resetFunction = $engineAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasServiceDefaultsReset'
            }, $true)
        $resetFunction | Should -Not -BeNullOrEmpty
        @($resetFunction.Body.ParamBlock.Parameters).Count | Should -Be 0
        $resetFunction.Extent.Text | Should -Match `
            'Assert-AtlasPrivilege\s+-TrustedInstaller'
        $resetFunction.Extent.Text | Should -Match `
            '(?s)NetworkDiscovery.+?completed\.ContainsKey\(''LanmanWorkstation''\)'
        $resetFunction.Extent.Text | Should -Match `
            'Invoke-AtlasToggleInProcess[\s\S]+?-ResetServices'

        $coreFunction = $engineAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasToggleInProcess'
            }, $true)
        $coreFunction | Should -Not -BeNullOrEmpty
        $coreFunction.Extent.Text | Should -Match `
            'ResetServices\s*=\s*\[bool\]\$ResetServices'

        $exportedToggleCommands = @(Get-Command -Module Atlas.Toggles | ForEach-Object { $_.Name })
        $exportedToggleCommands | Should -Not -Contain 'Invoke-AtlasToggleInProcess'
        $exportedToggleCommands | Should -Not -Contain 'Invoke-AtlasServiceDefaultsReset'

        $definitionsRoot = Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Toggles\Services'
        foreach ($file in @(Get-ChildItem -LiteralPath $definitionsRoot -File -Filter '*.ps1')) {
            $definition = & $file.FullName
            [string]$definition.Elevation | Should -BeExactly 'Admin'
            $defaults = @($definition.States.Keys | Where-Object {
                $entry = $definition.States[$_]
                $entry.Contains('Launcher') -and ([string]$entry.Launcher) -match '(?i)\(default\)'
            })
            $defaults.Count | Should -Be 1 -Because "$($file.Name) needs one fixed reset state"
        }

        $networkSource = Get-Content -LiteralPath `
            (Join-Path $definitionsRoot 'NetworkDiscovery.ps1') -Raw
        $networkSource | Should -Match `
            '(?s)if\s*\(-not\s+\$Toggle\.ResetServices\).+?Invoke-AtlasToggle.+?LanmanWorkstation'
    }
}
