BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PackageHelperPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\ProcessExplorer-Package.ps1'
    $script:TogglePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Toggles\Advanced\ProcessExplorer.ps1'
    $script:UpgradeStopPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Tasks\Stop-ProcessExplorerUpgrade.ps1'
    . $script:PackageHelperPath
}

Describe 'Process Explorer package identity' {
    It 'selects the reviewed native binary for <Architecture>' -TestCases @(
        @{
            Architecture = 'X86'
            Name = 'procexp.exe'
            Hash = 'b29917ce089e46bc6238e3e9e20596599bcbe7aa10d4f688bc32db94d6e4dae8'
        }
        @{
            Architecture = 'X64'
            Name = 'procexp64.exe'
            Hash = '8404b6cfad9d998b10d2df6073e1275b7744c0416982bdc5cb7ef5b74348333d'
        }
        @{
            Architecture = 'ARM64'
            Name = 'procexp64a.exe'
            Hash = 'f2a763d4ad679a2e585ff95c792b476c749832a1b6ba1f7521f387ff4e943f56'
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

Describe 'Process Explorer ownership state' {
    It 'records only package identity and the pcw value Atlas changed' {
        $state = ConvertTo-AtlasProcessExplorerState -Architecture X64 `
            -InstalledBinarySha256 ('a' * 64) -PcwStart 2 `
            -DisablePcw $true -ExistingState $null

        $state.SchemaVersion | Should -Be 1
        $state.PackageVersion | Should -Be '17.12'
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
{"SchemaVersion":1,"PackageVersion":"17.12","Architecture":"X64","InstalledBinarySha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","PcwChanged":true,"PcwPriorStart":null}
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
    BeforeEach {
        $internalPath = Join-Path $TestDrive 'Scripts\Internal'
        [void](New-Item $internalPath -ItemType Directory -Force)
        $fakeHelper = Join-Path $internalPath 'ProcessExplorer-Package.ps1'
        Set-Content -LiteralPath $fakeHelper -Encoding Ascii -Value @'
function Install-AtlasProcessExplorerPackage {
    param([switch]$DisablePcw)
    $script:AtlasProcessExplorerTestCall = "Install:$([bool]$DisablePcw)"
}
function Uninstall-AtlasProcessExplorerPackage {
    $script:AtlasProcessExplorerTestCall = 'Uninstall'
}
function Write-AtlasProcessExplorerUserPreference {
    $script:AtlasProcessExplorerTestCall = 'UserPreference'
}
'@
        $script:ToggleContext = [pscustomobject]@{
            ScriptsPath = (Split-Path -Parent $internalPath)
            Silent = $true
        }
        $script:Definition = . $script:TogglePath
        $script:AtlasProcessExplorerTestCall = $null
    }

    AfterEach {
        Remove-Variable AtlasProcessExplorerTestCall -Scope Script -ErrorAction SilentlyContinue
    }

    It 'passes the silent pcw choice to the machine package operation' {
        & $Definition.States.Install.MachineAction $ToggleContext
        $script:AtlasProcessExplorerTestCall | Should -Be 'Install:True'
    }

    It 'sets OneInstance in the initiating user action' {
        & $Definition.States.Install.UserAction $ToggleContext
        $script:AtlasProcessExplorerTestCall | Should -Be 'UserPreference'
    }

    It 'delegates uninstall to the machine package operation' {
        & $Definition.States.Uninstall.MachineAction $ToggleContext
        $script:AtlasProcessExplorerTestCall | Should -Be 'Uninstall'
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

    It 'preserves an enabled replay preference across teardown' {
        . $script:UpgradeStopPath

        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq $script:UpgradeStatePath -and
            $Name -eq 'state' -and $PropertyType -eq 'DWord' -and $Value -eq 1
        }
    }

}
