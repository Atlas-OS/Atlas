# Atlas.Core domain: fixed, noninteractive TrustedInstaller process creation.
#
# The public Atlas API never accepts an executable, script path, command line, or argv.
# This file is the final defense-in-depth boundary: the native request class contains
# only the three closed operations that Atlas currently supports, and the C# code maps
# those operations to fixed, protected files before creating a process.  The launcher
# deliberately has no LSASS/winlogon/generic-SYSTEM fallback.

$script:AtlasTrustedInstallerNativeTypeLoaded = $false

function Add-AtlasTrustedInstallerNativeType {
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

    # Windows PowerShell 5.1 exposes the from-birth DirectorySecurity overload. A future
    # high-integrity host without it must fail closed instead of compiling through a
    # requester-writable temp directory.
    $createWithSecurity = [IO.Directory].GetMethod(
        'CreateDirectory',
        [type[]]@([string], [Security.AccessControl.DirectorySecurity])
    )
    if (-not $createWithSecurity) {
        throw 'A protected from-birth compiler directory is unavailable in this high-integrity PowerShell host.'
    }

    $windowsDirectory = [Environment]::GetFolderPath('Windows')
    $systemProfile = Join-Path -Path $windowsDirectory -ChildPath 'System32\config\systemprofile'
    if (-not (Test-Path -LiteralPath $systemProfile -PathType Container) -or
        ((Get-Item -LiteralPath $systemProfile -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Protected system-profile compiler parent '$systemProfile' is unavailable."
    }

    $security = New-Object Security.AccessControl.DirectorySecurity
    $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $system = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
    $security.SetOwner($administrators)
    $security.SetAccessRuleProtection($true, $false)
    $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit
    foreach ($sid in @($system, $administrators)) {
        $security.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        )))
    }

    $compilerTemp = Join-Path -Path $systemProfile -ChildPath ('AtlasCompiler-' + [guid]::NewGuid().ToString('N'))
    $originalTemp = $env:TEMP
    $originalTmp = $env:TMP
    try {
        if (Test-Path -LiteralPath $compilerTemp) {
            throw "Random protected compiler directory '$compilerTemp' unexpectedly exists."
        }
        $createArguments = [object[]]@(
            [string]$compilerTemp,
            $security.PSObject.BaseObject
        )
        [void]$createWithSecurity.Invoke($null, $createArguments)
        $env:TEMP = $compilerTemp
        $env:TMP = $compilerTemp
        Add-Type -TypeDefinition $TypeDefinition -Language CSharp -ErrorAction Stop
    }
    finally {
        $env:TEMP = $originalTemp
        $env:TMP = $originalTmp
        if (Test-Path -LiteralPath $compilerTemp -PathType Container) {
            [IO.Directory]::Delete($compilerTemp, $true)
        }
    }
}

