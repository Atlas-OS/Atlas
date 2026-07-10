# Pinned Process Explorer package management for the privileged toggle.

$downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
if (-not [IO.File]::Exists($downloadIntegrity)) {
    throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
}
. $downloadIntegrity

$script:AtlasProcessExplorerVersion = '17.12'
$script:AtlasProcessExplorerArchiveSha256 = '47ff65944e87280a0d40e6eb7a6157f13f46d605df44ff794784b54d56795aa6'
$script:AtlasProcessExplorerArchiveBytes = 3511555
$script:AtlasProcessExplorerUri = 'https://download.sysinternals.com/files/ProcessExplorer.zip'
$script:AtlasProcessExplorerBinaries = @{
    x86   = @{ Name = 'procexp.exe'; Hash = 'b29917ce089e46bc6238e3e9e20596599bcbe7aa10d4f688bc32db94d6e4dae8' }
    x64   = @{ Name = 'procexp64.exe'; Hash = '8404b6cfad9d998b10d2df6073e1275b7744c0416982bdc5cb7ef5b74348333d' }
    arm64 = @{ Name = 'procexp64a.exe'; Hash = 'f2a763d4ad679a2e585ff95c792b476c749832a1b6ba1f7521f387ff4e943f56' }
}
$script:AtlasProcessExplorerAllowedFiles = @(
    'procexp.exe'
    'procexp64.exe'
    'procexp64a.exe'
    'Atlas.ProcessExplorer.State.json'
    'Atlas.ProcessExplorer.Pending.json'
    'Atlas.ProcessExplorer.Shortcut.lnk'
    'Microsoft.Sysinternals.ProcessExplorer_Microsoft.Winget.Source_8wekyb3d8bbwe.db'
    'Microsoft.Sysinternals.ProcessExplorer_DefaultSource.db'
)
$script:AtlasProcessExplorerStateFileName = 'Atlas.ProcessExplorer.State.json'
$script:AtlasProcessExplorerPendingFileName = 'Atlas.ProcessExplorer.Pending.json'
$script:AtlasProcessExplorerShortcutTemplateName = 'Atlas.ProcessExplorer.Shortcut.lnk'
$script:AtlasProcessExplorerUninstallJournalName = 'Atlas.ProcessExplorer.Uninstall.json'
$script:AtlasProcessExplorerTransactionType = 'Atlas.ProcessExplorer.PackageTransaction'
$script:AtlasProcessExplorerStateType = 'Atlas.ProcessExplorer.InstallState'

function Get-AtlasProcessExplorerLayout {
    [CmdletBinding()]
    param()

    $scriptsPath = [IO.Directory]::GetParent($PSScriptRoot).FullName
    $atlasModulesPath = [IO.Directory]::GetParent($scriptsPath).FullName
    $expectedAtlasModulesPath = [IO.Path]::GetFullPath(
        [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows),
            'AtlasModules'
        )
    )
    if (-not [IO.Path]::GetFullPath($atlasModulesPath).Equals(
            $expectedAtlasModulesPath,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Process Explorer package management is restricted to '$expectedAtlasModulesPath'."
    }

    $appsPath = [IO.Path]::Combine($atlasModulesPath, 'Apps')
    return [pscustomobject]@{
        AtlasModulesPath = $atlasModulesPath
        AppsPath         = $appsPath
        PackagePath      = [IO.Path]::Combine($appsPath, 'ProcessExplorer')
    }
}

function Enter-AtlasProcessExplorerOperationLock {
    [CmdletBinding()]
    param(
        [string]$AppsPath,

        [ValidateRange(100, 30000)]
        [int]$TimeoutMilliseconds = 5000
    )

    if ([string]::IsNullOrWhiteSpace($AppsPath)) {
        $layout = Get-AtlasProcessExplorerLayout
        Assert-AtlasProcessExplorerParent -Path $layout.AtlasModulesPath
        if (-not [IO.Directory]::Exists($layout.AppsPath)) {
            [void](New-Item -Path $layout.AppsPath -ItemType Directory -ErrorAction Stop)
        }
        $AppsPath = $layout.AppsPath
    }
    $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
    Assert-AtlasProcessExplorerParent -Path $appsFullPath
    $lockPath = [IO.Path]::Combine($appsFullPath, 'Atlas.ProcessExplorer.lock')
    $deadline = [Diagnostics.Stopwatch]::StartNew()
    $stream = $null
    do {
        try {
            $stream = New-Object IO.FileStream(
                $lockPath,
                [IO.FileMode]::OpenOrCreate,
                [IO.FileAccess]::ReadWrite,
                [IO.FileShare]::None
            )
            break
        }
        catch [IO.IOException] {
            if ($deadline.ElapsedMilliseconds -ge $TimeoutMilliseconds) {
                throw "Another Process Explorer operation still owns the protected lock '$lockPath'."
            }
            Start-Sleep -Milliseconds 100
        }
    } while ($deadline.ElapsedMilliseconds -lt $TimeoutMilliseconds)

    if ($null -eq $stream) {
        throw "The protected Process Explorer operation lock '$lockPath' could not be acquired."
    }
    try {
        $lockItem = Get-Item -LiteralPath $lockPath -Force -ErrorAction Stop
        if (($lockItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            -not (Test-AtlasProcessExplorerProtectedAcl `
                -Acl (Get-Acl -LiteralPath $lockPath -ErrorAction Stop))) {
            throw "The Process Explorer operation lock '$lockPath' is not protected."
        }
        return [pscustomobject]@{
            PSTypeName = 'Atlas.ProcessExplorer.OperationLock'
            AppsPath = $appsFullPath
            Path = $lockPath
            Stream = $stream
        }
    }
    catch {
        $stream.Dispose()
        throw
    }
}

function Exit-AtlasProcessExplorerOperationLock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Lock
    )

    if ($Lock.PSObject.TypeNames -notcontains 'Atlas.ProcessExplorer.OperationLock' -or
        $null -eq $Lock.Stream) {
        throw 'The Process Explorer operation lock has an unexpected type.'
    }
    $Lock.Stream.Dispose()
    $Lock.Stream = $null
}

function Assert-AtlasProcessExplorerOperationLock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Lock,

        [Parameter(Mandatory = $true)]
        [string]$AppsPath
    )

    if ($Lock.PSObject.TypeNames -notcontains 'Atlas.ProcessExplorer.OperationLock' -or
        $null -eq $Lock.Stream -or -not $Lock.Stream.CanWrite -or
        -not [IO.Path]::GetFullPath([string]$Lock.AppsPath).TrimEnd('\').Equals(
            [IO.Path]::GetFullPath($AppsPath).TrimEnd('\'),
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The Process Explorer operation is not covered by the expected protected lock.'
    }
}

function Assert-AtlasProcessExplorerParent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (-not $item.PSIsContainer -or
        ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The protected Process Explorer parent '$Path' is not a normal directory."
    }

    $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    if (-not (Test-AtlasProcessExplorerProtectedAcl -Acl $acl)) {
        throw "The protected Process Explorer directory '$Path' has an untrusted owner or writable principal."
    }
}

function Test-AtlasProcessExplorerProtectedAcl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.FileSystemSecurity]$Acl
    )

    $privilegedSids = @(
        'S-1-5-18'
        'S-1-5-32-544'
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
    )
    $owner = $Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
    if ($owner -notin $privilegedSids -or -not $Acl.AreAccessRulesCanonical) {
        return $false
    }

    # Match every filesystem mutation bit directly. FileSystemRights.Modify also
    # contains read bits, so using it as a mask can both miss unusual write ACEs
    # and incorrectly reject harmless read-only principals.
    $mutationRights = [Security.AccessControl.FileSystemRights]::WriteData -bor
        [Security.AccessControl.FileSystemRights]::AppendData -bor
        [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor
        [Security.AccessControl.FileSystemRights]::WriteAttributes -bor
        [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor
        [Security.AccessControl.FileSystemRights]::Delete -bor
        [Security.AccessControl.FileSystemRights]::ChangePermissions -bor
        [Security.AccessControl.FileSystemRights]::TakeOwnership
    foreach ($rule in $Acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
        if ($rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
            ($rule.FileSystemRights -band $mutationRights) -ne 0 -and
            $rule.IdentityReference.Value -notin $privilegedSids) {
            return $false
        }
    }
    return $true
}

function Assert-AtlasProcessExplorerDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$AppsPath
    )

    $directory = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
    if (-not $directory.PSIsContainer -or
        ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not $directory.Parent.FullName.Equals($appsFullPath, [StringComparison]::OrdinalIgnoreCase) -or
        $directory.Name -notmatch '^ProcessExplorer(?:\.(?:new|old|remove)-[0-9a-f]{32})?$') {
        throw "The Process Explorer package path '$Path' is not an expected direct child of '$AppsPath'."
    }
    Assert-AtlasProcessExplorerParent -Path $directory.FullName

    $entries = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction Stop)
    $failedStateReplacements = @($entries | Where-Object {
            -not $_.PSIsContainer -and
            $_.Name -match '^Atlas\.ProcessExplorer\.(?:State|Pending)\.json\.failed-[0-9a-f]{32}$'
        })
    foreach ($failed in $failedStateReplacements) {
        $maximumBytes = if ($failed.Name -like 'Atlas.ProcessExplorer.Pending.json.failed-*') {
            4194304
        }
        else { 2097152 }
        if (($failed.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $failed.Length -gt $maximumBytes -or
            -not (Test-AtlasProcessExplorerProtectedAcl `
                -Acl (Get-Acl -LiteralPath $failed.FullName -ErrorAction Stop))) {
            throw "The failed Process Explorer record generation '$($failed.FullName)' is unsafe."
        }
    }
    $orphanStateTemps = @($entries | Where-Object {
            -not $_.PSIsContainer -and
            $_.Name -match '^Atlas\.ProcessExplorer\.(?:State|Pending)\.json\.new-[0-9a-f]{32}$'
        })
    foreach ($orphan in $orphanStateTemps) {
        $maximumBytes = if ($orphan.Name -like 'Atlas.ProcessExplorer.Pending.json.*-*') {
            4194304
        }
        else { 2097152 }
        if (($orphan.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $orphan.Length -gt $maximumBytes) {
            throw "The orphan Process Explorer state temp '$($orphan.FullName)' is not a bounded normal file."
        }
        $orphanAcl = Get-Acl -LiteralPath $orphan.FullName -ErrorAction Stop
        if (-not (Test-AtlasProcessExplorerProtectedAcl -Acl $orphanAcl)) {
            throw "The orphan Process Explorer state temp '$($orphan.FullName)' is not protected."
        }
        Remove-Item -LiteralPath $orphan.FullName -Force -ErrorAction Stop
    }
    if ($orphanStateTemps.Count -ne 0) {
        $entries = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction Stop)
    }
    $recoveryBackups = @($entries | Where-Object {
            -not $_.PSIsContainer -and
            $_.Name -match '^Atlas\.ProcessExplorer\.(?:State|Pending)\.json\.backup-[0-9a-f]{32}$'
        })
    foreach ($backup in $recoveryBackups) {
        $maximumBytes = if ($backup.Name -like 'Atlas.ProcessExplorer.Pending.json.backup-*') {
            4194304
        }
        else { 2097152 }
        if (($backup.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $backup.Length -le 0 -or $backup.Length -gt $maximumBytes -or
            -not (Test-AtlasProcessExplorerProtectedAcl `
                -Acl (Get-Acl -LiteralPath $backup.FullName -ErrorAction Stop))) {
            throw "The Process Explorer recovery backup '$($backup.FullName)' is unsafe."
        }
    }
    $unexpected = @($entries | Where-Object {
            $_.PSIsContainer -or
            ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            ($_.Name -notin $script:AtlasProcessExplorerAllowedFiles -and
                $_.Name -notmatch '^Atlas\.ProcessExplorer\.(?:State|Pending)\.json\.(?:backup|failed)-[0-9a-f]{32}$')
        })
    if ($unexpected.Count -ne 0) {
        throw "The Process Explorer package directory contains unexpected entries: $($unexpected.Name -join ', ')."
    }
    foreach ($entry in $entries) {
        $entryAcl = Get-Acl -LiteralPath $entry.FullName -ErrorAction Stop
        if (-not (Test-AtlasProcessExplorerProtectedAcl -Acl $entryAcl)) {
            throw "The Process Explorer package entry '$($entry.FullName)' has an untrusted owner or writable principal."
        }
    }

    return $directory
}

function Remove-AtlasProcessExplorerDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$AppsPath
    )

    if (-not [IO.Directory]::Exists($Path)) {
        return
    }
    $directory = Assert-AtlasProcessExplorerDirectory -Path $Path -AppsPath $AppsPath
    $entries = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction Stop |
        Sort-Object @{ Expression = {
                    if ($_.Name -in @(
                            $script:AtlasProcessExplorerPendingFileName,
                            $script:AtlasProcessExplorerStateFileName
                        )) { 1 } else { 0 }
                } })
    foreach ($entry in $entries) {
        Remove-Item -LiteralPath $entry.FullName -Force -ErrorAction Stop
    }
    Remove-Item -LiteralPath $directory.FullName -Force -ErrorAction Stop
}

function Stop-AtlasProcessExplorerPackageProcesses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath
    )

    if (-not [IO.Directory]::Exists($PackagePath)) {
        return
    }
    $expectedPaths = @($script:AtlasProcessExplorerAllowedFiles | ForEach-Object {
            [IO.Path]::GetFullPath([IO.Path]::Combine($PackagePath, $_))
        })

    foreach ($process in @(Get-Process -Name procexp, procexp64, procexp64a -ErrorAction SilentlyContinue)) {
        try {
            $processPath = [IO.Path]::GetFullPath($process.Path)
        }
        catch {
            continue
        }
        if (-not @($expectedPaths | Where-Object {
                    $_.Equals($processPath, [StringComparison]::OrdinalIgnoreCase)
                })) {
            continue
        }

        $process.Kill()
        if (-not $process.WaitForExit(5000)) {
            throw "Process Explorer process $($process.Id) did not stop before package replacement."
        }
    }
}

function Get-AtlasProcessExplorerFileSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
}

function Get-AtlasProcessExplorerBytesSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Write-AtlasProcessExplorerDurableFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $stream = $null
    try {
        $stream = New-Object IO.FileStream(
            $Path,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $stream.Write($Bytes, 0, $Bytes.Length)
        # The temp must be on durable storage before its rename/replace becomes
        # an authoritative ownership or phase checkpoint.
        $stream.Flush($true)
    }
    finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function ConvertFrom-AtlasProcessExplorerJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [long]$MaximumBytes
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $item.Length -le 0 -or $item.Length -gt $MaximumBytes) {
        throw "The protected JSON record '$Path' is not a bounded normal file."
    }
    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    return $utf8.GetString([IO.File]::ReadAllBytes($item.FullName)) |
        ConvertFrom-Json -ErrorAction Stop
}

function Repair-AtlasProcessExplorerRecordBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrimaryPath,

        [Parameter(Mandatory = $true)]
        [long]$MaximumBytes,

        [Parameter(Mandatory = $true)]
        [ValidateSet('State', 'Pending')]
        [string]$RecordKind,

        [Parameter(Mandatory = $true)]
        [string]$SemanticPackagePath
    )

    $parentPath = [IO.Directory]::GetParent([IO.Path]::GetFullPath($PrimaryPath)).FullName
    $backupPattern = [IO.Path]::GetFileName($PrimaryPath) + '.backup-*'
    $backups = @(Get-ChildItem -LiteralPath $parentPath -Filter $backupPattern `
        -File -Force -ErrorAction Stop | Where-Object {
            $_.Name -match ('^' + [regex]::Escape([IO.Path]::GetFileName($PrimaryPath)) +
                '\.backup-[0-9a-f]{32}$')
        })
    $failedPattern = [IO.Path]::GetFileName($PrimaryPath) + '.failed-*'
    $failedGenerations = @(Get-ChildItem -LiteralPath $parentPath -Filter $failedPattern `
        -File -Force -ErrorAction Stop | Where-Object {
            $_.Name -match ('^' + [regex]::Escape([IO.Path]::GetFileName($PrimaryPath)) +
                '\.failed-[0-9a-f]{32}$')
        })
    if ($failedGenerations.Count -gt 1) {
        throw "Multiple failed protected record generations exist for '$PrimaryPath'."
    }
    if ($failedGenerations.Count -eq 1) {
        $failed = $failedGenerations[0]
        if (($failed.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $failed.Length -gt $MaximumBytes -or
            -not (Test-AtlasProcessExplorerProtectedAcl `
                -Acl (Get-Acl -LiteralPath $failed.FullName -ErrorAction Stop))) {
            throw "The failed protected record generation '$($failed.FullName)' is unsafe."
        }
        if ($backups.Count -ne 0 -or -not [IO.File]::Exists($PrimaryPath)) {
            throw "The failed protected record generation for '$PrimaryPath' has ambiguous siblings."
        }
        try {
            $confirmedPrimary = ConvertFrom-AtlasProcessExplorerJsonFile `
                -Path $PrimaryPath `
                -MaximumBytes $MaximumBytes
            if ($RecordKind -eq 'State') {
                [void](Assert-AtlasProcessExplorerInstallState `
                    -State $confirmedPrimary `
                    -PackagePath $SemanticPackagePath)
            }
            else {
                [void](Assert-AtlasProcessExplorerPendingInstall `
                    -Pending $confirmedPrimary `
                    -PackagePath $SemanticPackagePath)
            }
        }
        catch {
            throw "The primary protected record is not valid enough to discard its failed generation: $($_.Exception.Message)"
        }
        [IO.File]::Delete($failed.FullName)
        return
    }
    if ($backups.Count -eq 0) { return }
    if ($backups.Count -ne 1) {
        throw "Multiple protected recovery backups exist for '$PrimaryPath'."
    }
    $backupPath = $backups[0].FullName
    $primaryValid = $false
    if ([IO.File]::Exists($PrimaryPath)) {
        try {
            $primary = ConvertFrom-AtlasProcessExplorerJsonFile `
                -Path $PrimaryPath `
                -MaximumBytes $MaximumBytes
            if ($RecordKind -eq 'State') {
                [void](Assert-AtlasProcessExplorerInstallState `
                    -State $primary `
                    -PackagePath $SemanticPackagePath)
            }
            else {
                [void](Assert-AtlasProcessExplorerPendingInstall `
                    -Pending $primary `
                    -PackagePath $SemanticPackagePath)
            }
            $primaryValid = $true
        }
        catch {
            $primaryValid = $false
        }
    }
    if ($primaryValid) {
        [IO.File]::Delete($backupPath)
        return
    }

    $backup = ConvertFrom-AtlasProcessExplorerJsonFile `
        -Path $backupPath `
        -MaximumBytes $MaximumBytes
    if ($RecordKind -eq 'State') {
        [void](Assert-AtlasProcessExplorerInstallState `
            -State $backup `
            -PackagePath $SemanticPackagePath)
    }
    else {
        [void](Assert-AtlasProcessExplorerPendingInstall `
            -Pending $backup `
            -PackagePath $SemanticPackagePath)
    }
    if ([IO.File]::Exists($PrimaryPath)) {
        $failedPath = "$PrimaryPath.failed-$([guid]::NewGuid().ToString('N'))"
        $restored = $false
        try {
            [IO.File]::Replace($backupPath, $PrimaryPath, $failedPath)
            $restored = $true
        }
        finally {
            if ($restored -and [IO.File]::Exists($failedPath)) {
                [IO.File]::Delete($failedPath)
            }
        }
    }
    else {
        [IO.File]::Move($backupPath, $PrimaryPath)
    }
}

function Restore-AtlasProcessExplorerRecordBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrimaryPath,

        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    if (-not [IO.File]::Exists($BackupPath)) {
        throw "The protected recovery backup '$BackupPath' is unavailable."
    }
    if ([IO.File]::Exists($PrimaryPath)) {
        $failedPath = "$PrimaryPath.failed-$([guid]::NewGuid().ToString('N'))"
        $restored = $false
        try {
            [IO.File]::Replace($BackupPath, $PrimaryPath, $failedPath)
            $restored = $true
        }
        finally {
            # Only discard the failed replacement after File.Replace confirms that
            # the protected backup became the primary record. On an ambiguous
            # failure, retain every generation for startup/manual recovery.
            if ($restored -and [IO.File]::Exists($failedPath)) {
                [IO.File]::Delete($failedPath)
            }
        }
    }
    else {
        [IO.File]::Move($BackupPath, $PrimaryPath)
    }
}

function Assert-AtlasProcessExplorerPersistedRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [long]$MaximumBytes,

        [Parameter(Mandatory = $true)]
        [ValidateSet('State', 'Pending')]
        [string]$RecordKind,

        [Parameter(Mandatory = $true)]
        [string]$SemanticPackagePath,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{64}$')]
        [string]$ExpectedSha256
    )

    # This deliberately bypasses Read-* and its crash-recovery fallback. A
    # writer may only report success when the primary is the exact record it
    # just staged; silently recovering the previous backup is not a successful
    # checkpoint of the caller's new phase/progress.
    $record = ConvertFrom-AtlasProcessExplorerJsonFile `
        -Path $Path `
        -MaximumBytes $MaximumBytes
    if ($RecordKind -eq 'State') {
        [void](Assert-AtlasProcessExplorerInstallState `
            -State $record `
            -PackagePath $SemanticPackagePath)
    }
    else {
        [void](Assert-AtlasProcessExplorerPendingInstall `
            -Pending $record `
            -PackagePath $SemanticPackagePath)
    }
    if ((Get-AtlasProcessExplorerFileSha256 -Path $Path) -ne
        $ExpectedSha256.ToLowerInvariant()) {
        throw "The persisted Process Explorer $RecordKind checkpoint does not match the intended record."
    }
}

