[CmdletBinding()]
param(
    [string]$PayloadDirectory = (Join-Path $PSScriptRoot `
        '..\..\playbook\Executables\AtlasModules\Tools'),

    [string]$HashManifestPath = (Join-Path $PSScriptRoot `
        '..\..\playbook\Executables\AtlasModules\Tools\Atlas-ElevationBootstrapHashes.psd1'),

    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..\..')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

function Test-AtlasVerifierPathEqual {
    param(
        [Parameter(Mandatory = $true)][string]$First,
        [Parameter(Mandatory = $true)][string]$Second
    )

    $left = [IO.Path]::GetFullPath($First).TrimEnd('\')
    $right = [IO.Path]::GetFullPath($Second).TrimEnd('\')
    return [string]::Equals($left, $right, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-AtlasVerifierNoPathAlias {
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
        if ([string]::IsNullOrWhiteSpace($parent) -or
                (Test-AtlasVerifierPathEqual $parent $candidate)) {
            break
        }
        $candidate = $parent
    }
}

function Initialize-AtlasVerifierPathIdentityType {
    if ('Atlas.VerifierPathIdentity' -as [type]) {
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
    public static class VerifierPathIdentity
    {
        private const uint FileShareRead = 0x00000001;
        private const uint FileShareWrite = 0x00000002;
        private const uint FileShareDelete = 0x00000004;
        private const uint OpenExisting = 3;
        private const uint FileFlagBackupSemantics = 0x02000000;

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

        public static string GetFinalPath(SafeFileHandle file)
        {
            if (file == null || file.IsInvalid || file.IsClosed)
            {
                throw new ArgumentException("The filesystem handle is invalid.", "file");
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
    }
}
'@ | Out-Null
}

function Get-AtlasVerifierFinalPathIdentity {
    param([Parameter(Mandatory = $true)][string]$Path)

    Initialize-AtlasVerifierPathIdentityType
    return [Atlas.VerifierPathIdentity]::GetFinalPath(
        [IO.Path]::GetFullPath($Path)).TrimEnd('\')
}

function ConvertTo-AtlasVerifierExpectedFinalPathIdentity {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ($fullPath.StartsWith('\\?\', [StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath
    }
    if ($fullPath.StartsWith('\\', [StringComparison]::Ordinal)) {
        return '\\?\UNC\' + $fullPath.Substring(2)
    }
    return '\\?\' + $fullPath
}

function Assert-AtlasVerifierPathIdentity {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$ExpectedIdentity
    )

    Assert-AtlasVerifierNoPathAlias -Path $Path -Label $Label
    $actualIdentity = Get-AtlasVerifierFinalPathIdentity -Path $Path
    $requiredIdentity = if ($PSBoundParameters.ContainsKey('ExpectedIdentity')) {
        $ExpectedIdentity
    } else {
        ConvertTo-AtlasVerifierExpectedFinalPathIdentity -Path $Path
    }
    if (-not [string]::Equals($actualIdentity, $requiredIdentity,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label has an unexpected final filesystem identity."
    }
    return $actualIdentity
}

function Assert-AtlasVerifierStreamIdentity {
    param(
        [Parameter(Mandatory = $true)][IO.FileStream]$Stream,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Initialize-AtlasVerifierPathIdentityType
    $actualIdentity = [Atlas.VerifierPathIdentity]::GetFinalPath(
        $Stream.SafeFileHandle).TrimEnd('\')
    $requiredIdentity = ConvertTo-AtlasVerifierExpectedFinalPathIdentity -Path $Path
    if (-not [string]::Equals($actualIdentity, $requiredIdentity,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label was redirected between path validation and file leasing."
    }
}

function Assert-Range {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][long]$Offset,
        [Parameter(Mandatory = $true)][long]$Length,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Offset -lt 0 -or $Length -lt 0 -or $Offset -gt $Bytes.LongLength -or
            $Length -gt ($Bytes.LongLength - $Offset)) {
        throw "$Label is outside the PE file."
    }
}

function Assert-RelativeRange {
    param(
        [Parameter(Mandatory = $true)][uint64]$Offset,
        [Parameter(Mandatory = $true)][uint64]$Length,
        [Parameter(Mandatory = $true)][uint64]$ContainerLength,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Offset -gt $ContainerLength -or $Length -gt ($ContainerLength - $Offset)) {
        throw "$Label is outside its declared PE directory."
    }
}

function Read-UInt16LE {
    param([byte[]]$Bytes, [long]$Offset, [string]$Label = 'UInt16')
    Assert-Range -Bytes $Bytes -Offset $Offset -Length 2 -Label $Label
    return [BitConverter]::ToUInt16($Bytes, [int]$Offset)
}

function Read-UInt32LE {
    param([byte[]]$Bytes, [long]$Offset, [string]$Label = 'UInt32')
    Assert-Range -Bytes $Bytes -Offset $Offset -Length 4 -Label $Label
    return [BitConverter]::ToUInt32($Bytes, [int]$Offset)
}

function Read-UInt64LE {
    param([byte[]]$Bytes, [long]$Offset, [string]$Label = 'UInt64')
    Assert-Range -Bytes $Bytes -Offset $Offset -Length 8 -Label $Label
    return [BitConverter]::ToUInt64($Bytes, [int]$Offset)
}

function Get-PeChecksum {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$ChecksumOffset
    )

    Assert-Range -Bytes $Bytes -Offset $ChecksumOffset -Length 4 -Label 'PE checksum'
    [uint64]$sum = 0
    for ($offset = 0; $offset -lt $Bytes.Length; $offset += 2) {
        if ($offset -eq $ChecksumOffset -or $offset -eq ($ChecksumOffset + 2)) {
            continue
        }
        [uint32]$word = $Bytes[$offset]
        if ($offset + 1 -lt $Bytes.Length) {
            $word = $word -bor ([uint32]$Bytes[$offset + 1] -shl 8)
        }
        $sum += $word
        $sum = ($sum -band 0xffff) + ($sum -shr 16)
    }
    $sum = ($sum -band 0xffff) + ($sum -shr 16)
    $sum += ($sum -shr 16)
    return [uint32](($sum -band 0xffff) + $Bytes.Length)
}

function Convert-RvaToOffset {
    param(
        [uint32]$Rva,
        [uint32]$Length = 1,
        [object[]]$Sections,
        [uint32]$SizeOfHeaders,
        [byte[]]$Bytes
    )

    if ($Rva -lt $SizeOfHeaders) {
        Assert-RelativeRange -Offset $Rva -Length $Length -ContainerLength $SizeOfHeaders `
            -Label 'Header RVA'
        Assert-Range -Bytes $Bytes -Offset $Rva -Length $Length -Label 'Header RVA'
        return [long]$Rva
    }
    foreach ($section in $Sections) {
        if ([uint64]$Rva -ge [uint64]$section.VirtualAddress) {
            $relative = [uint64]$Rva - [uint64]$section.VirtualAddress
            if ($relative -le [uint64]$section.VirtualSize -and
                    [uint64]$Length -le ([uint64]$section.VirtualSize - $relative) -and
                    $relative -le [uint64]$section.RawSize -and
                    [uint64]$Length -le ([uint64]$section.RawSize - $relative)) {
                $offset = [uint64]$section.RawOffset + $relative
                Assert-Range -Bytes $Bytes -Offset $offset -Length $Length -Label 'Mapped RVA'
                return [long]$offset
            }
        }
    }
    throw ('RVA 0x{0:X8} with length 0x{1:X} is not fully raw-backed by one PE section.' -f
        $Rva, $Length)
}

function Get-RvaSection {
    param(
        [Parameter(Mandatory = $true)][uint32]$Rva,
        [Parameter(Mandatory = $true)][uint32]$Length,
        [Parameter(Mandatory = $true)][object[]]$Sections,
        [Parameter(Mandatory = $true)][string]$Label
    )

    foreach ($section in $Sections) {
        if ([uint64]$Rva -ge [uint64]$section.VirtualAddress) {
            $relative = [uint64]$Rva - [uint64]$section.VirtualAddress
            if ($relative -le [uint64]$section.VirtualSize -and
                    [uint64]$Length -le ([uint64]$section.VirtualSize - $relative) -and
                    $relative -le [uint64]$section.RawSize -and
                    [uint64]$Length -le ([uint64]$section.RawSize - $relative)) {
                return $section
            }
        }
    }
    throw "$Label is not fully raw-backed by one PE section."
}

function Convert-VaToRva {
    param(
        [Parameter(Mandatory = $true)][uint64]$Va,
        [Parameter(Mandatory = $true)][uint64]$ImageBase,
        [Parameter(Mandatory = $true)][uint32]$SizeOfImage,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Va -lt $ImageBase) {
        throw "$Label is below the PE image base."
    }
    $rva64 = $Va - $ImageBase
    if ($rva64 -ge [uint64]$SizeOfImage -or $rva64 -gt [uint32]::MaxValue) {
        throw "$Label is outside the PE image."
    }
    return [uint32]$rva64
}

function Read-PeAsciiZ {
    param(
        [byte[]]$Bytes,
        [uint32]$Rva,
        [object[]]$Sections,
        [uint32]$SizeOfHeaders,
        [int]$Maximum = 260
    )

    if ($Maximum -le 0) {
        throw 'The PE ASCII string bound is invalid.'
    }
    if ($Rva -lt $SizeOfHeaders) {
        $offset = [long]$Rva
        $available = [uint64]$SizeOfHeaders - [uint64]$Rva
    } else {
        $section = Get-RvaSection -Rva $Rva -Length 1 -Sections $Sections `
            -Label 'PE ASCII string'
        $relative = [uint64]$Rva - [uint64]$section.VirtualAddress
        $available = [Math]::Min(
            [uint64]$section.VirtualSize - $relative,
            [uint64]$section.RawSize - $relative)
        $offset = [long]([uint64]$section.RawOffset + $relative)
    }
    $searchLength = [Math]::Min([uint64]$Maximum, $available)
    Assert-Range -Bytes $Bytes -Offset $offset -Length $searchLength `
        -Label 'PE ASCII string'
    for ($index = 0; $index -lt $searchLength; $index++) {
        if ($Bytes[$offset + $index] -eq 0) {
            return [Text.Encoding]::ASCII.GetString($Bytes, [int]$offset, $index)
        }
    }
    throw 'The PE contains an unterminated or overlong ASCII string.'
}

function Read-PeImportThunkTable {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][uint32]$TableRva,
        [Parameter(Mandatory = $true)][object[]]$Sections,
        [Parameter(Mandatory = $true)][uint64]$MaximumEndRva,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([uint64]$TableRva -ge $MaximumEndRva) {
        throw "$Label begins outside its declared range."
    }
    $tableSection = Get-RvaSection -Rva $TableRva -Length 8 -Sections $Sections `
        -Label $Label
    $tableRelative = [uint64]$TableRva - [uint64]$tableSection.VirtualAddress
    $sectionAvailable = [Math]::Min(
        [uint64]$tableSection.VirtualSize - $tableRelative,
        [uint64]$tableSection.RawSize - $tableRelative)
    $declaredAvailable = $MaximumEndRva - [uint64]$TableRva
    $available = [Math]::Min($sectionAvailable, $declaredAvailable)
    $entryLimit = [Math]::Min([uint64]4096, [uint64]($available / 8))
    if ($entryLimit -eq 0) {
        throw "$Label has no fully raw-backed entry."
    }
    $tableOffset = [long]([uint64]$tableSection.RawOffset + $tableRelative)
    $values = New-Object 'Collections.Generic.List[uint64]'
    $names = New-Object 'Collections.Generic.List[string]'
    for ($index = 0; $index -lt $entryLimit; $index++) {
        $entryOffset = $tableOffset + ([long]$index * 8)
        $value = [BitConverter]::ToUInt64($Bytes, [int]$entryOffset)
        if ($value -eq 0) {
            $byteCount = [uint64]($index + 1) * [uint64]8
            return [pscustomobject]@{
                Values    = @($values)
                Names     = @($names)
                ByteCount = $byteCount
            }
        }
        $ordinalFlag = [uint64]1 -shl 63
        if (($value -band $ordinalFlag) -ne 0) {
            throw "$Label unexpectedly imports by ordinal."
        } else {
            if ($value -gt 0x7fffffff) {
                throw "$Label contains a non-PE32+ import-name RVA."
            }
            $hintNameRva = [uint32]$value
            $nameRva64 = [uint64]$hintNameRva + [uint64]2
            if ($nameRva64 -gt [uint32]::MaxValue) {
                throw "$Label contains an overflowing import-name RVA."
            }
            $nameSection = $null
            $hintRelative = [uint64]0
            foreach ($candidateSection in $Sections) {
                if ([uint64]$hintNameRva -ge [uint64]$candidateSection.VirtualAddress) {
                    $candidateRelative = [uint64]$hintNameRva -
                        [uint64]$candidateSection.VirtualAddress
                    if ($candidateRelative -le [uint64]$candidateSection.VirtualSize -and
                            [uint64]3 -le
                            ([uint64]$candidateSection.VirtualSize - $candidateRelative) -and
                            $candidateRelative -le [uint64]$candidateSection.RawSize -and
                            [uint64]3 -le
                            ([uint64]$candidateSection.RawSize - $candidateRelative)) {
                        $nameSection = $candidateSection
                        $hintRelative = $candidateRelative
                        break
                    }
                }
            }
            if ($null -eq $nameSection) {
                throw "$Label contains a non-raw-backed import name."
            }
            $nameRelative = $hintRelative + [uint64]2
            $nameAvailable = [Math]::Min(
                [uint64]$nameSection.VirtualSize - $nameRelative,
                [uint64]$nameSection.RawSize - $nameRelative)
            $nameLimit = [Math]::Min([uint64]512, $nameAvailable)
            $nameOffset = [long]([uint64]$nameSection.RawOffset + $nameRelative)
            if ($nameLimit -eq 0 -or $Bytes[$nameOffset] -eq 0) {
                throw "$Label contains an empty import name."
            }
            $nameTerminated = $false
            for ($nameIndex = 1; $nameIndex -lt $nameLimit; $nameIndex++) {
                if ($Bytes[$nameOffset + $nameIndex] -eq 0) {
                    $nameTerminated = $true
                    break
                }
            }
            if (-not $nameTerminated) {
                throw "$Label contains an unterminated import name."
            }
            $names.Add([Text.Encoding]::ASCII.GetString(
                $Bytes, [int]$nameOffset, $nameIndex))
        }
        $values.Add($value)
    }
    throw "$Label is unterminated within its raw-backed bounded range."
}

function Assert-NoOverlappingRange {
    param(
        [Parameter(Mandatory = $true)][object[]]$Ranges,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $ordered = @($Ranges | Where-Object { [uint64]$_.Length -ne 0 } |
        Sort-Object { [uint64]$_.Start })
    for ($index = 1; $index -lt $ordered.Count; $index++) {
        $previousEnd = [uint64]$ordered[$index - 1].Start + [uint64]$ordered[$index - 1].Length
        if ([uint64]$ordered[$index].Start -lt $previousEnd) {
            throw "$Label ranges overlap."
        }
    }
}

function Get-AlignedUInt64 {
    param(
        [Parameter(Mandatory = $true)][uint64]$Value,
        [Parameter(Mandatory = $true)][uint64]$Alignment
    )

    if ($Alignment -eq 0 -or ($Alignment -band ($Alignment - 1)) -ne 0) {
        throw 'The PE declares a non-power-of-two alignment.'
    }
    $remainder = $Value % $Alignment
    if ($remainder -eq 0) {
        return $Value
    }
    $increment = $Alignment - $remainder
    if ($Value -gt [uint64]::MaxValue - $increment) {
        throw 'The PE alignment calculation overflows.'
    }
    return $Value + $increment
}

function Assert-ResourceRange {
    param(
        [Parameter(Mandatory = $true)][uint32]$RelativeOffset,
        [Parameter(Mandatory = $true)][uint32]$Length,
        [Parameter(Mandatory = $true)][uint32]$ResourceSize,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-RelativeRange -Offset $RelativeOffset -Length $Length `
        -ContainerLength $ResourceSize -Label $Label
}

function Get-ResourceDirectoryEntry {
    param(
        [byte[]]$Bytes,
        [long]$ResourceRootOffset,
        [uint32]$ResourceSize,
        [uint32]$DirectoryRelativeOffset,
        [uint32]$Id
    )

    Assert-ResourceRange -RelativeOffset $DirectoryRelativeOffset -Length 16 `
        -ResourceSize $ResourceSize -Label 'Resource directory'
    $directory = $ResourceRootOffset + $DirectoryRelativeOffset
    Assert-Range -Bytes $Bytes -Offset $directory -Length 16 -Label 'Resource directory'
    $namedCount = Read-UInt16LE $Bytes ($directory + 12) 'Named resource count'
    $idCount = Read-UInt16LE $Bytes ($directory + 14) 'ID resource count'
    $entryCount = [int]$namedCount + [int]$idCount
    if ($namedCount -ne 0 -or $entryCount -gt 256) {
        # The fixed bootstrap resource contract uses numeric IDs only. Rejecting string
        # names also avoids parser differentials between the named and numeric prefixes.
        throw 'The PE resource directory exceeds the bounded entry count.'
    }
    $previousId = $null
    for ($index = 0; $index -lt $entryCount; $index++) {
        $entryRelative = [uint64]$DirectoryRelativeOffset + [uint64]16 +
            ([uint64]$index * [uint64]8)
        if ($entryRelative -gt [uint32]::MaxValue) {
            throw 'The PE resource entry offset overflows.'
        }
        Assert-ResourceRange -RelativeOffset ([uint32]$entryRelative) -Length 8 `
            -ResourceSize $ResourceSize -Label 'Resource entry'
        $entry = $directory + 16 + ($index * 8)
        Assert-Range -Bytes $Bytes -Offset $entry -Length 8 -Label 'Resource entry'
        $name = Read-UInt32LE $Bytes $entry 'Resource name'
        $target = Read-UInt32LE $Bytes ($entry + 4) 'Resource target'
        if (($name -band 0x80000000) -ne 0) {
            throw 'The PE numeric resource directory contains a string-name entry.'
        }
        if ($null -ne $previousId -and $name -le $previousId) {
            throw 'The PE numeric resource IDs are duplicated or out of order.'
        }
        $previousId = $name
        if ($name -eq $Id) {
            $relativeTarget = $target -band 0x7fffffff
            Assert-ResourceRange -RelativeOffset $relativeTarget -Length 1 `
                -ResourceSize $ResourceSize -Label 'Resource target'
            return [pscustomobject]@{
                IsDirectory = ($target -band 0x80000000) -ne 0
                Offset      = $relativeTarget
            }
        }
    }
    return $null
}

function Read-PeContract {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][uint16]$ExpectedMachine,
        [Collections.Generic.List[object]]$LeaseCollector
    )

    Assert-AtlasVerifierPathIdentity -Path $Path -Label "PE payload '$Path'" | Out-Null
    $pathItem = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($pathItem.PSIsContainer -or
            ($pathItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            -not [string]::IsNullOrWhiteSpace([string]$pathItem.LinkType)) {
        throw "'$Path' is not a direct regular file."
    }
    $stream = [IO.File]::Open($pathItem.FullName, [IO.FileMode]::Open,
        [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        Assert-AtlasVerifierStreamIdentity -Stream $stream -Path $pathItem.FullName `
            -Label "PE payload '$Path'"
        if ($stream.Length -le 0 -or $stream.Length -gt 4MB) {
            throw "'$Path' has an unsupported PE file length."
        }
        $bytes = New-Object byte[] ([int]$stream.Length)
        $bytesRead = 0
        while ($bytesRead -lt $bytes.Length) {
            $read = $stream.Read($bytes, $bytesRead, $bytes.Length - $bytesRead)
            if ($read -eq 0) {
                throw "'$Path' ended before its declared file length."
            }
            $bytesRead += $read
        }
        $artifactSha256Provider = [Security.Cryptography.SHA256]::Create()
        try {
            $artifactSha256 = [BitConverter]::ToString(
                $artifactSha256Provider.ComputeHash($bytes)).Replace('-', '')
        }
        finally {
            $artifactSha256Provider.Dispose()
        }
    Assert-Range -Bytes $bytes -Offset 0 -Length 64 -Label 'DOS header'
    if ($bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) {
        throw "'$Path' is not an MZ executable."
    }
    $peOffset = Read-UInt32LE $bytes 0x3c 'PE header offset'
    Assert-Range -Bytes $bytes -Offset $peOffset -Length 24 -Label 'PE header'
    if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or
            $bytes[$peOffset + 2] -ne 0 -or $bytes[$peOffset + 3] -ne 0) {
        throw "'$Path' has an invalid PE signature."
    }
    $machine = Read-UInt16LE $bytes ($peOffset + 4) 'PE machine'
    if ($machine -ne $ExpectedMachine) {
        throw ("'{0}' machine is 0x{1:X4}; expected 0x{2:X4}." -f $Path, $machine,
            $ExpectedMachine)
    }
    $symbolTable = Read-UInt32LE $bytes ($peOffset + 12) 'COFF symbol-table offset'
    $symbolCount = Read-UInt32LE $bytes ($peOffset + 16) 'COFF symbol count'
    $coffCharacteristics = Read-UInt16LE $bytes ($peOffset + 22) `
        'COFF characteristics'
    if (($symbolTable -bor $symbolCount) -ne 0 -or $coffCharacteristics -ne 0x22) {
        throw "'$Path' has unexpected COFF symbol or image characteristics."
    }
    $sectionCount = Read-UInt16LE $bytes ($peOffset + 6) 'PE section count'
    $optionalSize = Read-UInt16LE $bytes ($peOffset + 20) 'Optional-header size'
    if ($sectionCount -eq 0 -or $sectionCount -gt 32 -or $optionalSize -ne 240) {
        throw "'$Path' has an unsupported PE layout."
    }
    $optional = $peOffset + 24
    Assert-Range -Bytes $bytes -Offset $optional -Length $optionalSize -Label 'Optional header'
    if ((Read-UInt16LE $bytes $optional 'Optional-header magic') -ne 0x20b) {
        throw "'$Path' is not PE32+."
    }
    if ($bytes[$optional + 2] -ne 14 -or $bytes[$optional + 3] -ne 0 -or
            (Read-UInt16LE $bytes ($optional + 40) 'Major OS version') -ne 10 -or
            (Read-UInt16LE $bytes ($optional + 42) 'Minor OS version') -ne 0 -or
            (Read-UInt16LE $bytes ($optional + 44) 'Major image version') -ne 0 -or
            (Read-UInt16LE $bytes ($optional + 46) 'Minor image version') -ne 0 -or
            (Read-UInt16LE $bytes ($optional + 48) 'Major subsystem version') -ne 10 -or
            (Read-UInt16LE $bytes ($optional + 50) 'Minor subsystem version') -ne 0 -or
            (Read-UInt32LE $bytes ($optional + 52) 'Win32VersionValue') -ne 0 -or
            (Read-UInt64LE $bytes ($optional + 72) 'Stack reserve') -ne 1MB -or
            (Read-UInt64LE $bytes ($optional + 80) 'Stack commit') -ne 4KB -or
            (Read-UInt64LE $bytes ($optional + 88) 'Heap reserve') -ne 1MB -or
            (Read-UInt64LE $bytes ($optional + 96) 'Heap commit') -ne 4KB -or
            (Read-UInt32LE $bytes ($optional + 104) 'LoaderFlags') -ne 0) {
        throw "'$Path' has noncanonical fixed PE32+ optional-header metadata."
    }
    if ((Read-UInt16LE $bytes ($optional + 68) 'Subsystem') -ne 2) {
        throw "'$Path' is not a Windows GUI executable."
    }
    $dllCharacteristics = Read-UInt16LE $bytes ($optional + 70) 'DLL characteristics'
    if ($dllCharacteristics -ne 0xc160) {
        throw ("'{0}' has noncanonical ASLR/DEP/high-entropy/CFG flags (0x{1:X4})." -f
            $Path, $dllCharacteristics)
    }
    $entryPointRva = Read-UInt32LE $bytes ($optional + 16) 'Entry-point RVA'
    $sectionAlignment = Read-UInt32LE $bytes ($optional + 32) 'SectionAlignment'
    $fileAlignment = Read-UInt32LE $bytes ($optional + 36) 'FileAlignment'
    if ($entryPointRva -eq 0 -or $fileAlignment -ne 0x200 -or
            $sectionAlignment -ne 0x1000) {
        throw "'$Path' has invalid PE alignment or entry-point metadata."
    }
    $imageBase = Read-UInt64LE $bytes ($optional + 24) 'ImageBase'
    $sizeOfImage = Read-UInt32LE $bytes ($optional + 56) 'SizeOfImage'
    $sizeOfHeaders = Read-UInt32LE $bytes ($optional + 60) 'SizeOfHeaders'
    if ($imageBase -ne 0x0000000140000000 -or
            $sizeOfImage -eq 0 -or $sizeOfHeaders -eq 0 -or
            $sizeOfHeaders -gt $bytes.LongLength -or $sizeOfHeaders -gt $sizeOfImage) {
        throw "'$Path' has invalid PE image/header bounds."
    }
    $storedChecksum = Read-UInt32LE $bytes ($optional + 64) 'PE checksum'
    $calculatedChecksum = Get-PeChecksum -Bytes $bytes -ChecksumOffset ($optional + 64)
    if ($storedChecksum -eq 0 -or $storedChecksum -ne $calculatedChecksum) {
        throw "'$Path' has an invalid PE checksum."
    }
    if (($sizeOfHeaders % $fileAlignment) -ne 0 -or
            ($sizeOfImage % $sectionAlignment) -ne 0) {
        throw "'$Path' has unaligned PE image/header sizes."
    }
    $directoryCount = Read-UInt32LE $bytes ($optional + 108) 'Data-directory count'
    if ($directoryCount -ne 16) {
        throw "'$Path' does not have the exact PE32+ data-directory table."
    }
    $directoryBase = $optional + 112
    $sections = @()
    $sectionTable = $optional + $optionalSize
    Assert-Range -Bytes $bytes -Offset $sectionTable -Length ([long]$sectionCount * 40) `
        -Label 'Section table'
    if ($sectionTable + ([long]$sectionCount * 40) -gt $sizeOfHeaders) {
        throw "'$Path' has section headers outside SizeOfHeaders."
    }
    if ((Get-AlignedUInt64 -Value ([uint64]$sectionTable +
                ([uint64]$sectionCount * [uint64]40)) -Alignment $fileAlignment) -ne
            $sizeOfHeaders) {
        throw "'$Path' has noncanonical SizeOfHeaders padding."
    }
    for ($index = 0; $index -lt $sectionCount; $index++) {
        $section = $sectionTable + ($index * 40)
        Assert-Range -Bytes $bytes -Offset $section -Length 40 -Label 'Section header'
        $virtualSize = Read-UInt32LE $bytes ($section + 8) 'Section virtual size'
        $virtualAddress = Read-UInt32LE $bytes ($section + 12) 'Section RVA'
        $rawSize = Read-UInt32LE $bytes ($section + 16) 'Section raw size'
        $rawOffset = Read-UInt32LE $bytes ($section + 20) 'Section raw offset'
        $characteristics = Read-UInt32LE $bytes ($section + 36) 'Section characteristics'
        $mappedSize = [Math]::Max([uint64]$virtualSize, [uint64]$rawSize)
        if ($virtualSize -eq 0 -or $rawSize -eq 0 -or
                $virtualAddress -lt $sizeOfHeaders -or
                ($virtualAddress % $sectionAlignment) -ne 0 -or
                ([uint64]$virtualAddress + $mappedSize) -gt $sizeOfImage) {
            throw "'$Path' has a malformed virtual section range."
        }
        if ($rawOffset -lt $sizeOfHeaders -or ($rawOffset % $fileAlignment) -ne 0 -or
                ($rawSize % $fileAlignment) -ne 0) {
            throw "'$Path' has malformed or header-overlapping section raw data."
        }
        Assert-Range -Bytes $bytes -Offset $rawOffset -Length $rawSize `
            -Label 'Section raw data'
        if (($characteristics -band 0x20000000) -ne 0 -and
                ($characteristics -band 0x80000000) -ne 0) {
            throw "'$Path' contains a writable executable section."
        }
        $sections += [pscustomobject]@{
            VirtualSize    = $virtualSize
            VirtualAddress = $virtualAddress
            RawSize        = $rawSize
            RawOffset      = $rawOffset
            Characteristics = $characteristics
        }
    }
    Assert-NoOverlappingRange -Label 'PE section raw' -Ranges @($sections |
        ForEach-Object { [pscustomobject]@{ Start = $_.RawOffset; Length = $_.RawSize } })
    Assert-NoOverlappingRange -Label 'PE section RVA' -Ranges @($sections |
        ForEach-Object {
            [pscustomobject]@{
                Start = $_.VirtualAddress
                Length = [Math]::Max([uint64]$_.VirtualSize, [uint64]$_.RawSize)
            }
        })
    $orderedVirtualSections = @($sections)
    $expectedVirtualAddress = Get-AlignedUInt64 -Value $sizeOfHeaders `
        -Alignment $sectionAlignment
    foreach ($section in $orderedVirtualSections) {
        if ([uint64]$section.VirtualAddress -ne $expectedVirtualAddress) {
            throw "'$Path' has a gap or disorder in its aligned virtual section layout."
        }
        $mappedSize = [Math]::Max([uint64]$section.VirtualSize, [uint64]$section.RawSize)
        $expectedVirtualAddress = Get-AlignedUInt64 `
            -Value ([uint64]$section.VirtualAddress + $mappedSize) `
            -Alignment $sectionAlignment
    }
    if ($expectedVirtualAddress -ne $sizeOfImage) {
        throw "'$Path' has inconsistent SizeOfImage evidence."
    }
    $orderedRawSections = @($sections)
    $expectedRawOffset = [uint64]$sizeOfHeaders
    foreach ($section in $orderedRawSections) {
        if ([uint64]$section.RawOffset -ne $expectedRawOffset) {
            throw "'$Path' has a gap or disorder in its raw section layout."
        }
        $expectedRawOffset += [uint64]$section.RawSize
    }
    if ($expectedRawOffset -ne $bytes.LongLength) {
        throw "'$Path' has trailing data outside its PE sections."
    }
    $entryPointSection = Get-RvaSection -Rva $entryPointRva -Length 1 `
        -Sections $sections -Label 'PE entry point'
    if (($entryPointSection.Characteristics -band 0x20000000) -eq 0 -or
            ($entryPointSection.Characteristics -band 0x80000000) -ne 0) {
        throw "'$Path' entry point is not in an executable non-writable section."
    }

    foreach ($unexpectedDirectory in @(
            @{ Offset = 0; Label = 'export' },
            @{ Offset = 32; Label = 'certificate' },
            @{ Offset = 56; Label = 'architecture' },
            @{ Offset = 64; Label = 'global-pointer' },
            @{ Offset = 88; Label = 'bound-import' },
            @{ Offset = 120; Label = 'reserved' }
        )) {
        $unexpectedRva = Read-UInt32LE $bytes `
            ($directoryBase + $unexpectedDirectory.Offset) `
            "$($unexpectedDirectory.Label) directory address"
        $unexpectedSize = Read-UInt32LE $bytes `
            ($directoryBase + $unexpectedDirectory.Offset + 4) `
            "$($unexpectedDirectory.Label) directory size"
        if (($unexpectedRva -bor $unexpectedSize) -ne 0) {
            throw "'$Path' unexpectedly contains a $($unexpectedDirectory.Label) directory."
        }
    }

    $exceptionRva = Read-UInt32LE $bytes ($directoryBase + 24) 'Exception-table RVA'
    $exceptionSize = Read-UInt32LE $bytes ($directoryBase + 28) 'Exception-table size'
    $exceptionEntrySize = if ($ExpectedMachine -eq 0x8664) { 12 } else { 8 }
    if ($exceptionRva -eq 0 -or $exceptionSize -lt $exceptionEntrySize -or
            ($exceptionSize % $exceptionEntrySize) -ne 0 -or $exceptionSize -gt 1MB) {
        throw "'$Path' lacks a bounded architecture-canonical exception directory."
    }
    $exceptionOffset = Convert-RvaToOffset -Rva $exceptionRva -Length $exceptionSize `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $exceptionSection = Get-RvaSection -Rva $exceptionRva -Length $exceptionSize `
        -Sections $sections -Label 'Exception directory'
    if ($exceptionSection.VirtualAddress -ne $exceptionRva -or
            $exceptionSection.VirtualSize -ne $exceptionSize -or
            $exceptionSection.RawSize -ne
                (Get-AlignedUInt64 -Value $exceptionSize -Alignment $fileAlignment) -or
            $exceptionSection.Characteristics -ne 0x40000040) {
        throw "'$Path' has a noncanonical read-only exception section."
    }
    $exceptionCount = [int]($exceptionSize / $exceptionEntrySize)
    $previousFunctionBegin = $null
    $previousFunctionEnd = $null
    for ($exceptionIndex = 0; $exceptionIndex -lt $exceptionCount; $exceptionIndex++) {
        $entryOffset = $exceptionOffset + ($exceptionIndex * $exceptionEntrySize)
        $functionBegin = Read-UInt32LE $bytes $entryOffset 'Runtime-function begin RVA'
        if ($functionBegin -eq 0 -or ($functionBegin % 4) -ne 0 -or
                ($null -ne $previousFunctionBegin -and
                    $functionBegin -le $previousFunctionBegin) -or
                ($null -ne $previousFunctionEnd -and
                    $functionBegin -lt $previousFunctionEnd)) {
            throw "'$Path' has duplicate, unordered, or overlapping runtime functions."
        }
        $beginSection = Get-RvaSection -Rva $functionBegin -Length 1 `
            -Sections $sections -Label 'Runtime-function begin RVA'
        if (($beginSection.Characteristics -band 0x20000000) -eq 0 -or
                ($beginSection.Characteristics -band 0x80000000) -ne 0) {
            throw "'$Path' has a runtime function outside executable non-writable code."
        }

        $currentFunctionEnd = $null
        if ($ExpectedMachine -eq 0x8664) {
            $functionEnd = Read-UInt32LE $bytes ($entryOffset + 4) `
                'Runtime-function end RVA'
            $unwindInfoRva = Read-UInt32LE $bytes ($entryOffset + 8) `
                'Runtime-function unwind-info RVA'
            if ($functionEnd -le $functionBegin -or $functionEnd -gt $sizeOfImage -or
                    $unwindInfoRva -eq 0 -or ($unwindInfoRva % 4) -ne 0) {
                throw "'$Path' has malformed AMD64 runtime-function metadata."
            }
            $endSection = Get-RvaSection -Rva ([uint32]($functionEnd - 1)) -Length 1 `
                -Sections $sections -Label 'Runtime-function end RVA'
            if ($endSection.VirtualAddress -ne $beginSection.VirtualAddress -or
                    ($endSection.Characteristics -band 0x20000000) -eq 0 -or
                    ($endSection.Characteristics -band 0x80000000) -ne 0) {
                throw "'$Path' has an AMD64 runtime function spanning invalid code."
            }
            $unwindInfoOffset = Convert-RvaToOffset -Rva $unwindInfoRva -Length 4 `
                -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
            $unwindHeader = Read-UInt32LE $bytes $unwindInfoOffset `
                'AMD64 unwind-info header'
            $unwindVersion = $unwindHeader -band 0x07
            $unwindFlags = ($unwindHeader -shr 3) -band 0x1f
            $prologSize = ($unwindHeader -shr 8) -band 0xff
            $unwindCodeCount = ($unwindHeader -shr 16) -band 0xff
            $frameData = ($unwindHeader -shr 24) -band 0xff
            $functionLength = [uint32]($functionEnd - $functionBegin)
            if ($unwindVersion -ne 1 -or $unwindFlags -ne 0 -or
                    $unwindCodeCount -gt 64 -or $prologSize -gt $functionLength -or
                    $frameData -ne 0) {
                throw "'$Path' has invalid AMD64 unwind information."
            }
            $unwindInfoLength = [uint32](4 +
                ([Math]::Floor(([double]$unwindCodeCount + 1) / 2) * 4))
            Convert-RvaToOffset -Rva $unwindInfoRva -Length $unwindInfoLength `
                -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes |
                Out-Null
            $unwindInfoSection = Get-RvaSection -Rva $unwindInfoRva `
                -Length $unwindInfoLength -Sections $sections -Label 'AMD64 unwind-info RVA'
            if (($unwindInfoSection.Characteristics -band 0xa0000000) -ne 0) {
                throw "'$Path' has AMD64 unwind information in writable or executable data."
            }
            $currentFunctionEnd = $functionEnd
        } else {
            $unwindData = Read-UInt32LE $bytes ($entryOffset + 4) `
                'ARM64 runtime-function unwind data'
            $unwindFlag = $unwindData -band 0x03
            if ($unwindData -eq 0 -or $unwindFlag -gt 1) {
                throw "'$Path' has malformed ARM64 runtime-function metadata."
            }
            if ($unwindFlag -eq 0) {
                $armUnwindOffset = Convert-RvaToOffset -Rva $unwindData -Length 4 `
                    -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
                $armUnwindHeader = Read-UInt32LE $bytes $armUnwindOffset `
                    'ARM64 unwind-data header'
                $armFunctionLength = [uint32](($armUnwindHeader -band 0x3ffff) * 4)
                $armVersion = ($armUnwindHeader -shr 18) -band 0x03
                $exceptionDataPresent = ($armUnwindHeader -shr 20) -band 0x01
                $epilogInHeader = ($armUnwindHeader -shr 21) -band 0x01
                $epilogCount = ($armUnwindHeader -shr 22) -band 0x1f
                $codeWords = ($armUnwindHeader -shr 27) -band 0x1f
                $armHeaderLength = [uint32]4
                if ($epilogCount -eq 0 -and $codeWords -eq 0) {
                    $extendedHeader = Read-UInt32LE $bytes ($armUnwindOffset + 4) `
                        'ARM64 extended unwind-data header'
                    $epilogCount = $extendedHeader -band 0xffff
                    $codeWords = ($extendedHeader -shr 16) -band 0xff
                    if (($extendedHeader -band 0xff000000) -ne 0) {
                        throw "'$Path' has reserved ARM64 extended unwind-header bits."
                    }
                    $armHeaderLength = 8
                }
                if ($armFunctionLength -eq 0 -or $armVersion -ne 0 -or
                        $exceptionDataPresent -ne 0 -or
                        [uint64]$functionBegin + $armFunctionLength -gt $sizeOfImage) {
                    throw "'$Path' has invalid ARM64 unwind information."
                }
                $epilogScopeBytes = if ($epilogInHeader -eq 0) {
                    [uint32]$epilogCount * [uint32]4
                } else {
                    if ($epilogCount -ge ([uint32]$codeWords * [uint32]4)) {
                        throw "'$Path' has an invalid ARM64 epilog unwind-code index."
                    }
                    [uint32]0
                }
                $armUnwindLength = [uint64]$armHeaderLength + $epilogScopeBytes +
                    ([uint64]$codeWords * [uint64]4)
                if ($armUnwindLength -gt [uint32]::MaxValue) {
                    throw "'$Path' has oversized ARM64 unwind information."
                }
                Convert-RvaToOffset -Rva $unwindData -Length ([uint32]$armUnwindLength) `
                    -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes |
                    Out-Null
                $armUnwindSection = Get-RvaSection -Rva $unwindData `
                    -Length ([uint32]$armUnwindLength) -Sections $sections `
                    -Label 'ARM64 unwind-data RVA'
                if (($armUnwindSection.Characteristics -band 0xa0000000) -ne 0) {
                    throw "'$Path' has ARM64 unwind information in writable or executable data."
                }
                if ($epilogInHeader -eq 0) {
                    for ($epilogIndex = 0; $epilogIndex -lt $epilogCount; $epilogIndex++) {
                        $scopeOffset = $armUnwindOffset + $armHeaderLength +
                            ($epilogIndex * 4)
                        $scope = Read-UInt32LE $bytes $scopeOffset 'ARM64 epilog scope'
                        $epilogStart = [uint32](($scope -band 0x3ffff) * 4)
                        $epilogCodeIndex = ($scope -shr 22) -band 0x3ff
                        if (($scope -band 0x003c0000) -ne 0 -or
                                $epilogStart -ge $armFunctionLength -or
                                $epilogCodeIndex -ge ([uint32]$codeWords * [uint32]4)) {
                            throw "'$Path' has invalid ARM64 epilog-scope metadata."
                        }
                    }
                }
                $armFunctionEnd = [uint32]($functionBegin + $armFunctionLength)
                $armEndSection = Get-RvaSection -Rva ([uint32]($armFunctionEnd - 1)) `
                    -Length 1 -Sections $sections -Label 'ARM64 function end RVA'
                if ($armEndSection.VirtualAddress -ne $beginSection.VirtualAddress -or
                        ($armEndSection.Characteristics -band 0x20000000) -eq 0 -or
                        ($armEndSection.Characteristics -band 0x80000000) -ne 0) {
                    throw "'$Path' has ARM64 unwind data spanning invalid code."
                }
                $currentFunctionEnd = $armFunctionEnd
            } else {
                $packedFunctionLength = [uint32]((($unwindData -shr 2) -band 0x7ff) * 4)
                if ($packedFunctionLength -eq 0 -or
                        [uint64]$functionBegin + $packedFunctionLength -gt $sizeOfImage) {
                    throw "'$Path' has invalid packed ARM64 unwind information."
                }
                $packedEnd = [uint32]($functionBegin + $packedFunctionLength)
                $packedEndSection = Get-RvaSection -Rva ([uint32]($packedEnd - 1)) `
                    -Length 1 -Sections $sections -Label 'Packed ARM64 function end RVA'
                if ($packedEndSection.VirtualAddress -ne $beginSection.VirtualAddress -or
                        ($packedEndSection.Characteristics -band 0x20000000) -eq 0 -or
                        ($packedEndSection.Characteristics -band 0x80000000) -ne 0) {
                    throw "'$Path' has packed ARM64 unwind data spanning invalid code."
                }
                $currentFunctionEnd = $packedEnd
            }
        }
        $previousFunctionBegin = $functionBegin
        $previousFunctionEnd = $currentFunctionEnd
    }

    $iatRva = Read-UInt32LE $bytes ($directoryBase + 96) 'IAT RVA'
    $iatSize = Read-UInt32LE $bytes ($directoryBase + 100) 'IAT size'
    if ($iatRva -eq 0 -or $iatSize -lt 8 -or ($iatSize % 8) -ne 0) {
        throw "'$Path' has no bounded PE32+ IAT."
    }
    Convert-RvaToOffset -Rva $iatRva -Length $iatSize -Sections $sections `
        -SizeOfHeaders $sizeOfHeaders -Bytes $bytes | Out-Null
    $iatEnd = [uint64]$iatRva + [uint64]$iatSize

    $importRva = Read-UInt32LE $bytes ($directoryBase + 8) 'Import RVA'
    $importSize = Read-UInt32LE $bytes ($directoryBase + 12) 'Import size'
    if ($importRva -eq 0 -or $importSize -lt 40 -or ($importSize % 20) -ne 0 -or
            $importSize -gt (33 * 20)) {
        throw "'$Path' has no bounded import table."
    }
    $importOffset = Convert-RvaToOffset -Rva $importRva -Length $importSize `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $imports = @()
    $importDescriptors = @()
    $iatRanges = @()
    $descriptorCount = [int]($importSize / 20)
    $foundTerminator = $false
    for ($index = 0; $index -lt $descriptorCount; $index++) {
        $descriptor = $importOffset + ($index * 20)
        $originalThunk = Read-UInt32LE $bytes $descriptor 'Import lookup RVA'
        $timeDate = Read-UInt32LE $bytes ($descriptor + 4) 'Import timestamp'
        $forwarder = Read-UInt32LE $bytes ($descriptor + 8) 'Import forwarder'
        $nameRva = Read-UInt32LE $bytes ($descriptor + 12) 'Import name RVA'
        $firstThunk = Read-UInt32LE $bytes ($descriptor + 16) 'Import address RVA'
        if (($originalThunk -bor $timeDate -bor $forwarder -bor $nameRva -bor $firstThunk) -eq 0) {
            if ($index -ne ($descriptorCount - 1)) {
                throw "'$Path' has data after the import-table terminator."
            }
            $foundTerminator = $true
            break
        }
        if ($nameRva -eq 0 -or $firstThunk -eq 0 -or $originalThunk -eq 0 -or
                $timeDate -ne 0 -or $forwarder -ne 0) {
            throw "'$Path' contains an incomplete import descriptor."
        }
        if ([uint64]$firstThunk -lt [uint64]$iatRva -or
                [uint64]$firstThunk -ge $iatEnd) {
            throw "'$Path' contains an import descriptor outside the IAT directory."
        }
        $lookupTable = Read-PeImportThunkTable -Bytes $bytes -TableRva $originalThunk `
            -Sections $sections -MaximumEndRva 0x100000000 `
            -Label 'Import lookup thunk'
        $addressTable = Read-PeImportThunkTable -Bytes $bytes -TableRva $firstThunk `
            -Sections $sections -MaximumEndRva $iatEnd -Label 'Import address thunk'
        if ($lookupTable.Values.Count -ne $addressTable.Values.Count) {
            throw "'$Path' import lookup and address thunk sequences differ."
        }
        for ($thunkIndex = 0; $thunkIndex -lt $lookupTable.Values.Count; $thunkIndex++) {
            if ([uint64]$lookupTable.Values[$thunkIndex] -ne
                    [uint64]$addressTable.Values[$thunkIndex]) {
                throw "'$Path' import lookup and address thunk sequences differ."
            }
        }
        $iatRanges += [pscustomobject]@{
            Start  = [uint64]$firstThunk
            Length = [uint64]$addressTable.ByteCount
        }
        $dllName = Read-PeAsciiZ -Bytes $bytes -Rva $nameRva -Sections $sections `
            -SizeOfHeaders $sizeOfHeaders -Maximum 128
        $imports += $dllName
        $importDescriptors += [pscustomobject]@{
            Name    = $dllName
            Symbols = [string[]]$lookupTable.Names
        }
    }
    if (-not $foundTerminator) {
        throw "'$Path' has no in-directory import-table terminator."
    }
    Assert-NoOverlappingRange -Ranges $iatRanges -Label 'Import address table'
    $orderedIatRanges = @($iatRanges | Sort-Object { [uint64]$_.Start })
    $expectedIatRva = [uint64]$iatRva
    foreach ($range in $orderedIatRanges) {
        if ([uint64]$range.Start -ne $expectedIatRva) {
            throw "'$Path' has unreferenced or disordered IAT entries."
        }
        $expectedIatRva += [uint64]$range.Length
    }
    if ($expectedIatRva -ne $iatEnd) {
        throw "'$Path' does not bind the complete declared IAT."
    }
    $expectedImports = @('ADVAPI32.dll', 'bcrypt.dll', 'KERNEL32.dll', 'SHELL32.dll')
    if (@($imports | Select-Object -Unique).Count -ne $imports.Count) {
        throw "'$Path' contains a duplicate DLL import descriptor."
    }
    $difference = Compare-Object -ReferenceObject ($expectedImports | Sort-Object) `
        -DifferenceObject ($imports | Sort-Object) -CaseSensitive
    if ($difference) {
        throw "'$Path' has an unexpected DLL import set: $($imports -join ', ')."
    }

    $kernel32Symbols = @(
        'CancelIoEx',
        'CancelSynchronousIo',
        'CloseHandle',
        'CompareStringOrdinal',
        'CreateDirectoryW',
        'CreateEventW',
        'CreateFileW',
        'CreateIoCompletionPort',
        'CreateJobObjectW',
        'CreatePipe',
        'CreateProcessW',
        'CreateThread',
        'DeleteFileW',
        'DeleteProcThreadAttributeList',
        'DuplicateHandle',
        'ExitProcess',
        'FindClose',
        'FindFirstFileW',
        'FindNextFileW',
        'GetCommandLineW',
        'GetCurrentProcess',
        'GetCurrentProcessId',
        'GetDriveTypeW',
        'GetEnvironmentVariableW',
        'GetExitCodeProcess',
        'GetFileInformationByHandleEx',
        'GetFileSizeEx',
        'GetFileType',
        'GetFinalPathNameByHandleW',
        'GetHandleInformation',
        'GetLastError',
        'GetModuleFileNameW',
        'GetNamedPipeServerProcessId',
        'GetNamedPipeServerSessionId',
        'GetOverlappedResult',
        'GetProcessHeap',
        'GetProcessTimes',
        'GetQueuedCompletionStatus',
        'GetSystemDirectoryW',
        'GetSystemTimeAsFileTime',
        'GetSystemWindowsDirectoryW',
        'GetTickCount64',
        'HeapAlloc',
        'HeapFree',
        'InitializeProcThreadAttributeList',
        'IsProcessInJob',
        'LocalFree',
        'OpenProcess',
        'PeekNamedPipe',
        'ProcessIdToSessionId',
        'QueryFullProcessImageNameW',
        'QueryInformationJobObject',
        'ReadFile',
        'RemoveDirectoryW',
        'ResumeThread',
        'RtlCaptureContext',
        'SetHandleInformation',
        'SetInformationJobObject',
        'SetLastError',
        'SetNamedPipeHandleState',
        'SetUnhandledExceptionFilter',
        'Sleep',
        'TerminateJobObject',
        'TerminateProcess',
        'UnhandledExceptionFilter',
        'UpdateProcThreadAttribute',
        'WaitForMultipleObjects',
        'WaitForSingleObject',
        'WaitNamedPipeW',
        'WriteFile'
    )
    if ($ExpectedMachine -eq 0x8664) {
        $kernel32Symbols += @(
            'GetCurrentThreadId',
            'GetTickCount',
            'QueryPerformanceCounter',
            'RtlLookupFunctionEntry',
            'RtlVirtualUnwind'
        )
    }
    $expectedImportSymbols = [ordered]@{
        'ADVAPI32.dll' = @(
            'CheckTokenMembership',
            'ConvertSidToStringSidW',
            'ConvertStringSecurityDescriptorToSecurityDescriptorW',
            'CreateWellKnownSid',
            'DuplicateToken',
            'EqualSid',
            'GetAce',
            'GetAclInformation',
            'GetSecurityInfo',
            'GetSidSubAuthority',
            'GetSidSubAuthorityCount',
            'GetTokenInformation',
            'IsValidSid',
            'IsWellKnownSid',
            'LookupAccountNameW',
            'MapGenericMask',
            'OpenProcessToken'
        )
        'bcrypt.dll' = @(
            'BCryptCloseAlgorithmProvider',
            'BCryptCreateHash',
            'BCryptDestroyHash',
            'BCryptFinishHash',
            'BCryptGetProperty',
            'BCryptHashData',
            'BCryptOpenAlgorithmProvider'
        )
        'KERNEL32.dll' = $kernel32Symbols
        'SHELL32.dll' = @('CommandLineToArgvW', 'SHGetFolderPathW')
    }
    foreach ($descriptor in $importDescriptors) {
        $actualSymbols = @($descriptor.Symbols)
        if (@($actualSymbols | Select-Object -Unique).Count -ne $actualSymbols.Count) {
            throw "'$Path' contains duplicate imports from $($descriptor.Name)."
        }
        $symbolDifference = Compare-Object `
            -ReferenceObject @($expectedImportSymbols[$descriptor.Name] | Sort-Object) `
            -DifferenceObject @($actualSymbols | Sort-Object) -CaseSensitive
        if ($symbolDifference) {
            throw "'$Path' has an unexpected $($descriptor.Name) import-symbol set."
        }
    }

    $resourceRva = Read-UInt32LE $bytes ($directoryBase + 16) 'Resource RVA'
    $resourceSize = Read-UInt32LE $bytes ($directoryBase + 20) 'Resource size'
    if ($resourceRva -eq 0 -or $resourceSize -lt 16) {
        throw "'$Path' has no resource directory."
    }
    $resourceRoot = Convert-RvaToOffset -Rva $resourceRva -Length $resourceSize `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $rootNamedCount = Read-UInt16LE $bytes ($resourceRoot + 12) `
        'Root resource named count'
    $rootIdCount = Read-UInt16LE $bytes ($resourceRoot + 14) `
        'Root resource ID count'
    if ($rootNamedCount -ne 0 -or $rootIdCount -ne 2 -or
            (Read-UInt32LE $bytes ($resourceRoot + 16) 'VERSIONINFO resource ID') -ne 16 -or
            (Read-UInt32LE $bytes ($resourceRoot + 24) 'RT_MANIFEST resource ID') -ne 24) {
        throw "'$Path' does not contain the exact VERSIONINFO/RT_MANIFEST resource type set."
    }
    $manifestType = Get-ResourceDirectoryEntry -Bytes $bytes `
        -ResourceRootOffset $resourceRoot -ResourceSize $resourceSize `
        -DirectoryRelativeOffset 0 -Id 24
    if (-not $manifestType -or -not $manifestType.IsDirectory) {
        throw "'$Path' has no RT_MANIFEST resource directory."
    }
    $manifestTypeDirectory = $resourceRoot + $manifestType.Offset
    if ((Read-UInt16LE $bytes ($manifestTypeDirectory + 12) `
                'RT_MANIFEST named count') -ne 0 -or
            (Read-UInt16LE $bytes ($manifestTypeDirectory + 14) `
                'RT_MANIFEST ID count') -ne 1) {
        throw "'$Path' must contain exactly one numeric RT_MANIFEST name."
    }
    $manifestName = Get-ResourceDirectoryEntry -Bytes $bytes `
        -ResourceRootOffset $resourceRoot -ResourceSize $resourceSize `
        -DirectoryRelativeOffset $manifestType.Offset -Id 1
    if (-not $manifestName -or -not $manifestName.IsDirectory) {
        throw "'$Path' has no RT_MANIFEST ID 1."
    }
    Assert-ResourceRange -RelativeOffset $manifestName.Offset -Length 24 `
        -ResourceSize $resourceSize -Label 'Manifest language directory'
    $languageDirectory = $resourceRoot + $manifestName.Offset
    $languageNamedCount = Read-UInt16LE $bytes ($languageDirectory + 12) `
        'Manifest language names'
    $languageIdCount = Read-UInt16LE $bytes ($languageDirectory + 14) `
        'Manifest language IDs'
    if ($languageNamedCount -ne 0 -or $languageIdCount -ne 1) {
        throw "'$Path' must contain exactly one numeric manifest language."
    }
    $languageId = Read-UInt32LE $bytes ($languageDirectory + 16) 'Manifest language ID'
    if ($languageId -ne 0x0409) {
        throw "'$Path' does not use the canonical en-US manifest language ID."
    }
    $languageTarget = Read-UInt32LE $bytes ($languageDirectory + 20) 'Manifest language target'
    if (($languageTarget -band 0x80000000) -ne 0) {
        throw "'$Path' manifest language does not point to data."
    }
    $manifestDataRelative = $languageTarget -band 0x7fffffff
    Assert-ResourceRange -RelativeOffset $manifestDataRelative -Length 16 `
        -ResourceSize $resourceSize -Label 'Manifest data entry'
    $manifestDataEntry = $resourceRoot + $manifestDataRelative
    $manifestRva = Read-UInt32LE $bytes $manifestDataEntry 'Manifest data RVA'
    $manifestLength = Read-UInt32LE $bytes ($manifestDataEntry + 4) 'Manifest length'
    $manifestCodePage = Read-UInt32LE $bytes ($manifestDataEntry + 8) `
        'Manifest code page'
    $manifestReserved = Read-UInt32LE $bytes ($manifestDataEntry + 12) `
        'Manifest reserved field'
    if ($manifestLength -eq 0 -or $manifestLength -gt 64KB) {
        throw "'$Path' has an invalid manifest size."
    }
    if ($manifestCodePage -ne 0 -or $manifestReserved -ne 0 -or
            [uint64]$manifestRva -lt [uint64]$resourceRva) {
        throw "'$Path' has noncanonical manifest resource metadata."
    }
    $manifestResourceRelative = [uint64]$manifestRva - [uint64]$resourceRva
    Assert-RelativeRange -Offset $manifestResourceRelative -Length $manifestLength `
        -ContainerLength $resourceSize -Label 'Manifest resource data'
    $manifestOffset = Convert-RvaToOffset -Rva $manifestRva -Length $manifestLength `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
    $manifest = $strictUtf8.GetString($bytes, [int]$manifestOffset, [int]$manifestLength)
    $manifestBytes = New-Object byte[] $manifestLength
    [Array]::Copy($bytes, $manifestOffset, $manifestBytes, 0, $manifestLength)
    $manifestSha256Provider = [Security.Cryptography.SHA256]::Create()
    try {
        $embeddedManifestSha256 = [BitConverter]::ToString(
            $manifestSha256Provider.ComputeHash($manifestBytes)).Replace('-', '')
    }
    finally {
        $manifestSha256Provider.Dispose()
    }
    $xmlSettings = New-Object Xml.XmlReaderSettings
    $xmlSettings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $xmlSettings.XmlResolver = $null
    $xmlSettings.MaxCharactersInDocument = 64KB
    $stringReader = New-Object IO.StringReader($manifest)
    $xmlReader = [Xml.XmlReader]::Create($stringReader, $xmlSettings)
    try {
        $manifestDocument = New-Object Xml.XmlDocument
        $manifestDocument.XmlResolver = $null
        $manifestDocument.Load($xmlReader)
    }
    finally {
        $xmlReader.Dispose()
        $stringReader.Dispose()
    }
    $namespaceManager = New-Object Xml.XmlNamespaceManager($manifestDocument.NameTable)
    $namespaceManager.AddNamespace('asmv1', 'urn:schemas-microsoft-com:asm.v1')
    $namespaceManager.AddNamespace('asmv3', 'urn:schemas-microsoft-com:asm.v3')
    $namespaceManager.AddNamespace(
        'ws2016', 'http://schemas.microsoft.com/SMI/2016/WindowsSettings')
    $allExecutionNodes = @($manifestDocument.SelectNodes(
        "//*[local-name()='requestedExecutionLevel']"))
    $executionNodes = @($manifestDocument.SelectNodes(
        '/asmv1:assembly/asmv3:trustInfo/asmv3:security/' +
        'asmv3:requestedPrivileges/asmv3:requestedExecutionLevel',
        $namespaceManager))
    $allLongPathNodes = @($manifestDocument.SelectNodes(
        "//*[local-name()='longPathAware']"))
    $longPathNodes = @($manifestDocument.SelectNodes(
        '/asmv1:assembly/asmv3:application/asmv3:windowsSettings/' +
        'ws2016:longPathAware', $namespaceManager))
    if ($manifestDocument.DocumentElement.LocalName -cne 'assembly' -or
            $manifestDocument.DocumentElement.NamespaceURI -cne
            'urn:schemas-microsoft-com:asm.v1' -or
            $allExecutionNodes.Count -ne 1 -or $executionNodes.Count -ne 1 -or
            $executionNodes[0].Attributes.Count -ne 2 -or
            $executionNodes[0].GetAttribute('level') -cne 'requireAdministrator' -or
            $executionNodes[0].GetAttribute('uiAccess') -cne 'false' -or
            $allLongPathNodes.Count -ne 1 -or $longPathNodes.Count -ne 1 -or
            $longPathNodes[0].InnerText -cne 'true') {
        throw "'$Path' does not embed the required elevation/long-path manifest."
    }

    $relocRva = Read-UInt32LE $bytes ($directoryBase + 40) 'Relocation RVA'
    $relocSize = Read-UInt32LE $bytes ($directoryBase + 44) 'Relocation size'
    if ($relocRva -eq 0 -or $relocSize -lt 12 -or $relocSize -gt 1MB -or
            ($relocSize % 4) -ne 0) {
        throw "'$Path' lacks a nonempty bounded relocation directory."
    }
    $relocOffset = Convert-RvaToOffset -Rva $relocRva -Length $relocSize `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $relocCursor = [uint32]0
    $hasRelocation = $false
    $previousRelocPageRva = $null
    $previousRelocationTargetRva = $null
    $relocationTargets = New-Object 'Collections.Generic.HashSet[uint64]'
    while ($relocCursor -lt $relocSize) {
        Assert-RelativeRange -Offset $relocCursor -Length 8 -ContainerLength $relocSize `
            -Label 'Relocation block header'
        $block = $relocOffset + $relocCursor
        $pageRva = Read-UInt32LE $bytes $block 'Relocation page RVA'
        $blockSize = Read-UInt32LE $bytes ($block + 4) 'Relocation block size'
        if (($pageRva % 0x1000) -ne 0 -or $blockSize -lt 12 -or
                ($blockSize % 4) -ne 0) {
            throw "'$Path' has a malformed relocation block."
        }
        if ($null -ne $previousRelocPageRva -and $pageRva -le $previousRelocPageRva) {
            throw "'$Path' has duplicate or unordered relocation pages."
        }
        Assert-RelativeRange -Offset $relocCursor -Length $blockSize `
            -ContainerLength $relocSize -Label 'Relocation block'
        $blockHasRelocation = $false
        $paddingSeen = $false
        for ($entryOffset = 8; $entryOffset -lt $blockSize; $entryOffset += 2) {
            $entry = Read-UInt16LE $bytes ($block + $entryOffset) 'Relocation entry'
            $type = $entry -shr 12
            if ($type -eq 0) {
                $paddingSeen = $true
                continue
            }
            if ($paddingSeen) {
                throw "'$Path' has noncanonical relocation padding."
            }
            if ($type -ne 10) {
                throw "'$Path' has an unexpected base-relocation type."
            }
            $targetRva = [uint64]$pageRva + [uint64]($entry -band 0x0fff)
            if (($targetRva % 8) -ne 0 -or
                    $targetRva -gt ([uint64]$sizeOfImage - [uint64]8) -or
                    $targetRva -gt [uint32]::MaxValue) {
                throw "'$Path' has a relocation target outside the image."
            }
            if (($null -ne $previousRelocationTargetRva -and
                    $targetRva -le $previousRelocationTargetRva) -or
                    -not $relocationTargets.Add($targetRva)) {
                throw "'$Path' has duplicate or unordered relocation targets."
            }
            $targetOffset = Convert-RvaToOffset -Rva ([uint32]$targetRva) -Length 8 `
                -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
            $relocatedValue = Read-UInt64LE $bytes $targetOffset `
                'DIR64 relocation target value'
            if ($relocatedValue -lt $imageBase -or
                    ($relocatedValue - $imageBase) -ge [uint64]$sizeOfImage) {
                throw "'$Path' has a DIR64 relocation over a non-image VA."
            }
            $previousRelocationTargetRva = $targetRva
            $blockHasRelocation = $true
            $hasRelocation = $true
        }
        if (-not $blockHasRelocation) {
            throw "'$Path' has an empty relocation block."
        }
        $previousRelocPageRva = $pageRva
        $relocCursor += $blockSize
    }
    if (-not $hasRelocation -or $relocCursor -ne $relocSize) {
        throw "'$Path' has no effective base relocation."
    }

    $tlsRva = Read-UInt32LE $bytes ($directoryBase + 72) 'TLS RVA'
    $tlsSize = Read-UInt32LE $bytes ($directoryBase + 76) 'TLS size'
    if (($tlsRva -bor $tlsSize) -ne 0) {
        throw "'$Path' unexpectedly contains a TLS directory."
    }

    $loadConfigRva = Read-UInt32LE $bytes ($directoryBase + 80) 'Load-config RVA'
    $loadConfigSize = Read-UInt32LE $bytes ($directoryBase + 84) 'Load-config size'
    if ($loadConfigRva -eq 0 -or $loadConfigSize -ne 0x148) {
        throw "'$Path' lacks the bounded CFG/security-cookie load configuration."
    }
    $loadConfigOffset = Convert-RvaToOffset -Rva $loadConfigRva -Length $loadConfigSize `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $internalLoadConfigSize = Read-UInt32LE $bytes $loadConfigOffset `
        'Load-config internal size'
    if ($internalLoadConfigSize -ne 0x148) {
        throw "'$Path' has inconsistent load-config bounds."
    }
    foreach ($zeroRange in @(
            @{ Offset = 0x04; Length = 0x4a },
            @{ Offset = 0x50; Length = 0x08 },
            @{ Offset = 0x60; Length = 0x10 }
        )) {
        for ($zeroOffset = $zeroRange.Offset;
                $zeroOffset -lt ($zeroRange.Offset + $zeroRange.Length);
                $zeroOffset++) {
            if ($bytes[$loadConfigOffset + $zeroOffset] -ne 0) {
                throw "'$Path' contains unexpected legacy load-config state."
            }
        }
    }
    $dependentLoadFlags = Read-UInt16LE $bytes ($loadConfigOffset + 0x4e) `
        'DependentLoadFlags'
    if ($dependentLoadFlags -ne 0x0800) {
        throw ("'{0}' has DependentLoadFlags 0x{1:X4}; expected 0x0800." -f
            $Path, $dependentLoadFlags)
    }
    $securityCookieVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x58) `
        'Security-cookie VA'
    if ($securityCookieVa -eq 0) {
        throw "'$Path' has no security cookie."
    }
    $securityCookieRva = Convert-VaToRva -Va $securityCookieVa -ImageBase $imageBase `
        -SizeOfImage $sizeOfImage -Label 'Security-cookie VA'
    $securityCookieOffset = Convert-RvaToOffset -Rva $securityCookieRva -Length 8 `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $securityCookieSection = Get-RvaSection -Rva $securityCookieRva -Length 8 `
        -Sections $sections -Label 'Security cookie'
    if (($securityCookieRva % 8) -ne 0 -or
            (Read-UInt64LE $bytes $securityCookieOffset 'Security-cookie value') -eq 0 -or
            ($securityCookieSection.Characteristics -band 0x80000000) -eq 0 -or
            ($securityCookieSection.Characteristics -band 0x20000000) -ne 0) {
        throw "'$Path' has no nonzero cookie in writable non-executable image data."
    }

    $guardCheckVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x70) `
        'GuardCF check-function VA'
    $guardDispatchVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x78) `
        'GuardCF dispatch-function VA'
    $guardTableVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x80) `
        'GuardCF function-table VA'
    $guardCount = Read-UInt64LE $bytes ($loadConfigOffset + 0x88) `
        'GuardCF function count'
    $guardFlags = Read-UInt32LE $bytes ($loadConfigOffset + 0x90) 'Guard flags'
    if ($guardCheckVa -eq 0 -or $guardDispatchVa -eq 0 -or $guardTableVa -eq 0 -or
            $guardCount -ne 7 -or $guardFlags -ne 0x00010500) {
        throw "'$Path' lacks the required complete GuardCF load configuration."
    }
    for ($extendedOffset = 0x94; $extendedOffset -lt 0x118; $extendedOffset++) {
        if ($bytes[$loadConfigOffset + $extendedOffset] -ne 0) {
            throw "'$Path' contains unexpected extended load-config state."
        }
    }
    foreach ($zeroPointerOffset in @(0x138, 0x140)) {
        if ((Read-UInt64LE $bytes ($loadConfigOffset + $zeroPointerOffset) `
                'Unused load-config pointer') -ne 0) {
            throw "'$Path' contains an unexpected nonzero load-config pointer."
        }
    }

    $xfgCheckVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x118) `
        'GuardXFG check-function-pointer VA'
    $xfgDispatchVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x120) `
        'GuardXFG dispatch-function-pointer VA'
    $xfgTableDispatchVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x128) `
        'GuardXFG table-dispatch-function-pointer VA'
    $castGuardVa = Read-UInt64LE $bytes ($loadConfigOffset + 0x130) `
        'CastGuard failure-mode-pointer VA'
    if ($castGuardVa -eq 0) {
        throw "'$Path' lacks the required CastGuard pointer slot."
    }
    if ($ExpectedMachine -eq 0x8664) {
        if ($xfgCheckVa -eq 0 -or $xfgDispatchVa -eq 0 -or $xfgTableDispatchVa -eq 0 -or
                $xfgCheckVa -eq $xfgDispatchVa -or $xfgCheckVa -eq $xfgTableDispatchVa -or
                $xfgDispatchVa -eq $xfgTableDispatchVa -or $castGuardVa -eq $xfgCheckVa -or
                $castGuardVa -eq $xfgDispatchVa -or $castGuardVa -eq $xfgTableDispatchVa) {
            throw "'$Path' lacks the exact amd64 GuardXFG/CastGuard pointer layout."
        }
    } elseif (($xfgCheckVa -bor $xfgDispatchVa -bor $xfgTableDispatchVa) -ne 0) {
        throw "'$Path' has unexpected ARM64 GuardXFG pointer state."
    }

    $pointerFieldOffsets = @(
        @{ Offset = 0x58; Value = $securityCookieVa; Label = 'Security-cookie VA' },
        @{ Offset = 0x70; Value = $guardCheckVa; Label = 'GuardCF check-function VA' },
        @{ Offset = 0x78; Value = $guardDispatchVa; Label = 'GuardCF dispatch-function VA' },
        @{ Offset = 0x80; Value = $guardTableVa; Label = 'GuardCF function-table VA' },
        @{ Offset = 0x50; Value = 0; Label = 'EditList VA' },
        @{ Offset = 0x60; Value = 0; Label = 'SEH table VA' },
        @{ Offset = 0xA0; Value = 0; Label = 'Guard address-taken IAT table VA' },
        @{ Offset = 0xB0; Value = 0; Label = 'Guard long-jump table VA' },
        @{ Offset = 0xC0; Value = 0; Label = 'Dynamic-value relocation table VA' },
        @{ Offset = 0xC8; Value = 0; Label = 'CHPE metadata VA' },
        @{ Offset = 0xD0; Value = 0; Label = 'Guard RF failure-routine VA' },
        @{ Offset = 0xD8; Value = 0; Label = 'Guard RF failure-pointer VA' },
        @{ Offset = 0xE8; Value = 0; Label = 'Guard RF stack-pointer verifier VA' },
        @{ Offset = 0xF8; Value = 0; Label = 'Enclave configuration VA' },
        @{ Offset = 0x100; Value = 0; Label = 'Volatile metadata VA' },
        @{ Offset = 0x108; Value = 0; Label = 'Guard EH continuation-table VA' },
        @{ Offset = 0x118; Value = $xfgCheckVa; Label = 'GuardXFG check-function-pointer VA' },
        @{ Offset = 0x120; Value = $xfgDispatchVa; Label = 'GuardXFG dispatch-function-pointer VA' },
        @{ Offset = 0x128; Value = $xfgTableDispatchVa; Label = 'GuardXFG table-dispatch-function-pointer VA' },
        @{ Offset = 0x130; Value = $castGuardVa; Label = 'CastGuard failure-mode-pointer VA' },
        @{ Offset = 0x138; Value = 0; Label = 'Guard memcpy-function-pointer VA' },
        @{ Offset = 0x140; Value = 0; Label = 'UMA function-pointers VA' }
    )
    $allowedLoadConfigRelocations = New-Object 'Collections.Generic.HashSet[uint64]'
    foreach ($pointerField in $pointerFieldOffsets) {
        $fieldRva = [uint64]$loadConfigRva + [uint64]$pointerField.Offset
        $hasFieldRelocation = $relocationTargets.Contains($fieldRva)
        if (($pointerField.Value -ne 0) -ne $hasFieldRelocation) {
            throw "'$Path' has inconsistent relocation coverage for $($pointerField.Label)."
        }
        if ($pointerField.Value -ne 0) {
            [void]$allowedLoadConfigRelocations.Add($fieldRva)
        }
    }
    $loadConfigEndRva = [uint64]$loadConfigRva + [uint64]0x148
    foreach ($relocationTarget in $relocationTargets) {
        if ($relocationTarget -ge [uint64]$loadConfigRva -and
                $relocationTarget -lt $loadConfigEndRva -and
                -not $allowedLoadConfigRelocations.Contains($relocationTarget)) {
            throw "'$Path' has an unexpected relocation inside the load configuration."
        }
    }

    $guardPointerTargetRvas = New-Object 'Collections.Generic.List[uint32]'
    $guardPointerTargets = @{}
    $guardPointers = @(
        @{ Key = 'GuardCFCheck'; Value = $guardCheckVa; Label = 'GuardCF check-function VA' },
        @{ Key = 'GuardCFDispatch'; Value = $guardDispatchVa; Label = 'GuardCF dispatch-function VA' }
    )
    if ($ExpectedMachine -eq 0x8664) {
        $guardPointers += @(
            @{ Key = 'XFGCheck'; Value = $xfgCheckVa; Label = 'GuardXFG check-function-pointer VA' },
            @{ Key = 'XFGDispatch'; Value = $xfgDispatchVa; Label = 'GuardXFG dispatch-function-pointer VA' },
            @{ Key = 'XFGTableDispatch'; Value = $xfgTableDispatchVa; Label = 'GuardXFG table-dispatch-function-pointer VA' }
        )
    }
    $pointerSlotRvas = New-Object 'Collections.Generic.HashSet[uint32]'
    foreach ($guardPointer in $guardPointers) {
        $guardPointerRva = Convert-VaToRva -Va $guardPointer.Value -ImageBase $imageBase `
            -SizeOfImage $sizeOfImage -Label $guardPointer.Label
        $guardPointerOffset = Convert-RvaToOffset -Rva $guardPointerRva -Length 8 `
            -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
        $guardPointerSection = Get-RvaSection -Rva $guardPointerRva -Length 8 `
            -Sections $sections -Label $guardPointer.Label
        if (($guardPointerRva % 8) -ne 0 -or -not $pointerSlotRvas.Add($guardPointerRva) -or
                ($guardPointerSection.Characteristics -band 0x20000000) -ne 0 -or
                ($guardPointerSection.Characteristics -band 0x80000000) -ne 0) {
            throw "'$Path' has a GuardCF pointer slot in executable or writable data."
        }
        $guardTargetVa = Read-UInt64LE $bytes $guardPointerOffset `
            "$($guardPointer.Label) target"
        $guardTargetRva = Convert-VaToRva -Va $guardTargetVa -ImageBase $imageBase `
            -SizeOfImage $sizeOfImage -Label "$($guardPointer.Label) target"
        $guardTargetSection = Get-RvaSection -Rva $guardTargetRva -Length 1 `
            -Sections $sections -Label "$($guardPointer.Label) target"
        if (($guardTargetSection.Characteristics -band 0x20000000) -eq 0 -or
                ($guardTargetSection.Characteristics -band 0x80000000) -ne 0) {
            throw "'$Path' has a GuardCF pointer whose target is not executable code."
        }
        if (-not $relocationTargets.Contains([uint64]$guardPointerRva)) {
            throw "'$Path' has a non-relocatable GuardCF/XFG pointer-slot target."
        }
        $guardPointerTargetRvas.Add($guardTargetRva)
        $guardPointerTargets[$guardPointer.Key] = $guardTargetRva
    }
    if ($guardPointerTargets.GuardCFCheck -eq $guardPointerTargets.GuardCFDispatch) {
        throw "'$Path' aliases distinct GuardCF handler targets."
    }
    if ($ExpectedMachine -eq 0x8664) {
        if ($guardPointerTargets.GuardCFCheck -ne $guardPointerTargets.XFGCheck -or
                $guardPointerTargets.XFGDispatch -ne
                    $guardPointerTargets.XFGTableDispatch -or
                $guardPointerTargets.GuardCFCheck -eq
                    $guardPointerTargets.XFGDispatch -or
                $guardPointerTargets.GuardCFDispatch -eq
                    $guardPointerTargets.XFGDispatch) {
            throw "'$Path' has inconsistent amd64 GuardCF/GuardXFG pointer targets."
        }
    }

    $castGuardRva = Convert-VaToRva -Va $castGuardVa -ImageBase $imageBase `
        -SizeOfImage $sizeOfImage -Label 'CastGuard failure-mode-pointer VA'
    $castGuardOffset = Convert-RvaToOffset -Rva $castGuardRva -Length 8 `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $castGuardSection = Get-RvaSection -Rva $castGuardRva -Length 8 `
        -Sections $sections -Label 'CastGuard failure-mode-pointer VA'
    if (($castGuardRva % 8) -ne 0 -or $pointerSlotRvas.Contains($castGuardRva) -or
            ($castGuardSection.Characteristics -band 0x20000000) -ne 0 -or
            ($castGuardSection.Characteristics -band 0x80000000) -ne 0 -or
            (Read-UInt64LE $bytes $castGuardOffset 'CastGuard failure-mode target') -ne 0 -or
            $relocationTargets.Contains([uint64]$castGuardRva)) {
        throw "'$Path' has a noncanonical CastGuard failure-mode pointer slot."
    }
    $guardTableRva = Convert-VaToRva -Va $guardTableVa -ImageBase $imageBase `
        -SizeOfImage $sizeOfImage -Label 'GuardCF function-table VA'
    $guardEntrySize = [uint64]4 + [uint64](($guardFlags -shr 28) -band 0x0f)
    if ($guardCount -gt 1MB -or $guardCount -gt
            ([uint64][uint32]::MaxValue / $guardEntrySize)) {
        throw "'$Path' has an oversized GuardCF function table."
    }
    $guardTableLength = $guardCount * $guardEntrySize
    $guardTableOffset = Convert-RvaToOffset -Rva $guardTableRva `
        -Length ([uint32]$guardTableLength) -Sections $sections `
        -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $guardTableSection = Get-RvaSection -Rva $guardTableRva `
        -Length ([uint32]$guardTableLength) -Sections $sections `
        -Label 'GuardCF function table'
    if (($guardTableSection.Characteristics -band 0x20000000) -ne 0 -or
            ($guardTableSection.Characteristics -band 0x80000000) -ne 0) {
        throw "'$Path' has a GuardCF function table in executable or writable data."
    }
    $previousGuardFunctionRva = $null
    $guardFunctionRvas = New-Object 'Collections.Generic.List[uint32]'
    for ($guardIndex = [uint64]0; $guardIndex -lt $guardCount; $guardIndex++) {
        $entryOffset = [uint64]$guardTableOffset + ($guardIndex * $guardEntrySize)
        $guardFunctionRva = Read-UInt32LE $bytes ([long]$entryOffset) `
            'GuardCF function RVA'
        if ($guardFunctionRva -eq 0 -or ($guardFunctionRva % 16) -ne 0 -or
                $guardFunctionRva -ge $sizeOfImage) {
            throw "'$Path' has an invalid GuardCF function-table entry."
        }
        if ($null -ne $previousGuardFunctionRva -and
                $guardFunctionRva -le $previousGuardFunctionRva) {
            throw "'$Path' has duplicate or unordered GuardCF function RVAs."
        }
        $guardFunctionSection = Get-RvaSection -Rva $guardFunctionRva -Length 1 `
            -Sections $sections -Label 'GuardCF function RVA'
        if (($guardFunctionSection.Characteristics -band 0x20000000) -eq 0 -or
                ($guardFunctionSection.Characteristics -band 0x80000000) -ne 0) {
            throw "'$Path' has a GuardCF target outside executable non-writable image data."
        }
        if ($guardEntrySize -gt 4) {
            $metadata = $bytes[[int]($entryOffset + 4)]
            if (($metadata -band 0xf0) -ne 0) {
                throw "'$Path' has undefined GuardCF function metadata flags."
            }
            for ($metadataIndex = 5; $metadataIndex -lt $guardEntrySize; $metadataIndex++) {
                if ($bytes[[int]($entryOffset + $metadataIndex)] -ne 0) {
                    throw "'$Path' has nonzero reserved GuardCF function metadata."
                }
            }
        }
        $guardFunctionRvas.Add($guardFunctionRva)
        $previousGuardFunctionRva = $guardFunctionRva
    }
    foreach ($guardPointerTargetRva in $guardPointerTargetRvas) {
        if (-not $guardFunctionRvas.Contains($guardPointerTargetRva)) {
            throw "'$Path' has a GuardCF pointer target absent from its function table."
        }
    }

    $delayImportRva = Read-UInt32LE $bytes ($directoryBase + 104) 'Delay-import RVA'
    $delayImportSize = Read-UInt32LE $bytes ($directoryBase + 108) 'Delay-import size'
    if (($delayImportRva -bor $delayImportSize) -ne 0) {
        throw "'$Path' unexpectedly contains a delay-import directory."
    }

    $debugRva = Read-UInt32LE $bytes ($directoryBase + 48) 'Debug RVA'
    $debugSize = Read-UInt32LE $bytes ($directoryBase + 52) 'Debug size'
    if ($debugRva -eq 0 -or $debugSize -ne 56) {
        throw "'$Path' has an invalid debug directory."
    }
    $debugOffset = Convert-RvaToOffset -Rva $debugRva -Length $debugSize `
        -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
    $cetCount = 0
    $reproCount = 0
    for ($index = 0; $index -lt ($debugSize / 28); $index++) {
        $entry = $debugOffset + ($index * 28)
        $type = Read-UInt32LE $bytes ($entry + 12) 'Debug type'
        $dataSize = Read-UInt32LE $bytes ($entry + 16) 'Debug data size'
        $dataRva = Read-UInt32LE $bytes ($entry + 20) 'Debug data RVA'
        $dataOffset = Read-UInt32LE $bytes ($entry + 24) 'Debug data offset'
        if (($dataSize -eq 0) -ne (($dataRva -bor $dataOffset) -eq 0)) {
            throw "'$Path' has inconsistent debug-data bounds."
        }
        if ($dataSize -ne 0) {
            Assert-Range -Bytes $bytes -Offset $dataOffset -Length $dataSize `
                -Label 'Debug data'
            $mappedDebugData = Convert-RvaToOffset -Rva $dataRva -Length $dataSize `
                -Sections $sections -SizeOfHeaders $sizeOfHeaders -Bytes $bytes
            if ($mappedDebugData -ne $dataOffset) {
                throw "'$Path' has mismatched debug RVA/file offsets."
            }
        }
        if ($type -eq 16) {
            if ($dataSize -ne 0 -or ($dataRva -bor $dataOffset) -ne 0) {
                throw "'$Path' has malformed reproducible-build debug evidence."
            }
            $reproCount++
        } elseif ($type -eq 20) {
            if ($dataSize -ne 4 -or
                    (Read-UInt32LE $bytes $dataOffset `
                        'Extended DLL characteristics') -ne 1) {
                throw "'$Path' has malformed CET debug evidence."
            }
            $cetCount++
        } else {
            throw "'$Path' contains an unexpected debug-directory type."
        }
    }
    $hasCet = $cetCount -eq 1
    $hasRepro = $reproCount -eq 1
    if (-not $hasCet -or -not $hasRepro) {
        throw "'$Path' lacks CET compatibility or the reproducible-build marker."
    }

    $clrRva = Read-UInt32LE $bytes ($directoryBase + 112) 'CLR header RVA'
    $clrSize = Read-UInt32LE $bytes ($directoryBase + 116) 'CLR header size'
    if (($clrRva -bor $clrSize) -ne 0) {
        throw "'$Path' unexpectedly contains a CLR header."
    }

    $result = [pscustomobject]@{
        Path               = $pathItem.FullName
        Machine            = $machine
        Length             = $bytes.LongLength
        SHA256             = $artifactSha256
        DllCharacteristics = $dllCharacteristics
        Imports            = @($imports)
        CetCompatible      = $hasCet
        Reproducible       = $hasRepro
        DependentLoadFlags = $dependentLoadFlags
        GuardFlags         = $guardFlags
        GuardFunctionCount = $guardCount
        HasRelocations     = $hasRelocation
        ManifestSHA256     = $embeddedManifestSha256
    }
    if ($null -ne $LeaseCollector) {
        $LeaseCollector.Add($stream)
        $stream = $null
    }
    return $result
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Assert-ManifestKeySet {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Map,
        [Parameter(Mandatory = $true)][string[]]$ExpectedKeys,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $difference = Compare-Object -ReferenceObject @($ExpectedKeys | Sort-Object) `
        -DifferenceObject @($Map.Keys | ForEach-Object { [string]$_ } | Sort-Object) `
        -CaseSensitive
    if ($difference) {
        throw "$Label has an unexpected field set."
    }
}

