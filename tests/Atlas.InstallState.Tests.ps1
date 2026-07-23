BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    $script:installStateModulePath = Join-Path -Path $modulesRoot `
        -ChildPath 'Atlas.InstallState\Atlas.InstallState.psd1'
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

        {
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
                -Mode Reapply -CaptureNonce 'other'
        } | Should -Throw -ExpectedMessage '*does not match the requested Reapply mode*'

        {
            Start-AtlasInstallState -StatePath $path -TargetVersion '0.6.0' `
                -Mode Fresh -IsOobe $true -CaptureNonce 'other'
        } | Should -Throw -ExpectedMessage '*does not match the requested Fresh mode and OOBE scope*'
    }

    It 'resumes the original plan when AME reclassifies a recorded failed run' {
        $path = New-TestInstallStatePath
        $first = Start-TestInstallState -Path $path -Status Running
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
        @($retry.options).Count | Should -Be 0
        @($retry.completedSteps) | Should -Contain 'Features'
        Test-Path -LiteralPath (Join-Path $workRoot 'partial.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) 'abandoned.json') | Should -BeFalse
    }

    It 'recovers an older RC abandoned Fresh transaction on a Reapply retry' {
        $path = New-TestInstallStatePath
        $first = Start-TestInstallState -Path $path -Status Running
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
        Add-AtlasInstallOption -StatePath $path -Name 'install-toolbox' | Out-Null
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
        $path = New-TestInstallStatePath
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

        $completed = Complete-AtlasInstallState -StatePath $path `
            -RequiredSteps 'Apply/Tweaks' -FlagsPath $flagsPath
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
    }
}
