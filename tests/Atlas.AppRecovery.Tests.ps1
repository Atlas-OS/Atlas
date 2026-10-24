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
        $security.GetSecurityDescriptorSddlForm('Access,Owner') | Should -BeExactly 'O:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;BU)' `
            -Because 'only SYSTEM and administrators may change recovery folders'
        { Assert-AtlasRecoverySecurity $security } | Should -Not -Throw
        $user = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')
        $security.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($user, 'Write', 'Allow')))
        { Assert-AtlasRecoverySecurity $security } | Should -Throw '*permissions*'
    }
}

Describe 'Links on recovery paths' {
    It 'refuses a path that passes through a junction' {
        $target = Join-Path $TestDrive 'target'
        [void][IO.Directory]::CreateDirectory($target)
        [IO.File]::WriteAllBytes((Join-Path $target 'AtlasManager.exe'), [byte[]](1, 2, 3))
        $junction = Join-Path $TestDrive 'linked'
        $null = cmd.exe /d /c mklink /J "$junction" "$target"
        try {
            { Assert-AtlasRecoveryPath (Join-Path $junction 'AtlasManager.exe') } | Should -Throw '*Linked*'
        }
        finally { [IO.Directory]::Delete($junction) }
        { Assert-AtlasRecoveryPath (Join-Path $target 'AtlasManager.exe') } | Should -Not -Throw
    }
    It 'accepts a reparse point that is not a link, such as a OneDrive folder' {
        Mock Get-Item { [pscustomobject]@{ Attributes = [IO.FileAttributes]'Archive, ReparsePoint'; LinkType = $null; Parent = $null } }
        { Assert-AtlasRecoveryPath 'C:\Users\Someone\OneDrive\Desktop\AtlasManager.exe' } | Should -Not -Throw
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
    Context 'with files the current user may only read' {
        BeforeEach {
            # Under full control the marker's extra write right merges into the user's
            # existing rule, so every file would get the same descriptor.
            Mock Get-AtlasRecoveryFileSecurity {
                $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
                $security = New-Object Security.AccessControl.FileSecurity
                $security.SetSecurityDescriptorSddlForm("O:${sid}D:P(A;;FA;;;SY)(A;;0x1200a9;;;${sid})")
                return $security
            }
        }
        It 'creates immutable worker and policy files with a separate precreated cancellation marker' {
            (Get-AtlasCancellationSecurity).GetSecurityDescriptorSddlForm('Access,Owner') |
                Should -Not -Be (Get-AtlasRecoveryFileSecurity).GetSecurityDescriptorSddlForm('Access,Owner')
            $scope = 'a' * 64
            $directory = New-AtlasPreparationJob $script:Root $scope '123-456' '# inert worker' ([byte[]](1,2,3)) '# library' '# registry'
            [IO.File]::ReadAllText((Join-Path $directory 'Update-Windows.ps1')) | Should -Be '# inert worker'
            [IO.File]::ReadAllText((Join-Path $directory 'WindowsTransition.ps1')) | Should -BeExactly '# library'
            [IO.File]::ReadAllText((Join-Path $directory 'RegistryFile.ps1')) | Should -BeExactly '# registry'
            foreach ($file in @('Update-Windows.ps1', 'WindowsTransition.ps1', 'RegistryFile.ps1', 'DriverPolicy.reg', 'worker.log', 'updates.log')) {
                Assert-AtlasRecoveryFileSecurity (Join-Path $directory $file)
            }
            Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'cancel') (Get-AtlasCancellationSecurity)
            { [IO.File]::WriteAllText((Join-Path $directory 'Update-Windows.ps1'), 'x') } | Should -Throw
            [IO.File]::ReadAllText((Join-Path $directory 'cancel')) | Should -Be ''
            [IO.File]::WriteAllText((Join-Path $directory 'cancel'), 'cancel')
            [IO.File]::ReadAllText((Join-Path $directory 'cancel')) | Should -Be 'cancel'
            { New-AtlasPreparationJob $script:Root $scope '123-456' '# changed' ([byte[]](4,5)) } | Should -Throw
            [IO.File]::ReadAllText((Join-Path $directory 'Update-Windows.ps1')) | Should -Be '# inert worker'
        }
    }
    It 'refuses path traversal in preparation namespaces and job names' {
        { New-AtlasPreparationJob $script:Root '../other' '123-456' '' ([byte[]]@()) } | Should -Throw '*identity*'
        { New-AtlasPreparationJob $script:Root ('a' * 64) '../other' '' ([byte[]]@()) } | Should -Throw '*identity*'
    }
    It 'stages media worker files from the app request immutably' {
        $scope = 'b' * 64
        # The shape the app sends on standard input: file contents as byte arrays.
        $request = '{"files":[{"name":"Write-Usb.ps1","bytes":[35,32,105,110,101,114,116]},{"name":"usb-request.json","bytes":[]}]}' | ConvertFrom-Json
        $directory = New-AtlasMediaJob $script:Root $scope '123-456' @($request.files)
        $directory | Should -Be (Join-Path $script:Root "Media\$scope\123-456")
        [IO.File]::ReadAllText((Join-Path $directory 'Write-Usb.ps1')) | Should -Be '# inert'
        [IO.File]::ReadAllBytes((Join-Path $directory 'usb-request.json')) | Should -HaveCount 0
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'Write-Usb.ps1')
        Assert-AtlasRecoveryFileSecurity (Join-Path $directory 'usb-request.json')
        { New-AtlasMediaJob $script:Root $scope '123-456' @([pscustomobject]@{ name='Write-Usb.ps1'; bytes=[byte[]](1) }) } | Should -Throw
        [IO.File]::ReadAllText((Join-Path $directory 'Write-Usb.ps1')) | Should -Be '# inert'
    }
    It 'creates an empty media job that the worker is staged into later' {
        $scope = 'c' * 64
        # The ISO page creates the job before anything can fail, so a failure
        # always has a folder to leave its error in.
        $request = '{"files":[]}' | ConvertFrom-Json
        $directory = New-AtlasMediaJob $script:Root $scope '123-456' @($request.files)
        @(Get-ChildItem -LiteralPath $directory -Force) | Should -HaveCount 0
        $request = '{"files":[{"name":"Build-Iso.ps1","bytes":[35,32,105,110,101,114,116]}]}' | ConvertFrom-Json
        New-AtlasMediaJob $script:Root $scope '123-456' @($request.files) | Should -Be $directory
        [IO.File]::ReadAllText((Join-Path $directory 'Build-Iso.ps1')) | Should -Be '# inert'
    }
    It 'refuses path traversal in media namespaces, job names and file names' {
        { New-AtlasMediaJob $script:Root '../other' '123-456' @() } | Should -Throw '*identity*'
        { New-AtlasMediaJob $script:Root ('a' * 64) '..\other' @() } | Should -Throw '*identity*'
        foreach ($name in @('..\Build-Iso.ps1', 'sources\Build-Iso.ps1', '.hidden', '')) {
            { New-AtlasMediaJob $script:Root ('a' * 64) '123-789' @([pscustomobject]@{ name=$name; bytes=[byte[]]@() }) } | Should -Throw '*file name*'
        }
    }
}

Describe 'Staging request dispatch' {
    BeforeAll {
        $script:StageApp = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../app/resources/prepare/Stage-App.ps1'))
        # Runs the script as Atlas Manager does, with the request on standard input.
        function Invoke-StageApp {
            param([hashtable]$Request)
            $start = New-Object Diagnostics.ProcessStartInfo (Join-Path $PSHOME 'powershell.exe')
            $start.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $script:StageApp + '"'
            $start.UseShellExecute = $false
            $start.CreateNoWindow = $true
            $start.RedirectStandardInput = $true
            $start.RedirectStandardOutput = $true
            $start.RedirectStandardError = $true
            # StandardInput writes the console input encoding's byte order mark as it opens, which
            # Atlas Manager never sends; a UTF-8 console (as on CI runners) would otherwise add one.
            $inputEncoding = [Console]::InputEncoding
            [Console]::InputEncoding = New-Object Text.UTF8Encoding $false
            try { $process = [Diagnostics.Process]::Start($start) }
            finally { [Console]::InputEncoding = $inputEncoding }
            try {
                $errorText = $process.StandardError.ReadToEndAsync()
                $process.StandardInput.Write(($Request | ConvertTo-Json -Compress))
                $process.StandardInput.Close()
                $output = $process.StandardOutput.ReadToEnd()
                $process.WaitForExit()
                return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $output; Error = $errorText.Result }
            }
            finally { $process.Dispose() }
        }
    }
    It 'refuses an unknown operation <Case> instead of copying the executable' -TestCases @(
        @{ Case = 'in the wrong case'; Operation = 'Executable' }
        @{ Case = 'when it is missing'; Operation = $null }
    ) {
        param($Case, $Operation)
        $result = Invoke-StageApp @{ operation = $Operation; source = (Join-Path $TestDrive 'missing.exe') }
        $result.ExitCode | Should -Not -Be 0 -Because $Case
        $result.Error | Should -Match 'Unknown staging operation\.'
        $result.Output | Should -BeNullOrEmpty
    }
    # The check runs before anything is created under Program Files.
    It 'exits with the linked-source code for an executable reached through a junction' {
        $target = Join-Path $TestDrive 'staged-target'
        [void][IO.Directory]::CreateDirectory($target)
        [IO.File]::WriteAllBytes((Join-Path $target 'AtlasManager.exe'), [byte[]](1, 2, 3))
        $junction = Join-Path $TestDrive 'staged-linked'
        $null = cmd.exe /d /c mklink /J "$junction" "$target"
        try {
            $result = Invoke-StageApp @{ operation = 'executable'; source = (Join-Path $junction 'AtlasManager.exe') }
        }
        finally { [IO.Directory]::Delete($junction) }
        $result.ExitCode | Should -Be $AtlasSourceLinkedExitCode
        $result.Error | Should -Match 'linked folder'
        $result.Output | Should -BeNullOrEmpty
    }
    It 'keeps the linked-source code for linked sources only' {
        $result = Invoke-StageApp @{ operation = 'executable'; source = (Join-Path $TestDrive 'missing.exe') }
        $result.ExitCode | Should -Be 1
        $result.Error | Should -Not -Match 'linked folder'
        $result.Output | Should -BeNullOrEmpty
    }
}
