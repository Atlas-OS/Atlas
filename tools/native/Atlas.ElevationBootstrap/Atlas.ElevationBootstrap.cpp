#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#define SECURITY_WIN32

#include <windows.h>
#include <aclapi.h>
#include <bcrypt.h>
#include <sddl.h>
#include <shellapi.h>
#include <shlobj.h>
#include <stddef.h>
#include <stdint.h>

// This executable deliberately has no C/C++ runtime dependency.  The build links
// BufferOverflowU.lib so /GS remains active with the custom Unicode GUI entrypoint.
extern "C" void __security_init_cookie(void);

extern "C" __declspec(noinline) void* __cdecl memset(void* destination, int value,
        size_t length) {
    volatile unsigned char* bytes = static_cast<volatile unsigned char*>(destination);
    for (size_t index = 0; index < length; ++index) {
        bytes[index] = static_cast<unsigned char>(value);
    }
    return destination;
}

extern "C" __declspec(noinline) void* __cdecl memcpy(void* destination, const void* source,
        size_t length) {
    volatile unsigned char* output = static_cast<volatile unsigned char*>(destination);
    const volatile unsigned char* input = static_cast<const volatile unsigned char*>(source);
    for (size_t index = 0; index < length; ++index) {
        output[index] = input[index];
    }
    return destination;
}

extern "C" __declspec(noinline) size_t __cdecl wcslen(const wchar_t* value) {
    size_t length = 0;
    while (value[length] != L'\0') {
        ++length;
    }
    return length;
}

namespace AtlasBootstrap {

static const DWORD kExitInvalidInvocation = 10;
static const DWORD kExitInvalidElevation = 11;
static const DWORD kExitUntrustedPath = 12;
static const DWORD kExitPipeFailure = 13;
static const DWORD kExitInvalidPeer = 14;
static const DWORD kExitInvalidFrame = 15;
static const DWORD kExitEnvironmentFailure = 16;
static const DWORD kExitBrokerFailure = 17;
static const DWORD kExitContainmentFailure = 18;
static const DWORD kExitRequesterLost = 19;
static const DWORD kExitFailpoint = 20;

static const DWORD kFrameHeaderLength = 64;
static const DWORD kRequestMaximum = 16u * 1024u;
static const DWORD kReadyMaximum = 4u * 1024u;
static const DWORD kResultMaximum = 64u * 1024u;
static const ULONGLONG kConnectTimeoutMs = 60u * 1000u;
static const ULONGLONG kHandshakeTimeoutMs = 30u * 1000u;
static const ULONGLONG kOperationTimeoutMs = (24ull * 60ull * 60ull * 1000ull) + (60ull * 1000ull);
static const DWORD kTerminalPipeTimeoutMs = 10u * 1000u;
static const DWORD kTerminalDeliveryTimeoutMs = 30u * 1000u;
static const DWORD kBrokerExitTimeoutMs = 10u * 1000u;
static const DWORD kDrainTimeoutMs = 15u * 1000u;
static const DWORD kMaximumPathCharacters = 32768;
static const DWORD kMaximumCommandCharacters = 16384;
static const DWORD kMaximumEnvironmentCharacters = 32767;
static const DWORD kMaximumStaleDirectories = 64;
static const DWORD kMaximumCleanupEntries = 2048;
static const DWORD kMaximumCleanupDepth = 8;
static const ULONGLONG kMaximumCleanupBytes = 64ull * 1024ull * 1024ull;
static const ULONGLONG kStaleAge100ns = 48ull * 60ull * 60ull * 10000000ull;

static const BYTE kFrameMagic[8] = { 'A', 'T', 'L', 'A', 'S', 'T', 'I', '2' };
static const USHORT kFrameVersion = 2;
static const USHORT kFrameRequest = 1;
static const USHORT kFrameReady = 2;
static const USHORT kFrameResult = 3;

struct OwnedHandle {
    HANDLE value;
};

struct Frame {
    BYTE header[kFrameHeaderLength];
    BYTE* payload;
    DWORD payloadLength;
    USHORT kind;
};

struct RequesterEvidence {
    DWORD processId;
    ULONGLONG creationFileTime;
    DWORD sessionId;
    LPWSTR sid;
    OwnedHandle process;
};

struct FixedPaths {
    WCHAR windows[kMaximumPathCharacters];
    WCHAR system32[kMaximumPathCharacters];
    WCHAR self[kMaximumPathCharacters];
    WCHAR powershell[kMaximumPathCharacters];
    WCHAR broker[kMaximumPathCharacters];
    WCHAR programData[kMaximumPathCharacters];
    WCHAR tempRoot[kMaximumPathCharacters];
    WCHAR temp[kMaximumPathCharacters];
};

struct Containment {
    OwnedHandle job;
    OwnedHandle ownerGuard;
    OwnedHandle completionPort;
};

struct InternalPipes {
    OwnedHandle requestChildRead;
    OwnedHandle requestParentWrite;
    OwnedHandle resultParentRead;
    OwnedHandle resultChildWrite;
};

struct ExternalInputMonitor {
    OwnedHandle event;
    OVERLAPPED overlapped;
    BYTE byte;
    bool active;
};

enum class ExternalInputCompletion {
    Stopped,
    Closed,
    UnexpectedInput,
    Failed
};

// Set only after the outer kill-on-close job is fully initialized. Cancellation paths
// that cannot synchronously join must terminate the job explicitly before ExitProcess:
// the broker temporarily inherits a duplicate while atomically assigning its TI child.
static HANDLE gContainmentJobForFailFast = nullptr;

enum class Failpoint {
    None,
    AfterPipeCreate,
    AfterClientBind,
    AfterRequestRelay,
    AfterBrokerCreate,
    AfterReadyRelay,
    BeforeResultRelay,
    ForceSynchronousIoNonJoin
};

static void Close(OwnedHandle* handle) {
    if (handle != nullptr && handle->value != nullptr && handle->value != INVALID_HANDLE_VALUE) {
        CloseHandle(handle->value);
        handle->value = nullptr;
    }
}

[[noreturn]] static void FailFastContainment() {
    HANDLE job = gContainmentJobForFailFast;
    if (job != nullptr && job != INVALID_HANDLE_VALUE) {
        TerminateJobObject(job, kExitContainmentFailure);
    }
    ExitProcess(kExitContainmentFailure);
}

static void* Allocate(SIZE_T length) {
    if (length == 0) {
        length = 1;
    }
    return HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, length);
}

static void Release(void* memory) {
    if (memory != nullptr) {
        HeapFree(GetProcessHeap(), 0, memory);
    }
}

static SIZE_T StringLength(const WCHAR* value) {
    if (value == nullptr) {
        return 0;
    }
    const WCHAR* cursor = value;
    while (*cursor != L'\0') {
        ++cursor;
    }
    return static_cast<SIZE_T>(cursor - value);
}

static bool CopyString(WCHAR* destination, SIZE_T capacity, const WCHAR* source) {
    if (destination == nullptr || source == nullptr || capacity == 0) {
        return false;
    }
    const SIZE_T length = StringLength(source);
    if (length >= capacity) {
        return false;
    }
    for (SIZE_T index = 0; index <= length; ++index) {
        destination[index] = source[index];
    }
    return true;
}

static bool AppendString(WCHAR* destination, SIZE_T capacity, const WCHAR* suffix) {
    if (destination == nullptr || suffix == nullptr) {
        return false;
    }
    const SIZE_T existing = StringLength(destination);
    const SIZE_T added = StringLength(suffix);
    if (existing + added >= capacity) {
        return false;
    }
    for (SIZE_T index = 0; index <= added; ++index) {
        destination[existing + index] = suffix[index];
    }
    return true;
}

static bool JoinPath(WCHAR* destination, SIZE_T capacity, const WCHAR* root, const WCHAR* suffix) {
    if (!CopyString(destination, capacity, root)) {
        return false;
    }
    const SIZE_T length = StringLength(destination);
    if (length == 0) {
        return false;
    }
    if (destination[length - 1] != L'\\') {
        if (!AppendString(destination, capacity, L"\\")) {
            return false;
        }
    }
    while (*suffix == L'\\') {
        ++suffix;
    }
    return AppendString(destination, capacity, suffix);
}

static bool EqualOrdinal(const WCHAR* left, const WCHAR* right, bool ignoreCase = false) {
    if (left == nullptr || right == nullptr) {
        return false;
    }
    return CompareStringOrdinal(left, -1, right, -1, ignoreCase ? TRUE : FALSE) == CSTR_EQUAL;
}

static bool StartsWith(const WCHAR* value, const WCHAR* prefix, bool ignoreCase = false) {
    if (value == nullptr || prefix == nullptr) {
        return false;
    }
    const SIZE_T prefixLength = StringLength(prefix);
    if (StringLength(value) < prefixLength) {
        return false;
    }
    return CompareStringOrdinal(value, static_cast<int>(prefixLength), prefix,
        static_cast<int>(prefixLength), ignoreCase ? TRUE : FALSE) == CSTR_EQUAL;
}

static bool IsDotName(const WCHAR* name) {
    return EqualOrdinal(name, L".") || EqualOrdinal(name, L"..");
}

static bool IsLowerHexId(const WCHAR* value) {
    if (value == nullptr || StringLength(value) != 32) {
        return false;
    }
    bool anyNonzero = false;
    for (SIZE_T index = 0; index < 32; ++index) {
        const WCHAR current = value[index];
        if (!((current >= L'0' && current <= L'9') || (current >= L'a' && current <= L'f'))) {
            return false;
        }
        if (current != L'0') {
            anyNonzero = true;
        }
    }
    return anyNonzero;
}

static BYTE HexNibble(WCHAR value) {
    return value <= L'9' ? static_cast<BYTE>(value - L'0')
                         : static_cast<BYTE>(10 + value - L'a');
}

static void DecodeRequestId(const WCHAR* requestId, BYTE output[16]) {
    for (SIZE_T index = 0; index < 16; ++index) {
        output[index] = static_cast<BYTE>((HexNibble(requestId[index * 2]) << 4)
            | HexNibble(requestId[index * 2 + 1]));
    }
}

static bool AppendUnsigned(WCHAR* destination, SIZE_T capacity, ULONGLONG value) {
    WCHAR reversed[32];
    SIZE_T count = 0;
    do {
        reversed[count++] = static_cast<WCHAR>(L'0' + (value % 10));
        value /= 10;
    } while (value != 0 && count < 32);
    const SIZE_T start = StringLength(destination);
    if (start + count >= capacity) {
        return false;
    }
    for (SIZE_T index = 0; index < count; ++index) {
        destination[start + index] = reversed[count - index - 1];
    }
    destination[start + count] = L'\0';
    return true;
}

static bool AppendHex16(WCHAR* destination, SIZE_T capacity, ULONGLONG value) {
    static const WCHAR digits[] = L"0123456789ABCDEF";
    const SIZE_T start = StringLength(destination);
    if (start + 16 >= capacity) {
        return false;
    }
    for (SIZE_T index = 0; index < 16; ++index) {
        const SIZE_T shift = (15 - index) * 4;
        destination[start + index] = digits[(value >> shift) & 0x0f];
    }
    destination[start + 16] = L'\0';
    return true;
}

static ULONGLONG FileTimeToUnsigned(const FILETIME& value) {
    return (static_cast<ULONGLONG>(value.dwHighDateTime) << 32)
        | static_cast<ULONGLONG>(value.dwLowDateTime);
}

static bool QueryProcessCreationTime(HANDLE process, ULONGLONG* creationTime) {
    FILETIME creation = {};
    FILETIME exit = {};
    FILETIME kernel = {};
    FILETIME user = {};
    if (!GetProcessTimes(process, &creation, &exit, &kernel, &user)) {
        return false;
    }
    *creationTime = FileTimeToUnsigned(creation);
    return *creationTime != 0;
}

static bool IsFixedLocalPath(const WCHAR* path) {
    if (path == nullptr || StringLength(path) < 3 || path[1] != L':' || path[2] != L'\\') {
        return false;
    }
    WCHAR root[4] = { path[0], L':', L'\\', L'\0' };
    return GetDriveTypeW(root) == DRIVE_FIXED;
}

static const WCHAR* SkipExtendedPrefix(const WCHAR* path) {
    if (StartsWith(path, L"\\\\?\\UNC\\", true)) {
        return path + 6; // Leaves one leading backslash; UNC is rejected separately.
    }
    if (StartsWith(path, L"\\\\?\\", true)) {
        return path + 4;
    }
    return path;
}

static bool HandlePathMatches(HANDLE handle, const WCHAR* expectedPath) {
    WCHAR* actual = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    if (actual == nullptr) {
        return false;
    }
    const DWORD length = GetFinalPathNameByHandleW(handle, actual, kMaximumPathCharacters,
        FILE_NAME_NORMALIZED | VOLUME_NAME_DOS);
    const bool validLength = length != 0 && length < kMaximumPathCharacters;
    const WCHAR* normalized = validLength ? SkipExtendedPrefix(actual) : actual;
    const bool matches = validLength && IsFixedLocalPath(normalized)
        && EqualOrdinal(normalized, expectedPath, true);
    SecureZeroMemory(actual, sizeof(WCHAR) * kMaximumPathCharacters);
    Release(actual);
    return matches;
}

static bool IsProtectedSid(PSID sid, PSID trustedInstallerSid) {
    if (sid == nullptr || !IsValidSid(sid)) {
        return false;
    }
    if (IsWellKnownSid(sid, WinLocalSystemSid) || IsWellKnownSid(sid, WinBuiltinAdministratorsSid)) {
        return true;
    }
    return trustedInstallerSid != nullptr && EqualSid(sid, trustedInstallerSid) != FALSE;
}

struct CompoundAllowAce {
    ACE_HEADER Header;
    ACCESS_MASK Mask;
    USHORT CompoundAceType;
    USHORT Reserved;
    DWORD SidStart;
};

static PSID AllowedAceSid(ACE_HEADER* header, ACCESS_MASK** mask) {
    if (header == nullptr || mask == nullptr) {
        return nullptr;
    }
    if (header->AceType == ACCESS_ALLOWED_ACE_TYPE
            || header->AceType == ACCESS_ALLOWED_CALLBACK_ACE_TYPE) {
        ACCESS_ALLOWED_ACE* ace = reinterpret_cast<ACCESS_ALLOWED_ACE*>(header);
        *mask = &ace->Mask;
        return reinterpret_cast<PSID>(&ace->SidStart);
    }
    if (header->AceType == ACCESS_ALLOWED_COMPOUND_ACE_TYPE) {
        CompoundAllowAce* ace = reinterpret_cast<CompoundAllowAce*>(header);
        *mask = &ace->Mask;
        return reinterpret_cast<PSID>(&ace->SidStart);
    }
    if (header->AceType == ACCESS_ALLOWED_OBJECT_ACE_TYPE
            || header->AceType == ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE) {
        ACCESS_ALLOWED_OBJECT_ACE* ace = reinterpret_cast<ACCESS_ALLOWED_OBJECT_ACE*>(header);
        BYTE* sid = reinterpret_cast<BYTE*>(&ace->ObjectType);
        if ((ace->Flags & ACE_OBJECT_TYPE_PRESENT) != 0) {
            sid += sizeof(GUID);
        }
        if ((ace->Flags & ACE_INHERITED_OBJECT_TYPE_PRESENT) != 0) {
            sid += sizeof(GUID);
        }
        *mask = &ace->Mask;
        return reinterpret_cast<PSID>(sid);
    }
    return nullptr;
}

static bool IsKnownNonGrantAceType(BYTE type) {
    switch (type) {
    case ACCESS_DENIED_ACE_TYPE:
    case SYSTEM_AUDIT_ACE_TYPE:
    case SYSTEM_ALARM_ACE_TYPE:
    case ACCESS_DENIED_OBJECT_ACE_TYPE:
    case SYSTEM_AUDIT_OBJECT_ACE_TYPE:
    case SYSTEM_ALARM_OBJECT_ACE_TYPE:
    case ACCESS_DENIED_CALLBACK_ACE_TYPE:
    case ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE:
    case SYSTEM_AUDIT_CALLBACK_ACE_TYPE:
    case SYSTEM_ALARM_CALLBACK_ACE_TYPE:
    case SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE:
    case SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE:
    case SYSTEM_MANDATORY_LABEL_ACE_TYPE:
    case SYSTEM_RESOURCE_ATTRIBUTE_ACE_TYPE:
    case SYSTEM_SCOPED_POLICY_ID_ACE_TYPE:
    case SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE:
    case SYSTEM_ACCESS_FILTER_ACE_TYPE:
        return true;
    default:
        return false;
    }
}

