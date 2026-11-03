param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ReplacementScript = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Install\Tasks\Invoke-AtlasPayloadReplacement.ps1'
    $cbsRetryScript = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\CbsRetry.ps1'
    . $cbsRetryScript -LibraryOnly
    . $script:ReplacementScript -LibraryOnly

    function New-TestInstallState {
        param(
            [ValidateSet('Fresh', 'Upgrade', 'Reapply', 'Rebase')][string]$Mode,
            [bool]$IsOobe = $false,
            [string]$Status = 'Running'
        )
        [pscustomobject]@{ status = $Status; mode = $Mode; isOobe = $IsOobe }
    }
}

Describe 'Atlas file replacement plan' {
    It 'maps <Mode> OOBE=<IsOobe> to stop=<Stop> remove=<Remove>' -TestCases @(
        @{ Mode = 'Fresh'; IsOobe = $false; Stop = $false; Remove = $false }
        @{ Mode = 'Fresh'; IsOobe = $true; Stop = $false; Remove = $false }
        @{ Mode = 'Upgrade'; IsOobe = $false; Stop = $true; Remove = $true }
        @{ Mode = 'Upgrade'; IsOobe = $true; Stop = $true; Remove = $false }
        @{ Mode = 'Reapply'; IsOobe = $false; Stop = $true; Remove = $true }
        @{ Mode = 'Reapply'; IsOobe = $true; Stop = $true; Remove = $false }
        @{ Mode = 'Rebase'; IsOobe = $false; Stop = $true; Remove = $true }
        @{ Mode = 'Rebase'; IsOobe = $true; Stop = $true; Remove = $false }
    ) {
        $plan = Resolve-AtlasPayloadReplacementPlan `
            -InstallState (New-TestInstallState -Mode $Mode -IsOobe $IsOobe)
        $plan.Mode | Should -BeExactly $Mode
        $plan.StopInstalledPayload | Should -Be $Stop
        $plan.RemoveInstalledPayload | Should -Be $Remove
    }

    It 'requires committed Running install state' {
        { Resolve-AtlasPayloadReplacementPlan `
                -InstallState (New-TestInstallState -Mode Fresh -Status Capturing) } |
            Should -Throw -ExpectedMessage '*requires a Running install state*'
    }

    It 'requires a typed OOBE decision' {
        $state = [pscustomobject]@{ status = 'Running'; mode = 'Fresh'; isOobe = 'false' }
        { Resolve-AtlasPayloadReplacementPlan -InstallState $state } |
            Should -Throw -ExpectedMessage '*isOobe must be a Boolean*'
    }
}

