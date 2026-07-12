#requires -Version 7.0
Set-StrictMode -Version 3.0

. (Join-Path -Path $PSScriptRoot -ChildPath 'AtlasYamlAction.ps1')

$script:IsWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::Windows)

#region Private helpers

function New-TemporaryDirectory {
    $tempPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)
    return New-Item -ItemType Directory -Path $tempPath -Force
}

function Set-ParentDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Get-AtlasFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-AtlasStreamSha256 {
    param([Parameter(Mandatory = $true)][IO.Stream]$Stream)

    if (-not $Stream.CanRead -or -not $Stream.CanSeek) {
        throw 'SHA-256 verification requires a readable, seekable archive stream.'
    }

    $originalPosition = $Stream.Position
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $Stream.Position = 0
        $hashBytes = $sha256.ComputeHash($Stream)
        return [BitConverter]::ToString($hashBytes).Replace('-', '')
    }
    finally {
        $Stream.Position = $originalPosition
        $sha256.Dispose()
    }
}

function Initialize-AtlasAtomicFilePublisher {
    if ($null -ne ('AtlasBuild.Native.AtomicFilePublisher' -as [type])) {
        return
    }

    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using Microsoft.Win32.SafeHandles;

namespace AtlasBuild.Native
{
    public static class AtomicFilePublisher
    {
        private const uint GenericRead = 0x80000000;
        private const uint Delete = 0x00010000;
        private const uint FileShareRead = 0x00000001;
        private const uint OpenExisting = 3;
        private const uint FileAttributeNormal = 0x00000080;
        private const int FileRenameInfo = 3;

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern SafeFileHandle CreateFileW(
            string fileName,
            uint desiredAccess,
            uint shareMode,
            IntPtr securityAttributes,
            uint creationDisposition,
            uint flagsAndAttributes,
            IntPtr templateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetFileInformationByHandle(
            SafeFileHandle file,
            int fileInformationClass,
            IntPtr fileInformation,
            uint bufferSize);

        private static byte[] HashStream(Stream stream)
        {
            stream.Position = 0;
            using (SHA256 sha = SHA256.Create())
            {
                return sha.ComputeHash(stream);
            }
        }

        private static byte[] ParseHash(string value)
        {
            if (String.IsNullOrWhiteSpace(value) || value.Length != 64)
                throw new ArgumentException("Expected a 64-character SHA-256 value.", "expectedSha256");

            byte[] result = new byte[32];
            for (int i = 0; i < result.Length; i++)
                result[i] = Convert.ToByte(value.Substring(i * 2, 2), 16);
            return result;
        }

        private static bool FixedEquals(byte[] left, byte[] right)
        {
            if (left.Length != right.Length) return false;
            int difference = 0;
            for (int i = 0; i < left.Length; i++) difference |= left[i] ^ right[i];
            return difference == 0;
        }

        public static void Publish(
            string sourcePath,
            string destinationPath,
            string expectedSha256,
            bool replaceExisting)
        {
            string source = Path.GetFullPath(sourcePath);
            string destination = Path.GetFullPath(destinationPath);
            string sourceDirectory = Path.GetDirectoryName(source);
            string destinationDirectory = Path.GetDirectoryName(destination);
            if (String.Equals(source, destination, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Atomic publication requires distinct source and destination files.");
            if (!String.Equals(sourceDirectory, destinationDirectory, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Atomic publication requires sibling source and destination files.");

            SafeFileHandle sourceHandle = CreateFileW(
                source,
                GenericRead | Delete,
                FileShareRead,
                IntPtr.Zero,
                OpenExisting,
                FileAttributeNormal,
                IntPtr.Zero);
            if (sourceHandle.IsInvalid)
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not bind the verified APBX file object.");

            FileStream sourceStream = null;
            try
            {
                sourceStream = new FileStream(sourceHandle, FileAccess.Read, 65536, false);
                sourceHandle = null;
                byte[] expected = ParseHash(expectedSha256);
                byte[] actual = HashStream(sourceStream);
                if (!FixedEquals(expected, actual))
                    throw new InvalidDataException("The APBX sibling changed after semantic verification.");

                byte[] nameBytes = System.Text.Encoding.Unicode.GetBytes(destination);
                int rootOffset = IntPtr.Size == 8 ? 8 : 4;
                int lengthOffset = rootOffset + IntPtr.Size;
                int nameOffset = lengthOffset + 4;
                // FILE_RENAME_INFO.FileNameLength excludes the UTF-16 terminator, but
                // the Win32 structure still requires storage for that terminator.
                int bufferSize = checked(nameOffset + nameBytes.Length + 2);
                IntPtr buffer = Marshal.AllocHGlobal(bufferSize);
                try
                {
                    for (int i = 0; i < bufferSize; i++) Marshal.WriteByte(buffer, i, 0);
                    Marshal.WriteByte(buffer, 0, replaceExisting ? (byte)1 : (byte)0);
                    Marshal.WriteIntPtr(buffer, rootOffset, IntPtr.Zero);
                    Marshal.WriteInt32(buffer, lengthOffset, nameBytes.Length);
                    Marshal.Copy(nameBytes, 0, IntPtr.Add(buffer, nameOffset), nameBytes.Length);
                    if (!SetFileInformationByHandle(
                        sourceStream.SafeFileHandle,
                        FileRenameInfo,
                        buffer,
                        (uint)bufferSize))
                    {
                        throw new Win32Exception(Marshal.GetLastWin32Error(), "Handle-bound APBX publication failed.");
                    }
                }
                finally
                {
                    Marshal.FreeHGlobal(buffer);
                }
            }
            finally
            {
                if (sourceStream != null) sourceStream.Dispose();
                else if (sourceHandle != null) sourceHandle.Dispose();
            }
        }
    }
}
'@
}

function Publish-AtlasVerifiedArchive {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [switch]$AllowReplace
    )

    if ($script:IsWindowsPlatform) {
        Initialize-AtlasAtomicFilePublisher
        [AtlasBuild.Native.AtomicFilePublisher]::Publish(
            $SourcePath,
            $DestinationPath,
            $ExpectedSha256,
            [bool]$AllowReplace
        )
        return
    }

    $actualSha256 = Get-AtlasFileSha256 -Path $SourcePath
    if ($actualSha256 -cne $ExpectedSha256) {
        throw 'The APBX sibling changed after semantic verification.'
    }
    if ((Test-Path -LiteralPath $DestinationPath -PathType Leaf) -and -not $AllowReplace) {
        throw "Archive '$DestinationPath' appeared before publication; refusing to overwrite it."
    }
    [IO.File]::Move($SourcePath, $DestinationPath, [bool]$AllowReplace)
}

function Invoke-AtlasApbxVerifier {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$PlaybookPath,
        [switch]$NoPassword
    )

    $pwshName = if ($script:IsWindowsPlatform) { 'pwsh.exe' } else { 'pwsh' }
    $pwshPath = Join-Path -Path $PSHOME -ChildPath $pwshName
    $verifierPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) `
        -ChildPath 'Test-Apbx.ps1'
    $arguments = @(
        '-NoLogo', '-NoProfile', '-File', $verifierPath,
        '-Path', $Path,
        '-PlaybookPath', $PlaybookPath
    )
    if ($NoPassword) {
        $arguments += @('-Password', '')
    }

    $output = @(& $pwshPath @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
        if ($message.Length -gt 65536) {
            $message = $message.Substring(0, 65536) + [Environment]::NewLine + '[output truncated]'
        }
        throw "Semantic APBX verification failed with exit code $exitCode.`n$message"
    }
    foreach ($line in $output) {
        Write-Information -MessageData "$line" -InformationAction Continue
    }
}

function Assert-NoAtlasPublicationArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Directory
    )

    $patterns = @(
        '*.apbx.tmp',
        '*.apbx.*.building.tmp*',
        '*.apbx.*.replaced.bak'
    )
    $artifacts = @($patterns | ForEach-Object {
            Get-ChildItem -LiteralPath $Directory -Filter $_ -File -Force -Recurse `
                -ErrorAction Stop
        } | Sort-Object FullName -Unique)
    if ($artifacts.Count -gt 0) {
        throw (
            'Stale or concurrent APBX publication artifacts must be removed before building: ' +
            (($artifacts | ForEach-Object FullName) -join ', ')
        )
    }
}

#endregion

function Resolve-SevenZip {
    <#
    .SYNOPSIS
        Locates a 7-Zip compatible executable (7z, 7zz or the installed 7-Zip copy on Windows).
    #>
    $candidates = @('7z', '7zz')

    foreach ($candidate in $candidates) {
        $commandInfo = Get-Command -Name $candidate -ErrorAction SilentlyContinue
        if ($commandInfo) {
            return $commandInfo.Source
        }
    }

    if ($script:IsWindowsPlatform) {
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')
        if ($programFiles) {
            $installedPath = Join-Path -Path $programFiles -ChildPath '7-Zip\7z.exe'
            if (Test-Path -LiteralPath $installedPath) {
                return $installedPath
            }
        }
    }

    throw 'This script requires 7-Zip or NanaZip to be installed to continue.'
}

function Invoke-SevenZip {
    <#
    .SYNOPSIS
        Runs 7-Zip with the given arguments, recovering interrupted "<archive>.tmp" writes
        that 7-Zip leaves behind when updating password-protected zip archives.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SevenZipPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [string]$ErrorContext = '7-Zip operation',
        [string]$ArchivePath
    )

    $previousErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $processOutput = & $SevenZipPath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    $recovered = $false

    if ($ArchivePath) {
        $archiveDirectory = Split-Path -Path $ArchivePath -Parent
        $archiveLeaf = Split-Path -Path $ArchivePath -Leaf
        $primaryTempPath = "$ArchivePath.tmp"

        $candidateItems = @()
        if (Test-Path -LiteralPath $primaryTempPath) {
            $candidateItems += Get-Item -LiteralPath $primaryTempPath
        }

        if ($archiveDirectory) {
            $additionalCandidates = Get-ChildItem -LiteralPath $archiveDirectory -Filter "$archiveLeaf.tmp*" -ErrorAction SilentlyContinue
            foreach ($item in $additionalCandidates) {
                if ($primaryTempPath -and ($item.FullName -eq $primaryTempPath)) {
                    continue
                }
                $candidateItems += $item
            }
        }

        if ($candidateItems) {
            $candidateItems = $candidateItems | Sort-Object LastWriteTime -Descending
            $targetName = $archiveLeaf

            foreach ($candidate in $candidateItems) {
                for ($attempt = 0; $attempt -lt 5 -and -not $recovered; $attempt++) {
                    try {
                        Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
                        Rename-Item -LiteralPath $candidate.FullName -NewName $targetName -Force
                        $recovered = $true
                        break
                    }
                    catch {
                        if ($attempt -eq 4) {
                            $warningMessage = "Failed to recover archive from temporary file '{0}': {1}" -f $candidate.FullName, $_.Exception.Message
                            Write-Warning $warningMessage
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }

                if ($recovered) {
                    break
                }
            }

            if (Test-Path -LiteralPath $ArchivePath) {
                foreach ($candidate in $candidateItems) {
                    if (Test-Path -LiteralPath $candidate.FullName) {
                        Remove-Item -LiteralPath $candidate.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }

    if ($exitCode -ne 0 -and $recovered) {
        $exitCode = 0
    }

    if ($exitCode -ne 0) {
        $message = "$ErrorContext failed with exit code $exitCode while executing '$SevenZipPath'."
        if ($processOutput) {
            $message += " Output:`n$($processOutput -join [Environment]::NewLine)"
        }
        throw $message
    }

    return $processOutput
}