static bool ResolveTrustedInstallerSid(BYTE* sidBuffer, DWORD sidBufferLength, PSID* sid) {
    DWORD sidLength = sidBufferLength;
    DWORD domainLength = 0;
    SID_NAME_USE use = SidTypeUnknown;
    LookupAccountNameW(nullptr, L"NT SERVICE\\TrustedInstaller", sidBuffer, &sidLength,
        nullptr, &domainLength, &use);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || sidLength > sidBufferLength
            || domainLength == 0) {
        return false;
    }
    WCHAR* domain = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * domainLength));
    if (domain == nullptr) {
        return false;
    }
    sidLength = sidBufferLength;
    const bool resolved = LookupAccountNameW(nullptr, L"NT SERVICE\\TrustedInstaller", sidBuffer,
        &sidLength, domain, &domainLength, &use) != FALSE;
    Release(domain);
    if (!resolved || !IsValidSid(sidBuffer)) {
        return false;
    }
    *sid = sidBuffer;
    return true;
}

static bool ValidateHandleSecurity(HANDLE handle, bool directory, PSID trustedInstallerSid) {
    PSID owner = nullptr;
    PACL dacl = nullptr;
    PSECURITY_DESCRIPTOR descriptor = nullptr;
    const DWORD securityResult = GetSecurityInfo(handle, SE_FILE_OBJECT,
        OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, &owner, nullptr, &dacl, nullptr,
        &descriptor);
    if (securityResult != ERROR_SUCCESS || descriptor == nullptr || owner == nullptr || dacl == nullptr
            || !IsProtectedSid(owner, trustedInstallerSid)) {
        if (descriptor != nullptr) {
            LocalFree(descriptor);
        }
        return false;
    }

    ACL_SIZE_INFORMATION information = {};
    if (!GetAclInformation(dacl, &information, sizeof(information), AclSizeInformation)) {
        LocalFree(descriptor);
        return false;
    }
    GENERIC_MAPPING mapping = { FILE_GENERIC_READ, FILE_GENERIC_WRITE, FILE_GENERIC_EXECUTE,
        FILE_ALL_ACCESS };
    const ACCESS_MASK writeMask = FILE_WRITE_DATA | FILE_APPEND_DATA | FILE_WRITE_EA
        | FILE_WRITE_ATTRIBUTES | DELETE | WRITE_DAC | WRITE_OWNER
        | (directory ? FILE_DELETE_CHILD : 0);
    bool valid = true;
    for (DWORD index = 0; index < information.AceCount; ++index) {
        void* rawAce = nullptr;
        if (!GetAce(dacl, index, &rawAce) || rawAce == nullptr) {
            valid = false;
            break;
        }
        ACE_HEADER* header = static_cast<ACE_HEADER*>(rawAce);
        if ((header->AceFlags & INHERIT_ONLY_ACE) != 0) {
            continue;
        }
        ACCESS_MASK* grantedMask = nullptr;
        PSID grantedSid = AllowedAceSid(header, &grantedMask);
        if (grantedSid == nullptr) {
            if (!IsKnownNonGrantAceType(header->AceType)) {
                valid = false;
                break;
            }
            continue;
        }
        if (!IsValidSid(grantedSid) || grantedMask == nullptr) {
            valid = false;
            break;
        }
        ACCESS_MASK mapped = *grantedMask;
        MapGenericMask(&mapped, &mapping);
        if (!IsProtectedSid(grantedSid, trustedInstallerSid) && (mapped & writeMask) != 0) {
            valid = false;
            break;
        }
    }
    LocalFree(descriptor);
    return valid;
}

static bool ValidatePathObject(const WCHAR* path, bool directory, bool lease,
        bool requireNonEmpty, PSID trustedInstallerSid, OwnedHandle* heldHandle) {
    DWORD access = FILE_READ_ATTRIBUTES | READ_CONTROL;
    DWORD sharing = FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE;
    DWORD flags = FILE_FLAG_OPEN_REPARSE_POINT | (directory ? FILE_FLAG_BACKUP_SEMANTICS : 0);
    if (lease) {
        access |= GENERIC_READ;
        sharing = FILE_SHARE_READ;
    }
    OwnedHandle handle = { CreateFileW(path, access, sharing, nullptr, OPEN_EXISTING, flags, nullptr) };
    if (handle.value == INVALID_HANDLE_VALUE) {
        handle.value = nullptr;
        return false;
    }
    FILE_ATTRIBUTE_TAG_INFO tag = {};
    FILE_STANDARD_INFO standard = {};
    const bool attributesValid = GetFileInformationByHandleEx(handle.value, FileAttributeTagInfo,
            &tag, sizeof(tag)) != FALSE
        && GetFileInformationByHandleEx(handle.value, FileStandardInfo, &standard,
            sizeof(standard)) != FALSE;
    const bool correctType = attributesValid
        && ((tag.FileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) == 0)
        && tag.ReparseTag == 0 && standard.DeletePending == FALSE
        && (standard.Directory != FALSE) == directory
        && (((tag.FileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) == directory)
        && GetFileType(handle.value) == FILE_TYPE_DISK;
    LARGE_INTEGER size = {};
    const bool sizeValid = directory || (GetFileSizeEx(handle.value, &size) != FALSE
        && (!requireNonEmpty || size.QuadPart > 0));
    const bool valid = correctType && sizeValid && HandlePathMatches(handle.value, path)
        && ValidateHandleSecurity(handle.value, directory, trustedInstallerSid);
    if (!valid) {
        Close(&handle);
        return false;
    }
    if (lease && heldHandle != nullptr) {
        *heldHandle = handle;
    } else {
        Close(&handle);
    }
    return true;
}

static bool ValidateProtectedHierarchy(const WCHAR* windowsRoot, const WCHAR* target,
        PSID trustedInstallerSid, bool targetIsDirectory, bool lease, OwnedHandle* heldHandle) {
    if (!IsFixedLocalPath(windowsRoot) || !IsFixedLocalPath(target)
            || !StartsWith(target, windowsRoot, true)) {
        return false;
    }
    const SIZE_T rootLength = StringLength(windowsRoot);
    if (StringLength(target) <= rootLength
            || (target[rootLength] != L'\\' && windowsRoot[rootLength - 1] != L'\\')) {
        return false;
    }
    WCHAR* partial = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    if (partial == nullptr || !CopyString(partial, kMaximumPathCharacters, windowsRoot)) {
        Release(partial);
        return false;
    }
    if (!ValidatePathObject(partial, true, false, false, trustedInstallerSid, nullptr)) {
        Release(partial);
        return false;
    }
    const WCHAR* cursor = target + rootLength;
    while (*cursor == L'\\') {
        ++cursor;
    }
    while (*cursor != L'\0') {
        const WCHAR* separator = cursor;
        while (*separator != L'\0' && *separator != L'\\') {
            ++separator;
        }
        WCHAR segment[260] = {};
        const SIZE_T segmentLength = static_cast<SIZE_T>(separator - cursor);
        if (segmentLength == 0 || segmentLength >= 260) {
            Release(partial);
            return false;
        }
        for (SIZE_T index = 0; index < segmentLength; ++index) {
            segment[index] = cursor[index];
        }
        if (!AppendString(partial, kMaximumPathCharacters, L"\\")
                || !AppendString(partial, kMaximumPathCharacters, segment)) {
            Release(partial);
            return false;
        }
        const bool last = *separator == L'\0';
        if (!ValidatePathObject(partial, last ? targetIsDirectory : true, last && lease,
                last && !targetIsDirectory, trustedInstallerSid, last ? heldHandle : nullptr)) {
            Release(partial);
            return false;
        }
        if (last) {
            break;
        }
        cursor = separator + 1;
    }
    Release(partial);
    return true;
}

static bool QueryPrimaryTokenMembership(HANDLE primaryToken, PSID sid, BOOL* isMember) {
    if (primaryToken == nullptr || primaryToken == INVALID_HANDLE_VALUE || sid == nullptr
            || !IsValidSid(sid) || isMember == nullptr) {
        return false;
    }
    *isMember = FALSE;
    OwnedHandle impersonationToken = { nullptr };
    if (!DuplicateToken(primaryToken, SecurityIdentification, &impersonationToken.value)) {
        return false;
    }
    const bool queried = CheckTokenMembership(impersonationToken.value, sid, isMember) != FALSE;
    Close(&impersonationToken);
    return queried;
}

static bool ValidateElevatedHighToken() {
    OwnedHandle token = { nullptr };
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY | TOKEN_DUPLICATE, &token.value)) {
        return false;
    }
    TOKEN_ELEVATION elevation = {};
    DWORD returned = 0;
    if (!GetTokenInformation(token.value, TokenElevation, &elevation, sizeof(elevation), &returned)
            || elevation.TokenIsElevated == 0) {
        Close(&token);
        return false;
    }
    BYTE buffer[SECURITY_MAX_SID_SIZE + sizeof(TOKEN_MANDATORY_LABEL)] = {};
    if (!GetTokenInformation(token.value, TokenIntegrityLevel, buffer, sizeof(buffer), &returned)) {
        Close(&token);
        return false;
    }
    TOKEN_MANDATORY_LABEL* label = reinterpret_cast<TOKEN_MANDATORY_LABEL*>(buffer);
    if (!IsValidSid(label->Label.Sid)) {
        Close(&token);
        return false;
    }
    const DWORD count = *GetSidSubAuthorityCount(label->Label.Sid);
    if (count == 0) {
        Close(&token);
        return false;
    }
    const DWORD integrity = *GetSidSubAuthority(label->Label.Sid, count - 1);
    BYTE adminSidBuffer[SECURITY_MAX_SID_SIZE] = {};
    DWORD adminSidLength = sizeof(adminSidBuffer);
    if (!CreateWellKnownSid(WinBuiltinAdministratorsSid, nullptr, adminSidBuffer, &adminSidLength)) {
        Close(&token);
        return false;
    }
    BOOL isAdministrator = FALSE;
    const bool valid = QueryPrimaryTokenMembership(token.value, adminSidBuffer, &isAdministrator)
        && isAdministrator != FALSE && integrity >= SECURITY_MANDATORY_HIGH_RID;
    Close(&token);
    return valid;
}

static bool InitializeFixedPaths(const WCHAR* requestId, FixedPaths* paths) {
    if (GetSystemWindowsDirectoryW(paths->windows, kMaximumPathCharacters) == 0
            || GetSystemDirectoryW(paths->system32, kMaximumPathCharacters) == 0
            || !IsFixedLocalPath(paths->windows) || !IsFixedLocalPath(paths->system32)
            || !StartsWith(paths->system32, paths->windows, true)) {
        return false;
    }
#if defined(_M_ARM64)
    if (!JoinPath(paths->self, kMaximumPathCharacters, paths->windows,
            L"AtlasModules\\Tools\\AtlasElevationBootstrap-arm64.exe")
#elif defined(_M_X64)
    if (!JoinPath(paths->self, kMaximumPathCharacters, paths->windows,
            L"AtlasModules\\Tools\\AtlasElevationBootstrap-amd64.exe")
#else
#error Atlas.ElevationBootstrap supports only x64 and ARM64.
#endif
        || !JoinPath(paths->powershell, kMaximumPathCharacters, paths->system32,
            L"WindowsPowerShell\\v1.0\\powershell.exe")
        || !JoinPath(paths->broker, kMaximumPathCharacters, paths->windows,
            L"AtlasModules\\Scripts\\Internal\\Invoke-AtlasTrustedInstallerBroker.ps1")) {
        return false;
    }
    if (SHGetFolderPathW(nullptr, CSIDL_COMMON_APPDATA | CSIDL_FLAG_DONT_VERIFY, nullptr,
            SHGFP_TYPE_CURRENT, paths->programData) != S_OK
            || !IsFixedLocalPath(paths->programData)
            || !JoinPath(paths->tempRoot, kMaximumPathCharacters, paths->programData,
                L"AtlasOS\\Broker\\ElevationBootstrap")
            || !JoinPath(paths->temp, kMaximumPathCharacters, paths->tempRoot, L"Transport-")
            || !AppendString(paths->temp, kMaximumPathCharacters, requestId)) {
        return false;
    }
    return true;
}

static bool ValidateAndLeaseFixedPaths(const FixedPaths& paths, PSID trustedInstallerSid,
        OwnedHandle* selfLease, OwnedHandle* powershellLease, OwnedHandle* brokerLease) {
    WCHAR* current = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    if (current == nullptr) {
        return false;
    }
    const DWORD length = GetModuleFileNameW(nullptr, current, kMaximumPathCharacters);
    const bool valid = length != 0 && length < kMaximumPathCharacters
        && EqualOrdinal(current, paths.self, true)
        && ValidateProtectedHierarchy(paths.windows, paths.self, trustedInstallerSid, false, true,
               selfLease)
        && ValidateProtectedHierarchy(paths.windows, paths.powershell, trustedInstallerSid, false,
               true, powershellLease)
        && ValidateProtectedHierarchy(paths.windows, paths.broker, trustedInstallerSid, false, true,
               brokerLease);
    SecureZeroMemory(current, sizeof(WCHAR) * kMaximumPathCharacters);
    Release(current);
    return valid;
}

static bool BuildProtectedSecurityAttributes(SECURITY_ATTRIBUTES* attributes,
        PSECURITY_DESCRIPTOR* descriptor) {
    *descriptor = nullptr;
    if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(
            L"O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)", SDDL_REVISION_1, descriptor,
            nullptr)) {
        return false;
    }
    attributes->nLength = sizeof(*attributes);
    attributes->lpSecurityDescriptor = *descriptor;
    attributes->bInheritHandle = FALSE;
    return true;
}