Describe 'Atlas file replacement sequencing' {
    BeforeEach {
        $script:Events = [Collections.Generic.List[string]]::new()
        $script:AtlasExtractedExecutablesRoot = 'C:\extracted'
        $script:AtlasWindowsPath = 'C:\Windows'

        Mock Assert-AtlasPayloadReplacementAllowed { $script:Events.Add('CBS') }
        Mock Invoke-AtlasInstalledPayloadStop { $script:Events.Add('Stop') }
        Mock Invoke-AtlasProcessExplorerStop { $script:Events.Add('ProcessExplorer') }
        Mock Invoke-AtlasInstalledPayloadRemove { $script:Events.Add('Remove') }
        Mock Invoke-AtlasExtractedPayloadCopy { $script:Events.Add('Copy') }
        Mock Assert-AtlasPayloadInstalled { $script:Events.Add('Verify') }
        $script:ProcessExplorerChoiceEnabled = $true
        Mock Test-AtlasProcessExplorerChoiceEnabled { $script:Events.Add('Choice'); $script:ProcessExplorerChoiceEnabled }
        Mock Invoke-AtlasProcessExplorerRestore { $script:Events.Add('RestoreProcessExplorer') }
    }

    It 'copies and verifies fresh files without touching an old install' {
        $plan = Resolve-AtlasPayloadReplacementPlan `
            -InstallState (New-TestInstallState -Mode Fresh)
        Invoke-AtlasPayloadReplacementCore -Plan $plan
        @($script:Events) | Should -Be @('CBS', 'Copy', 'Verify')
    }

    It 'stops, removes, copies, and verifies an upgrade in order' {
        $plan = Resolve-AtlasPayloadReplacementPlan `
            -InstallState (New-TestInstallState -Mode Upgrade)
        Invoke-AtlasPayloadReplacementCore -Plan $plan
        @($script:Events) | Should -Be @('CBS', 'Stop', 'ProcessExplorer', 'Remove', 'Copy', 'Verify')
    }

    It 'does not remove the old files during an OOBE reapply' {
        $plan = Resolve-AtlasPayloadReplacementPlan `
            -InstallState (New-TestInstallState -Mode Reapply -IsOobe $true)
        Invoke-AtlasPayloadReplacementCore -Plan $plan
        @($script:Events) | Should -Be @('CBS', 'Stop', 'ProcessExplorer', 'Copy', 'Verify')
    }

    It 'blocks every mutation while CBS retry is pending' {
        Mock Assert-AtlasPayloadReplacementAllowed {
            $script:Events.Add('CBS')
            throw 'CBS retry state is Armed'
        }
        $plan = Resolve-AtlasPayloadReplacementPlan `
            -InstallState (New-TestInstallState -Mode Upgrade)
        { Invoke-AtlasPayloadReplacementCore -Plan $plan } |
            Should -Throw -ExpectedMessage '*CBS retry state is Armed*'
        @($script:Events) | Should -Be @('CBS')
    }

    It 'does not continue after old-file cleanup fails' {
        Mock Invoke-AtlasInstalledPayloadRemove {
            $script:Events.Add('Remove')
            throw 'remove failed'
        }
        $plan = Resolve-AtlasPayloadReplacementPlan `
            -InstallState (New-TestInstallState -Mode Upgrade)
        { Invoke-AtlasPayloadReplacementCore -Plan $plan } |
            Should -Throw -ExpectedMessage '*remove failed*'
        @($script:Events) | Should -Be @('CBS', 'Stop', 'ProcessExplorer', 'Remove')
    }

    It 'reinstalls an enabled Process Explorer when a resume skips Defaults: <Case>' -TestCases @(
        @{ Case = 'Defaults done, choice enabled'; Steps = @('PreInstall', 'Defaults'); Enabled = $true
            Expected = @('CBS', 'Choice', 'Stop', 'ProcessExplorer', 'Remove', 'Copy', 'Verify', 'RestoreProcessExplorer') }
        @{ Case = 'Defaults done, choice disabled'; Steps = @('Defaults'); Enabled = $false
            Expected = @('CBS', 'Choice', 'Stop', 'ProcessExplorer', 'Remove', 'Copy', 'Verify') }
        @{ Case = 'Defaults still to run'; Steps = @('PreInstall'); Enabled = $true
            Expected = @('CBS', 'Stop', 'ProcessExplorer', 'Remove', 'Copy', 'Verify') }
    ) {
        param($Case, $Steps, $Enabled, $Expected)
        $script:ProcessExplorerChoiceEnabled = $Enabled
        $state = [pscustomobject]@{ status = 'Running'; mode = 'Upgrade'; isOobe = $false; completedSteps = $Steps }
        Invoke-AtlasPayloadReplacementCore -Plan (Resolve-AtlasPayloadReplacementPlan -InstallState $state)
        @($script:Events) | Should -Be $Expected -Because $Case
    }
}

Describe 'Process Explorer reinstall after replacement' {
    BeforeEach {
        $script:AtlasWindowsPath = Join-Path $TestDrive 'Windows'
        $script:PackageHelper = Join-Path $script:AtlasWindowsPath 'AtlasModules\Scripts\Operations\ProcessExplorer-Package.ps1'
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $script:PackageHelper) | Out-Null
    }

    It 'runs the installed package helper without disabling pcw' {
        Set-Content -LiteralPath $script:PackageHelper -Value 'function Install-AtlasProcessExplorerPackage { param([switch]$DisablePcw) "installed DisablePcw=$DisablePcw" }'
        @(Invoke-AtlasProcessExplorerRestore) | Should -Be @('installed DisablePcw=False', 'Reinstalled Process Explorer for the recorded ProcessExplorer choice.')
    }

    It 'fails the step, naming the choice, when the reinstall fails' {
        Set-Content -LiteralPath $script:PackageHelper -Value 'function Install-AtlasProcessExplorerPackage { throw "download failed" }'
        { Invoke-AtlasProcessExplorerRestore } | Should -Throw '*recorded ProcessExplorer choice failed: download failed*'
    }
}

Describe 'Process Explorer choice before the reinstall' {
    BeforeEach {
        $script:ChoicePath = 'HKLM:\SOFTWARE\AtlasOS\Services\ProcessExplorer'
        Mock Test-Path { $script:ChoiceKeyExists } -ParameterFilter { $LiteralPath -eq $script:ChoicePath }
        Mock Get-Item {
            $key = [pscustomobject]@{ Values = $script:ChoiceValues }
            $key | Add-Member -MemberType ScriptMethod -Name GetValueNames -Value { return @($this.Values.Keys) }
            $key | Add-Member -MemberType ScriptMethod -Name GetValueKind -Value { param($Name) return $this.Values[$Name].Kind }
            $key | Add-Member -MemberType ScriptMethod -Name GetValue -Value { param($Name) return $this.Values[$Name].Data }
            return $key
        } -ParameterFilter { $LiteralPath -eq $script:ChoicePath }
    }

    # Stop-ProcessExplorerUpgrade.ps1 keeps the choice through the teardown on the same
    # reading, so only a DWord state of 1 counts as enabled.
    It 'reads <Case> as <Expected>' -TestCases @(
        @{ Case = 'a DWord state of 1'; Exists = $true; Expected = $true
            Values = @{ state = @{ Kind = [Microsoft.Win32.RegistryValueKind]::DWord; Data = 1 } } }
        @{ Case = 'a missing key'; Exists = $false; Expected = $false; Values = @{} }
        @{ Case = 'a key without a state value'; Exists = $true; Expected = $false
            Values = @{ other = @{ Kind = [Microsoft.Win32.RegistryValueKind]::DWord; Data = 1 } } }
        @{ Case = 'a DWord state of 0'; Exists = $true; Expected = $false
            Values = @{ state = @{ Kind = [Microsoft.Win32.RegistryValueKind]::DWord; Data = 0 } } }
        @{ Case = 'a String state of 1'; Exists = $true; Expected = $false
            Values = @{ state = @{ Kind = [Microsoft.Win32.RegistryValueKind]::String; Data = '1' } } }
    ) {
        param($Case, $Exists, $Values, $Expected)
        $script:ChoiceKeyExists = $Exists
        $script:ChoiceValues = $Values
        Test-AtlasProcessExplorerChoiceEnabled | Should -Be $Expected -Because $Case
        Should -Invoke Get-Item -Times ([int]$Exists) -Exactly -ParameterFilter { $LiteralPath -eq $script:ChoicePath }
    }
}

Describe 'Installed Atlas file verification' {
    BeforeEach {
        $script:ExtractedRoot = Join-Path $TestDrive 'extracted'
        $script:WindowsRoot = Join-Path $TestDrive 'Windows'
        foreach ($directory in @(
                'AtlasModules',
                'AtlasDesktop',
                'Themes'
            )) {
            New-Item -Path (Join-Path $script:ExtractedRoot $directory) `
                -ItemType Directory -Force | Out-Null
        }
        foreach ($directory in @(
                'AtlasModules\Scripts',
                'AtlasDesktop',
                'Resources\Themes'
            )) {
            New-Item -Path (Join-Path $script:WindowsRoot $directory) `
                -ItemType Directory -Force | Out-Null
        }
        Set-Content -LiteralPath (Join-Path $script:WindowsRoot 'AtlasModules\Scripts\Initialize-AtlasPowerShell.ps1') `
            -Value '# installed bootstrap'
        Set-Content -LiteralPath (Join-Path $script:ExtractedRoot 'Themes\atlas.theme') `
            -Value 'source theme'
        Set-Content -LiteralPath (Join-Path $script:WindowsRoot 'Resources\Themes\atlas.theme') `
            -Value 'installed theme'
    }

    It 'accepts the installed roots, bootstrap, and theme' {
        { Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:ExtractedRoot `
                -WindowsPath $script:WindowsRoot } | Should -Not -Throw
    }

    It 'fails when the installed bootstrap is missing' {
        Remove-Item -LiteralPath (Join-Path $script:WindowsRoot 'AtlasModules\Scripts\Initialize-AtlasPowerShell.ps1')
        { Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:ExtractedRoot `
                -WindowsPath $script:WindowsRoot } |
            Should -Throw -ExpectedMessage '*Atlas bootstrap*is missing*'
    }
}

