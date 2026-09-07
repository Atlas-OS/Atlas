param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    # The public adapter imports Atlas.Core for Test-AtlasAdmin; load the real module
    # once so the adapter tests can mock that command.
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    $script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $script:scriptsRoot = Join-Path -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts'
    $script:phasePath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Install\Phases\Invoke-ServicesPhase.ps1'
    $script:internalResetPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Entry\Restore-AtlasServiceDefaults.ps1'
    $script:publicResetPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Entry\Invoke-AtlasResetServices.ps1'
    $script:hostExecutable = (Get-Process -Id $PID).Path
    $script:wrapperPaths = @(
        (Join-Path -Path $script:repoRoot `
            -ChildPath 'playbook\Executables\AtlasDesktop\9. Troubleshooting\Set services to defaults.cmd')
        (Join-Path -Path $script:repoRoot `
            -ChildPath 'playbook\Executables\AtlasModules\Toolbox\Scripts\setServicesToDefaults.cmd')
        (Join-Path -Path $script:repoRoot `
            -ChildPath 'playbook\Executables\AtlasModules\Toolbox\Scripts\Troubleshooting\Set services to defaults.cmd')
    )

    function Invoke-AtlasTrustedInstaller {
        [CmdletBinding()]
        param(
            [string]$Operation,
            [string]$RestoreSource
        )

        $null = $Operation, $RestoreSource
    }

    function Write-TestFile {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Content
        )

        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force
        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    }

    function Initialize-AtlasResetFixture {
        param([Parameter(Mandatory = $true)][string]$Root)

        $atlasModules = Join-Path -Path $Root -ChildPath 'AtlasModules'
        $scripts = Join-Path -Path $atlasModules -ChildPath 'Scripts'
        $modules = Join-Path -Path $scripts -ChildPath 'Modules'
        $phase = Join-Path -Path $scripts -ChildPath 'Install\Phases\Invoke-ServicesPhase.ps1'
        $internal = Join-Path -Path $scripts -ChildPath 'Entry\Restore-AtlasServiceDefaults.ps1'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $phase) -Force
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $internal) -Force
        Copy-Item -LiteralPath $script:phasePath -Destination $phase -Force
        Copy-Item -LiteralPath $script:internalResetPath -Destination $internal -Force
        Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') -Destination $scripts

        Write-TestFile -Path (Join-Path $modules 'Atlas.Core\Atlas.Core.psd1') -Content @'
@{ RootModule = 'Atlas.Core.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Assert-AtlasPrivilege', 'Get-AtlasContext') }
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Core\Atlas.Core.psm1') -Content @'
function Write-ResetEvent { param([string]$Message) Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value $Message -Encoding UTF8 }
function Assert-AtlasPrivilege {
    [CmdletBinding()] param([switch]$TrustedInstaller)
    Write-ResetEvent "Privilege:$([bool]$TrustedInstaller)"
    if (-not $TrustedInstaller -or $env:ATLAS_RESET_TEST_FAIL -ceq 'Privilege') { throw 'simulated privilege failure' }
}
function Get-AtlasContext { [pscustomobject]@{ AtlasModulesPath = $env:ATLAS_RESET_TEST_ROOT } }
Export-ModuleMember -Function Assert-AtlasPrivilege, Get-AtlasContext
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Services\Atlas.Services.psd1') -Content @'
@{ RootModule = 'Atlas.Services.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Export-AtlasServicesBackup', 'Restore-AtlasServicesBackup') }
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Services\Atlas.Services.psm1') -Content @'
function Write-ResetEvent { param([string]$Message) Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value $Message -Encoding UTF8 }
function Export-AtlasServicesBackup {
    param([string]$FilePath)
    Write-ResetEvent "Backup:$([IO.Path]::GetFullPath($FilePath))"
    if ($env:ATLAS_RESET_TEST_FAIL -ceq 'Backup') { throw 'simulated backup failure' }
}
function Restore-AtlasServicesBackup {
    param([string]$FilePath)
    Write-ResetEvent "Restore:$([IO.Path]::GetFullPath($FilePath))"
}
Export-ModuleMember -Function Export-AtlasServicesBackup, Restore-AtlasServicesBackup
'@
        # Stub engine: the Services phase applies each feature default through
        # Invoke-AtlasToggleMachineState, then verifies the record against the
        # definition's StateValue through Get-AtlasToggleDefinition/Get-AtlasToggleState.
        Write-TestFile -Path (Join-Path $modules 'Atlas.Toggles\Atlas.Toggles.psd1') -Content @'
@{ RootModule = 'Atlas.Toggles.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Invoke-AtlasToggleMachineState', 'Get-AtlasToggleDefinition', 'Get-AtlasToggleState', 'Set-AtlasToggleState') }
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Toggles\Atlas.Toggles.psm1') -Content @'
$script:States = @{}
$script:StateValues = @{
    FileSharing = @{ Disable = 0; Enable = 1 }
    Location    = @{ Disable = 0; Enable = 1 }
    Indexing    = @{ Default = 0; Minimal = 1; Disable = 2 }
}
function Write-ResetEvent { param([string]$Message) Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value $Message -Encoding UTF8 }
function Invoke-AtlasToggleMachineState {
    param([string]$Name, [string]$State, [string]$StateRoot, [string]$TogglesRoot)
    Write-ResetEvent "MachineState:${Name}:$State"
    if ($env:ATLAS_RESET_TEST_FAIL -ceq "MachineState:$Name") { throw "simulated $Name failure" }
    if ($env:ATLAS_RESET_TEST_FAIL -cne "Record:$Name") { $script:States[$Name] = [int]$script:StateValues[$Name][$State] }
}
function Get-AtlasToggleDefinition {
    param([string]$Name, [string]$TogglesRoot)
    $states = [ordered]@{}
    foreach ($stateName in $script:StateValues[$Name].Keys) { $states[$stateName] = @{ StateValue = $script:StateValues[$Name][$stateName] } }
    return [ordered]@{ Name = $Name; States = $states }
}
function Get-AtlasToggleState {
    param([string]$Name, [string]$StateRoot)
    if ($script:States.ContainsKey($Name)) { return [pscustomobject]@{ State = $script:States[$Name] } }
    return $null
}
function Set-AtlasToggleState {
    param([string]$Name, [int]$State, [string]$StateRoot)
    $script:States[$Name] = $State
    Write-ResetEvent "State:${Name}:$State"
}
function Invoke-AtlasServiceDefaultsReset {
    Write-ResetEvent 'ResetDefaults'
    if ($env:ATLAS_RESET_TEST_FAIL -ceq 'ResetDefaults') { throw 'simulated service reset failure' }
}
Export-ModuleMember -Function Invoke-AtlasToggleMachineState, Get-AtlasToggleDefinition, Get-AtlasToggleState, Set-AtlasToggleState
'@

        $phaseRunner = Join-Path -Path $Root -ChildPath 'Invoke-ServicesPhase.Test.ps1'
        Write-TestFile -Path $phaseRunner -Content @'
Import-Module -Name (Join-Path $env:ATLAS_RESET_TEST_ROOT 'Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
& (Join-Path $env:ATLAS_RESET_TEST_ROOT 'Scripts\Install\Phases\Invoke-ServicesPhase.ps1')
'@

        return [pscustomobject]@{
            AtlasModules = $atlasModules
            PhaseRunner  = $phaseRunner
            Internal     = $internal
            Log          = Join-Path -Path $Root -ChildPath 'events.log'
        }
    }

    function Invoke-AtlasResetFixture {
        param(
            [Parameter(Mandatory = $true)]$Fixture,
            [Parameter(Mandatory = $true)][ValidateSet('Phase', 'Internal')][string]$Target,
            [string]$RestoreSource = 'ToggleDefaults',
            [string]$FailAt
        )

        Remove-Item -LiteralPath $Fixture.Log -Force -ErrorAction SilentlyContinue
        $oldLog = $env:ATLAS_RESET_TEST_LOG
        $oldRoot = $env:ATLAS_RESET_TEST_ROOT
        $oldFail = $env:ATLAS_RESET_TEST_FAIL
        $oldErrorActionPreference = $ErrorActionPreference
        try {
            $env:ATLAS_RESET_TEST_LOG = $Fixture.Log
            $env:ATLAS_RESET_TEST_ROOT = $Fixture.AtlasModules
            $env:ATLAS_RESET_TEST_FAIL = $FailAt
            # A nonzero child is the behavior under test. Windows PowerShell surfaces
            # redirected native stderr as an ErrorRecord when the caller prefers Stop.
            $ErrorActionPreference = 'Continue'
            $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File')
            if ($Target -ceq 'Phase') {
                $output = @(& $script:hostExecutable @arguments $Fixture.PhaseRunner 2>&1)
            }
            else {
                $output = @(& $script:hostExecutable @arguments $Fixture.Internal `
                        -RestoreSource $RestoreSource 2>&1)
            }
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:ATLAS_RESET_TEST_LOG = $oldLog
            $env:ATLAS_RESET_TEST_ROOT = $oldRoot
            $env:ATLAS_RESET_TEST_FAIL = $oldFail
            $ErrorActionPreference = $oldErrorActionPreference
        }

        $events = if (Test-Path -LiteralPath $Fixture.Log -PathType Leaf) {
            @(Get-Content -LiteralPath $Fixture.Log)
        }
        else {
            @()
        }
        return [pscustomobject]@{ ExitCode = $exitCode; Events = $events; Output = $output }
    }
}

