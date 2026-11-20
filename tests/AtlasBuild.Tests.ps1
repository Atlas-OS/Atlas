BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\tools\build\AtlasBuild\AtlasBuild.psd1') -Force
}

Describe 'Package license distribution' {
    It 'includes the complete project license in the installed modules' {
        $repo = Split-Path $PSScriptRoot -Parent
        $projectLicense = Join-Path $repo 'LICENSE'
        $payloadLicense = Join-Path $repo 'playbook\Executables\AtlasModules\LICENSE'
        [IO.File]::ReadAllText($payloadLicense) | Should -BeExactly ([IO.File]::ReadAllText($projectLicense))
        @(Get-AtlasPlaybookPayloadPath -PlaybookPath (Join-Path $repo 'playbook')) |
            Should -Contain 'Executables/AtlasModules/LICENSE'
    }
}

Describe 'Get-PlaybookVersion' {
    It 'parses version metadata from a valid playbook.conf' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Version>0.5.1</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        $result = Get-PlaybookVersion -PlaybookConfPath $conf
        $result.Version | Should -Be '0.5.1'
        $result.VersionLabel | Should -Be 'v0.5.1'
    }

    It 'throws on <Case>' -TestCases @(
        @{ Case = 'an invalid version format'; Version = 'not.a.version'; Message = "*Invalid version format 'not.a.version'*" }
        @{ Case = 'a missing file'; Version = $null; Message = '*playbook.conf not found*' }
    ) {
        $conf = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).conf"
        if ($Version) {
            "<Playbook><Version>$Version</Version></Playbook>" |
                Set-Content -Path $conf -Encoding UTF8
        }

        { Get-PlaybookVersion -PlaybookConfPath $conf } | Should -Throw $Message
    }
}

Describe 'New-StagedPlaybookConf' {
    BeforeAll {
        # The document without the given nodes. Indentation and line endings are ignored;
        # comments are not.
        function Get-PlaybookConfXml {
            param(
                [Parameter(Mandatory = $true)][string]$Path,
                [string[]]$RemoveXPath = @()
            )
            $document = [Xml.XmlDocument]::new()
            $reader = [Xml.XmlReader]::Create($Path)
            try { $document.Load($reader) } finally { $reader.Dispose() }
            foreach ($xpath in $RemoveXPath) {
                $nodes = @($document.SelectNodes($xpath))
                $nodes.Count | Should -BeGreaterThan 0 -Because "the source must have $xpath to remove"
                foreach ($node in $nodes) { [void]$node.ParentNode.RemoveChild($node) }
            }
            $document.OuterXml
        }
    }

    BeforeEach {
        # Shaped like the committed file: comments in SupportedBuilds, and upgrade sources that
        # are <string> lines too.
        $script:sourceConf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Version>0.5.1</Version>
    <SupportedBuilds>
        <!-- 25H2 -->
        <string>26200</string>
        <!-- 26H2 -->
        <string>26300</string>
    </SupportedBuilds>
    <UpgradableFrom>
        <string>0.4.1</string>
        <string>0.5.0</string>
    </UpgradableFrom>
    <Requirements>
        <Requirement>NoAntivirus</Requirement>
        <Requirement>PluggedIn</Requirement>
    </Requirements>
    <EstimatedMinutes>15</EstimatedMinutes>
</Playbook>
'@ | Set-Content -Path $script:sourceConf -Encoding UTF8
        $script:stagedConf = Join-Path $TestDrive 'staged\playbook.conf'
    }

    It 'returns false when no removals are requested' {
        $result = New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf
        $result | Should -BeFalse
        Test-Path $stagedConf | Should -BeFalse
    }

    It '-<Switch> removes only <Removed>' -ForEach @(
        @{ Switch = 'RemoveRequirements'; Removed = '/Playbook/Requirements/Requirement' }
        @{ Switch = 'RemoveWinverRequirement'; Removed = '/Playbook/SupportedBuilds' }
    ) {
        $removal = @{ $Switch = $true }
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf @removal | Should -BeTrue

        Get-PlaybookConfXml -Path $stagedConf |
            Should -BeExactly (Get-PlaybookConfXml -Path $sourceConf -RemoveXPath $Removed)
    }

    It 'leaves the rest of the committed playbook.conf, upgrade sources included, as it is' {
        $committedConf = Join-Path $PSScriptRoot '..\playbook\playbook.conf'
        New-StagedPlaybookConf -PlaybookConfPath $committedConf -DestinationPath $stagedConf `
            -RemoveRequirements -RemoveWinverRequirement | Should -BeTrue

        Get-PlaybookConfXml -Path $stagedConf | Should -BeExactly (Get-PlaybookConfXml -Path $committedConf `
                -RemoveXPath '/Playbook/Requirements/Requirement', '/Playbook/SupportedBuilds')
    }
}