Describe 'CBS retry file replacement gate' {
    BeforeEach {
        $script:GateEvents = [Collections.Generic.List[string]]::new()
        # Never touch the real System32 list or the real retry state from a test.
        Mock Remove-AtlasLegacyCbsRetryList { $script:GateEvents.Add('Legacy') }
        Mock Clear-AtlasUnarmedCbsRetry { $script:GateEvents.Add('Unarmed') }
    }

    It 'allows replacement when no retry exists' {
        Mock Read-AtlasCbsRetryState { $script:GateEvents.Add('Read'); $null }
        { Assert-AtlasPayloadReplacementAllowed } | Should -Not -Throw
        # The Atlas 0.5 list and a retry nobody armed are given up before the state decides.
        @($script:GateEvents) | Should -Be @('Legacy', 'Unarmed', 'Read')
    }

    It 'rejects a <Phase> retry, naming the state file and the way out' -TestCases @(
        @{ Phase = 'Pending'; Instruction = '*Invoke-AtlasCbsRetry.cmd" /discard as an administrator*' }
        @{ Phase = 'Armed'; Instruction = '*Safe Mode with Command Prompt*Invoke-AtlasCbsRetry.cmd*' }
    ) {
        Mock Read-AtlasCbsRetryState { [pscustomobject]@{ Phase = $Phase } }
        { Assert-AtlasPayloadReplacementAllowed } |
            Should -Throw -ExpectedMessage "*CBS retry state is '$Phase' ('$(Get-AtlasCbsRetryStatePath)')*"
        { Assert-AtlasPayloadReplacementAllowed } | Should -Throw -ExpectedMessage $Instruction
    }

    It 'fails closed when retry-state reading fails' {
        Mock Read-AtlasCbsRetryState { throw 'invalid CBS retry state' }
        { Assert-AtlasPayloadReplacementAllowed } |
            Should -Throw -ExpectedMessage '*invalid CBS retry state*'
    }

    It 'stops while the Atlas 0.5 retry is still set to run' {
        Mock Remove-AtlasLegacyCbsRetryList { throw 'Restart Windows to let it finish' }
        Mock Read-AtlasCbsRetryState { $null }
        { Assert-AtlasPayloadReplacementAllowed } | Should -Throw -ExpectedMessage '*Restart Windows to let it finish*'
        Should -Invoke Read-AtlasCbsRetryState -Times 0 -Exactly
    }
}

