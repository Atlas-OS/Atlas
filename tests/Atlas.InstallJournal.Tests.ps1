BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    $script:journalModulePath = Join-Path -Path $modulesRoot -ChildPath 'Atlas.InstallJournal\Atlas.InstallJournal.psd1'
    Import-Module -Name $script:journalModulePath -Force

    function New-TestAtlasJournalPath {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'This test-only factory creates an isolated Pester TestDrive directory.'
        )]
        param()

        $directory = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString('N'))
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        return Join-Path -Path $directory -ChildPath 'active.json'
    }
}

Describe 'Atlas install journal schema and persistence' {
    It 'freezes source, target, mode, sorted options and the ordered recovery plan' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $journal = New-AtlasInstallJournal -JournalPath $JournalPath `
                -SourceVersion '0.5.1' -TargetVersion '0.6.0' -Mode Upgrade `
                -InteractiveUserSid 'S-1-5-21-100-200-300-1001' `
                -Options @('uninstall-edge', 'browser-brave', 'browser-brave') `
                -PhasePlan @(
                    @{ Key = 'Payload/Activate'; RecoveryPolicy = 'Reconcile'; Required = $true }
                    @{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent'; Required = $true }
                    'External/Appx'
                )

            $journal.schemaVersion | Should -Be 1
            $journal.sourceVersion | Should -BeExactly '0.5.1'
            $journal.targetVersion | Should -BeExactly '0.6.0'
            $journal.mode | Should -BeExactly 'Upgrade'
            $journal.interactiveUserSid | Should -BeExactly 'S-1-5-21-100-200-300-1001'
            $journal.initiatingPrincipalSid | Should -Match '^S-1-'
            @($journal.options) | Should -Be @('browser-brave', 'uninstall-edge')
            @($journal.phases.key) | Should -Be @('Payload/Activate', 'PreInstall', 'External/Appx')
            $journal.phases[2].recoveryPolicy | Should -BeExactly 'Manual'
            $journal.phases[0].postcondition | Should -BeExactly 'CallerVerified'
            $journal.phases[2].postcondition | Should -BeExactly 'ManualVerification'
            $journal.identitySha256 | Should -Match '^[a-f0-9]{64}$'
            $journal.payload.generationState | Should -BeExactly 'NotManaged'
            Test-Path -LiteralPath $JournalPath -PathType Leaf | Should -BeTrue
            @(Get-ChildItem -LiteralPath (Split-Path -Parent $JournalPath) -Filter '*.tmp') | Should -BeNullOrEmpty
        }
    }

    It 'refuses to replace an existing active transaction, including the same target version' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $arguments = @{
                JournalPath  = $JournalPath
                TargetVersion = '0.6.0'
                Mode          = 'Fresh'
                PhasePlan     = @('PreInstall')
            }
            New-AtlasInstallJournal @arguments | Out-Null
            { New-AtlasInstallJournal @arguments } | Should -Throw -ExpectedMessage '*active Atlas install journal already exists*'
        }
    }

    It 'never retires a Failed transaction or changes its diagnostic bytes' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Upgrade `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Set-AtlasInstallJournalPhaseFailed -JournalPath $JournalPath -PhaseKey PreInstall `
                -Message 'Injected terminal failure.' | Out-Null
            $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($JournalPath))

            { New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Upgrade `
                    -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) } |
                Should -Throw -ExpectedMessage "*state 'Failed'*"
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($JournalPath)) | Should -BeExactly $before
            Test-Path -LiteralPath (Join-Path (Split-Path -Parent $JournalPath) 'archive') | Should -BeFalse
        }
    }

    It 'resumes the frozen original transaction instead of accepting AME reclassification' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $created = New-AtlasInstallJournal -JournalPath $JournalPath -SourceVersion '0.5.1' `
                -TargetVersion '0.6.0' -Mode Upgrade -Options @('uninstall-edge') `
                -PhasePlan @(@{ Key = 'Payload/Activate'; RecoveryPolicy = 'Reconcile' })
            $resumed = Resume-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0'

            $resumed.mode | Should -BeExactly 'Upgrade'
            @($resumed.options) | Should -Be @('uninstall-edge')
            $resumed.identitySha256 | Should -BeExactly $created.identitySha256
            $resumed.resumeCount | Should -Be 1
            { Resume-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.7.0' } |
                Should -Throw -ExpectedMessage "*targets '0.6.0', not '0.7.0'*"
        }
    }

    It 'rotates an atomic backup and increments the document revision' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null

            $primary = Read-AtlasJournalFile -Path $JournalPath
            $backup = Read-AtlasJournalFile -Path "$JournalPath.bak"
            $primary.revision | Should -Be 1
            $backup.revision | Should -Be 0
            $primary.phases[0].state | Should -BeExactly 'Running'
            $backup.phases[0].state | Should -BeExactly 'Pending'
        }
    }

    It 'fails closed and preserves both files when the primary is corrupt but its backup is valid' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            $backupBytes = [IO.File]::ReadAllBytes("$JournalPath.bak")
            [IO.File]::WriteAllText($JournalPath, '{broken')

            { Get-AtlasInstallJournal -JournalPath $JournalPath } |
                Should -Throw -ExpectedMessage '*backup is valid but may be stale and was not used*'
            [IO.File]::ReadAllText($JournalPath) | Should -BeExactly '{broken'
            [Convert]::ToBase64String([IO.File]::ReadAllBytes("$JournalPath.bak")) |
                Should -BeExactly ([Convert]::ToBase64String($backupBytes))
        }
    }

    It 'fails closed when immutable identity fields are changed without a matching identity hash' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @('PreInstall') | Out-Null
            $document = Get-Content -LiteralPath $JournalPath -Raw | ConvertFrom-Json
            $document.targetVersion = '9.9.9'
            [IO.File]::WriteAllText(
                $JournalPath,
                ($document | ConvertTo-Json -Depth 24),
                (New-Object Text.UTF8Encoding($false, $true))
            )

            { Get-AtlasInstallJournal -JournalPath $JournalPath } |
                Should -Throw -ExpectedMessage '*immutable identity hash*'
        }
    }

    It 'checksums the entire mutable document, not only the immutable identity' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @('PreInstall') | Out-Null
            $document = Get-Content -LiteralPath $JournalPath -Raw | ConvertFrom-Json
            $document.resumeCount = 99
            [IO.File]::WriteAllText(
                $JournalPath,
                ($document | ConvertTo-Json -Depth 24),
                (New-Object Text.UTF8Encoding($false, $true))
            )

            { Get-AtlasInstallJournal -JournalPath $JournalPath } |
                Should -Throw -ExpectedMessage '*document checksum does not match*'
        }
    }

    It 'keeps the top-level checksum slot unambiguous when compensation data uses the same property name' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @('PreInstall') | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Register-AtlasInstallCompensation -JournalPath $JournalPath -Id NestedChecksum -Kind RegistrySnapshot `
                -OwnerPhase PreInstall -RecoveryPolicy Reconcile `
                -Data @{ documentSha256 = ('f' * 64); retained = $true } | Out-Null

            $journal = Get-AtlasInstallJournal -JournalPath $JournalPath
            $journal.compensations[0].data.documentSha256 | Should -BeExactly ('f' * 64)
            (Get-Content -LiteralPath $JournalPath -Raw).TrimStart() |
                Should -Match '^\{\s*"documentSha256"'
        }
    }

    It 'rejects malformed UTF-8 and oversized documents before JSON planning' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            [IO.File]::WriteAllBytes($JournalPath, [byte[]]@(0x7B, 0x22, 0xC3, 0x28, 0x7D))
            { Read-AtlasJournalFile -Path $JournalPath } |
                Should -Throw -ExpectedMessage '*not strict UTF-8*'

            [IO.File]::WriteAllBytes($JournalPath, [byte[]]@(0xEF, 0xBB, 0xBF, 0x7B, 0x7D))
            { Read-AtlasJournalFile -Path $JournalPath } |
                Should -Throw -ExpectedMessage '*must not contain a byte-order mark*'

            $stream = [IO.File]::Open($JournalPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try {
                $stream.SetLength($script:AtlasJournalMaximumDocumentBytes + 1)
            }
            finally {
                $stream.Dispose()
            }
            { Read-AtlasJournalFile -Path $JournalPath } |
                Should -Throw -ExpectedMessage '*outside the supported*byte range*'
        }
    }

    It 'serializes schema collections as arrays and rejects ambiguous scalar types' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            $serialized = Get-Content -LiteralPath $JournalPath -Raw | ConvertFrom-Json
            ($serialized.phases -is [Array]) | Should -BeTrue
            ($serialized.options -is [Array]) | Should -BeTrue
            ($serialized.compensations -is [Array]) | Should -BeTrue
            ($serialized.events -is [Array]) | Should -BeTrue
            ($serialized.payload.roots -is [Array]) | Should -BeTrue

            $scalarPhases = Get-AtlasInstallJournal -JournalPath $JournalPath
            $scalarPhases.phases = $scalarPhases.phases[0]
            { Test-AtlasJournalDocument -Journal $scalarPhases -SkipDocumentChecksum } |
                Should -Throw -ExpectedMessage '*phases must be a JSON array*'

            $stringBoolean = Get-AtlasInstallJournal -JournalPath $JournalPath
            $stringBoolean.phases[0].required = 'false'
            { Test-AtlasJournalDocument -Journal $stringBoolean -SkipDocumentChecksum } |
                Should -Throw -ExpectedMessage '*required must be a JSON Boolean*'

            $stringInteger = Get-AtlasInstallJournal -JournalPath $JournalPath
            $stringInteger.revision = '0'
            { Test-AtlasJournalDocument -Journal $stringInteger -SkipDocumentChecksum } |
                Should -Throw -ExpectedMessage '*revision must be a JSON integer*'
        }
    }

    It 'leaves the primary unchanged when a failure occurs before atomic replacement' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Reconcile' }) | Out-Null
            $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($JournalPath))
            Mock Set-AtlasJournalFileAcl {
                param($Path)
                if ($Path -like '*.tmp') {
                    throw 'Injected temporary ACL failure.'
                }
            }

            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall } |
                Should -Throw -ExpectedMessage '*Injected temporary ACL failure*'
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($JournalPath)) | Should -BeExactly $before
            Test-Path -LiteralPath "$JournalPath.bak" | Should -BeFalse
            @(Get-ChildItem -LiteralPath (Split-Path -Parent $JournalPath) -Filter '*.tmp') |
                Should -BeNullOrEmpty
        }
    }

    It 'retains a Running checkpoint when a post-replace ACL verification reports failure' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Reconcile' }) | Out-Null
            Mock Set-AtlasJournalFileAcl {
                param($Path)
                if ($Path -like '*.bak') {
                    throw 'Injected post-replace ACL failure.'
                }
            }

            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall } |
                Should -Throw -ExpectedMessage '*Injected post-replace ACL failure*'
            (Read-AtlasJournalFile -Path $JournalPath).phases[0].state | Should -BeExactly 'Running'
            (Read-AtlasJournalFile -Path "$JournalPath.bak").phases[0].state | Should -BeExactly 'Pending'
            (Get-AtlasInstallResumePlan -JournalPath $JournalPath)[0].Action | Should -BeExactly 'Reconcile'
        }
    }

    It 'validates a new transaction completely before retiring a completed journal' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Complete-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall `
                -PostconditionEvidence 'The completed transaction remains the active audit record.' | Out-Null
            Complete-AtlasInstallJournal -JournalPath $JournalPath | Out-Null
            $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($JournalPath))

            { New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.1' -Mode Upgrade `
                    -PhasePlan @(@{ Key = 'PreInstall'; Required = 'false' }) } |
                Should -Throw -ExpectedMessage '*Required must be a Boolean*'
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($JournalPath)) | Should -BeExactly $before
            Test-Path -LiteralPath (Join-Path (Split-Path -Parent $JournalPath) 'archive') |
                Should -BeFalse
        }
    }

    It 'reports active-journal corruption before considering replacement input' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            [IO.File]::WriteAllText($JournalPath, '{broken')

            { New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.1' -Mode Upgrade `
                    -PhasePlan @(@{ Key = 'PreInstall'; Required = 'false' }) } |
                Should -Throw -ExpectedMessage '*primary Atlas install journal is invalid*preserved for diagnosis*'
            [IO.File]::ReadAllText($JournalPath) | Should -BeExactly '{broken'
            Test-Path -LiteralPath (Join-Path (Split-Path -Parent $JournalPath) 'archive') |
                Should -BeFalse
        }
    }

    It 'archives a valid completed journal under the lock before creating the next transaction' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $first = New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' })
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Complete-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall `
                -PostconditionEvidence 'First transaction verified.' | Out-Null
            Complete-AtlasInstallJournal -JournalPath $JournalPath | Out-Null

            $second = New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.1' -Mode Upgrade `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' })
            $archiveRoot = Join-Path -Path (Split-Path -Parent $JournalPath) -ChildPath 'archive'
            $archivePath = Join-Path -Path $archiveRoot -ChildPath "$($first.transactionId).json"
            $previousPath = Join-Path -Path $archiveRoot -ChildPath "$($first.transactionId).previous.json"

            Test-Path -LiteralPath $archivePath -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath $previousPath -PathType Leaf | Should -BeTrue
            (Get-Content -LiteralPath $archivePath -Raw | ConvertFrom-Json).state | Should -BeExactly 'Completed'
            $second.transactionId | Should -Not -BeExactly $first.transactionId
            (Get-Content -LiteralPath $JournalPath -Raw | ConvertFrom-Json).transactionId |
                Should -BeExactly $second.transactionId
        }
    }

    It 'resumes archive retirement after interruption between backup and primary moves' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $first = New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' })
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Complete-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall `
                -PostconditionEvidence 'The first transaction is complete.' | Out-Null
            Complete-AtlasInstallJournal -JournalPath $JournalPath | Out-Null

            $archiveRoot = Join-Path -Path (Split-Path -Parent $JournalPath) -ChildPath 'archive'
            New-Item -Path $archiveRoot -ItemType Directory | Out-Null
            $archivePrevious = Join-Path -Path $archiveRoot -ChildPath "$($first.transactionId).previous.json"
            [IO.File]::Move("$JournalPath.bak", $archivePrevious)

            $second = New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.1' -Mode Upgrade `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' })
            $archivePath = Join-Path -Path $archiveRoot -ChildPath "$($first.transactionId).json"
            Test-Path -LiteralPath $archivePrevious -PathType Leaf | Should -BeTrue
            (Read-AtlasJournalFile -Path $archivePath).state | Should -BeExactly 'Completed'
            (Read-AtlasJournalFile -Path $JournalPath).transactionId | Should -BeExactly $second.transactionId
        }
    }
}

