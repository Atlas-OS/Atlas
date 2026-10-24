BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Themes\Atlas.Themes.psd1') -Force
}

Describe 'Set-AtlasThemeMru' {
    BeforeAll {
        $script:themeMruNames = @(
            'atlas-v0.4.x-dark.theme'
            'atlas-v0.4.x-light.theme'
            'atlas-v0.5.x-dark.theme'
            'atlas-v0.5.x-light.theme'
            'dark.theme'
            'aero.theme'
        )
    }

    BeforeEach {
        # No ParameterFilter, so nothing reaches HKCU or stops a real process.
        Mock Set-ItemProperty -ModuleName Atlas.Themes
        Mock Stop-ThemeProcesses -ModuleName Atlas.Themes
    }

    It 'writes the ThemeMRU list to the CurrentVersion\Themes key' {
        $expected = -join @($script:themeMruNames | ForEach-Object { "$env:SystemRoot\resources\Themes\$_;" })

        Set-AtlasThemeMru

        Should -Invoke Set-ItemProperty -ModuleName Atlas.Themes -Times 1 -Exactly -ParameterFilter {
            $Path -ceq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes' -and
            $Name -ceq 'ThemeMRU' -and
            $Value -ceq $expected -and
            $Type -eq 'String'
        }
        Should -Invoke Stop-ThemeProcesses -ModuleName Atlas.Themes -Times 1 -Exactly
    }

    It 'lists only Atlas themes that the Atlas package installs' {
        # Copy-AtlasPayload copies these to Resources\Themes; the other entries are inbox themes.
        $themesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\Themes'
        foreach ($name in @($script:themeMruNames -like 'atlas-*')) {
            Join-Path -Path $themesRoot -ChildPath $name | Should -Exist
        }
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
