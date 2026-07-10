BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:helperPath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-IndexConfiguration.ps1'
    $script:launcherPath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Scripts\Set-IndexConfiguration.cmd'
    $script:callerPath = Join-Path $script:repoRoot `
        'playbook\Executables\AtlasModules\Toggles\General\Indexing.ps1'

    . $script:helperPath -LibraryOnly
}

Describe 'Typed index configuration primitives' {
    It 'preserves percent, exclamation, ampersand, and space characters as literal path data' {
        $candidate = Join-Path $TestDrive 'Index %ATLAS_INDEX_PERCENT% & !ATLAS_INDEX_PATH_TEST! Folder'
        $expected = [IO.Path]::GetFullPath($candidate)
        $original = [Environment]::GetEnvironmentVariable('ATLAS_INDEX_PATH_TEST', 'Process')
        try {
            [Environment]::SetEnvironmentVariable('ATLAS_INDEX_PATH_TEST', 'MUTATED', 'Process')
            ConvertTo-AtlasIndexPath -Candidate $candidate | Should -BeExactly $expected
        }
        finally {
            [Environment]::SetEnvironmentVariable('ATLAS_INDEX_PATH_TEST', $original, 'Process')
        }
    }

    It 'rejects relative and wildcard paths before any registry operation' {
        { ConvertTo-AtlasIndexPath -Candidate '.\relative' } | Should -Throw '*fully qualified*'
        { ConvertTo-AtlasIndexPath -Candidate '\root-relative' } | Should -Throw '*fully qualified*'
        { ConvertTo-AtlasIndexPath -Candidate 'C:drive-relative' } | Should -Throw '*fully qualified*'
        { ConvertTo-AtlasIndexPath -Candidate '\\server-only' } | Should -Throw '*fully qualified*'
        { ConvertTo-AtlasIndexPath -Candidate (Join-Path $TestDrive 'wild*card') } | Should -Throw '*wildcard*'
    }

    It 'selects the first free numeric registry entry deterministically' {
        Get-AtlasFirstFreeIndexEntryName -ExistingNames @() | Should -BeExactly '0'
        Get-AtlasFirstFreeIndexEntryName -ExistingNames @('0', '1', '3', 'custom') | Should -BeExactly '2'
    }

    It 'preserves a protected native child failure without an ERRORLEVEL environment expansion' {
        $cmdPath = Join-Path ([Environment]::GetFolderPath('System')) 'cmd.exe'
        $caught = $null
        $originalErrorLevel = [Environment]::GetEnvironmentVariable('ERRORLEVEL', 'Process')
        try {
            [Environment]::SetEnvironmentVariable('ERRORLEVEL', '91', 'Process')
            try {
                [void](Invoke-AtlasIndexNativeCommand -FilePath $cmdPath `
                        -ArgumentList @('/d', '/s', '/c', 'exit /b 37') `
                        -Description 'safe index exit probe')
            }
            catch {
                $caught = $_
            }
        }
        finally {
            [Environment]::SetEnvironmentVariable('ERRORLEVEL', $originalErrorLevel, 'Process')
        }

        $caught | Should -Not -BeNullOrEmpty
        $caught.Exception.Data['Atlas.IndexConfiguration.ExitCode'] | Should -Be 37
    }

    It 'round-trips native argv without a shell under the hidden process boundary' {
        $probePath = Join-Path $TestDrive 'index-native-argv-probe.ps1'
        @'
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [AllowEmptyCollection()]
    [AllowEmptyString()]
    [string[]]$Values
)
foreach ($value in $Values) {
    'ARG:' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($value))
}
'@ | Set-Content -LiteralPath $probePath -Encoding UTF8
        $powershellPath = Join-Path ([Environment]::GetFolderPath('System')) `
            'WindowsPowerShell\v1.0\powershell.exe'
        $expected = @(
            'space & percent %UNDEFINED% !mark!'
            'trailing-slash\'
            'quoted"value'
            ''
        )

        $output = @(Invoke-AtlasIndexNativeCommand `
                -FilePath $powershellPath `
                -ArgumentList (@('-NoProfile', '-NoLogo', '-NonInteractive', '-File', $probePath) + $expected) `
                -Description 'native argv round-trip probe')
        $encodedValues = @(($output -join "`n") -split '\r?\n' | Where-Object {
                $_.StartsWith('ARG:', [StringComparison]::Ordinal)
            })
        $actual = @($encodedValues | ForEach-Object {
                [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($_.Substring(4)))
            })

        $actual.Count | Should -Be $expected.Count
        for ($index = 0; $index -lt $expected.Count; $index++) {
            $actual[$index] | Should -BeExactly $expected[$index]
        }
    }

    It 'preserves a typed native exit through the production error writer in a child host' {
        $hostPath = if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Join-Path $PSHOME 'powershell.exe'
        }
        else {
            Join-Path $PSHOME 'pwsh.exe'
        }
        $probePath = Join-Path $TestDrive 'index-typed-exit-probe.ps1'
        @'
