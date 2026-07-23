BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ScriptsRoot = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts'
    $script:PreviousInstallScript = Join-Path $script:ScriptsRoot `
        'Tasks\Remove-PreviousAtlasInstall.ps1'
    $script:VersionSpecificScript = Join-Path $script:ScriptsRoot `
        'Tasks\Remove-VersionSpecificAtlasFiles.ps1'
    $script:TrustBootstrap = Join-Path $script:ScriptsRoot `
        'Internal\Initialize-PowerShellTrust.ps1'
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
    $null = New-Item -Path (Join-Path $harnessRoot 'Tasks') -ItemType Directory -Force
    $null = New-Item -Path (Join-Path $harnessRoot 'Internal') -ItemType Directory -Force
    $script:RehostedPreviousInstall = Join-Path $harnessRoot `
        'Tasks\Remove-PreviousAtlasInstall.ps1'
    [IO.File]::WriteAllText(
        $script:RehostedPreviousInstall,
        (ConvertTo-RehostedRemovalScript -Path $script:PreviousInstallScript)
    )
    Copy-Item -LiteralPath $script:TrustBootstrap `
        -Destination (Join-Path $harnessRoot 'Internal\Initialize-PowerShellTrust.ps1')

    $script:VersionSpecificBlock = [scriptblock]::Create(
        (ConvertTo-RehostedRemovalScript -Path $script:VersionSpecificScript)
    )

    function Invoke-PreviousInstallRemoval {
        param([Parameter(Mandatory = $true)][string]$WindowsRoot)

        $env:ATLAS_TEST_WINDIR = $WindowsRoot
        try {
            $output = & $script:PowerShell51 -NoProfile -NoLogo -NonInteractive `
                -ExecutionPolicy Bypass -File $script:RehostedPreviousInstall 2>&1
            return [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = ($output | Out-String)
            }
        }
        finally {
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

Describe 'Previous-install payload removal' {
    It 'removes both Atlas payload trees and leaves every sibling intact' {
        $windowsRoot = New-UpgradeWindowsFixture -Name 'WinDirFull'

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasDesktop') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $windowsRoot 'AtlasModules') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $windowsRoot 'UnrelatedComponent\keep.dat') |
            Should -BeTrue
        Test-Path -LiteralPath (Join-Path $windowsRoot 'notepad.exe.txt') | Should -BeTrue
    }

    It 'succeeds when no previous Atlas payload exists' {
        $windowsRoot = Join-Path $TestDrive 'WinDirClean'
        $null = New-Item -Path (Join-Path $windowsRoot 'UnrelatedComponent') `
            -ItemType Directory -Force

        $result = Invoke-PreviousInstallRemoval -WindowsRoot $windowsRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        Test-Path -LiteralPath (Join-Path $windowsRoot 'UnrelatedComponent') | Should -BeTrue
    }

    It 'fails explicitly when a payload file cannot be deleted' {
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

    It 'surfaces an undeletable Open-Shell entry as a terminating error' {
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
