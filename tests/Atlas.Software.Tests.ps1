BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    function New-AtlasTestNanaZipBundle {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [string]$Name = '40174MouriNaruto.NanaZip',
            [string]$Publisher = 'CN=E310A153-74A9-4D81-800B-857A8D58408A',
            [string]$Version = '6.5.1767.0'
        )

        Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
        $file = [IO.File]::Open($Path, [IO.FileMode]::CreateNew)
        $archive = New-Object IO.Compression.ZipArchive(
            $file,
            [IO.Compression.ZipArchiveMode]::Create,
            $false
        )
        try {
            $entry = $archive.CreateEntry('AppxMetadata/AppxBundleManifest.xml')
            $entryStream = $entry.Open()
            $writer = New-Object IO.StreamWriter(
                $entryStream,
                (New-Object Text.UTF8Encoding($false))
            )
            try {
                $writer.Write(
                    '<?xml version="1.0" encoding="utf-8"?>' +
                    '<Bundle xmlns="http://schemas.microsoft.com/appx/2013/bundle">' +
                    '<Identity Name="' + $Name + '" Publisher="' + $Publisher +
                    '" Version="' + $Version + '" />' +
                    '</Bundle>'
                )
            }
            finally {
                $writer.Dispose()
                $entryStream.Dispose()
            }
        }
        finally {
            $archive.Dispose()
            $file.Dispose()
        }
    }

    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Software\Atlas.Software.psd1') -Force
}

Describe 'Official archive-app mirrors' {
    It 'downloads each pinned NanaZip asset from its SourceForge mirror when GitHub fails' {
        $temp = Join-Path -Path $TestDrive -ChildPath 'nanazip-pinned-mirror'
        New-Item -Path $temp -ItemType Directory | Out-Null
        InModuleScope Atlas.Software -Parameters @{ Temp = $temp } {
            param($Temp)
            $assets = @(Get-AtlasPinnedNanaZipReleaseAssets)
            $assets.Count | Should -Be 2
            $tag = [string]$assets[0].Tag
            foreach ($asset in $assets) {
                $asset.Sha256 | Should -Match '^[0-9a-f]{64}$'
                $asset.Size | Should -BeGreaterThan 0
            }
            $commands = [pscustomobject]@{
                GetProvisionedPackage = {
                    [pscustomobject]@{ DisplayName = '40174MouriNaruto.NanaZip'; Version = $tag }
                }.GetNewClosure()
                AddProvisionedPackage = { }
            }
            # Keeps the test off the network if a GitHub API lookup is reintroduced.
            Mock Invoke-AtlasGitHubApiJson { throw 'GitHub is unavailable' }
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Assert-AtlasNanaZipBundleIdentity
            Mock Write-AtlasLog
            Mock Invoke-AtlasPinnedDownload {
                if ($Uri.Host -eq 'github.com') { throw 'HTTP 403' }
                $Destination
            }

            Install-AtlasNanaZip -TempDir $Temp -Assets $assets -DismCommands $commands | Should -BeTrue

            Should -Invoke Invoke-AtlasPinnedDownload -Times 4 -Exactly
            foreach ($asset in $assets) {
                foreach ($expectedUri in @(
                        "https://github.com/M2Team/NanaZip/releases/download/$tag/$($asset.Name)"
                        "https://downloads.sourceforge.net/project/nanazip/$tag/$($asset.Name)"
                    )) {
                    Should -Invoke Invoke-AtlasPinnedDownload -Times 1 -Exactly -ParameterFilter {
                        $Uri.AbsoluteUri -ceq $expectedUri -and
                        $Sha256 -ceq $asset.Sha256 -and
                        $ExpectedBytes -eq $asset.Size
                    }
                }
            }
        }
    }
}

Describe 'Archive download failover' {
    It 'uses only GitHub when the first verified download succeeds' {
        InModuleScope Atlas.Software -Parameters @{ Destination = (Join-Path $TestDrive 'success.exe') } {
            Mock Write-AtlasLog {}
            Mock Invoke-AtlasPinnedDownload { $Destination }
            Invoke-AtlasArchiveDownload -Uris @('https://github.com/a', 'https://downloads.sourceforge.net/a') -Destination $Destination -Sha256 ('a' * 64) -ExpectedBytes 42 | Should -Be $Destination
            Should -Invoke Invoke-AtlasPinnedDownload -Times 1 -Exactly -ParameterFilter { $Uri.Host -eq 'github.com' }
        }
    }

    It 'tries the mirror with identical verification after GitHub fails' {
        InModuleScope Atlas.Software -Parameters @{ Destination = (Join-Path $TestDrive 'fallback.exe') } {
            Mock Write-AtlasLog {}
            Mock Invoke-AtlasPinnedDownload {
                if ($Uri.Host -eq 'github.com') { throw 'HTTP 403' }
                $Destination
            }
            Invoke-AtlasArchiveDownload -Uris @('https://github.com/a', 'https://downloads.sourceforge.net/a') -Destination $Destination -Sha256 ('a' * 64) -ExpectedBytes 42 | Should -Be $Destination
            Should -Invoke Invoke-AtlasPinnedDownload -Times 2 -Exactly -ParameterFilter { $Sha256 -eq ('a' * 64) -and $ExpectedBytes -eq 42 -and $MaximumSeconds -eq 60 }
            Should -Invoke Invoke-AtlasPinnedDownload -Times 1 -Exactly -ParameterFilter { $Uri.Host -eq 'downloads.sourceforge.net' }
        }
    }

    It 'reports both sources when neither passes verification' {
        InModuleScope Atlas.Software -Parameters @{ Destination = (Join-Path $TestDrive 'failure.exe') } {
            Mock Write-AtlasLog {}
            Mock Invoke-AtlasPinnedDownload { throw 'SHA-256 mismatch' }
            { Invoke-AtlasArchiveDownload -Uris @('https://github.com/a', 'https://downloads.sourceforge.net/a') -Destination $Destination -Sha256 ('a' * 64) -ExpectedBytes 42 } | Should -Throw '*github.com*sourceforge.net*'
        }
    }

    It 'gives each source a limit that grows with the asset size' {
        InModuleScope Atlas.Software -Parameters @{ Destination = (Join-Path $TestDrive 'bundle.msixbundle') } {
            Mock Write-AtlasLog {}
            Mock Invoke-AtlasPinnedDownload { $Destination }
            Invoke-AtlasArchiveDownload -Uris @('https://github.com/a') -Destination $Destination -Sha256 ('a' * 64) -ExpectedBytes 11931446 | Should -Be $Destination
            Should -Invoke Invoke-AtlasPinnedDownload -Times 1 -Exactly -ParameterFilter { $MaximumSeconds -eq 365 }
        }
    }

    It 'names the time limit when a source is too slow' {
        InModuleScope Atlas.Software -Parameters @{ Destination = (Join-Path $TestDrive 'slow.msixbundle') } {
            Mock Write-AtlasLog {}
            Mock Invoke-AtlasPinnedDownload {
                # The shape the shared HTTP reader throws when its deadline cancels a read.
                $deadline = New-Object Threading.CancellationTokenSource
                $deadline.Cancel()
                [Threading.Tasks.Task]::Delay(1000, $deadline.Token).GetAwaiter().GetResult()
            }
            { Invoke-AtlasArchiveDownload -Uris @('https://github.com/a', 'https://downloads.sourceforge.net/a') -Destination $Destination -Sha256 ('a' * 64) -ExpectedBytes 11931446 } |
                Should -Throw "*github.com/a : the download didn't finish within its 365-second limit.*sourceforge.net/a : the download didn't finish*"
        }
    }
}