Describe 'CBS retry file replacement gate with retry state on disk' {
    BeforeEach {
        $script:statePath = Join-Path $TestDrive 'Recovery\CbsRetry.json'
        $script:legacyPath = Join-Path $TestDrive 'safeModePackagesToInstall.atlasmodule'
        foreach ($path in @($script:statePath, $script:legacyPath)) {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        }
        $script:package = Join-Path $TestDrive 'one.cab'
        Mock Get-AtlasCbsRetryStatePath { $script:statePath }
        Mock Get-AtlasLegacyCbsRetryStatePath { $script:legacyPath }
        Mock Get-AtlasLegacyCbsRetryShell { 'explorer.exe' }
        Mock Invoke-WithAtlasCbsRetryLock { & $Action }
    }

    It 'gives up a retry that was never armed and the Atlas 0.5 list, then allows replacement' {
        # Atlas 0.5 never deleted its list, and earlier 0.6 builds recorded it as a Pending retry.
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages $script:package)
        Set-Content -LiteralPath $script:legacyPath -Value $script:package
        { Assert-AtlasPayloadReplacementAllowed } | Should -Not -Throw
        Test-Path -LiteralPath $script:statePath | Should -BeFalse
        Test-Path -LiteralPath $script:legacyPath | Should -BeFalse
    }

    It 'keeps blocking an armed retry' {
        [void](Write-AtlasCbsRetryState -Phase Armed -Packages $script:package)
        { Assert-AtlasPayloadReplacementAllowed } |
            Should -Throw -ExpectedMessage "*CBS retry state is 'Armed' ('$($script:statePath)')*"
        (Read-AtlasCbsRetryState).Phase | Should -BeExactly 'Armed'
    }
}

