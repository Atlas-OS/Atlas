# Shared download and native-execution boundaries for elevated Atlas callers.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-AtlasProtectedStagingAcl')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-AtlasDirectoryWithSecurity')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-AtlasProtectedStagingDirectory')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Resolve-AtlasGitHubRepositoryMetadata')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Resolve-AtlasGitHubReleaseAssetMetadata')]
param()

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

function New-AtlasProtectedStagingAcl {
    $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $security = New-Object Security.AccessControl.DirectorySecurity
    $security.SetOwner($administrators)
    $security.SetAccessRuleProtection($true, $false)
    $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [Security.AccessControl.InheritanceFlags]::ObjectInherit
    foreach ($sid in @(
            'S-1-5-18'
            'S-1-5-32-544'
            'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
        )) {
        $identity = New-Object Security.Principal.SecurityIdentifier($sid)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $identity,
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        )
        [void]$security.AddAccessRule($rule)
    }
    return $security
}

function Test-AtlasProtectedStagingAcl {
    param(
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.DirectorySecurity]$Acl
    )

    $expected = @(
        'S-1-5-18'
        'S-1-5-32-544'
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
    )
    if (-not $Acl.AreAccessRulesProtected -or
        $Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -cne 'S-1-5-32-544') {
        return $false
    }
    $rules = @($Acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))
    if ($rules.Count -ne $expected.Count) { return $false }
    foreach ($rule in $rules) {
        if ($rule.IdentityReference.Value -cnotin $expected -or
            $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or
            $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::FullControl -or
            $rule.IsInherited) {
            return $false
        }
    }
    return $true
}

function New-AtlasDirectoryWithSecurity {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.DirectorySecurity]$Security
    )

    $legacyCreate = [IO.Directory].GetMethod(
        'CreateDirectory',
        [type[]]@([string], [Security.AccessControl.DirectorySecurity])
    )
    if ($null -ne $legacyCreate) {
        return $legacyCreate.Invoke($null, [object[]]@($Path, $Security))
    }
    [void][Type]::GetType(
        'System.IO.FileSystemAclExtensions, System.IO.FileSystem.AccessControl',
        $true
    )
    $directory = New-Object IO.DirectoryInfo($Path)
    [IO.FileSystemAclExtensions]::Create($directory, $Security)
    return $directory
}