static bool ValidateNormalDirectoryWithoutAcl(const WCHAR* path) {
    OwnedHandle handle = { CreateFileW(path, FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr, OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT, nullptr) };
    if (handle.value == INVALID_HANDLE_VALUE) {
        handle.value = nullptr;
        return false;
    }
    FILE_ATTRIBUTE_TAG_INFO tag = {};
    FILE_STANDARD_INFO standard = {};
    const bool valid = GetFileInformationByHandleEx(handle.value, FileAttributeTagInfo, &tag,
            sizeof(tag)) != FALSE
        && GetFileInformationByHandleEx(handle.value, FileStandardInfo, &standard,
            sizeof(standard)) != FALSE
        && (tag.FileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0
        && (tag.FileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) == 0 && tag.ReparseTag == 0
        && standard.Directory != FALSE && standard.DeletePending == FALSE
        && GetFileType(handle.value) == FILE_TYPE_DISK
        && HandlePathMatches(handle.value, path);
    Close(&handle);
    return valid;
}

static bool EnsureProtectedDirectory(const WCHAR* path, bool requireNew, PSID trustedInstallerSid) {
    SECURITY_ATTRIBUTES attributes = {};
    PSECURITY_DESCRIPTOR descriptor = nullptr;
    if (!BuildProtectedSecurityAttributes(&attributes, &descriptor)) {
        return false;
    }
    const BOOL created = CreateDirectoryW(path, &attributes);
    const DWORD error = created ? ERROR_SUCCESS : GetLastError();
    LocalFree(descriptor);
    if (!created && (error != ERROR_ALREADY_EXISTS || requireNew)) {
        return false;
    }
    return ValidatePathObject(path, true, false, false, trustedInstallerSid, nullptr);
}

static bool TraverseOwnedTree(const WCHAR* path, DWORD depth, DWORD* entryCount,
        ULONGLONG* byteCount, bool removeObjects, PSID trustedInstallerSid) {
    if (depth > kMaximumCleanupDepth || *entryCount >= kMaximumCleanupEntries
            || !ValidatePathObject(path, true, false, false, trustedInstallerSid, nullptr)) {
        return false;
    }
    ++(*entryCount);
    WCHAR* pattern = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    WCHAR* child = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    if (pattern == nullptr || child == nullptr || !JoinPath(pattern, kMaximumPathCharacters, path, L"*")) {
        Release(pattern);
        Release(child);
        return false;
    }
    WIN32_FIND_DATAW data = {};
    HANDLE find = FindFirstFileW(pattern, &data);
    bool valid = true;
    if (find == INVALID_HANDLE_VALUE) {
        valid = GetLastError() == ERROR_FILE_NOT_FOUND;
    } else {
        do {
            if (IsDotName(data.cFileName)) {
                continue;
            }
            if (*entryCount >= kMaximumCleanupEntries
                    || !JoinPath(child, kMaximumPathCharacters, path, data.cFileName)
                    || (data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
                valid = false;
                break;
            }
            if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
                if (!TraverseOwnedTree(child, depth + 1, entryCount, byteCount, removeObjects,
                        trustedInstallerSid)) {
                    valid = false;
                    break;
                }
            } else {
                ++(*entryCount);
                const ULONGLONG fileBytes = (static_cast<ULONGLONG>(data.nFileSizeHigh) << 32)
                    | static_cast<ULONGLONG>(data.nFileSizeLow);
                if (fileBytes > kMaximumCleanupBytes
                        || *byteCount > kMaximumCleanupBytes - fileBytes) {
                    valid = false;
                    break;
                }
                *byteCount += fileBytes;
                // Stale compiler and lock files can be zero bytes. Temp cleanup validates
                // their type, final path, reparse state, and ACL without imposing the
                // non-empty invariant reserved for fixed executable/script artifacts.
                if (!ValidatePathObject(child, false, false, false, trustedInstallerSid, nullptr)
                        || (removeObjects && !DeleteFileW(child))) {
                    valid = false;
                    break;
                }
            }
        } while (FindNextFileW(find, &data));
        const DWORD enumerationError = GetLastError();
        FindClose(find);
        if (valid && enumerationError != ERROR_NO_MORE_FILES) {
            valid = false;
        }
    }
    SecureZeroMemory(pattern, sizeof(WCHAR) * kMaximumPathCharacters);
    SecureZeroMemory(child, sizeof(WCHAR) * kMaximumPathCharacters);
    Release(pattern);
    Release(child);
    return valid && (!removeObjects || RemoveDirectoryW(path) != FALSE);
}

static bool IsTransportDirectoryName(const WCHAR* name) {
    return name != nullptr && StartsWith(name, L"Transport-")
        && IsLowerHexId(name + StringLength(L"Transport-"));
}

static bool ReconcileStaleTempDirectories(const FixedPaths& paths, const WCHAR* requestId,
        PSID trustedInstallerSid) {
    WCHAR currentName[64] = L"Transport-";
    if (!AppendString(currentName, 64, requestId)) {
        return false;
    }
    WCHAR* pattern = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    WCHAR* candidate = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    WCHAR* staleNames = static_cast<WCHAR*>(Allocate(
        sizeof(WCHAR) * kMaximumStaleDirectories * 64));
    if (pattern == nullptr || candidate == nullptr || staleNames == nullptr
            || !JoinPath(pattern, kMaximumPathCharacters, paths.tempRoot, L"*")) {
        Release(pattern);
        Release(candidate);
        Release(staleNames);
        return false;
    }
    FILETIME nowFileTime = {};
    GetSystemTimeAsFileTime(&nowFileTime);
    const ULONGLONG now = FileTimeToUnsigned(nowFileTime);
    WIN32_FIND_DATAW data = {};
    HANDLE find = FindFirstFileW(pattern, &data);
    DWORD seen = 0;
    DWORD staleCount = 0;
    bool valid = true;
    if (find == INVALID_HANDLE_VALUE) {
        valid = GetLastError() == ERROR_FILE_NOT_FOUND;
    } else {
        do {
            if (IsDotName(data.cFileName)) {
                continue;
            }
            ++seen;
            if (seen > kMaximumStaleDirectories || !IsTransportDirectoryName(data.cFileName)
                    || (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0
                    || (data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
                valid = false;
                break;
            }
            if (EqualOrdinal(data.cFileName, currentName)) {
                valid = false; // Reuse of a request ID is never reconciled in-place.
                break;
            }
            const ULONGLONG modified = FileTimeToUnsigned(data.ftLastWriteTime);
            if (modified == 0 || now <= modified || now - modified < kStaleAge100ns) {
                continue;
            }
            if (staleCount >= kMaximumStaleDirectories
                    || !CopyString(staleNames + (staleCount * 64), 64, data.cFileName)) {
                valid = false;
                break;
            }
            ++staleCount;
        } while (FindNextFileW(find, &data));
        const DWORD enumerationError = GetLastError();
        FindClose(find);
        if (valid && enumerationError != ERROR_NO_MORE_FILES) {
            valid = false;
        }
    }
    DWORD entryCount = 0;
    ULONGLONG byteCount = 0;
    for (DWORD index = 0; valid && index < staleCount; ++index) {
        if (!JoinPath(candidate, kMaximumPathCharacters, paths.tempRoot,
                staleNames + (index * 64))
                || !TraverseOwnedTree(candidate, 0, &entryCount, &byteCount, false,
                    trustedInstallerSid)) {
            valid = false;
        }
    }
    entryCount = 0;
    byteCount = 0;
    for (DWORD index = 0; valid && index < staleCount; ++index) {
        if (!JoinPath(candidate, kMaximumPathCharacters, paths.tempRoot,
                staleNames + (index * 64))
                || !TraverseOwnedTree(candidate, 0, &entryCount, &byteCount, true,
                    trustedInstallerSid)) {
            valid = false;
        }
    }
    SecureZeroMemory(pattern, sizeof(WCHAR) * kMaximumPathCharacters);
    SecureZeroMemory(candidate, sizeof(WCHAR) * kMaximumPathCharacters);
    SecureZeroMemory(staleNames, sizeof(WCHAR) * kMaximumStaleDirectories * 64);
    Release(pattern);
    Release(candidate);
    Release(staleNames);
    return valid;
}

static bool PrepareProtectedTemp(const FixedPaths& paths, const WCHAR* requestId,
        PSID trustedInstallerSid) {
    if (!ValidateNormalDirectoryWithoutAcl(paths.programData)) {
        return false;
    }
    WCHAR* scratch = static_cast<WCHAR*>(Allocate(
        sizeof(WCHAR) * kMaximumPathCharacters * 2));
    if (scratch == nullptr) {
        return false;
    }
    WCHAR* atlasRoot = scratch;
    WCHAR* brokerRoot = scratch + kMaximumPathCharacters;
    const bool failed = !JoinPath(atlasRoot, kMaximumPathCharacters, paths.programData, L"AtlasOS")
            || !JoinPath(brokerRoot, kMaximumPathCharacters, atlasRoot, L"Broker")
            || !EnsureProtectedDirectory(atlasRoot, false, trustedInstallerSid)
            || !EnsureProtectedDirectory(brokerRoot, false, trustedInstallerSid)
            || !EnsureProtectedDirectory(paths.tempRoot, false, trustedInstallerSid)
            || !ReconcileStaleTempDirectories(paths, requestId, trustedInstallerSid)
            || !EnsureProtectedDirectory(paths.temp, true, trustedInstallerSid);
    SecureZeroMemory(scratch, sizeof(WCHAR) * kMaximumPathCharacters * 2);
    Release(scratch);
    return !failed;
}

static void CleanupProtectedTemp(const FixedPaths& paths, PSID trustedInstallerSid) {
    DWORD entryCount = 0;
    ULONGLONG byteCount = 0;
    if (!TraverseOwnedTree(paths.temp, 0, &entryCount, &byteCount, false,
            trustedInstallerSid)) {
        return;
    }
    entryCount = 0;
    byteCount = 0;
    TraverseOwnedTree(paths.temp, 0, &entryCount, &byteCount, true, trustedInstallerSid);
}

static Failpoint ReadFailpoint() {
    WCHAR value[64] = {};
    const DWORD length = GetEnvironmentVariableW(L"ATLAS_BOOTSTRAP_FAILPOINT", value, 64);
    if (length == 0 || length >= 64) {
        return Failpoint::None;
    }
    if (EqualOrdinal(value, L"AfterPipeCreate")) return Failpoint::AfterPipeCreate;
    if (EqualOrdinal(value, L"AfterClientBind")) return Failpoint::AfterClientBind;
    if (EqualOrdinal(value, L"AfterRequestRelay")) return Failpoint::AfterRequestRelay;
    if (EqualOrdinal(value, L"AfterBrokerCreate")) return Failpoint::AfterBrokerCreate;
    if (EqualOrdinal(value, L"AfterReadyRelay")) return Failpoint::AfterReadyRelay;
    if (EqualOrdinal(value, L"BeforeResultRelay")) return Failpoint::BeforeResultRelay;
    if (EqualOrdinal(value, L"ForceSynchronousIoNonJoin")) {
        return Failpoint::ForceSynchronousIoNonJoin;
    }
    return Failpoint::None;
}

static bool ForceSynchronousIoNonJoinEnabled() {
    WCHAR value[64] = {};
    const DWORD length = GetEnvironmentVariableW(L"ATLAS_BOOTSTRAP_FAILPOINT", value, 64);
    return length != 0 && length < 64 && EqualOrdinal(value, L"ForceSynchronousIoNonJoin");
}

static bool BuildPrivatePipeSecurityAttributes(bool inheritable,
        SECURITY_ATTRIBUTES* attributes, PSECURITY_DESCRIPTOR* descriptor) {
    const WCHAR* sddl = L"O:BAG:BAD:P(A;;GA;;;SY)(A;;GA;;;BA)";
    *descriptor = nullptr;
    if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl, SDDL_REVISION_1, descriptor,
            nullptr)) {
        return false;
    }
    attributes->nLength = sizeof(*attributes);
    attributes->lpSecurityDescriptor = *descriptor;
    attributes->bInheritHandle = inheritable ? TRUE : FALSE;
    return true;
}

static bool BuildExternalPipeName(const WCHAR* requestId, WCHAR* output, SIZE_T capacity) {
    return CopyString(output, capacity, L"\\\\.\\pipe\\AtlasOS.TrustedInstaller.")
        && AppendString(output, capacity, requestId);
}

static DWORD RemainingMilliseconds(ULONGLONG deadline) {
    const ULONGLONG now = GetTickCount64();
    if (now >= deadline) {
        return 0;
    }
    const ULONGLONG remaining = deadline - now;
    return remaining > MAXDWORD ? MAXDWORD : static_cast<DWORD>(remaining);
}

static bool ConnectExternalPipe(const WCHAR* requestId, ULONGLONG deadline, OwnedHandle* pipe) {
    WCHAR name[128] = {};
    if (!BuildExternalPipeName(requestId, name, 128)) {
        return false;
    }
    while (RemainingMilliseconds(deadline) != 0) {
        pipe->value = CreateFileW(name, GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_EXISTING,
            FILE_FLAG_OVERLAPPED | SECURITY_SQOS_PRESENT | SECURITY_IDENTIFICATION, nullptr);
        if (pipe->value != INVALID_HANDLE_VALUE) {
            DWORD mode = PIPE_READMODE_BYTE;
            if (SetNamedPipeHandleState(pipe->value, &mode, nullptr, nullptr)) {
                return true;
            }
            Close(pipe);
            return false;
        }
        pipe->value = nullptr;
        const DWORD error = GetLastError();
        if (error != ERROR_PIPE_BUSY && error != ERROR_FILE_NOT_FOUND) {
            return false;
        }
        const DWORD remaining = RemainingMilliseconds(deadline);
        if (remaining == 0) {
            break;
        }
        if (error == ERROR_PIPE_BUSY) {
            const DWORD wait = remaining > 250 ? 250 : remaining;
            WaitNamedPipeW(name, wait);
        } else {
            Sleep(remaining > 25 ? 25 : remaining);
        }
    }
    return false;
}

static bool QueryRequesterEvidence(HANDLE pipe, RequesterEvidence* evidence) {
    evidence->sid = nullptr;
    evidence->process.value = nullptr;
    ULONG serverProcessId = 0;
    ULONG pipeSessionId = 0;
    if (!GetNamedPipeServerProcessId(pipe, &serverProcessId) || serverProcessId == 0
            || !GetNamedPipeServerSessionId(pipe, &pipeSessionId)) {
        return false;
    }
    evidence->process.value = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | SYNCHRONIZE, FALSE,
        serverProcessId);
    if (evidence->process.value == nullptr
            || !QueryProcessCreationTime(evidence->process.value, &evidence->creationFileTime)
            || !ProcessIdToSessionId(serverProcessId, &evidence->sessionId)
            || evidence->sessionId != pipeSessionId
            || WaitForSingleObject(evidence->process.value, 0) != WAIT_TIMEOUT) {
        Close(&evidence->process);
        return false;
    }
    OwnedHandle token = { nullptr };
    if (!OpenProcessToken(evidence->process.value, TOKEN_QUERY, &token.value)) {
        Close(&evidence->process);
        return false;
    }
    DWORD tokenLength = 0;
    GetTokenInformation(token.value, TokenUser, nullptr, 0, &tokenLength);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || tokenLength == 0) {
        Close(&token);
        Close(&evidence->process);
        return false;
    }
    TOKEN_USER* user = static_cast<TOKEN_USER*>(Allocate(tokenLength));
    const bool queried = user != nullptr
        && GetTokenInformation(token.value, TokenUser, user, tokenLength, &tokenLength) != FALSE
        && IsValidSid(user->User.Sid) != FALSE
        && ConvertSidToStringSidW(user->User.Sid, &evidence->sid) != FALSE;
    Release(user);
    Close(&token);
    if (!queried || evidence->sid == nullptr) {
        Close(&evidence->process);
        return false;
    }
    ULONG serverProcessIdAgain = 0;
    ULONGLONG creationAgain = 0;
    if (!GetNamedPipeServerProcessId(pipe, &serverProcessIdAgain)
            || serverProcessIdAgain != serverProcessId
            || !QueryProcessCreationTime(evidence->process.value, &creationAgain)
            || creationAgain != evidence->creationFileTime) {
        LocalFree(evidence->sid);
        evidence->sid = nullptr;
        Close(&evidence->process);
        return false;
    }
    evidence->processId = serverProcessId;
    return true;
}

static void ReleaseRequesterEvidence(RequesterEvidence* evidence) {
    if (evidence->sid != nullptr) {
        LocalFree(evidence->sid);
        evidence->sid = nullptr;
    }
    Close(&evidence->process);
}

static bool StartExternalInputMonitor(HANDLE pipe, ExternalInputMonitor* monitor) {
    if (pipe == nullptr || pipe == INVALID_HANDLE_VALUE || monitor == nullptr) {
        return false;
    }
    monitor->event.value = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (monitor->event.value == nullptr) {
        return false;
    }
    monitor->overlapped = {};
    monitor->overlapped.hEvent = monitor->event.value;
    monitor->byte = 0;
    monitor->active = false;
    DWORD transferred = 0;
    const BOOL completed = ReadFile(pipe, &monitor->byte, 1, &transferred,
        &monitor->overlapped);
    if (completed) {
        Close(&monitor->event);
        SetLastError(transferred == 0 ? ERROR_BROKEN_PIPE : ERROR_MORE_DATA);
        return false;
    }
    const DWORD error = GetLastError();
    if (error != ERROR_IO_PENDING) {
        Close(&monitor->event);
        SetLastError(error);
        return false;
    }
    monitor->active = true;
    return true;
}

static HANDLE GetExternalInputMonitorEvent(const ExternalInputMonitor& monitor) {
    return monitor.active ? monitor.event.value : nullptr;
}

static bool ExternalInputMonitorTriggered(const ExternalInputMonitor& monitor) {
    return monitor.active
        && WaitForSingleObject(monitor.event.value, 0) == WAIT_OBJECT_0;
}

static bool IsExternalPipeClosureError(DWORD error) {
    return error == ERROR_BROKEN_PIPE || error == ERROR_NO_DATA
        || error == ERROR_PIPE_NOT_CONNECTED;
}

static ExternalInputCompletion QueryExternalInputMonitorCompletion(HANDLE pipe,
        const ExternalInputMonitor& monitor) {
    if (!monitor.active || WaitForSingleObject(monitor.event.value, 0) != WAIT_OBJECT_0) {
        return ExternalInputCompletion::Stopped;
    }
    DWORD transferred = 0;
    if (GetOverlappedResult(pipe, const_cast<OVERLAPPED*>(&monitor.overlapped), &transferred,
            FALSE)) {
        return transferred == 0 ? ExternalInputCompletion::Closed
            : ExternalInputCompletion::UnexpectedInput;
    }
    return IsExternalPipeClosureError(GetLastError()) ? ExternalInputCompletion::Closed
        : ExternalInputCompletion::Failed;
}

