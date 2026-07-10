[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'Public parameters are captured by the journal mutation closures that PSScriptAnalyzer does not trace.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions',
    '',
    Justification = 'Journal transitions are explicit transactional APIs; WhatIf would invalidate their durability contract.'
)]
param()

Set-StrictMode -Version 3.0

$script:AtlasJournalSchemaVersion = 1
$script:AtlasJournalOwnerSid = 'S-1-5-32-544'
$script:AtlasJournalPrincipalSids = @(
    'S-1-5-18'
    'S-1-5-32-544'
    'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
)
$script:AtlasJournalModes = @('Fresh', 'Upgrade', 'Oobe', 'Reapply')
$script:AtlasJournalRecoveryPolicies = @('Idempotent', 'Reconcile', 'Manual')
$script:AtlasJournalPhaseStates = @('Pending', 'Ready', 'Running', 'Succeeded', 'Failed', 'Skipped')
$script:AtlasJournalCompensationStates = @('Pending', 'Ready', 'Running', 'Compensated', 'Discharged', 'Failed')
$script:AtlasJournalStates = @('InProgress', 'Failed', 'Completed')
$script:AtlasJournalMaximumDocumentBytes = 4MB
$script:AtlasJournalMaximumPhases = 128
$script:AtlasJournalMaximumCompensations = 512
$script:AtlasJournalMaximumEvents = 4096
$script:AtlasJournalLockTimeoutMilliseconds = 30000
$script:AtlasPayloadGenerationStates = @(
    'NotManaged', 'Pending', 'Staging', 'Staged', 'Activating', 'Active',
    'RollingBack', 'RolledBack', 'Committed', 'Failed'
)

function Get-AtlasInstallJournalPath {
    <#
    .SYNOPSIS
        Returns the protected, payload-independent path of the active Atlas install journal.
    #>
    $windowsPath = [Environment]::GetFolderPath('Windows')
    return Join-Path -Path $windowsPath -ChildPath 'AtlasOS\Transactions\active.json'
}

function Get-AtlasJournalUtcTimestamp {
    return [DateTime]::UtcNow.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
}

function Assert-AtlasJournalName {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$Pattern = '^[A-Za-z][A-Za-z0-9]*(?:[/-][A-Za-z0-9][A-Za-z0-9-]*)*$'
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt 128 -or $Value -notmatch $Pattern) {
        throw "Invalid $Label '$Value'."
    }
}

function Assert-AtlasJournalWholeNumber {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][long]$Minimum,
        [Parameter(Mandatory = $true)][long]$Maximum
    )

    if ($Value -isnot [int] -and $Value -isnot [long]) {
        throw "$Label must be a JSON integer."
    }
    $number = [long]$Value
    if ($number -lt $Minimum -or $number -gt $Maximum) {
        throw "$Label must be between $Minimum and $Maximum."
    }
}

function Assert-AtlasJournalBoolean {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Value -isnot [bool]) {
        throw "$Label must be a JSON Boolean."
    }
}

function Assert-AtlasJournalArray {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Value -isnot [Array]) {
        throw "$Label must be a JSON array."
    }
}

function Assert-AtlasJournalString {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowNull
    )

    if ($null -eq $Value -and $AllowNull) {
        return
    }
    if ($Value -isnot [string]) {
        throw "$Label must be a JSON string."
    }
}

function Assert-AtlasJournalNotReparsePoint {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Install journal path must not be a reparse point: '$Path'."
    }
}

function New-AtlasJournalDirectorySecurity {
    $security = New-Object Security.AccessControl.DirectorySecurity
    $security.SetAccessRuleProtection($true, $false)
    $security.SetOwner((New-Object Security.Principal.SecurityIdentifier($script:AtlasJournalOwnerSid)))

    $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit
    foreach ($sidValue in $script:AtlasJournalPrincipalSids) {
        $sid = New-Object Security.Principal.SecurityIdentifier($sidValue)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        )
        [void]$security.AddAccessRule($rule)
    }

    return $security
}

function New-AtlasJournalFileSecurity {
    $security = New-Object Security.AccessControl.FileSecurity
    $security.SetAccessRuleProtection($true, $false)
    $security.SetOwner((New-Object Security.Principal.SecurityIdentifier($script:AtlasJournalOwnerSid)))

    foreach ($sidValue in $script:AtlasJournalPrincipalSids) {
        $sid = New-Object Security.Principal.SecurityIdentifier($sidValue)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            [Security.AccessControl.AccessControlType]::Allow
        )
        [void]$security.AddAccessRule($rule)
    }

    return $security
}

function Set-AtlasJournalFileAcl {
    param([Parameter(Mandatory = $true)][string]$Path)

    Set-Acl -LiteralPath $Path -AclObject (New-AtlasJournalFileSecurity) -ErrorAction Stop
}

function Test-AtlasJournalAcl {
    param(
        [Parameter(Mandatory = $true)][Security.AccessControl.FileSystemSecurity]$Acl,
        [Parameter(Mandatory = $true)][bool]$Directory
    )

    if (-not $Acl.AreAccessRulesProtected) {
        return $false
    }

    $owner = $Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
    if ($owner -ne $script:AtlasJournalOwnerSid) {
        return $false
    }

    $expected = @{}
    foreach ($sidValue in $script:AtlasJournalPrincipalSids) {
        $expected[$sidValue] = 0
    }

    $rules = @($Acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))
    if ($rules.Count -ne $script:AtlasJournalPrincipalSids.Count) {
        return $false
    }

    $expectedInheritance = if ($Directory) {
        [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
            [Security.AccessControl.InheritanceFlags]::ObjectInherit
    }
    else {
        [Security.AccessControl.InheritanceFlags]::None
    }
    foreach ($rule in $rules) {
        $sidValue = $rule.IdentityReference.Value
        if (-not $expected.ContainsKey($sidValue) -or
            $rule.IsInherited -or
            $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or
            $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::FullControl -or
            $rule.InheritanceFlags -ne $expectedInheritance -or
            $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None) {
            return $false
        }
        $expected[$sidValue] = [int]$expected[$sidValue] + 1
    }

    return -not ($expected.Values | Where-Object { $_ -ne 1 })
}

function Assert-AtlasJournalProtectedDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Install journal directory does not exist: '$Path'."
    }
    Assert-AtlasJournalNotReparsePoint -Path $Path
    if (-not (Test-AtlasJournalAcl -Acl (Get-Acl -LiteralPath $Path -ErrorAction Stop) -Directory $true)) {
        throw "Install journal directory ACL is not the required protected ACL: '$Path'."
    }
}

function Assert-AtlasJournalProtectedFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Install journal file is not a regular file: '$Path'."
    }
    Assert-AtlasJournalNotReparsePoint -Path $Path
    if (-not (Test-AtlasJournalAcl -Acl (Get-Acl -LiteralPath $Path -ErrorAction Stop) -Directory $false)) {
        throw "Install journal file ACL is not the required protected ACL: '$Path'."
    }
}

