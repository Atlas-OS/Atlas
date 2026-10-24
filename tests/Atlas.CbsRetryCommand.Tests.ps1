BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    $script:CbsRetryPath = Join-Path $script:AtlasTestScriptsRoot 'Operations\CbsRetry.ps1'
    . $script:CbsRetryPath -LibraryOnly
}

Describe 'The CBS retry launcher arguments' {
    It 'needs exactly one of -Recover and -Discard' {
        { & $script:CbsRetryPath } | Should -Throw '*Specify -Recover or -Discard*'
        { & $script:CbsRetryPath -Recover -Discard } | Should -Throw '*Specify -Recover or -Discard*'
    }
}

Describe 'What the Safe Mode retry command says is left to do' {
    BeforeEach {
        $script:statePath = Join-Path $TestDrive 'Recovery\CbsRetry.json'
        $package = Join-Path $TestDrive 'package.cab'
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $package -Path $script:statePath)
        $script:shown = @()
        Mock Invoke-WithAtlasCbsRetryLock { & $Action }
        # Nothing here may change this PC's boot configuration or restart it.
        Mock Invoke-AtlasCbsRetrySafeMode {}
        Mock Read-AtlasYesNo { $false }
        Mock Test-AtlasTrustedInstaller { $false }
        Mock Assert-AtlasPrivilege {}
        Mock Get-CimInstance { [pscustomobject]@{ BootupState = 'Fail-safe boot' } }
        Mock Invoke-AtlasTrustedInstaller { Clear-AtlasCbsRetryState -Path $script:statePath }
        Mock Test-AtlasCbsRetryInstallUnfinished { $false }
        foreach ($command in @('Set-AtlasLogConsoleStyle', 'Write-AtlasTitle', 'Write-AtlasStep',
                'Write-AtlasLog', 'Write-AtlasNotApplied')) {
            Mock -CommandName $command -MockWith {}
        }
        Mock Write-AtlasSuccess { $script:shown += $Text }
    }

    It 'says only that Windows starts normally when no install is waiting (<Mode>)' -ForEach @(
        @{ Mode = 'Recover'; Done = 'The packages are installed. Windows starts normally from the next restart.' }
        @{ Mode = 'Discard'; Done = 'The retry was given up. Windows starts normally from the next restart.' }
    ) {
        Invoke-AtlasCbsRetryCommand -Mode $Mode -StatePath $script:statePath | Should -Be 0
        $script:shown | Should -Be @($Done)
    }

    It 'sends the user back to Atlas for the install that armed the retry (<Mode>)' -ForEach @(
        @{ Mode = 'Recover'; Next = '* After the restart, open Atlas to finish installing it.' }
        @{ Mode = 'Discard'; Next = '* After the restart, open Atlas to try installing again.' }
    ) {
        Mock Test-AtlasCbsRetryInstallUnfinished { $true }
        Invoke-AtlasCbsRetryCommand -Mode $Mode -StatePath $script:statePath | Should -Be 0
        $script:shown | Should -BeLike $Next
    }

    It 'offers the restart after giving up only where Safe Mode has no Start menu (<Boot>)' -ForEach @(
        @{ Boot = 'Fail-safe boot'; Asks = 1 }
        @{ Boot = 'Normal boot'; Asks = 0 }
    ) {
        Mock Get-CimInstance { [pscustomobject]@{ BootupState = $Boot } }
        Invoke-AtlasCbsRetryCommand -Mode Discard -StatePath $script:statePath | Should -Be 0
        Should -Invoke Read-AtlasYesNo -Times $Asks -Exactly -ParameterFilter { $Question -ceq 'Restart Windows now?' }
    }
}