Describe 'Install session logs kept with the machine''s' {
    BeforeAll {
        $script:SessionScript = Join-Path $script:RepoRoot 'playbook\Executables\AtlasModules\Scripts\Install\Invoke-AtlasInstallSession.ps1'
        $script:SessionAst = [Management.Automation.Language.Parser]::ParseFile($script:SessionScript, [ref]$null, [ref]$null)
        foreach ($name in @('Write-AtlasSessionLog', 'Save-AtlasSessionLog')) {
            $function = $script:SessionAst.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
            . ([scriptblock]::Create($function.Extent.Text))
        }
    }

    It 'copies the phase log under its UTC time and phase, replacing nothing else' {
        $root = Join-Path $TestDrive "Logs-$([guid]::NewGuid().ToString('N'))"
        $sessionLog = Join-Path $TestDrive 'install-run.log'
        Set-Content -LiteralPath $sessionLog -Value 'the whole run'
        $now = [DateTime]::new(2026, 10, 31, 14, 25, 30, [DateTimeKind]::Utc)

        Save-AtlasSessionLog -LogPath $sessionLog -PhaseName Run -LogRoot $root -Now $now

        $copy = Join-Path $root 'install\20261031-142530-install-run.log'
        Get-Content -LiteralPath $copy | Should -Be 'the whole run'
        @(Get-ChildItem -LiteralPath (Join-Path $root 'install')).Count | Should -Be 1
    }

    It 'only notes in the phase log a copy it couldn''t make' {
        $sessionLog = Join-Path $TestDrive 'install-capture.log'
        Set-Content -LiteralPath $sessionLog -Value 'start'
        $root = Join-Path $TestDrive "Blocked-$([guid]::NewGuid().ToString('N'))"
        # A file where the install folder should be stops the copy.
        $null = New-Item -Path $root -ItemType Directory
        Set-Content -LiteralPath (Join-Path $root 'install') -Value 'not a folder'

        { Save-AtlasSessionLog -LogPath $sessionLog -PhaseName Capture -LogRoot $root } | Should -Not -Throw
        (Get-Content -LiteralPath $sessionLog -Raw) | Should -Match "Couldn't copy this log to the machine's Logs folder"
    }

    It 'refuses to copy through a reparse point' {
        $sessionLog = Join-Path $TestDrive 'install-junction.log'
        Set-Content -LiteralPath $sessionLog -Value 'start'
        $elsewhere = Join-Path $TestDrive "Elsewhere-$([guid]::NewGuid().ToString('N'))"
        $root = Join-Path $TestDrive "Junction-$([guid]::NewGuid().ToString('N'))"
        $null = New-Item -Path $elsewhere -ItemType Directory
        try { New-Item -Path $root -ItemType Junction -Value $elsewhere -ErrorAction Stop | Out-Null }
        catch { Set-ItResult -Skipped -Because 'this host cannot create junctions'; return }

        Save-AtlasSessionLog -LogPath $sessionLog -PhaseName Run -LogRoot $root
        @(Get-ChildItem -LiteralPath $elsewhere -Recurse) | Should -HaveCount 0
        (Get-Content -LiteralPath $sessionLog -Raw) | Should -Match 'is a reparse point'
    }

    It 'saves the phase log before every exit, whichever way the phase ends' {
        # Success of either phase, a failed Run plan, and any failure caught.
        $exits = @($script:SessionAst.FindAll({ param($node) $node -is [Management.Automation.Language.ExitStatementAst] }, $true))
        $exits.Count | Should -Be 3
        foreach ($exit in $exits) {
            $statements = @($exit.Parent.Statements)
            $index = [array]::IndexOf($statements, $exit)
            $index | Should -BeGreaterThan 0
            $statements[$index - 1].Extent.Text | Should -BeExactly 'Save-AtlasSessionLog' -Because "line $($exit.Extent.StartLineNumber)"
        }
    }

    It 'tidies the machine''s install logs as Run begins, before anything appends to them' {
        $switch = $script:SessionAst.Find({ param($node) $node -is [Management.Automation.Language.SwitchStatementAst] }, $true)
        $run = @($switch.Clauses | Where-Object { $_.Item1.Extent.Text -ceq "'Run'" })
        $run.Count | Should -Be 1
        $first = @($run[0].Item2.Statements)[0]
        $first | Should -BeOfType ([Management.Automation.Language.TryStatementAst])
        $first.Body.Extent.Text | Should -Match '^\{\s*Invoke-AtlasInstallLogRetention\s*\}$' -Because 'it runs with its own limits'
    }

    It 'leaves a copy when a phase fails before anything loads' {
        # The session script runs from a copy whose Windows folder is a test one, and
        # without its bootstrap, so it fails at once.
        $harness = Join-Path $TestDrive "Session-$([guid]::NewGuid().ToString('N'))"
        $windows = Join-Path $harness 'Windows'
        $null = New-Item -Path (Join-Path $harness 'AtlasModules\Scripts\Install'), $windows -ItemType Directory -Force
        $windowsExpression = "[Environment]::GetFolderPath('Windows')"
        $source = [IO.File]::ReadAllText($script:SessionScript)
        $source.Contains($windowsExpression) | Should -BeTrue
        [IO.File]::WriteAllText((Join-Path $harness 'AtlasModules\Scripts\Install\Invoke-AtlasInstallSession.ps1'), $source.Replace($windowsExpression, '$env:ATLAS_TEST_WINDIR'))

        $env:ATLAS_TEST_WINDIR = $windows
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $powershell = [IO.Path]::Combine([Environment]::SystemDirectory, 'WindowsPowerShell', 'v1.0', 'powershell.exe')
            & $powershell -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass `
                -File (Join-Path $harness 'AtlasModules\Scripts\Install\Invoke-AtlasInstallSession.ps1') -Phase Capture 2>&1 | Out-Null
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $savedPreference
            Remove-Item Env:\ATLAS_TEST_WINDIR -ErrorAction SilentlyContinue
        }

        $exitCode | Should -Be 1
        $copies = @(Get-ChildItem -LiteralPath (Join-Path $windows 'AtlasModules\Logs\install') -Filter '*-install-capture.log')
        $copies.Count | Should -Be 1
        $copies[0].Name | Should -Match '^\d{8}-\d{6}-install-capture\.log$'
        (Get-Content -LiteralPath $copies[0].FullName -Raw) | Should -Match 'The PowerShell bootstrap is missing'
    }
}

Describe 'Install log retention' {
    BeforeAll {
        Import-Module (Join-Path $script:RepoRoot 'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
        $script:Now = [DateTime]::new(2026, 10, 31, 12, 0, 0, [DateTimeKind]::Utc)
        function New-TestLog {
            param([string]$Root, [string]$Name, [int]$AgeDays, [string]$Text = 'x')
            $path = Join-Path $Root $Name
            Set-Content -LiteralPath $path -Value $Text
            [IO.File]::SetLastWriteTimeUtc($path, $script:Now.AddDays(-$AgeDays))
        }
    }

    BeforeEach {
        $script:Logs = Join-Path $TestDrive "install-$([guid]::NewGuid().ToString('N'))"
        $null = New-Item -Path $script:Logs -ItemType Directory
    }

    It 'moves a shared log past its limit aside, replacing the one moved before' {
        New-TestLog $script:Logs 'atlas-install.log' 0 ('a' * 64)
        New-TestLog $script:Logs 'atlas-install.previous.log' 30 'older'
        New-TestLog $script:Logs 'warnings-summary.log' 0 'short'

        Invoke-AtlasInstallLogRetention -Path $script:Logs -RotateBytes 32 -Now $script:Now

        Test-Path -LiteralPath (Join-Path $script:Logs 'atlas-install.log') | Should -BeFalse
        (Get-Content -LiteralPath (Join-Path $script:Logs 'atlas-install.previous.log') -Raw).Trim() | Should -BeExactly ('a' * 64)
        Get-Content -LiteralPath (Join-Path $script:Logs 'warnings-summary.log') | Should -BeExactly 'short'
        Test-Path -LiteralPath (Join-Path $script:Logs 'warnings-summary.previous.log') | Should -BeFalse
    }

    It 'deletes timestamped logs past the age limit, apart from the newest ones' {
        New-TestLog $script:Logs '20260601-090000-install-run.log' 152
        New-TestLog $script:Logs '20260725-090000-Tweaks-qol-Admin.log' 98
        New-TestLog $script:Logs '20260731-090000-install-capture.log' 92
        New-TestLog $script:Logs '20261021-090000-install-run.log' 10
        New-TestLog $script:Logs '20261030-090000-Defaults-Admin.log' 1
        # Only names that begin with their time are pruned.
        New-TestLog $script:Logs 'notes.log' 400
        New-TestLog $script:Logs 'atlas-install.previous.log' 400

        Invoke-AtlasInstallLogRetention -Path $script:Logs -KeepNewest 3 -Now $script:Now

        @(Get-ChildItem -LiteralPath $script:Logs | ForEach-Object Name | Sort-Object) | Should -Be @(
            '20260731-090000-install-capture.log', '20261021-090000-install-run.log', '20261030-090000-Defaults-Admin.log',
            'atlas-install.previous.log', 'notes.log'
        ) -Because 'the newest three stay however old they are'
    }

    It 'keeps every log within the age limit, however many there are' {
        foreach ($day in 1..5) { New-TestLog $script:Logs ('2026102{0}-090000-install-run.log' -f $day) $day }
        Invoke-AtlasInstallLogRetention -Path $script:Logs -KeepNewest 2 -Now $script:Now
        @(Get-ChildItem -LiteralPath $script:Logs).Count | Should -Be 5
    }

    It 'moves a shared log aside only once it is past 16 MB' {
        foreach ($log in @(@{ Name = 'atlas-install.log'; Length = 16MB + 1 }, @{ Name = 'warnings-summary.log'; Length = 16MB })) {
            $stream = [IO.File]::Create((Join-Path $script:Logs $log.Name))
            try { $stream.SetLength($log.Length) }
            finally { $stream.Dispose() }
        }

        Invoke-AtlasInstallLogRetention -Path $script:Logs -Now $script:Now

        @(Get-ChildItem -LiteralPath $script:Logs | ForEach-Object Name | Sort-Object) |
            Should -Be @('atlas-install.previous.log', 'warnings-summary.log')
    }

    It 'keeps the newest 200 timestamped logs, and any within 90 days: <Case>' -TestCases @(
        @{ Case = 'the 200th is old'; Recent = 199; Old = @(91, 92); Kept = @(91) }
        @{ Case = 'two are within 90 days past the newest 200'; Recent = 200; Old = @(89, 91); Kept = @(89) }
    ) {
        param($Case, $Recent, $Old, $Kept)
        $start = [DateTime]::new(2026, 10, 1, 0, 0, 0, [DateTimeKind]::Utc)
        for ($index = 0; $index -lt $Recent; $index++) {
            $path = Join-Path $script:Logs ('{0:yyyyMMdd-HHmmss}-install-run.log' -f $start.AddMinutes($index))
            [IO.File]::WriteAllText($path, 'x')
            [IO.File]::SetLastWriteTimeUtc($path, $script:Now.AddDays(-1).AddMinutes(-$index))
        }
        foreach ($age in $Old) { New-TestLog $script:Logs ('20260101-0000{0:00}-install-run.log' -f $age) $age }

        Invoke-AtlasInstallLogRetention -Path $script:Logs -Now $script:Now

        @(Get-ChildItem -LiteralPath $script:Logs -Filter '20260101-*').Name | Sort-Object |
            Should -Be @($Kept | ForEach-Object { '20260101-0000{0:00}-install-run.log' -f $_ }) -Because $Case
        @(Get-ChildItem -LiteralPath $script:Logs -Filter '202610*').Count | Should -Be $Recent
    }

    It 'does nothing without the folder, and refuses one that is a reparse point' {
        { Invoke-AtlasInstallLogRetention -Path (Join-Path $TestDrive 'missing') } | Should -Not -Throw
        $junction = Join-Path $TestDrive "junction-$([guid]::NewGuid().ToString('N'))"
        try { New-Item -Path $junction -ItemType Junction -Value $script:Logs -ErrorAction Stop | Out-Null }
        catch { Set-ItResult -Skipped -Because 'this host cannot create junctions'; return }
        { Invoke-AtlasInstallLogRetention -Path $junction } | Should -Throw '*reparse point*'
    }
}