function Initialize-AtlasInstallJournalStore {
    <#
    .SYNOPSIS
        Creates and protects the Atlas transaction store below the Windows directory.
    .DESCRIPTION
        The protected DACL grants FullControl only to SYSTEM, Administrators and the
        TrustedInstaller service SID. Reparse points are rejected. This must run elevated
        before any destructive install work.
    #>
    [CmdletBinding()]
    param(
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    $expectedJournalPath = [IO.Path]::GetFullPath((Get-AtlasInstallJournalPath))
    $requestedJournalPath = [IO.Path]::GetFullPath($JournalPath)
    if (-not [string]::Equals(
            $requestedJournalPath,
            $expectedJournalPath,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The Atlas install journal store initializer only accepts the canonical path '$expectedJournalPath'."
    }

    $windowsPath = [IO.Path]::GetFullPath([Environment]::GetFolderPath('Windows')).TrimEnd('\')
    $storePath = [IO.Path]::GetFullPath((Split-Path -Parent $requestedJournalPath)).TrimEnd('\')
    $requiredPrefix = $windowsPath + '\'
    if (-not $storePath.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The Atlas install journal store must be below '$windowsPath'."
    }

    $relativeStorePath = $storePath.Substring($requiredPrefix.Length)
    $currentPath = $windowsPath
    foreach ($segment in @($relativeStorePath -split '\\' | Where-Object { $_ })) {
        $currentPath = Join-Path -Path $currentPath -ChildPath $segment
        if (Test-Path -LiteralPath $currentPath) {
            if (-not (Test-Path -LiteralPath $currentPath -PathType Container)) {
                throw "Install journal store component is not a directory: '$currentPath'."
            }
            Assert-AtlasJournalNotReparsePoint -Path $currentPath
        }
        else {
            New-Item -Path $currentPath -ItemType Directory -ErrorAction Stop | Out-Null
        }

        Set-Acl -LiteralPath $currentPath -AclObject (New-AtlasJournalDirectorySecurity) -ErrorAction Stop
        Assert-AtlasJournalProtectedDirectory -Path $currentPath
    }

    Assert-AtlasInstallJournalStore -JournalPath $JournalPath
    return $storePath
}

function Assert-AtlasInstallJournalStore {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [AllowNull()][string]$TransactionRoot
    )

    if (-not [IO.Path]::IsPathRooted($JournalPath)) {
        throw "Install journal path must be rooted: '$JournalPath'."
    }

    $storePath = Split-Path -Parent ([IO.Path]::GetFullPath($JournalPath))
    if (-not (Test-Path -LiteralPath $storePath -PathType Container)) {
        throw "Install journal store does not exist: '$storePath'."
    }

    Assert-AtlasJournalProtectedDirectory -Path $storePath

    foreach ($documentPath in @($JournalPath, "$JournalPath.bak", "$JournalPath.lock")) {
        if (Test-Path -LiteralPath $documentPath) {
            Assert-AtlasJournalProtectedFile -Path $documentPath
        }
    }

    $archivePath = Join-Path -Path $storePath -ChildPath 'archive'
    if (Test-Path -LiteralPath $archivePath) {
        Assert-AtlasJournalProtectedDirectory -Path $archivePath
        foreach ($archiveItem in @(Get-ChildItem -LiteralPath $archivePath -Force -ErrorAction Stop)) {
            if ($archiveItem.PSIsContainer) {
                throw "Unexpected directory in the install journal archive: '$($archiveItem.FullName)'."
            }
            Assert-AtlasJournalProtectedFile -Path $archiveItem.FullName
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($TransactionRoot)) {
        $canonicalStore = [IO.Path]::GetFullPath($storePath).TrimEnd('\')
        $canonicalRoot = [IO.Path]::GetFullPath($TransactionRoot).TrimEnd('\')
        if (-not $canonicalRoot.StartsWith($canonicalStore + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Install transaction root must be a direct child of '$canonicalStore'."
        }
        if ((Split-Path -Parent $canonicalRoot) -ine $canonicalStore) {
            throw "Install transaction root must be a direct child of '$canonicalStore'."
        }
        Assert-AtlasJournalProtectedDirectory -Path $canonicalRoot
    }
}

function Open-AtlasJournalLock {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [ValidateRange(1, 300000)][int]$TimeoutMilliseconds = $script:AtlasJournalLockTimeoutMilliseconds
    )

    $lockPath = "$JournalPath.lock"
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
                throw "Timed out after $TimeoutMilliseconds ms waiting for the Atlas install journal file lock '$lockPath'."
            }
            Start-Sleep -Milliseconds 50
            continue
        }

        try {
            Assert-AtlasJournalNotReparsePoint -Path $lockPath
            if ($existed) {
                if (-not (Test-AtlasJournalAcl -Acl (Get-Acl -LiteralPath $lockPath -ErrorAction Stop) -Directory $false)) {
                    throw "Install journal lock ACL is not the required protected ACL: '$lockPath'."
                }
            }
            else {
                Set-AtlasJournalFileAcl -Path $lockPath
            }
            return $stream
        }
        catch {
            $stream.Dispose()
            throw
        }
    }
}

function Invoke-WithAtlasJournalLock {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
    )

    Assert-AtlasInstallJournalStore -JournalPath $JournalPath
    $lockStream = Open-AtlasJournalLock -JournalPath $JournalPath
    try {
        Assert-AtlasInstallJournalStore -JournalPath $JournalPath
        & $ScriptBlock
    }
    finally {
        $lockStream.Dispose()
    }
}

function ConvertTo-AtlasIdentityField {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return '-1:'
    }
    $text = [string]$Value
    return "$($text.Length):$text"
}

function Get-AtlasJournalIdentityHash {
    param([Parameter(Mandatory = $true)]$Journal)

    $fields = New-Object Collections.Generic.List[string]
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.transactionId))
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.transactionRoot))
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.sourceVersion))
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.targetVersion))
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.mode))
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.interactiveUserSid))
    $fields.Add((ConvertTo-AtlasIdentityField -Value $Journal.initiatingPrincipalSid))
    foreach ($option in @($Journal.options)) {
        $fields.Add((ConvertTo-AtlasIdentityField -Value $option))
    }
    foreach ($phase in @($Journal.phases)) {
        $fields.Add((ConvertTo-AtlasIdentityField -Value $phase.key))
        $fields.Add((ConvertTo-AtlasIdentityField -Value ([bool]$phase.required)))
        $fields.Add((ConvertTo-AtlasIdentityField -Value $phase.recoveryPolicy))
        $fields.Add((ConvertTo-AtlasIdentityField -Value $phase.postcondition))
    }

    $canonical = $fields -join '|'
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical))
    }
    finally {
        $sha256.Dispose()
    }
    return ([BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

function Get-AtlasJournalSha256 {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash($Bytes)
    }
    finally {
        $sha256.Dispose()
    }
    return ([BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

function Get-AtlasJournalRawDocumentChecksumMatch {
    param([Parameter(Mandatory = $true)][string]$Raw)

    # The checksum is deliberately the first top-level property. Anchoring the match
    # to the start of the JSON document makes the checksum slot unambiguous even when
    # caller-owned compensation data contains a nested property with the same name.
    $pattern = '\A\s*\{\s*"documentSha256"\s*:\s*"([a-f0-9]{64})"'
    $checksumMatch = [Text.RegularExpressions.Regex]::Match($Raw, $pattern)
    if (-not $checksumMatch.Success) {
        throw 'Install journal must begin with one lowercase SHA-256 document checksum.'
    }
    return $checksumMatch
}

function Test-AtlasJournalRawDocumentChecksum {
    param(
        [Parameter(Mandatory = $true)][string]$Raw,
        [Parameter(Mandatory = $true)]$Journal
    )

    $checksumMatch = Get-AtlasJournalRawDocumentChecksumMatch -Raw $Raw
    $storedChecksum = $checksumMatch.Groups[1].Value
    if ([string]$Journal.documentSha256 -cne $storedChecksum) {
        throw 'Install journal parsed checksum differs from its serialized checksum.'
    }

    $checksumGroup = $checksumMatch.Groups[1]
    $placeholderRaw = $Raw.Substring(0, $checksumGroup.Index) + ('0' * 64) +
        $Raw.Substring($checksumGroup.Index + $checksumGroup.Length)
    $bytes = (New-Object Text.UTF8Encoding($false, $true)).GetBytes($placeholderRaw)
    $expectedChecksum = Get-AtlasJournalSha256 -Bytes $bytes
    if ($storedChecksum -cne $expectedChecksum) {
        throw 'Install journal document checksum does not match its serialized contents.'
    }
    return $true
}

function ConvertTo-AtlasPhasePlan {
    param([Parameter(Mandatory = $true)][object[]]$PhasePlan)

    if ($PhasePlan.Count -lt 1 -or $PhasePlan.Count -gt $script:AtlasJournalMaximumPhases) {
        throw "The install journal phase plan must contain between 1 and $($script:AtlasJournalMaximumPhases) entries."
    }

    $seen = @{}
    $result = @()
    foreach ($entry in $PhasePlan) {
        if ($entry -is [string]) {
            $key = [string]$entry
            $required = $true
            $recoveryPolicy = 'Manual'
            $postcondition = 'ManualVerification'
        }
        else {
            if ($entry -is [Collections.IDictionary]) {
                $keyValue = if ($entry.Contains('Key')) { $entry['Key'] } else { $null }
                $requiredSpecified = $entry.Contains('Required')
                $requiredValue = if ($entry.Contains('Required')) { $entry['Required'] } else { $true }
                $recoveryValue = if ($entry.Contains('RecoveryPolicy')) { $entry['RecoveryPolicy'] } else { $null }
                $postconditionValue = if ($entry.Contains('Postcondition')) { $entry['Postcondition'] } else { $null }
            }
            else {
                $keyProperty = $entry.PSObject.Properties['Key']
                $requiredProperty = $entry.PSObject.Properties['Required']
                $recoveryProperty = $entry.PSObject.Properties['RecoveryPolicy']
                $postconditionProperty = $entry.PSObject.Properties['Postcondition']
                $keyValue = if ($keyProperty) { $keyProperty.Value } else { $null }
                $requiredSpecified = $null -ne $requiredProperty
                $requiredValue = if ($requiredProperty) { $requiredProperty.Value } else { $true }
                $recoveryValue = if ($recoveryProperty) { $recoveryProperty.Value } else { $null }
                $postconditionValue = if ($postconditionProperty) { $postconditionProperty.Value } else { $null }
            }

            if ($null -ne $keyValue -and $keyValue -isnot [string]) {
                throw 'Install journal phase Key must be a string.'
            }
            if ($requiredSpecified -and $requiredValue -isnot [bool]) {
                throw "Install journal phase '$keyValue' Required must be a Boolean."
            }
            if ($null -ne $recoveryValue -and $recoveryValue -isnot [string]) {
                throw "Install journal phase '$keyValue' RecoveryPolicy must be a string."
            }
            if ($null -ne $postconditionValue -and $postconditionValue -isnot [string]) {
                throw "Install journal phase '$keyValue' Postcondition must be a string."
            }

            $key = [string]$keyValue
            $required = [bool]$requiredValue
            $recoveryPolicy = if ([string]::IsNullOrWhiteSpace([string]$recoveryValue)) {
                'Manual'
            }
            else {
                [string]$recoveryValue
            }
            $postcondition = if ([string]::IsNullOrWhiteSpace([string]$postconditionValue)) {
                'CallerVerified'
            }
            else {
                [string]$postconditionValue
            }
        }

        Assert-AtlasJournalName -Value $key -Label 'phase key'
        if ($script:AtlasJournalRecoveryPolicies -notcontains $recoveryPolicy) {
            throw "Invalid recovery policy '$recoveryPolicy' for phase '$key'."
        }
        if ($seen.ContainsKey($key)) {
            throw "Duplicate install journal phase '$key'."
        }
        Assert-AtlasJournalName -Value $postcondition -Label 'phase postcondition'
        $seen[$key] = $true

        $result += [ordered]@{
            key            = $key
            required       = $required
            recoveryPolicy = $recoveryPolicy
            postcondition  = $postcondition
            state          = 'Pending'
            attempts       = 0
            startedUtc     = $null
            completedUtc   = $null
            postconditionEvidence = $null
            lastError      = $null
            reconciliationEvidence = $null
        }
    }
    return @($result)
}

function Add-AtlasJournalEvent {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)][string]$Kind,
        [AllowNull()][string]$Subject,
        [AllowNull()][object]$Detail
    )

    $Journal.eventSequence = [int]$Journal.eventSequence + 1
    $journalEvent = [ordered]@{
        sequence = $Journal.eventSequence
        utc      = Get-AtlasJournalUtcTimestamp
        kind     = $Kind
        subject  = $Subject
        detail   = $Detail
    }
    $Journal.events = @($Journal.events) + @($journalEvent)
}

function Test-AtlasJournalDocument {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [switch]$SkipDocumentChecksum
    )

    Assert-AtlasJournalWholeNumber -Value $Journal.schemaVersion -Label 'Install journal schemaVersion' `
        -Minimum $script:AtlasJournalSchemaVersion -Maximum $script:AtlasJournalSchemaVersion
    if ([long]$Journal.schemaVersion -ne $script:AtlasJournalSchemaVersion) {
        throw "Unsupported install journal schema version '$($Journal.schemaVersion)'."
    }

    Assert-AtlasJournalString -Value $Journal.transactionId -Label 'Install journal transactionId'
    $transactionId = [Guid]::Empty
    if (-not [Guid]::TryParse([string]$Journal.transactionId, [ref]$transactionId) -or
        $transactionId -eq [Guid]::Empty) {
        throw 'Install journal transactionId is invalid.'
    }
    Assert-AtlasJournalWholeNumber -Value $Journal.revision -Label 'Install journal revision' `
        -Minimum 0 -Maximum 1000000
    Assert-AtlasJournalWholeNumber -Value $Journal.resumeCount -Label 'Install journal resumeCount' `
        -Minimum 0 -Maximum 1000000
    Assert-AtlasJournalString -Value $Journal.state -Label 'Install journal state'
    if ($script:AtlasJournalStates -notcontains [string]$Journal.state) {
        throw "Install journal state '$($Journal.state)' is invalid."
    }
    Assert-AtlasJournalString -Value $Journal.targetVersion -Label 'Install journal targetVersion'
    if ([string]::IsNullOrWhiteSpace([string]$Journal.targetVersion) -or
        ([string]$Journal.targetVersion).Length -gt 128) {
        throw 'Install journal targetVersion is required.'
    }
    Assert-AtlasJournalString -Value $Journal.sourceVersion -Label 'Install journal sourceVersion' -AllowNull
    if (([string]$Journal.sourceVersion).Length -gt 128) {
        throw 'Install journal sourceVersion exceeds 128 characters.'
    }
    Assert-AtlasJournalString -Value $Journal.mode -Label 'Install journal mode'
    if ($script:AtlasJournalModes -notcontains [string]$Journal.mode) {
        throw "Install journal mode '$($Journal.mode)' is invalid."
    }
    Assert-AtlasJournalString -Value $Journal.interactiveUserSid -Label 'Install journal interactiveUserSid' -AllowNull
    if (-not [string]::IsNullOrWhiteSpace([string]$Journal.interactiveUserSid)) {
        try {
            $null = New-Object Security.Principal.SecurityIdentifier([string]$Journal.interactiveUserSid)
        }
        catch {
            throw "Install journal interactiveUserSid '$($Journal.interactiveUserSid)' is invalid."
        }
    }
    Assert-AtlasJournalString -Value $Journal.initiatingPrincipalSid -Label 'Install journal initiatingPrincipalSid'
    try {
        $null = New-Object Security.Principal.SecurityIdentifier([string]$Journal.initiatingPrincipalSid)
    }
    catch {
        throw "Install journal initiatingPrincipalSid '$($Journal.initiatingPrincipalSid)' is invalid."
    }
    Assert-AtlasJournalWholeNumber -Value $Journal.payload.schemaVersion `
        -Label 'Install journal payload schemaVersion' -Minimum 1 -Maximum 1
    Assert-AtlasJournalBoolean -Value $Journal.payload.required -Label 'Install journal payload required'
    Assert-AtlasJournalString -Value $Journal.payload.generationState `
        -Label 'Install journal payload generationState'
    if ($script:AtlasPayloadGenerationStates -notcontains [string]$Journal.payload.generationState) {
        throw "Install journal payload generation state '$($Journal.payload.generationState)' is invalid."
    }
    Assert-AtlasJournalArray -Value $Journal.payload.roots -Label 'Install journal payload roots'
    Assert-AtlasJournalString -Value $Journal.transactionRoot -Label 'Install journal transactionRoot'
    if (-not [IO.Path]::IsPathRooted([string]$Journal.transactionRoot)) {
        throw 'Install journal transactionRoot must be rooted.'
    }

    Assert-AtlasJournalArray -Value $Journal.options -Label 'Install journal options'
    $optionNames = @($Journal.options)
    if ($optionNames.Count -gt 128) {
        throw 'Install journal options exceed the schema limit of 128.'
    }
    if (@($optionNames | Sort-Object -Unique).Count -ne $optionNames.Count) {
        throw 'Install journal options contain duplicates.'
    }
    foreach ($optionName in $optionNames) {
        Assert-AtlasJournalString -Value $optionName -Label 'Install journal option'
        Assert-AtlasJournalName -Value ([string]$optionName) -Label 'option' -Pattern '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    }

    Assert-AtlasJournalArray -Value $Journal.phases -Label 'Install journal phases'
    $phases = @($Journal.phases)
    if ($phases.Count -lt 1 -or $phases.Count -gt $script:AtlasJournalMaximumPhases) {
        throw "Install journal phases must contain between 1 and $($script:AtlasJournalMaximumPhases) entries."
    }

    $phaseKeys = @{}
    $encounteredUnresolvedPhase = $false
    foreach ($phase in $phases) {
        Assert-AtlasJournalString -Value $phase.key -Label 'Install journal phase key'
        Assert-AtlasJournalName -Value ([string]$phase.key) -Label 'phase key'
        if ($phaseKeys.ContainsKey([string]$phase.key)) {
            throw "Duplicate install journal phase '$($phase.key)'."
        }
        $phaseKeys[[string]$phase.key] = $true
        Assert-AtlasJournalString -Value $phase.recoveryPolicy `
            -Label "Install journal phase '$($phase.key)' recoveryPolicy"
        if ($script:AtlasJournalRecoveryPolicies -notcontains [string]$phase.recoveryPolicy) {
            throw "Invalid recovery policy '$($phase.recoveryPolicy)' for phase '$($phase.key)'."
        }
        Assert-AtlasJournalString -Value $phase.postcondition `
            -Label "Install journal phase '$($phase.key)' postcondition"
        Assert-AtlasJournalName -Value ([string]$phase.postcondition) -Label 'phase postcondition'
        Assert-AtlasJournalString -Value $phase.state -Label "Install journal phase '$($phase.key)' state"
        if ($script:AtlasJournalPhaseStates -notcontains [string]$phase.state) {
            throw "Invalid state '$($phase.state)' for phase '$($phase.key)'."
        }
        Assert-AtlasJournalBoolean -Value $phase.required -Label "Install journal phase '$($phase.key)' required"
        Assert-AtlasJournalWholeNumber -Value $phase.attempts `
            -Label "Install journal phase '$($phase.key)' attempts" -Minimum 0 -Maximum 100000
        $phaseIsTerminal = [string]$phase.state -in @('Succeeded', 'Skipped')
        if ($phaseIsTerminal -and $encounteredUnresolvedPhase) {
            throw "Phase '$($phase.key)' is terminal after an unresolved predecessor."
        }
        if (-not $phaseIsTerminal) {
            $encounteredUnresolvedPhase = $true
        }
        if ([bool]$phase.required -and $phase.state -eq 'Skipped') {
            throw "Required phase '$($phase.key)' cannot be skipped."
        }
        if ($phase.state -eq 'Succeeded' -and
            [string]::IsNullOrWhiteSpace([string]$phase.postconditionEvidence)) {
            throw "Succeeded phase '$($phase.key)' lacks postcondition evidence."
        }
        if ($phase.state -eq 'Skipped' -and
            [string]::IsNullOrWhiteSpace([string]$phase.postconditionEvidence)) {
            throw "Skipped phase '$($phase.key)' lacks explicit skip evidence."
        }
        if ($phase.state -eq 'Ready' -and $null -eq $phase.reconciliationEvidence) {
            throw "Ready phase '$($phase.key)' lacks reconciliation evidence."
        }
        if ($phase.state -eq 'Failed' -and $null -eq $phase.lastError) {
            throw "Failed phase '$($phase.key)' lacks failure evidence."
        }
    }
    if (@($phases | Where-Object { $_.state -eq 'Running' }).Count -gt 1) {
        throw 'Install journal contains more than one Running phase.'
    }

    Assert-AtlasJournalArray -Value $Journal.compensations -Label 'Install journal compensations'
    $compensations = @($Journal.compensations)
    if ($compensations.Count -gt $script:AtlasJournalMaximumCompensations) {
        throw "Install journal compensations exceed the schema limit of $($script:AtlasJournalMaximumCompensations)."
    }
    $compensationIds = @{}
    $expectedCompensationOrder = 1
    foreach ($compensation in $compensations) {
        Assert-AtlasJournalString -Value $compensation.id -Label 'Install journal compensation id'
        Assert-AtlasJournalName -Value ([string]$compensation.id) -Label 'compensation id'
        Assert-AtlasJournalString -Value $compensation.kind `
            -Label "Install journal compensation '$($compensation.id)' kind"
        Assert-AtlasJournalName -Value ([string]$compensation.kind) -Label 'compensation kind'
        if ($compensationIds.ContainsKey([string]$compensation.id)) {
            throw "Duplicate install journal compensation '$($compensation.id)'."
        }
        $compensationIds[[string]$compensation.id] = $true
        Assert-AtlasJournalString -Value $compensation.ownerPhase `
            -Label "Install journal compensation '$($compensation.id)' ownerPhase"
        if (-not $phaseKeys.ContainsKey([string]$compensation.ownerPhase)) {
            throw "Compensation '$($compensation.id)' refers to an unknown phase."
        }
        Assert-AtlasJournalString -Value $compensation.recoveryPolicy `
            -Label "Install journal compensation '$($compensation.id)' recoveryPolicy"
        if ($script:AtlasJournalRecoveryPolicies -notcontains [string]$compensation.recoveryPolicy) {
            throw "Compensation '$($compensation.id)' has an invalid recovery policy."
        }
        Assert-AtlasJournalString -Value $compensation.state `
            -Label "Install journal compensation '$($compensation.id)' state"
        if ($script:AtlasJournalCompensationStates -notcontains [string]$compensation.state) {
            throw "Compensation '$($compensation.id)' has an invalid state."
        }
        Assert-AtlasJournalWholeNumber -Value $compensation.order `
            -Label "Install journal compensation '$($compensation.id)' order" -Minimum 1 -Maximum 100000
        if ([long]$compensation.order -ne $expectedCompensationOrder) {
            throw "Compensation '$($compensation.id)' has a non-contiguous order."
        }
        $expectedCompensationOrder++
        Assert-AtlasJournalWholeNumber -Value $compensation.attempts `
            -Label "Install journal compensation '$($compensation.id)' attempts" -Minimum 0 -Maximum 100000
        if ($compensation.state -eq 'Ready' -and $null -eq $compensation.reconciliationEvidence) {
            throw "Ready compensation '$($compensation.id)' lacks reconciliation evidence."
        }
        if ($compensation.state -eq 'Failed' -and $null -eq $compensation.lastError) {
            throw "Failed compensation '$($compensation.id)' lacks failure evidence."
        }
        if ($compensation.state -in @('Compensated', 'Discharged') -and
            [string]::IsNullOrWhiteSpace([string]$compensation.completionEvidence)) {
            throw "Terminal compensation '$($compensation.id)' lacks completion evidence."
        }
    }
    if (@($compensations | Where-Object { $_.state -eq 'Running' }).Count -gt 1) {
        throw 'Install journal contains more than one Running compensation.'
    }

    $encounteredUnresolvedCompensation = $false
    foreach ($compensation in @($compensations | Sort-Object -Property order -Descending)) {
        $compensationIsTerminal = $compensation.state -in @('Compensated', 'Discharged')
        if ($compensationIsTerminal -and $encounteredUnresolvedCompensation) {
            throw "Compensation '$($compensation.id)' is terminal ahead of an unresolved LIFO predecessor."
        }
        if (-not $compensationIsTerminal) {
            $encounteredUnresolvedCompensation = $true
        }
    }

    Assert-AtlasJournalArray -Value $Journal.events -Label 'Install journal events'
    $events = @($Journal.events)
    if ($events.Count -gt $script:AtlasJournalMaximumEvents) {
        throw "Install journal events exceed the schema limit of $($script:AtlasJournalMaximumEvents)."
    }
    Assert-AtlasJournalWholeNumber -Value $Journal.eventSequence -Label 'Install journal eventSequence' `
        -Minimum 0 -Maximum $script:AtlasJournalMaximumEvents
    if ([long]$Journal.eventSequence -ne $events.Count) {
        throw 'Install journal eventSequence does not match the event list.'
    }
    for ($eventIndex = 0; $eventIndex -lt $events.Count; $eventIndex++) {
        Assert-AtlasJournalWholeNumber -Value $events[$eventIndex].sequence `
            -Label 'Install journal event sequence' -Minimum 1 -Maximum $script:AtlasJournalMaximumEvents
        if ([long]$events[$eventIndex].sequence -ne ($eventIndex + 1)) {
            throw 'Install journal event sequence is not contiguous.'
        }
        Assert-AtlasJournalString -Value $events[$eventIndex].kind -Label 'Install journal event kind'
        if ([string]::IsNullOrWhiteSpace([string]$events[$eventIndex].kind) -or
            ([string]$events[$eventIndex].kind).Length -gt 128) {
            throw 'Install journal event kind is invalid.'
        }
    }

    if ($Journal.state -eq 'Completed') {
        if (@($phases | Where-Object { $_.state -notin @('Succeeded', 'Skipped') }).Count -ne 0) {
            throw 'A completed install journal contains unresolved phases.'
        }
        if (@($compensations | Where-Object { $_.state -notin @('Compensated', 'Discharged') }).Count -ne 0) {
            throw 'A completed install journal contains unresolved compensations.'
        }
        if ([string]::IsNullOrWhiteSpace([string]$Journal.completedUtc)) {
            throw 'A completed install journal lacks a completion timestamp.'
        }
    }
    elseif ($Journal.state -eq 'InProgress' -and
        (@($phases | Where-Object { $_.state -eq 'Failed' }).Count -ne 0 -or
            @($compensations | Where-Object { $_.state -eq 'Failed' }).Count -ne 0)) {
        throw 'An InProgress install journal contains a failed phase or compensation.'
    }
    elseif ($Journal.state -eq 'Failed' -and $null -eq $Journal.failure) {
        throw 'A failed install journal lacks failure evidence.'
    }

    $expectedIdentityHash = Get-AtlasJournalIdentityHash -Journal $Journal
    Assert-AtlasJournalString -Value $Journal.identitySha256 -Label 'Install journal identitySha256'
    if ([string]$Journal.identitySha256 -cne $expectedIdentityHash) {
        throw 'Install journal immutable identity hash does not match its contents.'
    }
    if (-not $SkipDocumentChecksum) {
        Assert-AtlasJournalString -Value $Journal.documentSha256 -Label 'Install journal documentSha256'
        if ([string]$Journal.documentSha256 -notmatch '^[a-f0-9]{64}$') {
            throw 'Install journal document checksum is missing or invalid.'
        }
    }
    return $true
}