function ConvertTo-ManifestUInt64 {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowZero
    )

    $integralTypes = @(
        [byte], [sbyte], [uint16], [int16], [uint32], [int32], [uint64], [int64]
    )
    $isIntegral = $false
    foreach ($type in $integralTypes) {
        if ($Value -is $type) {
            $isIntegral = $true
            break
        }
    }
    if (-not $isIntegral -or ([decimal]$Value) -lt 0 -or
            (-not $AllowZero -and ([decimal]$Value) -eq 0)) {
        throw "$Label must be a positive integral value."
    }
    return [uint64]$Value
}

function Assert-ManifestSha256 {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Value -isnot [string] -or $Value -cnotmatch '^[0-9A-F]{64}$') {
        throw "$Label must be one uppercase SHA-256 digest."
    }
}

function Assert-ManifestFileEvidence {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Entry,
        [Parameter(Mandatory = $true)][string]$ExpectedFileName,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$RequireVersion
    )

    $keys = @('FileName', 'Length', 'SHA256')
    if ($RequireVersion) {
        $keys += 'Version'
    }
    Assert-ManifestKeySet -Map $Entry -ExpectedKeys $keys -Label $Label
    if ($Entry.FileName -isnot [string] -or
            [string]$Entry.FileName -cne $ExpectedFileName -or
            [IO.Path]::IsPathRooted([string]$Entry.FileName) -or
            [IO.Path]::GetFileName([string]$Entry.FileName) -cne [string]$Entry.FileName) {
        throw "$Label has a nonportable or unexpected FileName."
    }
    ConvertTo-ManifestUInt64 -Value $Entry.Length -Label "$Label.Length" | Out-Null
    Assert-ManifestSha256 -Value $Entry.SHA256 -Label "$Label.SHA256"
    if ($RequireVersion -and ($Entry.Version -isnot [string] -or
            [string]::IsNullOrWhiteSpace([string]$Entry.Version) -or
            [string]$Entry.Version -match '[\r\n]')) {
        throw "$Label.Version is invalid."
    }
}

