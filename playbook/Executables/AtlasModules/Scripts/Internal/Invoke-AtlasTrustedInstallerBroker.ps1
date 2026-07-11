<#
.SYNOPSIS
    Fixed high-integrity broker for Atlas's closed TrustedInstaller operation protocol.
.NOTES
    The native bootstrap supplies only kernel-derived identity fields and four inherited
    handles. Canonical request/result bytes never enter argv, environment variables, or
    persistent storage. This script never accepts a command, executable, script, or argv.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{32}$')]
    [string]$ExpectedRequestId,

    [Parameter(Mandatory = $true)]
    [uint64]$RequestHandle,

    [Parameter(Mandatory = $true)]
    [uint64]$ResultHandle,

    [Parameter(Mandatory = $true)]
    [uint64]$LivenessHandle,

    [Parameter(Mandatory = $true)]
    [uint64]$OuterJobHandle,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$BootstrapProcessId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-F]{16}$')]
    [string]$BootstrapCreationFileTime,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$RequesterProcessId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-F]{16}$')]
    [string]$RequesterCreationFileTime,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RequesterSid,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$RequesterSessionId
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if ($ExpectedRequestId -cnotmatch '^[0-9a-f]{32}$' -or
    [string]::Equals($ExpectedRequestId, ('0' * 32), [StringComparison]::Ordinal)) {
    throw 'ExpectedRequestId must be nonzero canonical lowercase 32-hex.'
}
if ([string]::Equals($BootstrapCreationFileTime, ('0' * 16), [StringComparison]::Ordinal) -or
    [string]::Equals($RequesterCreationFileTime, ('0' * 16), [StringComparison]::Ordinal)) {
    throw 'Bootstrap and requester creation FILETIMEs must not be all zero.'
}
$handleValues = @($RequestHandle, $ResultHandle, $LivenessHandle, $OuterJobHandle)
if (@($handleValues | Where-Object { $_ -eq 0 -or $_ -gt [long]::MaxValue }).Count -ne 0 -or
    @($handleValues | Select-Object -Unique).Count -ne 4) {
    throw 'The inherited elevation handles must be four distinct nonzero native handle values.'
}
try {
    $canonicalRequesterSid = New-Object Security.Principal.SecurityIdentifier($RequesterSid)
}
catch {
    throw 'RequesterSid must be a canonical Windows SID.'
}
if (-not [string]::Equals($canonicalRequesterSid.Value, $RequesterSid, [StringComparison]::Ordinal)) {
    throw 'RequesterSid must be a canonical Windows SID.'
}

# The native bootstrap constructs this environment from Win32-discovered fixed paths before
# powershell.exe is created. Reject loader/runtime hooks defensively before importing anything.
foreach ($environmentEntry in Get-ChildItem Env:) {
    if ($environmentEntry.Name -match '^(?i:COR_|COMPLUS_|DOTNET_)' -or
        $environmentEntry.Name -in @('PSExecutionPolicyPreference', '__PSLockDownPolicy')) {
        throw "Forbidden broker environment variable '$($environmentEntry.Name)' is present."
    }
}
$windowsDirectory = [IO.Path]::GetFullPath($env:SystemRoot)
$atlasModulesPath = [IO.Path]::GetFullPath((Join-Path -Path $windowsDirectory -ChildPath 'AtlasModules'))
$moduleRoot = Join-Path -Path $atlasModulesPath -ChildPath 'Scripts\Modules'
$expectedBrokerTemp = [IO.Path]::GetFullPath((
        Join-Path -Path $env:ProgramData -ChildPath "AtlasOS\Broker\ElevationBootstrap\Transport-$ExpectedRequestId"
    ))
foreach ($tempPath in @($env:TEMP, $env:TMP)) {
    if (-not [string]::Equals(
            [IO.Path]::GetFullPath($tempPath),
            $expectedBrokerTemp,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The broker temp path is not the native bootstrap-owned transport directory.'
    }
}

function New-AtlasInheritedSafeHandle {
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$Value
    )

    if ($Value -eq 0 -or $Value -gt [long]::MaxValue) {
        throw 'Inherited native handle value is outside the supported process handle range.'
    }
    return [Microsoft.Win32.SafeHandles.SafeFileHandle]::new([IntPtr][long]$Value, $true)
}

