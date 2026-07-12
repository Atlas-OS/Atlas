# Atlas.Core domain: checked native-process execution without a visible window.
#
# A Windows process receives one command-line string, not an argv array. PowerShell
# 5.1 and 7 also join Start-Process -ArgumentList values without preserving their
# boundaries. Keep argv as strings until this file serializes it with the Windows C
# runtime rules, then launch the caller's explicit executable directly.

function ConvertTo-AtlasQuotedWindowsArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Argument
    )

    if ($Argument.IndexOf([char]0) -ge 0) {
        throw 'A native-process argument cannot contain NUL.'
    }
    if ($Argument.Length -eq 0) {
        return '""'
    }
    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    $result = New-Object Text.StringBuilder
    [void]$result.Append('"')
    $backslashes = 0

    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }

        if ($character -eq '"') {
            # Backslashes before a quote are doubled, then the quote is escaped.
            [void]$result.Append('\', (($backslashes * 2) + 1))
            [void]$result.Append('"')
        }
        else {
            if ($backslashes -gt 0) {
                [void]$result.Append('\', $backslashes)
            }
            [void]$result.Append($character)
        }
        $backslashes = 0
    }

    # A closing quote would otherwise consume trailing backslashes.
    if ($backslashes -gt 0) {
        [void]$result.Append('\', ($backslashes * 2))
    }
    [void]$result.Append('"')
    return $result.ToString()
}

function ConvertTo-AtlasWindowsArgumentString {
    <#
    .SYNOPSIS
        Serializes exact argv elements for a Windows CreateProcess command line.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [object[]]$ArgumentList
    )

    $encoded = New-Object 'System.Collections.Generic.List[string]'
    foreach ($argument in $ArgumentList) {
        if ($null -eq $argument) {
            throw 'A native-process argument cannot be null.'
        }
        if ($argument -isnot [string]) {
            throw 'A native-process argument must be a string.'
        }
        $encoded.Add((ConvertTo-AtlasQuotedWindowsArgument -Argument $argument))
    }

    $commandLine = [string]::Join(' ', $encoded.ToArray())
    if ($commandLine.Length -gt 32766) {
        throw 'The native-process argument string exceeds 32,766 characters.'
    }
    return $commandLine
}

function Resolve-AtlasProcessExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    if ([string]::IsNullOrWhiteSpace($FilePath) -or
        $FilePath.IndexOf([char]0) -ge 0 -or
        $FilePath -notmatch '^(?:[A-Za-z]:[\\/]|\\\\)') {
        throw 'Invoke-AtlasHiddenProcess requires an explicit absolute executable path.'
    }

    $resolvedPath = [IO.Path]::GetFullPath($FilePath)
    if (-not [IO.File]::Exists($resolvedPath)) {
        throw "The executable '$resolvedPath' does not exist or is not a file."
    }
    return $resolvedPath
}

function Invoke-AtlasHiddenProcess {
    <#
    .SYNOPSIS
        Runs one explicit executable invisibly and checks its exit code.
    .PARAMETER ArgumentList
        Exact argv elements. Do not pass a pre-serialized command-line string.
    .PARAMETER Wait
        Required because unchecked detached launches are outside this helper's contract.
    .PARAMETER AllowedExitCode
        The complete accepted exit-code set. The default is zero.
    .PARAMETER CaptureOutput
        Includes the child's standard output and error in the returned object. Output is
        always collected so a checked failure can include useful diagnostics.
    #>
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [object[]]$ArgumentList = @(),

        [Parameter(Mandatory = $true)]
        [switch]$Wait,

        [ValidateNotNullOrEmpty()]
        [int[]]$AllowedExitCode = @(0),

        [ValidateRange(0, 86400)]
        [int]$TimeoutSeconds = 0,

        [switch]$CaptureOutput
    )

    if (-not $Wait) {
        throw 'Invoke-AtlasHiddenProcess supports only waited launches.'
    }

    $resolvedFile = Resolve-AtlasProcessExecutable -FilePath $FilePath
    $encodedArguments = ConvertTo-AtlasWindowsArgumentString -ArgumentList $ArgumentList
    if (($resolvedFile.Length + $encodedArguments.Length + 3) -gt 32766) {
        throw 'The executable and argument string exceed the Windows command-line limit.'
    }

    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = $resolvedFile
    $startInfo.Arguments = $encodedArguments
    $startInfo.WorkingDirectory = [IO.Path]::GetDirectoryName($resolvedFile)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = $null
    try {
        $process = New-Object Diagnostics.Process
        $process.StartInfo = $startInfo
        if (-not $process.Start()) {
            throw "Could not start executable '$resolvedFile'."
        }

        # Begin both reads before waiting so neither child pipe can fill and deadlock.
        $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
        $standardErrorTask = $process.StandardError.ReadToEndAsync()
        $completed = if ($TimeoutSeconds -eq 0) {
            $process.WaitForExit()
            $true
        }
        else {
            $process.WaitForExit($TimeoutSeconds * 1000)
        }
        if (-not $completed) {
            try {
                $process.Kill()
                $process.WaitForExit()
            }
            catch {
                throw [TimeoutException]::new(
                    "'$resolvedFile' exceeded its $TimeoutSeconds-second timeout and could not be terminated: $($_.Exception.Message)",
                    $_.Exception
                )
            }
            throw [TimeoutException]::new(
                "'$resolvedFile' exceeded its $TimeoutSeconds-second timeout and was terminated."
            )
        }
        $standardOutput = $standardOutputTask.Result
        $standardError = $standardErrorTask.Result
        $exitCode = [int]$process.ExitCode

        if ($AllowedExitCode -notcontains $exitCode) {
            $message = "'$resolvedFile' exited with disallowed code $exitCode."
            $diagnostic = @($standardOutput, $standardError) |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
            if ($diagnostic.Count -gt 0) {
                $message += ' Output: ' + (($diagnostic -join ' ').Trim())
            }
            throw $message
        }

        return [pscustomobject]@{
            ExitCode       = $exitCode
            StandardOutput = if ($CaptureOutput) { $standardOutput } else { $null }
            StandardError  = if ($CaptureOutput) { $standardError } else { $null }
        }
    }
    finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}
