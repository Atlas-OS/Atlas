BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PackageHelperPath = Join-Path -Path $script:RepoRoot -ChildPath `
        'playbook\Executables\AtlasModules\Scripts\Internal\ProcessExplorer-Package.ps1'
    $script:TogglePath = Join-Path -Path $script:RepoRoot -ChildPath `
        'playbook\Executables\AtlasModules\Toggles\Advanced\ProcessExplorer.ps1'
    . $script:PackageHelperPath
}

Describe 'Process Explorer protected package transaction' {
    BeforeEach {
        Mock Assert-AtlasProcessExplorerParent {}
        Mock Assert-AtlasProcessExplorerOperationLock {}
        Mock Stop-AtlasProcessExplorerPackageProcesses {}
        Mock Get-Acl { New-AtlasProtectedStagingAcl }
    }

    It 'rejects a custom interactive SID with a direct Modify ACE' {
        $acl = New-Object Security.AccessControl.DirectorySecurity
        $acl.SetAccessRuleProtection($true, $false)
        $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
        $interactiveUser = New-Object Security.Principal.SecurityIdentifier(
            'S-1-5-21-111111111-222222222-333333333-1001'
        )
        $acl.SetOwner($administrators)
        [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                    $administrators,
                    [Security.AccessControl.FileSystemRights]::FullControl,
                    [Security.AccessControl.AccessControlType]::Allow
                )))
        [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                    $interactiveUser,
                    [Security.AccessControl.FileSystemRights]::Modify,
                    [Security.AccessControl.AccessControlType]::Allow
                )))

        (Test-AtlasProcessExplorerProtectedAcl -Acl $acl) | Should -BeFalse
    }

    It 'models Start Menu delete-only access separately from shortcut content mutation' {
        $acl = New-Object Security.AccessControl.DirectorySecurity
        $acl.SetAccessRuleProtection($true, $false)
        $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
        $interactiveUser = New-Object Security.Principal.SecurityIdentifier(
            'S-1-5-21-111111111-222222222-333333333-1001'
        )
        $acl.SetOwner($administrators)
        [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                    $administrators,
                    [Security.AccessControl.FileSystemRights]::FullControl,
                    [Security.AccessControl.AccessControlType]::Allow
                )))
        [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                    $interactiveUser,
                    ([Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor
                        [Security.AccessControl.FileSystemRights]::Delete),
                    [Security.AccessControl.AccessControlType]::Allow
                )))

        (Test-AtlasProcessExplorerShortcutAcl -Acl $acl) | Should -BeTrue
        (Test-AtlasProcessExplorerProtectedAcl -Acl $acl) | Should -BeFalse

        [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                    $interactiveUser,
                    [Security.AccessControl.FileSystemRights]::WriteData,
                    [Security.AccessControl.AccessControlType]::Allow
                )))
        (Test-AtlasProcessExplorerShortcutAcl -Acl $acl) | Should -BeFalse
    }

    It 'keeps the old package until the explicit outer commit' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'Apps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        $operationId = [guid]::NewGuid().ToString('N')
        $backupPath = Join-Path -Path $appsPath -ChildPath "ProcessExplorer.old-$operationId"
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [void](New-Item -Path $backupPath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'new-package')
        [IO.File]::WriteAllText((Join-Path $backupPath 'procexp.exe'), 'old-package')
        $installedHash = Get-AtlasProcessExplorerFileSha256 -Path (Join-Path $packagePath 'procexp.exe')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('ab' * 32)
        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state
        $pending = New-AtlasProcessExplorerPendingInstall `
            -PackagePath $packagePath `
            -InstallState $state `
            -ImmediateDebuggerExists $false `
            -ImmediateDebuggerValue $null `
            -ImmediateDebuggerKind $null `
            -ImmediatePcwStart 3 `
            -ImmediateShortcutExists $false `
            -ImmediateShortcutBytes $null `
            -ConfigurePcw $false
        $pending.OperationId = $operationId
        $pending.Package.HadPreviousPackage = $true
        $pending.Package.InstalledSha256 = $installedHash
        $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
        $pending.Progress.PackagePublished = $true
        $pending.Progress.ShortcutApplied = $true
        $pending.Progress.DebuggerApplied = $true
        $pending.Progress.PcwApplied = $true
        $pending.Progress.OwnershipStateWritten = $true
        $pending.Phase = 'ReadyToCommit'
        Write-AtlasProcessExplorerPendingInstall -PackagePath $packagePath -Pending $pending
        $transaction = New-AtlasProcessExplorerPackageTransaction `
            -OperationId $pending.OperationId `
            -AppsPath $appsPath `
            -HadPreviousPackage $true `
            -InstalledSha256 $installedHash
        $transaction.OperationLock = [pscustomobject]@{}

        [IO.Directory]::Exists($backupPath) | Should -BeTrue
        $transaction.State | Should -Be 'Published'

        Complete-AtlasProcessExplorerPackageInstall -Transaction $transaction

        $transaction.State | Should -Be 'Committed'
        [IO.Directory]::Exists($backupPath) | Should -BeFalse
        [IO.File]::ReadAllText((Join-Path $packagePath 'procexp.exe')) |
            Should -Be 'new-package'
    }

    It 'blocks uninstall until a failed committed-backup cleanup converges' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'CommitCleanupApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        $operationId = [guid]::NewGuid().ToString('N')
        $backupPath = Join-Path -Path $appsPath -ChildPath "ProcessExplorer.old-$operationId"
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [void](New-Item -Path $backupPath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'new-package')
        [IO.File]::WriteAllText((Join-Path $backupPath 'procexp.exe'), 'old-package')
        $installedHash = Get-AtlasProcessExplorerFileSha256 -Path (Join-Path $packagePath 'procexp.exe')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('33' * 32)
        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state
        $pending = New-AtlasProcessExplorerPendingInstall `
            -PackagePath $packagePath `
            -InstallState $state `
            -ImmediateDebuggerExists $false `
            -ImmediateDebuggerValue $null `
            -ImmediateDebuggerKind $null `
            -ImmediatePcwStart 3 `
            -ImmediateShortcutExists $false `
            -ImmediateShortcutBytes $null `
            -ConfigurePcw $false
        $pending.OperationId = $operationId
        $pending.Package.HadPreviousPackage = $true
        $pending.Package.InstalledSha256 = $installedHash
        $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
        $pending.Progress.PackagePublished = $true
        $pending.Progress.ShortcutApplied = $true
        $pending.Progress.DebuggerApplied = $true
        $pending.Progress.PcwApplied = $true
        $pending.Progress.OwnershipStateWritten = $true
        $pending.Phase = 'ReadyToCommit'
        Write-AtlasProcessExplorerPendingInstall -PackagePath $packagePath -Pending $pending
        $control = @{ FailBackupCleanup = $true }
        Mock Remove-AtlasProcessExplorerDirectory {
            if ($control.FailBackupCleanup -and
                [IO.Path]::GetFullPath($Path).Equals(
                    [IO.Path]::GetFullPath($backupPath),
                    [StringComparison]::OrdinalIgnoreCase
                )) {
                throw 'injected committed-backup cleanup failure'
            }
            [IO.Directory]::Delete($Path, $true)
        }
        $script:commitCleanupAppsPath = $appsPath
        $script:commitCleanupPackagePath = $packagePath
        Mock Get-AtlasProcessExplorerLayout {
            [pscustomobject]@{
                AppsPath = $script:commitCleanupAppsPath
                PackagePath = $script:commitCleanupPackagePath
            }
        }
        $transaction = New-AtlasProcessExplorerPackageTransaction `
            -OperationId $operationId `
            -AppsPath $appsPath `
            -HadPreviousPackage $true `
            -InstalledSha256 $installedHash
        $transaction.OperationLock = [pscustomobject]@{}

        { Complete-AtlasProcessExplorerPackageInstall -Transaction $transaction } |
            Should -Throw '*injected committed-backup cleanup failure*'
        [IO.Directory]::Exists($backupPath) | Should -BeTrue
        (Read-AtlasProcessExplorerPendingInstall -PackagePath $packagePath).Phase |
            Should -Be 'Committed'
        { Uninstall-AtlasProcessExplorerPackage `
                -DependentStateRestored `
                -OperationLock ([pscustomobject]@{}) } |
            Should -Throw '*blocked until committed backup-generation cleanup completes*'
        [IO.Directory]::Exists($packagePath) | Should -BeTrue

        $control.FailBackupCleanup = $false
        $retryTransaction = New-AtlasProcessExplorerPackageTransaction `
            -OperationId $operationId `
            -AppsPath $appsPath `
            -HadPreviousPackage $true `
            -InstalledSha256 $installedHash
        $retryTransaction.OperationLock = [pscustomobject]@{}
        Complete-AtlasProcessExplorerPackageInstall -Transaction $retryTransaction
        [IO.Directory]::Exists($backupPath) | Should -BeFalse
        Uninstall-AtlasProcessExplorerPackage `
            -DependentStateRestored `
            -OperationLock ([pscustomobject]@{})
        [IO.Directory]::Exists($packagePath) | Should -BeFalse
    }

    It 'atomically restores the old package through the typed rollback' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'RollbackApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        $operationId = [guid]::NewGuid().ToString('N')
        $backupPath = Join-Path -Path $appsPath -ChildPath "ProcessExplorer.old-$operationId"
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [void](New-Item -Path $backupPath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-new')
        [IO.File]::WriteAllText((Join-Path $backupPath 'procexp.exe'), 'trusted-old')
        $installedHash = Get-AtlasProcessExplorerFileSha256 -Path (Join-Path $packagePath 'procexp.exe')
        $transaction = New-AtlasProcessExplorerPackageTransaction `
            -OperationId $operationId `
            -AppsPath $appsPath `
            -HadPreviousPackage $true `
            -InstalledSha256 $installedHash
        $transaction.OperationLock = [pscustomobject]@{}

        Undo-AtlasProcessExplorerPackageInstall -Transaction $transaction

        $transaction.State | Should -Be 'RolledBack'
        [IO.Directory]::Exists($backupPath) | Should -BeFalse
        [IO.Directory]::Exists($transaction.CandidatePath) | Should -BeFalse
        [IO.File]::ReadAllText((Join-Path $packagePath 'procexp.exe')) |
            Should -Be 'trusted-old'
    }

    It 'retains the current trusted package when the old backup is unavailable' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'MissingBackupApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        $operationId = [guid]::NewGuid().ToString('N')
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-current')
        $installedHash = Get-AtlasProcessExplorerFileSha256 -Path (Join-Path $packagePath 'procexp.exe')
        $transaction = New-AtlasProcessExplorerPackageTransaction `
            -OperationId $operationId `
            -AppsPath $appsPath `
            -HadPreviousPackage $true `
            -InstalledSha256 $installedHash
        $transaction.OperationLock = [pscustomobject]@{}

        { Undo-AtlasProcessExplorerPackageInstall -Transaction $transaction } |
            Should -Throw '*previous Process Explorer package is unavailable*'
        [IO.File]::ReadAllText((Join-Path $packagePath 'procexp.exe')) |
            Should -Be 'trusted-current'
        $transaction.State | Should -Be 'Published'
    }

    It 'checkpoints failures after IFEO and shortcut success and converges on retry' {
        $state = [pscustomobject]@{
            RestoreProgress = [pscustomobject]@{
                Debugger = $false
                Shortcut = $false
                Pcw = $false
            }
        }
        $control = @{ FailAt = 'Shortcut' }
        $calls = @{ Debugger = 0; Shortcut = 0; Pcw = 0; Persist = 0 }
        $steps = @(
            [pscustomobject]@{
                Name = 'Debugger'
                Action = { $calls.Debugger++ }.GetNewClosure()
            }
            [pscustomobject]@{
                Name = 'Shortcut'
                Action = {
                    $calls.Shortcut++
                    if ($control.FailAt -eq 'Shortcut') { throw 'injected shortcut failure' }
                }.GetNewClosure()
            }
            [pscustomobject]@{
                Name = 'Pcw'
                Action = {
                    $calls.Pcw++
                    if ($control.FailAt -eq 'Pcw') { throw 'injected pcw failure' }
                }.GetNewClosure()
            }
        )
        $persist = {
            param($Value)
            [void]$Value
            $calls.Persist++
        }.GetNewClosure()

        $first = Invoke-AtlasProcessExplorerRestorePlan `
            -State $state `
            -Steps $steps `
            -PersistState $persist
        $first.AllComplete | Should -BeFalse
        $state.RestoreProgress.Debugger | Should -BeTrue
        $state.RestoreProgress.Shortcut | Should -BeFalse

        $control.FailAt = 'Pcw'
        $second = Invoke-AtlasProcessExplorerRestorePlan `
            -State $state `
            -Steps $steps `
            -PersistState $persist
        $second.AllComplete | Should -BeFalse
        $state.RestoreProgress.Shortcut | Should -BeTrue
        $state.RestoreProgress.Pcw | Should -BeFalse

        $control.FailAt = $null
        $third = Invoke-AtlasProcessExplorerRestorePlan `
            -State $state `
            -Steps $steps `
            -PersistState $persist
        $third.AllComplete | Should -BeTrue
        $calls.Debugger | Should -Be 1
        $calls.Shortcut | Should -Be 2
        $calls.Pcw | Should -Be 2
        $calls.Persist | Should -Be 3
    }

    It 'round-trips a large pending record from a physical candidate against the canonical path' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'PendingApps'
        $canonicalPath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        $largeShortcut = New-Object byte[] 1048576
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $canonicalPath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $true `
            -ShortcutPriorBytes $largeShortcut `
            -ShortcutInstalledSha256 ('ab' * 32)
        $pending = New-AtlasProcessExplorerPendingInstall `
            -PackagePath $canonicalPath `
            -InstallState $state `
            -ImmediateDebuggerExists $false `
            -ImmediateDebuggerValue $null `
            -ImmediateDebuggerKind $null `
            -ImmediatePcwStart 3 `
            -ImmediateShortcutExists $true `
            -ImmediateShortcutBytes $largeShortcut `
            -ConfigurePcw $false
        $pending.Package.InstalledSha256 = ('cd' * 32)
        $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
        $candidatePath = Join-Path -Path $appsPath -ChildPath (
            'ProcessExplorer.new-' + $pending.OperationId
        )
        [void](New-Item -Path $candidatePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $candidatePath 'procexp.exe'), 'candidate')

        Write-AtlasProcessExplorerPendingInstall `
            -PackagePath $candidatePath `
            -CanonicalPackagePath $canonicalPath `
            -Pending $pending
        $pendingPath = Join-Path $candidatePath 'Atlas.ProcessExplorer.Pending.json'
        (Get-Item -LiteralPath $pendingPath).Length | Should -BeGreaterThan 2097152
        (Get-Item -LiteralPath $pendingPath).Length | Should -BeLessOrEqual 4194304

        $roundTrip = Read-AtlasProcessExplorerPendingInstall `
            -PackagePath $candidatePath `
            -CanonicalPackagePath $canonicalPath
        $roundTrip.OperationId | Should -Be $pending.OperationId
        $roundTrip.Desired.DebuggerValue | Should -Be (
            Join-Path $canonicalPath 'procexp.exe'
        )
    }

    It 'recovers fresh-start candidates interrupted before and during the first pending write' {
        foreach ($withInterruptedTemp in @($false, $true)) {
            $appsPath = Join-Path -Path $TestDrive -ChildPath (
                'PrePendingApps-' + [int]$withInterruptedTemp
            )
            $canonicalPath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
            $operationId = [guid]::NewGuid().ToString('N')
            $candidatePath = Join-Path -Path $appsPath -ChildPath (
                'ProcessExplorer.new-' + $operationId
            )
            [void](New-Item -Path $canonicalPath -ItemType Directory -Force)
            [void](New-Item -Path $candidatePath -ItemType Directory -Force)
            [IO.File]::WriteAllText((Join-Path $canonicalPath 'procexp.exe'), 'old')
            [IO.File]::WriteAllText((Join-Path $candidatePath 'procexp.exe'), 'new')
            if ($withInterruptedTemp) {
                $tempPath = Join-Path $candidatePath (
                    'Atlas.ProcessExplorer.Pending.json.new-' + [guid]::NewGuid().ToString('N')
                )
                [IO.File]::WriteAllBytes($tempPath, (New-Object byte[] 3145728))
            }

            $result = Repair-AtlasProcessExplorerPackageGenerations `
                -OperationLock ([pscustomobject]@{}) `
                -AppsPath $appsPath
            $result | Should -BeNullOrEmpty
            [IO.Directory]::Exists($candidatePath) | Should -BeFalse
            [IO.File]::ReadAllText((Join-Path $canonicalPath 'procexp.exe')) |
                Should -Be 'old'
        }
    }

    It 'recovers both caught rename topologies without stranding the old generation' {
        foreach ($candidatePublished in @($false, $true)) {
            $appsPath = Join-Path -Path $TestDrive -ChildPath (
                'CaughtRenameApps-' + [int]$candidatePublished
            )
            $canonicalPath = Join-Path $appsPath 'ProcessExplorer'
            $operationId = [guid]::NewGuid().ToString('N')
            $candidatePath = Join-Path $appsPath "ProcessExplorer.new-$operationId"
            $backupPath = Join-Path $appsPath "ProcessExplorer.old-$operationId"
            [void](New-Item -Path $candidatePath -ItemType Directory -Force)
            [void](New-Item -Path $backupPath -ItemType Directory -Force)
            [IO.File]::WriteAllText((Join-Path $candidatePath 'procexp.exe'), 'new-package')
            [IO.File]::WriteAllText((Join-Path $backupPath 'procexp.exe'), 'old-package')
            $state = New-AtlasProcessExplorerInstallState `
                -PackagePath $canonicalPath `
                -DebuggerPriorExists $false `
                -DebuggerPriorValue $null `
                -DebuggerPriorKind $null `
                -PcwChanged $false `
                -PcwPriorStart 3 `
                -ShortcutPriorExists $false `
                -ShortcutPriorBytes $null `
                -ShortcutInstalledSha256 ('11' * 32)
            $pending = New-AtlasProcessExplorerPendingInstall `
                -PackagePath $canonicalPath `
                -InstallState $state `
                -ImmediateDebuggerExists $false `
                -ImmediateDebuggerValue $null `
                -ImmediateDebuggerKind $null `
                -ImmediatePcwStart 3 `
                -ImmediateShortcutExists $false `
                -ImmediateShortcutBytes $null `
                -ConfigurePcw $false
            $pending.OperationId = $operationId
            $pending.Package.HadPreviousPackage = $true
            $pending.Package.InstalledSha256 = ('22' * 32)
            $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
            Write-AtlasProcessExplorerPendingInstall `
                -PackagePath $candidatePath `
                -CanonicalPackagePath $canonicalPath `
                -Pending $pending
            if ($candidatePublished) {
                [IO.Directory]::Move($candidatePath, $canonicalPath)
            }

            $context = Repair-AtlasProcessExplorerPackageGenerations `
                -OperationLock ([pscustomobject]@{}) `
                -AppsPath $appsPath
            if ($candidatePublished) {
                $context | Should -Not -BeNullOrEmpty
                Undo-AtlasProcessExplorerPackageInstall -Transaction $context.Transaction
            }
            else {
                $context | Should -BeNullOrEmpty
            }
            [IO.File]::ReadAllText((Join-Path $canonicalPath 'procexp.exe')) |
                Should -Be 'old-package'
            [IO.Directory]::Exists($backupPath) | Should -BeFalse
            [IO.Directory]::Exists($candidatePath) | Should -BeFalse
        }
    }

    It 'retains the package when durable dependent restoration fails' {
        $appsPath = Join-Path $TestDrive 'DependentFailureApps'
        $packagePath = Join-Path $appsPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'retained-package')
        $state = [pscustomobject]@{
            RestoreProgress = [pscustomobject]@{
                Debugger = $false
                Shortcut = $false
                Pcw = $false
            }
        }
        $steps = @(
            [pscustomobject]@{ Name = 'Debugger'; Action = { throw 'injected restore failure' } }
            [pscustomobject]@{ Name = 'Shortcut'; Action = {} }
            [pscustomobject]@{ Name = 'Pcw'; Action = {} }
        )
        $result = Invoke-AtlasProcessExplorerRestorePlan `
            -State $state `
            -Steps $steps `
            -PersistState {}
        Mock Get-AtlasProcessExplorerLayout {
            [pscustomobject]@{ AppsPath = $appsPath; PackagePath = $packagePath }
        }

        { Uninstall-AtlasProcessExplorerPackage `
                -DependentStateRestored:$result.AllComplete `
                -OperationLock ([pscustomobject]@{}) } |
            Should -Throw '*requires confirmed dependent-state restoration*'
        [IO.File]::ReadAllText((Join-Path $packagePath 'procexp.exe')) |
            Should -Be 'retained-package'
    }

    It 'serializes two processes through the protected Apps lock' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'LockApps'
        [void](New-Item -Path $appsPath -ItemType Directory -Force)
        $lockPath = Join-Path -Path $appsPath -ChildPath 'Atlas.ProcessExplorer.lock'
        $stream = $null
        try {
            $stream = New-Object IO.FileStream(
                $lockPath,
                [IO.FileMode]::OpenOrCreate,
                [IO.FileAccess]::ReadWrite,
                [IO.FileShare]::None
            )
            $escapedLock = $lockPath.Replace("'", "''")
            $childCode = @"
try {
    `$childLock = New-Object IO.FileStream('$escapedLock',[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    `$childLock.Dispose()
    exit 0
}
catch [IO.IOException] { exit 42 }
"@
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCode))
            $hostExecutable = if ($PSVersionTable.PSEdition -eq 'Core') {
                Join-Path $PSHOME 'pwsh.exe'
            }
            else { Join-Path $PSHOME 'powershell.exe' }
            $blocked = Start-Process -FilePath $hostExecutable `
                -ArgumentList @('-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded) `
                -Wait -PassThru
            $blocked.ExitCode | Should -Be 42
            $stream.Dispose()
            $stream = $null

            $acquired = Start-Process -FilePath $hostExecutable `
                -ArgumentList @('-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded) `
                -Wait -PassThru
            $acquired.ExitCode | Should -Be 0
        }
        finally {
            if ($null -ne $stream) { $stream.Dispose() }
        }
    }
}

