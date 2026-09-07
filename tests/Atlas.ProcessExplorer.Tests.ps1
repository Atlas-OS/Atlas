BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PackageHelperPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\ProcessExplorer-Package.ps1'
    $script:UpgradeStopPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Install\Tasks\Stop-ProcessExplorerUpgrade.ps1'
    . $script:PackageHelperPath
}

Describe 'Process Explorer package identity' {
    It 'selects the reviewed native binary for <Architecture>' -TestCases @(
        @{
            Architecture = 'X86'
            Name = 'procexp.exe'
            Hash = '6a26da49b2de1c70705918f8805192f7dfe43234c59a06a55145b35d46a8e660'
        }
        @{
            Architecture = 'X64'
            Name = 'procexp64.exe'
            Hash = '917b5d71f732bf5b5423cd212c004b2433a63e9dfe02a2a27ea421252c815690'
        }
        @{
            Architecture = 'ARM64'
            Name = 'procexp64a.exe'
            Hash = '3373e0461a8421c1c92c5b07c8b258ba09a722ebb1f082fd75f43c40ed8ef839'
        }
    ) {
        param($Architecture, $Name, $Hash)

        $binary = Get-AtlasProcessExplorerBinary -Architecture $Architecture
        $binary.ArchiveName | Should -Be $Name
        $binary.Sha256 | Should -Be $Hash
    }

    It 'rejects an unsupported native architecture' {
        { Get-AtlasProcessExplorerBinary -Architecture 'RISCV64' } |
            Should -Throw "*does not support native architecture 'RISCV64'*"
    }
}

Describe 'Process Explorer boot driver protection' {
    It 'rejects disabling pcw at startup type <Start> before publishing any package changes' -TestCases @(
        @{ Start = 0 }
        @{ Start = 1 }
    ) {
        param($Start)
        $script:PcwStart = $Start
        Mock Get-AtlasProcessExplorerLayout {
            [pscustomobject]@{
                StatePath = 'TestDrive:\missing.json'
                IfeoPath = 'TestRegistry:\unused'
                ShortcutPath = 'TestDrive:\missing.lnk'
                PcwPath = 'TestRegistry:\pcw'
            }
        }
        Mock Read-AtlasProcessExplorerState { $null }
        Mock Get-AtlasProcessExplorerDebugger { [pscustomobject]@{ Exists = $false } }
        Mock Get-AtlasProcessExplorerShortcutTarget { $null }
        Mock Get-AtlasProcessExplorerPcwStart { $script:PcwStart }
        Mock Assert-AtlasProcessExplorerInstallOwnership {}
        Mock New-AtlasProtectedStagingDirectory {}
        Mock Invoke-AtlasProcessExplorerPcwStartUpdate {}

        { Install-AtlasProcessExplorerPackageCore -DisablePcw $true } |
            Should -Throw '*boot or system-start driver*'
        Should -Invoke Assert-AtlasProcessExplorerInstallOwnership -Times 0 -Exactly
        Should -Invoke New-AtlasProtectedStagingDirectory -Times 0 -Exactly
        Should -Invoke Invoke-AtlasProcessExplorerPcwStartUpdate -Times 0 -Exactly
    }
}

Describe 'Process Explorer registry provider integration' {
    It 'writes, replaces and removes debugger values without changing unrelated values' {
        # Use Pester's isolated HKCU registry; never touch the real machine IFEO.
        $path = 'TestRegistry:\ProcessExplorerDebugger'
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -LiteralPath $path -Name 'Unrelated' -Value 7 -PropertyType DWord | Out-Null
        foreach ($kind in @('String', 'ExpandString')) {
            $value = '%SystemRoot%\AtlasModules\Apps\ProcessExplorer\procexp.exe'
            Write-AtlasProcessExplorerDebugger -IfeoPath $path -State ([pscustomobject]@{
                Exists = $true; Value = $value; Kind = $kind
            })
            $actual = Get-AtlasProcessExplorerDebugger -IfeoPath $path
            $actual.Exists | Should -BeTrue
            $actual.Value | Should -BeExactly $value
            $actual.Kind | Should -Be $kind
        }
        $absent = [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }
        Write-AtlasProcessExplorerDebugger -IfeoPath $path -State $absent
        Write-AtlasProcessExplorerDebugger -IfeoPath $path -State $absent
        (Get-AtlasProcessExplorerDebugger -IfeoPath $path).Exists | Should -BeFalse
        (Get-ItemProperty -LiteralPath $path).Unrelated | Should -Be 7
    }
}