Describe 'Set-OemVersionStamp' {
    It 'replaces the placeholder with the version label' {
        $script = Join-Path $TestDrive 'Set-OemInformation.ps1'
        '$version = "AtlasVersionUndefined"' | Set-Content -Path $script -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-oem.ps1'

        Set-OemVersionStamp -ScriptPath $script -VersionLabel 'v0.5.1' -DestinationPath $staged | Should -BeTrue
        (Get-Content $staged -Raw) | Should -Match ([regex]::Escape('$version = "v0.5.1"'))
    }

    It 'returns false when the placeholder is missing' {
        $script = Join-Path $TestDrive 'no-placeholder.ps1'
        '$version = "v9.9.9"' | Set-Content -Path $script -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-none.ps1'

        Set-OemVersionStamp -ScriptPath $script -VersionLabel 'v0.5.1' -DestinationPath $staged -WarningAction SilentlyContinue | Should -BeFalse
    }
}

Describe 'Get-AvailableArchiveName' {
    It 'keeps the base name until it exists, then appends a counter when replacement is not allowed' {
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas.apbx'

        New-Item -Path (Join-Path $TestDrive 'Atlas.apbx') -ItemType File | Out-Null
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas (1).apbx'
    }

    It 'selects the existing name without deleting it when replacement is allowed' {
        New-Item -Path (Join-Path $TestDrive 'Atlas.apbx') -ItemType File -Force | Out-Null
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' -AllowReplace |
            Should -Be 'Atlas.apbx'
        Test-Path (Join-Path $TestDrive 'Atlas.apbx') | Should -BeTrue
    }
}

