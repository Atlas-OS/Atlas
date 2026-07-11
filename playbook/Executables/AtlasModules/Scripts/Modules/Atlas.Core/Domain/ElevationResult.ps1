# Atlas.Core domain: canonical, structured TrustedInstaller broker result protocol.

$script:AtlasElevationMaximumResultBytes = 64KB
$script:AtlasElevationResultStatuses = @(
    'Completed',
    'ConsentDenied',
    'NotStarted',
    'CompletionUnknown'
)
$script:AtlasTrustedInstallerServiceSid = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'

function ConvertTo-AtlasCanonicalTokenEvidence {
    param(
        $Evidence,
        [switch]$AllowNull
    )

    if ($null -eq $Evidence) {
        if ($AllowNull) {
            return $null
        }
        throw 'TrustedInstaller token evidence is required.'
    }

    $names = @('userSid', 'trustedInstallerSid', 'enabledTrustedInstallerSid', 'integrityRid', 'sessionId', 'authenticationId')
    Assert-AtlasElevationExactProperties -InputObject $Evidence -Names $names -Label 'Token evidence'
    foreach ($property in @('userSid', 'trustedInstallerSid')) {
        Assert-AtlasElevationString -Value $Evidence.$property -Label "Token evidence $property" -MaximumLength 184
        try {
            $sid = New-Object Security.Principal.SecurityIdentifier($Evidence.$property)
        }
        catch {
            throw "Token evidence $property is not a canonical SID."
        }
        if (-not [string]::Equals($sid.Value, $Evidence.$property, [StringComparison]::Ordinal)) {
            throw "Token evidence $property is not a canonical SID."
        }
    }
    Assert-AtlasElevationBoolean -Value $Evidence.enabledTrustedInstallerSid -Label 'Token evidence enabledTrustedInstallerSid'
    $integrityRid = Assert-AtlasElevationInteger -Value $Evidence.integrityRid -Label 'Token evidence integrityRid' -Minimum 0 -Maximum ([int]::MaxValue)
    $sessionId = Assert-AtlasElevationInteger -Value $Evidence.sessionId -Label 'Token evidence sessionId' -Minimum 0 -Maximum ([int]::MaxValue)
    Assert-AtlasElevationString -Value $Evidence.authenticationId -Label 'Token evidence authenticationId' -MaximumLength 17
    if ($Evidence.authenticationId -cnotmatch '^[0-9A-F]{8}:[0-9A-F]{8}$') {
        throw 'Token evidence authenticationId must be a canonical LUID.'
    }

    return [pscustomobject][ordered]@{
        userSid                      = [string]$Evidence.userSid
        trustedInstallerSid          = [string]$Evidence.trustedInstallerSid
        enabledTrustedInstallerSid   = [bool]$Evidence.enabledTrustedInstallerSid
        integrityRid                 = [int]$integrityRid
        sessionId                    = [int]$sessionId
        authenticationId             = [string]$Evidence.authenticationId
    }
}