Describe 'Visual C++ v14 prerequisite detection' {
    BeforeEach {
        InModuleScope Atlas.Software {
            Mock Write-AtlasLog {}
            Mock Get-Item { [pscustomobject]@{ VersionInfo = [pscustomobject]@{ ProductVersion = '14.44.35211.0' } } }
            Mock Get-ItemProperty { throw 'No runtime registration' }
        }
    }

    It 'accepts an installed equal or newer <Architecture> runtime <Version>' -TestCases @(
        @{ Architecture = 'x64'; Version = 'v14.51.36247.0' }
        @{ Architecture = 'x86'; Version = 'v14.51.36231.0' }
        @{ Architecture = 'x64'; Version = 'v14.44.35211.0' }
    ) {
        param($Architecture, $Version)
        InModuleScope Atlas.Software -Parameters @{ Architecture = $Architecture; Version = $Version } {
            Mock Get-ItemProperty { [pscustomobject]@{ Installed = 1; Version = $Version } } -ParameterFilter {
                $LiteralPath -eq "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\$Architecture"
            }
            Test-AtlasVisualCppRuntimeCurrent -Architecture $Architecture -InstallerPath 'fixture.exe' | Should -BeTrue
        }
    }

    It 'does not skip for an older, malformed, unrelated, or uninstalled runtime (<Version>, <Installed>)' -TestCases @(
        @{ Version = 'v14.43.34808.0'; Installed = 1 }
        @{ Version = 'invalid'; Installed = 1 }
        @{ Version = 'v15.0.0.0'; Installed = 1 }
        @{ Version = 'v14.51.36247.0'; Installed = 0 }
    ) {
        param($Version, $Installed)
        InModuleScope Atlas.Software -Parameters @{ Version = $Version; Installed = $Installed } {
            Mock Get-ItemProperty { [pscustomobject]@{ Installed = $Installed; Version = $Version } }
            Test-AtlasVisualCppRuntimeCurrent -Architecture x64 -InstallerPath 'fixture.exe' | Should -BeFalse
        }
    }

    It 'does not use x64 registration to satisfy x86' {
        InModuleScope Atlas.Software {
            Mock Get-ItemProperty { [pscustomobject]@{ Installed = 1; Version = 'v14.51.36247.0' } } -ParameterFilter { $LiteralPath -like '*\x64' }
            Test-AtlasVisualCppRuntimeCurrent -Architecture x86 -InstallerPath 'fixture.exe' | Should -BeFalse
        }
    }

    It 'falls back to installation when registration is missing or unreadable' {
        InModuleScope Atlas.Software {
            Test-AtlasVisualCppRuntimeCurrent -Architecture x64 -InstallerPath 'fixture.exe' | Should -BeFalse
        }
    }

    It 'falls back to installation when package metadata cannot be parsed' {
        InModuleScope Atlas.Software {
            Mock Get-Item { [pscustomobject]@{ VersionInfo = [pscustomobject]@{ ProductVersion = '' } } }
            Test-AtlasVisualCppRuntimeCurrent -Architecture x64 -InstallerPath 'fixture.exe' | Should -BeFalse
        }
    }
}

Describe 'Select-AtlasCbsPackage' {
    It 'matches CABs by pattern and architecture' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'C:\Packages\Z-Atlas-NoTelemetry-Package-arm64-1.cab'
                'C:\Packages\Z-Atlas-NoTelemetry-Package-amd64-1.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-1.cab'
            )
            $patterns = @('*Z-Atlas-NoDefender-Package*', '*Z-Atlas-NoTelemetry-Package*')

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns $patterns -Architecture 'amd64' -SingleUsePatterns

            $result.Matched | Should -Be @(
                'C:\Packages\Z-Atlas-NoTelemetry-Package-amd64-1.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-1.cab'
            )
            @($result.UnmatchedPatterns).Count | Should -Be 0
        }
    }

    It 'reports patterns that matched nothing for <Architecture>' -TestCases @(
        @{ Architecture = 'arm64'; Matched = @('C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab'); Unmatched = @('*Z-Atlas-NoTelemetry-Package*') }
        @{ Architecture = 'amd64'; Matched = @(); Unmatched = @('*Z-Atlas-NoDefender-Package*', '*Z-Atlas-NoTelemetry-Package*') }
    ) {
        $result = InModuleScope Atlas.Software -Parameters @{ Architecture = $Architecture } {
            Select-AtlasCbsPackage -Candidates @('C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab') `
                -Patterns @('*Z-Atlas-NoDefender-Package*', '*Z-Atlas-NoTelemetry-Package*') `
                -Architecture $Architecture -SingleUsePatterns
        }

        @($result.Matched) -join ',' | Should -BeExactly ($Matched -join ',')
        @($result.UnmatchedPatterns) -join ',' | Should -BeExactly ($Unmatched -join ',')
    }

    It 'consumes each pattern on its first match with -SingleUsePatterns (CAB install semantics)' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-2.cab'
                'C:\Packages\Z-Atlas-NoDefender-Package-amd64-1.cab'
            )

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns @('*Z-Atlas-NoDefender-Package*') -Architecture 'amd64' -SingleUsePatterns

            $result.Matched | Should -Be @('C:\Packages\Z-Atlas-NoDefender-Package-amd64-2.cab')
        }
    }

    It 'lets one pattern match multiple candidates without -SingleUsePatterns (uninstall semantics)' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'Z-Atlas-NoDefender-Package~amd64~~1.0.0.0'
                'Z-Atlas-NoDefender-Package~amd64~~2.0.0.0'
            )

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns @('*Z-Atlas-NoDefender-Package*') -Architecture 'amd64'

            @($result.Matched).Count | Should -Be 2
            @($result.UnmatchedPatterns).Count | Should -Be 0
        }
    }
}