function Assert-ManifestDirectoryEvidence {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Entry,
        [Parameter(Mandatory = $true)][string]$ExpectedRelativePath,
        [Parameter(Mandatory = $true)][string]$ExpectedVersion,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-ManifestKeySet -Map $Entry `
        -ExpectedKeys @('RelativePath', 'Version', 'FileCount', 'SHA256') `
        -Label $Label
    if ($Entry.RelativePath -isnot [string] -or
            $Entry.Version -isnot [string] -or
            [string]$Entry.RelativePath -cne $ExpectedRelativePath -or
            [string]$Entry.Version -cne $ExpectedVersion -or
            [IO.Path]::IsPathRooted([string]$Entry.RelativePath) -or
            [string]$Entry.RelativePath -match '\\|(^|/)\.\.(/|$)') {
        throw "$Label has invalid portable directory identity evidence."
    }
    ConvertTo-ManifestUInt64 -Value $Entry.FileCount -Label "$Label.FileCount" |
        Out-Null
    Assert-ManifestSha256 -Value $Entry.SHA256 -Label "$Label.SHA256"
}

function Assert-ManifestHashEvidence {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Entry,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-ManifestKeySet -Map $Entry -ExpectedKeys @('Length', 'SHA256') -Label $Label
    ConvertTo-ManifestUInt64 -Value $Entry.Length -Label "$Label.Length" | Out-Null
    Assert-ManifestSha256 -Value $Entry.SHA256 -Label "$Label.SHA256"
}

