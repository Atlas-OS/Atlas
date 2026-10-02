BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
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
    $script:ReadConfig = [scriptblock]::Create(@($statements | Where-Object {
        $_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$config'
    })[0].Extent.Text)
}

Describe 'Setup configuration encoding' {
    # Build-Iso leaves non-ASCII characters raw in BOM-less UTF-8. Names are built
    # from code points so this file's own encoding cannot hide a decoding fault.
    It 'reads the account name <Name> exactly as Build-Iso writes it' -ForEach @(
        @{ Name = "Jos$([char]0xE9)" }
        @{ Name = "$([char]0x5C0F)$([char]0x660E)" }
        @{ Name = "$([char]0x41C)$([char]0x430)$([char]0x440)$([char]0x438)$([char]0x44F)" }
    ) {
        $root = $TestDrive
        $written = @{ schema = 2; mode = 'configured'; options = @(); username = $Name; drivers = 'automatic' }
        [IO.File]::WriteAllText((Join-Path $root 'setup.json'), ($written | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))
        . $script:ReadConfig
        $config.username | Should -BeExactly $Name
    }
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

Describe 'The drivers choice during ISO setup' {
    BeforeAll {
        $source = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Setup.ps1'
        $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$null)
        # The step that applies DriverPolicy.reg, and the libraries setup loads.
        $script:DriverStep = [scriptblock]::Create(@($ast.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.IfStatementAst] -and
                        $node.Clauses[0].Item1.Extent.Text -like '*DriverPolicy.reg*'
                    }, $true))[0].Extent.Text)
        $script:Libraries = @($ast.EndBlock.Statements | Where-Object {
                $_.Extent.Text -match "^\. \(Join-Path \`$root '([^']+)'\)$"
            } | ForEach-Object { $_.Extent.Text -replace "^\. \(Join-Path \`$root '([^']+)'\)$", '$1' })
        . (Join-Path $script:AtlasTestScriptsRoot 'Preparation\RegistryFile.ps1')
    }
    BeforeEach {
        $script:root = $TestDrive
        $script:log = Join-Path $TestDrive 'setup.log'
        Mock Import-AtlasRegistryFile {}
    }

    It 'loads only libraries the media build copies beside it' {
        $build = [Management.Automation.Language.Parser]::ParseFile(
            (Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Build-Iso.ps1'), [ref]$null, [ref]$null)
        $copy = $build.Find({
                param($node)
                $node -is [Management.Automation.Language.ForEachStatementAst] -and
                @($node.Condition.FindAll({ param($n) $n -is [Management.Automation.Language.StringConstantExpressionAst] }, $true).Value) -contains 'Setup.ps1'
            }, $true)
        $copied = @($copy.Condition.FindAll({ param($n) $n -is [Management.Automation.Language.StringConstantExpressionAst] }, $true).Value)
        @($script:Libraries).Count | Should -BeGreaterThan 0
        foreach ($library in $script:Libraries) { $copied | Should -Contain $library }
    }

    It 'applies the staged drivers choice with the shared import, logging to setup.log' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'DriverPolicy.reg') -Value 'Windows Registry Editor Version 5.00'
        & $script:DriverStep
        Should -Invoke Import-AtlasRegistryFile -Times 1 -Exactly -ParameterFilter {
            $Path -eq (Join-Path $TestDrive 'DriverPolicy.reg') -and $Log -eq (Join-Path $TestDrive 'setup.log')
        }
    }

    It 'stops setup with its own message when the drivers choice cannot be applied' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'DriverPolicy.reg') -Value 'Windows Registry Editor Version 5.00'
        Mock Import-AtlasRegistryFile { throw 'DriverPolicy.reg has a line Atlas doesn''t apply: odd' }
        { & $script:DriverStep } | Should -Throw '*could not apply the ISO driver policy*odd*'
    }

    It 'leaves the drivers alone when the media carries no choice' {
        Remove-Item -LiteralPath (Join-Path $TestDrive 'DriverPolicy.reg') -ErrorAction SilentlyContinue
        & $script:DriverStep
        Should -Invoke Import-AtlasRegistryFile -Times 0 -Exactly
    }
}
