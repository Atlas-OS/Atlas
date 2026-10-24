# Creates the selected executable suspended, sets its priority, and only then
# resumes it. Realtime, and any executable that needs administrator rights, go
# through UAC to the fixed installed handler.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Low', 'BelowNormal', 'Normal', 'AboveNormal', 'High', 'Realtime')]
    [string]$Priority,

    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath,

    [switch]$Elevated
)

function Resolve-AtlasPriorityTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if ($Path -cnotmatch '^[A-Za-z]:[\\/]') {
        throw 'The priority target must be an absolute path on a local drive.'
    }

    try {
        $resolvedPath = [IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "The priority target path is invalid: '$Path'."
    }

    if (-not [IO.Path]::GetExtension($resolvedPath).Equals(
            '.exe',
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The priority target must be an executable file: '$resolvedPath'."
    }
    if (-not [IO.File]::Exists($resolvedPath)) {
        throw "The priority target does not exist: '$resolvedPath'."
    }

    return $resolvedPath
}

function Get-AtlasPriorityClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Low', 'BelowNormal', 'Normal', 'AboveNormal', 'High', 'Realtime')]
        [string]$Name
    )

    switch ($Name) {
        'Low' { return [uint32]0x00000040 }
        'BelowNormal' { return [uint32]0x00004000 }
        'Normal' { return [uint32]0x00000020 }
        'AboveNormal' { return [uint32]0x00008000 }
        'High' { return [uint32]0x00000080 }
        'Realtime' { return [uint32]0x00000100 }
    }
}

function Get-AtlasPriorityRelaunchArgumentList {
    param(
        [string]$HandlerPath,
        [string]$ExecutablePath,
        [string]$Priority
    )

    return @(
        '-NoLogo'
        '-NoProfile'
        '-NonInteractive'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        (ConvertTo-AtlasShellWindowsArgument -Value $HandlerPath)
        '-Priority'
        $Priority
        '-TargetPath'
        (ConvertTo-AtlasShellWindowsArgument -Value $ExecutablePath)
        '-Elevated'
    )
}