Describe 'Process Explorer ownership state' {
    BeforeEach {
        Mock Assert-AtlasProcessExplorerParent {}
        Mock Get-Acl { New-AtlasProtectedStagingAcl }
    }

    It 'round-trips prior Debugger kind, pcw Start, and shortcut bytes' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'StateApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $priorShortcutBytes = [Text.Encoding]::UTF8.GetBytes('prior-shortcut-state')
        $installedShortcutHash = ('ab' * 32)
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $true `
            -DebuggerPriorValue '%SystemRoot%\System32\custom-debugger.exe' `
            -DebuggerPriorKind 'ExpandString' `
            -PcwChanged $true `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $true `
            -ShortcutPriorBytes $priorShortcutBytes `
            -ShortcutInstalledSha256 $installedShortcutHash

        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state
        $roundTrip = Read-AtlasProcessExplorerInstallState -PackagePath $packagePath

        $roundTrip.PSObject.TypeNames | Should -Contain 'Atlas.ProcessExplorer.InstallState'
        $roundTrip.Debugger.PriorExists | Should -BeTrue
        $roundTrip.Debugger.PriorValue | Should -Be '%SystemRoot%\System32\custom-debugger.exe'
        $roundTrip.Debugger.PriorKind | Should -Be 'ExpandString'
        $roundTrip.Pcw.Changed | Should -BeTrue
        $roundTrip.Pcw.PriorStart | Should -Be 3
        [Convert]::FromBase64String([string]$roundTrip.Shortcut.PriorBytesBase64) |
            Should -Be $priorShortcutBytes
        $roundTrip.Shortcut.InstalledSha256 | Should -Be $installedShortcutHash
    }

    It 'atomically replaces shortcut, ownership, and pending checkpoint files' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'ReplaceApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('12' * 32)
        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state
        $firstInstallId = $state.InstallId
        $state.InstallId = [guid]::NewGuid().ToString('N')
        Write-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -State $state `
            -ReplaceExisting
        (Read-AtlasProcessExplorerInstallState -PackagePath $packagePath).InstallId |
            Should -Not -Be $firstInstallId

        $pending = New-AtlasProcessExplorerPendingInstall `
            -PackagePath $packagePath `
            -InstallState $state `
            -ImmediateDebuggerExists $false `
            -ImmediateDebuggerValue $null `
            -ImmediateDebuggerKind $null `
            -ImmediatePcwStart 3 `
            -ImmediateShortcutExists $false `
            -ImmediateShortcutBytes $null `
            -ConfigurePcw $false
        $pending.Package.InstalledSha256 = ('34' * 32)
        $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
        Write-AtlasProcessExplorerPendingInstall -PackagePath $packagePath -Pending $pending
        $pending.Progress.ShortcutApplied = $true
        Write-AtlasProcessExplorerPendingInstall `
            -PackagePath $packagePath `
            -Pending $pending `
            -ReplaceExisting
        (Read-AtlasProcessExplorerPendingInstall -PackagePath $packagePath).Progress.ShortcutApplied |
            Should -BeTrue

        $shortcutParent = Join-Path -Path $TestDrive -ChildPath 'Programs'
        [void](New-Item -Path $shortcutParent -ItemType Directory -Force)
        $shortcutPath = Join-Path -Path $shortcutParent -ChildPath 'Process Explorer.lnk'
        [IO.File]::WriteAllBytes($shortcutPath, [byte[]](1, 2, 3))
        $replacementBytes = [byte[]](4, 5, 6, 7)
        $priorShortcutHash = Get-AtlasProcessExplorerFileSha256 -Path $shortcutPath
        [void](Set-AtlasProcessExplorerShortcutBytesAtomically `
            -Path $shortcutPath `
            -Bytes $replacementBytes `
            -ArtifactId ([guid]::NewGuid().ToString('N')) `
            -AlternateSha256 $priorShortcutHash)
        [IO.File]::ReadAllBytes($shortcutPath) | Should -Be $replacementBytes
        @(Get-ChildItem -LiteralPath $shortcutParent -Filter '*.atlas-*') |
            Should -HaveCount 0
    }

    It 'cleans an interrupted restore temp while preserving the durable Immediate shortcut' {
        $parent = Join-Path $TestDrive 'ShortcutRestoreCrash'
        [void](New-Item -Path $parent -ItemType Directory -Force)
        $path = Join-Path $parent 'Process Explorer.lnk'
        $artifactId = [guid]::NewGuid().ToString('N')
        $immediateBytes = [Text.Encoding]::UTF8.GetBytes('immediate-shortcut')
        $desiredBytes = [Text.Encoding]::UTF8.GetBytes('desired-shortcut')
        [IO.File]::WriteAllBytes($path, $immediateBytes)
        [IO.File]::WriteAllBytes("$path.atlas-restore-$artifactId", $desiredBytes)
        $immediateHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $immediateBytes
        $desiredHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $desiredBytes

        $result = Repair-AtlasProcessExplorerShortcutArtifacts `
            -Path $path `
            -ArtifactId $artifactId `
            -TargetExists $true `
            -TargetSha256 $immediateHash `
            -AlternateSha256 $desiredHash `
            -AllowCompleteTarget

        $result.TargetSatisfied | Should -BeTrue
        [IO.File]::ReadAllBytes($path) | Should -Be $immediateBytes
        @(Get-ChildItem -LiteralPath $parent -Filter '*.atlas-*') | Should -HaveCount 0
    }

    It 'cleans an interrupted backup after the durable shortcut is already restored' {
        $parent = Join-Path $TestDrive 'ShortcutBackupCrash'
        [void](New-Item -Path $parent -ItemType Directory -Force)
        $path = Join-Path $parent 'Process Explorer.lnk'
        $artifactId = [guid]::NewGuid().ToString('N')
        $priorBytes = [Text.Encoding]::UTF8.GetBytes('prior-shortcut')
        $installedBytes = [Text.Encoding]::UTF8.GetBytes('installed-shortcut')
        [IO.File]::WriteAllBytes($path, $priorBytes)
        [IO.File]::WriteAllBytes("$path.atlas-backup-$artifactId", $installedBytes)
        $priorHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $priorBytes
        $installedHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $installedBytes

        $result = Repair-AtlasProcessExplorerShortcutArtifacts `
            -Path $path `
            -ArtifactId $artifactId `
            -TargetExists $true `
            -TargetSha256 $priorHash `
            -AlternateSha256 $installedHash `
            -AllowCompleteTarget

        $result.TargetSatisfied | Should -BeTrue
        [IO.File]::ReadAllBytes($path) | Should -Be $priorBytes
        @(Get-ChildItem -LiteralPath $parent -Filter '*.atlas-*') | Should -HaveCount 0
    }

    It 'promotes a durable backup target after an interrupted shortcut replacement' {
        $parent = Join-Path $TestDrive 'ShortcutPromoteCrash'
        [void](New-Item -Path $parent -ItemType Directory -Force)
        $path = Join-Path $parent 'Process Explorer.lnk'
        $artifactId = [guid]::NewGuid().ToString('N')
        $immediateBytes = [Text.Encoding]::UTF8.GetBytes('immediate-target')
        $desiredBytes = [Text.Encoding]::UTF8.GetBytes('desired-primary')
        [IO.File]::WriteAllBytes($path, $desiredBytes)
        [IO.File]::WriteAllBytes("$path.atlas-backup-$artifactId", $immediateBytes)
        $immediateHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $immediateBytes
        $desiredHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $desiredBytes

        $result = Repair-AtlasProcessExplorerShortcutArtifacts `
            -Path $path `
            -ArtifactId $artifactId `
            -TargetExists $true `
            -TargetSha256 $immediateHash `
            -AlternateSha256 $desiredHash `
            -AllowCompleteTarget

        $result.TargetSatisfied | Should -BeTrue
        [IO.File]::ReadAllBytes($path) | Should -Be $immediateBytes
        @(Get-ChildItem -LiteralPath $parent -Filter '*.atlas-*') | Should -HaveCount 0
    }

    It 'preserves contradictory, foreign, and unknown shortcut artifacts' {
        $parent = Join-Path $TestDrive 'ShortcutArtifactRejects'
        [void](New-Item -Path $parent -ItemType Directory -Force)
        $path = Join-Path $parent 'Process Explorer.lnk'
        $artifactId = [guid]::NewGuid().ToString('N')
        $foreignId = [guid]::NewGuid().ToString('N')
        $immediateBytes = [Text.Encoding]::UTF8.GetBytes('strict-immediate')
        $desiredBytes = [Text.Encoding]::UTF8.GetBytes('strict-desired')
        $unknownBytes = [Text.Encoding]::UTF8.GetBytes('unknown-artifact')
        $immediateHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $immediateBytes
        $desiredHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $desiredBytes
        [IO.File]::WriteAllBytes($path, $immediateBytes)
        $restorePath = "$path.atlas-restore-$artifactId"
        [IO.File]::WriteAllBytes($restorePath, $desiredBytes)

        { Repair-AtlasProcessExplorerShortcutArtifacts `
                -Path $path `
                -ArtifactId $artifactId `
                -TargetExists $true `
                -TargetSha256 $desiredHash `
                -AlternateSha256 $immediateHash } |
            Should -Throw '*contradicts its durable completed phase*'
        [IO.File]::Exists($restorePath) | Should -BeTrue

        [IO.File]::Delete($restorePath)
        $foreignPath = "$path.atlas-backup-$foreignId"
        [IO.File]::WriteAllBytes($foreignPath, $desiredBytes)
        { Repair-AtlasProcessExplorerShortcutArtifacts `
                -Path $path `
                -ArtifactId $artifactId `
                -TargetExists $true `
                -TargetSha256 $immediateHash `
                -AlternateSha256 $desiredHash `
                -AllowCompleteTarget } |
            Should -Throw '*foreign*'
        [IO.File]::Exists($foreignPath) | Should -BeTrue

        [IO.File]::Delete($foreignPath)
        $unknownPath = "$path.atlas-backup-$artifactId"
        [IO.File]::WriteAllBytes($unknownPath, $unknownBytes)
        { Repair-AtlasProcessExplorerShortcutArtifacts `
                -Path $path `
                -ArtifactId $artifactId `
                -TargetExists $true `
                -TargetSha256 $immediateHash `
                -AlternateSha256 $desiredHash `
                -AllowCompleteTarget } |
            Should -Throw '*unknown bytes*'
        [IO.File]::Exists($unknownPath) | Should -BeTrue
    }

    It 'reconciles valid primary state and pending records left with displaced failed generations' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'FailedRecordRecoveryApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('bc' * 32)
        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state
        $statePath = Join-Path $packagePath 'Atlas.ProcessExplorer.State.json'
        $stateFailed = "$statePath.failed-$([guid]::NewGuid().ToString('N'))"
        [IO.File]::WriteAllText($stateFailed, 'displaced-old-state')
        (Read-AtlasProcessExplorerInstallState -PackagePath $packagePath).InstallId |
            Should -Be $state.InstallId
        [IO.File]::Exists($stateFailed) | Should -BeFalse

        $pending = New-AtlasProcessExplorerPendingInstall `
            -PackagePath $packagePath `
            -InstallState $state `
            -ImmediateDebuggerExists $false `
            -ImmediateDebuggerValue $null `
            -ImmediateDebuggerKind $null `
            -ImmediatePcwStart 3 `
            -ImmediateShortcutExists $false `
            -ImmediateShortcutBytes $null `
            -ConfigurePcw $false
        $pending.Package.InstalledSha256 = ('de' * 32)
        $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
        Write-AtlasProcessExplorerPendingInstall -PackagePath $packagePath -Pending $pending
        $pendingPath = Join-Path $packagePath 'Atlas.ProcessExplorer.Pending.json'
        $pendingFailed = "$pendingPath.failed-$([guid]::NewGuid().ToString('N'))"
        [IO.File]::WriteAllText($pendingFailed, 'displaced-old-pending')
        (Read-AtlasProcessExplorerPendingInstall -PackagePath $packagePath).OperationId |
            Should -Be $pending.OperationId
        [IO.File]::Exists($pendingFailed) | Should -BeFalse
    }

    It 'restores the previous ownership checkpoint when the replacement primary is corrupted' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'CorruptStateReplaceApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('56' * 32)
        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state
        $previousInstallId = [string]$state.InstallId
        $state.InstallId = [guid]::NewGuid().ToString('N')
        $statePath = Join-Path $packagePath 'Atlas.ProcessExplorer.State.json'

        Mock ConvertFrom-AtlasProcessExplorerJsonFile {
            [IO.File]::WriteAllText($Path, '{injected-corruption')
            throw 'injected new-primary corruption'
        } -ParameterFilter { $Path -eq $statePath }

        { Write-AtlasProcessExplorerInstallState `
                -PackagePath $packagePath `
                -State $state `
                -ReplaceExisting } |
            Should -Throw '*did not retain the intended record*'
        $restored = [IO.File]::ReadAllText($statePath) | ConvertFrom-Json
        $restored.InstallId | Should -Be $previousInstallId
        @(Get-ChildItem -LiteralPath $packagePath -Filter 'Atlas.ProcessExplorer.State.json.*-*') |
            Should -HaveCount 0
    }

    It 'restores the previous pending checkpoint when the replacement primary is corrupted' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'CorruptPendingReplaceApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('78' * 32)
        $pending = New-AtlasProcessExplorerPendingInstall `
            -PackagePath $packagePath `
            -InstallState $state `
            -ImmediateDebuggerExists $false `
            -ImmediateDebuggerValue $null `
            -ImmediateDebuggerKind $null `
            -ImmediatePcwStart 3 `
            -ImmediateShortcutExists $false `
            -ImmediateShortcutBytes $null `
            -ConfigurePcw $false
        $pending.Package.InstalledSha256 = ('9a' * 32)
        $pending.Desired.ShortcutSha256 = [string]$state.Shortcut.InstalledSha256
        Write-AtlasProcessExplorerPendingInstall -PackagePath $packagePath -Pending $pending
        $pending.Progress.ShortcutApplied = $true
        $pendingPath = Join-Path $packagePath 'Atlas.ProcessExplorer.Pending.json'

        Mock ConvertFrom-AtlasProcessExplorerJsonFile {
            [IO.File]::WriteAllText($Path, '{injected-corruption')
            throw 'injected new-primary corruption'
        } -ParameterFilter { $Path -eq $pendingPath }

        { Write-AtlasProcessExplorerPendingInstall `
                -PackagePath $packagePath `
                -Pending $pending `
                -ReplaceExisting } |
            Should -Throw '*did not retain the intended record*'
        $restored = [IO.File]::ReadAllText($pendingPath) | ConvertFrom-Json
        $restored.Progress.ShortcutApplied | Should -BeFalse
        @(Get-ChildItem -LiteralPath $packagePath -Filter 'Atlas.ProcessExplorer.Pending.json.*-*') |
            Should -HaveCount 0
    }

    It 'rejects a tampered shortcut ownership snapshot' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'TamperedStateApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $true `
            -ShortcutPriorBytes ([byte[]](1, 2, 3)) `
            -ShortcutInstalledSha256 ('cd' * 32)
        $state.Shortcut.PriorBytesBase64 = [Convert]::ToBase64String([byte[]](4, 5, 6))

        { Assert-AtlasProcessExplorerInstallState -State $state -PackagePath $packagePath } |
            Should -Throw '*snapshot failed its hash check*'
    }

    It 'accepts protected prior state after a future package pin changes' {
        $appsPath = Join-Path -Path $TestDrive -ChildPath 'PriorVersionStateApps'
        $packagePath = Join-Path -Path $appsPath -ChildPath 'ProcessExplorer'
        [void](New-Item -Path $packagePath -ItemType Directory -Force)
        [IO.File]::WriteAllText((Join-Path $packagePath 'procexp.exe'), 'trusted-package')
        $state = New-AtlasProcessExplorerInstallState `
            -PackagePath $packagePath `
            -DebuggerPriorExists $false `
            -DebuggerPriorValue $null `
            -DebuggerPriorKind $null `
            -PcwChanged $false `
            -PcwPriorStart 3 `
            -ShortcutPriorExists $false `
            -ShortcutPriorBytes $null `
            -ShortcutInstalledSha256 ('ef' * 32)
        $state.SchemaVersion = 1
        $state.PSObject.Properties.Remove('RestoreProgress')
        Write-AtlasProcessExplorerInstallState -PackagePath $packagePath -State $state

        $previousPin = $script:AtlasProcessExplorerVersion
        try {
            $script:AtlasProcessExplorerVersion = '18.0'
            $priorState = Read-AtlasProcessExplorerInstallState -PackagePath $packagePath
            $priorState.PackageVersion | Should -Be $previousPin
            $priorState.SchemaVersion | Should -Be 2
        }
        finally {
            $script:AtlasProcessExplorerVersion = $previousPin
        }
    }

    It 'orders ownership persistence before commit and restoration before package removal' {
        $toggle = Get-Content -LiteralPath $script:TogglePath -Raw
        $writeState = $toggle.IndexOf('Write-AtlasProcessExplorerInstallState')
        $commit = $toggle.IndexOf('Complete-AtlasProcessExplorerPackageInstall')
        $restorationGate = $toggle.LastIndexOf('$restoreResult.Failures.Count -ne 0')
        $packageRemoval = $toggle.LastIndexOf('Uninstall-AtlasProcessExplorerPackage')

        $toggle | Should -Match 'refusing to replace a non-Atlas Task Manager Debugger'
        $toggle | Should -Match 'if \(-not \$debuggerOwned -and -not \$debuggerAlreadyRestored\)[\s\S]+?throw'
        $toggle | Should -Match 'InstalledSha256[\s\S]+?Get-AtlasProcessExplorerShortcutState'
        $writeState | Should -BeGreaterThan -1
        $commit | Should -BeGreaterThan $writeState
        $restorationGate | Should -BeGreaterThan $commit
        $packageRemoval | Should -BeGreaterThan $restorationGate
    }
}

Describe 'Process Explorer host shortcut boundary' {
    It 'accepts the real common Start Menu ACL without treating it as a protected package ACL' {
        $programsPath = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) 'Programs'
        $acl = Microsoft.PowerShell.Security\Get-Acl -LiteralPath $programsPath -ErrorAction Stop

        (Test-AtlasProcessExplorerShortcutAcl -Acl $acl) | Should -BeTrue
    }
}
