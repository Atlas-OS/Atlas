# Atlas.Core domain: data-only request protocol for the TrustedInstaller broker.
#
# This file intentionally contains no public arbitrary-command surface. The broker maps
# the closed operations below to fixed Atlas-owned entrypoints. Keep these helpers private
# until the module manifest, broker, caller binding, and VM privilege gates land together.

$script:AtlasElevationProtocolVersion = 2
$script:AtlasElevationMaximumRequestBytes = 16KB
$script:AtlasElevationMaximumReadyBytes = 4KB
$script:AtlasElevationMaximumResultBytes = 64KB
$script:AtlasElevationMaximumArguments = 128
$script:AtlasElevationMaximumCommandLineCharacters = 32766
$script:AtlasElevationUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
$script:AtlasElevationFrameMagic = [Text.Encoding]::ASCII.GetBytes('ATLASTI2')
$script:AtlasElevationFrameHeaderBytes = 64
$script:AtlasTrustedInstallerToggleStates = New-Object `
    'Collections.Generic.Dictionary[string,string[]]' ([StringComparer]::Ordinal)
$script:AtlasTrustedInstallerToggleStates.Add('FSOGameBar', @('Disable', 'Enable'))
$script:AtlasTrustedInstallerToggleStates.Add('Indexing', @('Disable', 'Minimal', 'Enable'))
$script:AtlasTrustedInstallerToggleStates.Add(
    'Mitigations',
    @('Disable', 'WindowsDefault', 'Enable')
)
$script:AtlasTrustedInstallerToggleStates.Add('ToggleDefender', @('Run'))
$script:AtlasTrustedInstallerToggleStates.Add('FixErrors2502and2503', @('Run'))
$script:AtlasTrustedInstallerToggleStates.Add('FixMSStoreIssues', @('Run'))
$script:AtlasTrustedInstallerToggleStates.Add('TelemetryComponents', @('Run'))

function Assert-AtlasElevationExactProperties {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The helper validates the complete properties collection as one schema.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Names,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($null -eq $InputObject) {
        throw "$Label must be an object."
    }

    $actual = if ($InputObject -is [Collections.IDictionary]) {
        @($InputObject.Keys | ForEach-Object { [string]$_ })
    }
    else {
        @($InputObject.PSObject.Properties | ForEach-Object { $_.Name })
    }
    if ($actual.Count -ne $Names.Count) {
        throw "$Label must contain exactly these properties: $($Names -join ', ')."
    }

    foreach ($actualName in $actual) {
        $matched = $false
        foreach ($expectedName in $Names) {
            if ([string]::Equals($actualName, $expectedName, [StringComparison]::Ordinal)) {
                $matched = $true
                break
            }
        }
        if (-not $matched) {
            throw "$Label property '$actualName' is unknown, duplicated, or incorrectly cased."
        }
    }
}

function Assert-AtlasElevationString {
    param(
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [int]$MaximumLength = 1024,

        [switch]$AllowEmpty
    )

    if ($Value -isnot [string]) {
        throw "$Label must be a string."
    }
    if (-not $AllowEmpty -and $Value.Length -eq 0) {
        throw "$Label must not be empty."
    }
    if ($Value.Length -gt $MaximumLength) {
        throw "$Label exceeds the $MaximumLength-character limit."
    }
    if ($Value.IndexOf([char]0) -ge 0) {
        throw "$Label must not contain NUL."
    }

    # UTF8Encoding(false, true) still receives UTF-16 code units. Reject unpaired
    # surrogates before encoding so malformed text is never normalized to U+FFFD.
    for ($index = 0; $index -lt $Value.Length; $index++) {
        $codeUnit = [int]$Value[$index]
        if ($codeUnit -ge 0xD800 -and $codeUnit -le 0xDBFF) {
            if ($index + 1 -ge $Value.Length) {
                throw "$Label contains an unpaired UTF-16 surrogate."
            }
            $low = [int]$Value[$index + 1]
            if ($low -lt 0xDC00 -or $low -gt 0xDFFF) {
                throw "$Label contains an unpaired UTF-16 surrogate."
            }
            $index++
        }
        elseif ($codeUnit -ge 0xDC00 -and $codeUnit -le 0xDFFF) {
            throw "$Label contains an unpaired UTF-16 surrogate."
        }
    }
}

function Test-AtlasElevationIntegerType {
    param($Value)

    return $Value -is [byte] -or $Value -is [sbyte] -or
        $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64]
}

function Assert-AtlasElevationInteger {
    param(
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [long]$Minimum,

        [long]$Maximum
    )

    if (-not (Test-AtlasElevationIntegerType -Value $Value)) {
        throw "$Label must be an integer."
    }

    try {
        $number = [Convert]::ToInt64($Value, [Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        throw "$Label is outside the supported integer range."
    }

    if ($number -lt $Minimum -or $number -gt $Maximum) {
        throw "$Label must be between $Minimum and $Maximum."
    }

    return $number
}

function Assert-AtlasElevationBoolean {
    param(
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($Value -isnot [bool]) {
        throw "$Label must be a boolean."
    }
}

function Assert-AtlasElevationFileTimeHex {
    param(
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    Assert-AtlasElevationString -Value $Value -Label $Label -MaximumLength 16
    if ($Value -cnotmatch '^[0-9A-F]{16}$') {
        throw "$Label must be a canonical uppercase 16-hex FILETIME."
    }
    try {
        $numeric = [uint64]::Parse(
            [string]$Value,
            [Globalization.NumberStyles]::HexNumber,
            [Globalization.CultureInfo]::InvariantCulture
        )
    }
    catch {
        throw "$Label must be a canonical uppercase 16-hex FILETIME."
    }
    if ($numeric -eq 0 -or $numeric -gt [uint64][long]::MaxValue) {
        throw "$Label must be between 0000000000000001 and 7FFFFFFFFFFFFFFF."
    }
    return [string]$Value
}

function ConvertTo-AtlasCanonicalJsonString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    Assert-AtlasElevationString -Value $Value -Label 'JSON string' -MaximumLength ([int]::MaxValue) -AllowEmpty

    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    foreach ($character in $Value.ToCharArray()) {
        $escaped = switch ([int]$character) {
            0x22 { '\"' }
            0x5C { '\\' }
            0x08 { '\b' }
            0x09 { '\t' }
            0x0A { '\n' }
            0x0C { '\f' }
            0x0D { '\r' }
            default { $null }
        }

        if ($null -ne $escaped) {
            [void]$builder.Append($escaped)
        }
        elseif ([int]$character -lt 0x20) {
            [void]$builder.Append(('\u{0:x4}' -f [int]$character))
        }
        else {
            [void]$builder.Append($character)
        }
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Get-AtlasElevationSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return (($algorithm.ComputeHash($Bytes) | ForEach-Object { $_.ToString('X2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
    }
}

function ConvertTo-AtlasCanonicalOperationData {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        $OperationData
    )

    if (@('Toggle', 'ResetServices', 'SafeModeRecovery') -cnotcontains $Operation) {
        throw "Unsupported TrustedInstaller operation '$Operation'."
    }
    switch ($Operation) {
        'Toggle' {
            $names = @('name', 'state', 'silent', 'justContext', 'noExplorerRestart')
            Assert-AtlasElevationExactProperties -InputObject $OperationData -Names $names -Label 'Toggle operationData'
            Assert-AtlasElevationString -Value $OperationData.name -Label 'Toggle name' -MaximumLength 128
            Assert-AtlasElevationString -Value $OperationData.state -Label 'Toggle state' -MaximumLength 128
            if ($OperationData.name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -or
                $OperationData.state -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
                throw 'Toggle name and state must be bounded identifier values, not paths or command text.'
            }
            $toggleName = [string]$OperationData.name
            $toggleState = [string]$OperationData.state
            if (-not $script:AtlasTrustedInstallerToggleStates.ContainsKey($toggleName)) {
                throw "Toggle '$toggleName' is outside the exact TrustedInstaller operation allowlist."
            }
            $allowedStates = $script:AtlasTrustedInstallerToggleStates[$toggleName]
            if (@($allowedStates | Where-Object {
                        [string]::Equals([string]$_, $toggleState, [StringComparison]::Ordinal)
                    }).Count -ne 1) {
                throw "Toggle '$toggleName' does not allow exact TrustedInstaller state '$toggleState'."
            }
            Assert-AtlasElevationBoolean -Value $OperationData.silent -Label 'Toggle silent'
            Assert-AtlasElevationBoolean -Value $OperationData.justContext -Label 'Toggle justContext'
            Assert-AtlasElevationBoolean -Value $OperationData.noExplorerRestart -Label 'Toggle noExplorerRestart'
            if (-not $OperationData.silent) {
                throw 'The initial noninteractive Toggle protocol requires silent=true.'
            }

            return [pscustomobject][ordered]@{
                name              = $toggleName
                state             = $toggleState
                silent            = [bool]$OperationData.silent
                justContext       = [bool]$OperationData.justContext
                noExplorerRestart = [bool]$OperationData.noExplorerRestart
            }
        }
        'ResetServices' {
            $names = @('restoreSource')
            Assert-AtlasElevationExactProperties -InputObject $OperationData -Names $names -Label 'ResetServices operationData'
            Assert-AtlasElevationString -Value $OperationData.restoreSource -Label 'ResetServices restoreSource' -MaximumLength 15
            if (@('ToggleDefaults', 'WindowsBackup', 'AtlasBackup') -cnotcontains [string]$OperationData.restoreSource) {
                throw 'ResetServices restoreSource must be ToggleDefaults, WindowsBackup, or AtlasBackup.'
            }

            return [pscustomobject][ordered]@{
                restoreSource = [string]$OperationData.restoreSource
            }
        }
        'SafeModeRecovery' {
            $names = @('operationId')
            Assert-AtlasElevationExactProperties -InputObject $OperationData -Names $names -Label 'SafeModeRecovery operationData'
            Assert-AtlasElevationString -Value $OperationData.operationId `
                -Label 'SafeModeRecovery operationId' -MaximumLength 32
            if ($OperationData.operationId -cnotmatch '^[a-f0-9]{32}$' -or
                [string]::Equals($OperationData.operationId, ('0' * 32), [StringComparison]::Ordinal)) {
                throw 'SafeModeRecovery operationId must be a nonzero lowercase 32-hex identifier.'
            }

            return [pscustomobject][ordered]@{
                operationId = [string]$OperationData.operationId
            }
        }
        default {
            throw "Unsupported TrustedInstaller operation '$Operation'."
        }
    }
}

