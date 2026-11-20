#requires -Version 7.0
Set-StrictMode -Version 3.0

$script:IsWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::Windows)

# docs/package-format.md defines the package file, its manifest and these values.
$script:PackageExtension = '.atlaspkg'
# Public on purpose: it keeps antivirus engines from scanning the scripts inside before
# Atlas Manager stages them, and protects nothing.
$script:PackagePassword = 'atlasos'
$script:VersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?\z'
# Atlas Manager versions are plain major.minor.patch.
$script:ManagerVersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\z'
$script:ImageStemPattern = '^[A-Za-z0-9_-]+\z'
$script:ManifestFields = @(
    'schemaVersion', 'version', 'minimumManagerVersion', 'supportedBuilds', 'updatableFrom',
    'requirements', 'estimatedMinutes', 'choices'
)
$script:ChoiceFields = @('id', 'kind', 'default', 'dependsOn', 'description', 'learnMore', 'options')
$script:OptionFields = @('id', 'label', 'image')
$script:RequirementIds = @('windows-security-off', 'no-third-party-antivirus', 'plugged-in')

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
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not bind the verified package file object.");

            FileStream sourceStream = null;
            try
            {
                sourceStream = new FileStream(sourceHandle, FileAccess.Read, 65536, false);
                sourceHandle = null;
                byte[] expected = ParseHash(expectedSha256);
                byte[] actual = HashStream(sourceStream);
                if (!FixedEquals(expected, actual))
                    throw new InvalidDataException("The package sibling changed after semantic verification.");

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
                        throw new Win32Exception(Marshal.GetLastWin32Error(), "Handle-bound package publication failed.");
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
        throw 'The package sibling changed after semantic verification.'
    }
    if ((Test-Path -LiteralPath $DestinationPath -PathType Leaf) -and -not $AllowReplace) {
        throw "Archive '$DestinationPath' appeared before publication; refusing to overwrite it."
    }
    [IO.File]::Move($SourcePath, $DestinationPath, [bool]$AllowReplace)
}

