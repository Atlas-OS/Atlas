param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    # The public adapter imports Atlas.Core for Test-AtlasAdmin; load the real module
    # once so the adapter tests can mock that command.
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    $script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $script:scriptsRoot = Join-Path -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts'
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
        $internal = Join-Path -Path $scripts -ChildPath 'Entry\Restore-AtlasServiceDefaults.ps1'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $internal) -Force
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
    if (-not $TrustedInstaller) { throw 'simulated privilege failure' }
}
function Get-AtlasContext { [pscustomobject]@{ AtlasModulesPath = $env:ATLAS_RESET_TEST_ROOT } }
Export-ModuleMember -Function Assert-AtlasPrivilege, Get-AtlasContext
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Services\Atlas.Services.psd1') -Content @'
@{ RootModule = 'Atlas.Services.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Restore-AtlasServicesBackup') }
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Services\Atlas.Services.psm1') -Content @'
function Write-ResetEvent { param([string]$Message) Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value $Message -Encoding UTF8 }
function Restore-AtlasServicesBackup {
    param([string]$FilePath)
    Write-ResetEvent "Restore:$([IO.Path]::GetFullPath($FilePath))"
}
Export-ModuleMember -Function Restore-AtlasServicesBackup
'@
        # The reset enters the module and calls this private function directly.
        Write-TestFile -Path (Join-Path $modules 'Atlas.Toggles\Atlas.Toggles.psd1') -Content @'
@{ RootModule = 'Atlas.Toggles.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @() }
'@
        Write-TestFile -Path (Join-Path $modules 'Atlas.Toggles\Atlas.Toggles.psm1') -Content @'
function Write-ResetEvent { param([string]$Message) Add-Content -LiteralPath $env:ATLAS_RESET_TEST_LOG -Value $Message -Encoding UTF8 }
function Invoke-AtlasServiceDefaultsReset {
    Write-ResetEvent 'ResetDefaults'
    if ($env:ATLAS_RESET_TEST_FAIL -ceq 'ResetDefaults') { throw 'simulated service reset failure' }
}
'@

        return [pscustomobject]@{
            AtlasModules = $atlasModules
            Internal     = $internal
            Log          = Join-Path -Path $Root -ChildPath 'events.log'
        }
    }

    function Invoke-AtlasResetFixture {
        param(
            [Parameter(Mandatory = $true)]$Fixture,
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
            # A nonzero child is the behavior under test. Windows PowerShell reports
            # redirected native stderr as an ErrorRecord when the caller prefers Stop.
            $ErrorActionPreference = 'Continue'
            $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File')
            $output = @(& $script:hostExecutable @arguments $Fixture.Internal -RestoreSource $RestoreSource 2>&1)
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

Describe 'Reset Services privileged adapter behavior' {
    BeforeEach {
        $script:fixture = Initialize-AtlasResetFixture -Root $TestDrive
    }

    It 'applies closed service defaults before restoring the fixed typed snapshot and fails stop' {
        $result = Invoke-AtlasResetFixture -Fixture $script:fixture -RestoreSource WindowsBackup
        $expectedRestore = Join-Path -Path $script:fixture.AtlasModules `
            -ChildPath 'Other\winServices.reg'

        $result.ExitCode | Should -Be 0
        $result.Events | Should -Be @('Privilege:True', 'ResetDefaults', "Restore:$expectedRestore")

        $failed = Invoke-AtlasResetFixture -Fixture $script:fixture -RestoreSource WindowsBackup -FailAt ResetDefaults
        $failed.ExitCode | Should -Not -Be 0
        $failed.Events | Should -Be @('Privilege:True', 'ResetDefaults')
    }
}

Describe 'Reset Services public adapter behavior' {
    BeforeEach {
        # The script dot-sources the Atlas bootstrap, which replaces PSModulePath for the
        # whole process.
        $script:savedModulePath = $env:PSModulePath
        Mock -CommandName Import-Module -ParameterFilter { $Name -like '*Atlas.Core*' } -MockWith {}
        Mock -CommandName Test-AtlasAdmin -MockWith { $true }
        Mock -CommandName Invoke-AtlasTrustedInstaller
    }

    AfterEach {
        $env:PSModulePath = $script:savedModulePath
    }

    It 'uses the typed broker default and reports the required restart' {
        $output = & $script:publicResetPath -Silent

        $output | Should -BeExactly `
            'Atlas service defaults were restored. A restart is required to apply every change.'
        Should -Invoke -CommandName Invoke-AtlasTrustedInstaller -Times 1 -Exactly `
            -ParameterFilter { $Operation -ceq 'ResetServices' -and $RestoreSource -ceq 'ToggleDefaults' }
    }

    It 'reports a checked broker or target failure without claiming success' {
        Mock -CommandName Invoke-AtlasTrustedInstaller -MockWith {
            throw 'TrustedInstaller broker exited with disallowed code 5: target failed.'
        }
        { & $script:publicResetPath -Silent } | Should -Throw '*disallowed code 5*target failed*'
    }
}

Describe 'Reset Services launcher parity' {
    It 'keeps the desktop and Toolbox launchers identical' {
        $contents = @($script:wrapperPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw })
        $contents.Count | Should -Be 3
        $contents[1] | Should -BeExactly $contents[0]
        $contents[2] | Should -BeExactly $contents[0]
    }
}
