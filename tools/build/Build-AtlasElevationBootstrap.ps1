#requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateSet('all', 'amd64', 'arm64')]
    [string]$Architecture = 'all',

    [string]$OutputDirectory = (Join-Path $PSScriptRoot `
        '..\..\playbook\Executables\AtlasModules\Tools'),

    [string]$LlvmRoot = $env:ATLAS_LLVM_ROOT,

    [switch]$RunContractHarness,

    [string]$HashManifestPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

function Resolve-Executable {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$ExplicitPath
    )

    if ($ExplicitPath) {
        $resolved = Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop
        return $resolved.ProviderPath
    }
    $command = Get-Command -Name $Name -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
    return $command.Source
}

function Test-PathEqual {
    param(
        [Parameter(Mandatory = $true)][string]$First,
        [Parameter(Mandatory = $true)][string]$Second
    )

    $left = [IO.Path]::GetFullPath($First).TrimEnd('\')
    $right = [IO.Path]::GetFullPath($Second).TrimEnd('\')
    return [string]::Equals($left, $right, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoPathAlias {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $candidate = [IO.Path]::GetFullPath($Path)
    while ($candidate) {
        if (Test-Path -LiteralPath $candidate) {
            $item = Get-Item -LiteralPath $candidate -Force -ErrorAction Stop
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                    -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
                throw "$Label cannot contain or target a filesystem alias: '$($item.FullName)'."
            }
        }
        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or (Test-PathEqual $parent $candidate)) {
            break
        }
        $candidate = $parent
    }
}

function Initialize-AtlasBuildPathIdentityType {
    if ('Atlas.BuildPathIdentity' -as [type]) {
        return
    }

    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Atlas
{
    public static class BuildPathIdentity
    {
        private const uint FileShareRead = 0x00000001;
        private const uint FileShareWrite = 0x00000002;
        private const uint FileShareDelete = 0x00000004;
        private const uint OpenExisting = 3;
        private const uint FileFlagBackupSemantics = 0x02000000;
        private const int FileIdInfo = 18;
        private const int FileIdInfoSize = 24;

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern SafeFileHandle CreateFileW(
            string fileName,
            uint desiredAccess,
            uint shareMode,
            IntPtr securityAttributes,
            uint creationDisposition,
            uint flagsAndAttributes,
            IntPtr templateFile);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern uint GetFinalPathNameByHandleW(
            SafeFileHandle file,
            StringBuilder path,
            uint pathLength,
            uint flags);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetFileInformationByHandleEx(
            SafeFileHandle file,
            int fileInformationClass,
            IntPtr fileInformation,
            uint bufferSize);

        public static string GetFinalPath(string path)
        {
            using (SafeFileHandle file = CreateFileW(
                path,
                0,
                FileShareRead | FileShareWrite | FileShareDelete,
                IntPtr.Zero,
                OpenExisting,
                FileFlagBackupSemantics,
                IntPtr.Zero))
            {
                if (file.IsInvalid)
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }

                return GetFinalPath(file);
            }
        }

        public static string GetFinalPath(SafeFileHandle file)
        {
            if (file == null || file.IsInvalid || file.IsClosed)
            {
                throw new InvalidOperationException("The filesystem identity handle is not open.");
            }

            uint capacity = 512;
            while (true)
            {
                StringBuilder result = new StringBuilder((int)capacity);
                uint required = GetFinalPathNameByHandleW(file, result, capacity, 0);
                if (required == 0)
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }
                if (required < capacity)
                {
                    return result.ToString();
                }
                if (required >= 32767)
                {
                    throw new InvalidOperationException("The final filesystem path is too long.");
                }
                capacity = required + 1;
            }
        }

        public static SafeFileHandle OpenDirectoryLease(string path)
        {
            SafeFileHandle file = CreateFileW(
                path,
                0,
                FileShareRead | FileShareWrite,
                IntPtr.Zero,
                OpenExisting,
                FileFlagBackupSemantics,
                IntPtr.Zero);
            if (file.IsInvalid)
            {
                int error = Marshal.GetLastWin32Error();
                file.Dispose();
                throw new Win32Exception(error);
            }
            return file;
        }

        public static string GetFileId(string path)
        {
            using (SafeFileHandle file = CreateFileW(
                path,
                0,
                FileShareRead | FileShareWrite | FileShareDelete,
                IntPtr.Zero,
                OpenExisting,
                FileFlagBackupSemantics,
                IntPtr.Zero))
            {
                if (file.IsInvalid)
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }
                return GetFileId(file);
            }
        }

        public static string GetFileId(SafeFileHandle file)
        {
            if (file == null || file.IsInvalid || file.IsClosed)
            {
                throw new InvalidOperationException("The filesystem identity handle is not open.");
            }

            IntPtr buffer = Marshal.AllocHGlobal(FileIdInfoSize);
            try
            {
                for (int index = 0; index < FileIdInfoSize; index++)
                {
                    Marshal.WriteByte(buffer, index, 0);
                }
                if (!GetFileInformationByHandleEx(
                    file, FileIdInfo, buffer, (uint)FileIdInfoSize))
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }

                ulong volumeSerialNumber = unchecked((ulong)Marshal.ReadInt64(buffer, 0));
                StringBuilder result = new StringBuilder(16 + 1 + 32);
                result.Append(volumeSerialNumber.ToString("X16"));
                result.Append(':');
                for (int index = 0; index < 16; index++)
                {
                    result.Append(Marshal.ReadByte(buffer, 8 + index).ToString("X2"));
                }
                return result.ToString();
            }
            finally
            {
                Marshal.FreeHGlobal(buffer);
            }
        }
    }
}
'@ | Out-Null
}

function Get-FinalPathIdentity {
    param([Parameter(Mandatory = $true)][string]$Path)

    Initialize-AtlasBuildPathIdentityType
    return [Atlas.BuildPathIdentity]::GetFinalPath(
        [IO.Path]::GetFullPath($Path)).TrimEnd('\')
}

function ConvertFrom-FinalPathIdentity {
    param([Parameter(Mandatory = $true)][string]$Identity)

    if ($Identity.StartsWith('\\?\UNC\', [StringComparison]::OrdinalIgnoreCase)) {
        return '\\' + $Identity.Substring(8)
    }
    if ($Identity -match '^\\\\\?\\[A-Za-z]:$') {
        return $Identity.Substring(4) + '\'
    }
    if ($Identity -match '^\\\\\?\\[A-Za-z]:\\') {
        return $Identity.Substring(4)
    }
    return $Identity
}

function Invoke-NativeTool {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $output = @(& $Tool @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $diagnostic = ($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join `
            [Environment]::NewLine
        if ($diagnostic) {
            throw "$Label failed with exit code $exitCode.`r`n$diagnostic"
        }
        throw "$Label failed with exit code $exitCode."
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = [string[]]$output
    }
}

function Get-NativeToolVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $invocation = Invoke-NativeTool -Tool $Tool -Arguments $Arguments `
        -Label "$Label version query"
    $version = $invocation.Output |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($version)) {
        throw "$Label did not report a version."
    }
    return $version.Trim()
}

function Get-FileEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Version
    )

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item.PSIsContainer) {
        throw "Expected a file but found a directory: '$($item.FullName)'."
    }
    $evidence = [ordered]@{
        FileName = $item.Name
        Length   = [long]$item.Length
        SHA256   = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
    }
    if ($PSBoundParameters.ContainsKey('Version')) {
        if ([string]::IsNullOrWhiteSpace($Version) -or $Version -match '[\r\n]') {
            throw "Invalid version evidence for '$($item.FullName)'."
        }
        $evidence.Version = $Version
    }
    return $evidence
}

function Get-PublicationFileEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($item.PSIsContainer -or
            ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
        throw "$Label must be a regular non-reparse file: '$($item.FullName)'."
    }

    $stream = [IO.File]::Open(
        $item.FullName,
        [IO.FileMode]::Open,
        [IO.FileAccess]::Read,
        [IO.FileShare]::Read
    )
    try {
        $openedPath = ConvertFrom-FinalPathIdentity -Identity `
            ([Atlas.BuildPathIdentity]::GetFinalPath($stream.SafeFileHandle))
        if (-not (Test-PathEqual $openedPath $item.FullName)) {
            throw "$Label resolved to a different file after its read lease was opened."
        }
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            $hash = [Convert]::ToHexString($sha256.ComputeHash($stream))
        }
        finally {
            $sha256.Dispose()
        }
        return [pscustomobject]@{
            Length = [long]$stream.Length
            SHA256 = $hash
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Assert-PublicationRootIdentity {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ExpectedIdentity,
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.SafeHandles.SafeFileHandle]$Lease,
        [Parameter(Mandatory = $true)][string]$ExpectedFileId,
        [Parameter(Mandatory = $true)][string]$Phase
    )

    if ($Lease.IsInvalid -or $Lease.IsClosed) {
        throw "The output-directory identity lease closed $Phase."
    }
    Assert-NoPathAlias -Path $Root -Label "The output directory $Phase"
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "The output directory disappeared ${Phase}: '$Root'."
    }
    $currentIdentity = Get-FinalPathIdentity -Path $Root
    if (-not [string]::Equals($currentIdentity, $ExpectedIdentity,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw "The output directory filesystem identity changed $Phase."
    }
    $leaseIdentity = [Atlas.BuildPathIdentity]::GetFinalPath($Lease).TrimEnd('\')
    if (-not [string]::Equals($leaseIdentity, $ExpectedIdentity,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw "The leased output directory path changed $Phase."
    }
    $leaseFileId = [Atlas.BuildPathIdentity]::GetFileId($Lease)
    $currentFileId = [Atlas.BuildPathIdentity]::GetFileId($Root)
    if ($leaseFileId -cne $ExpectedFileId -or $currentFileId -cne $ExpectedFileId) {
        throw "The output directory file identity changed $Phase."
    }
}

function Assert-PublicationOperationPrecondition {
    param(
        [Parameter(Mandatory = $true)][object]$Operation,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ExpectedRootIdentity,
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.SafeHandles.SafeFileHandle]$RootLease,
        [Parameter(Mandatory = $true)][string]$ExpectedRootFileId,
        [Parameter(Mandatory = $true)][string]$Phase
    )

    Assert-PublicationRootIdentity -Root $Root -ExpectedIdentity $ExpectedRootIdentity `
        -Lease $RootLease -ExpectedFileId $ExpectedRootFileId -Phase $Phase
    foreach ($path in @(
            $Operation.DestinationPath,
            $Operation.TemporaryPath,
            $Operation.BackupPath)) {
        if (-not (Test-PathEqual (Split-Path -Parent $path) $Root)) {
            throw "A publication path escaped the output directory ${Phase}: '$path'."
        }
    }
    Assert-NoPathAlias -Path $Operation.DestinationPath `
        -Label "The publication destination $Phase"
    Assert-NoPathAlias -Path $Operation.BackupPath `
        -Label "The publication backup path $Phase"

    Assert-NoPathAlias -Path $Operation.TemporaryPath `
        -Label "The staged publication file $Phase"
    if (-not (Test-Path -LiteralPath $Operation.TemporaryPath -PathType Leaf)) {
        throw "The staged publication file disappeared ${Phase}: '$($Operation.TemporaryPath)'."
    }
    $temporaryEvidence = Get-PublicationFileEvidence `
        -Path $Operation.TemporaryPath -Label "The staged publication file $Phase"
    if ($temporaryEvidence.Length -ne $Operation.ExpectedLength -or
            $temporaryEvidence.SHA256 -cne $Operation.ExpectedSHA256) {
        throw "The staged publication file changed ${Phase}: '$($Operation.TemporaryPath)'."
    }

    if (Test-Path -LiteralPath $Operation.BackupPath) {
        throw "A publication backup path unexpectedly exists ${Phase}: '$($Operation.BackupPath)'."
    }

    if ($Operation.HadDestination) {
        if (-not (Test-Path -LiteralPath $Operation.DestinationPath -PathType Leaf)) {
            throw "A publication destination disappeared ${Phase}: '$($Operation.DestinationPath)'."
        }
        $destinationEvidence = Get-PublicationFileEvidence `
            -Path $Operation.DestinationPath -Label "The publication destination $Phase"
        if ($destinationEvidence.Length -ne $Operation.OriginalLength -or
                $destinationEvidence.SHA256 -cne $Operation.OriginalSHA256) {
            throw "A publication destination changed ${Phase}: '$($Operation.DestinationPath)'."
        }
    }
    elseif (Test-Path -LiteralPath $Operation.DestinationPath) {
        throw "A publication destination unexpectedly appeared ${Phase}: '$($Operation.DestinationPath)'."
    }
}

