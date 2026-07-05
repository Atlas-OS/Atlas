BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
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

Describe 'Install-AtlasSoftware' {
    It 'rejects unknown components' {
        { Install-AtlasSoftware -Component 'NotARealComponent' } | Should -Throw
    }
}

Describe 'Assert-AtlasFileHash' {
    It 'passes when the file hash matches the expected SHA256' {
        $file = Join-Path -Path $TestDrive -ChildPath 'download.bin'
        Set-Content -LiteralPath $file -Value 'atlas test payload' -NoNewline
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash

        InModuleScope Atlas.Software -Parameters @{ Path = $file; Hash = $hash } {
            param($Path, $Hash)
            { Assert-AtlasFileHash -Path $Path -ExpectedSha256 $Hash -Description 'test file' } | Should -Not -Throw
        }
    }

    It 'throws a refusal when the file hash does not match' {
        $file = Join-Path -Path $TestDrive -ChildPath 'download.bin'
        Set-Content -LiteralPath $file -Value 'atlas test payload' -NoNewline

        InModuleScope Atlas.Software -Parameters @{ Path = $file } {
            param($Path)
            $wrongHash = 'deadbeef' * 8
            { Assert-AtlasFileHash -Path $Path -ExpectedSha256 $wrongHash -Description 'test file' } |
                Should -Throw -ExpectedMessage '*Refusing*'
        }
    }
}

Describe 'Assert-AtlasFileSignature' {
    It 'passes for a valid signature whose quoted subject CN matches the expected publisher' {
        InModuleScope Atlas.Software {
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

    It 'does not match a CN that is only a prefix of the signer CN' {
        InModuleScope Atlas.Software {
            Mock Get-AuthenticodeSignature {
                [pscustomobject]@{
                    Status            = [System.Management.Automation.SignatureStatus]::Valid
                    SignerCertificate = [pscustomobject]@{ Subject = 'CN=Google LLC Fake, O=Attacker, C=US' }
                }
            }

            { Assert-AtlasFileSignature -Path 'C:\fake\installer.msi' -ExpectedSubjectCn 'Google LLC' -Description 'Google Chrome' } |
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

Describe 'Get-AtlasCbsSafeModeListPath' {
    It 'points at the path Install-AtlasPackage.ps1 uses for the Safe Mode retry list' {
        InModuleScope Atlas.Software {
            Get-AtlasCbsSafeModeListPath | Should -Be (Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'safeModePackagesToInstall.atlasmodule')
        }
    }
}

Describe 'Remove-AtlasOneDriveUserFolder' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Software
    }

    It 'keeps a folder that still contains a real user file and logs a warning' {
        $folder = Join-Path -Path $TestDrive -ChildPath 'OneDrive-realfile'
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path -Path $folder -ChildPath 'Report.docx') -Value 'user data' -NoNewline

        InModuleScope Atlas.Software -Parameters @{ Path = $folder } {
            param($Path)
            Remove-AtlasOneDriveUserFolder -Path $Path
        }

        Test-Path -LiteralPath $folder | Should -BeTrue
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Software -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*Not deleting*'
        }
    }

    It 'deletes a folder that contains only desktop.ini' {
        $folder = Join-Path -Path $TestDrive -ChildPath 'OneDrive-desktopini'
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path -Path $folder -ChildPath 'desktop.ini') -Value '[.ShellClassInfo]' -NoNewline

        InModuleScope Atlas.Software -Parameters @{ Path = $folder } {
            param($Path)
            Remove-AtlasOneDriveUserFolder -Path $Path
        }

        Test-Path -LiteralPath $folder | Should -BeFalse
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Software -Times 0 -Exactly
    }

    It 'deletes an empty folder' {
        $folder = Join-Path -Path $TestDrive -ChildPath 'OneDrive-empty'
        New-Item -Path $folder -ItemType Directory -Force | Out-Null

        InModuleScope Atlas.Software -Parameters @{ Path = $folder } {
            param($Path)
            Remove-AtlasOneDriveUserFolder -Path $Path
        }

        Test-Path -LiteralPath $folder | Should -BeFalse
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Software -Times 0 -Exactly
    }

    It 'does not throw or log for a nonexistent path' {
        $folder = Join-Path -Path $TestDrive -ChildPath 'OneDrive-missing'

        InModuleScope Atlas.Software -Parameters @{ Path = $folder } {
            param($Path)
            { Remove-AtlasOneDriveUserFolder -Path $Path } | Should -Not -Throw
        }

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Software -Times 0 -Exactly
    }

    It 'keeps a folder whose only file is in a nested subdirectory' {
        $folder = Join-Path -Path $TestDrive -ChildPath 'OneDrive-nested'
        $nested = Join-Path -Path $folder -ChildPath 'Documents\Projects'
        New-Item -Path $nested -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path -Path $nested -ChildPath 'notes.txt') -Value 'nested data' -NoNewline

        InModuleScope Atlas.Software -Parameters @{ Path = $folder } {
            param($Path)
            Remove-AtlasOneDriveUserFolder -Path $Path
        }

        Test-Path -LiteralPath $folder | Should -BeTrue
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Software -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*Not deleting*'
        }
    }
}