function ConvertTo-AtlasCanonicalElevationRequest {
    param(
        [Parameter(Mandatory = $true)]
        $Request
    )

    $names = @(
        'protocolVersion',
        'requestId',
        'requesterSid',
        'requesterProcessId',
        'requesterCreationFileTime',
        'requesterSessionId',
        'operation',
        'operationData',
        'timeoutMilliseconds',
        'windowMode'
    )
    Assert-AtlasElevationExactProperties -InputObject $Request -Names $names -Label 'Elevation request'

    $protocolVersion = Assert-AtlasElevationInteger -Value $Request.protocolVersion `
        -Label 'protocolVersion' -Minimum 2 -Maximum 2

    Assert-AtlasElevationString -Value $Request.requestId -Label 'requestId' -MaximumLength 32
    if ($Request.requestId -cnotmatch '^[0-9a-f]{32}$' -or
        [string]::Equals($Request.requestId, ('0' * 32), [StringComparison]::Ordinal)) {
        throw 'requestId must be a nonzero lowercase 32-hex identifier.'
    }
    $requestId = [string]$Request.requestId

    Assert-AtlasElevationString -Value $Request.requesterSid -Label 'requesterSid' -MaximumLength 184
    try {
        $sid = New-Object Security.Principal.SecurityIdentifier($Request.requesterSid)
    }
    catch {
        throw 'requesterSid must be a canonical Windows SID string.'
    }
    if (-not [string]::Equals($sid.Value, $Request.requesterSid, [StringComparison]::Ordinal)) {
        throw 'requesterSid must be a canonical Windows SID string.'
    }

    $requesterProcessId = Assert-AtlasElevationInteger -Value $Request.requesterProcessId `
        -Label 'requesterProcessId' -Minimum 1 -Maximum ([int]::MaxValue)

    $requesterCreationFileTime = Assert-AtlasElevationFileTimeHex `
        -Value $Request.requesterCreationFileTime `
        -Label 'requesterCreationFileTime'

    $requesterSessionId = Assert-AtlasElevationInteger -Value $Request.requesterSessionId `
        -Label 'requesterSessionId' -Minimum 0 -Maximum ([int]::MaxValue)

    Assert-AtlasElevationString -Value $Request.operation -Label 'operation' -MaximumLength 32
    if (@('Toggle', 'ResetServices', 'SafeModeRecovery') -cnotcontains [string]$Request.operation) {
        throw "Unsupported TrustedInstaller operation '$($Request.operation)'."
    }
    $operationData = ConvertTo-AtlasCanonicalOperationData -Operation $Request.operation -OperationData $Request.operationData

    $timeoutMilliseconds = Assert-AtlasElevationInteger -Value $Request.timeoutMilliseconds `
        -Label 'timeoutMilliseconds' -Minimum 1 -Maximum 86400000

    Assert-AtlasElevationString -Value $Request.windowMode -Label 'windowMode' -MaximumLength 14
    if (-not [string]::Equals($Request.windowMode, 'NonInteractive', [StringComparison]::Ordinal)) {
        throw 'The initial operation set requires windowMode NonInteractive.'
    }

    return [pscustomobject][ordered]@{
        protocolVersion    = [int]$protocolVersion
        requestId          = $requestId
        requesterSid       = $sid.Value
        requesterProcessId = [int]$requesterProcessId
        requesterCreationFileTime = $requesterCreationFileTime
        requesterSessionId = [int]$requesterSessionId
        operation          = [string]$Request.operation
        operationData      = $operationData
        timeoutMilliseconds = [int]$timeoutMilliseconds
        windowMode         = 'NonInteractive'
    }
}

function ConvertTo-AtlasCanonicalOperationDataJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        $OperationData
    )

    switch ($Operation) {
        'Toggle' {
            return '{"name":' + (ConvertTo-AtlasCanonicalJsonString $OperationData.name) +
                ',"state":' + (ConvertTo-AtlasCanonicalJsonString $OperationData.state) +
                ',"silent":' + $OperationData.silent.ToString().ToLowerInvariant() +
                ',"justContext":' + $OperationData.justContext.ToString().ToLowerInvariant() +
                ',"noExplorerRestart":' + $OperationData.noExplorerRestart.ToString().ToLowerInvariant() + '}'
        }
        'ResetServices' {
            return '{"restoreSource":' + (ConvertTo-AtlasCanonicalJsonString $OperationData.restoreSource) + '}'
        }
        'SafeModeRecovery' {
            return '{"operationId":' + (ConvertTo-AtlasCanonicalJsonString $OperationData.operationId) + '}'
        }
    }
}

function Test-AtlasElevationRequesterBinding {
    param(
        [Parameter(Mandatory = $true)]
        $Request,

        [Parameter(Mandatory = $true)]
        $Evidence
    )

    try {
        $canonical = ConvertTo-AtlasCanonicalElevationRequest -Request $Request
        foreach ($propertyName in @('ProcessId', 'CreationFileTime', 'UserSid', 'SessionId')) {
            if ($null -eq $Evidence.PSObject.Properties[$propertyName]) {
                return $false
            }
        }
        $processId = Assert-AtlasElevationInteger -Value $Evidence.ProcessId `
            -Label 'Kernel requester process ID' -Minimum 1 -Maximum ([int]::MaxValue)
        $creationFileTime = Assert-AtlasElevationInteger -Value $Evidence.CreationFileTime `
            -Label 'Kernel requester creation FILETIME' -Minimum 1 -Maximum ([long]::MaxValue)
        $sessionId = Assert-AtlasElevationInteger -Value $Evidence.SessionId `
            -Label 'Kernel requester session ID' -Minimum 0 -Maximum ([int]::MaxValue)
        Assert-AtlasElevationString -Value $Evidence.UserSid -Label 'Kernel requester SID' -MaximumLength 184
        $creationFileTimeHex = ([uint64]$creationFileTime).ToString(
            'X16',
            [Globalization.CultureInfo]::InvariantCulture
        )

        return $processId -eq $canonical.requesterProcessId -and
            [string]::Equals(
                $creationFileTimeHex,
                $canonical.requesterCreationFileTime,
                [StringComparison]::Ordinal
            ) -and
            [string]::Equals([string]$Evidence.UserSid, $canonical.requesterSid, [StringComparison]::Ordinal) -and
            $sessionId -eq $canonical.requesterSessionId
    }
    catch {
        return $false
    }
}

function ConvertTo-AtlasElevationRequestBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Bytes is the established protocol term for the bound byte sequence.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        $Request
    )

    $canonical = ConvertTo-AtlasCanonicalElevationRequest -Request $Request
    $operationJson = ConvertTo-AtlasCanonicalOperationDataJson `
        -Operation $canonical.operation -OperationData $canonical.operationData

    $json = '{"protocolVersion":' + $canonical.protocolVersion.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"requestId":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requestId) +
        ',"requesterSid":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requesterSid) +
        ',"requesterProcessId":' + $canonical.requesterProcessId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"requesterCreationFileTime":' + (ConvertTo-AtlasCanonicalJsonString $canonical.requesterCreationFileTime) +
        ',"requesterSessionId":' + $canonical.requesterSessionId.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"operation":' + (ConvertTo-AtlasCanonicalJsonString $canonical.operation) +
        ',"operationData":' + $operationJson +
        ',"timeoutMilliseconds":' + $canonical.timeoutMilliseconds.ToString([Globalization.CultureInfo]::InvariantCulture) +
        ',"windowMode":' + (ConvertTo-AtlasCanonicalJsonString $canonical.windowMode) + '}'

    $bytes = $script:AtlasElevationUtf8.GetBytes($json)
    if ($bytes.Length -gt $script:AtlasElevationMaximumRequestBytes) {
        throw "Canonical request exceeds the $($script:AtlasElevationMaximumRequestBytes)-byte limit."
    }

    return ,([byte[]]$bytes)
}