param([Parameter(Mandatory = $true)][string]$HelperPath)
. $HelperPath -LibraryOnly
$cmdPath = Join-Path ([Environment]::GetFolderPath('System')) 'cmd.exe'
try {
    [void](Invoke-AtlasIndexNativeCommand -FilePath $cmdPath `
            -ArgumentList @('/d', '/s', '/c', 'exit /b 37') `
            -Description 'typed child exit probe')
}
catch {
    exit (Write-AtlasIndexError -ErrorRecord $_)
}
exit 0
'@ | Set-Content -LiteralPath $probePath -Encoding UTF8

        $stderrPath = Join-Path $TestDrive 'index-typed-exit-probe.stderr.txt'
        $process = Start-Process -FilePath $hostPath `
            -ArgumentList @(
                '-NoProfile',
                '-NoLogo',
                '-NonInteractive',
                '-File',
                "`"$probePath`"",
                '-HelperPath',
                "`"$script:helperPath`""
            ) `
            -RedirectStandardError $stderrPath `
            -Wait `
            -PassThru
        $process.ExitCode | Should -Be 37
    }

    It 'throws in-process contract failures without terminating the caller host' {
        {
            & $script:helperPath -Operation SetRespectPowerModes -InProcess
        } | Should -Throw '*requires an explicit setting value*'

        # Reaching this assertion proves the helper returned control to the host.
        $PID | Should -BeGreaterThan 0
    }
}

Describe 'Index configuration compatibility launcher' {
    It 'is a thin fixed-path PowerShell wrapper with a closed argument grammar' {
        $launcher = Get-Content -LiteralPath $script:launcherPath -Raw

        $launcher | Should -Match '(?m)^verify other 2>nul\r?\nsetlocal EnableExtensions DisableDelayedExpansion\r?\nif errorlevel 1 exit /b 1\r?$'
        $launcher | Should -Match 'Internal\\Set-IndexConfiguration\.ps1'
        $launcher | Should -Match ([regex]::Escape('"%AtlasNativeFltmc%"'))
        $launcher | Should -Match ([regex]::Escape('"%AtlasNativePowerShell%"'))
        $launcher | Should -Not -Match '%__APPDIR__%WindowsPowerShell|%__APPDIR__%fltmc'
        foreach ($mapping in @(
                @{ Argument = '/include'; Operation = 'Include' }
                @{ Argument = '/exclude'; Operation = 'Exclude' }
                @{ Argument = '/cleanpolicies'; Operation = 'CleanPolicies' }
                @{ Argument = '/start'; Operation = 'Start' }
                @{ Argument = '/stop'; Operation = 'Stop' }
            )) {
            $launcher | Should -Match ([regex]::Escape(('"%~1"=="{0}"' -f $mapping.Argument)))
            $launcher | Should -Match ([regex]::Escape(('set "operation={0}"' -f $mapping.Operation)))
        }
        $launcher | Should -Match '-Operation "%operation%" -IndexPath "%indexPath%"'
        ([regex]::Matches(
                $launcher,
                '(?ms)^if errorlevel 0 \(\r?\n\s+if errorlevel 1 exit /b\r?\n\) else \(\r?\n\s+exit /b 1\r?\n\)\r?\nexit /b 0\r?$'
            )).Count | Should -Be 2
        $launcher | Should -Not -Match '(?im)^\s*(?:reg|sc|gpupdate|netsh)\b|for /f|enabledelayedexpansion|%errorlevel%|!errorlevel!|%\*'
    }

    It 'uses CRLF exclusively for the CMD compatibility surface' {
        $bytes = [IO.File]::ReadAllBytes($script:launcherPath)
        for ($index = 0; $index -lt $bytes.Length; $index++) {
            if ($bytes[$index] -eq 10) {
                $index | Should -BeGreaterThan 0
                $bytes[$index - 1] | Should -Be 13
            }
        }
    }
}

