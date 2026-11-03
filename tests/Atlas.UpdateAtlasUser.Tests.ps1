BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'
    $script:CurrentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $script:SandboxSubKey = 'Software\AtlasRewriteTestUpdateAtlasUser'
    # What Invoke-AtlasInstallingUserSetup stamps for a reinstall of 0.6.0.
    $script:ReinstallStamp = '0.6.0+3f2504e0-4f89-41d3-9a0c-0305e82c3301'

    # Copies Update-AtlasUser.ps1 and the real bootstrap into a fixture tree with stub
    # modules that log each call. The entry's two Atlas keys are pointed at the sandbox,
    # so a run never touches this account's own Atlas markers.
    function New-UpdateUserFixture {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $scripts = Join-Path $root 'AtlasModules\Scripts'
        $sandbox = "HKCU:\$script:SandboxSubKey\$(Split-Path -Leaf $root)"
        $fixture = [pscustomobject]@{
            Entry        = Join-Path $scripts 'Entry\Update-AtlasUser.ps1'
            CallLog      = Join-Path $root 'calls.log'
            LocalAppData = Join-Path $root 'LocalAppData'
            Modules      = Join-Path $root 'AtlasModules'
            Inherited    = Join-Path $root 'inherited-modules'
            MarkerPath   = "$sandbox\UserSetup"
            EligiblePath = "$sandbox\UpgradeUsers"
        }
        New-Item -ItemType Directory -Path (Join-Path $scripts 'Entry'), $fixture.LocalAppData -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') -Destination $scripts

        $entry = Get-Content -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Entry\Update-AtlasUser.ps1') -Raw
        foreach ($pair in @(
                @("'HKCU:\SOFTWARE\AtlasOS\UserSetup'", "'$($fixture.MarkerPath)'"),
                @("'HKLM:\SOFTWARE\AtlasOS\UpgradeUsers'", "'$($fixture.EligiblePath)'"))) {
            if (-not $entry.Contains($pair[0])) { throw "Update-AtlasUser.ps1 no longer names $($pair[0])." }
            $entry = $entry.Replace($pair[0], $pair[1])
        }
        Set-Content -LiteralPath $fixture.Entry -Value $entry

        $stubs = @{
            'Atlas.Core'     = @'
Add-Content -LiteralPath $env:ATLAS_TEST_CALL_LOG -Value ('Join-Path:' + (Get-Command Join-Path).Source)
function Test-AtlasSystem { $false }
function Test-AtlasAdmin { $false }
function Get-AtlasContext {
    param([switch]$Refresh)
    [pscustomobject]@{ IsUpgrade = $false; IsInstallStateBacked = $true; TargetVersion = '0.6.0'; InstalledVersion = '0.5.0'; AtlasModulesPath = $env:ATLAS_TEST_MODULES_PATH }
}
'@
            'Atlas.Registry' = @'
function Initialize-AtlasRegistryIdentityContext {
    param([switch]$CurrentToken, [string]$ExpectedUserSid)
    Add-Content -LiteralPath $env:ATLAS_TEST_CALL_LOG -Value "Identity:$ExpectedUserSid"
}
'@
            'Atlas.Tweaks'   = @'
function Get-AtlasTweakManifest {
    param([string]$Path)
    Add-Content -LiteralPath $env:ATLAS_TEST_CALL_LOG -Value "Manifest:$Path"
    @{ Categories = @(@{ Name = 'privacy' }, @{ Name = 'qol' }) }
}
function Invoke-AtlasTweakCategory {
    param([string]$Name, [string]$RegistryScope, [switch]$RegistryOnly, $Context)
    Add-Content -LiteralPath $env:ATLAS_TEST_CALL_LOG -Value "Category:${Name}:$RegistryScope"
}
'@
            'Atlas.Toggles'  = @'
function Invoke-AtlasToggleUserReapply { Add-Content -LiteralPath $env:ATLAS_TEST_CALL_LOG -Value 'ToggleReapply' }
'@
        }
        foreach ($module in $stubs.Keys) {
            $moduleRoot = Join-Path $scripts "Modules\$module"
            New-Item -ItemType Directory -Path $moduleRoot -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $moduleRoot "$module.psd1") -Value "@{ RootModule = '$module.psm1'; ModuleVersion = '1.0.0' }"
            Set-Content -LiteralPath (Join-Path $moduleRoot "$module.psm1") -Value $stubs[$module]
        }

        # A user module that exports two core cmdlet names, as an inherited logon
        # PSModulePath can carry.
        $shadowRoot = Join-Path $fixture.Inherited 'Shadow'
        New-Item -ItemType Directory -Path $shadowRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $shadowRoot 'Shadow.psd1') -Value "@{ RootModule = 'Shadow.psm1'; ModuleVersion = '1.0.0'; FunctionsToExport = @('Split-Path', 'Join-Path') }"
        Set-Content -LiteralPath (Join-Path $shadowRoot 'Shadow.psm1') -Value @'
