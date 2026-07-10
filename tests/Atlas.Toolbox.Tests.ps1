BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PackagePath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Toolbox-Package.ps1'
    $script:EntryPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Install-Toolbox.ps1'
    $script:DownloadIntegrityPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Download-Integrity.ps1'
    $script:LauncherPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasDesktop\Install AtlasOS Toolbox.cmd'

    $script:PackageSource = Get-Content -LiteralPath $script:PackagePath -Raw
    $script:EntrySource = Get-Content -LiteralPath $script:EntryPath -Raw
    $script:LauncherSource = Get-Content -LiteralPath $script:LauncherPath -Raw
    . $script:DownloadIntegrityPath
    . $script:PackagePath
}

Describe 'Atlas Toolbox latest-channel integrity contract' {
    It 'resolves latest without coupling the playbook to a Toolbox version' {
        $script:PackageSource | Should -Match 'Get-AtlasLatestGitHubReleaseAsset'
        $script:PackageSource | Should -Match "-Owner 'Atlas-OS'"
        $script:PackageSource | Should -Match "-Repository 'atlas-toolbox'"
        $script:PackageSource | Should -Match "-AssetName 'AtlasToolbox-Setup\.exe'"
        $script:PackageSource | Should -Not -Match '\$toolboxVersion\s*='
        $script:PackageSource | Should -Match 'accepts control of the[\s\S]+?GitHub repository as its publisher authority'
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

        $asset = Resolve-AtlasGitHubReleaseAssetMetadata `
            -Release $release `
            -Owner 'Atlas-OS' `
            -Repository 'atlas-toolbox' `
            -AssetName 'AtlasToolbox-Setup.exe'
        $asset.Version | Should -BeExactly '1.2.3'
        $asset.AssetId | Should -Be 42
        $asset.Size | Should -Be 123456
        $asset.Sha256 | Should -BeExactly ('a' * 64)

        $release.assets[0].digest = $null
        {
            Resolve-AtlasGitHubReleaseAssetMetadata `
                -Release $release -Owner Atlas-OS -Repository atlas-toolbox `
                -AssetName AtlasToolbox-Setup.exe
        } | Should -Throw '*complete upload*'

        $release.assets[0].digest = 'sha256:' + ('a' * 64)
        $release.assets[0].browser_download_url = 'https://example.test/AtlasToolbox-Setup.exe'
        {
            Resolve-AtlasGitHubReleaseAssetMetadata `
                -Release $release -Owner Atlas-OS -Repository atlas-toolbox `
                -AssetName AtlasToolbox-Setup.exe
        } | Should -Throw '*canonical repository and tag*'
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

    It 'uses protected staging and drains the installer tree before postconditions' {
        $script:PackageSource | Should -Match '\$tempDirectory = New-AtlasProtectedStagingDirectory'
        $script:PackageSource | Should -Match 'Invoke-AtlasPinnedDownload[\s\S]+?-Sha256 \$toolboxRelease\.Sha256[\s\S]+?-ExpectedBytes \$toolboxRelease\.Size'
        $script:PackageSource | Should -Match 'Invoke-AtlasContainedProcess[\s\S]+?-FilePath \$toolboxPath[\s\S]+?-TimeoutSeconds 1800'
        $script:PackageSource | Should -Match '\$installerResult\.ContainmentConfirmed[\s\S]+?\$installerResult\.RootExited[\s\S]+?\$installerResult\.JobDrained'
        $script:PackageSource | Should -Not -Match 'Start-Process|Wait-AtlasProcessWithTimeout|GetTempPath|\$env:TEMP'
    }

    It 'crosses UAC with one typed compatibility token and exact signed exit propagation' {
        $script:LauncherSource | Should -Match '%__APPDIR__%WindowsPowerShell\\v1\.0\\powershell\.exe'
        $script:LauncherSource | Should -Match 'set "AtlasLauncherArgument=%~1"'
        $script:LauncherSource | Should -Not -Match '(?im)%\*|___args|%ComSpec%|%ERRORLEVEL%|^\s*powershell(?:\.exe)?\s'
        $script:LauncherSource | Should -Match '\$p\.Verb=''runas'''
        $script:LauncherSource | Should -Match 'NativeErrorCode -eq 1223\)\{exit 1223\}'
        $script:LauncherSource | Should -Match '(?m)^\s*if errorlevel 1 exit /b\r?\n\s*if not errorlevel 0 exit /b\r?$'
        $script:EntrySource | Should -Match 'Unsupported Toolbox launcher argument'
        $script:EntrySource | Should -Match 'Toolbox-Package\.ps1[\s\S]+?Install-AtlasToolboxPackage'
    }
}