Describe 'Process Explorer ownership state' {
    It 'records only package identity and the pcw value Atlas changed' {
        $state = ConvertTo-AtlasProcessExplorerState -Architecture X64 `
            -InstalledBinarySha256 ('a' * 64) -PcwStart 2 `
            -DisablePcw $true -ExistingState $null

        $state.SchemaVersion | Should -Be 1
        $state.PackageVersion | Should -Be '17.13'
        $state.PcwChanged | Should -BeTrue
        $state.PcwPriorStart | Should -Be 2
        @($state.PSObject.Properties.Name) | Should -Be @(
            'SchemaVersion', 'PackageVersion', 'Architecture',
            'InstalledBinarySha256', 'PcwChanged', 'PcwPriorStart'
        )
    }

    It 'preserves the original pcw value across reinstall' {
        $existing = [pscustomobject]@{ PcwChanged = $true; PcwPriorStart = 3 }
        $state = ConvertTo-AtlasProcessExplorerState -Architecture X64 `
            -InstalledBinarySha256 ('b' * 64) -PcwStart 4 `
            -DisablePcw $true -ExistingState $existing

        $state.PcwChanged | Should -BeTrue
        $state.PcwPriorStart | Should -Be 3
    }

    It 'round-trips the bounded JSON record' {
        $statePath = Join-Path $TestDrive 'ProcessExplorer\Atlas.ProcessExplorer.State.json'
        $state = ConvertTo-AtlasProcessExplorerState -Architecture ARM64 `
            -InstalledBinarySha256 ('c' * 64) -PcwStart 4 `
            -DisablePcw $false -ExistingState $null

        Write-AtlasProcessExplorerState -StatePath $statePath -State $state
        $actual = Read-AtlasProcessExplorerState -StatePath $statePath

        $actual.Architecture | Should -Be 'ARM64'
        $actual.InstalledBinarySha256 | Should -Be ('c' * 64)
        $actual.PcwChanged | Should -BeFalse
        $actual.PcwPriorStart | Should -BeNullOrEmpty
        @(Get-ChildItem (Split-Path -Parent $statePath) -Force).Count | Should -Be 1
    }

    It 'rejects state that claims pcw ownership without a prior value' {
        $statePath = Join-Path $TestDrive 'invalid.json'
        [IO.File]::WriteAllText($statePath, @'
{"SchemaVersion":1,"PackageVersion":"17.13","Architecture":"X64","InstalledBinarySha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","PcwChanged":true,"PcwPriorStart":null}
'@)

        { Read-AtlasProcessExplorerState -StatePath $statePath } |
            Should -Throw '*pcw ownership state is invalid*'
    }
}

Describe 'Process Explorer file publication' {
    It 'publishes checked bytes without leaving transaction artifacts' {
        $source = Join-Path $TestDrive 'source.exe'
        $destination = Join-Path $TestDrive 'package\procexp.exe'
        [IO.File]::WriteAllText($source, 'reviewed-binary')
        [void](New-Item (Split-Path -Parent $destination) -ItemType Directory -Force)
        [IO.File]::WriteAllText($destination, 'old-binary')
        $hash = Get-AtlasProcessExplorerFileSha256 -Path $source

        Copy-AtlasProcessExplorerFile -Source $source -Destination $destination `
            -ExpectedSha256 $hash

        [IO.File]::ReadAllText($destination) | Should -Be 'reviewed-binary'
        @(Get-ChildItem (Split-Path -Parent $destination) -Filter '*.new-*').Count |
            Should -Be 0
    }

    It 'leaves the working binary untouched when copied bytes fail validation' {
        $source = Join-Path $TestDrive 'bad-source.exe'
        $destination = Join-Path $TestDrive 'existing\procexp.exe'
        [void](New-Item (Split-Path -Parent $destination) -ItemType Directory -Force)
        [IO.File]::WriteAllText($source, 'unexpected')
        [IO.File]::WriteAllText($destination, 'working')

        { Copy-AtlasProcessExplorerFile -Source $source -Destination $destination `
                -ExpectedSha256 ('0' * 64) } | Should -Throw '*failed its SHA-256 check*'
        [IO.File]::ReadAllText($destination) | Should -Be 'working'
    }
}

