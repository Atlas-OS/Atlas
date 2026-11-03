BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:installStateModulePath = Join-Path -Path $script:AtlasTestModulesRoot `
        -ChildPath 'Atlas.InstallState\Atlas.InstallState.psd1'
    # Atlas.InstallState imports Atlas.State into its own scope. Loading it here first
    # lets tests read the state document through the same module instance.
    Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.State\Atlas.State.psd1') -Force
    Import-Module -Name $script:installStateModulePath -Force -DisableNameChecking

    function New-TestInstallStatePath {
        $root = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString('N'))
        return Join-Path -Path $root -ChildPath 'active.json'
    }

    function Start-TestInstallState {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [ValidateSet('Capturing', 'Running')][string]$Status = 'Capturing'
        )

        $state = Start-AtlasInstallState -StatePath $Path -TargetVersion '0.6.0' `
            -Mode Fresh -CaptureNonce 'capture-test'
        if ($Status -eq 'Running') {
            $state = Commit-AtlasInstallState -StatePath $Path
        }
        return $state
    }
}

Describe 'Atlas.InstallState lifecycle' {
    It 'accepts ASCII step names under Turkish culture without accepting non-ASCII names' {
        $previous = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('tr-TR')
            $path = New-TestInstallStatePath
            Start-TestInstallState -Path $path -Status Running | Out-Null
            Invoke-AtlasInstallStep -StatePath $path -Name 'PreInstall' -Action {} | Out-Null
            @((Get-AtlasInstallState -StatePath $path).completedSteps) | Should -Contain 'PreInstall'
            $invalid = 'Pre' + [char]0x0130 + 'nstall'
            { Invoke-AtlasInstallStep -StatePath $path -Name $invalid -Action {} } | Should -Throw '*Invalid step name*'
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture = $previous }
    }

    It 'replaces an interrupted option capture instead of merging incompatible choices' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Set-AtlasInstallOptions -StatePath $path -Options @('defender-disable') | Out-Null
        Start-TestInstallState -Path $path | Out-Null
        Set-AtlasInstallOptions -StatePath $path -Options @('defender-enable') | Out-Null
        @((Get-AtlasInstallState -StatePath $path).options) | Should -Be @('defender-enable')
    }

    It 'records an interrupted AME capture afresh instead of merging its options' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'defender-disable' | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'uninstall-edge' | Out-Null
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'defender-enable' | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null

        @((Get-AtlasInstallState -StatePath $path).options) | Should -Be @('defender-enable')
    }

    It 'records options afresh when AME reclassifies a failed run that completed no steps' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'defender-disable' | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        { Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action { throw 'failure' } } | Should -Throw '*failure*'

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply
        $retry.mode | Should -BeExactly 'Fresh'
        @($retry.options).Count | Should -Be 0
        Add-AtlasInstallOption -StatePath $path -Name 'defender-enable' | Out-Null
        @((Get-AtlasInstallState -StatePath $path).options) | Should -Be @('defender-enable')
    }

    It 'keeps a committed run''s options on a same-mode retry that completed no steps' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'defender-enable' | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        { Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action { throw 'failure' } } | Should -Throw '*failure*'

        $retry = Start-TestInstallState -Path $path
        $retry.status | Should -BeExactly 'Running'
        @($retry.options) | Should -Be @('defender-enable')
        Add-AtlasInstallOption -StatePath $path -Name 'defender-enable' | Out-Null
        @((Get-AtlasInstallState -StatePath $path).options) | Should -Be @('defender-enable')
    }

    It 'rejects changed resume options without changing saved choices or completed steps' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Set-AtlasInstallOptions -StatePath $path -Options @('defender-enable') | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action {} | Out-Null
        { Invoke-AtlasInstallStep -StatePath $path -Name 'Software' -Action { throw 'failure' } } | Should -Throw '*failure*'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply | Out-Null
        # The refusal names the options to run again with.
        $refusal = "This installation already started with other choices, and the steps it finished won't run again. Run it again with the choices it started with: defender-enable."
        { Set-AtlasInstallOptions -StatePath $path -Options @('defender-disable') } | Should -Throw -ExpectedMessage $refusal
        { Add-AtlasInstallOption -StatePath $path -Name 'defender-disable' } | Should -Throw -ExpectedMessage $refusal
        Add-AtlasInstallOption -StatePath $path -Name 'defender-enable' | Out-Null
        Set-AtlasInstallOptions -StatePath $path -Options @('defender-enable') | Out-Null
        $state = Get-AtlasInstallState -StatePath $path
        @($state.options) | Should -Be @('defender-enable')
        @($state.completedSteps) | Should -Be @('Features')
    }

    It 'uses the compact Windows install paths by default' {
        $root = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasOS\Install'
        Get-AtlasInstallStatePath | Should -BeExactly (Join-Path $root 'active.json')
        Get-AtlasInstallWorkRoot | Should -BeExactly (Join-Path $root 'work')
    }

    It 'starts a capturing state and creates its work directory' {
        $path = New-TestInstallStatePath
        $state = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
            -Mode Upgrade -IsOobe $true -CaptureNonce 'nonce-1'

        $state.schemaVersion | Should -Be 1
        $state.status | Should -BeExactly 'Capturing'
        $state.mode | Should -BeExactly 'Upgrade'
        $state.isOobe | Should -BeTrue
        $state.options.Count | Should -Be 0
        $state.completedSteps.Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) 'work') | Should -BeTrue
    }

    It 'returns the same install retry and rejects a conflicting install identity' {
        $path = New-TestInstallStatePath
        $first = Start-TestInstallState -Path $path -Status Running

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
            -Mode Fresh -IsOobe $false -CaptureNonce 'replacement'
        $retry.transactionId | Should -BeExactly $first.transactionId
        $retry.mode | Should -BeExactly 'Fresh'
        $retry.isOobe | Should -BeFalse
        $retry.captureNonce | Should -BeExactly 'capture-test'

        {
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.7.0' `
                -Mode Upgrade -CaptureNonce 'other'
        } | Should -Throw -ExpectedMessage '*target*0.6.0*already active*'

        # Each refusal says what to do next.
        {
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
                -Mode Reapply -CaptureNonce 'other'
        } | Should -Throw -ExpectedMessage ("An unfinished Atlas Fresh installation of 0.6.0 is waiting to finish, so a Reapply installation can't start. " +
            'Finish it first: in Atlas Manager, choose Finish installing Atlas 0.6.0, or run Install-Atlas.ps1 again with the options it started with.')

        {
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
                -Mode Fresh -IsOobe $true -CaptureNonce 'other'
        } | Should -Throw -ExpectedMessage "An unfinished Atlas Fresh installation of 0.6.0 is waiting to finish, so a Fresh installation during Windows setup can't start.*"

        {
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
                -Mode Upgrade -CaptureNonce 'other'
        } | Should -Throw -ExpectedMessage '*, so an Upgrade installation can''t start.*'
    }

    It 'names an unfinished installation begun during Windows setup in its refusal' {
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Fresh -IsOobe $true | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        { Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Fresh } |
            Should -Throw -ExpectedMessage "An unfinished Atlas Fresh installation of 0.6.0, begun during Windows setup, is waiting to finish, so a Fresh installation can't start.*"
    }

    It 'resumes the original plan when AME reclassifies a recorded failed run' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'browser-brave' | Out-Null
        $first = Commit-AtlasInstallState -StatePath $path
        $workRoot = Join-Path (Split-Path $path -Parent) 'work'
        [IO.File]::WriteAllText((Join-Path $workRoot 'partial.txt'), 'partial')
        Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action { } | Out-Null

        {
            Invoke-AtlasInstallStep -StatePath $path -Name 'Tweaks/qol' `
                -Action { throw 'install failed' }
        } | Should -Throw -ExpectedMessage '*install failed*'

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
            -Mode Reapply -CaptureNonce 'retry-capture'

        $retry.transactionId | Should -BeExactly $first.transactionId
        $retry.status | Should -BeExactly 'Capturing'
        $retry.mode | Should -BeExactly 'Fresh'
        $retry.captureNonce | Should -BeExactly 'retry-capture'
        @($retry.options) | Should -Be @('browser-brave')
        @($retry.completedSteps) | Should -Contain 'Features'
        Test-Path -LiteralPath (Join-Path $workRoot 'partial.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) 'abandoned.json') | Should -BeFalse
    }

    It 'resumes a reclassified retry again when its capture was interrupted before Commit' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'browser-brave' | Out-Null
        $first = Commit-AtlasInstallState -StatePath $path
        Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action { } | Out-Null
        { Invoke-AtlasInstallStep -StatePath $path -Name 'Tweaks' -Action { throw 'install failed' } } |
            Should -Throw '*install failed*'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -CaptureNonce 'first-retry' | Out-Null

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
            -Mode Reapply -CaptureNonce 'second-retry'

        $retry.transactionId | Should -BeExactly $first.transactionId
        $retry.status | Should -BeExactly 'Capturing'
        $retry.mode | Should -BeExactly 'Fresh'
        $retry.captureNonce | Should -BeExactly 'second-retry'
        @($retry.options) | Should -Be @('browser-brave')
        @($retry.completedSteps) | Should -Be @('Features')
    }

    It 'recovers an older RC abandoned Fresh transaction on a Reapply retry' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'browser-brave' | Out-Null
        $first = Commit-AtlasInstallState -StatePath $path
        Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action { } | Out-Null
        {
            Invoke-AtlasInstallStep -StatePath $path -Name 'Tweaks/privacy' `
                -Action { throw 'older RC failure' }
        } | Should -Throw '*older RC failure*'

        $directory = Split-Path $path -Parent
        Move-Item -LiteralPath $path -Destination (Join-Path $directory 'abandoned.json')
        Remove-Item -LiteralPath (Join-Path $directory 'work') -Recurse -Force

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
            -Mode Reapply -CaptureNonce 'recovered-capture'

        $retry.transactionId | Should -BeExactly $first.transactionId
        $retry.status | Should -BeExactly 'Capturing'
        $retry.mode | Should -BeExactly 'Fresh'
        $retry.captureNonce | Should -BeExactly 'recovered-capture'
        @($retry.options) | Should -Be @('browser-brave')
        @($retry.completedSteps) | Should -Contain 'Features'
        Test-Path -LiteralPath (Join-Path $directory 'abandoned.json') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $directory 'work') -PathType Container | Should -BeTrue
    }

    It 'records each selected option once only during capture' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'browser-brave' | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'BROWSER-BRAVE' | Out-Null

        $state = Get-AtlasInstallState -StatePath $path
        $state.options.Count | Should -Be 1
        $state.options[0] | Should -BeExactly 'browser-brave'

        Commit-AtlasInstallState -StatePath $path | Out-Null
        { Add-AtlasInstallOption -StatePath $path -Name 'install-toolbox' } | Should -Throw '*Run it again with the choices it started with: browser-brave.'
        (Get-AtlasInstallState -StatePath $path).options | Should -Not -Contain 'install-toolbox'
    }

    It 'binds one install user and can refresh only that user session' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Set-AtlasInstallUser -StatePath $path -UserSid 'S-1-5-21-1-2-3-1001' `
            -UserSessionId 2 | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null

        $refreshed = Set-AtlasInstallUser -StatePath $path -UserSid 'S-1-5-21-1-2-3-1001' `
            -UserSessionId 7
        $refreshed.userSessionId | Should -Be 7
        {
            Set-AtlasInstallUser -StatePath $path -UserSid 'S-1-5-21-1-2-3-1002' `
                -UserSessionId 8
        } | Should -Throw -ExpectedMessage '*already bound*'
    }

    It 'commits capture once without replacing captured values' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'defender-enable' | Out-Null
        $first = Commit-AtlasInstallState -StatePath $path
        $second = Commit-AtlasInstallState -StatePath $path

        $first.status | Should -BeExactly 'Running'
        $second.transactionId | Should -BeExactly $first.transactionId
        $second.options | Should -Contain 'defender-enable'
    }
}

Describe 'Atlas.InstallState update path' {
    It 'stores Keep unless asked to choose again' {
        $keep = New-TestInstallStatePath
        (Start-AtlasInstallState -StatePath $keep -TargetVersion '0.6.0' -Mode Reapply).choices | Should -BeExactly 'Keep'
        (Get-AtlasInstallState -StatePath $keep).choices | Should -BeExactly 'Keep'

        $chooseAgain = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $chooseAgain -TargetVersion '0.6.0' -Mode Upgrade -Choices ChooseAgain | Out-Null
        (Get-AtlasInstallState -StatePath $chooseAgain).choices | Should -BeExactly 'ChooseAgain'
    }

    It 'takes the new path while capturing with no completed steps, as the options do' {
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices ChooseAgain | Out-Null
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply | Out-Null
        (Get-AtlasInstallState -StatePath $path).choices | Should -BeExactly 'Keep'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices ChooseAgain | Out-Null
        (Get-AtlasInstallState -StatePath $path).choices | Should -BeExactly 'ChooseAgain'
    }

    It 'keeps the path a run began with once it is <Case>' -TestCases @(
        @{ Case = 'committed'; Steps = @(); Fail = $false }
        @{ Case = 'past its first step'; Steps = @('Features'); Fail = $true }
    ) {
        param($Case, $Steps, $Fail)
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices ChooseAgain | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        foreach ($step in $Steps) { Invoke-AtlasInstallStep -StatePath $path -Name $step -Action {} | Out-Null }
        if ($Fail) { { Invoke-AtlasInstallStep -StatePath $path -Name 'Software' -Action { throw 'failure' } } | Should -Throw '*failure*' }

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices Keep
        $retry.choices | Should -BeExactly 'ChooseAgain' -Because $Case
        (Get-AtlasInstallState -StatePath $path).choices | Should -BeExactly 'ChooseAgain'
    }

    It 'keeps the path when AME reclassifies a failed run that completed steps' {
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Upgrade -Choices ChooseAgain | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        Invoke-AtlasInstallStep -StatePath $path -Name 'Features' -Action {} | Out-Null
        { Invoke-AtlasInstallStep -StatePath $path -Name 'Software' -Action { throw 'failure' } } | Should -Throw '*failure*'

        $retry = Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply
        $retry.mode | Should -BeExactly 'Upgrade'
        $retry.choices | Should -BeExactly 'ChooseAgain'
    }

    It 'loads an install state written before the path existed, and adds the path when it captures again' {
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply | Out-Null
        $older = [IO.File]::ReadAllText($path) | ConvertFrom-Json
        $older.PSObject.Properties.Remove('choices')
        [IO.File]::WriteAllText($path, ($older | ConvertTo-Json -Compress))

        $loaded = Get-AtlasInstallState -StatePath $path
        $loaded.PSObject.Properties['choices'] | Should -BeNullOrEmpty
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices ChooseAgain | Out-Null
        (Get-AtlasInstallState -StatePath $path).choices | Should -BeExactly 'ChooseAgain'
    }

    It 'refuses an install state whose path is <Value>' -TestCases @(
        @{ Value = 'keep' }, @{ Value = 'Sometimes' }, @{ Value = 1 }
    ) {
        param($Value)
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply | Out-Null
        $state = [IO.File]::ReadAllText($path) | ConvertFrom-Json
        $state.choices = $Value
        [IO.File]::WriteAllText($path, ($state | ConvertTo-Json -Compress))
        { Get-AtlasInstallState -StatePath $path } | Should -Throw '*invalid choices value*'
    }

    It 'refuses an install state whose recordedOptions is <Case>' -TestCases @(
        @{ Case = 'a string'; Value = 'defender-enable'; Message = '*recordedOptions must be an array*' }
        @{ Case = 'an array holding a number'; Value = @('defender-enable', 1); Message = '*recordedOptions must contain strings*' }
        @{ Case = 'an array holding an invalid name'; Value = @('not an option'); Message = "*Invalid option name 'not an option'*" }
    ) {
        param($Case, $Value, $Message)
        $path = New-TestInstallStatePath
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply | Out-Null
        $state = [IO.File]::ReadAllText($path) | ConvertFrom-Json
        $state | Add-Member -NotePropertyName recordedOptions -NotePropertyValue $Value
        [IO.File]::WriteAllText($path, ($state | ConvertTo-Json -Compress))
        { Get-AtlasInstallState -StatePath $path } | Should -Throw $Message -Because $Case

        $state.recordedOptions = @('defender-enable')
        [IO.File]::WriteAllText($path, ($state | ConvertTo-Json -Compress))
        @((Get-AtlasInstallState -StatePath $path).recordedOptions) | Should -Be @('defender-enable')
    }

    Context 'Resolve-AtlasInstallChoices' {
        It 'keeps on a first installation, saying -ChooseAgain changes nothing' {
            $path = New-TestInstallStatePath
            $resolved = Resolve-AtlasInstallChoices -StatePath $path -TargetVersion '0.6.0' -Mode Fresh -Requested ChooseAgain
            $resolved.Choices | Should -BeExactly 'Keep'
            $resolved.Summary | Should -BeExactly 'Fresh'
            $resolved.Note | Should -BeExactly 'A first installation applies every choice, so -ChooseAgain changes nothing.'
            (Resolve-AtlasInstallChoices -StatePath $path -TargetVersion '0.6.0' -Mode Fresh).Note | Should -BeNullOrEmpty
        }

        It 'takes the request on an update: <Requested> on <Mode>' -TestCases @(
            @{ Mode = 'Upgrade'; Requested = 'Keep'; Summary = 'Upgrade, keeping your choices' }
            @{ Mode = 'Upgrade'; Requested = 'ChooseAgain'; Summary = 'Upgrade, choosing again' }
            @{ Mode = 'Reapply'; Requested = 'Keep'; Summary = 'Reapply, keeping your choices' }
            @{ Mode = 'Reapply'; Requested = 'ChooseAgain'; Summary = 'Reapply, choosing again' }
            @{ Mode = 'Rebase'; Requested = 'Keep'; Summary = 'Rebase, keeping your choices' }
        ) {
            param($Mode, $Requested, $Summary)
            $resolved = Resolve-AtlasInstallChoices -StatePath (New-TestInstallStatePath) -TargetVersion '0.6.0' -Mode $Mode -Requested $Requested
            $resolved.Choices | Should -BeExactly $Requested
            $resolved.Summary | Should -BeExactly $Summary
            $resolved.Note | Should -BeNullOrEmpty
        }

        It 'refuses to choose again on a Rebase, naming the next step' {
            {
                Resolve-AtlasInstallChoices -StatePath (New-TestInstallStatePath) -TargetVersion '0.6.0' -Mode Rebase -Requested ChooseAgain
            } | Should -Throw -ExpectedMessage ('Windows reinstalled itself while Atlas Manager moved it to a newer version, so this installation first puts back the choices you had. ' +
                'Run it again without -ChooseAgain; once it has finished, you can reinstall Atlas and choose again.')
        }

        It 'continues an unfinished install the way it began: <Began> asked <Requested>' -TestCases @(
            @{ Mode = 'Reapply'; Began = 'ChooseAgain'; Requested = 'Keep'; Note = "Continuing the unfinished installation as it began, choosing again; its choices can't change now." }
            @{ Mode = 'Upgrade'; Began = 'Keep'; Requested = 'ChooseAgain'; Note = "Continuing the unfinished installation as it began, keeping your choices; its choices can't change now." }
            @{ Mode = 'Rebase'; Began = 'Keep'; Requested = 'ChooseAgain'; Note = "Continuing the unfinished installation as it began, keeping your choices; its choices can't change now." }
            @{ Mode = 'Reapply'; Began = 'ChooseAgain'; Requested = 'ChooseAgain'; Note = $null }
        ) {
            param($Mode, $Began, $Requested, $Note)
            $path = New-TestInstallStatePath
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode $Mode -Choices $Began | Out-Null
            Set-AtlasInstallOptions -StatePath $path -Options @('defender-disable', 'mitigations-default') | Out-Null
            Commit-AtlasInstallState -StatePath $path | Out-Null

            $resolved = Resolve-AtlasInstallChoices -StatePath $path -TargetVersion '0.6.0' -Mode $Mode -Requested $Requested
            $resolved.Choices | Should -BeExactly $Began
            $resolved.Note | Should -Be $Note
            @($resolved.ResumedOptions) | Should -Be @('defender-disable', 'mitigations-default') -Because 'its resume must give the options it began with'
        }

        It 'holds an unfinished first installation to its options too' {
            $path = New-TestInstallStatePath
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Fresh | Out-Null
            Set-AtlasInstallOptions -StatePath $path -Options @('defender-enable') | Out-Null
            Commit-AtlasInstallState -StatePath $path | Out-Null
            @((Resolve-AtlasInstallChoices -StatePath $path -TargetVersion '0.6.0' -Mode Fresh).ResumedOptions) | Should -Be @('defender-enable')
            # Another version's state holds nothing here; the mode resolution refuses it.
            $null -eq (Resolve-AtlasInstallChoices -StatePath $path -TargetVersion '0.7.0' -Mode Fresh).ResumedOptions | Should -BeTrue
        }

        It 'takes the request over a capture that hasn''t begun its steps' {
            $path = New-TestInstallStatePath
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices ChooseAgain | Out-Null
            Set-AtlasInstallOptions -StatePath $path -Options @('defender-disable') | Out-Null
            $resolved = Resolve-AtlasInstallChoices -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Requested Keep
            $resolved.Choices | Should -BeExactly 'Keep'
            $resolved.Note | Should -BeNullOrEmpty
            $null -eq $resolved.ResumedOptions | Should -BeTrue -Because 'a capture that starts again records the options afresh'
        }
    }
}

Describe 'Atlas.InstallState step execution' {
    It 'runs a Once step once and reports the resumed skip' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path -Status Running | Out-Null
        $script:calls = 0

        $first = Invoke-AtlasInstallStep -StatePath $path -Name 'Install/Browser' -Mode Once `
            -Action { $script:calls++ }
        $second = Invoke-AtlasInstallStep -StatePath $path -Name 'Install/Browser' -Mode Once `
            -Action { $script:calls++ }

        $script:calls | Should -Be 1
        $first.Skipped | Should -BeFalse
        $second.Skipped | Should -BeTrue
        (Get-AtlasInstallState -StatePath $path).completedSteps | Should -Contain 'Install/Browser'
    }

    It 'reruns an Always step but keeps one completion marker' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path -Status Running | Out-Null
        $script:calls = 0

        1..2 | ForEach-Object {
            Invoke-AtlasInstallStep -StatePath $path -Name 'Refresh/Shell' -Mode Always `
                -Action { $script:calls++ } | Out-Null
        }

        $state = Get-AtlasInstallState -StatePath $path
        $script:calls | Should -Be 2
        @($state.completedSteps | Where-Object { $_ -eq 'Refresh/Shell' }).Count | Should -Be 1
    }

    It 'persists failure without completing the step and rethrows it' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path -Status Running | Out-Null

        {
            Invoke-AtlasInstallStep -StatePath $path -Name 'Install/Failing' `
                -Action { throw 'installer failed' }
        } | Should -Throw -ExpectedMessage '*installer failed*'

        $state = Get-AtlasInstallState -StatePath $path
        $state.completedSteps | Should -Not -Contain 'Install/Failing'
        $state.lastError | Should -BeExactly 'installer failed'
    }

    It 'rethrows the action failure when the state changes mid-step' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path -Status Running | Out-Null

        $action = {
            [IO.File]::Delete($path)
            if ([IO.File]::Exists("$path.bak")) {
                [IO.File]::Delete("$path.bak")
            }
            throw 'installer failed'
        }.GetNewClosure()

        {
            Invoke-AtlasInstallStep -StatePath $path -Name 'Install/Vanishing' `
                -Action $action -WarningAction SilentlyContinue
        } | Should -Throw -ExpectedMessage '*installer failed*'
    }

    It 'requires a committed state before running steps' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null

        {
            Invoke-AtlasInstallStep -StatePath $path -Name 'TooEarly' -Action { }
        } | Should -Throw -ExpectedMessage '*Capturing*'
    }
}