function Get-PublicationPathState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Operation,
        [Parameter(Mandatory = $true)][string]$Label
    )

    try {
        try {
            $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            return [pscustomobject]@{ Kind = 'Absent'; Detail = $null }
        }
        Assert-NoPathAlias -Path $Path -Label $Label
        if ($item.PSIsContainer -or
                ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
            throw "The path is not a regular file: '$Path'."
        }
        $evidence = Get-PublicationFileEvidence -Path $Path -Label $Label
        $matchesOriginal = $Operation.HadDestination -and
            $evidence.Length -eq $Operation.OriginalLength -and
            $evidence.SHA256 -ceq $Operation.OriginalSHA256
        $matchesExpected = $evidence.Length -eq $Operation.ExpectedLength -and
            $evidence.SHA256 -ceq $Operation.ExpectedSHA256
        $kind = if ($matchesOriginal -and $matchesExpected) {
            'OriginalAndExpected'
        }
        elseif ($matchesOriginal) {
            'Original'
        }
        elseif ($matchesExpected) {
            'Expected'
        }
        else {
            'Unexpected'
        }
        return [pscustomobject]@{
            Kind   = $kind
            Detail = "Length=$($evidence.Length), SHA256=$($evidence.SHA256)"
        }
    }
    catch {
        return [pscustomobject]@{
            Kind   = 'Unclassifiable'
            Detail = $_.Exception.Message
        }
    }
}

function Get-PublicationOperationState {
    param([Parameter(Mandatory = $true)][object]$Operation)

    return [pscustomobject]@{
        Destination = Get-PublicationPathState -Path $Operation.DestinationPath `
            -Operation $Operation -Label 'A publication rollback destination'
        Temporary   = Get-PublicationPathState -Path $Operation.TemporaryPath `
            -Operation $Operation -Label 'A publication rollback staging file'
        Backup      = Get-PublicationPathState -Path $Operation.BackupPath `
            -Operation $Operation -Label 'A publication rollback backup'
    }
}

function Test-PublicationStateKind {
    param(
        [Parameter(Mandatory = $true)][object]$State,
        [Parameter(Mandatory = $true)][string[]]$Allowed
    )

    return $Allowed -ccontains [string]$State.Kind
}

function Format-PublicationOperationState {
    param([Parameter(Mandatory = $true)][object]$State)

    return 'Destination={0}; Temporary={1}; Backup={2}' -f `
        $State.Destination.Kind, $State.Temporary.Kind, $State.Backup.Kind
}

function Invoke-PublicationOperationRollback {
    param(
        [Parameter(Mandatory = $true)][object]$Operation,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ExpectedRootIdentity,
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.SafeHandles.SafeFileHandle]$RootLease,
        [Parameter(Mandatory = $true)][string]$ExpectedRootFileId
    )

    Assert-PublicationRootIdentity -Root $Root -ExpectedIdentity $ExpectedRootIdentity `
        -Lease $RootLease -ExpectedFileId $ExpectedRootFileId `
        -Phase 'during publication rollback classification'
    $state = Get-PublicationOperationState -Operation $Operation
    $temporaryIsExpectedOrAbsent = Test-PublicationStateKind -State $state.Temporary `
        -Allowed @('Absent', 'Expected', 'OriginalAndExpected')
    $action = 'None'

    if ($Operation.HadDestination) {
        $destinationIsOriginal = Test-PublicationStateKind -State $state.Destination `
            -Allowed @('Original', 'OriginalAndExpected')
        $destinationIsExpected = Test-PublicationStateKind -State $state.Destination `
            -Allowed @('Expected', 'OriginalAndExpected')
        $backupIsOriginalOrAbsent = Test-PublicationStateKind -State $state.Backup `
            -Allowed @('Absent', 'Original', 'OriginalAndExpected')
        $backupIsOriginal = Test-PublicationStateKind -State $state.Backup `
            -Allowed @('Original', 'OriginalAndExpected')

        if ($destinationIsOriginal -and $temporaryIsExpectedOrAbsent -and
                $backupIsOriginalOrAbsent) {
            # ReplaceFile can report an error after retaining or recreating the
            # exact pre-state. No filesystem mutation is required to roll back.
            $Operation.RollbackClassified = $true
        }
        elseif (($state.Destination.Kind -ceq 'Absent' -or $destinationIsExpected) -and
                $temporaryIsExpectedOrAbsent -and $backupIsOriginal) {
            # This includes ERROR_UNABLE_TO_MOVE_REPLACEMENT_2: the destination
            # is absent, the original is in the backup, and the replacement is
            # still staged. It also covers a completed replace reported as an
            # error, where the exact replacement is at the destination.
            $Operation.RollbackClassified = $true
            $action = 'RestoreOriginalFromBackup'
        }
        else {
            $Operation.RetainRecoveryPaths = $true
            throw "The attempted replacement has an unclassifiable state: $(Format-PublicationOperationState -State $state)."
        }
    }
    else {
        $destinationIsExpectedOrAbsent = Test-PublicationStateKind `
            -State $state.Destination -Allowed @('Absent', 'Expected')
        if (-not $destinationIsExpectedOrAbsent -or
                -not $temporaryIsExpectedOrAbsent -or
                $state.Backup.Kind -cne 'Absent') {
            $Operation.RetainRecoveryPaths = $true
            throw "The attempted move has an unclassifiable state: $(Format-PublicationOperationState -State $state)."
        }
        $Operation.RollbackClassified = $true
        if ($state.Destination.Kind -ceq 'Expected') {
            # File.Move can succeed and still surface a later interruption. The
            # exact newly published destination must be removed during rollback.
            $action = 'RemoveNewDestination'
        }
    }

    $actionError = $null
    try {
        if ($action -cne 'None') {
            Assert-PublicationRootIdentity -Root $Root `
                -ExpectedIdentity $ExpectedRootIdentity -Lease $RootLease `
                -ExpectedFileId $ExpectedRootFileId `
                -Phase 'immediately before a publication rollback mutation'
            $state = Get-PublicationOperationState -Operation $Operation
        }
        if ($action -ceq 'RestoreOriginalFromBackup') {
            $destinationIsExpected = Test-PublicationStateKind `
                -State $state.Destination -Allowed @('Expected', 'OriginalAndExpected')
            $backupIsOriginal = Test-PublicationStateKind -State $state.Backup `
                -Allowed @('Original', 'OriginalAndExpected')
            if (($state.Destination.Kind -cne 'Absent' -and -not $destinationIsExpected) -or
                    -not $backupIsOriginal -or
                    -not (Test-PublicationStateKind -State $state.Temporary `
                        -Allowed @('Absent', 'Expected', 'OriginalAndExpected'))) {
                throw "The classified replacement changed before rollback: $(Format-PublicationOperationState -State $state)."
            }
            if ($state.Destination.Kind -cne 'Absent') {
                [IO.File]::Delete($Operation.DestinationPath)
            }
            [IO.File]::Move($Operation.BackupPath, $Operation.DestinationPath)
        }
        elseif ($action -ceq 'RemoveNewDestination') {
            if ($state.Destination.Kind -cne 'Expected' -or
                    $state.Backup.Kind -cne 'Absent' -or
                    -not (Test-PublicationStateKind -State $state.Temporary `
                        -Allowed @('Absent', 'Expected'))) {
                throw "The classified move changed before rollback: $(Format-PublicationOperationState -State $state)."
            }
            [IO.File]::Delete($Operation.DestinationPath)
        }
    }
    catch {
        $actionError = $_
    }

    $finalState = Get-PublicationOperationState -Operation $Operation
    $finalTemporaryIsExpectedOrAbsent = Test-PublicationStateKind `
        -State $finalState.Temporary -Allowed @('Absent', 'Expected', 'OriginalAndExpected')
    $restored = if ($Operation.HadDestination) {
        (Test-PublicationStateKind -State $finalState.Destination `
            -Allowed @('Original', 'OriginalAndExpected')) -and
            $finalTemporaryIsExpectedOrAbsent -and
            (Test-PublicationStateKind -State $finalState.Backup `
                -Allowed @('Absent', 'Original', 'OriginalAndExpected'))
    }
    else {
        $finalState.Destination.Kind -ceq 'Absent' -and
            $finalTemporaryIsExpectedOrAbsent -and
            $finalState.Backup.Kind -ceq 'Absent'
    }
    if (-not $restored) {
        $Operation.RetainRecoveryPaths = $true
        $actionMessage = if ($actionError) {
            " Rollback mutation failed: $($actionError.Exception.Message)"
        } else {
            ''
        }
        throw "The attempted publication could not be restored: $(Format-PublicationOperationState -State $finalState).$actionMessage"
    }

    $Operation.RollbackSucceeded = $true
    $Operation.RetainRecoveryPaths = $false
}

function Get-ExactPublicationDebris {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$DestinationNames
    )

    $escapedNames = @($DestinationNames | ForEach-Object { [regex]::Escape($_) })
    if ($escapedNames.Count -eq 0) {
        return @()
    }
    $pattern = '^\.(?:{0})\.[0-9a-f]{{32}}\.(?:publish|backup)$' -f `
        ($escapedNames -join '|')
    $debris = New-Object 'Collections.Generic.List[object]'
    foreach ($item in Get-ChildItem -LiteralPath $Root -Force -ErrorAction Stop) {
        if (-not [regex]::IsMatch($item.Name, $pattern,
                [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            continue
        }
        if ($item.PSIsContainer -or
                ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
            throw "Refusing to recover non-file publication debris: '$($item.FullName)'."
        }
        Assert-NoPathAlias -Path $item.FullName -Label 'Publication debris'
        if (-not (Test-PathEqual (Split-Path -Parent $item.FullName) $Root)) {
            throw "Publication debris escaped the output directory: '$($item.FullName)'."
        }
        $evidence = Get-PublicationFileEvidence -Path $item.FullName `
            -Label 'Publication debris'
        $debris.Add([pscustomobject]@{
            Path   = $item.FullName
            Length = $evidence.Length
            SHA256 = $evidence.SHA256
        })
    }
    return [object[]]$debris.ToArray()
}

