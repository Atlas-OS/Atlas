# Atlas.Core domain: run a process as the interactive user from a SYSTEM context.
#
# This is the mirror of RunAsTI.cmd: where that elevates to TrustedInstaller, this drops
# from SYSTEM/TrustedInstaller down to the logged-on interactive user. It is the technique
# AME Wizard's backend (TrustedUninstaller) uses for `runas: currentUser` - grab the active
# console session's user token with WTSQueryUserToken and CreateProcessAsUser onto the
# interactive desktop (winsta0\default), which shell COM (theme apply, pin-to-Home) needs.
#
# Requires the calling process to be SYSTEM (S-1-5-18) so it holds SeTcbPrivilege; the
# install phases that use this run as TrustedInstaller, which qualifies.

$script:AtlasRunAsUserTypeLoaded = $false

function Initialize-AtlasRunAsUserType {
    if ($script:AtlasRunAsUserTypeLoaded) {
        return
    }

    $signature = @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace Atlas {
    public static class UserProcess {
        [StructLayout(LayoutKind.Sequential)]
        struct STARTUPINFO {
            public int cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
            public short wShowWindow, cbReserved2;
            public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct PROCESS_INFORMATION {
            public IntPtr hProcess, hThread;
            public int dwProcessId, dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct SECURITY_ATTRIBUTES {
            public int nLength;
            public IntPtr lpSecurityDescriptor;
            public bool bInheritHandle;
        }

        enum SECURITY_IMPERSONATION_LEVEL { SecurityAnonymous, SecurityIdentification, SecurityImpersonation, SecurityDelegation }
        enum TOKEN_TYPE { TokenPrimary = 1, TokenImpersonation }
        enum TOKEN_INFORMATION_CLASS { TokenLinkedToken = 19 }

        [StructLayout(LayoutKind.Sequential)]
        struct LUID {
            public uint LowPart;
            public int HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct TOKEN_PRIVILEGES {
            public int PrivilegeCount;
            public LUID Luid;
            public int Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct WTS_SESSION_INFO {
            public uint SessionId;
            public IntPtr pWinStationName;
            public int State; // WTS_CONNECTSTATE_CLASS; 0 = WTSActive
        }

        const int TOKEN_DUPLICATE = 0x0002;
        const int TOKEN_ADJUST_PRIVILEGES = 0x0020;
        const int TOKEN_QUERY = 0x0008;
        const int SE_PRIVILEGE_ENABLED = 0x0002;
        const int ERROR_NOT_ALL_ASSIGNED = 1300;
        const uint MAXIMUM_ALLOWED = 0x02000000;
        const int CREATE_UNICODE_ENVIRONMENT = 0x00000400;
        const int CREATE_NO_WINDOW = 0x08000000;
        const uint INFINITE = 0xFFFFFFFF;

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern uint WTSGetActiveConsoleSessionId();

        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentProcess();

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(IntPtr ProcessHandle, int DesiredAccess, out IntPtr TokenHandle);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

        [DllImport("wtsapi32.dll", SetLastError = true)]
        static extern bool WTSEnumerateSessions(IntPtr hServer, int Reserved, int Version, out IntPtr ppSessionInfo, out int pCount);

        [DllImport("wtsapi32.dll")]
        static extern void WTSFreeMemory(IntPtr pMemory);

        [DllImport("wtsapi32.dll", SetLastError = true)]
        static extern bool WTSQueryUserToken(uint sessionId, out IntPtr phToken);

        // SYSTEM holds these privileges but they can arrive disabled; WTSQueryUserToken
        // needs SeTcb and CreateProcessAsUser needs SeAssignPrimaryToken + SeIncreaseQuota.
        static void EnablePrivilege(string name) {
            IntPtr token;
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out token)) {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "OpenProcessToken failed.");
            }
            try {
                LUID luid;
                if (!LookupPrivilegeValue(null, name, out luid)) {
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "LookupPrivilegeValue(" + name + ") failed.");
                }
                TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
                tp.PrivilegeCount = 1;
                tp.Luid = luid;
                tp.Attributes = SE_PRIVILEGE_ENABLED;
                if (!AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero) || Marshal.GetLastWin32Error() == ERROR_NOT_ALL_ASSIGNED) {
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "Enabling privilege " + name + " failed (is the caller SYSTEM?).");
                }
            }
            finally {
                CloseHandle(token);
            }
        }

        // The interactive user can be in a non-console session (Hyper-V enhanced session,
        // RDP), so pick the first active user session and only fall back to the console.
        static uint GetInteractiveSessionId() {
            IntPtr pSessions;
            int count;
            if (WTSEnumerateSessions(IntPtr.Zero, 0, 1, out pSessions, out count)) {
                try {
                    int size = Marshal.SizeOf(typeof(WTS_SESSION_INFO));
                    for (int i = 0; i < count; i++) {
                        WTS_SESSION_INFO info = (WTS_SESSION_INFO)Marshal.PtrToStructure(new IntPtr(pSessions.ToInt64() + (long)i * size), typeof(WTS_SESSION_INFO));
                        if (info.State == 0 && info.SessionId != 0) {
                            return info.SessionId;
                        }
                    }
                }
                finally {
                    WTSFreeMemory(pSessions);
                }
            }
            return WTSGetActiveConsoleSessionId();
        }

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool DuplicateTokenEx(IntPtr hExistingToken, uint dwDesiredAccess, IntPtr lpTokenAttributes,
            SECURITY_IMPERSONATION_LEVEL impersonationLevel, TOKEN_TYPE tokenType, out IntPtr phNewToken);

        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(IntPtr TokenHandle, TOKEN_INFORMATION_CLASS TokenInformationClass,
            out IntPtr TokenInformation, int TokenInformationLength, out int ReturnLength);

        [DllImport("userenv.dll", SetLastError = true)]
        static extern bool CreateEnvironmentBlock(out IntPtr lpEnvironment, IntPtr hToken, bool bInherit);

        [DllImport("userenv.dll", SetLastError = true)]
        static extern bool DestroyEnvironmentBlock(IntPtr lpEnvironment);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool CreateProcessAsUser(IntPtr hToken, string lpApplicationName, StringBuilder lpCommandLine,
            IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, int dwCreationFlags,
            IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetExitCodeProcess(IntPtr hProcess, out uint lpExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);

        // Runs the command line as the active console user; returns the child exit code
        // (or 0 when not waiting). Throws Win32Exception on any failure.
        public static int Launch(string applicationName, string commandLine, string workingDirectory, bool wait, bool elevated) {
            EnablePrivilege("SeTcbPrivilege");
            EnablePrivilege("SeAssignPrimaryTokenPrivilege");
            EnablePrivilege("SeIncreaseQuotaPrivilege");

            uint sessionId = GetInteractiveSessionId();
            if (sessionId == 0xFFFFFFFF) {
                throw new InvalidOperationException("No active user session; there is no interactive user to run as.");
            }

            IntPtr userToken = IntPtr.Zero;
            if (!WTSQueryUserToken(sessionId, out userToken)) {
                int error = Marshal.GetLastWin32Error();
                throw new Win32Exception(error, string.Format("WTSQueryUserToken failed for session {0} (Win32 error {1}).", sessionId, error));
            }

            IntPtr primaryToken = IntPtr.Zero;
            IntPtr envBlock = IntPtr.Zero;
            IntPtr linkedToken = IntPtr.Zero;
            try {
                IntPtr sourceToken = userToken;

                // For UserElevated, follow the linked (elevated) token when the interactive
                // token is a filtered admin token.
                if (elevated) {
                    IntPtr info;
                    int returned;
                    if (GetTokenInformation(userToken, TOKEN_INFORMATION_CLASS.TokenLinkedToken, out info, IntPtr.Size, out returned) && info != IntPtr.Zero) {
                        linkedToken = Marshal.ReadIntPtr(info);
                        Marshal.FreeHGlobal(info);
                        if (linkedToken != IntPtr.Zero) {
                            sourceToken = linkedToken;
                        }
                    }
                }

                if (!DuplicateTokenEx(sourceToken, MAXIMUM_ALLOWED, IntPtr.Zero,
                        SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, TOKEN_TYPE.TokenPrimary, out primaryToken)) {
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "DuplicateTokenEx failed.");
                }

                if (!CreateEnvironmentBlock(out envBlock, primaryToken, false)) {
                    envBlock = IntPtr.Zero; // non-fatal; fall back to no explicit environment
                }

                STARTUPINFO si = new STARTUPINFO();
                si.cb = Marshal.SizeOf(si);
                si.lpDesktop = "winsta0\\default"; // the interactive desktop, required for shell COM

                PROCESS_INFORMATION pi;
                int flags = CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW;
                StringBuilder cmd = new StringBuilder(commandLine);

                bool ok = CreateProcessAsUser(primaryToken, applicationName, cmd, IntPtr.Zero, IntPtr.Zero,
                    false, flags, envBlock, workingDirectory, ref si, out pi);
                if (!ok) {
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "CreateProcessAsUser failed.");
                }

                int exitCode = 0;
                try {
                    if (wait) {
                        WaitForSingleObject(pi.hProcess, INFINITE);
                        uint code;
                        if (GetExitCodeProcess(pi.hProcess, out code)) {
                            exitCode = unchecked((int)code);
                        }
                    }
                }
                finally {
                    if (pi.hThread != IntPtr.Zero) { CloseHandle(pi.hThread); }
                    if (pi.hProcess != IntPtr.Zero) { CloseHandle(pi.hProcess); }
                }
                return exitCode;
            }
            finally {
                if (envBlock != IntPtr.Zero) { DestroyEnvironmentBlock(envBlock); }
                if (linkedToken != IntPtr.Zero) { CloseHandle(linkedToken); }
                if (primaryToken != IntPtr.Zero) { CloseHandle(primaryToken); }
                if (userToken != IntPtr.Zero) { CloseHandle(userToken); }
            }
        }
    }
}
'@

    Add-Type -TypeDefinition $signature -Language CSharp -ErrorAction Stop
    $script:AtlasRunAsUserTypeLoaded = $true
}

