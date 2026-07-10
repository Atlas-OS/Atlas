# Atlas.Registry domain: default-user-hive replay.
#
# Only typed mutations recorded by Atlas.Registry are replayed. The obsolete
# hkcu-paths.log is deliberately ignored: a path alone does not identify Atlas-owned
# values and must never authorize recursive copying from an interactive user's hive.

function Sync-AtlasDefaultUserHive {
    <#
    .SYNOPSIS
        Replays the exact typed HKCU mutations recorded by Atlas.Registry into the
        loaded default-user hive (HKU\AME_UserHive_Default). Replay requires the active
        install transaction's durable commit marker. Every record and the marker's
        transaction, length, count, and hash are validated while holding the same lock
        used by writers. Malformed, truncated, or uncommitted input is retained.
    #>
    $installLogPath = Join-Path -Path (Get-AtlasContext).LogsPath -ChildPath 'install'
    $legacyPath = Join-Path -Path $installLogPath -ChildPath 'hkcu-paths.log'

    if (Test-Path -LiteralPath $legacyPath -PathType Leaf) {
        Write-AtlasLog -Message "The obsolete path-only HKCU journal '$legacyPath' is untrusted and was ignored." -Level Warning
    }

    $initialTransaction = Get-AtlasHkcuActiveTransaction
    $result = Invoke-WithAtlasHkcuDeltaLock -InitialTransaction $initialTransaction -ScriptBlock {
        param($transaction, $paths)

        if (Test-Path -LiteralPath $paths.Consumed -PathType Leaf) {
            if (Test-Path -LiteralPath $paths.Marker -PathType Leaf) {
                throw "Atlas HKCU delta transaction '$($transaction.TransactionId)' has both active and consumed commit markers."
            }
            $consumedMarker = Read-AtlasHkcuDeltaCommitMarker -Path $paths.Consumed `
                -ExpectedTransactionId $transaction.TransactionId
            if (Test-Path -LiteralPath $paths.Journal -PathType Leaf) {
                $journalBytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $paths.Journal
                $records = @(ConvertFrom-AtlasHkcuDeltaJournalBytes -Bytes $journalBytes `
                    -ExpectedTransactionId $transaction.TransactionId)
                Assert-AtlasHkcuDeltaCommitBinding -Marker $consumedMarker -Records $records -JournalBytes $journalBytes
                $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
                [IO.File]::Delete($paths.Journal)
                if (Test-Path -LiteralPath $paths.Journal) {
                    throw "The previously replayed Atlas HKCU mutation journal '$($paths.Journal)' could not be consumed."
                }
            }
            $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
            return [pscustomobject]@{
                Count         = [int]$consumedMarker.RecordCount
                TransactionId = $transaction.TransactionId
                Replayed      = $false
            }
        }

        if (-not (Test-Path -LiteralPath $paths.Marker -PathType Leaf)) {
            throw "Atlas HKCU delta transaction '$($transaction.TransactionId)' has no durable commit marker; refusing to replay or consume it."
        }

        # A committed journal is immutable. Do not run final-fragment recovery here:
        # any byte mismatch after completion must fail the marker binding below.
        $journalBytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $paths.Journal
        $records = @(ConvertFrom-AtlasHkcuDeltaJournalBytes -Bytes $journalBytes `
            -ExpectedTransactionId $transaction.TransactionId)
        $marker = Read-AtlasHkcuDeltaCommitMarker -Path $paths.Marker `
            -ExpectedTransactionId $transaction.TransactionId
        Assert-AtlasHkcuDeltaCommitBinding -Marker $marker -Records $records -JournalBytes $journalBytes
        $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction

        if ($records.Count -gt 0 -and -not (Test-AtlasDefaultUserHiveLoaded)) {
            throw "The default-user hive is not loaded at 'HKU\$script:AtlasDefaultUserHiveName'; refusing to discard the committed HKCU delta transaction '$($transaction.TransactionId)'."
        }

        $replayedCount = Invoke-AtlasHkcuDeltaJournal -Deltas $records `
            -DestinationRootSubPath $script:AtlasDefaultUserHiveName
        $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction

        # Atomically retire the authorization marker before deleting the journal. The
        # consumed tombstone prevents both replay and late writers. A crash after this
        # move is recovered by the branch above, which validates and removes the journal
        # without replaying it a second time.
        if (Test-Path -LiteralPath $paths.Consumed) {
            throw "The Atlas HKCU consumed marker '$($paths.Consumed)' already exists."
        }
        [IO.File]::Move($paths.Marker, $paths.Consumed)
        Assert-AtlasHkcuDeltaFileSecurity -Path $paths.Consumed
        if ((Test-Path -LiteralPath $paths.Marker) -or
            -not (Test-Path -LiteralPath $paths.Consumed -PathType Leaf)) {
            throw "The Atlas HKCU delta commit marker '$($paths.Marker)' could not be retired after replay."
        }
        if (Test-Path -LiteralPath $paths.Journal -PathType Leaf) {
            [IO.File]::Delete($paths.Journal)
        }
        if (Test-Path -LiteralPath $paths.Journal) {
            throw "The Atlas HKCU mutation journal '$($paths.Journal)' could not be consumed after replay."
        }

        return [pscustomobject]@{
            Count         = [int]$replayedCount
            TransactionId = $transaction.TransactionId
            Replayed      = $true
        }
    }

    if ($result.Replayed) {
        Write-AtlasLog -Message "Replayed and consumed $($result.Count) Atlas-owned HKCU mutation(s) from transaction '$($result.TransactionId)' in the default-user hive."
    }
    else {
        Write-AtlasLog -Message "Confirmed $($result.Count) previously replayed Atlas-owned HKCU mutation(s) were consumed for transaction '$($result.TransactionId)'."
    }
}
