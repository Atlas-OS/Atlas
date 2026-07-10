# Atlas.Registry domain: transaction-bound HKCU mutation journal and default-hive replay.
#
# Every install-time redirected HKCU mutation is represented as typed data beneath the
# protected Atlas.InstallJournal transaction root. Writers, completion, and replay use
# one kernel file lock. Replay requires a flushed commit marker binding the transaction,
# exact journal bytes, and record count; a valid but interrupted prefix is never enough.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions',
    '',
    Justification = 'Private durability primitives cannot offer WhatIf without invalidating the journal protocol.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseSingularNouns',
    '',
    Justification = 'Private helpers intentionally name byte arrays and the transaction path set.'
)]
param()

$script:AtlasHkcuDeltaSchemaVersion = 1
$script:AtlasHkcuDeltaJournalName = 'registry-deltas.jsonl'
$script:AtlasHkcuDeltaLockName = 'registry-deltas.lock'
$script:AtlasHkcuDeltaMarkerName = 'registry-deltas.commit.json'
$script:AtlasHkcuDeltaMarkerTempName = 'registry-deltas.commit.tmp'
$script:AtlasHkcuDeltaConsumedName = 'registry-deltas.consumed.json'
$script:AtlasHkcuDeltaRecoveryName = 'registry-deltas.recovery.jsonl'
$script:AtlasHkcuDeltaFailureMarker = 'Atlas.Registry.HkcuDeltaJournalFailure'
$script:AtlasHkcuDeltaMaximumJournalBytes = 16MB
$script:AtlasHkcuDeltaMaximumRecordBytes = 1MB
$script:AtlasHkcuDeltaLockTimeoutMilliseconds = 30000
$script:AtlasTrustedInstallerSid = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
$script:AtlasInstallJournalPathOverride = $null

function New-AtlasHkcuDeltaFailureException {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubPath,

        [Parameter(Mandatory = $true)]
        [Exception]$InnerException
    )

    $exception = New-Object IO.IOException(
        "The redirected HKCU mutation at '$SubPath' could not be recorded durably; refusing to continue.",
        $InnerException
    )
    $exception.Data[$script:AtlasHkcuDeltaFailureMarker] = $true
    return $exception
}

function Test-AtlasHkcuDeltaFailureException {
    param(
        [Parameter(Mandatory = $true)]
        [Exception]$Exception
    )

    $currentException = $Exception
    while ($null -ne $currentException) {
        if ($currentException.Data.Contains($script:AtlasHkcuDeltaFailureMarker) -and
            $currentException.Data[$script:AtlasHkcuDeltaFailureMarker]) {
            return $true
        }
        $currentException = $currentException.InnerException
    }

    return $false
}

function Get-AtlasRegistryInstallJournalPath {
    if (-not [string]::IsNullOrWhiteSpace($script:AtlasInstallJournalPathOverride)) {
        return [IO.Path]::GetFullPath($script:AtlasInstallJournalPathOverride)
    }
    return [IO.Path]::GetFullPath((Get-AtlasInstallJournalPath))
}

function Test-AtlasDefaultUserHiveLoaded {
    return Test-Path -LiteralPath $script:AtlasDefaultUserHiveRoot -PathType Container
}

function Get-AtlasHkcuActiveTransaction {
    param(
        [switch]$AllowInactive
    )

    $installJournalPath = Get-AtlasRegistryInstallJournalPath
    if (-not (Test-Path -LiteralPath $installJournalPath -PathType Leaf)) {
        if ($AllowInactive -and -not (Test-AtlasDefaultUserHiveLoaded)) {
            return $null
        }
        throw "No active Atlas install journal exists at '$installJournalPath'."
    }

    $journal = Get-AtlasInstallJournal -JournalPath $installJournalPath
    $transactionGuid = [Guid]::Empty
    if (-not [Guid]::TryParse([string]$journal.transactionId, [ref]$transactionGuid) -or
        $transactionGuid -eq [Guid]::Empty -or
        $transactionGuid.ToString('D') -cne [string]$journal.transactionId) {
        throw 'The active Atlas install transaction id is not canonical.'
    }
    if (-not [IO.Path]::IsPathRooted([string]$journal.transactionRoot)) {
        throw 'The active Atlas install transaction root is not absolute.'
    }

    $transactionRoot = [IO.Path]::GetFullPath([string]$journal.transactionRoot).TrimEnd('\')
    if ((Split-Path -Leaf $transactionRoot) -cne [string]$journal.transactionId) {
        throw 'The active Atlas install transaction root does not match its transaction id.'
    }

    switch ([string]$journal.state) {
        'InProgress' {
            return [pscustomobject]@{
                InstallJournalPath = $installJournalPath
                TransactionId      = [string]$journal.transactionId
                TransactionRoot    = $transactionRoot
                State              = 'InProgress'
            }
        }
        'Completed' {
            if ($AllowInactive -and -not (Test-AtlasDefaultUserHiveLoaded)) {
                return $null
            }
            throw "Atlas install transaction '$($journal.transactionId)' is already completed."
        }
        default {
            throw "Atlas install transaction '$($journal.transactionId)' is '$($journal.state)' and cannot accept HKCU mutations."
        }
    }
}

function Get-AtlasHkcuDeltaPaths {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [pscustomobject]$Transaction
    )

    return [pscustomobject]@{
        Journal    = Join-Path -Path $Transaction.TransactionRoot -ChildPath $script:AtlasHkcuDeltaJournalName
        Lock       = Join-Path -Path $Transaction.TransactionRoot -ChildPath $script:AtlasHkcuDeltaLockName
        Marker     = Join-Path -Path $Transaction.TransactionRoot -ChildPath $script:AtlasHkcuDeltaMarkerName
        MarkerTemp = Join-Path -Path $Transaction.TransactionRoot -ChildPath $script:AtlasHkcuDeltaMarkerTempName
        Consumed   = Join-Path -Path $Transaction.TransactionRoot -ChildPath $script:AtlasHkcuDeltaConsumedName
        Recovery   = Join-Path -Path $Transaction.TransactionRoot -ChildPath $script:AtlasHkcuDeltaRecoveryName
    }
}

