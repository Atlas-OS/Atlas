# Atlas.Core domain: run the inbox Windows PowerShell host as the installing user.
#
# The install state supplies one explicit account SID and Windows session. Atlas asks
# WTS for only that session, verifies the returned token, and never enumerates sessions
# or falls back to whichever account happens to be active.

function Get-AtlasUserProcessCommandLine {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
        [string]$Arguments = ''
    )

    $commandLine = '"{0}"' -f $FilePath
    if (-not [string]::IsNullOrEmpty($Arguments)) {
        $commandLine += " $Arguments"
    }
    return $commandLine
}

function ConvertTo-AtlasRunAsUserSid {
    param([AllowNull()][AllowEmptyString()][string]$Value)

    try {
        $sid = New-Object Security.Principal.SecurityIdentifier($Value)
    }
    catch {
        throw 'The install state does not contain a valid interactive user SID.'
    }
    if (-not $sid.IsAccountSid() -or $sid.Value -cne $Value -or
        $sid.Value -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) {
        throw 'The install state does not contain an interactive account SID.'
    }
    return $sid.Value
}

function Invoke-AtlasBoundUserProcess {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This private helper owns the checked native child launch.'
    )]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string]$Arguments = '',
        [string]$WorkingDirectory,
        [bool]$Wait = $true,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 900,
        [scriptblock]$ContextReader = { Get-AtlasContext },
        [scriptblock]$ProcessLauncher = {
            param($ApplicationPath, $CommandLine, $CurrentDirectory,
                $TimeoutMilliseconds, $UserSid, $UserSessionId)
            Initialize-AtlasNativeType
            [Atlas.Native.UserProcess]::Launch($ApplicationPath, $CommandLine,
                $CurrentDirectory, $TimeoutMilliseconds,
                $UserSessionId, $UserSid)
        }
    )

    $contexts = @(& $ContextReader)
    if ($contexts.Count -ne 1 -or $null -eq $contexts[0]) {
        throw 'Get-AtlasContext must return exactly one install context.'
    }
    $context = $contexts[0]
    if ($context.IsOobe -isnot [bool]) {
        throw 'The install context does not contain a valid OOBE state.'
    }
    if ([bool]$context.IsOobe) {
        return 0
    }
    if (-not $Wait) {
        throw 'Detached installing-user processes are not supported.'
    }

    $userSid = ConvertTo-AtlasRunAsUserSid -Value ([string]$context.InteractiveUserSid)
    $sessionProperty = $context.PSObject.Properties['InteractiveUserSessionId']
    if ($null -eq $sessionProperty -or
        $sessionProperty.Value -isnot [int] -and
        $sessionProperty.Value -isnot [long]) {
        throw 'The install state does not contain an integer interactive user session ID.'
    }
    $sessionId = [long]$sessionProperty.Value
    if ($sessionId -lt 1 -or $sessionId -gt [int]::MaxValue) {
        throw 'The install state contains an invalid interactive user session ID.'
    }

    if ([string]::IsNullOrWhiteSpace([string]$context.WinDir) -or
        -not [IO.Path]::IsPathRooted([string]$context.WinDir)) {
        throw 'The install context does not contain an absolute Windows path.'
    }
    $windowsPath = [IO.Path]::GetFullPath([string]$context.WinDir)
    $expectedPowerShell = [IO.Path]::Combine(
        $windowsPath, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe'
    )
    if (-not [IO.Path]::IsPathRooted($FilePath) -or
        -not [IO.Path]::GetFullPath($FilePath).Equals(
            $expectedPowerShell, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Installing-user launches require the inbox Windows PowerShell host '$expectedPowerShell'."
    }
    if (-not [IO.File]::Exists($expectedPowerShell) -or
        (([IO.File]::GetAttributes($expectedPowerShell) -band
                [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "The inbox Windows PowerShell host is unavailable at '$expectedPowerShell'."
    }

    if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $WorkingDirectory = $windowsPath
    }
    if (-not [IO.Path]::IsPathRooted($WorkingDirectory)) {
        throw 'The installing-user working directory must be absolute.'
    }

    $commandLine = Get-AtlasUserProcessCommandLine -FilePath $expectedPowerShell `
        -Arguments $Arguments
    $results = @(& $ProcessLauncher $expectedPowerShell $commandLine `
            ([IO.Path]::GetFullPath($WorkingDirectory)) `
            ([uint32]($TimeoutSeconds * 1000)) $userSid ([uint32]$sessionId))
    if ($results.Count -ne 1 -or
        ($results[0] -isnot [int] -and $results[0] -isnot [long])) {
        throw 'The installing-user process launcher must return one integer exit code.'
    }
    $exitCode = [long]$results[0]
    if ($exitCode -lt [int]::MinValue -or $exitCode -gt [int]::MaxValue) {
        throw 'The installing-user process launcher returned an invalid exit code.'
    }
    return [int]$exitCode
}

function Invoke-AtlasAsUser {
    <#
    .SYNOPSIS
        Runs inbox Windows PowerShell as the exact installing user and returns its exit code.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This function is the explicit user-process execution boundary.'
    )]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
        [string]$Arguments = '',
        [string]$WorkingDirectory,
        [bool]$Wait = $true,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 900
    )

    if (-not (Test-AtlasSystem)) {
        throw '[privilege] Invoke-AtlasAsUser must run as SYSTEM.'
    }
    return Invoke-AtlasBoundUserProcess -FilePath $FilePath -Arguments $Arguments `
        -WorkingDirectory $WorkingDirectory -Wait:$Wait -TimeoutSeconds $TimeoutSeconds
}