function ConvertFrom-AtlasElevationRequestBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Bytes is the established protocol term for the bound byte sequence.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,

        [ValidateNotNullOrEmpty()]
        [string]$ExpectedSha256,

        [ValidateNotNullOrEmpty()]
        [string]$ExpectedRequestId
    )

    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt $script:AtlasElevationMaximumRequestBytes) {
        throw "Request bytes must contain between 1 and $($script:AtlasElevationMaximumRequestBytes) bytes."
    }

    $actualHash = Get-AtlasElevationSha256 -Bytes $Bytes
    if ($PSBoundParameters.ContainsKey('ExpectedSha256')) {
        if ($ExpectedSha256 -cnotmatch '^[0-9A-F]{64}$' -or
            -not [string]::Equals($actualHash, $ExpectedSha256, [StringComparison]::Ordinal)) {
            throw 'Request SHA-256 binding does not match the original request bytes.'
        }
    }

    try {
        $json = $script:AtlasElevationUtf8.GetString($Bytes)
    }
    catch {
        throw 'Request is not valid canonical UTF-8.'
    }

    try {
        $request = $json | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Request is not valid JSON: $($_.Exception.Message)"
    }
    if ($request -is [Array]) {
        throw 'Request root must be one JSON object.'
    }

    $canonical = ConvertTo-AtlasCanonicalElevationRequest -Request $request
    $canonicalBytes = ConvertTo-AtlasElevationRequestBytes -Request $canonical
    if ($canonicalBytes.Length -ne $Bytes.Length) {
        throw 'Request JSON is valid but noncanonical.'
    }
    for ($index = 0; $index -lt $Bytes.Length; $index++) {
        if ($canonicalBytes[$index] -ne $Bytes[$index]) {
            throw 'Request JSON is valid but noncanonical.'
        }
    }

    if ($PSBoundParameters.ContainsKey('ExpectedRequestId')) {
        Assert-AtlasElevationString -Value $ExpectedRequestId -Label 'Expected request ID' -MaximumLength 32
        if (-not [string]::Equals($canonical.requestId, $ExpectedRequestId, [StringComparison]::Ordinal)) {
            throw 'Request ID binding does not match the expected request.'
        }
    }

    return $canonical
}