function Assert-AtlasHkcuTransactionMatch {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [pscustomobject]$Expected
    )

    $current = Get-AtlasHkcuActiveTransaction
    if ($current.TransactionId -cne $Expected.TransactionId -or
        -not [string]::Equals(
            $current.TransactionRoot,
            $Expected.TransactionRoot,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The active Atlas install transaction changed while registry delta state was locked (expected '$($Expected.TransactionId)', found '$($current.TransactionId)')."
    }

    return $current
}

function New-AtlasHkcuDeltaFileSecurity {
    $security = New-Object Security.AccessControl.FileSecurity
    $security.SetAccessRuleProtection($true, $false)
    $security.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')))

    foreach ($sid in @('S-1-5-18', 'S-1-5-32-544', $script:AtlasTrustedInstallerSid)) {
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            (New-Object Security.Principal.SecurityIdentifier($sid)),
            [Security.AccessControl.FileSystemRights]::FullControl,
            [Security.AccessControl.AccessControlType]::Allow
        )
        $security.AddAccessRule($rule)
    }

    return $security
}

function Set-AtlasHkcuDeltaFileAccessControl {
    param(
        [Parameter(Mandatory = $true)]
        [IO.FileInfo]$File
    )

    $security = New-AtlasHkcuDeltaFileSecurity
    if ($PSVersionTable.PSEdition -eq 'Core') {
        [System.IO.FileSystemAclExtensions]::SetAccessControl($File, $security)
    }
    else {
        $File.SetAccessControl($security)
    }
}

function Assert-AtlasHkcuDeltaNotReparsePoint {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing to use the reparse-point Atlas HKCU delta file '$Path'."
    }
}

function Assert-AtlasHkcuDeltaFileSecurity {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "The Atlas HKCU delta file does not exist: '$Path'."
    }
    Assert-AtlasHkcuDeltaNotReparsePoint -Path $Path

    $security = Get-Acl -LiteralPath $Path -ErrorAction Stop
    if (-not $security.AreAccessRulesProtected) {
        throw "The Atlas HKCU delta file '$Path' has an inheritable DACL."
    }
    if ($security.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne 'S-1-5-32-544') {
        throw "The Atlas HKCU delta file '$Path' has an unexpected owner."
    }

    $expectedSids = @('S-1-5-18', 'S-1-5-32-544', $script:AtlasTrustedInstallerSid)
    $rules = @($security.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))
    if ($rules.Count -ne $expectedSids.Count) {
        throw "The Atlas HKCU delta file '$Path' has an unexpected explicit rule count."
    }
    foreach ($rule in $rules) {
        if ($expectedSids -notcontains $rule.IdentityReference.Value -or
            $rule.IsInherited -or
            $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or
            $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::FullControl -or
            $rule.InheritanceFlags -ne [Security.AccessControl.InheritanceFlags]::None -or
            $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None) {
            throw "The Atlas HKCU delta file '$Path' has an unexpected access rule."
        }
    }
}

function Protect-AtlasHkcuInterruptedEmptyFile {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Path
    )

    Assert-AtlasHkcuDeltaNotReparsePoint -Path $Path
    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($file.Length -ne 0) {
        Assert-AtlasHkcuDeltaFileSecurity -Path $Path
        return
    }

    # Transaction roots are independently validated by Atlas.InstallJournal. An empty
    # exact-name file can only be residue from a crash between CreateNew and SetAcl;
    # normalize it before any transaction bytes are written.
    Set-AtlasHkcuDeltaFileAccessControl -File $file
    Assert-AtlasHkcuDeltaFileSecurity -Path $Path
}

function Open-AtlasHkcuDeltaLock {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TransactionRoot,

        [ValidateRange(1, 300000)]
        [int]$TimeoutMilliseconds = $script:AtlasHkcuDeltaLockTimeoutMilliseconds
    )

    $lockPath = Join-Path -Path $TransactionRoot -ChildPath $script:AtlasHkcuDeltaLockName
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        $existed = Test-Path -LiteralPath $lockPath
        $stream = $null
        try {
            $stream = [IO.File]::Open(
                $lockPath,
                [IO.FileMode]::OpenOrCreate,
                [IO.FileAccess]::ReadWrite,
                [IO.FileShare]::None
            )
        }
        catch [IO.IOException] {
            if ($stopwatch.ElapsedMilliseconds -ge $TimeoutMilliseconds) {
                throw "Timed out after $TimeoutMilliseconds ms waiting for the Atlas HKCU delta lock '$lockPath'."
            }
            Start-Sleep -Milliseconds 50
            continue
        }

        try {
            Assert-AtlasHkcuDeltaNotReparsePoint -Path $lockPath
            if (-not $existed) {
                Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($lockPath))
            }
            Assert-AtlasHkcuDeltaFileSecurity -Path $lockPath
            return $stream
        }
        catch {
            $stream.Dispose()
            throw
        }
    }
}

function Invoke-WithAtlasHkcuDeltaLock {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [pscustomobject]$InitialTransaction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $paths = Get-AtlasHkcuDeltaPaths -Transaction $InitialTransaction
    $lockStream = Open-AtlasHkcuDeltaLock -TransactionRoot $InitialTransaction.TransactionRoot
    try {
        $currentTransaction = Assert-AtlasHkcuTransactionMatch -Expected $InitialTransaction
        return & $ScriptBlock $currentTransaction $paths
    }
    finally {
        $lockStream.Dispose()
    }
}

function Get-AtlasHkcuSha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function ConvertTo-AtlasStrictUtf8Bytes {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $encoding = New-Object Text.UTF8Encoding($false, $true)
    return ,$encoding.GetBytes($Text)
}

function ConvertFrom-AtlasStrictUtf8Bytes {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $encoding = New-Object Text.UTF8Encoding($false, $true)
    try {
        return $encoding.GetString($Bytes)
    }
    catch [Text.DecoderFallbackException] {
        throw "Atlas HKCU delta data is not valid UTF-8: $($_.Exception.Message)"
    }
}