function Get-AtlasUserProcessCommandLine {
    <#
    .SYNOPSIS
        Builds the CreateProcessAsUser command line: the exe path quoted first so paths
        with spaces survive, then the raw argument string.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
        [string]$Arguments = ''
    )

    $commandLine = '"{0}"' -f $FilePath
    if ($Arguments) {
        $commandLine += " $Arguments"
    }
    return $commandLine
}

function Invoke-AtlasAsUser {
    <#
    .SYNOPSIS
        Runs a command line as the interactive console user from a SYSTEM/TrustedInstaller
        context, on the interactive desktop. Returns the child process exit code.
    .DESCRIPTION
        The engine equivalent of AME Wizard's `runas: currentUser`. The caller MUST be
        SYSTEM (the install phases that use this run as TrustedInstaller). Throws when
        there is no active interactive session (e.g. a headless stage) - callers should
        treat that as "skip, log a warning".
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [string]$Arguments = '',

        [string]$WorkingDirectory,

        [switch]$Elevated,

        [bool]$Wait = $true
    )

    if (-not (Test-AtlasTrustedInstaller)) {
        throw '[privilege] Invoke-AtlasAsUser must run as SYSTEM/TrustedInstaller to obtain the interactive user token.'
    }

    Initialize-AtlasRunAsUserType

    if (-not $WorkingDirectory) {
        $WorkingDirectory = (Get-AtlasContext).WinDir
    }

    $commandLine = Get-AtlasUserProcessCommandLine -FilePath $FilePath -Arguments $Arguments

    return [Atlas.UserProcess]::Launch($FilePath, $commandLine, $WorkingDirectory, $Wait, [bool]$Elevated)
}