function New-AtlasElevationRequestEnvelope {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This pure constructor only returns an in-memory protocol envelope.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Toggle', 'ResetServices', 'SafeModeRecovery')]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        $OperationData,

        [Parameter(Mandatory = $true)]
        [string]$RequesterSid,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$RequesterProcessId,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [long]::MaxValue)]
        [long]$RequesterCreationFileTime,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$RequesterSessionId,

        [ValidateRange(1, 86400000)]
        [int]$TimeoutMilliseconds = 900000,

        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$RequestId = [guid]::NewGuid().ToString('N')
    )

    $request = [pscustomobject][ordered]@{
        protocolVersion    = $script:AtlasElevationProtocolVersion
        requestId          = $RequestId
        requesterSid       = $RequesterSid
        requesterProcessId = $RequesterProcessId
        requesterCreationFileTime = ([uint64]$RequesterCreationFileTime).ToString(
            'X16',
            [Globalization.CultureInfo]::InvariantCulture
        )
        requesterSessionId = $RequesterSessionId
        operation          = $Operation
        operationData      = $OperationData
        timeoutMilliseconds = $TimeoutMilliseconds
        windowMode         = 'NonInteractive'
    }
    $canonical = ConvertTo-AtlasCanonicalElevationRequest -Request $request
    $bytes = ConvertTo-AtlasElevationRequestBytes -Request $canonical

    return [pscustomobject][ordered]@{
        Request = $canonical
        Bytes   = [byte[]]$bytes
        Sha256  = Get-AtlasElevationSha256 -Bytes $bytes
    }
}

function New-AtlasElevationRequestDocument {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This pure constructor only returns an in-memory protocol document.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Toggle', 'ResetServices', 'SafeModeRecovery')]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        $OperationData,

        [Parameter(Mandatory = $true)]
        [string]$RequesterSid,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$RequesterProcessId,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [long]::MaxValue)]
        [long]$RequesterCreationFileTime,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$RequesterSessionId,

        [ValidateRange(1, 86400000)]
        [int]$TimeoutMilliseconds = 900000,

        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$RequestId = [guid]::NewGuid().ToString('N')
    )

    return (New-AtlasElevationRequestEnvelope @PSBoundParameters).Request
}

function Get-AtlasSha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    return Get-AtlasElevationSha256 -Bytes $Bytes
}

