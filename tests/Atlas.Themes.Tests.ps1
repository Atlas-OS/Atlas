# Set-AtlasThemeMru reads the build from [Environment]::OSVersion, which cannot be mocked,
# so only the case for the running build can run. Pester evaluates -Skip during discovery,
# so the flag is set here rather than in BeforeAll.
$script:isWin11 = [System.Environment]::OSVersion.Version.Build -ge 22000

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Themes\Atlas.Themes.psd1') -Force
}

Describe 'Set-AtlasThemeMru' {
    BeforeEach {
        # No ParameterFilter, so nothing reaches HKCU or stops a real process.
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
        Should -Invoke Stop-ThemeProcesses -ModuleName Atlas.Themes -Times 1 -Exactly
    }

    It 'is a no-op on Windows 10 (build < 22000)' -Skip:($script:isWin11) {
        Set-AtlasThemeMru

        Should -Invoke Set-ItemProperty -ModuleName Atlas.Themes -Times 0 -Exactly
    }
}

Describe 'Set-AtlasTheme' {
    # Applying a theme goes through a native COM call that cannot be mocked and would change
    # this machine, so only the input guard is tested.
    It 'refuses <File> before applying anything' -TestCases @(
        @{ File = 'notatheme.txt'; Create = $true }
        @{ File = 'missing.theme'; Create = $false }
    ) {
        $path = Join-Path -Path $TestDrive -ChildPath $File
        if ($Create) { Set-Content -LiteralPath $path -Value 'x' -NoNewline }

        { Set-AtlasTheme -Path $path } | Should -Throw -ExpectedMessage '*not a valid path to a theme file*'
    }
}

Describe 'Set-AtlasLockscreenImage' {
    # Success calls the WinRT LockScreen API, which changes this user's lock screen.
    It 'throws when the source image path does not exist' {
        $missing = Join-Path -Path $TestDrive -ChildPath 'no-such-image.png'

        { Set-AtlasLockscreenImage -Path $missing } | Should -Throw -ExpectedMessage '*not found*'
    }
}
