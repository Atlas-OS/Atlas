[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions',
    '',
    Justification = 'The caller explicitly selects the load or unload lifecycle transition.'
)]
param()

Set-StrictMode -Version 3.0

function Invoke-AtlasDefaultHiveRegistryProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RegExePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [ValidateRange(1000, 120000)][int]$TimeoutMilliseconds = 30000
    )

    if (-not (Test-Path -LiteralPath $RegExePath -PathType Leaf)) {
        throw "Registry executable was not found: '$RegExePath'."
    }
    foreach ($argument in $Arguments) {
        if ($argument.IndexOf('"') -ge 0) {
            throw 'Registry process arguments must not contain double quotes.'
        }
    }

    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = $RegExePath
    $startInfo.Arguments = (($Arguments | ForEach-Object { '"' + $_ + '"' }) -join ' ')
    $startInfo.WorkingDirectory = Split-Path -Parent $RegExePath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Failed to start '$RegExePath'."
        }
        # Drain both redirected streams concurrently. Reading either stream
        # synchronously before WaitForExit can deadlock when the other pipe fills,
        # and it makes the timeout ineffective while ReadToEnd is blocked.
        $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
        $standardErrorTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill()
                }
                $process.WaitForExit()
                # Observe both asynchronous drains before disposing their streams.
                $null = $standardOutputTask.GetAwaiter().GetResult()
                $null = $standardErrorTask.GetAwaiter().GetResult()
            }
            catch {
                # Preserve the timeout as the authoritative failure. Disposal in
                # finally remains the last-resort handle cleanup if termination races.
                $null = $_
            }
            throw "Registry process timed out after $TimeoutMilliseconds ms."
        }
        $standardOutput = $standardOutputTask.GetAwaiter().GetResult()
        $standardError = $standardErrorTask.GetAwaiter().GetResult()
        return [pscustomobject][ordered]@{
            ExitCode       = [int]$process.ExitCode
            StandardOutput = $standardOutput
            StandardError  = $standardError
        }
    }
    finally {
        $process.Dispose()
    }
}

function Test-AtlasDefaultUserHiveMounted {
    [CmdletBinding()]
    [OutputType([bool])]
    param([string]$MountName = 'Atlas_DefaultUser')

    $key = [Microsoft.Win32.Registry]::Users.OpenSubKey($MountName, $false)
    if ($null -eq $key) {
        return $false
    }
    $key.Dispose()
    return $true
}

function Set-AtlasDefaultUserHiveState {
    <#
    .SYNOPSIS
        Reconciles the Atlas default-user hive mount to an explicit Loaded/Unloaded state.
    .DESCRIPTION
        Loaded always unloads a pre-existing mount first, then mounts the configured
        Default profile hive. This safely recovers an interrupted prior Atlas run and
        avoids accepting an unrelated key or wrong hive at the shared mount name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'RegExePath',
        Justification = 'Used by the nested checked-registry invocation closure.'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'NativeInvoker',
        Justification = 'Used by the nested checked-registry invocation closure.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Loaded', 'Unloaded')]
        [string]$State,

        [Parameter(Mandatory = $true)]
        [string]$RegExePath,

        [Parameter(Mandatory = $true)]
        [string]$HivePath,

        [string]$MountName = 'Atlas_DefaultUser',

        [scriptblock]$MountTester = {
            param([string]$Name)
            Test-AtlasDefaultUserHiveMounted -MountName $Name
        },

        [scriptblock]$NativeInvoker = {
            param([string]$Executable, [string[]]$NativeArguments)
            Invoke-AtlasDefaultHiveRegistryProcess -RegExePath $Executable -Arguments $NativeArguments
        }
    )

    if ($MountName -cne 'Atlas_DefaultUser') {
        throw "Atlas only supports the fixed default-user mount name 'Atlas_DefaultUser'."
    }

    $target = "HKU\$MountName"
    $invokeRegistry = {
        param([string[]]$NativeArguments, [string]$Operation)

        $result = & $NativeInvoker $RegExePath $NativeArguments
        if ($null -eq $result -or $null -eq $result.PSObject.Properties['ExitCode']) {
            throw "Registry $Operation returned no exit-code result."
        }
        if ([int]$result.ExitCode -ne 0) {
            $details = @([string]$result.StandardError, [string]$result.StandardOutput) |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $detailText = ($details -join ' ').Trim()
            if ($detailText.Length -gt 2048) {
                $detailText = $detailText.Substring(0, 2048)
            }
            throw "Registry $Operation failed with exit code $($result.ExitCode): $detailText"
        }
    }

    $mounted = [bool](& $MountTester $MountName)
    if ($mounted) {
        # A finalizer-pending RegistryKey handle into the mount fails the unload, so
        # collect managed handles first and retry briefly before treating it as fatal.
        $unloadAttempt = 0
        while ($true) {
            $unloadAttempt++
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            try {
                & $invokeRegistry -NativeArguments @('unload', $target) -Operation 'unload'
                break
            }
            catch {
                if ($unloadAttempt -ge 3) {
                    throw
                }
                Start-Sleep -Milliseconds 500
            }
        }
        if ([bool](& $MountTester $MountName)) {
            throw "Registry unload reported success but '$target' remains mounted."
        }
    }

    if ($State -eq 'Unloaded') {
        return [pscustomobject]@{ State = 'Unloaded'; Changed = $mounted }
    }

    if (-not [IO.Path]::IsPathRooted($HivePath) -or
        -not (Test-Path -LiteralPath $HivePath -PathType Leaf)) {
        throw "Default-user hive is not a rooted regular file: '$HivePath'."
    }
    $hiveItem = Get-Item -LiteralPath $HivePath -Force -ErrorAction Stop
    if (($hiveItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Default-user hive must not be a reparse point: '$HivePath'."
    }

    & $invokeRegistry -NativeArguments @(
        'load', $target, [IO.Path]::GetFullPath($HivePath)
    ) -Operation 'load'
    if (-not [bool](& $MountTester $MountName)) {
        throw "Registry load reported success but '$target' is not mounted."
    }
    return [pscustomobject]@{ State = 'Loaded'; Changed = $true }
}