function Initialize-AtlasTrustedInstallerNativeType {
    if ($script:AtlasTrustedInstallerNativeTypeLoaded -or ('Atlas.TrustedInstallerProcessNative' -as [type])) {
        $script:AtlasTrustedInstallerNativeTypeLoaded = $true
        return
    }

    $signature = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using Microsoft.Win32.SafeHandles;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;

namespace Atlas {
    public sealed class TrustedInstallerTokenEvidence {
        public string UserSid { get; internal set; }
        public string TrustedInstallerSid { get; internal set; }
        public bool IsSystem { get; internal set; }
        public bool HasEnabledTrustedInstallerSid { get; internal set; }
        public bool IsSystemIntegrity { get; internal set; }
        public int IntegrityRid { get; internal set; }
        public int SessionId { get; internal set; }
        public string AuthenticationId { get; internal set; }

        public bool IsTrustedInstaller {
            get { return IsSystem && HasEnabledTrustedInstallerSid && IsSystemIntegrity; }
        }
    }

    public sealed class TrustedInstallerLaunchRequest {
        public string Operation { get; set; }
        public string AtlasModulesPath { get; set; }
        public string ToggleName { get; set; }
        public string ToggleState { get; set; }
        public bool Silent { get; set; }
        public bool JustContext { get; set; }
        public bool NoExplorerRestart { get; set; }
        public bool MachineOnly { get; set; }
        public string RestoreSource { get; set; }
        public int TimeoutMilliseconds { get; set; }
    }

    public sealed class TrustedInstallerLaunchResult {
        public string Status { get; internal set; }
        public UInt32 ExitCodeUInt32 { get; internal set; }
        public int RootProcessId { get; internal set; }
        public int SourceProcessId { get; internal set; }
        public TrustedInstallerTokenEvidence SourceToken { get; internal set; }
        public TrustedInstallerTokenEvidence ChildToken { get; internal set; }
        public bool RootExited { get; internal set; }
        public bool JobDrained { get; internal set; }
    }

    public static class TrustedInstallerProcessNative {
        const UInt32 TOKEN_ASSIGN_PRIMARY = 0x0001;
        const UInt32 TOKEN_DUPLICATE = 0x0002;
        const UInt32 TOKEN_QUERY = 0x0008;
        const UInt32 TOKEN_ADJUST_PRIVILEGES = 0x0020;
        const UInt32 SE_PRIVILEGE_ENABLED = 0x00000002;
        const UInt32 SE_GROUP_ENABLED = 0x00000004;
        const UInt32 SE_GROUP_USE_FOR_DENY_ONLY = 0x00000010;
        const int ERROR_INSUFFICIENT_BUFFER = 122;
        const int ERROR_NOT_ALL_ASSIGNED = 1300;
        const int ERROR_SERVICE_ALREADY_RUNNING = 1056;
        const UInt32 SC_MANAGER_CONNECT = 0x0001;
        const UInt32 SERVICE_QUERY_STATUS = 0x0004;
        const UInt32 SERVICE_START = 0x0010;
        const UInt32 SERVICE_STOPPED = 0x00000001;
        const UInt32 SERVICE_START_PENDING = 0x00000002;
        const UInt32 SERVICE_RUNNING = 0x00000004;
        const int SC_STATUS_PROCESS_INFO = 0;
        const UInt32 PROCESS_CREATE_PROCESS = 0x0080;
        const UInt32 PROCESS_QUERY_INFORMATION = 0x0400;
        const UInt32 PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;
        const UInt32 SYNCHRONIZE = 0x00100000;
        const UInt32 CREATE_SUSPENDED = 0x00000004;
        const UInt32 CREATE_UNICODE_ENVIRONMENT = 0x00000400;
        const UInt32 CREATE_NO_WINDOW = 0x08000000;
        const UInt32 EXTENDED_STARTUPINFO_PRESENT = 0x00080000;
        const UInt32 PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = 0x00020000;
        const UInt32 PROC_THREAD_ATTRIBUTE_JOB_LIST = 0x0002000D;
        const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
        const int JobObjectBasicAndIoAccountingInformation = 8;
        const int JobObjectExtendedLimitInformation = 9;
        const UInt32 WAIT_OBJECT_0 = 0;
        const UInt32 WAIT_TIMEOUT = 258;
        const UInt32 WAIT_FAILED = 0xFFFFFFFF;
        const UInt32 STILL_ACTIVE = 259;
        const UInt32 FILE_ATTRIBUTE_REPARSE_POINT = 0x00000400;
        const UInt32 FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000;
        const UInt32 FILE_SHARE_READ = 0x00000001;
        const UInt32 FILE_SHARE_WRITE = 0x00000002;
        const UInt32 FILE_READ_ATTRIBUTES = 0x00000080;
        const UInt32 READ_CONTROL = 0x00020000;
        const UInt32 OPEN_EXISTING = 3;
        const UInt32 GENERIC_READ = 0x80000000;
        const UInt32 INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF;
        const UInt32 SECURITY_MANDATORY_SYSTEM_RID = 0x00004000;
        const UInt32 MAX_REQUEST_MILLISECONDS = 86400000;

        enum TOKEN_INFORMATION_CLASS {
            TokenUser = 1,
            TokenStatistics = 10,
            TokenSessionId = 12,
            TokenElevation = 20,
            TokenIntegrityLevel = 25
        }

        [StructLayout(LayoutKind.Sequential)]
        struct LUID { public UInt32 LowPart; public Int32 HighPart; }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_PRIVILEGES_ONE {
            public UInt32 PrivilegeCount;
            public LUID Luid;
            public UInt32 Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_STATISTICS {
            public LUID TokenId;
            public LUID AuthenticationId;
            public Int64 ExpirationTime;
            public Int32 TokenType;
            public Int32 ImpersonationLevel;
            public UInt32 DynamicCharged;
            public UInt32 DynamicAvailable;
            public UInt32 GroupCount;
            public UInt32 PrivilegeCount;
            public LUID ModifiedId;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct FILE_ATTRIBUTE_TAG_INFO {
            public UInt32 FileAttributes;
            public UInt32 ReparseTag;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct SERVICE_STATUS_PROCESS {
            public UInt32 dwServiceType;
            public UInt32 dwCurrentState;
            public UInt32 dwControlsAccepted;
            public UInt32 dwWin32ExitCode;
            public UInt32 dwServiceSpecificExitCode;
            public UInt32 dwCheckPoint;
            public UInt32 dwWaitHint;
            public UInt32 dwProcessId;
            public UInt32 dwServiceFlags;
        }

        [StructLayout(LayoutKind.Sequential)]
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
            public Int32 dwFlags;
            public UInt16 wShowWindow;
            public UInt16 cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct STARTUPINFOEX {
            public STARTUPINFO StartupInfo;
            public IntPtr lpAttributeList;
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

        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentProcess();

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr OpenProcess(UInt32 dwDesiredAccess, bool bInheritHandle, UInt32 dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool QueryFullProcessImageName(IntPtr hProcess, UInt32 dwFlags, StringBuilder lpExeName, ref UInt32 lpdwSize);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(IntPtr ProcessHandle, UInt32 DesiredAccess, out IntPtr TokenHandle);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(IntPtr TokenHandle, TOKEN_INFORMATION_CLASS TokenInformationClass, IntPtr TokenInformation, Int32 TokenInformationLength, out Int32 ReturnLength);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES_ONE NewState, Int32 BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool LookupAccountName(string lpSystemName, string lpAccountName, IntPtr Sid, ref UInt32 cbSid, StringBuilder ReferencedDomainName, ref UInt32 cchReferencedDomainName, out Int32 peUse);

        [DllImport("advapi32.dll", EntryPoint = "ConvertSidToStringSidW", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool ConvertSidToStringSid(IntPtr Sid, out IntPtr StringSid);

        [DllImport("kernel32.dll")]
        static extern IntPtr LocalFree(IntPtr hMem);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern IntPtr OpenSCManager(string lpMachineName, string lpDatabaseName, UInt32 dwDesiredAccess);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern IntPtr OpenService(IntPtr hSCManager, string lpServiceName, UInt32 dwDesiredAccess);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool StartService(IntPtr hService, UInt32 dwNumServiceArgs, IntPtr lpServiceArgVectors);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool QueryServiceStatusEx(IntPtr hService, Int32 InfoLevel, out SERVICE_STATUS_PROCESS lpBuffer, Int32 cbBufSize, out Int32 pcbBytesNeeded);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool CloseServiceHandle(IntPtr hSCObject);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern UInt32 GetWindowsDirectory(StringBuilder lpBuffer, UInt32 uSize);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern UInt32 GetSystemDirectory(StringBuilder lpBuffer, UInt32 uSize);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string lpName);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool SetInformationJobObject(IntPtr hJob, Int32 JobObjectInfoClass, ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION lpJobObjectInfo, Int32 cbJobObjectInfoLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool QueryInformationJobObject(IntPtr hJob, Int32 JobObjectInfoClass, out JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION lpJobObjectInfo, Int32 cbJobObjectInfoLength, out Int32 lpReturnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool InitializeProcThreadAttributeList(IntPtr lpAttributeList, Int32 dwAttributeCount, UInt32 dwFlags, ref UIntPtr lpSize);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool UpdateProcThreadAttribute(IntPtr lpAttributeList, UInt32 dwFlags, UIntPtr Attribute, IntPtr lpValue, UIntPtr cbSize, IntPtr lpPreviousValue, IntPtr lpReturnSize);

        [DllImport("kernel32.dll")]
        static extern void DeleteProcThreadAttributeList(IntPtr lpAttributeList);

        [DllImport("kernel32.dll", EntryPoint = "CreateProcessW", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool CreateProcess(string lpApplicationName, StringBuilder lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, UInt32 dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFOEX lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool IsProcessInJob(IntPtr ProcessHandle, IntPtr JobHandle, out bool Result);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 ResumeThread(IntPtr hThread);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetExitCodeProcess(IntPtr hProcess, out UInt32 lpExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateJobObject(IntPtr hJob, UInt32 uExitCode);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern IntPtr CreateFile(string lpFileName, UInt32 dwDesiredAccess, UInt32 dwShareMode, IntPtr lpSecurityAttributes, UInt32 dwCreationDisposition, UInt32 dwFlagsAndAttributes, IntPtr hTemplateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 GetFileType(IntPtr hFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetFileInformationByHandleEx(IntPtr hFile, Int32 FileInformationClass, out FILE_ATTRIBUTE_TAG_INFO lpFileInformation, UInt32 dwBufferSize);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern UInt32 GetFinalPathNameByHandle(IntPtr hFile, StringBuilder lpszFilePath, UInt32 cchFilePath, UInt32 dwFlags);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern UInt32 GetFileAttributes(string lpFileName);

        static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
        public static TrustedInstallerTokenEvidence GetCurrentTokenEvidence() {
            IntPtr token = IntPtr.Zero;
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY | TOKEN_DUPLICATE, out token)) {
                throw LastError("OpenProcessToken(current) failed");
            }
            try {
                return ReadTokenEvidence(token);
            }
            finally {
                CloseHandle(token);
            }
        }

        public static bool IsStrictTrustedInstallerEvidence(string userSid, bool trustedInstallerGroupPresent, UInt32 trustedInstallerGroupAttributes, int integrityRid) {
            bool isSystem = String.Equals(userSid, "S-1-5-18", StringComparison.OrdinalIgnoreCase);
            bool enabled = trustedInstallerGroupPresent &&
                (trustedInstallerGroupAttributes & SE_GROUP_ENABLED) != 0 &&
                (trustedInstallerGroupAttributes & SE_GROUP_USE_FOR_DENY_ONLY) == 0;
            return isSystem && enabled && integrityRid == unchecked((int)SECURITY_MANDATORY_SYSTEM_RID);
        }

        public static string QuoteWindowsArgument(string value) {
            if (value == null) {
                throw new ArgumentNullException("value");
            }
            if (value.Length == 0) {
                return "\"\"";
            }
            bool requiresQuotes = false;
            for (int i = 0; i < value.Length; i++) {
                char c = value[i];
                if (char.IsWhiteSpace(c) || c == '"') {
                    requiresQuotes = true;
                    break;
                }
            }
            if (!requiresQuotes) {
                return value;
            }

            StringBuilder output = new StringBuilder();
            output.Append('"');
            int backslashes = 0;
            for (int i = 0; i < value.Length; i++) {
                char c = value[i];
                if (c == '\\') {
                    backslashes++;
                    continue;
                }
                if (c == '"') {
                    output.Append('\\', backslashes * 2 + 1);
                    output.Append('"');
                    backslashes = 0;
                    continue;
                }
                if (backslashes != 0) {
                    output.Append('\\', backslashes);
                    backslashes = 0;
                }
                output.Append(c);
            }
            if (backslashes != 0) {
                output.Append('\\', backslashes * 2);
            }
            output.Append('"');
            return output.ToString();
        }

        public static string BuildWindowsCommandLine(string applicationPath, string[] arguments) {
            if (String.IsNullOrWhiteSpace(applicationPath)) {
                throw new ArgumentException("An explicit application path is required.", "applicationPath");
            }
            List<string> values = new List<string>();
            values.Add(applicationPath);
            if (arguments != null) {
                values.AddRange(arguments);
            }
            if (values.Count > 129) {
                throw new ArgumentOutOfRangeException("arguments", "At most 128 arguments are supported.");
            }
            StringBuilder commandLine = new StringBuilder();
            for (int i = 0; i < values.Count; i++) {
                if (values[i] == null || values[i].IndexOf('\0') >= 0) {
                    throw new ArgumentException("Arguments must be non-null and cannot contain NUL.", "arguments");
                }
                if (i != 0) {
                    commandLine.Append(' ');
                }
                commandLine.Append(QuoteWindowsArgument(values[i]));
            }
            if (commandLine.Length > 32766) {
                throw new ArgumentOutOfRangeException("arguments", "The Windows command line exceeds 32,766 characters.");
            }
            return commandLine.ToString();
        }

        public static TrustedInstallerLaunchResult LaunchNonInteractive(TrustedInstallerLaunchRequest request) {
            if (request == null) {
                throw new ArgumentNullException("request");
            }
            if (IntPtr.Size != 8) {
                throw new PlatformNotSupportedException("Atlas TrustedInstaller process creation requires a 64-bit PowerShell host.");
            }
            if (!Environment.Is64BitOperatingSystem || !Environment.Is64BitProcess) {
                throw new PlatformNotSupportedException("WoW64 process creation is not supported for the TrustedInstaller boundary.");
            }
            if (request.TimeoutMilliseconds < 1 || (UInt32)request.TimeoutMilliseconds > MAX_REQUEST_MILLISECONDS) {
                throw new ArgumentOutOfRangeException("request.TimeoutMilliseconds", "Timeout must be between 1 millisecond and 24 hours.");
            }
            RequireElevatedAdministrator();
            EnablePrivilege("SeDebugPrivilege");

            Stopwatch stopwatch = Stopwatch.StartNew();
            string windowsDirectory = GetNativeDirectory(true);
            string systemDirectory = GetNativeDirectory(false);
            string expectedAtlasRoot = Path.GetFullPath(Path.Combine(windowsDirectory, "AtlasModules"));
            string atlasRoot = RequireExactPath(request.AtlasModulesPath, expectedAtlasRoot, "AtlasModulesPath");
            string workingDirectory = systemDirectory;

            string applicationPath = null;
            string[] arguments = null;
            List<IDisposable> heldObjects = new List<IDisposable>();
            IntPtr scm = IntPtr.Zero;
            IntPtr service = IntPtr.Zero;
            IntPtr sourceProcess = IntPtr.Zero;
            IntPtr sourceToken = IntPtr.Zero;
            IntPtr job = IntPtr.Zero;
            IntPtr attributeList = IntPtr.Zero;
            IntPtr parentValue = IntPtr.Zero;
            IntPtr jobValue = IntPtr.Zero;
            IntPtr environment = IntPtr.Zero;
            PROCESS_INFORMATION processInfo = new PROCESS_INFORMATION();
            bool childCreated = false;
            bool jobDrained = false;
            try {
                ResolveOperation(request, atlasRoot, windowsDirectory, systemDirectory, out applicationPath, out arguments, heldObjects);
                UInt32 sourcePid = StartAndValidateTrustedInstallerService(request, stopwatch, out scm, out service, out sourceProcess, out sourceToken);
                TrustedInstallerTokenEvidence sourceEvidence = ReadTokenEvidence(sourceToken);

                job = CreateJobObject(IntPtr.Zero, null);
                if (job == IntPtr.Zero) {
                    throw LastError("CreateJobObject failed");
                }
                JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
                limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
                if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation, ref limits, Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION)))) {
                    throw LastError("SetInformationJobObject(KILL_ON_JOB_CLOSE) failed");
                }

                UIntPtr attributeBytes = UIntPtr.Zero;
                InitializeProcThreadAttributeList(IntPtr.Zero, 2, 0, ref attributeBytes);
                int initialError = Marshal.GetLastWin32Error();
                if (attributeBytes == UIntPtr.Zero || (initialError != ERROR_INSUFFICIENT_BUFFER && initialError != 0)) {
                    throw new Win32Exception(initialError, "InitializeProcThreadAttributeList(size) failed.");
                }
                attributeList = Marshal.AllocHGlobal(checked((int)attributeBytes.ToUInt64()));
                if (!InitializeProcThreadAttributeList(attributeList, 2, 0, ref attributeBytes)) {
                    throw LastError("InitializeProcThreadAttributeList failed");
                }
                parentValue = Marshal.AllocHGlobal(IntPtr.Size);
                Marshal.WriteIntPtr(parentValue, sourceProcess);
                if (!UpdateProcThreadAttribute(attributeList, 0, new UIntPtr(PROC_THREAD_ATTRIBUTE_PARENT_PROCESS), parentValue, new UIntPtr((UInt32)IntPtr.Size), IntPtr.Zero, IntPtr.Zero)) {
                    throw LastError("UpdateProcThreadAttribute(PARENT_PROCESS) failed");
                }
                // PARENT_PROCESS supplies the TrustedInstaller token and session. Assign
                // the child atomically to the broker-owned kill-on-close job.
                int jobListBytes = checked(IntPtr.Size);
                jobValue = Marshal.AllocHGlobal(jobListBytes);
                Marshal.WriteIntPtr(jobValue, job);
                if (!UpdateProcThreadAttribute(attributeList, 0, new UIntPtr(PROC_THREAD_ATTRIBUTE_JOB_LIST), jobValue, new UIntPtr(unchecked((UInt32)jobListBytes)), IntPtr.Zero, IntPtr.Zero)) {
                    throw LastError("UpdateProcThreadAttribute(JOB_LIST) failed");
                }

                RevalidateService(service, sourcePid);
                ValidateProcessImage(sourceProcess, Path.Combine(windowsDirectory, "servicing", "TrustedInstaller.exe"), "TrustedInstaller service");
                RequireTrustedInstaller(ReadTokenEvidence(sourceToken), "TrustedInstaller service token");

                string environmentText = BuildSanitizedEnvironment(windowsDirectory, systemDirectory, atlasRoot, workingDirectory);
                environment = Marshal.StringToHGlobalUni(environmentText);
                STARTUPINFOEX startup = new STARTUPINFOEX();
                startup.StartupInfo.cb = Marshal.SizeOf(typeof(STARTUPINFOEX));
                startup.lpAttributeList = attributeList;
                StringBuilder commandLine = new StringBuilder(BuildWindowsCommandLine(applicationPath, arguments));
                UInt32 creationFlags = CREATE_SUSPENDED | CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW | EXTENDED_STARTUPINFO_PRESENT;
                ThrowIfDeadlineExceeded(stopwatch, request.TimeoutMilliseconds);
                bool created = CreateProcess(applicationPath, commandLine, IntPtr.Zero, IntPtr.Zero, false, creationFlags, environment, systemDirectory, ref startup, out processInfo);
                if (!created) {
                    throw LastError("CreateProcessW with atomic parent and inner job attributes failed");
                }
                childCreated = true;

                ValidateProcessImage(processInfo.hProcess, applicationPath, "suspended child");
                IntPtr childToken = IntPtr.Zero;
                TrustedInstallerTokenEvidence childEvidence;
                try {
                    if (!OpenProcessToken(processInfo.hProcess, TOKEN_QUERY | TOKEN_DUPLICATE, out childToken)) {
                        throw LastError("OpenProcessToken(child) failed");
                    }
                    childEvidence = ReadTokenEvidence(childToken);
                    RequireTrustedInstaller(childEvidence, "suspended child token");
                }
                finally {
                    if (childToken != IntPtr.Zero) {
                        CloseHandle(childToken);
                    }
                }

                bool inAtlasJob;
                if (!IsProcessInJob(processInfo.hProcess, job, out inAtlasJob)) {
                    throw LastError("IsProcessInJob(child, inner job) failed");
                }
                if (!inAtlasJob) {
                    throw new InvalidOperationException("The suspended TrustedInstaller child was not created in the Atlas kill-on-close job.");
                }

                ThrowIfDeadlineExceeded(stopwatch, request.TimeoutMilliseconds);
                UInt32 previousSuspendCount = ResumeThread(processInfo.hThread);
                if (previousSuspendCount == UInt32.MaxValue) {
                    throw LastError("ResumeThread(child) failed");
                }
                if (previousSuspendCount != 1) {
                    throw new InvalidOperationException(String.Format(
                        "The TrustedInstaller child had unexpected suspend count {0}; expected exactly one.",
                        previousSuspendCount));
                }
                bool rootExited = false;
                UInt32 exitCode = STILL_ACTIVE;
                while (true) {
                    ThrowIfDeadlineExceeded(stopwatch, request.TimeoutMilliseconds);
                    if (!rootExited) {
                        UInt32 rootWait = WaitForSingleObject(processInfo.hProcess, 0);
                        if (rootWait == WAIT_OBJECT_0) {
                            if (!GetExitCodeProcess(processInfo.hProcess, out exitCode)) {
                                throw LastError("GetExitCodeProcess(root) failed");
                            }
                            rootExited = true;

                            // Capture the terminal root exit value, then release Atlas's
                            // PROCESS_INFORMATION references before the lifecycle advances to
                            // its authoritative job-accounting drain check.
                            CloseProcessInformationHandles(ref processInfo);
                        }
                        else if (rootWait == WAIT_FAILED) {
                            throw LastError("WaitForSingleObject(root) failed");
                        }
                    }

                    UInt32 activeProcesses = QueryActiveProcesses(job);
                    if (rootExited && activeProcesses == 0) {
                        jobDrained = true;
                        return new TrustedInstallerLaunchResult {
                            Status = "Completed",
                            ExitCodeUInt32 = exitCode,
                            RootProcessId = checked((int)processInfo.dwProcessId),
                            SourceProcessId = checked((int)sourcePid),
                            SourceToken = sourceEvidence,
                            ChildToken = childEvidence,
                            RootExited = true,
                            JobDrained = true
                        };
                    }
                    System.Threading.Thread.Sleep(50);
                }
            }
            catch {
                if (job != IntPtr.Zero && childCreated && !jobDrained) {
                    try {
                        try {
                            if (!TerminateJobObject(job, 0xC000013A)) {
                                throw LastError("TerminateJobObject failed while containing a failed TrustedInstaller operation");
                            }
                        }
                        finally {
                            // Release both PROCESS_INFORMATION references before the bounded
                            // post-termination drain so the ownership order stays unambiguous.
                            CloseProcessInformationHandles(ref processInfo);
                        }
                        DrainTerminatedJob(job, 10000);
                        jobDrained = true;
                    }
                    catch (Exception drainFailure) {
                        throw new InvalidOperationException(
                            "The TrustedInstaller operation failed and Atlas could not authoritatively confirm that its privileged process tree drained.",
                            drainFailure
                        );
                    }
                }
                throw;
            }
            finally {
                if (processInfo.hThread != IntPtr.Zero) CloseHandle(processInfo.hThread);
                if (processInfo.hProcess != IntPtr.Zero) CloseHandle(processInfo.hProcess);
                if (environment != IntPtr.Zero) Marshal.FreeHGlobal(environment);
                if (attributeList != IntPtr.Zero) {
                    DeleteProcThreadAttributeList(attributeList);
                    Marshal.FreeHGlobal(attributeList);
                }
                if (jobValue != IntPtr.Zero) Marshal.FreeHGlobal(jobValue);
                if (parentValue != IntPtr.Zero) Marshal.FreeHGlobal(parentValue);
                if (job != IntPtr.Zero) CloseHandle(job);
                if (sourceToken != IntPtr.Zero) CloseHandle(sourceToken);
                if (sourceProcess != IntPtr.Zero) CloseHandle(sourceProcess);
                if (service != IntPtr.Zero) CloseServiceHandle(service);
                if (scm != IntPtr.Zero) CloseServiceHandle(scm);
                for (int i = heldObjects.Count - 1; i >= 0; i--) {
                    heldObjects[i].Dispose();
                }
            }
        }

        static void ResolveOperation(TrustedInstallerLaunchRequest request, string atlasRoot, string windowsDirectory, string systemDirectory, out string applicationPath, out string[] arguments, List<IDisposable> heldObjects) {
            if (String.Equals(request.Operation, "Toggle", StringComparison.Ordinal)) {
                RequireBoundedScalar(request.ToggleName, "ToggleName", 128, false);
                RequireBoundedScalar(request.ToggleState, "ToggleState", 128, false);
                if (!request.Silent) {
                    throw new ArgumentException("The initial noninteractive Toggle operation requires Silent=true.");
                }
                applicationPath = Path.Combine(systemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe");
                string scriptPath = Path.Combine(atlasRoot, "Scripts", "Invoke-Toggle.ps1");
                heldObjects.Add(OpenProtectedFile(applicationPath, true, null));
                heldObjects.Add(OpenProtectedFile(scriptPath, true, atlasRoot));
                List<string> values = new List<string>();
                values.Add("-NoLogo");
                values.Add("-NoProfile");
                values.Add("-NonInteractive");
                values.Add("-ExecutionPolicy");
                values.Add("Bypass");
                values.Add("-File");
                values.Add(scriptPath);
                values.Add("-Name");
                values.Add(request.ToggleName);
                values.Add("-State");
                values.Add(request.ToggleState);
                if (request.Silent) values.Add("/silent");
                if (request.JustContext) values.Add("/justcontext");
                if (request.NoExplorerRestart) values.Add("/noaction");
                if (request.MachineOnly) values.Add("-MachineOnly");
                arguments = values.ToArray();
                return;
            }

            if (String.Equals(request.Operation, "ResetServices", StringComparison.Ordinal)) {
                if (!String.Equals(request.RestoreSource, "ToggleDefaults", StringComparison.Ordinal) &&
                    !String.Equals(request.RestoreSource, "WindowsBackup", StringComparison.Ordinal) &&
                    !String.Equals(request.RestoreSource, "AtlasBackup", StringComparison.Ordinal)) {
                    throw new ArgumentException("ResetServices RestoreSource is outside the closed operation schema.");
                }
                applicationPath = Path.Combine(systemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe");
                string scriptPath = Path.Combine(atlasRoot, "Scripts", "Internal", "Invoke-AtlasResetServices.ps1");
                heldObjects.Add(OpenProtectedFile(applicationPath, true, null));
                heldObjects.Add(OpenProtectedFile(scriptPath, true, atlasRoot));
                arguments = new string[] {
                    "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                    "-File", scriptPath, "-RestoreSource", request.RestoreSource
                };
                return;
            }

            throw new ArgumentException("The operation is outside the closed TrustedInstaller operation schema.", "request.Operation");
        }

        static UInt32 StartAndValidateTrustedInstallerService(TrustedInstallerLaunchRequest request, Stopwatch stopwatch, out IntPtr scm, out IntPtr service, out IntPtr sourceProcess, out IntPtr sourceToken) {
            scm = IntPtr.Zero;
            service = IntPtr.Zero;
            sourceProcess = IntPtr.Zero;
            sourceToken = IntPtr.Zero;
            ThrowIfDeadlineExceeded(stopwatch, request.TimeoutMilliseconds);
            scm = OpenSCManager(null, null, SC_MANAGER_CONNECT);
            if (scm == IntPtr.Zero) throw LastError("OpenSCManager failed");
            service = OpenService(scm, "TrustedInstaller", SERVICE_QUERY_STATUS | SERVICE_START);
            if (service == IntPtr.Zero) throw LastError("OpenService(TrustedInstaller) failed");

            SERVICE_STATUS_PROCESS status = QueryService(service);
            if (status.dwCurrentState == SERVICE_STOPPED) {
                ThrowIfDeadlineExceeded(stopwatch, request.TimeoutMilliseconds);
                if (!StartService(service, 0, IntPtr.Zero)) {
                    int error = Marshal.GetLastWin32Error();
                    if (error != ERROR_SERVICE_ALREADY_RUNNING) {
                        throw new Win32Exception(error, "StartService(TrustedInstaller) failed.");
                    }
                }
            }

            while (true) {
                ThrowIfDeadlineExceeded(stopwatch, request.TimeoutMilliseconds);
                status = QueryService(service);
                if (status.dwCurrentState == SERVICE_RUNNING && status.dwProcessId != 0) break;
                if (status.dwCurrentState == SERVICE_STOPPED) {
                    throw new InvalidOperationException(String.Format("TrustedInstaller stopped while starting (Win32 exit {0}, service exit {1}).", status.dwWin32ExitCode, status.dwServiceSpecificExitCode));
                }
                System.Threading.Thread.Sleep(100);
            }

            UInt32 pid = status.dwProcessId;
            sourceProcess = OpenProcess(PROCESS_CREATE_PROCESS | PROCESS_QUERY_INFORMATION | PROCESS_QUERY_LIMITED_INFORMATION | SYNCHRONIZE, false, pid);
            if (sourceProcess == IntPtr.Zero) throw LastError("OpenProcess(TrustedInstaller) failed");
            string windowsDirectory = GetNativeDirectory(true);
            ValidateProcessImage(sourceProcess, Path.Combine(windowsDirectory, "servicing", "TrustedInstaller.exe"), "TrustedInstaller service");
            if (!OpenProcessToken(sourceProcess, TOKEN_QUERY | TOKEN_DUPLICATE, out sourceToken)) {
                throw LastError("OpenProcessToken(TrustedInstaller) failed");
            }
            RequireTrustedInstaller(ReadTokenEvidence(sourceToken), "TrustedInstaller service token");
            RevalidateService(service, pid);
            return pid;
        }

        static void RevalidateService(IntPtr service, UInt32 expectedPid) {
            SERVICE_STATUS_PROCESS status = QueryService(service);
            if (status.dwCurrentState != SERVICE_RUNNING || status.dwProcessId != expectedPid) {
                throw new InvalidOperationException("TrustedInstaller service identity changed before child creation.");
            }
        }

        static SERVICE_STATUS_PROCESS QueryService(IntPtr service) {
            SERVICE_STATUS_PROCESS status;
            Int32 needed;
            if (!QueryServiceStatusEx(service, SC_STATUS_PROCESS_INFO, out status, Marshal.SizeOf(typeof(SERVICE_STATUS_PROCESS)), out needed)) {
                throw LastError("QueryServiceStatusEx(TrustedInstaller) failed");
            }
            return status;
        }

        static TrustedInstallerTokenEvidence ReadTokenEvidence(IntPtr token) {
            string userSid = ReadTokenSid(token, TOKEN_INFORMATION_CLASS.TokenUser);
            string trustedInstallerSid = ResolveAccountSid("NT SERVICE\\TrustedInstaller");
            bool enabledTiSid = HasEnabledGroup(token, trustedInstallerSid);
            int integrityRid = ReadIntegrityRid(token);
            int sessionId = ReadTokenInt32(token, TOKEN_INFORMATION_CLASS.TokenSessionId);
            string authenticationId = ReadAuthenticationId(token);
            return new TrustedInstallerTokenEvidence {
                UserSid = userSid,
                TrustedInstallerSid = trustedInstallerSid,
                IsSystem = String.Equals(userSid, "S-1-5-18", StringComparison.OrdinalIgnoreCase),
                HasEnabledTrustedInstallerSid = enabledTiSid,
                IsSystemIntegrity = integrityRid == unchecked((int)SECURITY_MANDATORY_SYSTEM_RID),
                IntegrityRid = integrityRid,
                SessionId = sessionId,
                AuthenticationId = authenticationId
            };
        }

        static void RequireTrustedInstaller(TrustedInstallerTokenEvidence evidence, string subject) {
            if (!evidence.IsTrustedInstaller) {
                throw new InvalidOperationException(String.Format("{0} is not strict TrustedInstaller (user={1}, enabledTiSid={2}, integrity=0x{3:X}).", subject, evidence.UserSid, evidence.HasEnabledTrustedInstallerSid, evidence.IntegrityRid));
            }
        }

        static string ReadTokenSid(IntPtr token, TOKEN_INFORMATION_CLASS informationClass) {
            IntPtr buffer = GetTokenBuffer(token, informationClass);
            try {
                IntPtr sid = Marshal.ReadIntPtr(buffer);
                return SidToString(sid);
            }
            finally {
                Marshal.FreeHGlobal(buffer);
            }
        }

        static bool HasEnabledGroup(IntPtr token, string expectedSid) {
            SecurityIdentifier sid = new SecurityIdentifier(expectedSid);
            using (WindowsIdentity identity = new WindowsIdentity(token)) {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(sid);
            }
        }

        static int ReadIntegrityRid(IntPtr token) {
            IntPtr buffer = GetTokenBuffer(token, TOKEN_INFORMATION_CLASS.TokenIntegrityLevel);
            try {
                IntPtr sid = Marshal.ReadIntPtr(buffer);
                byte subAuthorityCount = Marshal.ReadByte(sid, 1);
                if (subAuthorityCount == 0) throw new InvalidOperationException("Token integrity SID has no subauthority.");
                return Marshal.ReadInt32(sid, 8 + (subAuthorityCount - 1) * 4);
            }
            finally {
                Marshal.FreeHGlobal(buffer);
            }
        }

        static int ReadTokenInt32(IntPtr token, TOKEN_INFORMATION_CLASS informationClass) {
            IntPtr buffer = GetTokenBuffer(token, informationClass);
            try { return Marshal.ReadInt32(buffer); }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static string ReadAuthenticationId(IntPtr token) {
            IntPtr buffer = GetTokenBuffer(token, TOKEN_INFORMATION_CLASS.TokenStatistics);
            try {
                TOKEN_STATISTICS statistics = (TOKEN_STATISTICS)Marshal.PtrToStructure(buffer, typeof(TOKEN_STATISTICS));
                return String.Format("{0:X8}:{1:X8}", unchecked((UInt32)statistics.AuthenticationId.HighPart), statistics.AuthenticationId.LowPart);
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static IntPtr GetTokenBuffer(IntPtr token, TOKEN_INFORMATION_CLASS informationClass) {
            Int32 needed;
            GetTokenInformation(token, informationClass, IntPtr.Zero, 0, out needed);
            int error = Marshal.GetLastWin32Error();
            if (needed <= 0 || error != ERROR_INSUFFICIENT_BUFFER) {
                throw new Win32Exception(error, "GetTokenInformation(size) failed for " + informationClass + ".");
            }
            IntPtr buffer = Marshal.AllocHGlobal(needed);
            if (!GetTokenInformation(token, informationClass, buffer, needed, out needed)) {
                int readError = Marshal.GetLastWin32Error();
                Marshal.FreeHGlobal(buffer);
                throw new Win32Exception(readError, "GetTokenInformation failed for " + informationClass + ".");
            }
            return buffer;
        }

        static string ResolveAccountSid(string accountName) {
            UInt32 sidLength = 0;
            UInt32 domainLength = 0;
            Int32 use;
            LookupAccountName(null, accountName, IntPtr.Zero, ref sidLength, null, ref domainLength, out use);
            int error = Marshal.GetLastWin32Error();
            if (sidLength == 0 || error != ERROR_INSUFFICIENT_BUFFER) {
                throw new Win32Exception(error, "LookupAccountName(size) failed for " + accountName + ".");
            }
            IntPtr sid = Marshal.AllocHGlobal(checked((int)sidLength));
            try {
                StringBuilder domain = new StringBuilder(checked((int)domainLength));
                if (!LookupAccountName(null, accountName, sid, ref sidLength, domain, ref domainLength, out use)) {
                    throw LastError("LookupAccountName failed for " + accountName);
                }
                return SidToString(sid);
            }
            finally {
                Marshal.FreeHGlobal(sid);
            }
        }

        static string SidToString(IntPtr sid) {
            if (sid == IntPtr.Zero) throw new InvalidOperationException("A token contained a null SID pointer.");
            IntPtr text = IntPtr.Zero;
            if (!ConvertSidToStringSid(sid, out text)) throw LastError("ConvertSidToStringSid failed");
            try { return Marshal.PtrToStringUni(text); }
            finally { LocalFree(text); }
        }

        static void RequireElevatedAdministrator() {
            WindowsIdentity identity = WindowsIdentity.GetCurrent();
            WindowsPrincipal principal = new WindowsPrincipal(identity);
            if (!principal.IsInRole(WindowsBuiltInRole.Administrator)) {
                throw new UnauthorizedAccessException("The TrustedInstaller broker requires an elevated Administrator token.");
            }
            IntPtr token = IntPtr.Zero;
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, out token)) throw LastError("OpenProcessToken(elevation) failed");
            try {
                int elevated = ReadTokenInt32(token, TOKEN_INFORMATION_CLASS.TokenElevation);
                if (elevated == 0) throw new UnauthorizedAccessException("The TrustedInstaller broker token is not elevated.");
            }
            finally { CloseHandle(token); }
        }

        static void EnablePrivilege(string name) {
            IntPtr token = IntPtr.Zero;
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out token)) throw LastError("OpenProcessToken(privilege) failed");
            try {
                LUID luid;
                if (!LookupPrivilegeValue(null, name, out luid)) throw LastError("LookupPrivilegeValue(" + name + ") failed");
                TOKEN_PRIVILEGES_ONE privileges = new TOKEN_PRIVILEGES_ONE();
                privileges.PrivilegeCount = 1;
                privileges.Luid = luid;
                privileges.Attributes = SE_PRIVILEGE_ENABLED;
                if (!AdjustTokenPrivileges(token, false, ref privileges, 0, IntPtr.Zero, IntPtr.Zero)) throw LastError("AdjustTokenPrivileges(" + name + ") failed");
                int error = Marshal.GetLastWin32Error();
                if (error == ERROR_NOT_ALL_ASSIGNED) throw new Win32Exception(error, "The broker token does not hold " + name + ".");
            }
            finally { CloseHandle(token); }
        }

        static void ThrowIfDeadlineExceeded(Stopwatch stopwatch, int timeoutMilliseconds) {
            if (stopwatch.ElapsedMilliseconds >= timeoutMilliseconds) throw new TimeoutException("The TrustedInstaller operation exceeded its common deadline.");
        }

        static UInt32 QueryActiveProcesses(IntPtr job) {
            JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION accounting;
            Int32 returned;
            if (!QueryInformationJobObject(job, JobObjectBasicAndIoAccountingInformation, out accounting, Marshal.SizeOf(typeof(JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION)), out returned)) {
                throw LastError("QueryInformationJobObject(accounting) failed");
            }
            return accounting.BasicInfo.ActiveProcesses;
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

        static void DrainTerminatedJob(IntPtr job, int timeoutMilliseconds) {
            Stopwatch stopwatch = Stopwatch.StartNew();
            while (true) {
                if (QueryActiveProcesses(job) == 0) return;
                if (stopwatch.ElapsedMilliseconds >= timeoutMilliseconds) {
                    throw new TimeoutException("The terminated TrustedInstaller process tree did not reach zero active processes within its bounded drain allowance.");
                }
                System.Threading.Thread.Sleep(50);
            }
        }

        static void ValidateProcessImage(IntPtr process, string expectedPath, string subject) {
            StringBuilder path = new StringBuilder(32768);
            UInt32 length = unchecked((UInt32)path.Capacity);
            if (!QueryFullProcessImageName(process, 0, path, ref length)) throw LastError("QueryFullProcessImageName(" + subject + ") failed");
            string actual = Path.GetFullPath(path.ToString());
            string expected = Path.GetFullPath(expectedPath);
            if (!String.Equals(actual, expected, StringComparison.OrdinalIgnoreCase)) {
                throw new InvalidOperationException(String.Format("{0} image mismatch: expected '{1}', got '{2}'.", subject, expected, actual));
            }
        }

        static string GetNativeDirectory(bool windows) {
            StringBuilder path = new StringBuilder(32768);
            UInt32 length = windows ? GetWindowsDirectory(path, unchecked((UInt32)path.Capacity)) : GetSystemDirectory(path, unchecked((UInt32)path.Capacity));
            if (length == 0 || length >= path.Capacity) throw LastError(windows ? "GetWindowsDirectory failed" : "GetSystemDirectory failed");
            return Path.GetFullPath(path.ToString());
        }

        static string BuildSanitizedEnvironment(string windowsDirectory, string systemDirectory, string atlasRoot, string workingDirectory) {
            string systemDrive = Path.GetPathRoot(windowsDirectory).TrimEnd(Path.DirectorySeparatorChar);
            string programData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
            string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            string nativePowerShell = Path.Combine(systemDirectory, "WindowsPowerShell", "v1.0");
            SortedDictionary<string, string> environment = new SortedDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            environment.Add("ALLUSERSPROFILE", programData);
            environment.Add("ComSpec", Path.Combine(systemDirectory, "cmd.exe"));
            environment.Add("PATHEXT", ".COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;.CPL");
            environment.Add("PATH", windowsDirectory + ";" + systemDirectory + ";" + Path.Combine(systemDirectory, "Wbem") + ";" + nativePowerShell);
            environment.Add("ProgramData", programData);
            environment.Add("ProgramFiles", programFiles);
            string processArchitecture = RuntimeInformation.ProcessArchitecture.ToString();
            environment.Add("PROCESSOR_ARCHITECTURE", String.Equals(processArchitecture, "Arm64", StringComparison.OrdinalIgnoreCase) ? "ARM64" : "AMD64");
            environment.Add("PSModulePath", Path.Combine(atlasRoot, "Scripts", "Modules") + ";" + Path.Combine(nativePowerShell, "Modules") + ";" + Path.Combine(programFiles, "WindowsPowerShell", "Modules"));
            environment.Add("SystemDrive", systemDrive);
            environment.Add("SystemRoot", windowsDirectory);
            environment.Add("TEMP", workingDirectory);
            environment.Add("TMP", workingDirectory);
            environment.Add("WINDIR", windowsDirectory);
            StringBuilder block = new StringBuilder();
            foreach (KeyValuePair<string, string> item in environment) {
                if (item.Value == null || item.Value.IndexOf('\0') >= 0) throw new InvalidOperationException("The sanitized environment contains an invalid value.");
                block.Append(item.Key).Append('=').Append(item.Value).Append('\0');
            }
            block.Append('\0');
            return block.ToString();
        }

        static string RequireExactPath(string path, string expected, string name) {
            if (String.IsNullOrWhiteSpace(path)) throw new ArgumentException(name + " is required.", name);
            string full = Path.GetFullPath(path);
            if (!String.Equals(full, Path.GetFullPath(expected), StringComparison.OrdinalIgnoreCase)) throw new ArgumentException(name + " is not the fixed protected path.", name);
            ValidatePathSegmentsNotReparse(full);
            return full;
        }

        static string RequirePathBelow(string path, string root, string name) {
            if (String.IsNullOrWhiteSpace(path)) throw new ArgumentException(name + " is required.", name);
            string full = Path.GetFullPath(path);
            string rootFull = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            if (!full.StartsWith(rootFull, StringComparison.OrdinalIgnoreCase)) throw new ArgumentException(name + " escapes its protected root.", name);
            ValidatePathSegmentsNotReparse(full);
            return full;
        }

        static void ValidatePathSegmentsNotReparse(string path) {
            string full = Path.GetFullPath(path);
            string root = Path.GetPathRoot(full);
            string remaining = full.Substring(root.Length);
            string current = root;
            string[] segments = remaining.Split(new char[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < segments.Length; i++) {
                current = Path.Combine(current, segments[i]);
                UInt32 attributes = GetFileAttributes(current);
                if (attributes == INVALID_FILE_ATTRIBUTES) throw LastError("GetFileAttributes failed for protected path '" + current + "'");
                if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) throw new InvalidOperationException("Protected path contains a reparse point: '" + current + "'.");
            }
        }

        static FileStream OpenProtectedFile(string path, bool requireTrustedOwner, string requiredRoot) {
            string full = Path.GetFullPath(path);
            if (requiredRoot != null) RequirePathBelow(full, requiredRoot, "protected file");
            ValidatePathSegmentsNotReparse(full);
            FileStream stream = new FileStream(full, FileMode.Open, FileAccess.Read, FileShare.Read);
            try {
                string resolved = GetFinalFilePath(stream.SafeFileHandle.DangerousGetHandle());
                if (!String.Equals(Path.GetFullPath(resolved), full, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Protected file final path changed after open: '" + full + "'.");
                if (requireTrustedOwner) ValidateFileSecurity(full);
                return stream;
            }
            catch {
                stream.Dispose();
                throw;
            }
        }

        static string GetFinalFilePath(IntPtr handle) {
            if (GetFileType(handle) != 1) throw new InvalidOperationException("Protected input is not a disk file.");
            StringBuilder path = new StringBuilder(32768);
            UInt32 length = GetFinalPathNameByHandle(handle, path, unchecked((UInt32)path.Capacity), 0);
            if (length == 0 || length >= path.Capacity) throw LastError("GetFinalPathNameByHandle failed");
            string value = path.ToString();
            if (value.StartsWith("\\\\?\\UNC\\", StringComparison.OrdinalIgnoreCase)) return "\\\\" + value.Substring(8);
            if (value.StartsWith("\\\\?\\", StringComparison.OrdinalIgnoreCase)) return value.Substring(4);
            return value;
        }

        static void ValidateFileSecurity(string path) {
            ValidateFileSystemSecurity(new FileInfo(path).GetAccessControl(AccessControlSections.Owner | AccessControlSections.Access), path);
        }

        static void ValidateFileSystemSecurity(FileSystemSecurity security, string path) {
            SecurityIdentifier owner = (SecurityIdentifier)security.GetOwner(typeof(SecurityIdentifier));
            string ownerSid = owner.Value;
            string tiSid = ResolveAccountSid("NT SERVICE\\TrustedInstaller");
            if (!String.Equals(ownerSid, "S-1-5-18", StringComparison.OrdinalIgnoreCase) &&
                !String.Equals(ownerSid, "S-1-5-32-544", StringComparison.OrdinalIgnoreCase) &&
                !String.Equals(ownerSid, tiSid, StringComparison.OrdinalIgnoreCase)) {
                throw new UnauthorizedAccessException("Protected file has an unexpected owner: '" + path + "' (" + ownerSid + ").");
            }
            AuthorizationRuleCollection rules = security.GetAccessRules(true, true, typeof(SecurityIdentifier));
            for (int i = 0; i < rules.Count; i++) {
                FileSystemAccessRule rule = (FileSystemAccessRule)rules[i];
                if (rule.AccessControlType != AccessControlType.Allow) continue;
                string sid = ((SecurityIdentifier)rule.IdentityReference).Value;
                FileSystemRights unsafeRights = FileSystemRights.WriteData | FileSystemRights.AppendData |
                    FileSystemRights.WriteExtendedAttributes | FileSystemRights.WriteAttributes |
                    FileSystemRights.DeleteSubdirectoriesAndFiles | FileSystemRights.Delete |
                    FileSystemRights.ChangePermissions | FileSystemRights.TakeOwnership |
                    (FileSystemRights)0x10000000 | (FileSystemRights)0x40000000; // GENERIC_ALL | GENERIC_WRITE
                bool inertCreatorOwner = sid == "S-1-3-0" && (rule.PropagationFlags & PropagationFlags.InheritOnly) != 0;
                bool trustedWriter = sid == "S-1-5-18" || sid == "S-1-5-32-544" || String.Equals(sid, tiSid, StringComparison.OrdinalIgnoreCase) || inertCreatorOwner;
                if (!trustedWriter && (rule.FileSystemRights & unsafeRights) != 0) {
                    throw new UnauthorizedAccessException("Protected payload object grants write-capable access to an untrusted principal: '" + path + "' (" + sid + ").");
                }
            }
        }

        static void RequireBoundedScalar(string value, string name, int maxLength, bool allowEmpty) {
            if (value == null || (!allowEmpty && value.Length == 0)) throw new ArgumentException(name + " is required.", name);
            if (value.Length > maxLength) throw new ArgumentOutOfRangeException(name, name + " exceeds its bounded length.");
            if (value.IndexOf('\0') >= 0 || value.IndexOf('\r') >= 0 || value.IndexOf('\n') >= 0) throw new ArgumentException(name + " contains a forbidden control character.", name);
        }

        static Win32Exception LastError(string message) {
            int error = Marshal.GetLastWin32Error();
            return new Win32Exception(error, message + " (Win32 error " + error + ").");
        }
    }
}
'@

    Add-AtlasTrustedInstallerNativeType -TypeDefinition $signature
    $script:AtlasTrustedInstallerNativeTypeLoaded = $true
}

function Get-AtlasCurrentTokenEvidence {
    Initialize-AtlasTrustedInstallerNativeType
    return [Atlas.TrustedInstallerProcessNative]::GetCurrentTokenEvidence()
}

function Invoke-AtlasTrustedInstallerNativeOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Toggle', 'ResetServices')]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 86400000)]
        [int]$TimeoutMilliseconds,

        [string]$Name,
        [string]$State,
        [switch]$Silent,
        [switch]$JustContext,
        [switch]$NoExplorerRestart,
        [switch]$MachineOnly,
        [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
        [string]$RestoreSource
    )

    Initialize-AtlasTrustedInstallerNativeType

    $request = New-Object -TypeName Atlas.TrustedInstallerLaunchRequest
    $request.Operation = $Operation
    $request.AtlasModulesPath = (Get-AtlasContext).AtlasModulesPath
    $request.ToggleName = $Name
    $request.ToggleState = $State
    $request.Silent = [bool]$Silent
    $request.JustContext = [bool]$JustContext
    $request.NoExplorerRestart = [bool]$NoExplorerRestart
    $request.MachineOnly = [bool]$MachineOnly
    $request.RestoreSource = $RestoreSource
    $request.TimeoutMilliseconds = $TimeoutMilliseconds

    return [Atlas.TrustedInstallerProcessNative]::LaunchNonInteractive($request)
}