function Get-LeasedFileEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-AtlasVerifierPathIdentity -Path $Path -Label $Label | Out-Null
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($item.PSIsContainer -or
            ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
        throw "$Label is not a direct regular file."
    }

    $stream = [IO.File]::Open($item.FullName, [IO.FileMode]::Open,
        [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        Assert-AtlasVerifierStreamIdentity -Stream $stream -Path $item.FullName -Label $Label
        if ($stream.Length -le 0 -or $stream.Length -gt 4MB) {
            throw "$Label has an unsupported file length."
        }
        $bytes = New-Object byte[] ([int]$stream.Length)
        $bytesRead = 0
        while ($bytesRead -lt $bytes.Length) {
            $read = $stream.Read($bytes, $bytesRead, $bytes.Length - $bytesRead)
            if ($read -eq 0) {
                throw "$Label ended before its leased file length."
            }
            $bytesRead += $read
        }
        if ($stream.ReadByte() -ne -1) {
            throw "$Label grew while its snapshot was being read."
        }
        $sha256Provider = [Security.Cryptography.SHA256]::Create()
        try {
            $sha256 = [BitConverter]::ToString(
                $sha256Provider.ComputeHash($bytes)).Replace('-', '')
        }
        finally {
            $sha256Provider.Dispose()
        }
        return [pscustomobject]@{
            Stream = $stream
            Length = $bytes.LongLength
            SHA256 = $sha256
            Bytes  = $bytes
        }
    }
    catch {
        $stream.Dispose()
        throw
    }
}

