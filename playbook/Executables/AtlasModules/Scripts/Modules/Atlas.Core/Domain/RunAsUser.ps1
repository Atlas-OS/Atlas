# Atlas.Core domain: run the inbox Windows PowerShell host as the installing user.
#
# The install state supplies one explicit account SID and Windows session. Atlas asks
# WTS for only that session, verifies the returned token, and never enumerates sessions
# or falls back to whichever account happens to be active.

$script:AtlasRunAsUserTypeLoaded = $false

function Initialize-AtlasRunAsUserType {
    if ($script:AtlasRunAsUserTypeLoaded -or ('Atlas.UserProcess' -as [type])) {
        $script:AtlasRunAsUserTypeLoaded = $true
        return
    }

    $signature = @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;

namespace Atlas {
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
'@

    Add-AtlasTrustedInstallerNativeType -TypeDefinition $signature
    $script:AtlasRunAsUserTypeLoaded = $true
}

function Get-AtlasUserProcessCommandLine {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
        [string]$Arguments = ''
    )

    $commandLine = '"{0}"' -f $FilePath
    if (-not [string]::IsNullOrEmpty($Arguments)) {
        $commandLine += " $Arguments"
    }
    return $commandLine
}

function ConvertTo-AtlasRunAsUserSid {
    param([AllowNull()][AllowEmptyString()][string]$Value)

    try {
        $sid = New-Object Security.Principal.SecurityIdentifier($Value)
    }
    catch {
        throw 'The install state does not contain a valid interactive user SID.'
    }
    if (-not $sid.IsAccountSid() -or $sid.Value -cne $Value -or
        $sid.Value -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) {
        throw 'The install state does not contain an interactive account SID.'
    }
    return $sid.Value
}

function Invoke-AtlasBoundUserProcess {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This private helper owns the checked native child launch.'
    )]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string]$Arguments = '',
        [string]$WorkingDirectory,
        [bool]$Wait = $true,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 900,
        [scriptblock]$ContextReader = { Get-AtlasContext },
        [scriptblock]$ProcessLauncher = {
            param($ApplicationPath, $CommandLine, $CurrentDirectory,
                $TimeoutMilliseconds, $UserSid, $UserSessionId)
            Initialize-AtlasRunAsUserType
            [Atlas.UserProcess]::Launch($ApplicationPath, $CommandLine,
                $CurrentDirectory, $TimeoutMilliseconds,
                $UserSessionId, $UserSid)
        }
    )

    $contexts = @(& $ContextReader)
    if ($contexts.Count -ne 1 -or $null -eq $contexts[0]) {
        throw 'Get-AtlasContext must return exactly one install context.'
    }
    $context = $contexts[0]
    if ($context.IsOobe -isnot [bool]) {
        throw 'The install context does not contain a valid OOBE state.'
    }
    if ([bool]$context.IsOobe) {
        return 0
    }
    if (-not $Wait) {
        throw 'Detached installing-user processes are not supported.'
    }

    $userSid = ConvertTo-AtlasRunAsUserSid -Value ([string]$context.InteractiveUserSid)
    $sessionProperty = $context.PSObject.Properties['InteractiveUserSessionId']
    if ($null -eq $sessionProperty -or
        $sessionProperty.Value -isnot [int] -and
        $sessionProperty.Value -isnot [long]) {
        throw 'The install state does not contain an integer interactive user session ID.'
    }
    $sessionId = [long]$sessionProperty.Value
    if ($sessionId -lt 1 -or $sessionId -gt [int]::MaxValue) {
        throw 'The install state contains an invalid interactive user session ID.'
    }

    if ([string]::IsNullOrWhiteSpace([string]$context.WinDir) -or
        -not [IO.Path]::IsPathRooted([string]$context.WinDir)) {
        throw 'The install context does not contain an absolute Windows path.'
    }
    $windowsPath = [IO.Path]::GetFullPath([string]$context.WinDir)
    $expectedPowerShell = [IO.Path]::Combine(
        $windowsPath, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe'
    )
    if (-not [IO.Path]::IsPathRooted($FilePath) -or
        -not [IO.Path]::GetFullPath($FilePath).Equals(
            $expectedPowerShell, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Installing-user launches require the inbox Windows PowerShell host '$expectedPowerShell'."
    }
    if (-not [IO.File]::Exists($expectedPowerShell) -or
        (([IO.File]::GetAttributes($expectedPowerShell) -band
                [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "The inbox Windows PowerShell host is unavailable at '$expectedPowerShell'."
    }

    if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $WorkingDirectory = $windowsPath
    }
    if (-not [IO.Path]::IsPathRooted($WorkingDirectory)) {
        throw 'The installing-user working directory must be absolute.'
    }

    $commandLine = Get-AtlasUserProcessCommandLine -FilePath $expectedPowerShell `
        -Arguments $Arguments
    $results = @(& $ProcessLauncher $expectedPowerShell $commandLine `
            ([IO.Path]::GetFullPath($WorkingDirectory)) `
            ([uint32]($TimeoutSeconds * 1000)) $userSid ([uint32]$sessionId))
    if ($results.Count -ne 1 -or
        ($results[0] -isnot [int] -and $results[0] -isnot [long])) {
        throw 'The installing-user process launcher must return one integer exit code.'
    }
    $exitCode = [long]$results[0]
    if ($exitCode -lt [int]::MinValue -or $exitCode -gt [int]::MaxValue) {
        throw 'The installing-user process launcher returned an invalid exit code.'
    }
    return [int]$exitCode
}

function Invoke-AtlasAsUser {
    <#
    .SYNOPSIS
        Runs inbox Windows PowerShell as the exact installing user and returns its exit code.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This function is the explicit user-process execution boundary.'
    )]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
        [string]$Arguments = '',
        [string]$WorkingDirectory,
        [bool]$Wait = $true,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 900
    )

    if (-not (Test-AtlasSystem)) {
        throw '[privilege] Invoke-AtlasAsUser must run as SYSTEM.'
    }
    return Invoke-AtlasBoundUserProcess -FilePath $FilePath -Arguments $Arguments `
        -WorkingDirectory $WorkingDirectory -Wait:$Wait -TimeoutSeconds $TimeoutSeconds
}