function New-AtlasInheritedFileStream {
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$Value,

        [Parameter(Mandatory = $true)]
        [IO.FileAccess]$Access
    )

    $safeHandle = New-AtlasInheritedSafeHandle -Value $Value
    try {
        # Disable managed buffering. Frame writes are already complete and bounded at
        # the handle when BeginWrite completes, so no unbounded FlushFileBuffers call is needed.
        $stream = [IO.FileStream]::new($safeHandle, $Access, 1, $false)
        $safeHandle = $null
        return $stream
    }
    finally {
        if ($safeHandle) { $safeHandle.Dispose() }
    }
}

function ConvertTo-AtlasBrokerTokenRecord {
    param($Evidence)

    if ($null -eq $Evidence) { return $null }
    return [pscustomobject][ordered]@{
        userSid                    = [string]$Evidence.UserSid
        trustedInstallerSid        = [string]$Evidence.TrustedInstallerSid
        enabledTrustedInstallerSid = [bool]$Evidence.HasEnabledTrustedInstallerSid
        integrityRid               = [int]$Evidence.IntegrityRid
        sessionId                  = [int]$Evidence.SessionId
        authenticationId           = [string]$Evidence.AuthenticationId
    }
}

$requestStream = $null
$resultStream = $null
$livenessLease = $null
$outerJobLease = $null
$payloadLease = $null
$coreModule = $null
$request = $null
$requestHash = $null
$brokerEvidence = $null
$readinessFramePublished = $false
$brokerCreationFileTime = $null
$resultDocument = $null
$startedUtc = [datetime]::UtcNow
$brokerTimer = [Diagnostics.Stopwatch]::StartNew()
$exitCodeUInt32 = [uint32]1

