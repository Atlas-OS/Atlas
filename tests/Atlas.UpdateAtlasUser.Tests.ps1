BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'
    $script:CurrentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $script:SandboxSubKey = 'Software\AtlasRewriteTestUpdateAtlasUser'

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
        Set-ItemProperty -LiteralPath $fixture.EligiblePath -Name $script:CurrentSid -Value 1 -Type DWord
        Set-ItemProperty -LiteralPath $fixture.MarkerPath -Name UpgradeVersion -Value '0.5.0' -Type String

        $result = Invoke-UpdateUserFixture -Fixture $fixture

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Calls | Should -Contain "Manifest:$(Join-Path $fixture.Modules 'Scripts\Tweaks\tweaks.manifest.psd1')"
        @($result.Calls -like 'Category:*') | Should -Be @('Category:privacy:CurrentUser', 'Category:qol:CurrentUser')
        $result.Calls | Should -Contain 'ToggleReapply'
        (Get-ItemProperty -LiteralPath $fixture.MarkerPath).UpgradeVersion | Should -BeExactly '0.6.0'
    }

    It 'pins module resolution before a user module can shadow a core cmdlet' {
        $fixture = New-UpdateUserFixture
        $result = Invoke-UpdateUserFixture -Fixture $fixture -Arguments @('-ExpectedUserSid', $script:CurrentSid)

        $result.Output | Should -Not -Match 'SHADOWED'
        $result.Calls | Should -Contain 'Join-Path:Microsoft.PowerShell.Management'
    }
}
