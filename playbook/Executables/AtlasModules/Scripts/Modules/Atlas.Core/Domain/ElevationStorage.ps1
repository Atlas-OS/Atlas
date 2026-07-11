# Atlas.Core domain: first-instance rendezvous pipe and exact elevated-peer evidence.
#
# Canonical request and result bytes never enter the command line or persistent storage.
# The medium caller owns one first-instance local pipe and authenticates the exact native
# ShellExecute process generation before it transmits a framed request.

$script:AtlasElevationStorageTypeLoaded = $false

function Initialize-AtlasElevationStorageType {
    if ($script:AtlasElevationStorageTypeLoaded -or ('Atlas.ElevationPipeNative' -as [type])) {
        $script:AtlasElevationStorageTypeLoaded = $true
        return
    }

    $signature = @'
using System;
using System.ComponentModel;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Atlas {
    public sealed class ElevationBootstrapProcess : IDisposable {
        const UInt32 WAIT_OBJECT_0 = 0;
        const UInt32 WAIT_TIMEOUT = 258;
        const UInt32 STILL_ACTIVE = 259;
        IntPtr process;

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 WaitForSingleObject(IntPtr handle, UInt32 milliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetExitCodeProcess(IntPtr process, out UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateProcess(IntPtr process, UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr value);

        internal ElevationBootstrapProcess(IntPtr processHandle, Int32 processId) {
            process = processHandle;
            ProcessId = processId;
        }

        public Int32 ProcessId { get; private set; }

        public IntPtr ProcessHandle {
            get {
                EnsureOpen();
                return process;
            }
        }

        public bool HasExited {
            get {
                EnsureOpen();
                UInt32 wait = WaitForSingleObject(process, 0);
                if (wait == WAIT_OBJECT_0) return true;
                if (wait == WAIT_TIMEOUT) return false;
                throw ElevationPipeNative.LastErrorForBootstrap("Waiting for the exact elevation bootstrap failed");
            }
        }

        public bool WaitForExit(Int32 milliseconds) {
            EnsureOpen();
            if (milliseconds < 0) throw new ArgumentOutOfRangeException("milliseconds");
            UInt32 wait = WaitForSingleObject(process, unchecked((UInt32)milliseconds));
            if (wait == WAIT_OBJECT_0) return true;
            if (wait == WAIT_TIMEOUT) return false;
            throw ElevationPipeNative.LastErrorForBootstrap("Waiting for the exact elevation bootstrap failed");
        }

        public UInt32 GetExitCodeUInt32() {
            EnsureOpen();
            UInt32 exitCode;
            if (!GetExitCodeProcess(process, out exitCode)) {
                throw ElevationPipeNative.LastErrorForBootstrap("Reading the exact elevation bootstrap exit code failed");
            }
            if (exitCode == STILL_ACTIVE && !HasExited) {
                throw new InvalidOperationException("The exact elevation bootstrap is still running.");
            }
            return exitCode;
        }

        public void Terminate(UInt32 exitCode) {
            EnsureOpen();
            if (!HasExited && !TerminateProcess(process, exitCode)) {
                throw ElevationPipeNative.LastErrorForBootstrap("Terminating the exact elevation bootstrap failed");
            }
        }

        public void Dispose() {
            IntPtr current = process;
            process = IntPtr.Zero;
            if (current != IntPtr.Zero && current != new IntPtr(-1)) CloseHandle(current);
            GC.SuppressFinalize(this);
        }

        ~ElevationBootstrapProcess() { Dispose(); }

        void EnsureOpen() {
            if (process == IntPtr.Zero || process == new IntPtr(-1)) {
                throw new ObjectDisposedException("ElevationBootstrapProcess");
            }
        }
    }

    public sealed class ElevationPeerEvidence {
        public Int32 ProcessId { get; set; }
        public Int64 CreationFileTime { get; set; }
        public string ImagePath { get; set; }
        public string UserSid { get; set; }
        public Int32 SessionId { get; set; }
        public Int32 IntegrityRid { get; set; }
        public bool IsElevated { get; set; }
    }

    public static class ElevationPipeNative {
        const UInt32 FILE_FLAG_FIRST_PIPE_INSTANCE = 0x00080000;
        const UInt32 FILE_FLAG_OVERLAPPED = 0x40000000;
        const UInt32 PIPE_ACCESS_DUPLEX = 0x00000003;
        const UInt32 PIPE_REJECT_REMOTE_CLIENTS = 0x00000008;
        const UInt32 PROCESS_QUERY_LIMITED_INFORMATION = 0x00001000;
        const UInt32 SYNCHRONIZE = 0x00100000;
        const UInt32 TOKEN_QUERY = 0x0008;
        const UInt32 SDDL_REVISION_1 = 1;
        const Int32 TokenUser = 1;
        const Int32 TokenElevation = 20;
        const Int32 TokenIntegrityLevel = 25;
        const UInt32 SEE_MASK_NOCLOSEPROCESS = 0x00000040;
        const UInt32 SEE_MASK_NOASYNC = 0x00000100;
        const UInt32 SEE_MASK_FLAG_NO_UI = 0x00000400;
        const Int32 SW_HIDE = 0;

        [StructLayout(LayoutKind.Sequential)]
        struct SECURITY_ATTRIBUTES {
            public Int32 nLength;
            public IntPtr lpSecurityDescriptor;
            [MarshalAs(UnmanagedType.Bool)] public bool bInheritHandle;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_ELEVATION { public Int32 TokenIsElevated; }

        [StructLayout(LayoutKind.Sequential)]
        struct SID_AND_ATTRIBUTES {
            public IntPtr Sid;
            public UInt32 Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_MANDATORY_LABEL { public SID_AND_ATTRIBUTES Label; }

        [StructLayout(LayoutKind.Explicit)]
        struct PROCESSOR_INFO_UNION {
            [FieldOffset(0)] public UInt32 dwOemId;
            [FieldOffset(0)] public UInt16 wProcessorArchitecture;
            [FieldOffset(2)] public UInt16 wReserved;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct SYSTEM_INFO {
            public PROCESSOR_INFO_UNION ProcessorInfo;
            public UInt32 dwPageSize;
            public IntPtr lpMinimumApplicationAddress;
            public IntPtr lpMaximumApplicationAddress;
            public UIntPtr dwActiveProcessorMask;
            public UInt32 dwNumberOfProcessors;
            public UInt32 dwProcessorType;
            public UInt32 dwAllocationGranularity;
            public UInt16 wProcessorLevel;
            public UInt16 wProcessorRevision;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct SHELLEXECUTEINFO {
            public Int32 cbSize;
            public UInt32 fMask;
            public IntPtr hwnd;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpVerb;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpFile;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpParameters;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpDirectory;
            public Int32 nShow;
            public IntPtr hInstApp;
            public IntPtr lpIDList;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpClass;
            public IntPtr hkeyClass;
            public UInt32 dwHotKey;
            public IntPtr hIconOrMonitor;
            public IntPtr hProcess;
        }

        [DllImport("advapi32.dll", EntryPoint = "ConvertStringSecurityDescriptorToSecurityDescriptorW", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool ConvertStringSecurityDescriptorToSecurityDescriptor(string value, UInt32 revision, out IntPtr descriptor, out UInt32 descriptorBytes);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(IntPtr process, UInt32 desiredAccess, out IntPtr token);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenThreadToken(IntPtr thread, UInt32 desiredAccess, bool openAsSelf, out IntPtr token);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool ImpersonateNamedPipeClient(IntPtr pipe);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool RevertToSelf();

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(IntPtr token, Int32 informationClass, IntPtr information, Int32 informationBytes, out Int32 requiredBytes);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern IntPtr GetSidSubAuthorityCount(IntPtr sid);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern IntPtr GetSidSubAuthority(IntPtr sid, UInt32 index);

        [DllImport("kernel32.dll", EntryPoint = "CreateNamedPipeW", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        static extern IntPtr CreateNamedPipe(string name, UInt32 openMode, UInt32 pipeMode, UInt32 maximumInstances, UInt32 outputBufferBytes, UInt32 inputBufferBytes, UInt32 defaultTimeout, ref SECURITY_ATTRIBUTES attributes);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetNamedPipeClientProcessId(IntPtr pipe, out UInt32 processId);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr OpenProcess(UInt32 desiredAccess, bool inheritHandle, UInt32 processId);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetProcessTimes(IntPtr process, out Int64 creation, out Int64 exit, out Int64 kernel, out Int64 user);

        [DllImport("kernel32.dll", EntryPoint = "QueryFullProcessImageNameW", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool QueryFullProcessImageName(IntPtr process, UInt32 flags, StringBuilder path, ref UInt32 pathCharacters);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool ProcessIdToSessionId(UInt32 processId, out UInt32 sessionId);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr value);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentThread();

        [DllImport("kernel32.dll")]
        static extern void GetNativeSystemInfo(out SYSTEM_INFO information);

        [DllImport("shell32.dll", EntryPoint = "ShellExecuteExW", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool ShellExecuteEx(ref SHELLEXECUTEINFO information);

        [DllImport("kernel32.dll")]
        static extern IntPtr LocalFree(IntPtr value);

        static readonly IntPtr InvalidHandle = new IntPtr(-1);

        public static UInt16 GetNativeProcessorArchitecture() {
            SYSTEM_INFO information;
            GetNativeSystemInfo(out information);
            return information.ProcessorInfo.wProcessorArchitecture;
        }

        public static ElevationBootstrapProcess StartElevationBootstrap(string executablePath, string requestId, string workingDirectory) {
            if (String.IsNullOrEmpty(executablePath) || !Path.IsPathRooted(executablePath)) {
                throw new ArgumentException("A fixed absolute bootstrap path is required.", "executablePath");
            }
            if (String.IsNullOrEmpty(workingDirectory) || !Path.IsPathRooted(workingDirectory)) {
                throw new ArgumentException("A fixed absolute bootstrap working directory is required.", "workingDirectory");
            }
            ValidateRequestId(requestId);
            SHELLEXECUTEINFO information = new SHELLEXECUTEINFO();
            information.cbSize = Marshal.SizeOf(typeof(SHELLEXECUTEINFO));
            information.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC | SEE_MASK_FLAG_NO_UI;
            information.lpVerb = "runas";
            information.lpFile = Path.GetFullPath(executablePath);
            information.lpParameters = requestId;
            information.lpDirectory = Path.GetFullPath(workingDirectory);
            information.nShow = SW_HIDE;
            if (!ShellExecuteEx(ref information) || information.hProcess == IntPtr.Zero || information.hProcess == InvalidHandle) {
                if (information.hProcess != IntPtr.Zero && information.hProcess != InvalidHandle) CloseHandle(information.hProcess);
                throw LastError("Starting the fixed native elevation bootstrap failed");
            }
            UInt32 processId = GetProcessId(information.hProcess);
            if (processId == 0 || processId > Int32.MaxValue) {
                CloseHandle(information.hProcess);
                throw LastError("Reading the fixed native elevation bootstrap PID failed");
            }
            return new ElevationBootstrapProcess(information.hProcess, checked((Int32)processId));
        }

        public static NamedPipeServerStream CreateFirstPipeServer(string pipeName, string ownerSid) {
            ValidatePipeName(pipeName);
            ValidateSid(ownerSid, "ownerSid");

            // Administrators and SYSTEM can connect. The owner may rewrite the DACL, so
            // this is not peer authentication; the exact client process handle check is.
            string sddl = "O:" + ownerSid + "D:P(A;;FA;;;SY)(A;;FA;;;BA)";
            IntPtr descriptor;
            UInt32 descriptorBytes;
            if (!ConvertStringSecurityDescriptorToSecurityDescriptor(sddl, SDDL_REVISION_1, out descriptor, out descriptorBytes)) {
                throw LastError("Converting the rendezvous pipe descriptor failed");
            }
            try {
                SECURITY_ATTRIBUTES attributes = new SECURITY_ATTRIBUTES();
                attributes.nLength = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
                attributes.lpSecurityDescriptor = descriptor;
                attributes.bInheritHandle = false;
                UInt32 mode = PIPE_ACCESS_DUPLEX | FILE_FLAG_FIRST_PIPE_INSTANCE | FILE_FLAG_OVERLAPPED;
                IntPtr raw = CreateNamedPipe("\\\\.\\pipe\\" + pipeName, mode, PIPE_REJECT_REMOTE_CLIENTS, 1, 65536, 65536, 0, ref attributes);
                if (raw == InvalidHandle) throw LastError("Creating the first-instance rendezvous pipe failed");
                SafePipeHandle safe = new SafePipeHandle(raw, true);
                try {
                    NamedPipeServerStream stream = new NamedPipeServerStream(PipeDirection.InOut, true, false, safe);
                    safe = null;
                    return stream;
                }
                finally {
                    if (safe != null) safe.Dispose();
                }
            }
            finally {
                LocalFree(descriptor);
            }
        }

        public static ElevationPeerEvidence GetConnectedClientEvidence(IntPtr pipeHandle) {
            if (pipeHandle == IntPtr.Zero || pipeHandle == InvalidHandle) throw new ArgumentException("A connected rendezvous pipe handle is required.", "pipeHandle");
            UInt32 processId;
            if (!GetNamedPipeClientProcessId(pipeHandle, out processId) || processId == 0) {
                throw LastError("Resolving the rendezvous pipe client PID failed");
            }
            IntPtr impersonationToken = TryOpenPipeClientToken(pipeHandle);
            try {
                ElevationPeerEvidence evidence = ReadProcessEvidence(processId, IntPtr.Zero, impersonationToken, true);
                UInt32 processIdAgain;
                if (!GetNamedPipeClientProcessId(pipeHandle, out processIdAgain) || processIdAgain != processId) {
                    throw new InvalidOperationException("The rendezvous pipe client PID changed while identity evidence was collected.");
                }
                return evidence;
            }
            finally {
                if (impersonationToken != IntPtr.Zero) CloseHandle(impersonationToken);
            }
        }

        public static ElevationPeerEvidence GetProcessHandleEvidence(IntPtr processHandle) {
            if (processHandle == IntPtr.Zero || processHandle == InvalidHandle) throw new ArgumentException("A live process handle is required.", "processHandle");
            // The ShellExecute process may use over-the-shoulder credentials. Its returned
            // process handle authoritatively supplies PID/creation/image/session, while the
            // connected pipe's identification token supplies elevation evidence below.
            return ReadProcessEvidence(0, processHandle, IntPtr.Zero, false);
        }

        static ElevationPeerEvidence ReadProcessEvidence(UInt32 processId, IntPtr suppliedHandle, IntPtr suppliedToken, bool includeToken) {
            IntPtr process = suppliedHandle;
            bool ownsProcess = false;
            if (process == IntPtr.Zero) {
                process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | SYNCHRONIZE, false, processId);
                if (process == IntPtr.Zero) throw LastError("Opening the exact elevation peer failed");
                ownsProcess = true;
            }
            try {
                Int64 creation, exit, kernel, user;
                if (!GetProcessTimes(process, out creation, out exit, out kernel, out user) || creation <= 0) {
                    throw LastError("Reading elevation peer creation time failed");
                }
                UInt32 actualProcessId = processId;
                if (actualProcessId == 0) {
                    actualProcessId = GetProcessId(process);
                    if (actualProcessId == 0) throw LastError("Reading elevation peer PID from its handle failed");
                }
                StringBuilder path = new StringBuilder(32768);
                UInt32 pathCharacters = unchecked((UInt32)path.Capacity);
                if (!QueryFullProcessImageName(process, 0, path, ref pathCharacters) || pathCharacters == 0) {
                    throw LastError("Reading elevation peer image path failed");
                }
                UInt32 sessionId;
                if (!ProcessIdToSessionId(actualProcessId, out sessionId)) throw LastError("Reading elevation peer session failed");

                IntPtr token = suppliedToken;
                bool ownsToken = false;
                if (includeToken && token == IntPtr.Zero) {
                    if (!OpenProcessToken(process, TOKEN_QUERY, out token)) throw LastError("Opening elevation peer token failed");
                    ownsToken = true;
                }
                try {
                    return new ElevationPeerEvidence {
                        ProcessId = checked((Int32)actualProcessId),
                        CreationFileTime = creation,
                        ImagePath = Path.GetFullPath(path.ToString()),
                        UserSid = includeToken ? ReadTokenSid(token) : null,
                        SessionId = checked((Int32)sessionId),
                        IntegrityRid = includeToken ? ReadIntegrityRid(token) : 0,
                        IsElevated = includeToken && ReadElevation(token)
                    };
                }
                finally { if (ownsToken) CloseHandle(token); }
            }
            finally {
                if (ownsProcess) CloseHandle(process);
            }
        }

        static IntPtr TryOpenPipeClientToken(IntPtr pipeHandle) {
            if (!ImpersonateNamedPipeClient(pipeHandle)) {
                return IntPtr.Zero;
            }
            IntPtr token = IntPtr.Zero;
            bool reverted = false;
            try {
                // Identification tokens cannot open executive objects as the client.
                // OpenAsSelf performs this TOKEN_QUERY open as the medium server without
                // granting it SecurityImpersonation authority over an OTS administrator.
                if (!OpenThreadToken(GetCurrentThread(), TOKEN_QUERY, true, out token)) {
                    token = IntPtr.Zero;
                }
            }
            finally {
                reverted = RevertToSelf();
                if (!reverted && token != IntPtr.Zero) {
                    CloseHandle(token);
                    token = IntPtr.Zero;
                }
            }
            if (!reverted) throw LastError("Reverting rendezvous client identification failed");
            return token;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 GetProcessId(IntPtr process);

        static string ReadTokenSid(IntPtr token) {
            IntPtr buffer = ReadTokenBuffer(token, TokenUser);
            try {
                SID_AND_ATTRIBUTES value = (SID_AND_ATTRIBUTES)Marshal.PtrToStructure(buffer, typeof(SID_AND_ATTRIBUTES));
                return new SecurityIdentifier(value.Sid).Value;
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static Int32 ReadIntegrityRid(IntPtr token) {
            IntPtr buffer = ReadTokenBuffer(token, TokenIntegrityLevel);
            try {
                TOKEN_MANDATORY_LABEL value = (TOKEN_MANDATORY_LABEL)Marshal.PtrToStructure(buffer, typeof(TOKEN_MANDATORY_LABEL));
                byte count = Marshal.ReadByte(GetSidSubAuthorityCount(value.Label.Sid));
                if (count == 0) throw new InvalidOperationException("Elevation peer integrity SID has no subauthority.");
                return Marshal.ReadInt32(GetSidSubAuthority(value.Label.Sid, unchecked((UInt32)(count - 1))));
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static bool ReadElevation(IntPtr token) {
            Int32 bytes = Marshal.SizeOf(typeof(TOKEN_ELEVATION));
            IntPtr buffer = Marshal.AllocHGlobal(bytes);
            try {
                Int32 returned;
                if (!GetTokenInformation(token, TokenElevation, buffer, bytes, out returned)) throw LastError("Reading elevation peer elevation state failed");
                TOKEN_ELEVATION value = (TOKEN_ELEVATION)Marshal.PtrToStructure(buffer, typeof(TOKEN_ELEVATION));
                return value.TokenIsElevated != 0;
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static IntPtr ReadTokenBuffer(IntPtr token, Int32 informationClass) {
            Int32 required;
            GetTokenInformation(token, informationClass, IntPtr.Zero, 0, out required);
            if (required <= 0) throw LastError("Sizing elevation peer token evidence failed");
            IntPtr buffer = Marshal.AllocHGlobal(required);
            try {
                if (!GetTokenInformation(token, informationClass, buffer, required, out required)) throw LastError("Reading elevation peer token evidence failed");
                return buffer;
            }
            catch {
                Marshal.FreeHGlobal(buffer);
                throw;
            }
        }

        static void ValidatePipeName(string value) {
            const string prefix = "AtlasOS.TrustedInstaller.";
            if (String.IsNullOrEmpty(value) || !value.StartsWith(prefix, StringComparison.Ordinal) || value.Length != prefix.Length + 32) {
                throw new ArgumentException("Pipe name is outside the Atlas TrustedInstaller schema.", "value");
            }
            bool nonzero = false;
            for (Int32 index = prefix.Length; index < value.Length; index++) {
                char current = value[index];
                if (!((current >= '0' && current <= '9') || (current >= 'a' && current <= 'f'))) {
                    throw new ArgumentException("Pipe suffix must be lowercase hexadecimal.", "value");
                }
                if (current != '0') nonzero = true;
            }
            if (!nonzero) throw new ArgumentException("Pipe suffix must not be all zero.", "value");
        }

        static void ValidateRequestId(string value) {
            if (String.IsNullOrEmpty(value) || value.Length != 32) {
                throw new ArgumentException("Request ID must be lowercase 32-hex.", "value");
            }
            bool nonzero = false;
            for (Int32 index = 0; index < value.Length; index++) {
                char current = value[index];
                if (!((current >= '0' && current <= '9') || (current >= 'a' && current <= 'f'))) {
                    throw new ArgumentException("Request ID must be lowercase 32-hex.", "value");
                }
                if (current != '0') nonzero = true;
            }
            if (!nonzero) throw new ArgumentException("Request ID must not be all zero.", "value");
        }

        static void ValidateSid(string value, string parameterName) {
            try {
                SecurityIdentifier sid = new SecurityIdentifier(value);
                if (!String.Equals(sid.Value, value, StringComparison.Ordinal)) throw new ArgumentException("SID is not canonical.", parameterName);
            }
            catch (Exception error) {
                if (error is ArgumentException) throw;
                throw new ArgumentException("SID is not canonical.", parameterName, error);
            }
        }

        static Win32Exception LastError(string message) {
            Int32 error = Marshal.GetLastWin32Error();
            return new Win32Exception(error, message + " (Win32 error " + error + ").");
        }

        internal static Win32Exception LastErrorForBootstrap(string message) { return LastError(message); }
    }
}
'@

    Add-AtlasTrustedInstallerNativeType -TypeDefinition $signature
    $script:AtlasElevationStorageTypeLoaded = $true
}
