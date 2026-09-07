BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:BrokerFixture = Join-Path $TestDrive 'AtlasModules\Scripts\Entry\Invoke-AtlasTrustedInstallerBroker.ps1'
    $fixtureModules = Join-Path $TestDrive 'AtlasModules\Scripts\Modules'
    New-Item -ItemType Directory -Path (Split-Path $script:BrokerFixture),
        (Join-Path $fixtureModules 'Atlas.Core'), (Join-Path $fixtureModules 'Atlas.Toggles') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasTrustedInstallerBroker.ps1') `
        -Destination $script:BrokerFixture
    Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') `
        -Destination (Join-Path $TestDrive 'AtlasModules\Scripts')

    # Exercise the real broker in a separate process, with a private native boundary
    # that records requests instead of creating privileged processes.
    Set-Content -LiteralPath (Join-Path $fixtureModules 'Atlas.Core\Atlas.Core.psm1') -Encoding UTF8 -Value @'
function Assert-AtlasPrivilege { param([switch]$Administrator) }
function Invoke-AtlasTrustedInstallerNativeOperation {
    param($Operation, $TimeoutMilliseconds, $Name, $State, $Silent, $JustContext,
        $NoExplorerRestart, $MachineOnly, $RestoreSource, $InstallPhase, $PayloadRoot)
    $PSBoundParameters | ConvertTo-Json | Set-Content -LiteralPath $env:ATLAS_BROKER_TEST_RESULT
    [pscustomobject]@{ ExitCodeUInt32 = [uint32]$env:ATLAS_BROKER_TEST_EXIT }
}
Export-ModuleMember -Function Assert-AtlasPrivilege
'@
    Set-Content -LiteralPath (Join-Path $fixtureModules 'Atlas.Core\Atlas.Core.psd1') -Encoding UTF8 -Value @'
@{ RootModule = 'Atlas.Core.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Assert-AtlasPrivilege') }
'@
    Set-Content -LiteralPath (Join-Path $fixtureModules 'Atlas.Toggles\Atlas.Toggles.psm1') -Encoding UTF8 -Value @'
function Get-AtlasToggleDefinition {
    param($Name)
    @{ Name = $Name; Elevation = 'TrustedInstaller'; States = @{ Minimal = @{} } }
}
Export-ModuleMember -Function Get-AtlasToggleDefinition
'@
    Set-Content -LiteralPath (Join-Path $fixtureModules 'Atlas.Toggles\Atlas.Toggles.psd1') -Encoding UTF8 -Value @'
@{ RootModule = 'Atlas.Toggles.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Get-AtlasToggleDefinition') }
'@
    $script:BrokerPowerShell = Join-Path $PSHOME 'powershell.exe'
    $script:PreviousBrokerResult = $env:ATLAS_BROKER_TEST_RESULT
    $script:PreviousBrokerExit = $env:ATLAS_BROKER_TEST_EXIT
}

AfterAll {
    $env:ATLAS_BROKER_TEST_RESULT = $script:PreviousBrokerResult
    $env:ATLAS_BROKER_TEST_EXIT = $script:PreviousBrokerExit
}

Describe 'TrustedInstaller broker private native dispatch' {
    BeforeEach {
        $env:ATLAS_BROKER_TEST_RESULT = Join-Path $TestDrive ([guid]::NewGuid().ToString() + '.json')
        $env:ATLAS_BROKER_TEST_EXIT = '0'
    }

    It 'dispatches a validated toggle through the private module function' {
        & $script:BrokerPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:BrokerFixture `
            -Operation Toggle -Name Indexing -State Minimal -TimeoutSeconds 42
        $LASTEXITCODE | Should -Be 0
        $request = Get-Content -LiteralPath $env:ATLAS_BROKER_TEST_RESULT -Raw | ConvertFrom-Json
        $request.Operation | Should -Be 'Toggle'
        $request.Name | Should -Be 'Indexing'
        $request.State | Should -Be 'Minimal'
        $request.TimeoutMilliseconds | Should -Be 42000
        $request.Silent | Should -BeTrue
    }

    It 'dispatches service reset through the same private boundary' {
        & $script:BrokerPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:BrokerFixture `
            -Operation ResetServices -RestoreSource ToggleDefaults
        $LASTEXITCODE | Should -Be 0
        $request = Get-Content -LiteralPath $env:ATLAS_BROKER_TEST_RESULT -Raw | ConvertFrom-Json
        $request.RestoreSource | Should -Be 'ToggleDefaults'
    }

    It 'dispatches an install request without writing to the real staging directory' {
        $payloadRoot = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Staging\BrokerTest\Executables'
        & $script:BrokerPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:BrokerFixture `
            -Operation Install -InstallPhase Capture -PayloadRoot $payloadRoot
        $LASTEXITCODE | Should -Be 0
        $request = Get-Content -LiteralPath $env:ATLAS_BROKER_TEST_RESULT -Raw | ConvertFrom-Json
        $request.InstallPhase | Should -Be 'Capture'
        $request.PayloadRoot | Should -Be $payloadRoot
    }

    It 'rejects an undeclared toggle state before native dispatch' {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $output = & $script:BrokerPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:BrokerFixture `
                -Operation Toggle -Name Indexing -State Unknown 2>&1
        }
        finally { $ErrorActionPreference = $previousPreference }
        $LASTEXITCODE | Should -Be 1
        ($output | Out-String) | Should -Match 'does not declare exact state'
        Test-Path -LiteralPath $env:ATLAS_BROKER_TEST_RESULT | Should -BeFalse
    }

    It 'preserves a nonzero native child exit code' {
        $env:ATLAS_BROKER_TEST_EXIT = '37'
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $output = & $script:BrokerPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script:BrokerFixture `
                -Operation ResetServices -RestoreSource ToggleDefaults 2>&1
        }
        finally { $ErrorActionPreference = $previousPreference }
        $LASTEXITCODE | Should -Be 37
        ($output | Out-String) | Should -Match 'child exited with code 37'
    }
}
