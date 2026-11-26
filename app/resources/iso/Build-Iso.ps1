<#
.SYNOPSIS
    Checks a Windows ISO and builds Atlas installation media from it.
.DESCRIPTION
    The host-side image worker. It never runs an Atlas package or writes the host's
    setup keys. Atlas Manager stages it in a protected media job folder (see
    Stage-App.ps1) and runs it elevated with -File; app\tools\Run-IsoValidation.ps1
    runs it the same way outside the app.

    It writes lines for the app on standard output: ATLAS_STAGE for each stage,
    ATLAS_PROGRESS with the bytes written while Master-Iso.ps1 writes the ISO,
    ATLAS_ERROR with a typed failure reason, ATLAS_RESULT with the ISO's editions, size
    and architecture, and ATLAS_NOTE when this PC has no network drivers to copy. A file
    named cancel in the job folder stops the build at the next stage.
.PARAMETER RequestFile
    The request.json Atlas Manager writes in the job folder: the source ISO, the output
    path, the Atlas package and app to add, and the setup choices.
.PARAMETER Operation
    Inspect checks the ISO and reports what it contains. Build also writes the new ISO.
.NOTES
    Exit codes: 0 inspected or built, 1 failed or cancelled (the error is on standard
    error).
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RequestFile, [ValidateSet('Inspect', 'Build')][string]$Operation)
# This elevated worker must never autoload a module from an inherited user path.
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$ProgressPreference = 'SilentlyContinue'
$job = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($RequestFile))
$request = [IO.File]::ReadAllText($RequestFile) | ConvertFrom-Json
# Rust may hand over paths in the \\?\ verbatim form, which -LiteralPath accepts
# but Join-Path and the other path cmdlets cannot parse ("drive is null").
function ConvertFrom-VerbatimPath([string]$Path) {
    if ($Path.StartsWith('\\?\UNC\')) { return '\\' + $Path.Substring(8) }
    if ($Path.StartsWith('\\?\')) { return $Path.Substring(4) }
    return $Path
}
foreach ($name in @('source', 'output', 'archive', 'package', 'app')) {
    if ($null -ne $request.PSObject.Properties[$name]) { $request.$name = ConvertFrom-VerbatimPath ([string]$request.$name) }
}
. (Join-Path $PSScriptRoot 'Windows-Release.ps1')
. (Join-Path $PSScriptRoot 'Iso-Mount.ps1')
$ownedMount = $false
$work = $null
$workParent = $null
$partial = $null
$source = $null
$appStream = $null
$mutex = $null
$ownsMutex = $false

# Markers for the app go straight to the console: Write-Output would be lost
# inside a function whose output a caller captures.
function Write-Stage([string]$Stage) {
    [Console]::Out.WriteLine("ATLAS_STAGE:$Stage")
    if (Test-Path -LiteralPath (Join-Path $job 'cancel')) { throw 'Cancelled at a safe checkpoint.' }
}
# A typed reason the app turns into advice; the message goes to the log.
function Fail([string]$Reason, [string]$Message) {
    [Console]::Out.WriteLine("ATLAS_ERROR:$Reason")
    throw $Message
}
function Open-AtlasIsoManager([string]$Path) {
    # A browser may remove its temporary download during the build. Keep reading
    # the same file after a rename or deletion, while allowing that cleanup.
    try {
        return [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::Read -bor [IO.FileShare]::Delete))
    } catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] {
        Fail 'manager-missing' "Atlas Manager is no longer at '$Path'. Download it to a local folder and launch it again."
    }
}
function Assert-PlainTree([string]$Path) {
    $root = Get-Item -LiteralPath $Path -Force
    if ($root.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point: $Path" }
    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -Recurse) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point: $($item.FullName)" }
    }
}
# El Torito: 2048-byte sectors with volume descriptors from sector 16; the boot
# record holds the catalog's sector at byte 71. The catalog's validation entry
# sums to zero, 0x88 marks a bootable entry and platform 0xEF is UEFI.
function Assert-BootCatalog([string]$Path, [ValidateSet('x64','arm64')][string]$Architecture = 'x64') {
    $stream = [IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] 2048
        for ($sector = 16; $sector -lt 48; $sector++) {
            [void]$stream.Seek([long]$sector * 2048, [IO.SeekOrigin]::Begin)
            if ($stream.Read($buffer, 0, 2048) -ne 2048) { throw 'Truncated volume descriptors.' }
            if ($buffer[0] -eq 0 -and [Text.Encoding]::ASCII.GetString($buffer, 1, 5) -eq 'CD001' -and
                [Text.Encoding]::ASCII.GetString($buffer, 7, 23) -eq 'EL TORITO SPECIFICATION') {
                $lba = [BitConverter]::ToUInt32($buffer, 71)
                [void]$stream.Seek([long]$lba * 2048, [IO.SeekOrigin]::Begin)
                if ($stream.Read($buffer, 0, 2048) -ne 2048) { throw 'Truncated boot catalog.' }
                $checksum = 0
                for ($i = 0; $i -lt 32; $i += 2) { $checksum += [BitConverter]::ToUInt16($buffer, $i) }
                if (($checksum -band 0xffff) -ne 0 -or $buffer[0] -ne 1 -or
                    $buffer[30] -ne 0x55 -or $buffer[31] -ne 0xaa -or $buffer[32] -ne 0x88) {
                    throw 'The output does not contain a valid boot catalog.'
                }
                if ($Architecture -eq 'arm64') {
                    if ($buffer[1] -ne 0xef) { throw 'The output does not contain a bootable UEFI entry for ARM64.' }
                } elseif ($buffer[1] -ne 0 -or $buffer[64] -notin @(0x90, 0x91) -or $buffer[65] -ne 0xef -or $buffer[96] -ne 0x88) {
                    throw 'The output does not contain valid BIOS and UEFI boot entries.'
                }
                return
            }
        }
        throw 'The output has no El Torito boot catalog.'
    }
    finally { $stream.Dispose() }
}
function Initialize-AtlasIsoDestinationVolume {
    if (-not ('AtlasIsoDestinationVolume' -as [type])) {
        Add-Type -TypeDefinition @'
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public sealed class AtlasIsoDestinationVolume {
    public string FileSystem;
    public ulong AvailableBytes;

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
    static extern bool GetVolumePathNameW(string path, StringBuilder root, uint size);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true)]
    static extern uint GetDriveTypeW(string root);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
    static extern bool GetVolumeInformationW(string root, System.IntPtr label, uint labelSize,
        System.IntPtr serial, System.IntPtr maxComponentLength, System.IntPtr flags,
        StringBuilder fileSystem, uint fileSystemSize);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
    static extern bool GetDiskFreeSpaceExW(string path, out ulong availableBytes,
        System.IntPtr totalBytes, System.IntPtr freeBytes);

    public static AtlasIsoDestinationVolume Read(string path) {
        var root = new StringBuilder(32768);
        if (!GetVolumePathNameW(path, root, (uint)root.Capacity))
            throw Failure("GetVolumePathNameW");

        string mount = root.ToString();
        uint driveType = GetDriveTypeW(mount);
        if (driveType <= 1 || driveType == 4) // Unknown, missing or remote
            throw new IOException("The destination does not resolve to a local volume.");

        var fileSystem = new StringBuilder(260);
        if (!GetVolumeInformationW(mount, System.IntPtr.Zero, 0, System.IntPtr.Zero,
            System.IntPtr.Zero, System.IntPtr.Zero, fileSystem, (uint)fileSystem.Capacity))
            throw Failure("GetVolumeInformationW");

        ulong availableBytes;
        if (!GetDiskFreeSpaceExW(path, out availableBytes, System.IntPtr.Zero, System.IntPtr.Zero))
            throw Failure("GetDiskFreeSpaceExW");
        return new AtlasIsoDestinationVolume { FileSystem = fileSystem.ToString(), AvailableBytes = availableBytes };
    }

    public static string Root(string path) {
        var root = new StringBuilder(32768);
        if (!GetVolumePathNameW(path, root, (uint)root.Capacity))
            throw Failure("GetVolumePathNameW");
        return root.ToString();
    }

    // Names the call Windows refused, as some PCs refuse one of these for their system
    // drive ("A required privilege is not held by the client").
    static Win32Exception Failure(string call) {
        int error = Marshal.GetLastWin32Error();
        return new Win32Exception(error, call + ": " + new Win32Exception(error).Message);
    }
}
'@
    }
}
function Get-AtlasIsoDestinationVolume([string]$Path) {
    Initialize-AtlasIsoDestinationVolume
    return [AtlasIsoDestinationVolume]::Read($Path)
}
# Whether the drive letter $Folder starts with names the volume that holds it: no link or
# mount point on the way leads to another volume.
function Test-AtlasIsoLetterVolume($Folder) {
    if ($Folder.FullName -notmatch '^[A-Za-z]:\\') { return $false }
    for ($item = $Folder; $null -ne $item; $item = $item.Parent) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -and @('SymbolicLink', 'Junction') -contains $item.LinkType) { return $false }
    }
    return $true
}
# The filesystem and free space of the volume that holds $Folder, read by its drive letter
# with Get-Volume, which needs none of the calls Windows can refuse; nothing where that
# letter doesn't name the folder's volume, or Get-Volume can't say.
function Get-AtlasIsoVolumeByLetter($Folder) {
    if (-not (Test-AtlasIsoLetterVolume $Folder)) { return $null }
    try {
        $parameters = Get-AtlasIsoStorageParameters
        $found = @(Receive-AtlasIsoStorage (Get-Volume -DriveLetter $Folder.FullName[0] @parameters) 'reading the destination volume')
    }
    catch { return $null }
    if ($found.Count -ne 1 -or $null -eq $found[0].PSObject.Properties['FileSystem'] -or $null -eq $found[0].PSObject.Properties['SizeRemaining']) { return $null }
    return [pscustomobject]@{ FileSystem = [string]$found[0].FileSystem; AvailableBytes = [uint64]$found[0].SizeRemaining }
}
# The mount point of the volume that holds $Path, through any junction on the way, or the
# path's own drive root where Windows refuses the call and that letter names the volume.
function Get-AtlasIsoVolumeRoot([string]$Path) {
    Initialize-AtlasIsoDestinationVolume
    try { return [AtlasIsoDestinationVolume]::Root($Path) }
    catch {
        if (-not (Test-AtlasIsoLetterVolume (Get-Item -LiteralPath $Path))) { throw }
        return [IO.Path]::GetPathRoot($Path)
    }
}
# The length a copy of the tree at $Root needs beyond the folder it goes in: its longest
# file path, or folder path with 12 characters to spare, relative to $Root.
function Get-AtlasIsoDeepestPath([string]$Root) {
    $deepest = 0
    foreach ($item in Get-ChildItem -LiteralPath $Root -Force -Recurse) {
        $length = $item.FullName.Length - $Root.Length + $(if ($item.PSIsContainer) { 12 } else { 0 })
        if ($length -gt $deepest) { $deepest = $length }
    }
    return $deepest
}
# The workspace $Name, whose media folder takes a copy needing $Deepest more characters.
# Windows PowerShell's file cmdlets stop at MAX_PATH: a file's path must stay under 260
# characters, and a folder's under 248, room for an 8.3 name in it. The workspace goes
# beside the output in $Parent or, when that's too deep, at the root of the same volume,
# so the finished ISO is still only renamed into place.
function Get-AtlasIsoWorkspace([string]$Parent, [string]$Name, [int]$Deepest) {
    $work = Join-Path $Parent $Name
    if ((Join-Path $work 'media\').Length + $Deepest -lt 260) { return $work }
    $root = Get-AtlasIsoVolumeRoot $Parent
    $atRoot = Join-Path $root $Name
    if ((Join-Path $atRoot 'media\').Length + $Deepest -lt 260) { return $atRoot }
    Fail 'destination-path' "The ISO's files need $Deepest characters beyond the workspace, more than MAX_PATH leaves beside '$Parent' or at '$root'. Save the ISO to a folder with a shorter path."
}
function Assert-Output([string]$OutputPath, [string]$PackagePath, [string]$SourcePath) {
    if ([IO.Path]::GetExtension($OutputPath) -ine '.iso') { throw 'Output must end in .iso.' }
    if (Test-Path -LiteralPath $OutputPath) { Fail 'output-exists' 'Output already exists. Choose a new filename.' }
    $parent = Get-Item -LiteralPath ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutputPath)))
    if ($parent.FullName.StartsWith('\\')) { Fail 'destination-filesystem' 'Choose a local NTFS or ReFS destination.' }
    # Query the real mount point even for a directory reached through a junction.
    try { $volume = Get-AtlasIsoDestinationVolume -Path $parent.FullName }
    catch {
        # The message names the call Windows refused. Only a refused call has a fallback:
        # a volume that isn't local stays refused.
        $failure = $_.Exception.GetBaseException()
        $volume = if ($failure -is [ComponentModel.Win32Exception]) { Get-AtlasIsoVolumeByLetter $parent }
        if ($null -eq $volume) { Fail 'destination-filesystem' "Could not read the volume for '$($parent.FullName)': $($failure.Message)" }
        [Console]::Error.WriteLine("Could not read the volume for '$($parent.FullName)' ($($failure.Message)), so Get-Volume read it by its drive letter.")
    }
    if ($volume.FileSystem -notin @('NTFS', 'ReFS')) {
        Fail 'destination-filesystem' 'Choose an NTFS or ReFS destination for large installation files.'
    }
    # Conservative budget: extracted media, output, package, plus scratch headroom.
    $packageBytes = (Get-ChildItem -LiteralPath $PackagePath -File -Force -Recurse | Measure-Object Length -Sum).Sum
    $required = 5 * (Get-Item -LiteralPath $SourcePath).Length + 2 * [long]$packageBytes + 4GB
    if ($volume.AvailableBytes -lt $required) { Fail 'disk-space' "Not enough free space. Required: $required bytes." }
    return $parent.FullName
}
function Get-AtlasMediaEditions([string]$ImagePath, [int[]]$SupportedBuilds, [switch]$OfflineReleaseCheck) {
    $architecture = $null
    foreach ($summary in @(Get-WindowsImage -ImagePath $ImagePath)) {
        $info = Get-WindowsImage -ImagePath $ImagePath -Index $summary.ImageIndex
        $version = [version]$info.Version
        # DISM architecture: 9 = x64, 12 = ARM64.
        if ([int]$info.Architecture -notin @(9,12) -or $SupportedBuilds -notcontains $version.Build) {
            Fail 'windows-unsupported' "Unsupported Windows image: $($info.ImageName), $($info.Version), architecture $($info.Architecture)."
        }
        if ($null -ne $architecture -and $architecture -ne [int]$info.Architecture) {
            Fail 'windows-unsupported' 'Mixed x64 and ARM64 installation images are not supported.'
        }
        $architecture = [int]$info.Architecture
        if ($info.InstallationType -ne 'Client') { Fail 'windows-unsupported' 'Only Windows client installation media is supported.' }
        $release = Get-AtlasWindowsReleaseStatus -Version $version -NoRefresh:$OfflineReleaseCheck
        if ($release -eq 'Unlisted') {
            Fail 'windows-release-unlisted' "The Windows image version $version is not in Microsoft's list of public Windows 11 releases. Release Preview and other preview builds are not supported."
        }
        if ($release -ne 'Released') {
            Fail 'windows-release-unknown' "The Windows image version $version could not be verified as a public release. Connect to the internet and retry, or choose official release media."
        }
        # Skip the editions Install-Atlas.ps1 refuses (Home and LTSC). Consumer media
        # also carries Home; keep every supported edition for Setup to offer.
        $edition = [string]$info.EditionId
        if ([string]::IsNullOrWhiteSpace($edition)) { throw 'The Windows image has no edition identity.' }
        if ($edition -like 'Core*' -or $edition -in @('EnterpriseS','EnterpriseSN','EnterpriseSEval','EnterpriseSNEval','IoTEnterpriseS','IoTEnterpriseSK')) { continue }
        $info
    }
}
function Get-AtlasMediaTerms([string]$Image, [object[]]$Editions, [string]$Root, [string]$Job) {
    if (-not ('AtlasIsoLicense' -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class AtlasIsoLicense {
    [DllImport("wimgapi.dll", CharSet=CharSet.Unicode, ExactSpelling=true)]
    static extern IntPtr WIMCreateFile(string path, uint access, uint disposition, uint flags, uint compression, out uint result);
    [DllImport("wimgapi.dll", CharSet=CharSet.Unicode, ExactSpelling=true)]
    static extern bool WIMSetTemporaryPath(IntPtr image, string path);
    [DllImport("wimgapi.dll")] static extern IntPtr WIMLoadImage(IntPtr file, uint index);
    [DllImport("wimgapi.dll", CharSet=CharSet.Unicode, ExactSpelling=true)]
    static extern bool WIMExtractImagePath(IntPtr image, string source, string destination, uint flags);
    [DllImport("wimgapi.dll")] static extern bool WIMCloseHandle(IntPtr handle);
    public static bool Extract(string file, uint index, string source, string output, string temp) {
        uint result;
        IntPtr wim = WIMCreateFile(file, 0x80000000, 3, 0, 0, out result);
        if (wim == IntPtr.Zero) return false;
        try {
            if (!WIMSetTemporaryPath(wim, temp)) return false;
            IntPtr image = WIMLoadImage(wim, index);
            if (image == IntPtr.Zero) return false;
            try { return WIMExtractImagePath(image, source, output, 0); }
            finally { WIMCloseHandle(image); }
        } finally { WIMCloseHandle(wim); }
    }
}
"@
    }
    $channel = '_Default'
    $config = Join-Path $Root 'sources\ei.cfg'
    if (Test-Path -LiteralPath $config) {
        $ini = [IO.File]::ReadAllText($config)
        if ($ini -match '(?im)^\[VL\]\s*1\s*$' -or $ini -match '(?im)^\[Channel\]\s*Volume\s*$') { $channel = 'Volume' }
        elseif ($ini -match '(?im)^\[Channel\]\s*OEM\s*$') { $channel = 'OEM' }
    }
    foreach ($edition in $Editions) {
        $digest = ''
        $id = [string]$edition.EditionId
        $languages = @($edition.Languages)
        $lang = if ($edition.DefaultLanguageIndex -ge 0 -and $edition.DefaultLanguageIndex -lt $languages.Count) {
            [string]$languages[$edition.DefaultLanguageIndex]
        }
        if ($id -ne 'EnterpriseEval' -and $id -match '^[a-zA-Z0-9]+$' -and $lang -match '^[a-zA-Z0-9-]+$') {
            $inside = "\Windows\System32\$lang\Licenses\$channel\$id\license.rtf"
            $file = Join-Path $Job ("license-" + [int]$edition.ImageIndex + '.rtf')
            $baseEdition = if ($id.EndsWith('N')) { 'ProfessionalN' } else { 'Professional' }
            # Business media can carry one shared volume agreement in the base Pro image.
            if ([AtlasIsoLicense]::Extract($Image, $edition.ImageIndex, $inside, $file, $Job) -or
                ($channel -eq 'Volume' -and [AtlasIsoLicense]::Extract($Image, $edition.ImageIndex, "\Windows\System32\$lang\Licenses\Volume\$baseEdition\license.rtf", $file, $Job)) -or
                [AtlasIsoLicense]::Extract($Image, $edition.ImageIndex, '\Windows\System32\license.rtf', $file, $Job)) {
                $candidateHash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
                Add-Type -AssemblyName System.Windows.Forms
                $reader = New-Object Windows.Forms.RichTextBox
                try {
                    $reader.LoadFile($file)
                    $textFile = Join-Path $Job ("windows-terms-" + $candidateHash + '.txt')
                    if (![string]::IsNullOrWhiteSpace($reader.Text)) {
                        [IO.File]::WriteAllText($textFile, $reader.Text, [Text.Encoding]::UTF8)
                        $digest = $candidateHash
                    }
                } catch [ArgumentException] {
                    Write-Verbose "Could not read the licence terms for $id. Windows Setup will display them."
                } finally { $reader.Dispose() }
            }
        }
        $digest
    }
}
# Whether a DISM cmdlet failed for want of native code of this process's architecture
# (0x8007000B), as on Arm64 Windows, where Atlas Manager and its workers run as x64.
function Test-AtlasWrongArchitecture($Failure) {
    for ($exception = $Failure.Exception; $null -ne $exception; $exception = $exception.InnerException) {
        if ($exception -is [BadImageFormatException] -or $exception.HResult -eq -2147024885) { return $true }
    }
    return $false
}
# Exports one edition with Windows' own DISM, which runs natively whatever this process's
# architecture, with the same compression and integrity check as Export-WindowsImage.
function Invoke-AtlasDismExport([string]$SourceImage, [int]$Index, [string]$DestinationImage, [string]$Dism = (Join-Path ([Environment]::GetFolderPath('System')) 'dism.exe')) {
    # DISM reports on standard output; its standard error goes to the build log as it is.
    $output = @(& $Dism /English /Export-Image "/SourceImageFile:$SourceImage" "/SourceIndex:$Index" "/DestinationImageFile:$DestinationImage" /Compress:max /CheckIntegrity)
    if ($LASTEXITCODE -ne 0) {
        throw "DISM couldn't export image $Index (exit code $LASTEXITCODE): $((@($output | Where-Object { "$_".Trim() }) | Select-Object -Last 3) -join ' ')"
    }
}
function Export-AtlasMediaEditions([string]$SourceImage, [string]$DestinationImage, [object[]]$Editions) {
    if (Test-Path -LiteralPath $DestinationImage) { throw 'The filtered Windows image already exists.' }
    if ($Editions.Count -eq 0) { Fail 'edition-unsupported' 'The ISO contains no supported Windows editions.' }
    try {
        foreach ($edition in $Editions) {
            Write-Stage copy
            Export-WindowsImage -SourceImagePath $SourceImage -SourceIndex $edition.ImageIndex -DestinationImagePath $DestinationImage -CompressionType Max -CheckIntegrity -ErrorAction Stop | Out-Null
        }
    }
    catch {
        if (-not (Test-AtlasWrongArchitecture $_)) { throw }
        # The cmdlet can fail after writing the image, so the export starts again from nothing.
        [Console]::Error.WriteLine("The DISM module can't run in this process, so dism.exe exports the editions: $($_.Exception.Message)")
        if (Test-Path -LiteralPath $DestinationImage) { Remove-Item -LiteralPath $DestinationImage -Force }
        foreach ($edition in $Editions) {
            Write-Stage copy
            Invoke-AtlasDismExport $SourceImage $edition.ImageIndex $DestinationImage
        }
    }
    $actual = @(Get-WindowsImage -ImagePath $DestinationImage)
    if ($actual.Count -ne $Editions.Count) { throw 'The filtered Windows image has an unexpected edition count.' }
    for ($index = 0; $index -lt $actual.Count; $index++) {
        $info = Get-WindowsImage -ImagePath $DestinationImage -Index $actual[$index].ImageIndex
        $expected = $Editions[$index]
        if ($info.EditionId -ne $expected.EditionId -or $info.ImageName -ne $expected.ImageName -or
            [version]$info.Version -ne [version]$expected.Version -or [int]$info.Architecture -ne [int]$expected.Architecture -or $info.InstallationType -ne 'Client') {
            throw 'The filtered Windows image does not match the selected editions.'
        }
    }
}
try {
    $mutex = New-Object Threading.Mutex($false, 'Global\AtlasOS.ISO.Build')
    try { $ownsMutex = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) { throw 'Another Atlas ISO operation is running. Wait for it to finish.' }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Administrator access is required.' }
    Write-Stage inspect
    if ($Operation -eq 'Build') { $appStream = Open-AtlasIsoManager $request.app }
    $source = (Get-Item -LiteralPath $request.source).FullName
    if ([IO.Path]::GetExtension($source) -ine '.iso') { throw 'Choose a Windows ISO file.' }
    # Only a build writes the output. The app checks its folder before Create,
    # where it can be changed, so a check of the files never fails on it.
    if ($Operation -eq 'Build') { $parent = Assert-Output -OutputPath $request.output -PackagePath $request.package -SourcePath $source }
    $disk = Get-AtlasIsoImage $source
    if (-not $disk.Attached) {
        $disk = Mount-AtlasIso $source -ReadOnly
        $ownedMount = $true
    }
    $root = Get-AtlasIsoRoot -ImagePath $source -Disk $disk -Owned:$ownedMount
    foreach ($relative in @('setup.exe', 'sources\boot.wim', 'efi\microsoft\boot\efisys.bin')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) { throw "Windows installation file missing: $relative" }
    }
    foreach ($relative in @('autounattend.xml', 'unattend.xml', 'sources\autounattend.xml', 'sources\unattend.xml', 'sources\$OEM$')) {
        if (Test-Path -LiteralPath (Join-Path $root $relative)) { Fail 'iso-customised' "This ISO already has custom setup content ($relative). Choose unmodified Microsoft media." }
    }
    $images = @('sources\install.wim', 'sources\install.esd' | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path -LiteralPath $_ })
    if ($images.Count -ne 1) { throw 'Expected one install.wim or install.esd. Split images are not supported in this Beta.' }
    Import-Module Dism -ErrorAction Stop
    $sourceEditionCount = @(Get-WindowsImage -ImagePath $images[0]).Count
    $supportedEditions = @(Get-AtlasMediaEditions -ImagePath $images[0] -SupportedBuilds $request.supportedBuilds -OfflineReleaseCheck:($null -ne $request.PSObject.Properties['offlineReleaseCheck'] -and $request.offlineReleaseCheck -eq $true))
    $editions = @($supportedEditions | ForEach-Object { [string]$_.ImageName })
    if ($editions.Count -eq 0) { Fail 'edition-unsupported' 'The ISO contains no supported Windows editions. Windows Home and LTSC are not supported.' }
    $architecture = if ([int]$supportedEditions[0].Architecture -eq 12) { 'arm64' } else { 'x64' }
    $bootFiles = if ($architecture -eq 'arm64') { @('efi\boot\bootaa64.efi') } else { @('efi\boot\bootx64.efi', 'boot\etfsboot.com') }
    foreach ($relative in $bootFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { Fail 'windows-unsupported' "Windows $architecture boot file missing: $relative" }
    }
    if ($request.copyNetworkDrivers) {
        # Win32_Processor reports architecture with the same codes as DISM.
        $hostArchitectures = @(Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Architecture -Unique)
        if ($hostArchitectures.Count -ne 1 -or [int]$hostArchitectures[0] -ne [int]$supportedEditions[0].Architecture) {
            Fail 'network-architecture' 'Network drivers cannot be copied between x64 and ARM64. Choose media for this PC or turn off network driver copying.'
        }
    }
    $acceptedTerms = if ($request.PSObject.Properties['acceptedTerms']) { [string]$request.acceptedTerms }
    $chosenEdition = if ($request.PSObject.Properties['edition']) { [string]$request.edition }
    if ($chosenEdition) {
        $supportedEditions = @($supportedEditions | Where-Object { $_.ImageName -ceq $chosenEdition })
        if ($supportedEditions.Count -ne 1) { Fail 'edition-unsupported' 'The selected edition is no longer available. Check the ISO again.' }
    }
    $editionTerms = @()
    if ($Operation -eq 'Inspect' -or $acceptedTerms) {
        $editionTerms = @(Get-AtlasMediaTerms $images[0] $supportedEditions $root $job)
    }
    if ($acceptedTerms -and (@($editionTerms | Where-Object { $_ -cne $acceptedTerms }).Count -or !$editionTerms.Count)) {
        throw 'The Windows licence terms changed. Check the files and review the terms again.'
    }
    Write-Output ('ATLAS_RESULT:' + (@{ editions = $editions; editionTerms = $editionTerms; bytes = (Get-Item -LiteralPath $source).Length; architecture = $architecture } | ConvertTo-Json -Compress))
    if ($Operation -eq 'Inspect') { exit 0 }
    if ($request.mode -notin @('interactive', 'configured', 'before-desktop')) { throw 'Unknown setup mode.' }
    if ($request.copyNetworkDrivers -and -not $request.reinstallThisPc) { throw 'Network driver copying is only available when reinstalling this PC.' }
    if ($request.updateNetworkDrivers -and -not $request.copyNetworkDrivers) { throw 'Network driver updates require network driver copying.' }
    $packageManifest = Get-Content -LiteralPath (Join-Path $request.package 'atlas.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $packageVersion = [version]([string]$packageManifest.version -replace '-.*$', '')
    if ($packageVersion -lt [version]'0.6.0') { throw 'ISO creation requires Atlas 0.6.0 or newer.' }
    Assert-PlainTree $request.package
    if ($request.mode -ne 'interactive') {
        $cap = Get-Content -LiteralPath (Join-Path $request.package 'Executables\AtlasModules\Scripts\Install\iso-setup.json') -Raw | ConvertFrom-Json
        if ($cap.schema -ne 1 -or $cap.firstSignIn -ne $true) { throw 'The package does not support ISO setup.' }
    }
    $id = [guid]::NewGuid().ToString('N')
    $work = Get-AtlasIsoWorkspace -Parent $parent -Name ".atlas-iso-$id" -Deepest (Get-AtlasIsoDeepestPath $root)
    $workParent = [IO.Path]::GetDirectoryName($work)
    $partial = Join-Path $parent ".atlas-iso-$id.partial"
    # The elevated worker creates the private tree with its final ACL atomically:
    # full control for SYSTEM (S-1-5-18) and Administrators (S-1-5-32-544) only.
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule((New-Object Security.Principal.SecurityIdentifier($sid)), 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
    }
    [void][IO.Directory]::CreateDirectory($work, $acl)
    [IO.File]::WriteAllText((Join-Path $job 'workspace.txt'), $work)
    $media = Join-Path $work 'media'
    [void][IO.Directory]::CreateDirectory($media)
    Write-Stage copy
    Assert-PlainTree $root
    foreach ($item in Get-ChildItem -LiteralPath $root -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $media -Recurse -Force
    }
    $imageRelative = 'sources\' + [IO.Path]::GetFileName($images[0])
    $mediaImage = Join-Path $media $imageRelative
    if ((Get-FileHash -LiteralPath $images[0]).Hash -ne (Get-FileHash -LiteralPath $mediaImage).Hash) { throw 'Windows installation image copy verification failed.' }
    if ($supportedEditions.Count -ne $sourceEditionCount) {
        $filteredImage = Join-Path $work 'supported.wim'
        Export-AtlasMediaEditions -SourceImage $images[0] -DestinationImage $filteredImage -Editions $supportedEditions
        # Replace only the workspace copy. The answer file selects no image and
        # sets no key, so Setup offers exactly these editions.
        Remove-Item -LiteralPath $mediaImage -Force
        $imageRelative = 'sources\install.wim'
        $mediaImage = Join-Path $media $imageRelative
        [IO.File]::Move($filteredImage, $mediaImage)
    }
    Write-Stage add-atlas
    # Windows Setup copies $OEM$\$$ into %WINDIR%, so these land in %WINDIR%\AtlasISO.
    $atlasIso = 'sources\$OEM$\$$\AtlasISO'
    $target = Join-Path $media $atlasIso
    [void][IO.Directory]::CreateDirectory($target)
    $managerName = 'AtlasManager.exe'
    $managerOutput = [IO.File]::Open((Join-Path $target $managerName), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $appStream.CopyTo($managerOutput) }
    finally { $managerOutput.Dispose() }
    $appStream.Dispose()
    $appStream = $null
    $payload = [ordered]@{ 'Atlas.atlaspkg' = $request.archive }
    foreach ($name in @('Setup.ps1', 'Desktop.ps1', 'Desktop-Policy.ps1', 'RegistryFile.ps1', 'THIRD-PARTY-NOTICES.txt', 'DriverPolicy.reg')) {
        $payload[$name] = Join-Path $job $name
    }
    # The app installs from Atlas.atlaspkg. The unpacked package stays off the media:
    # its deepest launchers pass MAX_PATH under a workspace in the user's folders.
    foreach ($name in $payload.Keys) { Copy-Item -LiteralPath $payload[$name] -Destination (Join-Path $target $name) }
    $username = [string]$request.username
    if ($username.Length -lt 1 -or $username.Length -gt 20 -or $username.Trim() -cne $username -or $username.EndsWith('.') -or $username -match '[\p{Cc}"/\\\[\]:;|=,+*?<>@]' -or $username -in @('administrator','guest','defaultaccount','defaultuser0','wdagutilityaccount','system','anonymous logon')) { throw 'Invalid Windows local account name.' }
    if ($null -ne $request.drivers -and $request.drivers -notin @('automatic','manual')) { throw 'Unknown driver choice.' }
    $config = @{ schema = 2; mode = $request.mode; options = @($request.options); username = $username; drivers = $request.drivers }
    [IO.File]::WriteAllText((Join-Path $target 'setup.json'), ($config | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))
    # ProtectYourPC answers the OOBE Express settings question, so OOBE doesn't ask it;
    # 3 is Microsoft's documented value for automatic protection turned off.
    $answer = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <EnableFirewall>true</EnableFirewall>
      <DynamicUpdate><Enable>false</Enable><WillShowUI>Never</WillShowUI></DynamicUpdate>
      <UserData><AcceptEula>false</AcceptEula><ProductKey><WillShowUI>Always</WillShowUI></ProductKey></UserData>
      <ImageInstall><OSImage><WillShowUI>Always</WillShowUI></OSImage></ImageInstall>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RunSynchronous>
        <RunSynchronousCommand xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add">
          <Order>1</Order>
          <Path>powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%WINDIR%\AtlasISO\Setup.ps1"</Path>
          <Description>Atlas</Description>
          <WillReboot>Never</WillReboot>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RegisteredOwner>ATLAS_LOCAL_ACCOUNT</RegisteredOwner>
      <OOBE>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <HideEULAPage>false</HideEULAPage>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts><LocalAccounts><LocalAccount xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add">
        <Name>ATLAS_LOCAL_ACCOUNT</Name><Group>Administrators</Group>
        <Password><Value></Value><PlainText>true</PlainText></Password>
      </LocalAccount></LocalAccounts></UserAccounts>
      <AutoLogon><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>ATLAS_LOCAL_ACCOUNT</Username>
        <Password><Value></Value><PlainText>true</PlainText></Password>
      </AutoLogon>
      <FirstLogonCommands><SynchronousCommand xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add">
        <Order>1</Order><Description>Atlas account preparation</Description>
        <CommandLine>powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%WINDIR%\AtlasISO\Setup.ps1" -FirstLogon</CommandLine>
      </SynchronousCommand></FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@
    if ($architecture -eq 'arm64') { $answer = $answer.Replace('processorArchitecture="amd64"', 'processorArchitecture="arm64"') }
    [xml]$document = $answer
    $namespace = New-Object Xml.XmlNamespaceManager($document.NameTable)
    $namespace.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
    foreach ($node in $document.SelectNodes('//u:LocalAccount/u:Name | //u:AutoLogon/u:Username | //u:RegisteredOwner', $namespace)) { $node.InnerText = $username }
    if ($acceptedTerms) {
        $document.SelectSingleNode('//u:UserData/u:AcceptEula', $namespace).InnerText = 'true'
        $document.SelectSingleNode('//u:OOBE/u:HideEULAPage', $namespace).InnerText = 'true'
    }
    $answer = $document.OuterXml
    # An answer file in WinPE overrides the source's EI.cfg. Enterprise Evaluation
    # relies on that file to select its keyless evaluation channel. On that media,
    # deliver the answer to the installed OS for specialize and first sign-in.
    $answerPaths = @('sources\$OEM$\$$\System32\Sysprep\unattend.xml')
    if ($supportedEditions.Count -eq 1 -and $supportedEditions[0].EditionId -eq 'EnterpriseEval') {
        $answerPaths += 'sources\$OEM$\$$\Panther\unattend.xml'
    }
    else {
        $answerPaths += @('autounattend.xml', 'sources\autounattend.xml')
    }
    foreach ($relative in $answerPaths) {
        $destination = Join-Path $media $relative
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        [IO.File]::WriteAllText($destination, $answer, (New-Object Text.UTF8Encoding($false)))
    }
    # This PC's network drivers come last, so each stage is reported once, in order.
    $networkIncluded = $false
    if ($request.copyNetworkDrivers) {
        Write-Stage network-drivers
        . (Join-Path $job 'Network-Drivers.ps1')
        $networkRoot = Join-Path $target 'NetworkDrivers'
        $networkPackages = @(Export-AtlasNetworkDrivers -Destination $networkRoot -CancelFile (Join-Path $job 'cancel') -LogPath (Join-Path $job 'network-drivers.log') -CheckUpdates:$request.updateNetworkDrivers)
        if ($networkPackages.Count -eq 0) {
            # The adapters use drivers that come with Windows: nothing to add,
            # and the app says so instead of claiming a copy.
            [Console]::Out.WriteLine('ATLAS_NOTE:network-drivers-inbox')
        }
        else {
            Assert-PlainTree $networkRoot
            [IO.File]::WriteAllText((Join-Path $target 'network-drivers.json'), (ConvertTo-Json -InputObject $networkPackages), (New-Object Text.UTF8Encoding($false)))
            $networkIncluded = $true
        }
    }
    Write-Stage master
    & (Join-Path $PSScriptRoot 'Master-Iso.ps1') -Media $media -Output $partial -CancelFile (Join-Path $job 'cancel') -Architecture $architecture
    Write-Stage verify
    Assert-BootCatalog $partial $architecture
    if ((Get-Item -LiteralPath $partial).Length -le (Get-Item -LiteralPath $mediaImage).Length) { throw 'The output ISO is incomplete.' }
    # Re-read the image, Atlas's files and the boot files from the mounted output.
    # Mount-DiskImage needs an .iso extension, hence the rename.
    $verifyIso = Join-Path $work 'verify.iso'
    [IO.File]::Move($partial, $verifyIso)
    $verifiedMount = $false
    try {
        $checkDisk = Mount-AtlasIso $verifyIso -ReadOnly -OwnFile
        $verifiedMount = $true
        $checkRoot = Get-AtlasIsoRoot -ImagePath $verifyIso -Disk $checkDisk -Owned
        # The staged image, not the source: it may be the filtered export.
        $expected = @($imageRelative, 'sources\boot.wim', 'efi\microsoft\boot\efisys.bin') + $bootFiles
        $expected += @(@($payload.Keys) + @($managerName, 'setup.json') | ForEach-Object { Join-Path $atlasIso $_ })
        $expected += $answerPaths
        if ($networkIncluded) {
            $expected += @(@(Get-ChildItem -LiteralPath $networkRoot -File -Force -Recurse) + @(Get-Item -LiteralPath (Join-Path $target 'network-drivers.json')) |
                ForEach-Object { $_.FullName.Substring($media.Length + 1) })
        }
        foreach ($relative in $expected) {
            if ((Get-FileHash -LiteralPath (Join-Path $media $relative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $checkRoot $relative)).Hash) {
                throw "Output verification failed: $relative"
            }
        }
    }
    finally {
        if ($verifiedMount) { Dismount-AtlasIso $verifyIso -Required }
    }
    [IO.File]::Move($verifyIso, $partial)
    # Read the entire output before publication, retaining a checksum for diagnostics.
    $digest = Get-FileHash -LiteralPath $partial -Algorithm SHA256
    $digest.Hash | Set-Content -LiteralPath (Join-Path $job 'sha256.txt')
    Write-Stage cleanup
    # File.Move refuses an existing destination, including one created mid-build.
    [IO.File]::Move($partial, [IO.Path]::GetFullPath($request.output))
    $partial = $null
}
catch {
    [Console]::Error.WriteLine($_.Exception.ToString())
    [Console]::Error.WriteLine($_.ScriptStackTrace)
    exit 1
}
finally {
    if ($null -ne $appStream) { $appStream.Dispose() }
    if ($ownedMount -and $source) { Dismount-AtlasIso $source }
    # Only remove the exact unique paths created above, after checking their parent.
    if ($work -and (Test-Path -LiteralPath $work)) {
        $resolved = [IO.Path]::GetFullPath($work)
        if ([IO.Path]::GetDirectoryName($resolved) -eq $workParent -and [IO.Path]::GetFileName($resolved) -match '^\.atlas-iso-[0-9a-f]{32}$') {
            try { Assert-PlainTree $resolved; Remove-Item -LiteralPath $resolved -Recurse -Force } catch { [Console]::Error.WriteLine("Cleanup required: $resolved. $_") }
        }
    }
    if ($partial -and (Test-Path -LiteralPath $partial)) {
        if ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($partial)) -eq $parent -and [IO.Path]::GetFileName($partial) -match '^\.atlas-iso-[0-9a-f]{32}\.partial$') {
            Remove-Item -LiteralPath $partial -Force -ErrorAction Continue
        }
    }
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