function ConvertTo-AtlasWindowsArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    Assert-AtlasElevationString -Value $Value -Label 'Windows argument' -MaximumLength 32766 -AllowEmpty
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }

    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    $backslashes = 0

    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }

        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }

        if ($backslashes -gt 0) {
            [void]$builder.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }

    if ($backslashes -gt 0) {
        [void]$builder.Append(('\' * ($backslashes * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function ConvertTo-AtlasWindowsCommandLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApplicationPath,

        [AllowEmptyCollection()]
        [object[]]$ArgumentList = @()
    )

    Assert-AtlasElevationString -Value $ApplicationPath -Label 'Application path' -MaximumLength 32766
    $tokens = @($ApplicationPath) + @($ArgumentList)
    $commandLine = Join-AtlasWindowsArguments -ArgumentList $tokens
    return $commandLine
}

function New-AtlasWindowsCommandLine {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This pure constructor only returns a command-line string.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApplicationPath,

        [AllowEmptyCollection()]
        [object[]]$ArgumentList = @()
    )

    return ConvertTo-AtlasWindowsCommandLine -ApplicationPath $ApplicationPath -ArgumentList $ArgumentList
}

function Join-AtlasWindowsArguments {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Arguments accurately names the token collection being joined.'
    )]
    param(
        [AllowEmptyCollection()]
        [object[]]$ArgumentList = @()
    )

    if ($ArgumentList.Count -gt $script:AtlasElevationMaximumArguments) {
        throw "Argument list exceeds the $($script:AtlasElevationMaximumArguments)-argument limit."
    }

    $quoted = foreach ($token in $ArgumentList) {
        if ($token -isnot [string]) {
            throw 'Windows argument list must contain only non-null strings.'
        }
        ConvertTo-AtlasWindowsArgument -Value $token
    }
    $commandLine = $quoted -join ' '
    if ($commandLine.Length -gt $script:AtlasElevationMaximumCommandLineCharacters) {
        throw "Windows command line exceeds the $($script:AtlasElevationMaximumCommandLineCharacters)-character limit."
    }

    return $commandLine
}

function Get-AtlasElevationFrameKindValue {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Request', 'Ready', 'Result')]
        [string]$Kind
    )

    if (@('Request', 'Ready', 'Result') -cnotcontains $Kind) {
        throw "Elevation frame kind '$Kind' is not canonical."
    }
    switch ($Kind) {
        'Request' { return [uint16]1 }
        'Ready' { return [uint16]2 }
        'Result' { return [uint16]3 }
    }
}

function Get-AtlasElevationFrameMaximumBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Bytes describes the byte-count limit returned for one frame kind.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Request', 'Ready', 'Result')]
        [string]$Kind
    )

    if (@('Request', 'Ready', 'Result') -cnotcontains $Kind) {
        throw "Elevation frame kind '$Kind' is not canonical."
    }
    switch ($Kind) {
        'Request' { return $script:AtlasElevationMaximumRequestBytes }
        'Ready' { return $script:AtlasElevationMaximumReadyBytes }
        'Result' { return $script:AtlasElevationMaximumResultBytes }
    }
}

function ConvertTo-AtlasElevationRequestIdBytes {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Bytes describes the fixed 16-byte request identifier representation.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestId
    )

    if ($RequestId -cnotmatch '^[0-9a-f]{32}$' -or
        [string]::Equals($RequestId, ('0' * 32), [StringComparison]::Ordinal)) {
        throw 'RequestId must be a nonzero lowercase 32-hex identifier.'
    }
    $bytes = New-Object byte[] 16
    for ($index = 0; $index -lt 16; $index++) {
        $bytes[$index] = [Convert]::ToByte($RequestId.Substring($index * 2, 2), 16)
    }
    return ,$bytes
}

function ConvertTo-AtlasElevationFrame {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This pure encoder returns an in-memory protocol frame.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Request', 'Ready', 'Result')]
        [string]$Kind,

        [Parameter(Mandatory = $true)]
        [string]$RequestId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Payload
    )

    $maximum = Get-AtlasElevationFrameMaximumBytes -Kind $Kind
    if ($Payload.Length -eq 0 -or $Payload.Length -gt $maximum) {
        throw "$Kind frame payload must contain an allowed bounded byte sequence (maximum $maximum bytes)."
    }
    $requestIdBytes = ConvertTo-AtlasElevationRequestIdBytes -RequestId $RequestId
    $payloadHash = Get-AtlasElevationSha256 -Bytes $Payload
    $frame = New-Object byte[] ($script:AtlasElevationFrameHeaderBytes + $Payload.Length)
    [Array]::Copy($script:AtlasElevationFrameMagic, 0, $frame, 0, 8)
    [Array]::Copy([BitConverter]::GetBytes([uint16]2), 0, $frame, 8, 2)
    [Array]::Copy([BitConverter]::GetBytes((Get-AtlasElevationFrameKindValue -Kind $Kind)), 0, $frame, 10, 2)
    [Array]::Copy([BitConverter]::GetBytes([uint32]$Payload.Length), 0, $frame, 12, 4)
    [Array]::Copy($requestIdBytes, 0, $frame, 16, 16)
    for ($index = 0; $index -lt 32; $index++) {
        $frame[32 + $index] = [Convert]::ToByte($payloadHash.Substring($index * 2, 2), 16)
    }
    if ($Payload.Length -ne 0) {
        [Array]::Copy($Payload, 0, $frame, $script:AtlasElevationFrameHeaderBytes, $Payload.Length)
    }
    return ,$frame
}