Describe 'Atomic APBX publication' {
    BeforeEach {
        $playbook = Join-Path $TestDrive 'playbook'
        $output = Join-Path $TestDrive 'output'
        New-Item -ItemType Directory -Path $playbook, $output -Force | Out-Null
        '<Playbook><Version>0.6.0</Version></Playbook>' |
            Set-Content -LiteralPath (Join-Path $playbook 'playbook.conf') -Encoding UTF8
        Mock Resolve-SevenZip { 'mock-7z.exe' } -ModuleName AtlasBuild
        Mock Invoke-AtlasApbxVerifier { } -ModuleName AtlasBuild
    }

    It 'preserves the previous APBX when integrity verification of the sibling build fails' {
        $existingArchive = Join-Path $output 'Atlas.apbx'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList
            if ($ErrorContext -eq 'Creating APBX archive') {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
                return
            }
            if ($ErrorContext -eq 'Verifying built APBX archive') {
                throw 'simulated integrity failure'
            }
        } -ModuleName AtlasBuild

        {
            New-Apbx -PlaybookPath $playbook -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceOldPlaybook
        } | Should -Throw -ExpectedMessage '*simulated integrity failure*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'preserves the previous APBX when semantic verification of the sibling build fails' {
        $existingArchive = Join-Path $output 'Atlas.apbx'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
        Mock Invoke-AtlasApbxVerifier {
            throw 'simulated semantic verification failure'
        } -ModuleName AtlasBuild

        {
            New-Apbx -PlaybookPath $playbook -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceOldPlaybook
        } | Should -Throw -ExpectedMessage '*simulated semantic verification failure*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Should -Invoke Invoke-AtlasApbxVerifier -ModuleName AtlasBuild -Times 1 -Exactly
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'denies an attempted sibling change while semantic verification holds its file identity' {
        $existingArchive = Join-Path $output 'Atlas.apbx'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
        Mock Invoke-AtlasApbxVerifier {
            param($Path, $PlaybookPath, [switch]$NoPassword)
            $null = $PlaybookPath, $NoPassword
            $mutationBlocked = $false
            try {
                [IO.File]::WriteAllBytes($Path, [byte[]](5, 5, 5, 5))
            }
            catch {
                $writeException = $_.Exception
                while ($null -ne $writeException.InnerException) {
                    $writeException = $writeException.InnerException
                }
                if ($writeException -is [IO.IOException] -or
                    $writeException -is [UnauthorizedAccessException]) {
                    $mutationBlocked = $true
                }
                else {
                    throw
                }
            }
            if (-not $mutationBlocked) {
                throw 'The semantic archive lock allowed a write.'
            }
            throw 'simulated sibling mutation was blocked by semantic lock'
        } -ModuleName AtlasBuild

        {
            New-Apbx -PlaybookPath $playbook -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceOldPlaybook
        } | Should -Throw -ExpectedMessage '*mutation was blocked by semantic lock*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'preserves the previous APBX when handle hashes diverge across semantic verification' {
        $existingArchive = Join-Path $output 'Atlas.apbx'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
        Mock Get-AtlasStreamSha256 {
            $script:AtlasSemanticHashInvocation++
            if ($script:AtlasSemanticHashInvocation -eq 1) {
                return ('A' * 64)
            }
            return ('B' * 64)
        } -ModuleName AtlasBuild
        & (Get-Module AtlasBuild) { $script:AtlasSemanticHashInvocation = 0 }

        {
            New-Apbx -PlaybookPath $playbook -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceOldPlaybook
        } | Should -Throw -ExpectedMessage '*changed during semantic verification*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Should -Invoke Invoke-AtlasApbxVerifier -ModuleName AtlasBuild -Times 1 -Exactly
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'rejects stale publication artifacts before invoking 7-Zip' {
        $stalePaths = @(
            Join-Path $output 'Atlas.apbx.tmp'
            Join-Path $output 'Other.apbx.0123456789abcdef0123456789abcdef.building.tmp'
            Join-Path $output 'Legacy.apbx.0123456789abcdef0123456789abcdef.replaced.bak'
        )
        foreach ($stalePath in $stalePaths) {
            [IO.File]::WriteAllBytes($stalePath, [byte[]](7, 7, 7, 7))
        }
        Mock Invoke-SevenZip {
            throw 'archive execution must remain unreachable'
        } -ModuleName AtlasBuild

        {
            New-Apbx -PlaybookPath $playbook -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceOldPlaybook
        } | Should -Throw -ExpectedMessage '*publication artifacts must be removed*'

        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 0 -Exactly
        foreach ($stalePath in $stalePaths) {
            $stalePath | Should -Exist
        }
        Remove-Item -LiteralPath $stalePaths -Force
    }

    It 'atomically publishes the verified sibling over the previous APBX' {
        $existingArchive = Join-Path $output 'Atlas.apbx'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList
            if ($ErrorContext -eq 'Creating APBX archive') {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild

        $result = New-Apbx -PlaybookPath $playbook -OutputDirectory $output `
            -FileName 'Atlas' -NoPassword -ReplaceOldPlaybook -WarningAction SilentlyContinue

        $result | Should -BeExactly $existingArchive
        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](9, 8, 7, 6))
        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 1 -Exactly `
            -ParameterFilter { $ErrorContext -eq 'Verifying built APBX archive' }
        Should -Invoke Invoke-AtlasApbxVerifier -ModuleName AtlasBuild -Times 1 -Exactly `
            -ParameterFilter {
                $Path -like '*.building.tmp' -and
                $PlaybookPath -eq $playbook -and
                $NoPassword
            }
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'returns a successful publication result when invoked from a non-filesystem provider' {
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
        $originalLocation = Get-Location
        try {
            Set-Location Function:\
            $result = New-Apbx -PlaybookPath $playbook -OutputDirectory $output `
                -FileName 'Provider' -NoPassword -WarningAction SilentlyContinue

            $result | Should -BeExactly (Join-Path $output 'Provider.apbx')
            [IO.File]::ReadAllBytes($result) | Should -Be ([byte[]](9, 8, 7, 6))
            (Get-Location).Provider.Name | Should -BeExactly 'Function'
        }
        finally {
            Set-Location -LiteralPath $originalLocation.Path
        }
    }

    It 'refuses to publish a different file object than the verified content' `
        -Skip:(-not $IsWindows) {
        $source = Join-Path $output 'Atlas.apbx.bound.building.tmp'
        $destination = Join-Path $output 'Atlas.apbx'
        [IO.File]::WriteAllBytes($source, [byte[]](9, 8, 7, 6))
        [IO.File]::WriteAllBytes($destination, [byte[]](1, 2, 3, 4))
        $verifiedHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        Move-Item -LiteralPath $source -Destination "$source.verified-object"
        [IO.File]::WriteAllBytes($source, [byte[]](5, 5, 5, 5))

        {
            & (Get-Module AtlasBuild) {
                param($Source, $Destination, $ExpectedSha256)
                Publish-AtlasVerifiedArchive `
                    -SourcePath $Source `
                    -DestinationPath $Destination `
                    -ExpectedSha256 $ExpectedSha256 `
                    -AllowReplace
            } $source $destination $verifiedHash
        } | Should -Throw -ExpectedMessage '*changed after semantic verification*'

        [IO.File]::ReadAllBytes($destination) | Should -Be ([byte[]](1, 2, 3, 4))
        [IO.File]::ReadAllBytes($source) | Should -Be ([byte[]](5, 5, 5, 5))
        [IO.File]::ReadAllBytes("$source.verified-object") |
            Should -Be ([byte[]](9, 8, 7, 6))
    }
}

Describe 'APBX file path contracts' {
    It 'enumerates every source file except generated APBX outputs' {
        $playbook = Join-Path $TestDrive 'playbook'
        New-Item -Path (Join-Path $playbook 'Images') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $playbook 'Executables\Nested') -ItemType Directory -Force | Out-Null
        '<Playbook />' | Set-Content -Path (Join-Path $playbook 'playbook.conf') -Encoding UTF8
        'image' | Set-Content -Path (Join-Path $playbook 'Images\browser.png') -Encoding UTF8
        'payload' | Set-Content -Path (Join-Path $playbook 'Executables\Nested\tool.txt') -Encoding UTF8
        'generated' | Set-Content -Path (Join-Path $playbook 'Atlas Test.apbx') -Encoding UTF8
        'interrupted' | Set-Content -Path (Join-Path $playbook 'Atlas Test.apbx.tmp') -Encoding UTF8
        'building' | Set-Content -Path `
            (Join-Path $playbook 'Atlas Test.apbx.0123456789abcdef0123456789abcdef.building.tmp') `
            -Encoding UTF8
        'backup' | Set-Content -Path `
            (Join-Path $playbook 'Atlas Test.apbx.0123456789abcdef0123456789abcdef.replaced.bak') `
            -Encoding UTF8

        @(Get-AtlasPlaybookPayloadPath -PlaybookPath $playbook) | Should -Be @(
            'Executables/Nested/tool.txt'
            'Images/browser.png'
            'playbook.conf'
        )
    }

    It 'reports missing, unexpected, and duplicate archive paths independently' {
        $result = Compare-AtlasPayloadPath `
            -ExpectedPath @('Images/browser.png', 'Executables/tool.ps1') `
            -ActualPath @('Images\browser.png', 'Executables/stale.ps1', 'Executables/stale.ps1')

        $result.Matches | Should -BeFalse
        $result.Missing | Should -Be @('Executables/tool.ps1')
        $result.Unexpected | Should -Be @('Executables/stale.ps1')
        $result.Duplicates | Should -Be @('Executables/stale.ps1')
    }

    It 'treats path casing as part of the archive contract' {
        $result = Compare-AtlasPayloadPath `
            -ExpectedPath @('Executables/AtlasModules/Tool.ps1') `
            -ActualPath @('Executables/atlasmodules/Tool.ps1')

        $result.Matches | Should -BeFalse
        $result.Missing.Count | Should -Be 1
        $result.Unexpected.Count | Should -Be 1
    }
}

Describe 'APBX verifier extraction gate' {
    # The listed files match the source, so only the directory record can block extraction.
    It 'never invokes 7-Zip extraction after <Case> is listed' -ForEach @(
        @{ Case = 'a parent-traversal directory'; Directories = @('../outside'); Failure = 'rooted or parent-traversal paths: \.\./outside' }
        @{ Case = 'a rooted directory'; Directories = @('C:/outside'); Failure = 'rooted or parent-traversal paths: C:/outside' }
        @{ Case = 'a duplicate directory'; Directories = @('Images', 'Images'); Failure = 'duplicate entry paths: Images' }
    ) -Skip:(-not $IsWindows) {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $fakeBin = Join-Path $TestDrive 'fake-bin'
        $playbook = Join-Path $TestDrive 'playbook'
        New-Item -ItemType Directory -Path $fakeBin, $playbook -Force | Out-Null
        '<Playbook />' | Set-Content -LiteralPath (Join-Path $playbook 'playbook.conf') `
            -Encoding UTF8
        $archive = Join-Path $TestDrive 'unsafe.apbx'
        [IO.File]::WriteAllBytes($archive, [byte[]](1))
        $logPath = Join-Path $TestDrive 'fake-7z.log'
        Remove-Item -LiteralPath $logPath -ErrorAction SilentlyContinue
        $directoryRecords = foreach ($directory in $Directories) {
            "  echo Path = $directory", '  echo Folder = +', '  echo.'
        }
        @(
            '@echo off'
            '>>"%ATLAS_FAKE_7Z_LOG%" echo %*'
            'if /i "%~1"=="l" ('
            '  echo Path = playbook.conf'
            '  echo Folder = -'
            '  echo.'
            $directoryRecords
            ')'
            'exit /b 0'
        ) | Set-Content -LiteralPath (Join-Path $fakeBin '7z.cmd') -Encoding Ascii

        $oldPath = $env:PATH
        $oldLog = $env:ATLAS_FAKE_7Z_LOG
        try {
            $env:PATH = "$fakeBin$([IO.Path]::PathSeparator)$oldPath"
            $env:ATLAS_FAKE_7Z_LOG = $logPath
            $pwshPath = (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source
            $output = & $pwshPath -NoLogo -NoProfile -File `
                (Join-Path $repoRoot 'tools\build\Test-Apbx.ps1') `
                -Path $archive -PlaybookPath $playbook 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:PATH = $oldPath
            $env:ATLAS_FAKE_7Z_LOG = $oldLog
        }

        $exitCode | Should -Be 1
        $output = $output -join "`n"
        $output | Should -Match 'PASS: Exact source/archive file path parity'
        $output | Should -Match $Failure
        $output | Should -Match 'Archive extraction was blocked'
        $sevenZipCalls = (Get-Content -LiteralPath $logPath) -join "`n"
        $sevenZipCalls | Should -Match '(?m)^t\s'
        $sevenZipCalls | Should -Match '(?m)^l\s'
        $sevenZipCalls | Should -Not -Match '(?m)^[ex](?:\s|$)'
    }
}

Describe 'Repository build wrappers' {
    It 'runs the Windows wrapper through PowerShell 7 and preserves its exit code' -Skip:(-not $IsWindows) {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $sandbox = Join-Path $TestDrive 'repo with spaces'
        $toolsDir = Join-Path $sandbox 'tools\build'
        New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $repoRoot 'build.cmd') -Destination (Join-Path $sandbox 'build.cmd')

        $capturePath = Join-Path $TestDrive 'wrapper-capture.txt'
        @'
Set-Content -LiteralPath $env:ATLAS_WRAPPER_CAPTURE -Value "$($PSVersionTable.PSEdition)|$PSCommandPath|$($args -join '|')"
exit 37
'@ | Set-Content -LiteralPath (Join-Path $toolsDir 'Build-Playbook.ps1') -Encoding UTF8

        $previousCapture = $env:ATLAS_WRAPPER_CAPTURE
        $env:ATLAS_WRAPPER_CAPTURE = $capturePath
        try {
            Push-Location -LiteralPath $sandbox
            try {
                & $env:ComSpec /d /c '.\build.cmd automated'
                $wrapperExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }
        }
        finally {
            $env:ATLAS_WRAPPER_CAPTURE = $previousCapture
        }

        $wrapperExitCode | Should -Be 37
        $capture = Get-Content -LiteralPath $capturePath -Raw
        $capture | Should -Match '^Core\|'
        $capture | Should -Match ([regex]::Escape((Join-Path $toolsDir 'Build-Playbook.ps1')))
        $capture | Should -Match '\|-LocalTest\s*$'
    }

}

