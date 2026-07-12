function Invoke-AtlasToggleNativeCommand {
    <#
    .SYNOPSIS
        Invokes a native executable with an explicit exit-code contract.

    .DESCRIPTION
        Toggle actions run in Windows PowerShell 5.1, where a non-zero native
        exit code does not become a terminating PowerShell error. This helper
        therefore requires callers to provide a fully qualified executable
        path, a typed argument array, and the complete set of accepted exit
        codes for that operation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [ValidateNotNull()]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateCount(1, 256)]
        [int[]]$AllowedExitCodes,

        [switch]$PassThru
    )

    $isDriveQualified = $FilePath -match '^[A-Za-z]:[\\/]'
    $isUncPath = $FilePath -match '^[\\/]{2}[^\\/]+[\\/][^\\/]+(?:[\\/]|$)'
    if (-not ($isDriveQualified -or $isUncPath)) {
        throw "Native executable path '$FilePath' must be fully qualified."
    }

    $resolvedFilePath = [IO.Path]::GetFullPath($FilePath)
    if (-not [IO.File]::Exists($resolvedFilePath)) {
        throw "Native executable '$resolvedFilePath' does not exist."
    }

    $allowedExitCodeSet = @{}
    foreach ($allowedExitCode in $AllowedExitCodes) {
        if ($allowedExitCodeSet.ContainsKey($allowedExitCode)) {
            throw "AllowedExitCodes contains the duplicate exit code $allowedExitCode."
        }
        $allowedExitCodeSet[$allowedExitCode] = $true
    }

    # Native stderr becomes a PowerShell error record when it is redirected.
    # Keep that conversion non-terminating locally so the explicitly declared
    # native exit-code contract remains authoritative even when the toggle
    # engine itself runs with ErrorActionPreference = Stop.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $nativeOutput = & $resolvedFilePath @ArgumentList 2>&1
        $nativeExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($null -eq $nativeExitCode) {
        throw "Native executable '$resolvedFilePath' did not report an exit code."
    }

    if (-not $allowedExitCodeSet.ContainsKey([int]$nativeExitCode)) {
        $allowedText = (@($AllowedExitCodes | Sort-Object) -join ', ')
        $diagnosticText = (@($nativeOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine).Trim()
        $message = "Native executable '$resolvedFilePath' exited with code $nativeExitCode; allowed exit codes: $allowedText."
        if (-not [string]::IsNullOrWhiteSpace($diagnosticText)) {
            $message += " Output: $diagnosticText"
        }
        throw $message
    }

    if ($PassThru) {
        return [pscustomobject]@{
            FilePath = $resolvedFilePath
            ExitCode = [int]$nativeExitCode
            Output   = [string[]]@($nativeOutput | ForEach-Object { [string]$_ })
        }
    }

    $nativeOutput
}
