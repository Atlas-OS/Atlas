BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Atlas.Registry.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:testSubPath = 'Software\AtlasRewriteTest'
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Resolve-AtlasRegistryPath' {
    Context 'HKCU redirection' {
        It 'redirects <PathStyle> to the active user hive and produces the default-hive mirror' -TestCases @(
            @{ PathStyle = 'drive notation'; Path = 'HKCU:\Software\X' }
            @{ PathStyle = 'bare notation'; Path = 'HKCU\Software\X' }
        ) {
            $result = Resolve-AtlasRegistryPath -Path $Path -ActiveUserSid 'S-1-5-21-1-2-3-1001' -RedirectHkcu
            $result.Primary | Should -Be 'Registry::HKEY_USERS\S-1-5-21-1-2-3-1001\Software\X'
            $result.Mirror | Should -Be 'Registry::HKEY_USERS\AME_UserHive_Default\Software\X'
            $result.HkcuSubPath | Should -Be 'Software\X'
            $result.IsHkcu | Should -BeTrue
        }

        It 'keeps HKCU ambient when not redirecting' {
            $result = Resolve-AtlasRegistryPath -Path 'HKCU:\Software\X'
            $result.Primary | Should -Be 'Registry::HKEY_CURRENT_USER\Software\X'
            $result.Mirror | Should -BeNullOrEmpty
            $result.HkcuSubPath | Should -BeNullOrEmpty
            $result.IsHkcu | Should -BeTrue
        }

        It 'throws when redirecting without an active user SID' {
            { Resolve-AtlasRegistryPath -Path 'HKCU:\Software\X' -RedirectHkcu } | Should -Throw '*active user SID*'
        }
    }

    Context 'other roots pass through' {
        It 'passes HKLM through untouched even when redirecting' {
            $result = Resolve-AtlasRegistryPath -Path 'HKLM:\SOFTWARE\Test' -ActiveUserSid 'S-1-5-21-1-2-3-1001' -RedirectHkcu
            $result.Primary | Should -Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Test'
            $result.Mirror | Should -BeNullOrEmpty
            $result.HkcuSubPath | Should -BeNullOrEmpty
            $result.IsHkcu | Should -BeFalse
        }

        It 'normalizes HKU paths to the Registry provider' {
            $result = Resolve-AtlasRegistryPath -Path 'HKU\S-1-5-18\Software'
            $result.Primary | Should -Be 'Registry::HKEY_USERS\S-1-5-18\Software'
        }

        It 'accepts Registry:: provider notation' {
            $result = Resolve-AtlasRegistryPath -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Test'
            $result.Primary | Should -Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Test'
        }

        It 'throws on an unsupported root' {
            { Resolve-AtlasRegistryPath -Path 'HKXX:\Software' } | Should -Throw '*Unsupported registry root*'
        }
    }
}

