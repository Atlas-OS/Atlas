BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ScriptsRoot = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts'
    $script:PreviousInstallScript = Join-Path $script:ScriptsRoot `
        'Install\Tasks\Remove-PreviousAtlasInstall.ps1'
    $script:VersionSpecificScript = Join-Path $script:ScriptsRoot `
        'Tweaks\misc\delete-windows-specific-files.ps1'
    $script:TrustBootstrap = Join-Path $script:ScriptsRoot `
        'Initialize-AtlasPowerShell.ps1'
    $script:PowerShell51 = [IO.Path]::Combine(
        [Environment]::SystemDirectory,
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe'
    )

    # Both executors hard-code the live Windows directory. Rehost them against a
    # TestDrive root through an environment hook, and fail if that anchor drifts.
    $script:WindowsPathExpression = "[Environment]::GetFolderPath('Windows')"
    function ConvertTo-RehostedRemovalScript {
        param([Parameter(Mandatory = $true)][string]$Path)

        $source = [IO.File]::ReadAllText($Path)
        if (-not $source.Contains($script:WindowsPathExpression)) {
            throw "The removal script '$Path' no longer anchors on the Windows directory expression this harness rewrites."
        }
        return $source.Replace($script:WindowsPathExpression, '$env:ATLAS_TEST_WINDIR')
    }

    $harnessRoot = Join-Path $TestDrive 'Harness'
    # Remove-PreviousAtlasInstall.ps1 resolves the trust bootstrap two levels above
    # itself, so the harness mirrors the installed Install\Tasks layout.
    $null = New-Item -Path (Join-Path $harnessRoot 'Install\Tasks') -ItemType Directory -Force
    $script:RehostedPreviousInstall = Join-Path $harnessRoot `
        'Install\Tasks\Remove-PreviousAtlasInstall.ps1'
    [IO.File]::WriteAllText(
        $script:RehostedPreviousInstall,
        (ConvertTo-RehostedRemovalScript -Path $script:PreviousInstallScript)
    )
    Copy-Item -LiteralPath $script:TrustBootstrap `
        -Destination (Join-Path $harnessRoot 'Initialize-AtlasPowerShell.ps1')

    $script:VersionSpecificBlock = [scriptblock]::Create(
        (ConvertTo-RehostedRemovalScript -Path $script:VersionSpecificScript)
    )

    function Invoke-PreviousInstallRemoval {
        param([Parameter(Mandatory = $true)][string]$WindowsRoot)

        $env:ATLAS_TEST_WINDIR = $WindowsRoot
        $savedPreference = $ErrorActionPreference
        try {
            # Capture expected native failures under CI's Stop preference.
            $ErrorActionPreference = 'Continue'
            $output = & $script:PowerShell51 -NoProfile -NoLogo -NonInteractive `
                -ExecutionPolicy Bypass -File $script:RehostedPreviousInstall 2>&1
            return [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = ($output | Out-String)
            }
        }
        finally {
            $ErrorActionPreference = $savedPreference
            Remove-Item Env:\ATLAS_TEST_WINDIR -ErrorAction SilentlyContinue
        }
    }

    function New-UpgradeWindowsFixture {
        param([Parameter(Mandatory = $true)][string]$Name)

        $windowsRoot = Join-Path $TestDrive $Name
        foreach ($child in @(
                'AtlasDesktop\1. Software'
                'AtlasModules\Scripts'
                'UnrelatedComponent'
            )) {
            $null = New-Item -Path (Join-Path $windowsRoot $child) -ItemType Directory -Force
        }
        [IO.File]::WriteAllText((Join-Path $windowsRoot 'AtlasDesktop\1. Software\launcher.cmd'), 'x')
        [IO.File]::WriteAllText((Join-Path $windowsRoot 'AtlasModules\Scripts\helper.ps1'), 'x')
        [IO.File]::WriteAllText((Join-Path $windowsRoot 'UnrelatedComponent\keep.dat'), 'x')
        [IO.File]::WriteAllText((Join-Path $windowsRoot 'notepad.exe.txt'), 'x')
        return $windowsRoot
    }
}

