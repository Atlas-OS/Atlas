BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PackagePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\Toolbox-Package.ps1'
    $script:DownloadModulePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Download\Atlas.Download.psd1'

    Import-Module -Name $script:DownloadModulePath -Force
    . $script:PackagePath

    function Wait-ForMarkerFile {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][int]$TimeoutSeconds
        )

        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while ([DateTime]::UtcNow -lt $deadline) {
            if ([IO.File]::Exists($Path)) {
                return $true
            }
            Start-Sleep -Milliseconds 100
        }
        return [IO.File]::Exists($Path)
    }
}

Describe 'Atlas Toolbox latest-channel integrity contract' {
    It 'requests the latest stable Toolbox asset without a pinned version' {
        $latestAsset = [pscustomobject]@{
            Version = '1.2.3'
            Uri     = [uri]'https://example.test/AtlasToolbox-Setup.exe'
            Sha256 = 'a' * 64
            Size    = 123456
        }
        Mock Get-AtlasLatestGitHubReleaseAsset { $latestAsset } -ParameterFilter {
            $Owner -ceq 'Atlas-OS' -and
            $Repository -ceq 'atlas-toolbox' -and
            $AssetName -ceq 'AtlasToolbox-Setup.exe' -and
            $ExpectedRepositoryId -eq 929016610 -and
            $ExpectedOwnerId -eq 78708182
        }
        Mock Test-AtlasToolboxInstallation { $true } -ParameterFilter {
            $ExpectedVersion -ceq '1.2.3'
        }
        Mock Write-AtlasNote

        Install-AtlasToolboxPackage | Should -BeNullOrEmpty
        Should -Invoke Write-AtlasNote -Times 1 -Exactly -ParameterFilter {
            $Text -ceq 'AtlasOS Toolbox 1.2.3 is already installed.'
        }
        Should -Invoke Get-AtlasLatestGitHubReleaseAsset -Times 1 -Exactly `
            -ParameterFilter {
                $Owner -ceq 'Atlas-OS' -and
                $Repository -ceq 'atlas-toolbox' -and
                $AssetName -ceq 'AtlasToolbox-Setup.exe' -and
                $ExpectedRepositoryId -eq 929016610 -and
                $ExpectedOwnerId -eq 78708182
            }
    }

    It 'binds each resolved latest asset to exact GitHub identity, bytes, and digest' {
        $release = [pscustomobject]@{
            draft      = $false
            prerelease = $false
            tag_name   = 'v1.2.3'
            assets     = @(
                [pscustomobject]@{
                    id                   = 42
                    name                 = 'AtlasToolbox-Setup.exe'
                    state                = 'uploaded'
                    size                 = 123456
                    digest               = 'sha256:' + ('a' * 64)
                    browser_download_url = 'https://github.com/Atlas-OS/atlas-toolbox/releases/download/v1.2.3/AtlasToolbox-Setup.exe'
                }
            )
        }

        # The resolver is private to Atlas.Download; reach it through the module scope.
        InModuleScope Atlas.Download -Parameters @{ Release = $release } {
            param($Release)

            $asset = Resolve-AtlasGitHubReleaseAssetMetadata `
                -Release $Release `
                -Owner 'Atlas-OS' `
                -Repository 'atlas-toolbox' `
                -AssetName 'AtlasToolbox-Setup.exe'
            $asset.Version | Should -BeExactly '1.2.3'
            $asset.AssetId | Should -Be 42
            $asset.Size | Should -Be 123456
            $asset.Sha256 | Should -BeExactly ('a' * 64)

            $Release.assets[0].digest = $null
            {
                Resolve-AtlasGitHubReleaseAssetMetadata `
                    -Release $Release -Owner Atlas-OS -Repository atlas-toolbox `
                    -AssetName AtlasToolbox-Setup.exe
            } | Should -Throw '*complete upload*'

            $Release.assets[0].digest = 'sha256:' + ('a' * 64)
            $Release.assets[0].browser_download_url = 'https://example.test/AtlasToolbox-Setup.exe'
            {
                Resolve-AtlasGitHubReleaseAssetMetadata `
                    -Release $Release -Owner Atlas-OS -Repository atlas-toolbox `
                    -AssetName AtlasToolbox-Setup.exe
            } | Should -Throw '*canonical repository and tag*'
        }
    }

    It 'accepts only the expected installed version at a normal non-empty path' {
        $programFilesRoot = Join-Path $TestDrive 'Program Files'
        $installDirectory = Join-Path $programFilesRoot 'Atlas Toolbox'
        $toolboxPath = Join-Path $installDirectory 'AtlasToolbox.exe'
        [void](New-Item -Path $installDirectory -ItemType Directory -Force)
        [IO.File]::WriteAllBytes($toolboxPath, [byte[]](1, 2, 3))

        $script:InstalledVersion = '1.2.3'
        Mock Get-ItemPropertyValue { $script:InstalledVersion }
        Test-AtlasToolboxInstallation -ExpectedVersion '1.2.3' `
            -ProgramFilesRoot $programFilesRoot | Should -BeTrue

        $script:InstalledVersion = '1.2.2'
        Test-AtlasToolboxInstallation -ExpectedVersion '1.2.3' `
            -ProgramFilesRoot $programFilesRoot | Should -BeFalse

        [IO.File]::WriteAllBytes($toolboxPath, [byte[]]@())
        {
            Test-AtlasToolboxInstallation -ExpectedVersion '1.2.3' `
                -ProgramFilesRoot $programFilesRoot
        } | Should -Throw '*not a normal non-empty file*'
    }

}