function Write-AtlasHkcuDurableLine {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Line,

        [ValidateRange(1, 33554432)]
        [int]$MaximumBytes = $script:AtlasHkcuDeltaMaximumJournalBytes
    )

    if ($Line.IndexOf("`r") -ge 0 -or $Line.IndexOf("`n") -ge 0) {
        throw 'An Atlas HKCU delta JSON line cannot contain a literal newline.'
    }

    $lineBytes = ConvertTo-AtlasStrictUtf8Bytes -Text $Line
    if ($lineBytes.Length + 1 -gt $script:AtlasHkcuDeltaMaximumRecordBytes) {
        throw 'An Atlas HKCU delta record exceeds the 1 MiB safety limit.'
    }

    $existingLength = 0
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Protect-AtlasHkcuInterruptedEmptyFile -Path $Path
        $existingLength = (Get-Item -LiteralPath $Path -Force -ErrorAction Stop).Length
    }
    else {
        $creationStream = [IO.File]::Open(
            $Path,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $creationStream.Dispose()
        Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($Path))
        Assert-AtlasHkcuDeltaFileSecurity -Path $Path
    }
    if ($existingLength + $lineBytes.Length + 1 -gt $MaximumBytes) {
        throw "The Atlas HKCU delta file '$Path' would exceed its safety limit."
    }

    $stream = [IO.File]::Open(
        $Path,
        [IO.FileMode]::Open,
        [IO.FileAccess]::Write,
        [IO.FileShare]::Read
    )
    try {
        $null = $stream.Seek(0, [IO.SeekOrigin]::End)
        $stream.Write($lineBytes, 0, $lineBytes.Length)
        $stream.WriteByte(0x0A)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }

    Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($Path))
    Assert-AtlasHkcuDeltaFileSecurity -Path $Path
}

function Write-AtlasHkcuRecoveryEvidence {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [pscustomobject]$Transaction,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [pscustomobject]$Paths,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Kind,

        [Parameter(Mandatory = $true)]
        [hashtable]$Detail
    )

    Repair-AtlasHkcuRecoveryEvidenceFinalFragment -Transaction $Transaction -Paths $Paths

    $evidence = [pscustomobject][ordered]@{
        Version       = 1
        TransactionId = $Transaction.TransactionId
        Utc           = 'UTC:' + [DateTime]::UtcNow.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
        Kind          = $Kind
        Detail        = [pscustomobject]$Detail
    }
    $json = $evidence | ConvertTo-Json -Compress -Depth 6
    Write-AtlasHkcuDurableLine -Path $Paths.Recovery -Line $json -MaximumBytes 4MB
}

function Assert-AtlasHkcuRecoveryEvidenceBytes {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ExpectedTransactionId
    )

    if ($Bytes.Length -gt 4MB) { throw 'The Atlas HKCU recovery evidence exceeds its 4 MiB safety limit.' }
    if ($Bytes.Length -eq 0) { return }
    if ($Bytes[$Bytes.Length - 1] -ne 0x0A) { throw 'The Atlas HKCU recovery evidence has an unterminated final fragment.' }

    $content = ConvertFrom-AtlasStrictUtf8Bytes -Bytes $Bytes
    $lines = @($content -split "`n")
    for ($lineIndex = 0; $lineIndex -lt $lines.Count - 1; $lineIndex++) {
        $lineNumber = $lineIndex + 1
        $line = $lines[$lineIndex]
        if ([string]::IsNullOrEmpty($line) -or $line -cne $line.Trim() -or
            -not $line.StartsWith('{') -or -not $line.EndsWith('}')) {
            throw "Invalid Atlas HKCU recovery evidence at line ${lineNumber}: expected one canonical JSON object."
        }
        try { $record = $line | ConvertFrom-Json -ErrorAction Stop }
        catch { throw "Invalid Atlas HKCU recovery evidence at line ${lineNumber}: $($_.Exception.Message)" }

        Assert-AtlasRegistryDeltaSchema -Record $record -ExpectedProperties @(
            'Version', 'TransactionId', 'Utc', 'Kind', 'Detail'
        )
        if (($record.Version -isnot [int] -and $record.Version -isnot [long]) -or $record.Version -ne 1) {
            throw "Invalid Atlas HKCU recovery evidence version at line $lineNumber."
        }
        if ($record.TransactionId -isnot [string] -or $record.TransactionId -cne $ExpectedTransactionId) {
            throw "Atlas HKCU recovery evidence at line $lineNumber belongs to another transaction."
        }
        if ($record.Utc -isnot [string] -or -not $record.Utc.StartsWith('UTC:')) {
            throw "Invalid Atlas HKCU recovery evidence timestamp at line $lineNumber."
        }
        $timestamp = [DateTime]::MinValue
        if (-not [DateTime]::TryParseExact(
            $record.Utc.Substring(4),
            'o',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$timestamp
        ) -or $timestamp.Kind -ne [DateTimeKind]::Utc -or
            $timestamp.ToString('o', [Globalization.CultureInfo]::InvariantCulture) -cne $record.Utc.Substring(4)) {
            throw "The Atlas HKCU recovery evidence timestamp at line $lineNumber is not canonical UTC."
        }
        if ($record.Kind -isnot [string] -or [string]::IsNullOrWhiteSpace($record.Kind) -or
            $record.Detail -isnot [pscustomobject]) {
            throw "Invalid Atlas HKCU recovery evidence payload at line $lineNumber."
        }
    }
}

function Repair-AtlasHkcuRecoveryEvidenceFinalFragment {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][pscustomobject]$Transaction,
        [Parameter(Mandatory = $true)][ValidateNotNull()][pscustomobject]$Paths
    )

    if (-not (Test-Path -LiteralPath $Paths.Recovery -PathType Leaf)) { return }
    Protect-AtlasHkcuInterruptedEmptyFile -Path $Paths.Recovery
    Assert-AtlasHkcuDeltaFileSecurity -Path $Paths.Recovery
    $recoveryFile = Get-Item -LiteralPath $Paths.Recovery -Force -ErrorAction Stop
    if ($recoveryFile.Length -gt 4MB) {
        throw 'The Atlas HKCU recovery evidence exceeds its 4 MiB safety limit.'
    }
    $bytes = [IO.File]::ReadAllBytes($Paths.Recovery)
    if ($bytes.Length -eq 0 -or $bytes[$bytes.Length - 1] -eq 0x0A) {
        Assert-AtlasHkcuRecoveryEvidenceBytes -Bytes $bytes -ExpectedTransactionId $Transaction.TransactionId
        return
    }

    $lastLineFeed = -1
    for ($index = $bytes.Length - 1; $index -ge 0; $index--) {
        if ($bytes[$index] -eq 0x0A) { $lastLineFeed = $index; break }
    }
    $prefixLength = $lastLineFeed + 1
    $prefixBytes = if ($prefixLength -eq 0) { [byte[]]@() } else {
        $result = New-Object byte[] $prefixLength
        [Array]::Copy($bytes, 0, $result, 0, $prefixLength)
        $result
    }
    Assert-AtlasHkcuRecoveryEvidenceBytes -Bytes $prefixBytes -ExpectedTransactionId $Transaction.TransactionId

    $stream = [IO.File]::Open($Paths.Recovery, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    try {
        $stream.SetLength($prefixLength)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
    Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($Paths.Recovery))
    Assert-AtlasHkcuDeltaFileSecurity -Path $Paths.Recovery
}