Describe 'Atlas install journal phase recovery' {
    It 'enforces the immutable phase order before starting later work' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh -PhasePlan @(
                @{ Key = 'Payload/Activate'; RecoveryPolicy = 'Reconcile' }
                @{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }
            ) | Out-Null

            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall } |
                Should -Throw -ExpectedMessage "*not the earliest unresolved phase*Payload/Activate*"
        }
    }

    It 'marks interrupted work for reconciliation instead of assuming it succeeded' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Upgrade `
                -PhasePlan @(@{ Key = 'Payload/Activate'; RecoveryPolicy = 'Reconcile' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey 'Payload/Activate' | Out-Null

            (Get-AtlasInstallResumePlan -JournalPath $JournalPath)[0].Action | Should -BeExactly 'Reconcile'
            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey 'Payload/Activate' } |
                Should -Throw -ExpectedMessage '*must be reconciled*'

            Resolve-AtlasInterruptedJournalPhase -JournalPath $JournalPath -PhaseKey 'Payload/Activate' `
                -Resolution ReadyToRetry -Reason 'Generation markers show the previous payload was restored.' | Out-Null
            $retry = Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey 'Payload/Activate'
            $retry.phases[0].attempts | Should -Be 2
        }
    }

    It 'allows a failed idempotent phase to retry but blocks an unreconciled phase' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Upgrade -PhasePlan @(
                @{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }
                @{ Key = 'Defaults'; RecoveryPolicy = 'Reconcile' }
            ) | Out-Null

            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Set-AtlasInstallJournalPhaseFailed -JournalPath $JournalPath -PhaseKey PreInstall -Message 'Injected failure' -ExitCode 1 | Out-Null
            (Get-AtlasInstallResumePlan -JournalPath $JournalPath | Where-Object PhaseKey -eq PreInstall).Action |
                Should -BeExactly 'Retry'
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Complete-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall `
                -PostconditionEvidence 'Helper returned and the phase postcondition passed.' | Out-Null

            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey Defaults | Out-Null
            Set-AtlasInstallJournalPhaseFailed -JournalPath $JournalPath -PhaseKey Defaults -Message 'Unknown partial replay' | Out-Null
            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey Defaults } |
                Should -Throw -ExpectedMessage '*requires reconciliation*'
        }
    }

    It 'permits manual work to retry only after explicit reconciliation evidence' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @('External/Appx') | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey 'External/Appx' | Out-Null
            $resolved = Resolve-AtlasInterruptedJournalPhase -JournalPath $JournalPath -PhaseKey 'External/Appx' `
                -Resolution ReadyToRetry -Reason 'Operator verified that the partial action was rolled back.'
            $resolved.phases[0].state | Should -BeExactly 'Ready'
            $resolved.phases[0].reconciliationEvidence.reason |
                Should -BeExactly 'Operator verified that the partial action was rolled back.'
            (Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey 'External/Appx').phases[0].attempts |
                Should -Be 2
        }
    }

    It 'makes only the earliest unresolved phase actionable and requires an explicit optional skip' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh -PhasePlan @(
                @{ Key = 'Optional/Browser'; RecoveryPolicy = 'Manual'; Required = $false }
                @{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent'; Required = $true }
            ) | Out-Null

            $initialPlan = Get-AtlasInstallResumePlan -JournalPath $JournalPath
            @($initialPlan.Action) | Should -Be @('RunOrSkip', 'Blocked')
            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall } |
                Should -Throw -ExpectedMessage '*not the earliest unresolved phase*'
            { Complete-AtlasInstallJournal -JournalPath $JournalPath } |
                Should -Throw -ExpectedMessage '*phases remain unresolved*'

            Skip-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey 'Optional/Browser' `
                -Reason 'The operator explicitly declined the optional browser.' | Out-Null
            @((Get-AtlasInstallResumePlan -JournalPath $JournalPath).Action) |
                Should -Be @('Completed', 'Run')
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Complete-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall `
                -PostconditionEvidence 'Required phase verified.' | Out-Null
            (Complete-AtlasInstallJournal -JournalPath $JournalPath).state | Should -BeExactly 'Completed'
        }
    }

    It 'reconciles both Running and Failed phases only through evidence-backed legal transitions' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Upgrade `
                -PhasePlan @(@{ Key = 'Defaults'; RecoveryPolicy = 'Reconcile' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey Defaults | Out-Null
            Set-AtlasInstallJournalPhaseFailed -JournalPath $JournalPath -PhaseKey Defaults `
                -Message 'The helper outcome was unknown.' | Out-Null

            $ready = Resolve-AtlasInterruptedJournalPhase -JournalPath $JournalPath -PhaseKey Defaults `
                -Resolution ReadyToRetry -Reason 'The postcondition proves that no partial state remains.'
            $ready.phases[0].state | Should -BeExactly 'Ready'
            $ready.state | Should -BeExactly 'InProgress'
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey Defaults | Out-Null
            $succeeded = Resolve-AtlasInterruptedJournalPhase -JournalPath $JournalPath -PhaseKey Defaults `
                -Resolution VerifiedSucceeded -Reason 'The declared Defaults postcondition is satisfied.'
            $succeeded.phases[0].state | Should -BeExactly 'Succeeded'
            $succeeded.phases[0].postconditionEvidence |
                Should -BeExactly 'The declared Defaults postcondition is satisfied.'
        }
    }

    It 'enforces the complete Running and Failed phase reconciliation table' {
        $baseDirectory = Split-Path -Parent (New-TestAtlasJournalPath)
        InModuleScope Atlas.InstallJournal -Parameters @{ BaseDirectory = $baseDirectory } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $scenarios = @(
                @{ Source = 'Running'; Resolution = 'VerifiedSucceeded'; Expected = 'Succeeded' }
                @{ Source = 'Running'; Resolution = 'ReadyToRetry'; Expected = 'Ready' }
                @{ Source = 'Running'; Resolution = 'Failed'; Expected = 'Failed' }
                @{ Source = 'Failed'; Resolution = 'VerifiedSucceeded'; Expected = 'Succeeded' }
                @{ Source = 'Failed'; Resolution = 'ReadyToRetry'; Expected = 'Ready' }
                @{ Source = 'Failed'; Resolution = 'Failed'; Expected = 'Failed' }
            )
            foreach ($scenario in $scenarios) {
                $directory = Join-Path -Path $BaseDirectory -ChildPath ([Guid]::NewGuid().ToString('N'))
                New-Item -Path $directory -ItemType Directory | Out-Null
                $path = Join-Path -Path $directory -ChildPath 'active.json'
                New-AtlasInstallJournal -JournalPath $path -TargetVersion '0.6.0' -Mode Upgrade `
                    -PhasePlan @(@{ Key = 'Defaults'; RecoveryPolicy = 'Reconcile' }) | Out-Null
                Start-AtlasInstallJournalPhase -JournalPath $path -PhaseKey Defaults | Out-Null
                if ($scenario.Source -eq 'Failed') {
                    Set-AtlasInstallJournalPhaseFailed -JournalPath $path -PhaseKey Defaults `
                        -Message 'Injected table failure.' | Out-Null
                }

                $reason = "Evidence for $($scenario.Source) to $($scenario.Resolution)."
                $result = Resolve-AtlasInterruptedJournalPhase -JournalPath $path -PhaseKey Defaults `
                    -Resolution $scenario.Resolution -Reason $reason
                $result.phases[0].state | Should -BeExactly $scenario.Expected
                $result.phases[0].reconciliationEvidence.reason | Should -BeExactly $reason
            }
        }
    }
}

Describe 'Atlas install journal compensations' {
    It 'persists compensations before mutation and returns them in LIFO order' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Register-AtlasInstallCompensation -JournalPath $JournalPath -Id NotificationState -Kind RegistrySnapshot `
                -OwnerPhase PreInstall -RecoveryPolicy Reconcile -Data @{ valueExisted = $false } | Out-Null
            Register-AtlasInstallCompensation -JournalPath $JournalPath -Id DefaultHive -Kind HiveUnload `
                -OwnerPhase PreInstall -RecoveryPolicy Idempotent -Data @{ hive = 'AME_UserHive_Default' } | Out-Null

            $plan = Get-AtlasInstallCompensationPlan -JournalPath $JournalPath
            @($plan.Id) | Should -Be @('DefaultHive', 'NotificationState')
            @($plan.Action) | Should -Be @('Run', 'Blocked')

            { Start-AtlasInstallCompensation -JournalPath $JournalPath -Id NotificationState } |
                Should -Throw -ExpectedMessage '*not the earliest unresolved LIFO compensation*'
            Start-AtlasInstallCompensation -JournalPath $JournalPath -Id DefaultHive | Out-Null
            Complete-AtlasInstallCompensation -JournalPath $JournalPath -Id DefaultHive -Outcome Compensated `
                -Evidence 'The Atlas-loaded hive alias is absent.' | Out-Null
            (Get-AtlasInstallCompensationPlan -JournalPath $JournalPath | Where-Object Id -eq NotificationState).Action |
                Should -BeExactly 'Reconcile'
            Resolve-AtlasInstallCompensation -JournalPath $JournalPath -Id NotificationState `
                -Resolution ReadyToRetry -Evidence 'The registry snapshot is present and the forward mutation occurred.' | Out-Null
            Start-AtlasInstallCompensation -JournalPath $JournalPath -Id NotificationState | Out-Null
        }
    }

    It 'blocks completion until every required phase and temporary-state compensation is terminal' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'PreInstall'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall | Out-Null
            Register-AtlasInstallCompensation -JournalPath $JournalPath -Id NotificationState -Kind RegistrySnapshot `
                -OwnerPhase PreInstall -RecoveryPolicy Reconcile -Data @{ valueExisted = $true; value = 1 } | Out-Null
            Complete-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall `
                -PostconditionEvidence 'The action returned and its snapshot is durable.' | Out-Null

            $invalidCompleted = Get-AtlasInstallJournal -JournalPath $JournalPath
            $invalidCompleted.state = 'Completed'
            $invalidCompleted.completedUtc = [DateTime]::UtcNow.ToString('o')
            { Test-AtlasJournalDocument -Journal $invalidCompleted -SkipDocumentChecksum } |
                Should -Throw -ExpectedMessage '*completed install journal contains unresolved compensations*'

            { Complete-AtlasInstallJournal -JournalPath $JournalPath } |
                Should -Throw -ExpectedMessage '*compensations remain pending*'
            Complete-AtlasInstallCompensation -JournalPath $JournalPath -Id NotificationState -Outcome Discharged `
                -Evidence 'Notification registry and service baselines match.' | Out-Null
            $completed = Complete-AtlasInstallJournal -JournalPath $JournalPath
            $completed.state | Should -BeExactly 'Completed'
            $completed.completedUtc | Should -Not -BeNullOrEmpty
            { Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey PreInstall } |
                Should -Throw -ExpectedMessage '*already completed*'
        }
    }

    It 'records compensation failure and only auto-retries an idempotent compensation' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'Environment'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey Environment | Out-Null
            Register-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy -Kind RegistrySnapshot `
                -OwnerPhase Environment -RecoveryPolicy Idempotent -Data @{ value = 'RemoteSigned' } | Out-Null
            Start-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy | Out-Null
            Set-AtlasInstallCompensationFailed -JournalPath $JournalPath -Id ExecutionPolicy -Message 'Injected restore failure' | Out-Null

            (Get-AtlasInstallCompensationPlan -JournalPath $JournalPath)[0].Action | Should -BeExactly 'Retry'
            $retried = Start-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy
            $retried.compensations[0].attempts | Should -Be 2
        }
    }

    It 'covers evidence-backed reconciliation from Pending, Running and Failed compensation states' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @(@{ Key = 'Environment'; RecoveryPolicy = 'Idempotent' }) | Out-Null
            Start-AtlasInstallJournalPhase -JournalPath $JournalPath -PhaseKey Environment | Out-Null
            Register-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy -Kind RegistrySnapshot `
                -OwnerPhase Environment -RecoveryPolicy Reconcile -Data @{ value = 'RemoteSigned' } | Out-Null

            { Start-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy } |
                Should -Throw -ExpectedMessage '*requires explicit reconciliation before its first run*'
            $ready = Resolve-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy `
                -Resolution ReadyToRetry -Evidence 'The snapshot exists and the forward mutation is present.'
            $ready.compensations[0].state | Should -BeExactly 'Ready'

            Start-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy | Out-Null
            Set-AtlasInstallCompensationFailed -JournalPath $JournalPath -Id ExecutionPolicy `
                -Message 'The first restoration attempt failed.' | Out-Null
            $discharged = Resolve-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy `
                -Resolution VerifiedDischarged -Evidence 'Independent inspection proves the original value is restored.'
            $discharged.compensations[0].state | Should -BeExactly 'Discharged'
            $discharged.compensations[0].completionEvidence |
                Should -BeExactly 'Independent inspection proves the original value is restored.'

            { Resolve-AtlasInstallCompensation -JournalPath $JournalPath -Id ExecutionPolicy `
                    -Resolution ReadyToRetry -Evidence 'Terminal state cannot reopen.' } |
                Should -Throw -ExpectedMessage '*not the earliest unresolved LIFO compensation*'
        }
    }

    It 'enforces the complete Pending, Running and Failed compensation reconciliation table' {
        $baseDirectory = Split-Path -Parent (New-TestAtlasJournalPath)
        InModuleScope Atlas.InstallJournal -Parameters @{ BaseDirectory = $baseDirectory } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $expectedStates = @{
                VerifiedCompensated = 'Compensated'
                VerifiedDischarged  = 'Discharged'
                ReadyToRetry        = 'Ready'
                Failed              = 'Failed'
            }
            foreach ($sourceState in @('Pending', 'Running', 'Failed')) {
                foreach ($resolution in @('VerifiedCompensated', 'VerifiedDischarged', 'ReadyToRetry', 'Failed')) {
                    $directory = Join-Path -Path $BaseDirectory -ChildPath ([Guid]::NewGuid().ToString('N'))
                    New-Item -Path $directory -ItemType Directory | Out-Null
                    $path = Join-Path -Path $directory -ChildPath 'active.json'
                    New-AtlasInstallJournal -JournalPath $path -TargetVersion '0.6.0' -Mode Fresh `
                        -PhasePlan @(@{ Key = 'Environment'; RecoveryPolicy = 'Idempotent' }) | Out-Null
                    Start-AtlasInstallJournalPhase -JournalPath $path -PhaseKey Environment | Out-Null
                    Register-AtlasInstallCompensation -JournalPath $path -Id ExecutionPolicy `
                        -Kind RegistrySnapshot -OwnerPhase Environment -RecoveryPolicy Idempotent `
                        -Data @{ value = 'RemoteSigned' } | Out-Null
                    if ($sourceState -in @('Running', 'Failed')) {
                        Start-AtlasInstallCompensation -JournalPath $path -Id ExecutionPolicy | Out-Null
                    }
                    if ($sourceState -eq 'Failed') {
                        Set-AtlasInstallCompensationFailed -JournalPath $path -Id ExecutionPolicy `
                            -Message 'Injected table failure.' | Out-Null
                    }

                    $evidence = "Evidence for $sourceState to $resolution."
                    $result = Resolve-AtlasInstallCompensation -JournalPath $path -Id ExecutionPolicy `
                        -Resolution $resolution -Evidence $evidence
                    $result.compensations[0].state | Should -BeExactly $expectedStates[$resolution]
                    $result.compensations[0].reconciliationEvidence.evidence | Should -BeExactly $evidence
                }
            }
        }
    }
}

Describe 'Atlas install journal access-control contract' {
    It 'rejects a noncanonical journal path before changing any Windows-directory ACL' {
        InModuleScope Atlas.InstallJournal {
            Mock Set-Acl { throw 'Set-Acl must not be reached.' }
            Mock New-Item { throw 'New-Item must not be reached.' }

            $unsafePath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) `
                -ChildPath 'System32\AtlasJournal\active.json'
            { Initialize-AtlasInstallJournalStore -JournalPath $unsafePath } |
                Should -Throw -ExpectedMessage '*only accepts the canonical path*'
            Should -Invoke Set-Acl -Times 0 -Exactly
            Should -Invoke New-Item -Times 0 -Exactly
        }
    }

    It 'builds a protected ACL containing only SYSTEM, Administrators and TrustedInstaller' {
        InModuleScope Atlas.InstallJournal {
            $acl = New-AtlasJournalDirectorySecurity
            $acl.AreAccessRulesProtected | Should -BeTrue
            (Test-AtlasJournalAcl -Acl $acl -Directory $true) | Should -BeTrue
            $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value | Should -BeExactly 'S-1-5-32-544'
            $sids = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) |
                    ForEach-Object { $_.IdentityReference.Value } | Sort-Object)
            $sids | Should -Be @(
                'S-1-5-18'
                'S-1-5-32-544'
                'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
            )
            foreach ($rule in @($acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))) {
                $rule.InheritanceFlags | Should -Be (
                    [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                    [Security.AccessControl.InheritanceFlags]::ObjectInherit
                )
                $rule.PropagationFlags | Should -Be ([Security.AccessControl.PropagationFlags]::None)
                $rule.IsInherited | Should -BeFalse
            }

            (Test-AtlasJournalAcl -Acl (New-AtlasJournalFileSecurity) -Directory $true) | Should -BeFalse
            $unexpectedRule = New-Object Security.AccessControl.FileSystemAccessRule(
                (New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')),
                [Security.AccessControl.FileSystemRights]::FullControl,
                ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                    [Security.AccessControl.InheritanceFlags]::ObjectInherit),
                [Security.AccessControl.PropagationFlags]::None,
                [Security.AccessControl.AccessControlType]::Allow
            )
            [void]$acl.AddAccessRule($unexpectedRule)
            (Test-AtlasJournalAcl -Acl $acl -Directory $true) | Should -BeFalse
        }
    }

    It 'secures and revalidates the transaction root associated with the active transaction id' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Open-AtlasJournalLock { New-Object IO.MemoryStream }
            Mock Set-AtlasJournalFileAcl {}
            Mock Set-Acl {}
            Mock Assert-AtlasJournalProtectedDirectory {}
            Mock Assert-AtlasJournalProtectedFile {}

            $journal = New-AtlasInstallJournal -JournalPath $JournalPath -TargetVersion '0.6.0' -Mode Fresh `
                -PhasePlan @('PreInstall')
            Get-AtlasInstallJournal -JournalPath $JournalPath | Out-Null

            $expectedRoot = $journal.transactionRoot
            Should -Invoke Assert-AtlasInstallJournalStore -Times 1 -Scope It -ParameterFilter {
                $TransactionRoot -eq $expectedRoot
            }
            Should -Invoke Assert-AtlasJournalProtectedDirectory -Times 1 -Scope It -ParameterFilter {
                $Path -eq $expectedRoot
            }
        }
    }

    It 'keeps the active journal outside the replaceable AtlasModules payload' {
        $journalPath = Get-AtlasInstallJournalPath
        $journalPath | Should -Match '\\AtlasOS\\Transactions\\active\.json$'
        $journalPath | Should -Not -Match '\\AtlasModules\\'
    }

    It 'uses a bounded protected-store file lock that is released with its process handle' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Set-AtlasJournalFileAcl {}
            Mock Assert-AtlasJournalNotReparsePoint {}
            Mock Test-AtlasJournalAcl { $true }

            $first = Open-AtlasJournalLock -JournalPath $JournalPath -TimeoutMilliseconds 1000
            try {
                { Open-AtlasJournalLock -JournalPath $JournalPath -TimeoutMilliseconds 100 } |
                    Should -Throw -ExpectedMessage '*Timed out after 100 ms*file lock*'
            }
            finally {
                $first.Dispose()
            }

            $afterRelease = Open-AtlasJournalLock -JournalPath $JournalPath -TimeoutMilliseconds 1000
            $afterRelease | Should -BeOfType ([IO.FileStream])
            $afterRelease.Dispose()
        }
    }

    It 'serializes a separate PowerShell process and recovers the lock after that process is killed' {
        $journalPath = New-TestAtlasJournalPath
        InModuleScope Atlas.InstallJournal -Parameters @{ JournalPath = $journalPath } {
            Mock Assert-AtlasInstallJournalStore {}
            Mock Set-AtlasJournalFileAcl {}
            Mock Assert-AtlasJournalNotReparsePoint {}
            Mock Test-AtlasJournalAcl { $true }

            $created = Open-AtlasJournalLock -JournalPath $JournalPath -TimeoutMilliseconds 1000
            $created.Dispose()
            $lockPath = "$JournalPath.lock"
            $readyPath = "$JournalPath.child-ready"
            $escapedLockPath = $lockPath.Replace("'", "''")
            $escapedReadyPath = $readyPath.Replace("'", "''")
            $childScript = @"
`$lockPath = '$escapedLockPath'
`$readyPath = '$escapedReadyPath'
`$stream = [IO.File]::Open(
    `$lockPath,
    [IO.FileMode]::Open,
    [IO.FileAccess]::ReadWrite,
    [IO.FileShare]::None
)
try {
    [IO.File]::WriteAllText(`$readyPath, 'ready')
    Start-Sleep -Seconds 30
}
finally {
    `$stream.Dispose()
}
"@
            $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
            $engineName = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
            $enginePath = Join-Path -Path $PSHOME -ChildPath $engineName
            $process = Start-Process -FilePath $enginePath -WindowStyle Hidden -PassThru -ArgumentList @(
                '-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand', $encodedCommand
            )

            try {
                $deadline = [DateTime]::UtcNow.AddSeconds(10)
                while (-not (Test-Path -LiteralPath $readyPath) -and
                    -not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
                    Start-Sleep -Milliseconds 25
                    $process.Refresh()
                }
                Test-Path -LiteralPath $readyPath -PathType Leaf | Should -BeTrue
                $process.HasExited | Should -BeFalse
                { Open-AtlasJournalLock -JournalPath $JournalPath -TimeoutMilliseconds 150 } |
                    Should -Throw -ExpectedMessage '*Timed out after 150 ms*file lock*'

                $process.Kill()
                $process.WaitForExit(5000) | Should -BeTrue
                $process.Dispose()
                $process = $null

                $afterCrash = Open-AtlasJournalLock -JournalPath $JournalPath -TimeoutMilliseconds 1000
                $afterCrash | Should -BeOfType ([IO.FileStream])
                $afterCrash.Dispose()
            }
            finally {
                if ($null -ne $process) {
                    if (-not $process.HasExited) {
                        $process.Kill()
                        [void]$process.WaitForExit(5000)
                    }
                    $process.Dispose()
                }
            }
        }
    }

    It 'rejects reparse-point store components and contains no named-mutex fallback' {
        InModuleScope Atlas.InstallJournal {
            Mock Get-Item {
                [pscustomobject]@{ Attributes = [IO.FileAttributes]::ReparsePoint }
            }
            { Assert-AtlasJournalNotReparsePoint -Path 'C:\attacker-controlled' } |
                Should -Throw -ExpectedMessage '*must not be a reparse point*'
        }

        $moduleSource = Get-Content -LiteralPath ($script:journalModulePath -replace '\.psd1$', '.psm1') -Raw
        $moduleSource | Should -Not -Match 'Global\\AtlasOS\.InstallJournal'
        $moduleSource | Should -Not -Match 'Threading\.Mutex|MutexSecurity|MutexAccessRule'
    }
}
