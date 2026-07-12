param()

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ReplacementScript = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Tasks\Invoke-AtlasPayloadReplacement.ps1'
    $cbsRetryScript = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\CbsRetry.ps1'
    . $cbsRetryScript -LibraryOnly
    . $script:ReplacementScript -LibraryOnly

    function New-TestInstallState {
        param(
            [ValidateSet('Fresh', 'Upgrade', 'Reapply')][string]$Mode,
            [bool]$IsOobe = $false,
            [string]$Status = 'Running'
        )
        [pscustomobject]@{ status = $Status; mode = $Mode; isOobe = $IsOobe }
    }
}

Describe 'Atlas payload replacement plan' {
    It 'maps <Mode> OOBE=<IsOobe> to stop=<Stop> remove=<Remove>' -TestCases @(
        @{ Mode = 'Fresh'; IsOobe = $false; Stop = $false; Remove = $false }
        @{ Mode = 'Fresh'; IsOobe = $true; Stop = $false; Remove = $false }
        @{ Mode = 'Upgrade'; IsOobe = $false; Stop = $true; Remove = $true }
        @{ Mode = 'Upgrade'; IsOobe = $true; Stop = $true; Remove = $false }
        @{ Mode = 'Reapply'; IsOobe = $false; Stop = $true; Remove = $true }
        @{ Mode = 'Reapply'; IsOobe = $true; Stop = $true; Remove = $false }
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

Describe 'Atlas payload replacement sequencing' {
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
    }

    It 'copies and verifies a fresh payload without touching an old install' {
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

    It 'does not remove the old payload during an OOBE reapply' {
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

    It 'does not continue after old-payload cleanup fails' {
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

    It 'keeps VerifyOnly read-only' {
        Invoke-AtlasPayloadReplacementCore -VerifyOnly
        @($script:Events) | Should -Be @('Verify')
    }
}

Describe 'Installed Atlas payload verification' {
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
                'AtlasModules',
                'AtlasDesktop',
                'Resources\Themes'
            )) {
            New-Item -Path (Join-Path $script:WindowsRoot $directory) `
                -ItemType Directory -Force | Out-Null
        }
        Set-Content -LiteralPath (Join-Path $script:WindowsRoot 'AtlasModules\initPowerShell.ps1') `
            -Value '# installed bootstrap'
        Set-Content -LiteralPath (Join-Path $script:ExtractedRoot 'Themes\atlas.theme') `
            -Value 'source theme'
        Set-Content -LiteralPath (Join-Path $script:WindowsRoot 'Resources\Themes\atlas.theme') `
            -Value 'installed theme'
    }

    It 'accepts the installed roots, bootstrap, and theme payload' {
        { Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:ExtractedRoot `
                -WindowsPath $script:WindowsRoot } | Should -Not -Throw
    }

    It 'fails when the installed bootstrap is missing' {
        Remove-Item -LiteralPath (Join-Path $script:WindowsRoot 'AtlasModules\initPowerShell.ps1')
        { Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:ExtractedRoot `
                -WindowsPath $script:WindowsRoot } |
            Should -Throw -ExpectedMessage '*payload bootstrap*is missing*'
    }
}

Describe 'CBS retry payload replacement gate' {
    It 'allows replacement when no retry exists' {
        Mock Read-AtlasCbsRetryState { $null }
        { Assert-AtlasPayloadReplacementAllowed } | Should -Not -Throw
    }

    It 'rejects both supported retry phases' -TestCases @(
        @{ Phase = 'Pending' }
        @{ Phase = 'Armed' }
    ) {
        Mock Read-AtlasCbsRetryState { [pscustomobject]@{ Phase = $Phase } }
        { Assert-AtlasPayloadReplacementAllowed } |
            Should -Throw -ExpectedMessage "*CBS retry state is '$Phase'*"
    }

    It 'fails closed when retry-state reading fails' {
        Mock Read-AtlasCbsRetryState { throw 'invalid CBS retry state' }
        { Assert-AtlasPayloadReplacementAllowed } |
            Should -Throw -ExpectedMessage '*invalid CBS retry state*'
    }
}