function ConvertTo-AtlasCanonicalHkcuSubPath {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [ValidateNotNull()]
        [string]$SubPath
    )

    if ($SubPath.IndexOf([char]0) -ge 0) {
        throw 'An HKCU delta subpath cannot contain a null character.'
    }

    $segments = @($SubPath -split '\\' | Where-Object { $_.Length -gt 0 })
    $canonical = $segments -join '\'
    if ($canonical.Length -gt 32767) {
        throw 'An HKCU delta subpath cannot exceed 32767 characters.'
    }
    return $canonical
}

function ConvertTo-AtlasRegistryDeltaData {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')]
        [string]$Kind,

        [AllowNull()]
        [object]$Data
    )

    switch ($Kind) {
        'String' { return [string]$Data }
        'ExpandString' { return [string]$Data }
        'Binary' { return [Convert]::ToBase64String([byte[]]$Data) }
        'DWord' {
            $signedValue = [int32](ConvertTo-AtlasDwordData -Data $Data)
            $unsignedValue = [BitConverter]::ToUInt32([BitConverter]::GetBytes($signedValue), 0)
            return $unsignedValue.ToString('X8', [Globalization.CultureInfo]::InvariantCulture)
        }
        'MultiString' { return ,([string[]]$Data) }
        'QWord' {
            $signedValue = [int64](ConvertTo-AtlasQwordData -Data $Data)
            $unsignedValue = [BitConverter]::ToUInt64([BitConverter]::GetBytes($signedValue), 0)
            return $unsignedValue.ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
        }
        'None' {
            if ($null -eq $Data) { return '' }
            return [Convert]::ToBase64String([byte[]]$Data)
        }
    }
}

function ConvertFrom-AtlasRegistryDeltaData {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')]
        [string]$Kind,

        [AllowNull()]
        [object]$Data
    )

    switch ($Kind) {
        { $_ -in @('String', 'ExpandString') } {
            if ($Data -isnot [string]) { throw "Registry delta data for kind '$Kind' must be a string." }
            return [string]$Data
        }
        { $_ -in @('Binary', 'None') } {
            if ($Data -isnot [string]) { throw "Registry delta data for kind '$Kind' must be canonical Base64 text." }
            try { $bytes = [Convert]::FromBase64String($Data) }
            catch { throw "Registry delta data for kind '$Kind' is not valid Base64." }
            if ([Convert]::ToBase64String($bytes) -cne $Data) {
                throw "Registry delta data for kind '$Kind' is not canonical Base64."
            }
            return ,$bytes
        }
        'DWord' {
            if ($Data -isnot [string] -or $Data -cnotmatch '^[0-9A-F]{8}$') {
                throw 'Registry delta DWord data must be exactly eight uppercase hexadecimal digits.'
            }
            $unsignedValue = [uint32]::Parse($Data, [Globalization.NumberStyles]::HexNumber, [Globalization.CultureInfo]::InvariantCulture)
            return [BitConverter]::ToInt32([BitConverter]::GetBytes($unsignedValue), 0)
        }
        'MultiString' {
            if ($null -eq $Data -or $Data -is [string] -or $Data -isnot [array]) {
                throw 'Registry delta MultiString data must be a JSON string array.'
            }
            foreach ($element in @($Data)) {
                if ($element -isnot [string]) { throw 'Registry delta MultiString data must contain only strings.' }
            }
            return ,([string[]]@($Data))
        }
        'QWord' {
            if ($Data -isnot [string] -or $Data -cnotmatch '^[0-9A-F]{16}$') {
                throw 'Registry delta QWord data must be exactly sixteen uppercase hexadecimal digits.'
            }
            $unsignedValue = [uint64]::Parse($Data, [Globalization.NumberStyles]::HexNumber, [Globalization.CultureInfo]::InvariantCulture)
            return [BitConverter]::ToInt64([BitConverter]::GetBytes($unsignedValue), 0)
        }
    }
}

function New-AtlasHkcuDeltaRecord {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TransactionId,
        [Parameter(Mandatory = $true)][AllowEmptyString()][ValidateNotNull()][string]$SubPath,
        [Parameter(Mandatory = $true)][ValidateSet('SetValue', 'DeleteValue', 'CreateKey', 'DeleteKey')][string]$Operation,
        [AllowNull()][AllowEmptyString()][string]$Name,
        [AllowNull()][string]$Kind,
        [AllowNull()][object]$Data
    )

    $transactionGuid = [Guid]::Empty
    if (-not [Guid]::TryParse($TransactionId, [ref]$transactionGuid) -or
        $transactionGuid.ToString('D') -cne $TransactionId) {
        throw "HKCU delta transaction id '$TransactionId' is not canonical."
    }

    $canonicalSubPath = ConvertTo-AtlasCanonicalHkcuSubPath -SubPath $SubPath
    $record = [ordered]@{
        Version       = [int]$script:AtlasHkcuDeltaSchemaVersion
        TransactionId = $TransactionId
        Operation     = $Operation
        SubPath       = $canonicalSubPath
    }

    switch ($Operation) {
        'SetValue' {
            if (-not $PSBoundParameters.ContainsKey('Name')) { throw 'A SetValue HKCU delta requires a value name.' }
            if (-not $PSBoundParameters.ContainsKey('Kind') -or
                $Kind -notin @('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')) {
                throw 'A SetValue HKCU delta requires a supported registry value kind.'
            }
            if ($null -eq $Data -and $Kind -notin @('None', 'String', 'ExpandString')) {
                throw "A SetValue HKCU delta for kind '$Kind' requires data."
            }
            $record['Name'] = $Name
            $record['Kind'] = $Kind
            $record['Data'] = ConvertTo-AtlasRegistryDeltaData -Kind $Kind -Data $Data
        }
        'DeleteValue' {
            if (-not $PSBoundParameters.ContainsKey('Name')) { throw 'A DeleteValue HKCU delta requires a value name.' }
            $record['Name'] = $Name
        }
        'DeleteKey' {
            if ([string]::IsNullOrEmpty($canonicalSubPath)) { throw 'Refusing to journal deletion of the HKCU root.' }
        }
    }

    return [pscustomobject]$record
}