Describe 'A release candidate''s bundled Toolbox' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $script:AddBundledToolbox = Join-Path $repoRoot 'tools\release\Add-BundledToolbox.ps1'
        $script:CheckoutPlaybook = Join-Path $repoRoot 'playbook'
        . (Join-Path $repoRoot 'playbook\Executables\AtlasModules\Scripts\Operations\Toolbox-Package.ps1')
    }

    It 'adds an installer and manifest that Atlas installs from' {
        $playbook = Join-Path $TestDrive 'staged\playbook'
        New-Item -Path $playbook -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $playbook 'playbook.conf') -Value '<Playbook />'
        $installer = Join-Path $TestDrive 'AtlasToolbox-Setup.exe'
        [IO.File]::WriteAllBytes($installer, [byte[]](1, 2, 3, 4))

        & $script:AddBundledToolbox -PlaybookPath $playbook -Installer $installer -Version '0.2.0' 6>$null

        $bundled = Get-AtlasBundledToolbox -Root (Join-Path $playbook 'Executables\AtlasModules\Bundled\Toolbox')
        $bundled.Version | Should -BeExactly '0.2.0'
        $bundled.Size | Should -Be 4
        $bundled.Sha256 | Should -BeExactly (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash
        [IO.File]::ReadAllBytes($bundled.Path) | Should -Be ([byte[]](1, 2, 3, 4))
    }

    It "refuses the checkout's own playbook folder, which releases build from" {
        $installer = Join-Path $TestDrive 'AtlasToolbox-Setup.exe'
        [IO.File]::WriteAllBytes($installer, [byte[]](1))
        { & $script:AddBundledToolbox -PlaybookPath $script:CheckoutPlaybook -Installer $installer -Version '0.2.0' } |
            Should -Throw '*staged copy*'
        Join-Path $script:CheckoutPlaybook 'Executables\AtlasModules\Bundled' | Should -Not -Exist
    }
}