function New-AtlasProtectedStagingDirectory {
    $root = [Environment]::GetFolderPath('CommonApplicationData')
    if (-not [IO.Directory]::Exists($root)) {
        throw "The common application-data directory '$root' is unavailable."
    }
    $path = [IO.Path]::Combine($root, 'AtlasOS-Staging-' + [guid]::NewGuid().ToString('N'))
    $directory = New-AtlasDirectoryWithSecurity `
        -Path $path -Security (New-AtlasProtectedStagingAcl)
    if (-not (Test-AtlasProtectedStagingAcl -Acl (Get-Acl -LiteralPath $path -ErrorAction Stop))) {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        throw "The staging directory '$path' did not retain its protected ACL."
    }
    return $directory.FullName
}

function Invoke-AtlasBoundedHttpGet {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][IO.Stream]$OutputStream,
        [Parameter(Mandatory = $true)][ValidateRange(1, 1073741824)][long]$MaximumBytes,
        [ValidateRange(1, 3600)][int]$MaximumSeconds = 300,
        [long]$ExpectedBytes = -1,
        [switch]$AllowRedirect,
        [switch]$GitHubApi
    )

    if ($Uri.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($Uri.UserInfo)) {
        throw "Only HTTPS URIs without user information are allowed: '$Uri'."
    }
    Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
    $handler = New-Object Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = [bool]$AllowRedirect
    $handler.MaxAutomaticRedirections = 5
    $handler.SslProtocols = [Security.Authentication.SslProtocols]::Tls12
    $client = New-Object Net.Http.HttpClient($handler)
    $client.Timeout = [Threading.Timeout]::InfiniteTimeSpan
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('AtlasOS-Playbook')
    if ($GitHubApi) {
        $client.DefaultRequestHeaders.Accept.ParseAdd('application/vnd.github+json')
        $client.DefaultRequestHeaders.Add('X-GitHub-Api-Version', '2022-11-28')
    }

    $response = $null
    $inputStream = $null
    $deadline = New-Object Threading.CancellationTokenSource
    $deadline.CancelAfter([TimeSpan]::FromSeconds($MaximumSeconds))
    try {
        $response = $client.GetAsync(
            $Uri,
            [Net.Http.HttpCompletionOption]::ResponseHeadersRead,
            $deadline.Token
        ).GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Downloading '$Uri' failed with HTTP status $([int]$response.StatusCode)."
        }
        $finalUri = $response.RequestMessage.RequestUri
        if ($finalUri.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($finalUri.UserInfo)) {
            throw "Downloading '$Uri' redirected outside HTTPS."
        }
        if (-not $AllowRedirect -and $finalUri.AbsoluteUri -cne $Uri.AbsoluteUri) {
            throw "Downloading '$Uri' redirected unexpectedly."
        }
        $contentLength = $response.Content.Headers.ContentLength
        if ($null -ne $contentLength -and
            ([long]$contentLength -gt $MaximumBytes -or
                ($ExpectedBytes -ge 0 -and [long]$contentLength -ne $ExpectedBytes))) {
            throw "Downloading '$Uri' returned an unexpected byte length."
        }

        $inputStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $buffer = New-Object byte[] 65536
        [long]$total = 0
        while (($read = $inputStream.ReadAsync(
                    $buffer, 0, $buffer.Length, $deadline.Token
                ).GetAwaiter().GetResult()) -gt 0) {
            $total += $read
            if ($total -gt $MaximumBytes) {
                throw "Downloading '$Uri' exceeded the $MaximumBytes-byte limit."
            }
            $OutputStream.Write($buffer, 0, $read)
        }
        return $total
    }
    finally {
        if ($null -ne $inputStream) { $inputStream.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        $deadline.Dispose()
        $client.Dispose()
        $handler.Dispose()
    }
}

function Invoke-AtlasPinnedDownload {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{64}$')][string]$Sha256,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1073741824)][long]$ExpectedBytes,
        [ValidateRange(1, 3600)][int]$MaximumSeconds = 300
    )

    if ([IO.File]::Exists($Destination) -or [IO.Directory]::Exists($Destination)) {
        throw "The download destination '$Destination' already exists."
    }
    $parent = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Destination))
    if (-not [IO.Directory]::Exists($parent)) {
        throw "The download destination parent '$parent' does not exist."
    }

    try {
        $stream = [IO.File]::Open(
            $Destination,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        try {
            $bytes = Invoke-AtlasBoundedHttpGet -Uri $Uri -OutputStream $stream `
                -MaximumBytes $ExpectedBytes -ExpectedBytes $ExpectedBytes `
                -MaximumSeconds $MaximumSeconds -AllowRedirect
        }
        finally {
            $stream.Dispose()
        }
        if ($bytes -ne $ExpectedBytes) {
            throw "Downloading '$Uri' returned $bytes bytes; expected $ExpectedBytes."
        }
        $actualHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
        if (-not $actualHash.Equals($Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "SHA-256 '$actualHash' does not match '$Sha256' for '$Uri'."
        }
        return (Get-Item -LiteralPath $Destination -Force -ErrorAction Stop).FullName
    }
    catch {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw
    }
}

function Test-AtlasProtectedExecutionAcl {
    param(
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.FileSystemSecurity]$Acl
    )

    $privileged = @(
        'S-1-5-18'
        'S-1-5-32-544'
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
    )
    if ($Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -cnotin $privileged -or
        -not $Acl.AreAccessRulesCanonical) {
        return $false
    }
    $mutation = [long][Security.AccessControl.FileSystemRights]::Modify -bor
        [long][Security.AccessControl.FileSystemRights]::ChangePermissions -bor
        [long][Security.AccessControl.FileSystemRights]::TakeOwnership
    foreach ($rule in $Acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
        if ($rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
            ([long]$rule.FileSystemRights -band $mutation) -ne 0 -and
            $rule.IdentityReference.Value -cnotin $privileged) {
            return $false
        }
    }
    return $true
}

function Resolve-AtlasProtectedExecutionPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Leaf', 'Container')][string]$PathType,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path.IndexOf([char]0) -ge 0 -or
        $Path -notmatch '^[A-Za-z]:[\\/]') {
        throw "$Description must be an explicit absolute local drive path."
    }
    $fullPath = [IO.Path]::GetFullPath($Path)
    if ($fullPath.Substring(2).Contains(':')) {
        throw "$Description cannot address an alternate data stream."
    }
    $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($PathType -eq 'Leaf' -and ($item.PSIsContainer -or $item.Length -le 0)) -or
        ($PathType -eq 'Container' -and -not $item.PSIsContainer)) {
        throw "$Description is not a normal $($PathType.ToLowerInvariant())."
    }
    return $item.FullName
}

function ConvertTo-AtlasDownloadProcessArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Argument)

    if ($Argument.IndexOf([char]0) -ge 0) { throw 'A process argument cannot contain NUL.' }
    if ($Argument.Length -eq 0) { return '""' }
    if ($Argument -notmatch '[\s"]') { return $Argument }
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    $slashes = 0
    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') { $slashes++; continue }
        if ($character -eq '"') {
            [void]$builder.Append('\', ($slashes * 2 + 1))
            [void]$builder.Append('"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) { [void]$builder.Append('\', $slashes); $slashes = 0 }
        [void]$builder.Append($character)
    }
    if ($slashes -gt 0) { [void]$builder.Append('\', ($slashes * 2)) }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Test-AtlasContainedProcessContainmentUnconfirmed {
    param([Parameter(Mandatory = $true)][Exception]$Exception)

    for ($current = $Exception; $null -ne $current; $current = $current.InnerException) {
        if ($current.Data.Contains('AtlasProcessMayStillBeRunning') -and
            [bool]$current.Data['AtlasProcessMayStillBeRunning']) {
            return $true
        }
    }
    return $false
}

function Invoke-AtlasContainedProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [AllowEmptyCollection()][string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][ValidateLength(1, 512)][string]$Description,
        [switch]$Hidden,
        [switch]$NoWindow
    )

    if ($ArgumentList.Count -gt 128) { throw 'At most 128 process arguments are supported.' }
    $executable = Resolve-AtlasProtectedExecutionPath `
        -Path $FilePath -PathType Leaf -Description 'The executable'
    $working = Resolve-AtlasProtectedExecutionPath `
        -Path $WorkingDirectory -PathType Container -Description 'The working directory'
    $arguments = @($ArgumentList | ForEach-Object {
            ConvertTo-AtlasDownloadProcessArgument -Argument $_
        }) -join ' '
    if (($executable.Length + $arguments.Length + 3) -gt 32766) {
        throw 'The native command line exceeds 32,766 characters.'
    }

    $startParameters = @{
        FilePath         = $executable
        WorkingDirectory = $working
        Wait             = $true
        PassThru         = $true
        ErrorAction      = 'Stop'
    }
    if ($ArgumentList.Count -gt 0) {
        # Windows PowerShell joins ArgumentList arrays without preserving argv
        # boundaries. Atlas passes one string that it already serialized above.
        $startParameters['ArgumentList'] = [string[]]@($arguments)
    }
    if ($Hidden) {
        $startParameters['WindowStyle'] = 'Hidden'
    }
    elseif ($NoWindow) {
        $startParameters['NoNewWindow'] = $true
    }

    try {
        $process = Start-Process @startParameters
    }
    catch {
        $failure = New-Object InvalidOperationException(
            "$Description failed before its process tree was confirmed complete.",
            $_.Exception
        )
        $failure.Data['AtlasProcessMayStillBeRunning'] = $true
        throw $failure
    }

    try {
        $exitCode = [BitConverter]::ToUInt32(
            [BitConverter]::GetBytes([int]$process.ExitCode), 0
        )
        return [pscustomobject]@{
            ExitCodeUInt32 = $exitCode
        }
    }
    finally {
        $process.Dispose()
    }
}

function Resolve-AtlasGitHubRepositoryMetadata {
    param(
        [Parameter(Mandatory = $true)]$RepositoryMetadata,
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][long]$ExpectedRepositoryId,
        [Parameter(Mandatory = $true)][long]$ExpectedOwnerId
    )

    [long]$repositoryId = 0
    [long]$ownerId = 0
    $fullName = "$Owner/$Repository"
    if (-not [long]::TryParse([string]$RepositoryMetadata.id, [ref]$repositoryId) -or
        -not [long]::TryParse([string]$RepositoryMetadata.owner.id, [ref]$ownerId) -or
        $repositoryId -ne $ExpectedRepositoryId -or $ownerId -ne $ExpectedOwnerId -or
        [string]$RepositoryMetadata.full_name -cne $fullName -or
        [string]$RepositoryMetadata.owner.login -cne $Owner -or
        $RepositoryMetadata.private -isnot [bool] -or $RepositoryMetadata.private -or
        $RepositoryMetadata.archived -isnot [bool] -or $RepositoryMetadata.archived) {
        throw "GitHub repository metadata does not match the reviewed immutable identity for '$fullName'."
    }
    return [pscustomobject]@{
        RepositoryId = $repositoryId
        OwnerId      = $ownerId
        FullName     = $fullName
    }
}

function Invoke-AtlasGitHubApiJson {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Description
    )

    if ($Uri.Scheme -cne 'https' -or $Uri.Host -cne 'api.github.com' -or
        -not $Uri.IsDefaultPort -or $Uri.Query -or $Uri.Fragment) {
        throw "$Description does not use a canonical GitHub API URI."
    }
    $memory = New-Object IO.MemoryStream
    try {
        [void](Invoke-AtlasBoundedHttpGet -Uri $Uri -OutputStream $memory `
                -MaximumBytes 1048576 -MaximumSeconds 30 -GitHubApi)
        $utf8 = New-Object Text.UTF8Encoding($false, $true)
        return ($utf8.GetString($memory.ToArray()) | ConvertFrom-Json -ErrorAction Stop)
    }
    finally {
        $memory.Dispose()
    }
}