Describe 'Shared download boundary' {
    It 'rejects non-HTTPS input and removes an incomplete destination' {
        $destination = Join-Path $TestDrive 'rejected-download.bin'

        {
            Invoke-AtlasPinnedDownload -Uri 'http://example.test/payload.bin' `
                -Destination $destination -Sha256 ('0' * 64) -ExpectedBytes 1
        } | Should -Throw '*Only HTTPS*'

        Test-Path -LiteralPath $destination | Should -BeFalse
    }

    It 'keeps a download only after its exact byte length and SHA-256 match' {
        $source = Join-Path $TestDrive 'expected-payload.bin'
        $destination = Join-Path $TestDrive 'verified-payload.bin'
        [IO.File]::WriteAllBytes($source, [Text.Encoding]::UTF8.GetBytes('atlas payload'))
        $expectedBytes = [IO.File]::ReadAllBytes($source)
        $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        # Invoke-AtlasPinnedDownload calls the HTTP helper inside Atlas.Download, so the
        # mock must live in the module; its body runs there too and reads the source file
        # from a fixed environment hook instead of this test's scope.
        $env:ATLAS_TEST_DOWNLOAD_SOURCE = $source
        try {
            Mock Invoke-AtlasBoundedHttpGet -ModuleName Atlas.Download -MockWith {
                $bytes = [IO.File]::ReadAllBytes($env:ATLAS_TEST_DOWNLOAD_SOURCE)
                $OutputStream.Write($bytes, 0, $bytes.Length)
                return $bytes.Length
            }

            $result = Invoke-AtlasPinnedDownload -Uri 'https://example.test/payload.bin' `
                -Destination $destination -Sha256 $hash `
                -ExpectedBytes $expectedBytes.Length
        }
        finally {
            Remove-Item Env:\ATLAS_TEST_DOWNLOAD_SOURCE -ErrorAction SilentlyContinue
        }

        Should -Invoke Invoke-AtlasBoundedHttpGet -ModuleName Atlas.Download -Times 1 -Exactly `
            -ParameterFilter { [string]$Uri -eq 'https://example.test/payload.bin' }
        $result | Should -BeExactly $destination
        [IO.File]::ReadAllBytes($destination) | Should -Be $expectedBytes
    }

    It 'waits for an exact native executable and its longer-lived descendant' {
        $commandHost = [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::System),
            'cmd.exe'
        )
        $powerShellHost = [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::System),
            'WindowsPowerShell',
            'v1.0',
            'powershell.exe'
        )
        $marker = Join-Path $TestDrive 'descendant-complete.txt'
        $probe = Join-Path $TestDrive 'spawn-descendant.cmd'
        $childCommand = "Start-Sleep -Milliseconds 900; " +
            "[IO.File]::WriteAllText('$($marker.Replace("'", "''"))', 'complete')"
        $probeText = @(
            '@echo off'
            ('start "" /b "{0}" -NoLogo -NoProfile -NonInteractive -Command "{1}"' -f
                $powerShellHost, $childCommand)
            'exit /b 7'
            ''
        ) -join "`r`n"
        [IO.File]::WriteAllText($probe, $probeText, [Text.Encoding]::ASCII)

        $result = Invoke-AtlasContainedProcess -FilePath $commandHost `
            -ArgumentList ([string[]]@('/d', '/s', '/c', 'call', $probe)) `
            -WorkingDirectory $TestDrive `
            -Description 'The download-boundary process probe' -Hidden -NoWindow

        $result.ExitCodeUInt32 | Should -Be 7
        # The tree wait must cover the descendant; the short poll only absorbs
        # file-visibility latency, not descendant runtime.
        Wait-ForMarkerFile -Path $marker -TimeoutSeconds 5 | Should -BeTrue
        [IO.File]::ReadAllText($marker) | Should -BeExactly 'complete'
    }

    It 'terminates the complete process tree when its finite timeout expires' {
        $commandHost = [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::System),
            'cmd.exe'
        )
        $powerShellHost = [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::System),
            'WindowsPowerShell',
            'v1.0',
            'powershell.exe'
        )
        $marker = Join-Path $TestDrive 'timed-out-descendant.txt'
        $probe = Join-Path $TestDrive 'spawn-timed-out-descendant.cmd'
        $childCommand = "Start-Sleep -Milliseconds 1500; " +
            "[IO.File]::WriteAllText('$($marker.Replace("'", "''"))', 'escaped')"
        $probeText = @(
            '@echo off'
            ('start "" /b "{0}" -NoLogo -NoProfile -NonInteractive -Command "{1}"' -f
                $powerShellHost, $childCommand)
            'exit /b 0'
            ''
        ) -join "`r`n"
        [IO.File]::WriteAllText($probe, $probeText, [Text.Encoding]::ASCII)

        {
            Invoke-AtlasContainedProcess -FilePath $commandHost `
                -ArgumentList ([string[]]@('/d', '/s', '/c', 'call', $probe)) `
                -WorkingDirectory $TestDrive `
                -Description 'The timeout process probe' `
                -TimeoutSeconds 1 -Hidden -NoWindow
        } | Should -Throw -ExpectedMessage '*1-second timeout*process tree was terminated*'

        # An escaped descendant was spawned before the timeout throw and would write
        # its marker about 1500ms later. Poll well past that point and require that
        # the marker never appears; the poll returns early on escape.
        Wait-ForMarkerFile -Path $marker -TimeoutSeconds 4 | Should -BeFalse
    }
}