function Invoke-AtlasPackageVerifier {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$PackagePath,
        [switch]$NoPassword
    )

    $pwshName = if ($script:IsWindowsPlatform) { 'pwsh.exe' } else { 'pwsh' }
    $pwshPath = Join-Path -Path $PSHOME -ChildPath $pwshName
    $verifierPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) `
        -ChildPath 'Test-Package.ps1'
    $arguments = @(
        '-NoLogo', '-NoProfile', '-File', $verifierPath,
        '-Path', $Path,
        '-PackagePath', $PackagePath
    )
    if ($NoPassword) {
        $arguments += '-NoPassword'
    }

    $output = @(& $pwshPath @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
        if ($message.Length -gt 65536) {
            $message = $message.Substring(0, 65536) + [Environment]::NewLine + '[output truncated]'
        }
        throw "Semantic package verification failed with exit code $exitCode.`n$message"
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
        "*$script:PackageExtension.tmp",
        "*$script:PackageExtension.*.building.tmp*"
    )
    $artifacts = @($patterns | ForEach-Object {
            Get-ChildItem -LiteralPath $Directory -Filter $_ -File -Force -Recurse `
                -ErrorAction Stop
        } | Sort-Object FullName -Unique)
    if ($artifacts.Count -gt 0) {
        throw (
            'Stale or concurrent package publication artifacts must be removed before building: ' +
            (($artifacts | ForEach-Object FullName) -join ', ')
        )
    }
}

function Get-AtlasInnermostMessage {
    param([Parameter(Mandatory = $true)][Exception]$Exception)

    while ($null -ne $Exception.InnerException) {
        $Exception = $Exception.InnerException
    }
    return $Exception.Message
}

function Read-AtlasManifestText {
    # atlas.json is UTF-8 without a byte order mark; anything else is refused rather than
    # decoded leniently, because Atlas Manager reads it strictly.
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "atlas.json not found at '$Path'."
    }
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "'$Path' starts with a byte order mark; atlas.json is UTF-8 without one."
    }
    try {
        return [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    }
    catch {
        throw "'$Path' isn't valid UTF-8."
    }
}

function ConvertFrom-AtlasManifestText {
    # A strict parse: comments, trailing commas and other JSON extensions are errors.
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Path
    )

    try {
        return [System.Text.Json.JsonDocument]::Parse($Text, [System.Text.Json.JsonDocumentOptions]::new())
    }
    catch {
        throw "'$Path' isn't valid JSON: $(Get-AtlasInnermostMessage -Exception $_.Exception)"
    }
}

function Get-AtlasJsonMember {
    # The members of a JSON object by name. Names outside -KnownName and names declared
    # more than once are added to -Problem; a repeated name keeps its first value.
    param(
        [Parameter(Mandatory = $true)][System.Text.Json.JsonElement]$Element,
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $true)][string[]]$KnownName,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Problem
    )

    $members = [System.Collections.Generic.Dictionary[string, System.Text.Json.JsonElement]]::new(
        [StringComparer]::Ordinal)
    $repeated = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($property in $Element.EnumerateObject()) {
        if ($members.ContainsKey($property.Name)) {
            if ($repeated.Add($property.Name)) {
                $Problem.Add("$Context declares '$($property.Name)' more than once.")
            }
            continue
        }
        $members[$property.Name] = $property.Value
        if ($KnownName -cnotcontains $property.Name) {
            $Problem.Add("$Context has an unknown field '$($property.Name)'.")
        }
    }
    return $members
}

function Get-AtlasJsonString {
    # The value of a JSON string, or $null for any other kind of value.
    param([Parameter(Mandatory = $true)][System.Text.Json.JsonElement]$Element)

    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::String) {
        return $Element.GetString()
    }
    return $null
}

function Get-AtlasJsonInteger {
    # The value of a JSON number written as an integer, or $null for anything else,
    # including 1.0 and 1e3.
    param([Parameter(Mandatory = $true)][System.Text.Json.JsonElement]$Element)

    $value = [long]0
    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Number -and $Element.TryGetInt64([ref]$value)) {
        return $value
    }
    return $null
}

function Test-AtlasJsonStringList {
    # Checks that a member is an array of distinct strings that each pass -IsValid.
    param(
        [Parameter(Mandatory = $true)][System.Text.Json.JsonElement]$Element,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$IsValid,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Problem
    )

    if ($Element.ValueKind -ne [System.Text.Json.JsonValueKind]::Array) {
        $Problem.Add("$Name must be an array of $Expected.")
        return
    }
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in $Element.EnumerateArray()) {
        $value = Get-AtlasJsonString -Element $entry
        if ($null -eq $value -or -not (& $IsValid $value)) {
            $Problem.Add("$Name has $($entry.GetRawText()), which isn't one of $Expected.")
        }
        elseif (-not $seen.Add($value)) {
            $Problem.Add("$Name lists '$value' more than once.")
        }
    }
}

function Compare-AtlasVersionCore {
    # Compares the major.minor.patch numbers of two versions that match $script:VersionPattern
    # and returns -1, 0 or 1. Any -suffix is ignored. BigInteger keeps numbers of any length.
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )

    $leftParts = ($Left -split '-', 2)[0] -split '\.'
    $rightParts = ($Right -split '-', 2)[0] -split '\.'
    for ($index = 0; $index -lt 3; $index++) {
        $order = [System.Numerics.BigInteger]::Parse($leftParts[$index]).CompareTo(
            [System.Numerics.BigInteger]::Parse($rightParts[$index]))
        if ($order -ne 0) {
            return [Math]::Sign($order)
        }
    }
    return 0
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
        that 7-Zip leaves behind when updating encrypted zip archives.
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

function Get-AtlasPackagePassword {
    <#
    .SYNOPSIS
        Returns the public password that encrypts every entry of an Atlas package.
    .DESCRIPTION
        The password protects nothing. It stops antivirus engines from scanning, and
        possibly quarantining, Atlas's scripts before Atlas Manager stages them.
    #>
    [OutputType([string])]
    param()

    return $script:PackagePassword
}

function Get-AtlasPackageVersion {
    <#
    .SYNOPSIS
        Reads the version from an atlas.json.
    .OUTPUTS
        PSCustomObject with Version and VersionLabel, the version with a leading "v".
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath
    )

    $document = ConvertFrom-AtlasManifestText -Text (Read-AtlasManifestText -Path $ManifestPath) -Path $ManifestPath
    try {
        $root = $document.RootElement
        $versionElement = [System.Text.Json.JsonElement]::new()
        $version = $null
        if ($root.ValueKind -eq [System.Text.Json.JsonValueKind]::Object -and
            $root.TryGetProperty('version', [ref]$versionElement)) {
            $version = Get-AtlasJsonString -Element $versionElement
        }
    }
    finally {
        $document.Dispose()
    }

    if ($null -eq $version) {
        throw "'$ManifestPath' has no version string."
    }
    if ($version -cnotmatch $script:VersionPattern) {
        throw "Invalid version format '$version' in '$ManifestPath'."
    }

    return [pscustomobject]@{
        Version      = $version
        VersionLabel = "v$version"
    }
}

function Test-AtlasManifest {
    <#
    .SYNOPSIS
        Checks an atlas.json against docs/package-format.md and returns each problem found.
    .DESCRIPTION
        Returns nothing when the manifest follows the format. With -PackageFile, the
        package-relative paths of the files in the package, every option image must also
        name a PNG in Images/.
    .OUTPUTS
        System.String, one per problem.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyCollection()][string[]]$PackageFile
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    $packageFiles = $null
    if ($PSBoundParameters.ContainsKey('PackageFile')) {
        $packageFiles = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($file in @($PackageFile)) {
            $null = $packageFiles.Add($file.Replace('\', '/'))
        }
    }

    try {
        $document = ConvertFrom-AtlasManifestText -Text (Read-AtlasManifestText -Path $Path) -Path $Path
    }
    catch {
        return $_.Exception.Message
    }

    try {
        $root = $document.RootElement
        if ($root.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
            return 'atlas.json must hold a JSON object.'
        }
        $top = Get-AtlasJsonMember -Element $root -Context 'atlas.json' -KnownName $script:ManifestFields -Problem $problems
        foreach ($name in $script:ManifestFields) {
            if (-not $top.ContainsKey($name)) {
                $problems.Add("atlas.json has no '$name'.")
            }
        }

        if ($top.ContainsKey('schemaVersion') -and (Get-AtlasJsonInteger -Element $top['schemaVersion']) -ne 1) {
            $problems.Add("schemaVersion must be 1, not $($top['schemaVersion'].GetRawText()).")
        }

        $version = $null
        if ($top.ContainsKey('version')) {
            $version = Get-AtlasJsonString -Element $top['version']
            if ($null -eq $version -or $version -cnotmatch $script:VersionPattern) {
                $problems.Add("version must be a string such as 1.2.3 or 1.2.3-rc.1, not $($top['version'].GetRawText()).")
                $version = $null
            }
        }

        if ($top.ContainsKey('minimumManagerVersion')) {
            $managerVersion = Get-AtlasJsonString -Element $top['minimumManagerVersion']
            if ($null -eq $managerVersion -or $managerVersion -cnotmatch $script:ManagerVersionPattern) {
                $problems.Add(
                    'minimumManagerVersion must be a string such as 1.2.3, not ' +
                    "$($top['minimumManagerVersion'].GetRawText()).")
            }
            # Atlas Manager is released with the package version, so a package can't need a
            # later Manager. A pre-release such as 0.7.0-rc.1 may need the 0.7.0 Manager.
            elseif ($null -ne $version -and (Compare-AtlasVersionCore -Left $managerVersion -Right $version) -gt 0) {
                $problems.Add("minimumManagerVersion '$managerVersion' is higher than version '$version'.")
            }
        }

        if ($top.ContainsKey('supportedBuilds')) {
            $builds = $top['supportedBuilds']
            if ($builds.ValueKind -ne [System.Text.Json.JsonValueKind]::Array) {
                $problems.Add('supportedBuilds must be an array.')
            }
            else {
                $seenBuilds = [System.Collections.Generic.HashSet[long]]::new()
                $index = 0
                foreach ($entry in $builds.EnumerateArray()) {
                    $context = "supportedBuilds[$index]"
                    $index++
                    if ($entry.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
                        $problems.Add("$context must be an object with a build and a release.")
                        continue
                    }
                    $fields = Get-AtlasJsonMember -Element $entry -Context $context -KnownName 'build', 'release' -Problem $problems
                    $build = if ($fields.ContainsKey('build')) { Get-AtlasJsonInteger -Element $fields['build'] } else { $null }
                    if ($null -eq $build -or $build -le 0) {
                        $problems.Add("$context.build must be a positive integer.")
                    }
                    elseif (-not $seenBuilds.Add($build)) {
                        $problems.Add("supportedBuilds lists build $build more than once.")
                    }
                    $release = if ($fields.ContainsKey('release')) { Get-AtlasJsonString -Element $fields['release'] } else { $null }
                    if ([string]::IsNullOrWhiteSpace($release)) {
                        $problems.Add("$context.release must name the release, such as 25H2.")
                    }
                }
            }
        }

        if ($top.ContainsKey('updatableFrom')) {
            Test-AtlasJsonStringList -Element $top['updatableFrom'] -Name 'updatableFrom' `
                -Expected 'the Atlas versions' -Problem $problems `
                -IsValid { param($Value) $Value -cmatch $script:VersionPattern }
        }

        if ($top.ContainsKey('requirements')) {
            Test-AtlasJsonStringList -Element $top['requirements'] -Name 'requirements' `
                -Expected "the requirement ids ($($script:RequirementIds -join ', '))" -Problem $problems `
                -IsValid { param($Value) $script:RequirementIds -ccontains $Value }
        }

        if ($top.ContainsKey('estimatedMinutes')) {
            $minutes = Get-AtlasJsonInteger -Element $top['estimatedMinutes']
            if ($null -eq $minutes -or $minutes -le 0) {
                $problems.Add("estimatedMinutes must be a positive whole number, not $($top['estimatedMinutes'].GetRawText()).")
            }
        }

        if ($top.ContainsKey('choices')) {
            $choices = $top['choices']
            if ($choices.ValueKind -ne [System.Text.Json.JsonValueKind]::Array) {
                $problems.Add('choices must be an array.')
            }
            else {
                # The first pass collects every option, because dependsOn can name an option
                # of a later choice; the second checks default and dependsOn against them.
                $records = [System.Collections.Generic.List[object]]::new()
                $choiceIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                $optionIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                $choiceIndex = 0
                foreach ($choice in $choices.EnumerateArray()) {
                    $context = "choices[$choiceIndex]"
                    $choiceIndex++
                    if ($choice.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
                        $problems.Add("$context must be an object.")
                        continue
                    }
                    $fields = Get-AtlasJsonMember -Element $choice -Context $context -KnownName $script:ChoiceFields -Problem $problems
                    $id = if ($fields.ContainsKey('id')) { Get-AtlasJsonString -Element $fields['id'] } else { $null }
                    if ([string]::IsNullOrWhiteSpace($id)) {
                        $problems.Add("$context has no id.")
                    }
                    else {
                        $context = "Choice '$id'"
                        if (-not $choiceIds.Add($id)) {
                            $problems.Add("More than one choice has the id '$id'.")
                        }
                    }

                    $kind = if ($fields.ContainsKey('kind')) { Get-AtlasJsonString -Element $fields['kind'] } else { $null }
                    if ($kind -cnotin 'single', 'multiple') {
                        $problems.Add("$context must have the kind single or multiple.")
                    }
                    if ($fields.ContainsKey('description') -and $null -eq (Get-AtlasJsonString -Element $fields['description'])) {
                        $problems.Add("$context has a description that isn't a string.")
                    }
                    if ($fields.ContainsKey('learnMore') -and
                        (Get-AtlasJsonString -Element $fields['learnMore']) -cnotmatch '^https://\S+\z') {
                        $problems.Add("$context has a learnMore that isn't an https:// link.")
                    }

                    $ownOptions = [System.Collections.Generic.List[string]]::new()
                    $options = if ($fields.ContainsKey('options')) { $fields['options'] } else { $null }
                    if ($null -eq $options -or $options.ValueKind -ne [System.Text.Json.JsonValueKind]::Array) {
                        $problems.Add("$context must have an options array.")
                    }
                    else {
                        $optionIndex = 0
                        foreach ($option in $options.EnumerateArray()) {
                            $optionContext = "$context option $optionIndex"
                            $optionIndex++
                            if ($option.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
                                $problems.Add("$optionContext must be an object.")
                                continue
                            }
                            $optionFields = Get-AtlasJsonMember -Element $option -Context $optionContext -KnownName $script:OptionFields -Problem $problems
                            $optionId = if ($optionFields.ContainsKey('id')) { Get-AtlasJsonString -Element $optionFields['id'] } else { $null }
                            if ([string]::IsNullOrWhiteSpace($optionId)) {
                                $problems.Add("$optionContext has no id.")
                            }
                            else {
                                $optionContext = "Option '$optionId'"
                                $ownOptions.Add($optionId)
                                if (-not $optionIds.Add($optionId)) {
                                    $problems.Add("More than one option has the id '$optionId'.")
                                }
                            }
                            $label = if ($optionFields.ContainsKey('label')) { Get-AtlasJsonString -Element $optionFields['label'] } else { $null }
                            if ([string]::IsNullOrWhiteSpace($label)) {
                                $problems.Add("$optionContext has no label.")
                            }
                            if ($optionFields.ContainsKey('image')) {
                                $stem = Get-AtlasJsonString -Element $optionFields['image']
                                if ($null -eq $stem -or $stem -cnotmatch $script:ImageStemPattern) {
                                    $problems.Add(
                                        "$optionContext has the image $($optionFields['image'].GetRawText()), " +
                                        'which must be a PNG name without its extension, in letters, digits, - and _.')
                                }
                                elseif ($null -ne $packageFiles -and -not $packageFiles.Contains("Images/$stem.png")) {
                                    $problems.Add("$optionContext has the image '$stem', but the package has no Images/$stem.png.")
                                }
                            }
                        }
                        if ($optionIndex -eq 0) {
                            $problems.Add("$context has no options.")
                        }
                    }

                    $records.Add([pscustomobject]@{
                            Context = $context
                            Kind    = $kind
                            Fields  = $fields
                            Options = $ownOptions
                        })
                }

                foreach ($record in $records) {
                    $fields = $record.Fields
                    if ($fields.ContainsKey('default')) {
                        $default = Get-AtlasJsonString -Element $fields['default']
                        if ($record.Kind -ceq 'multiple') {
                            $problems.Add("$($record.Context) has a default, which only single choices take.")
                        }
                        elseif ($null -eq $default -or $record.Options -cnotcontains $default) {
                            $problems.Add("$($record.Context) has the default $($fields['default'].GetRawText()), which isn't one of its options.")
                        }
                    }
                    elseif ($record.Kind -ceq 'single') {
                        $problems.Add("$($record.Context) is a single choice without a default.")
                    }

                    if ($fields.ContainsKey('dependsOn')) {
                        $dependsOn = Get-AtlasJsonString -Element $fields['dependsOn']
                        if ($null -eq $dependsOn -or -not $optionIds.Contains($dependsOn)) {
                            $problems.Add("$($record.Context) depends on $($fields['dependsOn'].GetRawText()), which isn't a declared option.")
                        }
                        elseif ($record.Options -ccontains $dependsOn) {
                            $problems.Add("$($record.Context) depends on its own option '$dependsOn'.")
                        }
                    }
                }
            }
        }

        return $problems.ToArray()
    }
    finally {
        $document.Dispose()
    }
}

function ConvertTo-AtlasManifestJson {
    <#
    .SYNOPSIS
        Serialises a manifest node the way atlas.json is written: two-space indents, LF
        line endings, a final newline, and apostrophes and non-ASCII letters as they are.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][System.Text.Json.Nodes.JsonNode]$Manifest
    )

    $options = [System.Text.Json.JsonSerializerOptions]::new()
    $options.WriteIndented = $true
    $options.Encoder = [System.Text.Encodings.Web.JavaScriptEncoder]::UnsafeRelaxedJsonEscaping
    # Indented output breaks lines with the platform's line ending; line breaks inside
    # strings are always escaped, so every CRLF here is one of those breaks.
    return ($Manifest.ToJsonString($options) -replace "`r`n", "`n") + "`n"
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
        $candidate = "{0} ({1}){2}" -f $DisplayName, $counter, $script:PackageExtension
        $counter++
    }

    return $candidate
}

function Get-AtlasPackageFilePath {
    <#
    .SYNOPSIS
        Returns the normalised relative path of every file that belongs in an Atlas package.
    .DESCRIPTION
        The package/ folder defines what a package contains. Built packages and the
        files an interrupted build or publication leaves are the only files left out.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $PackagePath).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path -Path $resolvedRoot -ChildPath 'atlas.json') -PathType Leaf)) {
        throw "atlas.json not found in '$resolvedRoot'; it isn't an Atlas package source folder."
    }

    $extension = $script:PackageExtension
    return @(Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse |
        Where-Object {
            $_.Name -notlike "*$extension" -and
            $_.Name -notlike "*$extension.tmp" -and
            $_.Name -notlike "*$extension.*.building.tmp*"
        } |
        ForEach-Object {
            [IO.Path]::GetRelativePath($resolvedRoot, $_.FullName).Replace('\', '/')
        } |
        Sort-Object -CaseSensitive -Unique)
}

function Compare-AtlasPackageFilePath {
    <#
    .SYNOPSIS
        Compares the expected and archived package file paths without hiding duplicates.
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

function New-StagedAtlasManifest {
    <#
    .SYNOPSIS
        Writes a copy of atlas.json with the requested lists emptied, for test builds.
    .DESCRIPTION
        -RemoveRequirements empties requirements, so the front door runs only the checks it
        always runs. -RemoveSupportedBuilds empties supportedBuilds, so the front door
        refuses the package on every build while Atlas Manager can still open it. Every
        other field keeps its value and order.
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [switch]$RemoveRequirements,
        [switch]$RemoveSupportedBuilds
    )

    if (-not $RemoveRequirements -and -not $RemoveSupportedBuilds) {
        return $false
    }

    $manifest = [System.Text.Json.Nodes.JsonNode]::Parse((Read-AtlasManifestText -Path $ManifestPath))
    if ($manifest -isnot [System.Text.Json.Nodes.JsonObject]) {
        throw "'$ManifestPath' doesn't hold a JSON object."
    }
    if ($RemoveRequirements) {
        $manifest['requirements'] = [System.Text.Json.Nodes.JsonArray]::new()
    }
    if ($RemoveSupportedBuilds) {
        $manifest['supportedBuilds'] = [System.Text.Json.Nodes.JsonArray]::new()
    }

    Set-ParentDirectory -Path $DestinationPath
    [IO.File]::WriteAllText($DestinationPath, (ConvertTo-AtlasManifestJson -Manifest $manifest),
        [Text.UTF8Encoding]::new($false))

    return (Test-Path -LiteralPath $DestinationPath)
}

function Set-OemVersionStamp {
    <#
    .SYNOPSIS
        Writes a copy of the OEM information script with the AtlasVersionUndefined
        placeholder replaced by the package version label.
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

function New-AtlasPackage {
    <#
    .SYNOPSIS
        Packs the package/ folder into an Atlas package (.atlaspkg), with the test-build
        overrides applied on top.
    .DESCRIPTION
        The package is a ZIP archive whose entries are encrypted with AES-256 under the
        public password, unless -NoPassword is given. It's built beside its destination,
        checked with 7-Zip and Test-Package.ps1, and only then moved into place, so a
        failed build leaves an existing package as it was.
    .OUTPUTS
        Full path of the built package.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PackagePath,
        [string]$OutputDirectory,
        [string]$FileName = 'Atlas Test',
        [switch]$RemoveRequirements,
        [switch]$RemoveSupportedBuilds,
        [switch]$NoPassword,
        [switch]$ReplaceExisting
    )

    $PackagePath = (Resolve-Path -LiteralPath $PackagePath).ProviderPath
    $manifestPath = Join-Path -Path $PackagePath -ChildPath 'atlas.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "atlas.json not found in '$PackagePath'; it isn't an Atlas package source folder."
    }

    if (-not $OutputDirectory) {
        $OutputDirectory = $PackagePath
    }
    $OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).ProviderPath

    $sevenZipPath = Resolve-SevenZip

    $packageFileName = Get-AvailableArchiveName -BaseName "$FileName$script:PackageExtension" `
        -WorkingDirectory $OutputDirectory -DisplayName $FileName -AllowReplace:$ReplaceExisting
    $packageFile = Join-Path -Path $OutputDirectory -ChildPath $packageFileName
    Assert-NoAtlasPublicationArtifact -Directory $PackagePath
    $pathComparison = if ($script:IsWindowsPlatform) {
        [StringComparison]::OrdinalIgnoreCase
    }
    else {
        [StringComparison]::Ordinal
    }
    if (-not [string]::Equals(
            $PackagePath,
            $OutputDirectory,
            $pathComparison)) {
        Assert-NoAtlasPublicationArtifact -Directory $OutputDirectory
    }
    $publicationId = [guid]::NewGuid().ToString('N')
    $buildPath = '{0}.{1}.building.tmp' -f `
        $packageFile,
        $publicationId

    $rootTempDir = $null
    $filesListPath = $null
    $previousLocation = Get-Location

    try {
        Set-Location -LiteralPath $PackagePath

        # Staged overrides are written into a temp mirror of the package/ tree and added
        # to the archive after the main pass, in place of the originals.
        $rootTempDir = New-TemporaryDirectory
        $stagingPath = Join-Path -Path $rootTempDir.FullName -ChildPath 'package'
        New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
        $stagedPaths = [System.Collections.Generic.List[string]]::new()

        $stagedManifest = New-StagedAtlasManifest `
            -ManifestPath $manifestPath `
            -DestinationPath (Join-Path -Path $stagingPath -ChildPath 'atlas.json') `
            -RemoveRequirements:$RemoveRequirements `
            -RemoveSupportedBuilds:$RemoveSupportedBuilds
        if ($stagedManifest) {
            $stagedPaths.Add('atlas.json')
        }

        $oemScriptRelativePath = 'Executables/AtlasModules/Scripts/Install/Tasks/Set-OemInformation.ps1'
        try {
            $versionInfo = Get-AtlasPackageVersion -ManifestPath $manifestPath
            $stagedOemScript = Set-OemVersionStamp `
                -ScriptPath (Join-Path -Path $PackagePath -ChildPath $oemScriptRelativePath) `
                -VersionLabel $versionInfo.VersionLabel `
                -DestinationPath (Join-Path -Path $stagingPath -ChildPath $oemScriptRelativePath)
            if ($stagedOemScript) {
                $stagedPaths.Add($oemScriptRelativePath)
            }
        }
        catch {
            Write-Warning "Failed to process OEM information: $($_.Exception.Message)"
        }

        # Files replaced by staged overrides stay out of the main pass so the archive never
        # holds two copies of one path.
        $relativePaths = @(Get-AtlasPackageFilePath -PackagePath $PackagePath |
            Where-Object { $stagedPaths -cnotcontains $_ })

        $filesListPath = [IO.Path]::GetTempFileName()
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($filesListPath, [string[]]$relativePaths, $utf8NoBom)

        $encryptionArgs = @()
        $testPasswordArgs = @()
        if (-not $NoPassword) {
            $encryptionArgs = @('-mem=AES256', "-p$script:PackagePassword")
            $testPasswordArgs = @("-p$script:PackagePassword")
        }

        # Fastest compression. -bso0 and -bsp0 silence normal output and progress; errors
        # stay on stderr so Invoke-SevenZip can say which file failed and why.
        $archiveArgs = @('a', '-tzip', '-y', '-mx1', '-bso0', '-bsp0')
        if ($script:IsWindowsPlatform) {
            $archiveArgs += '-spf'
        }
        $archiveArgs += $encryptionArgs
        $archiveArgs += $buildPath
        # The @listfile syntax must not be quoted or 7-Zip misparses it.
        $archiveArgs += "@$filesListPath"

        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $archiveArgs `
            -ErrorContext 'Creating the package archive' -ArchivePath $buildPath | Out-Null

        if ($stagedPaths.Count -gt 0) {
            Set-Location -LiteralPath $stagingPath
            try {
                # The update pass needs the encryption method too: 7-Zip would otherwise
                # protect the added entries with legacy ZipCrypto.
                $updateArgs = @('u', '-tzip', '-mx1', '-bso0', '-bsp0')
                $updateArgs += $encryptionArgs
                $updateArgs += $buildPath
                $updateArgs += '*'

                Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $updateArgs `
                    -ErrorContext 'Adding staged overrides' -ArchivePath $buildPath | Out-Null
            }
            finally {
                Set-Location -LiteralPath $PackagePath
            }
        }

        $integrityArgs = @('t', '-bso0', '-bsp0') +
            $testPasswordArgs + @($buildPath)
        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $integrityArgs `
            -ErrorContext 'Verifying the built package archive' | Out-Null

        $semanticArchiveStream = [IO.File]::Open(
            $buildPath,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )
        try {
            $preVerificationSha256 = Get-AtlasStreamSha256 -Stream $semanticArchiveStream
            Invoke-AtlasPackageVerifier `
                -Path $buildPath `
                -PackagePath $PackagePath `
                -NoPassword:$NoPassword
            $postVerificationSha256 = Get-AtlasStreamSha256 -Stream $semanticArchiveStream
            if ($preVerificationSha256 -cne $postVerificationSha256) {
                throw 'The package sibling changed during semantic verification.'
            }
        }
        finally {
            $semanticArchiveStream.Dispose()
        }

        Publish-AtlasVerifiedArchive `
            -SourcePath $buildPath `
            -DestinationPath $packageFile `
            -ExpectedSha256 $postVerificationSha256 `
            -AllowReplace:$ReplaceExisting

        return $packageFile
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
                    Set-Location -LiteralPath $PackagePath -ErrorAction Stop
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
            if ($buildPath -and (Test-Path -LiteralPath $buildPath)) {
                Remove-Item -LiteralPath $buildPath -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # A stale sibling is rejected at the start of the next build.
            $null = $_
        }

        try {
            $buildLeaf = Split-Path -Path $buildPath -Leaf
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