Describe 'Get-AtlasSoftwareComponentMap' {
    It 'maps every Install-AtlasSoftware component to an existing installer function' {
        InModuleScope Atlas.Software {
            $map = Get-AtlasSoftwareComponentMap
            $components = (Get-Command -Name Install-AtlasSoftware).Parameters['Component'].Attributes |
                Where-Object { $_ -is [Management.Automation.ValidateSetAttribute] } |
                ForEach-Object { $_.ValidValues }

            @($map.Keys | Sort-Object) | Should -Be @($components | Sort-Object)
            foreach ($function in $map.Values) {
                Get-Command -Name $function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Install-AtlasEclean' {
    It 'does not start the installer when publisher verification fails' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasSoftwareDownload
            Mock Assert-AtlasFileSignature { throw 'publisher verification failed' }
            Mock Start-AtlasSoftwareInstaller

            { Install-AtlasEclean -TempDir $TestDrive } | Should -Throw '*publisher verification failed*'
            Should -Invoke Start-AtlasSoftwareInstaller -Times 0
        }
    }

    It 'verifies the eclean publisher and installs silently' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasSoftwareDownload
            Mock Assert-AtlasFileSignature
            Mock Start-AtlasSoftwareInstaller

            Install-AtlasEclean -TempDir $TestDrive

            Should -Invoke Assert-AtlasFileSignature -Times 1 -Exactly -ParameterFilter {
                $ExpectedSubjectCn -ceq 'eclean Labs AB'
            }
            Should -Invoke Start-AtlasSoftwareInstaller -Times 1 -Exactly -ParameterFilter {
                $ArgumentList.Count -eq 1 -and $ArgumentList[0] -ceq '/S'
            }
        }
    }
}

Describe 'Test-AtlasSoftwareArm64' {
    It 'recognizes exactly one native <SystemType> computer-system result' -TestCases @(
        @{ SystemType = 'ARM64-based PC'; Expected = $true }
        @{ SystemType = 'x64-based PC'; Expected = $false }
    ) {
        InModuleScope Atlas.Software -Parameters @{ SystemType = $SystemType; Expected = $Expected } {
            Mock Get-CimInstance {
                [pscustomobject]@{ SystemType = $SystemType }
            }

            Test-AtlasSoftwareArm64 | Should -Be $Expected
            Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
                $ClassName -ceq 'Win32_ComputerSystem' -and $ErrorAction -eq 'Stop'
            }
        }
    }

    It 'fails closed for an unknown or empty native architecture value' {
        InModuleScope Atlas.Software {
            Mock Get-CimInstance {
                [pscustomobject]@{ SystemType = 'Unknown' }
            }
            { Test-AtlasSoftwareArm64 } | Should -Throw -ExpectedMessage '*Unsupported or unreadable*'

            Mock Get-CimInstance {
                [pscustomobject]@{ SystemType = $null }
            }
            { Test-AtlasSoftwareArm64 } | Should -Throw -ExpectedMessage '*Unsupported or unreadable*'
        }
    }
}

Describe 'Get-AtlasCbsArchitecture' {
    It 'uses the exact module architecture authority for <Expected> CBS packages' -TestCases @(
        @{ IsArm64 = $true; Expected = 'arm64' }
        @{ IsArm64 = $false; Expected = 'amd64' }
    ) {
        InModuleScope Atlas.Software -Parameters @{ IsArm64 = $IsArm64; Expected = $Expected } {
            Mock Test-AtlasSoftwareArm64 { $IsArm64 }

            Get-AtlasCbsArchitecture | Should -BeExactly $Expected
            Should -Invoke Test-AtlasSoftwareArm64 -Times 1 -Exactly
        }
    }
}

Describe 'Install-AtlasSoftware' {
    It 'returns false when protected staging cleanup fails instead of reporting success' {
        InModuleScope Atlas.Software -Parameters @{ Root = $TestDrive } {
            $stage = Join-Path -Path $Root -ChildPath 'cleanup-failure'
            New-Item -Path $stage -ItemType Directory | Out-Null
            Mock Assert-AtlasPrivilege
            Mock New-AtlasProtectedStagingDirectory { $stage }
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Install-AtlasBraveBrowser
            Mock Remove-Item -ParameterFilter { $LiteralPath -eq $stage } -MockWith {
                throw 'simulated cleanup failure'
            }
            Mock Write-AtlasLog

            Install-AtlasSoftware -Component Brave | Should -BeFalse
            Test-Path -LiteralPath $stage | Should -BeTrue
            Should -Invoke Write-AtlasLog -Times 1 -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*staging cleanup failed*'
            }
        }
    }

    It 'retains staging when installer process-tree containment is unconfirmed' {
        InModuleScope Atlas.Software -Parameters @{ Root = $TestDrive } {
            $stage = Join-Path -Path $Root -ChildPath 'unconfirmed-containment'
            New-Item -Path $stage -ItemType Directory | Out-Null
            Mock Assert-AtlasPrivilege
            Mock New-AtlasProtectedStagingDirectory { $stage }
            Mock Install-AtlasBraveBrowser { throw 'simulated containment failure' }
            Mock Test-AtlasContainedProcessContainmentUnconfirmed { $true }
            Mock Remove-Item
            Mock Write-AtlasLog

            Install-AtlasSoftware -Component Brave | Should -BeFalse
            Test-Path -LiteralPath $stage | Should -BeTrue
            Should -Invoke Remove-Item -Times 0 -ParameterFilter { $LiteralPath -eq $stage }
            Should -Invoke Write-AtlasLog -Times 1 -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*staging was retained*'
            }
        }
    }

    It 'returns exactly one Boolean even when a component writes pipeline output' {
        InModuleScope Atlas.Software -Parameters @{ Root = $TestDrive } {
            $stage = Join-Path -Path $Root -ChildPath 'single-boolean-outcome'
            New-Item -Path $stage -ItemType Directory | Out-Null
            Mock Assert-AtlasPrivilege
            Mock New-AtlasProtectedStagingDirectory { $stage }
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Install-AtlasBraveBrowser { 'component diagnostic output' }
            Mock Write-AtlasLog

            $result = @(Install-AtlasSoftware -Component Brave)

            $result.Count | Should -Be 1
            $result[0].GetType().FullName | Should -BeExactly 'System.Boolean'
            $result[0] | Should -BeTrue
        }
    }
}

Describe 'Assert-AtlasFileHash' {
    It 'passes when the file hash matches the expected SHA256' {
        $file = Join-Path -Path $TestDrive -ChildPath 'download.bin'
        Set-Content -LiteralPath $file -Value 'atlas test payload' -NoNewline
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash

        InModuleScope Atlas.Software -Parameters @{ Path = $file; Hash = $hash } {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            { Assert-AtlasFileHash -Path $Path -ExpectedSha256 $Hash -Description 'test file' } | Should -Not -Throw
        }
    }

    It 'throws a refusal when the file hash does not match' {
        $file = Join-Path -Path $TestDrive -ChildPath 'download.bin'
        Set-Content -LiteralPath $file -Value 'atlas test payload' -NoNewline

        InModuleScope Atlas.Software -Parameters @{ Path = $file } {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            $wrongHash = 'deadbeef' * 8
            { Assert-AtlasFileHash -Path $Path -ExpectedSha256 $wrongHash -Description 'test file' } |
                Should -Throw -ExpectedMessage '*Refusing*'
        }
    }
}

