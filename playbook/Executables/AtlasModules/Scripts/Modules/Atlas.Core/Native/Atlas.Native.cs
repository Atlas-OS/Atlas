// Atlas.Native - the complete native (C#) surface of the Atlas payload.
//
// Every runtime-compiled type Atlas uses lives in this one audited file. It is
// compiled exactly once per PowerShell process by Initialize-AtlasNativeType
// (Atlas.Core\Domain\Native.ps1), which routes the compile through a random,
// from-birth-ACL'd directory whenever the host holds a high-integrity token, so
// no caller ever compiles through a requester-writable %TEMP%.
//
// Each section below is one formerly inline Add-Type block, kept verbatim apart
// from the move into the single Atlas.Native namespace and the class renames.
// Nothing here may gain behaviour without review: this is a privileged surface.

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using Microsoft.Win32.SafeHandles;

namespace Atlas.Native
{
    [ComImport, Guid("EA502723-A23D-11D1-A7D3-0000F87571E3"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ILocalGroupPolicyObject {
        void New([MarshalAs(UnmanagedType.LPWStr)] string domain, [MarshalAs(UnmanagedType.LPWStr)] string displayName, uint flags);
        void OpenDSGPO([MarshalAs(UnmanagedType.LPWStr)] string path, uint flags);
        void OpenLocalMachineGPO(uint flags);
        void OpenRemoteMachineGPO([MarshalAs(UnmanagedType.LPWStr)] string computer, uint flags);
        void Save([MarshalAs(UnmanagedType.Bool)] bool machine, [MarshalAs(UnmanagedType.Bool)] bool add, ref Guid extension, ref Guid editor);
        void Delete();
        void GetName(IntPtr name, int length);
        void GetDisplayName(IntPtr name, int length);
        void SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string name);
        void GetPath(IntPtr path, int length);
        void GetDSPath(uint section, IntPtr path, int length);
        void GetFileSysPath(uint section, IntPtr path, int length);
        void GetRegistryKey(uint section, out IntPtr key);
    }

    public static class LocalMachinePolicy {
        // GPEdit.h / IGroupPolicyObject: edit the existing local GPO, preserving
        // unrelated settings, and save through Windows rather than writing .pol bytes.
        public static void SetDword(string subKey, string name, int value) {
            if (String.IsNullOrWhiteSpace(subKey) || !subKey.StartsWith("Software\\Policies\\", StringComparison.OrdinalIgnoreCase) || subKey.Contains(".."))
                throw new ArgumentException("Local machine policy requires a Software\\Policies subkey.");
            if (String.IsNullOrWhiteSpace(name) || name.StartsWith("**", StringComparison.Ordinal) || name.IndexOf('\0') >= 0)
                throw new ArgumentException("Invalid policy value name.");
            Exception failure = null;
            Thread worker = new Thread(delegate() {
                ILocalGroupPolicyObject policy = null;
                try {
                    policy = (ILocalGroupPolicyObject)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("EA502722-A23D-11D1-A7D3-0000F87571E3"), true));
                    policy.OpenLocalMachineGPO(1); // GPO_OPEN_LOAD_REGISTRY
                    IntPtr handle;
                    policy.GetRegistryKey(2, out handle); // GPO_SECTION_MACHINE
                    using (SafeRegistryHandle safeHandle = new SafeRegistryHandle(handle, true))
                    using (Microsoft.Win32.RegistryKey root = Microsoft.Win32.RegistryKey.FromHandle(safeHandle))
                    using (Microsoft.Win32.RegistryKey key = root.CreateSubKey(subKey)) {
                        key.SetValue(name, value, Microsoft.Win32.RegistryValueKind.DWord);
                    }
                    Guid registryExtension = new Guid("35378EAC-683F-11D2-A89A-00C04FBBCFA2");
                    Guid editor = new Guid("EA502722-A23D-11D1-A7D3-0000F87571E3");
                    policy.Save(true, true, ref registryExtension, ref editor);
                } catch (Exception error) { failure = error; }
                finally {
                    try { if (policy != null) Marshal.FinalReleaseComObject(policy); }
                    catch (Exception error) { if (failure == null) failure = error; }
                }
            });
            worker.SetApartmentState(ApartmentState.STA);
            worker.Start();
            worker.Join();
            if (failure != null) throw new InvalidOperationException("Saving local machine policy failed.", failure);
        }
    }

    // Windows Search COM contracts, in SDK SearchAPI.h vtable order.
    // https://learn.microsoft.com/windows/win32/search/-search-3x-wds-extidx-csm-scoperules
    // Only the methods used by SearchScope are called; opaque unused interfaces and
    // PROPVARIANT values stay IntPtr so no additional interop surface is needed.
    [ComImport, Guid("AB310581-AC80-11D1-8DF3-00C04FB6EF69"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISearchManager {
        void GetIndexerVersionStr(out IntPtr value);
        void GetIndexerVersion(out uint major, out uint minor);
        void GetParameter([MarshalAs(UnmanagedType.LPWStr)] string name, out IntPtr value);
        void SetParameter([MarshalAs(UnmanagedType.LPWStr)] string name, IntPtr value);
        void GetProxyName(out IntPtr value);
        void GetBypassList(out IntPtr value);
        void SetProxy(int access, [MarshalAs(UnmanagedType.Bool)] bool local, uint port, [MarshalAs(UnmanagedType.LPWStr)] string name, [MarshalAs(UnmanagedType.LPWStr)] string bypass);
        void GetCatalog([MarshalAs(UnmanagedType.LPWStr)] string name, out ISearchCatalogManager catalog);
    }

    [ComImport, Guid("AB310581-AC80-11D1-8DF3-00C04FB6EF50"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISearchCatalogManager {
        void GetName(out IntPtr value);
        void GetParameter([MarshalAs(UnmanagedType.LPWStr)] string name, out IntPtr value);
        void SetParameter([MarshalAs(UnmanagedType.LPWStr)] string name, IntPtr value);
        void GetCatalogStatus(out int status, out int reason);
        void Reset();
        void Reindex();
        void ReindexMatchingURLs([MarshalAs(UnmanagedType.LPWStr)] string pattern);
        void ReindexSearchRoot([MarshalAs(UnmanagedType.LPWStr)] string root);
        void SetConnectTimeout(uint value);
        void GetConnectTimeout(out uint value);
        void SetDataTimeout(uint value);
        void GetDataTimeout(out uint value);
        void NumberOfItems(out int value);
        void NumberOfItemsToIndex(out int incremental, out int notifications, out int priority);
        void URLBeingIndexed(out IntPtr value);
        void GetURLIndexingState([MarshalAs(UnmanagedType.LPWStr)] string url, out uint state);
        void GetPersistentItemsChangedSink(out IntPtr sink);
        void RegisterViewForNotification([MarshalAs(UnmanagedType.LPWStr)] string view, IntPtr sink, out uint cookie);
        void GetItemsChangedSink(IntPtr site, ref Guid iid, out IntPtr sink, out Guid reset, out Guid checkpoint, out uint number);
        void UnregisterViewForNotification(uint cookie);
        void SetExtensionClusion([MarshalAs(UnmanagedType.LPWStr)] string extension, [MarshalAs(UnmanagedType.Bool)] bool exclude);
        void EnumerateExcludedExtensions(out IntPtr extensions);
        void GetQueryHelper(out IntPtr helper);
        void SetDiacriticSensitivity([MarshalAs(UnmanagedType.Bool)] bool value);
        void GetDiacriticSensitivity([MarshalAs(UnmanagedType.Bool)] out bool value);
        void GetCrawlScopeManager(out ISearchCrawlScopeManager scope);
    }

    [ComImport, Guid("AB310581-AC80-11D1-8DF3-00C04FB6EF55"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISearchCrawlScopeManager {
        void AddDefaultScopeRule([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] bool include, uint flags);
        void AddRoot(IntPtr root);
        void RemoveRoot([MarshalAs(UnmanagedType.LPWStr)] string url);
        void EnumerateRoots(out IntPtr roots);
        void AddHierarchicalScope([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] bool include, [MarshalAs(UnmanagedType.Bool)] bool isDefault, [MarshalAs(UnmanagedType.Bool)] bool overrideChildren);
        void AddUserScopeRule([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] bool include, [MarshalAs(UnmanagedType.Bool)] bool overrideChildren, uint flags);
        void RemoveScopeRule([MarshalAs(UnmanagedType.LPWStr)] string url);
        void EnumerateScopeRules(out IntPtr rules);
        void HasParentScopeRule([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] out bool value);
        void HasChildScopeRule([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] out bool value);
        void IncludedInCrawlScope([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] out bool value);
        void IncludedInCrawlScopeEx([MarshalAs(UnmanagedType.LPWStr)] string url, [MarshalAs(UnmanagedType.Bool)] out bool value, out int reason);
        void RevertToDefaultScopes();
        void SaveAll();
    }

    public static class SearchScope {
        private sealed class Connection : IDisposable {
            private ISearchManager manager;
            private ISearchCatalogManager catalog;
            internal ISearchCrawlScopeManager Scope;
            internal Connection() {
                try {
                    manager = (ISearchManager)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("7D096C5F-AC08-4F1F-BEB7-5C22C517CE39"), true));
                    manager.GetCatalog("SystemIndex", out catalog);
                    catalog.GetCrawlScopeManager(out Scope);
                } catch { Dispose(); throw; }
            }
            public void Dispose() {
                if (Scope != null) { Marshal.FinalReleaseComObject(Scope); Scope = null; }
                if (catalog != null) { Marshal.FinalReleaseComObject(catalog); catalog = null; }
                if (manager != null) { Marshal.FinalReleaseComObject(manager); manager = null; }
            }
        }

        private static void ValidateUrls(string[] urls, bool exclusion) {
            if (urls == null) throw new ArgumentNullException("urls");
            foreach (string url in urls) {
                string suffix = exclusion ? "\\*" : "\\";
                if (String.IsNullOrWhiteSpace(url) || !url.StartsWith("file://", StringComparison.OrdinalIgnoreCase) || !url.EndsWith(suffix, StringComparison.Ordinal))
                    throw new ArgumentException("Search scope must contain directory file URLs with the correct include/exclude suffix.");
            }
        }

        // Applying a preset resets previous user scope overrides using the supported
        // API, retaining Windows' default rule set and all administrator policies.
        // Save once, then reopen the catalog to verify persisted effective rules.
        public static void Apply(string[] includes, string[] excludes) {
            ValidateUrls(includes, false);
            ValidateUrls(excludes, true);
            if (includes.Length == 0 && excludes.Length == 0) throw new ArgumentException("An empty Search preset is not allowed.");
            using (Connection connection = new Connection()) {
                connection.Scope.RevertToDefaultScopes();
                foreach (string url in includes) connection.Scope.AddUserScopeRule(url, true, true, 0);
                foreach (string url in excludes) connection.Scope.AddUserScopeRule(url, false, true, 0);
                connection.Scope.SaveAll();
            }
            using (Connection connection = new Connection()) {
                foreach (string url in includes) Verify(connection.Scope, url + "__atlas_scope_probe__", true);
                foreach (string url in excludes) Verify(connection.Scope, url.Substring(0, url.Length - 1) + "__atlas_scope_probe__", false);
            }
        }

        private static void Verify(ISearchCrawlScopeManager scope, string url, bool expected) {
            bool actual;
            int reason;
            scope.IncludedInCrawlScopeEx(url, out actual, out reason);
            if (actual != expected) throw new InvalidOperationException("Search scope verification failed for '" + url + "': expected included=" + expected + ", actual=" + actual + ", reason=" + reason + ".");
        }

        public static bool[] Read(string[] urls) {
            if (urls == null) throw new ArgumentNullException("urls");
            foreach (string url in urls) {
                if (String.IsNullOrWhiteSpace(url) || !url.StartsWith("file://", StringComparison.OrdinalIgnoreCase) || url.Contains("*"))
                    throw new ArgumentException("Search scope queries require non-pattern file URLs.");
            }
            bool[] values = new bool[urls.Length];
            using (Connection connection = new Connection()) {
                for (int i = 0; i < urls.Length; i++) connection.Scope.IncludedInCrawlScope(urls[i], out values[i]);
            }
            return values;
        }
    }

    // ----- TrustedInstaller broker -----
    // PowerShell consumer: Atlas.Core\Domain\TrustedInstallerProcess.ps1
    //   (Get-AtlasCurrentTokenEvidence, Invoke-AtlasTrustedInstallerNativeOperation)
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
        public string InstallPhase { get; set; }
        public string PayloadRoot { get; set; }
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

    public static class TrustedInstallerProcess {
        const UInt32 TOKEN_ASSIGN_PRIMARY = 0x0001;
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
            TokenGroups = 2,
            TokenStatistics = 10,
            TokenSessionId = 12,
            TokenElevation = 20,
            TokenIntegrityLevel = 25
        }

        [StructLayout(LayoutKind.Sequential)]
        struct LUID { public UInt32 LowPart; public Int32 HighPart; }

        [StructLayout(LayoutKind.Sequential)]
        struct SID_AND_ATTRIBUTES {
            public IntPtr Sid;
            public UInt32 Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_GROUPS_HEADER {
            public UInt32 GroupCount;
            public SID_AND_ATTRIBUTES FirstGroup;
        }

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
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, out token)) {
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
            // An Install runs from a protected staging copy of the payload; the installed
            // tree does not exist yet on a fresh machine, so only its name is fixed here.
            bool isInstall = String.Equals(request.Operation, "Install", StringComparison.Ordinal);
            string atlasRoot = isInstall
                ? expectedAtlasRoot
                : RequireExactPath(request.AtlasModulesPath, expectedAtlasRoot, "AtlasModulesPath");
            string moduleRoot = atlasRoot;
            if (isInstall) {
                moduleRoot = RequireProtectedStagingPayload(request.PayloadRoot, windowsDirectory);
            }
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
                ResolveOperation(request, atlasRoot, moduleRoot, windowsDirectory, systemDirectory, out applicationPath, out arguments, heldObjects);
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

                string environmentText = BuildSanitizedEnvironment(windowsDirectory, systemDirectory, moduleRoot, workingDirectory);
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
                    if (!OpenProcessToken(processInfo.hProcess, TOKEN_QUERY, out childToken)) {
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

        static string RequireProtectedStagingPayload(string payloadRoot, string windowsDirectory) {
            // The front door stages the extracted playbook beneath the protected staging
            // root with a from-birth Administrators/SYSTEM-only DACL. Only such a copy may
            // run as TrustedInstaller; a user-writable extraction folder never can.
            string stagingRoot = Path.GetFullPath(Path.Combine(windowsDirectory, "AtlasOS", "Staging"));
            string full = RequirePathBelow(payloadRoot, stagingRoot, "PayloadRoot");
            if (!Directory.Exists(full)) throw new DirectoryNotFoundException("PayloadRoot '" + full + "' does not exist.");
            ValidateFileSystemSecurity(new DirectoryInfo(full).GetAccessControl(AccessControlSections.Owner | AccessControlSections.Access), full);
            string modulesRoot = Path.Combine(full, "AtlasModules");
            if (!Directory.Exists(modulesRoot)) throw new DirectoryNotFoundException("PayloadRoot '" + full + "' has no AtlasModules tree.");
            return modulesRoot;
        }

        static void ResolveOperation(TrustedInstallerLaunchRequest request, string atlasRoot, string moduleRoot, string windowsDirectory, string systemDirectory, out string applicationPath, out string[] arguments, List<IDisposable> heldObjects) {
            if (String.Equals(request.Operation, "Install", StringComparison.Ordinal)) {
                if (!String.Equals(request.InstallPhase, "Capture", StringComparison.Ordinal) &&
                    !String.Equals(request.InstallPhase, "Run", StringComparison.Ordinal)) {
                    throw new ArgumentException("Install InstallPhase is outside the closed operation schema.");
                }
                applicationPath = Path.Combine(systemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe");
                string scriptPath = Path.Combine(moduleRoot, "Scripts", "Install", "Invoke-AtlasInstallSession.ps1");
                heldObjects.Add(OpenProtectedFile(applicationPath, true, null));
                heldObjects.Add(OpenProtectedFile(scriptPath, true, moduleRoot));
                arguments = new string[] {
                    "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                    "-File", scriptPath, "-Phase", request.InstallPhase
                };
                return;
            }

            if (String.Equals(request.Operation, "Toggle", StringComparison.Ordinal)) {
                RequireBoundedScalar(request.ToggleName, "ToggleName", 128, false);
                RequireBoundedScalar(request.ToggleState, "ToggleState", 128, false);
                if (!request.Silent) {
                    throw new ArgumentException("The initial noninteractive Toggle operation requires Silent=true.");
                }
                applicationPath = Path.Combine(systemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe");
                string scriptPath = Path.Combine(atlasRoot, "Scripts", "Entry", "Invoke-Toggle.ps1");
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
                string scriptPath = Path.Combine(atlasRoot, "Scripts", "Entry", "Restore-AtlasServiceDefaults.ps1");
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
            if (!OpenProcessToken(sourceProcess, TOKEN_QUERY, out sourceToken)) {
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
            // Inspect the group attributes with TOKEN_QUERY only. WindowsPrincipal
            // may duplicate a primary token for membership checks; a service token
            // can permit inspection while denying TOKEN_DUPLICATE.
            IntPtr buffer = GetTokenBuffer(token, TOKEN_INFORMATION_CLASS.TokenGroups);
            try {
                UInt32 count = unchecked((UInt32)Marshal.ReadInt32(buffer));
                int offset = Marshal.OffsetOf(typeof(TOKEN_GROUPS_HEADER), "FirstGroup").ToInt32();
                int stride = Marshal.SizeOf(typeof(SID_AND_ATTRIBUTES));
                for (UInt32 index = 0; index < count; index++) {
                    int entryOffset = checked(offset + checked((int)index * stride));
                    SID_AND_ATTRIBUTES group = (SID_AND_ATTRIBUTES)Marshal.PtrToStructure(
                        IntPtr.Add(buffer, entryOffset), typeof(SID_AND_ATTRIBUTES));
                    if (String.Equals(SidToString(group.Sid), expectedSid, StringComparison.OrdinalIgnoreCase)) {
                        return (group.Attributes & SE_GROUP_ENABLED) != 0 &&
                            (group.Attributes & SE_GROUP_USE_FOR_DENY_ONLY) == 0;
                    }
                }
                return false;
            }
            finally { Marshal.FreeHGlobal(buffer); }
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
            // TokenElevation rejects a zero-length size probe with ERROR_BAD_LENGTH.
            // Both scalar classes read here have a fixed DWORD representation.
            IntPtr buffer = Marshal.AllocHGlobal(sizeof(Int32));
            try {
                Int32 returned;
                if (!GetTokenInformation(token, informationClass, buffer, sizeof(Int32), out returned)) {
                    throw LastError("GetTokenInformation failed for " + informationClass);
                }
                if (returned != sizeof(Int32)) {
                    throw new InvalidOperationException("Unexpected token scalar size for " + informationClass + ".");
                }
                return Marshal.ReadInt32(buffer);
            }
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

    // ----- Contained process launcher -----
    // PowerShell consumer: Atlas.Download\Atlas.Download.psm1 (Invoke-AtlasContainedProcess)
    public static class ContainedProcess {
        const UInt32 CREATE_SUSPENDED = 0x00000004;
        const UInt32 CREATE_NO_WINDOW = 0x08000000;
        const UInt32 STARTF_USESHOWWINDOW = 0x00000001;
        const UInt16 SW_HIDE = 0;
        const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
        const int JobObjectBasicAndIoAccountingInformation = 8;
        const int JobObjectExtendedLimitInformation = 9;
        const UInt32 WAIT_OBJECT_0 = 0;
        const UInt32 WAIT_FAILED = 0xFFFFFFFF;
        const UInt32 STILL_ACTIVE = 259;

        [StructLayout(LayoutKind.Sequential)]
        struct PROCESS_INFORMATION {
            public IntPtr hProcess;
            public IntPtr hThread;
            public UInt32 dwProcessId;
            public UInt32 dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct STARTUPINFO {
            public Int32 cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public UInt32 dwX;
            public UInt32 dwY;
            public UInt32 dwXSize;
            public UInt32 dwYSize;
            public UInt32 dwXCountChars;
            public UInt32 dwYCountChars;
            public UInt32 dwFillAttribute;
            public UInt32 dwFlags;
            public UInt16 wShowWindow;
            public UInt16 cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
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

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool CreateProcess(
            string applicationName, StringBuilder commandLine, IntPtr processAttributes,
            IntPtr threadAttributes, bool inheritHandles, UInt32 creationFlags,
            IntPtr environment, string currentDirectory, ref STARTUPINFO startupInfo,
            out PROCESS_INFORMATION processInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr CreateJobObject(IntPtr jobAttributes, string name);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool SetInformationJobObject(
            IntPtr job, int informationClass, ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION information,
            int informationLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool QueryInformationJobObject(
            IntPtr job, int informationClass,
            out JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION information,
            int informationLength, out int returnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateJobObject(IntPtr job, UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateProcess(IntPtr process, UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 ResumeThread(IntPtr thread);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern UInt32 WaitForSingleObject(IntPtr handle, UInt32 milliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetExitCodeProcess(IntPtr process, out UInt32 exitCode);

        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr handle);

        static Win32Exception LastError(string operation) {
            return new Win32Exception(Marshal.GetLastWin32Error(), operation);
        }

        static UInt32 ActiveProcessCount(IntPtr job) {
            JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION accounting;
            int returned;
            if (!QueryInformationJobObject(job, JobObjectBasicAndIoAccountingInformation,
                    out accounting, Marshal.SizeOf(typeof(JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION)),
                    out returned)) {
                throw LastError("QueryInformationJobObject failed");
            }
            return accounting.BasicInfo.ActiveProcesses;
        }

        static bool DrainJob(IntPtr job, int milliseconds) {
            Stopwatch timer = Stopwatch.StartNew();
            while (timer.ElapsedMilliseconds < milliseconds) {
                if (ActiveProcessCount(job) == 0) return true;
                Thread.Sleep(25);
            }
            return ActiveProcessCount(job) == 0;
        }

        static Exception Unconfirmed(Exception inner) {
            InvalidOperationException failure = new InvalidOperationException(
                "The process failed and Atlas could not confirm that its process tree terminated.", inner);
            failure.Data["AtlasProcessMayStillBeRunning"] = true;
            return failure;
        }

        public static UInt32 Run(string applicationPath, string commandLine,
                string workingDirectory, int timeoutMilliseconds, bool hideWindow,
                bool createNoWindow) {
            if (timeoutMilliseconds < 1) throw new ArgumentOutOfRangeException("timeoutMilliseconds");

            IntPtr job = IntPtr.Zero;
            PROCESS_INFORMATION process = new PROCESS_INFORMATION();
            bool childCreated = false;
            bool jobAssigned = false;
            bool jobDrained = false;
            try {
                job = CreateJobObject(IntPtr.Zero, null);
                if (job == IntPtr.Zero) throw LastError("CreateJobObject failed");
                JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
                limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
                if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation, ref limits,
                        Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION)))) {
                    throw LastError("SetInformationJobObject failed");
                }

                STARTUPINFO startup = new STARTUPINFO();
                startup.cb = Marshal.SizeOf(typeof(STARTUPINFO));
                if (hideWindow) {
                    startup.dwFlags = STARTF_USESHOWWINDOW;
                    startup.wShowWindow = SW_HIDE;
                }
                UInt32 flags = CREATE_SUSPENDED | (createNoWindow ? CREATE_NO_WINDOW : 0);
                if (!CreateProcess(applicationPath, new StringBuilder(commandLine), IntPtr.Zero,
                        IntPtr.Zero, false, flags, IntPtr.Zero, workingDirectory, ref startup,
                        out process)) {
                    throw LastError("CreateProcessW failed");
                }
                childCreated = true;
                if (!AssignProcessToJobObject(job, process.hProcess)) {
                    throw LastError("AssignProcessToJobObject failed");
                }
                jobAssigned = true;
                if (ResumeThread(process.hThread) != 1) {
                    throw LastError("ResumeThread failed");
                }

                Stopwatch timer = Stopwatch.StartNew();
                bool rootExited = false;
                UInt32 exitCode = STILL_ACTIVE;
                while (timer.ElapsedMilliseconds < timeoutMilliseconds) {
                    if (!rootExited) {
                        UInt32 wait = WaitForSingleObject(process.hProcess, 0);
                        if (wait == WAIT_OBJECT_0) {
                            if (!GetExitCodeProcess(process.hProcess, out exitCode)) {
                                throw LastError("GetExitCodeProcess failed");
                            }
                            rootExited = true;
                        }
                        else if (wait == WAIT_FAILED) {
                            throw LastError("WaitForSingleObject failed");
                        }
                    }
                    if (rootExited && ActiveProcessCount(job) == 0) {
                        jobDrained = true;
                        return exitCode;
                    }
                    Thread.Sleep(25);
                }

                if (!TerminateJobObject(job, 0xC000013A)) {
                    throw LastError("TerminateJobObject failed after timeout");
                }
                if (!DrainJob(job, 10000)) {
                    throw new TimeoutException("The timed-out process tree did not drain within 10 seconds.");
                }
                jobDrained = true;
                throw new TimeoutException(String.Format(
                    "The process exceeded its {0}-second timeout and its process tree was terminated.",
                    timeoutMilliseconds / 1000));
            }
            catch (Exception failure) {
                if (childCreated && !jobDrained && job != IntPtr.Zero) {
                    try {
                        if (jobAssigned) {
                            if (!TerminateJobObject(job, 0xC000013A) || !DrainJob(job, 10000)) {
                                throw LastError("Process-tree cleanup failed");
                            }
                        }
                        else {
                            // Assignment happens while the root is suspended, so it cannot
                            // have descendants when this fallback is required.
                            if (!TerminateProcess(process.hProcess, 0xC000013A) ||
                                WaitForSingleObject(process.hProcess, 10000) != WAIT_OBJECT_0) {
                                throw LastError("Suspended process cleanup failed");
                            }
                        }
                        jobDrained = true;
                    }
                    catch (Exception cleanupFailure) {
                        throw Unconfirmed(new AggregateException(failure, cleanupFailure));
                    }
                }
                throw;
            }
            finally {
                if (process.hThread != IntPtr.Zero) CloseHandle(process.hThread);
                if (process.hProcess != IntPtr.Zero) CloseHandle(process.hProcess);
                if (job != IntPtr.Zero) CloseHandle(job);
            }
        }
    }

    // ----- Priority launcher -----
    // PowerShell consumer: Operations\Invoke-AtlasPriorityLaunch.ps1 (Invoke-AtlasPriorityLaunch)
    public static class PriorityLauncher
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

    // Update the live session as well as the profile: theme application can write
    // cached accessibility flags back over a registry-only shortcut change.
    // https://learn.microsoft.com/windows/win32/api/winuser/ns-winuser-highcontrastw
    public static class HighContrastShortcut
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct HighContrast
        {
            public uint Size;
            public uint Flags;
            public IntPtr DefaultScheme;
        }

        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SystemParametersInfo(uint action, uint size, ref HighContrast value, uint update);

        [DllImport("kernel32.dll")]
        private static extern IntPtr LocalFree(IntPtr memory);

        public static void DisableForCurrentUser()
        {
            using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
            using (Process process = Process.GetCurrentProcess())
            {
                if (identity.IsSystem || process.SessionId == 0 ||
                    new WindowsPrincipal(identity).IsInRole(WindowsBuiltInRole.Administrator))
                    throw new InvalidOperationException("Accessibility setup requires a non-elevated interactive user.");
            }

            HighContrast value = new HighContrast();
            value.Size = (uint)Marshal.SizeOf(typeof(HighContrast));
            try
            {
                if (!SystemParametersInfo(0x42, value.Size, ref value, 0))
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "Reading High Contrast settings failed.");

                // Only disable HOTKEYACTIVE. Keep HIGHCONTRASTON and the current
                // scheme unchanged; NOTHEMECHANGE prevents a needless theme reload.
                value.Flags = (value.Flags & ~4u) | 0x1000u;
                if (!SystemParametersInfo(0x43, value.Size, ref value, 3))
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "Saving High Contrast shortcut settings failed.");
            }
            finally
            {
                if (value.DefaultScheme != IntPtr.Zero) LocalFree(value.DefaultScheme);
            }
        }
    }

    // ----- Desktop wallpaper -----
    // PowerShell consumer: Entry\Initialize-NewUser.ps1
    public static class Wallpaper
    {
        [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
        public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
    }

    // ----- Known folders -----
    // PowerShell consumer: Atlas.Registry\Domain\UserPaths.ps1 (Get-UserPath)
    // https://learn.microsoft.com/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
    public class KnownFolder
    {
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        public static extern int SHGetKnownFolderPath(
            [MarshalAs(UnmanagedType.LPStruct)] Guid rfid,
            uint dwFlags,
            IntPtr hToken,
            out IntPtr pszPath
        );
    }

    // ----- Shortcut property store -----
    // PowerShell consumer: Atlas.Shortcuts\Atlas.Shortcuts.psm1 (Set-AtlasShortcutAppUserModelId)
    [ComImport]
    [Guid("00021401-0000-0000-C000-000000000046")]
    internal class ShellLink
    {
    }

    [ComImport]
    [Guid("0000010B-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPersistFile
    {
        void GetClassID(out Guid classId);
        [PreserveSig] int IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string fileName, uint mode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string fileName, [MarshalAs(UnmanagedType.Bool)] bool remember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string fileName);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string fileName);
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    internal struct PropertyKey
    {
        internal Guid FormatId;
        internal uint PropertyId;
    }

    [StructLayout(LayoutKind.Explicit)]
    internal struct PropVariant
    {
        [FieldOffset(0)] internal ushort VariantType;
        [FieldOffset(8)] internal IntPtr PointerValue;
    }

    [ComImport]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPropertyStore
    {
        uint GetCount();
        void GetAt(uint propertyIndex, out PropertyKey key);
        void GetValue(ref PropertyKey key, out PropVariant value);
        void SetValue(ref PropertyKey key, ref PropVariant value);
        void Commit();
    }

    public static class ShortcutPropertyStore
    {
        [DllImport("ole32.dll")]
        private static extern int PropVariantClear(ref PropVariant value);

        public static void SetAppUserModelId(string path, string appUserModelId)
        {
            object link = new ShellLink();
            PropVariant value = new PropVariant();
            try
            {
                IPersistFile file = (IPersistFile)link;
                file.Load(path, 2); // STGM_READWRITE

                PropertyKey key = new PropertyKey
                {
                    FormatId = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
                    PropertyId = 5
                };
                value.VariantType = 31; // VT_LPWSTR
                value.PointerValue = Marshal.StringToCoTaskMemUni(appUserModelId);

                IPropertyStore store = (IPropertyStore)link;
                store.SetValue(ref key, ref value);
                store.Commit();
                file.Save(path, true);
            }
            finally
            {
                PropVariantClear(ref value);
                if (link != null && Marshal.IsComObject(link))
                {
                    Marshal.FinalReleaseComObject(link);
                }
            }
        }
    }

    // ----- Shell window -----
    // PowerShell consumer: Atlas.TasksProcs\Domain\Processes.ps1 (Get-AtlasShellWindowProcessId)
    public static class ShellWindow
    {
        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern System.IntPtr GetShellWindow();

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(System.IntPtr window, out uint processId);
    }

    // ----- Theme manager -----
    // PowerShell consumer: Atlas.Themes\Domain\ThemeApplication.ps1 (Set-AtlasTheme)
    public static class ThemeManager
    {
        public static void ApplyTheme(string themeFilePath)
        {
            IThemeManager themeManager = new ThemeManagerClass();
            themeManager.ApplyTheme(themeFilePath);
        }

        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        [Guid("D23CC733-5522-406D-8DFB-B3CF5EF52A71")]
        [ComImport]
        public interface ITheme
        {
        }

        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        [Guid("0646EBBE-C1B7-4045-8FD0-FFD65D3FC792")]
        [ComImport]
        public interface IThemeManager
        {
            [DispId(1610678272)]
            ITheme CurrentTheme { get; }

            [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
            void ApplyTheme([MarshalAs(UnmanagedType.BStr)] string themeFilePath);
        }

        [TypeLibType(TypeLibTypeFlags.FCanCreate)]
        [Guid("C04B329E-5823-4415-9C93-BA44688947B0")]
        [ClassInterface(ClassInterfaceType.None)]
        [ComImport]
        public class ThemeManagerClass : IThemeManager
        {
            [DispId(1610678272)]
            public virtual extern ITheme CurrentTheme { [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)] get; }

            [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
            public virtual extern void ApplyTheme([MarshalAs(UnmanagedType.BStr)] string themeFilePath);
        }
    }

    // ----- Installing-user process launch (Atlas.Core\Domain\RunAsUser.ps1) -----

    public static class UserProcess {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct STARTUPINFO {
            public int cb;
            public string lpReserved, lpDesktop, lpTitle;
            public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars;
            public int dwFillAttribute, dwFlags;
            public short wShowWindow, cbReserved2;
            public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct PROCESS_INFORMATION {
            public IntPtr hProcess, hThread;
            public int dwProcessId, dwThreadId;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct SID_AND_ATTRIBUTES { public IntPtr Sid; public uint Attributes; }
        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_USER { public SID_AND_ATTRIBUTES User; }
        enum SECURITY_IMPERSONATION_LEVEL {
            SecurityAnonymous, SecurityIdentification, SecurityImpersonation, SecurityDelegation
        }
        const int TokenUser = 1;
        const int TokenType = 8;
        const int TokenSessionId = 12;
        const int TokenElevationType = 18;
        const int TokenLinkedToken = 19;
        const int TokenIntegrityLevel = 25;
        const int PrimaryToken = 1;
        const int TokenElevationTypeDefault = 1;
        const int TokenElevationTypeFull = 2;
        const int TokenElevationTypeLimited = 3;
        const int TOKEN_ASSIGN_PRIMARY = 0x0001;
        const int TOKEN_DUPLICATE = 0x0002;
        const int TOKEN_QUERY = 0x0008;
        const int KEY_QUERY_VALUE = 0x0001;
        const int CREATE_UNICODE_ENVIRONMENT = 0x00000400;
        const int CREATE_NO_WINDOW = 0x08000000;
        const uint WAIT_OBJECT_0 = 0;
        const uint WAIT_TIMEOUT = 0x00000102;
        const uint WAIT_FAILED = 0xFFFFFFFF;
        [DllImport("wtsapi32.dll", SetLastError = true)]
        static extern bool WTSQueryUserToken(uint sessionId, out IntPtr token);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool DuplicateTokenEx(IntPtr existingToken, uint access,
            IntPtr tokenAttributes, SECURITY_IMPERSONATION_LEVEL impersonationLevel,
            int tokenType, out IntPtr newToken);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(IntPtr token, int informationClass,
            IntPtr information, int length, out int returned);
        [DllImport("advapi32.dll", EntryPoint = "RegOpenKeyExW", CharSet = CharSet.Unicode)]
        static extern int RegOpenKeyEx(UIntPtr key, string subKey, uint options,
            int access, out IntPtr result);
        [DllImport("advapi32.dll")]
        static extern int RegCloseKey(IntPtr key);
        [DllImport("userenv.dll", SetLastError = true)]
        static extern bool CreateEnvironmentBlock(out IntPtr environment, IntPtr token,
            bool inherit);
        [DllImport("userenv.dll", SetLastError = true)]
        static extern bool DestroyEnvironmentBlock(IntPtr environment);
        [DllImport("advapi32.dll", EntryPoint = "CreateProcessAsUserW",
            CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool CreateProcessAsUser(IntPtr token, string applicationName,
            StringBuilder commandLine, IntPtr processAttributes, IntPtr threadAttributes,
            bool inheritHandles, int flags, IntPtr environment, string currentDirectory,
            ref STARTUPINFO startupInfo, out PROCESS_INFORMATION processInformation);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetExitCodeProcess(IntPtr process, out uint exitCode);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateProcess(IntPtr process, uint exitCode);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr handle);

        static Win32Exception LastError(string operation) {
            int error = Marshal.GetLastWin32Error();
            return new Win32Exception(error,
                String.Format("{0} (Win32 error {1}).", operation, error));
        }

        static string ReadTokenSid(IntPtr token) {
            int required;
            GetTokenInformation(token, TokenUser, IntPtr.Zero, 0, out required);
            IntPtr buffer = Marshal.AllocHGlobal(required);
            try {
                if (!GetTokenInformation(token, TokenUser, buffer, required, out required)) {
                    throw LastError("GetTokenInformation(TokenUser) failed");
                }
                TOKEN_USER user = (TOKEN_USER)Marshal.PtrToStructure(buffer,
                    typeof(TOKEN_USER));
                return new SecurityIdentifier(user.User.Sid).Value;
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static int ReadTokenInt32(IntPtr token, int informationClass) {
            IntPtr buffer = Marshal.AllocHGlobal(sizeof(int));
            try {
                int returned;
                if (!GetTokenInformation(token, informationClass, buffer, sizeof(int),
                        out returned)) {
                    throw LastError("GetTokenInformation failed");
                }
                return Marshal.ReadInt32(buffer);
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static IntPtr ReadLinkedToken(IntPtr token) {
            IntPtr buffer = Marshal.AllocHGlobal(IntPtr.Size);
            try {
                int returned;
                if (!GetTokenInformation(token, TokenLinkedToken, buffer, IntPtr.Size,
                        out returned)) {
                    throw LastError("GetTokenInformation(TokenLinkedToken) failed");
                }
                IntPtr linkedToken = Marshal.ReadIntPtr(buffer);
                if (linkedToken == IntPtr.Zero) {
                    throw new InvalidOperationException("The elevated user token has no linked limited token.");
                }
                return linkedToken;
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static int ReadIntegrityLevel(IntPtr token) {
            int required;
            GetTokenInformation(token, TokenIntegrityLevel, IntPtr.Zero, 0, out required);
            IntPtr buffer = Marshal.AllocHGlobal(required);
            try {
                if (!GetTokenInformation(token, TokenIntegrityLevel, buffer, required,
                        out required)) {
                    throw LastError("GetTokenInformation(TokenIntegrityLevel) failed");
                }
                SID_AND_ATTRIBUTES label = (SID_AND_ATTRIBUTES)Marshal.PtrToStructure(
                    buffer, typeof(SID_AND_ATTRIBUTES));
                string[] parts = new SecurityIdentifier(label.Sid).Value.Split('-');
                return Int32.Parse(parts[parts.Length - 1]);
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }

        static bool IsAdministrator(IntPtr token) {
            using (WindowsIdentity identity = new WindowsIdentity(token)) {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(new SecurityIdentifier("S-1-5-32-544"));
            }
        }

        public static void ValidateIdentity(string expectedSid, uint expectedSession,
            string actualSid, uint actualSession, int tokenType) {
            string canonicalExpected = new SecurityIdentifier(expectedSid).Value;
            string canonicalActual = new SecurityIdentifier(actualSid).Value;
            if (!String.Equals(canonicalExpected, canonicalActual,
                    StringComparison.Ordinal)) {
                throw new InvalidOperationException("The WTS token SID does not match the installing user.");
            }
            if (expectedSession == 0 || actualSession != expectedSession) {
                throw new InvalidOperationException("The WTS token session does not match the installing user.");
            }
            if (tokenType != PrimaryToken) {
                throw new InvalidOperationException("WTSQueryUserToken did not return a primary token.");
            }
        }

        static void ValidateToken(IntPtr token, string expectedSid, uint expectedSession) {
            ValidateIdentity(expectedSid, expectedSession, ReadTokenSid(token),
                unchecked((uint)ReadTokenInt32(token, TokenSessionId)),
                ReadTokenInt32(token, TokenType));
        }

        public static void ValidateMediumIdentity(int elevationType,
            int integrityLevel, bool isAdministrator) {
            if (elevationType == TokenElevationTypeFull) {
                throw new InvalidOperationException("The installing-user token is elevated.");
            }
            if (elevationType != TokenElevationTypeDefault &&
                    elevationType != TokenElevationTypeLimited) {
                throw new InvalidOperationException("The installing-user token has an invalid elevation type.");
            }
            if (integrityLevel < 0x2000 || integrityLevel >= 0x3000) {
                throw new InvalidOperationException("The installing-user token is not medium integrity.");
            }
            if (isAdministrator) {
                throw new InvalidOperationException("The installing-user token has the Administrators role enabled.");
            }
        }

        static void ValidateMediumToken(IntPtr token) {
            ValidateMediumIdentity(ReadTokenInt32(token, TokenElevationType),
                ReadIntegrityLevel(token), IsAdministrator(token));
        }

        public static int Launch(string applicationName, string commandLine,
            string workingDirectory, uint timeoutMilliseconds,
            uint sessionId, string expectedSid) {
            IntPtr profile = IntPtr.Zero;
            IntPtr userToken = IntPtr.Zero;
            IntPtr linkedToken = IntPtr.Zero;
            IntPtr primaryToken = IntPtr.Zero;
            IntPtr environment = IntPtr.Zero;
            PROCESS_INFORMATION process = new PROCESS_INFORMATION();
            try {
                int profileStatus = RegOpenKeyEx(new UIntPtr(0x80000003u), expectedSid,
                    0, KEY_QUERY_VALUE, out profile);
                if (profileStatus != 0 || profile == IntPtr.Zero) {
                    throw new Win32Exception(profileStatus,
                        "The installing user's HKU profile is not loaded.");
                }
                if (!WTSQueryUserToken(sessionId, out userToken)) {
                    throw LastError("WTSQueryUserToken failed for session " + sessionId);
                }
                ValidateToken(userToken, expectedSid, sessionId);
                IntPtr launchToken = userToken;
                int elevationType = ReadTokenInt32(userToken, TokenElevationType);
                if (elevationType == TokenElevationTypeFull) {
                    linkedToken = ReadLinkedToken(userToken);
                    launchToken = linkedToken;
                    ValidateToken(launchToken, expectedSid, sessionId);
                }
                ValidateMediumToken(launchToken);
                uint access = TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_QUERY;
                if (!DuplicateTokenEx(launchToken, access, IntPtr.Zero,
                        SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation,
                        PrimaryToken, out primaryToken)) {
                    throw LastError("DuplicateTokenEx failed for the installing user");
                }
                ValidateToken(primaryToken, expectedSid, sessionId);
                ValidateMediumToken(primaryToken);
                if (!CreateEnvironmentBlock(out environment, primaryToken, false)) {
                    throw LastError("CreateEnvironmentBlock failed for the installing user");
                }

                STARTUPINFO startup = new STARTUPINFO();
                startup.cb = Marshal.SizeOf(typeof(STARTUPINFO));
                startup.lpDesktop = "winsta0\\default";
                if (!CreateProcessAsUser(primaryToken, applicationName,
                        new StringBuilder(commandLine), IntPtr.Zero, IntPtr.Zero, false,
                        CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW, environment,
                        workingDirectory, ref startup, out process)) {
                    throw LastError("CreateProcessAsUser failed");
                }

                uint waitResult = WaitForSingleObject(process.hProcess, timeoutMilliseconds);
                if (waitResult == WAIT_TIMEOUT) {
                    if (!TerminateProcess(process.hProcess, 0xC000013Au) &&
                            WaitForSingleObject(process.hProcess, 0) != WAIT_OBJECT_0) {
                        throw LastError("TerminateProcess failed after the installing-user timeout");
                    }
                    uint terminateWait = WaitForSingleObject(process.hProcess, 10000);
                    if (terminateWait == WAIT_TIMEOUT) {
                        throw new TimeoutException(
                            "The installing-user process did not terminate after its timeout.");
                    }
                    if (terminateWait == WAIT_FAILED) {
                        throw LastError("Waiting for the timed-out installing-user process failed");
                    }
                    throw new TimeoutException("The installing-user process timed out.");
                }
                if (waitResult == WAIT_FAILED) {
                    throw LastError("WaitForSingleObject failed");
                }
                if (waitResult != WAIT_OBJECT_0) {
                    throw new InvalidOperationException("WaitForSingleObject returned an unexpected status.");
                }
                uint exitCode;
                if (!GetExitCodeProcess(process.hProcess, out exitCode)) {
                    throw LastError("GetExitCodeProcess failed");
                }
                return unchecked((int)exitCode);
            }
            finally {
                if (process.hThread != IntPtr.Zero) CloseHandle(process.hThread);
                if (process.hProcess != IntPtr.Zero) CloseHandle(process.hProcess);
                if (environment != IntPtr.Zero) DestroyEnvironmentBlock(environment);
                if (primaryToken != IntPtr.Zero) CloseHandle(primaryToken);
                if (linkedToken != IntPtr.Zero) CloseHandle(linkedToken);
                if (userToken != IntPtr.Zero) CloseHandle(userToken);
                if (profile != IntPtr.Zero) RegCloseKey(profile);
            }
        }
    }
}
