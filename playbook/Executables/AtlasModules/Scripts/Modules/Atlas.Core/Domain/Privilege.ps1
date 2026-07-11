# Atlas.Core domain: privilege identity and the closed TrustedInstaller operation API.
#
# A SYSTEM token is not automatically a TrustedInstaller token. Atlas treats those as
# distinct contracts, and the public elevation function accepts only typed operations.
# No executable, script path, raw command, scriptblock, or caller-supplied argv crosses
# the UAC boundary.

function Test-AtlasAdmin {
    <#
    .SYNOPSIS
        Returns whether the current process runs with Administrator rights.
    #>
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AtlasCurrentUserSid {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
}

function Test-AtlasSystem {
    <#
    .SYNOPSIS
        Returns whether the current token user is LocalSystem (S-1-5-18).
    #>
    try {
        return (Get-AtlasCurrentUserSid) -eq 'S-1-5-18'
    }
    catch {
        return $false
    }
}

function Test-AtlasTrustedInstaller {
    <#
    .SYNOPSIS
        Returns whether the current token is strict TrustedInstaller.
    .DESCRIPTION
        Strict TrustedInstaller means token user LocalSystem, the dynamically resolved
        NT SERVICE\TrustedInstaller SID present and enabled (not disabled/deny-only), and
        System integrity. Translation or native-token inspection failure returns false.
    #>
    try {
        return [bool](Get-AtlasCurrentTokenEvidence).IsTrustedInstaller
    }
    catch {
        return $false
    }
}

function Assert-AtlasPrivilege {
    <#
    .SYNOPSIS
        Throws when the current process lacks the required privilege. The thrown message
        carries the '[privilege]' marker that Invoke-AtlasInstall.ps1 maps to exit code 2.
    #>
    param(
        [switch]$Administrator,
        [switch]$System,
        [switch]$TrustedInstaller
    )

    if ($TrustedInstaller -and -not (Test-AtlasTrustedInstaller)) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires a TrustedInstaller service token (SYSTEM user, enabled NT SERVICE\TrustedInstaller SID, System integrity); current identity is '$($identity.Name)' ($($identity.User.Value))."
    }

    if ($System -and -not (Test-AtlasSystem)) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires LocalSystem (S-1-5-18); current identity is '$($identity.Name)' ($($identity.User.Value))."
    }

    if ($Administrator -and -not (Test-AtlasAdmin)) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        throw "[privilege] This operation requires Administrator rights; current identity is '$($identity.Name)'."
    }
}

function New-AtlasElevationPipeServer {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private constructor allocates the caller-owned rendezvous pipe and never prompts interactively.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$RequestId
    )

    if ($RequestId -cnotmatch '^[0-9a-f]{32}$' -or
        [string]::Equals($RequestId, ('0' * 32), [StringComparison]::Ordinal)) {
        throw 'The elevation request ID must be nonzero canonical lowercase 32-hex.'
    }
    $pipeName = "AtlasOS.TrustedInstaller.$RequestId"

    Initialize-AtlasElevationStorageType
    $ownerSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $stream = [Atlas.ElevationPipeNative]::CreateFirstPipeServer($pipeName, $ownerSid)
    return [pscustomobject]@{
        Name   = $pipeName
        Stream = $stream
    }
}

function Wait-AtlasElevationPipeConnection {
    param(
        [Parameter(Mandatory = $true)]
        [IO.Pipes.NamedPipeServerStream]$Pipe,

        [Parameter(Mandatory = $true)]
        $BootstrapProcess,

        [ValidateRange(1, 120000)]
        [int]$TimeoutMilliseconds = 30000
    )

    $pending = $Pipe.BeginWaitForConnection($null, $null)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        while (-not $pending.AsyncWaitHandle.WaitOne(100)) {
            if ($BootstrapProcess.HasExited) {
                throw "The native elevation bootstrap exited with code $($BootstrapProcess.GetExitCodeUInt32()) before binding its rendezvous pipe."
            }
            if ($timer.ElapsedMilliseconds -ge $TimeoutMilliseconds) {
                throw 'The native elevation bootstrap did not bind its rendezvous pipe within the bounded connection deadline.'
            }
        }
        $Pipe.EndWaitForConnection($pending)
    }
    finally {
        $pending.AsyncWaitHandle.Close()
        $timer.Stop()
    }
}

function Get-AtlasElevationBootstrapPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AtlasModulesPath
    )

    $fileName = switch ([Atlas.ElevationPipeNative]::GetNativeProcessorArchitecture()) {
        9 { 'AtlasElevationBootstrap-amd64.exe' }
        12 { 'AtlasElevationBootstrap-arm64.exe' }
        default { throw 'Atlas TrustedInstaller elevation supports only native AMD64 and ARM64 Windows.' }
    }
    $path = [IO.Path]::GetFullPath((Join-Path -Path $AtlasModulesPath -ChildPath "Tools\$fileName"))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "The fixed native elevation bootstrap is missing: '$path'."
    }
    return $path
}

function Assert-AtlasElevationBootstrapPeer {
    param(
        [Parameter(Mandatory = $true)]$SpawnedEvidence,
        [Parameter(Mandatory = $true)]$ConnectedEvidence,
        [Parameter(Mandatory = $true)][string]$ExpectedImagePath,
        [Parameter(Mandatory = $true)][int]$ExpectedSessionId
    )

    if ($SpawnedEvidence.ProcessId -ne $ConnectedEvidence.ProcessId -or
        $SpawnedEvidence.CreationFileTime -ne $ConnectedEvidence.CreationFileTime) {
        throw 'The rendezvous pipe client is not the exact ShellExecute bootstrap process generation.'
    }
    $expectedPath = [IO.Path]::GetFullPath($ExpectedImagePath)
    foreach ($evidence in @($SpawnedEvidence, $ConnectedEvidence)) {
        if (-not [string]::Equals(
                [IO.Path]::GetFullPath($evidence.ImagePath),
                $expectedPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw 'The rendezvous pipe client image is not the fixed Atlas elevation bootstrap.'
        }
        if ($evidence.SessionId -ne $ExpectedSessionId) {
            throw 'The rendezvous pipe client is outside the requester session.'
        }
    }
    if ([string]::IsNullOrWhiteSpace($ConnectedEvidence.UserSid) -or
        -not $ConnectedEvidence.IsElevated -or $ConnectedEvidence.IntegrityRid -lt 0x3000) {
        throw 'The rendezvous pipe client does not expose an elevated high-integrity identification token.'
    }
}

function Assert-AtlasElevationReadyBinding {
    param(
        [Parameter(Mandatory = $true)]$Ready,
        [Parameter(Mandatory = $true)]$Envelope,
        [Parameter(Mandatory = $true)]$BootstrapEvidence
    )

    $bootstrapFileTime = ([uint64]$BootstrapEvidence.CreationFileTime).ToString(
        'X16',
        [Globalization.CultureInfo]::InvariantCulture
    )
    if (-not [string]::Equals($Ready.requestId, $Envelope.Request.requestId, [StringComparison]::Ordinal) -or
        -not [string]::Equals($Ready.requestSha256, $Envelope.Sha256, [StringComparison]::Ordinal) -or
        $Ready.bootstrapProcessId -ne $BootstrapEvidence.ProcessId -or
        -not [string]::Equals($Ready.bootstrapCreationFileTime, $bootstrapFileTime, [StringComparison]::Ordinal)) {
        throw 'The authenticated Ready record is not bound to the active request and bootstrap generation.'
    }
}

function Get-AtlasNestedWin32ErrorCode {
    param([Parameter(Mandatory = $true)][Exception]$Exception)

    $current = $Exception
    while ($null -ne $current) {
        if ($current -is [ComponentModel.Win32Exception]) {
            return [int]$current.NativeErrorCode
        }
        $current = $current.InnerException
    }
    return 0
}

function New-AtlasCallerElevationResult {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This pure constructor returns an in-memory structured failure result.'
    )]
    param(
        [Parameter(Mandatory = $true)]$Envelope,
        [Parameter(Mandatory = $true)]$RequesterEvidence,
        [Parameter(Mandatory = $true)]
        [ValidateSet('ConsentDenied', 'NotStarted', 'CompletionUnknown')]
        [string]$Status,
        [Parameter(Mandatory = $true)]
        [ValidateSet('NotStarted', 'CompletionUnknown')]
        [string]$CompletionState,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ErrorMessage,
        [Nullable[int]]$BootstrapProcessId,
        [Nullable[long]]$BootstrapCreationFileTime,
        [Nullable[int]]$BrokerProcessId,
        [Nullable[long]]$BrokerCreationFileTime
    )

    if (@('ConsentDenied', 'NotStarted', 'CompletionUnknown') -cnotcontains $Status) {
        throw "Caller elevation status '$Status' is not canonical."
    }
    if (@('NotStarted', 'CompletionUnknown') -cnotcontains $CompletionState) {
        throw "Caller elevation completion state '$CompletionState' is not canonical."
    }
    $validPair = ($Status -ceq 'ConsentDenied' -and $CompletionState -ceq 'NotStarted') -or
        ($Status -ceq 'NotStarted' -and $CompletionState -ceq 'NotStarted') -or
        ($Status -ceq 'CompletionUnknown' -and $CompletionState -ceq 'CompletionUnknown')
    if (-not $validPair) {
        throw "Caller elevation status '$Status' cannot pair with completion state '$CompletionState'."
    }
    if ([string]::IsNullOrWhiteSpace($ErrorMessage)) {
        throw 'Caller elevation error text must contain non-whitespace text.'
    }
    if ($ErrorMessage.Length -gt 2048) {
        $ErrorMessage = $ErrorMessage.Substring(0, 2048)
    }
    $timestamp = [datetime]::UtcNow.ToString(
        "yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'",
        [Globalization.CultureInfo]::InvariantCulture
    )
    $result = [pscustomobject][ordered]@{
        protocolVersion           = 2
        requestId                 = $Envelope.Request.requestId
        requestSha256             = $Envelope.Sha256
        requesterSid              = $RequesterEvidence.UserSid
        requesterProcessId        = $RequesterEvidence.ProcessId
        requesterCreationFileTime = ([uint64]$RequesterEvidence.CreationFileTime).ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
        requesterSessionId        = $RequesterEvidence.SessionId
        bootstrapProcessId        = if ($null -eq $BootstrapProcessId) { $null } else { [int]$BootstrapProcessId }
        bootstrapCreationFileTime = if ($null -eq $BootstrapCreationFileTime) {
            $null
        }
        else {
            ([uint64][long]$BootstrapCreationFileTime).ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
        }
        brokerProcessId           = if ($null -eq $BrokerProcessId) { $null } else { [int]$BrokerProcessId }
        brokerCreationFileTime    = if ($null -eq $BrokerCreationFileTime) {
            $null
        }
        else {
            ([uint64][long]$BrokerCreationFileTime).ToString('X16', [Globalization.CultureInfo]::InvariantCulture)
        }
        rootProcessId             = $null
        sourceProcessId           = $null
        sourceToken               = $null
        childToken                = $null
        startedUtc                = $timestamp
        endedUtc                  = $timestamp
        status                    = $Status
        completionState           = $CompletionState
        exitCodeUInt32            = $null
        rootExited                = $false
        jobDrained                = $false
        error                     = $ErrorMessage
    }
    return ConvertTo-AtlasCanonicalElevationResult -Result $result
}