function Test-AtlasProcessExplorerShortcutAcl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Security.AccessControl.FileSystemSecurity]$Acl
    )

    $privilegedSids = @(
        'S-1-5-18'
        'S-1-5-32-544'
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
    )
    $owner = $Acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
    if ($owner -notin $privilegedSids -or -not $Acl.AreAccessRulesCanonical) {
        return $false
    }

    # The common Start Menu is intentionally UI/user-controlled state. Windows
    # can grant an interactive user Delete/DeleteChild there, so availability is
    # not a privileged invariant. Content creation or mutation still is: reject
    # every non-privileged ACE that can create/alter shortcut bytes or its ACL.
    $contentMutationRights = [Security.AccessControl.FileSystemRights]::WriteData -bor
        [Security.AccessControl.FileSystemRights]::AppendData -bor
        [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor
        [Security.AccessControl.FileSystemRights]::WriteAttributes -bor
        [Security.AccessControl.FileSystemRights]::ChangePermissions -bor
        [Security.AccessControl.FileSystemRights]::TakeOwnership
    foreach ($rule in $Acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
        if ($rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
            ($rule.FileSystemRights -band $contentMutationRights) -ne 0 -and
            $rule.IdentityReference.Value -notin $privilegedSids) {
            return $false
        }
    }
    return $true
}

function Get-AtlasProcessExplorerShortcutState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$ReadBytes
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    if ([IO.Path]::GetFileName($fullPath) -ne 'Process Explorer.lnk') {
        throw "The Process Explorer shortcut destination '$fullPath' is unexpected."
    }
    $parentPath = [IO.Directory]::GetParent($fullPath).FullName
    $parent = Get-Item -LiteralPath $parentPath -Force -ErrorAction Stop
    if (-not $parent.PSIsContainer -or
        ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not (Test-AtlasProcessExplorerShortcutAcl `
            -Acl (Get-Acl -LiteralPath $parent.FullName -ErrorAction Stop))) {
        throw 'The Process Explorer shortcut parent permits untrusted content mutation.'
    }
    if (-not [IO.File]::Exists($fullPath)) {
        return [pscustomobject]@{
            Exists = $false
            Path = $fullPath
            Sha256 = $null
            Bytes = $null
        }
    }
    $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    if ($item.PSIsContainer -or
        ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $item.Length -le 0 -or $item.Length -gt 1048576 -or
        -not (Test-AtlasProcessExplorerShortcutAcl `
            -Acl (Get-Acl -LiteralPath $item.FullName -ErrorAction Stop))) {
        throw 'The Process Explorer shortcut is not a bounded content-protected normal file.'
    }
    return [pscustomobject]@{
        Exists = $true
        Path = $item.FullName
        Sha256 = Get-AtlasProcessExplorerFileSha256 -Path $item.FullName
        Bytes = if ($ReadBytes) { [IO.File]::ReadAllBytes($item.FullName) } else { $null }
    }
}

