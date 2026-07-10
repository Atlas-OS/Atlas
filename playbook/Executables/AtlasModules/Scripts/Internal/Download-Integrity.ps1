# Shared primitives for downloads that are consumed by an elevated Atlas process.

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

function New-AtlasProtectedStagingAcl {
    [CmdletBinding()]
    param()

    $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $system = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
    $trustedInstaller = New-Object Security.Principal.SecurityIdentifier('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464')
    $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit

    $security = New-Object Security.AccessControl.DirectorySecurity
    $security.SetAccessRuleProtection($true, $false)
    $security.SetOwner($administrators)
    foreach ($sid in @($system, $administrators, $trustedInstaller)) {
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        )
        [void]$security.AddAccessRule($rule)
    }

    return $security
}

function Test-AtlasProtectedStagingAcl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.DirectorySecurity]$Acl
    )

    $administrators = 'S-1-5-32-544'
    if (-not $Acl.AreAccessRulesProtected -or
        $Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $administrators) {
        return $false
    }

    $expectedSids = @(
        'S-1-5-18'
        $administrators
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
    )
    $expectedInheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit
    $rules = @($Acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))
    if ($rules.Count -ne $expectedSids.Count) {
        return $false
    }

    $principalCounts = @{}
    foreach ($sid in $expectedSids) {
        $principalCounts[$sid] = 0
    }

    foreach ($rule in $rules) {
        if ($rule.IdentityReference.Value -notin $expectedSids -or
            $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or
            $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::FullControl -or
            $rule.InheritanceFlags -ne $expectedInheritance -or
            $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None -or
            $rule.IsInherited) {
            return $false
        }

        $principalCounts[$rule.IdentityReference.Value]++
    }

    foreach ($sid in $expectedSids) {
        if ($principalCounts[$sid] -ne 1) {
            return $false
        }
    }

    return $true
}

function New-AtlasDirectoryWithSecurity {
    <#
    .SYNOPSIS
        Atomically creates a directory with its final security descriptor.
    .DESCRIPTION
        Windows PowerShell exposes Directory.CreateDirectory(path, security).
        Modern .NET exposes the same atomic operation through
        FileSystemAclExtensions.Create(DirectoryInfo, security). Resolve the
        available API explicitly so the security boundary works on both hosts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [Security.AccessControl.DirectorySecurity]$Security
    )

    $parameterTypes = [type[]]@(
        [string]
        [Security.AccessControl.DirectorySecurity]
    )
    $legacyCreate = [IO.Directory].GetMethod('CreateDirectory', $parameterTypes)
    if ($null -ne $legacyCreate) {
        return $legacyCreate.Invoke($null, [object[]]@($Path, $Security))
    }

    [void][Type]::GetType(
        'System.IO.FileSystemAclExtensions, System.IO.FileSystem.AccessControl',
        $true
    )

    $directory = New-Object IO.DirectoryInfo($Path)
    [IO.FileSystemAclExtensions]::Create($directory, $Security)
    return $directory
}

function New-AtlasProtectedStagingDirectory {
    <#
    .SYNOPSIS
        Atomically creates a random, ACL-protected staging directory.
    .DESCRIPTION
        Hashing a file in the caller's normal TEMP directory and reopening it by
        path leaves a medium-integrity process with the same user SID able to race
        the elevated consumer. The final directory is created atomically with a
        protected DACL and an Administrators owner so that owner rights do not
        preserve access for the split-token user.
    #>
    [CmdletBinding()]
    param()

    $stagingRoot = [Environment]::GetFolderPath('CommonApplicationData')
    if (-not (Test-Path -LiteralPath $stagingRoot -PathType Container)) {
        throw "The common application-data directory '$stagingRoot' is unavailable."
    }

    $rootItem = Get-Item -LiteralPath $stagingRoot -Force -ErrorAction Stop
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The staging root '$stagingRoot' is a reparse point. Refusing to stage an elevated download there."
    }

    $security = New-AtlasProtectedStagingAcl

    # A GUID makes pre-creation infeasible; the DirectorySecurity overload applies
    # the protected descriptor as the final directory is created, not afterwards.
    $stagingPath = Join-Path -Path $stagingRoot -ChildPath ('AtlasOS-Staging-' + [guid]::NewGuid().ToString('N'))
    $directory = New-AtlasDirectoryWithSecurity -Path $stagingPath -Security $security
    if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
        throw "The protected staging directory '$stagingPath' resolved to a reparse point."
    }

    $actualSecurity = Get-Acl -LiteralPath $stagingPath -ErrorAction Stop
    if (-not (Test-AtlasProtectedStagingAcl -Acl $actualSecurity)) {
        Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
        throw "The staging directory '$stagingPath' did not retain its exact protected ACL."
    }

    return $directory.FullName
}

