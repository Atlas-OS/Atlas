BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $PSScriptRoot '../app/resources/prepare/Stage-App.ps1') -FunctionsOnly
}

Describe 'Protected recovery descriptors' {
    It 'ignores only the DACL inheritance-history flag, not changed access or ownership' {
        $expected = Get-AtlasRecoveryFileSecurity
        $sddl = $expected.GetSecurityDescriptorSddlForm('Access,Owner')
        $actual = New-Object Security.AccessControl.FileSecurity
        $actual.SetSecurityDescriptorSddlForm($sddl.Replace('D:P(', 'D:PAI('))
        Get-AtlasRecoveryAccessDescriptor $actual | Should -Be (Get-AtlasRecoveryAccessDescriptor $expected)
        foreach ($changed in @($sddl.Replace('D:P(', 'D:('), $sddl.Replace('O:BA', 'O:BU'), $sddl.Replace('0x1200a9', 'FA'))) {
            $actual.SetSecurityDescriptorSddlForm($changed)
            Get-AtlasRecoveryAccessDescriptor $actual | Should -Not -Be (Get-AtlasRecoveryAccessDescriptor $expected)
        }
    }
    It 'protects ownership and permits only administrators and SYSTEM to write' {
        $security = Get-AtlasRecoverySecurity
        $security.AreAccessRulesProtected | Should -BeTrue
        $security.GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'
        Assert-AtlasRecoverySecurity $security
        $user = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')
        $security.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($user, 'Write', 'Allow')))
        { Assert-AtlasRecoverySecurity $security } | Should -Throw '*permissions*'
    }
    It 'gives recovery executables protected administrator ownership at creation' {
        $security = Get-AtlasRecoveryFileSecurity
        $security.AreAccessRulesProtected | Should -BeTrue
        $security.GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -Be 'S-1-5-32-544'
        $rules = @($security.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))
        @($rules | Where-Object { $_.IdentityReference.Value -eq 'S-1-5-32-545' })[0].FileSystemRights | Should -Be 'ReadAndExecute, Synchronize'
    }
}

Describe 'Immutable recovery copies in owned temporary storage' {
    BeforeEach {
        # Exercise the real copy/hash/atomic rename with a current-user-only test ACL.
        # Production descriptors are independently checked above; never create Program Files entries.
        Mock New-AtlasRecoveryDirectory {
            param($Path)
            [void][IO.Directory]::CreateDirectory($Path)
            return [IO.Path]::GetFullPath($Path)
        }
        Mock Get-AtlasRecoveryFileSecurity {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $security = New-Object Security.AccessControl.FileSecurity
            $security.SetSecurityDescriptorSddlForm("O:${sid}D:P(A;;FA;;;${sid})")
            return $security
        }
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Source = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.exe')
        [IO.File]::WriteAllBytes($script:Source, [byte[]](1,2,3,4,5))
    }
    It 'keeps the executable available after the original is removed' {
        $destination = Copy-AtlasRecoveryExecutable $script:Source $script:Root
        $expected = (Get-FileHash -LiteralPath $script:Source).Hash
        Remove-Item -LiteralPath $script:Source
        (Get-FileHash -LiteralPath $destination).Hash | Should -Be $expected
        Split-Path -Leaf (Split-Path -Parent $destination) | Should -Be $expected.ToLowerInvariant()
    }
    It 'reuses identical content without replacing the file' {
        $first = Copy-AtlasRecoveryExecutable $script:Source $script:Root
        $created = (Get-Item -LiteralPath $first).CreationTimeUtc
        Copy-AtlasRecoveryExecutable $script:Source $script:Root | Should -Be $first
        (Get-Item -LiteralPath $first).CreationTimeUtc | Should -Be $created
        @(Get-ChildItem -LiteralPath (Split-Path -Parent $first) -Force).Count | Should -Be 1
    }
    It 'accepts an atomically replaced journal without weakening its protected access' {
        $destination = Join-Path $TestDrive 'state.json'
        $temporary = Join-Path $TestDrive 'state.tmp'
        Write-AtlasProtectedRecoveryFile $destination ([Text.Encoding]::UTF8.GetBytes('first')) (Get-AtlasRecoveryFileSecurity)
        Write-AtlasProtectedRecoveryFile $temporary ([Text.Encoding]::UTF8.GetBytes('second')) (Get-AtlasRecoveryFileSecurity)
        [IO.File]::Replace($temporary, $destination, [NullString]::Value)
        [IO.File]::ReadAllText($destination) | Should -Be 'second'
        Assert-AtlasRecoveryFileSecurity $destination
    }
    It 'refuses an altered existing destination rather than overwriting it' {
        $first = Copy-AtlasRecoveryExecutable $script:Source $script:Root
        [IO.File]::WriteAllText($first, 'changed')
        { Copy-AtlasRecoveryExecutable $script:Source $script:Root } | Should -Throw '*does not match*'
        [IO.File]::ReadAllText($first) | Should -Be 'changed'
    }
    It 'creates immutable worker and policy files with a separate precreated cancellation marker' {
        $scope = 'a' * 64
        $directory = New-AtlasPreparationJob $script:Root $scope '123-456' '# inert worker' ([byte[]](1,2,3))
        [IO.File]::ReadAllText((Join-Path $directory 'Update-Windows.ps1')) | Should -Be '# inert worker'
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'Update-Windows.ps1')
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'DriverPolicy.reg')
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'cancel') (Get-AtlasCancellationSecurity)
        [IO.File]::ReadAllText((Join-Path $directory 'cancel')) | Should -Be ''
        [IO.File]::WriteAllText((Join-Path $directory 'cancel'), 'cancel')
        [IO.File]::ReadAllText((Join-Path $directory 'cancel')) | Should -Be 'cancel'
        { New-AtlasPreparationJob $script:Root $scope '123-456' '# changed' ([byte[]](4,5)) } | Should -Throw
        [IO.File]::ReadAllText((Join-Path $directory 'Update-Windows.ps1')) | Should -Be '# inert worker'
    }
    It 'refuses path traversal in preparation namespaces and job names' {
        { New-AtlasPreparationJob $script:Root '../other' '123-456' '' ([byte[]]@()) } | Should -Throw '*identity*'
        { New-AtlasPreparationJob $script:Root ('a' * 64) '../other' '' ([byte[]]@()) } | Should -Throw '*identity*'
    }
}