function Read-AtlasJournalFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = $null
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        if ($stream.Length -lt 1 -or $stream.Length -gt $script:AtlasJournalMaximumDocumentBytes) {
            throw "Install journal file length is outside the supported 1-$($script:AtlasJournalMaximumDocumentBytes) byte range: '$Path'."
        }
        $bytes = New-Object byte[] ([int]$stream.Length)
        $offset = 0
        while ($offset -lt $bytes.Length) {
            $read = $stream.Read($bytes, $offset, $bytes.Length - $offset)
            if ($read -le 0) {
                throw "Install journal file ended before its declared length: '$Path'."
            }
            $offset += $read
        }
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw "Install journal UTF-8 must not contain a byte-order mark: '$Path'."
        }
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }
    }

    try {
        $raw = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
    }
    catch [Text.DecoderFallbackException] {
        throw "Install journal file is not strict UTF-8: '$Path'."
    }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Install journal file is empty: '$Path'."
    }
    $journal = $raw | ConvertFrom-Json -ErrorAction Stop
    [void](Test-AtlasJournalDocument -Journal $journal)
    [void](Test-AtlasJournalRawDocumentChecksum -Raw $raw -Journal $journal)
    return $journal
}

function Read-AtlasJournalDocument {
    param([Parameter(Mandatory = $true)][string]$JournalPath)

    try {
        $journal = Read-AtlasJournalFile -Path $JournalPath
    }
    catch {
        $primaryMessage = $_.Exception.Message
        $backupPath = "$JournalPath.bak"
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            try {
                $null = Read-AtlasJournalFile -Path $backupPath
                throw "The primary Atlas install journal is invalid. Its backup is valid but may be stale and was not used; both files were preserved for explicit diagnosis. Primary: $primaryMessage"
            }
            catch {
                if ($_.Exception.Message -like 'The primary Atlas install journal is invalid.*') {
                    throw
                }
                throw "The primary Atlas install journal and its backup are invalid; both files were preserved for diagnosis. Primary: $primaryMessage Backup: $($_.Exception.Message)"
            }
        }
        throw "The primary Atlas install journal is invalid and has no backup; it was preserved for diagnosis. Primary: $primaryMessage"
    }

    $storePath = Split-Path -Parent ([IO.Path]::GetFullPath($JournalPath))
    $expectedTransactionRoot = Join-Path -Path $storePath -ChildPath ([string]$journal.transactionId)
    if (-not [string]::Equals(
            [IO.Path]::GetFullPath([string]$journal.transactionRoot),
            [IO.Path]::GetFullPath($expectedTransactionRoot),
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'Install journal transactionRoot does not match its transactionId.'
    }
    Assert-AtlasInstallJournalStore -JournalPath $JournalPath -TransactionRoot ([string]$journal.transactionRoot)
    return $journal
}