function Invoke-AtlasPinnedDownload {
    <#
    .SYNOPSIS
        Downloads an HTTPS resource and verifies its pinned SHA-256.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{64}$')]
        [string]$Sha256,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1073741824)]
        [long]$ExpectedBytes,

        [ValidateRange(1, 3600)]
        [int]$MaximumSeconds = 300
    )

    if ($Uri.Scheme -ne 'https' -or -not [string]::IsNullOrEmpty($Uri.UserInfo)) {
        throw "Only HTTPS download URIs without user information are allowed: '$Uri'."
    }
    if (Test-Path -LiteralPath $Destination) {
        throw "The download destination '$Destination' already exists."
    }

    $destinationParent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        throw "The download destination parent '$destinationParent' does not exist."
    }
    $parentItem = Get-Item -LiteralPath $destinationParent -Force -ErrorAction Stop
    if (($parentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The download destination parent '$destinationParent' is a reparse point."
    }
    $parentSecurity = Get-Acl -LiteralPath $destinationParent -ErrorAction Stop
    if (-not (Test-AtlasProtectedStagingAcl -Acl $parentSecurity)) {
        throw "The download destination parent '$destinationParent' does not have the exact Atlas protected staging ACL."
    }

    $curlPath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'curl.exe'
    if (-not (Test-Path -LiteralPath $curlPath -PathType Leaf)) {
        throw "The Windows cURL executable was not found at '$curlPath'."
    }

    $curlArguments = @(
        # This must be argument zero. Otherwise curl automatically reads the
        # caller-writable .curlrc and may perform extra privileged operations.
        '--disable'
        '--fail'
        '--location'
        '--silent'
        '--show-error'
        '--proto', '=https'
        '--proto-redir', '=https'
        '--tlsv1.2'
        '--connect-timeout', '10'
        '--max-time', [string]$MaximumSeconds
        '--retry-max-time', [string]$MaximumSeconds
        '--retry', '5'
        '--retry-delay', '0'
        '--retry-all-errors'
        '--max-filesize', [string]$ExpectedBytes
        $Uri.AbsoluteUri
        '--output', $Destination
    )

    $curlErrorPath = Join-Path -Path $destinationParent -ChildPath (
        'curl-' + [guid]::NewGuid().ToString('N') + '.stderr'
    )
    $curlArguments += @('--stderr', $curlErrorPath)
    try {
        $curlResult = Invoke-AtlasContainedProcess `
            -FilePath $curlPath `
            -ArgumentList ([string[]]$curlArguments) `
            -WorkingDirectory $destinationParent `
            -TimeoutSeconds $MaximumSeconds `
            -Description "The protected cURL download for '$Uri'" `
            -Hidden `
            -NoWindow
    }
    catch {
        if (-not (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception)) {
            Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $curlErrorPath -Force -ErrorAction SilentlyContinue
        }
        throw
    }

    if (-not $curlResult.ContainmentConfirmed -or -not $curlResult.RootExited -or
        -not $curlResult.JobDrained) {
        throw [Atlas.ContainedProcessException]::new(
            "The protected cURL download for '$Uri' returned without confirmed process-tree containment.",
            $false,
            [InvalidOperationException]::new('The native contained-process result violated its completion invariant.')
        )
    }
    $curlExitCode = [uint32]$curlResult.ExitCodeUInt32
    if ($curlExitCode -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        $curlDiagnostic = $null
        if (Test-Path -LiteralPath $curlErrorPath -PathType Leaf) {
            $curlError = Get-Item -LiteralPath $curlErrorPath -Force -ErrorAction SilentlyContinue
            if ($null -ne $curlError -and $curlError.Length -le 65536) {
                $curlDiagnostic = [IO.File]::ReadAllText($curlError.FullName)
            }
        }
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $curlErrorPath -Force -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($curlDiagnostic)) {
            throw "Downloading '$Uri' failed with cURL exit code $curlExitCode."
        }
        throw "Downloading '$Uri' failed with cURL exit code $curlExitCode. cURL reported: $($curlDiagnostic.Trim())"
    }
    Remove-Item -LiteralPath $curlErrorPath -Force -ErrorAction SilentlyContinue

    $download = Get-Item -LiteralPath $Destination -Force -ErrorAction Stop
    if (($download.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $download.Length -ne $ExpectedBytes) {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw "The downloaded file '$Destination' did not match the reviewed file type and byte length."
    }

    $actualSha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($actualSha256 -ne $Sha256) {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw "SHA-256 '$actualSha256' does not match the reviewed '$Sha256' for '$Uri'."
    }

    return $download.FullName
}

function Test-AtlasProtectedExecutionAcl {
    <#
    .SYNOPSIS
        Rejects executable or working-directory ACLs writable by an untrusted principal.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.FileSystemSecurity]$Acl
    )

    $privilegedSids = @(
        'S-1-5-18'
        'S-1-5-32-544'
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
    )
    $owner = $Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
    if ($owner -notin $privilegedSids -or -not $Acl.AreAccessRulesCanonical) {
        return $false
    }

    [long]$mutationRights = [long][Security.AccessControl.FileSystemRights]::WriteData -bor
        [long][Security.AccessControl.FileSystemRights]::AppendData -bor
        [long][Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor
        [long][Security.AccessControl.FileSystemRights]::WriteAttributes -bor
        [long][Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor
        [long][Security.AccessControl.FileSystemRights]::Delete -bor
        [long][Security.AccessControl.FileSystemRights]::ChangePermissions -bor
        [long][Security.AccessControl.FileSystemRights]::TakeOwnership -bor
        [long]0x10000000 -bor [long]0x40000000
    foreach ($rule in $Acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
        $inheritOnly = ($rule.PropagationFlags -band
            [Security.AccessControl.PropagationFlags]::InheritOnly) -ne 0
        if (-not $inheritOnly -and
            $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
            ([long]$rule.FileSystemRights -band $mutationRights) -ne 0 -and
            $rule.IdentityReference.Value -notin $privilegedSids) {
            return $false
        }
    }
    return $true
}

function Resolve-AtlasProtectedExecutionPath {
    <#
    .SYNOPSIS
        Resolves one fixed local path and rejects reparse or untrusted writable objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Leaf', 'Container')]
        [string]$PathType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path.IndexOf([char]0) -ge 0 -or
        $Path -notmatch '^[A-Za-z]:[\\/]') {
        throw "$Description must be an explicit absolute local drive path."
    }
    $fullPath = [IO.Path]::GetFullPath($Path)
    if ($fullPath.Substring(2).Contains(':')) {
        throw "$Description cannot address an alternate data stream."
    }

    $root = [IO.Path]::GetPathRoot($fullPath)
    $current = $root
    $segments = $fullPath.Substring($root.Length).Split(
        [char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar),
        [StringSplitOptions]::RemoveEmptyEntries
    )
    foreach ($segment in $segments) {
        $current = [IO.Path]::Combine($current, $segment)
        $segmentItem = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($segmentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Description contains a reparse point at '$current'."
        }
    }

    $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    if ($PathType -eq 'Leaf') {
        if ($item.PSIsContainer -or $item.Length -le 0) {
            throw "$Description is not a normal non-empty file."
        }
        $parentPath = [IO.Path]::GetDirectoryName($fullPath)
        $parentAcl = Get-Acl -LiteralPath $parentPath -ErrorAction Stop
        if (-not (Test-AtlasProtectedExecutionAcl -Acl $parentAcl)) {
            throw "The parent of $Description is writable by an untrusted principal."
        }
    }
    elseif (-not $item.PSIsContainer) {
        throw "$Description is not a normal directory."
    }

    $acl = Get-Acl -LiteralPath $fullPath -ErrorAction Stop
    if (-not (Test-AtlasProtectedExecutionAcl -Acl $acl)) {
        throw "$Description has an untrusted owner or writable principal."
    }
    return $fullPath
}

$script:AtlasContainedProcessNativeTypeLoaded = $false

function Add-AtlasDownloadIntegrityNativeType {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private compiler wrapper creates and removes only its random protected compiler directory.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TypeDefinition
    )

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isHighIntegrityContext = $identity.User.Value -eq 'S-1-5-18' -or
        $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isHighIntegrityContext) {
        Add-Type -TypeDefinition $TypeDefinition -Language CSharp -ErrorAction Stop
        return
    }

    $compilerTemp = New-AtlasProtectedStagingDirectory
    $originalTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
    $originalTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
    try {
        [Environment]::SetEnvironmentVariable('TEMP', $compilerTemp, 'Process')
        [Environment]::SetEnvironmentVariable('TMP', $compilerTemp, 'Process')
        Add-Type -TypeDefinition $TypeDefinition -Language CSharp -ErrorAction Stop
    }
    finally {
        [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
        [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        if ([IO.Directory]::Exists($compilerTemp)) {
            Remove-Item -LiteralPath $compilerTemp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Initialize-AtlasContainedProcessNativeType {
    [CmdletBinding()]
    param()

    if ($script:AtlasContainedProcessNativeTypeLoaded -or ('Atlas.ContainedProcessNative' -as [type])) {
        $script:AtlasContainedProcessNativeTypeLoaded = $true
        return
    }

    $signature = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace Atlas {
    public sealed class ContainedProcessResult {
        public UInt32 ExitCodeUInt32 { get; internal set; }
        public UInt32 RootProcessId { get; internal set; }
        public bool RootExited { get; internal set; }
        public bool JobDrained { get; internal set; }
        public bool ContainmentConfirmed { get; internal set; }
    }

    public sealed class ContainedProcessException : Exception {
        public bool ContainmentConfirmed { get; private set; }

        public ContainedProcessException(string message, bool containmentConfirmed, Exception innerException)
            : base(message, innerException) {
            ContainmentConfirmed = containmentConfirmed;
        }
    }

    public static class ContainedProcessNative {
        const UInt32 CREATE_SUSPENDED = 0x00000004;
        const UInt32 CREATE_NO_WINDOW = 0x08000000;
        const UInt32 STARTF_USESHOWWINDOW = 0x00000001;
        const UInt16 SW_HIDE = 0;
        const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
        const Int32 JobObjectBasicAndIoAccountingInformation = 8;
        const Int32 JobObjectExtendedLimitInformation = 9;
        const UInt32 WAIT_OBJECT_0 = 0;
        const UInt32 WAIT_TIMEOUT = 258;
        const UInt32 WAIT_FAILED = 0xFFFFFFFF;
        const UInt32 TERMINATED_PROCESS_EXIT_CODE = 0xC000013A;
        const Int32 TERMINATION_DRAIN_MILLISECONDS = 10000;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct STARTUPINFO {
            public Int32 cb;
            public IntPtr lpReserved;
            public IntPtr lpDesktop;
            public IntPtr lpTitle;
            public Int32 dwX;
            public Int32 dwY;
            public Int32 dwXSize;
            public Int32 dwYSize;
            public Int32 dwXCountChars;
            public Int32 dwYCountChars;
            public Int32 dwFillAttribute;
            public UInt32 dwFlags;
            public UInt16 wShowWindow;
            public UInt16 cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct PROCESS_INFORMATION {
            public IntPtr hProcess;
            public IntPtr hThread;
            public UInt32 dwProcessId;
            public UInt32 dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct IO_COUNTERS {
            public UInt64 ReadOperationCount;
            public UInt64 WriteOperationCount;
            public UInt64 OtherOperationCount;
            public UInt64 ReadTransferCount;
            public UInt64 WriteTransferCount;
            public UInt64 OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
            public Int64 PerProcessUserTimeLimit;
            public Int64 PerJobUserTimeLimit;
            public UInt32 LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public UInt32 ActiveProcessLimit;
            public UIntPtr Affinity;
            public UInt32 PriorityClass;
            public UInt32 SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
            public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            public IO_COUNTERS IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct JOBOBJECT_BASIC_ACCOUNTING_INFORMATION {
            public Int64 TotalUserTime;
            public Int64 TotalKernelTime;
            public Int64 ThisPeriodTotalUserTime;
            public Int64 ThisPeriodTotalKernelTime;
            public UInt32 TotalPageFaultCount;
            public UInt32 TotalProcesses;
            public UInt32 ActiveProcesses;
            public UInt32 TotalTerminatedProcesses;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION {
            public JOBOBJECT_BASIC_ACCOUNTING_INFORMATION BasicInfo;
            public IO_COUNTERS IoInfo;
        }

        [DllImport("kernel32.dll", EntryPoint = "CreateJobObjectW", ExactSpelling = true,
            CharSet = CharSet.Unicode, SetLastError = true)]
        static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string lpName);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool SetInformationJobObject(IntPtr hJob, Int32 infoClass,
            ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION info, Int32 length);

        [DllImport("kernel32.dll", EntryPoint = "CreateProcessW", ExactSpelling = true,
            CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool CreateProcess(string lpApplicationName, StringBuilder lpCommandLine,
            IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles,
            UInt32 dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory,
            ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool IsProcessInJob(IntPtr processHandle, IntPtr jobHandle, out bool result);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 ResumeThread(IntPtr hThread);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 milliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetExitCodeProcess(IntPtr hProcess, out UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateJobObject(IntPtr hJob, UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateProcess(IntPtr hProcess, UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool QueryInformationJobObject(IntPtr hJob, Int32 infoClass,
            out JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION info, Int32 length,
            out Int32 returnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);

        public static string QuoteWindowsArgument(string value) {
            if (value == null) throw new ArgumentNullException("value");
            if (value.Length == 0) return "\"\"";

            bool requiresQuotes = false;
            for (int index = 0; index < value.Length; index++) {
                char current = value[index];
                if (Char.IsWhiteSpace(current) || current == '\"') {
                    requiresQuotes = true;
                    break;
                }
            }
            if (!requiresQuotes) return value;

            StringBuilder output = new StringBuilder();
            output.Append('\"');
            int backslashes = 0;
            for (int index = 0; index < value.Length; index++) {
                char current = value[index];
                if (current == '\\') {
                    backslashes++;
                    continue;
                }
                if (current == '\"') {
                    output.Append('\\', backslashes * 2 + 1);
                    output.Append('\"');
                    backslashes = 0;
                    continue;
                }
                if (backslashes != 0) {
                    output.Append('\\', backslashes);
                    backslashes = 0;
                }
                output.Append(current);
            }
            if (backslashes != 0) output.Append('\\', backslashes * 2);
            output.Append('\"');
            return output.ToString();
        }

        public static string BuildWindowsCommandLine(string applicationPath, string[] arguments) {
            if (String.IsNullOrWhiteSpace(applicationPath)) {
                throw new ArgumentException("An explicit application path is required.", "applicationPath");
            }
            List<string> values = new List<string>();
            values.Add(applicationPath);
            if (arguments != null) values.AddRange(arguments);
            if (values.Count > 129) {
                throw new ArgumentOutOfRangeException("arguments", "At most 128 arguments are supported.");
            }

            StringBuilder commandLine = new StringBuilder();
            for (int index = 0; index < values.Count; index++) {
                string value = values[index];
                if (value == null || value.IndexOf('\0') >= 0) {
                    throw new ArgumentException("Arguments must be non-null and cannot contain NUL.", "arguments");
                }
                if (index != 0) commandLine.Append(' ');
                commandLine.Append(QuoteWindowsArgument(value));
            }
            if (commandLine.Length > 32766) {
                throw new ArgumentOutOfRangeException("arguments", "The Windows command line exceeds 32,766 characters.");
            }
            return commandLine.ToString();
        }

        public static ContainedProcessResult Launch(string applicationPath, string[] arguments,
            string workingDirectory, Int32 timeoutMilliseconds, bool hidden, bool noWindow,
            string description) {
            if (String.IsNullOrWhiteSpace(applicationPath)) {
                throw new ArgumentException("An explicit application path is required.", "applicationPath");
            }
            if (String.IsNullOrWhiteSpace(workingDirectory)) {
                throw new ArgumentException("An explicit protected working directory is required.", "workingDirectory");
            }
            if (timeoutMilliseconds < 1) {
                throw new ArgumentOutOfRangeException("timeoutMilliseconds");
            }
            if (String.IsNullOrWhiteSpace(description)) {
                throw new ArgumentException("A process description is required.", "description");
            }

            IntPtr job = IntPtr.Zero;
            PROCESS_INFORMATION processInfo = new PROCESS_INFORMATION();
            bool childCreated = false;
            bool assignedToJob = false;
            bool jobDrained = false;
            Stopwatch stopwatch = Stopwatch.StartNew();
            try {
                job = CreateJobObject(IntPtr.Zero, null);
                if (job == IntPtr.Zero) throw LastError("CreateJobObject failed");

                JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
                limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
                if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation, ref limits,
                    Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION)))) {
                    throw LastError("SetInformationJobObject(KILL_ON_JOB_CLOSE) failed");
                }

                STARTUPINFO startup = new STARTUPINFO();
                startup.cb = Marshal.SizeOf(typeof(STARTUPINFO));
                if (hidden) {
                    startup.dwFlags = STARTF_USESHOWWINDOW;
                    startup.wShowWindow = SW_HIDE;
                }
                UInt32 creationFlags = CREATE_SUSPENDED;
                if (noWindow) creationFlags |= CREATE_NO_WINDOW;
                StringBuilder commandLine = new StringBuilder(
                    BuildWindowsCommandLine(applicationPath, arguments));
                if (!CreateProcess(applicationPath, commandLine, IntPtr.Zero, IntPtr.Zero, false,
                    creationFlags, IntPtr.Zero, workingDirectory, ref startup, out processInfo)) {
                    throw LastError("CreateProcessW(CREATE_SUSPENDED) failed");
                }
                childCreated = true;

                if (!AssignProcessToJobObject(job, processInfo.hProcess)) {
                    throw LastError("AssignProcessToJobObject failed for the suspended root");
                }
                assignedToJob = true;
                bool inJob;
                if (!IsProcessInJob(processInfo.hProcess, job, out inJob)) {
                    throw LastError("IsProcessInJob(root) failed");
                }
                if (!inJob) {
                    throw new InvalidOperationException(
                        "The suspended root was not assigned to the Atlas contained-process job.");
                }

                if (ResumeThread(processInfo.hThread) == UInt32.MaxValue) {
                    throw LastError("ResumeThread(root) failed");
                }

                Int32 remaining = RemainingMilliseconds(stopwatch, timeoutMilliseconds);
                UInt32 waitResult = WaitForSingleObject(processInfo.hProcess,
                    unchecked((UInt32)remaining));
                if (waitResult == WAIT_TIMEOUT) {
                    throw new TimeoutException(description + " exceeded its common deadline.");
                }
                if (waitResult == WAIT_FAILED) {
                    throw LastError("WaitForSingleObject(root) failed");
                }
                if (waitResult != WAIT_OBJECT_0) {
                    throw new InvalidOperationException(String.Format(
                        "WaitForSingleObject(root) returned unexpected status 0x{0:X8}.", waitResult));
                }

                UInt32 exitCode;
                if (!GetExitCodeProcess(processInfo.hProcess, out exitCode)) {
                    throw LastError("GetExitCodeProcess(root) failed");
                }
                UInt32 rootProcessId = processInfo.dwProcessId;

                // Job accounting retains an exited process until all process references
                // are released. Close both PROCESS_INFORMATION handles before polling.
                CloseProcessInformationHandles(ref processInfo);
                DrainJobUntilDeadline(job, stopwatch, timeoutMilliseconds);
                jobDrained = true;

                return new ContainedProcessResult {
                    ExitCodeUInt32 = exitCode,
                    RootProcessId = rootProcessId,
                    RootExited = true,
                    JobDrained = true,
                    ContainmentConfirmed = true
                };
            }
            catch (Exception launchFailure) {
                if (childCreated && !jobDrained) {
                    try {
                        if (assignedToJob) {
                            TerminateAndDrainAssignedJob(job, ref processInfo);
                        }
                        else {
                            TerminateAndDrainUnassignedRoot(ref processInfo);
                        }
                        jobDrained = true;
                    }
                    catch (Exception containmentFailure) {
                        throw new ContainedProcessException(
                            description + " failed and Atlas could not confirm that its process tree was contained and drained.",
                            false,
                            new AggregateException(launchFailure, containmentFailure));
                    }
                }

                string message = launchFailure is TimeoutException
                    ? description + " exceeded its deadline; its contained process tree was terminated and drained."
                    : description + " failed without leaving an unconfirmed process tree.";
                throw new ContainedProcessException(message, true, launchFailure);
            }
            finally {
                CloseProcessInformationHandlesBestEffort(ref processInfo);
                if (job != IntPtr.Zero) CloseHandle(job);
            }
        }

        static Int32 RemainingMilliseconds(Stopwatch stopwatch, Int32 timeoutMilliseconds) {
            Int64 remaining = (Int64)timeoutMilliseconds - stopwatch.ElapsedMilliseconds;
            if (remaining <= 0) throw new TimeoutException("The contained process exceeded its common deadline.");
            return checked((Int32)remaining);
        }

        static UInt32 QueryActiveProcesses(IntPtr job) {
            JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION accounting;
            Int32 returned;
            if (!QueryInformationJobObject(job, JobObjectBasicAndIoAccountingInformation,
                out accounting,
                Marshal.SizeOf(typeof(JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION)),
                out returned)) {
                throw LastError("QueryInformationJobObject(accounting) failed");
            }
            return accounting.BasicInfo.ActiveProcesses;
        }

        static void DrainJobUntilDeadline(IntPtr job, Stopwatch stopwatch,
            Int32 timeoutMilliseconds) {
            while (true) {
                if (QueryActiveProcesses(job) == 0) return;
                Int32 remaining = RemainingMilliseconds(stopwatch, timeoutMilliseconds);
                Thread.Sleep(Math.Min(50, remaining));
            }
        }

        static void DrainTerminatedJob(IntPtr job) {
            Stopwatch drain = Stopwatch.StartNew();
            while (true) {
                if (QueryActiveProcesses(job) == 0) return;
                if (drain.ElapsedMilliseconds >= TERMINATION_DRAIN_MILLISECONDS) {
                    throw new TimeoutException(
                        "The terminated contained process tree did not drain within ten seconds.");
                }
                Thread.Sleep(50);
            }
        }

        static void TerminateAndDrainAssignedJob(IntPtr job,
            ref PROCESS_INFORMATION processInfo) {
            try {
                if (!TerminateJobObject(job, TERMINATED_PROCESS_EXIT_CODE)) {
                    throw LastError("TerminateJobObject failed for the contained process tree");
                }
            }
            finally {
                CloseProcessInformationHandles(ref processInfo);
            }
            DrainTerminatedJob(job);
        }

        static void TerminateAndDrainUnassignedRoot(ref PROCESS_INFORMATION processInfo) {
            try {
                UInt32 state = WaitForSingleObject(processInfo.hProcess, 0);
                if (state == WAIT_FAILED) {
                    throw LastError("WaitForSingleObject(unassigned suspended root) failed");
                }
                if (state != WAIT_OBJECT_0) {
                    if (!TerminateProcess(processInfo.hProcess, TERMINATED_PROCESS_EXIT_CODE)) {
                        throw LastError("TerminateProcess failed for the unassigned suspended root");
                    }
                    state = WaitForSingleObject(processInfo.hProcess,
                        unchecked((UInt32)TERMINATION_DRAIN_MILLISECONDS));
                    if (state == WAIT_FAILED) {
                        throw LastError("WaitForSingleObject(unassigned root drain) failed");
                    }
                    if (state != WAIT_OBJECT_0) {
                        throw new TimeoutException(
                            "The unassigned suspended root did not terminate within ten seconds.");
                    }
                }
            }
            finally {
                CloseProcessInformationHandles(ref processInfo);
            }
        }

        static void CloseProcessInformationHandles(ref PROCESS_INFORMATION processInfo) {
            Exception firstFailure = null;
            if (processInfo.hThread != IntPtr.Zero) {
                IntPtr thread = processInfo.hThread;
                processInfo.hThread = IntPtr.Zero;
                if (!CloseHandle(thread)) {
                    firstFailure = LastError("CloseHandle(root thread) failed");
                }
            }
            if (processInfo.hProcess != IntPtr.Zero) {
                IntPtr process = processInfo.hProcess;
                processInfo.hProcess = IntPtr.Zero;
                if (!CloseHandle(process) && firstFailure == null) {
                    firstFailure = LastError("CloseHandle(root process) failed");
                }
            }
            if (firstFailure != null) throw firstFailure;
        }

        static void CloseProcessInformationHandlesBestEffort(
            ref PROCESS_INFORMATION processInfo) {
            if (processInfo.hThread != IntPtr.Zero) {
                IntPtr thread = processInfo.hThread;
                processInfo.hThread = IntPtr.Zero;
                CloseHandle(thread);
            }
            if (processInfo.hProcess != IntPtr.Zero) {
                IntPtr process = processInfo.hProcess;
                processInfo.hProcess = IntPtr.Zero;
                CloseHandle(process);
            }
        }

        static Win32Exception LastError(string message) {
            Int32 error = Marshal.GetLastWin32Error();
            return new Win32Exception(error,
                message + " (Win32 error " + error + ").");
        }
    }
}
'@

    Add-AtlasDownloadIntegrityNativeType -TypeDefinition $signature
    $script:AtlasContainedProcessNativeTypeLoaded = $true
}

function Test-AtlasContainedProcessContainmentUnconfirmed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Exception]$Exception
    )

    $current = $Exception
    while ($null -ne $current) {
        if ($current.GetType().FullName -eq 'Atlas.ContainedProcessException') {
            return -not $current.ContainmentConfirmed
        }
        $current = $current.InnerException
    }
    return $false
}

function Invoke-AtlasContainedProcess {
    <#
    .SYNOPSIS
        Launches one fixed executable under the current token in a bounded job.
    .DESCRIPTION
        The root is created suspended, assigned to an unnamed kill-on-close job,
        verified, and only then resumed. The result is returned only after the root
        exit code is captured and the entire inherited process tree reaches zero.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [AllowEmptyCollection()]
        [string[]]$ArgumentList = @(),

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 7200)]
        [int]$TimeoutSeconds,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 512)]
        [string]$Description,

        [switch]$Hidden,

        [switch]$NoWindow
    )

    $resolvedFile = Resolve-AtlasProtectedExecutionPath `
        -Path $FilePath -PathType Leaf -Description 'The contained executable'
    $resolvedWorkingDirectory = Resolve-AtlasProtectedExecutionPath `
        -Path $WorkingDirectory -PathType Container -Description 'The contained working directory'
    Initialize-AtlasContainedProcessNativeType

    return [Atlas.ContainedProcessNative]::Launch(
        $resolvedFile,
        [string[]]$ArgumentList,
        $resolvedWorkingDirectory,
        ($TimeoutSeconds * 1000),
        [bool]$Hidden,
        [bool]$NoWindow,
        $Description
    )
}

function Resolve-AtlasGitHubReleaseAssetMetadata {
    <#
    .SYNOPSIS
        Validates GitHub release metadata and resolves one canonical asset.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Release,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9-]{0,99}$')]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$')]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,199}$')]
        [string]$AssetName
    )

    if ($Release.draft -isnot [bool] -or $Release.draft -or
        $Release.prerelease -isnot [bool] -or $Release.prerelease -or
        [string]$Release.tag_name -notmatch '^v?[0-9]+\.[0-9]+\.[0-9]+$') {
        throw 'GitHub latest-release metadata is not a stable semantic-version release.'
    }

    $assets = @($Release.assets | Where-Object { $_.name -ceq $AssetName })
    if ($assets.Count -ne 1) {
        throw "GitHub latest-release metadata did not contain exactly one '$AssetName' asset."
    }
    $asset = $assets[0]
    $digestMatch = [regex]::Match([string]$asset.digest, '^sha256:([0-9a-fA-F]{64})$')
    $assetBytes = 0L
    $assetId = 0L
    if ($asset.state -cne 'uploaded' -or
        -not $digestMatch.Success -or
        -not [long]::TryParse([string]$asset.size, [ref]$assetBytes) -or
        $assetBytes -lt 1 -or $assetBytes -gt 1073741824 -or
        -not [long]::TryParse([string]$asset.id, [ref]$assetId) -or
        $assetId -lt 1) {
        throw "GitHub's '$AssetName' asset is not a complete upload with a bounded SHA-256 digest, byte size, and identity."
    }

    $tag = [string]$Release.tag_name
    $expectedUrl = "https://github.com/$Owner/$Repository/releases/download/$tag/$AssetName"
    if ([string]$asset.browser_download_url -cne $expectedUrl) {
        throw "GitHub's '$AssetName' asset URL does not match its canonical repository and tag."
    }

    return [pscustomobject]@{
        Tag      = $tag
        Version  = $tag.TrimStart('v')
        Uri      = [uri]$expectedUrl
        Sha256   = $digestMatch.Groups[1].Value.ToLowerInvariant()
        Size     = $assetBytes
        AssetId  = $assetId
    }
}

function Get-AtlasLatestGitHubReleaseAsset {
    <#
    .SYNOPSIS
        Resolves one exact asset from a repository's current stable GitHub release.
    .DESCRIPTION
        This is for products whose release policy intentionally tracks latest.
        GitHub's required SHA-256 digest and byte size become the per-request
        verification boundary consumed by Invoke-AtlasPinnedDownload.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9-]{0,99}$')]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$')]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,199}$')]
        [string]$AssetName
    )

    Microsoft.PowerShell.Utility\Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
    $apiUri = [uri]"https://api.github.com/repos/$Owner/$Repository/releases/latest"
    $handler = New-Object Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $true
    $handler.MaxAutomaticRedirections = 5
    $handler.SslProtocols = [Security.Authentication.SslProtocols]::Tls12
    $client = New-Object Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(30)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('AtlasOS-Playbook')
    $client.DefaultRequestHeaders.Accept.ParseAdd('application/vnd.github+json')
    $client.DefaultRequestHeaders.Add('X-GitHub-Api-Version', '2022-11-28')

    $response = $null
    $stream = $null
    $memory = $null
    $contentCancellation = $null
    try {
        $response = $client.GetAsync(
            $apiUri,
            [Net.Http.HttpCompletionOption]::ResponseHeadersRead
        ).GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "GitHub release metadata failed with HTTP status $([int]$response.StatusCode)."
        }
        if ($response.RequestMessage.RequestUri.AbsoluteUri -cne $apiUri.AbsoluteUri) {
            throw 'GitHub release metadata redirected away from the canonical API endpoint.'
        }

        $maximumMetadataBytes = 1048576
        if ($response.Content.Headers.ContentLength -and
            $response.Content.Headers.ContentLength.Value -gt $maximumMetadataBytes) {
            throw 'GitHub release metadata exceeds the one-megabyte bound.'
        }

        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        # HttpClient.Timeout stops at the response headers when
        # ResponseHeadersRead is used. Apply an independent total deadline to
        # the body so a peer cannot keep this elevated process alive forever by
        # trickling a bounded response one byte at a time.
        $contentCancellation = New-Object Threading.CancellationTokenSource
        $contentCancellation.CancelAfter([TimeSpan]::FromSeconds(30))
        $memory = New-Object IO.MemoryStream
        $buffer = New-Object byte[] 16384
        $total = 0
        while (($read = $stream.ReadAsync(
                    $buffer,
                    0,
                    $buffer.Length,
                    $contentCancellation.Token
                ).GetAwaiter().GetResult()) -gt 0) {
            $total += $read
            if ($total -gt $maximumMetadataBytes) {
                throw 'GitHub release metadata exceeded the one-megabyte bound while streaming.'
            }
            $memory.Write($buffer, 0, $read)
        }

        $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
        $release = $strictUtf8.GetString($memory.ToArray()) |
            ConvertFrom-Json -ErrorAction Stop
    }
    finally {
        if ($null -ne $contentCancellation) { $contentCancellation.Dispose() }
        if ($null -ne $memory) { $memory.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        $client.Dispose()
        $handler.Dispose()
    }

    return Resolve-AtlasGitHubReleaseAssetMetadata `
        -Release $release `
        -Owner $Owner `
        -Repository $Repository `
        -AssetName $AssetName
}

function Get-AtlasTrustedWingetPath {
    <#
    .SYNOPSIS
        Resolves the Microsoft-signed WinGet binary from Desktop App Installer.
    .DESCRIPTION
        Never resolves winget.exe through PATH or the per-user WindowsApps alias:
        elevated Atlas callers must not execute a same-user planted executable.
    #>
    [CmdletBinding()]
    param()

    if (-not [Environment]::Is64BitProcess) {
        throw 'The trusted WinGet resolver requires a 64-bit PowerShell host.'
    }

    # Import the inbox Appx module by its protected absolute manifest path so a
    # same-user module planted earlier in PSModulePath cannot spoof discovery.
    $appxManifest = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'WindowsPowerShell\v1.0\Modules\Appx\Appx.psd1'
    if (-not (Test-Path -LiteralPath $appxManifest -PathType Leaf)) {
        throw "The protected Appx module manifest is missing at '$appxManifest'."
    }
    $appxModules = @(Import-Module -Name $appxManifest -Force -PassThru -ErrorAction Stop)
    $appxModuleDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $appxManifest)).TrimEnd('\')
    $expectedAppxGuid = [guid]'aeef2bef-eba9-4a1d-a3d2-d0b52df76deb'
    if ($appxModules.Count -ne 1 -or
        $appxModules[0].Name -ne 'Appx' -or
        $appxModules[0].Guid -ne $expectedAppxGuid -or
        -not [IO.Path]::GetFullPath($appxModules[0].ModuleBase).TrimEnd('\').Equals(
            $appxModuleDirectory,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The protected Appx module did not load from its exact manifest at '$appxManifest'."
    }
    $appxModule = $appxModules[0]

    $appxBinary = [IO.Path]::GetFullPath($appxModule.Path)
    $systemRoot = [IO.Path]::GetFullPath(
        [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    ).TrimEnd('\') + '\'
    $appxSignature = Get-AuthenticodeSignature -LiteralPath $appxBinary
    if (-not $appxBinary.StartsWith($systemRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $appxSignature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
        $null -eq $appxSignature.SignerCertificate -or
        $appxSignature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Windows(,|$)') {
        throw "The Appx implementation loaded from '$appxBinary' is not a protected Microsoft Windows binary."
    }

    # Invoke the command object exported by that exact module instance. A
    # previously loaded, same-named Appx module must not be able to intercept
    # package discovery through PowerShell's command-name resolution rules.
    $getAppxPackage = $appxModule.ExportedCommands['Get-AppxPackage']
    if ($null -eq $getAppxPackage -or
        -not [IO.Path]::GetFullPath($getAppxPackage.Module.ModuleBase).TrimEnd('\').Equals(
            $appxModuleDirectory,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        -not [IO.Path]::GetFullPath($getAppxPackage.Module.Path).Equals(
            $appxBinary,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The protected Appx module did not export its expected Get-AppxPackage command."
    }

    $windowsAppsRoot = Join-Path -Path ([Environment]::GetFolderPath('ProgramFiles')) -ChildPath 'WindowsApps'
    $windowsAppsRoot = [IO.Path]::GetFullPath($windowsAppsRoot).TrimEnd('\') + '\'
    $packages = @(& $getAppxPackage -Name 'Microsoft.DesktopAppInstaller' -ErrorAction SilentlyContinue)
    try {
        $packages += @(& $getAppxPackage -AllUsers -Name 'Microsoft.DesktopAppInstaller' -ErrorAction Stop)
    }
    catch {
        # A non-elevated software-picker caller can still resolve its own package;
        # SYSTEM/TrustedInstaller and elevated callers use the all-users view.
        Write-Verbose "The all-users Desktop App Installer query was unavailable: $($_.Exception.Message)"
    }
    $packages = @($packages | Sort-Object -Property Version -Descending -Unique)

    $expectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
    foreach ($package in $packages) {
        if ([string]::IsNullOrWhiteSpace($package.InstallLocation)) {
            continue
        }
        if ($package.Name -ne 'Microsoft.DesktopAppInstaller' -or
            $package.PublisherId -ne '8wekyb3d8bbwe' -or
            $package.PackageFamilyName -ne 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -or
            $package.Publisher -ne $expectedPublisher -or
            $package.SignatureKind.ToString() -ne 'Store') {
            continue
        }

        $installLocation = [IO.Path]::GetFullPath([string]$package.InstallLocation).TrimEnd('\') + '\'
        if (-not $installLocation.StartsWith($windowsAppsRoot, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $wingetPath = Join-Path -Path $package.InstallLocation -ChildPath 'winget.exe'
        if (-not (Test-Path -LiteralPath $wingetPath -PathType Leaf)) {
            continue
        }

        $winget = Get-Item -LiteralPath $wingetPath -Force -ErrorAction Stop
        if (($winget.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            continue
        }

        $signature = Get-AuthenticodeSignature -LiteralPath $winget.FullName
        if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
            $null -eq $signature.SignerCertificate -or
            $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Corporation(,|$)') {
            continue
        }

        return $winget.FullName
    }

    throw 'A Microsoft-signed WinGet executable could not be resolved from the protected Desktop App Installer package.'
}

function Test-AtlasCanonicalWingetSource {
    <#
    .SYNOPSIS
        Returns whether a WinGet source export exactly matches Microsoft's
        canonical registration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Source,

        [Parameter(Mandatory = $true)]
        [ValidateSet('winget', 'msstore')]
        [string]$Name
    )

    <#
        These values are the default source records published by Microsoft. Checking
        the complete record prevents a same-named user source from redirecting an
        elevated install to a different endpoint or source implementation.
    #>
    $expectedSources = @{
        winget  = @{
            Name       = 'winget'
            Type       = 'Microsoft.PreIndexed.Package'
            Arg        = 'https://cdn.winget.microsoft.com/cache'
            Data       = 'Microsoft.Winget.Source_8wekyb3d8bbwe'
            Identifier = 'Microsoft.Winget.Source_8wekyb3d8bbwe'
            TrustLevel = 'StoreOrigin|Trusted'
            Explicit   = $false
        }
        msstore = @{
            Name       = 'msstore'
            Type       = 'Microsoft.Rest'
            Arg        = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0'
            Data       = ''
            Identifier = 'StoreEdgeFD'
            TrustLevel = 'Trusted'
            Explicit   = $false
        }
    }

    foreach ($propertyName in @('Name', 'Type', 'Arg', 'Data', 'Identifier', 'TrustLevel', 'Explicit')) {
        if ($null -eq $Source.PSObject.Properties[$propertyName]) {
            return $false
        }
    }

    $expected = $expectedSources[$Name]
    $actualTrustLevel = @($Source.TrustLevel | Sort-Object) -join '|'
    if ($Source.Name -cne $expected.Name -or
        $Source.Type -cne $expected.Type -or
        $Source.Arg -cne $expected.Arg -or
        [string]$Source.Data -cne $expected.Data -or
        $Source.Identifier -cne $expected.Identifier -or
        $actualTrustLevel -cne $expected.TrustLevel -or
        $Source.Explicit -isnot [bool] -or
        $Source.Explicit -ne $expected.Explicit) {
        return $false
    }

    return $true
}

function Assert-AtlasTrustedWingetSource {
    <#
    .SYNOPSIS
        Fails unless a named WinGet source matches Microsoft's canonical registration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WingetPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('winget', 'msstore')]
        [string]$Name
    )

    $sourceOutput = @(& $WingetPath source export $Name --disable-interactivity 2>&1)
    $sourceExitCode = $LASTEXITCODE
    if ($sourceExitCode -ne 0) {
        throw "WinGet could not export source '$Name' (exit code $sourceExitCode)."
    }

    $sourceText = @($sourceOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    try {
        $source = $sourceText | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "WinGet returned an invalid source export for '$Name': $($_.Exception.Message)"
    }

    if (-not (Test-AtlasCanonicalWingetSource -Source $source -Name $Name)) {
        throw "WinGet source '$Name' does not match Microsoft's canonical registration. Refusing the privileged package operation."
    }
}