function Start-AtlasPriorityElevatedHandler {
    param(
        [string]$PowerShellPath,
        [string]$HandlerPath,
        [string]$ExecutablePath,
        [string]$Priority
    )

    if (-not [IO.File]::Exists($PowerShellPath) -or -not [IO.File]::Exists($HandlerPath)) {
        throw 'The elevated launch host or installed handler is missing.'
    }
    # Process.Start keeps the Win32 error of a declined UAC prompt; Start-Process
    # reports only its text.
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $PowerShellPath
    $startInfo.Arguments = (Get-AtlasPriorityRelaunchArgumentList -HandlerPath $HandlerPath `
            -ExecutablePath $ExecutablePath -Priority $Priority) -join ' '
    $startInfo.Verb = 'runas'
    $startInfo.UseShellExecute = $true
    $startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    try {
        $child = [Diagnostics.Process]::Start($startInfo)
    }
    catch [ComponentModel.Win32Exception] {
        # ERROR_CANCELLED: the user declined the UAC prompt, which needs no report.
        if ($_.Exception.NativeErrorCode -eq 1223) {
            return
        }
        throw
    }
    if ($null -eq $child) {
        throw 'The elevated priority handler did not start.'
    }
    try {
        $child.WaitForExit()
        if ($child.ExitCode -ne 0) {
            # The elevated handler has already shown why it failed.
            throw [Management.Automation.ErrorRecord]::new(
                [InvalidOperationException]::new(
                    "The elevated priority handler failed with exit code $($child.ExitCode)."),
                'AtlasPriorityElevatedHandlerFailed',
                [Management.Automation.ErrorCategory]::NotSpecified,
                $null)
        }
    }
    finally {
        $child.Dispose()
    }
}

function Start-AtlasPriorityProcess {
    param(
        [string]$ExecutablePath,
        [uint32]$PriorityClass
    )

    Initialize-AtlasNativeType
    [void][Atlas.Native.PriorityLauncher]::Start(
        $ExecutablePath,
        (ConvertTo-AtlasShellWindowsArgument -Value $ExecutablePath),
        [IO.Path]::GetDirectoryName($ExecutablePath),
        $PriorityClass
    )
}

function Start-AtlasPriorityTarget {
    param(
        [string]$ExecutablePath,
        [string]$Priority,
        [uint32]$PriorityClass,
        [string]$PowerShellPath,
        [string]$HandlerPath,
        [bool]$IsAdministrator,
        [switch]$Elevated
    )

    $elevatedLaunch = @{
        PowerShellPath = $PowerShellPath
        HandlerPath    = $HandlerPath
        ExecutablePath = $ExecutablePath
        Priority       = $Priority
    }
    if ($Priority -ceq 'Realtime' -and -not $IsAdministrator) {
        Start-AtlasPriorityElevatedHandler @elevatedLaunch
        return
    }

    try {
        Start-AtlasPriorityProcess -ExecutablePath $ExecutablePath -PriorityClass $PriorityClass
    }
    catch [ComponentModel.Win32Exception] {
        # CreateProcess never shows UAC: an executable that needs administrator
        # rights fails with ERROR_ELEVATION_REQUIRED instead.
        if ($Elevated -or $_.Exception.NativeErrorCode -ne 740) {
            throw
        }
        Start-AtlasPriorityElevatedHandler @elevatedLaunch
    }
}

function Get-AtlasPriorityFailureReason {
    param(
        [Parameter(Mandatory = $true)]
        [Management.Automation.ErrorRecord]$ErrorRecord,

        [string]$FileName
    )

    $exception = $ErrorRecord.Exception
    if ($exception -is [Management.Automation.MethodInvocationException] -and
        $null -ne $exception.InnerException) {
        $exception = $exception.InnerException
    }
    if ($exception -isnot [ComponentModel.Win32Exception]) {
        return $exception.Message
    }
    # The native launcher names only the call that failed; Windows says why.
    $windowsReason = [ComponentModel.Win32Exception]::new($exception.NativeErrorCode).Message
    return '{0} (Windows error {1}).' -f `
        $windowsReason.Replace('%1', $FileName).TrimEnd('.'), $exception.NativeErrorCode
}

function Show-AtlasPriorityLaunchFailure {
    param(
        [Parameter(Mandatory = $true)]
        [Management.Automation.ErrorRecord]$ErrorRecord,

        [string]$TargetPath,

        [string]$Priority
    )

    $fileName = [IO.Path]::GetFileName($TargetPath)
    $reason = Get-AtlasPriorityFailureReason -ErrorRecord $ErrorRecord -FileName $fileName
    # Write-AtlasLog exists only once Atlas.Core is imported, and a failed log write
    # must not stop the message.
    try {
        Write-AtlasLog -Level Error -Message "Couldn't start '$TargetPath' with $Priority priority: $reason" `
            -ErrorRecord $ErrorRecord
    }
    catch {
        $null = $_
    }
    # Runs before the trust bootstrap too, so the message uses .NET and COM only.
    $shell = [Activator]::CreateInstance([Type]::GetTypeFromProgID('WScript.Shell'))
    # 16 shows the error icon and 4096 keeps the box above the window that was clicked.
    [void]$shell.Popup("Couldn't start '$fileName'.`n`n$reason", 0, 'Run with priority', 16 + 4096)
}

function Test-AtlasPriorityAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    finally {
        $identity.Dispose()
    }
}

function Invoke-AtlasPriorityLaunch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Low', 'BelowNormal', 'Normal', 'AboveNormal', 'High', 'Realtime')]
        [string]$Priority,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath,

        [switch]$Elevated
    )

    Set-StrictMode -Version 3.0
    $ErrorActionPreference = 'Stop'

    $executablePath = Resolve-AtlasPriorityTarget -Path $TargetPath
    $priorityClass = Get-AtlasPriorityClass -Name $Priority

    $windowsRoot = [Environment]::GetEnvironmentVariable('SystemRoot')
    if ([string]::IsNullOrWhiteSpace($windowsRoot)) {
        throw 'The Windows directory could not be resolved.'
    }
    $handlerPath = [IO.Path]::Combine(
        $windowsRoot,
        'AtlasModules',
        'Scripts',
        'Operations',
        'Invoke-AtlasPriorityLaunch.ps1'
    )
    $powerShellPath = [IO.Path]::Combine(
        $windowsRoot,
        'System32',
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe'
    )
    $isAdministrator = $false

    if ($Elevated -or $Priority -ceq 'Realtime') {
        $isAdministrator = Test-AtlasPriorityAdministrator
        if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or
            -not [IO.Path]::GetFullPath($PSCommandPath).Equals(
                [IO.Path]::GetFullPath($handlerPath),
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw 'Realtime and elevated launches are available only through the installed Atlas handler.'
        }
        if ($Elevated -and -not $isAdministrator) {
            throw 'The elevated priority handler does not have an administrator token.'
        }
    }

    $scriptsRoot = [IO.Path]::GetDirectoryName($PSScriptRoot)
    $trustBootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
    if (-not [IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap

    # Atlas.Core owns the single protected compile of the Atlas native surface. It
    # only defines functions, so it imports cleanly in this medium-integrity host.
    $coreManifest = [IO.Path]::Combine(
        $scriptsRoot, 'Modules', 'Atlas.Core', 'Atlas.Core.psd1'
    )
    if (-not [IO.File]::Exists($coreManifest)) {
        throw "The Atlas.Core manifest is missing at '$coreManifest'."
    }
    Microsoft.PowerShell.Core\Import-Module -Name $coreManifest -ErrorAction Stop

    $shellManifest = [IO.Path]::Combine($scriptsRoot, 'Modules', 'Atlas.Shell', 'Atlas.Shell.psd1')
    if (-not [IO.File]::Exists($shellManifest)) {
        throw "The Atlas.Shell manifest is missing at '$shellManifest'."
    }
    Microsoft.PowerShell.Core\Import-Module -Name $shellManifest -ErrorAction Stop

    Start-AtlasPriorityTarget -ExecutablePath $executablePath -Priority $Priority `
        -PriorityClass $priorityClass -PowerShellPath $powerShellPath -HandlerPath $handlerPath `
        -IsAdministrator $isAdministrator -Elevated:$Elevated
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-AtlasPriorityLaunch @PSBoundParameters
    }
    catch {
        # The handler window is hidden, so a failure would otherwise go unseen.
        if ($_.FullyQualifiedErrorId -cne 'AtlasPriorityElevatedHandlerFailed') {
            Show-AtlasPriorityLaunchFailure -ErrorRecord $_ -TargetPath $TargetPath -Priority $Priority
        }
        exit 1
    }
}