function Write-AtlasJournalDocument {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)]$Journal
    )

    [void](Test-AtlasJournalDocument -Journal $Journal -SkipDocumentChecksum)
    $Journal.documentSha256 = '0' * 64
    $placeholderJson = $Journal | ConvertTo-Json -Depth 24
    $placeholderMatch = Get-AtlasJournalRawDocumentChecksumMatch -Raw $placeholderJson
    if ($placeholderMatch.Groups[1].Value -cne ('0' * 64)) {
        throw 'Install journal serialization did not produce the checksum placeholder.'
    }
    $placeholderBytes = (New-Object Text.UTF8Encoding($false, $true)).GetBytes($placeholderJson)
    $Journal.documentSha256 = Get-AtlasJournalSha256 -Bytes $placeholderBytes
    $checksumGroup = $placeholderMatch.Groups[1]
    $json = $placeholderJson.Substring(0, $checksumGroup.Index) + $Journal.documentSha256 +
        $placeholderJson.Substring($checksumGroup.Index + $checksumGroup.Length)
    $bytes = (New-Object Text.UTF8Encoding($false, $true)).GetBytes($json)
    if ($bytes.Length -gt $script:AtlasJournalMaximumDocumentBytes) {
        throw "Install journal document exceeds the $($script:AtlasJournalMaximumDocumentBytes)-byte limit."
    }
    $storePath = Split-Path -Parent $JournalPath
    $temporaryPath = Join-Path -Path $storePath -ChildPath ('.active.{0}.tmp' -f [Guid]::NewGuid().ToString('N'))

    $stream = $null
    try {
        $stream = New-Object IO.FileStream(
            $temporaryPath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None,
            4096,
            [IO.FileOptions]::WriteThrough
        )
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null

        Set-AtlasJournalFileAcl -Path $temporaryPath
        if (Test-Path -LiteralPath $JournalPath -PathType Leaf) {
            [IO.File]::Replace($temporaryPath, $JournalPath, "$JournalPath.bak", $true)
            Set-AtlasJournalFileAcl -Path "$JournalPath.bak"
        }
        else {
            [IO.File]::Move($temporaryPath, $JournalPath)
        }
        Set-AtlasJournalFileAcl -Path $JournalPath
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-AtlasJournalPhase {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)][string]$PhaseKey
    )

    $phaseMatches = @($Journal.phases | Where-Object { $_.key -ceq $PhaseKey })
    if ($phaseMatches.Count -ne 1) {
        throw "Install journal phase '$PhaseKey' was not found."
    }
    return $phaseMatches[0]
}