Describe 'Package version coherence' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $script:setVersionScript = Join-Path $script:repoRoot 'tools\build\Set-AtlasVersion.ps1'

        function Get-ConfVersion {
            param([Parameter(Mandatory = $true)][string]$Path)
            $match = [regex]::Match([IO.File]::ReadAllText($Path), '<Version>\s*([^<]+?)\s*</Version>')
            if (-not $match.Success) { throw "No <Version> in '$Path'." }
            $match.Groups[1].Value
        }

        # The upgrade sources in either form playbook.conf allows: <string> values, or one version
        # as the element text. Whitespace nodes aren't loaded, so text() only matches the second form.
        function Get-UpgradeSource {
            param([Parameter(Mandatory = $true)][string]$Path)
            $conf = [Xml.XmlDocument]::new()
            $conf.Load($Path)
            @($conf.SelectNodes('/Playbook/UpgradableFrom/string | /Playbook/UpgradableFrom/text()') |
                    ForEach-Object InnerText)
        }

        function Get-CargoPackageVersion {
            param([Parameter(Mandatory = $true)][string]$Path)
            $match = [regex]::Match([IO.File]::ReadAllText($Path), '(?m)^version\s*=\s*"([^"]+)"')
            if (-not $match.Success) { throw "No package version in '$Path'." }
            $match.Groups[1].Value
        }

        function Get-CargoLockVersion {
            param(
                [Parameter(Mandatory = $true)][string]$Path,
                [Parameter(Mandatory = $true)][string]$Name
            )
            $match = [regex]::Match([IO.File]::ReadAllText($Path),
                '(?m)^name = "' + [regex]::Escape($Name) + '"\r?\nversion = "([^"]+)"')
            if (-not $match.Success) { throw "No $Name entry in '$Path'." }
            $match.Groups[1].Value
        }

        # With a dependency entry that the bump must leave alone.
        function New-CargoLockFixture {
            param([string]$AppVersion = '0.6.0')
            "version = 4`n`n[[package]]`nname = `"anyhow`"`nversion = `"1.0.0`"`n`n" +
                "[[package]]`nname = `"atlas-app`"`nversion = `"$AppVersion`"`n"
        }

        # Laid out like the repository, so the script finds the app files from the conf path
        # and never falls back to the real ones.
        function New-VersionFixture {
            param(
                [Parameter(Mandatory = $true)][string]$Name,
                [Parameter(Mandatory = $true)][string]$UpgradableFrom,
                [string]$AppVersion = '0.6.0'
            )
            $fixture = Join-Path $TestDrive $Name
            New-Item -Path (Join-Path $fixture 'playbook'), (Join-Path $fixture 'app') `
                -ItemType Directory -Force | Out-Null
            $conf = Join-Path $fixture 'playbook\playbook.conf'
            "<Playbook>`n    <Version>0.6.0</Version>`n    $UpgradableFrom`n</Playbook>" |
                Set-Content -LiteralPath $conf -Encoding UTF8
            [IO.File]::WriteAllText((Join-Path $fixture 'app\Cargo.toml'),
                "[package]`nname = `"atlas-app`"`nversion = `"$AppVersion`"`n")
            [IO.File]::WriteAllText((Join-Path $fixture 'app\Cargo.lock'), (New-CargoLockFixture -AppVersion $AppVersion))
            $conf
        }
    }

    It 'declares only what Atlas Manager and the front door read in the committed playbook.conf' {
        $conf = [Xml.XmlDocument]::new()
        $conf.Load((Join-Path $script:repoRoot 'playbook\playbook.conf'))
        @($conf.DocumentElement.ChildNodes | Where-Object NodeType -eq 'Element' | ForEach-Object LocalName) |
            Should -Be @('Version', 'SupportedBuilds', 'UpgradableFrom', 'Requirements', 'EstimatedMinutes', 'FeaturePages')
        @($conf.SelectNodes('/Playbook/Requirements/Requirement') | ForEach-Object InnerText) |
            Should -Be @('DefenderToggled', 'NoAntivirus', 'PluggedIn') -Because 'the front door refuses a requirement it cannot check'
    }

    It 'keeps the app/Cargo.toml package version equal to the playbook.conf version' {
        $confVersion = Get-ConfVersion -Path (Join-Path $script:repoRoot 'playbook\playbook.conf')

        Get-CargoPackageVersion -Path (Join-Path $script:repoRoot 'app\Cargo.toml') |
            Should -BeExactly $confVersion -Because 'Set-AtlasVersion.ps1 must keep the app at the released version'
    }

    It 'bumps the committed playbook.conf and app version and appends the superseded version' {
        $fixture = Join-Path $TestDrive 'version-fixture'
        New-Item -Path (Join-Path $fixture 'playbook'), (Join-Path $fixture 'app') -ItemType Directory -Force | Out-Null
        $conf = Join-Path $fixture 'playbook\playbook.conf'
        $cargoToml = Join-Path $fixture 'app\Cargo.toml'
        $cargoLock = Join-Path $fixture 'app\Cargo.lock'
        Copy-Item -LiteralPath (Join-Path $script:repoRoot 'playbook\playbook.conf') `
            -Destination $conf
        Copy-Item -LiteralPath (Join-Path $script:repoRoot 'app\Cargo.toml') -Destination $cargoToml
        [IO.File]::WriteAllText($cargoLock, (New-CargoLockFixture))

        $originalVersion = Get-ConfVersion -Path $conf
        $originalSources = @(Get-UpgradeSource -Path $conf)
        $originalSources.Count | Should -BeGreaterThan 0
        $originalManifest = [IO.File]::ReadAllLines($cargoToml)
        $bumpVersion = '9.9.9'

        & $script:setVersionScript -Version $bumpVersion -PlaybookConfPath $conf | Out-Null
        Get-ConfVersion -Path $conf | Should -Be $bumpVersion
        (Get-UpgradeSource -Path $conf) -join ',' |
            Should -BeExactly ((@($originalSources) + $originalVersion) -join ',')

        # Only the [package] version line changes; dependency versions stay as they are.
        Get-CargoPackageVersion -Path $cargoToml | Should -BeExactly $bumpVersion
        $manifest = [IO.File]::ReadAllLines($cargoToml)
        $manifest.Count | Should -Be $originalManifest.Count
        $changedLines = @(for ($index = 0; $index -lt $manifest.Count; $index++) {
                if ($manifest[$index] -cne $originalManifest[$index]) { $manifest[$index] }
            })
        $changedLines -join '|' | Should -BeExactly "version = `"$bumpVersion`""
        Get-CargoLockVersion -Path $cargoLock -Name 'atlas-app' | Should -BeExactly $bumpVersion
        Get-CargoLockVersion -Path $cargoLock -Name 'anyhow' | Should -BeExactly '1.0.0'
    }

    It 'leaves UpgradableFrom as <Expected> for <Case>' -ForEach @(
        @{ Case = 'a single source'; Sources = '<UpgradableFrom>0.5.0</UpgradableFrom>'; Version = '0.7.0'; Expected = '0.6.0' }
        @{ Case = 'a list that already has the superseded version'; Sources = '<UpgradableFrom><string>0.5.0</string><string>0.6.0</string></UpgradableFrom>'; Version = '0.7.0'; Expected = '0.5.0,0.6.0' }
        @{ Case = 'a bump to the current version'; Sources = '<UpgradableFrom>0.5.0</UpgradableFrom>'; Version = '0.6.0'; Expected = '0.5.0' }
    ) {
        $conf = New-VersionFixture -Name ($Case -replace '\W', '-') -UpgradableFrom $Sources
        $fixture = Split-Path (Split-Path $conf -Parent) -Parent

        & $script:setVersionScript -Version $Version -PlaybookConfPath $conf -WarningAction SilentlyContinue | Out-Null
        Get-ConfVersion -Path $conf | Should -Be $Version
        (Get-UpgradeSource -Path $conf) -join ',' | Should -BeExactly $Expected
        Get-CargoPackageVersion -Path (Join-Path $fixture 'app\Cargo.toml') | Should -BeExactly $Version
        Get-CargoLockVersion -Path (Join-Path $fixture 'app\Cargo.lock') -Name 'atlas-app' | Should -BeExactly $Version
    }

    It 'brings drifted app files in line when playbook.conf already has the version' {
        $conf = New-VersionFixture -Name 'drifted-app' -UpgradableFrom '<UpgradableFrom>0.5.0</UpgradableFrom>' -AppVersion '0.5.9'
        $app = Join-Path (Split-Path (Split-Path $conf -Parent) -Parent) 'app'
        $originalConf = [Convert]::ToBase64String([IO.File]::ReadAllBytes($conf))

        & $script:setVersionScript -Version '0.6.0' -PlaybookConfPath $conf -WarningAction SilentlyContinue | Out-Null
        Get-CargoPackageVersion -Path (Join-Path $app 'Cargo.toml') | Should -BeExactly '0.6.0'
        Get-CargoLockVersion -Path (Join-Path $app 'Cargo.lock') -Name 'atlas-app' | Should -BeExactly '0.6.0'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($conf)) | Should -BeExactly $originalConf
        (Get-UpgradeSource -Path $conf) -join ',' | Should -BeExactly '0.5.0'
    }

    It 'leaves every file byte-identical when they all already have the version' {
        $conf = New-VersionFixture -Name 'already-current' -UpgradableFrom '<UpgradableFrom>0.5.0</UpgradableFrom>'
        $fixture = Split-Path (Split-Path $conf -Parent) -Parent
        $files = @(Get-ChildItem -LiteralPath $fixture -Recurse -File -Force)
        $before = @($files | ForEach-Object { [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName)) })
        $files.Count | Should -Be 3

        & $script:setVersionScript -Version '0.6.0' -PlaybookConfPath $conf -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        @($files | ForEach-Object { [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName)) }) | Should -Be $before
        @($warnings) -join '|' | Should -BeLike '*nothing to do*'
    }

    It 'changes nothing when <Case>' -ForEach @(
        @{ Case = 'the version lacks a number'; Version = '0.7'; LockText = $null; Message = "*parameter 'Version'*" }
        @{ Case = 'Cargo.lock has no atlas-app entry'; Version = '0.7.0'; LockText = "version = 4`n"; Message = '*atlas-app entry*' }
    ) {
        $conf = New-VersionFixture -Name ($Case -replace '\W', '-') -UpgradableFrom '<UpgradableFrom>0.5.0</UpgradableFrom>'
        $fixture = Split-Path (Split-Path $conf -Parent) -Parent
        $app = Join-Path $fixture 'app'
        if ($LockText) { [IO.File]::WriteAllText((Join-Path $app 'Cargo.lock'), $LockText) }

        { & $script:setVersionScript -Version $Version -PlaybookConfPath $conf } |
            Should -Throw -ExpectedMessage $Message
        Get-ConfVersion -Path $conf | Should -Be '0.6.0'
        Get-CargoPackageVersion -Path (Join-Path $app 'Cargo.toml') | Should -BeExactly '0.6.0'
    }
}