function Assert-AtlasRegistryDeltaSchema {
    param(
        [Parameter(Mandatory = $true)][object]$Record,
        [Parameter(Mandatory = $true)][string[]]$ExpectedProperties
    )

    if ($Record -isnot [pscustomobject]) { throw 'An HKCU delta journal record must be a JSON object.' }
    $actualProperties = @($Record.PSObject.Properties.Name)
    foreach ($expectedProperty in $ExpectedProperties) {
        if ($actualProperties -cnotcontains $expectedProperty) {
            throw "An HKCU delta journal record is missing the '$expectedProperty' property."
        }
    }
    foreach ($actualProperty in $actualProperties) {
        if ($ExpectedProperties -cnotcontains $actualProperty) {
            throw "An HKCU delta journal record contains the unexpected '$actualProperty' property."
        }
    }
}

function ConvertFrom-AtlasHkcuDeltaRecord {
    param(
        [Parameter(Mandatory = $true)][object]$Record,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ExpectedTransactionId
    )

    if ($Record -isnot [pscustomobject]) { throw 'An HKCU delta journal record must be a JSON object.' }
    $actualProperties = @($Record.PSObject.Properties.Name)
    foreach ($requiredProperty in @('Version', 'TransactionId', 'Operation', 'SubPath')) {
        if ($actualProperties -cnotcontains $requiredProperty) {
            throw "An HKCU delta journal record is missing the '$requiredProperty' property."
        }
    }

    if (($Record.Version -isnot [int] -and $Record.Version -isnot [long]) -or
        $Record.Version -ne $script:AtlasHkcuDeltaSchemaVersion) {
        throw "Unsupported HKCU delta journal version '$($Record.Version)'."
    }
    if ($Record.TransactionId -isnot [string] -or $Record.TransactionId -cne $ExpectedTransactionId) {
        throw "HKCU delta record transaction '$($Record.TransactionId)' does not match active transaction '$ExpectedTransactionId'."
    }
    if ($Record.Operation -isnot [string] -or
        $Record.Operation -cnotin @('SetValue', 'DeleteValue', 'CreateKey', 'DeleteKey')) {
        throw "Unsupported HKCU delta operation '$($Record.Operation)'."
    }
    if ($Record.SubPath -isnot [string]) { throw 'An HKCU delta SubPath must be a string.' }
    $canonicalSubPath = ConvertTo-AtlasCanonicalHkcuSubPath -SubPath $Record.SubPath
    if ($canonicalSubPath -cne $Record.SubPath) {
        throw "The HKCU delta SubPath '$($Record.SubPath)' is not canonical."
    }

    $normalized = [ordered]@{
        TransactionId = $ExpectedTransactionId
        Operation     = $Record.Operation
        SubPath       = $canonicalSubPath
    }
    switch ($Record.Operation) {
        'SetValue' {
            Assert-AtlasRegistryDeltaSchema -Record $Record -ExpectedProperties @('Version', 'TransactionId', 'Operation', 'SubPath', 'Name', 'Kind', 'Data')
            if ($Record.Name -isnot [string]) { throw 'A SetValue HKCU delta Name must be a string.' }
            if ($Record.Kind -isnot [string] -or
                $Record.Kind -cnotin @('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')) {
                throw "A SetValue HKCU delta has unsupported kind '$($Record.Kind)'."
            }
            $normalized['Name'] = $Record.Name
            $normalized['Kind'] = $Record.Kind
            $normalized['Data'] = ConvertFrom-AtlasRegistryDeltaData -Kind $Record.Kind -Data $Record.Data
        }
        'DeleteValue' {
            Assert-AtlasRegistryDeltaSchema -Record $Record -ExpectedProperties @('Version', 'TransactionId', 'Operation', 'SubPath', 'Name')
            if ($Record.Name -isnot [string]) { throw 'A DeleteValue HKCU delta Name must be a string.' }
            $normalized['Name'] = $Record.Name
        }
        'CreateKey' {
            Assert-AtlasRegistryDeltaSchema -Record $Record -ExpectedProperties @('Version', 'TransactionId', 'Operation', 'SubPath')
        }
        'DeleteKey' {
            Assert-AtlasRegistryDeltaSchema -Record $Record -ExpectedProperties @('Version', 'TransactionId', 'Operation', 'SubPath')
            if ([string]::IsNullOrEmpty($canonicalSubPath)) { throw 'Refusing to replay deletion of the default-user hive root.' }
        }
    }
    return [pscustomobject]$normalized
}