function Invoke-ExactPublicationDebrisRecovery {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Debris,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ExpectedRootIdentity,
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.SafeHandles.SafeFileHandle]$RootLease,
        [Parameter(Mandatory = $true)][string]$ExpectedRootFileId
    )

    foreach ($entry in $Debris) {
        Assert-PublicationRootIdentity -Root $Root `
            -ExpectedIdentity $ExpectedRootIdentity -Lease $RootLease `
            -ExpectedFileId $ExpectedRootFileId -Phase 'during stale-debris recovery'
        if (-not (Test-PathEqual (Split-Path -Parent $entry.Path) $Root)) {
            throw "Refusing to remove publication debris outside '$Root': '$($entry.Path)'."
        }
        Assert-NoPathAlias -Path $entry.Path -Label 'Publication debris'
        if (-not (Test-Path -LiteralPath $entry.Path -PathType Leaf)) {
            throw "Publication debris changed before recovery: '$($entry.Path)'."
        }
        $currentEvidence = Get-PublicationFileEvidence -Path $entry.Path `
            -Label 'Publication debris'
        if ($currentEvidence.Length -ne $entry.Length -or
                $currentEvidence.SHA256 -cne $entry.SHA256) {
            throw "Publication debris changed before recovery: '$($entry.Path)'."
        }
        [IO.File]::Delete($entry.Path)
    }
}

function Get-DirectoryEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Version
    )

    $root = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $files = @(Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction Stop |
        Sort-Object FullName)
    if ($files.Count -eq 0) {
        throw "Toolchain directory '$root' is empty."
    }
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
    try {
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($root.Length).TrimStart('\') -replace '\\', '/'
            $fileHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            $recordStream = [IO.MemoryStream]::new()
            $recordWriter = [IO.BinaryWriter]::new($recordStream, $strictUtf8, $true)
            try {
                # BinaryWriter length-prefixes each UTF-8 string; the fixed-width Int64
                # keeps distinct path/length/hash tuples from sharing one byte stream.
                $recordWriter.Write([string]$relative)
                $recordWriter.Write([long]$file.Length)
                $recordWriter.Write([string]$fileHash)
                $recordWriter.Flush()
                $bytes = $recordStream.ToArray()
            }
            finally {
                $recordWriter.Dispose()
                $recordStream.Dispose()
            }
            [void]$sha256.TransformBlock($bytes, 0, $bytes.Length, $bytes, 0)
        }
        [void]$sha256.TransformFinalBlock([byte[]]::new(0), 0, 0)
        $digest = ([BitConverter]::ToString($sha256.Hash)).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    return [ordered]@{
        RelativePath = $RelativePath
        Version      = $Version
        FileCount    = [int]$files.Count
        SHA256       = $digest
    }
}

function Assert-EvidenceEqual {
    param(
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $expectedJson = ConvertTo-Json -InputObject $Expected -Depth 20 -Compress
    $actualJson = ConvertTo-Json -InputObject $Actual -Depth 20 -Compress
    if ($expectedJson -cne $actualJson) {
        throw "$Label changed while native artifacts were being produced."
    }
}

function Test-FilesByteEqual {
    param(
        [Parameter(Mandatory = $true)][string]$First,
        [Parameter(Mandatory = $true)][string]$Second
    )

    $firstInfo = Get-Item -LiteralPath $First
    $secondInfo = Get-Item -LiteralPath $Second
    if ($firstInfo.Length -ne $secondInfo.Length) {
        return $false
    }
    $left = [IO.File]::OpenRead($firstInfo.FullName)
    $right = [IO.File]::OpenRead($secondInfo.FullName)
    try {
        $leftBuffer = [byte[]]::new(1MB)
        $rightBuffer = [byte[]]::new(1MB)
        while ($true) {
            $leftRead = $left.Read($leftBuffer, 0, $leftBuffer.Length)
            $rightRead = $right.Read($rightBuffer, 0, $rightBuffer.Length)
            if ($leftRead -ne $rightRead) {
                return $false
            }
            if ($leftRead -eq 0) {
                return $true
            }
            for ($index = 0; $index -lt $leftRead; $index++) {
                if ($leftBuffer[$index] -ne $rightBuffer[$index]) {
                    return $false
                }
            }
        }
    }
    finally {
        $left.Dispose()
        $right.Dispose()
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
$sourceRoot = Join-Path $repoRoot 'tools\native\Atlas.ElevationBootstrap'
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$canonicalOutputRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot `
    'playbook\Executables\AtlasModules\Tools'))
Assert-NoPathAlias -Path $outputRoot -Label 'The output directory'
if (Test-Path -LiteralPath $outputRoot) {
    if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
        throw "The output path is not a directory: '$outputRoot'."
    }
}
else {
    New-Item -Path $outputRoot -ItemType Directory -Force | Out-Null
}
$outputIdentity = Get-FinalPathIdentity -Path $outputRoot
$outputRoot = [IO.Path]::GetFullPath((ConvertFrom-FinalPathIdentity `
    -Identity $outputIdentity))
Assert-NoPathAlias -Path $outputRoot -Label 'The normalized output directory'
if (-not [string]::Equals((Get-FinalPathIdentity -Path $outputRoot), $outputIdentity,
        [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The normalized output directory does not retain its filesystem identity.'
}
$canonicalOutputIdentity = Get-FinalPathIdentity -Path $canonicalOutputRoot
$isCanonicalOutput = [string]::Equals($outputIdentity, $canonicalOutputIdentity,
    [StringComparison]::OrdinalIgnoreCase)
if ($Architecture -ne 'all' -and $isCanonicalOutput) {
    throw 'A partial architecture build cannot write into the canonical playbook payload directory.'
}
if ($isCanonicalOutput -and -not $RunContractHarness) {
    throw 'The canonical playbook payload build requires -RunContractHarness.'
}
$expectedHashManifestPath = [IO.Path]::GetFullPath((Join-Path $outputRoot `
    'Atlas-ElevationBootstrapHashes.psd1'))
$requestedHashManifestPath = if ($HashManifestPath) {
    [IO.Path]::GetFullPath($HashManifestPath)
} else {
    $expectedHashManifestPath
}
if (-not (Test-PathEqual $requestedHashManifestPath $expectedHashManifestPath) -or
        -not (Test-PathEqual (Split-Path -Parent $requestedHashManifestPath) $outputRoot)) {
    throw 'The hash manifest must use the exact canonical filename directly below the output directory.'
}
$resolvedHashManifestPath = $expectedHashManifestPath
if ($Architecture -ne 'all' -and $PSBoundParameters.ContainsKey('HashManifestPath')) {
    throw 'A partial architecture build cannot produce or replace a hash manifest.'
}
if ($Architecture -ne 'all' -and
        (Test-Path -LiteralPath $resolvedHashManifestPath)) {
    throw 'A partial architecture build cannot write beside an existing complete-build hash manifest.'
}
if (Test-Path -LiteralPath $resolvedHashManifestPath) {
    Assert-NoPathAlias -Path $resolvedHashManifestPath -Label 'The hash-manifest destination'
    if (-not (Test-Path -LiteralPath $resolvedHashManifestPath -PathType Leaf)) {
        throw "The hash-manifest destination collides with a non-file path: '$resolvedHashManifestPath'."
    }
}

