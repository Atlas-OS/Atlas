BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $modulesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Scripts\Modules'

    Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:commandProcessor = [IO.Path]::Combine(
        [Environment]::GetFolderPath('System'),
        'cmd.exe'
    )
}

Describe 'Invoke-AtlasToggleNativeCommand' {
    It 'returns output and process details for an allowed exit code' {
        $result = Invoke-AtlasToggleNativeCommand `
            -FilePath $script:commandProcessor `
            -ArgumentList ([string[]]@('/d', '/c', 'echo atlas-native-ok')) `
            -AllowedExitCodes ([int[]]@(0)) `
            -PassThru

        $result.FilePath | Should -BeExactly $script:commandProcessor
        $result.ExitCode | Should -Be 0
        ($result.Output -join "`n").Trim() | Should -BeExactly 'atlas-native-ok'
    }

    It 'accepts an explicitly allowed nonzero exit even when stderr is written under Stop' {
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Stop'
            $result = Invoke-AtlasToggleNativeCommand `
                -FilePath $script:commandProcessor `
                -ArgumentList ([string[]]@(
                        '/d'
                        '/c'
                        'echo expected-absence 1>&2 & exit /b 37'
                    )) `
                -AllowedExitCodes ([int[]]@(37)) `
                -PassThru
        }
        finally {
            $ErrorActionPreference = $previousPreference
        }

        $result.ExitCode | Should -Be 37
        ($result.Output -join "`n") | Should -Match 'expected-absence'
    }

    It 'throws with native diagnostics when the exit code is not allowed' {
        {
            Invoke-AtlasToggleNativeCommand `
                -FilePath $script:commandProcessor `
                -ArgumentList ([string[]]@(
                        '/d'
                        '/c'
                        'echo native-failure & exit /b 37'
                    )) `
                -AllowedExitCodes ([int[]]@(0, 1))
        } | Should -Throw '*exited with code 37*allowed exit codes: 0, 1*native-failure*'
    }

    It 'rejects unsafe paths and ambiguous exit-code contracts before invocation' {
        {
            Invoke-AtlasToggleNativeCommand `
                -FilePath 'cmd.exe' `
                -ArgumentList ([string[]]@()) `
                -AllowedExitCodes ([int[]]@(0))
        } | Should -Throw '*must be fully qualified*'

        {
            Invoke-AtlasToggleNativeCommand `
                -FilePath (Join-Path $TestDrive 'missing.exe') `
                -ArgumentList ([string[]]@()) `
                -AllowedExitCodes ([int[]]@(0))
        } | Should -Throw '*does not exist*'

        {
            Invoke-AtlasToggleNativeCommand `
                -FilePath $script:commandProcessor `
                -ArgumentList ([string[]]@()) `
                -AllowedExitCodes ([int[]]@(0, 0))
        } | Should -Throw '*duplicate exit code 0*'
    }
}