function Invoke-AtlasTrustedInstaller {
    <#
    .SYNOPSIS
        Runs one closed, noninteractive Atlas operation with strict TrustedInstaller authority.
    .DESCRIPTION
        A fixed native bootstrap binds to this exact process through a caller-owned
        first-instance pipe, relays only framed canonical data to the fixed broker,
        validates the SCM TrustedInstaller process and token, contains the complete child
        tree in kill-on-close jobs, and returns a generation-bound structured result. It never
        accepts an executable, script path, command line, scriptblock, or raw argv.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Toggle', 'ResetServices', 'SafeModeRecovery')]
        [string]$Operation,

        [string]$Name,
        [string]$State,
        [bool]$Silent = $true,
        [switch]$JustContext,
        [switch]$NoExplorerRestart,

        [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
        [string]$RestoreSource,

        [ValidatePattern('^[a-f0-9]{32}$')]
        [string]$RecoveryOperationId,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 900
    )

    if (@('Toggle', 'ResetServices', 'SafeModeRecovery') -cnotcontains $Operation) {
        throw "TrustedInstaller operation '$Operation' is not canonical."
    }
    $operationParameterAllowlist = @{
        Toggle           = @('Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart')
        ResetServices    = @('RestoreSource')
        SafeModeRecovery = @('RecoveryOperationId')
    }
    $allOperationParameters = @(
        'Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart',
        'RestoreSource', 'RecoveryOperationId'
    )
    foreach ($operationParameter in $allOperationParameters) {
        if ($PSBoundParameters.ContainsKey($operationParameter) -and
            $operationParameter -notin $operationParameterAllowlist[$Operation]) {
            throw "$Operation does not accept the operation input '-$operationParameter'."
        }
    }

    switch ($Operation) {
        'Toggle' {
            if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($State)) {
                throw 'Toggle requires typed -Name and -State values.'
            }
            if (-not $Silent) {
                throw 'The initial TrustedInstaller Toggle operation is noninteractive and requires -Silent:$true.'
            }
            $operationData = [pscustomobject][ordered]@{
                name              = $Name
                state             = $State
                silent            = $true
                justContext       = [bool]$JustContext
                noExplorerRestart = [bool]$NoExplorerRestart
            }
        }
        'ResetServices' {
            if ([string]::IsNullOrWhiteSpace($RestoreSource)) {
                throw 'ResetServices requires a typed -RestoreSource value.'
            }
            $operationData = [pscustomobject][ordered]@{ restoreSource = $RestoreSource }
        }
        'SafeModeRecovery' {
            if ([string]::IsNullOrWhiteSpace($RecoveryOperationId)) {
                throw 'SafeModeRecovery requires -RecoveryOperationId.'
            }
            $operationData = [pscustomobject][ordered]@{
                operationId = $RecoveryOperationId
            }
        }
    }

    # Close the operation schema before allocating a kernel pipe object.
    $operationData = ConvertTo-AtlasCanonicalOperationData -Operation $Operation -OperationData $operationData

    Initialize-AtlasTrustedInstallerNativeType
    Initialize-AtlasElevationStorageType
    $requesterEvidence = [Atlas.TrustedInstallerProcessNative]::GetCurrentProcessEvidence()

    do {
        $requestId = [guid]::NewGuid().ToString('N').ToLowerInvariant()
    } while ([string]::Equals($requestId, ('0' * 32), [StringComparison]::Ordinal))
    if ($requestId -cnotmatch '^[0-9a-f]{32}$') {
        throw 'The generated elevation request ID is outside the canonical lowercase 32-hex schema.'
    }

    $pipeBinding = New-AtlasElevationPipeServer -RequestId $requestId
    $pipe = $pipeBinding.Stream
    try {
        $envelope = New-AtlasElevationRequestEnvelope `
            -Operation $Operation `
            -OperationData $operationData `
            -RequesterSid $requesterEvidence.UserSid `
            -RequesterProcessId $requesterEvidence.ProcessId `
            -RequesterCreationFileTime $requesterEvidence.CreationFileTime `
            -RequesterSessionId $requesterEvidence.SessionId `
            -TimeoutMilliseconds ($TimeoutSeconds * 1000) `
            -RequestId $requestId
    }
    catch {
        $pipe.Dispose()
        throw
    }

    $heldBroker = $null
    $bootstrapProcess = $null
    $bootstrapEvidence = $null
    $ready = $null
    $requestTransmissionStarted = $false
    # Native cancellation can spend up to five seconds joining synchronous I/O and
    # fifteen seconds draining the containment job before acknowledging pipe closure.
    $cancellationAcknowledgeTimeoutMilliseconds = 30000
    # After Result relay the native side may still spend ten seconds observing broker
    # exit, fifteen seconds draining the outer job, and up to five seconds joining the
    # permanent input monitor before bounded local cleanup. Leave explicit scheduling
    # and cleanup slack so an in-contract bootstrap is never terminated as hung.
    $postTerminalBootstrapExitTimeoutMilliseconds = 45000
    try {
        $context = Get-AtlasContext
        $bootstrapPath = Get-AtlasElevationBootstrapPath -AtlasModulesPath $context.AtlasModulesPath
        $workingDirectory = [IO.Path]::GetFullPath((Join-Path -Path $context.WinDir -ChildPath 'System32'))
        $heldBroker = [Atlas.TrustedInstallerProcessNative]::HoldFixedBrokerEntrypoint($context.AtlasModulesPath)
        try {
            $bootstrapProcess = [Atlas.ElevationPipeNative]::StartElevationBootstrap(
                $bootstrapPath,
                $requestId,
                $workingDirectory
            )
        }
        catch {
            if ((Get-AtlasNestedWin32ErrorCode -Exception $_.Exception) -eq 1223) {
                return New-AtlasCallerElevationResult -Envelope $envelope -RequesterEvidence $requesterEvidence `
                    -Status ConsentDenied -CompletionState NotStarted `
                    -ErrorMessage 'The user declined TrustedInstaller elevation.'
            }
            return New-AtlasCallerElevationResult -Envelope $envelope -RequesterEvidence $requesterEvidence `
                -Status NotStarted -CompletionState NotStarted `
                -ErrorMessage $_.Exception.Message
        }

        Wait-AtlasElevationPipeConnection -Pipe $pipe -BootstrapProcess $bootstrapProcess
        $bootstrapEvidence = [Atlas.ElevationPipeNative]::GetProcessHandleEvidence($bootstrapProcess.ProcessHandle)
        $connectedEvidence = [Atlas.ElevationPipeNative]::GetConnectedClientEvidence(
            $pipe.SafePipeHandle.DangerousGetHandle()
        )
        Assert-AtlasElevationBootstrapPeer `
            -SpawnedEvidence $bootstrapEvidence `
            -ConnectedEvidence $connectedEvidence `
            -ExpectedImagePath $bootstrapPath `
            -ExpectedSessionId $requesterEvidence.SessionId

        $requestTransmissionStarted = $true
        Write-AtlasElevationFrame -Stream $pipe -Kind Request -RequestId $requestId `
            -Payload $envelope.Bytes -TimeoutMilliseconds 30000

        $readyFrame = Read-AtlasElevationFrame -Stream $pipe -ExpectedKind Ready `
            -ExpectedRequestId $requestId -TimeoutMilliseconds 30000
        $readyCandidate = ConvertFrom-AtlasElevationReadyBytes -Bytes $readyFrame.Payload
        Assert-AtlasElevationReadyBinding `
            -Ready $readyCandidate -Envelope $envelope -BootstrapEvidence $bootstrapEvidence
        $ready = $readyCandidate
        $heldBroker.Dispose()
        $heldBroker = $null

        $resultWaitMilliseconds = [Math]::Min(86460000, (($TimeoutSeconds * 1000) + 60000))
        $resultFrame = Read-AtlasElevationFrame -Stream $pipe -ExpectedKind Result `
            -ExpectedRequestId $requestId -TimeoutMilliseconds $resultWaitMilliseconds
        $result = ConvertFrom-AtlasElevationResultBytes -Bytes $resultFrame.Payload
        if (-not $bootstrapProcess.WaitForExit($postTerminalBootstrapExitTimeoutMilliseconds)) {
            throw 'The native elevation bootstrap did not exit after relaying its terminal result.'
        }
        $bootstrapExitCodeUInt32 = $bootstrapProcess.GetExitCodeUInt32()
        Assert-AtlasElevationStreamEof -Stream $pipe -TimeoutMilliseconds 10000
        $brokerCreationFileTime = [uint64]::Parse(
            $ready.brokerCreationFileTime,
            [Globalization.NumberStyles]::HexNumber,
            [Globalization.CultureInfo]::InvariantCulture
        )
        return Test-AtlasElevationResultBinding `
            -Result $result `
            -RequestId $envelope.Request.requestId `
            -RequestSha256 $envelope.Sha256 `
            -RequesterSid $requesterEvidence.UserSid `
            -RequesterProcessId $requesterEvidence.ProcessId `
            -RequesterCreationFileTime $requesterEvidence.CreationFileTime `
            -RequesterSessionId $requesterEvidence.SessionId `
            -BootstrapProcessId $bootstrapEvidence.ProcessId `
            -BootstrapCreationFileTime $bootstrapEvidence.CreationFileTime `
            -BrokerProcessId $ready.brokerProcessId `
            -BrokerCreationFileTime ([long]$brokerCreationFileTime) `
            -BootstrapExitCodeUInt32 $bootstrapExitCodeUInt32
    }
    catch {
        $protocolError = $_.Exception.Message
        $containmentError = $null
        if ($bootstrapProcess) {
            if ($pipe) {
                $pipe.Dispose()
                $pipe = $null
            }
            try {
                if (-not $bootstrapProcess.WaitForExit($cancellationAcknowledgeTimeoutMilliseconds)) {
                    $cancelExitCode = [uint32]::Parse(
                        'C000013A',
                        [Globalization.NumberStyles]::HexNumber,
                        [Globalization.CultureInfo]::InvariantCulture
                    )
                    $bootstrapProcess.Terminate($cancelExitCode)
                    if (-not $bootstrapProcess.WaitForExit(5000)) {
                        throw 'The native bootstrap did not exit after exact-handle termination.'
                    }
                }
            }
            catch {
                $containmentError = $_.Exception.Message
            }
            $status = if ($requestTransmissionStarted) { 'CompletionUnknown' } else { 'NotStarted' }
            $completionState = if ($requestTransmissionStarted) { 'CompletionUnknown' } else { 'NotStarted' }
            $brokerCreation = $null
            if ($ready) {
                $brokerCreation = [long][uint64]::Parse(
                    $ready.brokerCreationFileTime,
                    [Globalization.NumberStyles]::HexNumber,
                    [Globalization.CultureInfo]::InvariantCulture
                )
            }
            return New-AtlasCallerElevationResult -Envelope $envelope -RequesterEvidence $requesterEvidence `
                -Status $status -CompletionState $completionState `
                -ErrorMessage $(if ($containmentError) {
                    "$protocolError Bootstrap containment also failed: $containmentError"
                } else { $protocolError }) `
                -BootstrapProcessId $(if ($bootstrapEvidence) { $bootstrapEvidence.ProcessId } else { $null }) `
                -BootstrapCreationFileTime $(if ($bootstrapEvidence) { $bootstrapEvidence.CreationFileTime } else { $null }) `
                -BrokerProcessId $(if ($ready) { $ready.brokerProcessId } else { $null }) `
                -BrokerCreationFileTime $brokerCreation
        }
        return New-AtlasCallerElevationResult -Envelope $envelope -RequesterEvidence $requesterEvidence `
            -Status NotStarted -CompletionState NotStarted `
            -ErrorMessage $protocolError
    }
    finally {
        if ($heldBroker) {
            $heldBroker.Dispose()
        }
        if ($pipe) {
            $pipe.Dispose()
        }
        if ($bootstrapProcess) {
            $bootstrapProcess.Dispose()
        }
    }
}