Describe 'Reset Services phase and privileged adapter behavior' {
    BeforeEach {
        $script:fixture = Initialize-AtlasResetFixture -Root $TestDrive
    }

    It 'gates on TrustedInstaller and backs up the fixed Windows snapshot before machine changes' {
        $result = Invoke-AtlasResetFixture -Fixture $script:fixture -Target Phase
        $expectedBackup = Join-Path -Path $script:fixture.AtlasModules `
            -ChildPath 'Other\winServices.reg'

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join "`n")
        $result.Events | Should -Be @(
            'Privilege:True'
            "Backup:$expectedBackup"
            'MachineState:FileSharing:Disable'
            'MachineState:Location:Disable'
            'MachineState:Indexing:Minimal'
        )
    }

    It 'stops at the first feature default whose machine state fails to apply' {
        $result = Invoke-AtlasResetFixture -Fixture $script:fixture -Target Phase -FailAt 'MachineState:Location'

        $result.ExitCode | Should -Not -Be 0
        $result.Events.Count | Should -Be 4
        $result.Events[2] | Should -BeExactly 'MachineState:FileSharing:Disable'
        $result.Events[3] | Should -BeExactly 'MachineState:Location:Disable'
        ($result.Output -join "`n") | Should -Match 'simulated Location failure'
    }

    It 'fails when a feature default did not leave the expected state record' {
        $result = Invoke-AtlasResetFixture -Fixture $script:fixture -Target Phase -FailAt 'Record:Indexing'

        $result.ExitCode | Should -Not -Be 0
        $result.Events[-1] | Should -BeExactly 'MachineState:Indexing:Minimal'
        ($result.Output -join "`n") | Should -Match "toggle 'Indexing' did not record state 'Minimal'"
    }

    It 'stops the phase before machine changes when its required backup fails' {
        $result = Invoke-AtlasResetFixture -Fixture $script:fixture -Target Phase -FailAt Backup

        $result.ExitCode | Should -Not -Be 0
        $result.Events.Count | Should -Be 2
        $result.Events[0] | Should -BeExactly 'Privilege:True'
        $result.Events[1] | Should -Match '^Backup:.+\\Other\\winServices\.reg$'
    }

    It 'applies closed service defaults before restoring the fixed typed snapshot and fails stop' {
        $result = Invoke-AtlasResetFixture -Fixture $script:fixture -Target Internal `
            -RestoreSource WindowsBackup
        $expectedRestore = Join-Path -Path $script:fixture.AtlasModules `
            -ChildPath 'Other\winServices.reg'

        $result.ExitCode | Should -Be 0
        $result.Events | Should -Be @('Privilege:True', 'ResetDefaults', "Restore:$expectedRestore")

        $failed = Invoke-AtlasResetFixture -Fixture $script:fixture -Target Internal `
            -RestoreSource WindowsBackup -FailAt ResetDefaults
        $failed.ExitCode | Should -Not -Be 0
        $failed.Events | Should -Be @('Privilege:True', 'ResetDefaults')
    }
}

Describe 'Reset Services public adapter behavior' {
    BeforeEach {
        Mock -CommandName Import-Module -ParameterFilter { $Name -like '*Atlas.Core*' } -MockWith {}
        Mock -CommandName Test-AtlasAdmin -MockWith { $true }
        Mock -CommandName Invoke-AtlasTrustedInstaller
    }

    It 'uses the typed broker default and reports the required restart' {
        $output = & $script:publicResetPath -Silent

        $output | Should -BeExactly `
            'Atlas service defaults were restored. A restart is required to apply every change.'
        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -Times 1 -Exactly `
            -ParameterFilter { $Operation -ceq 'ResetServices' -and $RestoreSource -ceq 'ToggleDefaults' }
    }

    It 'surfaces a checked broker or target failure without reporting success' {
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            throw 'TrustedInstaller broker exited with disallowed code 5: target failed.'
        }
        { & $script:publicResetPath -Silent } | Should -Throw '*disallowed code 5*target failed*'
    }
}

Describe 'Reset Services launcher parity' {
    It 'keeps the shipped desktop and Toolbox launchers identical' {
        $contents = @($script:wrapperPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw })
        $contents.Count | Should -Be 3
        $contents[1] | Should -BeExactly $contents[0]
        $contents[2] | Should -BeExactly $contents[0]
    }
}