$clangPath = if ($LlvmRoot) {
    Resolve-Executable -Name 'clang-cl.exe' -ExplicitPath (Join-Path $LlvmRoot 'bin\clang-cl.exe')
} else {
    Resolve-Executable -Name 'clang-cl.exe'
}
$lldPath = if ($LlvmRoot) {
    Resolve-Executable -Name 'lld-link.exe' -ExplicitPath (Join-Path $LlvmRoot 'bin\lld-link.exe')
} else {
    Resolve-Executable -Name 'lld-link.exe'
}
$clangBinRoot = Split-Path -Parent $clangPath
$lldBinRoot = Split-Path -Parent $lldPath
if (-not (Test-PathEqual $clangBinRoot $lldBinRoot) -or
        (Split-Path -Leaf $clangBinRoot) -cne 'bin') {
    throw 'clang-cl.exe and lld-link.exe must come from the same LLVM bin directory.'
}
$resolvedLlvmRoot = Split-Path -Parent $clangBinRoot
if ($LlvmRoot -and -not (Test-PathEqual $resolvedLlvmRoot $LlvmRoot)) {
    throw "The resolved LLVM tools do not belong to the requested LLVM root '$LlvmRoot'."
}
$clangResourceVersion = '22'
$clangVersionRoot = Get-Item -LiteralPath `
    (Join-Path $resolvedLlvmRoot "lib\clang\$clangResourceVersion") -ErrorAction Stop
if (-not $clangVersionRoot.PSIsContainer -or
        -not (Test-Path -LiteralPath (Join-Path $clangVersionRoot.FullName 'include') `
            -PathType Container)) {
    throw "Unable to locate the pinned Clang builtin headers below '$resolvedLlvmRoot'."
}

$programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
$vswhere = Join-Path $programFilesX86 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) {
    throw "Visual Studio discovery tool not found at '$vswhere'."
}
$vswhereResult = Invoke-NativeTool -Tool $vswhere -Arguments @(
    '-latest', '-products', '*', '-requires',
    'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', '-property', 'installationPath'
) -Label 'Visual Studio discovery'
$visualStudioRoot = $vswhereResult.Output |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -First 1
if (-not $visualStudioRoot) {
    throw 'A Visual Studio C++ header toolset is required.'
}
$msvcVersion = '14.51.36231'
$msvcRoot = Get-Item -LiteralPath `
    (Join-Path $visualStudioRoot "VC\Tools\MSVC\$msvcVersion") -ErrorAction Stop
if (-not $msvcRoot.PSIsContainer) {
    throw "Unable to locate the pinned MSVC toolset '$msvcVersion'."
}
$msvcCompilerPath = Resolve-Executable -Name 'cl.exe' -ExplicitPath `
    (Join-Path $msvcRoot.FullName 'bin\Hostx64\x64\cl.exe')

$kitsRegistry = Get-ItemProperty -LiteralPath `
    'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots'
$sdkRoot = $kitsRegistry.KitsRoot10
$sdkVersion = '10.0.26100.0'
$sdkIncludeRoot = Join-Path $sdkRoot "Include\$sdkVersion"
$sdkLibraryRoot = Join-Path $sdkRoot "Lib\$sdkVersion"
if (-not (Test-Path -LiteralPath $sdkIncludeRoot -PathType Container) -or
        -not (Test-Path -LiteralPath $sdkLibraryRoot -PathType Container)) {
    throw "Unable to locate the pinned Windows SDK '$sdkVersion'."
}
$rcPath = Resolve-Executable -Name 'rc.exe' -ExplicitPath `
    (Join-Path $sdkRoot "bin\$sdkVersion\x64\rc.exe")
$resourceCompilerDependencyNames = @('RCDLL.dll', 'ServicingCommon.dll')
$resourceCompilerDependencyPaths = [ordered]@{}
foreach ($dependencyName in $resourceCompilerDependencyNames) {
    $resourceCompilerDependencyPaths[$dependencyName] = Join-Path `
        (Split-Path -Parent $rcPath) $dependencyName
}
$clearedEnvironmentNames = @(
        'CL', '_CL_', 'LINK', 'RC', 'INCLUDE', 'LIB', 'LIBPATH', 'CPATH',
        'C_INCLUDE_PATH', 'CPLUS_INCLUDE_PATH', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS',
        'SDKROOT', 'CCC_OVERRIDE_OPTIONS'
)
$processEnvironment = [Environment]::GetEnvironmentVariables('Process')
$environmentSnapshot = [ordered]@{}
foreach ($name in $clearedEnvironmentNames) {
    $environmentSnapshot[$name] = [pscustomobject]@{
        Present = $processEnvironment.Contains($name)
        Value   = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
}

$targets = [ordered]@{
    amd64 = [ordered]@{
        Triple  = 'x86_64-pc-windows-msvc'
        Machine = 'X64'
        MachineCode = 0x8664
        LibArch = 'x64'
        Output  = 'AtlasElevationBootstrap-amd64.exe'
    }
    arm64 = [ordered]@{
        Triple  = 'arm64-pc-windows-msvc'
        Machine = 'ARM64'
        MachineCode = 0xAA64
        LibArch = 'arm64'
        Output  = 'AtlasElevationBootstrap-arm64.exe'
    }
}
$selectedTargets = if ($Architecture -eq 'all') {
    @('amd64', 'arm64')
} else {
    @($Architecture)
}
if ($Architecture -eq 'all' -and -not $RunContractHarness) {
    throw 'A complete architecture build requires -RunContractHarness so schema-v3 evidence is valid.'
}

$hostArchitecture = [string][Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$hostTarget = switch ($hostArchitecture) {
    'X64' { 'amd64' }
    'Arm64' { 'arm64' }
    default { throw "The native contract harness requires a 64-bit x64 or ARM64 PowerShell host; found '$hostArchitecture'." }
}
$harnessTimeoutMilliseconds = 30000
if ($RunContractHarness -and $hostTarget -notin $selectedTargets) {
    throw "The requested architecture set does not contain the host-runnable '$hostTarget' contract harness."
}
$expectedLibraryNames = @(
    'BufferOverflowU.lib', 'kernel32.lib', 'advapi32.lib', 'bcrypt.lib', 'shell32.lib'
)
$libraryPaths = [ordered]@{}
foreach ($targetName in @('amd64', 'arm64')) {
    $architectureLibraries = [ordered]@{}
    $libraryRoot = Join-Path $sdkLibraryRoot "um\$($targets[$targetName].LibArch)"
    foreach ($libraryName in $expectedLibraryNames) {
        $architectureLibraries[$libraryName] = Join-Path $libraryRoot $libraryName
    }
    $libraryPaths[$targetName] = $architectureLibraries
}

function Get-CurrentToolchainEvidence {
    $clangVersion = Get-NativeToolVersion -Tool $clangPath -Arguments @('--version') `
        -Label 'clang-cl'
    $lldVersion = Get-NativeToolVersion -Tool $lldPath -Arguments @('--version') `
        -Label 'lld-link'
    if ($clangVersion -notmatch '(?<!\d)22\.1\.8(?!\d)' -or
            $lldVersion -notmatch '(?<!\d)22\.1\.8(?!\d)') {
        throw 'The elevation bootstrap requires clang-cl and lld-link 22.1.8.'
    }
    $clVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($msvcCompilerPath).ProductVersion
    $resourceCompilerVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($rcPath).ProductVersion
    $resourceCompilerDependencies = [ordered]@{}
    foreach ($dependencyName in $resourceCompilerDependencyNames) {
        $resourceCompilerDependencies[$dependencyName] = Get-FileEvidence `
            -Path $resourceCompilerDependencyPaths[$dependencyName]
    }
    $libraries = [ordered]@{}
    foreach ($targetName in @('amd64', 'arm64')) {
        $architectureLibraries = [ordered]@{}
        foreach ($libraryName in $expectedLibraryNames) {
            $architectureLibraries[$libraryName] = Get-FileEvidence `
                -Path $libraryPaths[$targetName][$libraryName]
        }
        $libraries[$targetName] = $architectureLibraries
    }
    $includeDirectories = [ordered]@{
        Msvc = Get-DirectoryEvidence -Path (Join-Path $msvcRoot.FullName 'include') `
            -RelativePath "VC/Tools/MSVC/$msvcVersion/include" -Version $msvcVersion
        WindowsSdkUcrt = Get-DirectoryEvidence `
            -Path (Join-Path $sdkIncludeRoot 'ucrt') `
            -RelativePath "Include/$sdkVersion/ucrt" -Version $sdkVersion
        WindowsSdkShared = Get-DirectoryEvidence `
            -Path (Join-Path $sdkIncludeRoot 'shared') `
            -RelativePath "Include/$sdkVersion/shared" -Version $sdkVersion
        WindowsSdkUm = Get-DirectoryEvidence `
            -Path (Join-Path $sdkIncludeRoot 'um') `
            -RelativePath "Include/$sdkVersion/um" -Version $sdkVersion
    }
    return [ordered]@{
        ClangCl               = Get-FileEvidence -Path $clangPath -Version $clangVersion
        LldLink               = Get-FileEvidence -Path $lldPath -Version $lldVersion
        ClangResourceDirectory = Get-DirectoryEvidence `
            -Path (Join-Path $clangVersionRoot.FullName 'include') `
            -RelativePath 'lib/clang/22/include' -Version $clangResourceVersion
        MsvcCompiler          = Get-FileEvidence -Path $msvcCompilerPath -Version $clVersion
        MsvcTools             = $msvcVersion
        WindowsSdk            = $sdkVersion
        IncludeDirectories    = $includeDirectories
        ResourceCompiler      = Get-FileEvidence -Path $rcPath -Version $resourceCompilerVersion
        ResourceCompilerDependencies = $resourceCompilerDependencies
        Libraries             = $libraries
    }
}