Describe 'The CBS retry command' {
    BeforeAll {
        # A copy of the script beside an empty trust bootstrap, so a run keeps the test
        # host's module setup and the Atlas.Core this file imported.
        $harnessScripts = Join-Path $TestDrive 'Scripts'
        $script:CbsRetryEntry = Join-Path $harnessScripts 'Operations\CbsRetry.ps1'
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $script:CbsRetryEntry))
        Copy-Item -LiteralPath $script:CbsRetryPath -Destination $script:CbsRetryEntry
        Set-Content -LiteralPath (Join-Path $harnessScripts 'Initialize-AtlasPowerShell.ps1') -Value ''
    }

    BeforeEach {
        # The script runs these mocks from its own script scope, where $script: means the
        # script's variables, so they read the test's through the caller scopes instead.
        $cbsState = Join-Path $TestDrive 'Recovery\CbsRetry.json'
        $cbsPackage = Join-Path $TestDrive 'package.cab'
        if (Test-Path -LiteralPath $cbsState) {
            Remove-Item -LiteralPath $cbsState -Force
        }
        Set-Content -LiteralPath $cbsPackage -Value 'fixture'
        Mock Import-Module {} -ParameterFilter { $Name -like '*\Atlas.Core.psd1' }
        Mock Get-AtlasCbsRetryStatePath { $cbsState }
        Mock Invoke-WithAtlasCbsRetryLock { & $Action }
        Mock Invoke-AtlasCbsRetrySafeMode {}
        Mock Test-AtlasTrustedInstaller { $false }
        Mock Assert-AtlasPrivilege {}
        Mock Get-CimInstance { [pscustomobject]@{ BootupState = 'Fail-safe boot' } }
        Mock Invoke-AtlasTrustedInstaller {}
        Mock Test-AtlasCbsRetryInstallUnfinished { $false }
        Mock Read-AtlasYesNo { $false }
        Mock Start-AtlasPhase {}
        Mock Stop-AtlasPhase {}
        Mock Write-AtlasLog {}
        Mock Get-AtlasInstallLogPath {}
        foreach ($command in @('Set-AtlasLogConsoleStyle', 'Write-AtlasTitle', 'Write-AtlasStep',
                'Write-AtlasNote', 'Write-AtlasSuccess', 'Write-AtlasNotApplied')) {
            Mock -CommandName $command -MockWith {}
        }
    }

    It 'refuses a retry that was never armed and says how to give it up' {
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages $cbsPackage -Path $cbsState)
        $null = & $script:CbsRetryEntry -Recover
        $LASTEXITCODE | Should -Be 1
        Should -Invoke Write-AtlasNotApplied -Times 1 -Exactly -ParameterFilter {
            $Reason -like '*Invoke-AtlasCbsRetry.cmd" /discard*'
        }
        Should -Invoke Invoke-AtlasTrustedInstaller -Times 0 -Exactly
    }

    It 'refuses to retry outside Safe Mode' {
        Mock Get-CimInstance { [pscustomobject]@{ BootupState = 'Normal boot' } }
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $cbsPackage -Path $cbsState)
        $null = & $script:CbsRetryEntry -Recover
        $LASTEXITCODE | Should -Be 1
        Should -Invoke Write-AtlasNotApplied -Times 1 -Exactly -ParameterFilter { $Reason -like 'The retry runs in Safe Mode.*' }
        Should -Invoke Invoke-AtlasTrustedInstaller -Times 0 -Exactly
    }

    It 'hands an armed retry in Safe Mode to TrustedInstaller' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $cbsPackage -Path $cbsState)
        $null = & $script:CbsRetryEntry -Recover
        $LASTEXITCODE | Should -Be 0
        Should -Invoke Assert-AtlasPrivilege -Times 1 -Exactly -ParameterFilter { $Administrator }
        Should -Invoke Invoke-AtlasTrustedInstaller -Times 1 -Exactly -ParameterFilter { $Operation -ceq 'CbsRetry' }
        Should -Invoke Write-AtlasNotApplied -Times 0 -Exactly
    }

    It 'says what is left to do when the TrustedInstaller run fails with the retry <After>' -ForEach @(
        @{ After = 'Armed' }
        @{ After = 'Pending' }
    ) {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $cbsPackage -Path $cbsState)
        # A run that reached servicing has already left Safe Mode and marked the retry Pending.
        Mock Invoke-AtlasTrustedInstaller {
            [void](Write-AtlasCbsRetryState -Phase $After -Packages $cbsPackage -Path $cbsState)
            throw 'The broker failed.'
        }
        $expectedReason = "The packages didn't install: The broker failed. $(Get-AtlasCbsRetryInstruction -Phase $After)"
        $null = & $script:CbsRetryEntry -Recover
        $LASTEXITCODE | Should -Be 1
        Should -Invoke Write-AtlasNotApplied -Times 1 -Exactly -ParameterFilter { $Reason -ceq $expectedReason }
    }

    It 'runs the retry itself with a TrustedInstaller token and exits <ExitCode>' -ForEach @(
        @{ Fails = $false; ExitCode = 0 }
        @{ Fails = $true; ExitCode = 1 }
    ) {
        Mock Test-AtlasTrustedInstaller { $true }
        Mock Invoke-AtlasCbsRetryRecovery { if ($Fails) { throw 'Servicing failed.' } }
        $null = & $script:CbsRetryEntry -Recover
        $LASTEXITCODE | Should -Be $ExitCode
        Should -Invoke Invoke-AtlasCbsRetryRecovery -Times 1 -Exactly
        Should -Invoke Start-AtlasPhase -Times 1 -Exactly -ParameterFilter { $Phase -ceq 'CbsRetry' }
        Should -Invoke Stop-AtlasPhase -Times 1 -Exactly -ParameterFilter { [bool]$Failed -eq $Fails }
        Should -Invoke Invoke-AtlasTrustedInstaller -Times 0 -Exactly
    }

    It 'gives up with /discard whether or not a retry is waiting' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $cbsPackage -Path $cbsState)
        $null = & $script:CbsRetryEntry -Discard
        $LASTEXITCODE | Should -Be 0
        Test-Path -LiteralPath $cbsState | Should -BeFalse
        Should -Invoke Invoke-AtlasCbsRetrySafeMode -Times 1 -Exactly -ParameterFilter { $Mode -ceq 'Exit' }

        $null = & $script:CbsRetryEntry -Discard
        $LASTEXITCODE | Should -Be 0
        Should -Invoke Invoke-AtlasCbsRetrySafeMode -Times 1 -Exactly
        Should -Invoke Write-AtlasNote -Times 1 -Exactly
        Should -Invoke Test-AtlasTrustedInstaller -Times 0 -Exactly
    }
}
