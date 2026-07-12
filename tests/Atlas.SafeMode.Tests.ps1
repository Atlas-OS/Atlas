BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:SafeModePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\SafeMode.ps1'
    $script:CbsRetryPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\CbsRetry.ps1'
    . $script:SafeModePath -LibraryOnly
    . $script:CbsRetryPath -LibraryOnly
}

Describe 'Atlas Safe Mode configuration reader' {
    It 'binds BCDEdit to System32 and rejects a nonzero native exit code' {
        (Get-AtlasSafeModePaths).BcdEdit | Should -BeExactly `
            (Join-Path ([Environment]::GetFolderPath('Windows')) 'System32\bcdedit.exe')
        Mock Get-AtlasSafeModePaths {
            [pscustomobject]@{ BcdEdit = (Join-Path $env:SystemRoot 'System32\cmd.exe') }
        }
        { Invoke-AtlasBcdEdit -Arguments @('/d', '/c', 'exit 7') } | Should -Throw '*exit code 7*'
    }

    It 'reads minimal and alternate shell from the current boot entry' {
        Mock Invoke-AtlasBcdEdit { @('identifier {current}', 'safeboot Minimal', 'safebootalternateshell Yes') }
        $result = Get-AtlasSafeBootConfiguration
        $result.SafeBoot | Should -BeExactly 'minimal'
        $result.AlternateShellPresent | Should -BeTrue
        $result.AlternateShell | Should -BeTrue
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/enum {current}'
        }
    }

    It 'rejects an unsupported current safeboot value' {
        Mock Invoke-AtlasBcdEdit { 'safeboot DsRepair' }
        { Get-AtlasSafeBootConfiguration } | Should -Throw '*Unsupported current safeboot*'
    }
}

Describe 'Atlas Safe Mode configuration' {
    BeforeEach {
        $script:boot = [pscustomobject]@{
            SafeBoot = $null; AlternateShellPresent = $false; AlternateShell = $false
        }
        $script:shell = [pscustomobject]@{ Value = 'explorer.exe'; Kind = 'String' }
        $script:shellState = $null
        Mock Test-AtlasCbsRetryPending { $false }
        Mock Get-AtlasSafeBootConfiguration { $script:boot }
        Mock Get-AtlasWinlogonShell { $script:shell }
        Mock Read-AtlasSafeModeShellState { $script:shellState }
        Mock Invoke-AtlasBcdEdit {}
        Mock Write-AtlasSafeModeShellState {}
        Mock Clear-AtlasSafeModeShellState {}
        Mock Set-AtlasWinlogonShell {}
    }

    It 'refuses a non-Exit change while a CBS retry is pending' {
        Mock Test-AtlasCbsRetryPending { $true }
        { Set-AtlasSafeMode -Mode Minimal } | Should -Throw '*CBS retry is pending*'
        Should -Invoke Get-AtlasSafeBootConfiguration -Times 0
    }

    It 'sets minimal boot, removes alternate shell, and restores an Atlas-owned shell' {
        $script:boot = [pscustomobject]@{
            SafeBoot = 'network'; AlternateShellPresent = $true; AlternateShell = $true
        }
        $script:shell = [pscustomobject]@{ Value = 'cmd.exe'; Kind = 'String' }
        $script:shellState = [pscustomobject]@{
            Version = 1; Owner = 'AtlasOS'; OriginalShell = 'explorer.exe'; OriginalKind = 'String'
        }
        Set-AtlasSafeMode -Mode Minimal
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/set {current} safeboot minimal'
        }
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/deletevalue {current} safebootalternateshell'
        }
        Should -Invoke Set-AtlasWinlogonShell -Times 1 -ParameterFilter {
            $Value -ceq 'explorer.exe' -and $Kind -ceq 'String'
        }
    }

    It 'maps Networking to the network safeboot value' {
        $script:boot.SafeBoot = 'minimal'
        Set-AtlasSafeMode -Mode Networking
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/set {current} safeboot network'
        }
    }

    It 'captures the shell before enabling command-prompt Safe Mode' {
        Set-AtlasSafeMode -Mode CommandPrompt
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/set {current} safeboot minimal'
        }
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/set {current} safebootalternateshell yes'
        }
        Should -Invoke Write-AtlasSafeModeShellState -Times 1 -ParameterFilter {
            $Shell.Value -ceq 'explorer.exe'
        }
        Should -Invoke Set-AtlasWinlogonShell -Times 1 -ParameterFilter { $Value -ceq 'cmd.exe' }
    }

    It 'leaves an already-correct command-prompt configuration unchanged' {
        $script:boot = [pscustomobject]@{
            SafeBoot = 'minimal'; AlternateShellPresent = $true; AlternateShell = $true
        }
        $script:shell.Value = 'cmd.exe'
        Set-AtlasSafeMode -Mode CommandPrompt
        Should -Invoke Invoke-AtlasBcdEdit -Times 0
        Should -Invoke Write-AtlasSafeModeShellState -Times 0
        Should -Invoke Set-AtlasWinlogonShell -Times 0
    }

    It 'deletes both Safe Mode values and restores the captured shell on Exit' {
        $script:boot = [pscustomobject]@{
            SafeBoot = 'minimal'; AlternateShellPresent = $true; AlternateShell = $true
        }
        $script:shell.Value = 'cmd.exe'
        $script:shellState = [pscustomobject]@{
            Version = 1; Owner = 'AtlasOS'; OriginalShell = 'explorer.exe'; OriginalKind = 'String'
        }
        Set-AtlasSafeMode -Mode Exit
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/deletevalue {current} safeboot'
        }
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -ParameterFilter {
            ($Arguments -join ' ') -ceq '/deletevalue {current} safebootalternateshell'
        }
        Should -Invoke Set-AtlasWinlogonShell -Times 1 -ParameterFilter { $Value -ceq 'explorer.exe' }
        Should -Invoke Clear-AtlasSafeModeShellState -Times 1
    }

    It 'does not overwrite a shell changed by something else' {
        $script:shell.Value = 'powershell.exe'
        $script:shellState = [pscustomobject]@{
            Version = 1; Owner = 'AtlasOS'; OriginalShell = 'explorer.exe'; OriginalKind = 'String'
        }
        Set-AtlasSafeMode -Mode Exit
        Should -Invoke Set-AtlasWinlogonShell -Times 0
        Should -Invoke Clear-AtlasSafeModeShellState -Times 1
    }
}

Describe 'Atlas CBS retry lifecycle' {
    BeforeEach {
        $script:statePath = Join-Path $TestDrive 'Recovery\CbsRetry.json'
        $script:package = Join-Path $TestDrive 'package.cab'
        if (Test-Path -LiteralPath $script:statePath) {
            Remove-Item -LiteralPath $script:statePath -Force
        }
        Set-Content -LiteralPath $script:package -Value 'fixture'
        $script:events = @()
        Mock Invoke-WithAtlasCbsRetryLock { & $Action }
    }

    It 'round-trips the compact Pending and Armed state' {
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages $script:package -Path $script:statePath)
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Pending'
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Armed'
    }

    It 'rejects malformed state' {
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($script:statePath))
        Set-Content -LiteralPath $script:statePath -Value '{"Version":1,"Phase":"Other"}'
        { Read-AtlasCbsRetryState -Path $script:statePath } | Should -Throw '*state*invalid*'
    }

    It 'migrates and resumes the released plain-text retry list' {
        $legacyPath = Join-Path $TestDrive 'safeModePackagesToInstall.atlasmodule'
        Set-Content -LiteralPath $legacyPath -Value $script:package
        (Read-AtlasCbsRetryState -Path $script:statePath -LegacyPath $legacyPath).Phase |
            Should -BeExactly 'Pending'
        Test-Path -LiteralPath $legacyPath | Should -BeFalse

        Enable-AtlasCbsRetry -Packages $script:package -StatePath $script:statePath `
            -SafeModeCommand { param($Mode) $script:events += $Mode }
        $script:events | Should -Be @('CommandPrompt')
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Armed'
    }

    It 'arms command-prompt Safe Mode after publishing Pending state' {
        $safeMode = {
            param($Mode)
            $script:events += "${Mode}:$((Read-AtlasCbsRetryState -Path $script:statePath).Phase)"
        }
        Enable-AtlasCbsRetry -Packages $script:package -StatePath $script:statePath -SafeModeCommand $safeMode
        $script:events | Should -Be @('CommandPrompt:Pending')
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Armed'
    }

    It 'does not replace an existing retry' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
        { Enable-AtlasCbsRetry -Packages $script:package -StatePath $script:statePath -SafeModeCommand {} } |
            Should -Throw '*already armed*'
    }

    It 'restores normal boot before servicing and clears successful state' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
        $safeMode = { param($Mode) $script:events += $Mode }
        $installer = {
            param($Packages, [switch]$LiteralPaths)
            $null = $Packages, $LiteralPaths
            $script:events += 'Install'
            [pscustomobject]@{ FailedPackages = @() }
        }
        Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath `
            -SafeModeCommand $safeMode -Installer $installer
        $script:events | Should -Be @('Exit', 'Install')
        Test-Path -LiteralPath $script:statePath | Should -BeFalse
    }

    It 'keeps Pending state when servicing throws' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
        { Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath `
                -SafeModeCommand {} -Installer { throw 'servicing failed' } } |
            Should -Throw '*servicing failed*'
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Pending'
        { Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath -SafeModeCommand {} -Installer {} } |
            Should -Throw '*has not been armed*'
    }

    It 'treats reported failed packages as a failed recovery' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
        $installer = { [pscustomobject]@{ FailedPackages = @($script:package) } }
        { Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath `
                -SafeModeCommand {} -Installer $installer } | Should -Throw '*still failed*'
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Pending'
    }
}