static DWORD SelectExternalFailureExit(HANDLE pipe, const ExternalInputMonitor& monitor,
        const RequesterEvidence& requester, DWORD fallback) {
    const ExternalInputCompletion completion = QueryExternalInputMonitorCompletion(pipe,
        monitor);
    if (completion == ExternalInputCompletion::UnexpectedInput) {
        return kExitInvalidFrame;
    }
    if (completion == ExternalInputCompletion::Closed
            || (requester.process.value != nullptr
                && WaitForSingleObject(requester.process.value, 0) == WAIT_OBJECT_0)) {
        return kExitRequesterLost;
    }
    if (completion == ExternalInputCompletion::Failed) {
        return kExitPipeFailure;
    }
    return fallback;
}

static ExternalInputCompletion StopExternalInputMonitor(HANDLE pipe,
        ExternalInputMonitor* monitor) {
    if (monitor == nullptr || !monitor->active) {
        if (monitor != nullptr) {
            Close(&monitor->event);
        }
        return ExternalInputCompletion::Stopped;
    }
    const bool wasPending = WaitForSingleObject(monitor->event.value, 0) == WAIT_TIMEOUT;
    bool cancellationRequested = false;
    if (wasPending) {
        if (CancelIoEx(pipe, &monitor->overlapped)) {
            cancellationRequested = true;
        } else if (GetLastError() != ERROR_NOT_FOUND) {
            // The exact read still owns monitor storage. Returning would permit the
            // stack OVERLAPPED and byte to leave scope before the kernel is done.
            FailFastContainment();
        }
    }
    if (WaitForSingleObject(monitor->event.value, 5000) != WAIT_OBJECT_0) {
        // The stack OVERLAPPED and byte must remain live until completion.
        FailFastContainment();
    }
    DWORD transferred = 0;
    const BOOL completed = GetOverlappedResult(pipe, &monitor->overlapped, &transferred, FALSE);
    const DWORD error = completed ? ERROR_SUCCESS : GetLastError();
    monitor->active = false;
    Close(&monitor->event);
    SecureZeroMemory(&monitor->overlapped, sizeof(monitor->overlapped));
    monitor->byte = 0;
    if (completed) {
        // Any inbound byte after the one Request is a second/trailing message.
        return transferred == 0 ? ExternalInputCompletion::Closed
            : ExternalInputCompletion::UnexpectedInput;
    }
    if (error == ERROR_OPERATION_ABORTED && cancellationRequested) {
        return ExternalInputCompletion::Stopped;
    }
    return IsExternalPipeClosureError(error) ? ExternalInputCompletion::Closed
        : ExternalInputCompletion::Failed;
}

static bool PerformOverlappedIo(HANDLE pipe, bool write, BYTE* buffer, DWORD length,
        HANDLE watchOne, HANDLE watchTwo, ULONGLONG deadline, DWORD* transferred) {
    *transferred = 0;
    OwnedHandle event = { CreateEventW(nullptr, TRUE, FALSE, nullptr) };
    if (event.value == nullptr) {
        return false;
    }
    OVERLAPPED overlapped = {};
    overlapped.hEvent = event.value;
    BOOL completed = write
        ? WriteFile(pipe, buffer, length, transferred, &overlapped)
        : ReadFile(pipe, buffer, length, transferred, &overlapped);
    if (completed) {
        Close(&event);
        return true;
    }
    const DWORD error = GetLastError();
    if (error != ERROR_IO_PENDING) {
        Close(&event);
        SetLastError(error);
        return false;
    }
    HANDLE waits[3] = { event.value, watchOne, watchTwo };
    DWORD waitCount = 1;
    if (watchOne != nullptr && watchOne != INVALID_HANDLE_VALUE) {
        ++waitCount;
    } else {
        waits[1] = watchTwo;
    }
    if (watchTwo != nullptr && watchTwo != INVALID_HANDLE_VALUE) {
        ++waitCount;
    }
    const DWORD remaining = RemainingMilliseconds(deadline);
    const DWORD wait = remaining == 0 ? WAIT_TIMEOUT
        : WaitForMultipleObjects(waitCount, waits, FALSE, remaining);
    if (wait != WAIT_OBJECT_0) {
        CancelIoEx(pipe, &overlapped);
        if (WaitForSingleObject(event.value, 5000) != WAIT_OBJECT_0) {
            // The stack OVERLAPPED and caller buffer must remain live until completion.
            // If cancellation cannot be joined, fail-fast so they are never reused.
            FailFastContainment();
        }
        DWORD ignored = 0;
        GetOverlappedResult(pipe, &overlapped, &ignored, FALSE);
        Close(&event);
        SetLastError(wait == WAIT_TIMEOUT ? ERROR_TIMEOUT : ERROR_OPERATION_ABORTED);
        return false;
    }
    completed = GetOverlappedResult(pipe, &overlapped, transferred, FALSE);
    const DWORD completionError = completed ? ERROR_SUCCESS : GetLastError();
    Close(&event);
    if (!completed) {
        SetLastError(completionError);
    }
    return completed != FALSE;
}

struct SynchronousIoContext {
    HANDLE pipe;
    BYTE* buffer;
    DWORD length;
    DWORD transferred;
    DWORD error;
    bool write;
    bool succeeded;
};

static DWORD WINAPI SynchronousIoWorker(void* parameter) {
    SynchronousIoContext* context = static_cast<SynchronousIoContext*>(parameter);
    context->succeeded = (context->write
        ? WriteFile(context->pipe, context->buffer, context->length, &context->transferred, nullptr)
        : ReadFile(context->pipe, context->buffer, context->length, &context->transferred, nullptr))
        != FALSE;
    context->error = context->succeeded ? ERROR_SUCCESS : GetLastError();
    return 0;
}

static bool PerformSynchronousIo(HANDLE pipe, bool write, BYTE* buffer, DWORD length,
        HANDLE watchOne, HANDLE watchTwo, ULONGLONG deadline, DWORD* transferred) {
    *transferred = 0;
    SynchronousIoContext* context = static_cast<SynchronousIoContext*>(
        Allocate(sizeof(SynchronousIoContext)));
    if (context == nullptr) {
        return false;
    }
    context->pipe = pipe;
    context->buffer = buffer;
    context->length = length;
    context->write = write;
    OwnedHandle thread = { CreateThread(nullptr, 0, SynchronousIoWorker, context, 0, nullptr) };
    if (thread.value == nullptr) {
        Release(context);
        return false;
    }
    HANDLE waits[3] = { thread.value, watchOne, watchTwo };
    DWORD waitCount = 1;
    if (watchOne != nullptr && watchOne != INVALID_HANDLE_VALUE) {
        ++waitCount;
    } else {
        waits[1] = watchTwo;
    }
    if (watchTwo != nullptr && watchTwo != INVALID_HANDLE_VALUE) {
        ++waitCount;
    }
    const DWORD remaining = RemainingMilliseconds(deadline);
    const DWORD wait = remaining == 0 ? WAIT_TIMEOUT
        : WaitForMultipleObjects(waitCount, waits, FALSE, remaining);
    if (wait != WAIT_OBJECT_0) {
        CancelSynchronousIo(thread.value);
        CancelIoEx(pipe, nullptr);
        const DWORD cancelled = ForceSynchronousIoNonJoinEnabled()
            ? WAIT_TIMEOUT : WaitForSingleObject(thread.value, 5000);
        Close(&thread);
        if (cancelled != WAIT_OBJECT_0) {
            // The worker still owns buffer/context pointers. Returning would let cleanup
            // release them and create a use-after-free. Explicitly terminate the outer
            // job before fail-fast because the broker may still hold its temporary
            // assignment duplicate.
            FailFastContainment();
        }
        Release(context);
        SetLastError(wait == WAIT_TIMEOUT ? ERROR_TIMEOUT : ERROR_OPERATION_ABORTED);
        return false;
    }
    const bool succeeded = context->succeeded;
    const DWORD error = context->error;
    *transferred = context->transferred;
    Close(&thread);
    Release(context);
    if (!succeeded) {
        SetLastError(error);
    }
    return succeeded;
}

static bool PerformIo(HANDLE pipe, bool overlapped, bool write, BYTE* buffer, DWORD length,
        HANDLE watchOne, HANDLE watchTwo, ULONGLONG deadline, DWORD* transferred) {
    return overlapped
        ? PerformOverlappedIo(pipe, write, buffer, length, watchOne, watchTwo, deadline,
            transferred)
        : PerformSynchronousIo(pipe, write, buffer, length, watchOne, watchTwo, deadline,
            transferred);
}

static bool ReadExact(HANDLE pipe, BYTE* buffer, DWORD length, HANDLE watchOne,
        HANDLE watchTwo, ULONGLONG deadline, bool overlapped) {
    DWORD offset = 0;
    while (offset < length) {
        DWORD transferred = 0;
        if (!PerformIo(pipe, overlapped, false, buffer + offset, length - offset, watchOne,
                watchTwo, deadline, &transferred)
                || transferred == 0) {
            return false;
        }
        offset += transferred;
    }
    return true;
}

static bool WriteExact(HANDLE pipe, const BYTE* buffer, DWORD length, HANDLE watchOne,
        HANDLE watchTwo, ULONGLONG deadline, bool overlapped) {
    DWORD offset = 0;
    while (offset < length) {
        DWORD transferred = 0;
        if (!PerformIo(pipe, overlapped, true, const_cast<BYTE*>(buffer) + offset,
                length - offset, watchOne, watchTwo, deadline, &transferred)
                || transferred == 0) {
            return false;
        }
        offset += transferred;
    }
    return true;
}

static USHORT ReadUInt16(const BYTE* value) {
    return static_cast<USHORT>(value[0] | (static_cast<USHORT>(value[1]) << 8));
}

static DWORD ReadUInt32(const BYTE* value) {
    return static_cast<DWORD>(value[0]) | (static_cast<DWORD>(value[1]) << 8)
        | (static_cast<DWORD>(value[2]) << 16) | (static_cast<DWORD>(value[3]) << 24);
}

static bool HashPayload(const BYTE* payload, DWORD payloadLength, BYTE output[32]) {
    BCRYPT_ALG_HANDLE algorithm = nullptr;
    BCRYPT_HASH_HANDLE hash = nullptr;
    DWORD objectLength = 0;
    DWORD returned = 0;
    BYTE* object = nullptr;
    bool valid = BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) >= 0
        && BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH,
            reinterpret_cast<PUCHAR>(&objectLength), sizeof(objectLength), &returned, 0) >= 0
        && objectLength != 0;
    if (valid) {
        object = static_cast<BYTE*>(Allocate(objectLength));
        valid = object != nullptr
            && BCryptCreateHash(algorithm, &hash, object, objectLength, nullptr, 0, 0) >= 0
            && BCryptHashData(hash, const_cast<PUCHAR>(payload), payloadLength, 0) >= 0
            && BCryptFinishHash(hash, output, 32, 0) >= 0;
    }
    if (hash != nullptr) {
        BCryptDestroyHash(hash);
    }
    if (algorithm != nullptr) {
        BCryptCloseAlgorithmProvider(algorithm, 0);
    }
    if (object != nullptr) {
        SecureZeroMemory(object, objectLength);
        Release(object);
    }
    return valid;
}

static bool ConstantTimeEqual(const BYTE* left, const BYTE* right, SIZE_T length) {
    BYTE difference = 0;
    for (SIZE_T index = 0; index < length; ++index) {
        difference |= static_cast<BYTE>(left[index] ^ right[index]);
    }
    return difference == 0;
}

static bool ReadAndValidateFrame(HANDLE pipe, USHORT expectedKind, DWORD maximumPayload,
        const BYTE requestId[16], HANDLE watchOne, HANDLE watchTwo, ULONGLONG deadline,
        bool overlapped, Frame* frame) {
    frame->payload = nullptr;
    frame->payloadLength = 0;
    frame->kind = 0;
    if (!ReadExact(pipe, frame->header, kFrameHeaderLength, watchOne, watchTwo, deadline,
            overlapped)) {
        return false;
    }
    if (!ConstantTimeEqual(frame->header, kFrameMagic, sizeof(kFrameMagic))
            || ReadUInt16(frame->header + 8) != kFrameVersion
            || ReadUInt16(frame->header + 10) != expectedKind
            || !ConstantTimeEqual(frame->header + 16, requestId, 16)) {
        SetLastError(ERROR_INVALID_DATA);
        return false;
    }
    const DWORD payloadLength = ReadUInt32(frame->header + 12);
    if (payloadLength == 0 || payloadLength > maximumPayload) {
        SetLastError(ERROR_INVALID_DATA);
        return false;
    }
    frame->payload = static_cast<BYTE*>(Allocate(payloadLength));
    if (frame->payload == nullptr) {
        SetLastError(ERROR_OUTOFMEMORY);
        return false;
    }
    if (!ReadExact(pipe, frame->payload, payloadLength, watchOne, watchTwo, deadline,
            overlapped)) {
        Release(frame->payload);
        frame->payload = nullptr;
        return false;
    }
    BYTE digest[32] = {};
    if (!HashPayload(frame->payload, payloadLength, digest)
            || !ConstantTimeEqual(digest, frame->header + 32, 32)) {
        SecureZeroMemory(digest, sizeof(digest));
        SecureZeroMemory(frame->payload, payloadLength);
        Release(frame->payload);
        frame->payload = nullptr;
        SetLastError(ERROR_INVALID_DATA);
        return false;
    }
    SecureZeroMemory(digest, sizeof(digest));
    frame->payloadLength = payloadLength;
    frame->kind = expectedKind;
    return true;
}

static bool WriteFrame(HANDLE pipe, const Frame& frame, HANDLE watchOne, HANDLE watchTwo,
        ULONGLONG deadline, bool overlapped) {
    return WriteExact(pipe, frame.header, kFrameHeaderLength, watchOne, watchTwo, deadline,
            overlapped)
        && (frame.payloadLength == 0 || WriteExact(pipe, frame.payload, frame.payloadLength,
            watchOne, watchTwo, deadline, overlapped));
}

static void ReleaseFrame(Frame* frame) {
    if (frame->payload != nullptr) {
        SecureZeroMemory(frame->payload, frame->payloadLength);
        Release(frame->payload);
        frame->payload = nullptr;
    }
    SecureZeroMemory(frame->header, sizeof(frame->header));
    frame->payloadLength = 0;
    frame->kind = 0;
}

static bool NoAvailableInput(HANDLE pipe) {
    DWORD available = 0;
    if (!PeekNamedPipe(pipe, nullptr, 0, nullptr, &available, nullptr)) {
        return false;
    }
    if (available != 0) {
        SetLastError(ERROR_MORE_DATA);
        return false;
    }
    SetLastError(ERROR_SUCCESS);
    return true;
}

static bool RequirePipeEof(HANDLE pipe, HANDLE watchOne, HANDLE watchTwo, ULONGLONG deadline,
        bool overlapped) {
    BYTE trailing = 0;
    DWORD transferred = 0;
    if (PerformIo(pipe, overlapped, false, &trailing, 1, watchOne, watchTwo, deadline,
            &transferred)) {
        return transferred == 0;
    }
    const DWORD error = GetLastError();
    return error == ERROR_BROKEN_PIPE || error == ERROR_PIPE_NOT_CONNECTED;
}

static bool CreateInternalPipes(InternalPipes* pipes) {
    SECURITY_ATTRIBUTES attributes = {};
    PSECURITY_DESCRIPTOR descriptor = nullptr;
    if (!BuildPrivatePipeSecurityAttributes(true, &attributes, &descriptor)) {
        return false;
    }
    const BOOL requestCreated = CreatePipe(&pipes->requestChildRead.value,
        &pipes->requestParentWrite.value, &attributes, kFrameHeaderLength + kRequestMaximum);
    const BOOL resultCreated = requestCreated && CreatePipe(&pipes->resultParentRead.value,
        &pipes->resultChildWrite.value, &attributes, kFrameHeaderLength + kResultMaximum);
    LocalFree(descriptor);
    if (!requestCreated || !resultCreated
            || !SetHandleInformation(pipes->requestParentWrite.value, HANDLE_FLAG_INHERIT, 0)
            || !SetHandleInformation(pipes->resultParentRead.value, HANDLE_FLAG_INHERIT, 0)) {
        Close(&pipes->requestChildRead);
        Close(&pipes->requestParentWrite);
        Close(&pipes->resultParentRead);
        Close(&pipes->resultChildWrite);
        return false;
    }
    return true;
}