function ConvertFrom-AtlasElevationFrame {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,

        [ValidateSet('Request', 'Ready', 'Result')]
        [string]$ExpectedKind,

        [string]$ExpectedRequestId
    )

    if ($Bytes.Length -lt $script:AtlasElevationFrameHeaderBytes) {
        throw 'Elevation frame ended before its fixed header.'
    }
    for ($index = 0; $index -lt 8; $index++) {
        if ($Bytes[$index] -ne $script:AtlasElevationFrameMagic[$index]) {
            throw 'Elevation frame magic is invalid.'
        }
    }
    if ([BitConverter]::ToUInt16($Bytes, 8) -ne 2) {
        throw 'Elevation frame version is unsupported.'
    }
    $kindValue = [BitConverter]::ToUInt16($Bytes, 10)
    $kind = switch ($kindValue) {
        1 { 'Request' }
        2 { 'Ready' }
        3 { 'Result' }
        default { throw 'Elevation frame kind is unsupported.' }
    }
    $payloadLength = [BitConverter]::ToUInt32($Bytes, 12)
    $maximum = Get-AtlasElevationFrameMaximumBytes -Kind $kind
    if ($payloadLength -eq 0 -or $payloadLength -gt $maximum -or
        $Bytes.Length -ne ($script:AtlasElevationFrameHeaderBytes + $payloadLength)) {
        throw 'Elevation frame payload length is invalid or noncanonical.'
    }
    $requestIdBuilder = New-Object Text.StringBuilder 32
    for ($index = 0; $index -lt 16; $index++) {
        [void]$requestIdBuilder.Append($Bytes[16 + $index].ToString('x2'))
    }
    $requestId = $requestIdBuilder.ToString()
    [void](ConvertTo-AtlasElevationRequestIdBytes -RequestId $requestId)
    $payload = New-Object byte[] $payloadLength
    if ($payloadLength -ne 0) {
        [Array]::Copy($Bytes, $script:AtlasElevationFrameHeaderBytes, $payload, 0, $payloadLength)
    }
    $actualHash = Get-AtlasElevationSha256 -Bytes $payload
    for ($index = 0; $index -lt 32; $index++) {
        if ($Bytes[32 + $index] -ne [Convert]::ToByte($actualHash.Substring($index * 2, 2), 16)) {
            throw 'Elevation frame payload SHA-256 is invalid.'
        }
    }
    if ($PSBoundParameters.ContainsKey('ExpectedKind') -and
        -not [string]::Equals($kind, $ExpectedKind, [StringComparison]::Ordinal)) {
        throw "Expected a $ExpectedKind elevation frame, received $kind."
    }
    if ($PSBoundParameters.ContainsKey('ExpectedRequestId') -and
        -not [string]::Equals($requestId, $ExpectedRequestId, [StringComparison]::Ordinal)) {
        throw 'Elevation frame request ID does not match the active request.'
    }

    return [pscustomobject][ordered]@{
        Kind          = $kind
        RequestId     = $requestId
        Payload       = [byte[]]$payload
        PayloadSha256 = $actualHash
    }
}

function Invoke-AtlasElevationStreamOperation {
    param(
        [Parameter(Mandatory = $true)][IO.Stream]$Stream,
        [Parameter(Mandatory = $true)][ValidateSet('Read', 'Write')][string]$Operation,
        [Parameter(Mandatory = $true)][byte[]]$Buffer,
        [Parameter(Mandatory = $true)][int]$Offset,
        [Parameter(Mandatory = $true)][int]$Count,
        [Parameter(Mandatory = $true)][Diagnostics.Stopwatch]$Stopwatch,
        [Parameter(Mandatory = $true)][ValidateRange(1, 86460000)][int]$TimeoutMilliseconds
    )

    $remaining = $TimeoutMilliseconds - [int][Math]::Min($TimeoutMilliseconds, $Stopwatch.ElapsedMilliseconds)
    if ($remaining -le 0) {
        throw "Elevation frame $Operation exceeded its bounded deadline."
    }
    $pending = if ($Operation -eq 'Read') {
        $Stream.BeginRead($Buffer, $Offset, $Count, $null, $null)
    }
    else {
        $Stream.BeginWrite($Buffer, $Offset, $Count, $null, $null)
    }
    try {
        if (-not $pending.AsyncWaitHandle.WaitOne($remaining)) {
            # Stream APM has no cancellation token. Closing this one-request channel is
            # the protocol cancellation boundary; then observe completion and call the
            # matching End method before releasing its wait handle or buffer ownership.
            try { $Stream.Dispose() } catch { $null = $_ }
            if (-not $pending.AsyncWaitHandle.WaitOne(5000)) {
                throw "Elevation frame $Operation cancellation did not complete within five seconds."
            }
            try {
                if ($Operation -ceq 'Read') {
                    [void]$Stream.EndRead($pending)
                }
                else {
                    $Stream.EndWrite($pending)
                }
            }
            catch {
                # Disposal normally completes pending pipe I/O with an exception. The
                # timeout below is the authoritative caller-facing outcome.
                $null = $_
            }
            throw "Elevation frame $Operation exceeded its bounded deadline."
        }
        if ($Operation -ceq 'Read') {
            return $Stream.EndRead($pending)
        }
        $Stream.EndWrite($pending)
        return $Count
    }
    finally {
        $pending.AsyncWaitHandle.Close()
    }
}