function Get-PlaybookVersion {
    <#
    .SYNOPSIS
        Parses playbook.conf and returns version metadata.
    .OUTPUTS
        PSCustomObject with Version, Title, IsDev and VersionLabel (e.g. "v0.5.1 (dev)").
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookConfPath
    )

    if (-not (Test-Path -LiteralPath $PlaybookConfPath -PathType Leaf)) {
        throw "playbook.conf not found at '$PlaybookConfPath'."
    }

    $confXml = [xml](Get-Content -Path $PlaybookConfPath -Raw -Encoding UTF8)
    $playbookNode = $confXml.Playbook

    if (-not $playbookNode) {
        throw "'$PlaybookConfPath' does not contain a <Playbook> root element."
    }

    if ($playbookNode.Version -notmatch '^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$') {
        throw "Invalid version format '$($playbookNode.Version)' in '$PlaybookConfPath'."
    }

    $isDev = $playbookNode.Title -match '\(dev\)'
    $versionLabel = "v$($playbookNode.Version)"
    if ($isDev) {
        $versionLabel += ' (dev)'
    }

    return [pscustomobject]@{
        Version      = $playbookNode.Version
        Title        = $playbookNode.Title
        IsDev        = $isDev
        VersionLabel = $versionLabel
    }
}

function Get-AvailableArchiveName {
    <#
    .SYNOPSIS
        Picks a non-conflicting archive file name, optionally replacing an existing one.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$BaseName,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [switch]$AllowReplace
    )

    $candidate = $BaseName
    $candidatePath = Join-Path -Path $WorkingDirectory -ChildPath $candidate

    if ($AllowReplace -and (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        try {
            $stream = [IO.File]::Open(
                $candidatePath,
                [IO.FileMode]::Open,
                [IO.FileAccess]::ReadWrite,
                [IO.FileShare]::None
            )
            $stream.Dispose()
        }
        catch {
            Write-Warning "Couldn't replace '$candidate', it's in use."
            $AllowReplace = $false
        }
    }

    $counter = 1
    while ((-not $AllowReplace) -and (Test-Path -LiteralPath (Join-Path -Path $WorkingDirectory -ChildPath $candidate) -PathType Leaf)) {
        $candidate = "{0} ({1}).apbx" -f $DisplayName, $counter
        $counter++
    }

    return $candidate
}

