BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\tools\build\AtlasBuild\AtlasBuild.psd1') -Force
}

Describe 'Get-PlaybookVersion' {
    It 'parses version metadata from a valid playbook.conf' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas v0.5.1</Title>
    <Version>0.5.1</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        $result = Get-PlaybookVersion -PlaybookConfPath $conf
        $result.Version | Should -Be '0.5.1'
        $result.IsDev | Should -BeFalse
        $result.VersionLabel | Should -Be 'v0.5.1'
    }

    It 'marks dev builds from the title' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas v0.6.0 (dev)</Title>
    <Version>0.6.0</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        $result = Get-PlaybookVersion -PlaybookConfPath $conf
        $result.IsDev | Should -BeTrue
        $result.VersionLabel | Should -Be 'v0.6.0 (dev)'
    }

    It 'throws on an invalid version format' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas</Title>
    <Version>not.a.version</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        { Get-PlaybookVersion -PlaybookConfPath $conf } | Should -Throw
    }

    It 'throws when the file is missing' {
        { Get-PlaybookVersion -PlaybookConfPath (Join-Path $TestDrive 'missing.conf') } | Should -Throw
    }
}

Describe 'New-StagedPlaybookConf' {
    BeforeEach {
        $script:sourceConf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas v0.5.1</Title>
    <Version>0.5.1</Version>
    <Requirements>
        <Requirement>Internet</Requirement>
        <Requirement>PluggedIn</Requirement>
    </Requirements>
    <SupportedBuilds>
        <string>26100</string>
        <string>26200</string>
    </SupportedBuilds>
    <ProductCode>64</ProductCode>
</Playbook>
'@ | Set-Content -Path $script:sourceConf -Encoding UTF8
        $script:stagedConf = Join-Path $TestDrive 'staged\playbook.conf'
    }

    It 'returns false when no removals are requested' {
        $result = New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf
        $result | Should -BeFalse
        Test-Path $stagedConf | Should -BeFalse
    }

    It 'strips requirement lines' {
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf -RemoveRequirements | Should -BeTrue
        $content = Get-Content $stagedConf -Raw
        $content | Should -Not -Match '<Requirement>'
        $content | Should -Match '<SupportedBuilds>'
        $content | Should -Match '<ProductCode>'
    }

    It 'strips supported builds lines' {
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf -RemoveWinverRequirement | Should -BeTrue
        $content = Get-Content $stagedConf -Raw
        $content | Should -Not -Match 'SupportedBuilds'
        $content | Should -Not -Match '<string>26100</string>'
        $content | Should -Match '<Requirement>'
    }

    It 'strips the product code line' {
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf -RemoveVerification | Should -BeTrue
        (Get-Content $stagedConf -Raw) | Should -Not -Match '<ProductCode>'
    }
}