function Split-Path { [Console]::Out.WriteLine('SHADOWED'); throw 'A shadowing Split-Path ran.' }
function Join-Path { [Console]::Out.WriteLine('SHADOWED'); throw 'A shadowing Join-Path ran.' }
'@

        $null = New-Item -Path $fixture.MarkerPath -Force
        $null = New-Item -Path $fixture.EligiblePath -Force
        return $fixture
    }

    function Invoke-UpdateUserFixture {
        param($Fixture, [string[]]$Arguments = @())
        $saved = @{ PSModulePath = $env:PSModulePath; LOCALAPPDATA = $env:LOCALAPPDATA }
        $previousPreference = $ErrorActionPreference
        try {
            $env:PSModulePath = $Fixture.Inherited
            $env:LOCALAPPDATA = $Fixture.LocalAppData
            $env:ATLAS_TEST_CALL_LOG = $Fixture.CallLog
            $env:ATLAS_TEST_MODULES_PATH = $Fixture.Modules
            $ErrorActionPreference = 'Continue'
            $output = & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Fixture.Entry @Arguments 2>&1
            [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = ($output | Out-String)
                Calls    = @(if (Test-Path -LiteralPath $Fixture.CallLog) { Get-Content -LiteralPath $Fixture.CallLog })
            }
        }
        finally {
            $env:PSModulePath = $saved.PSModulePath
            $env:LOCALAPPDATA = $saved.LOCALAPPDATA
            Remove-Item -Path Env:\ATLAS_TEST_CALL_LOG, Env:\ATLAS_TEST_MODULES_PATH -ErrorAction SilentlyContinue
            $ErrorActionPreference = $previousPreference
        }
    }
}