Describe 'Atlas.InstallState persistence' {
    It 'recovers a valid backup when the active document is malformed' {
        $path = New-TestInstallStatePath
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'browser-brave' | Out-Null
        [IO.File]::WriteAllText($path, '{broken')

        $recovered = Get-AtlasInstallState -StatePath $path
        $recovered.status | Should -BeExactly 'Capturing'
        { [IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw
    }

    It 'archives completed diagnostics and removes active work only after required steps' {
        # Mirror the Windows layout so the default state document path is checked too.
        $root = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString('N'))
        $path = Join-Path -Path $root -ChildPath 'AtlasOS\Install\active.json'
        $documentPath = Join-Path -Path $root -ChildPath 'AtlasOS\state.json'
        $flagsPath = Join-Path (Split-Path $path -Parent) 'published-flags'
        Start-TestInstallState -Path $path | Out-Null
        Add-AtlasInstallOption -StatePath $path -Name 'install-toolbox' | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null
        Invoke-AtlasInstallStep -StatePath $path -Name 'Apply/Tweaks' -Action { } | Out-Null
        $workFile = Join-Path (Split-Path $path -Parent) 'work\partial.txt'
        [IO.File]::WriteAllText($workFile, 'partial')
        [void][IO.Directory]::CreateDirectory($flagsPath)
        [IO.File]::WriteAllText((Join-Path $flagsPath 'stale.flag'), '')

        {
            Complete-AtlasInstallState -StatePath $path `
                -RequiredSteps @('Apply/Tweaks', 'Apply/Software') -FlagsPath $flagsPath
        } | Should -Throw -ExpectedMessage '*Apply/Software*'
        Test-Path -LiteralPath $path | Should -BeTrue
        Test-Path -LiteralPath $documentPath | Should -BeFalse

        $completed = Complete-AtlasInstallState -StatePath $path `
            -RequiredSteps 'Apply/Tweaks' -FlagsPath $flagsPath
        $document = Get-AtlasState -Path $documentPath
        $document.installedVersion | Should -BeExactly '0.6.0'
        $document.mode | Should -BeExactly 'Fresh'
        $document.isInteractive | Should -BeTrue
        @($document.options) | Should -Be @('install-toolbox')
        @($document.history) | Should -HaveCount 1
        $document.history[0].transactionId | Should -BeExactly $completed.transactionId
        Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) 'state.json') | Should -BeFalse
        $lastPath = Join-Path (Split-Path $path -Parent) 'last.json'
        $archived = [IO.File]::ReadAllText($lastPath) | ConvertFrom-Json
        $completed.status | Should -BeExactly 'Completed'
        $archived.status | Should -BeExactly 'Completed'
        $archived.transactionId | Should -BeExactly $completed.transactionId
        Test-Path -LiteralPath $path | Should -BeFalse
        Test-Path -LiteralPath "$path.bak" | Should -BeFalse
        Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) 'work') | Should -BeFalse
        @([IO.Directory]::GetFiles($flagsPath) | ForEach-Object { [IO.Path]::GetFileName($_) } |
                Sort-Object) | Should -Be @('Interactive.flag', 'option-install-toolbox.flag')
        $archived.PSObject.Properties['recordedOptions'] | Should -BeNullOrEmpty -Because 'without a reading of the PC the request is recorded, as before'
        $document.history[0].PSObject.Properties['notApplied'] | Should -BeNullOrEmpty -Because 'nothing read says what took effect'
    }

    It 'records what the PC has, keeping the request and the path beside it in last.json' {
        $root = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString('N'))
        $path = Join-Path -Path $root -ChildPath 'AtlasOS\Install\active.json'
        $documentPath = Join-Path -Path $root -ChildPath 'AtlasOS\state.json'
        $flagsPath = Join-Path (Split-Path $path -Parent) 'published-flags'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply -Choices ChooseAgain | Out-Null
        Set-AtlasInstallOptions -StatePath $path -Options @('defender-enable', 'uninstall-edge') | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null

        $completed = Complete-AtlasInstallState -StatePath $path -FlagsPath $flagsPath `
            -RecordedOptions @('defender-disable') -NotApplied @('defender-disable', 'defender-enable')

        @((Get-AtlasState -Path $documentPath).options) | Should -Be @('defender-disable')
        # This install's own entry says what it tried and didn't get, for Atlas Manager.
        @((Get-AtlasState -Path $documentPath).history[-1].notApplied) | Should -Be @('defender-disable', 'defender-enable')
        @([IO.Directory]::GetFiles($flagsPath) | ForEach-Object { [IO.Path]::GetFileName($_) } | Sort-Object) |
            Should -Be @('Interactive.flag', 'option-defender-disable.flag')
        $archived = [IO.File]::ReadAllText((Join-Path (Split-Path $path -Parent) 'last.json')) | ConvertFrom-Json
        @($archived.options) | Should -Be @('defender-enable', 'uninstall-edge')
        @($archived.recordedOptions) | Should -Be @('defender-disable')
        $archived.choices | Should -BeExactly 'ChooseAgain'
        @($completed.recordedOptions) | Should -Be @('defender-disable')
    }

    It 'records no options when the PC shows none, and refuses an invalid one' {
        $root = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString('N'))
        $path = Join-Path -Path $root -ChildPath 'AtlasOS\Install\active.json'
        $flagsPath = Join-Path (Split-Path $path -Parent) 'published-flags'
        Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' -Mode Reapply | Out-Null
        Set-AtlasInstallOptions -StatePath $path -Options @('install-toolbox') | Out-Null
        Commit-AtlasInstallState -StatePath $path | Out-Null

        { Complete-AtlasInstallState -StatePath $path -FlagsPath $flagsPath -RecordedOptions @('not an option') } |
            Should -Throw '*Invalid option name*'
        { Complete-AtlasInstallState -StatePath $path -FlagsPath $flagsPath -RecordedOptions @() -NotApplied @('not an option') } |
            Should -Throw '*Invalid option name*'
        Test-Path -LiteralPath $path | Should -BeTrue
        Complete-AtlasInstallState -StatePath $path -FlagsPath $flagsPath -RecordedOptions @() -NotApplied @() | Out-Null
        @((Get-AtlasState -Path (Join-Path $root 'AtlasOS\state.json')).options) | Should -HaveCount 0
        $entry = (Get-AtlasState -Path (Join-Path $root 'AtlasOS\state.json')).history[-1]
        $entry.PSObject.Properties['notApplied'] | Should -Not -BeNullOrEmpty -Because 'read, with nothing it tried missing'
        @($entry.notApplied) | Should -HaveCount 0
        @([IO.Directory]::GetFiles($flagsPath) | ForEach-Object { [IO.Path]::GetFileName($_) }) | Should -Be @('Interactive.flag')
    }
}

Describe 'Atlas.InstallState choices taken from the PC' {
    BeforeAll {
        # What Get-AtlasTransitionMachineFact gives, as an object: nothing shows
        # except what a case sets.
        function New-TestFact {
            param([hashtable]$Set = @{})
            $facts = [ordered]@{
                State = $null; LegacyVersions = @(); Toggles = @(); Browser = $null; AtlasModules = $true
                Edge = $null; OneDrive = $false; Defender = $null; DefenderPackage = $null; Appx = @()
                Toolbox = $null; CoreIsolationOff = $null; Browsers = $null; LanguageHotkey = $null; KeyboardLayouts = $null
            }
            foreach ($name in $Set.Keys) { $facts[$name] = $Set[$name] }
            return [pscustomobject]$facts
        }
        function New-TestToggle {
            param([string]$Name, [int]$State)
            [pscustomobject]@{ name = $Name; state = $State }
        }
        $script:NoDefenderPackage = 'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0'
        # The PC of the report that led to this: an update that never took Defender
        # back, and records that disagree with the options.
        $script:ReportFacts = @{
            DefenderPackage = 'Installed'; Defender = $false; Edge = $true; Toolbox = $true; CoreIsolationOff = $true
            Toggles = @((New-TestToggle AutomaticUpdates 1), (New-TestToggle Mitigations 2), (New-TestToggle VbsState 0), (New-TestToggle PowerSaving 0))
        }
        $script:ReportRequest = @('auto-updates-disable', 'defender-enable', 'disable-power-saving', 'install-toolbox', 'keyboard-single', 'mitigations-disable', 'uninstall-edge')
    }

    Context 'Compare-AtlasInstallOption' {
        It 'names each choice whose options differ, by the name Atlas Manager gives it' {
            $changes = @(Compare-AtlasInstallOption -Requested @('defender-enable', 'uninstall-edge', 'install-another-browser', 'browser-brave', 'install-eclean') `
                    -Recorded @('defender-disable', 'install-another-browser', 'browser-firefox', 'install-eclean'))
            @($changes.Group) | Should -Be @('defender', 'edge', 'browser')
            @($changes.Label) | Should -Be @('Microsoft Defender', 'Remove Microsoft Edge', 'Browser')
            @($changes[0].Requested) | Should -Be @('defender-enable')
            @($changes[0].Options) | Should -Be @('defender-disable')
            @($changes[1].Options) | Should -HaveCount 0
            @($changes[2].Options) | Should -Be @('browser-firefox', 'install-another-browser')
        }

        It 'finds nothing when only the order differs' {
            @(Compare-AtlasInstallOption -Requested @('keyboard-single', 'defender-enable') -Recorded @('defender-enable', 'keyboard-single')) |
                Should -HaveCount 0
        }
    }

    Context 'Resolve-AtlasKeptOption at Capture' {
        BeforeEach {
            $script:Facts = New-TestFact $script:ReportFacts
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { $script:Facts }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { $script:NoDefenderPackage }
        }

        It 'keeps what the PC shows, from machine evidence only, and says why for each choice' {
            $kept = Resolve-AtlasKeptOption -Requested $script:ReportRequest

            @($kept.Options | Sort-Object) | Should -Be @('auto-updates-default', 'defender-disable', 'disable-core-isolation',
                'disable-power-saving', 'install-toolbox', 'keyboard-single', 'mitigations-default')
            # No user is bound and the time is short, so no account's settings or apps are read.
            Should -Invoke Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState -Times 1 -Exactly -ParameterFilter { $MachineOnly -and -not $UserSid }
            @($kept.Warnings) | Should -HaveCount 0
            @($kept.Changes.Message) | Should -Be @(
                "Kept 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable': Atlas's NoDefender package is installed. Run again with -ChooseAgain to change it."
                "Kept 'mitigations-default' for Processor protections instead of the requested 'mitigations-disable': the Mitigations toggle records state 2. Run again with -ChooseAgain to change it."
                "Kept 'auto-updates-default' for Windows Update instead of the requested 'auto-updates-disable': the AutomaticUpdates toggle records state 1. Run again with -ChooseAgain to change it."
                "Left out the requested 'uninstall-edge' for Remove Microsoft Edge: Microsoft Edge is installed. Run again with -ChooseAgain to change it."
                "Kept 'disable-core-isolation' for Turn off virtualisation-based security (VBS), which the request left out: VBS is off. Run again with -ChooseAgain to change it."
            )
        }

        It 'reads the PC as it is before the install: <Case>' -TestCases @(
            @{ Case = 'Defender removed only at the restart, and no Toolbox yet'; Package = 'InstallPending'; Requested = @('defender-enable', 'install-toolbox') }
            @{ Case = 'Defender back only at the restart'; Package = 'UninstallPending'; Requested = @('defender-disable') }
        ) {
            param($Case, $Package, $Requested)
            # A pending package only counts once the install has run, and a Toolbox
            # that isn't there yet is one this install puts on.
            $script:Facts = New-TestFact @{ DefenderPackage = $Package; Defender = $false; Toolbox = $false }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { @() }
            $kept = Resolve-AtlasKeptOption -Requested $Requested
            @($kept.Options) | Should -Be $Requested -Because $Case
            @($kept.Changes) | Should -HaveCount 0
        }

        It 'keeps the request for Snipping Tool, the language hotkey and eclean' {
            $script:Facts = New-TestFact @{ Toggles = @() }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { @() }
            $requested = @('keyboard-single', 'remove-snipping-tool', 'install-eclean')
            $kept = Resolve-AtlasKeptOption -Requested $requested
            @($kept.Options) | Should -Be $requested
            @($kept.Changes) | Should -HaveCount 0
        }

        It 'keeps the request, with a warning, when the PC can''t be read' {
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { throw 'registry access denied' }
            $kept = Resolve-AtlasKeptOption -Requested $script:ReportRequest
            @($kept.Options) | Should -Be $script:ReportRequest
            @($kept.Changes) | Should -HaveCount 0
            @($kept.Warnings) | Should -Be @("Couldn't read what this PC shows, so the requested choices are kept: registry access denied")
        }
    }

    Context 'Get-AtlasRecordedOption at completion' {
        BeforeEach {
            $script:Facts = New-TestFact ($script:ReportFacts + @{ Appx = @('Microsoft.WindowsCalculator_8wekyb3d8bbwe'); KeyboardLayouts = 2; LanguageHotkey = '3' })
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { $script:Facts }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { $script:NoDefenderPackage }
            $script:State = [pscustomobject]@{ options = $script:ReportRequest; userSid = 'S-1-5-21-1-2-3-1001' }
        }

        It 'records what the PC has after the plan, read for the installing user with every account''s apps' {
            $recorded = Get-AtlasRecordedOption -State $script:State

            Should -Invoke Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState -Times 1 -Exactly -ParameterFilter { $UserSid -eq 'S-1-5-21-1-2-3-1001' -and -not $MachineOnly }
            @($recorded.Options) | Should -Contain 'defender-disable'
            @($recorded.Options) | Should -Contain 'remove-snipping-tool' -Because 'no account has Snipping Tool'
            @($recorded.Options) | Should -Not -Contain 'uninstall-edge'
            ($recorded.Changes | Where-Object Group -eq 'defender').Message |
                Should -BeExactly "Recorded 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable': Atlas's NoDefender package is installed."
            @($recorded.Warnings) | Should -HaveCount 0
        }

        It 'counts a Defender change Windows makes at the restart: <Package>' -TestCases @(
            @{ Package = 'InstallPending'; Requested = 'defender-enable'; Recorded = 'defender-disable'; Reason = "Atlas's NoDefender package goes on at the restart" }
            @{ Package = 'UninstallPending'; Requested = 'defender-disable'; Recorded = 'defender-enable'; Reason = "Atlas's NoDefender package comes off at the restart" }
        ) {
            param($Package, $Requested, $Recorded, $Reason)
            $script:Facts = New-TestFact @{ DefenderPackage = $Package; Defender = $false; Appx = @('Microsoft.ScreenSketch_8wekyb3d8bbwe') }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { @() }
            $result = Get-AtlasRecordedOption -State ([pscustomobject]@{ options = @($Requested); userSid = 'S-1-5-21-1-2-3-1001' })
            @($result.Options) | Should -Be @($Recorded)
            $result.Changes[0].Reason | Should -BeExactly $Reason
        }

        It 'records the request for the keyboard and Snipping Tool, with a warning, when the user''s reading fails' {
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { throw 'hive unloaded' } -ParameterFilter { -not $MachineOnly }
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { New-TestFact @{ DefenderPackage = 'Installed' } } -ParameterFilter { $MachineOnly }
            $recorded = Get-AtlasRecordedOption -State ([pscustomobject]@{ options = @('defender-enable', 'keyboard-single', 'remove-snipping-tool'); userSid = 'S-1-5-21-1-2-3-1001' })
            @($recorded.Options | Sort-Object) | Should -Be @('defender-disable', 'keyboard-single', 'remove-snipping-tool')
            @($recorded.Warnings) | Should -Be @("Couldn't read what this PC shows for Keyboard languages and Remove Snipping Tool, so the requested choices are recorded: hive unloaded")
        }

        It 'records the request, with a warning, when the PC can''t be read at all' {
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { throw 'registry access denied' }
            $recorded = Get-AtlasRecordedOption -State $script:State
            @($recorded.Options) | Should -Be $script:ReportRequest
            @($recorded.Warnings) | Should -Be @("Couldn't read what this PC shows, so the requested choices are recorded: registry access denied")
        }

        It 'warns that Snipping Tool keeps the request when the apps couldn''t be listed' {
            $script:Facts = New-TestFact @{ Appx = @() }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { @() }
            $recorded = Get-AtlasRecordedOption -State ([pscustomobject]@{ options = @('remove-snipping-tool'); userSid = 'S-1-5-21-1-2-3-1001' })
            @($recorded.Options) | Should -Be @('remove-snipping-tool')
            @($recorded.Warnings) | Should -Be @("Couldn't list this PC's apps, so the requested choice is recorded for Remove Snipping Tool.")
        }

        It 'reads no keyboard settings for an install without a user' {
            $script:Facts = New-TestFact @{ LanguageHotkey = '1'; KeyboardLayouts = 1; Appx = @('Microsoft.ScreenSketch_8wekyb3d8bbwe') }
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { @() }
            $recorded = Get-AtlasRecordedOption -State ([pscustomobject]@{ options = @('keyboard-single'); userSid = $null })
            @($recorded.Options) | Should -Be @('keyboard-single') -Because "this process's own hotkey is nobody's choice"
        }

        It 'names as not applied only what the plan tried and the PC doesn''t have: <Case>' -TestCases @(
            @{ Case = 'a first installation leaves VBS already off with the box clear'; Mode = 'Fresh'; Choices = 'Keep'
                Requested = @('defender-enable', 'keyboard-single'); Shows = @{ CoreIsolationOff = $true }; NotApplied = @()
            }
            @{ Case = 'a first installation finds Edge already gone with the box clear'; Mode = 'Fresh'; Choices = 'Keep'
                Requested = @('defender-enable'); Shows = @{ Edge = $false }; NotApplied = @()
            }
            @{ Case = 'keeping the choices leaves Snipping Tool on another account'; Mode = 'Upgrade'; Choices = 'Keep'
                Requested = @('defender-enable', 'remove-snipping-tool'); Shows = @{}; NotApplied = @()
            }
            @{ Case = 'choosing again finds Edge gone with the box clear, which no update puts back'; Mode = 'Reapply'; Choices = 'ChooseAgain'
                Requested = @('defender-enable'); Shows = @{ Edge = $false }; NotApplied = @()
            }
            @{ Case = 'keeping the choices puts back no Toolbox'; Mode = 'Upgrade'; Choices = 'Keep'
                Requested = @('defender-enable', 'install-toolbox'); Shows = @{ Toolbox = $false }; NotApplied = @('install-toolbox')
            }
            @{ Case = 'choosing again to turn VBS off, which a policy keeps on'; Mode = 'Reapply'; Choices = 'ChooseAgain'
                Requested = @('defender-enable', 'disable-core-isolation'); Shows = @{ CoreIsolationOff = $false }; NotApplied = @('disable-core-isolation')
            }
            @{ Case = 'choosing again to turn VBS back on, which a policy keeps off'; Mode = 'Upgrade'; Choices = 'ChooseAgain'
                Requested = @('defender-enable'); Shows = @{ CoreIsolationOff = $true }; NotApplied = @('disable-core-isolation')
            }
            @{ Case = 'a first installation leaves Snipping Tool installed for an account'; Mode = 'Fresh'; Choices = 'Keep'
                Requested = @('defender-enable', 'remove-snipping-tool'); Shows = @{}; NotApplied = @('remove-snipping-tool')
            }
            @{ Case = 'a Rebase couldn''t take the NoDefender package off'; Mode = 'Rebase'; Choices = 'Keep'
                Requested = @('defender-enable'); Shows = @{ DefenderPackage = 'Installed'; Defender = $false }; NotApplied = @('defender-disable', 'defender-enable')
            }
            @{ Case = 'a first installation couldn''t install the browser'; Mode = 'Fresh'; Choices = 'Keep'
                Requested = @('defender-enable', 'install-another-browser', 'browser-brave'); Shows = @{ Browsers = @() }; NotApplied = @('browser-brave', 'install-another-browser')
            }
        ) {
            param($Case, $Mode, $Choices, $Requested, $Shows, $NotApplied)
            # Defender there and Snipping Tool installed, unless a case says otherwise.
            $read = @{ Defender = $true; Appx = @('Microsoft.ScreenSketch_8wekyb3d8bbwe', 'Microsoft.WindowsCalculator_8wekyb3d8bbwe') }
            foreach ($name in $Shows.Keys) { $read[$name] = $Shows[$name] }
            $script:Facts = New-TestFact $read
            Mock Get-AtlasInstalledAtlasPackage -ModuleName Atlas.InstallState { @() }
            $recorded = Get-AtlasRecordedOption -State ([pscustomobject]@{
                    options = $Requested; userSid = 'S-1-5-21-1-2-3-1001'; mode = $Mode; choices = $Choices
                })
            @($recorded.Changes).Count | Should -BeGreaterThan 0 -Because "the record differs from the request: $Case"
            @($recorded.NotApplied) | Should -Be @($NotApplied) -Because $Case
        }

        It 'says nothing of what took effect when the PC can''t be read' {
            Mock Get-AtlasTransitionMachineFact -ModuleName Atlas.InstallState { throw 'registry access denied' }
            $null -eq (Get-AtlasRecordedOption -State $script:State).NotApplied | Should -BeTrue -Because 'none read is not none missing'
        }
    }
}