function Resolve-AtlasGitHubReleaseAssetMetadata {
    param(
        [Parameter(Mandatory = $true)]$Release,
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$AssetName
    )

    if ($Release.draft -isnot [bool] -or $Release.draft -or
        $Release.prerelease -isnot [bool] -or $Release.prerelease -or
        [string]$Release.tag_name -notmatch '^v?[0-9]+\.[0-9]+\.[0-9]+$') {
        throw 'GitHub latest-release metadata is not a stable semantic-version release.'
    }
    $assets = @($Release.assets | Where-Object { $_.name -ceq $AssetName })
    if ($assets.Count -ne 1) {
        throw "GitHub metadata did not contain exactly one '$AssetName' asset."
    }
    $asset = $assets[0]
    $digest = [regex]::Match([string]$asset.digest, '^sha256:([0-9a-fA-F]{64})$')
    [long]$bytes = 0
    [long]$assetId = 0
    if ($asset.state -cne 'uploaded' -or -not $digest.Success -or
        -not [long]::TryParse([string]$asset.size, [ref]$bytes) -or
        $bytes -lt 1 -or $bytes -gt 1073741824 -or
        -not [long]::TryParse([string]$asset.id, [ref]$assetId) -or $assetId -lt 1) {
        throw "GitHub's '$AssetName' asset is not a complete upload with a bounded digest and size."
    }
    $tag = [string]$Release.tag_name
    $url = "https://github.com/$Owner/$Repository/releases/download/$tag/$AssetName"
    if ([string]$asset.browser_download_url -cne $url) {
        throw "GitHub's '$AssetName' asset URL does not match its canonical repository and tag."
    }
    return [pscustomobject]@{
        Tag = $tag; Version = $tag.TrimStart('v'); Uri = [uri]$url
        Sha256 = $digest.Groups[1].Value.ToLowerInvariant()
        Size = $bytes; AssetId = $assetId
    }
}