function ConvertTo-AtlasCanonicalUtcTimestamp {
    param(
        [Parameter(Mandatory = $true)]
        $Value,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $format = "yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'"
    if ($Value -is [datetime]) {
        return $Value.ToUniversalTime().ToString($format, [Globalization.CultureInfo]::InvariantCulture)
    }
    Assert-AtlasElevationString -Value $Value -Label $Label -MaximumLength 28
    try {
        $timestamp = [datetime]::ParseExact(
            $Value,
            $format,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal
        )
    }
    catch {
        throw "$Label must use the canonical seven-digit UTC format."
    }
    $canonical = $timestamp.ToUniversalTime().ToString($format, [Globalization.CultureInfo]::InvariantCulture)
    if (-not [string]::Equals($canonical, $Value, [StringComparison]::Ordinal)) {
        throw "$Label must use the canonical seven-digit UTC format."
    }
    return $canonical
}

function ConvertTo-AtlasCanonicalElevationResult {
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    $names = @(
        'protocolVersion', 'requestId', 'requestSha256',
        'requesterSid', 'requesterProcessId', 'requesterCreationFileTime', 'requesterSessionId',
        'bootstrapProcessId', 'bootstrapCreationFileTime',
        'brokerProcessId', 'brokerCreationFileTime', 'rootProcessId', 'sourceProcessId',
        'sourceToken', 'childToken', 'startedUtc', 'endedUtc',
        'status', 'completionState', 'exitCodeUInt32', 'rootExited', 'jobDrained', 'error'
    )
    Assert-AtlasElevationExactProperties -InputObject $Result -Names $names -Label 'Elevation result'

    $protocolVersion = Assert-AtlasElevationInteger -Value $Result.protocolVersion `
        -Label 'Result protocolVersion' -Minimum 2 -Maximum 2
    Assert-AtlasElevationString -Value $Result.requestId -Label 'Result requestId' -MaximumLength 32
    if ($Result.requestId -cnotmatch '^[0-9a-f]{32}$' -or
        [string]::Equals($Result.requestId, ('0' * 32), [StringComparison]::Ordinal)) {
        throw 'Result requestId must be a nonzero lowercase 32-hex identifier.'
    }
    Assert-AtlasElevationString -Value $Result.requestSha256 -Label 'Result requestSha256' -MaximumLength 64
    if ($Result.requestSha256 -cnotmatch '^[0-9A-F]{64}$') {
        throw 'Result requestSha256 must be canonical uppercase SHA-256.'
    }

    Assert-AtlasElevationString -Value $Result.requesterSid -Label 'Result requesterSid' -MaximumLength 184
    try {
        $requesterSid = New-Object Security.Principal.SecurityIdentifier($Result.requesterSid)
    }
    catch {
        throw 'Result requesterSid is invalid.'
    }
    if (-not [string]::Equals($requesterSid.Value, $Result.requesterSid, [StringComparison]::Ordinal)) {
        throw 'Result requesterSid is not canonical.'
    }
    $requesterProcessId = Assert-AtlasElevationInteger -Value $Result.requesterProcessId `
        -Label 'Result requesterProcessId' -Minimum 1 -Maximum ([int]::MaxValue)
    $requesterCreationFileTime = Assert-AtlasElevationFileTimeHex `
        -Value $Result.requesterCreationFileTime -Label 'Result requesterCreationFileTime'
    $requesterSessionId = Assert-AtlasElevationInteger -Value $Result.requesterSessionId `
        -Label 'Result requesterSessionId' -Minimum 0 -Maximum ([int]::MaxValue)

    $bootstrapProcessId = $null
    $bootstrapCreationFileTime = $null
    $hasBootstrapProcessId = $null -ne $Result.bootstrapProcessId
    $hasBootstrapCreation = $null -ne $Result.bootstrapCreationFileTime
    if ($hasBootstrapProcessId -ne $hasBootstrapCreation) {
        throw 'Result bootstrap PID and creation FILETIME must be both present or both null.'
    }
    if ($hasBootstrapProcessId) {
        $bootstrapProcessId = [int](Assert-AtlasElevationInteger `
            -Value $Result.bootstrapProcessId `
            -Label 'Result bootstrapProcessId' `
            -Minimum 1 `
            -Maximum ([int]::MaxValue))
        $bootstrapCreationFileTime = Assert-AtlasElevationFileTimeHex `
            -Value $Result.bootstrapCreationFileTime `
            -Label 'Result bootstrapCreationFileTime'
    }

    $brokerProcessId = $null
    $brokerCreationFileTime = $null
    $hasBrokerProcessId = $null -ne $Result.brokerProcessId
    $hasBrokerCreation = $null -ne $Result.brokerCreationFileTime
    if ($hasBrokerProcessId -ne $hasBrokerCreation) {
        throw 'Result broker PID and creation FILETIME must be both present or both null.'
    }
    if ($hasBrokerProcessId) {
        if (-not $hasBootstrapProcessId) {
            throw 'Result broker generation requires a bootstrap generation.'
        }
        $brokerProcessId = [int](Assert-AtlasElevationInteger `
            -Value $Result.brokerProcessId `
            -Label 'Result brokerProcessId' `
            -Minimum 1 `
            -Maximum ([int]::MaxValue))
        $brokerCreationFileTime = Assert-AtlasElevationFileTimeHex `
            -Value $Result.brokerCreationFileTime `
            -Label 'Result brokerCreationFileTime'
    }

    Assert-AtlasElevationString -Value $Result.status -Label 'Result status' -MaximumLength 32
    if ($script:AtlasElevationResultStatuses -cnotcontains [string]$Result.status) {
        throw "Result status '$($Result.status)' is unsupported."
    }
    Assert-AtlasElevationString -Value $Result.completionState -Label 'Result completionState' -MaximumLength 17
    if (@('NotStarted', 'Completed', 'CompletionUnknown') `
            -cnotcontains [string]$Result.completionState) {
        throw "Result completionState '$($Result.completionState)' is unsupported."
    }
    $validPair = switch ([string]$Result.status) {
        'Completed' { [string]$Result.completionState -ceq 'Completed' }
        'ConsentDenied' { [string]$Result.completionState -ceq 'NotStarted' }
        'NotStarted' { [string]$Result.completionState -ceq 'NotStarted' }
        'CompletionUnknown' { [string]$Result.completionState -ceq 'CompletionUnknown' }
        default { $false }
    }
    if (-not $validPair) {
        throw "Result status '$($Result.status)' cannot pair with completionState '$($Result.completionState)'."
    }
    Assert-AtlasElevationBoolean -Value $Result.rootExited -Label 'Result rootExited'
    Assert-AtlasElevationBoolean -Value $Result.jobDrained -Label 'Result jobDrained'

    $rootProcessId = $null
    $sourceProcessId = $null
    $exitCodeUInt32 = $null
    $sourceToken = ConvertTo-AtlasCanonicalTokenEvidence -Evidence $Result.sourceToken -AllowNull
    $childToken = ConvertTo-AtlasCanonicalTokenEvidence -Evidence $Result.childToken -AllowNull

    if ($null -ne $Result.rootProcessId) {
        $rootProcessId = [int](Assert-AtlasElevationInteger -Value $Result.rootProcessId -Label 'Result rootProcessId' -Minimum 1 -Maximum ([int]::MaxValue))
    }
    if ($null -ne $Result.sourceProcessId) {
        $sourceProcessId = [int](Assert-AtlasElevationInteger -Value $Result.sourceProcessId -Label 'Result sourceProcessId' -Minimum 1 -Maximum ([int]::MaxValue))
    }
    if ($null -ne $Result.exitCodeUInt32) {
        $exitCodeUInt32 = [uint64](Assert-AtlasElevationInteger -Value $Result.exitCodeUInt32 -Label 'Result exitCodeUInt32' -Minimum 0 -Maximum 4294967295)
    }

    $errorText = $null
    if ($null -ne $Result.error) {
        Assert-AtlasElevationString -Value $Result.error -Label 'Result error' -MaximumLength 2048
        $errorText = [string]$Result.error
        if ([string]::IsNullOrWhiteSpace($errorText)) {
            throw 'Result error must contain non-whitespace text.'
        }
    }

    if ($Result.status -ceq 'Completed') {
        if (-not $hasBootstrapProcessId -or -not $hasBrokerProcessId) {
            throw 'A Completed result requires bootstrap and broker generations.'
        }
        if ($null -eq $rootProcessId -or $null -eq $sourceProcessId -or
            $null -eq $sourceToken -or $null -eq $childToken -or $null -eq $exitCodeUInt32 -or
            -not $Result.rootExited -or -not $Result.jobDrained -or $null -ne $errorText -or
            $Result.completionState -cne 'Completed') {
            throw 'A Completed result requires source/root/token/exit evidence, rootExited=true, jobDrained=true, and error=null.'
        }
        foreach ($token in @($sourceToken, $childToken)) {
            if ($token.userSid -cne 'S-1-5-18' -or
                $token.trustedInstallerSid -cne $script:AtlasTrustedInstallerServiceSid -or
                -not $token.enabledTrustedInstallerSid -or $token.integrityRid -ne 0x4000) {
                throw 'A Completed result contains non-TrustedInstaller token evidence.'
            }
        }
        if ($sourceToken.authenticationId -cne $childToken.authenticationId -or
            $sourceToken.sessionId -ne $childToken.sessionId -or
            $sourceToken.trustedInstallerSid -cne $childToken.trustedInstallerSid) {
            throw 'A Completed result contains mismatched source and child token evidence.'
        }
    }
    else {
        if ($null -ne $rootProcessId -or $null -ne $sourceProcessId -or
            $null -ne $sourceToken -or $null -ne $childToken -or
            $null -ne $exitCodeUInt32 -or [bool]$Result.rootExited -or
            [bool]$Result.jobDrained -or $null -eq $errorText) {
            throw 'A non-completed result requires error text and must not publish target, token, exit, or positive containment evidence.'
        }
        switch ([string]$Result.status) {
            'ConsentDenied' {
                if ($hasBootstrapProcessId -or $hasBrokerProcessId) {
                    throw 'ConsentDenied must not publish bootstrap or broker generations.'
                }
            }
            'NotStarted' {
                if ($hasBrokerProcessId) {
                    throw 'NotStarted must not publish a broker generation.'
                }
            }
            'CompletionUnknown' {
                if (-not $hasBootstrapProcessId) {
                    throw 'CompletionUnknown requires an authenticated bootstrap generation.'
                }
            }
        }
    }

    $startedUtc = ConvertTo-AtlasCanonicalUtcTimestamp -Value $Result.startedUtc -Label 'Result startedUtc'
    $endedUtc = ConvertTo-AtlasCanonicalUtcTimestamp -Value $Result.endedUtc -Label 'Result endedUtc'
    if ([datetime]::Parse($endedUtc, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind) -lt
        [datetime]::Parse($startedUtc, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)) {
        throw 'Result endedUtc precedes startedUtc.'
    }

    return [pscustomobject][ordered]@{
        protocolVersion             = [int]$protocolVersion
        requestId                   = [string]$Result.requestId
        requestSha256               = [string]$Result.requestSha256
        requesterSid                = $requesterSid.Value
        requesterProcessId          = [int]$requesterProcessId
        requesterCreationFileTime   = $requesterCreationFileTime
        requesterSessionId          = [int]$requesterSessionId
        bootstrapProcessId           = $bootstrapProcessId
        bootstrapCreationFileTime   = $bootstrapCreationFileTime
        brokerProcessId             = $brokerProcessId
        brokerCreationFileTime      = $brokerCreationFileTime
        rootProcessId               = $rootProcessId
        sourceProcessId             = $sourceProcessId
        sourceToken                 = $sourceToken
        childToken                  = $childToken
        startedUtc                  = $startedUtc
        endedUtc                    = $endedUtc
        status                      = [string]$Result.status
        completionState             = [string]$Result.completionState
        exitCodeUInt32              = $exitCodeUInt32
        rootExited                  = [bool]$Result.rootExited
        jobDrained                  = [bool]$Result.jobDrained
        error                       = $errorText
    }
}

function ConvertTo-AtlasCanonicalBrokerResult {
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    $canonical = ConvertTo-AtlasCanonicalElevationResult -Result $Result
    if (@('Completed', 'CompletionUnknown') -cnotcontains [string]$canonical.status -or
        $null -eq $canonical.bootstrapProcessId -or
        $null -eq $canonical.bootstrapCreationFileTime -or
        $null -eq $canonical.brokerProcessId -or
        $null -eq $canonical.brokerCreationFileTime) {
        throw 'Broker wire results allow only Completed or CompletionUnknown with complete bootstrap and broker generations.'
    }
    return $canonical
}

function ConvertTo-AtlasTokenEvidenceJson {
    param($Evidence)

    if ($null -eq $Evidence) { return 'null' }
    return '{"userSid":' + (ConvertTo-AtlasCanonicalJsonString $Evidence.userSid) +
        ',"trustedInstallerSid":' + (ConvertTo-AtlasCanonicalJsonString $Evidence.trustedInstallerSid) +
        ',"enabledTrustedInstallerSid":' + $Evidence.enabledTrustedInstallerSid.ToString().ToLowerInvariant() +
        ',"integrityRid":' + $Evidence.integrityRid.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"sessionId":' + $Evidence.sessionId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"authenticationId":' + (ConvertTo-AtlasCanonicalJsonString $Evidence.authenticationId) + '}'
}

function ConvertTo-AtlasElevationResultBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The function returns a byte array; Bytes describes that protocol artifact.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    $canonical = ConvertTo-AtlasCanonicalBrokerResult -Result $Result
    $nullableNumber = {
        param($Value)
        if ($null -eq $Value) { return 'null' }
        return $Value.ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    $errorJson = if ($null -eq $canonical.error) { 'null' } else { ConvertTo-AtlasCanonicalJsonString $canonical.error }
    $json = '{"protocolVersion":' + $canonical.protocolVersion.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"requestId":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requestId) +
        ',"requestSha256":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requestSha256) +
        ',"requesterSid":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requesterSid) +
        ',"requesterProcessId":' + $canonical.requesterProcessId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"requesterCreationFileTime":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requesterCreationFileTime) +
        ',"requesterSessionId":' + $canonical.requesterSessionId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"bootstrapProcessId":' + $canonical.bootstrapProcessId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"bootstrapCreationFileTime":' + (ConvertTo-AtlasCanonicalJsonString $canonical.bootstrapCreationFileTime) +
        ',"brokerProcessId":' + $canonical.brokerProcessId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"brokerCreationFileTime":' + (ConvertTo-AtlasCanonicalJsonString $canonical.brokerCreationFileTime) +
        ',"rootProcessId":' + (& $nullableNumber $canonical.rootProcessId) +
        ',"sourceProcessId":' + (& $nullableNumber $canonical.sourceProcessId) +
        ',"sourceToken":' + (ConvertTo-AtlasTokenEvidenceJson $canonical.sourceToken) +
        ',"childToken":' + (ConvertTo-AtlasTokenEvidenceJson $canonical.childToken) +
        ',"startedUtc":' + (ConvertTo-AtlasCanonicalJsonString $canonical.startedUtc) +
        ',"endedUtc":' + (ConvertTo-AtlasCanonicalJsonString $canonical.endedUtc) +
        ',"status":' + (ConvertTo-AtlasCanonicalJsonString $canonical.status) +
        ',"completionState":' + (ConvertTo-AtlasCanonicalJsonString $canonical.completionState) +
        ',"exitCodeUInt32":' + (& $nullableNumber $canonical.exitCodeUInt32) +
        ',"rootExited":' + $canonical.rootExited.ToString().ToLowerInvariant() +
        ',"jobDrained":' + $canonical.jobDrained.ToString().ToLowerInvariant() +
        ',"error":' + $errorJson + '}'
    $bytes = $script:AtlasElevationUtf8.GetBytes($json)
    if ($bytes.Length -eq 0 -or $bytes.Length -gt $script:AtlasElevationMaximumResultBytes) {
        throw 'Canonical broker result exceeds its bounded size.'
    }
    return ,([byte[]]$bytes)
}

function ConvertFrom-AtlasElevationResultBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The function consumes the complete protocol byte array.'
    )]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt $script:AtlasElevationMaximumResultBytes) {
        throw 'Broker result bytes are empty or oversized.'
    }
    try { $json = $script:AtlasElevationUtf8.GetString($Bytes) }
    catch { throw 'Broker result is not strict UTF-8.' }
    try { $result = $json | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "Broker result is not valid JSON: $($_.Exception.Message)" }
    if ($result -is [Array]) { throw 'Broker result root must be one object.' }
    $canonical = ConvertTo-AtlasCanonicalBrokerResult -Result $result
    $canonicalBytes = ConvertTo-AtlasElevationResultBytes -Result $canonical
    if ($canonicalBytes.Length -ne $Bytes.Length) { throw 'Broker result JSON is noncanonical.' }
    for ($index = 0; $index -lt $Bytes.Length; $index++) {
        if ($canonicalBytes[$index] -ne $Bytes[$index]) { throw 'Broker result JSON is noncanonical.' }
    }
    return $canonical
}

function ConvertTo-AtlasElevationReadyBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The function returns the canonical readiness byte array.'
    )]
    param(
        [Parameter(Mandatory = $true)]$Ready
    )

    $names = @(
        'protocolVersion', 'requestId', 'requestSha256',
        'bootstrapProcessId', 'bootstrapCreationFileTime',
        'brokerProcessId', 'brokerCreationFileTime'
    )
    Assert-AtlasElevationExactProperties -InputObject $Ready -Names $names -Label 'Elevation ready record'
    $version = Assert-AtlasElevationInteger -Value $Ready.protocolVersion -Label 'Ready protocolVersion' -Minimum 2 -Maximum 2
    Assert-AtlasElevationString -Value $Ready.requestId -Label 'Ready requestId' -MaximumLength 32
    if ($Ready.requestId -cnotmatch '^[0-9a-f]{32}$' -or
        [string]::Equals($Ready.requestId, ('0' * 32), [StringComparison]::Ordinal)) {
        throw 'Ready requestId must be a nonzero lowercase 32-hex identifier.'
    }
    Assert-AtlasElevationString -Value $Ready.requestSha256 -Label 'Ready requestSha256' -MaximumLength 64
    if ($Ready.requestSha256 -cnotmatch '^[0-9A-F]{64}$') {
        throw 'Ready requestSha256 must be canonical uppercase SHA-256.'
    }
    $bootstrapProcessId = Assert-AtlasElevationInteger -Value $Ready.bootstrapProcessId -Label 'Ready bootstrapProcessId' -Minimum 1 -Maximum ([int]::MaxValue)
    $brokerProcessId = Assert-AtlasElevationInteger -Value $Ready.brokerProcessId -Label 'Ready brokerProcessId' -Minimum 1 -Maximum ([int]::MaxValue)
    $bootstrapCreationFileTime = Assert-AtlasElevationFileTimeHex `
        -Value $Ready.bootstrapCreationFileTime -Label 'Ready bootstrapCreationFileTime'
    $brokerCreationFileTime = Assert-AtlasElevationFileTimeHex `
        -Value $Ready.brokerCreationFileTime -Label 'Ready brokerCreationFileTime'

    $json = '{"protocolVersion":' + $version.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"requestId":' + (ConvertTo-AtlasCanonicalJsonString ([string]$Ready.requestId)) +
        ',"requestSha256":' + (ConvertTo-AtlasCanonicalJsonString ([string]$Ready.requestSha256)) +
        ',"bootstrapProcessId":' + $bootstrapProcessId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"bootstrapCreationFileTime":' + (ConvertTo-AtlasCanonicalJsonString $bootstrapCreationFileTime) +
        ',"brokerProcessId":' + $brokerProcessId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"brokerCreationFileTime":' + (ConvertTo-AtlasCanonicalJsonString $brokerCreationFileTime) + '}'
    $bytes = $script:AtlasElevationUtf8.GetBytes($json)
    if ($bytes.Length -eq 0 -or $bytes.Length -gt $script:AtlasElevationMaximumReadyBytes) {
        throw 'Canonical readiness record exceeds its bounded size.'
    }
    return ,([byte[]]$bytes)
}

function ConvertFrom-AtlasElevationReadyBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The function consumes the complete readiness byte array.'
    )]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt $script:AtlasElevationMaximumReadyBytes) {
        throw 'Readiness bytes are empty or oversized.'
    }
    try { $json = $script:AtlasElevationUtf8.GetString($Bytes) }
    catch { throw 'Readiness record is not strict UTF-8.' }
    try { $ready = $json | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "Readiness record is not valid JSON: $($_.Exception.Message)" }
    if ($ready -is [Array]) { throw 'Readiness root must be one object.' }
    $canonicalBytes = ConvertTo-AtlasElevationReadyBytes -Ready $ready
    if ($canonicalBytes.Length -ne $Bytes.Length) { throw 'Readiness JSON is noncanonical.' }
    for ($index = 0; $index -lt $Bytes.Length; $index++) {
        if ($canonicalBytes[$index] -ne $Bytes[$index]) { throw 'Readiness JSON is noncanonical.' }
    }
    return [pscustomobject][ordered]@{
        protocolVersion           = [int]$ready.protocolVersion
        requestId                 = [string]$ready.requestId
        requestSha256             = [string]$ready.requestSha256
        bootstrapProcessId        = [int]$ready.bootstrapProcessId
        bootstrapCreationFileTime = [string]$ready.bootstrapCreationFileTime
        brokerProcessId           = [int]$ready.brokerProcessId
        brokerCreationFileTime    = [string]$ready.brokerCreationFileTime
    }
}

function Test-AtlasElevationResultBinding {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$RequestId,
        [Parameter(Mandatory = $true)][string]$RequestSha256,
        [Parameter(Mandatory = $true)][string]$RequesterSid,
        [Parameter(Mandatory = $true)][int]$RequesterProcessId,
        [Parameter(Mandatory = $true)][long]$RequesterCreationFileTime,
        [Parameter(Mandatory = $true)][int]$RequesterSessionId,
        [Parameter(Mandatory = $true)][int]$BootstrapProcessId,
        [Parameter(Mandatory = $true)][long]$BootstrapCreationFileTime,
        [Parameter(Mandatory = $true)][int]$BrokerProcessId,
        [Parameter(Mandatory = $true)][long]$BrokerCreationFileTime,
        [Parameter(Mandatory = $true)][uint32]$BootstrapExitCodeUInt32
    )

    $canonical = ConvertTo-AtlasCanonicalBrokerResult -Result $Result
    $fileTimeHex = ([uint64]$RequesterCreationFileTime).ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
    $bootstrapFileTimeHex = ([uint64]$BootstrapCreationFileTime).ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
    $brokerFileTimeHex = ([uint64]$BrokerCreationFileTime).ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
    $bindings = @(
        @($canonical.requestId, $RequestId, 'request ID'),
        @($canonical.requestSha256, $RequestSha256, 'request hash'),
        @($canonical.requesterSid, $RequesterSid, 'requester SID'),
        @($canonical.requesterProcessId, $RequesterProcessId, 'requester PID'),
        @($canonical.requesterCreationFileTime, $fileTimeHex, 'requester creation FILETIME'),
        @($canonical.requesterSessionId, $RequesterSessionId, 'requester session'),
        @($canonical.bootstrapProcessId, $BootstrapProcessId, 'bootstrap PID'),
        @($canonical.bootstrapCreationFileTime, $bootstrapFileTimeHex, 'bootstrap creation FILETIME'),
        @($canonical.brokerProcessId, $BrokerProcessId, 'broker PID'),
        @($canonical.brokerCreationFileTime, $brokerFileTimeHex, 'broker creation FILETIME')
    )
    foreach ($binding in $bindings) {
        if (-not [string]::Equals([string]$binding[0], [string]$binding[1], [StringComparison]::Ordinal)) {
            throw "Broker result $($binding[2]) binding mismatch."
        }
    }
    if ($canonical.status -ceq 'Completed' -and [uint32]$canonical.exitCodeUInt32 -ne $BootstrapExitCodeUInt32) {
        throw 'Completed result exit code does not match the exact bootstrap process handle exit code.'
    }
    if ($canonical.status -cne 'Completed' -and $BootstrapExitCodeUInt32 -eq 0) {
        throw 'A non-completed broker result cannot bind to a successful bootstrap exit code.'
    }
    return $canonical
}