Describe 'Set-AtlasRegistryValue and Remove-AtlasRegistryValue' {
    BeforeAll {
        # Unelevated test runs never hit the TrustedInstaller redirect branch, so the
        # ambient HKCU scratch key is exactly what gets written.
        $script:valuesKeyPath = "$script:testRoot\Values"
    }

    It 'writes a String value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'StringValue' -Type String -Data 'hello'
        $key = Get-Item -Path $script:valuesKeyPath
        $key.GetValue('StringValue') | Should -Be 'hello'
        $key.GetValueKind('StringValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
    }

    It 'writes an ExpandString value without expanding it' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'ExpandValue' -Type ExpandString -Data '%windir%\test'
        (Get-Item -Path $script:valuesKeyPath).GetValueKind('ExpandValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::ExpandString)
    }

    It 'writes a DWord value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'DwordValue' -Type DWord -Data 1
        $key = Get-Item -Path $script:valuesKeyPath
        $key.GetValue('DwordValue') | Should -Be 1
        $key.GetValueKind('DwordValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
    }

    It 'writes a DWord value above Int32.MaxValue (e.g. 0xFFFFFFFF)' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'DwordMax' -Type DWord -Data 4294967295
        (Get-Item -Path $script:valuesKeyPath).GetValue('DwordMax') | Should -Be (-1)
    }

    It 'writes a QWord value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'QwordValue' -Type QWord -Data 8589934592
        $key = Get-Item -Path $script:valuesKeyPath
        $key.GetValue('QwordValue') | Should -Be 8589934592
        $key.GetValueKind('QwordValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::QWord)
    }

    It 'writes a Binary value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'BinaryValue' -Type Binary -Data @(1, 2, 3)
        $key = Get-Item -Path $script:valuesKeyPath
        @($key.GetValue('BinaryValue')) | Should -Be @(1, 2, 3)
        $key.GetValueKind('BinaryValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::Binary)
    }

    It 'writes a MultiString value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'MultiValue' -Type MultiString -Data @('one', 'two')
        $key = Get-Item -Path $script:valuesKeyPath
        @($key.GetValue('MultiValue')) | Should -Be @('one', 'two')
        $key.GetValueKind('MultiValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::MultiString)
    }

    It 'writes a REG_NONE value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'NoneValue' -Type None
        (Get-Item -Path $script:valuesKeyPath).GetValueKind('NoneValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::None)
    }

    It 'creates missing intermediate keys' {
        Set-AtlasRegistryValue -Path "$script:testRoot\Deep\Nested\Key" -Name 'Value' -Type DWord -Data 7
        (Get-Item -Path "$script:testRoot\Deep\Nested\Key").GetValue('Value') | Should -Be 7
    }

    It 'writes the default value when Name is empty (old-context-menu contract)' {
        # The OldContextMenu toggle requires setting a key's DEFAULT value to ''.
        Set-AtlasRegistryValue -Path "$script:testRoot\DefaultValue" -Name '' -Type String -Data ''
        $key = Get-Item -Path "$script:testRoot\DefaultValue"
        $key.GetValue('') | Should -Be ''
        $key.GetValueKind('') | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
    }

    It 'throws when a data-carrying type has no data' {
        { Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'NoData' -Type DWord } | Should -Throw '*no data*'
    }

    It 'removes an existing value' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'ToRemove' -Type String -Data 'x'
        Remove-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'ToRemove'
        (Get-Item -Path $script:valuesKeyPath).GetValue('ToRemove', $null) | Should -BeNullOrEmpty
    }

    It 'does not throw when removing a missing value' {
        { Remove-AtlasRegistryValue -Path $script:valuesKeyPath -Name 'NeverExisted' } | Should -Not -Throw
    }

    It 'does not throw when removing a value from a missing key' {
        { Remove-AtlasRegistryValue -Path "$script:testRoot\NoSuchKey" -Name 'Value' } | Should -Not -Throw
    }
}

Describe 'New-AtlasRegistryKey and Remove-AtlasRegistryKey' {
    It 'creates a key with missing parents' {
        New-AtlasRegistryKey -Path "$script:testRoot\Keys\Child"
        Test-Path -Path "$script:testRoot\Keys\Child" | Should -BeTrue
    }

    It 'does not throw when the key already exists' {
        { New-AtlasRegistryKey -Path "$script:testRoot\Keys\Child" } | Should -Not -Throw
    }

    It 'removes a key tree recursively' {
        New-AtlasRegistryKey -Path "$script:testRoot\Keys\Tree\Deeper"
        Remove-AtlasRegistryKey -Path "$script:testRoot\Keys\Tree"
        Test-Path -Path "$script:testRoot\Keys\Tree" | Should -BeFalse
    }

    It 'does not throw when removing a missing key' {
        { Remove-AtlasRegistryKey -Path "$script:testRoot\Keys\Missing" } | Should -Not -Throw
    }
}