function Assert-AtlasElevationStreamEof {
    param(
        [Parameter(Mandatory = $true)]
        [IO.Stream]$Stream,

        [ValidateRange(1, 60000)]
        [int]$TimeoutMilliseconds = 10000
    )

    $buffer = New-Object byte[] 1
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        $read = Invoke-AtlasElevationStreamOperation `
            -Stream $Stream `
            -Operation Read `
            -Buffer $buffer `
            -Offset 0 `
            -Count 1 `
            -Stopwatch $timer `
            -TimeoutMilliseconds $TimeoutMilliseconds
        if ($read -ne 0) {
            throw 'Elevation channel contained trailing bytes after its terminal Result frame.'
        }
    }
    finally {
        $timer.Stop()
    }
}

function Read-AtlasElevationFrame {
    param(
        [Parameter(Mandatory = $true)][IO.Stream]$Stream,
        [Parameter(Mandatory = $true)][ValidateSet('Request', 'Ready', 'Result')][string]$ExpectedKind,
        [Parameter(Mandatory = $true)][string]$ExpectedRequestId,
        [ValidateRange(1, 86460000)][int]$TimeoutMilliseconds = 30000
    )

    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        $header = New-Object byte[] $script:AtlasElevationFrameHeaderBytes
        $offset = 0
        while ($offset -lt $header.Length) {
            $read = Invoke-AtlasElevationStreamOperation -Stream $Stream -Operation Read -Buffer $header `
                -Offset $offset -Count ($header.Length - $offset) -Stopwatch $timer -TimeoutMilliseconds $TimeoutMilliseconds
            if ($read -eq 0) { throw 'Elevation channel closed before the frame header completed.' }
            $offset += $read
        }
        $payloadLength = [BitConverter]::ToUInt32($header, 12)
        $maximum = Get-AtlasElevationFrameMaximumBytes -Kind $ExpectedKind
        if ($payloadLength -gt $maximum) { throw 'Elevation frame declared an oversized payload.' }
        $bytes = New-Object byte[] ($header.Length + $payloadLength)
        [Array]::Copy($header, $bytes, $header.Length)
        $offset = $header.Length
        while ($offset -lt $bytes.Length) {
            $read = Invoke-AtlasElevationStreamOperation -Stream $Stream -Operation Read -Buffer $bytes `
                -Offset $offset -Count ($bytes.Length - $offset) -Stopwatch $timer -TimeoutMilliseconds $TimeoutMilliseconds
            if ($read -eq 0) { throw 'Elevation channel closed before the frame payload completed.' }
            $offset += $read
        }
        return ConvertFrom-AtlasElevationFrame -Bytes $bytes -ExpectedKind $ExpectedKind -ExpectedRequestId $ExpectedRequestId
    }
    finally {
        $timer.Stop()
    }
}

function Write-AtlasElevationFrame {
    param(
        [Parameter(Mandatory = $true)][IO.Stream]$Stream,
        [Parameter(Mandatory = $true)][ValidateSet('Request', 'Ready', 'Result')][string]$Kind,
        [Parameter(Mandatory = $true)][string]$RequestId,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Payload,
        [ValidateRange(1, 86460000)][int]$TimeoutMilliseconds = 30000
    )

    $bytes = ConvertTo-AtlasElevationFrame -Kind $Kind -RequestId $RequestId -Payload $Payload
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        [void](Invoke-AtlasElevationStreamOperation -Stream $Stream -Operation Write -Buffer $bytes `
            -Offset 0 -Count $bytes.Length -Stopwatch $timer -TimeoutMilliseconds $TimeoutMilliseconds)
    }
    finally {
        $timer.Stop()
    }
}