Describe 'Previous-install file removal' {
    It 'preserves device service backups byte for byte while removing old code' {
        $windowsRoot = New-UpgradeWindowsFixture -Name 'WinDirBackups'
        $other = Join-Path $windowsRoot 'AtlasModules\Other'
        $null = New-Item -Path $other -ItemType Directory
        foreach ($name in @('winServices.reg', 'atlasServices.reg')) {
            [IO.File]::WriteAllText((Join-Path $other $name), "original $name")
        }
        [IO.File]::WriteAllText((Join-Path $other 'old-helper.cmd'), 'old code')

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        foreach ($name in @('winServices.reg', 'atlasServices.reg')) {
            [IO.File]::ReadAllText((Join-Path $other $name)) | Should -BeExactly "original $name"
        }
        Test-Path (Join-Path $other 'old-helper.cmd') | Should -BeFalse
        Test-Path (Join-Path $windowsRoot 'AtlasModules\Scripts') | Should -BeFalse
        Test-Path (Join-Path $windowsRoot 'AtlasDesktop') | Should -BeFalse
        Test-Path (Join-Path $windowsRoot 'UnrelatedComponent\keep.dat') | Should -BeTrue
    }

    It 'keeps the logs byte for byte on every update, with or without service backups: backups <Backups>' -TestCases @(
        @{ Backups = $false }, @{ Backups = $true }
    ) {
        param($Backups)
        $windowsRoot = New-UpgradeWindowsFixture -Name "WinDirLogs$Backups"
        $logs = Join-Path $windowsRoot 'AtlasModules\Logs'
        $null = New-Item -Path (Join-Path $logs 'install') -ItemType Directory -Force
        $bytes = [byte[]](0xEF, 0xBB, 0xBF, 0x5B, 0x30, 0x5D, 0x0D, 0x0A, 0x00, 0xFF)
        [IO.File]::WriteAllBytes((Join-Path $logs 'install\atlas-install.log'), $bytes)
        [IO.File]::WriteAllText((Join-Path $logs 'install\20261001-101500-Tweaks-qol-Admin.log'), 'an earlier install')
        if ($Backups) {
            $null = New-Item -Path (Join-Path $windowsRoot 'AtlasModules\Other') -ItemType Directory
            [IO.File]::WriteAllText((Join-Path $windowsRoot 'AtlasModules\Other\winServices.reg'), 'original')
            [IO.File]::WriteAllText((Join-Path $windowsRoot 'AtlasModules\Other\old-helper.cmd'), 'old code')
        }

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        [IO.File]::ReadAllBytes((Join-Path $logs 'install\atlas-install.log')) | Should -Be $bytes
        [IO.File]::ReadAllText((Join-Path $logs 'install\20261001-101500-Tweaks-qol-Admin.log')) | Should -BeExactly 'an earlier install'
        $expected = if ($Backups) { @('Logs', 'Other') } else { @('Logs') }
        @(Get-ChildItem -LiteralPath (Join-Path $windowsRoot 'AtlasModules') -Force | ForEach-Object Name | Sort-Object) |
            Should -Be $expected -Because 'old code still goes'
        if ($Backups) {
            Test-Path (Join-Path $windowsRoot 'AtlasModules\Other\winServices.reg') | Should -BeTrue
            Test-Path (Join-Path $windowsRoot 'AtlasModules\Other\old-helper.cmd') | Should -BeFalse
        }
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasDesktop') | Should -BeFalse
    }

    It 'refuses to keep the logs through a reparse point' {
        $windowsRoot = New-UpgradeWindowsFixture -Name 'WinDirLogsJunction'
        $elsewhere = Join-Path $TestDrive 'LogsElsewhere'
        $null = New-Item -Path $elsewhere -ItemType Directory -Force
        [IO.File]::WriteAllText((Join-Path $elsewhere 'keep.txt'), 'not Atlas''s')
        try {
            New-Item -Path (Join-Path $windowsRoot 'AtlasModules\Logs') -ItemType Junction -Value $elsewhere -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because 'this host cannot create junctions'
            return
        }

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'reparse point'
        Test-Path -LiteralPath (Join-Path $elsewhere 'keep.txt') | Should -BeTrue
    }

    It 'removes both Atlas folders and leaves every sibling intact' {
        $windowsRoot = New-UpgradeWindowsFixture -Name 'WinDirFull'

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasDesktop') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasModules') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $windowsRoot 'UnrelatedComponent\keep.dat') |
            Should -BeTrue
        Test-Path -LiteralPath (Join-Path $windowsRoot 'notepad.exe.txt') | Should -BeTrue
    }

    It 'succeeds when no previous Atlas files exist' {
        $windowsRoot = Join-Path $TestDrive 'WinDirClean'
        $null = New-Item -Path (Join-Path $windowsRoot 'UnrelatedComponent') `
            -ItemType Directory -Force

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        Test-Path -LiteralPath (Join-Path $windowsRoot 'UnrelatedComponent') | Should -BeTrue
    }

    It 'fails explicitly when an Atlas file cannot be deleted' {
        $windowsRoot = New-UpgradeWindowsFixture -Name 'WinDirLocked'
        $lockedPath = Join-Path $windowsRoot 'AtlasModules\Scripts\locked.dat'
        [IO.File]::WriteAllText($lockedPath, 'locked')
        $lock = [IO.File]::Open(
            $lockedPath,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )
        try {
            $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot
        }
        finally {
            $lock.Dispose()
        }

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'locked\.dat'
        Test-Path -LiteralPath $lockedPath | Should -BeTrue
    }

    It 'fails explicitly when the Windows directory is unavailable' {
        $result = Invoke-PreviousInstallRemoval `
            -WindowsRoot (Join-Path $TestDrive 'DoesNotExist')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'is not available'
    }
}

