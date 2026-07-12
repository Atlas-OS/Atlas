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

$script:AtlasPriorityNativeSource = @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class AtlasPriorityLauncherNative
{
    private const UInt32 CREATE_SUSPENDED = 0x00000004;
    private const UInt32 CREATE_NEW_CONSOLE = 0x00000010;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct STARTUPINFO
    {
        public UInt32 cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public UInt32 dwX, dwY, dwXSize, dwYSize;
        public UInt32 dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public UInt16 wShowWindow;
        public UInt16 cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput, hStdOutput, hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROCESS_INFORMATION
    {
        public IntPtr hProcess;
        public IntPtr hThread;
        public UInt32 dwProcessId;
        public UInt32 dwThreadId;
    }

    [DllImport("kernel32.dll", EntryPoint = "CreateProcessW", ExactSpelling = true,
        SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CreateProcess(
        string applicationName,
        StringBuilder commandLine,
        IntPtr processAttributes,
        IntPtr threadAttributes,
        bool inheritHandles,
        UInt32 creationFlags,
        IntPtr environment,
        string currentDirectory,
        ref STARTUPINFO startupInfo,
        out PROCESS_INFORMATION processInformation);

    [DllImport("kernel32.dll", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetPriorityClass(IntPtr process, UInt32 priorityClass);

    [DllImport("kernel32.dll", ExactSpelling = true, SetLastError = true)]
    private static extern UInt32 ResumeThread(IntPtr thread);

    [DllImport("kernel32.dll", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool TerminateProcess(IntPtr process, UInt32 exitCode);

    [DllImport("kernel32.dll", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CloseHandle(IntPtr handle);

    private static Win32Exception LastError(string operation)
    {
        return new Win32Exception(Marshal.GetLastWin32Error(), operation);
    }

    public static UInt32 Start(
        string applicationPath,
        string commandLine,
        string workingDirectory,
        UInt32 priorityClass)
    {
        if (String.IsNullOrWhiteSpace(applicationPath))
            throw new ArgumentException("An application path is required.", "applicationPath");
        if (String.IsNullOrWhiteSpace(commandLine))
            throw new ArgumentException("A command line is required.", "commandLine");
        if (String.IsNullOrWhiteSpace(workingDirectory))
            throw new ArgumentException("A working directory is required.", "workingDirectory");

        STARTUPINFO startupInfo = new STARTUPINFO();
        startupInfo.cb = (UInt32)Marshal.SizeOf(typeof(STARTUPINFO));
        PROCESS_INFORMATION processInformation;
        bool created = CreateProcess(
            applicationPath,
            new StringBuilder(commandLine),
            IntPtr.Zero,
            IntPtr.Zero,
            false,
            CREATE_SUSPENDED | CREATE_NEW_CONSOLE,
            IntPtr.Zero,
            workingDirectory,
            ref startupInfo,
            out processInformation);
        if (!created)
            throw LastError("CreateProcessW failed for the selected executable");

        try
        {
            if (!SetPriorityClass(processInformation.hProcess, priorityClass))
                throw LastError("SetPriorityClass failed for the suspended executable");

            UInt32 suspendCount = ResumeThread(processInformation.hThread);
            if (suspendCount == UInt32.MaxValue)
                throw LastError("ResumeThread failed for the selected executable");
            if (suspendCount != 1)
                throw new InvalidOperationException(
                    "The executable had an unexpected initial suspend count.");
        }
        catch (Exception failure)
        {
            if (!TerminateProcess(processInformation.hProcess, 1))
                throw new AggregateException(
                    failure,
                    LastError("TerminateProcess failed for the suspended executable"));
            throw;
        }
        finally
        {
            CloseHandle(processInformation.hThread);
            CloseHandle(processInformation.hProcess);
        }

        return processInformation.dwProcessId;
    }
}
'@

function Initialize-AtlasPriorityNative {
    if ($null -eq ('AtlasPriorityLauncherNative' -as [type])) {
        Microsoft.PowerShell.Utility\Add-Type `
            -TypeDefinition $script:AtlasPriorityNativeSource `
            -Language CSharp -ErrorAction Stop
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
        'Internal',
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

    $trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
    if (-not [IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap

    $shellSupport = [IO.Path]::Combine($PSScriptRoot, 'Shell-ContextMenuSupport.ps1')
    if (-not [IO.File]::Exists($shellSupport)) {
        throw "The shell argument helper is missing at '$shellSupport'."
    }
    . $shellSupport

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

    Initialize-AtlasPriorityNative
    $commandLine = ConvertTo-AtlasShellWindowsArgument -Value $executablePath
    [void][AtlasPriorityLauncherNative]::Start(
        $executablePath,
        $commandLine,
        [IO.Path]::GetDirectoryName($executablePath),
        $priorityClass
    )
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-AtlasPriorityLaunch @PSBoundParameters
}