Describe 'Invoke-AtlasRegistryEntries' {
    BeforeEach {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith {
            [pscustomobject]@{
                IsArm64  = $false
                LogsPath = Join-Path -Path $TestDrive -ChildPath 'Logs'
            }
        }
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Registry
    }

    It 'applies entries and skips those gated to the other architecture' {
        Invoke-AtlasRegistryEntries -Entries @(
            @{ Path = "$script:testRoot\Entries"; Name = 'Ungated'; Type = 'DWord'; Data = 1 }
            @{ Path = "$script:testRoot\Entries"; Name = 'X64Only'; Type = 'DWord'; Data = 2; Arch = 'X64' }
            @{ Path = "$script:testRoot\Entries"; Name = 'Arm64Only'; Type = 'DWord'; Data = 3; Arch = 'ARM64' }
        )

        $key = Get-Item -Path "$script:testRoot\Entries"
        $key.GetValue('Ungated') | Should -Be 1
        $key.GetValue('X64Only') | Should -Be 2
        $key.GetValue('Arm64Only', $null) | Should -BeNullOrEmpty
    }

    It 'applies arm64-gated entries on arm64 machines' {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith {
            [pscustomobject]@{ IsArm64 = $true; LogsPath = Join-Path -Path $TestDrive -ChildPath 'Logs' }
        }

        Invoke-AtlasRegistryEntries -Entries @(
            @{ Path = "$script:testRoot\EntriesArm"; Name = 'Arm64Only'; Type = 'DWord'; Data = 3; Arch = 'ARM64' }
            @{ Path = "$script:testRoot\EntriesArm"; Name = 'X64Only'; Type = 'DWord'; Data = 2; Arch = 'X64' }
        )

        $key = Get-Item -Path "$script:testRoot\EntriesArm"
        $key.GetValue('Arm64Only') | Should -Be 3
        $key.GetValue('X64Only', $null) | Should -BeNullOrEmpty
    }

    It 'supports Delete, AddKey and DeleteKey operations' {
        Set-AtlasRegistryValue -Path "$script:testRoot\EntryOps" -Name 'DeleteMe' -Type String -Data 'x'
        New-AtlasRegistryKey -Path "$script:testRoot\EntryOps\DeleteThisKey"

        Invoke-AtlasRegistryEntries -Entries @(
            @{ Path = "$script:testRoot\EntryOps"; Name = 'DeleteMe'; Operation = 'Delete' }
            @{ Path = "$script:testRoot\EntryOps\DeleteThisKey"; Operation = 'DeleteKey' }
            @{ Path = "$script:testRoot\EntryOps\AddedKey"; Operation = 'AddKey' }
        )

        (Get-Item -Path "$script:testRoot\EntryOps").GetValue('DeleteMe', $null) | Should -BeNullOrEmpty
        Test-Path -Path "$script:testRoot\EntryOps\DeleteThisKey" | Should -BeFalse
        Test-Path -Path "$script:testRoot\EntryOps\AddedKey" | Should -BeTrue
    }

    It 'logs a warning for a failing entry and continues' {
        Invoke-AtlasRegistryEntries -Entries @(
            @{ Path = "$script:testRoot\EntryFail"; Name = 'Broken' } # Set without a Type
            @{ Path = "$script:testRoot\EntryFail"; Name = 'Works'; Type = 'DWord'; Data = 1 }
        )

        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Registry -Times 1 -Exactly -ParameterFilter { $Level -eq 'Warning' }
        (Get-Item -Path "$script:testRoot\EntryFail").GetValue('Works') | Should -Be 1
    }

    It 'swallows failures silently with IgnoreErrors' {
        Invoke-AtlasRegistryEntries -Entries @(
            @{ Path = "$script:testRoot\EntryFail"; Name = 'Broken'; IgnoreErrors = $true } # Set without a Type
        )

        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Registry -Times 0 -Exactly
    }
}