function Get-AtlasPlaybookPayloadPath {
    <#
    .SYNOPSIS
        Returns the normalized relative path of every file that belongs in an APBX.
    .DESCRIPTION
        The playbook directory is the payload contract. Generated APBX files and their
        recognized interrupted-build/publication artifacts are the only files excluded
        by New-Apbx.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PlaybookPath
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $PlaybookPath).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path -Path $resolvedRoot -ChildPath 'playbook.conf') -PathType Leaf)) {
        throw "playbook.conf not found in '$resolvedRoot' - not a playbook directory."
    }

    return @(Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse |
        Where-Object {
            $_.Name -notlike '*.apbx' -and
            $_.Name -notlike '*.apbx.tmp' -and
            $_.Name -notlike '*.apbx.*.building.tmp*' -and
            $_.Name -notlike '*.apbx.*.replaced.bak'
        } |
        ForEach-Object {
            [IO.Path]::GetRelativePath($resolvedRoot, $_.FullName).Replace('\', '/')
        } |
        Sort-Object -Unique)
}

function Compare-AtlasPayloadPath {
    <#
    .SYNOPSIS
        Compares the expected and archived APBX file paths without hiding duplicates.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ExpectedPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ActualPath
    )

    $expectedSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $actualSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $actualCounts = [System.Collections.Generic.Dictionary[string, int]]::new([StringComparer]::Ordinal)

    $normalizedExpected = foreach ($item in $ExpectedPath) {
        $normalized = $item.Replace('\', '/')
        $null = $expectedSet.Add($normalized)
        $normalized
    }

    $normalizedActual = foreach ($item in $ActualPath) {
        $normalized = $item.Replace('\', '/')
        $null = $actualSet.Add($normalized)
        if ($actualCounts.ContainsKey($normalized)) {
            $actualCounts[$normalized]++
        }
        else {
            $actualCounts[$normalized] = 1
        }
        $normalized
    }

    $missing = @($normalizedExpected | Where-Object { -not $actualSet.Contains($_) } | Sort-Object -Unique)
    $unexpected = @($normalizedActual | Where-Object { -not $expectedSet.Contains($_) } | Sort-Object -Unique)
    $duplicates = @($actualCounts.GetEnumerator() |
        Where-Object { $_.Value -gt 1 } |
        ForEach-Object { $_.Key } |
        Sort-Object)

    return [pscustomobject]@{
        Matches    = ($missing.Count -eq 0 -and $unexpected.Count -eq 0 -and $duplicates.Count -eq 0)
        Missing    = $missing
        Unexpected = $unexpected
        Duplicates = $duplicates
    }
}

function New-StagedPlaybookConf {
    <#
    .SYNOPSIS
        Writes a copy of playbook.conf with the requested requirement lines stripped.
        Used for dev builds so they install on unsupported/unverified machines.
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookConfPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [switch]$RemoveRequirements,
        [switch]$RemoveWinverRequirement,
        [switch]$RemoveVerification
    )

    $patternTokens = @()
    if ($RemoveRequirements) { $patternTokens += '<Requirement>' }
    if ($RemoveWinverRequirement) { $patternTokens += '<string>', '</SupportedBuilds>', '<SupportedBuilds>' }
    if ($RemoveVerification) { $patternTokens += '<ProductCode>' }

    if ($patternTokens.Count -eq 0) {
        return $false
    }

    Set-ParentDirectory -Path $DestinationPath
    $pattern = [string]::Join('|', $patternTokens)
    Get-Content -Path $PlaybookConfPath -Encoding UTF8 |
        Where-Object { $_ -notmatch $pattern } |
        Set-Content -Path $DestinationPath -Encoding UTF8

    return (Test-Path -LiteralPath $DestinationPath)
}