function Get-AtlasLatestGitHubReleaseAsset {
    param(
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$AssetName,
        [Parameter(Mandatory = $true)][long]$ExpectedRepositoryId,
        [Parameter(Mandatory = $true)][long]$ExpectedOwnerId
    )

    $base = "https://api.github.com/repos/$Owner/$Repository"
    $metadata = Invoke-AtlasGitHubApiJson `
        -Uri ([uri]$base) -Description 'GitHub repository metadata'
    [void](Resolve-AtlasGitHubRepositoryMetadata -RepositoryMetadata $metadata `
            -Owner $Owner -Repository $Repository `
            -ExpectedRepositoryId $ExpectedRepositoryId -ExpectedOwnerId $ExpectedOwnerId)
    $release = Invoke-AtlasGitHubApiJson `
        -Uri ([uri]"$base/releases/latest") -Description 'GitHub release metadata'
    return Resolve-AtlasGitHubReleaseAssetMetadata -Release $release `
        -Owner $Owner -Repository $Repository -AssetName $AssetName
}

function Get-AtlasTrustedWingetPath {
    if (-not [Environment]::Is64BitProcess) {
        throw 'The trusted WinGet resolver requires a 64-bit PowerShell host.'
    }
    $system = [Environment]::GetFolderPath('System')
    $manifest = [IO.Path]::Combine(
        $system, 'WindowsPowerShell', 'v1.0', 'Modules', 'Appx', 'Appx.psd1'
    )
    if (-not [IO.File]::Exists($manifest)) {
        throw "The inbox Appx module is missing at '$manifest'."
    }
    [void](Import-Module -Name $manifest -Force -ErrorAction Stop)
    $packages = @(Appx\Get-AppxPackage -Name Microsoft.DesktopAppInstaller `
            -ErrorAction SilentlyContinue)
    try {
        $packages += @(Appx\Get-AppxPackage -AllUsers `
                -Name Microsoft.DesktopAppInstaller -ErrorAction Stop)
    }
    catch {
        Write-Verbose "The all-users App Installer query was unavailable: $($_.Exception.Message)"
    }

    $windowsApps = [IO.Path]::Combine(
        [Environment]::GetFolderPath('ProgramFiles'), 'WindowsApps'
    ).TrimEnd('\') + '\'
    $publisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
    foreach ($package in @($packages | Sort-Object Version -Descending -Unique)) {
        if ($package.Name -cne 'Microsoft.DesktopAppInstaller' -or
            $package.PackageFamilyName -cne 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -or
            $package.Publisher -cne $publisher -or [string]$package.SignatureKind -cne 'Store' -or
            [string]::IsNullOrWhiteSpace([string]$package.InstallLocation)) {
            continue
        }
        $location = [IO.Path]::GetFullPath([string]$package.InstallLocation)
        if (-not ($location.TrimEnd('\') + '\').StartsWith(
                $windowsApps, [StringComparison]::OrdinalIgnoreCase
            )) {
            continue
        }
        $candidate = [IO.Path]::Combine($location, 'winget.exe')
        try {
            $candidate = Resolve-AtlasProtectedExecutionPath `
                -Path $candidate -PathType Leaf -Description 'The WinGet executable'
        }
        catch { continue }
        $signature = Get-AuthenticodeSignature -LiteralPath $candidate
        if ($signature.Status -eq [Management.Automation.SignatureStatus]::Valid -and
            $null -ne $signature.SignerCertificate -and
            $signature.SignerCertificate.Subject -match '(^|,\s*)CN=Microsoft Corporation(,|$)') {
            return $candidate
        }
    }
    throw 'A Microsoft-signed WinGet executable was not found in Desktop App Installer.'
}

