BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Atlas.Registry.psd1') -Force

    $script:registryPathsSource = Get-Content -LiteralPath `
        (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Domain\Paths.ps1') -Raw
    $script:registryRegFileSource = Get-Content -LiteralPath `
        (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Domain\RegFile.ps1') -Raw

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:testSubPath = 'Software\AtlasRewriteTest'
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Resolve-AtlasRegistryTarget identity boundary' {
    It 'redirects HKCU for LocalSystem even without strict TrustedInstaller evidence' {
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Registry -MockWith { $true }
        Mock -CommandName Get-AtlasActiveUserSid -ModuleName Atlas.Registry -MockWith {
            'S-1-5-21-1-2-3-1001'
        }

        $result = InModuleScope Atlas.Registry {
            Resolve-AtlasRegistryTarget -Path 'HKCU:\Software\X'
        }

        $result.Primary | Should -Be `
            'Registry::HKEY_USERS\S-1-5-21-1-2-3-1001\Software\X'
        $result.Mirror | Should -Be 'Registry::HKEY_USERS\AME_UserHive_Default\Software\X'
        Should -Invoke -CommandName Test-AtlasSystem -ModuleName Atlas.Registry -Times 1 -Exactly
        Should -Invoke -CommandName Get-AtlasActiveUserSid -ModuleName Atlas.Registry -Times 1 -Exactly
    }

    It 'keeps ambient HKCU for a non-System caller' {
        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Registry -MockWith { $false }
        Mock -CommandName Get-AtlasActiveUserSid -ModuleName Atlas.Registry -MockWith {
            throw 'The active-user resolver must not run for a non-System caller.'
        }

        $result = InModuleScope Atlas.Registry {
            Resolve-AtlasRegistryTarget -Path 'HKCU:\Software\X'
        }

        $result.Primary | Should -Be 'Registry::HKEY_CURRENT_USER\Software\X'
        $result.Mirror | Should -BeNullOrEmpty
        Should -Invoke -CommandName Test-AtlasSystem -ModuleName Atlas.Registry -Times 1 -Exactly
        Should -Not -Invoke -CommandName Get-AtlasActiveUserSid -ModuleName Atlas.Registry
    }

    It 'uses only the LocalSystem identity predicate for HKCU path and reg-file policy' {
        foreach ($source in @($script:registryPathsSource, $script:registryRegFileSource)) {
            $source | Should -Match '\bTest-AtlasSystem\b'
            $source | Should -Not -Match '\bTest-AtlasTrustedInstaller\b'
        }
    }
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
        # Unelevated test runs never hit the LocalSystem redirect branch, so the
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

    It 'removes a key default value when Name is empty' {
        Set-AtlasRegistryValue -Path $script:valuesKeyPath -Name '' -Type String -Data 'default'
        Remove-AtlasRegistryValue -Path $script:valuesKeyPath -Name ''
        (Get-Item -Path $script:valuesKeyPath).GetValue('', $null) | Should -BeNullOrEmpty
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

    It 'refuses to delete the redirected HKCU root' {
        { Remove-AtlasRegistryKey -Path 'HKCU:\' } | Should -Throw '*Refusing to delete the registry root*'
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

    It 'rejects HKCU imports under LocalSystem because they cannot be redirected or journaled safely' {
        $regFile = Join-Path -Path $TestDrive -ChildPath 'unsafe-hkcu.reg'
        @'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\AtlasRewriteTest\UnsafeImport]
"Imported"=dword:00000005
'@ | Set-Content -Path $regFile -Encoding ASCII

        Mock -CommandName Test-AtlasSystem -ModuleName Atlas.Registry -MockWith { $true }

        { Import-AtlasRegFile -Path $regFile } | Should -Throw '*cannot redirect or journal HKCU*'
        Test-Path -Path "$script:testRoot\UnsafeImport" | Should -BeFalse
        Should -Invoke -CommandName Test-AtlasSystem -ModuleName Atlas.Registry -Times 1 -Exactly
    }
}

Describe 'Atlas-owned transaction-bound HKCU delta journal' {
    BeforeEach {
        $script:transactionId = [Guid]::NewGuid().ToString('D')
        $script:transactionRoot = Join-Path -Path $TestDrive -ChildPath $script:transactionId
        $script:activeJournalPath = Join-Path -Path $TestDrive -ChildPath 'active.json'
        $script:logsPath = Join-Path -Path $TestDrive -ChildPath 'Logs'
        $script:currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $script:simulatedDefaultRoot = "$script:currentSid\Software\AtlasRewriteTest\SimulatedDefault"
        $script:unicodeData = 'Atlas ' + [char]0x03A9 + ' ' + [char]0x4E16 + [char]0x754C

        New-Item -Path $script:transactionRoot -ItemType Directory -Force | Out-Null
        New-Item -Path $script:activeJournalPath -ItemType File -Force | Out-Null
        $script:installJournalDocument = [pscustomobject]@{
            transactionId   = $script:transactionId
            state           = 'InProgress'
            transactionRoot = $script:transactionRoot
        }
        [AppDomain]::CurrentDomain.SetData('Atlas.Registry.Tests.InstallJournal', $script:installJournalDocument)

        InModuleScope Atlas.Registry -Parameters @{ JournalPath = $script:activeJournalPath } {
            param($JournalPath)
            $script:AtlasInstallJournalPathOverride = $JournalPath
        }

        Mock -CommandName Get-AtlasInstallJournal -ModuleName Atlas.Registry -MockWith {
            return [AppDomain]::CurrentDomain.GetData('Atlas.Registry.Tests.InstallJournal')
        }
        Mock -CommandName Set-AtlasHkcuDeltaFileAccessControl -ModuleName Atlas.Registry
        Mock -CommandName Assert-AtlasHkcuDeltaFileSecurity -ModuleName Atlas.Registry
        Mock -CommandName Write-AtlasLog -ModuleName Atlas.Registry
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith {
            [pscustomobject]@{ IsArm64 = $false; LogsPath = $TestDrive }
        }
        Mock -CommandName Test-AtlasDefaultUserHiveLoaded -ModuleName Atlas.Registry -MockWith { $false }

        $script:deltaPaths = InModuleScope Atlas.Registry {
            $transaction = Get-AtlasHkcuActiveTransaction
            return Get-AtlasHkcuDeltaPaths -Transaction $transaction
        }

        Remove-Item -Path "$script:testRoot\Journal" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$script:testRoot\JournalFailure" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$script:testRoot\PostInstall" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$script:testRoot\Contaminated" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$script:testRoot\SimulatedDefault" -Recurse -Force -ErrorAction SilentlyContinue
    }

    AfterEach {
        [AppDomain]::CurrentDomain.SetData('Atlas.Registry.Tests.InstallJournal', $null)
        [AppDomain]::CurrentDomain.SetData('Atlas.Registry.Tests.InstallJournalSequence', $null)
        InModuleScope Atlas.Registry {
            $script:AtlasInstallJournalPathOverride = $null
        }
    }

    It 'imports Atlas.InstallJournal by its exact sibling manifest and exports explicit completion' {
        $moduleSource = Get-Content -LiteralPath (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Atlas.Registry.psm1') -Raw
        $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Registry\Atlas.Registry.psd1')

        $moduleSource | Should -Match ([regex]::Escape('..\Atlas.InstallJournal\Atlas.InstallJournal.psd1'))
        $moduleSource | Should -Match 'Import-Module\s+-Name\s+\$installJournalManifestPath\s+-Force\s+-ErrorAction\s+Stop'
        $manifest.FunctionsToExport | Should -Contain 'Complete-AtlasHkcuDeltaJournal'
    }

    It 'builds an exact protected file DACL for SYSTEM, Administrators, and TrustedInstaller' {
        InModuleScope Atlas.Registry {
            $security = New-AtlasHkcuDeltaFileSecurity
            $security.AreAccessRulesProtected | Should -BeTrue
            $security.GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'
            $ruleSids = @($security.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]) |
                ForEach-Object { $_.IdentityReference.Value } | Sort-Object)
            $ruleSids | Should -Be @(
                'S-1-5-18',
                'S-1-5-32-544',
                'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
            )
            $ruleSids | Should -Not -Contain 'S-1-5-32-545'
        }
    }

    It 'records every value kind and key operation with the active transaction id' {
        Mock -CommandName Resolve-AtlasRegistryTarget -ModuleName Atlas.Registry -MockWith {
            param($Path)
            $subPath = $Path -replace '^HKCU:\\', ''
            [pscustomobject]@{
                Primary = "Registry::HKEY_CURRENT_USER\$subPath"
                Mirror = $null
                HkcuSubPath = $subPath
                IsHkcu = $true
            }
        }

        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'StringValue' -Type String -Data $script:unicodeData
        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'ExpandValue' -Type ExpandString -Data '%windir%\test'
        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'BinaryValue' -Type Binary -Data @(1, 2, 255)
        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'DwordMax' -Type DWord -Data 4294967295
        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'MultiValue' -Type MultiString -Data @('one', 'two')
        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'QwordMax' -Type QWord -Data ([uint64]::MaxValue)
        Set-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'NoneValue' -Type None -Data @(9, 8)
        Remove-AtlasRegistryValue -Path "$script:testRoot\Journal" -Name 'StringValue'
        New-AtlasRegistryKey -Path "$script:testRoot\Journal\CreatedKey"
        Remove-AtlasRegistryKey -Path "$script:testRoot\Journal\CreatedKey"

        $records = @([IO.File]::ReadAllLines($script:deltaPaths.Journal) | ForEach-Object { $_ | ConvertFrom-Json })
        $records.Count | Should -Be 10
        @($records.TransactionId | Select-Object -Unique) | Should -Be @($script:transactionId)
        @($records.Operation) | Should -Be @(
            'SetValue', 'SetValue', 'SetValue', 'SetValue', 'SetValue',
            'SetValue', 'SetValue', 'DeleteValue', 'CreateKey', 'DeleteKey'
        )
        ($records | Where-Object Name -eq 'DwordMax').Data | Should -Be 'FFFFFFFF'
        ($records | Where-Object Name -eq 'QwordMax').Data | Should -Be 'FFFFFFFFFFFFFFFF'
        ($records | Where-Object Name -eq 'BinaryValue').Data | Should -Be 'AQL/'
        ($records | Where-Object Name -eq 'NoneValue').Data | Should -Be 'CQg='
        ($records | Where-Object Name -eq 'StringValue' | Select-Object -First 1).Data | Should -Be $script:unicodeData
        @((($records | Where-Object Name -eq 'MultiValue').Data)) | Should -Be @('one', 'two')
        @($records | ForEach-Object { $_.PSObject.Properties.Name }) | Should -Not -Contain 'SourcePath'
    }

    It 'does not append post-install toggles when the install journal is completed or absent' {
        Mock -CommandName Resolve-AtlasRegistryTarget -ModuleName Atlas.Registry -MockWith {
            param($Path)
            $subPath = $Path -replace '^HKCU:\\', ''
            [pscustomobject]@{
                Primary = "Registry::HKEY_CURRENT_USER\$subPath"
                Mirror = $null
                HkcuSubPath = $subPath
                IsHkcu = $true
            }
        }
        $script:installJournalDocument.state = 'Completed'

        Set-AtlasRegistryValue -Path "$script:testRoot\PostInstall" -Name 'Completed' -Type DWord -Data 1
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse

        $script:installJournalDocument.state = 'InProgress'
        Remove-Item -LiteralPath $script:activeJournalPath -Force
        Set-AtlasRegistryValue -Path "$script:testRoot\PostInstall" -Name 'Missing' -Type DWord -Data 2

        (Get-Item -Path "$script:testRoot\PostInstall").GetValue('Completed') | Should -Be 1
        (Get-Item -Path "$script:testRoot\PostInstall").GetValue('Missing') | Should -Be 2
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse
    }

    It 'throws a marked durable failure through public and IgnoreErrors declarative APIs' {
        Mock -CommandName Resolve-AtlasRegistryTarget -ModuleName Atlas.Registry -MockWith {
            param($Path)
            $subPath = $Path -replace '^HKCU:\\', ''
            [pscustomobject]@{
                Primary = "Registry::HKEY_CURRENT_USER\$subPath"
                Mirror = $null
                HkcuSubPath = $subPath
                IsHkcu = $true
            }
        }
        $script:installJournalDocument.state = 'Failed'

        { Set-AtlasRegistryValue -Path "$script:testRoot\JournalFailure" -Name 'Direct' -Type DWord -Data 1 } |
            Should -Throw '*could not be recorded durably*'
        (Get-Item -Path "$script:testRoot\JournalFailure").GetValue('Direct') | Should -Be 1

        { Invoke-AtlasRegistryEntries -Entries @(
            @{ Path = "$script:testRoot\JournalFailure"; Name = 'Declarative'; Type = 'DWord'; Data = 2; IgnoreErrors = $true }
        ) } | Should -Throw '*could not be recorded durably*'
        (Get-Item -Path "$script:testRoot\JournalFailure").GetValue('Declarative') | Should -Be 2
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse
    }

    It 'uses one exclusive interprocess lock for the transaction' {
        InModuleScope Atlas.Registry -Parameters @{ TransactionRoot = $script:transactionRoot } {
            param($TransactionRoot)
            $first = Open-AtlasHkcuDeltaLock -TransactionRoot $TransactionRoot
            try {
                { Open-AtlasHkcuDeltaLock -TransactionRoot $TransactionRoot -TimeoutMilliseconds 100 } |
                    Should -Throw '*Timed out*'
            }
            finally {
                $first.Dispose()
            }

            $second = Open-AtlasHkcuDeltaLock -TransactionRoot $TransactionRoot -TimeoutMilliseconds 100
            $second | Should -BeOfType ([IO.FileStream])
            $second.Dispose()
        }
    }

    It 'preserves a validated prefix and records evidence before truncating only a final fragment' {
        InModuleScope Atlas.Registry -Parameters @{ Paths = $script:deltaPaths; TransactionId = $script:transactionId } {
            param($Paths, $TransactionId)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\First' -Operation CreateKey
            $fragment = ConvertTo-AtlasStrictUtf8Bytes -Text '{"Version":1,"TransactionId":"partial'
            $stream = [IO.File]::Open($Paths.Journal, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            try {
                $stream.Write($fragment, 0, $fragment.Length)
                $stream.Flush($true)
            }
            finally {
                $stream.Dispose()
            }

            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Second' -Operation CreateKey
            $records = @(Read-AtlasHkcuDeltaJournal -JournalPath $Paths.Journal -ExpectedTransactionId $TransactionId)
            $records.Count | Should -Be 2
            @($records.SubPath) | Should -Be @(
                'Software\AtlasRewriteTest\First',
                'Software\AtlasRewriteTest\Second'
            )
            Test-Path -LiteralPath $Paths.Recovery -PathType Leaf | Should -BeTrue
            ([IO.File]::ReadAllText($Paths.Recovery)) | Should -Match 'UnterminatedFinalFragmentTruncated'
        }
    }

    It 'rejects earlier or newline-terminated corruption without changing the journal' {
        InModuleScope Atlas.Registry -Parameters @{ Paths = $script:deltaPaths } {
            param($Paths)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\First' -Operation CreateKey
            $malformed = ConvertTo-AtlasStrictUtf8Bytes -Text "{not-json}`n"
            $stream = [IO.File]::Open($Paths.Journal, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            try {
                $stream.Write($malformed, 0, $malformed.Length)
                $stream.Flush($true)
            }
            finally {
                $stream.Dispose()
            }
            $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Paths.Journal))

            { Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Never' -Operation CreateKey } |
                Should -Throw '*line 2*'
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($Paths.Journal)) | Should -Be $before
            Test-Path -LiteralPath $Paths.Recovery | Should -BeFalse
        }
    }

    It 'refuses to truncate the journal unless recovery evidence can be made durable' {
        InModuleScope Atlas.Registry -Parameters @{ Paths = $script:deltaPaths } {
            param($Paths)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\First' -Operation CreateKey
            [IO.File]::WriteAllBytes($Paths.Recovery, (ConvertTo-AtlasStrictUtf8Bytes -Text "{bad-evidence}`n"))
            $fragment = ConvertTo-AtlasStrictUtf8Bytes -Text '{partial-record'
            $stream = [IO.File]::Open($Paths.Journal, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            try {
                $stream.Write($fragment, 0, $fragment.Length)
                $stream.Flush($true)
            }
            finally {
                $stream.Dispose()
            }
            $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Paths.Journal))

            { Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Never' -Operation CreateKey } |
                Should -Throw '*recovery evidence*line 1*'
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($Paths.Journal)) | Should -Be $before
        }
    }

    It 'replays all supported kinds and deletes without copying unrelated installing-user data' {
        New-Item -Path 'HKCU:\Software\AtlasRewriteTest\Contaminated' -Force | Out-Null
        Set-ItemProperty -Path 'HKCU:\Software\AtlasRewriteTest\Contaminated' -Name 'StringValue' -Value 'user-modified-value' -Type String
        Set-ItemProperty -Path 'HKCU:\Software\AtlasRewriteTest\Contaminated' -Name 'UnrelatedRoot' -Value 'installing-user-secret' -Type String
        New-Item -Path 'HKCU:\Software\AtlasRewriteTest\Contaminated\UnrelatedChild' -Force | Out-Null
        Set-ItemProperty -Path 'HKCU:\Software\AtlasRewriteTest\Contaminated\UnrelatedChild' -Name 'NestedSecret' -Value 73 -Type DWord

        $destinationPath = 'HKCU:\Software\AtlasRewriteTest\SimulatedDefault\Software\AtlasRewriteTest\Contaminated'
        New-Item -Path "$destinationPath\DeleteTree\Child" -Force | Out-Null
        Set-ItemProperty -Path $destinationPath -Name 'DeleteMe' -Value 'old' -Type String

        InModuleScope Atlas.Registry -Parameters @{
            Paths = $script:deltaPaths
            TransactionId = $script:transactionId
            DestinationRoot = $script:simulatedDefaultRoot
            UnicodeData = $script:unicodeData
        } {
            param($Paths, $TransactionId, $DestinationRoot, $UnicodeData)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'StringValue' -Kind String -Data $UnicodeData
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'ExpandValue' -Kind ExpandString -Data '%windir%\test'
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'BinaryValue' -Kind Binary -Data @(1, 2, 255)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'DwordMax' -Kind DWord -Data 4294967295
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'MultiValue' -Kind MultiString -Data @('one', 'two')
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'QwordMax' -Kind QWord -Data ([uint64]::MaxValue)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation SetValue -Name 'NoneValue' -Kind None -Data @(9, 8)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated' -Operation DeleteValue -Name 'DeleteMe'
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated\CreatedKey' -Operation CreateKey
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Contaminated\DeleteTree' -Operation DeleteKey
            $null = Complete-AtlasHkcuDeltaJournal
            $records = @(Read-AtlasHkcuDeltaJournal -JournalPath $Paths.Journal -ExpectedTransactionId $TransactionId)
            Invoke-AtlasHkcuDeltaJournal -Deltas $records -DestinationRootSubPath $DestinationRoot | Should -Be 10
        }

        $destinationKey = Get-Item -Path $destinationPath
        $destinationKey.GetValue('StringValue') | Should -Be $script:unicodeData
        $destinationKey.GetValueKind('StringValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
        $destinationKey.GetValue('ExpandValue', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) | Should -Be '%windir%\test'
        $destinationKey.GetValueKind('ExpandValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::ExpandString)
        @($destinationKey.GetValue('BinaryValue')) | Should -Be @(1, 2, 255)
        $destinationKey.GetValueKind('BinaryValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::Binary)
        $destinationKey.GetValue('DwordMax') | Should -Be (-1)
        @($destinationKey.GetValue('MultiValue')) | Should -Be @('one', 'two')
        $destinationKey.GetValue('QwordMax') | Should -Be (-1)
        @($destinationKey.GetValue('NoneValue')) | Should -Be @(9, 8)
        $destinationKey.GetValueKind('NoneValue') | Should -Be ([Microsoft.Win32.RegistryValueKind]::None)
        $destinationKey.GetValue('DeleteMe', $null) | Should -BeNullOrEmpty
        $destinationKey.GetValue('UnrelatedRoot', $null) | Should -BeNullOrEmpty
        Test-Path -Path "$destinationPath\UnrelatedChild" | Should -BeFalse
        Test-Path -Path "$destinationPath\CreatedKey" | Should -BeTrue
        Test-Path -Path "$destinationPath\DeleteTree" | Should -BeFalse
    }

    It 'writes an atomic marker bound to the flushed journal and blocks all later writers' {
        InModuleScope Atlas.Registry -Parameters @{ Paths = $script:deltaPaths; TransactionId = $script:transactionId } {
            param($Paths, $TransactionId)
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\One' -Operation CreateKey
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Two' -Operation CreateKey
            $marker = Complete-AtlasHkcuDeltaJournal
            $bytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $Paths.Journal

            $marker.TransactionId | Should -Be $TransactionId
            $marker.RecordCount | Should -Be 2
            $marker.JournalLength | Should -Be $bytes.Length
            $marker.JournalSha256 | Should -Be (Get-AtlasHkcuSha256Hex -Bytes $bytes)
            Test-Path -LiteralPath $Paths.Marker -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath $Paths.MarkerTemp | Should -BeFalse
            { Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Late' -Operation CreateKey } |
                Should -Throw '*already committed*'
        }
    }

    It 'recovers interrupted empty journal and marker-temp creation before writing protected data' {
        New-Item -Path $script:deltaPaths.Journal -ItemType File -Force | Out-Null
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\RecoveredEmpty' -Operation CreateKey
        }
        New-Item -Path $script:deltaPaths.MarkerTemp -ItemType File -Force | Out-Null

        $marker = Complete-AtlasHkcuDeltaJournal

        $marker.RecordCount | Should -Be 1
        Test-Path -LiteralPath $script:deltaPaths.Marker -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $script:deltaPaths.MarkerTemp | Should -BeFalse
        ([IO.File]::ReadAllText($script:deltaPaths.Recovery)) | Should -Match 'IncompleteCommitTemporaryRemoved'
    }

    It 'does not replay or consume an interrupted valid prefix without a commit marker' {
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Prefix' -Operation CreateKey
        }

        { Sync-AtlasDefaultUserHive } | Should -Throw '*no durable commit marker*'
        Test-Path -LiteralPath $script:deltaPaths.Journal -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $script:deltaPaths.Marker | Should -BeFalse
    }

    It 'rejects a commit marker from a different transaction before replay' {
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Mismatch' -Operation CreateKey
        }
        $null = Complete-AtlasHkcuDeltaJournal
        $marker = [IO.File]::ReadAllText($script:deltaPaths.Marker) | ConvertFrom-Json
        $marker.TransactionId = [Guid]::NewGuid().ToString('D')
        $json = $marker | ConvertTo-Json -Compress
        [IO.File]::WriteAllText($script:deltaPaths.Marker, $json, (New-Object Text.UTF8Encoding($false, $true)))
        Mock -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry

        { Sync-AtlasDefaultUserHive } | Should -Throw '*does not match*'
        Should -Invoke -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -Times 0 -Exactly
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeTrue
        Test-Path -LiteralPath $script:deltaPaths.Marker | Should -BeTrue
    }

    It 'rejects a newline-terminated journal record from another transaction before commit' {
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\WrongRecordTransaction' -Operation CreateKey
        }
        $record = [IO.File]::ReadAllText($script:deltaPaths.Journal).TrimEnd("`r", "`n") | ConvertFrom-Json
        $record.TransactionId = [Guid]::NewGuid().ToString('D')
        $tamperedLine = ($record | ConvertTo-Json -Compress) + "`n"
        [IO.File]::WriteAllText(
            $script:deltaPaths.Journal,
            $tamperedLine,
            (New-Object Text.UTF8Encoding($false, $true))
        )

        { Complete-AtlasHkcuDeltaJournal } | Should -Throw '*does not match active transaction*'
        Test-Path -LiteralPath $script:deltaPaths.Marker | Should -BeFalse
    }

    It 'rejects a transaction change after acquiring the lock without appending' {
        $secondId = [Guid]::NewGuid().ToString('D')
        $secondRoot = Join-Path -Path $TestDrive -ChildPath $secondId
        New-Item -Path $secondRoot -ItemType Directory -Force | Out-Null
        $firstDocument = $script:installJournalDocument
        $secondDocument = [pscustomobject]@{
            transactionId = $secondId
            state = 'InProgress'
            transactionRoot = $secondRoot
        }
        $sequence = [pscustomobject]@{ Documents = @($firstDocument, $secondDocument); Call = 0 }
        [AppDomain]::CurrentDomain.SetData('Atlas.Registry.Tests.InstallJournalSequence', $sequence)
        Mock -CommandName Get-AtlasInstallJournal -ModuleName Atlas.Registry -MockWith {
            $currentSequence = [AppDomain]::CurrentDomain.GetData('Atlas.Registry.Tests.InstallJournalSequence')
            $index = [Math]::Min($currentSequence.Call, $currentSequence.Documents.Count - 1)
            $currentSequence.Call++
            return $currentSequence.Documents[$index]
        }

        InModuleScope Atlas.Registry {
            { Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Changed' -Operation CreateKey } |
                Should -Throw '*active Atlas install transaction changed*'
        }
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse
    }

    It 'retains a committed journal when the default-user hive is unavailable' {
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Pending' -Operation CreateKey
        }
        $null = Complete-AtlasHkcuDeltaJournal
        Mock -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry

        { Sync-AtlasDefaultUserHive } | Should -Throw '*refusing to discard the committed*'
        Test-Path -LiteralPath $script:deltaPaths.Journal -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $script:deltaPaths.Marker -PathType Leaf | Should -BeTrue
        Should -Invoke -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -Times 0 -Exactly
    }

    It 'consumes marker and journal only after successful committed replay' {
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\Pending' -Operation CreateKey
        }
        $null = Complete-AtlasHkcuDeltaJournal
        Mock -CommandName Test-AtlasDefaultUserHiveLoaded -ModuleName Atlas.Registry -MockWith { $true }
        Mock -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -MockWith {
            return @($Deltas).Count
        }

        Sync-AtlasDefaultUserHive

        Test-Path -LiteralPath $script:deltaPaths.Marker | Should -BeFalse
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse
        Test-Path -LiteralPath $script:deltaPaths.Consumed -PathType Leaf | Should -BeTrue
        Should -Invoke -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -Times 1 -Exactly
        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Registry -Times 1 -Exactly -ParameterFilter {
            $Message -like 'Replayed and consumed 1*'
        }

        Sync-AtlasDefaultUserHive
        Should -Invoke -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -Times 1 -Exactly
        InModuleScope Atlas.Registry {
            { Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\TooLate' -Operation CreateKey } |
                Should -Throw '*committed or consumed*'
        }
    }

    It 'recovers a crash after marker retirement without replaying the journal twice' {
        InModuleScope Atlas.Registry {
            Write-AtlasHkcuDeltaRecord -SubPath 'Software\AtlasRewriteTest\AlreadyReplayed' -Operation CreateKey
        }
        $null = Complete-AtlasHkcuDeltaJournal
        [IO.File]::Move($script:deltaPaths.Marker, $script:deltaPaths.Consumed)
        Mock -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -MockWith {
            throw 'A consumed transaction was replayed twice.'
        }

        { Sync-AtlasDefaultUserHive } | Should -Not -Throw
        Should -Invoke -CommandName Invoke-AtlasHkcuDeltaJournal -ModuleName Atlas.Registry -Times 0 -Exactly
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse
        Test-Path -LiteralPath $script:deltaPaths.Consumed -PathType Leaf | Should -BeTrue

        $marker = Complete-AtlasHkcuDeltaJournal
        $marker.RecordCount | Should -Be 1
        Test-Path -LiteralPath $script:deltaPaths.Marker | Should -BeFalse
    }

    It 'commits and consumes an empty journal without requiring the default-user hive' {
        $marker = Complete-AtlasHkcuDeltaJournal
        $marker.RecordCount | Should -Be 0
        Test-Path -LiteralPath $script:deltaPaths.Journal | Should -BeFalse
        Test-Path -LiteralPath $script:deltaPaths.Marker -PathType Leaf | Should -BeTrue

        { Sync-AtlasDefaultUserHive } | Should -Not -Throw
        Test-Path -LiteralPath $script:deltaPaths.Marker | Should -BeFalse
        Test-Path -LiteralPath $script:deltaPaths.Consumed -PathType Leaf | Should -BeTrue
    }

    It 'ignores the obsolete path-only journal and never resolves a source user' {
        $installLogs = Join-Path -Path $script:logsPath -ChildPath 'install'
        New-Item -Path $installLogs -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $installLogs -ChildPath 'hkcu-paths.log') -ItemType File -Force | Out-Null
        Mock -CommandName Get-AtlasContext -ModuleName Atlas.Registry -MockWith {
            [pscustomobject]@{ IsArm64 = $false; LogsPath = $script:logsPath }
        }
        Mock -CommandName Get-AtlasActiveUserSid -ModuleName Atlas.Registry -MockWith {
            throw 'The obsolete path journal attempted to resolve a source user.'
        }
        $null = Complete-AtlasHkcuDeltaJournal

        { Sync-AtlasDefaultUserHive } | Should -Not -Throw
        Should -Invoke -CommandName Get-AtlasActiveUserSid -ModuleName Atlas.Registry -Times 0 -Exactly
        Should -Invoke -CommandName Write-AtlasLog -ModuleName Atlas.Registry -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*obsolete*ignored*'
        }
    }
}