function Set-OemVersionStamp {
    <#
    .SYNOPSIS
        Writes a copy of the OEM information script with the AtlasVersionUndefined
        placeholder replaced by the playbook version label.
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$VersionLabel,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        Write-Warning "Can't find '$ScriptPath', not setting OEM version."
        return $false
    }

    $oemContent = Get-Content -Path $ScriptPath -Raw -Encoding UTF8
    $updatedOemContent = $oemContent -replace 'AtlasVersionUndefined', $VersionLabel

    if ($updatedOemContent -eq $oemContent) {
        Write-Warning "Couldn't find OEM string 'AtlasVersionUndefined', not updating OEM version."
        return $false
    }

    Set-ParentDirectory -Path $DestinationPath
    Set-Content -Path $DestinationPath -Value $updatedOemContent -Encoding UTF8
    return $true
}

function New-Apbx {
    <#
    .SYNOPSIS
        Packages the playbook directory into a renamed, optionally password-protected ZIP
        (.apbx) understood by AME Wizard, applying dev-build staging overrides on top.
    .OUTPUTS
        Full path of the built .apbx file.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookPath,
        [string]$OutputDirectory,
        [string]$FileName = 'Atlas Test',
        [switch]$RemoveRequirements,
        [switch]$RemoveWinverRequirement,
        [switch]$RemoveVerification,
        [switch]$NoPassword,
        [switch]$ReplaceOldPlaybook
    )

    $PlaybookPath = (Resolve-Path -LiteralPath $PlaybookPath).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path -Path $PlaybookPath -ChildPath 'playbook.conf') -PathType Leaf)) {
        throw "playbook.conf not found in '$PlaybookPath' - not a playbook directory."
    }
    Assert-AtlasConfigurationRunnerBoundary `
        -ConfigurationRoot (Join-Path -Path $PlaybookPath -ChildPath 'Configuration') | Out-Null

    if (-not $OutputDirectory) {
        $OutputDirectory = $PlaybookPath
    }
    $OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).ProviderPath

    $sevenZipPath = Resolve-SevenZip

    $apbxFileName = Get-AvailableArchiveName -BaseName "$FileName.apbx" -WorkingDirectory $OutputDirectory -DisplayName $FileName -AllowReplace:$ReplaceOldPlaybook
    $apbxPath = Join-Path -Path $OutputDirectory -ChildPath $apbxFileName
    Assert-NoAtlasPublicationArtifact -Directory $PlaybookPath
    $pathComparison = if ($script:IsWindowsPlatform) {
        [StringComparison]::OrdinalIgnoreCase
    }
    else {
        [StringComparison]::Ordinal
    }
    if (-not [string]::Equals(
            $PlaybookPath,
            $OutputDirectory,
            $pathComparison)) {
        Assert-NoAtlasPublicationArtifact -Directory $OutputDirectory
    }
    $publicationId = [guid]::NewGuid().ToString('N')
    $buildApbxPath = '{0}.{1}.building.tmp' -f `
        $apbxPath,
        $publicationId

    $rootTempDir = $null
    $filesListPath = $null
    $previousLocation = Get-Location

    try {
        Set-Location -LiteralPath $PlaybookPath

        # Staged overrides are written into a temp mirror of the playbook tree and added
        # to the archive after the main pass, replacing the originals.
        $rootTempDir = New-TemporaryDirectory
        $stagingPath = Join-Path -Path $rootTempDir.FullName -ChildPath 'playbook'
        New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

        $stagedPlaybookConf = New-StagedPlaybookConf `
            -PlaybookConfPath (Join-Path -Path $PlaybookPath -ChildPath 'playbook.conf') `
            -DestinationPath (Join-Path -Path $stagingPath -ChildPath 'playbook.conf') `
            -RemoveRequirements:$RemoveRequirements `
            -RemoveWinverRequirement:$RemoveWinverRequirement `
            -RemoveVerification:$RemoveVerification

        $oemScriptRelativePath = 'Executables\AtlasModules\Scripts\Tasks\Set-OemInformation.ps1'
        $stagedOemScript = $false
        try {
            $versionInfo = Get-PlaybookVersion -PlaybookConfPath (Join-Path -Path $PlaybookPath -ChildPath 'playbook.conf')
            $stagedOemScript = Set-OemVersionStamp `
                -ScriptPath (Join-Path -Path $PlaybookPath -ChildPath $oemScriptRelativePath) `
                -VersionLabel $versionInfo.VersionLabel `
                -DestinationPath (Join-Path -Path $stagingPath -ChildPath $oemScriptRelativePath)
        }
        catch {
            Write-Warning "Failed to process OEM information: $($_.Exception.Message)"
        }

        # Files replaced by staged overrides are excluded from the main pass so the
        # archive never contains duplicates.
        $excludeFiles = @(
            '*.apbx', '*.apbx.tmp', '*.apbx.*.building.tmp*', '*.apbx.*.replaced.bak'
        )
        if ($stagedPlaybookConf) { $excludeFiles += 'playbook.conf' }
        if ($stagedOemScript) { $excludeFiles += 'Set-OemInformation.ps1' }

        $filesListPath = [IO.Path]::GetTempFileName()
        $rootPathNormalized = $PlaybookPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $rootPrefix = $rootPathNormalized + [IO.Path]::DirectorySeparatorChar

        $filesToInclude = Get-ChildItem -File -Exclude $excludeFiles -Recurse
        $relativePaths = foreach ($file in $filesToInclude) {
            $fullName = $file.FullName
            if ($fullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                $relative = $fullName.Substring($rootPrefix.Length)
            }
            elseif ($fullName.StartsWith($rootPathNormalized, [StringComparison]::OrdinalIgnoreCase)) {
                $relative = $fullName.Substring($rootPathNormalized.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
            }
            else {
                $relative = $file.Name
            }

            $relative -replace '\\', '/'
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($filesListPath, $relativePaths, $utf8NoBom)

        $passwordArgs = @()
        if (-not $NoPassword) {
            $passwordArgs += '-pmalte'
        }

        # Store-level compression for speed; -bs* flags keep 7-Zip quiet.
        $archiveArgs = @('a', '-tzip', '-y', '-mx1', '-bso0', '-bse0', '-bsp0')
        if ($script:IsWindowsPlatform) {
            $archiveArgs += '-spf'
        }
        $archiveArgs += $passwordArgs
        $archiveArgs += $buildApbxPath
        # The @listfile syntax must not be quoted or 7-Zip misparses it.
        $archiveArgs += "@$filesListPath"

        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $archiveArgs `
            -ErrorContext 'Creating APBX archive' -ArchivePath $buildApbxPath | Out-Null

        $stagedFiles = Get-ChildItem -Path $stagingPath -File -Recurse -ErrorAction SilentlyContinue
        if ($stagedFiles) {
            Set-Location -LiteralPath $stagingPath
            try {
                $updateArgs = @('u', '-bso0', '-bse0', '-bsp0')
                $updateArgs += $passwordArgs
                $updateArgs += $buildApbxPath
                $updateArgs += '*'

                Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $updateArgs `
                    -ErrorContext 'Adding staged overrides' -ArchivePath $buildApbxPath | Out-Null
            }
            finally {
                Set-Location -LiteralPath $PlaybookPath
            }
        }

        $integrityArgs = @('t', '-bso0', '-bse0', '-bsp0') +
            $passwordArgs + @($buildApbxPath)
        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $integrityArgs `
            -ErrorContext 'Verifying built APBX archive' | Out-Null

        $semanticArchiveStream = [IO.File]::Open(
            $buildApbxPath,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )
        try {
            $preVerificationSha256 = Get-AtlasStreamSha256 -Stream $semanticArchiveStream
            Invoke-AtlasApbxVerifier `
                -Path $buildApbxPath `
                -PlaybookPath $PlaybookPath `
                -NoPassword:$NoPassword
            $postVerificationSha256 = Get-AtlasStreamSha256 -Stream $semanticArchiveStream
            if ($preVerificationSha256 -cne $postVerificationSha256) {
                throw 'The APBX sibling changed during semantic verification.'
            }
        }
        finally {
            $semanticArchiveStream.Dispose()
        }

        Publish-AtlasVerifiedArchive `
            -SourcePath $buildApbxPath `
            -DestinationPath $apbxPath `
            -ExpectedSha256 $postVerificationSha256 `
            -AllowReplace:$ReplaceOldPlaybook

        return $apbxPath
    }
    finally {
        try {
            Set-Location -LiteralPath $previousLocation.Path -ErrorAction Stop
        }
        catch {
            try {
                Set-Location -LiteralPath $OutputDirectory -ErrorAction Stop
            }
            catch {
                try {
                    Set-Location -LiteralPath $PlaybookPath -ErrorAction Stop
                }
                catch {
                    # Publication has already succeeded or failed. Location restoration
                    # must never replace that result with a cleanup-only exception.
                    $null = $_
                }
            }
        }

        try {
            if ($filesListPath -and (Test-Path -LiteralPath $filesListPath)) {
                Remove-Item -LiteralPath $filesListPath -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # The OS temp file can be reclaimed independently of publication.
            $null = $_
        }

        try {
            if ($rootTempDir -and (Test-Path -LiteralPath $rootTempDir.FullName)) {
                Remove-Item -LiteralPath $rootTempDir.FullName -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
        catch {
            # The OS temp directory can be reclaimed independently of publication.
            $null = $_
        }

        try {
            if ($buildApbxPath -and (Test-Path -LiteralPath $buildApbxPath)) {
                Remove-Item -LiteralPath $buildApbxPath -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # A stale sibling is rejected at the start of the next build.
            $null = $_
        }

        try {
            $buildLeaf = Split-Path -Path $buildApbxPath -Leaf
            Get-ChildItem -LiteralPath $OutputDirectory -Filter "$buildLeaf.tmp*" `
                -ErrorAction SilentlyContinue |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
        catch {
            # A stale 7-Zip working file is rejected at the start of the next build.
            $null = $_
        }
    }
}
