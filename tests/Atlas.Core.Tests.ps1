BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = $script:AtlasTestModulesRoot
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    $coreModule = Get-Module -Name Atlas.Core
    & $coreModule { Initialize-AtlasNativeType }
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

    It 'keeps the orchestrator install-state commands loaded while reading active state' {
        $stateManifest = Join-Path -Path $modulesRoot `
            -ChildPath 'Atlas.InstallState\Atlas.InstallState.psd1'
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'ModuleLifetimeWindows'
        $statePath = Join-Path -Path $windowsPath -ChildPath 'AtlasOS\Install\active.json'
        try {
            Import-Module -Name $stateManifest -Force -DisableNameChecking
            $started = Start-AtlasInstallState -TargetVersion '0.6.0' -Mode Fresh `
                -StatePath $statePath
            $before = Get-Module -Name Atlas.InstallState

            $context = Get-AtlasContext -Refresh -WindowsPath $windowsPath `
                -WindowsBuildReader { 26200 } -OobeReader { 0 }

            $context.IsInstallStateBacked | Should -BeTrue
            $context.TransactionId | Should -BeExactly ([string]$started.transactionId)
            # Command lookup would autoload a torn-down module again from PSModulePath,
            # so check the function table and the module instance directly.
            Test-Path -LiteralPath Function:\Invoke-AtlasInstallStep | Should -BeTrue
            [object]::ReferenceEquals($before, (Get-Module -Name Atlas.InstallState)) | Should -BeTrue
        }
        finally {
            Remove-Module -Name Atlas.InstallState -Force -ErrorAction SilentlyContinue
        }
    }

    It 'uses published completion flags after active state is archived' {
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'FlagBackedWindows'
        $flagsPath = Join-Path -Path $windowsPath -ChildPath 'AtlasModules\Flags'
        [void][IO.Directory]::CreateDirectory($flagsPath)
        [IO.File]::WriteAllText((Join-Path $flagsPath 'Upgrade.flag'), '')
        [IO.File]::WriteAllText((Join-Path $flagsPath 'option-browser-firefox.flag'), '')

        $context = Get-AtlasContext -Refresh -WindowsPath $windowsPath `
            -StateReader { $null } -DocumentReader { $null } -WindowsBuildReader { 19045 } -OobeReader { 1 }

        $context.IsInstallStateBacked | Should -BeFalse
        $context.IsStateDocumentBacked | Should -BeFalse
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

Describe 'Write-AtlasLog fallback' {
    It 'routes unelevated diagnostics away from the protected machine log' {
        Mock Test-AtlasAdmin { $false } -ModuleName Atlas.Core
        Mock Get-AtlasContext { throw 'Unelevated logging must not resolve the machine log' } -ModuleName Atlas.Core
        Mock Test-Path { $true } -ModuleName Atlas.Core

        $expected = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'AtlasOS\Logs\install\atlas-install.log'
        Get-AtlasInstallLogPath | Should -BeExactly $expected
    }

    It 'keeps elevated diagnostics in the protected machine log without reading install state' {
        & $coreModule { $script:AtlasContext = $null }
        Mock Test-AtlasAdmin { $true } -ModuleName Atlas.Core
        Mock Get-AtlasContext { throw 'Elevated logging must not read the install-state documents' } -ModuleName Atlas.Core
        Mock Test-Path { $true } -ModuleName Atlas.Core

        $expected = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Logs\install\atlas-install.log'
        Get-AtlasInstallLogPath | Should -BeExactly $expected
    }

    It 'keeps elevated diagnostics in the log folder of a context that is already loaded' {
        # Elevated entry scripts load the context before anything logs.
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'LoadedContextWindows'
        [void][IO.Directory]::CreateDirectory($windowsPath)
        Get-AtlasContext -Refresh -WindowsPath $windowsPath -StateReader { $null } `
            -DocumentReader { $null } -WindowsBuildReader { 26100 } -OobeReader { 0 } | Out-Null
        try {
            Mock Test-AtlasAdmin { $true } -ModuleName Atlas.Core
            Mock Get-AtlasContext { throw 'Elevated logging must not reload the context' } -ModuleName Atlas.Core
            Mock Test-Path { $true } -ModuleName Atlas.Core

            $expected = Join-Path $windowsPath 'AtlasModules\Logs\install\atlas-install.log'
            Get-AtlasInstallLogPath | Should -BeExactly $expected
        }
        finally {
            & $coreModule { $script:AtlasContext = $null }
        }
    }

    It 'returns no log path instead of throwing when the log folder is unavailable' {
        Mock Test-AtlasAdmin { $false } -ModuleName Atlas.Core
        Mock Test-Path { $false } -ModuleName Atlas.Core
        Mock New-Item { throw 'simulated access denial' } -ModuleName Atlas.Core

        Get-AtlasInstallLogPath | Should -BeNullOrEmpty
    }

    It 'does not turn a log access failure into a terminating error under strict callers' {
        Mock Write-AtlasLogFile { throw 'simulated log access denial' } -ModuleName Atlas.Core

        {
            $ErrorActionPreference = 'Stop'
            Write-AtlasLog -Message 'best-effort diagnostic'
        } | Should -Not -Throw

        Should -Invoke Write-AtlasLogFile -ModuleName Atlas.Core -Times 1
    }
}

Describe 'Get-AtlasUserProcessCommandLine' {
    It 'quotes the executable and appends the raw arguments after one space: <Expected>' -TestCases @(
        @{ FilePath = 'C:\Program Files\x.exe'; Arguments = ''; Expected = '"C:\Program Files\x.exe"' }
        @{ FilePath = 'C:\x.exe'; Arguments = '-Flag "va lue"'; Expected = '"C:\x.exe" -Flag "va lue"' }
    ) {
        Get-AtlasUserProcessCommandLine -FilePath $FilePath -Arguments $Arguments |
            Should -BeExactly $Expected
    }
}

Describe 'Get-AtlasUserSessionHelperStage' {
    It 'names the stage for session-helper exit code <ExitCode>' -TestCases @(
        @{ ExitCode = 10; Expected = 'bootstrap' }
        @{ ExitCode = 12; Expected = 'process stop' }
        @{ ExitCode = 17; Expected = 'operation selection' }
    ) {
        Get-AtlasUserSessionHelperStage -ExitCode $ExitCode | Should -BeExactly $Expected
    }

    It 'returns $null for an exit code the session helper never uses' {
        $null -eq (Get-AtlasUserSessionHelperStage -ExitCode 1) | Should -BeTrue
    }
}

Describe 'Invoke-AtlasAsUser' {
    # Mocks only: the CreateProcessAsUser path must never launch anything from a test.
    It 'throws when the caller is not SYSTEM' {
        Mock Test-AtlasSystem { $false } -ModuleName Atlas.Core

        { Invoke-AtlasAsUser -FilePath 'C:\Windows\System32\cmd.exe' } |
            Should -Throw -ExpectedMessage '*must run as SYSTEM*'
    }
}

Describe 'Invoke-AtlasTrustedInstaller' {
    BeforeEach {
        Mock Assert-AtlasPrivilege -ModuleName Atlas.Core
        Mock Get-AtlasContext {
            [pscustomobject]@{
                WinDir = [Environment]::GetFolderPath('Windows')
                AtlasModulesPath = 'C:\Windows\AtlasModules'
            }
        } -ModuleName Atlas.Core
        Mock Invoke-AtlasHiddenProcess {
            [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' }
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
            'RestoreSource', 'InstallPhase', 'PayloadRoot', 'TimeoutSeconds'
        ) | Sort-Object
        $operationParameters | Should -Be $expectedParameters
    }

    It 'rejects incomplete typed operations before asking for elevation' {
        { Invoke-AtlasTrustedInstaller -Operation Toggle } |
            Should -Throw -ExpectedMessage '*requires typed -Name and -State*'
        { Invoke-AtlasTrustedInstaller -Operation ResetServices } |
            Should -Throw -ExpectedMessage '*requires a typed -RestoreSource*'
        { Invoke-AtlasTrustedInstaller -Operation RegistryImport } | Should -Throw
        Should -Invoke Assert-AtlasPrivilege -ModuleName Atlas.Core -Times 0 -Exactly
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
        { Invoke-AtlasTrustedInstaller -Operation Install -Name Test -InstallPhase Run `
                -PayloadRoot 'C:\Windows\AtlasOS\Staging\candidate\Executables' } |
            Should -Throw -ExpectedMessage "*Install does not accept*'-Name'*"
        { Invoke-AtlasTrustedInstaller -Operation Toggle -Name Test -State Enable -InstallPhase Run } |
            Should -Throw -ExpectedMessage "*Toggle does not accept*'-InstallPhase'*"
    }

    It 'passes only typed operation arguments to the fixed checked broker' {
        Invoke-AtlasTrustedInstaller -Operation Toggle -Name TestToggle -State Enable `
            -JustContext -TimeoutSeconds 42 | Out-Null

        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core -Times 1 -Exactly `
            -ParameterFilter {
                $FilePath -like '*\System32\WindowsPowerShell\v1.0\powershell.exe' -and
                @($ArgumentList | Where-Object {
                        $_ -like '*\Scripts\Entry\Invoke-AtlasTrustedInstallerBroker.ps1'
                    }).Count -eq 1 -and
                $ArgumentList -contains 'TestToggle' -and
                $ArgumentList -contains 'Enable' -and
                $ArgumentList -contains '-JustContext' -and
                $TimeoutSeconds -eq 57 -and
                $Wait -and $CaptureOutput -and
                $null -eq $AllowedExitCode
            }
    }

    It 'uses the candidate broker for fresh install <Phase>' -TestCases @(
        @{ Phase = 'Capture' }
        @{ Phase = 'Run' }
    ) {
        $payload = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Staging\candidate\Executables'
        $broker = Join-Path $payload 'AtlasModules\Scripts\Entry\Invoke-AtlasTrustedInstallerBroker.ps1'

        Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase $Phase -PayloadRoot $payload | Out-Null

        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core -Times 1 -Exactly `
            -ParameterFilter {
                $arguments = @($ArgumentList)
                $arguments[[array]::IndexOf($arguments, '-File') + 1] -eq $broker -and
                $arguments[[array]::IndexOf($arguments, '-Operation') + 1] -ceq 'Install' -and
                $arguments[[array]::IndexOf($arguments, '-InstallPhase') + 1] -ceq $Phase -and
                $arguments[[array]::IndexOf($arguments, '-PayloadRoot') + 1] -eq $payload
            }
    }

    It 'rejects install roots outside staging before starting a broker' {
        foreach ($payload in @('relative', 'C:\Users\Public\payload',
                'C:\Windows\AtlasOS\Staging-other\payload', 'C:\Windows\AtlasOS\Staging\..\payload')) {
            { Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase Capture -PayloadRoot $payload } | Should -Throw
        }
        Should -Not -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core
    }

    It 'runs the input-free CbsRetry operation through the installed broker' {
        Invoke-AtlasTrustedInstaller -Operation CbsRetry -TimeoutSeconds 3600 | Out-Null

        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core -Times 1 -Exactly `
            -ParameterFilter {
                $arguments = @($ArgumentList)
                $fileIndex = [array]::IndexOf($arguments, '-File')
                $arguments[$fileIndex + 1] -eq 'C:\Windows\AtlasModules\Scripts\Entry\Invoke-AtlasTrustedInstallerBroker.ps1' -and
                ($arguments[($fileIndex + 2)..($arguments.Count - 1)] -join ' ') -ceq '-Operation CbsRetry -TimeoutSeconds 3600' -and
                $TimeoutSeconds -eq 3615
            }
    }

    It 'rejects every operation input for CbsRetry' {
        { Invoke-AtlasTrustedInstaller -Operation CbsRetry -Name Test } |
            Should -Throw -ExpectedMessage "*CbsRetry does not accept*'-Name'*"
        { Invoke-AtlasTrustedInstaller -Operation CbsRetry -RestoreSource ToggleDefaults } |
            Should -Throw -ExpectedMessage "*CbsRetry does not accept*'-RestoreSource'*"
        { Invoke-AtlasTrustedInstaller -Operation CbsRetry -InstallPhase Run } |
            Should -Throw -ExpectedMessage "*CbsRetry does not accept*'-InstallPhase'*"
        Should -Not -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core
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

Describe 'Assert-AtlasPrivilege' {
    # Mocked probes take both branches of every guard whether or not Pester runs elevated.
    It 'allows -<Switch> when <Probe> confirms it' -TestCases @(
        @{ Switch = 'Administrator'; Probe = 'Test-AtlasAdmin' }
        @{ Switch = 'System'; Probe = 'Test-AtlasSystem' }
        @{ Switch = 'TrustedInstaller'; Probe = 'Test-AtlasTrustedInstaller' }
    ) {
        param($Switch, $Probe)
        Mock -CommandName $Probe -ModuleName Atlas.Core -MockWith { $true }
        $privilege = @{ $Switch = $true }

        { Assert-AtlasPrivilege @privilege } | Should -Not -Throw
        Should -Invoke -CommandName $Probe -ModuleName Atlas.Core -Times 1 -Exactly
    }

    It 'rejects -<Switch> when <Probe> denies it' -TestCases @(
        @{ Switch = 'Administrator'; Probe = 'Test-AtlasAdmin'; Message = '*requires Administrator rights*' }
        @{ Switch = 'System'; Probe = 'Test-AtlasSystem'; Message = '*requires LocalSystem*' }
        @{
            Switch = 'TrustedInstaller'; Probe = 'Test-AtlasTrustedInstaller'
            Message = '*requires a TrustedInstaller service token*'
        }
    ) {
        param($Switch, $Probe, $Message)
        Mock -CommandName $Probe -ModuleName Atlas.Core -MockWith { $false }
        $privilege = @{ $Switch = $true }

        { Assert-AtlasPrivilege @privilege } | Should -Throw -ExpectedMessage $Message
    }
}

Describe 'Import-AtlasModule' {
    It 'imports a sibling module from inside another module scope so its commands reach the caller' {
        # Companion functions run inside Atlas.Toggles and import Atlas.Appx or
        # Atlas.Download this way; the import must land in the caller-visible session.
        Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        Remove-Module -Name Atlas.Download -Force -ErrorAction SilentlyContinue

        & (Get-Module -Name Atlas.Toggles) { Import-AtlasModule -Name Atlas.Download }

        # Command lookup would autoload Atlas.Download from PSModulePath even if
        # nothing was imported, so check the session's modules and functions.
        $imported = @(Get-Module -Name Atlas.Download)
        $imported | Should -HaveCount 1
        $imported[0].ModuleBase | Should -Be (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Download')
        Test-Path -LiteralPath Function:\Get-AtlasTrustedWingetPath | Should -BeTrue
    }

    It 'rejects a name outside the Atlas module family and a missing manifest' {
        { Import-AtlasModule -Name 'Pester' } | Should -Throw
        { Import-AtlasModule -Name 'Atlas.DoesNotExist' } | Should -Throw '*manifest*is missing*'
    }
}

Describe 'Get-AtlasContext machine state document' {
    BeforeEach {
        & $coreModule { $script:AtlasContext = $null }
    }

    It 'reads installed version, mode and options from the state document after an install' {
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'Windows'
        [void][IO.Directory]::CreateDirectory($windowsPath)
        $document = [pscustomobject]@{
            installedVersion = '0.6.0'; mode = 'Upgrade'; isOobe = $false; isInteractive = $true
            options = @('defender-enable')
        }

        $context = Get-AtlasContext -WindowsPath $windowsPath -StateReader { $null } `
            -DocumentReader { $document } -WindowsBuildReader { 26100 }

        $context.IsInstallStateBacked | Should -BeFalse
        $context.IsStateDocumentBacked | Should -BeTrue
        $context.InstalledVersion | Should -Be '0.6.0'
        $context.Mode | Should -BeExactly 'Upgrade'
        $context.IsUpgrade | Should -BeTrue
        $context.IsOobe | Should -BeFalse
        @($context.Options) | Should -Be @('defender-enable')
        $context.StateDocumentPath | Should -Be (Join-Path $windowsPath 'AtlasOS\state.json')
    }

    It 'stays Legacy when the state document has no recorded mode' {
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'Windows'
        [void][IO.Directory]::CreateDirectory($windowsPath)
        $document = [pscustomobject]@{
            installedVersion = $null; mode = $null; isOobe = $false; isInteractive = $false; options = @()
        }

        $context = Get-AtlasContext -WindowsPath $windowsPath -StateReader { $null } `
            -DocumentReader { $document } -WindowsBuildReader { 26100 }

        $context.IsStateDocumentBacked | Should -BeTrue
        $context.Mode | Should -BeExactly 'Legacy'
    }

    It 'still counts as an update after a Reapply of an updated install, but not of a fresh one' -TestCases @(
        @{ First = 'Upgrade'; Expected = $true }
        @{ First = 'Rebase'; Expected = $true }
        @{ First = 'Fresh'; Expected = $false }
    ) {
        param($First, $Expected)
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'Windows'
        [void][IO.Directory]::CreateDirectory($windowsPath)
        $document = [pscustomobject]@{
            installedVersion = '0.6.0'; mode = 'Reapply'; isOobe = $false; isInteractive = $true; options = @()
            history = @(
                [pscustomobject]@{ version = '0.6.0'; mode = $First; completedAt = '2026-10-01T00:00:00Z'; transactionId = 'a' }
                [pscustomobject]@{ version = '0.6.0'; mode = 'Reapply'; completedAt = '2026-10-02T00:00:00Z'; transactionId = 'b' }
            )
        }

        $context = Get-AtlasContext -WindowsPath $windowsPath -StateReader { $null } `
            -DocumentReader { $document } -WindowsBuildReader { 26100 }

        $context.IsUpgrade | Should -Be $Expected
    }
}

Describe 'Native assembly loader seam' {
    It 'rejects an absent or unsigned prebuilt Atlas.Native.dll' {
        InModuleScope Atlas.Core {
            Test-AtlasNativeAssembly -Path (Join-Path $TestDrive 'absent.dll') | Should -BeFalse
            $unsigned = Join-Path $TestDrive 'Atlas.Native.dll'
            [IO.File]::WriteAllBytes($unsigned, [byte[]](0x4D, 0x5A, 0, 0))
            Test-AtlasNativeAssembly -Path $unsigned | Should -BeFalse
        }
    }

    It 'rejects a symbolic link to a validly signed file' {
        $signed = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'kernel32.dll'
        $link = Join-Path $TestDrive 'Linked\Atlas.Native.dll'
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $link))
        # Windows PowerShell's New-Item needs Administrator rights for a symbolic link;
        # mklink also works unelevated in Developer Mode.
        $null = cmd.exe /d /c mklink "$link" "$signed"
        if (-not (Test-Path -LiteralPath $link -PathType Leaf)) {
            Set-ItResult -Skipped -Because 'this host cannot create file symbolic links'
            return
        }

        InModuleScope Atlas.Core -Parameters @{ Signed = $signed; Link = $link } {
            param($Signed, $Link)
            Test-AtlasNativeAssembly -Path $Signed | Should -BeTrue
            Test-AtlasNativeAssembly -Path $Link | Should -BeFalse
        }
    }
}
