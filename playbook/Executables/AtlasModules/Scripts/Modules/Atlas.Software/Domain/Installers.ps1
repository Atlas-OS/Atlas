# Atlas.Software domain: install-time software downloads.

function Get-AtlasSoftwareComponentMap {
    # Component -> installer function. 'SevenZip' maps to the archive-tool installer,
    # which prefers NanaZip and falls back to 7-Zip.
    return @{
        SevenZip  = 'Install-AtlasArchiveTool'
        VCRedist  = 'Install-AtlasVisualCppRuntimes'
        DirectX   = 'Install-AtlasDirectXRuntime'
        Brave     = 'Install-AtlasBraveBrowser'
        Firefox   = 'Install-AtlasFirefoxBrowser'
        LibreWolf = 'Install-AtlasLibreWolfBrowser'
        Chrome    = 'Install-AtlasChromeBrowser'
        Toolbox   = 'Install-AtlasToolbox'
    }
}

function Test-AtlasSoftwareArm64 {
    [CmdletBinding()]
    param()

    $computerSystems = @(Get-CimInstance `
            -ClassName Win32_ComputerSystem `
            -ErrorAction Stop)
    if ($computerSystems.Count -ne 1) {
        throw "Expected exactly one Win32_ComputerSystem result, but received $($computerSystems.Count)."
    }

    $systemType = [string]$computerSystems[0].SystemType
    switch -CaseSensitive ($systemType) {
        'ARM64-based PC' { return $true }
        'x64-based PC' { return $false }
        default {
            throw "Unsupported or unreadable Win32_ComputerSystem SystemType '$systemType'."
        }
    }
}

function Invoke-AtlasSoftwareDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$Description,
        [ValidateRange(1, 1073741824)][long]$MaximumBytes = 1073741824,
        [ValidateRange(1, 3600)][int]$MaximumSeconds = 900
    )

    if ($Uri.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($Uri.UserInfo)) {
        throw "Only HTTPS software download URIs without user information are allowed: '$Uri'."
    }
    if ([string]::IsNullOrWhiteSpace($Destination) -or
        $Destination.IndexOf([char]0) -ge 0 -or
        $Destination -notmatch '^[A-Za-z]:[\\/]' -or
        [IO.Path]::GetFullPath($Destination).Substring(2).Contains(':')) {
        throw 'A software download destination must be an explicit local path without an alternate data stream.'
    }

    $destinationPath = [IO.Path]::GetFullPath($Destination)
    if ([IO.File]::Exists($destinationPath) -or [IO.Directory]::Exists($destinationPath)) {
        throw "The software download destination '$destinationPath' already exists."
    }
    $destinationParent = [IO.Path]::GetDirectoryName($destinationPath)
    $resolvedParent = Resolve-AtlasProtectedExecutionPath `
        -Path $destinationParent `
        -PathType Container `
        -Description 'The software download directory'
    if (-not $resolvedParent.Equals($destinationParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The software download directory '$destinationParent' did not resolve to its exact path."
    }

    Write-Host "Downloading $Description..."
    try {
        $stream = [IO.File]::Open(
            $destinationPath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        try {
            $bytes = Invoke-AtlasBoundedHttpGet `
                -Uri $Uri `
                -OutputStream $stream `
                -MaximumBytes $MaximumBytes `
                -MaximumSeconds $MaximumSeconds `
                -AllowRedirect
        }
        finally {
            $stream.Dispose()
        }
        if ($bytes -lt 1) {
            throw "Downloading $Description from '$Uri' returned an empty file."
        }
        return (Get-Item -LiteralPath $destinationPath -Force -ErrorAction Stop).FullName
    }
    catch {
        Remove-Item -LiteralPath $destinationPath -Force -ErrorAction SilentlyContinue
        throw
    }
}

function Assert-AtlasFileSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedSubjectCn,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $resolvedPath = Resolve-AtlasProtectedExecutionPath `
        -Path $Path -PathType Leaf -Description "The $Description installer"
    $signature = Get-AuthenticodeSignature -LiteralPath $resolvedPath -ErrorAction Stop
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
        $null -eq $signature.SignerCertificate) {
        throw "The $Description installer's Authenticode signature is not valid (status: $($signature.Status)). Refusing to run an untrusted installer."
    }

    $subject = $signature.SignerCertificate.Subject
    $cnMatches = [regex]::Matches(
        $subject,
        '(?:^|,\s*)CN=',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $escapedCn = [regex]::Escape($ExpectedSubjectCn)
    $subjectPattern = '(?:^|,\s*)CN=(?:"' + $escapedCn + '"|' + $escapedCn + ')(?=,|$)'
    if ($cnMatches.Count -ne 1 -or
        -not [regex]::IsMatch(
            $subject,
            $subjectPattern,
            [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )) {
        throw "The $Description installer is signed by '$subject' instead of the expected publisher 'CN=$ExpectedSubjectCn'. Refusing to run."
    }
}

function Assert-AtlasFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $resolvedPath = Resolve-AtlasProtectedExecutionPath `
        -Path $Path -PathType Leaf -Description "The $Description download"
    $actual = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($actual -ne $ExpectedSha256) {
        throw "The $Description download's SHA256 '$actual' does not match the expected '$ExpectedSha256'. Refusing to run an untrusted file."
    }
}

function Start-AtlasSoftwareInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [AllowEmptyCollection()][string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$Description,
        [uint32[]]$SuccessExitCode = @(0)
    )

    Write-Host "Installing $Description..."
    $workingDirectory = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($FilePath))
    $result = Invoke-AtlasContainedProcess `
        -FilePath $FilePath `
        -ArgumentList ([string[]]$ArgumentList) `
        -WorkingDirectory $workingDirectory `
        -Description "The $Description installer" `
        -Hidden `
        -NoWindow
    $exitCode = [uint32]$result.ExitCodeUInt32
    if ($exitCode -notin $SuccessExitCode) {
        throw "Installing $Description failed with exit code $exitCode."
    }
}

function Start-AtlasSoftwareOptionalInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [AllowEmptyCollection()][string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$Description,
        [uint32[]]$SuccessExitCode = @(0)
    )

    try {
        Start-AtlasSoftwareInstaller `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -Description $Description `
            -SuccessExitCode $SuccessExitCode
        return $true
    }
    catch {
        if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
            throw
        }
        Write-AtlasLog -Level Warning -Message $_.Exception.Message
        return $false
    }
}

function Invoke-AtlasSoftwareApiJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $memory = New-Object IO.MemoryStream
    try {
        [void](Invoke-AtlasBoundedHttpGet `
                -Uri $Uri `
                -OutputStream $memory `
                -MaximumBytes 1048576 `
                -MaximumSeconds 30)
        $utf8 = New-Object Text.UTF8Encoding($false, $true)
        return ($utf8.GetString($memory.ToArray()) |
                Microsoft.PowerShell.Utility\ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        throw "$Description could not be read: $($_.Exception.Message)"
    }
    finally {
        $memory.Dispose()
    }
}

function Resolve-AtlasLibreWolfReleaseMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Release,
        [Parameter(Mandatory = $true)]
        [ValidateSet('x86_64', 'arm64')]
        [string]$Architecture
    )

    $tag = [string]$Release.tag_name
    if ($Release.draft -isnot [bool] -or $Release.draft -or
        $Release.prerelease -isnot [bool] -or $Release.prerelease -or
        $tag -cnotmatch '^[0-9]+\.[0-9]+(?:\.[0-9]+)?-[0-9]+$') {
        throw 'Codeberg latest-release metadata is not a stable LibreWolf release.'
    }

    $assetName = "librewolf-$tag-windows-$Architecture-setup.exe"
    $assets = @($Release.assets | Where-Object { [string]$_.name -ceq $assetName })
    if ($assets.Count -ne 1) {
        throw "Codeberg latest-release metadata did not contain exactly one '$assetName' asset."
    }
    $asset = $assets[0]
    $expectedUrl = "https://dl.librewolf.net/librewolf/$tag/$assetName"
    if ([string]$asset.browser_download_url -cne $expectedUrl) {
        throw "Codeberg's '$assetName' asset does not use the canonical LibreWolf download URL."
    }

    return [pscustomobject]@{
        Tag  = $tag
        Name = $assetName
        Uri  = [uri]$expectedUrl
    }
}

function Resolve-AtlasLibreWolfWingetManifestHash {
    <#
    .SYNOPSIS
        Resolves LibreWolf's installer hash from Microsoft's independent WinGet
        manifest repository and binds it to the selected Codeberg release.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$ContentMetadata,
        [Parameter(Mandatory = $true)]$ReleaseMetadata,
        [Parameter(Mandatory = $true)]
        [ValidateSet('x86_64', 'arm64')]
        [string]$Architecture
    )

    foreach ($propertyName in @('Tag', 'Uri')) {
        if ($null -eq $ReleaseMetadata.PSObject.Properties[$propertyName]) {
            throw "LibreWolf release metadata is missing '$propertyName'."
        }
    }
    $tag = [string]$ReleaseMetadata.Tag
    if ($tag -cnotmatch '^[0-9]+\.[0-9]+(?:\.[0-9]+)?-[0-9]+$') {
        throw 'LibreWolf release metadata cannot address an independent WinGet manifest.'
    }

    if ([string]$ContentMetadata.encoding -cne 'base64' -or
        [string]::IsNullOrWhiteSpace([string]$ContentMetadata.content)) {
        throw 'Microsoft winget-pkgs did not return a base64 installer manifest.'
    }

    try {
        $encodedContent = ([string]$ContentMetadata.content) -replace '\s', ''
        $manifestBytes = [Convert]::FromBase64String($encodedContent)
    }
    catch {
        throw "Microsoft winget-pkgs returned invalid base64 manifest content: $($_.Exception.Message)"
    }
    if ($manifestBytes.LongLength -lt 1 -or $manifestBytes.LongLength -gt 262144) {
        throw 'Microsoft winget-pkgs returned an empty or unexpectedly large installer manifest.'
    }
    $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
    try {
        $manifest = $strictUtf8.GetString($manifestBytes)
    }
    catch {
        throw "Microsoft winget-pkgs returned invalid UTF-8 manifest content: $($_.Exception.Message)"
    }

    $packageIdentifier = [regex]::Matches(
        $manifest,
        '(?m)^PackageIdentifier:[ \t]*(?<Value>[^\r\n]+?)[ \t]*\r?$'
    )
    $packageVersion = [regex]::Matches(
        $manifest,
        '(?m)^PackageVersion:[ \t]*(?<Value>[^\r\n]+?)[ \t]*\r?$'
    )
    if ($packageIdentifier.Count -ne 1 -or
        $packageIdentifier[0].Groups['Value'].Value -cne 'LibreWolf.LibreWolf' -or
        $packageVersion.Count -ne 1 -or
        $packageVersion[0].Groups['Value'].Value -cne $tag) {
        throw 'Microsoft winget-pkgs manifest does not describe the selected LibreWolf release.'
    }

    $installerSection = [regex]::Matches(
        $manifest,
        '(?ms)^Installers:[ \t]*\r?\n(?<Value>.*?)(?=^[A-Za-z][A-Za-z0-9]*:|\z)'
    )
    if ($installerSection.Count -ne 1) {
        throw 'Microsoft winget-pkgs manifest does not contain one Installers collection.'
    }
    $selectedArchitecture = if ($Architecture -ceq 'x86_64') { 'x64' } else { 'arm64' }
    $selected = @()
    foreach ($record in @([regex]::Split(
                $installerSection[0].Groups['Value'].Value,
                '(?m)^(?=[ \t]*-[ \t]+)'
            ))) {
        $architectures = [regex]::Matches(
            $record,
            '(?m)^[ \t]*(?:-[ \t]*)?Architecture:[ \t]*(?<Value>[^\r\n]+?)[ \t]*\r?$'
        )
        if ($architectures.Count -eq 1 -and
            $architectures[0].Groups['Value'].Value -ceq $selectedArchitecture) {
            $selected += $record
        }
    }
    if ($selected.Count -ne 1) {
        throw "Microsoft winget-pkgs does not attest the exact '$selectedArchitecture' LibreWolf installer."
    }
    $urls = [regex]::Matches(
        $selected[0],
        '(?m)^[ \t]*(?:-[ \t]*)?InstallerUrl:[ \t]*(?<Value>[^\r\n]+?)[ \t]*\r?$'
    )
    $hashes = [regex]::Matches(
        $selected[0],
        '(?m)^[ \t]*(?:-[ \t]*)?InstallerSha256:[ \t]*(?<Value>[0-9a-fA-F]{64})[ \t]*\r?$'
    )
    if ($urls.Count -ne 1 -or
        $urls[0].Groups['Value'].Value -cne ([uri]$ReleaseMetadata.Uri).AbsoluteUri -or
        $hashes.Count -ne 1) {
        throw "Microsoft winget-pkgs does not attest the exact '$selectedArchitecture' LibreWolf installer."
    }
    return $hashes[0].Groups['Value'].Value.ToLowerInvariant()
}