function Repair-AtlasProcessExplorerShortcutArtifacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$ArtifactId,

        [Parameter(Mandatory = $true)]
        [bool]$TargetExists,

        [AllowNull()]
        [string]$TargetSha256,

        [AllowNull()]
        [string]$AlternateSha256,

        [switch]$AllowCompleteTarget
    )

    if (($TargetExists -and [string]$TargetSha256 -notmatch '^[0-9a-fA-F]{64}$') -or
        (-not $TargetExists -and $null -ne $TargetSha256) -or
        ($null -ne $AlternateSha256 -and
            [string]$AlternateSha256 -notmatch '^[0-9a-fA-F]{64}$')) {
        throw 'The Process Explorer shortcut artifact target is invalid.'
    }
    if ($TargetExists) { $TargetSha256 = $TargetSha256.ToLowerInvariant() }
    if ($null -ne $AlternateSha256) {
        $AlternateSha256 = $AlternateSha256.ToLowerInvariant()
    }

    $primary = Get-AtlasProcessExplorerShortcutState -Path $Path
    $fullPath = $primary.Path
    $parentPath = [IO.Directory]::GetParent($fullPath).FullName
    $artifactEntries = @(Get-ChildItem -LiteralPath $parentPath `
        -Filter 'Process Explorer.lnk.atlas-*' -Force -ErrorAction Stop)
    $artifacts = New-Object System.Collections.Generic.List[object]
    foreach ($entry in $artifactEntries) {
        if ($entry.Name -notmatch '^Process Explorer\.lnk\.atlas-(restore|backup|failed)-([0-9a-f]{32})$') {
            throw "The Process Explorer shortcut artifact '$($entry.FullName)' is unexpected."
        }
        $artifactKind = $Matches[1]
        $artifactOperationId = $Matches[2]
        if ($artifactOperationId -ne $ArtifactId) {
            throw 'A foreign Process Explorer shortcut artifact requires manual recovery.'
        }
        if ($entry.PSIsContainer -or
            ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $entry.Length -le 0 -or $entry.Length -gt 1048576 -or
            -not (Test-AtlasProcessExplorerShortcutAcl `
                -Acl (Get-Acl -LiteralPath $entry.FullName -ErrorAction Stop))) {
            throw "The Process Explorer shortcut artifact '$($entry.FullName)' is unsafe."
        }
        $artifactHash = Get-AtlasProcessExplorerFileSha256 -Path $entry.FullName
        if (($TargetExists -and $artifactHash -eq $TargetSha256) -or
            ($null -ne $AlternateSha256 -and $artifactHash -eq $AlternateSha256)) {
            $artifacts.Add([pscustomobject]@{
                    Kind = $artifactKind
                    Path = $entry.FullName
                    Sha256 = $artifactHash
                })
        }
        else {
            throw 'A Process Explorer shortcut artifact has unknown bytes.'
        }
    }
    foreach ($kind in @('restore', 'backup', 'failed')) {
        if (@($artifacts | Where-Object { $_.Kind -eq $kind }).Count -gt 1) {
            throw "Multiple Process Explorer shortcut $kind artifacts require manual recovery."
        }
    }

    $failed = @($artifacts | Where-Object { $_.Kind -eq 'failed' })
    if ($failed.Count -ne 0) {
        # A displaced primary is only disposable after the replacement target is
        # independently visible and exact. Otherwise retain the failed generation.
        if ($TargetExists -and $primary.Exists -and $primary.Sha256 -eq $TargetSha256) {
            [IO.File]::Delete($failed[0].Path)
            [void]$artifacts.Remove($failed[0])
        }
        else {
            throw 'An ambiguous Process Explorer shortcut replacement is retained for recovery.'
        }
    }

    if ($TargetExists -and $primary.Exists -and $primary.Sha256 -eq $TargetSha256) {
        foreach ($artifact in $artifacts.ToArray()) {
            [IO.File]::Delete($artifact.Path)
        }
        return [pscustomobject]@{ TargetSatisfied = $true; Sha256 = $TargetSha256 }
    }
    if (-not $TargetExists -and -not $primary.Exists) {
        foreach ($artifact in $artifacts.ToArray()) {
            [IO.File]::Delete($artifact.Path)
        }
        return [pscustomobject]@{ TargetSatisfied = $true; Sha256 = $null }
    }

    if ($TargetExists -and -not $primary.Exists) {
        if (-not $AllowCompleteTarget) {
            throw 'The Process Explorer shortcut primary is missing in its durable completed phase.'
        }
        $targetArtifacts = @($artifacts | Where-Object { $_.Sha256 -eq $TargetSha256 })
        if ($targetArtifacts.Count -gt 1) {
            throw 'Multiple Process Explorer shortcut artifacts contain the durable target.'
        }
        if ($targetArtifacts.Count -eq 1) {
            [IO.File]::Move($targetArtifacts[0].Path, $fullPath)
            $confirmed = Get-AtlasProcessExplorerShortcutState -Path $fullPath
            if (-not $confirmed.Exists -or $confirmed.Sha256 -ne $TargetSha256) {
                throw 'The Process Explorer shortcut artifact publication failed verification.'
            }
            foreach ($artifact in $artifacts.ToArray()) {
                if ([IO.File]::Exists($artifact.Path)) { [IO.File]::Delete($artifact.Path) }
            }
            return [pscustomobject]@{ TargetSatisfied = $true; Sha256 = $TargetSha256 }
        }
        foreach ($artifact in $artifacts.ToArray()) {
            [IO.File]::Delete($artifact.Path)
        }
        return [pscustomobject]@{ TargetSatisfied = $false; Sha256 = $null }
    }

    $primaryIsAlternate = $primary.Exists -and
        $null -ne $AlternateSha256 -and $primary.Sha256 -eq $AlternateSha256
    if (-not $primaryIsAlternate) {
        throw 'The Process Explorer shortcut primary matches neither durable state.'
    }
    if (-not $AllowCompleteTarget) {
        throw 'The Process Explorer shortcut primary contradicts its durable completed phase.'
    }

    if ($TargetExists) {
        $targetArtifacts = @($artifacts | Where-Object { $_.Sha256 -eq $TargetSha256 })
        if ($targetArtifacts.Count -gt 1) {
            throw 'Multiple Process Explorer shortcut artifacts contain the durable target.'
        }
        if ($targetArtifacts.Count -eq 1) {
            $failedPath = "$fullPath.atlas-failed-$ArtifactId"
            if ([IO.File]::Exists($failedPath)) {
                throw 'The Process Explorer shortcut failed-generation path is occupied.'
            }
            $replacementConfirmed = $false
            try {
                [IO.File]::Replace($targetArtifacts[0].Path, $fullPath, $failedPath)
                $confirmed = Get-AtlasProcessExplorerShortcutState -Path $fullPath
                if (-not $confirmed.Exists -or $confirmed.Sha256 -ne $TargetSha256) {
                    throw 'The Process Explorer shortcut artifact promotion failed verification.'
                }
                $replacementConfirmed = $true
            }
            finally {
                if ($replacementConfirmed -and [IO.File]::Exists($failedPath)) {
                    $failedItem = Get-Item -LiteralPath $failedPath -Force -ErrorAction Stop
                    if ($failedItem.PSIsContainer -or
                        ($failedItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                        $failedItem.Length -le 0 -or $failedItem.Length -gt 1048576 -or
                        (Get-AtlasProcessExplorerFileSha256 -Path $failedPath) -ne $AlternateSha256) {
                        throw 'The displaced Process Explorer shortcut generation is unsafe.'
                    }
                    [IO.File]::Delete($failedPath)
                }
            }
            foreach ($artifact in $artifacts.ToArray()) {
                if ([IO.File]::Exists($artifact.Path)) { [IO.File]::Delete($artifact.Path) }
            }
            return [pscustomobject]@{ TargetSatisfied = $true; Sha256 = $TargetSha256 }
        }
    }

    # No artifact can complete the target. Remove only validated, known duplicate
    # restore/backup generations; the caller's durable restore action still owns
    # the primary transition.
    foreach ($artifact in $artifacts.ToArray()) {
        [IO.File]::Delete($artifact.Path)
    }
    return [pscustomobject]@{ TargetSatisfied = $false; Sha256 = $primary.Sha256 }
}

function Set-AtlasProcessExplorerShortcutBytesAtomically {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$ArtifactId,

        [AllowNull()]
        [string]$AlternateSha256
    )

    if ($Bytes.Length -le 0 -or $Bytes.Length -gt 1048576) {
        throw 'The Process Explorer shortcut bytes are empty or exceed the ownership bound.'
    }
    $expectedHash = Get-AtlasProcessExplorerBytesSha256 -Bytes $Bytes
    $repair = Repair-AtlasProcessExplorerShortcutArtifacts `
        -Path $Path `
        -ArtifactId $ArtifactId `
        -TargetExists $true `
        -TargetSha256 $expectedHash `
        -AlternateSha256 $AlternateSha256 `
        -AllowCompleteTarget
    if ($repair.TargetSatisfied) { return $expectedHash }

    $fullPath = [IO.Path]::GetFullPath($Path)
    $temporaryPath = "$fullPath.atlas-restore-$ArtifactId"
    $backupPath = "$fullPath.atlas-backup-$ArtifactId"
    $stream = $null
    try {
        $stream = New-Object IO.FileStream(
            $temporaryPath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $stream.Write($Bytes, 0, $Bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null
        if ((Get-AtlasProcessExplorerFileSha256 -Path $temporaryPath) -ne $expectedHash) {
            throw 'The staged Process Explorer shortcut failed its byte check.'
        }
        if ([IO.File]::Exists($fullPath)) {
            [IO.File]::Replace($temporaryPath, $fullPath, $backupPath)
        }
        else {
            [IO.File]::Move($temporaryPath, $fullPath)
        }
        if ((Get-AtlasProcessExplorerFileSha256 -Path $fullPath) -ne $expectedHash) {
            throw 'The Process Explorer shortcut failed its post-replace byte check.'
        }
        [void](Get-AtlasProcessExplorerShortcutState -Path $fullPath)
        if ([IO.File]::Exists($backupPath)) {
            [IO.File]::Delete($backupPath)
        }
        return $expectedHash
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}

function New-AtlasProcessExplorerInstallState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [Parameter(Mandatory = $true)]
        [bool]$DebuggerPriorExists,

        [AllowNull()]
        [string]$DebuggerPriorValue,

        [AllowNull()]
        [string]$DebuggerPriorKind,

        [Parameter(Mandatory = $true)]
        [bool]$PcwChanged,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 4)]
        [int]$PcwPriorStart,

        [Parameter(Mandatory = $true)]
        [bool]$ShortcutPriorExists,

        [AllowNull()]
        [byte[]]$ShortcutPriorBytes,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{64}$')]
        [string]$ShortcutInstalledSha256
    )

    if ($DebuggerPriorExists) {
        if ($null -eq $DebuggerPriorValue -or
            $DebuggerPriorKind -notin @('String', 'ExpandString')) {
            throw 'The prior IFEO Debugger state is incomplete or has an unsupported registry kind.'
        }
    }
    else {
        if (-not [string]::IsNullOrEmpty($DebuggerPriorValue) -or
            -not [string]::IsNullOrEmpty($DebuggerPriorKind)) {
            throw 'An absent prior IFEO Debugger value cannot carry value data.'
        }
    }

    # Windows PowerShell coerces a null value bound to [string] into an empty
    # string. Copy into untyped locals so absence has one canonical JSON null;
    # a genuine empty prior string remains valid when PriorExists is true.
    $canonicalDebuggerPriorValue = $null
    $canonicalDebuggerPriorKind = $null
    if ($DebuggerPriorExists) {
        $canonicalDebuggerPriorValue = $DebuggerPriorValue
        $canonicalDebuggerPriorKind = $DebuggerPriorKind
    }

    if ($ShortcutPriorExists -and $null -eq $ShortcutPriorBytes) {
        throw 'The prior Process Explorer shortcut bytes are missing.'
    }
    if (-not $ShortcutPriorExists -and $null -ne $ShortcutPriorBytes) {
        throw 'An absent prior Process Explorer shortcut cannot carry bytes.'
    }
    if ($null -ne $ShortcutPriorBytes -and $ShortcutPriorBytes.Length -gt 1048576) {
        throw 'The prior Process Explorer shortcut is larger than the supported ownership snapshot.'
    }

    $priorShortcutBase64 = $null
    $priorShortcutSha256 = $null
    if ($ShortcutPriorExists) {
        $priorShortcutBase64 = [Convert]::ToBase64String($ShortcutPriorBytes)
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            $priorShortcutSha256 = ([BitConverter]::ToString(
                    $sha256.ComputeHash($ShortcutPriorBytes)
                ) -replace '-', '').ToLowerInvariant()
        }
        finally {
            $sha256.Dispose()
        }
    }

    $packageFullPath = [IO.Path]::GetFullPath($PackagePath).TrimEnd('\')
    return [pscustomobject]@{
        PSTypeName = $script:AtlasProcessExplorerStateType
        SchemaVersion = 2
        InstallId = [guid]::NewGuid().ToString('N')
        PackageVersion = $script:AtlasProcessExplorerVersion
        Debugger = [pscustomobject]@{
            Changed = $true
            InstalledValue = [IO.Path]::Combine($packageFullPath, 'procexp.exe')
            InstalledKind = 'String'
            PriorExists = $DebuggerPriorExists
            PriorValue = $canonicalDebuggerPriorValue
            PriorKind = $canonicalDebuggerPriorKind
        }
        Pcw = [pscustomobject]@{
            Changed = $PcwChanged
            InstalledStart = 4
            PriorStart = $PcwPriorStart
        }
        Shortcut = [pscustomobject]@{
            Changed = $true
            InstalledSha256 = $ShortcutInstalledSha256.ToLowerInvariant()
            PriorExists = $ShortcutPriorExists
            PriorBytesBase64 = $priorShortcutBase64
            PriorSha256 = $priorShortcutSha256
        }
        RestoreProgress = [pscustomobject]@{
            Debugger = $false
            Shortcut = $false
            Pcw = $false
        }
    }
}

function Assert-AtlasProcessExplorerInstallState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$State,

        [Parameter(Mandatory = $true)]
        [string]$PackagePath
    )

    foreach ($propertyName in @(
            'SchemaVersion', 'InstallId', 'PackageVersion', 'Debugger', 'Pcw', 'Shortcut'
        )) {
        if ($null -eq $State.PSObject.Properties[$propertyName]) {
            throw "The Process Explorer ownership state is missing '$propertyName'."
        }
    }
    if ([int]$State.SchemaVersion -notin @(1, 2) -or
        [string]$State.InstallId -notmatch '^[0-9a-f]{32}$' -or
        [string]$State.PackageVersion -notmatch '^\d{1,4}(?:\.\d{1,4}){1,3}$') {
        throw 'The Process Explorer ownership state has an unsupported identity.'
    }

    if ([int]$State.SchemaVersion -eq 1) {
        # Schema 1 predates durable uninstall progress. Its protected ownership
        # snapshots are sufficient to resume idempotently, so migrate in memory
        # and persist schema 2 at the first successful restoration step.
        $State.SchemaVersion = 2
        $State | Add-Member -MemberType NoteProperty -Name RestoreProgress -Value (
            [pscustomobject]@{
                Debugger = $false
                Shortcut = $false
                Pcw = $false
            }
        ) -Force
    }
    elseif ($null -eq $State.PSObject.Properties['RestoreProgress']) {
        throw 'The Process Explorer ownership state is missing restore progress.'
    }
    foreach ($propertyName in @('Debugger', 'Shortcut', 'Pcw')) {
        if ($null -eq $State.RestoreProgress.PSObject.Properties[$propertyName] -or
            $State.RestoreProgress.$propertyName -isnot [bool]) {
            throw "The Process Explorer restore progress is missing or invalid for '$propertyName'."
        }
    }

    foreach ($propertyName in @(
            'Changed', 'InstalledValue', 'InstalledKind', 'PriorExists', 'PriorValue', 'PriorKind'
        )) {
        if ($null -eq $State.Debugger.PSObject.Properties[$propertyName]) {
            throw "The Process Explorer Debugger ownership state is missing '$propertyName'."
        }
    }
    $expectedDebugger = [IO.Path]::Combine(
        [IO.Path]::GetFullPath($PackagePath).TrimEnd('\'),
        'procexp.exe'
    )
    if ($State.Debugger.Changed -isnot [bool] -or -not $State.Debugger.Changed -or
        -not ([string]$State.Debugger.InstalledValue).Equals(
            $expectedDebugger,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$State.Debugger.InstalledKind -ne 'String' -or
        $State.Debugger.PriorExists -isnot [bool]) {
        throw 'The Process Explorer Debugger ownership state is invalid.'
    }
    if ($State.Debugger.PriorExists) {
        if ($null -eq $State.Debugger.PriorValue -or
            [string]$State.Debugger.PriorKind -notin @('String', 'ExpandString')) {
            throw 'The prior Process Explorer Debugger ownership state is invalid.'
        }
    }
    elseif ($null -ne $State.Debugger.PriorValue -or $null -ne $State.Debugger.PriorKind) {
        throw 'An absent prior Process Explorer Debugger value contains data.'
    }

    foreach ($propertyName in @('Changed', 'InstalledStart', 'PriorStart')) {
        if ($null -eq $State.Pcw.PSObject.Properties[$propertyName]) {
            throw "The Process Explorer pcw ownership state is missing '$propertyName'."
        }
    }
    if ($State.Pcw.Changed -isnot [bool] -or
        [int]$State.Pcw.InstalledStart -ne 4 -or
        [int]$State.Pcw.PriorStart -notin 0..4 -or
        ($State.Pcw.Changed -and [int]$State.Pcw.PriorStart -eq 4)) {
        throw 'The Process Explorer pcw ownership state is invalid.'
    }

    foreach ($propertyName in @(
            'Changed', 'InstalledSha256', 'PriorExists', 'PriorBytesBase64', 'PriorSha256'
        )) {
        if ($null -eq $State.Shortcut.PSObject.Properties[$propertyName]) {
            throw "The Process Explorer shortcut ownership state is missing '$propertyName'."
        }
    }
    if ($State.Shortcut.Changed -isnot [bool] -or -not $State.Shortcut.Changed -or
        $State.Shortcut.PriorExists -isnot [bool] -or
        [string]$State.Shortcut.InstalledSha256 -notmatch '^[0-9a-f]{64}$') {
        throw 'The Process Explorer shortcut ownership state is invalid.'
    }
    if ($State.Shortcut.PriorExists) {
        if ([string]$State.Shortcut.PriorBytesBase64 -eq '' -or
            [string]$State.Shortcut.PriorSha256 -notmatch '^[0-9a-f]{64}$') {
            throw 'The prior Process Explorer shortcut ownership state is invalid.'
        }
        try {
            $priorBytes = [Convert]::FromBase64String([string]$State.Shortcut.PriorBytesBase64)
        }
        catch {
            throw 'The prior Process Explorer shortcut ownership state is not valid Base64.'
        }
        if ($priorBytes.Length -gt 1048576) {
            throw 'The prior Process Explorer shortcut ownership state is too large.'
        }
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            $actualPriorHash = ([BitConverter]::ToString(
                    $sha256.ComputeHash($priorBytes)
                ) -replace '-', '').ToLowerInvariant()
        }
        finally {
            $sha256.Dispose()
        }
        if ($actualPriorHash -ne [string]$State.Shortcut.PriorSha256) {
            throw 'The prior Process Explorer shortcut ownership snapshot failed its hash check.'
        }
    }
    elseif ($null -ne $State.Shortcut.PriorBytesBase64 -or
        $null -ne $State.Shortcut.PriorSha256) {
        throw 'An absent prior Process Explorer shortcut contains data.'
    }

    if ($State.PSObject.TypeNames -notcontains $script:AtlasProcessExplorerStateType) {
        $State.PSObject.TypeNames.Insert(0, $script:AtlasProcessExplorerStateType)
    }
    return $State
}

