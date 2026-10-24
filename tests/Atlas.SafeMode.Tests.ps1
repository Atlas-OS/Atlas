BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:SafeModePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\SafeMode.ps1'
    $script:CbsRetryPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\CbsRetry.ps1'
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
        $script:shellEvents = @()
        Mock Test-AtlasCbsRetryPending { $false }
        Mock Get-AtlasSafeBootConfiguration { $script:boot }
        Mock Get-AtlasWinlogonShell { $script:shell }
        Mock Read-AtlasSafeModeShellState { $script:shellState }
        Mock Invoke-AtlasBcdEdit {}
        Mock Clear-AtlasSafeModeShellState { $script:shellEvents += 'clear' }
        Mock Set-AtlasWinlogonShell { $script:shellEvents += "shell:$Value" }
    }

    It 'refuses a non-Exit change while a CBS retry is pending' {
        Mock Test-AtlasCbsRetryPending { $true }
        # The refusal names the command that gives up the retry.
        { Set-AtlasSafeMode -Mode Minimal } | Should -Throw '*CBS retry is pending*Invoke-AtlasCbsRetry.cmd*/discard*'
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

    It 'sets command-prompt Safe Mode in BCD alone and leaves the Winlogon shell for normal boots' {
        Set-AtlasSafeMode -Mode CommandPrompt
        Should -Invoke Invoke-AtlasBcdEdit -Times 2 -Exactly
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -Exactly -ParameterFilter {
            ($Arguments -join ' ') -ceq '/set {current} safeboot minimal'
        }
        Should -Invoke Invoke-AtlasBcdEdit -Times 1 -Exactly -ParameterFilter {
            ($Arguments -join ' ') -ceq '/set {current} safebootalternateshell yes'
        }
        Should -Invoke Set-AtlasWinlogonShell -Times 0
        Should -Invoke Clear-AtlasSafeModeShellState -Times 0
    }

    It 'leaves an already-correct command-prompt configuration unchanged' {
        $script:boot = [pscustomobject]@{
            SafeBoot = 'minimal'; AlternateShellPresent = $true; AlternateShell = $true
        }
        Set-AtlasSafeMode -Mode CommandPrompt
        Should -Invoke Invoke-AtlasBcdEdit -Times 0
        Should -Invoke Set-AtlasWinlogonShell -Times 0
    }

    It 'puts back the shell an earlier build replaced for command-prompt Safe Mode' {
        $script:boot = [pscustomobject]@{
            SafeBoot = 'minimal'; AlternateShellPresent = $true; AlternateShell = $true
        }
        $script:shell.Value = 'cmd.exe'
        $script:shellState = [pscustomobject]@{
            Version = 1; Owner = 'AtlasOS'; OriginalShell = 'explorer.exe'; OriginalKind = 'String'
        }
        Set-AtlasSafeMode -Mode CommandPrompt
        Should -Invoke Invoke-AtlasBcdEdit -Times 0
        $script:shellEvents -join ',' | Should -BeExactly 'shell:explorer.exe,clear'
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
        # The saved shell is deleted only once it's back, so a failed write can be retried.
        $script:shellEvents -join ',' | Should -BeExactly 'shell:explorer.exe,clear'
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

    It 'rejects malformed state' {
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($script:statePath))
        Set-Content -LiteralPath $script:statePath -Value '{"Version":1,"Phase":"Other"}'
        { Read-AtlasCbsRetryState -Path $script:statePath } | Should -Throw '*state*invalid*'
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

    It 're-arms a Pending retry of the same packages' {
        # A failed Safe Mode retry leaves Pending, and the next toggle run arms it again.
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages $script:package -Path $script:statePath)
        [void](Enable-AtlasCbsRetry -Packages $script:package.ToUpperInvariant() -StatePath $script:statePath `
                -SafeModeCommand { param($Mode) $script:events += $Mode })
        $script:events | Should -Be @('CommandPrompt')
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Armed'
    }

    It 'refuses to arm different packages over a Pending retry' {
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages $script:package -Path $script:statePath)
        { Enable-AtlasCbsRetry -Packages (Join-Path $TestDrive 'other.cab') -StatePath $script:statePath `
                -SafeModeCommand { param($Mode) $script:events += $Mode } } |
            Should -Throw '*different CBS retry is already pending*'
        @($script:events).Count | Should -Be 0
        (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Pending'
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

    Context 'The Atlas 0.5 Safe Mode package list' {
        BeforeEach {
            $script:legacyPath = Join-Path $TestDrive 'safeModePackagesToInstall.atlasmodule'
            if (Test-Path -LiteralPath $script:legacyPath) {
                Remove-Item -LiteralPath $script:legacyPath -Force
            }
            Mock Get-AtlasCbsRetryStatePath { $script:statePath }
            Mock Get-AtlasLegacyCbsRetryStatePath { $script:legacyPath }
            Mock Get-AtlasLegacyCbsRetryShell { 'explorer.exe' }
            $script:legacyPackage = Join-Path $TestDrive 'Z-Atlas-NoDefender-Package31bf3856ad364e35amd64.cab'
        }

        It 'is not read as a retry in progress' {
            # 0.5 never deleted the list, so it's left behind on PCs where nothing is pending.
            Set-Content -LiteralPath $script:legacyPath -Value $script:legacyPackage
            Read-AtlasCbsRetryState | Should -BeNullOrEmpty
            Test-Path -LiteralPath $script:statePath | Should -BeFalse
        }

        It 'records the packages it named and removes it' {
            Set-Content -LiteralPath $script:legacyPath -Value $script:legacyPackage
            $output = @(Remove-AtlasLegacyCbsRetryList)
            ($output -join ' ') | Should -BeLike "*$($script:legacyPackage)*"
            Test-Path -LiteralPath $script:legacyPath | Should -BeFalse
        }

        It 'removes an empty list without failing' {
            Set-Content -LiteralPath $script:legacyPath -Value ''
            { Remove-AtlasLegacyCbsRetryList } | Should -Not -Throw
            Test-Path -LiteralPath $script:legacyPath | Should -BeFalse
        }

        It 'keeps the list while the Atlas 0.5 retry is still set to run' {
            Mock Get-AtlasLegacyCbsRetryShell {
                $packageScript = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Scripts\packageInstall.ps1'
                "explorer.exe,cmd /c RunAsTI powershell -NoP -EP Unrestricted -File `"$packageScript`" -SafeMode"
            }
            Set-Content -LiteralPath $script:legacyPath -Value $script:legacyPackage
            { Remove-AtlasLegacyCbsRetryList } | Should -Throw '*Restart Windows to let it finish*'
            Test-Path -LiteralPath $script:legacyPath | Should -BeTrue
        }
    }

    Context 'CBS retry recovery' {
        BeforeAll {
            # 'checks for a TrustedInstaller token' needs the real Assert-AtlasPrivilege.
            Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force

            # Stands in for the installed Atlas.Software command the recovery resolves.
            function Install-AtlasCbsPackage {
                param([string[]]$Packages, [switch]$LiteralPaths)
                $null = $Packages, $LiteralPaths
                $script:events += 'Install'
                [pscustomobject]@{ FailedPackages = @() }
            }
        }

        AfterAll {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath 'Function:\Install-AtlasCbsPackage' `
                -ErrorAction SilentlyContinue
        }

        BeforeEach {
            $script:safeMode = { param($Mode) $script:events += $Mode }
        }

        It 'checks for a TrustedInstaller token before it leaves Safe Mode' {
            # The Safe Mode command prompt has an administrator token, not TrustedInstaller.
            [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
            { Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath -SafeModeCommand $script:safeMode } |
                Should -Throw '*TrustedInstaller*'
            $script:events | Should -BeNullOrEmpty
            (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Armed'
        }

        It 'leaves Safe Mode and services the packages once the token is TrustedInstaller' {
            Mock Assert-AtlasPrivilege {}
            [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
            Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath -SafeModeCommand $script:safeMode
            Should -Invoke Assert-AtlasPrivilege -Times 1 -Exactly -ParameterFilter { $TrustedInstaller }
            $script:events | Should -Be @('Exit', 'Install')
            Test-Path -LiteralPath $script:statePath | Should -BeFalse
        }

        It 'says how to give up a retry that is not armed' {
            [void](Write-AtlasCbsRetryState -Phase Pending -Packages $script:package -Path $script:statePath)
            { Invoke-AtlasCbsRetryRecovery -StatePath $script:statePath -SafeModeCommand $script:safeMode } |
                Should -Throw '*Invoke-AtlasCbsRetry.cmd" /discard*'
            $script:events | Should -BeNullOrEmpty
        }
    }

    Context 'Giving up a CBS retry' {
        BeforeEach {
            $script:safeMode = { param($Mode) $script:events += $Mode }
            Mock Restore-AtlasCbsRetryPrompt {}
        }

        It 'leaves Safe Mode and removes an armed retry' {
            [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
            Invoke-AtlasCbsRetryDiscard -StatePath $script:statePath -SafeModeCommand $script:safeMode |
                Should -BeTrue
            $script:events | Should -Be @('Exit')
            Test-Path -LiteralPath $script:statePath | Should -BeFalse
        }

        It 'removes state it cannot read' {
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($script:statePath))
            Set-Content -LiteralPath $script:statePath -Value '{"Version":1,"Phase":"Other"}'
            Invoke-AtlasCbsRetryDiscard -StatePath $script:statePath -SafeModeCommand $script:safeMode |
                Should -BeTrue
            Test-Path -LiteralPath $script:statePath | Should -BeFalse
        }

        It 'changes nothing when no retry is waiting' {
            Invoke-AtlasCbsRetryDiscard -StatePath $script:statePath -SafeModeCommand $script:safeMode |
                Should -BeFalse
            $script:events | Should -BeNullOrEmpty
        }

        It 'gives up a retry that was never armed before an update, and says which packages it named' {
            [void](Write-AtlasCbsRetryState -Phase Pending -Packages $script:package -Path $script:statePath)
            $output = @(Clear-AtlasUnarmedCbsRetry -StatePath $script:statePath)
            ($output -join ' ') | Should -BeLike "*$($script:package)*"
            Test-Path -LiteralPath $script:statePath | Should -BeFalse
            Should -Invoke Restore-AtlasCbsRetryPrompt -Times 1 -Exactly
        }

        It 'keeps an armed retry for its Safe Mode recovery' {
            [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package -Path $script:statePath)
            Clear-AtlasUnarmedCbsRetry -StatePath $script:statePath | Should -BeNullOrEmpty
            (Read-AtlasCbsRetryState -Path $script:statePath).Phase | Should -BeExactly 'Armed'
        }
    }

    Context 'The CBS retry instruction' {
        It 'names a launcher the Atlas package includes, for both recovering and giving up' {
            $launcher = Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasCbsRetry.cmd'
            Test-Path -LiteralPath $launcher -PathType Leaf | Should -BeTrue
            $installed = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Scripts\Entry\Invoke-AtlasCbsRetry.cmd'
            Get-AtlasCbsRetryInstruction | Should -BeLike "*run `"$installed`" to retry*`"$installed`" /discard*"
            Get-AtlasCbsRetryInstruction -Phase Pending | Should -BeLike "*`"$installed`" /discard*"
        }
    }
}

Describe 'The CBS retry Safe Mode prompt' {
    BeforeEach {
        $script:prompt = [pscustomobject]@{
            SavedPrompt    = Join-Path $TestDrive 'Recovery\CbsRetryPrompt.json'
            EnvironmentKey = 'TestRegistry:\Environment'
        }
        if (!(Test-Path -LiteralPath $script:prompt.EnvironmentKey)) {
            New-Item -Path $script:prompt.EnvironmentKey -Force | Out-Null
        }
        Remove-ItemProperty -LiteralPath $script:prompt.EnvironmentKey -Name PROMPT -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $script:prompt.SavedPrompt) { Remove-Item -LiteralPath $script:prompt.SavedPrompt -Force }
        function Get-Prompt {
            (Get-ItemProperty -LiteralPath $script:prompt.EnvironmentKey).PSObject.Properties['PROMPT']
        }
    }

    It 'shows the launcher at the prompt, then removes it again' {
        Set-AtlasCbsRetryPrompt -Paths $script:prompt
        $installed = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Scripts\Entry\Invoke-AtlasCbsRetry.cmd'
        (Get-Prompt).Value | Should -BeLike "*`$_Run `"$installed`" to retry*/discard*`$P`$G"

        Restore-AtlasCbsRetryPrompt -Paths $script:prompt
        Get-Prompt | Should -BeNullOrEmpty
        Test-Path -LiteralPath $script:prompt.SavedPrompt | Should -BeFalse
    }

    It "saves the original prompt once, so arming again doesn't save Atlas's own" {
        Set-ItemProperty -LiteralPath $script:prompt.EnvironmentKey -Name PROMPT -Value '$T $P$G'
        Set-AtlasCbsRetryPrompt -Paths $script:prompt
        Set-AtlasCbsRetryPrompt -Paths $script:prompt
        Restore-AtlasCbsRetryPrompt -Paths $script:prompt
        (Get-Prompt).Value | Should -BeExactly '$T $P$G'
    }

    It "removes Atlas's prompt when the saved one is unreadable" {
        Set-ItemProperty -LiteralPath $script:prompt.EnvironmentKey -Name PROMPT -Value '$T $P$G'
        Set-AtlasCbsRetryPrompt -Paths $script:prompt
        Set-Content -LiteralPath $script:prompt.SavedPrompt -Value 'not json'
        Restore-AtlasCbsRetryPrompt -Paths $script:prompt
        Get-Prompt | Should -BeNullOrEmpty
    }

    It 'changes nothing when no prompt was set' {
        Set-ItemProperty -LiteralPath $script:prompt.EnvironmentKey -Name PROMPT -Value '$T $P$G'
        Restore-AtlasCbsRetryPrompt -Paths $script:prompt
        (Get-Prompt).Value | Should -BeExactly '$T $P$G'
    }

    It 'sets the prompt with the Safe Mode the retry arms, and puts it back when the retry leaves' {
        Mock Set-AtlasSafeMode {}
        Mock Set-AtlasCbsRetryPrompt {}
        Mock Restore-AtlasCbsRetryPrompt {}
        Invoke-AtlasCbsRetrySafeMode -Mode CommandPrompt
        Should -Invoke Set-AtlasCbsRetryPrompt -Times 1 -Exactly
        Should -Invoke Restore-AtlasCbsRetryPrompt -Times 0 -Exactly
        Invoke-AtlasCbsRetrySafeMode -Mode Exit
        Should -Invoke Restore-AtlasCbsRetryPrompt -Times 1 -Exactly
    }
}