function ConvertFrom-AtlasHkcuDeltaJournalBytes {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ExpectedTransactionId
    )

    if ($Bytes.Length -gt $script:AtlasHkcuDeltaMaximumJournalBytes) {
        throw 'The Atlas HKCU delta journal exceeds the 16 MiB safety limit.'
    }
    if ($Bytes.Length -eq 0) { return @() }
    if ($Bytes[$Bytes.Length - 1] -ne 0x0A) {
        throw 'The Atlas HKCU delta journal has an unterminated final fragment.'
    }

    $content = ConvertFrom-AtlasStrictUtf8Bytes -Bytes $Bytes
    $records = New-Object System.Collections.Generic.List[object]
    $lines = @($content -split "`n")
    for ($lineIndex = 0; $lineIndex -lt $lines.Count - 1; $lineIndex++) {
        $lineNumber = $lineIndex + 1
        $line = $lines[$lineIndex]
        if ($line.EndsWith("`r")) {
            $line = $line.Substring(0, $line.Length - 1)
        }
        if ([string]::IsNullOrEmpty($line)) {
            throw "Invalid Atlas HKCU delta journal record at line ${lineNumber}: blank records are not permitted."
        }
        if ((ConvertTo-AtlasStrictUtf8Bytes -Text $line).Length -gt $script:AtlasHkcuDeltaMaximumRecordBytes) {
            throw "Invalid Atlas HKCU delta journal record at line ${lineNumber}: record exceeds the safety limit."
        }
        if ($line -cne $line.Trim() -or -not $line.StartsWith('{') -or -not $line.EndsWith('}')) {
            throw "Invalid Atlas HKCU delta journal record at line ${lineNumber}: record must be one canonical JSON object."
        }
        try {
            $jsonRecord = $line | ConvertFrom-Json -ErrorAction Stop
            $records.Add((ConvertFrom-AtlasHkcuDeltaRecord -Record $jsonRecord -ExpectedTransactionId $ExpectedTransactionId))
        }
        catch {
            throw "Invalid Atlas HKCU delta journal record at line ${lineNumber}: $($_.Exception.Message)"
        }
    }
    return $records.ToArray()
}

function Get-AtlasHkcuDeltaJournalBytes {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$JournalPath
    )

    if (-not (Test-Path -LiteralPath $JournalPath -PathType Leaf)) { return ,[byte[]]@() }
    Assert-AtlasHkcuDeltaFileSecurity -Path $JournalPath
    $fileInfo = Get-Item -LiteralPath $JournalPath -Force -ErrorAction Stop
    if ($fileInfo.Length -gt $script:AtlasHkcuDeltaMaximumJournalBytes) {
        throw "The Atlas HKCU delta journal '$JournalPath' exceeds the 16 MiB safety limit."
    }
    return ,[IO.File]::ReadAllBytes($JournalPath)
}

function Read-AtlasHkcuDeltaJournal {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$JournalPath,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ExpectedTransactionId
    )

    $bytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $JournalPath
    return ConvertFrom-AtlasHkcuDeltaJournalBytes -Bytes $bytes -ExpectedTransactionId $ExpectedTransactionId
}

function Repair-AtlasHkcuDeltaFinalFragment {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][pscustomobject]$Transaction,
        [Parameter(Mandatory = $true)][ValidateNotNull()][pscustomobject]$Paths
    )

    if (-not (Test-Path -LiteralPath $Paths.Journal -PathType Leaf)) { return @() }
    Protect-AtlasHkcuInterruptedEmptyFile -Path $Paths.Journal
    $bytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $Paths.Journal
    if ($bytes.Length -eq 0 -or $bytes[$bytes.Length - 1] -eq 0x0A) {
        return ConvertFrom-AtlasHkcuDeltaJournalBytes -Bytes $bytes -ExpectedTransactionId $Transaction.TransactionId
    }

    $lastLineFeed = -1
    for ($index = $bytes.Length - 1; $index -ge 0; $index--) {
        if ($bytes[$index] -eq 0x0A) { $lastLineFeed = $index; break }
    }
    $prefixLength = $lastLineFeed + 1
    $prefixBytes = if ($prefixLength -eq 0) { [byte[]]@() } else {
        $result = New-Object byte[] $prefixLength
        [Array]::Copy($bytes, 0, $result, 0, $prefixLength)
        $result
    }
    $null = @(ConvertFrom-AtlasHkcuDeltaJournalBytes -Bytes $prefixBytes -ExpectedTransactionId $Transaction.TransactionId)

    $fragmentLength = $bytes.Length - $prefixLength
    $fragmentBytes = New-Object byte[] $fragmentLength
    [Array]::Copy($bytes, $prefixLength, $fragmentBytes, 0, $fragmentLength)
    Write-AtlasHkcuRecoveryEvidence -Transaction $Transaction -Paths $Paths -Kind 'UnterminatedFinalFragmentTruncated' -Detail @{
        originalLength  = $bytes.Length
        preservedLength = $prefixLength
        removedLength   = $fragmentLength
        fragmentSha256  = Get-AtlasHkcuSha256Hex -Bytes $fragmentBytes
    }

    $stream = [IO.File]::Open($Paths.Journal, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    try {
        $stream.SetLength($prefixLength)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
    Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($Paths.Journal))
    Assert-AtlasHkcuDeltaFileSecurity -Path $Paths.Journal
    Write-AtlasLog -Message "Recovered Atlas HKCU delta transaction '$($Transaction.TransactionId)' by truncating an unterminated $fragmentLength-byte final fragment." -Level Warning

    return Read-AtlasHkcuDeltaJournal -JournalPath $Paths.Journal -ExpectedTransactionId $Transaction.TransactionId
}

function Write-AtlasHkcuDeltaRecord {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][ValidateNotNull()][string]$SubPath,
        [Parameter(Mandatory = $true)][ValidateSet('SetValue', 'DeleteValue', 'CreateKey', 'DeleteKey')][string]$Operation,
        [AllowNull()][AllowEmptyString()][string]$Name,
        [AllowNull()][string]$Kind,
        [AllowNull()][object]$Data
    )

    $deltaParameters = @{}
    foreach ($propertyName in @('Name', 'Kind', 'Data')) {
        if ($PSBoundParameters.ContainsKey($propertyName)) {
            $deltaParameters[$propertyName] = $PSBoundParameters[$propertyName]
        }
    }

    $initialTransaction = Get-AtlasHkcuActiveTransaction -AllowInactive
    if ($null -eq $initialTransaction) { return }

    Invoke-WithAtlasHkcuDeltaLock -InitialTransaction $initialTransaction -ScriptBlock {
        param($transaction, $paths)
        if ((Test-Path -LiteralPath $paths.Marker -PathType Leaf) -or
            (Test-Path -LiteralPath $paths.Consumed -PathType Leaf)) {
            throw "HKCU delta transaction '$($transaction.TransactionId)' is already committed or consumed; no further writer is permitted."
        }
        $null = @(Repair-AtlasHkcuDeltaFinalFragment -Transaction $transaction -Paths $paths)

        $recordParameters = @{
            TransactionId = $transaction.TransactionId
            SubPath       = $SubPath
            Operation     = $Operation
        }
        foreach ($propertyName in $deltaParameters.Keys) {
            $recordParameters[$propertyName] = $deltaParameters[$propertyName]
        }
        $record = New-AtlasHkcuDeltaRecord @recordParameters
        $json = $record | ConvertTo-Json -Compress -Depth 5
        $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
        Write-AtlasHkcuDurableLine -Path $paths.Journal -Line $json
        $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
    }
}