Describe 'Process Explorer integration ownership' {
    BeforeEach {
        $script:Layout = [pscustomobject]@{
            WindowsPath = 'C:\Windows'
            PackagePath = Join-Path $TestDrive 'ProcessExplorer'
            BinaryPath = Join-Path $TestDrive 'ProcessExplorer\procexp.exe'
            StatePath = Join-Path $TestDrive 'ProcessExplorer\Atlas.ProcessExplorer.State.json'
            ShortcutPath = Join-Path $TestDrive 'Process Explorer.lnk'
            IfeoPath = 'HKLM:\Test\taskmgr.exe'
            PcwPath = 'HKLM:\Test\pcw'
        }
        Remove-Item -LiteralPath $script:Layout.PackagePath -Recurse -Force `
            -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:Layout.ShortcutPath -Force `
            -ErrorAction SilentlyContinue
    }

    It 'refuses a foreign Task Manager debugger before mutation' {
        $debugger = [pscustomobject]@{
            Exists = $true
            Value = 'C:\Other\task-manager.exe'
            Kind = 'String'
        }

        { Assert-AtlasProcessExplorerInstallOwnership -Layout $Layout `
                -ExistingState $null -Debugger $debugger -ShortcutTarget $null `
                -PcwStart 3 -ExpectedBinarySha256 ('0' * 64) } |
            Should -Throw '*will not replace another Task Manager Debugger*'
    }

    It 'refuses to replace a foreign common Start menu shortcut' {
        [IO.File]::WriteAllText($Layout.ShortcutPath, 'foreign-link')
        $debugger = [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }

        { Assert-AtlasProcessExplorerInstallOwnership -Layout $Layout `
                -ExistingState $null -Debugger $debugger `
                -ShortcutTarget 'C:\Other\tool.exe' -PcwStart 3 `
                -ExpectedBinarySha256 ('0' * 64) } |
            Should -Throw '*will not replace the existing Start menu shortcut*'
    }

    It 'accepts the exact new pin when state refresh was interrupted' {
        [void](New-Item $Layout.PackagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText($Layout.BinaryPath, 'new-reviewed-binary')
        $newHash = Get-AtlasProcessExplorerFileSha256 -Path $Layout.BinaryPath
        $existing = [pscustomobject]@{
            PcwChanged = $false
            PcwPriorStart = $null
            InstalledBinarySha256 = ('1' * 64)
        }
        $debugger = [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }

        {
            Assert-AtlasProcessExplorerInstallOwnership -Layout $Layout `
                -ExistingState $existing -Debugger $debugger -ShortcutTarget $null `
                -PcwStart 3 -ExpectedBinarySha256 $newHash
        } | Should -Not -Throw
    }

    It 'removes only exact Atlas integrations and restores owned pcw state' {
        [IO.File]::WriteAllText($Layout.ShortcutPath, 'atlas-link')
        $state = [pscustomobject]@{ PcwChanged = $true; PcwPriorStart = 2 }
        Mock Get-AtlasProcessExplorerDebugger {
            [pscustomobject]@{ Exists = $true; Value = $script:Layout.BinaryPath; Kind = 'String' }
        }
        Mock Write-AtlasProcessExplorerDebugger {}
        Mock Get-AtlasProcessExplorerShortcutTarget { $script:Layout.BinaryPath }
        Mock Get-AtlasProcessExplorerPcwStart { 4 }
        Mock Invoke-AtlasProcessExplorerPcwStartUpdate {}

        Restore-AtlasProcessExplorerIntegration -Layout $Layout -State $state

        [IO.File]::Exists($Layout.ShortcutPath) | Should -BeFalse
        Should -Invoke Write-AtlasProcessExplorerDebugger -Times 1 -Exactly
        Should -Invoke Invoke-AtlasProcessExplorerPcwStartUpdate -Times 1 -Exactly `
            -ParameterFilter { $Start -eq 2 }
    }

    It 'leaves newer foreign integration values untouched' {
        [IO.File]::WriteAllText($Layout.ShortcutPath, 'custom-link')
        $state = [pscustomobject]@{ PcwChanged = $true; PcwPriorStart = 2 }
        Mock Get-AtlasProcessExplorerDebugger {
            [pscustomobject]@{ Exists = $true; Value = 'C:\Other\tool.exe'; Kind = 'String' }
        }
        Mock Write-AtlasProcessExplorerDebugger {}
        Mock Get-AtlasProcessExplorerShortcutTarget { 'C:\Other\tool.exe' }
        Mock Get-AtlasProcessExplorerPcwStart { 3 }
        Mock Invoke-AtlasProcessExplorerPcwStartUpdate {}

        Restore-AtlasProcessExplorerIntegration -Layout $Layout -State $state

        [IO.File]::Exists($Layout.ShortcutPath) | Should -BeTrue
        Should -Invoke Write-AtlasProcessExplorerDebugger -Times 0 -Exactly
        Should -Invoke Invoke-AtlasProcessExplorerPcwStartUpdate -Times 0 -Exactly
    }

    It 'retains the package when dependent restoration fails' {
        [void](New-Item $Layout.PackagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText($Layout.BinaryPath, 'working-package')
        $hash = Get-AtlasProcessExplorerFileSha256 -Path $Layout.BinaryPath
        $state = ConvertTo-AtlasProcessExplorerState -Architecture X64 `
            -InstalledBinarySha256 $hash -PcwStart 3 `
            -DisablePcw $false -ExistingState $null
        Write-AtlasProcessExplorerState -StatePath $Layout.StatePath -State $state
        Mock Get-AtlasProcessExplorerLayout { $script:Layout }
        Mock Restore-AtlasProcessExplorerIntegration { throw 'restore failed' }

        { Uninstall-AtlasProcessExplorerPackageCore } | Should -Throw '*restore failed*'
        [IO.File]::Exists($Layout.BinaryPath) | Should -BeTrue
        [IO.File]::Exists($Layout.StatePath) | Should -BeTrue
    }
}

Describe 'Process Explorer toggle caller' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        $modulesRoot = Join-Path $script:RepoRoot 'playbook\Executables\AtlasModules\Scripts\Modules'
        Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:Definition = Get-AtlasToggleDefinition -Name ProcessExplorer `
            -TogglesRoot (Join-Path $script:RepoRoot 'playbook\Executables\AtlasModules\Toggles')

        # The companion dot-sources ProcessExplorer-Package.ps1 from $Toggle.OperationsPath;
        # the fake records which package operation ran beside itself.
        $script:OperationsPath = Join-Path $TestDrive 'ToggleOperations'
        [void](New-Item $script:OperationsPath -ItemType Directory -Force)
        $script:CallRecord = Join-Path $script:OperationsPath 'call.txt'
        Set-Content -LiteralPath (Join-Path $script:OperationsPath 'ProcessExplorer-Package.ps1') `
            -Encoding Ascii -Value @'
function Install-AtlasProcessExplorerPackage {
    param([switch]$DisablePcw)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'call.txt'), "Install:$([bool]$DisablePcw)")
}
function Get-AtlasProcessExplorerLayout {
    [pscustomobject]@{ PcwPath = 'TestRegistry:\pcw' }
}
function Get-AtlasProcessExplorerPcwStart { 0 }
function Uninstall-AtlasProcessExplorerPackage {
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'call.txt'), 'Uninstall')
}
function Write-AtlasProcessExplorerUserPreference {
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'call.txt'), 'UserPreference')
}
'@
        $script:ToggleContext = [pscustomobject]@{
            Name              = 'ProcessExplorer'
            State             = 'Enable'
            StateValue        = 1
            Silent            = $true
            JustContext       = $false
            NoExplorerRestart = $false
            ResetServices     = $false
            StateRoot         = 'HKCU:\Software\AtlasRewriteTest\Services'
            LauncherPath      = $null
            WinDir            = $env:SystemRoot
            AtlasModulesPath  = $TestDrive
            ScriptsPath       = (Join-Path $TestDrive 'Scripts')
            ModulesPath       = (Join-Path $TestDrive 'Scripts\Modules')
            OperationsPath    = $script:OperationsPath
            WindowsBuild      = 26100
        }

        function Invoke-ProcessExplorerFunction {
            param([Parameter(Mandatory = $true)][string]$FunctionName)

            InModuleScope Atlas.Toggles {
                Invoke-AtlasToggleFunction -Definition $d -FunctionName $f -Toggle $t -Label 'test'
            } -Parameters @{ d = $script:Definition; f = $FunctionName; t = $script:ToggleContext }
        }
    }

    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Remove-Item -LiteralPath $script:CallRecord -Force -ErrorAction SilentlyContinue
    }

    It 'declares Enable as split machine and user work and Disable as machine work' {
        $install = $script:Definition.States['Enable']
        $uninstall = $script:Definition.States['Disable']

        $install['MachineAction'] | Should -BeExactly 'Install-AtlasProcessExplorer'
        $install['UserAction'] | Should -BeExactly 'Set-AtlasProcessExplorerUserPreference'
        $install['StateValue'] | Should -Be 1
        $uninstall['MachineAction'] | Should -BeExactly 'Uninstall-AtlasProcessExplorer'
        $uninstall.Contains('UserAction') | Should -BeFalse
        $uninstall['StateValue'] | Should -Be 0

        $installWork = Get-AtlasToggleStateWork -Definition $script:Definition -StateEntry $install
        $installWork.Machine | Should -BeTrue
        $installWork.User | Should -BeTrue
        $uninstallWork = Get-AtlasToggleStateWork -Definition $script:Definition -StateEntry $uninstall
        $uninstallWork.Machine | Should -BeTrue
        $uninstallWork.User | Should -BeFalse
    }

    It 'does not invent consent to disable pcw during silent replay' {
        Invoke-ProcessExplorerFunction -FunctionName $script:Definition.States['Enable']['MachineAction']
        Get-Content -LiteralPath $script:CallRecord | Should -Be 'Install:False'
    }

    It 'sets OneInstance in the initiating user action' {
        Invoke-ProcessExplorerFunction -FunctionName $script:Definition.States['Enable']['UserAction']
        Get-Content -LiteralPath $script:CallRecord | Should -Be 'UserPreference'
    }

    It 'installs interactively without offering to disable a boot driver' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { throw 'No driver prompt expected.' }
        $script:ToggleContext.Silent = $false
        try {
            Invoke-ProcessExplorerFunction -FunctionName $script:Definition.States['Enable']['MachineAction']
            Get-Content -LiteralPath $script:CallRecord | Should -Be 'Install:False'
            Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
        }
        finally { $script:ToggleContext.Silent = $true }
    }

    It 'delegates uninstall to the machine package operation' {
        Invoke-ProcessExplorerFunction -FunctionName $script:Definition.States['Disable']['MachineAction']
        Get-Content -LiteralPath $script:CallRecord | Should -Be 'Uninstall'
    }

    It 'fails clearly when the package helper is missing from the Operations folder' {
        $missing = [pscustomobject]@{
            Name           = 'ProcessExplorer'
            State          = 'Enable'
            Silent         = $true
            OperationsPath = (Join-Path $TestDrive 'no-operations')
        }

        {
            InModuleScope Atlas.Toggles {
                Invoke-AtlasToggleFunction -Definition $d -FunctionName 'Install-AtlasProcessExplorer' -Toggle $t -Label 'test'
            } -Parameters @{ d = $script:Definition; t = $missing }
        } | Should -Throw '*package helper is missing*'
        $script:CallRecord | Should -Not -Exist
    }
}

