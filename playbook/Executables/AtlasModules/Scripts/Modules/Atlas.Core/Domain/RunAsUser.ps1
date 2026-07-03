# Atlas.Core domain: run a process as the interactive user from a SYSTEM context.
#
# This is the mirror of RunAsTI.cmd: where that elevates to TrustedInstaller, this drops
# from SYSTEM/TrustedInstaller down to the logged-on interactive user. It is the technique
# AME Wizard's backend (TrustedUninstaller) uses for `runas: currentUser` — grab the active
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

        const int TOKEN_DUPLICATE = 0x0002;
        const uint MAXIMUM_ALLOWED = 0x02000000;
        const int CREATE_UNICODE_ENVIRONMENT = 0x00000400;
        const int CREATE_NO_WINDOW = 0x08000000;
        const uint INFINITE = 0xFFFFFFFF;

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern uint WTSGetActiveConsoleSessionId();

        [DllImport("wtsapi32.dll", SetLastError = true)]
        static extern bool WTSQueryUserToken(uint sessionId, out IntPtr phToken);

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
            uint sessionId = WTSGetActiveConsoleSessionId();
            if (sessionId == 0xFFFFFFFF) {
                throw new InvalidOperationException("No active console session; there is no interactive user to run as.");
            }

            IntPtr userToken = IntPtr.Zero;
            if (!WTSQueryUserToken(sessionId, out userToken)) {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "WTSQueryUserToken failed (is the caller SYSTEM with a user logged on?).");
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

    # CreateProcessAsUser reads the whole invocation from the command line; the exe path is
    # quoted first so paths with spaces survive.
    $commandLine = '"{0}"' -f $FilePath
    if ($Arguments) {
        $commandLine += " $Arguments"
    }

    return [Atlas.UserProcess]::Launch($FilePath, $commandLine, $WorkingDirectory, $Wait, [bool]$Elevated)
}
