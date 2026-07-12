BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    $coreModule = Get-Module -Name Atlas.Core
    & $coreModule { Initialize-AtlasRunAsUserType }
}

Describe 'Get-AtlasContext install state' {
    BeforeEach {
        & $coreModule { $script:AtlasContext = $null }
    }

    It 'maps the active install state and selected options into the shared context' {
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'Windows'
        [void][IO.Directory]::CreateDirectory($windowsPath)
        $transactionId = '31f30158-28ea-4e0c-86b5-d8f3e33b81f5'
        $state = [pscustomobject]@{
            mode          = 'Upgrade'
            isOobe        = $true
            targetVersion = '0.5.1'
            userSid       = 'S-1-5-21-1-2-3-1001'
            userSessionId = 7
            transactionId = $transactionId
            options       = @('defender-disable', 'browser-brave')
        }
        $observedPaths = [Collections.Generic.List[string]]::new()
        $stateReader = {
            param($path)
            [void]$observedPaths.Add($path)
            return $state
        }.GetNewClosure()

        $context = Get-AtlasContext -Refresh -WindowsPath $windowsPath `
            -StateReader $stateReader -WindowsBuildReader { 26100 }

        $observedPaths | Should -HaveCount 1
        $observedPaths[0] | Should -BeExactly (
            Join-Path -Path $windowsPath -ChildPath 'AtlasOS\Install\active.json'
        )
        $context.IsInstallStateBacked | Should -BeTrue
        $context.Mode | Should -BeExactly 'Upgrade'
        $context.IsUpgrade | Should -BeTrue
        $context.IsOobe | Should -BeTrue
        $context.TargetVersion | Should -BeExactly '0.5.1'
        $context.InteractiveUserSid | Should -BeExactly 'S-1-5-21-1-2-3-1001'
        $context.InteractiveUserSessionId | Should -Be 7
        $context.TransactionId | Should -BeExactly $transactionId
        $context.Options | Should -Be @('defender-disable', 'browser-brave')
        Test-AtlasOption -Name 'defender-disable' | Should -BeTrue
        Test-AtlasOption -Name 'browser-firefox' | Should -BeFalse
    }

    It 'uses published completion flags after active state is archived' {
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'FlagBackedWindows'
        $flagsPath = Join-Path -Path $windowsPath -ChildPath 'AtlasModules\Flags'
        [void][IO.Directory]::CreateDirectory($flagsPath)
        [IO.File]::WriteAllText((Join-Path $flagsPath 'Upgrade.flag'), '')
        [IO.File]::WriteAllText((Join-Path $flagsPath 'option-browser-firefox.flag'), '')

        $context = Get-AtlasContext -Refresh -WindowsPath $windowsPath `
            -StateReader { $null } -WindowsBuildReader { 19045 } -OobeReader { 1 }

        $context.IsInstallStateBacked | Should -BeFalse
        $context.Mode | Should -BeExactly 'Legacy'
        $context.IsUpgrade | Should -BeTrue
        $context.IsOobe | Should -BeTrue
        $context.TargetVersion | Should -BeNullOrEmpty
        $context.InteractiveUserSid | Should -BeNullOrEmpty
        $context.InteractiveUserSessionId | Should -BeNullOrEmpty
        $context.TransactionId | Should -BeNullOrEmpty
        $context.Options | Should -BeNullOrEmpty
        Test-AtlasOption -Name 'browser-firefox' | Should -BeTrue
        Test-AtlasOption -Name 'browser-brave' | Should -BeFalse
    }
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
        $commonParameters = @(
            'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction',
            'ProgressAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable',
            'OutVariable', 'OutBuffer', 'PipelineVariable'
        )
        $operationParameters = @($command.Parameters.Keys |
            Where-Object { $_ -cnotin $commonParameters } |
            Sort-Object)
        $expectedParameters = @(
            'Operation', 'Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart', 'MachineOnly',
            'RestoreSource', 'TimeoutSeconds'
        ) | Sort-Object
        $operationParameters | Should -Be $expectedParameters
    }

    It 'rejects incomplete typed operations before asking for elevation' {
        { Invoke-AtlasTrustedInstaller -Operation Toggle } |
            Should -Throw -ExpectedMessage '*requires typed -Name and -State*'
        { Invoke-AtlasTrustedInstaller -Operation ResetServices } |
            Should -Throw -ExpectedMessage '*requires a typed -RestoreSource*'
        { Invoke-AtlasTrustedInstaller -Operation RegistryImport } | Should -Throw
    }

    It 'rejects every operation input outside the selected operation schema' {
        { Invoke-AtlasTrustedInstaller -Operation Toggle -Name Test -State Enable `
                -RestoreSource ToggleDefaults } |
            Should -Throw -ExpectedMessage "*Toggle does not accept*'-RestoreSource'*"
        { Invoke-AtlasTrustedInstaller -Operation ResetServices -RestoreSource ToggleDefaults `
                -Name Test } |
            Should -Throw -ExpectedMessage "*ResetServices does not accept*'-Name'*"
        { Invoke-AtlasTrustedInstaller -Operation ResetServices -RestoreSource ToggleDefaults `
                -MachineOnly } |
            Should -Throw -ExpectedMessage "*ResetServices does not accept*'-MachineOnly'*"
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