Describe 'Assert-AtlasFileSignature' {
    It 'passes for a valid signature whose quoted subject CN matches the expected publisher' {
        InModuleScope Atlas.Software {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Get-AuthenticodeSignature {
                [pscustomobject]@{
                    Status            = [System.Management.Automation.SignatureStatus]::Valid
                    SignerCertificate = [pscustomobject]@{ Subject = 'CN="Brave Software, Inc.", O="Brave Software, Inc.", L=San Francisco, S=California, C=US' }
                }
            }

            { Assert-AtlasFileSignature -Path 'C:\fake\installer.exe' -ExpectedSubjectCn 'Brave Software, Inc.' -Description 'Brave' } | Should -Not -Throw
        }
    }

    It 'throws a refusal when the signature status is not valid' {
        InModuleScope Atlas.Software {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Get-AuthenticodeSignature {
                [pscustomobject]@{
                    Status            = [System.Management.Automation.SignatureStatus]::HashMismatch
                    SignerCertificate = [pscustomobject]@{ Subject = 'CN="Brave Software, Inc.", O="Brave Software, Inc.", L=San Francisco, S=California, C=US' }
                }
            }

            { Assert-AtlasFileSignature -Path 'C:\fake\installer.exe' -ExpectedSubjectCn 'Brave Software, Inc.' -Description 'Brave' } |
                Should -Throw -ExpectedMessage '*Refusing*'
        }
    }

    It 'throws a refusal when the signature is valid but signed by another publisher' {
        InModuleScope Atlas.Software {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Get-AuthenticodeSignature {
                [pscustomobject]@{
                    Status            = [System.Management.Automation.SignatureStatus]::Valid
                    SignerCertificate = [pscustomobject]@{ Subject = 'CN=Evil Corp, O=Evil Corp, C=US' }
                }
            }

            { Assert-AtlasFileSignature -Path 'C:\fake\installer.exe' -ExpectedSubjectCn 'Brave Software, Inc.' -Description 'Brave' } |
                Should -Throw -ExpectedMessage '*Refusing*'
        }
    }

}

Describe 'Get-AtlasSoftwarePickerItem' {
    It 'offers <Offered> on build <Build>' -TestCases @(
        @{ Build = 22631; Offered = 'StartIsBack.StartAllBack'; Hidden = 'StartIsBack.StartIsBack' }
        @{ Build = 19045; Offered = 'StartIsBack.StartIsBack'; Hidden = 'StartIsBack.StartAllBack' }
    ) {
        $items = InModuleScope Atlas.Software -Parameters @{ Build = $Build } {
            Get-AtlasSoftwarePickerItem -WindowsBuild $Build
        }

        @($items | Where-Object { $_.Package -eq $Offered }).Count | Should -Be 1
        @($items | Where-Object { $_.Package -eq $Hidden }).Count | Should -Be 0
    }

    It 'gives every build <Build> entry a name and a unique id and source that the installer accepts' -TestCases @(
        @{ Build = 22631 }
        @{ Build = 19045 }
    ) {
        InModuleScope Atlas.Software -Parameters @{ Build = $Build } {
            param($Build)
            $items = @(Get-AtlasSoftwarePickerItem -WindowsBuild $Build)
            # Check against the install boundary's own parameter validation.
            $parameters = (Get-Command -Name Invoke-AtlasSoftwarePickerPackageInstall).Parameters
            $pattern = @($parameters['PackageId'].Attributes |
                    Where-Object { $_ -is [Management.Automation.ValidatePatternAttribute] })
            $sources = @($parameters['Source'].Attributes |
                    Where-Object { $_ -is [Management.Automation.ValidateSetAttribute] })
            $pattern.Count | Should -Be 1
            $sources.Count | Should -Be 1

            $items.Count | Should -BeGreaterThan 0
            foreach ($item in $items) {
                $item.Text | Should -Not -BeNullOrEmpty
                [regex]::IsMatch($item.Package, $pattern[0].RegexPattern, $pattern[0].Options) |
                    Should -BeTrue -Because "'$($item.Package)' must pass the PackageId validation"
                $item.Source -cin $sources[0].ValidValues |
                    Should -BeTrue -Because "'$($item.Package)' must use an accepted source"
            }
            @($items.Package | Sort-Object -Unique).Count | Should -Be $items.Count
        }
    }
}