function New-AtlasHkcuDeltaCommitMarker {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TransactionId,
        [Parameter(Mandatory = $true)][ValidateRange(0, 1000000)][int]$RecordCount,
        [Parameter(Mandatory = $true)][ValidateRange(0, 16777216)][long]$JournalLength,
        [Parameter(Mandatory = $true)][ValidatePattern('^[0-9A-F]{64}$')][string]$JournalSha256
    )

    return [pscustomobject][ordered]@{
        Version       = 1
        TransactionId = $TransactionId
        State         = 'Committed'
        RecordCount   = $RecordCount
        JournalLength = $JournalLength
        JournalSha256 = $JournalSha256
        # Prefix the ISO value so ConvertFrom-Json cannot silently coerce it to a
        # DateTime on newer PowerShell versions while Windows PowerShell returns text.
        CommittedUtc  = 'UTC:' + [DateTime]::UtcNow.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
    }
}

function Read-AtlasHkcuDeltaCommitMarker {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Path,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ExpectedTransactionId
    )

    Assert-AtlasHkcuDeltaFileSecurity -Path $Path
    $markerFile = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($markerFile.Length -lt 2 -or $markerFile.Length -gt 64KB) {
        throw 'The Atlas HKCU delta commit marker has an invalid size.'
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $json = ConvertFrom-AtlasStrictUtf8Bytes -Bytes $bytes
    if ($json -cne $json.Trim() -or -not $json.StartsWith('{') -or -not $json.EndsWith('}')) {
        throw 'The Atlas HKCU delta commit marker is not one canonical JSON object.'
    }
    try { $marker = $json | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "The Atlas HKCU delta commit marker is invalid JSON: $($_.Exception.Message)" }

    Assert-AtlasRegistryDeltaSchema -Record $marker -ExpectedProperties @(
        'Version', 'TransactionId', 'State', 'RecordCount', 'JournalLength', 'JournalSha256', 'CommittedUtc'
    )
    if (($marker.Version -isnot [int] -and $marker.Version -isnot [long]) -or $marker.Version -ne 1) {
        throw 'The Atlas HKCU delta commit marker version is invalid.'
    }
    if ($marker.TransactionId -isnot [string] -or $marker.TransactionId -cne $ExpectedTransactionId) {
        throw "The Atlas HKCU delta commit marker transaction '$($marker.TransactionId)' does not match '$ExpectedTransactionId'."
    }
    if ($marker.State -isnot [string] -or $marker.State -cne 'Committed') {
        throw 'The Atlas HKCU delta commit marker state is not Committed.'
    }
    if (($marker.RecordCount -isnot [int] -and $marker.RecordCount -isnot [long]) -or
        [long]$marker.RecordCount -lt 0 -or [long]$marker.RecordCount -gt 1000000) {
        throw 'The Atlas HKCU delta commit marker record count is invalid.'
    }
    if (($marker.JournalLength -isnot [int] -and $marker.JournalLength -isnot [long]) -or
        [long]$marker.JournalLength -lt 0 -or [long]$marker.JournalLength -gt $script:AtlasHkcuDeltaMaximumJournalBytes) {
        throw 'The Atlas HKCU delta commit marker journal length is invalid.'
    }
    if ($marker.JournalSha256 -isnot [string] -or $marker.JournalSha256 -cnotmatch '^[0-9A-F]{64}$') {
        throw 'The Atlas HKCU delta commit marker journal hash is invalid.'
    }
    $timestamp = [DateTime]::MinValue
    if ($marker.CommittedUtc -isnot [string] -or
        -not $marker.CommittedUtc.StartsWith('UTC:') -or
        -not [DateTime]::TryParseExact(
            $marker.CommittedUtc.Substring(4),
            'o',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$timestamp
        )) {
        throw 'The Atlas HKCU delta commit marker timestamp is invalid.'
    }
    if ($timestamp.Kind -ne [DateTimeKind]::Utc -or
        $timestamp.ToString('o', [Globalization.CultureInfo]::InvariantCulture) -cne $marker.CommittedUtc.Substring(4)) {
        throw 'The Atlas HKCU delta commit marker timestamp is not canonical UTC.'
    }
    return $marker
}

function Assert-AtlasHkcuDeltaCommitBinding {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Marker,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Records,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$JournalBytes
    )

    if ([long]$Marker.RecordCount -ne $Records.Count) { throw 'The committed HKCU delta record count does not match the journal.' }
    if ([long]$Marker.JournalLength -ne $JournalBytes.Length) { throw 'The committed HKCU delta length does not match the journal.' }
    $actualHash = Get-AtlasHkcuSha256Hex -Bytes $JournalBytes
    if ([string]$Marker.JournalSha256 -cne $actualHash) { throw 'The committed HKCU delta hash does not match the journal.' }
}

