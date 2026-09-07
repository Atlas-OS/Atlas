# Atlas.Core domain: logging and phase lifecycle.
#
# The one-shot orchestrator owns install sequencing, while exact-user helpers and other
# privilege contexts can also write these files. A named mutex serializes their appends.

$script:AtlasCurrentPhase = $null
$script:AtlasTranscriptActive = $false
# Diagnostic echoes every log line to the console as written to the file, which silent
# runs, replay, installation and the TrustedInstaller broker rely on for captured
# output. Interactive entry points switch to Interactive: Info stays in the file,
# Warning and Error appear in the presentation vocabulary.
$script:AtlasLogConsoleStyle = 'Diagnostic'

function Set-AtlasLogConsoleStyle {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Diagnostic', 'Interactive')]
        [string]$Style
    )

    $script:AtlasLogConsoleStyle = $Style
}

function Get-AtlasLogConsoleStyle {
    return $script:AtlasLogConsoleStyle
}

function Get-AtlasInstallLogDirectory {
    # Medium-integrity desktop actions cannot append to the protected machine log.
    # Keep their diagnostics in their own profile; elevated callers never follow it.
    $logsPath = if (Test-AtlasAdmin) {
        (Get-AtlasContext).LogsPath
    }
    else {
        Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'AtlasOS\Logs'
    }
    $installLogPath = Join-Path -Path $logsPath -ChildPath 'install'
    if (-not (Test-Path -LiteralPath $installLogPath -PathType Container)) {
        New-Item -Path $installLogPath -ItemType Directory -Force | Out-Null
    }

    return $installLogPath
}

function Get-AtlasInstallLogPath {
    <#
    .SYNOPSIS
        The shared install log this process appends to, for pointing a user at details.
    #>
    return Join-Path -Path (Get-AtlasInstallLogDirectory) -ChildPath 'atlas-install.log'
}

function Write-AtlasLogFile {
    param(
        [Parameter(Mandatory = $true)][string]$FileName,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $logPath = Join-Path -Path (Get-AtlasInstallLogDirectory) -ChildPath $FileName

    $mutexName = if (Test-AtlasAdmin) {
        'Global\AtlasInstallLog'
    }
    else {
        'Local\AtlasUserLog-' + (Get-AtlasCurrentUserSid)
    }
    $mutex = New-Object System.Threading.Mutex($false, $mutexName)
    $acquired = $false
    try {
        try {
            $acquired = $mutex.WaitOne(5000)
        }
        catch [System.Threading.AbandonedMutexException] {
            $acquired = $true
        }

        # Losing append serialization beats losing the log line, so a lock timeout
        # degrades to an unserialized append with a warning.
        if (-not $acquired) {
            Write-Warning "Timed out acquiring the Atlas install log lock; appending to '$FileName' without serialization." `
                -WarningAction Continue
        }
        [System.IO.File]::AppendAllText($logPath, $Line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
    }
    finally {
        if ($acquired) {
            $mutex.ReleaseMutex()
        }
        $mutex.Dispose()
    }
}

function Write-AtlasLog {
    <#
    .SYNOPSIS
        Writes a structured line to the shared install log (and warnings summary for
        Warning/Error), echoing it to the current console.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        # The interactive presentation already shows this text; keep it out of the
        # console in Interactive style. Diagnostic style ignores the switch.
        [switch]$NoConsole
    )

    $phaseLabel = if ($script:AtlasCurrentPhase) { $script:AtlasCurrentPhase } else { '-' }
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$phaseLabel] [$($Level.ToUpperInvariant())] $Message"

    if ($ErrorRecord) {
        $line += " | $($ErrorRecord.InvocationInfo.PositionMessage -replace '\r?\n', ' ')"
    }

    try {
        Write-AtlasLogFile -FileName 'atlas-install.log' -Line $line
        if ($Level -ne 'Info') {
            Write-AtlasLogFile -FileName 'warnings-summary.log' -Line $line
        }
    }
    catch {
        # Exact-user helpers intentionally run with ErrorActionPreference=Stop and may
        # lack write access to the shared system log. Diagnostic fallback must never
        # turn an already-handled best-effort operation into a fatal child exit.
        Write-Warning "Failed to write to the Atlas install log: $($_.Exception.Message)" `
            -WarningAction Continue
    }

    if ($script:AtlasLogConsoleStyle -ceq 'Interactive') {
        if (-not $NoConsole) {
            switch ($Level) {
                'Warning' { Write-AtlasWarning -Text $Message }
                'Error' { Write-AtlasFailure -Text $Message }
            }
        }
        return
    }

    switch ($Level) {
        'Info' { Write-Host $line }
        'Warning' { Write-Host $line -ForegroundColor Yellow }
        'Error' { Write-Host $line -ForegroundColor Red }
    }
}

function Start-AtlasPhase {
    <#
    .SYNOPSIS
        Begins a named install phase: starts a per-process transcript and logs the
        execution context (user, privilege, architecture, build).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Phase,

        [string]$Category
    )

    $script:AtlasCurrentPhase = if ($Category) { "$Phase/$Category" } else { $Phase }

    $transcriptName = '{0:yyyyMMdd-HHmmss}-{1}-{2}.log' -f (Get-Date), ($script:AtlasCurrentPhase -replace '[\\/]', '-'), $env:USERNAME
    $transcriptPath = Join-Path -Path (Get-AtlasInstallLogDirectory) -ChildPath $transcriptName

    try {
        Start-Transcript -Path $transcriptPath -ErrorAction Stop | Out-Null
        $script:AtlasTranscriptActive = $true
    }
    catch {
        $script:AtlasTranscriptActive = $false
        Write-Warning "Couldn't start a transcript for phase '$Phase': $($_.Exception.Message)" `
            -WarningAction Continue
    }

    $context = Get-AtlasContext
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    Write-AtlasLog -Message "Phase started (user: $($identity.Name), sid: $($identity.User.Value), arm64: $($context.IsArm64), build: $($context.WindowsBuild), upgrade: $($context.IsUpgrade), oobe: $($context.IsOobe))"
}

function Stop-AtlasPhase {
    <#
    .SYNOPSIS
        Ends the current install phase and stops its transcript. -Failed records the
        phase outcome in the log.
    #>
    param([switch]$Failed)

    if ($script:AtlasCurrentPhase) {
        if ($Failed) {
            Write-AtlasLog -Level Warning -Message 'Phase failed'
        }
        else {
            Write-AtlasLog -Message 'Phase finished'
        }
    }

    if ($script:AtlasTranscriptActive) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            $null = $_
        }
        $script:AtlasTranscriptActive = $false
    }

    $script:AtlasCurrentPhase = $null
}
