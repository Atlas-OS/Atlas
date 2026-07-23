BeforeAll {
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

    It 'reports patterns that matched nothing for the architecture' {
        InModuleScope Atlas.Software {
            $candidates = @(
                'C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab'
            )
            $patterns = @('*Z-Atlas-NoDefender-Package*', '*Z-Atlas-NoTelemetry-Package*')

            $result = Select-AtlasCbsPackage -Candidates $candidates -Patterns $patterns -Architecture 'arm64' -SingleUsePatterns

            $result.Matched | Should -Be @('C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab')
            $result.UnmatchedPatterns | Should -Be @('*Z-Atlas-NoTelemetry-Package*')
        }
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

    It 'matches nothing when the architecture differs' {
        InModuleScope Atlas.Software {
            $result = Select-AtlasCbsPackage -Candidates @('C:\Packages\Z-Atlas-NoDefender-Package-arm64-1.cab') `
                -Patterns @('*Z-Atlas-NoDefender-Package*') -Architecture 'amd64' -SingleUsePatterns

            @($result.Matched).Count | Should -Be 0
            $result.UnmatchedPatterns | Should -Be @('*Z-Atlas-NoDefender-Package*')
        }
    }
}

Describe 'Get-AtlasSoftwareComponentMap' {
    It 'maps every Install-AtlasSoftware component to an existing installer function' {
        InModuleScope Atlas.Software {
            $map = Get-AtlasSoftwareComponentMap
            $expectedComponents = @('SevenZip', 'VCRedist', 'DirectX', 'Brave', 'Firefox', 'LibreWolf', 'Chrome', 'Toolbox')

            @($map.Keys) | Sort-Object | Should -Be ($expectedComponents | Sort-Object)
            foreach ($function in $map.Values) {
                Get-Command -Name $function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Test-AtlasSoftwareArm64' {
    It 'recognizes exactly one native ARM64 computer-system result' {
        InModuleScope Atlas.Software {
            Mock Get-CimInstance {
                [pscustomobject]@{ SystemType = 'ARM64-based PC' }
            }

            Test-AtlasSoftwareArm64 | Should -BeTrue
            Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
                $ClassName -ceq 'Win32_ComputerSystem' -and $ErrorAction -eq 'Stop'
            }
        }
    }

    It 'recognizes exactly one native x64 computer-system result' {
        InModuleScope Atlas.Software {
            Mock Get-CimInstance {
                [pscustomobject]@{ SystemType = 'x64-based PC' }
            }

            Test-AtlasSoftwareArm64 | Should -BeFalse
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
    It 'uses the exact module architecture authority for ARM64 CBS packages' {
        InModuleScope Atlas.Software {
            Mock Test-AtlasSoftwareArm64 { $true }

            Get-AtlasCbsArchitecture | Should -BeExactly 'arm64'
            Should -Invoke Test-AtlasSoftwareArm64 -Times 1 -Exactly
        }
    }

    It 'uses the exact module architecture authority for amd64 CBS packages' {
        InModuleScope Atlas.Software {
            Mock Test-AtlasSoftwareArm64 { $false }

            Get-AtlasCbsArchitecture | Should -BeExactly 'amd64'
            Should -Invoke Test-AtlasSoftwareArm64 -Times 1 -Exactly
        }

    }
}

Describe 'Install-AtlasSoftware' {
    It 'rejects unknown components' {
        { Install-AtlasSoftware -Component 'NotARealComponent' } | Should -Throw
    }

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
    It 'offers StartAllBack on Windows 11 builds' {
        InModuleScope Atlas.Software {
            $items = Get-AtlasSoftwarePickerItem -WindowsBuild 22631

            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartAllBack' }).Count | Should -Be 1
            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartIsBack' }).Count | Should -Be 0
        }
    }

    It 'offers StartIsBack on Windows 10 builds' {
        InModuleScope Atlas.Software {
            $items = Get-AtlasSoftwarePickerItem -WindowsBuild 19045

            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartIsBack' }).Count | Should -Be 1
            @($items | Where-Object { $_.Package -eq 'StartIsBack.StartAllBack' }).Count | Should -Be 0
        }
    }

    It 'keeps the full catalog with display names and package ids' {
        InModuleScope Atlas.Software {
            $items = @(Get-AtlasSoftwarePickerItem -WindowsBuild 22631)

            $items.Count | Should -Be 40
            foreach ($item in $items) {
                $item.Text | Should -Not -BeNullOrEmpty
                $item.Package | Should -Not -BeNullOrEmpty
            }
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
            Mock Write-Warning
            $catalog = @(
                [pscustomobject]@{ Package = 'Vendor.First'; Source = 'winget' }
                [pscustomobject]@{ Package = 'Vendor.Broken'; Source = 'winget' }
                [pscustomobject]@{ Package = 'Vendor.Last'; Source = 'msstore' }
            )

            $failures = @(Invoke-AtlasSoftwarePickerPackageBatch `
                    -PackageId @('Vendor.First', 'Vendor.Broken', 'Vendor.Last') `
                    -Catalog $catalog -AtlasContext ([pscustomobject]@{}))

            Should -Invoke Invoke-AtlasSoftwarePickerPackageInstall -Times 3 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly
            $failures.Count | Should -Be 1
            $failures[0].PackageId | Should -BeExactly 'Vendor.Broken'
            $failures[0].Message | Should -BeExactly 'fixture install failed'
        }
    }

    It 'reports missing catalog entries without skipping later packages' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasSoftwarePickerPackageInstall
            Mock Write-Warning
            $catalog = @(
                [pscustomobject]@{ Package = 'Vendor.Present'; Source = 'winget' }
            )

            $failures = @(Invoke-AtlasSoftwarePickerPackageBatch `
                    -PackageId @('Vendor.Missing', 'Vendor.Present') `
                    -Catalog $catalog -AtlasContext ([pscustomobject]@{}))

            Should -Invoke Invoke-AtlasSoftwarePickerPackageInstall -Times 1 -Exactly `
                -ParameterFilter { $PackageId -ceq 'Vendor.Present' }
            $failures.Count | Should -Be 1
            $failures[0].PackageId | Should -BeExactly 'Vendor.Missing'
        }
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

    It 'throws with the failing exit code when the installer returns a non-success code' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasContainedProcess {
                [pscustomobject]@{
                    ExitCodeUInt32 = [uint32]1
                }
            }

            { Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Test' } |
                Should -Throw -ExpectedMessage '*failed with exit code 1*'
        }
    }

    It 'treats a caller-supplied additional success code (3010, reboot required) as success' {
        InModuleScope Atlas.Software {
            Mock Invoke-AtlasContainedProcess {
                [pscustomobject]@{
                    ExitCodeUInt32 = [uint32]3010
                }
            }

            { Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Test' -SuccessExitCode @(0, 3010) } |
                Should -Not -Throw
        }
    }

}

Describe 'Start-AtlasSoftwareOptionalInstaller' {
    It 'returns false and logs a single warning so its caller can aggregate failure' {
        InModuleScope Atlas.Software {
            Mock Start-AtlasSoftwareInstaller { throw 'failed with exit code 1' }
            Mock Test-AtlasContainedProcessContainmentUnconfirmed { $false }
            Mock Write-AtlasLog

            Start-AtlasSoftwareOptionalInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Optional thing' |
                Should -BeFalse

            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*failed with exit code 1*'
            }
        }
    }

    It 'returns true only when the contained installer succeeds' {
        InModuleScope Atlas.Software {
            Mock Start-AtlasSoftwareInstaller

            Start-AtlasSoftwareOptionalInstaller -FilePath 'C:\fake\setup.exe' -Description 'Optional thing' |
                Should -BeTrue
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
    It 'streams HTTPS into the protected destination through the shared bounded reader' {
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

    It 'removes a partial file when bounded streaming fails' {
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

    It 'rejects duplicate or noncanonical latest installer assets' {
        $script:LibreWolfRelease.assets += $script:LibreWolfRelease.assets[0].PSObject.Copy()
        InModuleScope Atlas.Software -Parameters @{
            Release = $script:LibreWolfRelease
        } {
            { Resolve-AtlasLibreWolfReleaseMetadata `
                    -Release $Release -Architecture x86_64 } |
                Should -Throw -ExpectedMessage '*exactly one*'
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
}

Describe 'NanaZip latest-release integrity metadata' {
    BeforeEach {
        $script:NanaZipBundleHash = '606bba9cd7f3a8805bb89c6669e0abfd67a705ddc98939148afedefeed520b9c'
        $script:NanaZipLicenseHash = '75e59bba87de633e848f20285a24c3328e9670009a7acd34bb4d070bc5cebe53'
        $script:NanaZipRelease = [pscustomobject]@{
            tag_name   = '6.5.1767.0'
            draft      = $false
            prerelease = $false
            assets     = @(
                [pscustomobject]@{
                    name = 'NanaZip_6.5.1767.0.msixbundle'; state = 'uploaded'; size = 11885370
                    digest = "sha256:$script:NanaZipBundleHash"
                    browser_download_url = 'https://github.com/M2Team/NanaZip/releases/download/6.5.1767.0/NanaZip_6.5.1767.0.msixbundle'
                }
                [pscustomobject]@{
                    name = 'NanaZip_6.5.1767.0.xml'; state = 'uploaded'; size = 2667
                    digest = "sha256:$script:NanaZipLicenseHash"
                    browser_download_url = 'https://github.com/M2Team/NanaZip/releases/download/6.5.1767.0/NanaZip_6.5.1767.0.xml'
                }
            )
        }
    }

    It 'returns the exact stable bundle and license facts from GitHub asset digests' {
        InModuleScope Atlas.Software -Parameters @{
            Release = $script:NanaZipRelease
        } {
            $assets = @(Resolve-AtlasNanaZipReleaseAssets -Release $Release)

            $assets.Count | Should -Be 2
            $assets[0].Name | Should -BeExactly 'NanaZip_6.5.1767.0.msixbundle'
            $assets[0].Sha256 | Should -BeExactly '606bba9cd7f3a8805bb89c6669e0abfd67a705ddc98939148afedefeed520b9c'
            $assets[0].Size | Should -Be 11885370
            $assets[1].Name | Should -BeExactly 'NanaZip_6.5.1767.0.xml'
            @($assets[0].PSObject.Properties.Name) | Should -Be @('Tag', 'Name', 'Uri', 'Sha256', 'Size')
        }
    }

    It 'rejects an exact-name asset without a GitHub SHA-256 digest' {
        $script:NanaZipRelease.assets[0].digest = $null
        InModuleScope Atlas.Software -Parameters @{
            Release = $script:NanaZipRelease
        } {
            { Resolve-AtlasNanaZipReleaseAssets -Release $Release } |
                Should -Throw -ExpectedMessage '*bounded SHA-256 digest*'
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

Describe 'Install-AtlasNanaZip mutation boundary' {
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

    It 'allows the pinned 7-Zip fallback before DISM mutation begins' {
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
            Mock Install-Atlas7Zip
            Mock Write-AtlasLog
            Mock Test-AtlasContainedProcessContainmentUnconfirmed { $false }
            Mock Test-Path -ParameterFilter {
                $LiteralPath -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
            } -MockWith { $false }

            Install-AtlasNanaZip `
                -TempDir $Temp `
                -Assets $Assets `
                -DismCommands $commands | Should -BeFalse

            Should -Invoke Install-Atlas7Zip -Times 1 -Exactly -ParameterFilter {
                $TempDir -ceq $Temp
            }
        }
    }

    It 'propagates a failed post-provisioning readback without installing 7-Zip' {
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
            Mock Install-Atlas7Zip

            { Install-AtlasNanaZip -TempDir $Temp -Assets $Assets -DismCommands $commands } |
                Should -Throw -ExpectedMessage '*without provisioning NanaZip*'

            Should -Invoke Install-Atlas7Zip -Times 0 -Exactly
        }
    }
}

Describe 'Install-AtlasArchiveTool asset selection' {
    It 'routes exactly two verified NanaZip assets through the protected provisioning helper' {
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
            $assets = @(
                [pscustomobject]@{ Name = 'NanaZip_6.5.1767.0.msixbundle'; Tag = '6.5.1767.0' }
                [pscustomobject]@{ Name = 'NanaZip_6.5.1767.0.xml'; Tag = '6.5.1767.0' }
            )
            Mock Get-AtlasDismProvisioningCommands { $commands }
            Mock Get-AtlasLatestNanaZipReleaseAssets { $assets }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*7-Zip*' } -MockWith { $false }
            Mock Install-AtlasNanaZip
            Mock Install-Atlas7Zip

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            Should -Invoke Install-AtlasNanaZip -Times 1 -Exactly -ParameterFilter {
                @($Assets).Count -eq 2 -and
                $Assets[0].Name -ceq 'NanaZip_6.5.1767.0.msixbundle' -and
                $Assets[1].Name -ceq 'NanaZip_6.5.1767.0.xml' -and
                $null -ne $DismCommands.GetProvisionedPackage
            }
            Should -Invoke Install-Atlas7Zip -Times 0 -Exactly
        }
    }

    It 'falls back to pinned 7-Zip when NanaZip release integrity cannot be established' {
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
            Mock Get-AtlasLatestNanaZipReleaseAssets { throw 'digest missing' }
            Mock Install-AtlasNanaZip
            Mock Install-Atlas7Zip
            Mock Write-AtlasLog

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            Should -Invoke Install-Atlas7Zip -Times 1 -Exactly
            Should -Invoke Install-AtlasNanaZip -Times 0 -Exactly
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*integrity could not be established*'
            }
        }
    }

    It 'provisions and verifies NanaZip before invoking the validated 7-Zip uninstaller' {
        InModuleScope Atlas.Software {
            $commands = [pscustomobject]@{
                GetProvisionedPackage = { return @() }
                AddProvisionedPackage = { }
            }
            $assets = @(
                [pscustomobject]@{ Name = 'NanaZip_6.5.1767.0.msixbundle'; Tag = '6.5.1767.0' }
                [pscustomobject]@{ Name = 'NanaZip_6.5.1767.0.xml'; Tag = '6.5.1767.0' }
            )
            $script:ArchiveToolEvents = New-Object Collections.Generic.List[string]
            $script:SevenZipRegistryChecks = 0
            $expectedUninstaller = [IO.Path]::Combine(
                [Environment]::GetFolderPath('ProgramFiles'),
                '7-Zip',
                'Uninstall.exe'
            )

            Mock Get-AtlasDismProvisioningCommands { $commands }
            Mock Get-AtlasLatestNanaZipReleaseAssets { $assets }
            Mock Test-Path -ParameterFilter {
                $LiteralPath -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
            } -MockWith {
                $script:SevenZipRegistryChecks++
                return ($script:SevenZipRegistryChecks -eq 1)
            }
            Mock Read-MessageBox { 'Yes' } -RemoveParameterType @('Icon', 'Buttons')
            Mock Install-AtlasNanaZip {
                $script:ArchiveToolEvents.Add('NanaZip provisioned')
                return $true
            }
            Mock Get-ItemProperty {
                [pscustomobject]@{
                    QuietUninstallString = '"' + $expectedUninstaller + '" /S'
                }
            }
            Mock Resolve-AtlasProtectedExecutionPath {
                $script:ArchiveToolEvents.Add('7-Zip uninstaller validated')
                return $Path
            }
            Mock Start-AtlasSoftwareInstaller {
                $script:ArchiveToolEvents.Add('7-Zip uninstaller invoked')
            }

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            $script:ArchiveToolEvents | Should -Be @(
                'NanaZip provisioned'
                '7-Zip uninstaller validated'
                '7-Zip uninstaller invoked'
            )
        }
    }
}

Describe 'the 7-Zip uninstall-string parser' {
    # This helper is deliberately an exact 7-Zip recognizer, not a general
    # registry command-line parser.

    It 'accepts only the quoted expected path with an optional exact /S' {
        InModuleScope Atlas.Software {
            $expected = 'C:\Program Files\7-Zip\Uninstall.exe'
            foreach ($uninstallString in @(
                    '"C:\Program Files\7-Zip\Uninstall.exe"',
                    '"C:\Program Files\7-Zip\Uninstall.exe" /S'
                )) {
                $parsed = Get-AtlasParsedUninstallString `
                    -UninstallString $uninstallString `
                    -ExpectedFilePath $expected

                $parsed.FilePath | Should -BeExactly $expected
                $parsed.ArgumentList | Should -Be @('/S')
            }
        }
    }

    It 'rejects wrong paths, extra arguments, metacharacters, casing changes, and whitespace changes' {
        InModuleScope Atlas.Software {
            $expected = 'C:\Program Files\7-Zip\Uninstall.exe'
            foreach ($candidate in @(
                    'C:\Program Files\7-Zip\Uninstall.exe /S',
                    '"C:\Windows\System32\calc.exe" /S',
                    '"C:\Program Files\7-Zip\Uninstall.exe" /s',
                    '"C:\Program Files\7-Zip\Uninstall.exe" /S /D=C:\Temp',
                    '"C:\Program Files\7-Zip\Uninstall.exe" /S & calc.exe',
                    '"C:\Program Files\7-Zip\Uninstall.exe" ',
                    ' "C:\Program Files\7-Zip\Uninstall.exe" /S'
                )) {
                Get-AtlasParsedUninstallString `
                    -UninstallString $candidate `
                    -ExpectedFilePath $expected |
                    Should -BeNullOrEmpty -Because "'$candidate' is not the exact 7-Zip grammar"
            }
        }
    }

    It 'rejects an invalid expected execution path rather than generalizing the parser' {
        InModuleScope Atlas.Software {
            { Get-AtlasParsedUninstallString `
                    -UninstallString '"C:\Program Files\7-Zip\Uninstall.exe" /S' `
                    -ExpectedFilePath 'C:\Program Files\7-Zip\Uninstall.exe:evil' } |
                Should -Throw -ExpectedMessage '*alternate data stream*'
        }
    }

}
