# Atlas.Download: size-limited HTTPS downloads, protected staging, contained native
# execution, GitHub release resolution and trusted WinGet resolution for elevated
# Atlas callers. Entry points set up the protected module path before importing this
# module; it doesn't change the process environment itself.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-AtlasProtectedStagingAcl')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-AtlasDirectoryWithSecurity')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-AtlasProtectedStagingDirectory')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Resolve-AtlasGitHubRepositoryMetadata')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Resolve-AtlasGitHubReleaseAssetMetadata')]
param()

Set-StrictMode -Version 3.0

# Atlas.Native types come from Atlas.Core, which owns Atlas's only C# compile.
$coreManifest = Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Required Atlas.Core manifest '$coreManifest' is missing."
}
# No -Force: a nested forced import unloads the caller's copy in Windows PowerShell 5.1.
Import-Module -Name $coreManifest -ErrorAction Stop

# The accounts allowed to write protected staging and execution paths: LocalSystem
# (S-1-5-18), BUILTIN\Administrators (S-1-5-32-544) and NT SERVICE\TrustedInstaller
# (S-1-5-80-956008885-...), a service SID that Windows derives from the service name.
# https://learn.microsoft.com/windows-server/identity/ad-ds/manage/understand-security-identifiers

function New-AtlasProtectedStagingAcl {
    <#
    .SYNOPSIS
        Builds the staging directory security: owned by Administrators, inheritance
        blocked, and full control for the three privileged accounts only.
    #>
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
    <#
    .SYNOPSIS
        Returns whether a directory's security matches the protected staging ACL exactly.
    .DESCRIPTION
        The ACL must be owned by Administrators, block inheritance, and hold exactly one
        explicit full-control Allow rule for each privileged account, so no other
        account can plant or change files that elevated Atlas code later runs.
    .PARAMETER Acl
        The directory security to check, usually from Get-Acl.
    #>
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
    <#
    .SYNOPSIS
        Creates a directory with its security applied at creation, so it never exists
        with inherited permissions.
    .DESCRIPTION
        .NET Framework has Directory.CreateDirectory(string, DirectorySecurity); .NET
        (PowerShell 7) moved it to FileSystemAclExtensions.Create, so both are tried.
    #>
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
    <#
    .SYNOPSIS
        Creates a uniquely named staging directory under %ProgramData% that only the
        privileged accounts can write, and returns its full path.
    .DESCRIPTION
        Throws, after removing the directory, if it didn't keep the protected ACL.
        The caller owns the directory and removes it when finished.
    #>
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
    <#
    .SYNOPSIS
        Streams an HTTPS GET into OutputStream, failing past MaximumBytes or
        MaximumSeconds, and returns the number of bytes written.
    .DESCRIPTION
        Rejects URIs that aren't HTTPS or that carry user information, any non-success
        status, and a redirect that leaves HTTPS. The deadline covers the whole
        transfer, not each read.
    .PARAMETER Uri
        The HTTPS address to download.
    .PARAMETER OutputStream
        The writable stream that receives the response body. The caller disposes it.
    .PARAMETER MaximumBytes
        The most bytes accepted, checked against Content-Length and while reading.
    .PARAMETER MaximumSeconds
        The time allowed for the whole request, from sending it to the last byte.
    .PARAMETER ExpectedBytes
        Exact length required, or -1 for any.
    .PARAMETER AllowRedirect
        Follows up to five HTTPS redirects. Without it, any redirect fails.
    .PARAMETER GitHubApi
        Sends the Accept and X-GitHub-Api-Version headers the GitHub REST API expects.
    #>
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][IO.Stream]$OutputStream,
        [Parameter(Mandatory = $true)][ValidateRange(1, 1GB)][long]$MaximumBytes,
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
    # Let Windows negotiate TLS, including TLS 1.3-only download endpoints.
    $handler.SslProtocols = [Security.Authentication.SslProtocols]::None
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
    <#
    .SYNOPSIS
        Downloads a file whose exact size and SHA-256 are known in advance, and returns
        its full path.
    .DESCRIPTION
        Creates Destination as a new file, so an existing file is never overwritten.
        On any failure, including a size or hash mismatch, the partial file is removed.
    .PARAMETER Uri
        The HTTPS address to download. HTTPS redirects are followed.
    .PARAMETER Destination
        The file to create. It must not exist; its parent directory must.
    .PARAMETER Sha256
        The expected SHA-256 as 64 hexadecimal characters, in either case.
    .PARAMETER ExpectedBytes
        The exact file length, which is also the download limit.
    .PARAMETER MaximumSeconds
        The time allowed for the whole download.
    #>
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{64}$')][string]$Sha256,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1GB)][long]$ExpectedBytes,
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
    <#
    .SYNOPSIS
        Returns whether only the privileged accounts can change a file or directory
        that elevated code will run or read.
    .DESCRIPTION
        The owner must be a privileged account, the ACL must be in canonical order, and
        no Allow rule, explicit or inherited, may give another account Modify,
        ChangePermissions or TakeOwnership.
    .PARAMETER Acl
        The file or directory security to check, usually from Get-Acl.
    #>
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
    <#
    .SYNOPSIS
        Returns the full path of an existing local file or directory that is safe to
        pass to process creation, or throws.
    .DESCRIPTION
        Accepts only an absolute drive path. Rejects NUL characters, alternate data
        streams, reparse points (symbolic links and junctions), empty files, and an
        item of the other type.
    .PARAMETER Path
        The absolute drive path to check.
    .PARAMETER PathType
        Leaf for a non-empty file, or Container for a directory.
    .PARAMETER Description
        Names the path in error messages, for example 'The executable'.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Leaf', 'Container')][string]$PathType,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path.IndexOf([char]0) -ge 0 -or
        $Path -cnotmatch '^[A-Za-z]:[\\/]') {
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
    <#
    .SYNOPSIS
        Quotes one argument so CommandLineToArgvW and the C runtime parse it back
        unchanged: backslashes are doubled only before a quote.
    #>
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
    <#
    .SYNOPSIS
        Returns whether an exception from Invoke-AtlasContainedProcess means the
        process tree may still be running.
    .DESCRIPTION
        Atlas.Native marks the exception, or one it wraps, when it couldn't confirm
        that the job object terminated every process. Callers then keep the staging
        directory rather than delete files a live process may still use.
    .PARAMETER Exception
        The caught exception; its inner exceptions are checked too.
    #>
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
    <#
    .SYNOPSIS
        Runs an executable inside a job object and waits for its whole process tree,
        returning an object whose ExitCodeUInt32 is the root process's exit code.
    .DESCRIPTION
        The process starts suspended and joins a kill-on-close job before it runs, so
        every process it starts belongs to the job. The call returns when the root has
        exited and the job is empty. Past TimeoutSeconds, the job is terminated and the
        call throws. Check a failure with Test-AtlasContainedProcessContainmentUnconfirmed
        before deleting files the process used.
    .PARAMETER FilePath
        The absolute path of the executable, checked by Resolve-AtlasProtectedExecutionPath.
    .PARAMETER ArgumentList
        Up to 128 arguments, each quoted for the Windows command-line parser.
    .PARAMETER WorkingDirectory
        The absolute path of an existing directory to start in.
    .PARAMETER Description
        Names the process in error messages.
    .PARAMETER TimeoutSeconds
        The time allowed for the whole process tree; 30 minutes by default.
    .PARAMETER Hidden
        Starts the process with its window hidden (SW_HIDE).
    .PARAMETER NoWindow
        Starts a console process without a console window (CREATE_NO_WINDOW).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [AllowEmptyCollection()][string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][ValidateLength(1, 512)][string]$Description,
        [ValidateRange(1, 86400)][int]$TimeoutSeconds = 1800,
        [switch]$Hidden,
        [switch]$NoWindow
    )

    if ($ArgumentList.Count -gt 128) { throw 'At most 128 process arguments are supported.' }
    # CreateProcessW accepts a command line of at most 32,767 characters, including
    # the terminating NUL.
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
    $serializedExecutable = ConvertTo-AtlasDownloadProcessArgument -Argument $executable
    $commandLine = $serializedExecutable + $(if ($arguments) { ' ' + $arguments } else { '' })

    try {
        Initialize-AtlasNativeType
        $exitCode = [Atlas.Native.ContainedProcess]::Run(
            $executable,
            $commandLine,
            $working,
            ($TimeoutSeconds * 1000),
            [bool]$Hidden,
            [bool]$NoWindow
        )
    }
    catch {
        if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) { throw }
        throw [InvalidOperationException]::new(
            "$Description failed: $($_.Exception.Message)",
            $_.Exception
        )
    }

    return [pscustomobject]@{ ExitCodeUInt32 = [uint32]$exitCode }
}