$toolchainEvidence = $null
$publicationNames = @($selectedTargets | ForEach-Object { $targets[$_].Output })
if ($Architecture -eq 'all') {
    $publicationNames += 'Atlas-ElevationBootstrapHashes.psd1'
}
if (@($publicationNames | Sort-Object -Unique).Count -ne $publicationNames.Count) {
    throw 'The requested publication set contains a path collision.'
}
foreach ($publicationName in $publicationNames) {
    $destination = Join-Path $outputRoot $publicationName
    if (Test-Path -LiteralPath $destination) {
        Assert-NoPathAlias -Path $destination -Label 'A publication destination'
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "A publication destination collides with a non-file path: '$destination'."
        }
    }
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$buildRoot = Join-Path $tempBase ("AtlasElevationBootstrap-{0}" -f [guid]::NewGuid().ToString('N'))
$buildRoot = [IO.Path]::GetFullPath($buildRoot)
$tempPrefix = $tempBase.TrimEnd('\') + '\'
if (-not $buildRoot.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to create a build root outside '$tempBase'."
}
$snapshotRoot = Join-Path $buildRoot 'snapshot'
$snapshotNativeRoot = Join-Path $snapshotRoot 'native'
$snapshotBuildPath = Join-Path $snapshotRoot 'Build-AtlasElevationBootstrap.ps1'
$snapshotVerifierPath = Join-Path $snapshotRoot 'Test-AtlasElevationBootstrap.ps1'
$liveInputs = [ordered]@{
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.cpp' =
        (Join-Path $sourceRoot 'Atlas.ElevationBootstrap.cpp')
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.rc' =
        (Join-Path $sourceRoot 'Atlas.ElevationBootstrap.rc')
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.manifest' =
        (Join-Path $sourceRoot 'Atlas.ElevationBootstrap.manifest')
    'tools/native/Atlas.ElevationBootstrap/resource.h' =
        (Join-Path $sourceRoot 'resource.h')
    'tools/build/Build-AtlasElevationBootstrap.ps1' = $PSCommandPath
    'tools/build/Test-AtlasElevationBootstrap.ps1' =
        (Join-Path $repoRoot 'tools\build\Test-AtlasElevationBootstrap.ps1')
}
$snapshotInputs = [ordered]@{
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.cpp' =
        (Join-Path $snapshotNativeRoot 'Atlas.ElevationBootstrap.cpp')
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.rc' =
        (Join-Path $snapshotNativeRoot 'Atlas.ElevationBootstrap.rc')
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.manifest' =
        (Join-Path $snapshotNativeRoot 'Atlas.ElevationBootstrap.manifest')
    'tools/native/Atlas.ElevationBootstrap/resource.h' =
        (Join-Path $snapshotNativeRoot 'resource.h')
    'tools/build/Build-AtlasElevationBootstrap.ps1' = $snapshotBuildPath
    'tools/build/Test-AtlasElevationBootstrap.ps1' = $snapshotVerifierPath
}

function Invoke-OneBuild {
    param(
        [Parameter(Mandatory = $true)][string]$BuildName,
        [Parameter(Mandatory = $true)][string]$TargetName
    )

    $target = $targets[$TargetName]
    $root = Join-Path $buildRoot $BuildName
    $copiedSource = Join-Path $root 'source'
    $artifacts = Join-Path $root $TargetName
    New-Item -Path $copiedSource -ItemType Directory -Force | Out-Null
    New-Item -Path $artifacts -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $snapshotNativeRoot 'Atlas.ElevationBootstrap.cpp') `
        -Destination $copiedSource
    Copy-Item -LiteralPath (Join-Path $snapshotNativeRoot 'Atlas.ElevationBootstrap.rc') `
        -Destination $copiedSource
    Copy-Item -LiteralPath (Join-Path $snapshotNativeRoot 'Atlas.ElevationBootstrap.manifest') `
        -Destination $copiedSource
    Copy-Item -LiteralPath (Join-Path $snapshotNativeRoot 'resource.h') -Destination $copiedSource

    $resourcePath = Join-Path $artifacts 'Atlas.ElevationBootstrap.res'
    Push-Location $copiedSource
    try {
        $resourceArguments = @(
            '/nologo', '/r', '/8', '/x',
            '/i', $copiedSource,
            '/i', (Join-Path $msvcRoot.FullName 'include'),
            '/i', (Join-Path $sdkRoot "Include\$sdkVersion\ucrt"),
            '/i', (Join-Path $sdkRoot "Include\$sdkVersion\shared"),
            '/i', (Join-Path $sdkRoot "Include\$sdkVersion\um"),
            "/fo$resourcePath",
            'Atlas.ElevationBootstrap.rc'
        )
        Invoke-NativeTool -Tool $rcPath -Arguments $resourceArguments `
            -Label "Resource build ($BuildName/$TargetName)" | Out-Null
    }
    finally {
        Pop-Location
    }

    $objectPath = Join-Path $artifacts 'Atlas.ElevationBootstrap.obj'
    $includeArguments = @(
        '/imsvc', (Join-Path $clangVersionRoot.FullName 'include'),
        '/imsvc', (Join-Path $msvcRoot.FullName 'include'),
        '/imsvc', (Join-Path $sdkRoot "Include\$sdkVersion\ucrt"),
        '/imsvc', (Join-Path $sdkRoot "Include\$sdkVersion\shared"),
        '/imsvc', (Join-Path $sdkRoot "Include\$sdkVersion\um")
    )
    $compileArguments = @(
        "--target=$($target.Triple)", '--no-default-config',
        '/nologo', '/c', '/TP', '/std:c++20',
        '/O2', '/Oi', '/GS', '/guard:cf', '/Gw', '/Gy', '/Brepro', '/Zl',
        '/EHs-c-', '/GR-', '/permissive-', '/volatile:iso', '/Zc:wchar_t',
        '/Zc:strictStrings', '/Zc:threadSafeInit-', '/Zc:alignedNew-',
        '/Zc:sizedDealloc-', '/W4', '/WX', '/utf-8', '/X', '/DUNICODE',
        '/D_UNICODE', '/DSTRICT', '/DWINVER=0x0A00', '/D_WIN32_WINNT=0x0A00',
        '/clang:-fno-builtin-memset', '/clang:-fno-builtin-memcpy',
        '/clang:-fno-builtin-wcslen',
        "/clang:-fms-compatibility-version=$([Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $msvcRoot.FullName 'bin\Hostx64\x64\cl.exe')).ProductVersion)",
        "/clang:-ffile-prefix-map=$copiedSource=.",
        "/clang:-fmacro-prefix-map=$copiedSource=.",
        '/clang:-fdebug-compilation-dir=.',
        "/Fo$objectPath"
    ) + $includeArguments + @(Join-Path $copiedSource 'Atlas.ElevationBootstrap.cpp')
    Invoke-NativeTool -Tool $clangPath -Arguments $compileArguments `
        -Label "C++ build ($BuildName/$TargetName)" | Out-Null

    $executablePath = Join-Path $artifacts $target.Output
    $umLibraryRoot = Join-Path $sdkRoot "Lib\$sdkVersion\um\$($target.LibArch)"
    $linkArguments = @(
        '/nologo', '/lldignoreenv', "/machine:$($target.Machine)",
        '/subsystem:windows,10.00',
        '/entry:wWinMainCRTStartup', '/nodefaultlib', '/incremental:no', '/opt:ref',
        '/opt:icf', '/dynamicbase', '/nxcompat', '/highentropyva', '/guard:cf',
        '/cetcompat', '/dependentloadflag:0x800', '/largeaddressaware', '/fixed:no',
        '/release', '/brepro', '/manifest:no', '/stack:1048576,4096',
        "/out:$executablePath", $objectPath, $resourcePath,
        (Join-Path $umLibraryRoot 'BufferOverflowU.lib'),
        (Join-Path $umLibraryRoot 'kernel32.lib'),
        (Join-Path $umLibraryRoot 'advapi32.lib'),
        (Join-Path $umLibraryRoot 'bcrypt.lib'),
        (Join-Path $umLibraryRoot 'shell32.lib')
    )
    Invoke-NativeTool -Tool $lldPath -Arguments $linkArguments `
        -Label "PE link ($BuildName/$TargetName)" | Out-Null

    $harnessObjectPath = $null
    $harnessExecutablePath = $null
    if ($RunContractHarness) {
        $harnessObjectPath = Join-Path $artifacts 'Atlas.ElevationBootstrap.Harness.obj'
        $harnessCompileArguments = @(
            "--target=$($target.Triple)", '--no-default-config',
            '/nologo', '/c', '/TP', '/std:c++20',
            '/O2', '/Oi', '/GS', '/guard:cf', '/Gw', '/Gy', '/Brepro', '/Zl',
            '/EHs-c-', '/GR-', '/permissive-', '/volatile:iso', '/Zc:wchar_t',
            '/Zc:strictStrings', '/Zc:threadSafeInit-', '/Zc:alignedNew-',
            '/Zc:sizedDealloc-', '/W4', '/WX', '/utf-8', '/X', '/DUNICODE',
            '/D_UNICODE', '/DSTRICT', '/DWINVER=0x0A00', '/D_WIN32_WINNT=0x0A00',
            '/DATLAS_BOOTSTRAP_CONTRACT_HARNESS=1',
            '/clang:-fno-builtin-memset', '/clang:-fno-builtin-memcpy',
            '/clang:-fno-builtin-wcslen',
            "/clang:-fms-compatibility-version=$([Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $msvcRoot.FullName 'bin\Hostx64\x64\cl.exe')).ProductVersion)",
            "/clang:-ffile-prefix-map=$copiedSource=.",
            "/clang:-fmacro-prefix-map=$copiedSource=.",
            '/clang:-fdebug-compilation-dir=.',
            "/Fo$harnessObjectPath"
        ) + $includeArguments + @(Join-Path $copiedSource 'Atlas.ElevationBootstrap.cpp')
        Invoke-NativeTool -Tool $clangPath -Arguments $harnessCompileArguments `
            -Label "Contract-harness C++ build ($BuildName/$TargetName)" | Out-Null

        $harnessExecutablePath = Join-Path $artifacts 'AtlasElevationBootstrap-Harness.exe'
        $harnessLinkArguments = @(
            '/nologo', '/lldignoreenv', "/machine:$($target.Machine)",
            '/subsystem:windows,10.00',
            '/entry:wWinMainCRTStartup', '/nodefaultlib', '/incremental:no', '/opt:ref',
            '/opt:icf', '/dynamicbase', '/nxcompat', '/highentropyva', '/guard:cf',
            '/cetcompat', '/dependentloadflag:0x800', '/largeaddressaware', '/fixed:no',
            '/release', '/brepro', '/manifest:no', '/stack:1048576,4096',
            "/out:$harnessExecutablePath", $harnessObjectPath,
            (Join-Path $umLibraryRoot 'BufferOverflowU.lib'),
            (Join-Path $umLibraryRoot 'kernel32.lib'),
            (Join-Path $umLibraryRoot 'advapi32.lib'),
            (Join-Path $umLibraryRoot 'bcrypt.lib'),
            (Join-Path $umLibraryRoot 'shell32.lib')
        )
        Invoke-NativeTool -Tool $lldPath -Arguments $harnessLinkArguments `
            -Label "Contract-harness PE link ($BuildName/$TargetName)" | Out-Null
    }
    return [pscustomobject]@{
        Executable        = $executablePath
        Object            = $objectPath
        Resource          = $resourcePath
        HarnessExecutable = $harnessExecutablePath
        HarnessObject     = $harnessObjectPath
    }
}