Describe 'Start-AtlasSoftwareInstaller' {
    It 'runs the installer hidden/waited and returns quietly on a success exit code (0)' {
        InModuleScope Atlas.Software {
            Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

            { Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Test' } |
                Should -Not -Throw

            # The mutating launch is invoked with the exact file/args and the hidden, waited,
            # pass-through switches the exit-code contract depends on.
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq 'C:\fake\setup.exe' -and
                $ArgumentList -eq '/S' -and
                $Wait -and $PassThru
            }
        }
    }

    It 'throws with the failing exit code when the installer returns a non-success code' {
        InModuleScope Atlas.Software {
            Mock Start-Process { [pscustomobject]@{ ExitCode = 1 } }

            { Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Test' } |
                Should -Throw -ExpectedMessage '*failed with exit code 1*'
        }
    }

    It 'treats a caller-supplied additional success code (3010, reboot required) as success' {
        InModuleScope Atlas.Software {
            Mock Start-Process { [pscustomobject]@{ ExitCode = 3010 } }

            { Start-AtlasSoftwareInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Test' -SuccessExitCode @(0, 3010) } |
                Should -Not -Throw
        }
    }
}

Describe 'Start-AtlasSoftwareOptionalInstaller' {
    It 'swallows an installer failure and logs a single warning instead of throwing' {
        InModuleScope Atlas.Software {
            Mock Start-Process { [pscustomobject]@{ ExitCode = 1 } }
            Mock Write-AtlasLog

            { Start-AtlasSoftwareOptionalInstaller -FilePath 'C:\fake\setup.exe' -ArgumentList '/S' -Description 'Optional thing' } |
                Should -Not -Throw

            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like '*failed with exit code 1*'
            }
        }
    }
}

Describe 'Install-AtlasArchiveTool asset selection' {
    It 'selects the .msixbundle + .xml pair and installs NanaZip when the GitHub API responds' {
        InModuleScope Atlas.Software {
            Mock Invoke-RestMethod {
                [pscustomobject]@{
                    Assets = @(
                        [pscustomobject]@{ browser_download_url = 'https://example.test/NanaZip.msixbundle' }
                        [pscustomobject]@{ browser_download_url = 'https://example.test/NanaZip.xml' }
                        [pscustomobject]@{ browser_download_url = 'https://example.test/NanaZip.sha256' }
                        [pscustomobject]@{ browser_download_url = 'https://example.test/NanaZip.exe' }
                    )
                }
            }
            Mock Get-AppxProvisionedPackage { @() }
            # No existing 7-Zip install, so the code path goes straight to NanaZip.
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*7-Zip*' } -MockWith { $false }
            Mock Install-AtlasNanaZip
            Mock Install-Atlas7Zip

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            Should -Invoke Install-AtlasNanaZip -Times 1 -Exactly -ParameterFilter {
                @($Assets).Count -eq 2 -and
                (($Assets -join ';') -like '*NanaZip.msixbundle*') -and
                (($Assets -join ';') -like '*NanaZip.xml*') -and
                (($Assets -join ';') -notlike '*NanaZip.sha256*') -and
                (($Assets -join ';') -notlike '*NanaZip.exe*')
            }
            Should -Invoke Install-Atlas7Zip -Times 0 -Exactly
        }
    }

    It 'falls back to 7-Zip and warns when the GitHub API is unreachable' {
        InModuleScope Atlas.Software {
            Mock Invoke-RestMethod { $null }
            Mock Get-AppxProvisionedPackage { @() }
            Mock Install-AtlasNanaZip
            Mock Install-Atlas7Zip
            Mock Write-AtlasLog

            Install-AtlasArchiveTool -TempDir 'C:\fake\temp'

            Should -Invoke Install-Atlas7Zip -Times 1 -Exactly
            Should -Invoke Install-AtlasNanaZip -Times 0 -Exactly
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {
                $Level -eq 'Warning' -and $Message -like "*GitHub API*"
            }
        }
    }
}

Describe 'the 7-Zip uninstall-string parser' {
    # Get-AtlasParsedUninstallString accepts only the documented, quoted 7-Zip shape
    # and never hands registry-sourced text to a shell; it is module-private, hence
    # InModuleScope.

    It 'parses a quoted exe path with trailing arguments' {
        InModuleScope Atlas.Software {
            $parsed = Get-AtlasParsedUninstallString -UninstallString '"C:\Program Files\7-Zip\Uninstall.exe" /S'

            $parsed | Should -Not -BeNullOrEmpty
            $parsed.FilePath | Should -Be 'C:\Program Files\7-Zip\Uninstall.exe'
            $parsed.ArgumentList | Should -Be '/S'
        }
    }

    It 'defaults the arguments to /S when only a quoted path is present' {
        InModuleScope Atlas.Software {
            $parsed = Get-AtlasParsedUninstallString -UninstallString '"C:\Program Files\7-Zip\Uninstall.exe"'

            $parsed | Should -Not -BeNullOrEmpty
            $parsed.FilePath | Should -Be 'C:\Program Files\7-Zip\Uninstall.exe'
            $parsed.ArgumentList | Should -Be '/S'
        }
    }

    It 'rejects an unquoted, metacharacter-bearing string' {
        InModuleScope Atlas.Software {
            Get-AtlasParsedUninstallString -UninstallString 'C:\x.exe & calc' | Should -BeNullOrEmpty
        }
    }

    It 'rejects an empty-quotes-free string' {
        InModuleScope Atlas.Software {
            Get-AtlasParsedUninstallString -UninstallString 'C:\Program Files\7-Zip\Uninstall.exe /S' | Should -BeNullOrEmpty
        }
    }
}
