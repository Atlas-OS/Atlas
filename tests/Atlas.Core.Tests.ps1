BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    $coreModule = Get-Module -Name Atlas.Core
    & $coreModule { Initialize-AtlasRunAsUserType }
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
    It 'throws when the caller is not SYSTEM' {
        Mock Test-AtlasSystem { $false } -ModuleName Atlas.Core

        { Invoke-AtlasAsUser -FilePath 'C:\Windows\System32\cmd.exe' } |
            Should -Throw -ExpectedMessage '*must run as SYSTEM*'
    }

    It 'uses only the LocalSystem predicate at the interactive-user token boundary' {
        $runAsUserPath = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Domain\RunAsUser.ps1'
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $runAsUserPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $parseErrors.Count | Should -Be 0
        $function = $ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq 'Invoke-AtlasAsUser'
            }, $true)

        $function | Should -Not -BeNullOrEmpty
        $function.Extent.Text | Should -Match 'if\s*\(\s*-not\s*\(Test-AtlasSystem\)\s*\)'
        $function.Extent.Text | Should -Not -Match `
            'Test-AtlasTrustedInstaller|Assert-AtlasPrivilege\s+-TrustedInstaller'
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
    BeforeEach {
        Mock New-AtlasElevationPipeServer {
            throw 'TEST SAFETY SENTINEL: validation reached the kernel rendezvous boundary.'
        } -ModuleName Atlas.Core
    }

    It 'exports only the closed operation API and has no raw command surface' {
        $command = Get-Command Invoke-AtlasTrustedInstaller
        $command.Parameters.Keys | Should -Contain 'Operation'
        foreach ($forbidden in @(
                'CommandLine', 'Command', 'Executable', 'ScriptPath', 'ArgumentList',
                'Arguments', 'InputPath'
            )) {
            $command.Parameters.Keys | Should -Not -Contain $forbidden
        }
        $declaredParameters = @($command.ScriptBlock.Ast.Body.ParamBlock.Parameters |
            ForEach-Object { $_.Name.VariablePath.UserPath })
        $declaredParameters | Should -Be @(
            'Operation', 'Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart',
            'RestoreSource', 'RecoveryOperationId', 'TimeoutSeconds'
        )
    }

    It 'rejects incomplete typed operations before asking for elevation' {
        { Invoke-AtlasTrustedInstaller -Operation Toggle } |
            Should -Throw -ExpectedMessage '*requires typed -Name and -State*'
        { Invoke-AtlasTrustedInstaller -Operation ResetServices } |
            Should -Throw -ExpectedMessage '*requires a typed -RestoreSource*'
        { Invoke-AtlasTrustedInstaller -Operation SafeModeRecovery } |
            Should -Throw -ExpectedMessage '*requires -RecoveryOperationId*'
        { Invoke-AtlasTrustedInstaller -Operation RegistryImport } | Should -Throw
        { Invoke-AtlasTrustedInstaller -Operation Toggle -RecoveryOperationId '1234567890abcdef1234567890abcdef' } |
            Should -Throw -ExpectedMessage "*Toggle does not accept*'-RecoveryOperationId'*"
        { Invoke-AtlasTrustedInstaller -Operation SafeModeRecovery `
                 -RecoveryOperationId '1234567890abcdef1234567890abcdef' -Name Test } |
            Should -Throw -ExpectedMessage "*SafeModeRecovery does not accept*'-Name'*"
    }

    It 'rejects every operation input outside the selected operation schema' {
        { Invoke-AtlasTrustedInstaller -Operation Toggle -Name Test -State Enable `
                -RestoreSource ToggleDefaults } |
            Should -Throw -ExpectedMessage "*Toggle does not accept*'-RestoreSource'*"
        { Invoke-AtlasTrustedInstaller -Operation ResetServices -RestoreSource ToggleDefaults `
                -Name Test } |
            Should -Throw -ExpectedMessage "*ResetServices does not accept*'-Name'*"
        { Invoke-AtlasTrustedInstaller -Operation SafeModeRecovery `
                -RecoveryOperationId '1234567890abcdef1234567890abcdef' -Silent:$true } |
            Should -Throw -ExpectedMessage "*SafeModeRecovery does not accept*'-Silent'*"
    }

    It 'returns caller-generated failures with the complete versioned result shape' {
        $result = & $coreModule {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            New-AtlasCallerElevationResult `
                -Envelope ([pscustomobject]@{
                    Request = [pscustomobject]@{ requestId = '11111111222233334444555555555555' }
                    Sha256 = 'A' * 64
                }) `
                -RequesterEvidence ([pscustomobject]@{
                    UserSid = $sid
                    ProcessId = $PID
                    CreationFileTime = 1
                    SessionId = 0
                }) `
                -Status ConsentDenied `
                -CompletionState NotStarted `
                -ErrorMessage 'declined'
        }

        @($result.PSObject.Properties.Name) -join ',' | Should -BeExactly (@(
            'protocolVersion', 'requestId', 'requestSha256',
            'requesterSid', 'requesterProcessId', 'requesterCreationFileTime', 'requesterSessionId',
            'bootstrapProcessId', 'bootstrapCreationFileTime',
            'brokerProcessId', 'brokerCreationFileTime',
            'rootProcessId', 'sourceProcessId', 'sourceToken', 'childToken',
            'startedUtc', 'endedUtc', 'status', 'completionState',
            'exitCodeUInt32', 'rootExited', 'jobDrained', 'error'
        ) -join ',')
        $result.protocolVersion | Should -Be 2
        $result.status | Should -BeExactly 'ConsentDenied'
        $result.completionState | Should -BeExactly 'NotStarted'
        $result.bootstrapProcessId | Should -BeNullOrEmpty
        $result.bootstrapCreationFileTime | Should -BeNullOrEmpty
        $result.brokerProcessId | Should -BeNullOrEmpty
        $result.brokerCreationFileTime | Should -BeNullOrEmpty
        $result.startedUtc | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z$'
        $result.endedUtc | Should -BeExactly $result.startedUtc
    }

    It 'represents an ambiguity after request transmission begins as CompletionUnknown' {
        $result = & $coreModule {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            New-AtlasCallerElevationResult `
                -Envelope ([pscustomobject]@{
                    Request = [pscustomobject]@{ requestId = '11111111222233334444555555555555' }
                    Sha256 = 'A' * 64
                }) `
                -RequesterEvidence ([pscustomobject]@{
                    UserSid = $sid
                    ProcessId = $PID
                    CreationFileTime = 1
                    SessionId = 0
                }) `
                -Status CompletionUnknown `
                -CompletionState CompletionUnknown `
                -BootstrapProcessId 8 `
                -BootstrapCreationFileTime 2 `
                -BrokerProcessId 9 `
                -BrokerCreationFileTime 3 `
                -ErrorMessage 'Request transmission began before an ambiguous channel failure.'
        }

        $result.protocolVersion | Should -Be 2
        $result.status | Should -BeExactly 'CompletionUnknown'
        $result.completionState | Should -BeExactly 'CompletionUnknown'
        $result.bootstrapProcessId | Should -Be 8
        $result.bootstrapCreationFileTime | Should -BeExactly '0000000000000002'
        $result.brokerProcessId | Should -Be 9
        $result.brokerCreationFileTime | Should -BeExactly '0000000000000003'
        $result.exitCodeUInt32 | Should -BeNullOrEmpty
        $result.rootExited | Should -BeFalse
        $result.jobDrained | Should -BeFalse
    }

    It 'rejects mismatched caller status and completion-state pairs' {
        $invokeConstructor = {
            param($status, $completionState)
            & $coreModule {
                param($resultStatus, $resultCompletionState)
                $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
                New-AtlasCallerElevationResult `
                    -Envelope ([pscustomobject]@{
                        Request = [pscustomobject]@{ requestId = '11111111222233334444555555555555' }
                        Sha256 = 'A' * 64
                    }) `
                    -RequesterEvidence ([pscustomobject]@{
                        UserSid = $sid
                        ProcessId = $PID
                        CreationFileTime = 1
                        SessionId = 0
                    }) `
                    -Status $resultStatus `
                    -CompletionState $resultCompletionState `
                    -ErrorMessage 'test mismatch'
            } $status $completionState
        }

        { & $invokeConstructor CompletionUnknown NotStarted } | Should -Throw
        { & $invokeConstructor NotStarted CompletionUnknown } | Should -Throw
        { & $invokeConstructor completionunknown completionunknown } | Should -Throw
        { & $invokeConstructor consentdenied notstarted } | Should -Throw
    }
}

Describe 'Atlas privilege identity split' {
    It 'distinguishes LocalSystem from strict TrustedInstaller evidence' {
        Mock Get-AtlasCurrentUserSid { 'S-1-5-18' } -ModuleName Atlas.Core
        Mock Get-AtlasCurrentTokenEvidence {
            [pscustomobject]@{ IsSystem = $true; IsTrustedInstaller = $false }
        } -ModuleName Atlas.Core

        Test-AtlasSystem | Should -BeTrue
        Test-AtlasTrustedInstaller | Should -BeFalse
    }

    It 'fails closed when token evidence cannot be resolved' {
        Mock Get-AtlasCurrentUserSid { throw 'identity failed' } -ModuleName Atlas.Core
        Mock Get-AtlasCurrentTokenEvidence { throw 'translation failed' } -ModuleName Atlas.Core

        Test-AtlasSystem | Should -BeFalse
        Test-AtlasTrustedInstaller | Should -BeFalse
    }
}
