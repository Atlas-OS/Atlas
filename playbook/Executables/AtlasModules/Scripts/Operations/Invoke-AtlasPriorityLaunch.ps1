# Creates the selected executable suspended, sets its priority, and only then
# resumes it. Realtime keeps the fixed installed-handler UAC boundary.
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

    if ($Path -notmatch '^[A-Za-z]:[\\/]') {
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
        [string]$ExecutablePath
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
        'Realtime'
        '-TargetPath'
        (ConvertTo-AtlasShellWindowsArgument -Value $ExecutablePath)
        '-Elevated'
    )
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
    if ($Elevated -and $Priority -cne 'Realtime') {
        throw 'The elevated priority handler accepts only Realtime.'
    }

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

    if ($Priority -ceq 'Realtime') {
        $isAdministrator = Test-AtlasPriorityAdministrator
        if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or
            -not [IO.Path]::GetFullPath($PSCommandPath).Equals(
                [IO.Path]::GetFullPath($handlerPath),
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw 'Realtime is available only through the installed Atlas handler.'
        }
        if ($Elevated -and -not $isAdministrator) {
            throw 'The elevated Realtime handler does not have an administrator token.'
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

    if ($Priority -ceq 'Realtime' -and -not $isAdministrator) {
        if (-not [IO.File]::Exists($powerShellPath) -or
            -not [IO.File]::Exists($handlerPath)) {
            throw 'The Realtime launch host or installed handler is missing.'
        }
        $child = Microsoft.PowerShell.Management\Start-Process `
            -FilePath $powerShellPath `
            -ArgumentList (Get-AtlasPriorityRelaunchArgumentList `
                -HandlerPath $handlerPath `
                -ExecutablePath $executablePath) `
            -Verb RunAs `
            -WindowStyle Hidden `
            -PassThru
        if ($null -eq $child) {
            throw 'The elevated Realtime handler did not start.'
        }
        try {
            $child.WaitForExit()
            if ($child.ExitCode -ne 0) {
                throw "The elevated Realtime handler failed with exit code $($child.ExitCode)."
            }
        }
        finally {
            $child.Dispose()
        }
        return
    }

    Initialize-AtlasNativeType
    $commandLine = ConvertTo-AtlasShellWindowsArgument -Value $executablePath
    [void][Atlas.Native.PriorityLauncher]::Start(
        $executablePath,
        $commandLine,
        [IO.Path]::GetDirectoryName($executablePath),
        $priorityClass
    )
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-AtlasPriorityLaunch @PSBoundParameters
}
