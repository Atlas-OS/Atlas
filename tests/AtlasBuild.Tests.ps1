BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\tools\build\AtlasBuild\AtlasBuild.psd1') -Force
}

Describe 'Package license distribution' {
    It 'includes the complete project license in the installed modules' {
        $repo = Split-Path $PSScriptRoot -Parent
        $projectLicense = Join-Path $repo 'LICENSE'
        $packageLicense = Join-Path $repo 'package\Executables\AtlasModules\LICENSE'
        [IO.File]::ReadAllText($packageLicense) | Should -BeExactly ([IO.File]::ReadAllText($projectLicense))
        @(Get-AtlasPackageFilePath -PackagePath (Join-Path $repo 'package')) |
            Should -Contain 'Executables/AtlasModules/LICENSE'
    }
}

Describe 'Get-AtlasPackageVersion' {
    It 'reads <Version> from atlas.json' -ForEach @(
        @{ Version = '0.6.1' }
        @{ Version = '0.7.0-rc.1' }
    ) {
        $manifest = Join-Path $TestDrive 'atlas.json'
        [IO.File]::WriteAllText($manifest, "{ `"schemaVersion`": 1, `"version`": `"$Version`" }")

        $result = Get-AtlasPackageVersion -ManifestPath $manifest
        $result.Version | Should -BeExactly $Version
        $result.VersionLabel | Should -BeExactly "v$Version"
    }

    It 'throws on <Case>' -TestCases @(
        @{ Case = 'an invalid version format'; Text = '{ "version": "0.6" }'; Message = "*Invalid version format '0.6'*" }
        @{ Case = 'a version that is not a string'; Text = '{ "version": 6 }'; Message = '*no version string*' }
        @{ Case = 'JSON with a trailing comma'; Text = '{ "version": "0.6.0", }'; Message = "*isn't valid JSON*" }
        @{ Case = 'a missing file'; Text = $null; Message = '*atlas.json not found*' }
    ) {
        $manifest = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
        if ($null -ne $Text) {
            [IO.File]::WriteAllText($manifest, $Text)
        }

        { Get-AtlasPackageVersion -ManifestPath $manifest } | Should -Throw $Message
    }
}