function Resolve-AtlasGitHubRepositoryMetadata {
    <#
    .SYNOPSIS
        Checks GitHub repository metadata against the expected numeric repository and
        owner IDs, and throws if it doesn't match.
    .DESCRIPTION
        Numeric IDs survive renames and can't be taken over by a new account with the
        same name, so a renamed or re-registered repository fails the check. Private
        and archived repositories fail too.
    #>
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
        throw "GitHub repository metadata does not match the expected repository identity for '$fullName'."
    }
    return [pscustomobject]@{
        RepositoryId = $repositoryId
        OwnerId      = $ownerId
        FullName     = $fullName
    }
}

function Invoke-AtlasGitHubApiJson {
    <#
    .SYNOPSIS
        Fetches one GitHub REST API document of at most 1 MiB within 30 seconds and
        returns it parsed from JSON.
    .DESCRIPTION
        Only https://api.github.com addresses without a port, query or fragment are
        accepted, and redirects are refused. The body must be valid UTF-8.
    .PARAMETER Uri
        The GitHub REST API address.
    .PARAMETER Description
        Names the document in error messages.
    #>
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
    <#
    .SYNOPSIS
        Picks one named asset from GitHub release metadata and returns its tag,
        version, download address, SHA-256, size and asset ID.
    .DESCRIPTION
        The release must be a published, non-prerelease vX.Y.Z tag. The asset must be
        fully uploaded, at most 1 GiB, carry GitHub's sha256 digest, and have the
        canonical download address for the repository and tag.
    #>
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
        $bytes -lt 1 -or $bytes -gt 1GB -or
        -not [long]::TryParse([string]$asset.id, [ref]$assetId) -or $assetId -lt 1) {
        throw "GitHub's '$AssetName' asset is not a complete upload with a SHA-256 digest and a size of at most 1 GB."
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
    <#
    .SYNOPSIS
        Resolves a named asset of a repository's latest stable GitHub release, after
        checking the repository's identity.
    .DESCRIPTION
        Returns the Tag, Version, Uri, Sha256, Size and AssetId to pass to
        Invoke-AtlasPinnedDownload, so the download is checked against GitHub's digest.
    .PARAMETER Owner
        The repository owner's login.
    .PARAMETER Repository
        The repository name.
    .PARAMETER AssetName
        The exact, case-sensitive asset file name.
    .PARAMETER ExpectedRepositoryId
        GitHub's numeric repository ID, which a rename or re-registration doesn't keep.
    .PARAMETER ExpectedOwnerId
        GitHub's numeric account ID of the owner.
    #>
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
    <#
    .SYNOPSIS
        Returns the path of a Microsoft-signed winget.exe from an installed Desktop App
        Installer, or throws.
    .DESCRIPTION
        Ignores PATH and the per-user execution alias. A candidate package must have
        Microsoft's family name, publisher and Store signature and be installed under
        %ProgramFiles%\WindowsApps; its winget.exe must be a normal file with a valid
        Authenticode signature from Microsoft Corporation. The newest match wins.
        Administrators also consider other accounts' registrations.
    #>
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
    # Only administrators may list other accounts' packages; a standard user's
    # sign-in replay uses its own App Installer.
    if (Test-AtlasAdmin) {
        try {
            $packages += @(Appx\Get-AppxPackage -AllUsers `
                    -Name Microsoft.DesktopAppInstaller -ErrorAction Stop)
        }
        catch {
            Write-Verbose "The all-users App Installer query was unavailable: $($_.Exception.Message)"
        }
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
    <#
    .SYNOPSIS
        Returns whether an exported WinGet source matches Microsoft's default
        registration of that source: type, address, identifier and trust level.
    #>
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
    <#
    .SYNOPSIS
        Throws unless a WinGet source still has Microsoft's default registration.
    .DESCRIPTION
        Runs 'winget source export' and compares the result, so a source that was
        replaced or pointed at another address isn't used to install software.
    .PARAMETER WingetPath
        The winget.exe to run, from Get-AtlasTrustedWingetPath.
    .PARAMETER Name
        The source to check: winget or msstore.
    #>
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

Export-ModuleMember -Function @(
    'New-AtlasProtectedStagingDirectory', 'Test-AtlasProtectedStagingAcl',
    'Invoke-AtlasBoundedHttpGet', 'Invoke-AtlasPinnedDownload',
    'Test-AtlasProtectedExecutionAcl', 'Resolve-AtlasProtectedExecutionPath',
    'Invoke-AtlasContainedProcess', 'Test-AtlasContainedProcessContainmentUnconfirmed',
    'Invoke-AtlasGitHubApiJson', 'Get-AtlasLatestGitHubReleaseAsset',
    'Get-AtlasTrustedWingetPath', 'Assert-AtlasTrustedWingetSource'
)
