BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Desktop-Policy.ps1')
    $source = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Desktop.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    $restore = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Restore-AtlasDesktop' }, $true)
    . ([scriptblock]::Create($restore.Extent.Text))
    $start = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Start-AtlasWindowsShell' }, $true)
    . ([scriptblock]::Create($start.Extent.Text))
    $script:policyPath = 'Software\AtlasDesktopSetupTests\' + [guid]::NewGuid().ToString('N')
    $script:shell = 'owned test shell'
}
Describe 'Before-desktop recovery' {
BeforeEach {
    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:policyPath)
    $key.DeleteValue('Shell', $false)
    $key.Dispose()
    Mock Start-Process {}
    Mock Get-Process { @() }
    Mock Start-Sleep {}
    Mock Request-AtlasDesktopCleanup {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath, $true)
        try { Remove-AtlasOwnedShell -Key $key -Shell $script:shell }
        finally { if ($key) { $key.Dispose() } }
    }
}
AfterAll {
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($script:policyPath, $false)
}
    It 'removes its own shell and opens Windows' {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath, $true)
        $key.SetValue('Shell', $script:shell)
        $key.Dispose()
        Restore-AtlasDesktop
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath)
        try { $key.GetValue('Shell') | Should -BeNullOrEmpty } finally { $key.Dispose() }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq (Join-Path $env:WINDIR 'explorer.exe') }
    }
    It 'preserves a shell installed by another application' {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath, $true)
        $key.SetValue('Shell', 'another shell')
        $key.Dispose()
        Restore-AtlasDesktop
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath)
        try { $key.GetValue('Shell') | Should -Be 'another shell' } finally { $key.Dispose() }
        Should -Invoke Start-Process -Times 1 -Exactly
    }
    It 'opens Windows if its shell setting has already been removed' {
        Restore-AtlasDesktop
        Should -Invoke Start-Process -Times 1 -Exactly
    }
    It 'opens Windows if the policy key has been removed' {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($script:policyPath)
        Restore-AtlasDesktop
        Should -Invoke Start-Process -Times 1 -Exactly
    }
    It 'does not open an Explorer folder when the shell is already running' {
        Mock Get-Process { [pscustomobject]@{ SessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId } }
        Restore-AtlasDesktop
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'does not mistake another session for the current shell' {
        Mock Get-Process { [pscustomobject]@{ SessionId = -1 } }
        Start-AtlasWindowsShell
        Should -Invoke Start-Process -Times 1 -Exactly
    }
    It 'preserves its shell and opens Windows when the cleanup task cannot start' {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath, $true)
        $key.SetValue('Shell', $script:shell)
        $key.Dispose()
        Mock Request-AtlasDesktopCleanup { throw 'Injected task failure' }
        $previousLocalAppData = $env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA = $TestDrive
            Restore-AtlasDesktop
            [IO.File]::ReadAllText((Join-Path $TestDrive 'Atlas-desktop-recovery.log')) | Should -Match 'Injected task failure'
        }
        finally { $env:LOCALAPPDATA = $previousLocalAppData }
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:policyPath)
        try { $key.GetValue('Shell') | Should -Be $script:shell } finally { $key.Dispose() }
        Should -Invoke Start-Process -Times 1 -Exactly
    }
}