function Invoke-AtlasContractHarness {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TargetName
    )

    $process = $null
    try {
        $process = Start-Process -FilePath $Path -ArgumentList '--self-test' `
            -PassThru -WindowStyle Hidden
        if (-not $process.WaitForExit($harnessTimeoutMilliseconds)) {
            try {
                # Build tooling runs under PowerShell 7/.NET, whose tree-aware overload
                # prevents a failed harness from leaving any test worker behind.
                $process.Kill($true)
            }
            catch [InvalidOperationException] {
                if (-not $process.HasExited) {
                    throw
                }
            }
            if (-not $process.WaitForExit(10000)) {
                throw "The native contract harness for '$TargetName' timed out and could not be reaped."
            }
            throw "The native contract harness for '$TargetName' exceeded $harnessTimeoutMilliseconds milliseconds."
        }
        if ($process.ExitCode -ne 0) {
            throw "Native contract harness failed for $TargetName with exit code $($process.ExitCode)."
        }
    }
    finally {
        if ($null -ne $process) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill($true)
                    if (-not $process.WaitForExit(10000)) {
                        throw "The native contract harness for '$TargetName' could not be reaped."
                    }
                }
            }
            finally {
                $process.Dispose()
            }
        }
    }
}

function ConvertTo-Psd1QuotedString {
    param([Parameter(Mandatory = $true)][string]$Value)
    return "'$($Value.Replace("'", "''"))'"
}

function Write-AtlasBootstrapHashManifest {
    param(
        [Parameter(Mandatory = $true)][object[]]$BuildResults,
        [Parameter(Mandatory = $true)][string[]]$ExecutedArchitectures,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $lines = New-Object 'Collections.Generic.List[string]'
    $lines.Add('@{')
    $lines.Add('    SchemaVersion = 3')
    $lines.Add("    Source        = 'tools/native/Atlas.ElevationBootstrap'")
    $lines.Add('    Build         = @{')
    $lines.Add("        Runtime         = 'none'")
    $lines.Add("        Reproducibility = 'Two independent unsigned builds compared byte-for-byte per architecture'")
    $lines.Add('    }')

    $lines.Add('    Toolchain     = @{')
    foreach ($toolName in @('ClangCl', 'LldLink')) {
        $tool = $toolchainEvidence[$toolName]
        $lines.Add("        $toolName = @{")
        $lines.Add(('            FileName = {0}' -f (ConvertTo-Psd1QuotedString $tool.FileName)))
        $lines.Add(('            Length   = {0}' -f $tool.Length))
        $lines.Add(('            SHA256   = {0}' -f (ConvertTo-Psd1QuotedString $tool.SHA256)))
        $lines.Add(('            Version  = {0}' -f (ConvertTo-Psd1QuotedString $tool.Version)))
        $lines.Add('        }')
    }
    $clangResources = $toolchainEvidence.ClangResourceDirectory
    $lines.Add('        ClangResourceDirectory = @{')
    $lines.Add(('            RelativePath = {0}' -f `
        (ConvertTo-Psd1QuotedString $clangResources.RelativePath)))
    $lines.Add(('            Version      = {0}' -f `
        (ConvertTo-Psd1QuotedString $clangResources.Version)))
    $lines.Add(('            FileCount    = {0}' -f $clangResources.FileCount))
    $lines.Add(('            SHA256       = {0}' -f `
        (ConvertTo-Psd1QuotedString $clangResources.SHA256)))
    $lines.Add('        }')
    $msvcCompiler = $toolchainEvidence.MsvcCompiler
    $lines.Add('        MsvcCompiler = @{')
    $lines.Add(('            FileName = {0}' -f `
        (ConvertTo-Psd1QuotedString $msvcCompiler.FileName)))
    $lines.Add(('            Length   = {0}' -f $msvcCompiler.Length))
    $lines.Add(('            SHA256   = {0}' -f `
        (ConvertTo-Psd1QuotedString $msvcCompiler.SHA256)))
    $lines.Add(('            Version  = {0}' -f `
        (ConvertTo-Psd1QuotedString $msvcCompiler.Version)))
    $lines.Add('        }')
    $lines.Add(('        MsvcTools  = {0}' -f `
        (ConvertTo-Psd1QuotedString $toolchainEvidence.MsvcTools)))
    $lines.Add(('        WindowsSdk = {0}' -f `
        (ConvertTo-Psd1QuotedString $toolchainEvidence.WindowsSdk)))
    $lines.Add('        IncludeDirectories = @{')
    foreach ($includeName in @(
            'Msvc', 'WindowsSdkUcrt', 'WindowsSdkShared', 'WindowsSdkUm'
        )) {
        $include = $toolchainEvidence.IncludeDirectories[$includeName]
        $lines.Add("            $includeName = @{")
        $lines.Add(('                RelativePath = {0}' -f `
            (ConvertTo-Psd1QuotedString $include.RelativePath)))
        $lines.Add(('                Version      = {0}' -f `
            (ConvertTo-Psd1QuotedString $include.Version)))
        $lines.Add(('                FileCount    = {0}' -f $include.FileCount))
        $lines.Add(('                SHA256       = {0}' -f `
            (ConvertTo-Psd1QuotedString $include.SHA256)))
        $lines.Add('            }')
    }
    $lines.Add('        }')
    $resourceCompiler = $toolchainEvidence.ResourceCompiler
    $lines.Add('        ResourceCompiler = @{')
    $lines.Add(('            FileName = {0}' -f `
        (ConvertTo-Psd1QuotedString $resourceCompiler.FileName)))
    $lines.Add(('            Length   = {0}' -f $resourceCompiler.Length))
    $lines.Add(('            SHA256   = {0}' -f `
        (ConvertTo-Psd1QuotedString $resourceCompiler.SHA256)))
    $lines.Add(('            Version  = {0}' -f `
        (ConvertTo-Psd1QuotedString $resourceCompiler.Version)))
    $lines.Add('        }')
    $lines.Add('        ResourceCompilerDependencies = @{')
    foreach ($dependencyName in $resourceCompilerDependencyNames) {
        $dependency = $toolchainEvidence.ResourceCompilerDependencies[$dependencyName]
        $lines.Add(('            {0} = @{{' -f `
            (ConvertTo-Psd1QuotedString $dependencyName)))
        $lines.Add(('                FileName = {0}' -f `
            (ConvertTo-Psd1QuotedString $dependency.FileName)))
        $lines.Add(('                Length   = {0}' -f $dependency.Length))
        $lines.Add(('                SHA256   = {0}' -f `
            (ConvertTo-Psd1QuotedString $dependency.SHA256)))
        $lines.Add('            }')
    }
    $lines.Add('        }')
    $lines.Add('        Libraries = @{')
    foreach ($targetName in @('amd64', 'arm64')) {
        $lines.Add("            $targetName = @{")
        foreach ($libraryName in $expectedLibraryNames) {
            $library = $toolchainEvidence.Libraries[$targetName][$libraryName]
            $lines.Add(('                {0} = @{{' -f `
                (ConvertTo-Psd1QuotedString $libraryName)))
            $lines.Add(('                    FileName = {0}' -f `
                (ConvertTo-Psd1QuotedString $library.FileName)))
            $lines.Add(('                    Length   = {0}' -f $library.Length))
            $lines.Add(('                    SHA256   = {0}' -f `
                (ConvertTo-Psd1QuotedString $library.SHA256)))
            $lines.Add('                }')
        }
        $lines.Add('            }')
    }
    $lines.Add('        }')
    $lines.Add('    }')

    $lines.Add('    Harness       = @{')
    $lines.Add('        Requested             = $true')
    $lines.Add('        BuiltArchitectures    = @(')
    $lines.Add("            'amd64'")
    $lines.Add("            'arm64'")
    $lines.Add('        )')
    $lines.Add(('        HostArchitecture      = {0}' -f `
        (ConvertTo-Psd1QuotedString $hostTarget)))
    $lines.Add('        ExecutedArchitectures = @(')
    foreach ($executedArchitecture in $ExecutedArchitectures) {
        $lines.Add(('            {0}' -f `
            (ConvertTo-Psd1QuotedString $executedArchitecture)))
    }
    $lines.Add('        )')
    $lines.Add('        Passed                = $true')
    $lines.Add(('        TimeoutMilliseconds   = {0}' -f $harnessTimeoutMilliseconds))
    $lines.Add('    }')

    $lines.Add('    Inputs        = @{')
    foreach ($relativePath in $snapshotInputs.Keys) {
        $item = Get-Item -LiteralPath $snapshotInputs[$relativePath]
        $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        $lines.Add(('        {0} = @{{' -f (ConvertTo-Psd1QuotedString $relativePath)))
        $lines.Add(('            Length = {0}' -f $item.Length))
        $lines.Add(('            SHA256 = {0}' -f (ConvertTo-Psd1QuotedString $hash)))
        $lines.Add('        }')
    }
    $lines.Add('    }')
    $lines.Add('    Artifacts     = @{')
    foreach ($targetName in @('amd64', 'arm64')) {
        $result = $BuildResults | Where-Object TargetName -eq $targetName | Select-Object -First 1
        if (-not $result) {
            throw "Missing build evidence for $targetName."
        }
        $outputName = $targets[$targetName].Output
        $lines.Add(('        {0} = @{{' -f (ConvertTo-Psd1QuotedString $outputName)))
        $lines.Add(('            Architecture = {0}' -f `
            (ConvertTo-Psd1QuotedString $targetName)))
        $lines.Add(('            Machine      = 0x{0:X4}' -f $targets[$targetName].MachineCode))
        $lines.Add(('            Length       = {0}' -f $result.Length))
        $lines.Add(('            SHA256       = {0}' -f `
            (ConvertTo-Psd1QuotedString $result.SHA256)))
        $lines.Add('        }')
    }
    $lines.Add('    }')
    $lines.Add('}')

    $manifestDirectory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $manifestDirectory -PathType Container)) {
        New-Item -Path $manifestDirectory -ItemType Directory -Force | Out-Null
    }
    $temporaryPath = Join-Path $manifestDirectory `
        ('.Atlas-ElevationBootstrapHashes.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    try {
        $utf8NoBom = New-Object Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($temporaryPath, (($lines -join "`n") + "`n"), $utf8NoBom)
        [IO.File]::Move($temporaryPath, $Path)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Assert-LiveBuildInputsUnchanged {
    param([Parameter(Mandatory = $true)][string]$Phase)

    foreach ($relativePath in $liveInputs.Keys) {
        if (-not (Test-FilesByteEqual -First $liveInputs[$relativePath] `
                -Second $snapshotInputs[$relativePath])) {
            throw "Build input changed ${Phase}: '$relativePath'."
        }
    }
}

function Publish-AtlasBootstrapFileSet {
    param(
        [Parameter(Mandatory = $true)][object[]]$Files,
        [Parameter(Mandatory = $true)][scriptblock]$BeforeCommit
    )

    $destinationNames = @($Files | ForEach-Object {
        [IO.Path]::GetFileName([string]$_.DestinationPath)
    })
    if (@($destinationNames | Sort-Object -Unique).Count -ne $destinationNames.Count) {
        throw 'The publication transaction contains duplicate destination names.'
    }
    # Exact debris from an interrupted transaction is retained until a new
    # transaction has committed and verified a coherent replacement set.
    $staleDebris = @(Get-ExactPublicationDebris -Root $outputRoot `
        -DestinationNames $destinationNames)
    $operations = New-Object 'Collections.Generic.List[object]'
    $transactionComplete = $false
    $rollbackComplete = $false
    try {
        foreach ($file in $Files) {
            $destination = [IO.Path]::GetFullPath([string]$file.DestinationPath)
            if (-not (Test-PathEqual (Split-Path -Parent $destination) $outputRoot)) {
                throw "Refusing to publish outside '$outputRoot': '$destination'."
            }
            $hadDestination = Test-Path -LiteralPath $destination
            $originalLength = $null
            $originalHash = $null
            if ($hadDestination) {
                Assert-NoPathAlias -Path $destination -Label 'A publication destination'
                if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                    throw "A publication destination is not a file: '$destination'."
                }
                $originalEvidence = Get-PublicationFileEvidence -Path $destination `
                    -Label 'A publication destination'
                $originalLength = $originalEvidence.Length
                $originalHash = $originalEvidence.SHA256
            }
            $token = [guid]::NewGuid().ToString('N')
            $temporaryPath = Join-Path $outputRoot `
                ('.{0}.{1}.publish' -f ([IO.Path]::GetFileName($destination)), $token)
            $backupPath = Join-Path $outputRoot `
                ('.{0}.{1}.backup' -f ([IO.Path]::GetFileName($destination)), $token)
            if ((Test-Path -LiteralPath $temporaryPath) -or
                    (Test-Path -LiteralPath $backupPath)) {
                throw 'A newly generated publication transaction path already exists.'
            }
            $operation = [pscustomobject]@{
                DestinationPath = $destination
                TemporaryPath   = $temporaryPath
                BackupPath      = $backupPath
                HadDestination  = $hadDestination
                OriginalLength  = $originalLength
                OriginalSHA256  = $originalHash
                ExpectedLength  = [long]$file.Length
                ExpectedSHA256  = [string]$file.SHA256
                Prepared        = $false
                Attempted       = $false
                Published       = $false
                RollbackClassified = $false
                RollbackSucceeded  = $false
                RetainRecoveryPaths = $false
            }
            # Register before Copy-Item so the finally block owns and removes a
            # partially written staging file if preparation fails.
            $operations.Add($operation)
            Copy-Item -LiteralPath $file.StagePath -Destination $temporaryPath
            $temporaryEvidence = Get-PublicationFileEvidence -Path $temporaryPath `
                -Label 'A staged publication file'
            if ($temporaryEvidence.Length -ne $operation.ExpectedLength -or
                    $temporaryEvidence.SHA256 -cne $operation.ExpectedSHA256) {
                throw "Publication staging changed '$($file.StagePath)'."
            }
            $operation.Prepared = $true
        }

        & $BeforeCommit | Out-Null

        # Preflight the whole set immediately before committing the first file.
        # The per-operation check is intentionally repeated below so changes
        # between replacements cannot silently alter a later precondition.
        Assert-PublicationRootIdentity -Root $outputRoot `
            -ExpectedIdentity $outputIdentity -Lease $outputDirectoryLease `
            -ExpectedFileId $outputDirectoryFileId `
            -Phase 'immediately before publication'
        foreach ($operation in $operations) {
            Assert-PublicationOperationPrecondition -Operation $operation `
                -Root $outputRoot -ExpectedRootIdentity $outputIdentity `
                -RootLease $outputDirectoryLease `
                -ExpectedRootFileId $outputDirectoryFileId `
                -Phase 'immediately before publication began'
        }

        foreach ($operation in $operations) {
            Assert-PublicationOperationPrecondition -Operation $operation `
                -Root $outputRoot -ExpectedRootIdentity $outputIdentity `
                -RootLease $outputDirectoryLease `
                -ExpectedRootFileId $outputDirectoryFileId `
                -Phase "immediately before publishing '$([IO.Path]::GetFileName($operation.DestinationPath))'"
            if ($operation.HadDestination) {
                $operation.Attempted = $true
                [IO.File]::Replace($operation.TemporaryPath, $operation.DestinationPath,
                    $operation.BackupPath, $true)
            }
            else {
                $operation.Attempted = $true
                [IO.File]::Move($operation.TemporaryPath, $operation.DestinationPath)
            }
            $operation.Published = $true
        }

        foreach ($operation in $operations) {
            Assert-PublicationRootIdentity -Root $outputRoot `
                -ExpectedIdentity $outputIdentity -Lease $outputDirectoryLease `
                -ExpectedFileId $outputDirectoryFileId `
                -Phase 'during final publication verification'
            Assert-NoPathAlias -Path $operation.DestinationPath `
                -Label 'A published output'
            $publishedEvidence = Get-PublicationFileEvidence `
                -Path $operation.DestinationPath -Label 'A published output'
            if ($publishedEvidence.Length -ne $operation.ExpectedLength -or
                    $publishedEvidence.SHA256 -cne $operation.ExpectedSHA256) {
                throw "Published output failed its final hash check: '$($operation.DestinationPath)'."
            }
        }
        $transactionComplete = $true
    }
    catch {
        $publicationError = $_
        $rollbackErrors = New-Object 'Collections.Generic.List[string]'
        for ($index = $operations.Count - 1; $index -ge 0; $index--) {
            $operation = $operations[$index]
            if (-not $operation.Attempted -and -not $operation.Published) {
                continue
            }
            try {
                Invoke-PublicationOperationRollback -Operation $operation `
                    -Root $outputRoot -ExpectedRootIdentity $outputIdentity `
                    -RootLease $outputDirectoryLease `
                    -ExpectedRootFileId $outputDirectoryFileId
            }
            catch {
                $rollbackErrors.Add("$($operation.DestinationPath): $($_.Exception.Message)")
            }
        }
        $rollbackComplete = $rollbackErrors.Count -eq 0
        if (-not $rollbackComplete) {
            throw "Publication failed: $($publicationError.Exception.Message) Rollback also failed: $($rollbackErrors -join '; ')"
        }
        throw $publicationError
    }
    finally {
        foreach ($operation in $operations) {
            $cleanupAllowed = $transactionComplete -or
                -not $operation.Attempted -or $operation.RollbackSucceeded
            if ($cleanupAllowed -and -not $operation.RetainRecoveryPaths -and
                    (Test-Path -LiteralPath $operation.TemporaryPath)) {
                Assert-PublicationRootIdentity -Root $outputRoot `
                    -ExpectedIdentity $outputIdentity -Lease $outputDirectoryLease `
                    -ExpectedFileId $outputDirectoryFileId `
                    -Phase 'during transaction cleanup'
                Assert-NoPathAlias -Path $operation.TemporaryPath `
                    -Label 'A transaction staging file'
                if (-not (Test-Path -LiteralPath $operation.TemporaryPath -PathType Leaf)) {
                    throw "A transaction staging path became a non-file: '$($operation.TemporaryPath)'."
                }
                [IO.File]::Delete($operation.TemporaryPath)
            }
            if ($cleanupAllowed -and -not $operation.RetainRecoveryPaths -and
                    (Test-Path -LiteralPath $operation.BackupPath)) {
                Assert-PublicationRootIdentity -Root $outputRoot `
                    -ExpectedIdentity $outputIdentity -Lease $outputDirectoryLease `
                    -ExpectedFileId $outputDirectoryFileId `
                    -Phase 'during transaction cleanup'
                Assert-NoPathAlias -Path $operation.BackupPath `
                    -Label 'A transaction backup file'
                if (-not (Test-Path -LiteralPath $operation.BackupPath -PathType Leaf)) {
                    throw "A transaction backup path became a non-file: '$($operation.BackupPath)'."
                }
                [IO.File]::Delete($operation.BackupPath)
            }
        }
    }

    if ($transactionComplete) {
        Invoke-ExactPublicationDebrisRecovery -Debris $staleDebris -Root $outputRoot `
            -ExpectedRootIdentity $outputIdentity -RootLease $outputDirectoryLease `
            -ExpectedRootFileId $outputDirectoryFileId
        $remainingDebris = @(Get-ExactPublicationDebris -Root $outputRoot `
            -DestinationNames $destinationNames)
        if ($remainingDebris.Count -ne 0) {
            throw 'Publication committed, but new transaction debris appeared during stale-debris recovery.'
        }
    }
}

$outputDirectoryLease = $null
$outputDirectoryFileId = $null
try {
    $outputDirectoryLease = [Atlas.BuildPathIdentity]::OpenDirectoryLease($outputRoot)
    $outputDirectoryFileId = [Atlas.BuildPathIdentity]::GetFileId($outputDirectoryLease)
    Assert-PublicationRootIdentity -Root $outputRoot -ExpectedIdentity $outputIdentity `
        -Lease $outputDirectoryLease -ExpectedFileId $outputDirectoryFileId `
        -Phase 'when acquiring the build-long output-directory lease'
    foreach ($name in $clearedEnvironmentNames) {
        Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
    $toolchainEvidence = Get-CurrentToolchainEvidence

    New-Item -Path $buildRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $snapshotNativeRoot -ItemType Directory -Force | Out-Null
    foreach ($relativePath in $liveInputs.Keys) {
        Copy-Item -LiteralPath $liveInputs[$relativePath] `
            -Destination $snapshotInputs[$relativePath] -Force
    }

    $buildResults = @()
    $executedArchitectures = New-Object 'Collections.Generic.List[string]'
    foreach ($targetName in $selectedTargets) {
        $first = Invoke-OneBuild -BuildName 'A' -TargetName $targetName
        $second = Invoke-OneBuild -BuildName 'B' -TargetName $targetName
        $artifactKinds = @('Resource', 'Object', 'Executable')
        if ($RunContractHarness) {
            $artifactKinds += @('HarnessObject', 'HarnessExecutable')
        }
        foreach ($artifactKind in $artifactKinds) {
            if (-not (Test-FilesByteEqual -First $first.$artifactKind `
                    -Second $second.$artifactKind)) {
                throw "Non-reproducible $artifactKind output for $targetName."
            }
        }

        $firstHash = (Get-FileHash -LiteralPath $first.Executable -Algorithm SHA256).Hash
        $secondHash = (Get-FileHash -LiteralPath $second.Executable -Algorithm SHA256).Hash
        if ($firstHash -cne $secondHash) {
            throw "Non-reproducible output for ${targetName}: SHA-256 differs."
        }
        if ($RunContractHarness -and $targetName -ceq $hostTarget) {
            Invoke-AtlasContractHarness -Path $first.HarnessExecutable `
                -TargetName $targetName
            $executedArchitectures.Add($targetName)
        }

        $builtItem = Get-Item -LiteralPath $first.Executable
        $buildResults += [pscustomobject]@{
            TargetName = $targetName
            SourcePath = $builtItem.FullName
            Length     = [long]$builtItem.Length
            SHA256     = $firstHash
        }
    }

    if ($RunContractHarness -and
            ($executedArchitectures.Count -ne 1 -or
                $executedArchitectures[0] -cne $hostTarget)) {
        throw 'The build did not execute exactly one host-compatible native contract harness.'
    }
    Assert-LiveBuildInputsUnchanged -Phase 'while native artifacts were being produced'

    $candidateRoot = Join-Path $buildRoot 'candidate'
    New-Item -Path $candidateRoot -ItemType Directory -Force | Out-Null
    $publicationFiles = New-Object 'Collections.Generic.List[object]'
    foreach ($buildResult in $buildResults) {
        $outputName = $targets[$buildResult.TargetName].Output
        $candidatePath = Join-Path $candidateRoot $outputName
        [IO.File]::Copy($buildResult.SourcePath, $candidatePath, $false)
        $candidateItem = Get-Item -LiteralPath $candidatePath
        $candidateHash = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash
        if ($candidateItem.Length -ne $buildResult.Length -or
                $candidateHash -cne $buildResult.SHA256) {
            throw "The candidate copy changed '$outputName'."
        }
        $publicationFiles.Add([pscustomobject]@{
            StagePath      = $candidateItem.FullName
            DestinationPath = (Join-Path $outputRoot $outputName)
            Length         = [long]$candidateItem.Length
            SHA256         = $candidateHash
        })
    }

    $candidateManifestPath = $null
    if ($Architecture -eq 'all') {
        $candidateManifestPath = Join-Path $candidateRoot `
            'Atlas-ElevationBootstrapHashes.psd1'
        Write-AtlasBootstrapHashManifest -BuildResults $buildResults `
            -ExecutedArchitectures ([string[]]$executedArchitectures.ToArray()) `
            -Path $candidateManifestPath
        $manifestItem = Get-Item -LiteralPath $candidateManifestPath
        $manifestHash = (Get-FileHash -LiteralPath $manifestItem.FullName `
            -Algorithm SHA256).Hash
        # The manifest is deliberately last: it is the logical commit record for the two
        # executable replacements if this process is interrupted between rename calls.
        $publicationFiles.Add([pscustomobject]@{
            StagePath      = $manifestItem.FullName
            DestinationPath = $resolvedHashManifestPath
            Length         = [long]$manifestItem.Length
            SHA256         = $manifestHash
        })

        & $snapshotVerifierPath -PayloadDirectory $candidateRoot `
            -HashManifestPath $candidateManifestPath -RepositoryRoot $repoRoot |
            Out-Null
    }

    $beforeCommit = {
        Assert-LiveBuildInputsUnchanged -Phase 'before native publication committed'
        $currentToolchainEvidence = Get-CurrentToolchainEvidence
        Assert-EvidenceEqual -Expected $toolchainEvidence `
            -Actual $currentToolchainEvidence -Label 'Native toolchain evidence'
        foreach ($file in $publicationFiles) {
            $candidateItem = Get-Item -LiteralPath $file.StagePath
            $candidateHash = (Get-FileHash -LiteralPath $candidateItem.FullName `
                -Algorithm SHA256).Hash
            if ($candidateItem.Length -ne [long]$file.Length -or
                    $candidateHash -cne [string]$file.SHA256) {
                throw "A verified publication candidate changed: '$($file.StagePath)'."
            }
        }
    }
    Publish-AtlasBootstrapFileSet -Files ([object[]]$publicationFiles.ToArray()) `
        -BeforeCommit $beforeCommit

    $artifactResults = @()
    foreach ($buildResult in $buildResults) {
        $destination = Join-Path $outputRoot $targets[$buildResult.TargetName].Output
        $item = Get-Item -LiteralPath $destination
        $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        if ($item.Length -ne $buildResult.Length -or $hash -cne $buildResult.SHA256) {
            throw "The published $($buildResult.TargetName) artifact changed after commit."
        }
        $artifactResults += [pscustomobject]@{
            Architecture = $buildResult.TargetName
            Path         = $item.FullName
            Length       = [long]$item.Length
            SHA256       = $hash
        }
    }

    [pscustomobject]@{
        OutputDirectory              = $outputRoot
        Architectures                = [string[]]$selectedTargets
        HarnessExecutedArchitectures = [string[]]$executedArchitectures.ToArray()
        Artifacts                    = [object[]]$artifactResults
        HashManifestPath             = if ($Architecture -eq 'all') {
            $resolvedHashManifestPath
        } else {
            $null
        }
    }
}
finally {
    try {
        if (Test-Path -LiteralPath $buildRoot) {
            $resolvedBuildRoot = [IO.Path]::GetFullPath($buildRoot)
            $tempPrefix = $tempBase.TrimEnd('\') + '\'
            if (-not $resolvedBuildRoot.StartsWith($tempPrefix,
                    [StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing to remove build root outside '$tempBase'."
            }
            Assert-NoPathAlias -Path $resolvedBuildRoot -Label 'The temporary build root'
            Remove-Item -LiteralPath $resolvedBuildRoot -Recurse -Force
        }
    }
    finally {
        try {
            foreach ($name in $clearedEnvironmentNames) {
                $saved = $environmentSnapshot[$name]
                if ($saved.Present) {
                    [Environment]::SetEnvironmentVariable(
                        $name, [string]$saved.Value, 'Process')
                }
                else {
                    Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
                }
            }
        }
        finally {
            if ($null -ne $outputDirectoryLease) {
                $outputDirectoryLease.Dispose()
            }
        }
    }
}