function Get-AtlasJournalCompensation {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)][string]$Id
    )

    $compensationMatches = @($Journal.compensations | Where-Object { $_.id -ceq $Id })
    if ($compensationMatches.Count -ne 1) {
        throw "Install journal compensation '$Id' was not found."
    }
    return $compensationMatches[0]
}

function Update-AtlasJournalDocument {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)][scriptblock]$Mutation
    )

    return Invoke-WithAtlasJournalLock -JournalPath $JournalPath -ScriptBlock {
        Assert-AtlasInstallJournalStore -JournalPath $JournalPath
        $journal = Read-AtlasJournalDocument -JournalPath $JournalPath
        if ($journal.state -eq 'Completed') {
            throw 'The Atlas install journal is already completed and is immutable.'
        }

        & $Mutation $journal
        $journal.revision = [int]$journal.revision + 1
        $journal.updatedUtc = Get-AtlasJournalUtcTimestamp
        Write-AtlasJournalDocument -JournalPath $JournalPath -Journal $journal
        return $journal
    }
}

function Initialize-AtlasJournalProtectedDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            throw "Install journal managed path is not a directory: '$Path'."
        }
        Assert-AtlasJournalNotReparsePoint -Path $Path
    }
    else {
        New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
    }
    Set-Acl -LiteralPath $Path -AclObject (New-AtlasJournalDirectorySecurity) -ErrorAction Stop
    Assert-AtlasJournalProtectedDirectory -Path $Path
}

function Move-AtlasCompletedJournalToArchive {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)]$Journal
    )

    if ($Journal.state -ne 'Completed') {
        throw "Active Atlas install transaction '$($Journal.transactionId)' is '$($Journal.state)' and must not be retired."
    }

    $storePath = Split-Path -Parent ([IO.Path]::GetFullPath($JournalPath))
    $archiveRoot = Join-Path -Path $storePath -ChildPath 'archive'
    Initialize-AtlasJournalProtectedDirectory -Path $archiveRoot

    $archivePath = Join-Path -Path $archiveRoot -ChildPath ("$($Journal.transactionId).json")
    $archiveBackupPath = Join-Path -Path $archiveRoot -ChildPath ("$($Journal.transactionId).previous.json")
    if (Test-Path -LiteralPath $archivePath) {
        throw "Completed transaction archive already exists: '$archivePath'."
    }

    $backupPath = "$JournalPath.bak"
    if (Test-Path -LiteralPath $backupPath) {
        if (Test-Path -LiteralPath $archiveBackupPath) {
            throw "Completed transaction backup archive already exists: '$archiveBackupPath'."
        }
        [IO.File]::Move($backupPath, $archiveBackupPath)
        Set-AtlasJournalFileAcl -Path $archiveBackupPath
        Assert-AtlasJournalProtectedFile -Path $archiveBackupPath
    }
    elseif (Test-Path -LiteralPath $archiveBackupPath) {
        # A prior archive attempt may have moved the backup before interruption.
        Assert-AtlasJournalProtectedFile -Path $archiveBackupPath
    }

    [IO.File]::Move($JournalPath, $archivePath)
    Set-AtlasJournalFileAcl -Path $archivePath
    Assert-AtlasJournalProtectedFile -Path $archivePath
    return $archivePath
}