try {
    $requestStream = New-AtlasInheritedFileStream -Value $RequestHandle -Access Read
    $resultStream = New-AtlasInheritedFileStream -Value $ResultHandle -Access Write
    $livenessLease = New-AtlasInheritedSafeHandle -Value $LivenessHandle
    $outerJobLease = New-AtlasInheritedSafeHandle -Value $OuterJobHandle

    $coreManifest = Join-Path -Path $moduleRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1'
    Import-Module -Name $coreManifest -Force -ErrorAction Stop
    Assert-AtlasPrivilege -Administrator
    $coreModule = Get-Module -Name Atlas.Core -ErrorAction Stop
    & $coreModule {
        Initialize-AtlasTrustedInstallerNativeType
        Initialize-AtlasElevationStorageType
    }

    $requestFrame = & $coreModule {
        param($stream, $requestId)
        Read-AtlasElevationFrame -Stream $stream -ExpectedKind Request `
            -ExpectedRequestId $requestId -TimeoutMilliseconds 30000
    } $requestStream $ExpectedRequestId
    $requestHash = [string]$requestFrame.PayloadSha256
    $request = & $coreModule {
        param($bytes, $hash, $requestId)
        ConvertFrom-AtlasElevationRequestBytes -Bytes $bytes `
            -ExpectedSha256 $hash -ExpectedRequestId $requestId
    } $requestFrame.Payload $requestHash $ExpectedRequestId
    if ($request.requestId -cne $ExpectedRequestId) {
        throw 'The canonical request ID does not equal the authenticated native bootstrap expectation.'
    }

    $nativeRequesterEvidence = [pscustomobject]@{
        ProcessId       = $RequesterProcessId
        CreationFileTime = [long][uint64]::Parse(
            $RequesterCreationFileTime,
            [Globalization.NumberStyles]::HexNumber,
            [Globalization.CultureInfo]::InvariantCulture
        )
        UserSid         = $RequesterSid
        SessionId       = $RequesterSessionId
    }
    $requesterMatches = & $coreModule {
        param($canonicalRequest, $kernelEvidence)
        Test-AtlasElevationRequesterBinding -Request $canonicalRequest -Evidence $kernelEvidence
    } $request $nativeRequesterEvidence
    if (-not $requesterMatches) {
        throw 'Native bootstrap requester evidence does not match the canonical request.'
    }

    # Hold the complete protected Atlas payload before Ready. The medium caller may release
    # its overlapping lease only after this generation-bound Ready record is authenticated.
    $payloadLease = [Atlas.TrustedInstallerProcessNative]::HoldFixedBrokerEntrypoint($atlasModulesPath)

    if ($request.operation -ceq 'Toggle') {
        $togglesManifest = Join-Path -Path $moduleRoot -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1'
        Import-Module -Name $togglesManifest -Force -ErrorAction Stop
        $definition = Get-AtlasToggleDefinition `
            -Name $request.operationData.name `
            -TogglesRoot (Join-Path -Path $atlasModulesPath -ChildPath 'Toggles')
        if ([string]$definition.Name -cne [string]$request.operationData.name) {
            throw "Toggle '$($request.operationData.name)' did not resolve to one exact canonical definition name."
        }
        if (-not $definition.Contains('Elevation') -or
            -not [string]::Equals(
                [string]$definition.Elevation,
                'TrustedInstaller',
                [StringComparison]::Ordinal
            )) {
            throw "Toggle '$($request.operationData.name)' is not declared for exact TrustedInstaller elevation."
        }
        if (@($definition.States.Keys) -cnotcontains [string]$request.operationData.state) {
            throw "Toggle '$($request.operationData.name)' does not declare exact state '$($request.operationData.state)'."
        }
    }

    $brokerEvidence = [Atlas.TrustedInstallerProcessNative]::GetCurrentProcessEvidence()
    $brokerCreationFileTime = ([uint64]$brokerEvidence.CreationFileTime).ToString(
        'X16',
        [Globalization.CultureInfo]::InvariantCulture
    )
    $readyDocument = [pscustomobject][ordered]@{
        protocolVersion             = 2
        requestId                   = $request.requestId
        requestSha256               = $requestHash
        bootstrapProcessId          = $BootstrapProcessId
        bootstrapCreationFileTime   = $BootstrapCreationFileTime
        brokerProcessId             = $brokerEvidence.ProcessId
        brokerCreationFileTime      = $brokerCreationFileTime
    }
    $readyBytes = & $coreModule {
        param($document)
        ConvertTo-AtlasElevationReadyBytes -Ready $document
    } $readyDocument
    & $coreModule {
        param($stream, $requestId, $bytes)
        Write-AtlasElevationFrame -Stream $stream -Kind Ready -RequestId $requestId `
            -Payload $bytes -TimeoutMilliseconds 30000
    } $resultStream $ExpectedRequestId $readyBytes
    $readinessFramePublished = $true

    $remainingMilliseconds = [long]$request.timeoutMilliseconds - $brokerTimer.ElapsedMilliseconds
    if ($remainingMilliseconds -lt 1) {
        throw [TimeoutException]::new('The TrustedInstaller request deadline expired before native process creation.')
    }
    $launchParameters = @{
        Operation                 = $request.operation
        ProtectedWorkingDirectory = $expectedBrokerTemp
        TimeoutMilliseconds       = [int]$remainingMilliseconds
        RequesterProcessId        = $RequesterProcessId
        RequesterCreationFileTime = $nativeRequesterEvidence.CreationFileTime
        RequesterSid              = $RequesterSid
        RequesterSessionId        = $RequesterSessionId
        LivenessPipeHandle        = $livenessLease.DangerousGetHandle()
        OuterJobHandle            = $outerJobLease
    }
    switch ($request.operation) {
        'Toggle' {
            $launchParameters.Name = $request.operationData.name
            $launchParameters.State = $request.operationData.state
            $launchParameters.Silent = [bool]$request.operationData.silent
            $launchParameters.JustContext = [bool]$request.operationData.justContext
            $launchParameters.NoExplorerRestart = [bool]$request.operationData.noExplorerRestart
        }
        'ResetServices' {
            $launchParameters.RestoreSource = $request.operationData.restoreSource
        }
        'SafeModeRecovery' {
            $launchParameters.RecoveryOperationId = $request.operationData.operationId
        }
    }

    $nativeResult = & $coreModule {
        param($parameters)
        Invoke-AtlasTrustedInstallerNativeOperation @parameters
    } $launchParameters
    if ($outerJobLease -and -not $outerJobLease.IsClosed) {
        $outerJobLease.Dispose()
        $outerJobLease = $null
        throw 'The TrustedInstaller launcher returned while retaining the broker outer-job duplicate.'
    }
    $outerJobLease = $null

    $resultDocument = [pscustomobject][ordered]@{
        protocolVersion             = 2
        requestId                   = $request.requestId
        requestSha256               = $requestHash
        requesterSid                = $RequesterSid
        requesterProcessId          = $RequesterProcessId
        requesterCreationFileTime   = $RequesterCreationFileTime
        requesterSessionId          = $RequesterSessionId
        bootstrapProcessId          = $BootstrapProcessId
        bootstrapCreationFileTime   = $BootstrapCreationFileTime
        brokerProcessId             = $brokerEvidence.ProcessId
        brokerCreationFileTime      = $brokerCreationFileTime
        rootProcessId               = $nativeResult.RootProcessId
        sourceProcessId             = $nativeResult.SourceProcessId
        sourceToken                 = ConvertTo-AtlasBrokerTokenRecord $nativeResult.SourceToken
        childToken                  = ConvertTo-AtlasBrokerTokenRecord $nativeResult.ChildToken
        startedUtc                  = $startedUtc.ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'", [Globalization.CultureInfo]::InvariantCulture)
        endedUtc                    = [datetime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'", [Globalization.CultureInfo]::InvariantCulture)
        status                      = 'Completed'
        completionState             = 'Completed'
        exitCodeUInt32              = [uint64]$nativeResult.ExitCodeUInt32
        rootExited                  = [bool]$nativeResult.RootExited
        jobDrained                  = [bool]$nativeResult.JobDrained
        error                       = $null
    }
    $exitCodeUInt32 = [uint32]$nativeResult.ExitCodeUInt32
}
catch {
    if ($readinessFramePublished -and $request -and $brokerEvidence) {
        $errorText = $_.Exception.Message
        if ($errorText.Length -gt 2048) { $errorText = $errorText.Substring(0, 2048) }
        $resultDocument = [pscustomobject][ordered]@{
            protocolVersion             = 2
            requestId                   = $request.requestId
            requestSha256               = $requestHash
            requesterSid                = $RequesterSid
            requesterProcessId          = $RequesterProcessId
            requesterCreationFileTime   = $RequesterCreationFileTime
            requesterSessionId          = $RequesterSessionId
            bootstrapProcessId          = $BootstrapProcessId
            bootstrapCreationFileTime   = $BootstrapCreationFileTime
            brokerProcessId             = $brokerEvidence.ProcessId
            brokerCreationFileTime      = $brokerCreationFileTime
            rootProcessId               = $null
            sourceProcessId             = $null
            sourceToken                 = $null
            childToken                  = $null
            startedUtc                  = $startedUtc.ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'", [Globalization.CultureInfo]::InvariantCulture)
            endedUtc                    = [datetime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'", [Globalization.CultureInfo]::InvariantCulture)
            status                      = 'CompletionUnknown'
            completionState             = 'CompletionUnknown'
            exitCodeUInt32              = $null
            rootExited                  = $false
            jobDrained                  = $false
            error                       = $errorText
        }
    }
}
finally {
    try {
        if ($resultDocument -and $resultStream) {
            $resultBytes = & $coreModule {
                param($document)
                ConvertTo-AtlasElevationResultBytes -Result $document
            } $resultDocument
            & $coreModule {
                param($stream, $requestId, $bytes)
                Write-AtlasElevationFrame -Stream $stream -Kind Result -RequestId $requestId `
                    -Payload $bytes -TimeoutMilliseconds 30000
            } $resultStream $ExpectedRequestId $resultBytes
        }
    }
    catch {
        $exitCodeUInt32 = [uint32]1
    }
    finally {
        if ($payloadLease) {
            $payloadLease.Dispose()
        }
        foreach ($resource in @($outerJobLease, $livenessLease, $resultStream, $requestStream)) {
            if ($resource) { $resource.Dispose() }
        }
        $brokerTimer.Stop()
    }
}

if (-not $resultDocument -or $resultDocument.status -cne 'Completed') {
    exit 1
}
$signedExitCode = [BitConverter]::ToInt32([BitConverter]::GetBytes($exitCodeUInt32), 0)
exit $signedExitCode