Describe 'Invoke-AtlasSoftwarePickerPackageBatch' {
    It 'attempts every selected package and returns an aggregate failure record' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasSoftwarePickerPackageInstall {
                if ($PackageId -ceq 'Vendor.Broken') {
                    throw 'fixture install failed'
                }
            }
            Mock Write-AtlasWarning
            $catalog = @(
                [pscustomobject]@{ Package = 'Vendor.First'; Source = 'winget' }
                [pscustomobject]@{ Package = 'Vendor.Broken'; Source = 'winget' }
                [pscustomobject]@{ Package = 'Vendor.Last'; Source = 'msstore' }
            )

            $failures = @(Invoke-AtlasSoftwarePickerPackageBatch `
                    -PackageId @('Vendor.First', 'Vendor.Broken', 'Vendor.Last') `
                    -Catalog $catalog)

            Should -Invoke Invoke-AtlasSoftwarePickerPackageInstall -Times 3 -Exactly
            Should -Invoke Write-AtlasWarning -Times 1 -Exactly
            $failures.Count | Should -Be 1
            $failures[0].PackageId | Should -BeExactly 'Vendor.Broken'
            $failures[0].Message | Should -BeExactly 'fixture install failed'
        }
    }

    It 'reports missing catalog entries without skipping later packages' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasSoftwarePickerPackageInstall
            Mock Write-AtlasWarning
            $catalog = @(
                [pscustomobject]@{ Package = 'Vendor.Present'; Source = 'winget' }
            )

            $failures = @(Invoke-AtlasSoftwarePickerPackageBatch `
                    -PackageId @('Vendor.Missing', 'Vendor.Present') `
                    -Catalog $catalog)

            Should -Invoke Invoke-AtlasSoftwarePickerPackageInstall -Times 1 -Exactly `
                -ParameterFilter { $PackageId -ceq 'Vendor.Present' }
            $failures.Count | Should -Be 1
            $failures[0].PackageId | Should -BeExactly 'Vendor.Missing'
        }
    }
}

Describe 'Invoke-AtlasSoftwarePickerPackageInstall' {
    BeforeEach {
        $script:fakeWinget = Join-Path -Path $TestDrive -ChildPath 'winget.cmd'
        Mock Get-AtlasTrustedWingetPath -ModuleName Atlas.Software { $script:fakeWinget }
        Mock Assert-AtlasTrustedWingetSource -ModuleName Atlas.Software
        Mock Write-AtlasNote -ModuleName Atlas.Software
    }

    It 'accepts an installed package that has no applicable upgrade and keeps WinGet output off the pipeline' {
        Set-Content -LiteralPath $script:fakeWinget -Encoding Ascii -Value @(
            '@echo No available upgrade found.'
            '@exit /b -1978335189'
        )

        $output = @(InModuleScope Atlas.Software {
                Invoke-AtlasSoftwarePickerPackageInstall -PackageId 'Notepad++.Notepad++' -Source winget
            })

        $output.Count | Should -Be 0
        Should -Invoke Write-AtlasNote -ModuleName Atlas.Software -Times 1 -Exactly -ParameterFilter {
            $Text -like "'Notepad++.Notepad++' is already installed*"
        }
    }

    It 'reports any other WinGet exit code in hexadecimal' {
        Set-Content -LiteralPath $script:fakeWinget -Encoding Ascii -Value '@exit /b -1978335212'

        InModuleScope Atlas.Software {
            { Invoke-AtlasSoftwarePickerPackageInstall -PackageId 'Valve.Steam' -Source winget } |
                Should -Throw "*'Valve.Steam' from 'winget' with exit code 0x8A150014."
        }
        Should -Invoke Write-AtlasNote -ModuleName Atlas.Software -Times 0
    }
}

Describe 'CBS Safe Mode retry fallback' {
    It 'arms the compact retry with the verified package paths' {
        InModuleScope Atlas.Software {
            Mock Enable-AtlasCbsRetry {}
            Register-AtlasCbsFailureFallback -RetryPackages @(
                [pscustomobject]@{ Path = 'C:\Packages\one.cab'; Sha256 = ('A' * 64) }
                [pscustomobject]@{ Path = 'C:\Packages\two.cab'; Sha256 = ('B' * 64) }
            )
            Should -Invoke Enable-AtlasCbsRetry -Times 1 -Exactly -ParameterFilter {
                @($Packages).Count -eq 2 -and
                $Packages[0] -ceq 'C:\Packages\one.cab' -and
                $Packages[1] -ceq 'C:\Packages\two.cab'
            }
        }
    }

    It 'tells the user that the Safe Mode retry is armed and how to run it' {
        InModuleScope Atlas.Software {
            Mock Assert-AtlasPrivilege {}
            Mock Initialize-AtlasCbsEnvironment {}
            Mock Write-Host {}
            Mock Enable-AtlasCbsRetry {}
            Mock Install-AtlasCbsCab {
                [pscustomobject]@{
                    Path = $CabPath; Success = $false; RetryEligible = $true
                    Sha256 = ('A' * 64); FailureKind = 'Servicing'
                }
            }
            { Install-AtlasCbsPackage -Packages @('C:\Packages\one.cab') -PackagesPath 'C:\Packages' `
                    -LiteralPaths -NonInteractive } |
                Should -Throw '*one.cab.*Safe Mode with Command Prompt*Invoke-AtlasCbsRetry.cmd*'
            Should -Invoke Enable-AtlasCbsRetry -Times 1 -Exactly
        }
    }
}

Describe 'Start-AtlasSoftwareInstaller' {
    It 'runs the installer hidden/waited and returns quietly on a success exit code (0)' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasContainedProcess {
                [pscustomobject]@{
                    ExitCodeUInt32 = [uint32]0
                }
            }

            { Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList @('/S', '/AllUsers') -Description 'Test' -TimeoutSeconds 123 } |
                Should -Not -Throw

            Should -Invoke Invoke-AtlasContainedProcess -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq 'C:\fake\setup.exe' -and
                @($ArgumentList).Count -eq 2 -and
                $ArgumentList[0] -ceq '/S' -and
                $ArgumentList[1] -ceq '/AllUsers' -and
                $WorkingDirectory -eq 'C:\fake' -and
                $TimeoutSeconds -eq 123 -and
                $Hidden -and $NoWindow
            }
        }
    }

    It 'judges exit code <ExitCode> with <Codes> success codes' -TestCases @(
        @{ ExitCode = 1; Codes = 'the default'; SuccessExitCode = $null; Failure = '*failed with exit code 1*' }
        # 1638 (another version installed) is only a success where a caller says so.
        @{ ExitCode = 1638; Codes = 'caller-supplied 0 and 3010'; SuccessExitCode = @(0, 3010); Failure = '*exit code 1638*' }
        @{ ExitCode = 3010; Codes = 'caller-supplied 0 and 3010'; SuccessExitCode = @(0, 3010); Failure = $null }
    ) {
        InModuleScope Atlas.Software -Parameters @{ ExitCode = $ExitCode; SuccessExitCode = $SuccessExitCode; Failure = $Failure } {
            Mock Invoke-AtlasContainedProcess { [pscustomobject]@{ ExitCodeUInt32 = [uint32]$ExitCode } }
            $codes = @{}
            if ($null -ne $SuccessExitCode) { $codes.SuccessExitCode = $SuccessExitCode }
            $install = {
                Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Test' @codes
            }

            if ($Failure) { $install | Should -Throw -ExpectedMessage $Failure }
            else { $install | Should -Not -Throw }
        }
    }
}

Describe 'Start-AtlasSoftwareOptionalInstaller' {
    It 'returns <Expected> with <Warnings> warning(s) so its caller can aggregate failure' -TestCases @(
        @{ Fails = $true; Expected = $false; Warnings = 1 }
        @{ Fails = $false; Expected = $true; Warnings = 0 }
    ) {
        InModuleScope Atlas.Software -Parameters @{ Fails = $Fails; Expected = $Expected; Warnings = $Warnings } {
            Mock Start-AtlasSoftwareInstaller { if ($Fails) { throw 'failed with exit code 1' } }
            Mock Test-AtlasContainedProcessContainmentUnconfirmed { $false }
            Mock Write-AtlasLog

            Start-AtlasSoftwareOptionalInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Optional thing' |
                Should -Be $Expected

            Should -Invoke Write-AtlasLog -Times $Warnings -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*failed with exit code 1*'
            }
        }
    }

    It 'rethrows an unconfirmed-containment failure instead of starting a fallback concurrently' {
        InModuleScope Atlas.Software {
            Mock Start-AtlasSoftwareInstaller { throw 'containment unknown' }
            Mock Test-AtlasContainedProcessContainmentUnconfirmed { $true }
            Mock Write-AtlasLog

            { Start-AtlasSoftwareOptionalInstaller -FilePath 'C:\fake\setup.exe' -Description 'Optional thing' } |
                Should -Throw -ExpectedMessage '*containment unknown*'
            Should -Invoke Write-AtlasLog -Times 0
        }
    }
}