Describe 'Atlas.InstallState Toolbox record migration' {
    BeforeEach {
        $script:TestRoot = "HKCU:\Software\AtlasRewriteTest\ToolboxRecords-$([Guid]::NewGuid().ToString('N'))"
        $script:StateRoot = "$script:TestRoot\Services"
        $script:ClassesRoot = "$script:TestRoot\Classes"
        $script:ServicesRoot = "$script:TestRoot\SystemServices"
        $script:PowerSchemesRoot = "$script:TestRoot\PowerSchemes"
        New-Item -Path $script:StateRoot, $script:ClassesRoot, $script:ServicesRoot -Force | Out-Null
        $script:Migrate = @{ InstalledVersion = '0.5.0'; StateRoot = $script:StateRoot; ClassesRoot = $script:ClassesRoot; ServicesRoot = $script:ServicesRoot; PowerSchemesRoot = $script:PowerSchemesRoot }
        Mock Get-AtlasLoadedUserDword -ModuleName Atlas.InstallState { $null }
        Mock Get-AtlasBcdHighestMode -ModuleName Atlas.InstallState { $null }

        function New-TestRecord {
            param([string]$Name, [AllowNull()]$State, [string]$Launcher)
            $key = New-Item -Path "$script:StateRoot\$Name" -Force
            if ($null -ne $State) { New-ItemProperty -LiteralPath $key.PSPath -Name state -Value ([int]$State) -PropertyType DWord | Out-Null }
            if ($Launcher) { New-ItemProperty -LiteralPath $key.PSPath -Name path -Value "C:\Windows\AtlasDesktop\x\$Launcher" -PropertyType String | Out-Null }
        }
        function Get-TestRecord {
            param([string]$Name)
            $key = Get-ChildItem -LiteralPath $script:StateRoot | Where-Object PSChildName -ieq $Name
            if ($null -eq $key) { return $null }
            [pscustomobject]@{ Name = $key.PSChildName; State = $key.GetValue('state', $null) }
        }
        function Set-TestServiceStart {
            param([string]$Name, [int]$Start)
            $key = New-Item -Path "$script:ServicesRoot\$Name" -Force
            New-ItemProperty -LiteralPath $key.PSPath -Name Start -Value $Start -PropertyType DWord -Force | Out-Null
        }
    }

    AfterEach {
        Remove-Item -LiteralPath $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'repairs the stale power record before replay on Atlas <Version>, keeping rollback metadata' -TestCases @(
        @{ Version = '0.5.0' }, @{ Version = '0.6.0' }
    ) {
        param($Version)
        New-TestRecord PowerSaving 1
        New-ItemProperty -LiteralPath "$script:StateRoot\PowerSaving" -Name PreviousPowerSchemeGuid -Value '381b4222-f694-41f0-9685-ff5bb260df2e' | Out-Null
        New-Item -Path $script:PowerSchemesRoot -Force | Out-Null
        New-ItemProperty -LiteralPath $script:PowerSchemesRoot -Name ActivePowerScheme -Value '11111111-1111-1111-1111-111111111111' | Out-Null
        $migrate = $script:Migrate.Clone(); $migrate.InstalledVersion = $Version
        @(Repair-AtlasToolboxRecord @migrate) | Should -Contain "Set the 'PowerSaving' record to 0: the Atlas power plan is active."
        (Get-TestRecord PowerSaving).State | Should -Be 0
        (Get-ItemProperty -LiteralPath "$script:StateRoot\PowerSaving").PreviousPowerSchemeGuid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
        @(Repair-AtlasToolboxRecord @migrate) | Should -HaveCount 0
    }

    It 'uses the same power-plan evidence as Manager and the transition: <name>' -ForEach @(
        (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\power-saving-records.json') -Raw | ConvertFrom-Json) |
            ForEach-Object { @{ name = $_.name; active = $_.active; record = $_.record; expected = $_.expected } }
    ) {
        if ($null -ne $record) { New-TestRecord PowerSaving $record }
        if ($null -ne $active) {
            New-Item -Path $script:PowerSchemesRoot -Force | Out-Null
            New-ItemProperty -LiteralPath $script:PowerSchemesRoot -Name ActivePowerScheme -Value $active | Out-Null
        }
        $migrate = $script:Migrate.Clone(); $migrate.InstalledVersion = '0.6.0'
        Repair-AtlasToolboxRecord @migrate | Out-Null
        $result = Get-TestRecord PowerSaving
        if ($null -eq $expected) { $result | Should -BeNullOrEmpty }
        else { $result.State | Should -Be $expected }
    }

    It 'changes nothing on an update from Atlas <Version>' -TestCases @(
        @{ Version = '0.6.0' }, @{ Version = '0.6.1-rc1' }, @{ Version = '1.0.0' }, @{ Version = '' }
    ) {
        param($Version)
        New-TestRecord Mitigations 2
        $migrate = $script:Migrate.Clone(); $migrate.InstalledVersion = $Version
        @(Repair-AtlasToolboxRecord @migrate) | Should -HaveCount 0
        (Get-TestRecord Mitigations).State | Should -Be 2
    }

    It 'drops a Mitigations or ShortcutIcon record only the Toolbox wrote, and never translates it' -TestCases @(
        @{ Name = 'Mitigations'; State = 2 }, @{ Name = 'Mitigations'; State = 1 }, @{ Name = 'ShortcutIcon'; State = 0 }
    ) {
        param($Name, $State)
        New-TestRecord $Name $State
        $lines = @(Repair-AtlasToolboxRecord @script:Migrate)
        Get-TestRecord $Name | Should -BeNullOrEmpty
        $lines | Should -Be @("Removed the '$Name' record (state $State): only the old Atlas Toolbox wrote it, and its choices never reached this PC.")
    }

    It 'sets <Name> from the launcher that applied it: <Launcher>' -TestCases @(
        @{ Name = 'Mitigations'; State = 2; Launcher = 'Set Windows Default Mitigations.cmd'; Expected = 1 }
        @{ Name = 'Mitigations'; State = 1; Launcher = 'Enable All Mitigations.cmd'; Expected = 2 }
        @{ Name = 'Mitigations'; State = 2; Launcher = 'Disable All Mitigations.cmd'; Expected = 0 }
        @{ Name = 'ShortcutIcon'; State = 0; Launcher = 'Classic.cmd'; Expected = 1 }
        @{ Name = 'ShortcutIcon'; State = 0; Launcher = 'None (security risk).cmd'; Expected = 2 }
    ) {
        param($Name, $State, $Launcher, $Expected)
        New-TestRecord $Name $State $Launcher
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -Be @("Set the '$Name' record from $State to $Expected, the choice its launcher '$Launcher' applied.")
        (Get-TestRecord $Name).State | Should -Be $Expected
        (Get-Item -LiteralPath "$script:StateRoot\$Name").GetValue('path') | Should -BeLike "*\$Launcher" -Because 'the legacy choices step still reads it'
    }

    It 'leaves a record whose launcher already matches, or that it can''t tell' {
        New-TestRecord Mitigations 0 'Disable All Mitigations.cmd'
        New-TestRecord ShortcutIcon 1 'Some Other Launcher.cmd'
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -HaveCount 0
        (Get-TestRecord Mitigations).State | Should -Be 0
        (Get-TestRecord ShortcutIcon).State | Should -Be 1
    }

    It 'gives a Toolbox terminal menu record the menu this PC has: <Case>' -TestCases @(
        @{ Case = 'no menu'; Menu = $null; Recorded = 2; Expected = 0 }
        @{ Case = 'with Windows Terminal'; Menu = 'shell\Item1'; Recorded = 0; Expected = 1 }
        @{ Case = 'without Windows Terminal'; Menu = 'shell\Item0'; Recorded = 0; Expected = 2 }
    ) {
        param($Case, $Menu, $Recorded, $Expected)
        if ($Menu) { New-Item -Path "$script:ClassesRoot\Directory\shell\AtlasTerminals\$Menu" -Force | Out-Null }
        New-TestRecord ContextMenuTerminals $Recorded
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -HaveCount 1
        (Get-TestRecord ContextMenuTerminals).State | Should -Be $Expected -Because $Case
    }

    It 'drops a Toolbox terminal menu record when the menu this PC has can''t be read' {
        $menu = "$script:ClassesRoot\Directory\shell\AtlasTerminals"
        New-Item -Path "$menu\shell\Item1" -Force | Out-Null
        New-TestRecord ContextMenuTerminals 0
        # Test-Path still finds a key its reader can't open.
        $rights = [Security.AccessControl.RegistryRights]::ChangePermissions -bor [Security.AccessControl.RegistryRights]::ReadPermissions
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($menu.Substring('HKCU:\'.Length), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, $rights)
        $deny = New-Object Security.AccessControl.RegistryAccessRule(
            [Security.Principal.WindowsIdentity]::GetCurrent().User, [Security.AccessControl.RegistryRights]'QueryValues, EnumerateSubKeys', 'Deny')
        try {
            $acl = $key.GetAccessControl()
            $acl.AddAccessRule($deny)
            $key.SetAccessControl($acl)
            Test-Path -LiteralPath $menu | Should -BeTrue

            $lines = @(Repair-AtlasToolboxRecord @script:Migrate)
        }
        finally {
            $acl = $key.GetAccessControl()
            [void]$acl.RemoveAccessRule($deny)
            $key.SetAccessControl($acl)
            $key.Dispose()
        }
        Get-TestRecord ContextMenuTerminals | Should -BeNullOrEmpty
        $lines | Should -Be @("Removed the 'ContextMenuTerminals' record (state 0): only the old Atlas Toolbox wrote it, in its own numbering, and the terminal menu this PC has couldn't be read.")
    }

    It 'leaves a terminal menu record with a launcher path to the legacy choices step' {
        New-TestRecord ContextMenuTerminals 2 'Add Terminals.cmd'
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -HaveCount 0
        (Get-TestRecord ContextMenuTerminals).State | Should -Be 2
    }

    It 'drops the Toolbox''s Enable File Sharing record and keeps every other' {
        New-TestRecord FileSharing 0 'Enable File Sharing.cmd'
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -HaveCount 1
        Get-TestRecord FileSharing | Should -BeNullOrEmpty

        New-TestRecord FileSharing 0 'Disable File Sharing (default).cmd'
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -HaveCount 0
        (Get-TestRecord FileSharing).State | Should -Be 0
    }

    It 'keeps a Printing 0 only when the Print Spooler is off: Start <Start>' -TestCases @(
        @{ Start = 4; Kept = $true }, @{ Start = 2; Kept = $false }, @{ Start = $null; Kept = $false }
    ) {
        param($Start, $Kept)
        if ($null -ne $Start) { Set-TestServiceStart Spooler $Start }
        New-TestRecord Printing 0 'Disable Printing.cmd'
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        $null -ne (Get-TestRecord Printing) | Should -Be $Kept
    }

    It 'turns the Toolbox''s search indexing into Indexing only when the search service is off' {
        New-TestRecord Indexing 1 'Minimal Indexing.cmd'
        New-TestRecord SearchIndexing 1
        Set-TestServiceStart WSearch 2
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        (Get-TestRecord Indexing).State | Should -Be 1
        Get-TestRecord SearchIndexing | Should -BeNullOrEmpty

        New-TestRecord SearchIndexing 1
        Set-TestServiceStart WSearch 4
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        (Get-TestRecord Indexing).State | Should -Be 0
        Get-TestRecord SearchIndexing | Should -BeNullOrEmpty
    }

    It 'moves <From> to <To>, taking what the PC shows when both disagree' -TestCases @(
        @{ From = 'AppIconsThumbnail'; To = 'AppIconThumbnail'; Live = 'Get-AtlasLoadedUserDword' }
        @{ From = 'HightestMode'; To = 'HighestMode'; Live = 'Get-AtlasBcdHighestMode' }
    ) {
        param($From, $To, $Live)
        New-TestRecord $From 0
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        (Get-TestRecord $To).State | Should -Be 0 -Because 'nothing else was recorded'
        Get-TestRecord $From | Should -BeNullOrEmpty

        New-TestRecord $From 1
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        (Get-TestRecord $To).State | Should -Be 0 -Because 'with no reading of the PC the Atlas record stays'

        New-TestRecord $From 1
        Mock $Live -ModuleName Atlas.InstallState { 1 }
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        (Get-TestRecord $To).State | Should -Be 1
        Get-TestRecord $From | Should -BeNullOrEmpty
    }

    It 'gives a Recall record named in other letter case its exact name' {
        New-TestRecord recall 0
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -Be @("Renamed the old Atlas Toolbox's 'recall' record to 'Recall'.")
        $record = Get-TestRecord Recall
        $record.Name | Should -BeExactly 'Recall'
        $record.State | Should -Be 0
    }

    It 'replaces the Toolbox''s CPU Idle menu with a record for Atlas''s, and drops its record' {
        $menu = New-Item -Path "$script:ClassesRoot\DesktopBackground\Shell\Idle\Shell\Disable Idle" -Force
        New-ItemProperty -LiteralPath "$script:ClassesRoot\DesktopBackground\Shell\Idle" -Name MUIVerb -Value 'CPU Idle' | Out-Null
        $null = $menu
        New-TestRecord CPUIdleContextMenu 1 'Remove Idle Toggle in Desktop Context Menu (default).cmd'

        Repair-AtlasToolboxRecord @script:Migrate | Out-Null

        Test-Path -LiteralPath "$script:ClassesRoot\DesktopBackground\Shell\Idle" | Should -BeFalse
        $record = Get-TestRecord CpuIdleContextMenu
        $record.Name | Should -BeExactly 'CpuIdleContextMenu'
        $record.State | Should -Be 1
    }

    It 'drops a Toolbox CPU Idle record when the Toolbox''s menu is gone, and leaves another menu alone' {
        New-Item -Path "$script:ClassesRoot\DesktopBackground\Shell\Idle" -Force | Out-Null
        New-ItemProperty -LiteralPath "$script:ClassesRoot\DesktopBackground\Shell\Idle" -Name MUIVerb -Value 'Someone else''s menu' | Out-Null
        New-TestRecord CPUIdleContextMenu 0
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        Get-TestRecord CpuIdleContextMenu | Should -BeNullOrEmpty
        Test-Path -LiteralPath "$script:ClassesRoot\DesktopBackground\Shell\Idle" | Should -BeTrue
    }

    # toolbox-records.json, which Atlas Manager's tests and the record of a Windows
    # move read too. Each case is one record, by its key, state and launcher path,
    # on an update from the version given; its result is the record left, or null
    # when none is. Rules that read the PC as well have cases of their own above.
    It 'leaves each shared record as Atlas Manager reads it: <name>' -ForEach @(
        (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures\windows-transition\toolbox-records.json') -Raw | ConvertFrom-Json) |
            ForEach-Object { @{ name = $_.name; version = $_.version; record = $_.key; state = $_.state; path = $_.path; result = $_.result } }
    ) {
        $key = New-Item -Path "$script:StateRoot\$record" -Force
        New-ItemProperty -LiteralPath $key.PSPath -Name state -Value ([int]$state) -PropertyType DWord | Out-Null
        if ($null -ne $path) { New-ItemProperty -LiteralPath $key.PSPath -Name path -Value $path -PropertyType String | Out-Null }
        $migrate = $script:Migrate.Clone(); $migrate.InstalledVersion = $version

        Repair-AtlasToolboxRecord @migrate | Out-Null

        $left = @(Get-ChildItem -LiteralPath $script:StateRoot | Where-Object { @($_.GetValueNames()) -contains 'state' } |
                ForEach-Object { "$($_.PSChildName)=$($_.GetValue('state'))" })
        if ($null -eq $result) { $left | Should -BeNullOrEmpty -Because $name }
        else { ($left -join ',') | Should -BeExactly "$($result.key)=$($result.state)" -Because $name }
    }

    It 'changes nothing the second time, so a capture that starts again is safe' {
        New-TestRecord Mitigations 2
        New-TestRecord ShortcutIcon 0 'Classic.cmd'
        New-TestRecord ContextMenuTerminals 0
        New-TestRecord recall 1
        New-TestRecord AppIconsThumbnail 1
        Repair-AtlasToolboxRecord @script:Migrate | Out-Null
        @(Repair-AtlasToolboxRecord @script:Migrate) | Should -HaveCount 0
        Get-TestRecord Mitigations | Should -BeNullOrEmpty
        (Get-TestRecord ShortcutIcon).State | Should -Be 1
        (Get-TestRecord ContextMenuTerminals).State | Should -Be 0
        (Get-TestRecord AppIconThumbnail).State | Should -Be 1
    }
}