Describe 'Atlas file copy' {
    BeforeAll {
        # Copy-AtlasPayload.ps1 finds the staged files four levels above itself and
        # the trust bootstrap two levels above, so the harness mirrors that layout.
        $script:CopyScript = Join-Path $script:ScriptsRoot 'Install\Tasks\Copy-AtlasPayload.ps1'
        $script:Staged = Join-Path $TestDrive 'Staged\Executables'
        $tasks = Join-Path $script:Staged 'AtlasModules\Scripts\Install\Tasks'
        $null = New-Item -Path $tasks, (Join-Path $script:Staged 'AtlasDesktop\1. Software'), (Join-Path $script:Staged 'Themes'), (Join-Path $script:Staged 'AtlasModules\Logs') -ItemType Directory -Force
        [IO.File]::WriteAllText((Join-Path $tasks 'Copy-AtlasPayload.ps1'), (ConvertTo-RehostedRemovalScript -Path $script:CopyScript))
        Copy-Item -LiteralPath $script:TrustBootstrap -Destination (Join-Path $script:Staged 'AtlasModules\Scripts\Initialize-AtlasPowerShell.ps1')
        [IO.File]::WriteAllText((Join-Path $script:Staged 'AtlasModules\Logs\install-run.log'), 'the staged copy, still being written')
        [IO.File]::WriteAllText((Join-Path $script:Staged 'AtlasModules\Scripts\new.ps1'), 'new code')
        [IO.File]::WriteAllText((Join-Path $script:Staged 'AtlasDesktop\1. Software\launcher.cmd'), 'new launcher')
        [IO.File]::WriteAllText((Join-Path $script:Staged 'Themes\atlas.theme'), 'theme')
    }

    It 'copies Atlas''s new files without copying the staged logs over the machine''s' {
        $windowsRoot = Join-Path $TestDrive 'CopyWindows'
        $null = New-Item -Path (Join-Path $windowsRoot 'AtlasModules\Logs') -ItemType Directory -Force
        [IO.File]::WriteAllText((Join-Path $windowsRoot 'AtlasModules\Logs\install-run.log'), 'the machine''s own')

        $env:ATLAS_TEST_WINDIR = $windowsRoot
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & $script:PowerShell51 -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass `
                -File (Join-Path $script:Staged 'AtlasModules\Scripts\Install\Tasks\Copy-AtlasPayload.ps1') 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $savedPreference
            Remove-Item Env:\ATLAS_TEST_WINDIR -ErrorAction SilentlyContinue
        }

        $exitCode | Should -Be 0 -Because ($output | Out-String)
        [IO.File]::ReadAllText((Join-Path $windowsRoot 'AtlasModules\Logs\install-run.log')) | Should -BeExactly 'the machine''s own'
        [IO.File]::ReadAllText((Join-Path $windowsRoot 'AtlasModules\Scripts\new.ps1')) | Should -BeExactly 'new code'
        [IO.File]::ReadAllText((Join-Path $windowsRoot 'AtlasDesktop\1. Software\launcher.cmd')) | Should -BeExactly 'new launcher'
        Test-Path -LiteralPath (Join-Path $windowsRoot 'Resources\Themes\atlas.theme') | Should -BeTrue
    }

    It 'creates no Logs folder for a first installation' {
        $windowsRoot = Join-Path $TestDrive 'CopyFreshWindows'
        $null = New-Item -Path $windowsRoot -ItemType Directory -Force
        $env:ATLAS_TEST_WINDIR = $windowsRoot
        try {
            & $script:PowerShell51 -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass `
                -File (Join-Path $script:Staged 'AtlasModules\Scripts\Install\Tasks\Copy-AtlasPayload.ps1') 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }
        finally { Remove-Item Env:\ATLAS_TEST_WINDIR -ErrorAction SilentlyContinue }
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasModules\Scripts\new.ps1') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasModules\Logs') | Should -BeFalse
    }
}

