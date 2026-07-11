$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:BuildPath = Join-Path $script:RepoRoot `
        'tools\build\Build-AtlasElevationBootstrap.ps1'
    $script:VerifierPath = Join-Path $script:RepoRoot `
        'tools\build\Test-AtlasElevationBootstrap.ps1'
    $script:BuildOutput = Join-Path $TestDrive 'verified-build'
    New-Item -Path $script:BuildOutput -ItemType Directory -Force | Out-Null
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        & $script:BuildPath -Architecture all -OutputDirectory $script:BuildOutput `
            -RunContractHarness | Out-Null
    } else {
        $pwsh = (Get-Command pwsh.exe -CommandType Application -ErrorAction Stop).Source
        & $pwsh -NoLogo -NoProfile -NonInteractive -File $script:BuildPath `
            -Architecture all -OutputDirectory $script:BuildOutput `
            -RunContractHarness | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "The PowerShell 7 verifier-fixture build exited with code $LASTEXITCODE."
        }
    }

    function Read-TestUInt16 {
        param([byte[]]$Bytes, [int]$Offset)
        return [BitConverter]::ToUInt16($Bytes, $Offset)
    }

    function Read-TestUInt32 {
        param([byte[]]$Bytes, [int]$Offset)
        return [BitConverter]::ToUInt32($Bytes, $Offset)
    }

    function Read-TestUInt64 {
        param([byte[]]$Bytes, [int]$Offset)
        return [BitConverter]::ToUInt64($Bytes, $Offset)
    }

    function Write-TestUInt16 {
        param([byte[]]$Bytes, [int]$Offset, [uint16]$Value)
        [BitConverter]::GetBytes($Value).CopyTo($Bytes, $Offset)
    }

    function Write-TestUInt32 {
        param([byte[]]$Bytes, [int]$Offset, [uint32]$Value)
        [BitConverter]::GetBytes($Value).CopyTo($Bytes, $Offset)
    }

    function Write-TestUInt64 {
        param([byte[]]$Bytes, [int]$Offset, [uint64]$Value)
        [BitConverter]::GetBytes($Value).CopyTo($Bytes, $Offset)
    }

    function Update-TestPeChecksum {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Mutates only an isolated in-memory PE fixture.')]
        param(
            [Parameter(Mandatory = $true)][byte[]]$Bytes,
            [Parameter(Mandatory = $true)][object]$Layout
        )

        $checksumOffset = $Layout.Optional + 64
        Write-TestUInt32 $Bytes $checksumOffset 0
        [uint64]$sum = 0
        for ($offset = 0; $offset -lt $Bytes.Length; $offset += 2) {
            if ($offset -eq $checksumOffset -or $offset -eq ($checksumOffset + 2)) {
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
        Write-TestUInt32 $Bytes $checksumOffset `
            ([uint32](($sum -band 0xffff) + $Bytes.Length))
    }

    function Update-TestAsciiSequence {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Mutates only an isolated in-memory PE fixture.')]
        param(
            [Parameter(Mandatory = $true)][byte[]]$Bytes,
            [Parameter(Mandatory = $true)][string]$Search,
            [Parameter(Mandatory = $true)][string]$Replacement
        )

        $searchBytes = [Text.Encoding]::ASCII.GetBytes($Search)
        $replacementBytes = [Text.Encoding]::ASCII.GetBytes($Replacement)
        if ($searchBytes.Length -ne $replacementBytes.Length) {
            throw 'The test ASCII replacement must preserve the PE length.'
        }
        $replacementCount = 0
        for ($index = 0; $index -le $Bytes.Length - $searchBytes.Length; $index++) {
            $isMatch = $true
            for ($offset = 0; $offset -lt $searchBytes.Length; $offset++) {
                if ($Bytes[$index + $offset] -ne $searchBytes[$offset]) {
                    $isMatch = $false
                    break
                }
            }
            if ($isMatch) {
                $replacementBytes.CopyTo($Bytes, $index)
                $replacementCount++
                $index += $searchBytes.Length - 1
            }
        }
        return $replacementCount
    }

    function Convert-TestRvaToOffset {
        param([uint32]$Rva, [object[]]$Sections, [uint32]$SizeOfHeaders)

        if ($Rva -lt $SizeOfHeaders) {
            return [int]$Rva
        }
        foreach ($section in $Sections) {
            if ([uint64]$Rva -ge [uint64]$section.VirtualAddress -and
                    [uint64]$Rva -lt
                    ([uint64]$section.VirtualAddress + [uint64]$section.RawSize)) {
                return [int]([uint64]$section.RawOffset +
                    ([uint64]$Rva - [uint64]$section.VirtualAddress))
            }
        }
        throw ('Test fixture RVA 0x{0:X8} is not raw-backed.' -f $Rva)
    }

    function Find-TestResourceEntry {
        param(
            [byte[]]$Bytes,
            [int]$ResourceRoot,
            [uint32]$DirectoryRelative,
            [uint32]$Id
        )

        $directory = $ResourceRoot + [int]$DirectoryRelative
        $named = Read-TestUInt16 $Bytes ($directory + 12)
        $ids = Read-TestUInt16 $Bytes ($directory + 14)
        for ($index = $named; $index -lt ($named + $ids); $index++) {
            $entry = $directory + 16 + ($index * 8)
            if ((Read-TestUInt32 $Bytes $entry) -eq $Id) {
                return [pscustomobject]@{
                    Offset = $entry
                    Target = (Read-TestUInt32 $Bytes ($entry + 4))
                }
            }
        }
        throw "Test resource ID $Id was not found."
    }

    function Get-TestPeLayout {
        param([byte[]]$Bytes)

        $pe = [int](Read-TestUInt32 $Bytes 0x3c)
        $optional = $pe + 24
        $directory = $optional + 112
        $sectionCount = Read-TestUInt16 $Bytes ($pe + 6)
        $optionalSize = Read-TestUInt16 $Bytes ($pe + 20)
        $sizeOfHeaders = Read-TestUInt32 $Bytes ($optional + 60)
        $sizeOfImage = Read-TestUInt32 $Bytes ($optional + 56)
        $imageBase = Read-TestUInt64 $Bytes ($optional + 24)
        $sections = @()
        for ($index = 0; $index -lt $sectionCount; $index++) {
            $header = $optional + $optionalSize + ($index * 40)
            $sections += [pscustomobject]@{
                Header         = $header
                VirtualSize    = Read-TestUInt32 $Bytes ($header + 8)
                VirtualAddress = Read-TestUInt32 $Bytes ($header + 12)
                RawSize        = Read-TestUInt32 $Bytes ($header + 16)
                RawOffset      = Read-TestUInt32 $Bytes ($header + 20)
                Characteristics = Read-TestUInt32 $Bytes ($header + 36)
            }
        }
        $resourceRva = Read-TestUInt32 $Bytes ($directory + 16)
        $resourceSize = Read-TestUInt32 $Bytes ($directory + 20)
        $resourceRoot = Convert-TestRvaToOffset $resourceRva $sections $sizeOfHeaders
        $manifestType = Find-TestResourceEntry $Bytes $resourceRoot 0 24
        $manifestName = Find-TestResourceEntry $Bytes $resourceRoot `
            ($manifestType.Target -band 0x7fffffff) 1
        $languageDirectory = $resourceRoot +
            [int]($manifestName.Target -band 0x7fffffff)
        $manifestDataRelative = (Read-TestUInt32 $Bytes ($languageDirectory + 20)) `
            -band 0x7fffffff
        $manifestDataEntry = $resourceRoot + [int]$manifestDataRelative
        $relocationRva = Read-TestUInt32 $Bytes ($directory + 40)
        $relocationSize = Read-TestUInt32 $Bytes ($directory + 44)
        $relocationOffset = Convert-TestRvaToOffset $relocationRva `
            $sections $sizeOfHeaders
        $exceptionRva = Read-TestUInt32 $Bytes ($directory + 24)
        $exceptionSize = Read-TestUInt32 $Bytes ($directory + 28)
        $exceptionOffset = Convert-TestRvaToOffset $exceptionRva `
            $sections $sizeOfHeaders
        $loadConfigRva = Read-TestUInt32 $Bytes ($directory + 80)
        $loadConfigOffset = Convert-TestRvaToOffset $loadConfigRva $sections $sizeOfHeaders
        $guardCheckVa = Read-TestUInt64 $Bytes ($loadConfigOffset + 0x70)
        $guardCheckRva = [uint32]($guardCheckVa - $imageBase)
        $guardDispatchVa = Read-TestUInt64 $Bytes ($loadConfigOffset + 0x78)
        $guardDispatchRva = [uint32]($guardDispatchVa - $imageBase)
        $guardTableVa = Read-TestUInt64 $Bytes ($loadConfigOffset + 0x80)
        $guardCount = Read-TestUInt64 $Bytes ($loadConfigOffset + 0x88)
        $guardFlags = Read-TestUInt32 $Bytes ($loadConfigOffset + 0x90)
        $guardEntrySize = 4 + (($guardFlags -shr 28) -band 0x0f)
        $guardTableRva = [uint32]($guardTableVa - $imageBase)
        $cookieVa = Read-TestUInt64 $Bytes ($loadConfigOffset + 0x58)
        $cookieRva = [uint32]($cookieVa - $imageBase)
        $castGuardVa = Read-TestUInt64 $Bytes ($loadConfigOffset + 0x130)
        $castGuardRva = [uint32]($castGuardVa - $imageBase)
        $debugRva = Read-TestUInt32 $Bytes ($directory + 48)
        $debugSize = Read-TestUInt32 $Bytes ($directory + 52)
        $debugOffset = Convert-TestRvaToOffset $debugRva $sections $sizeOfHeaders
        $reproDebugEntry = $null
        $cetDebugEntry = $null
        for ($debugIndex = 0; $debugIndex -lt ($debugSize / 28); $debugIndex++) {
            $debugEntry = $debugOffset + ($debugIndex * 28)
            $debugType = Read-TestUInt32 $Bytes ($debugEntry + 12)
            if ($debugType -eq 16) { $reproDebugEntry = $debugEntry }
            if ($debugType -eq 20) { $cetDebugEntry = $debugEntry }
        }
        return [pscustomobject]@{
            Pe                    = $pe
            Optional              = $optional
            Directory             = $directory
            SizeOfHeaders         = $sizeOfHeaders
            SizeOfImage           = $sizeOfImage
            ImageBase             = $imageBase
            Sections              = @($sections)
            ResourceRva           = $resourceRva
            ResourceSize          = $resourceSize
            ResourceRoot          = $resourceRoot
            ManifestTypeEntry     = $manifestType.Offset
            ManifestNameEntry     = $manifestName.Offset
            ManifestLanguageEntry = $languageDirectory + 16
            ManifestDataEntry     = $manifestDataEntry
            RelocationOffset      = $relocationOffset
            RelocationSize        = $relocationSize
            ExceptionRva          = $exceptionRva
            ExceptionSize         = $exceptionSize
            ExceptionOffset       = $exceptionOffset
            LoadConfigRva         = $loadConfigRva
            LoadConfigOffset      = $loadConfigOffset
            XfgCheckFieldOffset   = $loadConfigOffset + 0x118
            CastGuardFieldOffset  = $loadConfigOffset + 0x130
            CastGuardPointerOffset = Convert-TestRvaToOffset $castGuardRva `
                $sections $sizeOfHeaders
            GuardCheckPointerOffset = Convert-TestRvaToOffset $guardCheckRva `
                $sections $sizeOfHeaders
            GuardDispatchPointerOffset = Convert-TestRvaToOffset $guardDispatchRva `
                $sections $sizeOfHeaders
            GuardTableOffset      = Convert-TestRvaToOffset $guardTableRva `
                $sections $sizeOfHeaders
            GuardCount            = $guardCount
            GuardEntrySize        = $guardEntrySize
            CookieOffset          = Convert-TestRvaToOffset $cookieRva `
                $sections $sizeOfHeaders
            ImportOffset          = Convert-TestRvaToOffset `
                (Read-TestUInt32 $Bytes ($directory + 8)) $sections $sizeOfHeaders
            ImportSize            = Read-TestUInt32 $Bytes ($directory + 12)
            IatOffset             = Convert-TestRvaToOffset `
                (Read-TestUInt32 $Bytes ($directory + 96)) $sections $sizeOfHeaders
            DebugOffset           = $debugOffset
            DebugSize             = $debugSize
            ReproDebugEntry       = $reproDebugEntry
            CetDebugEntry         = $cetDebugEntry
        }
    }

    function New-TestVerifierCase {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Creates files only below Pester TestDrive.')]
        param()

        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -Path $caseRoot -ItemType Directory -Force | Out-Null
        foreach ($item in Get-ChildItem -LiteralPath $script:BuildOutput -File) {
            Copy-Item -LiteralPath $item.FullName -Destination $caseRoot
        }
        return $caseRoot
    }

    function New-TestPeMutation {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Mutates only an isolated Pester TestDrive fixture.')]
        param(
            [Parameter(Mandatory = $true)][scriptblock]$Mutation,
            [object[]]$ArgumentList = @(),
            [switch]$UpdateArtifactEvidence,
            [switch]$LeaveInvalidChecksum,
            [ValidateSet('amd64', 'arm64')][string]$Architecture = 'amd64'
        )

        $caseRoot = New-TestVerifierCase
        $artifactName = "AtlasElevationBootstrap-$Architecture.exe"
        $path = Join-Path $caseRoot $artifactName
        $bytes = [IO.File]::ReadAllBytes($path)
        $layout = Get-TestPeLayout $bytes
        & $Mutation $bytes $layout @ArgumentList
        if (-not $LeaveInvalidChecksum) {
            Update-TestPeChecksum -Bytes $bytes -Layout $layout
        }
        [IO.File]::WriteAllBytes($path, $bytes)
        if ($UpdateArtifactEvidence) {
            $manifestPath = Join-Path $caseRoot `
                'Atlas-ElevationBootstrapHashes.psd1'
            $manifestText = [IO.File]::ReadAllText($manifestPath)
            $pattern = '(?s)' + [regex]::Escape("'$artifactName'") +
                "\s*=\s*@\{.*?SHA256\s*=\s*'(?<Hash>[0-9A-F]{64})'"
            $match = [regex]::Match($manifestText, $pattern)
            if (-not $match.Success) {
                throw "The $Architecture artifact hash evidence was not found in the fixture."
            }
            $updatedHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            $hashGroup = $match.Groups['Hash']
            $manifestText = $manifestText.Substring(0, $hashGroup.Index) +
                $updatedHash +
                $manifestText.Substring($hashGroup.Index + $hashGroup.Length)
            [IO.File]::WriteAllText(
                $manifestPath, $manifestText, (New-Object Text.UTF8Encoding($false)))
        }
        return $caseRoot
    }

    function New-TestManifestMutation {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Mutates only an isolated Pester TestDrive fixture.')]
        param([Parameter(Mandatory = $true)][scriptblock]$Mutation)

        $caseRoot = New-TestVerifierCase
        $path = Join-Path $caseRoot 'Atlas-ElevationBootstrapHashes.psd1'
        $text = [IO.File]::ReadAllText($path)
        $updated = & $Mutation $text
        if ($updated -ceq $text) {
            throw 'The manifest test mutation did not change the fixture.'
        }
        [IO.File]::WriteAllText($path, $updated, (New-Object Text.UTF8Encoding($false)))
        return $caseRoot
    }

    function Invoke-TestVerifier {
        param(
            [Parameter(Mandatory = $true)][string]$CaseRoot,
            [string]$ManifestPath = (Join-Path $CaseRoot `
                'Atlas-ElevationBootstrapHashes.psd1')
        )

        & $script:VerifierPath -PayloadDirectory $CaseRoot `
            -HashManifestPath $ManifestPath | Out-Null
    }
}

Describe 'Atlas elevation bootstrap verifier positive contract' {
    It 'accepts a fresh temporary all-architecture build and schema-3 provenance' {
        { Invoke-TestVerifier $script:BuildOutput } | Should -Not -Throw
    }

    It 'returns two reusable PE result objects rather than formatting records' {
        $results = @(& $script:VerifierPath -PayloadDirectory $script:BuildOutput `
            -HashManifestPath (Join-Path $script:BuildOutput `
                'Atlas-ElevationBootstrapHashes.psd1'))

        $results.Count | Should -Be 2
        @($results.Machine) | Should -Be @([uint16]0x8664, [uint16]0xaa64)
        foreach ($result in $results) {
            $result.GetType().FullName | Should -BeExactly `
                'System.Management.Automation.PSCustomObject'
            $result.Path | Should -Match 'AtlasElevationBootstrap-(amd64|arm64)\.exe$'
            $result.SHA256 | Should -Match '^[0-9A-F]{64}$'
            $result.HasRelocations | Should -BeTrue
        }
    }
}

Describe 'Atlas elevation bootstrap verifier structured provenance' {
    It 'rejects a noncanonical runtime claim' {
        $caseRoot = New-TestManifestMutation {
            param($text)
            return $text -replace "Runtime\s*=\s*'none'", "Runtime = 'msvcrt'"
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*Build evidence*'
    }

    It 'rejects an absolute tool path in place of portable identity evidence' {
        $caseRoot = New-TestManifestMutation {
            param($text)
            return $text -replace "FileName\s*=\s*'clang-cl\.exe'",
                "FileName = 'C:\\toolchain\\clang-cl.exe'"
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*FileName*'
    }

    It 'rejects a noncanonical harness timeout' {
        $caseRoot = New-TestManifestMutation {
            param($text)
            return $text -replace 'TimeoutMilliseconds\s*=\s*30000',
                'TimeoutMilliseconds = 30001'
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*canonical timeout*'
    }

    It 'rejects noncanonical consumed include-directory evidence' {
        $caseRoot = New-TestManifestMutation {
            param($text)
            return $text -replace
                "RelativePath\s*=\s*'VC/Tools/MSVC/14\.51\.36231/include'",
                "RelativePath = 'VC/Tools/MSVC/14.51.36231/headers'"
        }
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*Toolchain.IncludeDirectories.Msvc*'
    }

    It 'rejects a noncanonical resource-compiler dependency set' {
        $caseRoot = New-TestManifestMutation {
            param($text)
            return $text -replace "'RCDLL\.dll'\s*=", "'RCDLX.dll' ="
        }
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*Toolchain.ResourceCompilerDependencies*'
    }

    It 'rejects lowercase digests even when they contain 64 hex characters' {
        $caseRoot = New-TestManifestMutation {
            param($text)
            $match = [regex]::Match($text, "SHA256\s*=\s*'(?<Hash>[0-9A-F]{64})'")
            if (-not $match.Success) { return $text }
            return $text.Substring(0, $match.Groups['Hash'].Index) +
                $match.Groups['Hash'].Value.ToLowerInvariant() +
                $text.Substring($match.Groups['Hash'].Index + 64)
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*uppercase SHA-256*'
    }
}

Describe 'Atlas elevation bootstrap verifier PE parser boundary' {
    It 'requires the exact fixed PE32+ optional-header contract' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt16 $bytes ($layout.Optional + 48) 0xffff
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*noncanonical fixed PE32+ optional-header*'
    }

    It 'rejects a missing required DLL-characteristics bit' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $flags = Read-TestUInt16 $bytes ($layout.Optional + 70)
            Write-TestUInt16 $bytes ($layout.Optional + 70) ([uint16]($flags -band 0xffbf))
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*noncanonical ASLR/DEP*'
    }

    It 'rejects an extra FORCE_INTEGRITY DLL-characteristics bit' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $flags = Read-TestUInt16 $bytes ($layout.Optional + 70)
            Write-TestUInt16 $bytes ($layout.Optional + 70) ([uint16]($flags -bor 0x0080))
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*noncanonical ASLR/DEP*'
    }

    It 'requires the stored PE checksum to match the exact artifact bytes' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Optional + 64) 1
        } -UpdateArtifactEvidence -LeaveInvalidChecksum
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*invalid PE checksum*'
    }

    It 'rejects a missing exception directory' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 24) 0
            Write-TestUInt32 $bytes ($layout.Directory + 28) 0
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*exception directory*'
    }

    It 'rejects duplicate runtime-function begin RVAs' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $firstBegin = Read-TestUInt32 $bytes $layout.ExceptionOffset
            Write-TestUInt32 $bytes ($layout.ExceptionOffset + 12) $firstBegin
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*duplicate, unordered, or overlapping runtime functions*'
    }

    It 'rejects an oversized AMD64 unwind-code array' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $unwindRva = Read-TestUInt32 $bytes ($layout.ExceptionOffset + 8)
            $unwindOffset = Convert-TestRvaToOffset $unwindRva `
                $layout.Sections $layout.SizeOfHeaders
            $bytes[$unwindOffset + 2] = 0xff
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*invalid AMD64 unwind*'
    }

    It 'rejects a zero-length unpacked ARM64 runtime function' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $unwindRva = Read-TestUInt32 $bytes ($layout.ExceptionOffset + 4)
            if (($unwindRva -band 3) -ne 0) {
                throw 'The ARM64 fixture first runtime function is not unpacked.'
            }
            $unwindOffset = Convert-TestRvaToOffset $unwindRva `
                $layout.Sections $layout.SizeOfHeaders
            $header = Read-TestUInt32 $bytes $unwindOffset
            Write-TestUInt32 $bytes $unwindOffset ([uint32]($header -band 0xfffc0000))
        } -Architecture arm64 -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*invalid ARM64 unwind*'
    }

    It 'rejects a high-word alias of numeric RT_MANIFEST type 24' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes $layout.ManifestTypeEntry 0x00010018
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*RT_MANIFEST*'
    }

    It 'rejects a high-word alias of numeric manifest name ID 1' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes $layout.ManifestNameEntry 0x00010001
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*ID 1*'
    }

    It 'requires the exact en-US numeric manifest language ID 0x0409' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes $layout.ManifestLanguageEntry 0x0411
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*en-US manifest language ID*'
    }

    It 'rejects numeric IDs smuggled into the resource named-entry prefix' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt16 $bytes ($layout.ResourceRoot + 12) 1
            Write-TestUInt16 $bytes ($layout.ResourceRoot + 14) 1
        }
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*VERSIONINFO/RT_MANIFEST resource type set*'
    }

    It 'rejects a resource-relative subdirectory outside ResourceSize' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.ManifestTypeEntry + 4) `
                ([uint32](0x80000000 -bor $layout.ResourceSize))
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*declared PE directory*'
    }

    It 'rejects a directory mapped into a virtual-only section tail' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $section = $layout.Sections | Where-Object {
                $_.VirtualSize -gt $_.RawSize
            } | Select-Object -First 1
            Write-TestUInt32 $bytes ($layout.Directory + 8) `
                ([uint32]($section.VirtualAddress + $section.RawSize))
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*not fully raw-backed*'
    }

    It 'rejects overlapping raw section ranges' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Sections[1].Header + 20) `
                $layout.Sections[0].RawOffset
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*raw ranges overlap*'
    }

    It 'rejects overlapping virtual section ranges' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Sections[1].Header + 12) `
                $layout.Sections[0].VirtualAddress
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*RVA ranges overlap*'
    }

    It 'rejects writable executable sections' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $value = [uint32]($layout.Sections[0].Characteristics -bor 0x80000000)
            Write-TestUInt32 $bytes ($layout.Sections[0].Header + 36) $value
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*writable executable*'
    }

    It 'rejects a missing relocation directory' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 40) 0
            Write-TestUInt32 $bytes ($layout.Directory + 44) 0
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*relocation directory*'
    }

    It 'rejects a relocation directory whose size is not DWORD-aligned' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 44) `
                ([uint32]($layout.RelocationSize + 2))
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*bounded relocation directory*'
    }

    It 'rejects a relocation block whose size is not DWORD-aligned' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.RelocationOffset + 4) 14
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*malformed relocation block*'
    }

    It 'rejects duplicate effective relocation targets with matching artifact evidence' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $firstEntry = Read-TestUInt16 $bytes ($layout.RelocationOffset + 8)
            Write-TestUInt16 $bytes ($layout.RelocationOffset + 10) $firstEntry
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*duplicate or unordered relocation targets*'
    }

    It 'rejects a relocation target that crosses its 4KiB page boundary' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt16 $bytes ($layout.RelocationOffset + 8) 0xaffc
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*relocation target*'
    }

    It 'rejects effective relocations after canonical absolute padding begins' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt16 $bytes ($layout.RelocationOffset + 10) 0
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*noncanonical relocation padding*'
    }

    It 'rejects a DIR64 relocation over data that is not an image VA' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $cursor = 0
            $paddingEntryOffset = $null
            $paddingPageRva = $null
            $lastEffectiveOffset = 0
            while ($cursor -lt $layout.RelocationSize) {
                $block = $layout.RelocationOffset + $cursor
                $pageRva = Read-TestUInt32 $bytes $block
                $blockSize = Read-TestUInt32 $bytes ($block + 4)
                for ($entryOffset = 8; $entryOffset -lt $blockSize; $entryOffset += 2) {
                    $rawEntryOffset = $block + $entryOffset
                    $entry = Read-TestUInt16 $bytes $rawEntryOffset
                    if (($entry -shr 12) -eq 10) {
                        $lastEffectiveOffset = $entry -band 0x0fff
                    } elseif (($entry -shr 12) -eq 0) {
                        $paddingEntryOffset = $rawEntryOffset
                        $paddingPageRva = $pageRva
                    }
                }
                $cursor += $blockSize
            }
            if ($null -eq $paddingEntryOffset) {
                throw 'The test fixture lacks canonical relocation padding.'
            }
            $replacementOffset = $null
            for ($candidateOffset = (($lastEffectiveOffset + 15) -band 0xfff8);
                    $candidateOffset -le 0xff8; $candidateOffset += 8) {
                try {
                    $candidateRva = [uint32]($paddingPageRva + $candidateOffset)
                    $candidateRaw = Convert-TestRvaToOffset $candidateRva `
                        $layout.Sections $layout.SizeOfHeaders
                    $candidateValue = Read-TestUInt64 $bytes $candidateRaw
                    if ($candidateValue -lt $layout.ImageBase -or
                            ($candidateValue - $layout.ImageBase) -ge $layout.SizeOfImage) {
                        $replacementOffset = $candidateOffset
                        break
                    }
                }
                catch {
                    continue
                }
            }
            if ($null -eq $replacementOffset) {
                throw 'The test fixture lacks a non-image-VA relocation candidate.'
            }
            Write-TestUInt16 $bytes $paddingEntryOffset `
                ([uint16](0xa000 -bor $replacementOffset))
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*DIR64 relocation over a non-image VA*'
    }

    It 'rejects an otherwise canonical relocation into a zero load-config field' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $cursor = 0
            $changed = $false
            while ($cursor -lt $layout.RelocationSize -and -not $changed) {
                $block = $layout.RelocationOffset + $cursor
                $pageRva = Read-TestUInt32 $bytes $block
                $blockSize = Read-TestUInt32 $bytes ($block + 4)
                for ($entryOffset = 8; $entryOffset -lt $blockSize; $entryOffset += 2) {
                    $rawEntryOffset = $block + $entryOffset
                    $entry = Read-TestUInt16 $bytes $rawEntryOffset
                    $targetRva = [uint32]($pageRva + ($entry -band 0x0fff))
                    if (($entry -shr 12) -eq 10 -and
                            $targetRva -eq ([uint32]($layout.LoadConfigRva - 0x10))) {
                        $replacement = [uint16](0xa000 -bor
                            (($layout.LoadConfigRva + 0x28) - $pageRva))
                        Write-TestUInt16 $bytes $rawEntryOffset $replacement
                        $changed = $true
                        break
                    }
                }
                $cursor += $blockSize
            }
            if (-not $changed) {
                throw 'The test fixture lacks the expected pre-load-config relocation.'
            }
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*DIR64 relocation over a non-image VA*'
    }

    It 'rejects TLS metadata' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 72) $layout.ResourceRva
            Write-TestUInt32 $bytes ($layout.Directory + 76) 8
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*TLS directory*'
    }

    It 'rejects delay-import metadata' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 104) $layout.ResourceRva
            Write-TestUInt32 $bytes ($layout.Directory + 108) 32
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*delay-import*'
    }

    It 'rejects a load-config internal size that disagrees with its directory' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes $layout.LoadConfigOffset 0x94
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*load-config bounds*'
    }

    It 'requires the exact 0x148 load-config directory size' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 84) 0x147
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*bounded CFG/security-cookie load configuration*'
    }

    It 'requires the exact System32 dependent-load policy' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt16 $bytes ($layout.LoadConfigOffset + 0x4e) 0
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*DependentLoadFlags*'
    }

    It 'rejects a zero security-cookie pointer' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt64 $bytes ($layout.LoadConfigOffset + 0x58) 0
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*DIR64 relocation over*'
    }

    It 'rejects a zero in-image security-cookie value' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt64 $bytes $layout.CookieOffset 0
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*nonzero cookie*'
    }

    It 'rejects a security-cookie pointer into read-only image data' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $readOnly = $layout.Sections | Where-Object {
                ($_.Characteristics -band 0x40000000) -ne 0 -and
                ($_.Characteristics -band 0x80000000) -eq 0 -and
                ($_.Characteristics -band 0x20000000) -eq 0
            } | Select-Object -First 1
            Write-TestUInt64 $bytes ($layout.LoadConfigOffset + 0x58) `
                ([uint64]($layout.ImageBase + $readOnly.VirtualAddress))
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*writable non-executable*'
    }

    It 'rejects each missing required GuardCF pointer or count' -TestCases @(
        @{ Name = 'check'; Offset = 0x70 },
        @{ Name = 'dispatch'; Offset = 0x78 },
        @{ Name = 'table'; Offset = 0x80 },
        @{ Name = 'count'; Offset = 0x88 }
    ) {
        param($Name, $Offset)
        $fieldName = $Name
        $fieldOffset = $Offset
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout, $selectedOffset)
            Write-TestUInt64 $bytes ($layout.LoadConfigOffset + $selectedOffset) 0
        } -ArgumentList @($fieldOffset)
        $expectedError = if ($fieldOffset -eq 0x88) {
            '*complete GuardCF*'
        } else {
            '*DIR64 relocation over*'
        }
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw $expectedError -Because "$fieldName is mandatory"
    }

    It 'rejects GuardFlags without instrumentation/table evidence' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.LoadConfigOffset + 0x90) 0
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*complete GuardCF*'
    }

    It 'rejects GuardFlags that claim the security cookie is unused' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $flags = Read-TestUInt32 $bytes ($layout.LoadConfigOffset + 0x90)
            Write-TestUInt32 $bytes ($layout.LoadConfigOffset + 0x90) `
                ([uint32]($flags -bor 0x0800))
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*complete GuardCF*'
    }

    It 'rejects any noncanonical GuardFlags bit even when required bits remain set' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $flags = Read-TestUInt32 $bytes ($layout.LoadConfigOffset + 0x90)
            Write-TestUInt32 $bytes ($layout.LoadConfigOffset + 0x90) `
                ([uint32]($flags -bor 1))
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*complete GuardCF*'
    }

    It 'rejects a GuardCF pointer slot whose target was cleared' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt64 $bytes $layout.GuardCheckPointerOffset 0
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*DIR64 relocation over*'
    }

    It 'rejects a missing amd64 GuardXFG pointer field' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt64 $bytes $layout.XfgCheckFieldOffset 0
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*DIR64 relocation over*'
    }

    It 'rejects aliased amd64 GuardCF and GuardXFG pointer slots' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $guardCheckVa = Read-TestUInt64 $bytes ($layout.LoadConfigOffset + 0x70)
            Write-TestUInt64 $bytes $layout.XfgCheckFieldOffset $guardCheckVa
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*GuardCF pointer slot*'
    }

    It 'rejects nonzero ARM64 GuardXFG pointer state' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $castGuardVa = Read-TestUInt64 $bytes $layout.CastGuardFieldOffset
            Write-TestUInt64 $bytes $layout.XfgCheckFieldOffset $castGuardVa
        } -Architecture arm64 -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*unexpected ARM64 GuardXFG*'
    }

    It 'rejects a missing CastGuard pointer field' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt64 $bytes $layout.CastGuardFieldOffset 0
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*DIR64 relocation over*'
    }

    It 'rejects a nonzero CastGuard failure-mode slot' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt64 $bytes $layout.CastGuardPointerOffset `
                ([uint64]($layout.ImageBase + 0x1000))
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*CastGuard failure-mode*'
    }

    It 'rejects distinct GuardCF handlers that alias the same executable target' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $checkTarget = Read-TestUInt64 $bytes $layout.GuardCheckPointerOffset
            Write-TestUInt64 $bytes $layout.GuardDispatchPointerOffset $checkTarget
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*aliases distinct GuardCF*'
    }

    It 'does not mask malformed low bits from an exact GFIDS RVA' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $first = Read-TestUInt32 $bytes $layout.GuardTableOffset
            Write-TestUInt32 $bytes $layout.GuardTableOffset ([uint32]($first -bor 0x0f))
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*GuardCF function-table entry*'
    }

    It 'requires GFIDS targets to resolve into executable non-writable code' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $lastOffset = $layout.GuardTableOffset +
                ([int]($layout.GuardCount - 1) * $layout.GuardEntrySize)
            $readOnly = $layout.Sections | Where-Object {
                ($_.Characteristics -band 0x20000000) -eq 0
            } | Select-Object -First 1
            Write-TestUInt32 $bytes $lastOffset $readOnly.VirtualAddress
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*executable non-writable*'
    }

    It 'requires both canonical debug-directory records' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.Directory + 52) 28
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*invalid debug directory*'
    }

    It 'rejects a malformed reproducible-build debug record type' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes ($layout.ReproDebugEntry + 12) 20
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*malformed CET debug evidence*'
    }

    It 'rejects a malformed CET extended-characteristics value' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $cetDataOffset = Read-TestUInt32 $bytes ($layout.CetDebugEntry + 24)
            Write-TestUInt32 $bytes $cetDataOffset 0
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*malformed CET debug evidence*'
    }

    It 'rejects divergent import lookup and address thunk sequences' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $first = Read-TestUInt64 $bytes $layout.IatOffset
            $second = Read-TestUInt64 $bytes ($layout.IatOffset + 8)
            Write-TestUInt64 $bytes $layout.IatOffset $second
            Write-TestUInt64 $bytes ($layout.IatOffset + 8) $first
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*thunk sequences differ*'
    }

    It 'rejects an altered import symbol even when artifact SHA evidence is updated' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $null = $layout
            (Update-TestAsciiSequence -Bytes $bytes -Search 'GetLastError' `
                -Replacement 'ZetLastError') | Should -Be 1
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*unexpected KERNEL32.dll import-symbol set*'
    }

    It 'rejects an import FirstThunk outside the declared IAT' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $lookupRva = Read-TestUInt32 $bytes $layout.ImportOffset
            Write-TestUInt32 $bytes ($layout.ImportOffset + 16) $lookupRva
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*outside the IAT*'
    }

    It 'rejects manifest data outside the declared resource area' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            Write-TestUInt32 $bytes $layout.ManifestDataEntry `
                ([uint32]($layout.ResourceRva + $layout.ResourceSize))
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*Manifest resource data*'
    }

    It 'parses active manifest XML rather than accepting a matching comment or string' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $null = $layout
            $needle = [Text.Encoding]::ASCII.GetBytes('requireAdministrator')
            $replacement = [Text.Encoding]::ASCII.GetBytes('asInvoker           ')
            $found = -1
            for ($index = 0; $index -le $bytes.Length - $needle.Length; $index++) {
                $isMatch = $true
                for ($offset = 0; $offset -lt $needle.Length; $offset++) {
                    if ($bytes[$index + $offset] -ne $needle[$offset]) {
                        $isMatch = $false
                        break
                    }
                }
                if ($isMatch) {
                    $found = $index
                    break
                }
            }
            if ($found -lt 0) { throw 'Manifest fixture text was not found.' }
            $replacement.CopyTo($bytes, $found)
        }
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*elevation/long-path manifest*'
    }

    It 'requires the manifest nodes to use the qualified canonical hierarchy' {
        $caseRoot = New-TestPeMutation {
            param($bytes, $layout)
            $null = $layout
            (Update-TestAsciiSequence -Bytes $bytes -Search 'trustInfo' `
                -Replacement 'xrustInfo') | Should -Be 2
        } -UpdateArtifactEvidence
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*elevation/long-path manifest*'
    }

    It 'rejects a file overlay after the final section' {
        $caseRoot = New-TestVerifierCase
        $path = Join-Path $caseRoot 'AtlasElevationBootstrap-amd64.exe'
        $bytes = [IO.File]::ReadAllBytes($path)
        $extended = New-Object byte[] ($bytes.Length + 1)
        $bytes.CopyTo($extended, 0)
        $extended[$bytes.Length] = 0x41
        $layout = Get-TestPeLayout $extended
        Update-TestPeChecksum -Bytes $extended -Layout $layout
        [IO.File]::WriteAllBytes($path, $extended)
        $manifestPath = Join-Path $caseRoot 'Atlas-ElevationBootstrapHashes.psd1'
        $manifestText = [IO.File]::ReadAllText($manifestPath)
        $artifactName = 'AtlasElevationBootstrap-amd64.exe'
        $pattern = '(?s)' + [regex]::Escape("'$artifactName'") +
            "\s*=\s*@\{.*?SHA256\s*=\s*'(?<Hash>[0-9A-F]{64})'"
        $match = [regex]::Match($manifestText, $pattern)
        $updatedHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $hashGroup = $match.Groups['Hash']
        $manifestText = $manifestText.Substring(0, $hashGroup.Index) + $updatedHash +
            $manifestText.Substring($hashGroup.Index + $hashGroup.Length)
        [IO.File]::WriteAllText(
            $manifestPath, $manifestText, (New-Object Text.UTF8Encoding($false)))
        { Invoke-TestVerifier $caseRoot } | Should -Throw '*trailing data*'
    }
}

Describe 'Atlas elevation bootstrap verifier publication boundary' {
    It 'requires the hash manifest to be a direct canonical child' {
        $caseRoot = New-TestVerifierCase
        $nestedRoot = Join-Path $caseRoot 'nested'
        New-Item -Path $nestedRoot -ItemType Directory -Force | Out-Null
        $nestedManifest = Join-Path $nestedRoot `
            'Atlas-ElevationBootstrapHashes.psd1'
        Move-Item -LiteralPath (Join-Path $caseRoot `
            'Atlas-ElevationBootstrapHashes.psd1') -Destination $nestedManifest

        { Invoke-TestVerifier $caseRoot -ManifestPath $nestedManifest } |
            Should -Throw '*direct, regular canonical child*'
    }

    It 'rejects exact publication transaction debris' -TestCases @(
        @{ Suffix = 'publish' },
        @{ Suffix = 'backup' }
    ) {
        param($Suffix)
        $caseRoot = New-TestVerifierCase
        $debris = Join-Path $caseRoot `
            ('.AtlasElevationBootstrap-amd64.exe.{0}.{1}' -f ('a' * 32), $Suffix)
        [IO.File]::WriteAllBytes($debris, [byte[]]@(0x41))

        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*incomplete publication transaction*'
    }

    It 'rejects exact publication debris represented by a directory' {
        $caseRoot = New-TestVerifierCase
        $debris = Join-Path $caseRoot `
            ('.AtlasElevationBootstrap-amd64.exe.{0}.publish' -f ('b' * 32))
        New-Item -Path $debris -ItemType Directory | Out-Null

        { Invoke-TestVerifier $caseRoot } |
            Should -Throw '*incomplete publication transaction*'
    }
}