function Write-AtlasHkcuDeltaCommitMarkerAtomic {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Transaction,
        [Parameter(Mandatory = $true)][pscustomobject]$Paths,
        [Parameter(Mandatory = $true)][pscustomobject]$Marker
    )

    if (Test-Path -LiteralPath $Paths.Marker -PathType Leaf) { throw 'The Atlas HKCU delta commit marker already exists.' }
    if (Test-Path -LiteralPath $Paths.MarkerTemp -PathType Leaf) {
        Protect-AtlasHkcuInterruptedEmptyFile -Path $Paths.MarkerTemp
        $tempFile = Get-Item -LiteralPath $Paths.MarkerTemp -Force -ErrorAction Stop
        if ($tempFile.Length -gt 64KB) {
            throw 'The incomplete Atlas HKCU commit temporary exceeds its safety limit.'
        }
        $tempBytes = [IO.File]::ReadAllBytes($Paths.MarkerTemp)
        Write-AtlasHkcuRecoveryEvidence -Transaction $Transaction -Paths $Paths -Kind 'IncompleteCommitTemporaryRemoved' -Detail @{
            removedLength = $tempBytes.Length
            tempSha256    = Get-AtlasHkcuSha256Hex -Bytes $tempBytes
        }
        [IO.File]::Delete($Paths.MarkerTemp)
    }

    $json = $Marker | ConvertTo-Json -Compress -Depth 4
    $bytes = ConvertTo-AtlasStrictUtf8Bytes -Text $json
    $creationStream = [IO.File]::Open(
        $Paths.MarkerTemp,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    $creationStream.Dispose()
    Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($Paths.MarkerTemp))
    Assert-AtlasHkcuDeltaFileSecurity -Path $Paths.MarkerTemp

    $stream = [IO.File]::Open($Paths.MarkerTemp, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
    Assert-AtlasHkcuDeltaFileSecurity -Path $Paths.MarkerTemp
    [IO.File]::Move($Paths.MarkerTemp, $Paths.Marker)
    Set-AtlasHkcuDeltaFileAccessControl -File (New-Object IO.FileInfo($Paths.Marker))
    Assert-AtlasHkcuDeltaFileSecurity -Path $Paths.Marker
}

function Complete-AtlasHkcuDeltaJournal {
    <#
    .SYNOPSIS
        Atomically commits the active transaction's exact HKCU delta prefix for replay.
    #>
    $initialTransaction = Get-AtlasHkcuActiveTransaction
    return Invoke-WithAtlasHkcuDeltaLock -InitialTransaction $initialTransaction -ScriptBlock {
        param($transaction, $paths)

        if (Test-Path -LiteralPath $paths.Consumed -PathType Leaf) {
            if (Test-Path -LiteralPath $paths.Marker -PathType Leaf) {
                throw "HKCU delta transaction '$($transaction.TransactionId)' has both active and consumed commit markers."
            }
            $consumedMarker = Read-AtlasHkcuDeltaCommitMarker -Path $paths.Consumed `
                -ExpectedTransactionId $transaction.TransactionId
            if (Test-Path -LiteralPath $paths.Journal -PathType Leaf) {
                $records = @(Read-AtlasHkcuDeltaJournal -JournalPath $paths.Journal -ExpectedTransactionId $transaction.TransactionId)
                $journalBytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $paths.Journal
                Assert-AtlasHkcuDeltaCommitBinding -Marker $consumedMarker -Records $records -JournalBytes $journalBytes
            }
            $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
            return $consumedMarker
        }

        if (Test-Path -LiteralPath $paths.Marker -PathType Leaf) {
            $records = @(Read-AtlasHkcuDeltaJournal -JournalPath $paths.Journal -ExpectedTransactionId $transaction.TransactionId)
            $journalBytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $paths.Journal
            $existingMarker = Read-AtlasHkcuDeltaCommitMarker -Path $paths.Marker -ExpectedTransactionId $transaction.TransactionId
            Assert-AtlasHkcuDeltaCommitBinding -Marker $existingMarker -Records $records -JournalBytes $journalBytes
            $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
            return $existingMarker
        }

        $records = @(Repair-AtlasHkcuDeltaFinalFragment -Transaction $transaction -Paths $paths)
        $journalBytes = Get-AtlasHkcuDeltaJournalBytes -JournalPath $paths.Journal
        $marker = New-AtlasHkcuDeltaCommitMarker -TransactionId $transaction.TransactionId `
            -RecordCount $records.Count -JournalLength $journalBytes.Length `
            -JournalSha256 (Get-AtlasHkcuSha256Hex -Bytes $journalBytes)
        $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
        Write-AtlasHkcuDeltaCommitMarkerAtomic -Transaction $transaction -Paths $paths -Marker $marker
        $null = Assert-AtlasHkcuTransactionMatch -Expected $transaction
        return Read-AtlasHkcuDeltaCommitMarker -Path $paths.Marker -ExpectedTransactionId $transaction.TransactionId
    }
}

function Invoke-AtlasRegistryDelta {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][pscustomobject]$Delta,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DestinationRootSubPath
    )

    $canonicalDestinationRoot = ConvertTo-AtlasCanonicalHkcuSubPath -SubPath $DestinationRootSubPath
    if ([string]::IsNullOrEmpty($canonicalDestinationRoot) -or
        $canonicalDestinationRoot -cne $DestinationRootSubPath) {
        throw "The destination root '$DestinationRootSubPath' is not a canonical HKEY_USERS subpath."
    }

    $destinationSubPath = $canonicalDestinationRoot
    if ($Delta.SubPath) { $destinationSubPath = "$canonicalDestinationRoot\$($Delta.SubPath)" }
    switch ($Delta.Operation) {
        'SetValue' {
            Set-AtlasRegistryValueCore -ProviderPath "Registry::HKEY_USERS\$destinationSubPath" `
                -Name $Delta.Name -Type $Delta.Kind -Data $Delta.Data
        }
        'DeleteValue' {
            $key = [Microsoft.Win32.Registry]::Users.OpenSubKey($destinationSubPath, $true)
            if ($null -eq $key) { return }
            try { $key.DeleteValue($Delta.Name, $false) }
            finally { $key.Close() }
        }
        'CreateKey' {
            $key = [Microsoft.Win32.Registry]::Users.CreateSubKey($destinationSubPath)
            if ($null -eq $key) { throw "Failed to create the default-user-hive key 'HKU\$destinationSubPath'." }
            $key.Close()
        }
        'DeleteKey' {
            if ([string]::IsNullOrEmpty($Delta.SubPath)) { throw 'Refusing to delete the default-user hive root.' }
            [Microsoft.Win32.Registry]::Users.DeleteSubKeyTree($destinationSubPath, $false)
        }
    }
}

function Invoke-AtlasHkcuDeltaJournal {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Deltas,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DestinationRootSubPath
    )

    foreach ($delta in $Deltas) {
        Invoke-AtlasRegistryDelta -Delta $delta -DestinationRootSubPath $DestinationRootSubPath
    }
    return [int]$Deltas.Count
}