Describe 'Version-specific file removal' {
    BeforeEach {
        $script:windowsRoot = Join-Path $TestDrive ('VsWinDir-' + [Guid]::NewGuid().ToString('N'))
        $script:startMenuRoot = Join-Path $script:windowsRoot `
            'AtlasDesktop\4. Interface Tweaks\Start Menu'
        $env:ATLAS_TEST_WINDIR = $script:windowsRoot
    }

    AfterEach {
        Remove-Item Env:\ATLAS_TEST_WINDIR -ErrorAction SilentlyContinue
    }

    It 'removes only Open-Shell entries from the Start Menu folder' {
        $null = New-Item -Path $script:startMenuRoot -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $script:startMenuRoot 'Open-Shell Skins') `
            -ItemType Directory -Force
        [IO.File]::WriteAllText(
            (Join-Path $script:startMenuRoot 'Open-Shell Skins\skin.txt'), 'x')
        [IO.File]::WriteAllText(
            (Join-Path $script:startMenuRoot 'Enable Open-Shell.cmd'), 'x')
        [IO.File]::WriteAllText(
            (Join-Path $script:startMenuRoot 'Keep Start Tweak.cmd'), 'x')
        $sibling = Join-Path $script:windowsRoot `
            'AtlasDesktop\4. Interface Tweaks\Taskbar\Open-Shell lookalike.cmd'
        $null = New-Item -Path (Split-Path -Parent $sibling) -ItemType Directory -Force
        [IO.File]::WriteAllText($sibling, 'x')

        & $script:VersionSpecificBlock

        Test-Path -LiteralPath (Join-Path $script:startMenuRoot 'Open-Shell Skins') |
            Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:startMenuRoot 'Enable Open-Shell.cmd') |
            Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:startMenuRoot 'Keep Start Tweak.cmd') |
            Should -BeTrue
        Test-Path -LiteralPath $sibling | Should -BeTrue
    }

    It 'returns quietly when the Start Menu folder is absent' {
        $null = New-Item -Path (Join-Path $script:windowsRoot 'AtlasDesktop') `
            -ItemType Directory -Force

        { & $script:VersionSpecificBlock } | Should -Not -Throw
    }

    It 'reports an undeletable Open-Shell entry as a terminating error' {
        $null = New-Item -Path $script:startMenuRoot -ItemType Directory -Force
        $lockedPath = Join-Path $script:startMenuRoot 'Open-Shell locked.cmd'
        [IO.File]::WriteAllText($lockedPath, 'locked')
        $keeper = Join-Path $script:startMenuRoot 'Keep Start Tweak.cmd'
        [IO.File]::WriteAllText($keeper, 'x')
        $lock = [IO.File]::Open(
            $lockedPath,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )
        try {
            { & $script:VersionSpecificBlock } | Should -Throw
        }
        finally {
            $lock.Dispose()
        }

        Test-Path -LiteralPath $lockedPath | Should -BeTrue
        Test-Path -LiteralPath $keeper | Should -BeTrue
    }
}
