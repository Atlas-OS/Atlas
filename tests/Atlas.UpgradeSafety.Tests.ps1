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