Describe 'Index configuration state postconditions' {
    It 'implements registry, service, visibility, and policy-refresh postconditions in PowerShell' {
        $helper = Get-Content -LiteralPath $script:helperPath -Raw

        foreach ($operation in @(
                'Include',
                'Exclude',
                'CleanPolicies',
                'Start',
                'Stop',
                'SetRespectPowerModes',
                'ResetSetupCompleted'
            )) {
            $helper | Should -Match ([regex]::Escape("'$operation'"))
        }
        $helper | Should -Match '\[Microsoft\.Win32\.Registry\]::LocalMachine\.DeleteSubKeyTree'
        $helper | Should -Match "SetValue\('Path'.+RegistryValueKind\]::String\)"
        $helper | Should -Match "GetValueKind\('Path'\)"
        $helper | Should -Match "GetValueKind\('Start'\)"
        $helper | Should -Match "GetValueKind\('DelayedAutoStart'\)"
        $helper | Should -Match 'Set-AtlasIndexRegistryDword'
        $helper | Should -Match 'RegistryValueKind\]::DWord'
        $helper | Should -Match '\$startInfo\.UseShellExecute = \$false'
        $helper | Should -Match '\$startInfo\.CreateNoWindow = \$true'
        $helper | Should -Match '\$startInfo\.WindowStyle = \[Diagnostics\.ProcessWindowStyle\]::Hidden'
        $helper | Should -Match 'Assert-AtlasSearchServiceConfiguration'
        $helper | Should -Match 'Assert-AtlasSearchServiceState'
        $helper | Should -Match 'WaitForStatus\('
        $helper | Should -Match 'Assert-AtlasIndexSettingsVisibility'
        $helper | Should -Match "ArgumentList @\('/force', '/wait:600'\)"
        $gpUpdateIndex = $helper.IndexOf("-Description 'refreshing Group Policy'", [StringComparison]::Ordinal)
        $gpUpdateIndex | Should -BeGreaterThan -1
        $helper.IndexOf('Assert-AtlasSearchServiceConfiguration -Configuration DelayedAutomatic', $gpUpdateIndex) |
            Should -BeGreaterThan $gpUpdateIndex
        $helper.IndexOf('Assert-AtlasSearchServiceState -State Running', $gpUpdateIndex) |
            Should -BeGreaterThan $gpUpdateIndex
        $helper.IndexOf('Assert-AtlasIndexSettingsVisibility -Hidden $false', $gpUpdateIndex) |
            Should -BeGreaterThan $gpUpdateIndex
        $helper | Should -Not -Match '/wait:0|Invoke-Expression|%errorlevel%|!errorlevel!'
    }

    It 'uses the typed helper in-process without a cmd command string or nonterminating registry writes' {
        $caller = Get-Content -LiteralPath $script:callerPath -Raw

        $caller | Should -Match 'Internal'',\s*\r?\n\s*''Set-IndexConfiguration\.ps1'''
        $caller | Should -Match '& \$helperPath @invokeParameters'
        $caller | Should -Match 'InProcess = \$true'
        $caller | Should -Match 'Invoke-AtlasIndexConfig -Operation Include -IndexPath \$programsPath'
        $caller | Should -Match 'Invoke-AtlasIndexConfig -Operation SetRespectPowerModes -SettingValue 1'
        $caller | Should -Match 'Invoke-AtlasIndexConfig -Operation ResetSetupCompleted'
        $caller | Should -Match 'Get-ChildItem -LiteralPath \$usersPath -Directory -ErrorAction Stop'
        $caller | Should -Not -Match '(?i)cmd\.exe|Start-Process|ArgumentList|/c.+call|Set-IndexConfiguration\.cmd|New-ItemProperty|SilentlyContinue'
    }
}