Describe 'Atlas configuration build boundary' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $script:BuildBoundarySourceConfiguration = Join-Path $repoRoot 'playbook\Configuration'

        function Copy-AtlasTaskFreeConfiguration {
            param([Parameter(Mandatory = $true)][string]$Destination)

            Copy-Item -LiteralPath $script:BuildBoundarySourceConfiguration `
                -Destination $Destination -Recurse
            $customYml = Join-Path $Destination 'custom.yml'
            $content = [IO.File]::ReadAllText($customYml) -replace `
                '(?m)^  - !task:.*\r?\n', ''
            [IO.File]::WriteAllText($customYml, $content, [Text.UTF8Encoding]::new($false))
            return $Destination
        }
    }

    It 'accepts the compact reviewed runner configuration' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'task-free-target')
        $summary = Assert-AtlasConfigurationRunnerBoundary `
            -ConfigurationRoot $fixture

        $summary.Actions | Should -Be 29
        $summary.Runs | Should -Be 26
    }

    It 'rejects currentUserElevated even when every other run field is canonical' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'current-user-elevated')
        $customYml = Join-Path $fixture 'custom.yml'
        $content = [IO.File]::ReadAllText($customYml)
        $content = [regex]::new('runas: trustedInstaller').Replace(
            $content,
            'runas: currentUserElevated',
            1
        )
        [IO.File]::WriteAllText($customYml, $content, [Text.UTF8Encoding]::new($false))

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $fixture } |
            Should -Throw -ExpectedMessage "*unsupported runas 'currentUserElevated'*"
    }

    It 'rejects Command mode now that every privileged runner uses a direct script file' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'command-mode')
        $customYml = Join-Path $fixture 'custom.yml'
        $content = [IO.File]::ReadAllText($customYml)
        $content = [regex]::new(' -File ').Replace($content, ' -Command ', 1)
        [IO.File]::WriteAllText($customYml, $content, [Text.UTF8Encoding]::new($false))

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $fixture } |
            Should -Throw -ExpectedMessage '*!run must use direct File mode*'
    }

    It 'rejects abbreviated Command mode even when its command text contains a File decoy' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'abbreviated-command-mode')
        $customYml = Join-Path $fixture 'custom.yml'
        $content = [IO.File]::ReadAllText($customYml)
        $content = [regex]::new('-File "[^"]+"').Replace(
            $content,
            '-C "Write-Output 1; # -File decoy"',
            1
        )
        [IO.File]::WriteAllText($customYml, $content, [Text.UTF8Encoding]::new($false))

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $fixture } |
            Should -Throw -ExpectedMessage '*!run must use direct File mode*'
    }

    It 'rejects an unreviewed .yaml configuration variant before packaging' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'alternate-extension')
        'actions: []' | Set-Content -LiteralPath (Join-Path $fixture 'extra.yaml') -Encoding UTF8

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $fixture } |
            Should -Throw -ExpectedMessage '*unreviewed YAML filename variants*extra.yaml*'
    }

    It 'rejects every AME task action' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'task-action')
        $customYml = Join-Path $fixture 'custom.yml'
        $content = [IO.File]::ReadAllText($customYml) -replace `
            '(?m)^actions:\s*$',
            "actions:`n  - !task: {path: 'atlas\start.yml'}"
        [IO.File]::WriteAllText($customYml, $content, [Text.UTF8Encoding]::new($false))

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $fixture } |
            Should -Throw -ExpectedMessage '*must contain zero AME !task actions*'
    }

    It 'freezes the one ISO-only WdBoot registry mutation' {
        $fixture = Copy-AtlasTaskFreeConfiguration `
            -Destination (Join-Path $TestDrive 'registry-drift')
        $customYml = Join-Path $fixture 'custom.yml'
        $content = [IO.File]::ReadAllText($customYml).Replace(
            'HKLM\OfflineSys\ControlSet001\Services\WdBoot',
            'HKLM\OfflineSys\ControlSet001\Services\WdFilter'
        )
        [IO.File]::WriteAllText($customYml, $content, [Text.UTF8Encoding]::new($false))

        { Assert-AtlasConfigurationRunnerBoundary -ConfigurationRoot $fixture } |
            Should -Throw -ExpectedMessage '*!registryKey contract differs from the reviewed ISO-only WdBoot delete*'
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
    It 'returns the base name when nothing conflicts' {
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas.apbx'
    }

    It 'appends a counter when the file exists and replacement is not allowed' {
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
        '<Playbook><Title>Atlas v0.6.0</Title><Version>0.6.0</Version></Playbook>' |
            Set-Content -LiteralPath (Join-Path $playbook 'playbook.conf') -Encoding UTF8
        Mock Assert-AtlasConfigurationRunnerBoundary {
            [pscustomobject]@{ Files = 1; Actions = 29; Runs = 26 }
        } -ModuleName AtlasBuild
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

Describe 'APBX payload path contracts' {
    It 'enumerates every source payload file except generated APBX outputs' {
        $playbook = Join-Path $TestDrive 'playbook'
        New-Item -Path (Join-Path $playbook 'Configuration') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $playbook 'Executables\Nested') -ItemType Directory -Force | Out-Null
        '<Playbook />' | Set-Content -Path (Join-Path $playbook 'playbook.conf') -Encoding UTF8
        'actions: []' | Set-Content -Path (Join-Path $playbook 'Configuration\custom.yml') -Encoding UTF8
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
            'Configuration/custom.yml'
            'Executables/Nested/tool.txt'
            'playbook.conf'
        )
    }

    It 'reports missing, unexpected, and duplicate archive paths independently' {
        $result = Compare-AtlasPayloadPath `
            -ExpectedPath @('Configuration/custom.yml', 'Executables/tool.ps1') `
            -ActualPath @('Configuration\custom.yml', 'Executables/stale.ps1', 'Executables/stale.ps1')

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
    It 'never invokes 7-Zip extraction after an unsafe archive path is listed' `
        -Skip:(-not $IsWindows) {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $fakeBin = Join-Path $TestDrive 'fake-bin'
        $playbook = Join-Path $TestDrive 'playbook'
        New-Item -ItemType Directory -Path $fakeBin, $playbook -Force | Out-Null
        '<Playbook />' | Set-Content -LiteralPath (Join-Path $playbook 'playbook.conf') `
            -Encoding UTF8
        $archive = Join-Path $TestDrive 'unsafe.apbx'
        [IO.File]::WriteAllBytes($archive, [byte[]](1))
        $logPath = Join-Path $TestDrive 'fake-7z.log'
        @'
@echo off
>>"%ATLAS_FAKE_7Z_LOG%" echo %*
if /i "%~1"=="l" (
  echo Path = Configuration/../../outside.yml
  echo Folder = -
  echo.
)
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $fakeBin '7z.cmd') -Encoding Ascii

        $oldPath = $env:PATH
        $oldLog = $env:ATLAS_FAKE_7Z_LOG
        try {
            $env:PATH = "$fakeBin$([IO.Path]::PathSeparator)$oldPath"
            $env:ATLAS_FAKE_7Z_LOG = $logPath
            $pwshPath = (Get-Command pwsh -CommandType Application).Source
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
        ($output -join "`n") | Should -Match 'Archive extraction was blocked'
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
                & $env:ComSpec /d /c 'build.cmd automated'
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