function Test-AtlasCanonicalWingetSource {
    param(
        [Parameter(Mandatory = $true)][psobject]$Source,
        [Parameter(Mandatory = $true)]
        [ValidateSet('winget', 'msstore')][string]$Name
    )

    $expected = @{
        winget = @('Microsoft.PreIndexed.Package', 'https://cdn.winget.microsoft.com/cache',
            'Microsoft.Winget.Source_8wekyb3d8bbwe', 'Microsoft.Winget.Source_8wekyb3d8bbwe',
            'StoreOrigin|Trusted')
        msstore = @('Microsoft.Rest', 'https://storeedgefd.dsx.mp.microsoft.com/v9.0',
            '', 'StoreEdgeFD', 'Trusted')
    }[$Name]
    foreach ($property in @('Name', 'Type', 'Arg', 'Data', 'Identifier', 'TrustLevel', 'Explicit')) {
        if ($null -eq $Source.PSObject.Properties[$property]) { return $false }
    }
    return $Source.Name -ceq $Name -and
        $Source.Type -ceq $expected[0] -and $Source.Arg -ceq $expected[1] -and
        [string]$Source.Data -ceq $expected[2] -and
        $Source.Identifier -ceq $expected[3] -and
        (@($Source.TrustLevel | Sort-Object) -join '|') -ceq $expected[4] -and
        $Source.Explicit -is [bool] -and -not $Source.Explicit
}

function Assert-AtlasTrustedWingetSource {
    param(
        [Parameter(Mandatory = $true)][string]$WingetPath,
        [Parameter(Mandatory = $true)]
        [ValidateSet('winget', 'msstore')][string]$Name
    )

    $output = @(& $WingetPath source export $Name --disable-interactivity 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "WinGet could not export source '$Name' (exit code $LASTEXITCODE)."
    }
    try {
        $source = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine) |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "WinGet returned invalid source metadata for '$Name': $($_.Exception.Message)"
    }
    if (-not (Test-AtlasCanonicalWingetSource -Source $source -Name $Name)) {
        throw "WinGet source '$Name' does not match Microsoft's canonical registration."
    }
}