Describe 'Test-AtlasManifest' {
    BeforeAll {
        # A small manifest that follows the format, which each case breaks in one place.
        function New-ManifestFixture {
            [ordered]@{
                schemaVersion         = 1
                version               = '0.6.0'
                minimumManagerVersion = '0.6.0'
                supportedBuilds       = @([ordered]@{ build = 26200; release = '25H2' })
                updatableFrom         = @('0.5.0')
                requirements          = @('windows-security-off', 'plugged-in')
                estimatedMinutes      = 15
                choices               = @(
                    [ordered]@{
                        id      = 'extras'
                        kind    = 'multiple'
                        options = @(
                            [ordered]@{ id = 'install-another-browser'; label = 'Install a browser' }
                        )
                    }
                    [ordered]@{
                        id        = 'browser'
                        kind      = 'single'
                        default   = 'browser-brave'
                        dependsOn = 'install-another-browser'
                        learnMore = 'https://atlasos.net/docs/'
                        options   = @(
                            [ordered]@{ id = 'browser-brave'; label = 'Brave'; image = 'brave' }
                            [ordered]@{ id = 'browser-firefox'; label = 'Firefox' }
                        )
                    }
                )
            }
        }

        function Write-ManifestFixture {
            param([Parameter(Mandatory = $true)]$Manifest)
            $path = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
            [IO.File]::WriteAllText($path, ($Manifest | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
            $path
        }

        $script:FixtureFiles = @('atlas.json', 'Images/brave.png')
    }

    It 'returns nothing for a manifest that follows the format' {
        $path = Write-ManifestFixture -Manifest (New-ManifestFixture)
        @(Test-AtlasManifest -Path $path -PackageFile $script:FixtureFiles) | Should -BeNullOrEmpty
    }

    It 'accepts the minimum Manager version <Manager> for version <Version>' -ForEach @(
        @{ Manager = '0.6.0'; Version = '0.6.0' }
        @{ Manager = '0.9.0'; Version = '0.10.0' }
        @{ Manager = '0.7.0'; Version = '0.7.0-rc.1' }
        @{ Manager = '0.6.0'; Version = '1.0.0' }
    ) {
        $manifest = New-ManifestFixture
        $manifest.version = $Version
        $manifest.minimumManagerVersion = $Manager
        $path = Write-ManifestFixture -Manifest $manifest

        @(Test-AtlasManifest -Path $path -PackageFile $script:FixtureFiles) | Should -BeNullOrEmpty
    }

    It 'returns nothing for the committed atlas.json and its images' {
        $package = Join-Path $PSScriptRoot '..\package'
        @(Test-AtlasManifest -Path (Join-Path $package 'atlas.json') -PackageFile @(Get-AtlasPackageFilePath -PackagePath $package)) |
            Should -BeNullOrEmpty
    }

    It 'reports <Case>' -ForEach @(
        @{ Case = 'another schema version'; Change = { param($m) $m.schemaVersion = 2 }; Problem = 'schemaVersion must be 1*' }
        @{ Case = 'a version without three numbers'; Change = { param($m) $m.version = '0.6' }; Problem = 'version must be a string*' }
        @{ Case = 'a missing minimum Manager version'; Change = { param($m) $m.Remove('minimumManagerVersion') }; Problem = "atlas.json has no 'minimumManagerVersion'." }
        @{ Case = 'a minimum Manager version with a suffix'; Change = { param($m) $m.minimumManagerVersion = '0.6.0-rc.1' }; Problem = 'minimumManagerVersion must be a string such as 1.2.3, not "0.6.0-rc.1".' }
        @{ Case = 'a minimum Manager version without three numbers'; Change = { param($m) $m.minimumManagerVersion = '0.6' }; Problem = 'minimumManagerVersion must be a string such as 1.2.3*' }
        @{ Case = 'a minimum Manager version written as a number'; Change = { param($m) $m.minimumManagerVersion = 6 }; Problem = 'minimumManagerVersion must be a string such as 1.2.3, not 6.' }
        @{ Case = 'a minimum Manager version above the version'; Change = { param($m) $m.minimumManagerVersion = '0.6.1' }; Problem = "minimumManagerVersion '0.6.1' is higher than version '0.6.0'." }
        @{ Case = 'a minimum Manager version above the version by number, not text'; Change = { param($m) $m.version = '0.9.0'; $m.minimumManagerVersion = '0.10.0' }; Problem = "minimumManagerVersion '0.10.0' is higher than version '0.9.0'." }
        @{ Case = 'a build written as a string'; Change = { param($m) $m.supportedBuilds[0].build = '26200' }; Problem = 'supportedBuilds`[0`].build must be a positive integer.' }
        @{ Case = 'a build with a fraction'; Change = { param($m) $m.supportedBuilds[0].build = 26200.5 }; Problem = 'supportedBuilds`[0`].build must be a positive integer.' }
        @{ Case = 'a build without a release name'; Change = { param($m) $m.supportedBuilds[0].Remove('release') }; Problem = 'supportedBuilds`[0`].release must name the release*' }
        @{ Case = 'a source that is not a version'; Change = { param($m) $m.updatableFrom = @('latest') }; Problem = 'updatableFrom has "latest"*' }
        @{ Case = 'an unknown requirement'; Change = { param($m) $m.requirements = @('NoAntivirus') }; Problem = 'requirements has "NoAntivirus"*' }
        @{ Case = 'a repeated requirement'; Change = { param($m) $m.requirements = @('plugged-in', 'plugged-in') }; Problem = "requirements lists 'plugged-in' more than once." }
        @{ Case = 'an estimate that is not a whole number'; Change = { param($m) $m.estimatedMinutes = 'soon' }; Problem = 'estimatedMinutes must be a positive whole number*' }
        @{ Case = 'a missing field'; Change = { param($m) $m.Remove('choices') }; Problem = "atlas.json has no 'choices'." }
        @{ Case = 'an unknown field'; Change = { param($m) $m.FeaturePages = @() }; Problem = "atlas.json has an unknown field 'FeaturePages'." }
        @{ Case = 'a single choice without a default'; Change = { param($m) $m.choices[1].Remove('default') }; Problem = "Choice 'browser' is a single choice without a default." }
        @{ Case = 'a default that is not an option'; Change = { param($m) $m.choices[1].default = 'browser-chrome' }; Problem = "Choice 'browser' has the default ""browser-chrome"", which isn't one of its options." }
        @{ Case = 'a default on a multiple choice'; Change = { param($m) $m.choices[0].default = 'install-another-browser' }; Problem = "Choice 'extras' has a default, which only single choices take." }
        @{ Case = 'an unknown kind'; Change = { param($m) $m.choices[0].kind = 'many' }; Problem = "Choice 'extras' must have the kind single or multiple." }
        @{ Case = 'a repeated option id'; Change = { param($m) $m.choices[1].options[1].id = 'install-another-browser' }; Problem = "More than one option has the id 'install-another-browser'." }
        @{ Case = 'a repeated choice id'; Change = { param($m) $m.choices[1].id = 'extras' }; Problem = "More than one choice has the id 'extras'." }
        @{ Case = 'a dependsOn that names no option'; Change = { param($m) $m.choices[1].dependsOn = 'install-browser' }; Problem = "Choice 'browser' depends on ""install-browser"", which isn't a declared option." }
        @{ Case = 'a dependsOn on its own option'; Change = { param($m) $m.choices[1].dependsOn = 'browser-firefox' }; Problem = "Choice 'browser' depends on its own option 'browser-firefox'." }
        @{ Case = 'an image with its extension'; Change = { param($m) $m.choices[1].options[0].image = 'brave.png' }; Problem = "Option 'browser-brave' has the image ""brave.png""*" }
        @{ Case = 'an image the package lacks'; Change = { param($m) $m.choices[1].options[0].image = 'chrome' }; Problem = "Option 'browser-brave' has the image 'chrome', but the package has no Images/chrome.png." }
        @{ Case = 'an option without a label'; Change = { param($m) $m.choices[1].options[1].label = '' }; Problem = "Option 'browser-firefox' has no label." }
        @{ Case = 'a learnMore link without https'; Change = { param($m) $m.choices[1].learnMore = 'http://atlasos.net/' }; Problem = "Choice 'browser' has a learnMore that isn't an https:// link." }
        @{ Case = 'a choice without options'; Change = { param($m) $m.choices[0].options = @() }; Problem = "Choice 'extras' has no options." }
    ) {
        $manifest = New-ManifestFixture
        & $Change $manifest
        $path = Write-ManifestFixture -Manifest $manifest

        $problems = @(Test-AtlasManifest -Path $path -PackageFile $script:FixtureFiles)
        $problems | Should -Not -BeNullOrEmpty
        @($problems | Where-Object { $_ -like $Problem }) | Should -Not -BeNullOrEmpty -Because ($problems -join "`n")
    }

    It 'reports a repeated field, which a JSON reader would otherwise resolve silently' {
        $path = Join-Path $TestDrive 'repeated.json'
        $text = (New-ManifestFixture | ConvertTo-Json -Depth 10) -replace '"version": "0.6.0",', '"version": "0.6.0", "version": "0.7.0",'
        [IO.File]::WriteAllText($path, $text)

        @(Test-AtlasManifest -Path $path -PackageFile $script:FixtureFiles) |
            Should -Contain "atlas.json declares 'version' more than once."
    }

    It 'reports <Case> without reading further' -ForEach @(
        @{ Case = 'a byte order mark'; Bytes = [byte[]](0xEF, 0xBB, 0xBF) + [Text.Encoding]::UTF8.GetBytes('{}'); Problem = '*byte order mark*' }
        @{ Case = 'invalid UTF-8'; Bytes = [byte[]](0x7B, 0xC3, 0x7D); Problem = "*isn't valid UTF-8*" }
        @{ Case = 'a top-level array'; Bytes = [Text.Encoding]::UTF8.GetBytes('[]'); Problem = 'atlas.json must hold a JSON object.' }
    ) {
        $path = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
        [IO.File]::WriteAllBytes($path, $Bytes)

        $problems = @(Test-AtlasManifest -Path $path)
        $problems.Count | Should -Be 1
        $problems[0] | Should -BeLike $Problem
    }
}

Describe 'New-StagedAtlasManifest' {
    BeforeAll {
        # The manifest as data, so the comparison ignores formatting.
        function Get-ManifestData {
            param([Parameter(Mandatory = $true)][string]$Path)
            [IO.File]::ReadAllText($Path) | ConvertFrom-Json
        }

        function ConvertTo-ComparableJson {
            param([Parameter(Mandatory = $true)]$Manifest)
            $Manifest | ConvertTo-Json -Depth 20 -Compress
        }

        $script:committedManifest = Join-Path $PSScriptRoot '..\package\atlas.json'
    }

    BeforeEach {
        $script:stagedManifest = Join-Path $TestDrive "staged-$([guid]::NewGuid().ToString('N'))\atlas.json"
    }

    It 'returns false when no removals are requested' {
        $result = New-StagedAtlasManifest -ManifestPath $committedManifest -DestinationPath $stagedManifest
        $result | Should -BeFalse
        Test-Path $stagedManifest | Should -BeFalse
    }

    It '-<Switch> empties only <Field>' -ForEach @(
        @{ Switch = 'RemoveRequirements'; Field = 'requirements' }
        @{ Switch = 'RemoveSupportedBuilds'; Field = 'supportedBuilds' }
    ) {
        $removal = @{ $Switch = $true }
        New-StagedAtlasManifest -ManifestPath $committedManifest -DestinationPath $stagedManifest @removal | Should -BeTrue

        $expected = Get-ManifestData -Path $committedManifest
        @($expected.$Field).Count | Should -BeGreaterThan 0 -Because "the committed manifest must have $Field to empty"
        $expected.$Field = @()
        ConvertTo-ComparableJson -Manifest (Get-ManifestData -Path $stagedManifest) |
            Should -BeExactly (ConvertTo-ComparableJson -Manifest $expected)
    }

    It 'writes a manifest that still follows the format, in the committed layout' {
        New-StagedAtlasManifest -ManifestPath $committedManifest -DestinationPath $stagedManifest `
            -RemoveRequirements -RemoveSupportedBuilds | Should -BeTrue

        @(Test-AtlasManifest -Path $stagedManifest) | Should -BeNullOrEmpty
        $bytes = [IO.File]::ReadAllBytes($stagedManifest)
        $bytes[0] | Should -Be 0x7B -Because 'atlas.json has no byte order mark'
        [Text.Encoding]::UTF8.GetString($bytes) | Should -Not -Match "`r"
    }
}

Describe 'ConvertTo-AtlasManifestJson' {
    It 'writes the committed atlas.json back byte for byte' {
        $committed = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\package\atlas.json'))
        $manifest = [System.Text.Json.Nodes.JsonNode]::Parse($committed)

        ConvertTo-AtlasManifestJson -Manifest $manifest | Should -BeExactly $committed
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
        Get-AvailableArchiveName -BaseName 'Atlas.atlaspkg' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas.atlaspkg'

        New-Item -Path (Join-Path $TestDrive 'Atlas.atlaspkg') -ItemType File | Out-Null
        Get-AvailableArchiveName -BaseName 'Atlas.atlaspkg' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas (1).atlaspkg'
    }

    It 'selects the existing name without deleting it when replacement is allowed' {
        New-Item -Path (Join-Path $TestDrive 'Atlas.atlaspkg') -ItemType File -Force | Out-Null
        Get-AvailableArchiveName -BaseName 'Atlas.atlaspkg' -WorkingDirectory $TestDrive -DisplayName 'Atlas' -AllowReplace |
            Should -Be 'Atlas.atlaspkg'
        Test-Path (Join-Path $TestDrive 'Atlas.atlaspkg') | Should -BeTrue
    }
}

Describe 'Package archive encryption' {
    BeforeEach {
        $package = Join-Path $TestDrive 'package'
        $output = Join-Path $TestDrive 'output'
        New-Item -ItemType Directory -Path $package, $output -Force | Out-Null
        '{ "schemaVersion": 1, "version": "0.6.0" }' |
            Set-Content -LiteralPath (Join-Path $package 'atlas.json') -Encoding UTF8
        Mock Resolve-SevenZip { 'mock-7z.exe' } -ModuleName AtlasBuild
        Mock Invoke-AtlasPackageVerifier { } -ModuleName AtlasBuild
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
    }

    It 'creates the archive with AES-256 under the public password' {
        New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
            -WarningAction SilentlyContinue | Out-Null

        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 1 -Exactly -ParameterFilter {
            $ErrorContext -eq 'Creating the package archive' -and
            $ArgumentList -ccontains '-tzip' -and
            $ArgumentList -ccontains '-mem=AES256' -and
            $ArgumentList -ccontains "-p$(Get-AtlasPackagePassword)"
        }
        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 1 -Exactly -ParameterFilter {
            $ErrorContext -eq 'Verifying the built package archive' -and
            $ArgumentList -ccontains "-p$(Get-AtlasPackagePassword)"
        }
    }

    It 'encrypts the staged overrides with AES-256 too' {
        New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
            -RemoveSupportedBuilds -WarningAction SilentlyContinue | Out-Null

        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 1 -Exactly -ParameterFilter {
            $ErrorContext -eq 'Adding staged overrides' -and
            $ArgumentList -ccontains '-mem=AES256' -and
            $ArgumentList -ccontains "-p$(Get-AtlasPackagePassword)"
        }
    }

    It 'passes no password or encryption method with -NoPassword' {
        New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
            -NoPassword -RemoveSupportedBuilds -WarningAction SilentlyContinue | Out-Null

        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 0 -Exactly -ParameterFilter {
            @($ArgumentList | Where-Object { $_ -like '-p*' -or $_ -like '-mem=*' }).Count -gt 0
        }
        Should -Invoke Invoke-AtlasPackageVerifier -ModuleName AtlasBuild -Times 1 -Exactly -ParameterFilter { $NoPassword }
    }

    It 'names the archive with the .atlaspkg extension' {
        $result = New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas-v0.6.0' `
            -WarningAction SilentlyContinue

        $result | Should -BeExactly (Join-Path $output 'Atlas-v0.6.0.atlaspkg')
    }
}

Describe 'Atomic package publication' {
    BeforeEach {
        $package = Join-Path $TestDrive 'package'
        $output = Join-Path $TestDrive 'output'
        New-Item -ItemType Directory -Path $package, $output -Force | Out-Null
        '{ "schemaVersion": 1, "version": "0.6.0" }' |
            Set-Content -LiteralPath (Join-Path $package 'atlas.json') -Encoding UTF8
        Mock Resolve-SevenZip { 'mock-7z.exe' } -ModuleName AtlasBuild
        Mock Invoke-AtlasPackageVerifier { } -ModuleName AtlasBuild
    }

    It 'preserves the previous package when integrity verification of the sibling build fails' {
        $existingArchive = Join-Path $output 'Atlas.atlaspkg'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList
            if ($ErrorContext -eq 'Creating the package archive') {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
                return
            }
            if ($ErrorContext -eq 'Verifying the built package archive') {
                throw 'simulated integrity failure'
            }
        } -ModuleName AtlasBuild

        {
            New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceExisting
        } | Should -Throw -ExpectedMessage '*simulated integrity failure*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'preserves the previous package when semantic verification of the sibling build fails' {
        $existingArchive = Join-Path $output 'Atlas.atlaspkg'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
        Mock Invoke-AtlasPackageVerifier {
            throw 'simulated semantic verification failure'
        } -ModuleName AtlasBuild

        {
            New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceExisting
        } | Should -Throw -ExpectedMessage '*simulated semantic verification failure*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Should -Invoke Invoke-AtlasPackageVerifier -ModuleName AtlasBuild -Times 1 -Exactly
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'denies an attempted sibling change while semantic verification holds its file identity' {
        $existingArchive = Join-Path $output 'Atlas.atlaspkg'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList, $ErrorContext
            if ($ArchivePath) {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild
        Mock Invoke-AtlasPackageVerifier {
            param($Path, $PackagePath, [switch]$NoPassword)
            $null = $PackagePath, $NoPassword
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
            New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceExisting
        } | Should -Throw -ExpectedMessage '*mutation was blocked by semantic lock*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'preserves the previous package when handle hashes diverge across semantic verification' {
        $existingArchive = Join-Path $output 'Atlas.atlaspkg'
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
            New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceExisting
        } | Should -Throw -ExpectedMessage '*changed during semantic verification*'

        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](1, 2, 3, 4))
        Should -Invoke Invoke-AtlasPackageVerifier -ModuleName AtlasBuild -Times 1 -Exactly
        Get-ChildItem -LiteralPath $output -Filter '*.building.tmp*' |
            Should -BeNullOrEmpty
    }

    It 'rejects stale publication artifacts before invoking 7-Zip' {
        $stalePaths = @(
            Join-Path $output 'Atlas.atlaspkg.tmp'
            Join-Path $output 'Other.atlaspkg.0123456789abcdef0123456789abcdef.building.tmp'
        )
        foreach ($stalePath in $stalePaths) {
            [IO.File]::WriteAllBytes($stalePath, [byte[]](7, 7, 7, 7))
        }
        Mock Invoke-SevenZip {
            throw 'archive execution must remain unreachable'
        } -ModuleName AtlasBuild

        {
            New-AtlasPackage -PackagePath $package -OutputDirectory $output -FileName 'Atlas' `
                -NoPassword -ReplaceExisting
        } | Should -Throw -ExpectedMessage '*publication artifacts must be removed*'

        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 0 -Exactly
        foreach ($stalePath in $stalePaths) {
            $stalePath | Should -Exist
        }
        Remove-Item -LiteralPath $stalePaths -Force
    }

    It 'atomically publishes the verified sibling over the previous package' {
        $existingArchive = Join-Path $output 'Atlas.atlaspkg'
        [IO.File]::WriteAllBytes($existingArchive, [byte[]](1, 2, 3, 4))
        Mock Invoke-SevenZip {
            param($SevenZipPath, $ArgumentList, $ErrorContext, $ArchivePath)
            $null = $SevenZipPath, $ArgumentList
            if ($ErrorContext -eq 'Creating the package archive') {
                [IO.File]::WriteAllBytes($ArchivePath, [byte[]](9, 8, 7, 6))
            }
        } -ModuleName AtlasBuild

        $result = New-AtlasPackage -PackagePath $package -OutputDirectory $output `
            -FileName 'Atlas' -NoPassword -ReplaceExisting -WarningAction SilentlyContinue

        $result | Should -BeExactly $existingArchive
        [IO.File]::ReadAllBytes($existingArchive) | Should -Be ([byte[]](9, 8, 7, 6))
        Should -Invoke Invoke-SevenZip -ModuleName AtlasBuild -Times 1 -Exactly `
            -ParameterFilter { $ErrorContext -eq 'Verifying the built package archive' }
        Should -Invoke Invoke-AtlasPackageVerifier -ModuleName AtlasBuild -Times 1 -Exactly `
            -ParameterFilter {
                $Path -like '*.building.tmp' -and
                $PackagePath -eq $package -and
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
            $result = New-AtlasPackage -PackagePath $package -OutputDirectory $output `
                -FileName 'Provider' -NoPassword -WarningAction SilentlyContinue

            $result | Should -BeExactly (Join-Path $output 'Provider.atlaspkg')
            [IO.File]::ReadAllBytes($result) | Should -Be ([byte[]](9, 8, 7, 6))
            (Get-Location).Provider.Name | Should -BeExactly 'Function'
        }
        finally {
            Set-Location -LiteralPath $originalLocation.Path
        }
    }

    It 'refuses to publish a different file object than the verified content' `
        -Skip:(-not $IsWindows) {
        $source = Join-Path $output 'Atlas.atlaspkg.bound.building.tmp'
        $destination = Join-Path $output 'Atlas.atlaspkg'
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

Describe 'Package file path contracts' {
    It 'enumerates every source file except built packages' {
        $package = Join-Path $TestDrive 'package'
        New-Item -Path (Join-Path $package 'Images') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $package 'Executables\Nested') -ItemType Directory -Force | Out-Null
        '{}' | Set-Content -Path (Join-Path $package 'atlas.json') -Encoding UTF8
        'image' | Set-Content -Path (Join-Path $package 'Images\browser.png') -Encoding UTF8
        'script' | Set-Content -Path (Join-Path $package 'Executables\Nested\tool.txt') -Encoding UTF8
        'generated' | Set-Content -Path (Join-Path $package 'Atlas Test.atlaspkg') -Encoding UTF8
        'interrupted' | Set-Content -Path (Join-Path $package 'Atlas Test.atlaspkg.tmp') -Encoding UTF8
        'building' | Set-Content -Path `
            (Join-Path $package 'Atlas Test.atlaspkg.0123456789abcdef0123456789abcdef.building.tmp') `
            -Encoding UTF8

        @(Get-AtlasPackageFilePath -PackagePath $package) | Should -Be @(
            'atlas.json'
            'Executables/Nested/tool.txt'
            'Images/browser.png'
        )
    }

    It 'refuses a folder without atlas.json' {
        $folder = Join-Path $TestDrive 'not-a-package'
        New-Item -Path $folder -ItemType Directory -Force | Out-Null

        { Get-AtlasPackageFilePath -PackagePath $folder } | Should -Throw '*atlas.json not found*'
    }

    It 'reports missing, unexpected, and duplicate archive paths independently' {
        $result = Compare-AtlasPackageFilePath `
            -ExpectedPath @('Images/browser.png', 'Executables/tool.ps1') `
            -ActualPath @('Images\browser.png', 'Executables/stale.ps1', 'Executables/stale.ps1')

        $result.Matches | Should -BeFalse
        $result.Missing | Should -Be @('Executables/tool.ps1')
        $result.Unexpected | Should -Be @('Executables/stale.ps1')
        $result.Duplicates | Should -Be @('Executables/stale.ps1')
    }

    It 'treats path casing as part of the archive contract' {
        $result = Compare-AtlasPackageFilePath `
            -ExpectedPath @('Executables/AtlasModules/Tool.ps1') `
            -ActualPath @('Executables/atlasmodules/Tool.ps1')

        $result.Matches | Should -BeFalse
        $result.Missing.Count | Should -Be 1
        $result.Unexpected.Count | Should -Be 1
    }
}

Describe 'Package verifier' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath

        # Runs Test-Package.ps1 against a stand-in 7-Zip that prints the given listing records.
        function Invoke-VerifierWithListing {
            param(
                [Parameter(Mandatory = $true)][string[]]$Record,
                [switch]$NoPassword
            )
            $fakeBin = Join-Path $TestDrive "fake-bin-$([guid]::NewGuid().ToString('N'))"
            $package = Join-Path $TestDrive "package-$([guid]::NewGuid().ToString('N'))"
            New-Item -ItemType Directory -Path $fakeBin, $package -Force | Out-Null
            '{}' | Set-Content -LiteralPath (Join-Path $package 'atlas.json') -Encoding UTF8
            $archive = Join-Path $TestDrive 'unsafe.atlaspkg'
            [IO.File]::WriteAllBytes($archive, [byte[]](1))
            $logPath = Join-Path $fakeBin 'fake-7z.log'
            @(
                '@echo off'
                '>>"%ATLAS_FAKE_7Z_LOG%" echo %*'
                'if /i "%~1"=="l" ('
                $Record
                ')'
                'exit /b 0'
            ) | Set-Content -LiteralPath (Join-Path $fakeBin '7z.cmd') -Encoding Ascii

            $oldPath = $env:PATH
            $oldLog = $env:ATLAS_FAKE_7Z_LOG
            try {
                $env:PATH = "$fakeBin$([IO.Path]::PathSeparator)$oldPath"
                $env:ATLAS_FAKE_7Z_LOG = $logPath
                $pwshPath = (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source
                $verifierArguments = @('-Path', $archive, '-PackagePath', $package)
                if ($NoPassword) { $verifierArguments += '-NoPassword' }
                $output = & $pwshPath -NoLogo -NoProfile -File `
                    (Join-Path $script:RepoRoot 'tools\build\Test-Package.ps1') @verifierArguments 2>&1
                $exitCode = $LASTEXITCODE
            }
            finally {
                $env:PATH = $oldPath
                $env:ATLAS_FAKE_7Z_LOG = $oldLog
            }
            [pscustomobject]@{
                ExitCode = $exitCode
                Output   = $output -join "`n"
                Calls    = (Get-Content -LiteralPath $logPath) -join "`n"
            }
        }

        function New-ListingRecord {
            param([string]$Path, [string]$Folder = '-', [string]$Encrypted, [string]$Method)
            "  echo Path = $Path"
            "  echo Folder = $Folder"
            if ($Encrypted) { "  echo Encrypted = $Encrypted" }
            if ($Method) { "  echo Method = $Method" }
            '  echo.'
        }
    }

    # The listed files match the source, so only the directory record can block extraction.
    It 'never invokes 7-Zip extraction after <Case> is listed' -ForEach @(
        @{ Case = 'a parent-traversal directory'; Directories = @('../outside'); Failure = 'rooted or parent-traversal paths: \.\./outside' }
        @{ Case = 'a rooted directory'; Directories = @('C:/outside'); Failure = 'rooted or parent-traversal paths: C:/outside' }
        @{ Case = 'a duplicate directory'; Directories = @('Images', 'Images'); Failure = 'duplicate entry paths: Images' }
    ) -Skip:(-not $IsWindows) {
        $records = @(New-ListingRecord -Path 'atlas.json' -Encrypted '+' -Method 'AES-256 Deflate')
        foreach ($directory in $Directories) {
            $records += New-ListingRecord -Path $directory -Folder '+'
        }

        $result = Invoke-VerifierWithListing -Record $records

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'PASS: Exact source/archive file path parity'
        $result.Output | Should -Match 'PASS: Every file is encrypted with AES-256'
        $result.Output | Should -Match $Failure
        $result.Output | Should -Match 'Archive extraction was blocked'
        $result.Calls | Should -Match '(?m)^t\s'
        $result.Calls | Should -Match '(?m)^l\s'
        $result.Calls | Should -Not -Match '(?m)^[ex](?:\s|$)'
    }

    It 'fails <Case>' -ForEach @(
        @{ Case = 'a file without encryption'; Encrypted = '-'; Method = 'Deflate'; NoPassword = $false; Failure = 'Files not encrypted with AES-256: atlas.json' }
        @{ Case = 'a file under legacy ZipCrypto'; Encrypted = '+'; Method = 'ZipCrypto Deflate'; NoPassword = $false; Failure = 'Files not encrypted with AES-256: atlas.json' }
        @{ Case = 'an encrypted file in a -NoPassword build'; Encrypted = '+'; Method = 'AES-256 Deflate'; NoPassword = $true; Failure = 'Encrypted files in an archive expected without a password: atlas.json' }
    ) -Skip:(-not $IsWindows) {
        $result = Invoke-VerifierWithListing -Record (New-ListingRecord -Path 'atlas.json' -Encrypted $Encrypted -Method $Method) `
            -NoPassword:$NoPassword

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match ([regex]::Escape("FAIL: $Failure"))
    }

    It 'always passes the password, so 7-Zip never waits for one on the console' -Skip:(-not $IsWindows) {
        $result = Invoke-VerifierWithListing -Record (New-ListingRecord -Path 'atlas.json' -Encrypted '-' -Method 'Deflate') -NoPassword

        $result.Output | Should -Match 'PASS: No file is encrypted'
        foreach ($call in ($result.Calls -split "`n")) {
            $call | Should -Match ([regex]::Escape("-p$(Get-AtlasPackagePassword)"))
        }
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
'@ | Set-Content -LiteralPath (Join-Path $toolsDir 'Build-Package.ps1') -Encoding UTF8

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
        $capture | Should -Match ([regex]::Escape((Join-Path $toolsDir 'Build-Package.ps1')))
        $capture | Should -Match '\|-LocalTest\s*$'
    }

}

Describe 'A release candidate''s bundled Toolbox' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $script:AddBundledToolbox = Join-Path $repoRoot 'tools\release\Add-BundledToolbox.ps1'
        $script:CheckoutPackage = Join-Path $repoRoot 'package'
        . (Join-Path $repoRoot 'package\Executables\AtlasModules\Scripts\Operations\Toolbox-Package.ps1')
    }

    It 'adds an installer and manifest that Atlas installs from' {
        $package = Join-Path $TestDrive 'staged\package'
        New-Item -Path $package -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $package 'atlas.json') -Value '{}'
        $installer = Join-Path $TestDrive 'AtlasToolbox-Setup.exe'
        [IO.File]::WriteAllBytes($installer, [byte[]](1, 2, 3, 4))

        & $script:AddBundledToolbox -PackagePath $package -Installer $installer -Version '0.2.0' 6>$null

        $bundled = Get-AtlasBundledToolbox -Root (Join-Path $package 'Executables\AtlasModules\Bundled\Toolbox')
        $bundled.Version | Should -BeExactly '0.2.0'
        $bundled.Size | Should -Be 4
        $bundled.Sha256 | Should -BeExactly (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash
        [IO.File]::ReadAllBytes($bundled.Path) | Should -Be ([byte[]](1, 2, 3, 4))
    }

    It "refuses the checkout's own package folder, which releases build from" {
        $installer = Join-Path $TestDrive 'AtlasToolbox-Setup.exe'
        [IO.File]::WriteAllBytes($installer, [byte[]](1))
        { & $script:AddBundledToolbox -PackagePath $script:CheckoutPackage -Installer $installer -Version '0.2.0' } |
            Should -Throw '*staged copy*'
        Join-Path $script:CheckoutPackage 'Executables\AtlasModules\Bundled' | Should -Not -Exist
    }
}

