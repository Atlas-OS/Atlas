# Set-AtlasThemeMru only writes on Windows 11+ (build >= 22000); on Windows 10 it is a
# deliberate no-op. We cannot mock the [System.Environment]::OSVersion static, so branch the
# assertion on the real build while keeping the mutating cmdlet mocked in both cases. This is
# computed at the top level so it is available during Pester's discovery phase, where the
# -Skip expressions on the It blocks below are evaluated.
$script:isWin11 = [System.Environment]::OSVersion.Version.Build -ge 22000

BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Themes\Atlas.Themes.psd1') -Force
}

Describe 'Set-AtlasThemeMru' {
    BeforeEach {
        # Catch-all mocks (no ParameterFilter) guarantee the real Set-ItemProperty never
        # touches HKCU and no Settings/control processes are killed, whatever the args.
        Mock Set-ItemProperty -ModuleName Atlas.Themes
        Mock Stop-ThemeProcesses -ModuleName Atlas.Themes
    }

    It 'writes the Windows 11 ThemeMRU list to the CurrentVersion\Themes key' -Skip:(-not $script:isWin11) {
        Set-AtlasThemeMru

        Should -Invoke Set-ItemProperty -ModuleName Atlas.Themes -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'ThemeMRU' -and
            $Path -like '*CurrentVersion\Themes' -and
            $Value -like '*atlas-v0.4.x-dark.theme*' -and
            $Value -like '*atlas-v0.5.x-light.theme*' -and
            $Value -like '*aero.theme*'
        }
        # It stops the theme UI processes before rewriting the MRU.
        Should -Invoke Stop-ThemeProcesses -ModuleName Atlas.Themes -Times 1 -Exactly
    }

    It 'is a no-op on Windows 10 (build < 22000)' -Skip:($script:isWin11) {
        Set-AtlasThemeMru

        Should -Invoke Set-ItemProperty -ModuleName Atlas.Themes -Times 0 -Exactly
    }
}

Describe 'Set-AtlasTheme' {
    # The apply path drives a static [ThemeManagerAPI]::ApplyTheme COM call (with an
    # explorer-launch fallback nested inside the function) that is neither mockable nor
    # safe to run in a test, so only the input-validation guard is exercised here.
    It 'throws when the path is not a .theme file' {
        $notATheme = Join-Path -Path $TestDrive -ChildPath 'notatheme.txt'
        Set-Content -LiteralPath $notATheme -Value 'x' -NoNewline

        { Set-AtlasTheme -Path $notATheme } | Should -Throw -ExpectedMessage '*not a valid path to a theme file*'
    }

    It 'throws when the path does not exist' {
        $missing = Join-Path -Path $TestDrive -ChildPath 'missing.theme'

        { Set-AtlasTheme -Path $missing } | Should -Throw -ExpectedMessage '*not a valid path to a theme file*'
    }

    It 'rejects a null or empty path via parameter validation' {
        { Set-AtlasTheme -Path '' } | Should -Throw
    }
}

Describe 'Set-AtlasLockscreenImage' {
    # The success path calls the WinRT LockScreen API (real per-user mutation), so only the
    # missing-source guard is unit-testable without touching the machine.
    It 'throws when the source image path does not exist' {
        $missing = Join-Path -Path $TestDrive -ChildPath 'no-such-image.png'

        { Set-AtlasLockscreenImage -Path $missing } | Should -Throw -ExpectedMessage '*not found*'
    }
}