static bool AppendEnvironmentEntry(WCHAR* environment, SIZE_T capacity, SIZE_T* used,
        const WCHAR* name, const WCHAR* value) {
    const SIZE_T nameLength = StringLength(name);
    const SIZE_T valueLength = StringLength(value);
    if (nameLength == 0 || valueLength == 0 || *used + nameLength + valueLength + 2 >= capacity) {
        return false;
    }
    for (SIZE_T index = 0; index < nameLength; ++index) {
        environment[(*used)++] = name[index];
    }
    environment[(*used)++] = L'=';
    for (SIZE_T index = 0; index < valueLength; ++index) {
        environment[(*used)++] = value[index];
    }
    environment[(*used)++] = L'\0';
    return true;
}

struct EnvironmentPathScratch {
    WCHAR programFiles[kMaximumPathCharacters];
    WCHAR programFilesX86[kMaximumPathCharacters];
    WCHAR modulePath[kMaximumPathCharacters];
    WCHAR powershellDirectory[kMaximumPathCharacters];
    WCHAR searchPath[kMaximumPathCharacters];
};

static bool BuildEnvironment(const FixedPaths& paths, WCHAR** environmentOutput) {
    EnvironmentPathScratch* scratch = static_cast<EnvironmentPathScratch*>(
        Allocate(sizeof(EnvironmentPathScratch)));
    if (scratch == nullptr) {
        return false;
    }
    WCHAR systemDrive[3] = { paths.windows[0], L':', L'\0' };
    if (SHGetFolderPathW(nullptr, CSIDL_PROGRAM_FILES | CSIDL_FLAG_DONT_VERIFY, nullptr,
            SHGFP_TYPE_CURRENT, scratch->programFiles) != S_OK
            || SHGetFolderPathW(nullptr, CSIDL_PROGRAM_FILESX86 | CSIDL_FLAG_DONT_VERIFY, nullptr,
                SHGFP_TYPE_CURRENT, scratch->programFilesX86) != S_OK
            || !IsFixedLocalPath(scratch->programFiles)
            || !IsFixedLocalPath(scratch->programFilesX86)
            || !JoinPath(scratch->powershellDirectory, kMaximumPathCharacters, paths.system32,
                L"WindowsPowerShell\\v1.0")
            || !JoinPath(scratch->modulePath, kMaximumPathCharacters,
                scratch->powershellDirectory, L"Modules")) {
        Release(scratch);
        return false;
    }
    // Construct Path solely from validated Win32 paths; inherited search paths never cross the boundary.
    if (!CopyString(scratch->searchPath, kMaximumPathCharacters, paths.system32)
            || !AppendString(scratch->searchPath, kMaximumPathCharacters, L";")
            || !AppendString(scratch->searchPath, kMaximumPathCharacters, paths.windows)
            || !AppendString(scratch->searchPath, kMaximumPathCharacters, L";")
            || !AppendString(scratch->searchPath, kMaximumPathCharacters,
                scratch->powershellDirectory)) {
        Release(scratch);
        return false;
    }

    WCHAR* environment = static_cast<WCHAR*>(Allocate(
        sizeof(WCHAR) * kMaximumEnvironmentCharacters));
    if (environment == nullptr) {
        Release(scratch);
        return false;
    }
    SIZE_T used = 0;
#if defined(_M_ARM64)
    const WCHAR* processorArchitecture = L"ARM64";
#else
    const WCHAR* processorArchitecture = L"AMD64";
#endif
    const bool built =
        AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"ALLUSERSPROFILE", paths.programData)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"Path", scratch->searchPath)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"PATHEXT", L".COM;.EXE;.BAT;.CMD")
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"PROCESSOR_ARCHITECTURE", processorArchitecture)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"ProgramData", paths.programData)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"ProgramFiles", scratch->programFiles)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"ProgramFiles(x86)", scratch->programFilesX86)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"PSModulePath", scratch->modulePath)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"SystemDrive", systemDrive)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"SystemRoot", paths.windows)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"TEMP", paths.temp)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"TMP", paths.temp)
        && AppendEnvironmentEntry(environment, kMaximumEnvironmentCharacters, &used,
            L"WINDIR", paths.windows);
    if (!built || used + 1 >= kMaximumEnvironmentCharacters) {
        SecureZeroMemory(environment, sizeof(WCHAR) * kMaximumEnvironmentCharacters);
        Release(environment);
        SecureZeroMemory(scratch, sizeof(EnvironmentPathScratch));
        Release(scratch);
        return false;
    }
    environment[used++] = L'\0';
    *environmentOutput = environment;
    SecureZeroMemory(scratch, sizeof(EnvironmentPathScratch));
    Release(scratch);
    return true;
}

static bool AppendQuoted(WCHAR* command, SIZE_T capacity, const WCHAR* value) {
    // Every quoted value here is a kernel-derived fixed path or SID. Reject quotes defensively.
    for (const WCHAR* cursor = value; *cursor != L'\0'; ++cursor) {
        if (*cursor == L'"' || *cursor == L'\r' || *cursor == L'\n') {
            return false;
        }
    }
    return AppendString(command, capacity, L"\"")
        && AppendString(command, capacity, value)
        && AppendString(command, capacity, L"\"");
}

static bool AppendSwitch(WCHAR* command, SIZE_T capacity, const WCHAR* name) {
    return AppendString(command, capacity, L" ") && AppendString(command, capacity, name)
        && AppendString(command, capacity, L" ");
}

static bool BuildBrokerCommandLine(const FixedPaths& paths, const WCHAR* expectedRequestId,
        HANDLE requestHandle, HANDLE resultHandle, HANDLE livenessHandle, HANDLE outerJobHandle,
        const RequesterEvidence& requester, ULONGLONG bootstrapCreation, WCHAR** commandOutput) {
    WCHAR* command = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumCommandCharacters));
    if (command == nullptr || !AppendQuoted(command, kMaximumCommandCharacters, paths.powershell)
            || !AppendString(command, kMaximumCommandCharacters,
                L" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ")
            || !AppendQuoted(command, kMaximumCommandCharacters, paths.broker)
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-ExpectedRequestId")
            || !AppendString(command, kMaximumCommandCharacters, expectedRequestId)
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-RequestHandle")
            || !AppendUnsigned(command, kMaximumCommandCharacters,
                reinterpret_cast<ULONG_PTR>(requestHandle))
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-ResultHandle")
            || !AppendUnsigned(command, kMaximumCommandCharacters,
                reinterpret_cast<ULONG_PTR>(resultHandle))
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-LivenessHandle")
            || !AppendUnsigned(command, kMaximumCommandCharacters,
                reinterpret_cast<ULONG_PTR>(livenessHandle))
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-OuterJobHandle")
            || !AppendUnsigned(command, kMaximumCommandCharacters,
                reinterpret_cast<ULONG_PTR>(outerJobHandle))
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-BootstrapProcessId")
            || !AppendUnsigned(command, kMaximumCommandCharacters, GetCurrentProcessId())
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-BootstrapCreationFileTime")
            || !AppendHex16(command, kMaximumCommandCharacters, bootstrapCreation)
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-RequesterProcessId")
            || !AppendUnsigned(command, kMaximumCommandCharacters, requester.processId)
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-RequesterCreationFileTime")
            || !AppendHex16(command, kMaximumCommandCharacters, requester.creationFileTime)
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-RequesterSid")
            || !AppendString(command, kMaximumCommandCharacters, requester.sid)
            || !AppendSwitch(command, kMaximumCommandCharacters, L"-RequesterSessionId")
            || !AppendUnsigned(command, kMaximumCommandCharacters, requester.sessionId)) {
        if (command != nullptr) {
            SecureZeroMemory(command, sizeof(WCHAR) * kMaximumCommandCharacters);
            Release(command);
        }
        return false;
    }
    *commandOutput = command;
    return true;
}

static bool CreateContainment(Containment* containment) {
    containment->job.value = CreateJobObjectW(nullptr, nullptr);
    containment->ownerGuard.value = CreateJobObjectW(nullptr, nullptr);
    containment->completionPort.value = CreateIoCompletionPort(INVALID_HANDLE_VALUE, nullptr, 0, 1);
    if (containment->job.value == nullptr || containment->ownerGuard.value == nullptr
            || containment->completionPort.value == nullptr) {
        Close(&containment->completionPort);
        Close(&containment->ownerGuard);
        Close(&containment->job);
        return false;
    }
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {};
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        | JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION;
    if (!SetInformationJobObject(containment->job.value, JobObjectExtendedLimitInformation,
            &limits, sizeof(limits))
            || !SetInformationJobObject(containment->ownerGuard.value,
                JobObjectExtendedLimitInformation, &limits, sizeof(limits))) {
        Close(&containment->completionPort);
        Close(&containment->ownerGuard);
        Close(&containment->job);
        return false;
    }
    JOBOBJECT_ASSOCIATE_COMPLETION_PORT association = {};
    association.CompletionKey = containment;
    association.CompletionPort = containment->completionPort.value;
    if (!SetInformationJobObject(containment->job.value,
            JobObjectAssociateCompletionPortInformation, &association, sizeof(association))) {
        Close(&containment->completionPort);
        Close(&containment->ownerGuard);
        Close(&containment->job);
        return false;
    }
    return true;
}

static bool QueryJobIsDrained(HANDLE job) {
    JOBOBJECT_BASIC_ACCOUNTING_INFORMATION accounting = {};
    return QueryInformationJobObject(job, JobObjectBasicAccountingInformation, &accounting,
            sizeof(accounting), nullptr) != FALSE
        && accounting.ActiveProcesses == 0;
}

static bool DrainJob(const Containment& containment, DWORD timeoutMilliseconds,
        HANDLE cancellation = nullptr) {
    const ULONGLONG deadline = GetTickCount64() + timeoutMilliseconds;
    do {
        if (cancellation != nullptr && cancellation != INVALID_HANDLE_VALUE
                && WaitForSingleObject(cancellation, 0) == WAIT_OBJECT_0) {
            SetLastError(ERROR_OPERATION_ABORTED);
            return false;
        }
        if (QueryJobIsDrained(containment.job.value)) {
            return true;
        }
        DWORD message = 0;
        ULONG_PTR key = 0;
        LPOVERLAPPED value = nullptr;
        const DWORD remaining = RemainingMilliseconds(deadline);
        if (remaining == 0) {
            break;
        }
        const DWORD poll = remaining > 250 ? 250 : remaining;
        if (GetQueuedCompletionStatus(containment.completionPort.value, &message, &key, &value,
                poll)) {
            if (key != reinterpret_cast<ULONG_PTR>(&containment)) {
                return false;
            }
            if (message == JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO && QueryJobIsDrained(
                    containment.job.value)) {
                return true;
            }
        } else if (GetLastError() != WAIT_TIMEOUT) {
            return false;
        }
    } while (RemainingMilliseconds(deadline) != 0);
    if (cancellation != nullptr && cancellation != INVALID_HANDLE_VALUE
            && WaitForSingleObject(cancellation, 0) == WAIT_OBJECT_0) {
        SetLastError(ERROR_OPERATION_ABORTED);
        return false;
    }
    return QueryJobIsDrained(containment.job.value);
}

static bool TerminateReleaseAndDrainJob(const Containment& containment,
        OwnedHandle* brokerProcess) {
    const bool alreadyDrained = QueryJobIsDrained(containment.job.value);
    const bool terminated = alreadyDrained
        || TerminateJobObject(containment.job.value, kExitBrokerFailure) != FALSE;
    // Capture the terminal exit value, then release the bootstrap's process reference
    // before the containment lifecycle advances to its authoritative drain check.
    Close(brokerProcess);
    if (!terminated) {
        return false;
    }
    return QueryJobIsDrained(containment.job.value)
        || DrainJob(containment, kDrainTimeoutMs);
}

static bool WaitForBrokerExitAndRelease(OwnedHandle* brokerProcess, ULONGLONG deadline,
        DWORD* exitCode, HANDLE cancellation = nullptr) {
    if (brokerProcess == nullptr || brokerProcess->value == nullptr
            || brokerProcess->value == INVALID_HANDLE_VALUE || exitCode == nullptr) {
        return false;
    }
    const DWORD remaining = RemainingMilliseconds(deadline);
    HANDLE waits[2] = { brokerProcess->value, cancellation };
    const DWORD waitCount = cancellation == nullptr || cancellation == INVALID_HANDLE_VALUE
        ? 1u : 2u;
    const DWORD wait = WaitForMultipleObjects(waitCount, waits, FALSE, remaining);
    if (wait != WAIT_OBJECT_0) {
        SetLastError(wait == WAIT_TIMEOUT ? ERROR_TIMEOUT : ERROR_OPERATION_ABORTED);
        return false;
    }
    const bool queried = GetExitCodeProcess(brokerProcess->value, exitCode) != FALSE;
    const DWORD error = queried ? ERROR_SUCCESS : GetLastError();
    Close(brokerProcess);
    if (!queried) {
        SetLastError(error);
    }
    return queried;
}

static bool ValidateChildImageAndJob(HANDLE process, const WCHAR* expectedImage, HANDLE job) {
    WCHAR* image = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    if (image == nullptr) {
        return false;
    }
    DWORD length = kMaximumPathCharacters;
    BOOL inJob = FALSE;
    const bool valid = QueryFullProcessImageNameW(process, 0, image, &length) != FALSE
        && length != 0 && length < kMaximumPathCharacters
        && EqualOrdinal(image, expectedImage, true)
        && IsProcessInJob(process, job, &inJob) != FALSE && inJob != FALSE;
    SecureZeroMemory(image, sizeof(WCHAR) * kMaximumPathCharacters);
    Release(image);
    return valid;
}