Describe 'Package version coherence' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $script:setVersionScript = Join-Path $script:repoRoot 'tools\build\Set-AtlasVersion.ps1'
        $script:committedManifest = Join-Path $script:repoRoot 'package\atlas.json'

        function Get-ManifestVersion {
            param([Parameter(Mandatory = $true)][string]$Path)
            ([IO.File]::ReadAllText($Path) | ConvertFrom-Json).version
        }

        function Get-UpdateSource {
            param([Parameter(Mandatory = $true)][string]$Path)
            @(([IO.File]::ReadAllText($Path) | ConvertFrom-Json).updatableFrom)
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

        # Laid out like the repository, so the script finds the app files from the manifest
        # path and never falls back to the real ones.
        function New-VersionFixture {
            param(
                [Parameter(Mandatory = $true)][string]$Name,
                [AllowEmptyCollection()][string[]]$UpdatableFrom = @(),
                [string]$AppVersion = '0.6.0'
            )
            $fixture = Join-Path $TestDrive $Name
            New-Item -Path (Join-Path $fixture 'package'), (Join-Path $fixture 'app') `
                -ItemType Directory -Force | Out-Null
            $manifest = Join-Path $fixture 'package\atlas.json'
            $sources = (@($UpdatableFrom) | ForEach-Object { "`"$_`"" }) -join ', '
            [IO.File]::WriteAllText($manifest,
                "{`n  `"schemaVersion`": 1,`n  `"version`": `"0.6.0`",`n  `"updatableFrom`": [$sources]`n}`n")
            [IO.File]::WriteAllText((Join-Path $fixture 'app\Cargo.toml'),
                "[package]`nname = `"atlas-app`"`nversion = `"$AppVersion`"`n")
            [IO.File]::WriteAllText((Join-Path $fixture 'app\Cargo.lock'), (New-CargoLockFixture -AppVersion $AppVersion))
            $manifest
        }
    }

    It 'keeps the app/Cargo.toml package version equal to the atlas.json version' {
        Get-CargoPackageVersion -Path (Join-Path $script:repoRoot 'app\Cargo.toml') |
            Should -BeExactly (Get-ManifestVersion -Path $script:committedManifest) `
                -Because 'Set-AtlasVersion.ps1 must keep the app at the released version'
    }

    It 'bumps the committed atlas.json and app version and appends the superseded version' {
        $fixture = Join-Path $TestDrive 'version-fixture'
        New-Item -Path (Join-Path $fixture 'package'), (Join-Path $fixture 'app') -ItemType Directory -Force | Out-Null
        $manifest = Join-Path $fixture 'package\atlas.json'
        $cargoToml = Join-Path $fixture 'app\Cargo.toml'
        $cargoLock = Join-Path $fixture 'app\Cargo.lock'
        Copy-Item -LiteralPath $script:committedManifest -Destination $manifest
        Copy-Item -LiteralPath (Join-Path $script:repoRoot 'app\Cargo.toml') -Destination $cargoToml
        [IO.File]::WriteAllText($cargoLock, (New-CargoLockFixture))

        $originalVersion = Get-ManifestVersion -Path $manifest
        $originalSources = @(Get-UpdateSource -Path $manifest)
        $originalSources.Count | Should -BeGreaterThan 0
        $originalManagerVersion = ([IO.File]::ReadAllText($manifest) | ConvertFrom-Json).minimumManagerVersion
        $originalManagerVersion | Should -Not -BeNullOrEmpty
        $originalLines = [IO.File]::ReadAllLines($manifest)
        $originalManifest = [IO.File]::ReadAllLines($cargoToml)
        $bumpVersion = '9.9.9'

        & $script:setVersionScript -Version $bumpVersion -ManifestPath $manifest | Out-Null
        Get-ManifestVersion -Path $manifest | Should -Be $bumpVersion
        (Get-UpdateSource -Path $manifest) -join ',' |
            Should -BeExactly ((@($originalSources) + $originalVersion) -join ',')

        # Only the version line changes and one source line is added; the rest keeps its layout.
        $lines = [IO.File]::ReadAllLines($manifest)
        $lines.Count | Should -Be ($originalLines.Count + 1)
        @(Compare-Object -ReferenceObject $originalLines -DifferenceObject $lines -CaseSensitive |
                ForEach-Object { "$($_.SideIndicator)$($_.InputObject.Trim())" } | Sort-Object) -join '|' |
            Should -BeExactly ((@(
                        "<=`"version`": `"$originalVersion`","
                        "=>`"$originalVersion`""
                        "=>`"$($originalSources[-1])`","
                        "<=`"$($originalSources[-1])`""
                        "=>`"version`": `"$bumpVersion`","
                    ) | Sort-Object) -join '|')
        # minimumManagerVersion changes only when a package needs a newer Atlas Manager.
        ([IO.File]::ReadAllText($manifest) | ConvertFrom-Json).minimumManagerVersion |
            Should -BeExactly $originalManagerVersion
        @(Test-AtlasManifest -Path $manifest) | Should -BeNullOrEmpty

        # Only the [package] version line changes; dependency versions stay as they are.
        Get-CargoPackageVersion -Path $cargoToml | Should -BeExactly $bumpVersion
        $cargoLines = [IO.File]::ReadAllLines($cargoToml)
        $cargoLines.Count | Should -Be $originalManifest.Count
        $changedLines = @(for ($index = 0; $index -lt $cargoLines.Count; $index++) {
                if ($cargoLines[$index] -cne $originalManifest[$index]) { $cargoLines[$index] }
            })
        $changedLines -join '|' | Should -BeExactly "version = `"$bumpVersion`""
        Get-CargoLockVersion -Path $cargoLock -Name 'atlas-app' | Should -BeExactly $bumpVersion
        Get-CargoLockVersion -Path $cargoLock -Name 'anyhow' | Should -BeExactly '1.0.0'
    }

    It 'leaves updatableFrom as <Expected> for <Case>' -ForEach @(
        @{ Case = 'no sources'; Sources = @(); Version = '0.7.0'; Expected = '0.6.0' }
        @{ Case = 'a list that already has the superseded version'; Sources = @('0.5.0', '0.6.0'); Version = '0.7.0'; Expected = '0.5.0,0.6.0' }
        @{ Case = 'a bump to the current version'; Sources = @('0.5.0'); Version = '0.6.0'; Expected = '0.5.0' }
    ) {
        $manifest = New-VersionFixture -Name ($Case -replace '\W', '-') -UpdatableFrom $Sources
        $fixture = Split-Path (Split-Path $manifest -Parent) -Parent

        & $script:setVersionScript -Version $Version -ManifestPath $manifest -WarningAction SilentlyContinue | Out-Null
        Get-ManifestVersion -Path $manifest | Should -Be $Version
        (Get-UpdateSource -Path $manifest) -join ',' | Should -BeExactly $Expected
        Get-CargoPackageVersion -Path (Join-Path $fixture 'app\Cargo.toml') | Should -BeExactly $Version
        Get-CargoLockVersion -Path (Join-Path $fixture 'app\Cargo.lock') -Name 'atlas-app' | Should -BeExactly $Version
    }

    It 'brings drifted app files in line when atlas.json already has the version' {
        $manifest = New-VersionFixture -Name 'drifted-app' -UpdatableFrom '0.5.0' -AppVersion '0.5.9'
        $app = Join-Path (Split-Path (Split-Path $manifest -Parent) -Parent) 'app'
        $originalManifest = [Convert]::ToBase64String([IO.File]::ReadAllBytes($manifest))

        & $script:setVersionScript -Version '0.6.0' -ManifestPath $manifest -WarningAction SilentlyContinue | Out-Null
        Get-CargoPackageVersion -Path (Join-Path $app 'Cargo.toml') | Should -BeExactly '0.6.0'
        Get-CargoLockVersion -Path (Join-Path $app 'Cargo.lock') -Name 'atlas-app' | Should -BeExactly '0.6.0'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($manifest)) | Should -BeExactly $originalManifest
    }

    It 'leaves every file byte-identical when they all already have the version' {
        $manifest = New-VersionFixture -Name 'already-current' -UpdatableFrom '0.5.0'
        $fixture = Split-Path (Split-Path $manifest -Parent) -Parent
        $files = @(Get-ChildItem -LiteralPath $fixture -Recurse -File -Force)
        $before = @($files | ForEach-Object { [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName)) })
        $files.Count | Should -Be 3

        & $script:setVersionScript -Version '0.6.0' -ManifestPath $manifest -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        @($files | ForEach-Object { [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName)) }) | Should -Be $before
        @($warnings) -join '|' | Should -BeLike '*nothing to do*'
    }

    It 'changes nothing when <Case>' -ForEach @(
        @{ Case = 'the version lacks a number'; Version = '0.7'; LockText = $null; Message = "*parameter 'Version'*" }
        @{ Case = 'Cargo.lock has no atlas-app entry'; Version = '0.7.0'; LockText = "version = 4`n"; Message = '*atlas-app entry*' }
    ) {
        $manifest = New-VersionFixture -Name ($Case -replace '\W', '-') -UpdatableFrom '0.5.0'
        $fixture = Split-Path (Split-Path $manifest -Parent) -Parent
        $app = Join-Path $fixture 'app'
        if ($LockText) { [IO.File]::WriteAllText((Join-Path $app 'Cargo.lock'), $LockText) }

        { & $script:setVersionScript -Version $Version -ManifestPath $manifest } |
            Should -Throw -ExpectedMessage $Message
        Get-ManifestVersion -Path $manifest | Should -Be '0.6.0'
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
