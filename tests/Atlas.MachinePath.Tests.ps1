BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')

    # Lift Add-AtlasPath out of the task, which edits the machine PATH when it runs.
    $taskPath = Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Initialize-AtlasPath.ps1'
    $ast = [Management.Automation.Language.Parser]::ParseFile($taskPath, [ref]$null, [ref]$null)
    $definition = $ast.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Add-AtlasPath'
        }, $true)
    . ([scriptblock]::Create($definition.Extent.Text))

    $script:pathSubKey = "Software\AtlasMachinePathTest\$([guid]::NewGuid().ToString('N'))"

    function Set-TestPathValue {
        param([string]$Value, [Microsoft.Win32.RegistryValueKind]$Kind)
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:pathSubKey)
        try { $key.SetValue('Path', $Value, $Kind) }
        finally { $key.Dispose() }
    }

    function Get-TestPathValue {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:pathSubKey)
        try {
            [pscustomobject]@{
                Value = $key.GetValue('Path', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                Kind  = $key.GetValueKind('Path')
            }
        }
        finally { $key.Dispose() }
    }
}

AfterAll {
    Remove-Item -LiteralPath 'HKCU:\Software\AtlasMachinePathTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Machine PATH entries' {
    BeforeEach {
        $script:atlasPaths = @(
            (New-Item -Path (Join-Path $TestDrive 'AtlasModules') -ItemType Directory -Force).FullName
            (New-Item -Path (Join-Path $TestDrive 'AtlasModules\Tools') -ItemType Directory -Force).FullName
        )
    }

    It 'appends the Atlas entries and leaves every existing entry unexpanded' {
        $existing = '%SystemRoot%\system32;%SystemRoot%;C:\Windows;C:\WINDOWS;%JAVA_HOME%\bin'
        Set-TestPathValue -Value $existing -Kind ExpandString

        Add-AtlasPath -Paths $script:atlasPaths -Hive CurrentUser -SubKey $script:pathSubKey

        $path = Get-TestPathValue
        $path.Kind | Should -Be ([Microsoft.Win32.RegistryValueKind]::ExpandString)
        $path.Value | Should -BeExactly ((@($existing) + $script:atlasPaths) -join ';')
    }

    It 'adds nothing an existing entry already names, and makes a REG_SZ value expandable again' {
        $env:ATLAS_MACHINE_PATH_TEST = $TestDrive
        try {
            $existing = "%ATLAS_MACHINE_PATH_TEST%\atlasmodules\;$($script:atlasPaths[1].ToUpperInvariant())"
            Set-TestPathValue -Value $existing -Kind String

            Add-AtlasPath -Paths $script:atlasPaths -Hive CurrentUser -SubKey $script:pathSubKey

            $path = Get-TestPathValue
            $path.Kind | Should -Be ([Microsoft.Win32.RegistryValueKind]::ExpandString)
            $path.Value | Should -BeExactly $existing
        }
        finally { Remove-Item -LiteralPath Env:\ATLAS_MACHINE_PATH_TEST -ErrorAction SilentlyContinue }
    }
}