static bool StartBroker(const FixedPaths& paths, const WCHAR* expectedRequestId,
        const RequesterEvidence& requester, ULONGLONG bootstrapCreation,
        InternalPipes* pipes, const Containment& containment, WCHAR* environment,
        OwnedHandle* brokerProcess, OwnedHandle* bootstrapLivenessWrite) {
    OwnedHandle childLivenessRead = { nullptr };
    OwnedHandle parentLivenessWrite = { nullptr };
    OwnedHandle childJob = { nullptr };
    SECURITY_ATTRIBUTES pipeSecurity = {};
    pipeSecurity.nLength = sizeof(pipeSecurity);
    pipeSecurity.bInheritHandle = TRUE;
    if (!CreatePipe(&childLivenessRead.value, &parentLivenessWrite.value, &pipeSecurity, 0)
            || !SetHandleInformation(parentLivenessWrite.value, HANDLE_FLAG_INHERIT, 0)
            || !DuplicateHandle(GetCurrentProcess(), containment.job.value, GetCurrentProcess(),
                &childJob.value, JOB_OBJECT_ASSIGN_PROCESS | JOB_OBJECT_QUERY | SYNCHRONIZE,
                TRUE, 0)) {
        Close(&childLivenessRead);
        Close(&parentLivenessWrite);
        Close(&childJob);
        return false;
    }
    DWORD childLivenessFlags = 0;
    DWORD parentLivenessFlags = 0;
    if (!GetHandleInformation(childLivenessRead.value, &childLivenessFlags)
            || !GetHandleInformation(parentLivenessWrite.value, &parentLivenessFlags)
            || (childLivenessFlags & HANDLE_FLAG_INHERIT) == 0
            || (parentLivenessFlags & HANDLE_FLAG_INHERIT) != 0) {
        Close(&childLivenessRead);
        Close(&parentLivenessWrite);
        Close(&childJob);
        return false;
    }
    if (!SetHandleInformation(pipes->requestChildRead.value, HANDLE_FLAG_INHERIT,
            HANDLE_FLAG_INHERIT)
            || !SetHandleInformation(pipes->resultChildWrite.value, HANDLE_FLAG_INHERIT,
                HANDLE_FLAG_INHERIT)) {
        Close(&childLivenessRead);
        Close(&parentLivenessWrite);
        Close(&childJob);
        return false;
    }

    WCHAR* command = nullptr;
    if (!BuildBrokerCommandLine(paths, expectedRequestId, pipes->requestChildRead.value,
            pipes->resultChildWrite.value, childLivenessRead.value, childJob.value, requester,
            bootstrapCreation, &command)) {
        Close(&childLivenessRead);
        Close(&parentLivenessWrite);
        Close(&childJob);
        return false;
    }

    SIZE_T attributeBytes = 0;
    InitializeProcThreadAttributeList(nullptr, 2, 0, &attributeBytes);
    LPPROC_THREAD_ATTRIBUTE_LIST attributes = static_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(
        Allocate(attributeBytes));
    HANDLE inheritedHandles[4] = { pipes->requestChildRead.value, pipes->resultChildWrite.value,
        childLivenessRead.value, childJob.value };
    // The non-inherited owner guard is nested below the outer job. If the bootstrap
    // dies while the broker is still suspended and holding its temporary outer-job
    // duplicate, closing the guard still terminates the broker and releases that duplicate.
    HANDLE jobList[2] = { containment.job.value, containment.ownerGuard.value };
    const bool listInitialized = attributes != nullptr
        && InitializeProcThreadAttributeList(attributes, 2, 0, &attributeBytes) != FALSE;
    bool initialized = listInitialized
        && UpdateProcThreadAttribute(attributes, 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
            inheritedHandles, sizeof(inheritedHandles), nullptr, nullptr) != FALSE
        && UpdateProcThreadAttribute(attributes, 0, PROC_THREAD_ATTRIBUTE_JOB_LIST, jobList,
            sizeof(jobList), nullptr, nullptr) != FALSE;
    PROCESS_INFORMATION information = {};
    STARTUPINFOEXW startup = {};
    startup.StartupInfo.cb = sizeof(startup);
    startup.lpAttributeList = attributes;
    BOOL created = FALSE;
    if (initialized) {
        created = CreateProcessW(paths.powershell, command, nullptr, nullptr, TRUE,
            CREATE_SUSPENDED | CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW
                | EXTENDED_STARTUPINFO_PRESENT,
            environment, paths.system32, &startup.StartupInfo, &information);
    }
    if (attributes != nullptr) {
        if (listInitialized) {
            DeleteProcThreadAttributeList(attributes);
        }
        Release(attributes);
    }
    SecureZeroMemory(command, sizeof(WCHAR) * kMaximumCommandCharacters);
    Release(command);
    Close(&childLivenessRead);
    Close(&childJob);
    Close(&pipes->requestChildRead);
    Close(&pipes->resultChildWrite);
    if (!created) {
        Close(&parentLivenessWrite);
        return false;
    }
    OwnedHandle process = { information.hProcess };
    OwnedHandle thread = { information.hThread };
    if (!ValidateChildImageAndJob(process.value, paths.powershell, containment.job.value)
            || !ValidateChildImageAndJob(process.value, paths.powershell,
                containment.ownerGuard.value)
            || ResumeThread(thread.value) != 1) {
        TerminateJobObject(containment.job.value, kExitBrokerFailure);
        Close(&thread);
        Close(&process);
        Close(&parentLivenessWrite);
        return false;
    }
    Close(&thread);
    *brokerProcess = process;
    *bootstrapLivenessWrite = parentLivenessWrite;
    parentLivenessWrite.value = nullptr;
    return true;
}

static bool RequesterStillMatches(HANDLE externalPipe, const RequesterEvidence& requester) {
    ULONG serverProcessId = 0;
    ULONGLONG creation = 0;
    if (!GetNamedPipeServerProcessId(externalPipe, &serverProcessId)) {
        return false;
    }
    if (serverProcessId != requester.processId) {
        SetLastError(ERROR_INVALID_DATA);
        return false;
    }
    if (!QueryProcessCreationTime(requester.process.value, &creation)) {
        return false;
    }
    if (creation != requester.creationFileTime) {
        SetLastError(ERROR_INVALID_DATA);
        return false;
    }
    const DWORD wait = WaitForSingleObject(requester.process.value, 0);
    if (wait == WAIT_TIMEOUT) {
        SetLastError(ERROR_SUCCESS);
        return true;
    }
    if (wait == WAIT_OBJECT_0) {
        SetLastError(ERROR_PROCESS_ABORTED);
    }
    return false;
}

[[maybe_unused]] static DWORD Run() {
    DWORD exitCode = kExitInvalidInvocation;
    int argumentCount = 0;
    LPWSTR* arguments = CommandLineToArgvW(GetCommandLineW(), &argumentCount);
    FixedPaths* paths = nullptr;
    BYTE requestIdBytes[16] = {};
    BYTE trustedInstallerSidBuffer[SECURITY_MAX_SID_SIZE] = {};
    PSID trustedInstallerSid = nullptr;
    OwnedHandle selfLease = { nullptr };
    OwnedHandle powershellLease = { nullptr };
    OwnedHandle brokerLease = { nullptr };
    OwnedHandle externalPipe = { nullptr };
    ExternalInputMonitor externalMonitor = {};
    RequesterEvidence requester = {};
    InternalPipes pipes = {};
    Containment containment = {};
    OwnedHandle brokerProcess = { nullptr };
    OwnedHandle bootstrapLivenessWrite = { nullptr };
    WCHAR* environment = nullptr;
    Frame request = {};
    Frame ready = {};
    Frame result = {};
    bool tempPrepared = false;
    bool containmentCreated = false;
    bool protocolComplete = false;
    ULONGLONG bootstrapCreation = 0;
    ULONGLONG requestDeadline = 0;
    ULONGLONG readyDeadline = 0;
    ULONGLONG operationDeadline = 0;
    Failpoint failpoint = Failpoint::None;
    ExternalInputCompletion terminalInput = ExternalInputCompletion::Stopped;
    DWORD brokerExit = STILL_ACTIVE;

    if (arguments == nullptr || argumentCount != 2 || !IsLowerHexId(arguments[1])) {
        goto Cleanup;
    }
    DecodeRequestId(arguments[1], requestIdBytes);
    if (!ValidateElevatedHighToken()) {
        exitCode = kExitInvalidElevation;
        goto Cleanup;
    }
    paths = static_cast<FixedPaths*>(Allocate(sizeof(FixedPaths)));
    if (paths == nullptr || !InitializeFixedPaths(arguments[1], paths)
            || !ResolveTrustedInstallerSid(trustedInstallerSidBuffer,
                sizeof(trustedInstallerSidBuffer), &trustedInstallerSid)
            || !ValidateAndLeaseFixedPaths(*paths, trustedInstallerSid, &selfLease,
                &powershellLease, &brokerLease)) {
        exitCode = kExitUntrustedPath;
        goto Cleanup;
    }
    if (!QueryProcessCreationTime(GetCurrentProcess(), &bootstrapCreation)) {
        exitCode = kExitInvalidElevation;
        goto Cleanup;
    }

    if (!ConnectExternalPipe(arguments[1], GetTickCount64() + kConnectTimeoutMs,
            &externalPipe)) {
        exitCode = kExitPipeFailure;
        goto Cleanup;
    }
    failpoint = ReadFailpoint();
    if (failpoint == Failpoint::AfterPipeCreate) {
        exitCode = kExitFailpoint;
        goto Cleanup;
    }
    if (!QueryRequesterEvidence(externalPipe.value, &requester)
            || !RequesterStillMatches(externalPipe.value, requester)) {
        exitCode = kExitInvalidPeer;
        goto Cleanup;
    }
    if (failpoint == Failpoint::AfterClientBind) {
        exitCode = kExitFailpoint;
        goto Cleanup;
    }

    requestDeadline = GetTickCount64() + kHandshakeTimeoutMs;
    if (!ReadAndValidateFrame(externalPipe.value, kFrameRequest, kRequestMaximum,
            requestIdBytes, requester.process.value, nullptr, requestDeadline, true, &request)) {
        const DWORD requestError = GetLastError();
        exitCode = IsExternalPipeClosureError(requestError)
                || WaitForSingleObject(requester.process.value, 0) == WAIT_OBJECT_0
            ? kExitRequesterLost : kExitInvalidFrame;
        goto Cleanup;
    }
    if (!NoAvailableInput(externalPipe.value)) {
        const DWORD trailingError = GetLastError();
        exitCode = IsExternalPipeClosureError(trailingError)
                || WaitForSingleObject(requester.process.value, 0) == WAIT_OBJECT_0
            ? kExitRequesterLost : kExitInvalidFrame;
        goto Cleanup;
    }
    if (!RequesterStillMatches(externalPipe.value, requester)) {
        const DWORD requesterError = GetLastError();
        exitCode = IsExternalPipeClosureError(requesterError)
                || WaitForSingleObject(requester.process.value, 0) == WAIT_OBJECT_0
            ? kExitRequesterLost : kExitInvalidFrame;
        goto Cleanup;
    }
    if (!StartExternalInputMonitor(externalPipe.value, &externalMonitor)) {
        const DWORD monitorError = GetLastError();
        exitCode = IsExternalPipeClosureError(monitorError)
            ? kExitRequesterLost
            : (monitorError == ERROR_MORE_DATA ? kExitInvalidFrame : kExitPipeFailure);
        goto Cleanup;
    }
    readyDeadline = GetTickCount64() + kHandshakeTimeoutMs;
    if (!PrepareProtectedTemp(*paths, arguments[1], trustedInstallerSid)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitEnvironmentFailure);
        goto Cleanup;
    }
    tempPrepared = true;
    if (ExternalInputMonitorTriggered(externalMonitor)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitRequesterLost);
        goto Cleanup;
    }
    if (!CreateInternalPipes(&pipes) || !CreateContainment(&containment)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitContainmentFailure);
        goto Cleanup;
    }
    containmentCreated = true;
    gContainmentJobForFailFast = containment.job.value;
    if (!BuildEnvironment(*paths, &environment)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitEnvironmentFailure);
        goto Cleanup;
    }
    if (ExternalInputMonitorTriggered(externalMonitor)
            || !RequesterStillMatches(externalPipe.value, requester)
            || !StartBroker(*paths, arguments[1], requester, bootstrapCreation,
                &pipes, containment, environment, &brokerProcess,
                &bootstrapLivenessWrite)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            RequesterStillMatches(externalPipe.value, requester)
                ? kExitBrokerFailure : kExitRequesterLost);
        goto Cleanup;
    }
    if (ExternalInputMonitorTriggered(externalMonitor)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitRequesterLost);
        goto Cleanup;
    }
    if (failpoint == Failpoint::AfterBrokerCreate) {
        exitCode = kExitFailpoint;
        goto Cleanup;
    }
    if (!WriteFrame(pipes.requestParentWrite.value, request,
            GetExternalInputMonitorEvent(externalMonitor), brokerProcess.value, readyDeadline,
            false)
            || ExternalInputMonitorTriggered(externalMonitor)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitBrokerFailure);
        goto Cleanup;
    }
    Close(&pipes.requestParentWrite);
    ReleaseFrame(&request);
    if (failpoint == Failpoint::AfterRequestRelay) {
        exitCode = kExitFailpoint;
        goto Cleanup;
    }

    if (!ReadAndValidateFrame(pipes.resultParentRead.value, kFrameReady, kReadyMaximum,
            requestIdBytes, GetExternalInputMonitorEvent(externalMonitor),
            requester.process.value, readyDeadline,
            false, &ready)
            || ExternalInputMonitorTriggered(externalMonitor)
            || !RequesterStillMatches(externalPipe.value, requester)
            || !WriteFrame(externalPipe.value, ready,
                GetExternalInputMonitorEvent(externalMonitor), requester.process.value,
                readyDeadline, true)
            || ExternalInputMonitorTriggered(externalMonitor)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitInvalidFrame);
        goto Cleanup;
    }
    ReleaseFrame(&ready);
    if (failpoint == Failpoint::AfterReadyRelay) {
        exitCode = kExitFailpoint;
        goto Cleanup;
    }
    operationDeadline = GetTickCount64() + kOperationTimeoutMs;

    if (!ReadAndValidateFrame(pipes.resultParentRead.value, kFrameResult, kResultMaximum,
            requestIdBytes, GetExternalInputMonitorEvent(externalMonitor),
            requester.process.value, operationDeadline,
            false, &result)
            || ExternalInputMonitorTriggered(externalMonitor)
            || !RequirePipeEof(pipes.resultParentRead.value,
                GetExternalInputMonitorEvent(externalMonitor), requester.process.value,
                GetTickCount64() + kTerminalPipeTimeoutMs, false)
            || ExternalInputMonitorTriggered(externalMonitor)) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitInvalidFrame);
        goto Cleanup;
    }
    if (!WaitForBrokerExitAndRelease(&brokerProcess,
            GetTickCount64() + kBrokerExitTimeoutMs, &brokerExit,
            GetExternalInputMonitorEvent(externalMonitor))) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitBrokerFailure);
        goto Cleanup;
    }
    if (!DrainJob(containment, kDrainTimeoutMs,
            GetExternalInputMonitorEvent(externalMonitor))) {
        exitCode = SelectExternalFailureExit(externalPipe.value, externalMonitor, requester,
            kExitContainmentFailure);
        goto Cleanup;
    }
    if (failpoint == Failpoint::BeforeResultRelay) {
        exitCode = kExitFailpoint;
        goto Cleanup;
    }
    // The Result is a terminal commit, so prove containment and close the inbound
    // cancellation contract before exposing any Result bytes. After a successful
    // write there must be no fallible lifecycle phase whose infrastructure exit could
    // collide with an otherwise valid target DWORD.
    terminalInput = StopExternalInputMonitor(externalPipe.value, &externalMonitor);
    if (terminalInput != ExternalInputCompletion::Stopped) {
        if (terminalInput == ExternalInputCompletion::Closed) {
            exitCode = kExitRequesterLost;
        } else if (terminalInput == ExternalInputCompletion::UnexpectedInput) {
            exitCode = kExitInvalidFrame;
        } else {
            exitCode = kExitPipeFailure;
        }
        goto Cleanup;
    }
    if (!RequesterStillMatches(externalPipe.value, requester)
            || !WriteFrame(externalPipe.value, result, requester.process.value, nullptr,
                GetTickCount64() + kTerminalDeliveryTimeoutMs, true)) {
        const DWORD deliveryError = GetLastError();
        exitCode = IsExternalPipeClosureError(deliveryError)
                || WaitForSingleObject(requester.process.value, 0) == WAIT_OBJECT_0
            ? kExitRequesterLost : kExitPipeFailure;
        goto Cleanup;
    }
    ReleaseFrame(&result);
    // Closing produces the terminal EOF before any non-authoritative local cleanup.
    Close(&externalPipe);
    protocolComplete = true;
    exitCode = brokerExit;

Cleanup:
    ReleaseFrame(&request);
    ReleaseFrame(&ready);
    ReleaseFrame(&result);
    Close(&pipes.requestChildRead);
    Close(&pipes.requestParentWrite);
    Close(&pipes.resultChildWrite);
    Close(&pipes.resultParentRead);
    Close(&bootstrapLivenessWrite);
    bool drained = true;
    if (containmentCreated) {
        if (protocolComplete) {
            // Broker exit and ActiveProcesses==0 were proven before the terminal
            // Result commit. Do not introduce a second fallible lifecycle decision
            // that could overwrite the exact target DWORD after Result exposure.
            Close(&brokerProcess);
        } else {
            if (!QueryJobIsDrained(containment.job.value)) {
                drained = TerminateReleaseAndDrainJob(containment, &brokerProcess);
            } else {
                Close(&brokerProcess);
            }
            if (!drained) {
                exitCode = kExitContainmentFailure;
            }
        }
    } else {
        Close(&brokerProcess);
    }
    const ExternalInputCompletion monitorCompletion = protocolComplete
        ? ExternalInputCompletion::Stopped
        : StopExternalInputMonitor(externalPipe.value, &externalMonitor);
    if (protocolComplete) {
        if (monitorCompletion == ExternalInputCompletion::Closed) {
            exitCode = kExitRequesterLost;
        } else if (monitorCompletion == ExternalInputCompletion::UnexpectedInput) {
            exitCode = kExitInvalidFrame;
        } else if (monitorCompletion == ExternalInputCompletion::Failed) {
            exitCode = kExitPipeFailure;
        }
    }
    // Stop is the terminal inbound commit point. Close the channel immediately so
    // no unmonitored requester traffic can arrive during local lease/temp cleanup.
    Close(&externalPipe);
    gContainmentJobForFailFast = nullptr;
    Close(&containment.completionPort);
    Close(&containment.ownerGuard);
    Close(&containment.job);
    if (environment != nullptr) {
        SecureZeroMemory(environment, sizeof(WCHAR) * kMaximumEnvironmentCharacters);
        Release(environment);
    }
    if (tempPrepared && drained && paths != nullptr) {
        CleanupProtectedTemp(*paths, trustedInstallerSid);
    }
    ReleaseRequesterEvidence(&requester);
    Close(&brokerLease);
    Close(&powershellLease);
    Close(&selfLease);
    if (paths != nullptr) {
        SecureZeroMemory(paths, sizeof(FixedPaths));
        Release(paths);
    }
    SecureZeroMemory(requestIdBytes, sizeof(requestIdBytes));
    SecureZeroMemory(trustedInstallerSidBuffer, sizeof(trustedInstallerSidBuffer));
    if (arguments != nullptr) {
        LocalFree(arguments);
    }
    return exitCode;
}