Describe 'Process Explorer upgrade teardown' {
    BeforeEach {
        $script:UpgradeStateValue = 1
        $script:UpgradeStatePath = 'HKLM:\SOFTWARE\AtlasOS\Services\ProcessExplorer'
        $script:UpgradeUninstallPath = Join-Path `
            ([Environment]::GetFolderPath('Windows')) `
            'AtlasDesktop\6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
        $script:FakeUpgradeProcess = [pscustomobject]@{ ExitCode = 0 }
        $script:FakeUpgradeProcess | Add-Member -MemberType ScriptMethod `
            -Name WaitForExit -Value { return $true }

        Mock Test-Path {
            return $LiteralPath -in @($script:UpgradeStatePath, $script:UpgradeUninstallPath)
        }
        Mock Get-Item {
            $key = [pscustomobject]@{ StateValue = $script:UpgradeStateValue }
            $key | Add-Member -MemberType ScriptMethod -Name GetValueNames `
                -Value { return @('state') }
            $key | Add-Member -MemberType ScriptMethod -Name GetValueKind `
                -Value { return [Microsoft.Win32.RegistryValueKind]::DWord }
            $key | Add-Member -MemberType ScriptMethod -Name GetValue `
                -Value { return $this.StateValue }
            return $key
        } -ParameterFilter { $LiteralPath -eq $script:UpgradeStatePath }
        Mock Start-Process { return $script:FakeUpgradeProcess }
        Mock Get-Process { return @() }
        Mock Get-ItemProperty { return $null }
        Mock New-ItemProperty {}
        Mock New-Item {}
    }

    It 'uses the fixed staged cleanup helper instead of the installed desktop launcher' {
        . $script:UpgradeStopPath
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*WindowsPowerShell*v1.0*powershell.exe' -and
            ($ArgumentList -join ' ') -like '*Invoke-AtlasProcessExplorerCleanup.ps1*' -and
            $ArgumentList -contains '-NonInteractive'
        }
        Should -Invoke Start-Process -Times 0 -Exactly -ParameterFilter { $FilePath -like '*.cmd' }
    }

    It 'blocks payload removal after cleanup failure and retains the enabled choice' {
        $script:FakeUpgradeProcess.ExitCode = 7
        { . $script:UpgradeStopPath } | Should -Throw '*cleanup failed with exit code 7*'
        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'state' -and $Value -eq 1 }
        Should -Invoke Start-Process -Times 0 -Exactly -ParameterFilter { $FilePath -like '*taskkill.exe' }
    }

    It 'preserves an enabled replay preference across teardown' {
        . $script:UpgradeStopPath

        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq $script:UpgradeStatePath -and
            $Name -eq 'state' -and $PropertyType -eq 'DWord' -and $Value -eq 1
        }
    }

}
