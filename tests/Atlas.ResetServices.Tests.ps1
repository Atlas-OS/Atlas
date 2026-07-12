param()

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $script:scriptsRoot = Join-Path -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts'
    $script:phasePath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Phases\Invoke-ServicesPhase.ps1'
    $script:internalResetPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Internal\Invoke-AtlasResetServices.ps1'
    $script:publicResetPath = Join-Path -Path $script:scriptsRoot `
        -ChildPath 'Invoke-AtlasResetServices.ps1'
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
        $phase = Join-Path -Path $scripts -ChildPath 'Phases\Invoke-ServicesPhase.ps1'
        $internal = Join-Path -Path $scripts -ChildPath 'Internal\Invoke-AtlasResetServices.ps1'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $phase) -Force
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $internal) -Force
        Copy-Item -LiteralPath $script:phasePath -Destination $phase -Force
        Copy-Item -LiteralPath $script:internalResetPath -Destination $internal -Force

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
        Write-TestFile -Path (Join-Path $modules 'Atlas.Toggles\Atlas.Toggles.psd1') -Content @'
@{ RootModule = 'Atlas.Toggles.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Set-AtlasToggleState', 'Get-AtlasToggleState') }
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Toggles\Atlas.Toggles.psm1') -Content @'
$script:States = @{}
function Write-ResetEvent { param([string]$Message) Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value $Message -Encoding UTF8 }
function Set-AtlasToggleState {
    param([string]$Name, [int]$State)
    $script:States[$Name] = $State
    Write-ResetEvent "State:${Name}:$State"
}
function Get-AtlasToggleState { param([string]$Name) [pscustomobject]@{ State = $script:States[$Name] } }
function Invoke-AtlasServiceDefaultsReset {
    Write-ResetEvent 'ResetDefaults'
    if ($env:ATLAS_RESET_TEST_FAIL -ceq 'ResetDefaults') { throw 'simulated service reset failure' }
}
Export-ModuleMember -Function Set-AtlasToggleState, Get-AtlasToggleState
'@

        Write-TestFile -Path (Join-Path $scripts 'Internal\Disable-FileSharing.ps1') -Content @'
[CmdletBinding()] param([switch]$Silent)
Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value "FileSharing:$([bool]$Silent)" -Encoding UTF8
'@
        Write-TestFile -Path (Join-Path $scripts 'Internal\Set-AtlasLocationMachineState.ps1') -Content @'
param([string]$State)
Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value "Location:$State" -Encoding UTF8
'@
        Write-TestFile -Path (Join-Path $scripts 'Internal\Set-AtlasIndexingMachineState.ps1') -Content @'
param([string]$State)
Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value "Indexing:$State" -Encoding UTF8
'@

        $phaseRunner = Join-Path -Path $Root -ChildPath 'Invoke-ServicesPhase.Test.ps1'
        Write-TestFile -Path $phaseRunner -Content @'
Import-Module -Name (Join-Path $env:ATLAS_RESET_TEST_ROOT 'Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
& (Join-Path $env:ATLAS_RESET_TEST_ROOT 'Scripts\Phases\Invoke-ServicesPhase.ps1')
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

        $result.ExitCode | Should -Be 0
        $result.Events | Should -Be @(
            'Privilege:True'
            "Backup:$expectedBackup"
            'FileSharing:True'
            'Location:Disable'
            'State:Location:0'
            'Indexing:Minimal'
            'State:Indexing:1'
        )
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
        Mock -CommandName Import-Module -MockWith {}
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{ status = 'Completed'; exitCodeUInt32 = [uint64]0; error = $null }
        }
    }

    It 'uses the typed broker default and reports the required restart' {
        $output = & $script:publicResetPath -Silent

        $output | Should -BeExactly `
            'Atlas service defaults were restored. A restart is required to apply every change.'
        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -Times 1 -Exactly `
            -ParameterFilter { $Operation -ceq 'ResetServices' -and $RestoreSource -ceq 'ToggleDefaults' }
    }

    It 'surfaces broker and target failures without reporting success' {
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{ status = 'CompletionUnknown'; exitCodeUInt32 = [uint64]0; error = 'broker failed' }
        }
        { & $script:publicResetPath -Silent } | Should -Throw '*CompletionUnknown*broker failed*'

        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            [pscustomobject]@{ status = 'Completed'; exitCodeUInt32 = [uint64]5; error = $null }
        }
        { & $script:publicResetPath -Silent } | Should -Throw '*exited with code 5*'
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