Describe 'Get-AtlasActiveUserSid and user hive enumeration' {
    It 'resolves the current interactive user SID from explorer.exe' {
        $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        Get-AtlasActiveUserSid -Refresh | Should -Be $currentSid
    }

    It 'returns Registry:: provider paths for loaded user hives' {
        $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $hives = @(Get-AtlasUserHives)
        $hives | Should -Contain "Registry::HKEY_USERS\$currentSid"
        foreach ($hive in $hives) {
            $hive | Should -Match '^Registry::HKEY_USERS\\S-1-5-21-'
            $hive | Should -Not -Match '_Classes$'
        }
    }

    It 'keeps the Get-RegUserPaths compatibility shape (key objects with PSPath)' {
        $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $paths = @(Get-RegUserPaths)
        @($paths).Count | Should -BeGreaterThan 0
        @($paths.PSPath) -match [regex]::Escape($currentSid) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AtlasActiveUserSid' {
    BeforeEach {
        # No explorer.exe processes: force the HKEY_USERS hive fallback path.
        Mock -CommandName Get-CimInstance -ModuleName Atlas.Registry -MockWith { @() }
    }

    It 'throws instead of guessing when multiple hives are loaded and none has a Volatile Environment key' {
        Mock -CommandName Get-ChildItem -ModuleName Atlas.Registry -MockWith {
            @(
                [pscustomobject]@{ PSChildName = 'S-1-5-21-1-2-3-1001'; PSPath = 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-1-2-3-1001' }
                [pscustomobject]@{ PSChildName = 'S-1-5-21-1-2-3-2002'; PSPath = 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-1-2-3-2002' }
            )
        }
        Mock -CommandName Test-Path -ModuleName Atlas.Registry -MockWith { $false }

        { Get-AtlasActiveUserSid -Refresh } | Should -Throw '*Refusing to guess*'
    }

    It 'returns the single loaded hive SID even without a Volatile Environment key' {
        Mock -CommandName Get-ChildItem -ModuleName Atlas.Registry -MockWith {
            @(
                [pscustomobject]@{ PSChildName = 'S-1-5-21-1-2-3-1001'; PSPath = 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-1-2-3-1001' }
            )
        }
        Mock -CommandName Test-Path -ModuleName Atlas.Registry -MockWith { $false }

        Get-AtlasActiveUserSid -Refresh | Should -Be 'S-1-5-21-1-2-3-1001'
    }

    It 'returns the hive that has a Volatile Environment key when multiple hives are loaded' {
        Mock -CommandName Get-ChildItem -ModuleName Atlas.Registry -MockWith {
            @(
                [pscustomobject]@{ PSChildName = 'S-1-5-21-1-2-3-1001'; PSPath = 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-1-2-3-1001' }
                [pscustomobject]@{ PSChildName = 'S-1-5-21-1-2-3-2002'; PSPath = 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-1-2-3-2002' }
            )
        }
        Mock -CommandName Test-Path -ModuleName Atlas.Registry -MockWith {
            $LiteralPath -like '*S-1-5-21-1-2-3-2002*'
        }

        Get-AtlasActiveUserSid -Refresh | Should -Be 'S-1-5-21-1-2-3-2002'
    }

    It 'throws when no user hive is loaded' {
        Mock -CommandName Get-ChildItem -ModuleName Atlas.Registry -MockWith { @() }

        { Get-AtlasActiveUserSid -Refresh } | Should -Throw '*no S-1-5-21-*'
    }
}

Describe 'Import-AtlasRegFile' {
    It 'imports a .reg file' {
        $regFile = Join-Path -Path $TestDrive -ChildPath 'test.reg'
        @'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\AtlasRewriteTest\RegImport]
"Imported"=dword:00000005
'@ | Set-Content -Path $regFile -Encoding ASCII

        Import-AtlasRegFile -Path $regFile
        (Get-Item -Path "$script:testRoot\RegImport").GetValue('Imported') | Should -Be 5
    }

    It 'throws when the file is missing' {
        { Import-AtlasRegFile -Path (Join-Path -Path $TestDrive -ChildPath 'missing.reg') } | Should -Throw '*not found*'
    }
}

Describe 'Sync-AtlasDefaultUserHive' {
    BeforeEach {
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith {
            [pscustomobject]@{
                IsArm64  = $false
                LogsPath = Join-Path -Path $TestDrive -ChildPath 'Logs'
            }
        }
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Registry
    }

    It 'returns quietly when no hkcu-paths.log exists' {
        { Sync-AtlasDefaultUserHive } | Should -Not -Throw
        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Registry -Times 0 -Exactly -ParameterFilter { $Level -eq 'Warning' }
    }

    It 'warns and returns when the default-user hive is not loaded' {
        if (Test-Path -LiteralPath 'Registry::HKEY_USERS\AME_UserHive_Default') {
            Set-ItResult -Skipped -Because 'the AME default-user hive is loaded on this machine'
            return
        }

        $installLogs = Join-Path -Path (Join-Path -Path $TestDrive -ChildPath 'Logs') -ChildPath 'install'
        New-Item -Path $installLogs -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path -Path $installLogs -ChildPath 'hkcu-paths.log') -Value 'Software\AtlasRewriteTest'

        { Sync-AtlasDefaultUserHive } | Should -Not -Throw
        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Registry -Times 1 -Exactly -ParameterFilter { $Level -eq 'Warning' }
    }
}