Describe 'Invoke-AtlasSoftwareDownload' {
    It 'streams HTTPS into the protected destination through the shared size-limited reader' {
        InModuleScope Atlas.Software -Parameters @{ Root = $TestDrive } {
            $destination = Join-Path -Path $Root -ChildPath 'installer.exe'
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Invoke-AtlasBoundedHttpGet {
                $payload = [Text.Encoding]::UTF8.GetBytes('signed fixture')
                $OutputStream.Write($payload, 0, $payload.Length)
                return $payload.Length
            }

            Invoke-AtlasSoftwareDownload `
                -Uri 'https://downloads.example.test/setup.exe' `
                -Destination $destination `
                -Description 'fixture' `
                -MaximumBytes 4096 `
                -MaximumSeconds 45 | Should -Be $destination

            Get-Content -LiteralPath $destination -Raw | Should -BeExactly 'signed fixture'
            Should -Invoke Invoke-AtlasBoundedHttpGet -Times 1 -Exactly -ParameterFilter {
                $Uri.AbsoluteUri -ceq 'https://downloads.example.test/setup.exe' -and
                $MaximumBytes -eq 4096 -and
                $MaximumSeconds -eq 45 -and
                $AllowRedirect
            }
        }
    }

    It 'rejects HTTP before creating a destination' {
        InModuleScope Atlas.Software -Parameters @{ Root = $TestDrive } {
            Mock Invoke-AtlasBoundedHttpGet
            $destination = Join-Path $Root 'setup.exe'

            { Invoke-AtlasSoftwareDownload -Uri 'http://example.test/setup.exe' `
                    -Destination $destination -Description 'fixture' } |
                Should -Throw -ExpectedMessage '*Only HTTPS*'
            Test-Path -LiteralPath $destination | Should -BeFalse
            Should -Invoke Invoke-AtlasBoundedHttpGet -Times 0
        }
    }

    It 'removes a partial file when size-limited streaming fails' {
        InModuleScope Atlas.Software -Parameters @{ Root = $TestDrive } {
            $destination = Join-Path -Path $Root -ChildPath 'partial.exe'
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Invoke-AtlasBoundedHttpGet {
                $payload = [Text.Encoding]::UTF8.GetBytes('partial')
                $OutputStream.Write($payload, 0, $payload.Length)
                throw 'network failed'
            }

            { Invoke-AtlasSoftwareDownload -Uri 'https://example.test/setup.exe' `
                    -Destination $destination -Description 'fixture' } |
                Should -Throw -ExpectedMessage '*network failed*'
            Test-Path -LiteralPath $destination | Should -BeFalse
        }
    }
}

Describe 'LibreWolf latest-release identity and publisher boundary' {
    BeforeEach {
        $script:LibreWolfRelease = [pscustomobject]@{
            tag_name   = '152.0.5-1'
            draft      = $false
            prerelease = $false
            assets     = @(
                [pscustomobject]@{
                    name                 = 'librewolf-152.0.5-1-windows-x86_64-setup.exe'
                    browser_download_url = 'https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe'
                }
                [pscustomobject]@{
                    name                 = 'librewolf-152.0.5-1-windows-arm64-setup.exe'
                    browser_download_url = 'https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-arm64-setup.exe'
                }
            )
        }
        $script:LibreWolfWingetManifestText = @'
PackageIdentifier: LibreWolf.LibreWolf
PackageVersion: 152.0.5-1
InstallerType: nullsoft
Scope: machine
Installers:
- InstallerSha256: 227F69A02C286F90E82B6155F7CBFD01EACC63DDAE7CA73594EC32C5F4BC84F6
  InstallerUrl: https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe
  Architecture: x64
  ProductCode: ignored-extra-field
- Architecture: arm64
  InstallerUrl: https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-arm64-setup.exe
  InstallerSha256: 03B5E2E68A4B17551CC0798C015EBA3DF528C5CA5F27EC9D53065A8FDC90123E
ManifestType: installer
'@
        $manifestBytes = (New-Object Text.UTF8Encoding($false)).GetBytes(
            $script:LibreWolfWingetManifestText
        )
        $script:LibreWolfWingetContent = [pscustomobject]@{
            encoding = 'base64'
            content  = [Convert]::ToBase64String($manifestBytes)
        }
        $script:LibreWolfResolvedRelease = [pscustomobject]@{
            Tag = '152.0.5-1'
            Uri = [uri]'https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe'
        }
    }

    It 'selects the exact architecture-specific stable Codeberg asset' {
        InModuleScope Atlas.Software -Parameters @{
            Release = $script:LibreWolfRelease
        } {
            $metadata = Resolve-AtlasLibreWolfReleaseMetadata `
                -Release $Release -Architecture x86_64

            $metadata.Tag | Should -BeExactly '152.0.5-1'
            $metadata.Name | Should -BeExactly 'librewolf-152.0.5-1-windows-x86_64-setup.exe'
            $metadata.Uri.AbsoluteUri | Should -BeExactly 'https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe'
            @($metadata.PSObject.Properties.Name) | Should -Be @('Tag', 'Name', 'Uri')
        }
    }

    It 'rejects <Case>' -TestCases @(
        @{
            Case    = 'a duplicate installer asset'
            Change  = { param($Release) $Release.assets += $Release.assets[0].PSObject.Copy() }
            Message = '*exactly one*'
        }
        @{
            Case    = 'an installer asset outside the canonical download host'
            Change  = {
                param($Release)
                $Release.assets[0].browser_download_url =
                'https://attacker.example/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe'
            }
            Message = '*canonical LibreWolf download URL*'
        }
        @{
            Case    = 'a prerelease'
            Change  = { param($Release) $Release.prerelease = $true }
            Message = '*not a stable LibreWolf release*'
        }
        @{
            Case    = 'a draft'
            Change  = { param($Release) $Release.draft = $true }
            Message = '*not a stable LibreWolf release*'
        }
        @{
            Case    = 'a tag that leaves the download path'
            Change  = { param($Release) $Release.tag_name = '152.0.5-1/..' }
            Message = '*not a stable LibreWolf release*'
        }
    ) {
        & $Change $script:LibreWolfRelease
        InModuleScope Atlas.Software -Parameters @{
            Release = $script:LibreWolfRelease
            Message = $Message
        } {
            { Resolve-AtlasLibreWolfReleaseMetadata `
                    -Release $Release -Architecture x86_64 } |
                Should -Throw -ExpectedMessage $Message
        }
    }

    It 'reads the selected installer despite field reordering, extra fields, and another architecture' {
        InModuleScope Atlas.Software -Parameters @{
            ContentMetadata = $script:LibreWolfWingetContent
            ReleaseMetadata = $script:LibreWolfResolvedRelease
        } {
            Resolve-AtlasLibreWolfWingetManifestHash `
                -ContentMetadata $ContentMetadata `
                -ReleaseMetadata $ReleaseMetadata `
                -Architecture x86_64 |
                Should -BeExactly '227f69a02c286f90e82b6155f7cbfd01eacc63ddae7ca73594ec32c5f4bc84f6'
        }
    }

    It 'rejects an independent manifest that redirects the selected architecture' {
        $script:LibreWolfWingetManifestText = $script:LibreWolfWingetManifestText.Replace(
            'https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe',
            'https://attacker.example/setup.exe'
        )
        $manifestBytes = (New-Object Text.UTF8Encoding($false)).GetBytes(
            $script:LibreWolfWingetManifestText
        )
        $script:LibreWolfWingetContent.content = [Convert]::ToBase64String($manifestBytes)
        InModuleScope Atlas.Software -Parameters @{
            ContentMetadata = $script:LibreWolfWingetContent
            ReleaseMetadata = $script:LibreWolfResolvedRelease
        } {
            { Resolve-AtlasLibreWolfWingetManifestHash `
                    -ContentMetadata $ContentMetadata `
                    -ReleaseMetadata $ReleaseMetadata `
                    -Architecture x86_64 } |
                Should -Throw -ExpectedMessage '*does not attest*'
        }
    }

    It 'installs the newest release winget-pkgs has merged while a newer one awaits review' {
        $newer = [pscustomobject]@{
            tag_name   = '152.0.6-1'
            draft      = $false
            prerelease = $false
            assets     = @([pscustomobject]@{
                    name                 = 'librewolf-152.0.6-1-windows-x86_64-setup.exe'
                    browser_download_url = 'https://dl.librewolf.net/librewolf/152.0.6-1/librewolf-152.0.6-1-windows-x86_64-setup.exe'
                })
        }
        $draft = [pscustomobject]@{ tag_name = '152.0.7-1'; draft = $true; prerelease = $false; assets = @() }
        InModuleScope Atlas.Software -Parameters @{
            Releases = @($draft, $newer, $script:LibreWolfRelease)
            Manifest = $script:LibreWolfWingetContent
        } {
            Mock Write-AtlasLog
            Mock Invoke-AtlasSoftwareApiJson { $Releases }
            Mock Invoke-AtlasGitHubApiJson { throw "Unexpected GitHub request for '$Uri'." }
            Mock Invoke-AtlasGitHubApiJson -ParameterFilter {
                $Uri.AbsolutePath -ceq '/repos/microsoft/winget-pkgs/contents/manifests/l/LibreWolf/LibreWolf'
            } -MockWith {
                [pscustomobject]@{ name = '152.0.4-1'; type = 'dir' }
                [pscustomobject]@{ name = '152.0.5-1'; type = 'dir' }
            }
            Mock Invoke-AtlasGitHubApiJson -ParameterFilter {
                $Uri.AbsolutePath -ceq '/repos/microsoft/winget-pkgs/contents/manifests/l/LibreWolf/LibreWolf/152.0.5-1/LibreWolf.LibreWolf.installer.yaml'
            } -MockWith { $Manifest }

            $metadata = Get-AtlasLatestLibreWolfInstallerMetadata -Architecture x86_64

            $metadata.Tag | Should -BeExactly '152.0.5-1'
            $metadata.Uri.AbsoluteUri | Should -BeExactly 'https://dl.librewolf.net/librewolf/152.0.5-1/librewolf-152.0.5-1-windows-x86_64-setup.exe'
            $metadata.Sha256 | Should -BeExactly '227f69a02c286f90e82b6155f7cbfd01eacc63ddae7ca73594ec32c5f4bc84f6'
            Should -Invoke Invoke-AtlasGitHubApiJson -Times 2 -Exactly
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Message -like '*152.0.6-1 is awaiting Microsoft winget-pkgs review; installing 152.0.5-1*'
            }
        }
    }

    It 'fails before reading a manifest when winget-pkgs has merged none of the newest releases' {
        InModuleScope Atlas.Software -Parameters @{ Releases = @($script:LibreWolfRelease) } {
            Mock Write-AtlasLog
            Mock Invoke-AtlasSoftwareApiJson { $Releases }
            Mock Invoke-AtlasGitHubApiJson { throw "Unexpected GitHub request for '$Uri'." }
            Mock Invoke-AtlasGitHubApiJson -ParameterFilter {
                $Uri.AbsolutePath -ceq '/repos/microsoft/winget-pkgs/contents/manifests/l/LibreWolf/LibreWolf'
            } -MockWith {
                [pscustomobject]@{ name = '152.0.4-1'; type = 'dir' }
            }

            { Get-AtlasLatestLibreWolfInstallerMetadata -Architecture x86_64 } |
                Should -Throw "*hasn't merged any of the newest LibreWolf releases (152.0.5-1)*"
            Should -Invoke Invoke-AtlasGitHubApiJson -Times 1 -Exactly
        }
    }
}

Describe 'NanaZip package identity and provisioning boundary' {
    It 'accepts the exact Store bundle name, publisher, and release version' {
        $bundle = Join-Path -Path $TestDrive -ChildPath 'NanaZip.msixbundle'
        New-AtlasTestNanaZipBundle -Path $bundle

        InModuleScope Atlas.Software -Parameters @{ Bundle = $bundle } {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }

            { Assert-AtlasNanaZipBundleIdentity -Path $Bundle -Version '6.5.1767.0' } |
                Should -Not -Throw
        }
    }

    It 'rejects a hash-valid bundle for a different package publisher' {
        $bundle = Join-Path -Path $TestDrive -ChildPath 'WrongPublisher.msixbundle'
        New-AtlasTestNanaZipBundle -Path $bundle -Publisher 'CN=Attacker'

        InModuleScope Atlas.Software -Parameters @{ Bundle = $bundle } {
            Mock Resolve-AtlasProtectedExecutionPath { $Path }

            { Assert-AtlasNanaZipBundleIdentity -Path $Bundle -Version '6.5.1767.0' } |
                Should -Throw -ExpectedMessage '*reviewed Store package*'
        }
    }

}

Describe 'Install-AtlasNanaZip provisioning' {
    BeforeEach {
        $script:NanaZipMutationAssets = @(
            [pscustomobject]@{
                Name = 'NanaZip_6.5.1767.0.msixbundle'
                Tag = '6.5.1767.0'
                Uri = [uri]'https://example.invalid/NanaZip_6.5.1767.0.msixbundle'
                Sha256 = '1' * 64
                Size = 123L
            }
            [pscustomobject]@{
                Name = 'NanaZip_6.5.1767.0.xml'
                Tag = '6.5.1767.0'
                Uri = [uri]'https://example.invalid/NanaZip_6.5.1767.0.xml'
                Sha256 = '2' * 64
                Size = 456L
            }
        )
    }

    It 'downloads the exact pair, provisions it with DISM, and verifies the installed version' {
        $temp = Join-Path -Path $TestDrive -ChildPath 'nanazip-success'
        New-Item -Path $temp -ItemType Directory | Out-Null
        InModuleScope Atlas.Software -Parameters @{
            Temp = $temp
            Assets = $script:NanaZipMutationAssets
        } {
            $script:AddedPackage = $null
            $commands = [pscustomobject]@{
                GetProvisionedPackage = {
                    [pscustomobject]@{
                        DisplayName = '40174MouriNaruto.NanaZip'
                        Version = '6.5.1767.0'
                    }
                }
                AddProvisionedPackage = {
                    param(
                        [switch]$Online,
                        [string]$PackagePath,
                        [string]$LicensePath
                    )
                    $script:AddedPackage = [pscustomobject]@{
                        Online = $Online
                        PackagePath = $PackagePath
                        LicensePath = $LicensePath
                    }
                }
            }
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Invoke-AtlasPinnedDownload { $Destination }
            Mock Assert-AtlasNanaZipBundleIdentity

            Install-AtlasNanaZip `
                -TempDir $Temp `
                -Assets $Assets `
                -DismCommands $commands | Should -BeTrue

            Should -Invoke Invoke-AtlasPinnedDownload -Times 2 -Exactly
            Should -Invoke Assert-AtlasNanaZipBundleIdentity -Times 1 -Exactly `
                -ParameterFilter { $Version -ceq '6.5.1767.0' }
            $script:AddedPackage.Online | Should -BeTrue
            $script:AddedPackage.PackagePath | Should -BeLike '*NanaZip_6.5.1767.0.msixbundle'
            $script:AddedPackage.LicensePath | Should -BeLike '*NanaZip_6.5.1767.0.xml'
        }
    }

    It 'reports a download failure as a download-source failure without calling DISM' {
        $temp = Join-Path -Path $TestDrive -ChildPath 'nanazip-pre-mutation'
        New-Item -Path $temp -ItemType Directory | Out-Null
        InModuleScope Atlas.Software -Parameters @{
            Temp = $temp
            Assets = $script:NanaZipMutationAssets
        } {
            $commands = [pscustomobject]@{
                GetProvisionedPackage = { throw 'must not read back before provisioning' }
                AddProvisionedPackage = { throw 'must not mutate after a download failure' }
            }
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Invoke-AtlasPinnedDownload { throw 'verified download unavailable' }
            Mock Write-AtlasLog

            { Install-AtlasNanaZip -TempDir $Temp -Assets $Assets -DismCommands $commands } | Should -Throw '*verified download sources*'
        }
    }

    It 'rethrows the original error when the readback after DISM fails' {
        $temp = Join-Path -Path $TestDrive -ChildPath 'nanazip-readback-failure'
        New-Item -Path $temp -ItemType Directory | Out-Null
        InModuleScope Atlas.Software -Parameters @{
            Temp = $temp
            Assets = $script:NanaZipMutationAssets
        } {
            $commands = [pscustomobject]@{
                GetProvisionedPackage = {
                    [CmdletBinding()]
                    param([switch]$Online)
                    [void]$Online
                    return @()
                }
                AddProvisionedPackage = {
                    [CmdletBinding()]
                    param(
                        [switch]$Online,
                        [string]$PackagePath,
                        [string]$LicensePath
                    )
                    [void]$Online
                    [void]$PackagePath
                    [void]$LicensePath
                }
            }
            Mock Resolve-AtlasProtectedExecutionPath { $Path }
            Mock Invoke-AtlasPinnedDownload { $Destination }
            Mock Assert-AtlasNanaZipBundleIdentity

            # Exact match: DISM may have changed machine state, so the error must
            # not be reworded as a download-source failure.
            { Install-AtlasNanaZip -TempDir $Temp -Assets $Assets -DismCommands $commands } |
                Should -Throw -ExpectedMessage "DISM returned without provisioning NanaZip version '6.5.1767.0'."
        }
    }
}

Describe 'Install-AtlasArchiveTool asset selection' {
    BeforeEach {
        Mock Install-AtlasNanaZipFromStore -ModuleName Atlas.Software { $false }
        Mock Test-Path -ModuleName Atlas.Software -ParameterFilter {
            $LiteralPath -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
        } -MockWith { $false }
        Mock Read-MessageBox -ModuleName Atlas.Software {
            throw 'An archive installation test attempted to show an interactive prompt.'
        }
    }
    It 'reports a NanaZip integrity failure before installation' {
        InModuleScope Atlas.Software {
            $commands = [pscustomobject]@{
                GetProvisionedPackage = {
                    [CmdletBinding()]
                    param([switch]$Online)
                    [void]$Online
                    return @()
                }
                AddProvisionedPackage = { }
            }
            Mock Get-AtlasDismProvisioningCommands { $commands }
            Mock Get-AtlasPinnedNanaZipReleaseAssets { throw 'digest missing' }
            Mock Install-AtlasNanaZip
            Mock Write-AtlasLog

            { Install-AtlasArchiveTool -TempDir 'C:\fake\temp' } | Should -Throw '*integrity could not be established*'
            Should -Invoke Install-AtlasNanaZip -Times 0 -Exactly
        }
    }

    It 'falls back to the pinned NanaZip download when the Store path declines' {
        InModuleScope Atlas.Software {
            $commands = [pscustomobject]@{
                GetProvisionedPackage = {
                    [CmdletBinding()]
                    param([switch]$Online)
                    [void]$Online
                    return @()
                }
                AddProvisionedPackage = { }
            }
            Mock Get-AtlasDismProvisioningCommands { $commands }
            Mock Get-AtlasPinnedNanaZipReleaseAssets {
                [pscustomobject]@{ Name = 'NanaZip_6.5.1767.0.msixbundle'; Tag = '6.5.1767.0' }
                [pscustomobject]@{ Name = 'NanaZip_6.5.1767.0.xml'; Tag = '6.5.1767.0' }
            }
            Mock Install-AtlasNanaZip { $true }
            Mock Write-AtlasLog

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            Should -Invoke Install-AtlasNanaZipFromStore -Times 1 -Exactly -ParameterFilter {
                $null -ne $DismCommands.AddProvisionedPackage
            }
            Should -Invoke Install-AtlasNanaZip -Times 1 -Exactly -ParameterFilter {
                @($Assets).Count -eq 2 -and
                $Assets[0].Name -ceq 'NanaZip_6.5.1767.0.msixbundle' -and
                $Assets[1].Name -ceq 'NanaZip_6.5.1767.0.xml' -and
                $null -ne $DismCommands.AddProvisionedPackage -and
                $TempDir -ceq 'C:\fake\temp'
            }
        }
    }

    It 'keeps an installed 7-Zip without asking or installing NanaZip' {
        InModuleScope Atlas.Software {
            Mock Test-Path -ParameterFilter {
                $LiteralPath -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
            } -MockWith { $true }
            Mock Get-AtlasDismProvisioningCommands { throw 'DISM is not needed when 7-Zip stays.' }
            Mock Install-AtlasNanaZip
            Mock Write-AtlasLog

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            Should -Invoke Install-AtlasNanaZipFromStore -Times 0 -Exactly
            Should -Invoke Install-AtlasNanaZip -Times 0 -Exactly
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Message -like '7-Zip is installed*skips NanaZip*'
            }
        }
    }
}