AfterAll {
    Remove-Item -Path "HKCU:\$script:SandboxSubKey" -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'User upgrade entry' {
    It 'leaves the installing user''s categories to the install steps and keeps the other setup values' {
        $fixture = New-UpdateUserFixture
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name $script:CurrentSid -Value 2 -Type DWord
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name StartRefreshBoot -Value 'boot-stamp' -Type String

        $result = Invoke-UpdateUserFixture -Fixture $fixture -Arguments @('-ExpectedUserSid', $script:CurrentSid)

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Calls | Should -Contain "Identity:$script:CurrentSid"
        $result.Calls | Should -Contain 'ToggleReapply'
        @($result.Calls -like 'Manifest:*') | Should -HaveCount 0
        @($result.Calls -like 'Category:*') | Should -HaveCount 0
        $marker = Get-ItemProperty -LiteralPath $fixture.MarkerPath
        $marker.UpgradeVersion | Should -BeExactly '0.6.0'
        $marker.($script:CurrentSid) | Should -Be 2
        $marker.StartRefreshBoot | Should -BeExactly 'boot-stamp'
    }

    It 'migrates every manifest category for an eligible account at logon' {
        $fixture = New-UpdateUserFixture
        Set-ItemProperty -LiteralPath $fixture.EligiblePath -Name $script:CurrentSid -Value '0.6.0' -Type String
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name UpgradeVersion -Value '0.5.0' -Type String

        $result = Invoke-UpdateUserFixture -Fixture $fixture

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Calls | Should -Contain "Manifest:$(Join-Path $fixture.Modules 'Scripts\Tweaks\tweaks.manifest.psd1')"
        @($result.Calls -like 'Category:*') | Should -Be @('Category:privacy:CurrentUser', 'Category:qol:CurrentUser')
        $result.Calls | Should -Contain 'ToggleReapply'
        (Get-ItemProperty -LiteralPath $fixture.MarkerPath).UpgradeVersion | Should -BeExactly '0.6.0'
    }

    It 'runs once at logon for a reinstall of the same version, and records its stamp' {
        $fixture = New-UpdateUserFixture
        Set-ItemProperty -LiteralPath $fixture.EligiblePath -Name $script:CurrentSid -Value $script:ReinstallStamp -Type String
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name UpgradeVersion -Value '0.6.0' -Type String

        $result = Invoke-UpdateUserFixture -Fixture $fixture

        $result.ExitCode | Should -Be 0 -Because $result.Output
        @($result.Calls -like 'Category:*') | Should -Be @('Category:privacy:CurrentUser', 'Category:qol:CurrentUser')
        $result.Calls | Should -Contain 'ToggleReapply'
        (Get-ItemProperty -LiteralPath $fixture.MarkerPath).UpgradeVersion | Should -BeExactly $script:ReinstallStamp
    }

    It 'doesn''t run again at logon for the stamp it recorded' {
        $fixture = New-UpdateUserFixture
        Set-ItemProperty -LiteralPath $fixture.EligiblePath -Name $script:CurrentSid -Value $script:ReinstallStamp -Type String
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name UpgradeVersion -Value $script:ReinstallStamp -Type String

        $result = Invoke-UpdateUserFixture -Fixture $fixture

        $result.ExitCode | Should -Be 0 -Because $result.Output
        @($result.Calls -like 'Category:*') | Should -HaveCount 0
        $result.Calls | Should -Not -Contain 'ToggleReapply'
    }

    It 'records the installing user''s own stamp, so its next logon doesn''t run again' {
        $fixture = New-UpdateUserFixture
        Set-ItemProperty -LiteralPath $fixture.EligiblePath -Name $script:CurrentSid -Value $script:ReinstallStamp -Type String
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name UpgradeVersion -Value '0.6.0' -Type String

        $install = Invoke-UpdateUserFixture -Fixture $fixture -Arguments @('-ExpectedUserSid', $script:CurrentSid)
        Remove-Item -LiteralPath $fixture.CallLog
        $logon = Invoke-UpdateUserFixture -Fixture $fixture

        $install.ExitCode | Should -Be 0 -Because $install.Output
        $install.Calls | Should -Contain 'ToggleReapply'
        (Get-ItemProperty -LiteralPath $fixture.MarkerPath).UpgradeVersion | Should -BeExactly $script:ReinstallStamp
        $logon.ExitCode | Should -Be 0 -Because $logon.Output
        $logon.Calls | Should -Not -Contain 'ToggleReapply'
    }

    It 'takes an eligibility value that isn''t text as the installed version' {
        $fixture = New-UpdateUserFixture
        Set-ItemProperty -LiteralPath $fixture.EligiblePath -Name $script:CurrentSid -Value 1 -Type DWord
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name UpgradeVersion -Value '0.6.0' -Type String

        $result = Invoke-UpdateUserFixture -Fixture $fixture

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Calls | Should -Not -Contain 'ToggleReapply'
    }

    It 'pins module resolution before a user module can shadow a core cmdlet' {
        $fixture = New-UpdateUserFixture
        $result = Invoke-UpdateUserFixture -Fixture $fixture -Arguments @('-ExpectedUserSid', $script:CurrentSid)

        $result.Output | Should -Not -Match 'SHADOWED'
        $result.Calls | Should -Contain 'Join-Path:Microsoft.PowerShell.Management'
    }
}

Describe 'Set-AtlasUpgradeUserStamp' {
    BeforeAll {
        . (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Set-AtlasUpgradeUsers.ps1')
    }

    AfterAll {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath 'Function:\Set-AtlasUpgradeUserStamp' -ErrorAction SilentlyContinue
    }

    It 'stamps every person''s account in the profile list and drops the stamps an earlier install left' {
        $root = "HKCU:\$script:SandboxSubKey\Stamp-$([guid]::NewGuid().ToString('N'))"
        $profiles = "$root\ProfileList"
        foreach ($sid in 'S-1-5-18', 'S-1-5-21-1-2-3-1001', 'S-1-5-21-1-2-3-1001.bak', 'S-1-12-1-4-5-6-7') {
            New-Item -Path "$profiles\$sid" -Force | Out-Null
        }
        $eligible = "$root\UpgradeUsers"
        New-Item -Path $eligible -Force | Out-Null
        New-ItemProperty -LiteralPath $eligible -Name 'S-1-5-21-9-9-9-9' -Value '0.6.0' -PropertyType String | Out-Null

        Set-AtlasUpgradeUserStamp -Value $script:ReinstallStamp -Path $eligible -ProfileListPath $profiles

        $key = Get-Item -LiteralPath $eligible
        $names = @($key.GetValueNames())
        $names | Should -HaveCount 2
        foreach ($sid in 'S-1-5-21-1-2-3-1001', 'S-1-12-1-4-5-6-7') {
            $names | Should -Contain $sid
            $key.GetValueKind($sid) | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
            $key.GetValue($sid) | Should -BeExactly $script:ReinstallStamp
        }
    }
}

Describe 'Install-time stamps' {
    BeforeAll {
        $script:TransactionId = '3f2504e0-4f89-41d3-9a0c-0305e82c3301'

        # Copies the installing user's setup into a fixture tree whose Atlas.Core,
        # stamp helper and failure reader only log, so a run changes nothing here.
        function New-InstallingUserSetupFixture {
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $tasks = Join-Path $root 'Scripts\Install\Tasks'
            $core = Join-Path $root 'Scripts\Modules\Atlas.Core'
            $entry = Join-Path $root 'Scripts\Entry'
            New-Item -ItemType Directory -Path $tasks, $core, $entry -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Invoke-AtlasInstallingUserSetup.ps1') -Destination $tasks
            Set-Content -LiteralPath (Join-Path $tasks 'Get-AtlasUserFailureDetail.ps1') -Value 'function Get-AtlasUserFailureDetail { param($UserSid, $TranscriptPattern, $NotBefore) '''' }'
            Set-Content -LiteralPath (Join-Path $tasks 'Set-AtlasUpgradeUsers.ps1') -Value @'
function Set-AtlasUpgradeUserStamp {
    param([string]$Value)
    Add-Content -LiteralPath $env:ATLAS_TEST_CALL_LOG -Value "Stamp:$Value"
}
'@
            foreach ($name in 'Update-AtlasUser.ps1', 'Initialize-NewUser.ps1') {
                Set-Content -LiteralPath (Join-Path $entry $name) -Value '# Stands in for the account setup entry.'
            }
            Set-Content -LiteralPath (Join-Path $core 'Atlas.Core.psd1') -Value "@{ RootModule = 'Atlas.Core.psm1'; ModuleVersion = '1.0.0' }"
            Set-Content -LiteralPath (Join-Path $core 'Atlas.Core.psm1') -Value @"
function Assert-AtlasPrivilege { param([switch]`$TrustedInstaller) }
function Get-AtlasContext {
    param([switch]`$Refresh)
    [pscustomobject]@{
        IsInstallStateBacked = `$true; IsOobe = `$false; IsUpgrade = `$env:ATLAS_TEST_MODE -cne 'Fresh'
        Mode = `$env:ATLAS_TEST_MODE; InteractiveUserSid = 'S-1-5-21-1000-2000-3000-1001'
        TargetVersion = '0.6.0'; TransactionId = '$script:TransactionId'
    }
}
function Invoke-AtlasAsUser {
    param(`$FilePath, `$Arguments, `$TimeoutSeconds)
    Add-Content -LiteralPath `$env:ATLAS_TEST_CALL_LOG -Value "AsUser:`$Arguments"
    return 0
}
"@
            return [pscustomobject]@{ Script = Join-Path $tasks 'Invoke-AtlasInstallingUserSetup.ps1'; CallLog = Join-Path $root 'calls.log' }
        }

        function Invoke-InstallingUserSetupFixture {
            param($Fixture, [string]$Mode)
            $previousPreference = $ErrorActionPreference
            try {
                $env:ATLAS_TEST_CALL_LOG = $Fixture.CallLog
                $env:ATLAS_TEST_MODE = $Mode
                $ErrorActionPreference = 'Continue'
                $output = & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Fixture.Script 2>&1
                [pscustomobject]@{
                    ExitCode = $LASTEXITCODE
                    Output   = ($output | Out-String)
                    Calls    = @(if (Test-Path -LiteralPath $Fixture.CallLog) { Get-Content -LiteralPath $Fixture.CallLog })
                }
            }
            finally {
                Remove-Item -Path Env:\ATLAS_TEST_CALL_LOG, Env:\ATLAS_TEST_MODE -ErrorAction SilentlyContinue
                $ErrorActionPreference = $previousPreference
            }
        }
    }

    It 'stamps every account with a reinstall''s version and transaction before setting the installing user up' {
        $result = Invoke-InstallingUserSetupFixture -Fixture (New-InstallingUserSetupFixture) -Mode 'Reapply'

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Calls | Should -HaveCount 2
        $result.Calls[0] | Should -BeExactly "Stamp:0.6.0+$script:TransactionId"
        $result.Calls[1] | Should -BeLike 'AsUser:*\Entry\Update-AtlasUser.ps1*-ExpectedUserSid*'
    }

    It 'leaves the stamps to LegacyChoices on <Mode>' -ForEach @(
        @{ Mode = 'Upgrade' }
        @{ Mode = 'Rebase' }
        @{ Mode = 'Fresh' }
    ) {
        $result = Invoke-InstallingUserSetupFixture -Fixture (New-InstallingUserSetupFixture) -Mode $Mode

        $result.ExitCode | Should -Be 0 -Because $result.Output
        @($result.Calls -like 'Stamp:*') | Should -HaveCount 0
        @($result.Calls -like 'AsUser:*') | Should -HaveCount 1
    }

    It 'stamps an update with its version before LegacyChoices reads the old choices' {
        $path = Join-Path $script:AtlasTestScriptsRoot 'Install\Tasks\Import-AtlasLegacyChoices.ps1'
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        $calls = @($ast.EndBlock.Statements | ForEach-Object {
                $_.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true)
            })
        $stamp = @($calls | Where-Object { $_.GetCommandName() -ceq 'Set-AtlasUpgradeUserStamp' })
        $import = @($calls | Where-Object { $_.GetCommandName() -ceq 'Import-AtlasLegacyChoices' })
        $helper = @($calls | Where-Object {
                $_.InvocationOperator -eq [Management.Automation.Language.TokenKind]::Dot -and $_.Extent.Text -like '*Set-AtlasUpgradeUsers.ps1*'
            })

        $stamp | Should -HaveCount 1
        $stamp[0].Extent.Text | Should -BeLike '*-Value*$context.TargetVersion*'
        $import | Should -HaveCount 1
        $stamp[0].Extent.StartOffset | Should -BeLessThan $import[0].Extent.StartOffset
        $helper | Should -HaveCount 1
        $ast.Extent.Text | Should -Not -Match 'SOFTWARE\\AtlasOS\\UpgradeUsers' -Because 'the stamp helper owns that key'
    }
}
