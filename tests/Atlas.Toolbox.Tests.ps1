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
    BeforeAll {
        function New-ToolboxRepositoryFixture {
            [pscustomobject]@{
                id        = 929016610
                full_name = 'Atlas-OS/atlas-toolbox'
                private   = $false
                archived  = $false
                owner     = [pscustomobject]@{ id = 78708182; login = 'Atlas-OS' }
            }
        }

        function New-ToolboxReleaseFixture {
            [pscustomobject]@{
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
        }
    }

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

    It 'binds each resolved latest asset to its canonical release URL, bytes, and digest' {
        # The resolver is private to Atlas.Download; reach it through the module scope.
        InModuleScope Atlas.Download -Parameters @{ Release = (New-ToolboxReleaseFixture) } {
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

    Context 'Pinned repository identity' {
        BeforeEach {
            $script:Repository = New-ToolboxRepositoryFixture
            $script:Release = New-ToolboxReleaseFixture
            # The resolver calls the API helper inside Atlas.Download, so the mock lives
            # there. Any other request fails rather than reaching GitHub.
            Mock Invoke-AtlasGitHubApiJson -ModuleName Atlas.Download -MockWith {
                switch -CaseSensitive ($Uri.AbsoluteUri) {
                    'https://api.github.com/repos/Atlas-OS/atlas-toolbox' { return $script:Repository }
                    'https://api.github.com/repos/Atlas-OS/atlas-toolbox/releases/latest' { return $script:Release }
                    default { throw "Unexpected GitHub API request '$Uri'." }
                }
            }
        }

        It 'returns the latest asset from the pinned repository' {
            $asset = Get-AtlasLatestGitHubReleaseAsset -Owner Atlas-OS -Repository atlas-toolbox `
                -AssetName AtlasToolbox-Setup.exe -ExpectedRepositoryId 929016610 -ExpectedOwnerId 78708182

            $asset.Version | Should -BeExactly '1.2.3'
            $asset.Sha256 | Should -BeExactly ('a' * 64)
            $asset.Size | Should -Be 123456
            Should -Invoke Invoke-AtlasGitHubApiJson -ModuleName Atlas.Download -Times 2 -Exactly
        }

        It 'rejects <Case> before requesting release metadata' -TestCases @(
            @{ Case = 'another repository ID'; Field = 'id'; Value = 929016611 }
            @{ Case = 'a non-numeric repository ID'; Field = 'id'; Value = 'atlas-toolbox' }
            @{ Case = 'another owner ID'; Field = 'owner.id'; Value = 78708183 }
            @{ Case = 'another owner login'; Field = 'owner.login'; Value = 'atlas-os' }
            @{ Case = 'another full name'; Field = 'full_name'; Value = 'atlas-os/atlas-toolbox' }
            @{ Case = 'a private repository'; Field = 'private'; Value = $true }
            @{ Case = 'an archived repository'; Field = 'archived'; Value = $true }
        ) {
            param($Field, $Value)

            $metadata = if ($Field -like 'owner.*') { $script:Repository.owner } else { $script:Repository }
            $metadata.PSObject.Properties[$Field -replace '^owner\.'].Value = $Value

            {
                Get-AtlasLatestGitHubReleaseAsset -Owner Atlas-OS -Repository atlas-toolbox `
                    -AssetName AtlasToolbox-Setup.exe -ExpectedRepositoryId 929016610 -ExpectedOwnerId 78708182
            } | Should -Throw '*expected repository identity*'
            Should -Invoke Invoke-AtlasGitHubApiJson -ModuleName Atlas.Download -Times 0 -Exactly `
                -ParameterFilter { $Uri.AbsolutePath -like '*/releases/latest' }
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

    It 'keeps a download whose byte length and SHA-256 match' {
        $destination = Join-Path $TestDrive 'verified-download.bin'
        $received = [Text.Encoding]::UTF8.GetBytes('atlas download')
        $hash = (Get-FileHash -InputStream ([IO.MemoryStream]::new($received)) -Algorithm SHA256).Hash
        # Invoke-AtlasPinnedDownload calls the HTTP helper inside Atlas.Download, so the
        # mock must live in the module.
        Mock Invoke-AtlasBoundedHttpGet -ModuleName Atlas.Download -MockWith {
            $OutputStream.Write($received, 0, $received.Length)
            return [long]$received.Length
        }

        $result = Invoke-AtlasPinnedDownload -Uri 'https://example.test/download.bin' `
            -Destination $destination -Sha256 $hash -ExpectedBytes $received.Length

        Should -Invoke Invoke-AtlasBoundedHttpGet -ModuleName Atlas.Download -Times 1 -Exactly `
            -ParameterFilter { [string]$Uri -eq 'https://example.test/download.bin' }
        $result | Should -BeExactly $destination
        [IO.File]::ReadAllBytes($destination) | Should -Be $received
    }

    It 'deletes a download whose SHA-256 does not match' {
        $destination = Join-Path $TestDrive 'mismatched-download.bin'
        $received = [Text.Encoding]::UTF8.GetBytes('atlas download')
        Mock Invoke-AtlasBoundedHttpGet -ModuleName Atlas.Download -MockWith {
            $OutputStream.Write($received, 0, $received.Length)
            return [long]$received.Length
        }

        {
            Invoke-AtlasPinnedDownload -Uri 'https://example.test/download.bin' `
                -Destination $destination -Sha256 ('0' * 64) -ExpectedBytes $received.Length
        } | Should -Throw '*SHA-256*does not match*'

        Test-Path -LiteralPath $destination | Should -BeFalse
    }

    It 'deletes a download that ends before its expected byte length' {
        $destination = Join-Path $TestDrive 'short-download.bin'
        $received = [Text.Encoding]::UTF8.GetBytes('atlas')
        # The hash matches the bytes received, so only the length check can reject them.
        $hash = (Get-FileHash -InputStream ([IO.MemoryStream]::new($received)) -Algorithm SHA256).Hash
        Mock Invoke-AtlasBoundedHttpGet -ModuleName Atlas.Download -MockWith {
            $OutputStream.Write($received, 0, $received.Length)
            return [long]$received.Length
        }

        {
            Invoke-AtlasPinnedDownload -Uri 'https://example.test/download.bin' `
                -Destination $destination -Sha256 $hash -ExpectedBytes 13
        } | Should -Throw '*returned 5 bytes; expected 13*'

        Test-Path -LiteralPath $destination | Should -BeFalse
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
