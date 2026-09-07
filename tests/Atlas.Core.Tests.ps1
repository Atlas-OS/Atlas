BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
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
            Start-AtlasInstallState -TargetVersion '0.6.0' -Mode Fresh `
                -StatePath $statePath | Out-Null

            Get-AtlasContext -Refresh -WindowsPath $windowsPath `
                -WindowsBuildReader { 26200 } -OobeReader { 0 } | Out-Null

            Get-Command -Name Invoke-AtlasInstallStep -ErrorAction Stop |
                Should -Not -BeNullOrEmpty
            @(Get-Module -Name Atlas.InstallState) | Should -HaveCount 1
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

Describe 'Write-AtlasLog fallback' {
    It 'routes unelevated diagnostics away from the protected machine log' {
        Mock Test-AtlasAdmin { $false } -ModuleName Atlas.Core
        Mock Get-AtlasContext { throw 'Unelevated logging must not resolve the machine log' } -ModuleName Atlas.Core
        Mock Test-Path { $true } -ModuleName Atlas.Core

        $actual = & $coreModule { Get-AtlasInstallLogDirectory }
        $expected = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'AtlasOS\Logs\install'
        $actual | Should -BeExactly $expected
    }

    It 'keeps elevated diagnostics in the protected machine log' {
        Mock Test-AtlasAdmin { $true } -ModuleName Atlas.Core
        Mock Get-AtlasContext { [pscustomobject]@{ LogsPath = 'C:\Windows\AtlasModules\Logs' } } -ModuleName Atlas.Core
        Mock Test-Path { $true } -ModuleName Atlas.Core

        (& $coreModule { Get-AtlasInstallLogDirectory }) |
            Should -BeExactly 'C:\Windows\AtlasModules\Logs\install'
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
                $Wait -and $CaptureOutput
            }
    }

    It 'uses the candidate broker for fresh install capture and run' {
        $payload = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Staging\candidate\Executables'
        foreach ($phase in @('Capture', 'Run')) {
            Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase $phase -PayloadRoot $payload | Out-Null
        }
        Should -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core -Times 2 -Exactly `
            -ParameterFilter {
                $ArgumentList -contains (Join-Path ([Environment]::GetFolderPath('Windows')) `
                    'AtlasOS\Staging\candidate\Executables\AtlasModules\Scripts\Entry\Invoke-AtlasTrustedInstallerBroker.ps1')
            }
    }

    It 'rejects install roots outside staging before starting a broker' {
        foreach ($payload in @('relative', 'C:\Users\Public\payload',
                'C:\Windows\AtlasOS\Staging-other\payload', 'C:\Windows\AtlasOS\Staging\..\payload')) {
            { Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase Capture -PayloadRoot $payload } | Should -Throw
        }
        Should -Not -Invoke Invoke-AtlasHiddenProcess -ModuleName Atlas.Core
    }

    It 'propagates a checked broker failure' {
        Mock Invoke-AtlasHiddenProcess { throw 'broker exited with disallowed code 5: failed' } `
            -ModuleName Atlas.Core

        {
            Invoke-AtlasTrustedInstaller -Operation Toggle -Name TestToggle -State Enable
        } | Should -Throw '*disallowed code 5*failed*'
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

Describe 'Import-AtlasModule' {
    It 'imports a sibling module from inside another module scope so its commands reach the caller' {
        # Companion functions run inside Atlas.Toggles and import Atlas.Appx or
        # Atlas.Download this way; the import must land in the caller-visible session.
        Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        Remove-Module -Name Atlas.Download -Force -ErrorAction SilentlyContinue

        & (Get-Module -Name Atlas.Toggles) { Import-AtlasModule -Name Atlas.Download }

        Get-Command -Name Get-AtlasTrustedWingetPath -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
        $context.IsUpgrade | Should -BeTrue
        $context.IsOobe | Should -BeFalse
        @($context.Options) | Should -Be @('defender-enable')
        $context.StateDocumentPath | Should -Be (Join-Path $windowsPath 'AtlasOS\state.json')
    }

    It 'falls back to the published flags when no document exists' {
        $windowsPath = Join-Path -Path $TestDrive -ChildPath 'Windows'
        $flags = Join-Path $windowsPath 'AtlasModules\Flags'
        [void][IO.Directory]::CreateDirectory($flags)
        foreach ($flag in 'Upgrade.flag', 'Interactive.flag', 'option-browser-brave.flag') {
            [IO.File]::WriteAllText((Join-Path $flags $flag), '')
        }

        $context = Get-AtlasContext -WindowsPath $windowsPath -StateReader { $null } `
            -DocumentReader { $null } -WindowsBuildReader { 26100 }

        $context.IsStateDocumentBacked | Should -BeFalse
        $context.IsUpgrade | Should -BeTrue
        $context.IsOobe | Should -BeFalse
        Test-Path (Join-Path $flags 'option-browser-brave.flag') | Should -BeTrue
    }
}

Describe 'Native assembly loader seam' {
    It 'only accepts a signed regular Atlas.Native.dll and otherwise compiles the source' {
        InModuleScope Atlas.Core {
            Test-AtlasNativeAssembly -Path (Join-Path $TestDrive 'absent.dll') | Should -BeFalse
            $unsigned = Join-Path $TestDrive 'Atlas.Native.dll'
            [IO.File]::WriteAllBytes($unsigned, [byte[]](0x4D, 0x5A, 0, 0))
            Test-AtlasNativeAssembly -Path $unsigned | Should -BeFalse
        }
        Initialize-AtlasNativeType
        ('Atlas.Native.TrustedInstallerProcess' -as [type]) | Should -Not -BeNullOrEmpty
    }
}