function Read-AtlasProcessExplorerInstallState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [switch]$AllowMissing
    )

    $packageFullPath = [IO.Path]::GetFullPath($PackagePath).TrimEnd('\')
    $appsPath = [IO.Directory]::GetParent($packageFullPath).FullName
    if (-not [IO.Directory]::Exists($packageFullPath)) {
        if ($AllowMissing) { return $null }
        throw "The Process Explorer package is missing at '$packageFullPath'."
    }
    [void](Assert-AtlasProcessExplorerDirectory -Path $packageFullPath -AppsPath $appsPath)
    Assert-AtlasProcessExplorerParent -Path $packageFullPath

    $statePath = [IO.Path]::Combine($packageFullPath, $script:AtlasProcessExplorerStateFileName)
    Repair-AtlasProcessExplorerRecordBackup `
        -PrimaryPath $statePath `
        -MaximumBytes 2097152 `
        -RecordKind State `
        -SemanticPackagePath $packageFullPath
    if (-not [IO.File]::Exists($statePath)) {
        if ($AllowMissing) { return $null }
        throw 'The protected Process Explorer ownership state is missing; reinstall before uninstalling.'
    }
    $stateItem = Get-Item -LiteralPath $statePath -Force -ErrorAction Stop
    if (($stateItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $stateItem.Length -le 0 -or $stateItem.Length -gt 2097152) {
        throw 'The protected Process Explorer ownership state is not a bounded normal file.'
    }

    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    try {
        $json = $utf8.GetString([IO.File]::ReadAllBytes($stateItem.FullName))
        $state = $json | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "The protected Process Explorer ownership state is invalid: $($_.Exception.Message)"
    }
    return Assert-AtlasProcessExplorerInstallState -State $state -PackagePath $packageFullPath
}

function Write-AtlasProcessExplorerInstallState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [Parameter(Mandatory = $true)]
        [psobject]$State,

        [switch]$ReplaceExisting
    )

    $packageFullPath = [IO.Path]::GetFullPath($PackagePath).TrimEnd('\')
    $appsPath = [IO.Directory]::GetParent($packageFullPath).FullName
    [void](Assert-AtlasProcessExplorerDirectory -Path $packageFullPath -AppsPath $appsPath)
    Assert-AtlasProcessExplorerParent -Path $packageFullPath
    [void](Assert-AtlasProcessExplorerInstallState -State $State -PackagePath $packageFullPath)

    $statePath = [IO.Path]::Combine($packageFullPath, $script:AtlasProcessExplorerStateFileName)
    $stateExists = [IO.File]::Exists($statePath)
    if ($stateExists -and -not $ReplaceExisting) {
        throw 'The new Process Explorer package unexpectedly already contains ownership state.'
    }
    if (-not $stateExists -and $ReplaceExisting) {
        throw 'The Process Explorer ownership state disappeared before its progress update.'
    }
    $operationId = [guid]::NewGuid().ToString('N')
    $temporaryPath = "$statePath.new-$operationId"
    $backupPath = "$statePath.backup-$operationId"
    try {
        $json = $State | ConvertTo-Json -Depth 12 -Compress
        $utf8 = New-Object Text.UTF8Encoding($false, $true)
        $jsonBytes = $utf8.GetBytes($json)
        $expectedSha256 = Get-AtlasProcessExplorerBytesSha256 -Bytes $jsonBytes
        Write-AtlasProcessExplorerDurableFile `
            -Path $temporaryPath `
            -Bytes $jsonBytes
        $temporaryItem = Get-Item -LiteralPath $temporaryPath -Force -ErrorAction Stop
        if (($temporaryItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $temporaryItem.Length -le 0 -or $temporaryItem.Length -gt 2097152) {
            throw 'The staged Process Explorer ownership state is not a bounded normal file.'
        }
        if ($ReplaceExisting) {
            [IO.File]::Replace($temporaryPath, $statePath, $backupPath)
        }
        else {
            [IO.File]::Move($temporaryPath, $statePath)
        }
        try {
            Assert-AtlasProcessExplorerPersistedRecord `
                -Path $statePath `
                -MaximumBytes 2097152 `
                -RecordKind State `
                -SemanticPackagePath $packageFullPath `
                -ExpectedSha256 $expectedSha256
        }
        catch {
            $postconditionFailure = $_
            if ($ReplaceExisting -and [IO.File]::Exists($backupPath)) {
                try {
                    Restore-AtlasProcessExplorerRecordBackup `
                        -PrimaryPath $statePath `
                        -BackupPath $backupPath
                }
                catch {
                    throw "The Process Explorer ownership checkpoint failed verification and its previous record could not be restored: $($_.Exception.Message) Original verification failure: $($postconditionFailure.Exception.Message)"
                }
            }
            elseif (-not $ReplaceExisting -and [IO.File]::Exists($statePath)) {
                [IO.File]::Delete($statePath)
            }
            throw "The Process Explorer ownership checkpoint did not retain the intended record: $($postconditionFailure.Exception.Message)"
        }
        if ([IO.File]::Exists($backupPath)) {
            [IO.File]::Delete($backupPath)
        }
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}

function New-AtlasProcessExplorerPendingInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [Parameter(Mandatory = $true)]
        [psobject]$InstallState,

        [Parameter(Mandatory = $true)]
        [bool]$ImmediateDebuggerExists,

        [AllowNull()]
        [string]$ImmediateDebuggerValue,

        [AllowNull()]
        [string]$ImmediateDebuggerKind,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 4)]
        [int]$ImmediatePcwStart,

        [Parameter(Mandatory = $true)]
        [bool]$ImmediateShortcutExists,

        [AllowNull()]
        [byte[]]$ImmediateShortcutBytes,

        [Parameter(Mandatory = $true)]
        [bool]$ConfigurePcw
    )

    [void](Assert-AtlasProcessExplorerInstallState `
        -State $InstallState `
        -PackagePath $PackagePath)
    if ($ImmediateDebuggerExists) {
        if ($ImmediateDebuggerKind -notin @('String', 'ExpandString')) {
            throw 'The immediate Debugger snapshot has an unsupported kind.'
        }
        $canonicalImmediateDebuggerValue = $ImmediateDebuggerValue
        $canonicalImmediateDebuggerKind = $ImmediateDebuggerKind
    }
    else {
        if (-not [string]::IsNullOrEmpty($ImmediateDebuggerValue) -or
            -not [string]::IsNullOrEmpty($ImmediateDebuggerKind)) {
            throw 'An absent immediate Debugger snapshot cannot carry data.'
        }
        $canonicalImmediateDebuggerValue = $null
        $canonicalImmediateDebuggerKind = $null
    }
    if ($ImmediateShortcutExists -and $null -eq $ImmediateShortcutBytes) {
        throw 'The immediate shortcut snapshot is missing.'
    }
    if (-not $ImmediateShortcutExists -and $null -ne $ImmediateShortcutBytes) {
        throw 'An absent immediate shortcut snapshot cannot carry data.'
    }
    if ($null -ne $ImmediateShortcutBytes -and $ImmediateShortcutBytes.Length -gt 1048576) {
        throw 'The immediate shortcut snapshot exceeds its ownership bound.'
    }
    $immediateShortcutBase64 = $null
    $immediateShortcutSha256 = $null
    if ($ImmediateShortcutExists) {
        $immediateShortcutBase64 = [Convert]::ToBase64String($ImmediateShortcutBytes)
        $immediateShortcutSha256 = Get-AtlasProcessExplorerBytesSha256 `
            -Bytes $ImmediateShortcutBytes
    }

    return [pscustomobject]@{
        PSTypeName = 'Atlas.ProcessExplorer.PendingInstall'
        SchemaVersion = 1
        OperationId = [guid]::NewGuid().ToString('N')
        Phase = 'Prepared'
        PackageVersion = $script:AtlasProcessExplorerVersion
        Package = [pscustomobject]@{
            HadPreviousPackage = $false
            InstalledSha256 = ('0' * 64)
        }
        InstallState = $InstallState
        Immediate = [pscustomobject]@{
            Debugger = [pscustomobject]@{
                Exists = $ImmediateDebuggerExists
                Value = $canonicalImmediateDebuggerValue
                Kind = $canonicalImmediateDebuggerKind
            }
            PcwStart = $ImmediatePcwStart
            Shortcut = [pscustomobject]@{
                Exists = $ImmediateShortcutExists
                BytesBase64 = $immediateShortcutBase64
                Sha256 = $immediateShortcutSha256
            }
        }
        Desired = [pscustomobject]@{
            DebuggerValue = [IO.Path]::Combine(
                [IO.Path]::GetFullPath($PackagePath).TrimEnd('\'),
                'procexp.exe'
            )
            ShortcutSha256 = ('0' * 64)
            ConfigurePcw = $ConfigurePcw
            PcwStart = 4
        }
        Progress = [pscustomobject]@{
            PackagePublished = $false
            ShortcutApplied = $false
            DebuggerApplied = $false
            PcwApplied = $false
            OwnershipStateWritten = $false
        }
        RecoveryProgress = [pscustomobject]@{
            Pcw = $false
            Debugger = $false
            Shortcut = $false
        }
    }
}

function Assert-AtlasProcessExplorerPendingInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Pending,

        [Parameter(Mandatory = $true)]
        [string]$PackagePath
    )

    foreach ($propertyName in @(
            'SchemaVersion', 'OperationId', 'Phase', 'PackageVersion', 'Package',
            'InstallState', 'Immediate', 'Desired', 'Progress', 'RecoveryProgress'
        )) {
        if ($null -eq $Pending.PSObject.Properties[$propertyName]) {
            throw "The pending Process Explorer transaction is missing '$propertyName'."
        }
    }
    if ([int]$Pending.SchemaVersion -ne 1 -or
        [string]$Pending.OperationId -notmatch '^[0-9a-f]{32}$' -or
        [string]$Pending.Phase -notin @('Prepared', 'Published', 'ReadyToCommit', 'Committed') -or
        [string]$Pending.PackageVersion -notmatch '^\d{1,4}(?:\.\d{1,4}){1,3}$') {
        throw 'The pending Process Explorer transaction has an unsupported identity.'
    }
    if ($Pending.Package.HadPreviousPackage -isnot [bool] -or
        [string]$Pending.Package.InstalledSha256 -notmatch '^[0-9a-f]{64}$') {
        throw 'The pending Process Explorer package identity is invalid.'
    }
    [void](Assert-AtlasProcessExplorerInstallState `
        -State $Pending.InstallState `
        -PackagePath $PackagePath)

    if ($Pending.Immediate.Debugger.Exists -isnot [bool]) {
        throw 'The immediate Debugger transaction snapshot is invalid.'
    }
    if ($Pending.Immediate.Debugger.Exists) {
        if ($null -eq $Pending.Immediate.Debugger.Value -or
            [string]$Pending.Immediate.Debugger.Kind -notin @('String', 'ExpandString')) {
            throw 'The immediate Debugger transaction snapshot is incomplete.'
        }
    }
    elseif ($null -ne $Pending.Immediate.Debugger.Value -or
        $null -ne $Pending.Immediate.Debugger.Kind) {
        throw 'An absent immediate Debugger transaction snapshot contains data.'
    }
    if ([int]$Pending.Immediate.PcwStart -notin 0..4 -or
        $Pending.Immediate.Shortcut.Exists -isnot [bool]) {
        throw 'The immediate pcw or shortcut transaction snapshot is invalid.'
    }
    if ($Pending.Immediate.Shortcut.Exists) {
        if ([string]$Pending.Immediate.Shortcut.BytesBase64 -eq '' -or
            [string]$Pending.Immediate.Shortcut.Sha256 -notmatch '^[0-9a-f]{64}$') {
            throw 'The immediate shortcut transaction snapshot is incomplete.'
        }
        try {
            $immediateShortcutBytes = [Convert]::FromBase64String(
                [string]$Pending.Immediate.Shortcut.BytesBase64
            )
        }
        catch {
            throw 'The immediate shortcut transaction snapshot is invalid Base64.'
        }
        if ($immediateShortcutBytes.Length -gt 1048576 -or
            (Get-AtlasProcessExplorerBytesSha256 -Bytes $immediateShortcutBytes) -ne
                [string]$Pending.Immediate.Shortcut.Sha256) {
            throw 'The immediate shortcut transaction snapshot failed its hash or size check.'
        }
    }
    elseif ($null -ne $Pending.Immediate.Shortcut.BytesBase64 -or
        $null -ne $Pending.Immediate.Shortcut.Sha256) {
        throw 'An absent immediate shortcut transaction snapshot contains data.'
    }

    $expectedDebugger = [IO.Path]::Combine(
        [IO.Path]::GetFullPath($PackagePath).TrimEnd('\'),
        'procexp.exe'
    )
    if (-not ([string]$Pending.Desired.DebuggerValue).Equals(
            $expectedDebugger,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$Pending.Desired.ShortcutSha256 -notmatch '^[0-9a-f]{64}$' -or
        $Pending.Desired.ConfigurePcw -isnot [bool] -or
        [int]$Pending.Desired.PcwStart -ne 4) {
        throw 'The desired pending Process Explorer state is invalid.'
    }
    foreach ($propertyName in @(
            'PackagePublished', 'ShortcutApplied', 'DebuggerApplied', 'PcwApplied',
            'OwnershipStateWritten'
        )) {
        if ($Pending.Progress.$propertyName -isnot [bool]) {
            throw "The pending Process Explorer progress '$propertyName' is invalid."
        }
    }
    foreach ($propertyName in @('Pcw', 'Debugger', 'Shortcut')) {
        if ($Pending.RecoveryProgress.$propertyName -isnot [bool]) {
            throw "The pending Process Explorer recovery progress '$propertyName' is invalid."
        }
    }
    if ($Pending.PSObject.TypeNames -notcontains 'Atlas.ProcessExplorer.PendingInstall') {
        $Pending.PSObject.TypeNames.Insert(0, 'Atlas.ProcessExplorer.PendingInstall')
    }
    return $Pending
}

function Read-AtlasProcessExplorerPendingInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [string]$CanonicalPackagePath,

        [switch]$AllowMissing
    )

    $packageFullPath = [IO.Path]::GetFullPath($PackagePath).TrimEnd('\')
    if ([string]::IsNullOrWhiteSpace($CanonicalPackagePath)) {
        $CanonicalPackagePath = $packageFullPath
    }
    if (-not [IO.Directory]::Exists($packageFullPath)) {
        if ($AllowMissing) { return $null }
        throw "The Process Explorer package is missing at '$packageFullPath'."
    }
    $appsPath = [IO.Directory]::GetParent($packageFullPath).FullName
    [void](Assert-AtlasProcessExplorerDirectory -Path $packageFullPath -AppsPath $appsPath)
    $pendingPath = [IO.Path]::Combine($packageFullPath, $script:AtlasProcessExplorerPendingFileName)
    Repair-AtlasProcessExplorerRecordBackup `
        -PrimaryPath $pendingPath `
        -MaximumBytes 4194304 `
        -RecordKind Pending `
        -SemanticPackagePath $CanonicalPackagePath
    if (-not [IO.File]::Exists($pendingPath)) {
        if ($AllowMissing) { return $null }
        throw 'The pending Process Explorer transaction record is missing.'
    }
    $pendingItem = Get-Item -LiteralPath $pendingPath -Force -ErrorAction Stop
    if (($pendingItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $pendingItem.Length -le 0 -or $pendingItem.Length -gt 4194304) {
        throw 'The pending Process Explorer transaction is not a bounded normal file.'
    }
    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    try {
        $pending = $utf8.GetString([IO.File]::ReadAllBytes($pendingItem.FullName)) |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "The pending Process Explorer transaction is invalid: $($_.Exception.Message)"
    }
    return Assert-AtlasProcessExplorerPendingInstall `
        -Pending $pending `
        -PackagePath $CanonicalPackagePath
}

function Write-AtlasProcessExplorerPendingInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [Parameter(Mandatory = $true)]
        [psobject]$Pending,

        [string]$CanonicalPackagePath,

        [switch]$ReplaceExisting
    )

    $packageFullPath = [IO.Path]::GetFullPath($PackagePath).TrimEnd('\')
    if ([string]::IsNullOrWhiteSpace($CanonicalPackagePath)) {
        $CanonicalPackagePath = $packageFullPath
    }
    $appsPath = [IO.Directory]::GetParent($packageFullPath).FullName
    [void](Assert-AtlasProcessExplorerDirectory -Path $packageFullPath -AppsPath $appsPath)
    [void](Assert-AtlasProcessExplorerPendingInstall `
        -Pending $Pending `
        -PackagePath $CanonicalPackagePath)
    $pendingPath = [IO.Path]::Combine($packageFullPath, $script:AtlasProcessExplorerPendingFileName)
    $pendingExists = [IO.File]::Exists($pendingPath)
    if ($pendingExists -and -not $ReplaceExisting) {
        throw 'The Process Explorer candidate unexpectedly already contains a pending transaction.'
    }
    if (-not $pendingExists -and $ReplaceExisting) {
        throw 'The pending Process Explorer transaction disappeared before its checkpoint.'
    }
    $operationId = [guid]::NewGuid().ToString('N')
    $temporaryPath = "$pendingPath.new-$operationId"
    $backupPath = "$pendingPath.backup-$operationId"
    try {
        $json = $Pending | ConvertTo-Json -Depth 12 -Compress
        $utf8 = New-Object Text.UTF8Encoding($false, $true)
        $jsonBytes = $utf8.GetBytes($json)
        $expectedSha256 = Get-AtlasProcessExplorerBytesSha256 -Bytes $jsonBytes
        Write-AtlasProcessExplorerDurableFile `
            -Path $temporaryPath `
            -Bytes $jsonBytes
        if ($ReplaceExisting) {
            [IO.File]::Replace($temporaryPath, $pendingPath, $backupPath)
        }
        else {
            [IO.File]::Move($temporaryPath, $pendingPath)
        }
        try {
            Assert-AtlasProcessExplorerPersistedRecord `
                -Path $pendingPath `
                -MaximumBytes 4194304 `
                -RecordKind Pending `
                -SemanticPackagePath $CanonicalPackagePath `
                -ExpectedSha256 $expectedSha256
        }
        catch {
            $postconditionFailure = $_
            if ($ReplaceExisting -and [IO.File]::Exists($backupPath)) {
                try {
                    Restore-AtlasProcessExplorerRecordBackup `
                        -PrimaryPath $pendingPath `
                        -BackupPath $backupPath
                }
                catch {
                    throw "The pending Process Explorer checkpoint failed verification and its previous record could not be restored: $($_.Exception.Message) Original verification failure: $($postconditionFailure.Exception.Message)"
                }
            }
            elseif (-not $ReplaceExisting -and [IO.File]::Exists($pendingPath)) {
                [IO.File]::Delete($pendingPath)
            }
            throw "The pending Process Explorer checkpoint did not retain the intended record: $($postconditionFailure.Exception.Message)"
        }
        if ([IO.File]::Exists($backupPath)) {
            [IO.File]::Delete($backupPath)
        }
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}

function New-AtlasProcessExplorerPackageTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$OperationId,

        [Parameter(Mandatory = $true)]
        [string]$AppsPath,

        [Parameter(Mandatory = $true)]
        [bool]$HadPreviousPackage,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{64}$')]
        [string]$InstalledSha256
    )

    $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
    return [pscustomobject]@{
        PSTypeName = $script:AtlasProcessExplorerTransactionType
        OperationId = $OperationId
        AppsPath = $appsFullPath
        PackagePath = [IO.Path]::Combine($appsFullPath, 'ProcessExplorer')
        CandidatePath = [IO.Path]::Combine($appsFullPath, "ProcessExplorer.new-$OperationId")
        BackupPath = [IO.Path]::Combine($appsFullPath, "ProcessExplorer.old-$OperationId")
        HadPreviousPackage = $HadPreviousPackage
        InstalledSha256 = $InstalledSha256.ToLowerInvariant()
        State = 'Published'
        PendingInstall = $null
        OperationLock = $null
    }
}

function Assert-AtlasProcessExplorerPackageTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Transaction,

        [string[]]$AllowedState = @('Published')
    )

    if ($Transaction.PSObject.TypeNames -notcontains $script:AtlasProcessExplorerTransactionType) {
        throw 'The Process Explorer package transaction has an unexpected type.'
    }
    if ([string]$Transaction.OperationId -notmatch '^[0-9a-f]{32}$' -or
        $Transaction.HadPreviousPackage -isnot [bool] -or
        [string]$Transaction.InstalledSha256 -notmatch '^[0-9a-f]{64}$' -or
        [string]$Transaction.State -notin $AllowedState) {
        throw 'The Process Explorer package transaction is malformed or no longer active.'
    }

    $appsPath = [IO.Path]::GetFullPath([string]$Transaction.AppsPath).TrimEnd('\')
    $expectedPackage = [IO.Path]::Combine($appsPath, 'ProcessExplorer')
    $expectedCandidate = [IO.Path]::Combine(
        $appsPath,
        "ProcessExplorer.new-$($Transaction.OperationId)"
    )
    $expectedBackup = [IO.Path]::Combine(
        $appsPath,
        "ProcessExplorer.old-$($Transaction.OperationId)"
    )
    if (-not [IO.Path]::GetFullPath([string]$Transaction.PackagePath).Equals(
            $expectedPackage,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        -not [IO.Path]::GetFullPath([string]$Transaction.CandidatePath).Equals(
            $expectedCandidate,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        -not [IO.Path]::GetFullPath([string]$Transaction.BackupPath).Equals(
            $expectedBackup,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The Process Explorer package transaction paths are not canonical siblings.'
    }
    Assert-AtlasProcessExplorerParent -Path $appsPath
    return $Transaction
}

function Read-AtlasProcessExplorerUninstallJournal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppsPath,

        [switch]$AllowMissing
    )

    $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
    Assert-AtlasProcessExplorerParent -Path $appsFullPath
    $journalPath = [IO.Path]::Combine(
        $appsFullPath,
        $script:AtlasProcessExplorerUninstallJournalName
    )
    if (-not [IO.File]::Exists($journalPath)) {
        if ($AllowMissing) { return $null }
        throw 'The Process Explorer uninstall journal is missing.'
    }
    $item = Get-Item -LiteralPath $journalPath -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $item.Length -le 0 -or $item.Length -gt 65536 -or
        -not (Test-AtlasProcessExplorerProtectedAcl `
            -Acl (Get-Acl -LiteralPath $item.FullName -ErrorAction Stop))) {
        throw 'The Process Explorer uninstall journal is not a protected bounded file.'
    }
    $utf8 = New-Object Text.UTF8Encoding($false, $true)
    try {
        $journal = $utf8.GetString([IO.File]::ReadAllBytes($item.FullName)) |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "The Process Explorer uninstall journal is invalid: $($_.Exception.Message)"
    }
    if ([int]$journal.SchemaVersion -ne 1 -or
        [string]$journal.OperationId -notmatch '^[0-9a-f]{32}$' -or
        [string]$journal.SourceName -notmatch '^ProcessExplorer(?:\.new-[0-9a-f]{32})?$' -or
        [string]$journal.TombstoneName -ne "ProcessExplorer.remove-$($journal.OperationId)") {
        throw 'The Process Explorer uninstall journal has an unsupported identity.'
    }
    return $journal
}

function Write-AtlasProcessExplorerUninstallJournal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppsPath,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-f]{32}$')]
        [string]$OperationId,

        [ValidatePattern('^ProcessExplorer(?:\.new-[0-9a-f]{32})?$')]
        [string]$SourceName = 'ProcessExplorer'
    )

    $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
    Assert-AtlasProcessExplorerParent -Path $appsFullPath
    $journalPath = [IO.Path]::Combine(
        $appsFullPath,
        $script:AtlasProcessExplorerUninstallJournalName
    )
    if ([IO.File]::Exists($journalPath)) {
        throw 'A Process Explorer uninstall journal is already active.'
    }
    $temporaryPath = "$journalPath.new-$([guid]::NewGuid().ToString('N'))"
    $stream = $null
    try {
        $journal = [pscustomobject]@{
            SchemaVersion = 1
            OperationId = $OperationId
            SourceName = $SourceName
            TombstoneName = "ProcessExplorer.remove-$OperationId"
        }
        $utf8 = New-Object Text.UTF8Encoding($false, $true)
        $bytes = $utf8.GetBytes(($journal | ConvertTo-Json -Compress))
        $stream = New-Object IO.FileStream(
            $temporaryPath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null
        [IO.File]::Move($temporaryPath, $journalPath)
        [void](Read-AtlasProcessExplorerUninstallJournal -AppsPath $appsFullPath)
    }
    finally {
        if ($null -ne $stream) { $stream.Dispose() }
        if ([IO.File]::Exists($temporaryPath)) { [IO.File]::Delete($temporaryPath) }
    }
}