Describe 'Build-AtlasNative' {
    BeforeDiscovery {
        $script:LegacyCompiler = "$env:windir\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
        # The query the tool runs, so the Roslyn case runs wherever the tool would find a compiler.
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        $script:HasRoslynCompiler = $false
        if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
            $roslynCompiler = & $vswhere -latest -products '*' -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Roslyn\csc.exe' 2>$null
            $script:HasRoslynCompiler = $LASTEXITCODE -eq 0 -and [bool]$roslynCompiler
        }
    }

    BeforeAll {
        $script:NativeTool = Join-Path $PSScriptRoot '..\tools\native\Build-AtlasNative.ps1'
        $script:Pwsh = (Get-Process -Id $PID).Path
    }

    It 'compiles an unsigned library with the legacy compiler and records its hash' -ForEach @(
        @{ Compiler = $script:LegacyCompiler }
    ) -Skip:(-not (Test-Path -LiteralPath $script:LegacyCompiler -PathType Leaf)) {
        $output = Join-Path $TestDrive 'native'
        $log = (& $script:Pwsh -NoProfile -ExecutionPolicy Bypass -File $script:NativeTool -OutputPath $output -CompilerPath $Compiler 2>&1) -join "`n"
        $LASTEXITCODE | Should -Be 0 -Because $log
        $log | Should -Match '\(legacy, output is not reproducible\)'
        $dll = Join-Path $output 'Atlas.Native.dll'
        $dll | Should -Exist
        (Get-Content -LiteralPath "$dll.sha256" -Raw) | Should -Match "^$((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLowerInvariant()) \*Atlas\.Native\.dll"
        (Get-AuthenticodeSignature -FilePath $dll).Status | Should -Be 'NotSigned'
        [Reflection.AssemblyName]::GetAssemblyName($dll).Name | Should -Be 'Atlas.Native'
    }

    It 'builds a byte-identical library each time with the Roslyn compiler it finds' -Skip:(-not $script:HasRoslynCompiler) {
        $hashes = foreach ($build in 'first', 'second') {
            $output = Join-Path $TestDrive "roslyn-$build"
            $log = (& $script:Pwsh -NoProfile -ExecutionPolicy Bypass -File $script:NativeTool -OutputPath $output 2>&1) -join "`n"
            $LASTEXITCODE | Should -Be 0 -Because $log
            $log | Should -Not -Match '\(legacy'
            (Get-FileHash -LiteralPath (Join-Path $output 'Atlas.Native.dll') -Algorithm SHA256).Hash
        }
        $hashes[1] | Should -BeExactly $hashes[0]
    }

    It 'fails closed when no compiler is usable' {
        $log = & $script:Pwsh -NoProfile -ExecutionPolicy Bypass -File $script:NativeTool -OutputPath (Join-Path $TestDrive 'none') -CompilerPath (Join-Path $TestDrive 'missing-csc.exe') 2>&1
        $LASTEXITCODE | Should -Be 2 -Because ($log -join "`n")
    }
}