#if defined(ATLAS_BOOTSTRAP_CONTRACT_HARNESS)

// The contract harness is compiled from this exact translation unit, without the
// production resource or requireAdministrator manifest. It exercises only transient
// processes, anonymous/local named pipes, and job objects; it never connects to the
// Atlas broker or mutates machine state.
static const DWORD kHarnessFailure = 100;
static const DWORD kHarnessTimeoutMs = 10u * 1000u;
static const DWORD kHarnessMonitorRaceIterations = 64u;
static volatile LONG gHarnessNamedPipeSequence = 0;

static bool ParseHarnessUInt32(const WCHAR* value, DWORD* output) {
    if (value == nullptr || output == nullptr || StringLength(value) != 8) {
        return false;
    }
    DWORD parsed = 0;
    for (SIZE_T index = 0; index < 8; ++index) {
        const WCHAR current = value[index];
        BYTE nibble = 0;
        if (current >= L'0' && current <= L'9') {
            nibble = static_cast<BYTE>(current - L'0');
        } else if (current >= L'A' && current <= L'F') {
            nibble = static_cast<BYTE>(10 + current - L'A');
        } else {
            return false;
        }
        parsed = (parsed << 4) | nibble;
    }
    *output = parsed;
    return true;
}

static bool ParseHarnessHandle(const WCHAR* value, HANDLE* output) {
    if (value == nullptr || output == nullptr || *value == L'\0') {
        return false;
    }
    ULONG_PTR parsed = 0;
    const ULONG_PTR maximum = static_cast<ULONG_PTR>(~static_cast<ULONG_PTR>(0));
    for (const WCHAR* cursor = value; *cursor != L'\0'; ++cursor) {
        if (*cursor < L'0' || *cursor > L'9') {
            return false;
        }
        const ULONG_PTR digit = static_cast<ULONG_PTR>(*cursor - L'0');
        if (parsed > (maximum - digit) / 10) {
            return false;
        }
        parsed = (parsed * 10) + digit;
    }
    if (parsed == 0) {
        return false;
    }
    *output = reinterpret_cast<HANDLE>(parsed);
    return true;
}

static bool AppendHarnessHex32(WCHAR* destination, SIZE_T capacity, DWORD value) {
    static const WCHAR digits[] = L"0123456789ABCDEF";
    const SIZE_T start = StringLength(destination);
    if (start + 8 >= capacity) {
        return false;
    }
    for (SIZE_T index = 0; index < 8; ++index) {
        const SIZE_T shift = (7 - index) * 4;
        destination[start + index] = digits[(value >> shift) & 0x0f];
    }
    destination[start + 8] = L'\0';
    return true;
}

static bool AppendHarnessHandle(WCHAR* destination, SIZE_T capacity, HANDLE handle) {
    return AppendUnsigned(destination, capacity, reinterpret_cast<ULONG_PTR>(handle));
}

static bool StartHarnessChild(const WCHAR* arguments, HANDLE* inheritedHandles,
        DWORD inheritedHandleCount, HANDLE job, HANDLE secondJob, bool resume,
        OwnedHandle* processOutput, DWORD* processId) {
    if (arguments == nullptr || processOutput == nullptr || inheritedHandleCount > 4
            || (inheritedHandleCount != 0 && inheritedHandles == nullptr)
            || ((job == nullptr || job == INVALID_HANDLE_VALUE)
                && secondJob != nullptr && secondJob != INVALID_HANDLE_VALUE)) {
        return false;
    }
    processOutput->value = nullptr;
    if (processId != nullptr) {
        *processId = 0;
    }

    WCHAR* self = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumPathCharacters));
    const DWORD selfLength = self == nullptr ? 0
        : GetModuleFileNameW(nullptr, self, kMaximumPathCharacters);
    WCHAR* command = static_cast<WCHAR*>(Allocate(sizeof(WCHAR) * kMaximumCommandCharacters));
    if (selfLength == 0 || selfLength >= kMaximumPathCharacters || command == nullptr
            || !AppendQuoted(command, kMaximumCommandCharacters, self)
            || !AppendString(command, kMaximumCommandCharacters, L" ")
            || !AppendString(command, kMaximumCommandCharacters, arguments)) {
        if (command != nullptr) {
            SecureZeroMemory(command, sizeof(WCHAR) * kMaximumCommandCharacters);
            Release(command);
        }
        if (self != nullptr) {
            SecureZeroMemory(self, sizeof(WCHAR) * kMaximumPathCharacters);
            Release(self);
        }
        return false;
    }

    const DWORD jobCount = job == nullptr || job == INVALID_HANDLE_VALUE ? 0u
        : (secondJob == nullptr || secondJob == INVALID_HANDLE_VALUE ? 1u : 2u);
    const DWORD attributeCount = (inheritedHandleCount == 0 ? 0u : 1u)
        + (jobCount == 0 ? 0u : 1u);
    SIZE_T attributeBytes = 0;
    InitializeProcThreadAttributeList(nullptr, attributeCount, 0, &attributeBytes);
    LPPROC_THREAD_ATTRIBUTE_LIST attributes = static_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(
        Allocate(attributeBytes));
    const bool listInitialized = attributes != nullptr && attributeCount != 0
        && InitializeProcThreadAttributeList(attributes, attributeCount, 0, &attributeBytes)
            != FALSE;
    bool initialized = listInitialized;
    if (initialized && inheritedHandleCount != 0) {
        initialized = UpdateProcThreadAttribute(attributes, 0,
            PROC_THREAD_ATTRIBUTE_HANDLE_LIST, inheritedHandles,
            sizeof(HANDLE) * inheritedHandleCount, nullptr, nullptr) != FALSE;
    }
    HANDLE jobs[2] = { job, secondJob };
    if (initialized && jobCount != 0) {
        initialized = UpdateProcThreadAttribute(attributes, 0, PROC_THREAD_ATTRIBUTE_JOB_LIST,
            jobs, sizeof(HANDLE) * jobCount, nullptr, nullptr) != FALSE;
    }

    PROCESS_INFORMATION information = {};
    STARTUPINFOEXW startup = {};
    startup.StartupInfo.cb = sizeof(startup);
    startup.lpAttributeList = attributes;
    BOOL created = FALSE;
    if (initialized) {
        created = CreateProcessW(self, command, nullptr, nullptr,
            inheritedHandleCount == 0 ? FALSE : TRUE,
            CREATE_SUSPENDED | CREATE_NO_WINDOW | EXTENDED_STARTUPINFO_PRESENT,
            nullptr, nullptr, &startup.StartupInfo, &information);
    }
    if (attributes != nullptr) {
        if (listInitialized) {
            DeleteProcThreadAttributeList(attributes);
        }
        Release(attributes);
    }
    SecureZeroMemory(command, sizeof(WCHAR) * kMaximumCommandCharacters);
    Release(command);
    if (!created) {
        SecureZeroMemory(self, sizeof(WCHAR) * kMaximumPathCharacters);
        Release(self);
        return false;
    }

    OwnedHandle process = { information.hProcess };
    OwnedHandle thread = { information.hThread };
    bool valid = true;
    if (job != nullptr && job != INVALID_HANDLE_VALUE) {
        valid = ValidateChildImageAndJob(process.value, self, job);
    }
    if (valid && secondJob != nullptr && secondJob != INVALID_HANDLE_VALUE) {
        valid = ValidateChildImageAndJob(process.value, self, secondJob);
    }
    SecureZeroMemory(self, sizeof(WCHAR) * kMaximumPathCharacters);
    Release(self);
    if (!valid || (resume && ResumeThread(thread.value) != 1)) {
        TerminateProcess(process.value, kHarnessFailure);
        Close(&thread);
        Close(&process);
        return false;
    }
    Close(&thread);
    if (processId != nullptr) {
        *processId = information.dwProcessId;
    }
    *processOutput = process;
    return true;
}

static bool BuildHarnessExitArguments(DWORD value, WCHAR* output, SIZE_T capacity) {
    return AppendString(output, capacity, L"--emit-exit ")
        && AppendHarnessHex32(output, capacity, value);
}

static bool CreateHarnessNamedPipePair(OwnedHandle* server, OwnedHandle* client) {
    if (server == nullptr || client == nullptr) {
        return false;
    }
    server->value = nullptr;
    client->value = nullptr;
    WCHAR name[160] = {};
    const LONG sequence = InterlockedIncrement(&gHarnessNamedPipeSequence);
    if (!CopyString(name, 160, L"\\\\.\\pipe\\AtlasOS.BootstrapHarness.")
            || !AppendUnsigned(name, 160, GetCurrentProcessId())
            || !AppendString(name, 160, L".")
            || !AppendUnsigned(name, 160, GetTickCount64())
            || !AppendString(name, 160, L".")
            || !AppendUnsigned(name, 160, static_cast<DWORD>(sequence))) {
        return false;
    }
    server->value = CreateNamedPipeW(name, PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT, 1, 4096, 4096, 0, nullptr);
    if (server->value == INVALID_HANDLE_VALUE) {
        server->value = nullptr;
        return false;
    }
    client->value = CreateFileW(name, GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_EXISTING,
        FILE_FLAG_OVERLAPPED, nullptr);
    if (client->value == INVALID_HANDLE_VALUE) {
        client->value = nullptr;
        Close(server);
        return false;
    }
    SetLastError(ERROR_SUCCESS);
    const BOOL connected = ConnectNamedPipe(server->value, nullptr);
    const DWORD connectError = connected ? ERROR_SUCCESS : GetLastError();
    if (!connected && connectError != ERROR_PIPE_CONNECTED) {
        Close(client);
        Close(server);
        return false;
    }
    return true;
}

static bool TestHarnessExternalMonitorAllowsOutboundWrite() {
    OwnedHandle server = { nullptr };
    OwnedHandle client = { nullptr };
    ExternalInputMonitor monitor = {};
    BYTE outbound = 0x31;
    BYTE observed = 0;
    DWORD read = 0;
    bool success = CreateHarnessNamedPipePair(&server, &client)
        && StartExternalInputMonitor(client.value, &monitor)
        && WriteExact(client.value, &outbound, 1, nullptr, nullptr,
            GetTickCount64() + kHarnessTimeoutMs, true)
        && WaitForSingleObject(GetExternalInputMonitorEvent(monitor), 0) == WAIT_TIMEOUT
        && ReadFile(server.value, &observed, 1, &read, nullptr) != FALSE
        && read == 1
        && observed == outbound
        && WaitForSingleObject(GetExternalInputMonitorEvent(monitor), 0) == WAIT_TIMEOUT;
    const ExternalInputCompletion completion = StopExternalInputMonitor(client.value, &monitor);
    success = success && completion == ExternalInputCompletion::Stopped;
    Close(&client);
    Close(&server);
    return success;
}

static bool TestHarnessExternalMonitorDetectsCallerClose() {
    OwnedHandle server = { nullptr };
    OwnedHandle client = { nullptr };
    ExternalInputMonitor monitor = {};
    bool success = CreateHarnessNamedPipePair(&server, &client)
        && StartExternalInputMonitor(client.value, &monitor);
    // The server endpoint is owned by this still-running harness process. Closing only
    // that endpoint must be independently observable as caller-pipe disposal.
    Close(&server);
    success = success
        && WaitForSingleObject(GetExternalInputMonitorEvent(monitor), kHarnessTimeoutMs)
            == WAIT_OBJECT_0
        && QueryExternalInputMonitorCompletion(client.value, monitor)
            == ExternalInputCompletion::Closed;
    const ExternalInputCompletion completion = StopExternalInputMonitor(client.value, &monitor);
    success = success && completion == ExternalInputCompletion::Closed;
    Close(&client);
    Close(&server);
    return success;
}

static bool TestHarnessExternalMonitorDetectsUnexpectedInput() {
    OwnedHandle server = { nullptr };
    OwnedHandle client = { nullptr };
    ExternalInputMonitor monitor = {};
    BYTE unexpected = 0x7F;
    DWORD written = 0;
    bool success = CreateHarnessNamedPipePair(&server, &client)
        && StartExternalInputMonitor(client.value, &monitor)
        && WriteFile(server.value, &unexpected, 1, &written, nullptr) != FALSE
        && written == 1
        && WaitForSingleObject(GetExternalInputMonitorEvent(monitor), kHarnessTimeoutMs)
            == WAIT_OBJECT_0
        && QueryExternalInputMonitorCompletion(client.value, monitor)
            == ExternalInputCompletion::UnexpectedInput;
    const ExternalInputCompletion completion = StopExternalInputMonitor(client.value, &monitor);
    success = success && completion == ExternalInputCompletion::UnexpectedInput;
    Close(&client);
    Close(&server);
    return success;
}

static bool TestHarnessExternalMonitorTargetedStop() {
    OwnedHandle server = { nullptr };
    OwnedHandle client = { nullptr };
    ExternalInputMonitor monitor = {};
    bool success = CreateHarnessNamedPipePair(&server, &client)
        && StartExternalInputMonitor(client.value, &monitor);
    const ExternalInputCompletion completion = StopExternalInputMonitor(client.value, &monitor);
    BYTE outbound = 0x62;
    BYTE observed = 0;
    DWORD read = 0;
    success = success
        && completion == ExternalInputCompletion::Stopped
        && !monitor.active
        && monitor.event.value == nullptr
        && WriteExact(client.value, &outbound, 1, nullptr, nullptr,
            GetTickCount64() + kHarnessTimeoutMs, true)
        && ReadFile(server.value, &observed, 1, &read, nullptr) != FALSE
        && read == 1
        && observed == outbound;
    Close(&client);
    Close(&server);
    return success;
}

struct HarnessClosePipeRaceContext {
    HANDLE server;
    HANDLE start;
};

static DWORD WINAPI CloseHarnessPipeRaceWorker(LPVOID parameter) {
    HarnessClosePipeRaceContext* context = static_cast<HarnessClosePipeRaceContext*>(parameter);
    if (context == nullptr || context->server == nullptr
            || context->server == INVALID_HANDLE_VALUE || context->start == nullptr
            || context->start == INVALID_HANDLE_VALUE
            || WaitForSingleObject(context->start, kHarnessTimeoutMs) != WAIT_OBJECT_0) {
        return kHarnessFailure;
    }
    return CloseHandle(context->server) ? ERROR_SUCCESS : kHarnessFailure;
}

static bool TestHarnessExternalMonitorCancelCloseRaces() {
    for (DWORD iteration = 0; iteration < kHarnessMonitorRaceIterations; ++iteration) {
        OwnedHandle server = { nullptr };
        OwnedHandle client = { nullptr };
        OwnedHandle start = { nullptr };
        OwnedHandle worker = { nullptr };
        ExternalInputMonitor monitor = {};
        HarnessClosePipeRaceContext context = {};
        bool success = CreateHarnessNamedPipePair(&server, &client)
            && StartExternalInputMonitor(client.value, &monitor);
        if (success) {
            start.value = CreateEventW(nullptr, TRUE, FALSE, nullptr);
            context.server = server.value;
            context.start = start.value;
            worker.value = CreateThread(nullptr, 0, CloseHarnessPipeRaceWorker, &context, 0,
                nullptr);
            success = start.value != nullptr && worker.value != nullptr;
        }
        if (success) {
            // Transfer endpoint ownership to the joined worker, release it and race the
            // peer close against targeted cancellation of this exact OVERLAPPED read.
            server.value = nullptr;
            success = SetEvent(start.value) != FALSE;
        }
        const ExternalInputCompletion completion = StopExternalInputMonitor(client.value,
            &monitor);
        const DWORD wait = worker.value != nullptr
            ? WaitForSingleObject(worker.value, kHarnessTimeoutMs) : WAIT_FAILED;
        DWORD workerExit = kHarnessFailure;
        if (wait == WAIT_OBJECT_0) {
            GetExitCodeThread(worker.value, &workerExit);
        }
        success = success
            && (completion == ExternalInputCompletion::Stopped
                || completion == ExternalInputCompletion::Closed)
            && wait == WAIT_OBJECT_0
            && workerExit == ERROR_SUCCESS;
        Close(&worker);
        Close(&start);
        Close(&client);
        Close(&server);
        if (!success) {
            return false;
        }
    }
    return true;
}