function Repair-AtlasProcessExplorerUninstallTombstone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$OperationLock,

        [string]$AppsPath
    )

    if ([string]::IsNullOrWhiteSpace($AppsPath)) {
        $layout = Get-AtlasProcessExplorerLayout
    }
    else {
        $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
        $layout = [pscustomobject]@{
            AppsPath = $appsFullPath
            PackagePath = [IO.Path]::Combine($appsFullPath, 'ProcessExplorer')
        }
    }
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $OperationLock `
        -AppsPath $layout.AppsPath
    foreach ($orphan in @(Get-ChildItem -LiteralPath $layout.AppsPath `
            -Filter 'Atlas.ProcessExplorer.Uninstall.json.new-*' -Force -ErrorAction Stop)) {
        if ($orphan.PSIsContainer -or
            $orphan.Name -notmatch '^Atlas\.ProcessExplorer\.Uninstall\.json\.new-[0-9a-f]{32}$' -or
            ($orphan.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $orphan.Length -gt 65536 -or
            -not (Test-AtlasProcessExplorerProtectedAcl `
                -Acl (Get-Acl -LiteralPath $orphan.FullName -ErrorAction Stop))) {
            throw 'An orphan Process Explorer uninstall journal temp is unsafe.'
        }
        Remove-Item -LiteralPath $orphan.FullName -Force -ErrorAction Stop
    }

    $journal = Read-AtlasProcessExplorerUninstallJournal `
        -AppsPath $layout.AppsPath `
        -AllowMissing
    $tombstones = @(Get-ChildItem -LiteralPath $layout.AppsPath `
        -Directory -Force -ErrorAction Stop | Where-Object {
            $_.Name -match '^ProcessExplorer\.remove-[0-9a-f]{32}$'
        })
    if ($null -eq $journal) {
        if ($tombstones.Count -ne 0) {
            throw 'A Process Explorer removal tombstone exists without its protected journal.'
        }
        return
    }
    $foreignTombstones = @($tombstones | Where-Object {
            $_.Name -ne [string]$journal.TombstoneName
        })
    if ($foreignTombstones.Count -ne 0) {
        throw 'The Process Explorer removal journal has foreign protected tombstones.'
    }
    $tombstonePath = [IO.Path]::Combine($layout.AppsPath, [string]$journal.TombstoneName)
    $sourcePath = [IO.Path]::Combine($layout.AppsPath, [string]$journal.SourceName)
    $sourceExists = [IO.Directory]::Exists($sourcePath)
    $tombstoneExists = [IO.Directory]::Exists($tombstonePath)
    if ($sourceExists -and $tombstoneExists) {
        throw 'The Process Explorer removal journal has both source and tombstone generations.'
    }
    if ($sourceExists) {
        [void](Assert-AtlasProcessExplorerDirectory `
            -Path $sourcePath `
            -AppsPath $layout.AppsPath)
        [IO.Directory]::Move($sourcePath, $tombstonePath)
        $tombstoneExists = $true
    }
    if ($tombstoneExists) {
        Remove-AtlasProcessExplorerDirectory `
            -Path $tombstonePath `
            -AppsPath $layout.AppsPath
    }
    $journalPath = [IO.Path]::Combine(
        $layout.AppsPath,
        $script:AtlasProcessExplorerUninstallJournalName
    )
    Remove-Item -LiteralPath $journalPath -Force -ErrorAction Stop
}

function Repair-AtlasProcessExplorerPackageGenerations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$OperationLock,

        [string]$AppsPath
    )

    if ([string]::IsNullOrWhiteSpace($AppsPath)) {
        $layout = Get-AtlasProcessExplorerLayout
    }
    else {
        $appsFullPath = [IO.Path]::GetFullPath($AppsPath).TrimEnd('\')
        $layout = [pscustomobject]@{
            AppsPath = $appsFullPath
            PackagePath = [IO.Path]::Combine($appsFullPath, 'ProcessExplorer')
        }
    }
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $OperationLock `
        -AppsPath $layout.AppsPath
    Assert-AtlasProcessExplorerParent -Path $layout.AppsPath
    Repair-AtlasProcessExplorerUninstallTombstone `
        -OperationLock $OperationLock `
        -AppsPath $layout.AppsPath

    $candidateDirectories = @(Get-ChildItem -LiteralPath $layout.AppsPath `
        -Directory -Force -ErrorAction Stop | Where-Object {
            $_.Name -match '^ProcessExplorer\.new-[0-9a-f]{32}$'
        })
    $backupDirectories = @(Get-ChildItem -LiteralPath $layout.AppsPath `
        -Directory -Force -ErrorAction Stop | Where-Object {
            $_.Name -match '^ProcessExplorer\.old-[0-9a-f]{32}$'
        })
    if ($candidateDirectories.Count -gt 1) {
        throw 'Multiple pending Process Explorer candidate generations require manual recovery.'
    }
    if ($candidateDirectories.Count -eq 1) {
        $candidate = $candidateDirectories[0]
        [void](Assert-AtlasProcessExplorerDirectory `
            -Path $candidate.FullName `
            -AppsPath $layout.AppsPath)
        $candidateOperationId = $candidate.Name.Substring('ProcessExplorer.new-'.Length)
        $candidatePendingPath = [IO.Path]::Combine(
            $candidate.FullName,
            $script:AtlasProcessExplorerPendingFileName
        )
        if (-not [IO.File]::Exists($candidatePendingPath)) {
        $backupPath = [IO.Path]::Combine(
            $layout.AppsPath,
            "ProcessExplorer.old-$candidateOperationId"
        )
        $foreignBackups = @($backupDirectories | Where-Object {
                -not $_.FullName.Equals($backupPath, [StringComparison]::OrdinalIgnoreCase)
            })
        if ($foreignBackups.Count -ne 0) {
            throw 'The Process Explorer candidate has foreign protected backup generations.'
        }
            $canonicalExists = [IO.Directory]::Exists($layout.PackagePath)
            $backupExists = [IO.Directory]::Exists($backupPath)
            if ($canonicalExists -and $backupExists) {
                throw 'A pre-record Process Explorer candidate has ambiguous canonical and backup generations.'
            }
            if (-not $canonicalExists -and $backupExists) {
                [void](Assert-AtlasProcessExplorerDirectory `
                    -Path $backupPath `
                    -AppsPath $layout.AppsPath)
                [IO.Directory]::Move($backupPath, $layout.PackagePath)
            }
            Remove-AtlasProcessExplorerDirectory `
                -Path $candidate.FullName `
                -AppsPath $layout.AppsPath
            return Repair-AtlasProcessExplorerPackageGenerations `
                -OperationLock $OperationLock `
                -AppsPath $layout.AppsPath
        }
        $pending = Read-AtlasProcessExplorerPendingInstall `
            -PackagePath $candidate.FullName `
            -CanonicalPackagePath $layout.PackagePath
        if ($candidate.Name -ne "ProcessExplorer.new-$($pending.OperationId)") {
            throw 'The pending Process Explorer candidate generation has an inconsistent operation ID.'
        }
        $preparedCandidate = [string]$pending.Phase -eq 'Prepared' -and
            -not [bool]$pending.Progress.PackagePublished
        $rollbackCandidate = [bool]$pending.RecoveryProgress.Pcw -and
            [bool]$pending.RecoveryProgress.Debugger -and
            [bool]$pending.RecoveryProgress.Shortcut
        if (-not $preparedCandidate -and -not $rollbackCandidate) {
            throw 'The pending Process Explorer candidate generation has inconsistent progress.'
        }
        $backupPath = [IO.Path]::Combine(
            $layout.AppsPath,
            "ProcessExplorer.old-$($pending.OperationId)"
        )
        if (@($backupDirectories | Where-Object {
                    -not $_.FullName.Equals($backupPath, [StringComparison]::OrdinalIgnoreCase)
                }).Count -ne 0) {
            throw 'The pending Process Explorer candidate has foreign protected backup generations.'
        }
        if ($preparedCandidate) {
            if ([IO.Directory]::Exists($layout.PackagePath)) {
                if ([IO.Directory]::Exists($backupPath)) {
                    throw 'A pre-publish Process Explorer candidate unexpectedly has both canonical and backup generations.'
                }
            }
            elseif ($pending.Package.HadPreviousPackage) {
                if (-not [IO.Directory]::Exists($backupPath)) {
                    throw 'The previous Process Explorer generation is missing during pre-publish recovery.'
                }
                [void](Assert-AtlasProcessExplorerDirectory `
                    -Path $backupPath `
                    -AppsPath $layout.AppsPath)
                [IO.Directory]::Move($backupPath, $layout.PackagePath)
            }
        }
        elseif ($pending.Package.HadPreviousPackage -and
            -not [IO.Directory]::Exists($layout.PackagePath)) {
            if (-not [IO.Directory]::Exists($backupPath)) {
                throw 'The previous Process Explorer generation is missing during rollback recovery.'
            }
            [void](Assert-AtlasProcessExplorerDirectory `
                -Path $backupPath `
                -AppsPath $layout.AppsPath)
            [IO.Directory]::Move($backupPath, $layout.PackagePath)
        }
        elseif ($rollbackCandidate -and [IO.Directory]::Exists($backupPath)) {
            throw 'The rolled-back Process Explorer candidate still has an ambiguous backup generation.'
        }
        elseif ($rollbackCandidate -and
            -not $pending.Package.HadPreviousPackage -and
            [IO.Directory]::Exists($layout.PackagePath)) {
            throw 'A new-only Process Explorer rollback has both candidate and canonical generations.'
        }
        if ($rollbackCandidate) {
            $cleanupTransaction = New-AtlasProcessExplorerPackageTransaction `
                -OperationId ([string]$pending.OperationId) `
                -AppsPath $layout.AppsPath `
                -HadPreviousPackage ([bool]$pending.Package.HadPreviousPackage) `
                -InstalledSha256 ([string]$pending.Package.InstalledSha256)
            $cleanupTransaction.OperationLock = $OperationLock
            Start-AtlasProcessExplorerCandidateCleanup -Transaction $cleanupTransaction
            $cleanupJournalPath = [IO.Path]::Combine(
                $layout.AppsPath,
                $script:AtlasProcessExplorerUninstallJournalName
            )
            if ([IO.File]::Exists($cleanupJournalPath)) {
                throw 'The rolled-back Process Explorer candidate cleanup remains journaled.'
            }
        }
        else {
            Remove-AtlasProcessExplorerDirectory `
                -Path $candidate.FullName `
                -AppsPath $layout.AppsPath
        }
    }

    if (-not [IO.Directory]::Exists($layout.PackagePath)) {
        $orphanBackups = @(Get-ChildItem -LiteralPath $layout.AppsPath `
            -Directory -Force -ErrorAction Stop | Where-Object {
                $_.Name -match '^ProcessExplorer\.old-[0-9a-f]{32}$'
            })
        if ($orphanBackups.Count -ne 0) {
            throw 'A protected Process Explorer backup exists without a canonical transaction record.'
        }
        return $null
    }

    [void](Assert-AtlasProcessExplorerDirectory `
        -Path $layout.PackagePath `
        -AppsPath $layout.AppsPath)
    $pending = Read-AtlasProcessExplorerPendingInstall `
        -PackagePath $layout.PackagePath `
        -AllowMissing
    if ($null -eq $pending) {
        $orphanBackups = @(Get-ChildItem -LiteralPath $layout.AppsPath `
            -Directory -Force -ErrorAction Stop | Where-Object {
                $_.Name -match '^ProcessExplorer\.old-[0-9a-f]{32}$'
            })
        if ($orphanBackups.Count -ne 0) {
            throw 'A protected Process Explorer backup exists without a matching pending record.'
        }
        return $null
    }

    $transaction = New-AtlasProcessExplorerPackageTransaction `
        -OperationId ([string]$pending.OperationId) `
        -AppsPath $layout.AppsPath `
        -HadPreviousPackage ([bool]$pending.Package.HadPreviousPackage) `
        -InstalledSha256 ([string]$pending.Package.InstalledSha256)
    $transaction.PendingInstall = $pending
    $transaction.OperationLock = $OperationLock
    $expectedBackup = $transaction.BackupPath
    $backupDirectories = @(Get-ChildItem -LiteralPath $layout.AppsPath `
        -Directory -Force -ErrorAction Stop | Where-Object {
            $_.Name -match '^ProcessExplorer\.old-[0-9a-f]{32}$'
        })
    $foreignBackups = @($backupDirectories | Where-Object {
            -not $_.FullName.Equals($expectedBackup, [StringComparison]::OrdinalIgnoreCase)
        })
    if ($foreignBackups.Count -ne 0 -or
        (-not $transaction.HadPreviousPackage -and $backupDirectories.Count -ne 0)) {
        throw 'The pending Process Explorer transaction has foreign protected backup generations.'
    }
    if ($transaction.HadPreviousPackage -and
        [string]$pending.Phase -ne 'Committed' -and
        -not [IO.Directory]::Exists($expectedBackup)) {
        throw 'The pending Process Explorer transaction lost its protected backup generation.'
    }
    if ([IO.Directory]::Exists($expectedBackup)) {
        [void](Assert-AtlasProcessExplorerDirectory `
            -Path $expectedBackup `
            -AppsPath $layout.AppsPath)
    }
    return [pscustomobject]@{
        PSTypeName = 'Atlas.ProcessExplorer.RecoveryContext'
        Pending = $pending
        Transaction = $transaction
    }
}

function Complete-AtlasProcessExplorerPackageInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Transaction
    )

    [void](Assert-AtlasProcessExplorerPackageTransaction -Transaction $Transaction)
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $Transaction.OperationLock `
        -AppsPath $Transaction.AppsPath
    [void](Assert-AtlasProcessExplorerDirectory `
        -Path $Transaction.PackagePath `
        -AppsPath $Transaction.AppsPath)
    $installedPath = [IO.Path]::Combine($Transaction.PackagePath, 'procexp.exe')
    if (-not [IO.File]::Exists($installedPath) -or
        (Get-AtlasProcessExplorerFileSha256 -Path $installedPath) -ne $Transaction.InstalledSha256) {
        throw 'The Process Explorer package changed before its transaction could commit.'
    }
    $pending = Read-AtlasProcessExplorerPendingInstall `
        -PackagePath $Transaction.PackagePath
    if ([string]$pending.OperationId -ne [string]$Transaction.OperationId -or
        [string]$pending.Phase -notin @('ReadyToCommit', 'Committed') -or
        -not [bool]$pending.Progress.OwnershipStateWritten) {
        throw 'The pending Process Explorer transaction is not ready for outer commit.'
    }
    if ($Transaction.HadPreviousPackage -and
        [string]$pending.Phase -ne 'Committed' -and
        -not [IO.Directory]::Exists($Transaction.BackupPath)) {
        throw 'The previous Process Explorer package is missing before transaction commit.'
    }
    $installState = Read-AtlasProcessExplorerInstallState `
        -PackagePath $Transaction.PackagePath
    if ([string]$installState.InstallId -ne [string]$pending.InstallState.InstallId -or
        [string]$installState.Shortcut.InstalledSha256 -ne
            [string]$pending.Desired.ShortcutSha256) {
        throw 'The committed Process Explorer ownership state does not match its pending transaction.'
    }

    # This assignment is the outer commit boundary. Once it is crossed, the new
    # package and all dependent state are authoritative. Cleanup failure leaves
    # the protected backup in place and must not unwind the committed state.
    if ([string]$pending.Phase -ne 'Committed') {
        $pending.Phase = 'Committed'
        Write-AtlasProcessExplorerPendingInstall `
            -PackagePath $Transaction.PackagePath `
            -Pending $pending `
            -ReplaceExisting
    }
    $Transaction.State = 'Committed'
    if ($Transaction.HadPreviousPackage -and [IO.Directory]::Exists($Transaction.BackupPath)) {
        Remove-AtlasProcessExplorerDirectory `
            -Path $Transaction.BackupPath `
            -AppsPath $Transaction.AppsPath
    }
    if ([IO.Directory]::Exists($Transaction.BackupPath)) {
        throw 'The committed Process Explorer backup generation is still pending cleanup.'
    }
    $templatePath = [IO.Path]::Combine(
        $Transaction.PackagePath,
        $script:AtlasProcessExplorerShortcutTemplateName
    )
    if ([IO.File]::Exists($templatePath)) {
        Remove-Item -LiteralPath $templatePath -Force -ErrorAction Stop
    }
    $pendingPath = [IO.Path]::Combine(
        $Transaction.PackagePath,
        $script:AtlasProcessExplorerPendingFileName
    )
    Remove-Item -LiteralPath $pendingPath -Force -ErrorAction Stop
}

function Start-AtlasProcessExplorerCandidateCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Transaction
    )

    if (-not [IO.Directory]::Exists($Transaction.CandidatePath)) { return }
    $cleanupId = [guid]::NewGuid().ToString('N')
    Write-AtlasProcessExplorerUninstallJournal `
        -AppsPath $Transaction.AppsPath `
        -OperationId $cleanupId `
        -SourceName ([IO.Path]::GetFileName($Transaction.CandidatePath))
    try {
        Repair-AtlasProcessExplorerUninstallTombstone `
            -OperationLock $Transaction.OperationLock `
            -AppsPath $Transaction.AppsPath
    }
    catch {
        Write-Warning "The rolled-back Process Explorer candidate cleanup is journaled for retry: $($_.Exception.Message)"
    }
}

function Undo-AtlasProcessExplorerPackageInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Transaction
    )

    [void](Assert-AtlasProcessExplorerPackageTransaction -Transaction $Transaction)
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $Transaction.OperationLock `
        -AppsPath $Transaction.AppsPath
    if ([IO.Directory]::Exists($Transaction.PackagePath)) {
        [void](Assert-AtlasProcessExplorerDirectory `
            -Path $Transaction.PackagePath `
            -AppsPath $Transaction.AppsPath)
        Stop-AtlasProcessExplorerPackageProcesses -PackagePath $Transaction.PackagePath
    }

    if ($Transaction.HadPreviousPackage) {
        if (-not [IO.Directory]::Exists($Transaction.BackupPath)) {
            throw 'The previous Process Explorer package is unavailable for rollback.'
        }
        [void](Assert-AtlasProcessExplorerDirectory `
            -Path $Transaction.BackupPath `
            -AppsPath $Transaction.AppsPath)
        if ([IO.Directory]::Exists($Transaction.CandidatePath)) {
            throw 'The Process Explorer rollback holding path is unexpectedly occupied.'
        }

        $currentMoved = $false
        try {
            if ([IO.Directory]::Exists($Transaction.PackagePath)) {
                [IO.Directory]::Move($Transaction.PackagePath, $Transaction.CandidatePath)
                $currentMoved = $true
            }
            [IO.Directory]::Move($Transaction.BackupPath, $Transaction.PackagePath)
            $Transaction.State = 'RolledBack'
        }
        catch {
            $rollbackError = $_
            if ($currentMoved -and
                -not [IO.Directory]::Exists($Transaction.PackagePath) -and
                [IO.Directory]::Exists($Transaction.CandidatePath)) {
                try {
                    [IO.Directory]::Move($Transaction.CandidatePath, $Transaction.PackagePath)
                }
                catch {
                    throw "Process Explorer rollback failed and the new package could not be republished: $($rollbackError.Exception.Message); $($_.Exception.Message)"
                }
            }
            throw $rollbackError
        }

        Start-AtlasProcessExplorerCandidateCleanup -Transaction $Transaction
        return
    }

    if ([IO.Directory]::Exists($Transaction.PackagePath)) {
        if ([IO.Directory]::Exists($Transaction.CandidatePath)) {
            throw 'The Process Explorer rollback holding path is unexpectedly occupied.'
        }
        [IO.Directory]::Move($Transaction.PackagePath, $Transaction.CandidatePath)
    }
    $Transaction.State = 'RolledBack'
    Start-AtlasProcessExplorerCandidateCleanup -Transaction $Transaction
}

function Invoke-AtlasProcessExplorerRestorePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$State,

        [Parameter(Mandatory = $true)]
        [object[]]$Steps,

        [Parameter(Mandatory = $true)]
        [scriptblock]$PersistState,

        [ValidateSet('RestoreProgress', 'RecoveryProgress')]
        [string]$ProgressPropertyName = 'RestoreProgress'
    )

    $failures = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($step in $Steps) {
        if ($null -eq $step.PSObject.Properties['Name'] -or
            [string]$step.Name -notin @('Debugger', 'Shortcut', 'Pcw') -or
            $seen.ContainsKey([string]$step.Name) -or
            $null -eq $step.PSObject.Properties['Action'] -or
            $step.Action -isnot [scriptblock]) {
            $failures.Add('restore plan: malformed or duplicate dependent step')
            break
        }
        $name = [string]$step.Name
        $seen[$name] = $true
        try {
            $progress = $State.$ProgressPropertyName
            if ([bool]$progress.$name) {
                if ($null -ne $step.PSObject.Properties['VerifyCompleted'] -and
                    $null -ne $step.VerifyCompleted) {
                    if ($step.VerifyCompleted -isnot [scriptblock]) {
                        throw 'the completed-step verifier is malformed'
                    }
                    & $step.VerifyCompleted
                }
                continue
            }

            & $step.Action
            $progress.$name = $true
            & $PersistState $State
        }
        catch {
            $failures.Add("${name}: $($_.Exception.Message)")
            break
        }
    }

    $allComplete = $true
    $progress = $State.$ProgressPropertyName
    foreach ($name in @('Debugger', 'Shortcut', 'Pcw')) {
        if (-not [bool]$progress.$name) {
            $allComplete = $false
        }
    }
    return [pscustomobject]@{
        PSTypeName = 'Atlas.ProcessExplorer.RestoreResult'
        Failures = [string[]]$failures.ToArray()
        AllComplete = $allComplete
    }
}

function Resolve-AtlasProcessExplorerPendingTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RecoveryContext,

        [Parameter(Mandatory = $true)]
        [psobject]$OperationLock,

        [Parameter(Mandatory = $true)]
        [string]$WinDir
    )

    if ($RecoveryContext.PSObject.TypeNames -notcontains 'Atlas.ProcessExplorer.RecoveryContext') {
        throw 'The Process Explorer recovery context has an unexpected type.'
    }
    $pending = $RecoveryContext.Pending
    $transaction = $RecoveryContext.Transaction
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $OperationLock `
        -AppsPath $transaction.AppsPath
    [void](Assert-AtlasProcessExplorerPendingInstall `
        -Pending $pending `
        -PackagePath $transaction.PackagePath)

    $shortcut = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) `
        'Programs\Process Explorer.lnk'
    $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
    $pcwPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\pcw'

    $readyPhase = [string]$pending.Phase -in @('ReadyToCommit', 'Committed')
    if ($readyPhase) {
        $shortcutTargetExists = $true
        $shortcutTargetHash = [string]$pending.Desired.ShortcutSha256
        $shortcutAlternateHash = if ($pending.Immediate.Shortcut.Exists) {
            [string]$pending.Immediate.Shortcut.Sha256
        }
        else { $null }
    }
    else {
        $shortcutTargetExists = [bool]$pending.Immediate.Shortcut.Exists
        $shortcutTargetHash = if ($shortcutTargetExists) {
            [string]$pending.Immediate.Shortcut.Sha256
        }
        else { $null }
        $shortcutAlternateHash = [string]$pending.Desired.ShortcutSha256
    }
    $shortcutArtifactParameters = @{
        Path = $shortcut
        ArtifactId = [string]$pending.OperationId
        TargetExists = $shortcutTargetExists
        TargetSha256 = $shortcutTargetHash
        AlternateSha256 = $shortcutAlternateHash
    }
    if (-not $readyPhase) {
        $shortcutArtifactParameters.AllowCompleteTarget = $true
    }
    [void](Repair-AtlasProcessExplorerShortcutArtifacts @shortcutArtifactParameters)

    if ($readyPhase) {
        foreach ($propertyName in @('ShortcutApplied', 'DebuggerApplied', 'PcwApplied', 'OwnershipStateWritten')) {
            if (-not [bool]$pending.Progress.$propertyName) {
                throw "The ready Process Explorer transaction lacks '$propertyName'."
            }
        }
        $readyShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
        if (-not $readyShortcut.Exists -or
            $readyShortcut.Sha256 -ne [string]$pending.Desired.ShortcutSha256) {
            throw 'The ready Process Explorer shortcut no longer matches its transaction.'
        }
        if (-not (Test-Path -LiteralPath $ifeo -ErrorAction Stop)) {
            throw 'The ready Process Explorer transaction lost its IFEO key.'
        }
        $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
        if ($ifeoKey.GetValueNames() -notcontains 'Debugger') {
            throw 'The ready Process Explorer transaction lost its Debugger value.'
        }
        $debugger = [string]$ifeoKey.GetValue(
            'Debugger',
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        if (-not $debugger.Equals(
                [string]$pending.Desired.DebuggerValue,
                [StringComparison]::OrdinalIgnoreCase
            ) -or [string]$ifeoKey.GetValueKind('Debugger') -ne 'String') {
            throw 'The ready Process Explorer Debugger no longer matches its transaction.'
        }
        if ($pending.InstallState.Pcw.Changed -and
            [int](Get-ItemProperty -LiteralPath $pcwPath -Name Start -ErrorAction Stop).Start -ne
                [int]$pending.InstallState.Pcw.InstalledStart) {
            throw 'The ready Process Explorer pcw state no longer matches its transaction.'
        }
        Complete-AtlasProcessExplorerPackageInstall -Transaction $transaction
        return [pscustomobject]@{ Resolution = 'Committed'; Transaction = $transaction }
    }

    $persistPending = {
        param($PendingState)
        Write-AtlasProcessExplorerPendingInstall `
            -PackagePath $transaction.PackagePath `
            -Pending $PendingState `
            -ReplaceExisting
    }.GetNewClosure()
    $steps = New-Object System.Collections.Generic.List[object]

    $restorePcw = {
        if (-not $pending.Desired.ConfigurePcw) { return }
        $currentStart = [int](Get-ItemProperty `
                -LiteralPath $pcwPath `
                -Name Start `
                -ErrorAction Stop).Start
        $priorStart = [int]$pending.Immediate.PcwStart
        if ($currentStart -ne [int]$pending.Desired.PcwStart -and
            $currentStart -ne $priorStart) {
            throw "pcw is neither pending nor the recorded pre-install state ('$currentStart')."
        }
        if ($currentStart -eq [int]$pending.Desired.PcwStart) {
            $pcwStartNames = @{ 0 = 'boot'; 1 = 'system'; 2 = 'auto'; 3 = 'demand'; 4 = 'disabled' }
            $scPath = [IO.Path]::Combine($WinDir, 'System32', 'sc.exe')
            & $scPath @('config', 'pcw', 'start=', $pcwStartNames[$priorStart]) | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "sc.exe exited with $LASTEXITCODE" }
        }
        $restoredStart = [int](Get-ItemProperty `
                -LiteralPath $pcwPath `
                -Name Start `
                -ErrorAction Stop).Start
        if ($restoredStart -ne $priorStart) {
            throw "pcw did not restore its pre-install Start value ('$restoredStart')."
        }
    }.GetNewClosure()
    $verifyPcw = {
        if ($pending.Desired.ConfigurePcw -and
            [int](Get-ItemProperty -LiteralPath $pcwPath -Name Start -ErrorAction Stop).Start -ne
                [int]$pending.Immediate.PcwStart) {
            throw 'pcw changed after pending recovery checkpointed it.'
        }
    }.GetNewClosure()
    $steps.Add([pscustomobject]@{ Name = 'Pcw'; Action = $restorePcw; VerifyCompleted = $verifyPcw })

    $restoreDebugger = {
        $ifeoExists = Test-Path -LiteralPath $ifeo -ErrorAction Stop
        $debuggerExists = $false
        $currentValue = $null
        $currentKind = $null
        if ($ifeoExists) {
            $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
            $debuggerExists = $ifeoKey.GetValueNames() -contains 'Debugger'
            if ($debuggerExists) {
                $currentValue = [string]$ifeoKey.GetValue(
                    'Debugger',
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                $currentKind = [string]$ifeoKey.GetValueKind('Debugger')
            }
        }
        $matchesImmediate = if ($pending.Immediate.Debugger.Exists) {
            $debuggerExists -and
            $currentValue -ceq [string]$pending.Immediate.Debugger.Value -and
            $currentKind -eq [string]$pending.Immediate.Debugger.Kind
        }
        else { -not $debuggerExists }
        $matchesDesired = $debuggerExists -and
            $currentValue.Equals(
                [string]$pending.Desired.DebuggerValue,
                [StringComparison]::OrdinalIgnoreCase
            ) -and $currentKind -eq 'String'
        if (-not $matchesImmediate -and -not $matchesDesired) {
            throw 'The Debugger is neither pending nor the recorded pre-install value.'
        }
        if ($matchesDesired) {
            if (-not $ifeoExists) {
                throw 'The pending Debugger key disappeared during recovery.'
            }
            $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
            if ($pending.Immediate.Debugger.Exists) {
                $ifeoKey.SetValue(
                    'Debugger',
                    [string]$pending.Immediate.Debugger.Value,
                    [Microsoft.Win32.RegistryValueKind]([string]$pending.Immediate.Debugger.Kind)
                )
            }
            else {
                $ifeoKey.DeleteValue('Debugger', $false)
            }
        }
        & $verifyPendingDebugger
    }
    $verifyPendingDebugger = {
        $ifeoExists = Test-Path -LiteralPath $ifeo -ErrorAction Stop
        if ($pending.Immediate.Debugger.Exists) {
            if (-not $ifeoExists) { throw 'The pre-install IFEO key is missing.' }
            $ifeoKey = Get-Item -LiteralPath $ifeo -ErrorAction Stop
            if ($ifeoKey.GetValueNames() -notcontains 'Debugger') {
                throw 'The pre-install Debugger value is missing.'
            }
            $value = [string]$ifeoKey.GetValue(
                'Debugger',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
            if ($value -cne [string]$pending.Immediate.Debugger.Value -or
                [string]$ifeoKey.GetValueKind('Debugger') -ne
                    [string]$pending.Immediate.Debugger.Kind) {
                throw 'The Debugger no longer matches the pre-install snapshot.'
            }
        }
        elseif ($ifeoExists -and
            (Get-Item -LiteralPath $ifeo -ErrorAction Stop).GetValueNames() -contains 'Debugger') {
            throw 'A Debugger value appeared after pending recovery checkpointed its absence.'
        }
    }.GetNewClosure()
    # Recreate the action after the verifier exists so its closure binds the
    # durable verifier in Windows PowerShell 5.1 as well as modern PowerShell.
    $restoreDebugger = $restoreDebugger.GetNewClosure()
    $steps.Add([pscustomobject]@{
            Name = 'Debugger'
            Action = $restoreDebugger
            VerifyCompleted = $verifyPendingDebugger
        })

    $restoreShortcut = {
        $currentShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
        $shortcutExists = $currentShortcut.Exists
        $currentHash = $currentShortcut.Sha256
        $matchesImmediate = if ($pending.Immediate.Shortcut.Exists) {
            $shortcutExists -and $currentHash -eq [string]$pending.Immediate.Shortcut.Sha256
        }
        else { -not $shortcutExists }
        $matchesDesired = $shortcutExists -and
            $currentHash -eq [string]$pending.Desired.ShortcutSha256
        if (-not $matchesImmediate -and -not $matchesDesired) {
            throw 'The shortcut is neither pending nor the recorded pre-install file.'
        }
        if ($matchesDesired) {
            if ($pending.Immediate.Shortcut.Exists) {
                $bytes = [Convert]::FromBase64String(
                    [string]$pending.Immediate.Shortcut.BytesBase64
                )
                [void](Set-AtlasProcessExplorerShortcutBytesAtomically `
                    -Path $shortcut `
                    -Bytes $bytes `
                    -ArtifactId ([string]$pending.OperationId) `
                    -AlternateSha256 ([string]$pending.Desired.ShortcutSha256))
            }
            else {
                [IO.File]::Delete($shortcut)
            }
        }
        & $verifyPendingShortcut
    }
    $verifyPendingShortcut = {
        if ($pending.Immediate.Shortcut.Exists) {
            $restoredShortcut = Get-AtlasProcessExplorerShortcutState -Path $shortcut
            if (-not $restoredShortcut.Exists -or
                $restoredShortcut.Sha256 -ne [string]$pending.Immediate.Shortcut.Sha256) {
                throw 'The shortcut no longer matches the pre-install snapshot.'
            }
        }
        elseif ((Get-AtlasProcessExplorerShortcutState -Path $shortcut).Exists) {
            throw 'A shortcut appeared after pending recovery checkpointed its absence.'
        }
    }.GetNewClosure()
    $restoreShortcut = $restoreShortcut.GetNewClosure()
    $steps.Add([pscustomobject]@{
            Name = 'Shortcut'
            Action = $restoreShortcut
            VerifyCompleted = $verifyPendingShortcut
        })

    $result = Invoke-AtlasProcessExplorerRestorePlan `
        -State $pending `
        -Steps $steps.ToArray() `
        -PersistState $persistPending `
        -ProgressPropertyName RecoveryProgress
    if ($result.Failures.Count -ne 0 -or -not $result.AllComplete) {
        throw "The pending Process Explorer transaction could not recover: $($result.Failures -join '; ')"
    }
    Undo-AtlasProcessExplorerPackageInstall -Transaction $transaction
    return [pscustomobject]@{ Resolution = 'RolledBack'; Transaction = $transaction }
}

function Uninstall-AtlasProcessExplorerPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [switch]$DependentStateRestored,

        [Parameter(Mandatory = $true)]
        [psobject]$OperationLock
    )

    if (-not $DependentStateRestored) {
        throw 'Process Explorer package removal requires confirmed dependent-state restoration.'
    }

    $layout = Get-AtlasProcessExplorerLayout
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $OperationLock `
        -AppsPath $layout.AppsPath
    if (-not [IO.Directory]::Exists($layout.PackagePath)) {
        return
    }
    [void](Assert-AtlasProcessExplorerDirectory `
        -Path $layout.PackagePath `
        -AppsPath $layout.AppsPath)
    $uncleanBackupGenerations = @(Get-ChildItem -LiteralPath $layout.AppsPath `
        -Directory -Force -ErrorAction Stop | Where-Object {
            $_.Name -match '^ProcessExplorer\.old-[0-9a-f]{32}$'
        })
    if ($uncleanBackupGenerations.Count -ne 0) {
        throw 'Process Explorer uninstall is blocked until committed backup-generation cleanup completes.'
    }
    Stop-AtlasProcessExplorerPackageProcesses -PackagePath $layout.PackagePath
    $operationId = [guid]::NewGuid().ToString('N')
    Write-AtlasProcessExplorerUninstallJournal `
        -AppsPath $layout.AppsPath `
        -OperationId $operationId
    try {
        Repair-AtlasProcessExplorerUninstallTombstone -OperationLock $OperationLock
    }
    catch {
        if (-not [IO.Directory]::Exists($layout.PackagePath)) {
            Write-Warning "Process Explorer was atomically removed; protected tombstone cleanup will retry later: $($_.Exception.Message)"
            return
        }
        throw
    }
}

function Install-AtlasProcessExplorerPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$PendingInstall,

        [Parameter(Mandatory = $true)]
        [psobject]$OperationLock
    )

    $layout = Get-AtlasProcessExplorerLayout
    Assert-AtlasProcessExplorerParent -Path $layout.AtlasModulesPath
    if (-not (Test-Path -LiteralPath $layout.AppsPath -PathType Container)) {
        [void](New-Item -Path $layout.AppsPath -ItemType Directory -ErrorAction Stop)
    }
    Assert-AtlasProcessExplorerParent -Path $layout.AppsPath
    Assert-AtlasProcessExplorerOperationLock `
        -Lock $OperationLock `
        -AppsPath $layout.AppsPath
    [void](Assert-AtlasProcessExplorerPendingInstall `
        -Pending $PendingInstall `
        -PackagePath $layout.PackagePath)

    $architecture = switch ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToUpperInvariant()) {
        'X64' { 'x64' }
        'ARM64' { 'arm64' }
        'X86' { 'x86' }
        default { throw 'Process Explorer is not supported on this native architecture.' }
    }
    $binary = $script:AtlasProcessExplorerBinaries[$architecture]
    $stagingDirectory = New-AtlasProtectedStagingDirectory
    $candidatePath = $null
    $backupPath = $null
    $oldMoved = $false
    $candidatePublished = $false
    $transaction = $null
    $preparedTransaction = $null

    try {
        $archive = Join-Path -Path $stagingDirectory -ChildPath 'ProcessExplorer.zip'
        Invoke-AtlasPinnedDownload -Uri $script:AtlasProcessExplorerUri `
            -Destination $archive -Sha256 $script:AtlasProcessExplorerArchiveSha256 `
            -ExpectedBytes $script:AtlasProcessExplorerArchiveBytes | Out-Null

        $extracted = Join-Path -Path $stagingDirectory -ChildPath 'extracted'
        Expand-Archive -LiteralPath $archive -DestinationPath $extracted -ErrorAction Stop
        $source = Join-Path -Path $extracted -ChildPath $binary.Name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "The reviewed '$architecture' Process Explorer binary is absent from the archive."
        }
        $sourceItem = Get-Item -LiteralPath $source -Force -ErrorAction Stop
        if (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $binary.Hash -or
            $sourceItem.VersionInfo.FileVersion -ne $script:AtlasProcessExplorerVersion) {
            throw "The reviewed '$architecture' Process Explorer binary failed its identity checks."
        }

        $signature = Get-AuthenticodeSignature -LiteralPath $source
        if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
            $null -eq $signature.SignerCertificate -or
            $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Corporation(,|$)') {
            throw "The reviewed '$architecture' Process Explorer binary is not validly signed by Microsoft."
        }

        # Build and verify a sibling candidate before touching a working package.
        # Publishing and rollback are directory renames beneath the same protected
        # parent, so offline/download/signature failures preserve the old version.
        $operationId = [string]$PendingInstall.OperationId
        $candidatePath = [IO.Path]::Combine(
            $layout.AppsPath,
            "ProcessExplorer.new-$operationId"
        )
        $backupPath = [IO.Path]::Combine(
            $layout.AppsPath,
            "ProcessExplorer.old-$operationId"
        )
        $candidateSecurity = New-AtlasProtectedStagingAcl
        [void](New-AtlasDirectoryWithSecurity `
            -Path $candidatePath `
            -Security $candidateSecurity)
        $actualCandidateSecurity = Get-Acl -LiteralPath $candidatePath -ErrorAction Stop
        if (-not (Test-AtlasProtectedStagingAcl -Acl $actualCandidateSecurity)) {
            throw 'The Process Explorer candidate did not retain its exact protected ACL.'
        }
        [void](Assert-AtlasProcessExplorerDirectory -Path $candidatePath -AppsPath $layout.AppsPath)

        $destination = Join-Path -Path $candidatePath -ChildPath 'procexp.exe'
        Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
        $copied = Get-Item -LiteralPath $destination -Force -ErrorAction Stop
        if (($copied.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $binary.Hash) {
            throw 'The Process Explorer candidate failed final-byte verification.'
        }

        $templatePath = [IO.Path]::Combine(
            $candidatePath,
            $script:AtlasProcessExplorerShortcutTemplateName
        )
        $wsh = New-Object -ComObject WScript.Shell
        $template = $wsh.CreateShortcut($templatePath)
        $template.TargetPath = [string]$PendingInstall.Desired.DebuggerValue
        $template.Save()
        $templateItem = Get-Item -LiteralPath $templatePath -Force -ErrorAction Stop
        if (($templateItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $templateItem.Length -le 0 -or $templateItem.Length -gt 1048576) {
            throw 'The protected Process Explorer shortcut template is invalid.'
        }
        $templateHash = Get-AtlasProcessExplorerFileSha256 -Path $templatePath
        $PendingInstall.Desired.ShortcutSha256 = $templateHash
        $PendingInstall.InstallState.Shortcut.InstalledSha256 = $templateHash
        $PendingInstall.Package.InstalledSha256 = $binary.Hash.ToLowerInvariant()

        $hadPreviousPackage = [IO.Directory]::Exists($layout.PackagePath)
        if ($hadPreviousPackage) {
            [void](Assert-AtlasProcessExplorerDirectory `
                -Path $layout.PackagePath `
                -AppsPath $layout.AppsPath)
        }
        $PendingInstall.Package.HadPreviousPackage = $hadPreviousPackage
        Write-AtlasProcessExplorerPendingInstall `
            -PackagePath $candidatePath `
            -Pending $PendingInstall `
            -CanonicalPackagePath $layout.PackagePath
        $preparedTransaction = New-AtlasProcessExplorerPackageTransaction `
            -OperationId $operationId `
            -AppsPath $layout.AppsPath `
            -HadPreviousPackage $hadPreviousPackage `
            -InstalledSha256 $binary.Hash
        $preparedTransaction.PendingInstall = $PendingInstall
        $preparedTransaction.OperationLock = $OperationLock

        Stop-AtlasProcessExplorerPackageProcesses -PackagePath $layout.PackagePath
        if ($hadPreviousPackage) {
            [IO.Directory]::Move($layout.PackagePath, $backupPath)
            $oldMoved = $true
        }

        [IO.Directory]::Move($candidatePath, $layout.PackagePath)
        # Arm the typed transaction immediately after publication, before any
        # fallible validation/checkpoint. Every subsequent failure must use its
        # journaled rollback rather than deleting the canonical directory.
        $transaction = $preparedTransaction
        $candidatePublished = $true
        [void](Assert-AtlasProcessExplorerDirectory `
            -Path $layout.PackagePath `
            -AppsPath $layout.AppsPath)
        $installedPath = [IO.Path]::Combine($layout.PackagePath, 'procexp.exe')
        if ((Get-FileHash -LiteralPath $installedPath -Algorithm SHA256).Hash -ne $binary.Hash) {
            throw 'The published Process Explorer package failed final-byte verification.'
        }
        $PendingInstall.Progress.PackagePublished = $true
        $PendingInstall.Phase = 'Published'
        Write-AtlasProcessExplorerPendingInstall `
            -PackagePath $layout.PackagePath `
            -Pending $PendingInstall `
            -ReplaceExisting
        return $transaction
    }
    catch {
        $originalError = $_
        try {
            # Directory.Move may complete before a caught cancellation is
            # surfaced. Reconstruct the completed edge from protected topology
            # instead of trusting a flag assigned on the following statement.
            if ($null -eq $transaction -and $null -ne $preparedTransaction -and
                [IO.Directory]::Exists($layout.PackagePath) -and
                -not [IO.Directory]::Exists($candidatePath) -and
                (-not $hadPreviousPackage -or [IO.Directory]::Exists($backupPath))) {
                $transaction = $preparedTransaction
                $candidatePublished = $true
            }
            if (-not $oldMoved -and $hadPreviousPackage -and
                [IO.Directory]::Exists($backupPath) -and
                -not [IO.Directory]::Exists($layout.PackagePath) -and
                [IO.Directory]::Exists($candidatePath)) {
                $oldMoved = $true
            }
            if ($null -ne $transaction) {
                Undo-AtlasProcessExplorerPackageInstall -Transaction $transaction
                $candidatePublished = $false
                $oldMoved = $false
            }
            elseif ($candidatePublished) {
                throw 'The published Process Explorer generation has no typed rollback transaction.'
            }
            if ($oldMoved -and [IO.Directory]::Exists($backupPath) -and
                -not [IO.Directory]::Exists($layout.PackagePath)) {
                [IO.Directory]::Move($backupPath, $layout.PackagePath)
                $oldMoved = $false
            }
        }
        catch {
            throw "Process Explorer installation failed and rollback also failed: $($originalError.Exception.Message); $($_.Exception.Message)"
        }
        throw $originalError
    }
    finally {
        if ($null -eq $transaction -and
            $candidatePath -and [IO.Directory]::Exists($candidatePath) -and
            ($null -eq $backupPath -or -not [IO.Directory]::Exists($backupPath))) {
            Remove-AtlasProcessExplorerDirectory `
                -Path $candidatePath `
                -AppsPath $layout.AppsPath
        }
        if (Test-Path -LiteralPath $stagingDirectory -PathType Container) {
            Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