function New-AtlasInstallJournal {
    <#
    .SYNOPSIS
        Creates a new immutable Atlas install identity and ordered phase plan.
    .DESCRIPTION
        Source version, target version, original mode, selected options and the ordered
        phase/recovery plan are identity-hashed and cannot drift on a same-version retry.
        String phase-plan entries default to Manual recovery; callers must opt in to
        Idempotent or Reconcile semantics explicitly.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()][string]$SourceVersion,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TargetVersion,
        [Parameter(Mandatory = $true)][ValidateSet('Fresh', 'Upgrade', 'Oobe', 'Reapply')][string]$Mode,
        [AllowNull()][string]$InteractiveUserSid,
        [string[]]$Options = @(),
        [Parameter(Mandatory = $true)][object[]]$PhasePlan,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    Assert-AtlasJournalStorePathForCreate -JournalPath $JournalPath
    return Invoke-WithAtlasJournalLock -JournalPath $JournalPath -ScriptBlock {
        Assert-AtlasInstallJournalStore -JournalPath $JournalPath
        $completedJournal = $null
        if (Test-Path -LiteralPath $JournalPath) {
            $existingJournal = Read-AtlasJournalDocument -JournalPath $JournalPath
            if ($existingJournal.state -ne 'Completed') {
                throw "An active Atlas install journal already exists at '$JournalPath' with state '$($existingJournal.state)'."
            }
            $completedJournal = $existingJournal
        }
        elseif (Test-Path -LiteralPath "$JournalPath.bak") {
            throw "An orphaned Atlas install journal backup exists at '$JournalPath.bak'; it must be diagnosed explicitly before a new transaction is created."
        }

        # Validate the complete replacement identity before retiring a completed audit
        # record. Active/corrupt journal diagnostics remain authoritative and are checked
        # above, but invalid new input can never move the existing completed transaction.
        if ([string]::IsNullOrWhiteSpace($TargetVersion) -or $TargetVersion.Length -gt 128) {
            throw 'Install journal targetVersion must contain between 1 and 128 characters.'
        }
        if ($null -ne $SourceVersion -and $SourceVersion.Length -gt 128) {
            throw 'Install journal sourceVersion exceeds 128 characters.'
        }
        if (@($Options).Count -gt 128) {
            throw 'Install journal options exceed the schema limit of 128.'
        }
        $normalizedOptions = @($Options | ForEach-Object {
                Assert-AtlasJournalName -Value $_ -Label 'option' -Pattern '^[a-z0-9]+(?:-[a-z0-9]+)*$'
                $_
            } | Sort-Object -Unique)
        if (-not [string]::IsNullOrWhiteSpace($InteractiveUserSid)) {
            try {
                $InteractiveUserSid = (New-Object Security.Principal.SecurityIdentifier($InteractiveUserSid)).Value
            }
            catch {
                throw "Interactive user SID '$InteractiveUserSid' is invalid."
            }
        }
        $normalizedPhasePlan = @(ConvertTo-AtlasPhasePlan -PhasePlan $PhasePlan)

        if ($null -ne $completedJournal) {
            $null = Move-AtlasCompletedJournalToArchive -JournalPath $JournalPath -Journal $completedJournal
        }
        $transactionId = [Guid]::NewGuid().ToString('D')
        $storePath = Split-Path -Parent ([IO.Path]::GetFullPath($JournalPath))
        $transactionRoot = Join-Path -Path $storePath -ChildPath $transactionId
        if (Test-Path -LiteralPath $transactionRoot) {
            throw "Atlas transaction root already exists: '$transactionRoot'."
        }
        Initialize-AtlasJournalProtectedDirectory -Path $transactionRoot

        $timestamp = Get-AtlasJournalUtcTimestamp
        $journal = [pscustomobject][ordered]@{
            documentSha256  = $null
            schemaVersion   = $script:AtlasJournalSchemaVersion
            transactionId   = $transactionId
            revision        = 0
            state           = 'InProgress'
            sourceVersion   = if ([string]::IsNullOrWhiteSpace($SourceVersion)) { $null } else { $SourceVersion }
            targetVersion   = $TargetVersion
            mode            = $Mode
            interactiveUserSid = if ([string]::IsNullOrWhiteSpace($InteractiveUserSid)) { $null } else { $InteractiveUserSid }
            initiatingPrincipalSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            options         = $normalizedOptions
            identitySha256  = $null
            createdUtc      = $timestamp
            updatedUtc      = $timestamp
            completedUtc    = $null
            resumeCount     = 0
            transactionRoot = $transactionRoot
            phases          = $normalizedPhasePlan
            compensations   = @()
            payload         = [ordered]@{
                schemaVersion      = 1
                required           = $false
                generationState    = 'NotManaged'
                targetGeneration   = $null
                previousGeneration = $null
                roots              = @()
                lastVerifiedUtc    = $null
                failure            = $null
            }
            failure         = $null
            eventSequence   = 0
            events          = @()
        }
        $journal.identitySha256 = Get-AtlasJournalIdentityHash -Journal $journal
        Add-AtlasJournalEvent -Journal $journal -Kind 'TransactionCreated' -Subject $null -Detail $null
        Write-AtlasJournalDocument -JournalPath $JournalPath -Journal $journal
        Assert-AtlasInstallJournalStore -JournalPath $JournalPath -TransactionRoot $transactionRoot
        return $journal
    }
}

function Assert-AtlasJournalStorePathForCreate {
    param([Parameter(Mandatory = $true)][string]$JournalPath)

    if (-not [IO.Path]::IsPathRooted($JournalPath)) {
        throw "Install journal path must be rooted: '$JournalPath'."
    }
}

function Get-AtlasInstallJournal {
    [CmdletBinding()]
    param([string]$JournalPath = (Get-AtlasInstallJournalPath))

    return Invoke-WithAtlasJournalLock -JournalPath $JournalPath -ScriptBlock {
        Assert-AtlasInstallJournalStore -JournalPath $JournalPath
        return Read-AtlasJournalDocument -JournalPath $JournalPath
    }
}