static bool TestHarnessPrimaryTokenMembership() {
    OwnedHandle token = { nullptr };
    BYTE sidBuffer[SECURITY_MAX_SID_SIZE] = {};
    DWORD sidLength = sizeof(sidBuffer);
    BOOL isMember = FALSE;
    const bool valid = OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY | TOKEN_DUPLICATE,
            &token.value) != FALSE
        && CreateWellKnownSid(WinAuthenticatedUserSid, nullptr, sidBuffer, &sidLength) != FALSE
        && QueryPrimaryTokenMembership(token.value, sidBuffer, &isMember)
        && isMember != FALSE;
    Close(&token);
    return valid;
}

static bool TestHarnessExitAndDrain(DWORD expected) {
    Containment containment = {};
    OwnedHandle child = { nullptr };
    WCHAR arguments[64] = {};
    DWORD observed = STILL_ACTIVE;
    bool success = CreateContainment(&containment)
        && BuildHarnessExitArguments(expected, arguments, 64)
        && StartHarnessChild(arguments, nullptr, 0, containment.job.value, nullptr, true,
            &child, nullptr)
        && WaitForBrokerExitAndRelease(&child, GetTickCount64() + kHarnessTimeoutMs, &observed)
        && child.value == nullptr
        && DrainJob(containment, kHarnessTimeoutMs)
        && observed == expected;
    if (!success && containment.job.value != nullptr) {
        TerminateReleaseAndDrainJob(containment, &child);
    }
    Close(&child);
    Close(&containment.completionPort);
    Close(&containment.ownerGuard);
    Close(&containment.job);
    return success;
}

static bool TestHarnessSuspendedOwnerGuard() {
    Containment containment = {};
    OwnedHandle inheritedOuterJob = { nullptr };
    OwnedHandle child = { nullptr };
    WCHAR arguments[64] = {};
    bool started = CreateContainment(&containment)
        && DuplicateHandle(GetCurrentProcess(), containment.job.value, GetCurrentProcess(),
            &inheritedOuterJob.value, JOB_OBJECT_ASSIGN_PROCESS | JOB_OBJECT_QUERY | SYNCHRONIZE,
            TRUE, 0) != FALSE
        && BuildHarnessExitArguments(ERROR_SUCCESS, arguments, 64);
    HANDLE inherited[1] = { inheritedOuterJob.value };
    if (started) {
        started = StartHarnessChild(arguments, inherited, 1, containment.job.value,
            containment.ownerGuard.value, false, &child, nullptr);
    }
    Close(&inheritedOuterJob);
    const bool suspendedAndLive = started
        && WaitForSingleObject(child.value, 0) == WAIT_TIMEOUT;

    // The suspended child deliberately retains an outer-job duplicate and cannot run
    // liveness cleanup. The bootstrap-only guard must still kill it on last-handle close.
    Close(&containment.ownerGuard);
    const DWORD wait = suspendedAndLive
        ? WaitForSingleObject(child.value, kHarnessTimeoutMs) : WAIT_FAILED;
    DWORD exitCode = STILL_ACTIVE;
    const bool killed = wait == WAIT_OBJECT_0
        && GetExitCodeProcess(child.value, &exitCode) != FALSE
        && exitCode != STILL_ACTIVE;
    Close(&child);
    const bool success = killed && DrainJob(containment, kHarnessTimeoutMs);
    if (!success && containment.job.value != nullptr) {
        TerminateReleaseAndDrainJob(containment, &child);
    }
    Close(&child);
    Close(&containment.completionPort);
    Close(&containment.ownerGuard);
    Close(&containment.job);
    return success;
}

static bool TestHarnessLivenessEof() {
    SECURITY_ATTRIBUTES security = {};
    security.nLength = sizeof(security);
    security.bInheritHandle = TRUE;
    OwnedHandle childRead = { nullptr };
    OwnedHandle parentWrite = { nullptr };
    OwnedHandle parentReadyRead = { nullptr };
    OwnedHandle childReadyWrite = { nullptr };
    OwnedHandle child = { nullptr };
    if (!CreatePipe(&childRead.value, &parentWrite.value, &security, 0)
            || !CreatePipe(&parentReadyRead.value, &childReadyWrite.value, &security, 0)
            || !SetHandleInformation(parentWrite.value, HANDLE_FLAG_INHERIT, 0)
            || !SetHandleInformation(parentReadyRead.value, HANDLE_FLAG_INHERIT, 0)) {
        Close(&childRead);
        Close(&parentWrite);
        Close(&parentReadyRead);
        Close(&childReadyWrite);
        return false;
    }
    DWORD writerFlags = 0;
    if (!GetHandleInformation(parentWrite.value, &writerFlags)
            || (writerFlags & HANDLE_FLAG_INHERIT) != 0) {
        Close(&childRead);
        Close(&parentWrite);
        Close(&parentReadyRead);
        Close(&childReadyWrite);
        return false;
    }

    WCHAR arguments[128] = {};
    const bool commandBuilt = AppendString(arguments, 128, L"--liveness-reader ")
        && AppendHarnessHandle(arguments, 128, childRead.value)
        && AppendString(arguments, 128, L" ")
        && AppendHarnessHandle(arguments, 128, childReadyWrite.value);
    HANDLE inherited[2] = { childRead.value, childReadyWrite.value };
    const bool started = commandBuilt
        && StartHarnessChild(arguments, inherited, 2, nullptr, nullptr, true, &child, nullptr);
    Close(&childRead);
    Close(&childReadyWrite);
    BYTE ready = 0;
    const bool signaled = started
        && ReadExact(parentReadyRead.value, &ready, 1, child.value, nullptr,
            GetTickCount64() + kHarnessTimeoutMs, false)
        && ready == 0xA5;
    Close(&parentReadyRead);
    Close(&parentWrite);
    const DWORD wait = signaled
        ? WaitForSingleObject(child.value, kHarnessTimeoutMs) : WAIT_FAILED;
    DWORD exitCode = STILL_ACTIVE;
    const bool success = wait == WAIT_OBJECT_0
        && GetExitCodeProcess(child.value, &exitCode) != FALSE
        && exitCode == ERROR_SUCCESS;
    if (child.value != nullptr && wait != WAIT_OBJECT_0) {
        TerminateProcess(child.value, kHarnessFailure);
    }
    Close(&child);
    return success;
}

static DWORD RunHarnessJobWorker(HANDLE inheritedJob, HANDLE readyWrite) {
    if (inheritedJob == nullptr || inheritedJob == INVALID_HANDLE_VALUE
            || readyWrite == nullptr || readyWrite == INVALID_HANDLE_VALUE
            || !CloseHandle(inheritedJob)) {
        return kHarnessFailure;
    }
    BYTE ready = 0x5A;
    DWORD written = 0;
    const bool published = WriteFile(readyWrite, &ready, 1, &written, nullptr) != FALSE
        && written == 1;
    CloseHandle(readyWrite);
    if (!published) {
        return kHarnessFailure;
    }
    Sleep(INFINITE);
    return kHarnessFailure;
}

static DWORD RunHarnessOwnerController(HANDLE reportWrite) {
    Containment containment = {};
    OwnedHandle inheritedJob = { nullptr };
    OwnedHandle readyRead = { nullptr };
    OwnedHandle readyWrite = { nullptr };
    OwnedHandle worker = { nullptr };
    SECURITY_ATTRIBUTES security = {};
    security.nLength = sizeof(security);
    security.bInheritHandle = TRUE;
    DWORD workerProcessId = 0;
    bool success = CreateContainment(&containment)
        && DuplicateHandle(GetCurrentProcess(), containment.job.value, GetCurrentProcess(),
            &inheritedJob.value, JOB_OBJECT_ASSIGN_PROCESS | JOB_OBJECT_QUERY | SYNCHRONIZE,
            TRUE, 0) != FALSE
        && CreatePipe(&readyRead.value, &readyWrite.value, &security, 0) != FALSE
        && SetHandleInformation(readyRead.value, HANDLE_FLAG_INHERIT, 0) != FALSE;
    WCHAR arguments[128] = {};
    if (success) {
        success = AppendString(arguments, 128, L"--job-worker ")
            && AppendHarnessHandle(arguments, 128, inheritedJob.value)
            && AppendString(arguments, 128, L" ")
            && AppendHarnessHandle(arguments, 128, readyWrite.value);
    }
    HANDLE inherited[2] = { inheritedJob.value, readyWrite.value };
    if (success) {
        success = StartHarnessChild(arguments, inherited, 2, containment.job.value,
            containment.ownerGuard.value, true, &worker, &workerProcessId);
    }
    Close(&inheritedJob);
    Close(&readyWrite);
    BYTE ready = 0;
    if (success) {
        success = ReadExact(readyRead.value, &ready, 1, worker.value, nullptr,
            GetTickCount64() + kHarnessTimeoutMs, false)
            && ready == 0x5A;
    }
    Close(&readyRead);
    DWORD written = 0;
    if (success) {
        success = WriteFile(reportWrite, &workerProcessId, sizeof(workerProcessId), &written,
            nullptr) != FALSE && written == sizeof(workerProcessId);
    }
    CloseHandle(reportWrite);
    if (!success) {
        TerminateReleaseAndDrainJob(containment, &worker);
        Close(&worker);
        Close(&containment.completionPort);
        Close(&containment.ownerGuard);
        Close(&containment.job);
        return kHarnessFailure;
    }
    Close(&worker);
    Sleep(INFINITE);
    return kHarnessFailure;
}

static bool TestHarnessOwnerDeath() {
    SECURITY_ATTRIBUTES security = {};
    security.nLength = sizeof(security);
    security.bInheritHandle = TRUE;
    OwnedHandle reportRead = { nullptr };
    OwnedHandle reportWrite = { nullptr };
    OwnedHandle controller = { nullptr };
    OwnedHandle worker = { nullptr };
    if (!CreatePipe(&reportRead.value, &reportWrite.value, &security, 0)
            || !SetHandleInformation(reportRead.value, HANDLE_FLAG_INHERIT, 0)) {
        Close(&reportRead);
        Close(&reportWrite);
        return false;
    }
    WCHAR arguments[96] = {};
    const bool commandBuilt = AppendString(arguments, 96, L"--owner-controller ")
        && AppendHarnessHandle(arguments, 96, reportWrite.value);
    HANDLE inherited[1] = { reportWrite.value };
    const bool started = commandBuilt
        && StartHarnessChild(arguments, inherited, 1, nullptr, nullptr, true, &controller,
            nullptr);
    Close(&reportWrite);
    DWORD workerProcessId = 0;
    const bool reported = started
        && ReadExact(reportRead.value, reinterpret_cast<BYTE*>(&workerProcessId),
            sizeof(workerProcessId), controller.value, nullptr,
            GetTickCount64() + kHarnessTimeoutMs, false)
        && workerProcessId != 0;
    Close(&reportRead);
    if (reported) {
        worker.value = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION
            | PROCESS_TERMINATE, FALSE, workerProcessId);
    }
    const bool workerOpened = worker.value != nullptr && worker.value != INVALID_HANDLE_VALUE;
    const bool workerLiveBeforeOwnerDeath = workerOpened
        && WaitForSingleObject(worker.value, 0) == WAIT_TIMEOUT;
    const bool controllerKilled = workerLiveBeforeOwnerDeath
        && TerminateProcess(controller.value, kHarnessFailure) != FALSE
        && WaitForSingleObject(controller.value, kHarnessTimeoutMs) == WAIT_OBJECT_0;
    const DWORD workerWait = controllerKilled
        ? WaitForSingleObject(worker.value, kHarnessTimeoutMs) : WAIT_FAILED;
    DWORD workerExit = STILL_ACTIVE;
    const bool success = workerWait == WAIT_OBJECT_0
        && GetExitCodeProcess(worker.value, &workerExit) != FALSE
        && workerExit != STILL_ACTIVE;
    if (worker.value != nullptr && workerWait != WAIT_OBJECT_0) {
        if (TerminateProcess(worker.value, kHarnessFailure)) {
            WaitForSingleObject(worker.value, kHarnessTimeoutMs);
        }
    }
    if (controller.value != nullptr
            && WaitForSingleObject(controller.value, 0) == WAIT_TIMEOUT) {
        if (TerminateProcess(controller.value, kHarnessFailure)) {
            WaitForSingleObject(controller.value, kHarnessTimeoutMs);
        }
    }
    Close(&worker);
    Close(&controller);
    return success;
}

static DWORD RunContractHarness() {
    int argumentCount = 0;
    LPWSTR* arguments = CommandLineToArgvW(GetCommandLineW(), &argumentCount);
    DWORD result = kHarnessFailure;
    if (arguments == nullptr) {
        return result;
    }
    if (argumentCount == 3 && EqualOrdinal(arguments[1], L"--emit-exit")) {
        DWORD exitCode = 0;
        result = ParseHarnessUInt32(arguments[2], &exitCode) ? exitCode : kHarnessFailure;
    } else if (argumentCount == 4 && EqualOrdinal(arguments[1], L"--liveness-reader")) {
        HANDLE livenessRead = nullptr;
        HANDLE readyWrite = nullptr;
        if (ParseHarnessHandle(arguments[2], &livenessRead)
                && ParseHarnessHandle(arguments[3], &readyWrite)) {
            BYTE value = 0;
            DWORD read = 0;
            BYTE ready = 0xA5;
            DWORD written = 0;
            const bool published = WriteFile(readyWrite, &ready, 1, &written, nullptr) != FALSE
                && written == 1;
            CloseHandle(readyWrite);
            SetLastError(ERROR_SUCCESS);
            const bool completed = ReadFile(livenessRead, &value, 1, &read, nullptr) != FALSE;
            const DWORD error = completed ? ERROR_SUCCESS : GetLastError();
            CloseHandle(livenessRead);
            result = published && !completed && error == ERROR_BROKEN_PIPE
                ? ERROR_SUCCESS : kHarnessFailure;
        }
    } else if (argumentCount == 4 && EqualOrdinal(arguments[1], L"--job-worker")) {
        HANDLE inheritedJob = nullptr;
        HANDLE readyWrite = nullptr;
        if (ParseHarnessHandle(arguments[2], &inheritedJob)
                && ParseHarnessHandle(arguments[3], &readyWrite)) {
            result = RunHarnessJobWorker(inheritedJob, readyWrite);
        }
    } else if (argumentCount == 3 && EqualOrdinal(arguments[1], L"--owner-controller")) {
        HANDLE reportWrite = nullptr;
        if (ParseHarnessHandle(arguments[2], &reportWrite)) {
            result = RunHarnessOwnerController(reportWrite);
        }
    } else if (argumentCount == 1 || (argumentCount == 2
            && EqualOrdinal(arguments[1], L"--self-test"))) {
        const DWORD cases[] = { 0u, 5u, STILL_ACTIVE, 0x80000005u, 0xffffffffu };
        bool valid = TestHarnessPrimaryTokenMembership();
        for (SIZE_T index = 0; valid && index < sizeof(cases) / sizeof(cases[0]); ++index) {
            valid = TestHarnessExitAndDrain(cases[index]);
        }
        valid = valid && TestHarnessSuspendedOwnerGuard();
        valid = valid && TestHarnessLivenessEof();
        valid = valid && TestHarnessOwnerDeath();
        valid = valid && TestHarnessExternalMonitorAllowsOutboundWrite();
        valid = valid && TestHarnessExternalMonitorDetectsCallerClose();
        valid = valid && TestHarnessExternalMonitorDetectsUnexpectedInput();
        valid = valid && TestHarnessExternalMonitorTargetedStop();
        valid = valid && TestHarnessExternalMonitorCancelCloseRaces();
        result = valid ? ERROR_SUCCESS : kHarnessFailure;
    }
    LocalFree(arguments);
    return result;
}

#endif

} // namespace AtlasBootstrap

extern "C" __declspec(safebuffers) void WINAPI wWinMainCRTStartup() {
    __security_init_cookie();
#if defined(ATLAS_BOOTSTRAP_CONTRACT_HARNESS)
    ExitProcess(AtlasBootstrap::RunContractHarness());
#else
    ExitProcess(AtlasBootstrap::Run());
#endif
}