Assert-AtlasVerifierPathIdentity -Path $PayloadDirectory `
    -Label 'The native payload directory' | Out-Null
$payloadItem = Get-Item -LiteralPath $PayloadDirectory -Force -ErrorAction Stop
if (-not $payloadItem.PSIsContainer -or
        ($payloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not [string]::IsNullOrWhiteSpace([string]$payloadItem.LinkType)) {
    throw 'The native payload directory must be a direct, non-reparse directory.'
}
$payloadRoot = $payloadItem.FullName.TrimEnd('\')
$payloadIdentity = Get-AtlasVerifierFinalPathIdentity -Path $payloadRoot
Assert-AtlasVerifierPathIdentity -Path $HashManifestPath `
    -Label 'The elevation-bootstrap hash manifest' | Out-Null
$manifestItem = Get-Item -LiteralPath $HashManifestPath -Force -ErrorAction Stop
if ($manifestItem.PSIsContainer -or
        ($manifestItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not [string]::IsNullOrWhiteSpace([string]$manifestItem.LinkType) -or
        $manifestItem.Name -cne 'Atlas-ElevationBootstrapHashes.psd1' -or
        -not [string]::Equals($manifestItem.DirectoryName, $payloadRoot,
            [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The hash manifest must be the direct, regular canonical child of the payload directory.'
}
$manifestFile = $manifestItem.FullName
$publicationDebris = @(Get-ChildItem -LiteralPath $payloadRoot -Force |
    Where-Object Name -Match `
        '^\.(?:AtlasElevationBootstrap-(?:amd64|arm64)\.exe|Atlas-ElevationBootstrapHashes\.psd1)\.[0-9a-f]{32}\.(?:publish|backup)$')
if ($publicationDebris.Count -ne 0) {
    throw 'The native payload directory contains an incomplete publication transaction.'
}
Assert-AtlasVerifierPathIdentity -Path $payloadRoot -Label 'The native payload directory' `
    -ExpectedIdentity $payloadIdentity | Out-Null
Assert-AtlasVerifierPathIdentity -Path $RepositoryRoot `
    -Label 'The native source repository root' | Out-Null
$repoRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
$manifestEvidence = Get-LeasedFileEvidence -Path $manifestFile `
    -Label 'The elevation-bootstrap hash manifest'
$manifestLease = $manifestEvidence.Stream
$sourceLeases = New-Object 'Collections.Generic.List[object]'
$artifactLeases = New-Object 'Collections.Generic.List[object]'
try {
$manifestBytes = $manifestEvidence.Bytes
if ($manifestBytes.Length -ge 3 -and $manifestBytes[0] -eq 0xef -and
        $manifestBytes[1] -eq 0xbb -and $manifestBytes[2] -eq 0xbf) {
    throw "'$manifestFile' must use strict UTF-8 without a byte-order mark."
}
$strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
try {
    $manifestText = $strictUtf8.GetString($manifestBytes)
}
catch {
    throw "'$manifestFile' is not strict UTF-8."
}
$manifestTokens = $null
$manifestParseErrors = $null
$manifestAst = [Management.Automation.Language.Parser]::ParseInput(
    $manifestText, [ref]$manifestTokens, [ref]$manifestParseErrors)
if ($manifestParseErrors.Count -ne 0 -or $manifestAst.EndBlock.Statements.Count -ne 1 -or
        $manifestAst.EndBlock.Statements[0] -isnot
            [Management.Automation.Language.PipelineAst] -or
        $manifestAst.EndBlock.Statements[0].PipelineElements.Count -ne 1 -or
        $manifestAst.EndBlock.Statements[0].PipelineElements[0] -isnot
            [Management.Automation.Language.CommandExpressionAst] -or
        $manifestAst.EndBlock.Statements[0].PipelineElements[0].Expression -isnot
            [Management.Automation.Language.HashtableAst]) {
    throw "'$manifestFile' is not one literal PowerShell data hashtable."
}
try {
    $hashManifest = $manifestAst.EndBlock.Statements[0].PipelineElements[0].Expression.
        SafeGetValue()
}
catch {
    throw "'$manifestFile' contains a non-literal PowerShell data expression."
}
if ($hashManifest -isnot [Collections.IDictionary]) {
    throw "'$manifestFile' has an unsupported schema."
}
Assert-ManifestKeySet -Map $hashManifest -ExpectedKeys @(
    'SchemaVersion', 'Source', 'Build', 'Toolchain', 'Harness', 'Inputs', 'Artifacts'
) -Label 'Elevation-bootstrap hash manifest'
if ($hashManifest.SchemaVersion -isnot [int] -or $hashManifest.SchemaVersion -ne 3 -or
        $hashManifest.Source -isnot [string] -or
        $hashManifest.Source -cne 'tools/native/Atlas.ElevationBootstrap' -or
        $hashManifest.Build -isnot [Collections.IDictionary] -or
        $hashManifest.Toolchain -isnot [Collections.IDictionary] -or
        $hashManifest.Harness -isnot [Collections.IDictionary] -or
        $hashManifest.Inputs -isnot [Collections.IDictionary] -or
        $hashManifest.Artifacts -isnot [Collections.IDictionary]) {
    throw "'$manifestFile' has an unsupported schema."
}

Assert-ManifestKeySet -Map $hashManifest.Build `
    -ExpectedKeys @('Runtime', 'Reproducibility') -Label 'Build evidence'
if ($hashManifest.Build.Runtime -isnot [string] -or
        $hashManifest.Build.Runtime -cne 'none' -or
        $hashManifest.Build.Reproducibility -isnot [string] -or
        $hashManifest.Build.Reproducibility -cne
        'Two independent unsigned builds compared byte-for-byte per architecture') {
    throw 'The elevation-bootstrap hash manifest has noncanonical Build evidence.'
}

$toolchain = $hashManifest.Toolchain
Assert-ManifestKeySet -Map $toolchain -ExpectedKeys @(
    'ClangCl', 'LldLink', 'ClangResourceDirectory', 'MsvcCompiler', 'MsvcTools',
    'WindowsSdk', 'IncludeDirectories', 'ResourceCompiler',
    'ResourceCompilerDependencies', 'Libraries'
) -Label 'Toolchain evidence'
foreach ($tool in @(
        @{ Key = 'ClangCl'; FileName = 'clang-cl.exe' },
        @{ Key = 'LldLink'; FileName = 'lld-link.exe' },
        @{ Key = 'MsvcCompiler'; FileName = 'cl.exe' },
        @{ Key = 'ResourceCompiler'; FileName = 'rc.exe' }
    )) {
    if ($toolchain[$tool.Key] -isnot [Collections.IDictionary]) {
        throw "Toolchain.$($tool.Key) is not structured evidence."
    }
    Assert-ManifestFileEvidence -Entry $toolchain[$tool.Key] `
        -ExpectedFileName $tool.FileName -Label "Toolchain.$($tool.Key)" -RequireVersion
}
foreach ($versionField in @('MsvcTools', 'WindowsSdk')) {
    $versionValue = $toolchain[$versionField]
    if ($versionValue -isnot [string] -or [string]::IsNullOrWhiteSpace($versionValue) -or
            $versionValue -notmatch '^\d+(?:\.\d+){1,3}$') {
        throw "Toolchain.$versionField is not a portable version."
    }
}
if ([string]$toolchain.MsvcTools -cne '14.51.36231' -or
        [string]$toolchain.WindowsSdk -cne '10.0.26100.0' -or
        [string]$toolchain.ClangCl.Version -notmatch '(?<!\d)22\.1\.8(?!\d)' -or
        [string]$toolchain.LldLink.Version -notmatch '(?<!\d)22\.1\.8(?!\d)') {
    throw 'The elevation-bootstrap hash manifest records an unapproved toolchain version.'
}
$clangResources = $toolchain.ClangResourceDirectory
if ($clangResources -isnot [Collections.IDictionary]) {
    throw 'Toolchain.ClangResourceDirectory is not structured evidence.'
}
Assert-ManifestDirectoryEvidence -Entry $clangResources `
    -ExpectedRelativePath 'lib/clang/22/include' -ExpectedVersion '22' `
    -Label 'Toolchain.ClangResourceDirectory'

$includeDirectories = $toolchain.IncludeDirectories
if ($includeDirectories -isnot [Collections.IDictionary]) {
    throw 'Toolchain.IncludeDirectories is not structured evidence.'
}
$expectedIncludeDirectories = [ordered]@{
    Msvc = @{
        RelativePath = 'VC/Tools/MSVC/14.51.36231/include'
        Version = '14.51.36231'
    }
    WindowsSdkUcrt = @{
        RelativePath = 'Include/10.0.26100.0/ucrt'
        Version = '10.0.26100.0'
    }
    WindowsSdkShared = @{
        RelativePath = 'Include/10.0.26100.0/shared'
        Version = '10.0.26100.0'
    }
    WindowsSdkUm = @{
        RelativePath = 'Include/10.0.26100.0/um'
        Version = '10.0.26100.0'
    }
}
Assert-ManifestKeySet -Map $includeDirectories `
    -ExpectedKeys @($expectedIncludeDirectories.Keys) `
    -Label 'Toolchain.IncludeDirectories'
foreach ($includeName in $expectedIncludeDirectories.Keys) {
    $entry = $includeDirectories[$includeName]
    if ($entry -isnot [Collections.IDictionary]) {
        throw "Toolchain.IncludeDirectories.$includeName is not structured evidence."
    }
    Assert-ManifestDirectoryEvidence -Entry $entry `
        -ExpectedRelativePath $expectedIncludeDirectories[$includeName].RelativePath `
        -ExpectedVersion $expectedIncludeDirectories[$includeName].Version `
        -Label "Toolchain.IncludeDirectories.$includeName"
}

$resourceCompilerDependencies = $toolchain.ResourceCompilerDependencies
if ($resourceCompilerDependencies -isnot [Collections.IDictionary]) {
    throw 'Toolchain.ResourceCompilerDependencies is not structured evidence.'
}
$expectedResourceCompilerDependencies = @('RCDLL.dll', 'ServicingCommon.dll')
Assert-ManifestKeySet -Map $resourceCompilerDependencies `
    -ExpectedKeys $expectedResourceCompilerDependencies `
    -Label 'Toolchain.ResourceCompilerDependencies'
foreach ($dependencyName in $expectedResourceCompilerDependencies) {
    $dependency = $resourceCompilerDependencies[$dependencyName]
    if ($dependency -isnot [Collections.IDictionary]) {
        throw "Toolchain.ResourceCompilerDependencies.$dependencyName is not structured evidence."
    }
    Assert-ManifestFileEvidence -Entry $dependency -ExpectedFileName $dependencyName `
        -Label "Toolchain.ResourceCompilerDependencies.$dependencyName"
}

$libraries = $toolchain.Libraries
if ($libraries -isnot [Collections.IDictionary]) {
    throw 'Toolchain.Libraries is not structured evidence.'
}
Assert-ManifestKeySet -Map $libraries -ExpectedKeys @('amd64', 'arm64') `
    -Label 'Toolchain.Libraries'
$expectedLibraries = @(
    'BufferOverflowU.lib', 'kernel32.lib', 'advapi32.lib', 'bcrypt.lib', 'shell32.lib'
)
foreach ($architecture in @('amd64', 'arm64')) {
    $architectureLibraries = $libraries[$architecture]
    if ($architectureLibraries -isnot [Collections.IDictionary]) {
        throw "Toolchain.Libraries.$architecture is not structured evidence."
    }
    Assert-ManifestKeySet -Map $architectureLibraries -ExpectedKeys $expectedLibraries `
        -Label "Toolchain.Libraries.$architecture"
    foreach ($libraryName in $expectedLibraries) {
        $library = $architectureLibraries[$libraryName]
        if ($library -isnot [Collections.IDictionary]) {
            throw "Toolchain.Libraries.$architecture.$libraryName is not structured evidence."
        }
        Assert-ManifestFileEvidence -Entry $library -ExpectedFileName $libraryName `
            -Label "Toolchain.Libraries.$architecture.$libraryName"
    }
}

$harness = $hashManifest.Harness
Assert-ManifestKeySet -Map $harness -ExpectedKeys @(
    'Requested', 'BuiltArchitectures', 'HostArchitecture', 'ExecutedArchitectures',
    'Passed', 'TimeoutMilliseconds'
) -Label 'Harness evidence'
if ($harness.Requested -isnot [bool] -or -not $harness.Requested -or
        $harness.Passed -isnot [bool] -or -not $harness.Passed -or
        $harness.BuiltArchitectures -isnot [Array] -or
        $harness.ExecutedArchitectures -isnot [Array] -or
        $harness.HostArchitecture -isnot [string] -or
        [string]$harness.HostArchitecture -cnotmatch '^(amd64|arm64)$') {
    throw 'The elevation-bootstrap hash manifest has invalid harness evidence.'
}
$builtArchitectures = @($harness.BuiltArchitectures | ForEach-Object { [string]$_ })
$executedArchitectures = @($harness.ExecutedArchitectures | ForEach-Object { [string]$_ })
if ($builtArchitectures.Count -ne 2 -or
        $builtArchitectures[0] -cne 'amd64' -or $builtArchitectures[1] -cne 'arm64' -or
        $executedArchitectures.Count -ne 1 -or
        $executedArchitectures[0] -cne [string]$harness.HostArchitecture) {
    throw 'The elevation-bootstrap hash manifest has noncanonical harness coverage.'
}
$harnessTimeout = ConvertTo-ManifestUInt64 -Value $harness.TimeoutMilliseconds `
    -Label 'Harness.TimeoutMilliseconds'
if ($harnessTimeout -ne 30000) {
    throw 'Harness.TimeoutMilliseconds is not the canonical timeout.'
}

$expectedInputs = [ordered]@{
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.cpp' =
        (Join-Path $repoRoot 'tools\native\Atlas.ElevationBootstrap\Atlas.ElevationBootstrap.cpp')
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.rc' =
        (Join-Path $repoRoot 'tools\native\Atlas.ElevationBootstrap\Atlas.ElevationBootstrap.rc')
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.manifest' =
        (Join-Path $repoRoot 'tools\native\Atlas.ElevationBootstrap\Atlas.ElevationBootstrap.manifest')
    'tools/native/Atlas.ElevationBootstrap/resource.h' =
        (Join-Path $repoRoot 'tools\native\Atlas.ElevationBootstrap\resource.h')
    'tools/build/Build-AtlasElevationBootstrap.ps1' =
        (Join-Path $repoRoot 'tools\build\Build-AtlasElevationBootstrap.ps1')
    'tools/build/Test-AtlasElevationBootstrap.ps1' =
        (Join-Path $repoRoot 'tools\build\Test-AtlasElevationBootstrap.ps1')
}
Assert-ManifestKeySet -Map $hashManifest.Inputs -ExpectedKeys @($expectedInputs.Keys) `
    -Label 'Input evidence'
$sourceEvidence = @{}
foreach ($relativePath in $expectedInputs.Keys) {
    $path = $expectedInputs[$relativePath]
    $entry = $hashManifest.Inputs[$relativePath]
    if ($entry -isnot [Collections.IDictionary]) {
        throw "The input evidence for '$relativePath' is not structured."
    }
    Assert-ManifestHashEvidence -Entry $entry -Label "Inputs.$relativePath"
    $evidence = Get-LeasedFileEvidence -Path $path -Label "Input '$relativePath'"
    $sourceLeases.Add($evidence.Stream)
    $sourceEvidence[$relativePath] = $evidence
    if ([long]$entry.Length -ne $evidence.Length -or
            [string]$entry.SHA256 -cne $evidence.SHA256) {
        throw "The hash-manifest input evidence for '$relativePath' does not match the source tree."
    }
}

$expected = [ordered]@{
    'AtlasElevationBootstrap-amd64.exe' = [uint16]0x8664
    'AtlasElevationBootstrap-arm64.exe' = [uint16]0xaa64
}
$expectedManifestSha256 = $sourceEvidence[
    'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.manifest'].SHA256
Assert-ManifestKeySet -Map $hashManifest.Artifacts -ExpectedKeys @($expected.Keys) `
    -Label 'Artifact evidence'
$results = @()
foreach ($name in $expected.Keys) {
    Assert-AtlasVerifierPathIdentity -Path $payloadRoot `
        -Label 'The native payload directory' -ExpectedIdentity $payloadIdentity | Out-Null
    $path = Join-Path $payloadRoot $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required native bootstrap payload is missing: '$path'."
    }
    $result = Read-PeContract -Path $path -ExpectedMachine $expected[$name] `
        -LeaseCollector $artifactLeases
    if ($result.ManifestSHA256 -cne $expectedManifestSha256) {
        throw "'$path' does not embed the reviewed source manifest bytes."
    }
    $entry = $hashManifest.Artifacts[$name]
    if ($entry -isnot [Collections.IDictionary]) {
        throw "The artifact evidence for '$name' is not structured."
    }
    Assert-ManifestKeySet -Map $entry `
        -ExpectedKeys @('Architecture', 'Machine', 'Length', 'SHA256') `
        -Label "Artifacts.$name"
    ConvertTo-ManifestUInt64 -Value $entry.Length -Label "Artifacts.$name.Length" |
        Out-Null
    ConvertTo-ManifestUInt64 -Value $entry.Machine -Label "Artifacts.$name.Machine" |
        Out-Null
    Assert-ManifestSha256 -Value $entry.SHA256 -Label "Artifacts.$name.SHA256"
    if ([long]$entry.Length -ne $result.Length -or
            [string]$entry.SHA256 -cne $result.SHA256 -or
            [uint16]$entry.Machine -ne $result.Machine -or
            [string]$entry.Architecture -cne ($name -replace
                '^AtlasElevationBootstrap-(amd64|arm64)\.exe$', '$1')) {
        throw "The hash-manifest evidence for '$name' does not match the payload."
    }
    $results += $result
}

Assert-AtlasVerifierPathIdentity -Path $payloadRoot -Label 'The native payload directory' `
    -ExpectedIdentity $payloadIdentity | Out-Null
$results
}
finally {
    for ($leaseIndex = $artifactLeases.Count - 1; $leaseIndex -ge 0; $leaseIndex--) {
        $artifactLeases[$leaseIndex].Dispose()
    }
    for ($leaseIndex = $sourceLeases.Count - 1; $leaseIndex -ge 0; $leaseIndex--) {
        $sourceLeases[$leaseIndex].Dispose()
    }
    $manifestLease.Dispose()
}
