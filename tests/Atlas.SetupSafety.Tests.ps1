BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Desktop-Policy.ps1')
    $source = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Setup.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    # Execute the first-logon account/security handoff, stopping at an injected
    # shell registration failure before any registry ACL API can be reached.
    $statements = @($ast.EndBlock.Statements)
    $start = @($statements | Where-Object {
        $_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$account'
    })[0].Extent.StartOffset
    $end = @($statements | Where-Object {
        $_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$runOnce'
    })[0].Extent.StartOffset
    $script:AccountHandoff = [scriptblock]::Create($ast.Extent.Text.Substring($start, $end - $start))
}

Describe 'First-logon security before shell registration' {
    BeforeEach {
        $script:PreviousNativeExitCode = $global:LASTEXITCODE
        $script:identity = [pscustomobject]@{User=[Security.Principal.SecurityIdentifier]::new('S-1-5-21-1-2-3-1001')}
        $script:config = [pscustomobject]@{username='AtlasTest'; mode='before-desktop'}
        $script:root = $TestDrive
        $script:desktopShell = 'owned fixture desktop shell'
        $script:log = Join-Path $TestDrive 'setup.log'
        $script:FakeNet = Join-Path $TestDrive 'net-stub.ps1'
        Set-Content -LiteralPath $script:FakeNet -Value '$global:LASTEXITCODE = 0'
        $script:Operations = [Collections.Generic.List[string]]::new()
        Mock Get-LocalUser { [pscustomobject]@{Name='AtlasTest'} }
        Mock Set-ItemProperty { param($Name) $script:Operations.Add($Name) }
        Mock Remove-ItemProperty { param($Name) $script:Operations.Add($Name) }
        Mock Test-Path { $false }
        Mock Set-LocalUser { $script:Operations.Add('PasswordExpires') }
        Mock Add-Content {}
        Mock Join-Path {
            $script:Operations.Add('RequirePasswordChange')
            $script:FakeNet
        } -ParameterFilter { $ChildPath -eq 'System32\net.exe' }
        Mock New-Item { throw 'Injected shell registration failure' }
        Mock Register-AtlasDesktopCleanup {}
        Mock Unregister-AtlasDesktopCleanup {}
        $script:ReadPolicyPath = 'Software\AtlasSetupSafetyReadTests\' + [guid]::NewGuid().ToString('N')
        [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:ReadPolicyPath).Dispose()
        Mock Get-Item { [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:ReadPolicyPath) }
    }
    AfterEach {
        $global:LASTEXITCODE = $script:PreviousNativeExitCode
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($script:ReadPolicyPath, $false)
    }
    It 'disables automatic logon and requires a password change even when shell registration fails' {
        { & $script:AccountHandoff } | Should -Throw '*shell registration failure*'
        ($script:Operations -join ',') | Should -Be 'AutoAdminLogon,AutoLogonCount,DefaultPassword,PasswordExpires,RequirePasswordChange'
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'AutoAdminLogon' -and $Value -eq '0' }
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'AutoLogonCount' -and $Value -eq 0 }
    }
    It 'does not register a shell when Windows rejects the native password-change requirement' {
        Set-Content -LiteralPath $script:FakeNet -Value '$global:LASTEXITCODE = 1'
        { & $script:AccountHandoff } | Should -Throw '*require a password change*'
        Should -Invoke New-Item -Times 0 -Exactly
    }
    It 'registers cleanup before setting the shell without granting registry write permissions' {
        $fixturePath = 'Software\AtlasSetupSafetyTests\' + [guid]::NewGuid().ToString('N')
        $script:FixturePolicy = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($fixturePath)
        try {
            $script:FixturePolicy.SetValue('UnrelatedPolicy', 19)
            $before = $script:FixturePolicy.GetAccessControl().GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access)
            Mock New-Item {}
            Mock Register-AtlasDesktopCleanup { $script:Operations.Add('RegisterCleanup') }
            Mock Set-ItemProperty {
                param($Name, $Value)
                $script:Operations.Add($Name)
                if ($Name -eq 'Shell') { $script:FixturePolicy.SetValue('Shell', $Value) }
            }
            & $script:AccountHandoff
            $script:FixturePolicy.GetValue('Shell') | Should -Be $script:desktopShell
            $script:FixturePolicy.GetValue('UnrelatedPolicy') | Should -Be 19
            $script:FixturePolicy.GetAccessControl().GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access) | Should -Be $before
            ($script:Operations -join ',') | Should -Be 'AutoAdminLogon,AutoLogonCount,DefaultPassword,PasswordExpires,RequirePasswordChange,RegisterCleanup,Shell'
            [IO.File]::ReadAllText((Join-Path $TestDrive 'account-ready')) | Should -Be $script:identity.User.Value
            Should -Invoke Register-AtlasDesktopCleanup -Times 1 -Exactly -ParameterFilter { $Sid -eq $script:identity.User.Value -and $Root -eq $TestDrive }
        }
        finally {
            $script:FixturePolicy.Dispose()
            [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($fixturePath, $false)
        }
    }
    It 'removes the cleanup task and ready marker if shell assignment fails' {
        Mock New-Item {}
        Mock Set-ItemProperty { if ($Name -eq 'Shell') { throw 'Injected shell write failure' } }
        { & $script:AccountHandoff } | Should -Throw '*Injected shell write failure*'
        Should -Invoke Register-AtlasDesktopCleanup -Times 1 -Exactly
        Should -Invoke Unregister-AtlasDesktopCleanup -Times 1 -Exactly
        [IO.File]::Exists((Join-Path $TestDrive 'account-ready')) | Should -BeFalse
    }
    It 'refuses to replace an existing shell' {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:ReadPolicyPath, $true)
        try { $key.SetValue('Shell', 'existing shell') } finally { $key.Dispose() }
        Mock New-Item {}
        { & $script:AccountHandoff } | Should -Throw '*custom Windows shell*'
        Should -Invoke Register-AtlasDesktopCleanup -Times 0 -Exactly
    }
}