function Get-AtlasLatestLibreWolfInstallerMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('x86_64', 'arm64')]
        [string]$Architecture
    )

    $release = Invoke-AtlasSoftwareApiJson `
        -Uri 'https://codeberg.org/api/v1/repos/librewolf/bsys6/releases/latest' `
        -Description 'LibreWolf Codeberg latest-release metadata'
    $releaseMetadata = Resolve-AtlasLibreWolfReleaseMetadata `
        -Release $release -Architecture $Architecture

    $wingetManifestUri = [uri](
        'https://api.github.com/repos/microsoft/winget-pkgs/contents/' +
        "manifests/l/LibreWolf/LibreWolf/$($releaseMetadata.Tag)/LibreWolf.LibreWolf.installer.yaml"
    )
    $wingetManifest = Invoke-AtlasGitHubApiJson `
        -Uri $wingetManifestUri `
        -Description 'Microsoft winget-pkgs LibreWolf installer manifest'
    $independentSha256 = Resolve-AtlasLibreWolfWingetManifestHash `
        -ContentMetadata $wingetManifest `
        -ReleaseMetadata $releaseMetadata `
        -Architecture $Architecture

    return [pscustomobject]@{
        Tag    = $releaseMetadata.Tag
        Name   = $releaseMetadata.Name
        Uri    = $releaseMetadata.Uri
        Sha256 = $independentSha256
    }
}

function Resolve-AtlasNanaZipReleaseAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Release
    )

    $tag = [string]$Release.tag_name
    if ($Release.draft -isnot [bool] -or $Release.draft -or
        $Release.prerelease -isnot [bool] -or $Release.prerelease -or
        $tag -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') {
        throw 'GitHub latest-release metadata is not a stable NanaZip release.'
    }

    $specifications = @(
        [pscustomobject]@{ Name = "NanaZip_$tag.msixbundle" }
        [pscustomobject]@{ Name = "NanaZip_$tag.xml" }
    )
    $resolved = @()
    foreach ($specification in $specifications) {
        $assets = @($Release.assets | Where-Object {
                [string]$_.name -ceq $specification.Name
            })
        if ($assets.Count -ne 1) {
            throw "GitHub latest-release metadata did not contain exactly one '$($specification.Name)' asset."
        }

        $asset = $assets[0]
        $assetBytes = 0L
        $digestMatch = [regex]::Match(
            [string]$asset.digest,
            '^sha256:([0-9a-fA-F]{64})$'
        )
        $expectedUrl = "https://github.com/M2Team/NanaZip/releases/download/$tag/$($specification.Name)"
        if ($asset.state -cne 'uploaded' -or
            -not $digestMatch.Success -or
            -not [long]::TryParse([string]$asset.size, [ref]$assetBytes) -or
            $assetBytes -lt 1 -or $assetBytes -gt 1073741824 -or
            [string]$asset.browser_download_url -cne $expectedUrl) {
            throw "GitHub's '$($specification.Name)' asset is not a complete canonical upload with a bounded SHA-256 digest."
        }

        $apiHash = $digestMatch.Groups[1].Value.ToLowerInvariant()

        $resolved += [pscustomobject]@{
            Tag     = $tag
            Name    = $specification.Name
            Uri     = [uri]$expectedUrl
            Sha256  = $apiHash
            Size    = $assetBytes
        }
    }

    return $resolved
}

function Get-AtlasLatestNanaZipReleaseAssets {
    [CmdletBinding()]
    param()

    $release = Invoke-AtlasGitHubApiJson `
        -Uri 'https://api.github.com/repos/M2Team/NanaZip/releases/latest' `
        -Description 'NanaZip GitHub latest-release metadata'
    return Resolve-AtlasNanaZipReleaseAssets -Release $release
}

function Assert-AtlasNanaZipBundleIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Version
    )

    $resolvedPath = Resolve-AtlasProtectedExecutionPath `
        -Path $Path -PathType Leaf -Description 'The NanaZip MSIX bundle'
    Microsoft.PowerShell.Utility\Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop

    $fileStream = $null
    $archive = $null
    $manifestStream = $null
    $xmlReader = $null
    try {
        $fileStream = [IO.File]::Open(
            $resolvedPath,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read,
            [IO.FileShare]::Read
        )
        $archive = New-Object IO.Compression.ZipArchive(
            $fileStream,
            [IO.Compression.ZipArchiveMode]::Read,
            $false
        )
        $entries = @($archive.Entries | Where-Object {
                $_.FullName -ceq 'AppxMetadata/AppxBundleManifest.xml'
            })
        if ($entries.Count -ne 1 -or
            $entries[0].Length -lt 1 -or $entries[0].Length -gt 1048576) {
            throw 'The NanaZip bundle does not contain one bounded canonical AppxBundleManifest.xml.'
        }

        $settings = New-Object Xml.XmlReaderSettings
        $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $settings.MaxCharactersInDocument = 1048576
        $settings.MaxCharactersFromEntities = 0
        $manifestStream = $entries[0].Open()
        $xmlReader = [Xml.XmlReader]::Create($manifestStream, $settings)
        $document = New-Object Xml.XmlDocument
        $document.XmlResolver = $null
        $document.Load($xmlReader)

        $root = $document.DocumentElement
        if ($null -eq $root -or $root.LocalName -cne 'Bundle' -or
            $root.NamespaceURI -cne 'http://schemas.microsoft.com/appx/2013/bundle') {
            throw 'The NanaZip bundle manifest root is not the canonical MSIX Bundle element.'
        }
        $identities = @($root.ChildNodes | Where-Object {
                $_.NodeType -eq [Xml.XmlNodeType]::Element -and
                $_.LocalName -ceq 'Identity'
            })
        if ($identities.Count -ne 1 -or
            $identities[0].GetAttribute('Name') -cne '40174MouriNaruto.NanaZip' -or
            $identities[0].GetAttribute('Publisher') -cne 'CN=E310A153-74A9-4D81-800B-857A8D58408A' -or
            $identities[0].GetAttribute('Version') -cne $Version) {
            throw 'The NanaZip bundle identity does not match the reviewed Store package name, publisher, and release version.'
        }
    }
    finally {
        if ($null -ne $xmlReader) { $xmlReader.Dispose() }
        if ($null -ne $manifestStream) { $manifestStream.Dispose() }
        if ($null -ne $archive) { $archive.Dispose() }
        if ($null -ne $fileStream) { $fileStream.Dispose() }
    }
}

function Get-AtlasDismProvisioningCommands {
    [CmdletBinding()]
    param()

    $manifestPath = Join-Path -Path ([Environment]::GetFolderPath('System')) `
        -ChildPath 'WindowsPowerShell\v1.0\Modules\Dism\Dism.psd1'
    $resolvedManifest = Resolve-AtlasProtectedExecutionPath `
        -Path $manifestPath -PathType Leaf -Description 'The inbox DISM module manifest'
    $modules = @(Import-Module -Name $resolvedManifest -Force -PassThru -ErrorAction Stop)
    $expectedGuid = [guid]'389c464d-8b8d-48e9-aafe-6d8a590d6798'
    $expectedBase = [IO.Path]::GetFullPath((Split-Path -Parent $resolvedManifest)).TrimEnd('\')
    if ($modules.Count -ne 1 -or $modules[0].Name -cne 'Dism' -or
        $modules[0].Guid -ne $expectedGuid -or
        -not [IO.Path]::GetFullPath($modules[0].ModuleBase).TrimEnd('\').Equals(
            $expectedBase,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The inbox DISM module did not load from its exact manifest at '$resolvedManifest'."
    }

    $getPackage = $modules[0].ExportedCommands['Get-AppxProvisionedPackage']
    $addPackage = $modules[0].ExportedCommands['Add-AppxProvisionedPackage']
    if ($null -eq $getPackage -or $null -eq $addPackage -or
        $getPackage.Module.Guid -ne $expectedGuid -or
        $addPackage.Module.Guid -ne $expectedGuid) {
        throw 'The exact inbox DISM module did not export its expected AppX provisioning commands.'
    }

    return [pscustomobject]@{
        GetProvisionedPackage = $getPackage
        AddProvisionedPackage = $addPackage
    }
}

function Test-AtlasNanaZipProvisioned {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][object[]]$Package = @(),
        [string]$Version
    )

    foreach ($candidate in $Package) {
        if ($null -eq $candidate.PSObject.Properties['DisplayName'] -or
            [string]$candidate.DisplayName -cne '40174MouriNaruto.NanaZip') {
            continue
        }
        if ([string]::IsNullOrEmpty($Version)) {
            return $true
        }
        if ($null -ne $candidate.PSObject.Properties['Version'] -and
            [string]$candidate.Version -ceq $Version) {
            return $true
        }
    }
    return $false
}

function Install-AtlasToolbox {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    # TempDir remains part of the shared installer-function contract; Toolbox
    # uses its own protected staging directory because it executes elevated.
    [void]$TempDir
    $atlasSoftwareRoot = [IO.Directory]::GetParent($PSScriptRoot)
    $modulesRoot = $atlasSoftwareRoot.Parent
    $scriptsRoot = $modulesRoot.Parent
    $packageHelper = [IO.Path]::Combine(
        $scriptsRoot.FullName,
        'Internal',
        'Toolbox-Package.ps1'
    )
    if (-not [IO.File]::Exists($packageHelper) -or
        (([IO.File]::GetAttributes($packageHelper) -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "The protected Toolbox package helper is missing or a reparse point at '$packageHelper'."
    }
    . $packageHelper
    Install-AtlasToolboxPackage
}

function Install-AtlasBraveBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $installerPath = Join-Path -Path $TempDir -ChildPath 'BraveSetup.exe'
    Invoke-AtlasSoftwareDownload -Uri 'https://laptop-updates.brave.com/latest/winx64' -Destination $installerPath -Description 'Brave'
    Assert-AtlasFileSignature -Path $installerPath -ExpectedSubjectCn 'Brave Software, Inc.' -Description 'Brave'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList @('/silent', '/install') -Description 'Brave'
}

function Install-AtlasFirefoxBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $firefoxArch = if (Test-AtlasSoftwareArm64) { 'win64-aarch64' } else { 'win64' }
    $installerPath = Join-Path -Path $TempDir -ChildPath 'firefox.exe'
    Invoke-AtlasSoftwareDownload -Uri "https://download.mozilla.org/?product=firefox-latest-ssl&os=$firefoxArch&lang=en-US" -Destination $installerPath -Description 'Firefox'
    Assert-AtlasFileSignature -Path $installerPath -ExpectedSubjectCn 'Mozilla Corporation' -Description 'Firefox'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList @('/S', '/ALLUSERS=1') -Description 'Firefox'
}

function Install-AtlasChromeBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $chromeArch = if (Test-AtlasSoftwareArm64) { '_Arm64' } else { '64' }
    $installerPath = Join-Path -Path $TempDir -ChildPath 'chrome.msi'
    Invoke-AtlasSoftwareDownload -Uri "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi" -Destination $installerPath -Description 'Google Chrome'
    Assert-AtlasFileSignature -Path $installerPath -ExpectedSubjectCn 'Google LLC' -Description 'Google Chrome'
    $msiExecPath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'msiexec.exe'
    Start-AtlasSoftwareInstaller `
        -FilePath $msiExecPath `
        -ArgumentList @('/i', $installerPath, '/qn', '/norestart') `
        -Description 'Google Chrome' `
        -SuccessExitCode @(0, 3010)
}

function Install-AtlasLibreWolfBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $startMenu = [Environment]::GetFolderPath('CommonPrograms')
    $programs = [Environment]::GetFolderPath('ProgramFiles')
    $librewolfPath = Join-Path -Path $programs -ChildPath 'LibreWolf'
    $librewolfExecutable = Join-Path -Path $librewolfPath -ChildPath 'librewolf.exe'
    $updaterPath = Join-Path -Path $librewolfPath -ChildPath 'librewolf-winupdater'

    Write-Host 'Getting the latest LibreWolf release metadata'
    $librewolfArchitecture = if (Test-AtlasSoftwareArm64) { 'arm64' } else { 'x86_64' }
    $librewolfRelease = Get-AtlasLatestLibreWolfInstallerMetadata `
        -Architecture $librewolfArchitecture
    $outputLibrewolf = Join-Path -Path $TempDir -ChildPath $librewolfRelease.Name
    Invoke-AtlasSoftwareDownload `
        -Uri $librewolfRelease.Uri `
        -Destination $outputLibrewolf `
        -Description 'the latest LibreWolf setup'

    # Microsoft's independent winget-pkgs review must attest the exact Codeberg
    # release bytes. LibreWolf's official page additionally identifies OSSign as
    # the verified Windows publisher. A sibling checksum from the download host
    # would not establish either independent boundary.
    Assert-AtlasFileHash `
        -Path $outputLibrewolf `
        -ExpectedSha256 $librewolfRelease.Sha256 `
        -Description 'LibreWolf'
    Assert-AtlasFileSignature `
        -Path $outputLibrewolf `
        -ExpectedSubjectCn 'OSSign (Scheibling Consulting AB)' `
        -Description 'LibreWolf'

    Write-Host 'Installing LibreWolf silently'
    Start-AtlasSoftwareInstaller `
        -FilePath $outputLibrewolf -ArgumentList @('/S') -Description 'LibreWolf'
    $null = Resolve-AtlasProtectedExecutionPath `
        -Path $librewolfExecutable `
        -PathType Leaf `
        -Description 'The installed LibreWolf executable'

    # Pinned: the updater is unsigned and changes rarely; bump tag + hash together.
    # The updater self-updates LibreWolf afterwards, so a slightly stale updater is harmless.
    $librewolfUpdaterVersion = '1.14.0'
    $librewolfUpdaterHash = '4f90cf5c64c1897983f1c302afd0691cb57138a6ba26cd4a3a2ac92be5da7605'
    $librewolfUpdaterDownload = "https://codeberg.org/ltguillaume/librewolf-winupdater/releases/download/$librewolfUpdaterVersion/LibreWolf-WinUpdater_$librewolfUpdaterVersion.zip"

    $outputLibrewolfUpdater = Join-Path -Path $TempDir -ChildPath 'librewolf-winupdater.zip'
    Invoke-AtlasSoftwareDownload -Uri $librewolfUpdaterDownload -Destination $outputLibrewolfUpdater -Description 'the LibreWolf WinUpdater ZIP'
    Assert-AtlasFileHash -Path $outputLibrewolfUpdater -ExpectedSha256 $librewolfUpdaterHash -Description 'LibreWolf WinUpdater'

    Write-Host 'Extracting Librewolf-WinUpdater'
    if (Test-Path -LiteralPath $updaterPath) {
        $null = Resolve-AtlasProtectedExecutionPath `
            -Path $updaterPath `
            -PathType Container `
            -Description 'The existing LibreWolf WinUpdater directory'
    }
    Expand-Archive -LiteralPath $outputLibrewolfUpdater -DestinationPath $updaterPath -Force -ErrorAction Stop
    $updaterExecutable = Join-Path -Path $updaterPath -ChildPath 'LibreWolf-WinUpdater.exe'
    $null = Resolve-AtlasProtectedExecutionPath `
        -Path $updaterExecutable `
        -PathType Leaf `
        -Description 'The extracted LibreWolf WinUpdater executable'

    Write-Host 'Adding LibreWolf WinUpdater shortcut'
    New-AtlasShortcut -Source $updaterExecutable -Destination "$startMenu\LibreWolf\LibreWolf WinUpdater.lnk" -WorkingDir $librewolfPath
}

function Install-AtlasVisualCppRuntimes {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $legacyArgs = @('/q', '/norestart')
    $modernArgs = @('/install', '/quiet', '/norestart')
    $vcredists = @(
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe'; Name = '2005-x64'; Arguments = @('/c', '/q'); Extract = $true }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe'; Name = '2005-x86'; Arguments = @('/c', '/q'); Extract = $true }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe'; Name = '2008-x64'; Arguments = $legacyArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe'; Name = '2008-x86'; Arguments = $legacyArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe'; Name = '2010-x64'; Arguments = $legacyArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe'; Name = '2010-x86'; Arguments = $legacyArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'; Name = '2012-x64'; Arguments = $modernArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'; Name = '2012-x86'; Arguments = $modernArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe'; Name = '2013-x64'; Arguments = $modernArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://download.visualstudio.microsoft.com/download/pr/10912113/5da66ddebb0ad32ebd4b922fd82e8e25/vcredist_x86.exe'; Name = '2013-x86'; Arguments = $modernArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'; Name = '2015+-x64'; Arguments = $modernArgs; Extract = $false }
        [pscustomobject]@{ Uri = 'https://aka.ms/vs/17/release/vc_redist.x86.exe'; Name = '2015+-x86'; Arguments = $modernArgs; Extract = $false }
    )
    $msiExecPath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'msiexec.exe'
    $failedInstallers = New-Object Collections.Generic.List[string]

    foreach ($entry in $vcredists) {
        $vcName = $entry.Name
        $vcExePath = Join-Path -Path $TempDir -ChildPath "vcredist-$vcName.exe"
        Invoke-AtlasSoftwareDownload -Uri $entry.Uri -Destination $vcExePath -Description "Visual C++ Runtime $vcName"
        Assert-AtlasFileSignature -Path $vcExePath -ExpectedSubjectCn 'Microsoft Corporation' -Description "Visual C++ Runtime $vcName"

        if ($entry.Extract) {
            $msiDir = Join-Path -Path $TempDir -ChildPath "vcredist-$vcName"
            $extractArguments = @($entry.Arguments) + @('/t:' + $msiDir)
            if (-not (Start-AtlasSoftwareOptionalInstaller `
                    -FilePath $vcExePath `
                    -ArgumentList $extractArguments `
                    -Description "Visual C++ Runtime $vcName extractor" `
                    -SuccessExitCode @(0, 3010))) {
                $failedInstallers.Add("$vcName extractor")
                continue
            }
            $null = Resolve-AtlasProtectedExecutionPath `
                -Path $msiDir -PathType Container -Description "The $vcName MSI directory"
            $msiPaths = @(Get-ChildItem -LiteralPath $msiDir -File -Filter '*.msi' -ErrorAction Stop)
            if ($msiPaths.Count -lt 1) {
                Write-AtlasLog -Level Warning -Message "The $vcName extractor produced no MSI package."
                $failedInstallers.Add("$vcName extracted MSI")
                continue
            }
            foreach ($msi in $msiPaths) {
                $resolvedMsiPath = Resolve-AtlasProtectedExecutionPath `
                    -Path $msi.FullName `
                    -PathType Leaf `
                    -Description "The Visual C++ Runtime $vcName MSI"
                $msiArguments = @(
                    '/log'
                    (Join-Path -Path $msiDir -ChildPath 'logfile.log')
                    '/i'
                    $resolvedMsiPath
                    '/qn'
                    '/norestart'
                    'ALLUSERS=1'
                    'REBOOT=ReallySuppress'
                )
                if (-not (Start-AtlasSoftwareOptionalInstaller `
                        -FilePath $msiExecPath `
                        -ArgumentList $msiArguments `
                        -Description "Visual C++ Runtime $vcName MSI" `
                        -SuccessExitCode @(0, 3010))) {
                    $failedInstallers.Add("$vcName MSI")
                }
            }
        }
        else {
            if (-not (Start-AtlasSoftwareOptionalInstaller `
                    -FilePath $vcExePath `
                    -ArgumentList ([string[]]$entry.Arguments) `
                    -Description "Visual C++ Runtime $vcName" `
                    -SuccessExitCode @(0, 3010))) {
                $failedInstallers.Add($vcName)
            }
        }
    }

    if ($failedInstallers.Count -gt 0) {
        throw "One or more Visual C++ runtime installers failed: $($failedInstallers -join ', ')."
    }
}

function Install-Atlas7Zip {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    # Bump the version + hashes together when 7-Zip releases (~1-2x/year). 7-Zip
    # installers are not Authenticode-signed, so a pinned hash is the only integrity option.
    $sevenZipVersion = '2602'
    $sevenZipHashes = @{
        'x64'   = '6745fa76dc2ea031596d8678f6f6b99c3c1b435b4164a63485adbbc7b8d82ef0'
        'arm64' = '7c6fde79ed5e11b81c7bb6573b7962d3b6322aa5fce69c33ed19f672b55173ab'
    }
    $sevenZipArch = if (Test-AtlasSoftwareArm64) { 'arm64' } else { 'x64' }
    $installerPath = Join-Path -Path $TempDir -ChildPath '7zip.exe'
    Invoke-AtlasSoftwareDownload -Uri "https://7-zip.org/a/7z$sevenZipVersion-$sevenZipArch.exe" -Destination $installerPath -Description '7-Zip'
    Assert-AtlasFileHash -Path $installerPath -ExpectedSha256 $sevenZipHashes[$sevenZipArch] -Description '7-Zip'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList @('/S') -Description '7-Zip'
}

function Install-AtlasNanaZip {
    param(
        [Parameter(Mandatory = $true)][string]$TempDir,
        [Parameter(Mandatory = $true)][object[]]$Assets,
        [Parameter(Mandatory = $true)]$DismCommands
    )

    $provisioningStarted = $false
    try {
        if ($Assets.Count -ne 2 -or
            $null -eq $DismCommands.GetProvisionedPackage -or
            $null -eq $DismCommands.AddProvisionedPackage) {
            throw 'NanaZip installation requires exactly two verified assets and exact DISM commands.'
        }

        $tag = [string]$Assets[0].Tag
        if ($tag -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') {
            throw 'NanaZip asset metadata does not contain a stable release tag.'
        }
        $bundleName = "NanaZip_$tag.msixbundle"
        $licenseName = "NanaZip_$tag.xml"
        $expectedNames = @($bundleName, $licenseName)
        if (@($Assets | Where-Object {
                    $null -eq $_.PSObject.Properties['Name'] -or
                    $null -eq $_.PSObject.Properties['Uri'] -or
                    $null -eq $_.PSObject.Properties['Sha256'] -or
                    $null -eq $_.PSObject.Properties['Size'] -or
                    $null -eq $_.PSObject.Properties['Tag'] -or
                    [string]$_.Tag -cne $tag -or
                    [string]$_.Name -cnotin $expectedNames
                }).Count -ne 0 -or
            @($Assets | Select-Object -ExpandProperty Name -Unique).Count -ne 2) {
            throw 'NanaZip assets do not describe one exact release bundle and license pair.'
        }

        $nanaZipDirectory = Join-Path -Path $TempDir -ChildPath 'nanazip'
        if (Test-Path -LiteralPath $nanaZipDirectory) {
            throw "The NanaZip staging path '$nanaZipDirectory' already exists."
        }
        $nanaZipPath = New-Item -Path $nanaZipDirectory -ItemType Directory -ErrorAction Stop
        $null = Resolve-AtlasProtectedExecutionPath `
            -Path $nanaZipPath.FullName -PathType Container -Description 'The NanaZip staging directory'

        $assetPaths = @{}
        foreach ($asset in $Assets) {
            $destination = Join-Path -Path $nanaZipPath.FullName -ChildPath $asset.Name
            $assetPaths[$asset.Name] = Invoke-AtlasPinnedDownload `
                -Uri $asset.Uri `
                -Destination $destination `
                -Sha256 $asset.Sha256 `
                -ExpectedBytes $asset.Size `
                -MaximumSeconds 900
        }
        if (-not $assetPaths.ContainsKey($bundleName) -or
            -not $assetPaths.ContainsKey($licenseName)) {
            throw 'NanaZip release metadata did not resolve the exact bundle and license pair.'
        }
        Assert-AtlasNanaZipBundleIdentity -Path $assetPaths[$bundleName] -Version $tag

        $appxArgs = @{
            Online      = $true
            PackagePath = $assetPaths[$bundleName]
            LicensePath = $assetPaths[$licenseName]
            ErrorAction = 'Stop'
        }
        # From this point onward DISM may have mutated machine package state. A
        # failure must propagate rather than installing 7-Zip alongside a
        # partially or successfully provisioned NanaZip package.
        $provisioningStarted = $true
        & $DismCommands.AddProvisionedPackage @appxArgs | Out-Null
        $installed = @(& $DismCommands.GetProvisionedPackage -Online -ErrorAction Stop)
        if (-not (Test-AtlasNanaZipProvisioned -Package $installed -Version $tag)) {
            throw "DISM returned without provisioning NanaZip version '$tag'."
        }
        Write-Host 'Installed NanaZip!'
        return $true
    }
    catch {
        if ($provisioningStarted -or
            (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception)) {
            throw
        }
        Write-AtlasLog -Level Warning -Message "Failed to install NanaZip! Getting 7-Zip instead. $($_.Exception.Message)"
        $sevenZipRegistry = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
        if (-not (Test-Path -LiteralPath $sevenZipRegistry)) {
            Install-Atlas7Zip -TempDir $TempDir
        }
        return $false
    }
}

function Get-AtlasParsedUninstallString {
    # This is intentionally not a general uninstall-command parser. Accept only
    # the two exact 7-Zip values that resolve to the caller-supplied protected
    # Uninstall.exe path, then provide our own fixed argv array.
    param(
        [Parameter(Mandatory = $true)][string]$UninstallString,
        [Parameter(Mandatory = $true)][string]$ExpectedFilePath
    )

    if ([string]::IsNullOrWhiteSpace($ExpectedFilePath) -or
        $ExpectedFilePath.IndexOf([char]0) -ge 0 -or
        $ExpectedFilePath -notmatch '^[A-Za-z]:[\\/]') {
        throw 'The expected 7-Zip uninstaller must be an explicit absolute local drive path.'
    }
    if ($ExpectedFilePath.Substring(2).Contains(':')) {
        throw 'The expected 7-Zip uninstaller cannot address an alternate data stream.'
    }
    $expectedPath = [IO.Path]::GetFullPath($ExpectedFilePath)

    $quotedPath = '"' + $expectedPath + '"'
    if (-not $UninstallString.Equals($quotedPath, [StringComparison]::Ordinal) -and
        -not $UninstallString.Equals(($quotedPath + ' /S'), [StringComparison]::Ordinal)) {
        return $null
    }

    return [pscustomobject]@{
        FilePath     = $expectedPath
        ArgumentList = [string[]]@('/S')
    }
}

function Install-AtlasArchiveTool {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    try {
        $dismCommands = Get-AtlasDismProvisioningCommands
        $provisionedPackages = @(& $dismCommands.GetProvisionedPackage -Online -ErrorAction Stop)
    }
    catch {
        Write-AtlasLog -Level Warning -Message "NanaZip provisioning is unavailable; installing 7-Zip instead. $($_.Exception.Message)"
        Install-Atlas7Zip -TempDir $TempDir
        return
    }

    if (Test-AtlasNanaZipProvisioned -Package $provisionedPackages) {
        Write-Host 'NanaZip is already installed, skipping installation.'
        return
    }

    try {
        $assets = @(Get-AtlasLatestNanaZipReleaseAssets)
    }
    catch {
        Write-AtlasLog -Level Warning -Message "NanaZip release integrity could not be established; installing 7-Zip instead. $($_.Exception.Message)"
        Install-Atlas7Zip -TempDir $TempDir
        return
    }

    $sevenZipRegistry = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
    $replaceSevenZip = Test-Path -LiteralPath $sevenZipRegistry
    if ($replaceSevenZip) {
        $message = @'
Would you like to uninstall 7-Zip and replace it with NanaZip?

NanaZip is a fork of 7-Zip with an updated user interface and extra features.
'@
        if ((Read-MessageBox -Title 'Installing NanaZip - Atlas' -Body $message -Icon Question) -ne 'Yes') {
            Write-Host 'Keeping existing 7-Zip installation.'
            return
        }
    }

    $nanaZipInstalled = Install-AtlasNanaZip `
        -TempDir $TempDir `
        -Assets $assets `
        -DismCommands $dismCommands
    if (-not $nanaZipInstalled -or -not $replaceSevenZip) {
        return
    }

    try {
            $uninstallProperty = Get-ItemProperty `
                -Path $sevenZipRegistry `
                -Name 'QuietUninstallString' `
                -ErrorAction Stop
        $expectedUninstaller = [IO.Path]::Combine(
            [Environment]::GetFolderPath('ProgramFiles'),
            '7-Zip',
            'Uninstall.exe'
        )
        $parsedUninstall = Get-AtlasParsedUninstallString `
            -UninstallString ([string]$uninstallProperty.QuietUninstallString) `
            -ExpectedFilePath $expectedUninstaller
        if ($null -eq $parsedUninstall) {
            throw 'The 7-Zip QuietUninstallString does not use the supported exact format.'
        }
        $protectedUninstaller = Resolve-AtlasProtectedExecutionPath `
            -Path $parsedUninstall.FilePath `
            -PathType Leaf `
            -Description 'The expected 7-Zip uninstaller'
        if (-not $protectedUninstaller.Equals(
                $expectedUninstaller,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw 'The protected 7-Zip uninstaller did not resolve to the expected installation path.'
        }
        Start-AtlasSoftwareInstaller `
            -FilePath $protectedUninstaller `
            -ArgumentList ([string[]]$parsedUninstall.ArgumentList) `
            -Description '7-Zip removal'
        if (Test-Path -LiteralPath $sevenZipRegistry) {
            throw 'The 7-Zip uninstaller returned success but its machine uninstall record remains.'
        }
    }
    catch {
        $message = "NanaZip is installed, but 7-Zip cleanup failed; no rollback was attempted. $($_.Exception.Message)"
        Write-AtlasLog -Level Warning -Message $message
        throw $message
    }
}

function Install-AtlasDirectXRuntime {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $installerPath = Join-Path -Path $TempDir -ChildPath 'directx.exe'
    $extractPath = Join-Path -Path $TempDir -ChildPath 'directx'
    Invoke-AtlasSoftwareDownload -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -Destination $installerPath -Description 'legacy DirectX runtimes'
    # Fixed June 2010 URL: the file can never change, so pin its hash in addition to the signature.
    Assert-AtlasFileHash -Path $installerPath -ExpectedSha256 '053f76dcbb28802e23341b6a787e3b0791c0fa5c8d4d011b1044172dbf89c73b' -Description 'legacy DirectX runtimes'
    Assert-AtlasFileSignature -Path $installerPath -ExpectedSubjectCn 'Microsoft Corporation' -Description 'legacy DirectX runtimes'
    Start-AtlasSoftwareInstaller `
        -FilePath $installerPath `
        -ArgumentList @('/q', '/c', ('/t:' + $extractPath)) `
        -Description 'legacy DirectX runtime extractor'
    Start-AtlasSoftwareInstaller `
        -FilePath (Join-Path -Path $extractPath -ChildPath 'dxsetup.exe') `
        -ArgumentList @('/silent') `
        -Description 'legacy DirectX runtimes'
}

function Install-AtlasSoftware {
    <#
    .SYNOPSIS
        Downloads and installs the given software components at install time. Each
        component failure is logged as a warning and the remaining components still
        install.
    .OUTPUTS
        $true when every component installed successfully and protected staging was
        removed, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('SevenZip', 'VCRedist', 'DirectX', 'Brave', 'Firefox', 'LibreWolf', 'Chrome', 'Toolbox')]
        [string[]]$Component
    )

    Assert-AtlasPrivilege -Administrator

    $componentMap = Get-AtlasSoftwareComponentMap
    $tempDir = New-AtlasProtectedStagingDirectory
    $allSucceeded = $true
    $cleanupStaging = $true
    try {
        foreach ($name in $Component) {
            try {
                Write-AtlasLog -Message "Installing software component '$name'."
                $null = & $componentMap[$name] -TempDir $tempDir
            }
            catch {
                if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                    $cleanupStaging = $false
                }
                Write-AtlasLog -Level Warning -Message "Installing software component '$name' failed: $($_.Exception.Message)"
                $allSucceeded = $false
            }
        }
    }
    catch {
        if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
            $cleanupStaging = $false
        }
        Write-AtlasLog -Level Warning -Message "Software installer setup failed: $($_.Exception.Message)"
        $allSucceeded = $false
    }
    finally {
        if (-not $cleanupStaging) {
            Write-AtlasLog -Level Warning -Message "Protected software staging was retained at '$tempDir' because process-tree containment was not confirmed."
            $allSucceeded = $false
        }
        else {
            try {
                if (Test-Path -LiteralPath $tempDir) {
                    $resolvedStaging = Resolve-AtlasProtectedExecutionPath `
                        -Path $tempDir `
                        -PathType Container `
                        -Description 'The software staging directory'
                    Remove-Item -LiteralPath $resolvedStaging -Force -Recurse -ErrorAction Stop
                }
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Protected software staging cleanup failed: $($_.Exception.Message)"
                $allSucceeded = $false
            }
        }
    }

    return $allSucceeded
}