function Resume-AtlasInstallJournal {
    <#
    .SYNOPSIS
        Reopens an incomplete transaction without changing its original mode, options or plan.
    .DESCRIPTION
        AME can classify a fatal retry as a same-version application. The caller supplies only
        the target version it is attempting; the Atlas journal remains authoritative for the
        original source version, mode, option set and ordered phase plan.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TargetVersion,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        if ([string]$journal.targetVersion -cne $TargetVersion) {
            throw "Active Atlas transaction targets '$($journal.targetVersion)', not '$TargetVersion'."
        }
        $journal.resumeCount = [int]$journal.resumeCount + 1
        Add-AtlasJournalEvent -Journal $journal -Kind 'TransactionResumed' -Subject $null `
            -Detail ([ordered]@{ observedTargetVersion = $TargetVersion })
    }
}

function Test-AtlasJournalPhaseTerminal {
    param([Parameter(Mandatory = $true)]$Phase)

    return [string]$Phase.state -in @('Succeeded', 'Skipped')
}

function Get-AtlasJournalEarliestUnresolvedPhase {
    param([Parameter(Mandatory = $true)]$Journal)

    $nextPhase = $Journal.phases | Where-Object { -not (Test-AtlasJournalPhaseTerminal -Phase $_) } |
        Select-Object -First 1
    return $nextPhase
}

function Assert-AtlasJournalPhaseIsNext {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)]$Phase
    )

    $nextPhase = Get-AtlasJournalEarliestUnresolvedPhase -Journal $Journal
    if ($null -eq $nextPhase -or $nextPhase.key -cne $Phase.key) {
        $nextKey = if ($null -eq $nextPhase) { '<none>' } else { [string]$nextPhase.key }
        throw "Phase '$($Phase.key)' is not the earliest unresolved phase (next: '$nextKey')."
    }
}

function Update-AtlasJournalAggregateState {
    param([Parameter(Mandatory = $true)]$Journal)

    $failedPhase = $Journal.phases | Where-Object { $_.state -eq 'Failed' } | Select-Object -First 1
    $failedCompensation = $Journal.compensations | Where-Object { $_.state -eq 'Failed' } |
        Sort-Object -Property order -Descending | Select-Object -First 1
    if ($null -ne $failedPhase) {
        $Journal.state = 'Failed'
        $Journal.failure = [ordered]@{
            phase    = $failedPhase.key
            utc      = $failedPhase.lastError.utc
            message  = $failedPhase.lastError.message
            exitCode = $failedPhase.lastError.exitCode
        }
    }
    elseif ($null -ne $failedCompensation) {
        $Journal.state = 'Failed'
        $Journal.failure = [ordered]@{
            compensation = $failedCompensation.id
            utc          = $failedCompensation.lastError.utc
            message      = $failedCompensation.lastError.message
        }
    }
    else {
        $Journal.state = 'InProgress'
        $Journal.failure = $null
    }
}

function Start-AtlasInstallJournalPhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PhaseKey,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $phase = Get-AtlasJournalPhase -Journal $journal -PhaseKey $PhaseKey
        Assert-AtlasJournalPhaseIsNext -Journal $journal -Phase $phase
        if ($phase.state -eq 'Running') {
            throw "Phase '$PhaseKey' was interrupted and must be reconciled before it can run again."
        }
        if ($phase.state -eq 'Succeeded' -or $phase.state -eq 'Skipped') {
            throw "Phase '$PhaseKey' is already terminal with state '$($phase.state)'."
        }
        if ($phase.state -eq 'Failed' -and $phase.recoveryPolicy -ne 'Idempotent') {
            throw "Phase '$PhaseKey' requires reconciliation before retry."
        }
        if ($phase.state -notin @('Pending', 'Ready', 'Failed')) {
            throw "Phase '$PhaseKey' cannot start from '$($phase.state)'."
        }

        $phase.state = 'Running'
        $phase.attempts = [int]$phase.attempts + 1
        $phase.startedUtc = Get-AtlasJournalUtcTimestamp
        $phase.completedUtc = $null
        $phase.postconditionEvidence = $null
        $phase.reconciliationEvidence = $null
        $journal.state = 'InProgress'
        $journal.failure = $null
        Add-AtlasJournalEvent -Journal $journal -Kind 'PhaseStarted' -Subject $PhaseKey -Detail $null
    }
}

function Skip-AtlasInstallJournalPhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PhaseKey,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Reason,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($Reason.Length -gt 2048) {
        throw 'Phase skip evidence exceeds 2048 characters.'
    }
    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $phase = Get-AtlasJournalPhase -Journal $journal -PhaseKey $PhaseKey
        Assert-AtlasJournalPhaseIsNext -Journal $journal -Phase $phase
        if ([bool]$phase.required) {
            throw "Required phase '$PhaseKey' cannot be skipped."
        }
        if ($phase.state -notin @('Pending', 'Ready')) {
            throw "Optional phase '$PhaseKey' cannot be skipped from '$($phase.state)'."
        }

        $phase.state = 'Skipped'
        $phase.completedUtc = Get-AtlasJournalUtcTimestamp
        $phase.postconditionEvidence = $Reason
        $phase.lastError = $null
        Add-AtlasJournalEvent -Journal $journal -Kind 'PhaseSkipped' -Subject $PhaseKey -Detail $Reason
    }
}

function Complete-AtlasInstallJournalPhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PhaseKey,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PostconditionEvidence,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($PostconditionEvidence.Length -gt 2048) {
        throw 'Phase postcondition evidence exceeds 2048 characters.'
    }

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $phase = Get-AtlasJournalPhase -Journal $journal -PhaseKey $PhaseKey
        if ($phase.state -ne 'Running') {
            throw "Phase '$PhaseKey' can only complete from Running, not '$($phase.state)'."
        }
        $phase.state = 'Succeeded'
        $phase.completedUtc = Get-AtlasJournalUtcTimestamp
        $phase.postconditionEvidence = $PostconditionEvidence
        $phase.lastError = $null
        $phase.reconciliationEvidence = $null
        Add-AtlasJournalEvent -Journal $journal -Kind 'PhaseSucceeded' -Subject $PhaseKey -Detail $null
    }
}

function Set-AtlasInstallJournalPhaseFailed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PhaseKey,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Message,
        [Nullable[int]]$ExitCode,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($Message.Length -gt 4096) {
        $Message = $Message.Substring(0, 4096)
    }
    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $phase = Get-AtlasJournalPhase -Journal $journal -PhaseKey $PhaseKey
        if ($phase.state -ne 'Running') {
            throw "Phase '$PhaseKey' can only fail from Running, not '$($phase.state)'."
        }
        $errorDetail = [ordered]@{
            utc      = Get-AtlasJournalUtcTimestamp
            message  = $Message
            exitCode = if ($null -eq $ExitCode) { $null } else { [int]$ExitCode }
        }
        $phase.state = 'Failed'
        $phase.completedUtc = $errorDetail.utc
        $phase.lastError = $errorDetail
        $journal.state = 'Failed'
        $journal.failure = [ordered]@{
            phase    = $PhaseKey
            utc      = $errorDetail.utc
            message  = $errorDetail.message
            exitCode = $errorDetail.exitCode
        }
        Add-AtlasJournalEvent -Journal $journal -Kind 'PhaseFailed' -Subject $PhaseKey -Detail $errorDetail
    }
}

function Resolve-AtlasInterruptedJournalPhase {
    <#
    .SYNOPSIS
        Records the explicit result of reconciling a phase left in Running state.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PhaseKey,
        [Parameter(Mandatory = $true)][ValidateSet('VerifiedSucceeded', 'ReadyToRetry', 'Failed')][string]$Resolution,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Reason,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($Reason.Length -gt 2048) {
        throw 'Phase reconciliation evidence exceeds 2048 characters.'
    }
    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $phase = Get-AtlasJournalPhase -Journal $journal -PhaseKey $PhaseKey
        Assert-AtlasJournalPhaseIsNext -Journal $journal -Phase $phase
        if ($phase.state -notin @('Running', 'Failed')) {
            throw "Phase '$PhaseKey' cannot be reconciled from '$($phase.state)'."
        }

        $evidenceUtc = Get-AtlasJournalUtcTimestamp
        $phase.reconciliationEvidence = [ordered]@{
            utc        = $evidenceUtc
            resolution = $Resolution
            reason     = $Reason
        }

        switch ($Resolution) {
            'VerifiedSucceeded' {
                $phase.state = 'Succeeded'
                $phase.completedUtc = $evidenceUtc
                $phase.postconditionEvidence = $Reason
                $phase.lastError = $null
            }
            'ReadyToRetry' {
                $phase.state = 'Ready'
                $phase.startedUtc = $null
                $phase.completedUtc = $null
                $phase.postconditionEvidence = $null
            }
            'Failed' {
                $phase.state = 'Failed'
                $phase.completedUtc = $evidenceUtc
                $phase.lastError = [ordered]@{ utc = $phase.completedUtc; message = $Reason; exitCode = $null }
            }
        }
        Update-AtlasJournalAggregateState -Journal $journal
        Add-AtlasJournalEvent -Journal $journal -Kind "PhaseResolved$Resolution" -Subject $PhaseKey -Detail $Reason
    }
}

function Get-AtlasInstallResumePlan {
    [CmdletBinding()]
    param([string]$JournalPath = (Get-AtlasInstallJournalPath))

    $journal = Get-AtlasInstallJournal -JournalPath $JournalPath
    $nextPhase = Get-AtlasJournalEarliestUnresolvedPhase -Journal $journal
    $plan = foreach ($phase in @($journal.phases)) {
        if (Test-AtlasJournalPhaseTerminal -Phase $phase) {
            $action = 'Completed'
        }
        elseif ($null -eq $nextPhase -or $phase.key -cne $nextPhase.key) {
            $action = 'Blocked'
        }
        else {
            $action = switch ([string]$phase.state) {
                'Pending' { if ([bool]$phase.required) { 'Run' } else { 'RunOrSkip' } }
                'Ready' { if ([bool]$phase.required) { 'Run' } else { 'RunOrSkip' } }
                'Running' { 'Reconcile' }
                'Failed' {
                    if ($phase.recoveryPolicy -eq 'Idempotent') { 'Retry' }
                    else { 'Reconcile' }
                }
            }
        }
        [pscustomobject][ordered]@{
            PhaseKey      = $phase.key
            State         = $phase.state
            RecoveryPolicy = $phase.recoveryPolicy
            Action        = $action
        }
    }
    return @($plan)
}

function Register-AtlasInstallCompensation {
    <#
    .SYNOPSIS
        Persists a LIFO compensation before its owner phase changes temporary system state.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$OwnerPhase,
        [Parameter(Mandatory = $true)][ValidateSet('Idempotent', 'Reconcile', 'Manual')][string]$RecoveryPolicy,
        [AllowNull()][object]$Data,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    Assert-AtlasJournalName -Value $Id -Label 'compensation id'
    Assert-AtlasJournalName -Value $Kind -Label 'compensation kind'
    $normalizedData = $null
    if ($null -ne $Data) {
        $dataJson = $Data | ConvertTo-Json -Depth 12 -Compress
        if ([Text.Encoding]::UTF8.GetByteCount($dataJson) -gt 65536) {
            throw "Compensation '$Id' data exceeds 64 KiB."
        }
        $normalizedData = $dataJson | ConvertFrom-Json
    }

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $phase = Get-AtlasJournalPhase -Journal $journal -PhaseKey $OwnerPhase
        if ($phase.state -ne 'Running') {
            throw "Compensation '$Id' must be registered while owner phase '$OwnerPhase' is Running."
        }
        if (@($journal.compensations | Where-Object { $_.id -ceq $Id }).Count -ne 0) {
            throw "Install journal compensation '$Id' is already registered."
        }

        $nextOrder = @($journal.compensations).Count + 1
        $compensation = [ordered]@{
            id             = $Id
            kind           = $Kind
            ownerPhase     = $OwnerPhase
            recoveryPolicy = $RecoveryPolicy
            order          = $nextOrder
            state          = 'Pending'
            attempts       = 0
            registeredUtc  = Get-AtlasJournalUtcTimestamp
            startedUtc     = $null
            completedUtc   = $null
            lastError      = $null
            completionEvidence = $null
            reconciliationEvidence = $null
            data           = $normalizedData
        }
        $journal.compensations = @($journal.compensations) + @($compensation)
        Add-AtlasJournalEvent -Journal $journal -Kind 'CompensationRegistered' -Subject $Id -Detail $Kind
    }
}

function Test-AtlasJournalCompensationTerminal {
    param([Parameter(Mandatory = $true)]$Compensation)

    return [string]$Compensation.state -in @('Compensated', 'Discharged')
}

function Get-AtlasJournalEarliestUnresolvedCompensation {
    param([Parameter(Mandatory = $true)]$Journal)

    $nextCompensation = $Journal.compensations | Sort-Object -Property order -Descending |
        Where-Object { -not (Test-AtlasJournalCompensationTerminal -Compensation $_) } |
        Select-Object -First 1
    return $nextCompensation
}

function Assert-AtlasJournalCompensationIsNext {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)]$Compensation
    )

    $nextCompensation = Get-AtlasJournalEarliestUnresolvedCompensation -Journal $Journal
    if ($null -eq $nextCompensation -or $nextCompensation.id -cne $Compensation.id) {
        $nextId = if ($null -eq $nextCompensation) { '<none>' } else { [string]$nextCompensation.id }
        throw "Compensation '$($Compensation.id)' is not the earliest unresolved LIFO compensation (next: '$nextId')."
    }
}

function Get-AtlasInstallCompensationPlan {
    [CmdletBinding()]
    param([string]$JournalPath = (Get-AtlasInstallJournalPath))

    $journal = Get-AtlasInstallJournal -JournalPath $JournalPath
    $nextCompensation = Get-AtlasJournalEarliestUnresolvedCompensation -Journal $journal
    $plan = foreach ($compensation in @($journal.compensations | Sort-Object -Property order -Descending)) {
        if (Test-AtlasJournalCompensationTerminal -Compensation $compensation) {
            $action = 'Completed'
        }
        elseif ($null -eq $nextCompensation -or $compensation.id -cne $nextCompensation.id) {
            $action = 'Blocked'
        }
        else {
            $action = switch ([string]$compensation.state) {
                'Pending' {
                    if ($compensation.recoveryPolicy -eq 'Idempotent') { 'Run' }
                    else { 'Reconcile' }
                }
                'Ready' { 'Run' }
                'Running' { 'Reconcile' }
                'Failed' {
                    if ($compensation.recoveryPolicy -eq 'Idempotent') { 'Retry' }
                    else { 'Reconcile' }
                }
            }
        }
        [pscustomobject][ordered]@{
            Id             = $compensation.id
            Kind           = $compensation.kind
            State          = $compensation.state
            RecoveryPolicy = $compensation.recoveryPolicy
            Action         = $action
            Data           = $compensation.data
        }
    }
    return @($plan)
}

function Start-AtlasInstallCompensation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $compensation = Get-AtlasJournalCompensation -Journal $journal -Id $Id
        Assert-AtlasJournalCompensationIsNext -Journal $journal -Compensation $compensation
        if ($compensation.state -eq 'Running') {
            throw "Compensation '$Id' was interrupted and must be reconciled."
        }
        if ($compensation.state -eq 'Compensated' -or $compensation.state -eq 'Discharged') {
            throw "Compensation '$Id' is already terminal."
        }
        if ($compensation.state -eq 'Failed' -and $compensation.recoveryPolicy -ne 'Idempotent') {
            throw "Compensation '$Id' requires reconciliation before retry."
        }
        if ($compensation.state -eq 'Pending' -and $compensation.recoveryPolicy -ne 'Idempotent') {
            throw "Compensation '$Id' requires explicit reconciliation before its first run."
        }
        if ($compensation.state -notin @('Pending', 'Ready', 'Failed')) {
            throw "Compensation '$Id' cannot start from '$($compensation.state)'."
        }
        $compensation.state = 'Running'
        $compensation.attempts = [int]$compensation.attempts + 1
        $compensation.startedUtc = Get-AtlasJournalUtcTimestamp
        $compensation.completedUtc = $null
        $compensation.reconciliationEvidence = $null
        Update-AtlasJournalAggregateState -Journal $journal
        Add-AtlasJournalEvent -Journal $journal -Kind 'CompensationStarted' -Subject $Id -Detail $null
    }
}

function Resolve-AtlasInstallCompensation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)]
        [ValidateSet('VerifiedCompensated', 'VerifiedDischarged', 'ReadyToRetry', 'Failed')]
        [string]$Resolution,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Evidence,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($Evidence.Length -gt 2048) {
        throw 'Compensation reconciliation evidence exceeds 2048 characters.'
    }
    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $compensation = Get-AtlasJournalCompensation -Journal $journal -Id $Id
        Assert-AtlasJournalCompensationIsNext -Journal $journal -Compensation $compensation
        if ($compensation.state -notin @('Pending', 'Running', 'Failed')) {
            throw "Compensation '$Id' cannot be reconciled from '$($compensation.state)'."
        }

        $evidenceUtc = Get-AtlasJournalUtcTimestamp
        $compensation.reconciliationEvidence = [ordered]@{
            utc        = $evidenceUtc
            resolution = $Resolution
            evidence   = $Evidence
        }
        switch ($Resolution) {
            'VerifiedCompensated' {
                $compensation.state = 'Compensated'
                $compensation.completedUtc = $evidenceUtc
                $compensation.completionEvidence = $Evidence
                $compensation.lastError = $null
            }
            'VerifiedDischarged' {
                $compensation.state = 'Discharged'
                $compensation.completedUtc = $evidenceUtc
                $compensation.completionEvidence = $Evidence
                $compensation.lastError = $null
            }
            'ReadyToRetry' {
                $compensation.state = 'Ready'
                $compensation.startedUtc = $null
                $compensation.completedUtc = $null
                $compensation.completionEvidence = $null
            }
            'Failed' {
                $compensation.state = 'Failed'
                $compensation.completedUtc = $evidenceUtc
                $compensation.lastError = [ordered]@{ utc = $evidenceUtc; message = $Evidence }
            }
        }
        Update-AtlasJournalAggregateState -Journal $journal
        Add-AtlasJournalEvent -Journal $journal -Kind "CompensationResolved$Resolution" -Subject $Id -Detail $Evidence
    }
}

function Complete-AtlasInstallCompensation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][ValidateSet('Compensated', 'Discharged')][string]$Outcome,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Evidence,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($Evidence.Length -gt 2048) {
        throw 'Compensation evidence exceeds 2048 characters.'
    }

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $compensation = Get-AtlasJournalCompensation -Journal $journal -Id $Id
        Assert-AtlasJournalCompensationIsNext -Journal $journal -Compensation $compensation
        if ($Outcome -eq 'Compensated' -and $compensation.state -ne 'Running') {
            throw "Compensation '$Id' can only be compensated from Running."
        }
        if ($Outcome -eq 'Discharged' -and $compensation.state -notin @('Pending', 'Ready', 'Running')) {
            throw "Compensation '$Id' cannot be discharged from '$($compensation.state)'."
        }
        $compensation.state = $Outcome
        $compensation.completedUtc = Get-AtlasJournalUtcTimestamp
        $compensation.completionEvidence = $Evidence
        $compensation.lastError = $null
        $compensation.reconciliationEvidence = $null
        Update-AtlasJournalAggregateState -Journal $journal
        Add-AtlasJournalEvent -Journal $journal -Kind "Compensation$Outcome" -Subject $Id -Detail $null
    }
}

function Set-AtlasInstallCompensationFailed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Message,
        [string]$JournalPath = (Get-AtlasInstallJournalPath)
    )

    if ($Message.Length -gt 4096) {
        throw 'Compensation failure evidence exceeds 4096 characters.'
    }
    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $compensation = Get-AtlasJournalCompensation -Journal $journal -Id $Id
        Assert-AtlasJournalCompensationIsNext -Journal $journal -Compensation $compensation
        if ($compensation.state -ne 'Running') {
            throw "Compensation '$Id' can only fail from Running."
        }
        $compensation.state = 'Failed'
        $compensation.completedUtc = Get-AtlasJournalUtcTimestamp
        $compensation.lastError = [ordered]@{ utc = $compensation.completedUtc; message = $Message }
        Update-AtlasJournalAggregateState -Journal $journal
        Add-AtlasJournalEvent -Journal $journal -Kind 'CompensationFailed' -Subject $Id -Detail $Message
    }
}

function Complete-AtlasInstallJournal {
    [CmdletBinding()]
    param([string]$JournalPath = (Get-AtlasInstallJournalPath))

    return Update-AtlasJournalDocument -JournalPath $JournalPath -Mutation {
        param($journal)
        $incompletePhases = @($journal.phases | Where-Object {
                $_.state -notin @('Succeeded', 'Skipped')
            })
        if ($incompletePhases.Count -ne 0) {
            throw "Install phases remain unresolved: $($incompletePhases.key -join ', ')."
        }
        $invalidRequiredPhases = @($journal.phases | Where-Object { [bool]$_.required -and $_.state -ne 'Succeeded' })
        if ($invalidRequiredPhases.Count -ne 0) {
            throw "Required install phases did not succeed: $($invalidRequiredPhases.key -join ', ')."
        }
        $pendingCompensations = @($journal.compensations | Where-Object {
                $_.state -notin @('Compensated', 'Discharged')
            })
        if ($pendingCompensations.Count -ne 0) {
            throw "Install compensations remain pending: $($pendingCompensations.id -join ', ')."
        }
        if ([bool]$journal.payload.required -and $journal.payload.generationState -notin @('Active', 'Committed')) {
            throw "Payload generation is not active or committed (state '$($journal.payload.generationState)')."
        }

        $journal.state = 'Completed'
        $journal.completedUtc = Get-AtlasJournalUtcTimestamp
        $journal.failure = $null
        Add-AtlasJournalEvent -Journal $journal -Kind 'TransactionCompleted' -Subject $null -Detail $null
    }
}

Export-ModuleMember -Function @(
    'Get-AtlasInstallJournalPath',
    'Initialize-AtlasInstallJournalStore',
    'New-AtlasInstallJournal',
    'Get-AtlasInstallJournal',
    'Resume-AtlasInstallJournal',
    'Get-AtlasInstallResumePlan',
    'Start-AtlasInstallJournalPhase',
    'Skip-AtlasInstallJournalPhase',
    'Complete-AtlasInstallJournalPhase',
    'Set-AtlasInstallJournalPhaseFailed',
    'Resolve-AtlasInterruptedJournalPhase',
    'Register-AtlasInstallCompensation',
    'Get-AtlasInstallCompensationPlan',
    'Start-AtlasInstallCompensation',
    'Resolve-AtlasInstallCompensation',
    'Complete-AtlasInstallCompensation',
    'Set-AtlasInstallCompensationFailed',
    'Complete-AtlasInstallJournal'
)
