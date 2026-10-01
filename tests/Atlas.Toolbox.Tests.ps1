BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PackagePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Operations\Toolbox-Package.ps1'
    $script:DownloadModulePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Download\Atlas.Download.psd1'

    Import-Module -Name $script:DownloadModulePath -Force
    . $script:PackagePath

    $systemRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
    $script:CommandHost = [IO.Path]::Combine($systemRoot, 'cmd.exe')
    $script:PowerShellHost = [IO.Path]::Combine($systemRoot, 'WindowsPowerShell', 'v1.0', 'powershell.exe')

    # Writes a batch file that starts a detached PowerShell descendant running $Command,
    # then exits with $ExitCode while the descendant keeps running.
    function New-DescendantProbe {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Command,
            [Parameter(Mandatory = $true)][int]$ExitCode
        )

        $probeText = @(
            '@echo off'
            ('start "" /b "{0}" -NoLogo -NoProfile -NonInteractive -Command "{1}"' -f
                $script:PowerShellHost, $Command)
            "exit /b $ExitCode"
            ''
        ) -join "`r`n"
        [IO.File]::WriteAllText($Path, $probeText, [Text.Encoding]::ASCII)
    }

    function Get-ProbeProcess {
        param([Parameter(Mandatory = $true)][string]$Token)

        @(Get-CimInstance -ClassName Win32_Process -Filter "Name = 'powershell.exe'" |
                Where-Object { $_.CommandLine -like "*$Token*" })
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
        Mock Get-AtlasLatestGitHubReleaseAsset { $latestAsset }
        Mock Test-AtlasToolboxInstallation { $true } -ParameterFilter {
            $ExpectedVersion -ceq '1.2.3'
        }
        Mock Write-AtlasNote
        Mock New-AtlasProtectedStagingDirectory { throw 'An installed Toolbox must not be staged again.' }
        Mock Invoke-AtlasPinnedDownload

        Install-AtlasToolboxPackage | Should -BeNullOrEmpty
        Should -Invoke Invoke-AtlasPinnedDownload -Times 0 -Exactly
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
        $marker = Join-Path $TestDrive 'descendant-complete.txt'
        $probe = Join-Path $TestDrive 'spawn-descendant.cmd'
        New-DescendantProbe -Path $probe -ExitCode 7 -Command ("Start-Sleep -Milliseconds 900; " +
            "[IO.File]::WriteAllText('$($marker.Replace("'", "''"))', 'complete')")

        $result = Invoke-AtlasContainedProcess -FilePath $script:CommandHost `
            -ArgumentList ([string[]]@('/d', '/s', '/c', 'call', $probe)) `
            -WorkingDirectory $TestDrive `
            -Description 'The download-boundary process probe' -Hidden -NoWindow

        $result.ExitCodeUInt32 | Should -Be 7
        $marker | Should -Exist -Because 'the call must not return before the descendant finishes'
        [IO.File]::ReadAllText($marker) | Should -BeExactly 'complete'
    }

    It 'terminates the complete process tree when its finite timeout expires' {
        $token = "atlas-timeout-probe-$([guid]::NewGuid().ToString('N'))"
        $probe = Join-Path $TestDrive 'spawn-timed-out-descendant.cmd'
        New-DescendantProbe -Path $probe -ExitCode 0 -Command "Start-Sleep -Seconds 30 # $token"

        try {
            {
                Invoke-AtlasContainedProcess -FilePath $script:CommandHost `
                    -ArgumentList ([string[]]@('/d', '/s', '/c', 'call', $probe)) `
                    -WorkingDirectory $TestDrive `
                    -Description 'The timeout process probe' `
                    -TimeoutSeconds 1 -Hidden -NoWindow
            } | Should -Throw -ExpectedMessage '*1-second timeout*process tree was terminated*'

            # A terminated process can linger briefly while its last handles close.
            $deadline = [DateTime]::UtcNow.AddSeconds(5)
            while ((Get-ProbeProcess -Token $token).Count -gt 0 -and [DateTime]::UtcNow -lt $deadline) {
                Start-Sleep -Milliseconds 100
            }
            Get-ProbeProcess -Token $token | Should -BeNullOrEmpty -Because 'the descendant must not outlive the timeout'
        }
        finally {
            Get-ProbeProcess -Token $token | ForEach-Object {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
