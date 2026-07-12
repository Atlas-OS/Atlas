# Installs the reviewed Sysinternals Process Explorer binary and owns only the
# integrations Atlas creates for it.  The package is deliberately small: one
# executable, one ownership record, one Start menu shortcut, and one IFEO value.

$downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
if (-not [IO.File]::Exists($downloadIntegrity)) {
    throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
}
. $downloadIntegrity

$script:AtlasProcessExplorerVersion = '17.12'
$script:AtlasProcessExplorerUri = 'https://download.sysinternals.com/files/ProcessExplorer.zip'
$script:AtlasProcessExplorerArchiveSha256 = '47ff65944e87280a0d40e6eb7a6157f13f46d605df44ff794784b54d56795aa6'
$script:AtlasProcessExplorerArchiveBytes = 3511555
$script:AtlasProcessExplorerStateFileName = 'Atlas.ProcessExplorer.State.json'
$script:AtlasProcessExplorerBinaries = @{
    X86 = [pscustomobject]@{
        ArchiveName = 'procexp.exe'
        Sha256 = 'b29917ce089e46bc6238e3e9e20596599bcbe7aa10d4f688bc32db94d6e4dae8'
    }
    X64 = [pscustomobject]@{
        ArchiveName = 'procexp64.exe'
        Sha256 = '8404b6cfad9d998b10d2df6073e1275b7744c0416982bdc5cb7ef5b74348333d'
    }
    ARM64 = [pscustomobject]@{
        ArchiveName = 'procexp64a.exe'
        Sha256 = 'f2a763d4ad679a2e585ff95c792b476c749832a1b6ba1f7521f387ff4e943f56'
    }
}

function Get-AtlasProcessExplorerLayout {
    [CmdletBinding()]
    param()
    $windowsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    $atlasModulesPath = [IO.Path]::GetFullPath([IO.Path]::Combine($windowsPath, 'AtlasModules'))
    $packagePath = [IO.Path]::Combine($atlasModulesPath, 'Apps', 'ProcessExplorer')
    return [pscustomobject]@{
        WindowsPath = $windowsPath
        PackagePath = $packagePath
        BinaryPath = [IO.Path]::Combine($packagePath, 'procexp.exe')
        StatePath = [IO.Path]::Combine($packagePath, $script:AtlasProcessExplorerStateFileName)
        ShortcutPath = [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonStartMenu),
            'Programs',
            'Process Explorer.lnk'
        )
        IfeoPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
        PcwPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\pcw'
    }
}

function Get-AtlasProcessExplorerBinary {
    [CmdletBinding()]
    param(
        [string]$Architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    )
    $key = $Architecture.ToUpperInvariant()
    if (-not $script:AtlasProcessExplorerBinaries.ContainsKey($key)) {
        throw "Process Explorer does not support native architecture '$Architecture'."
    }
    return $script:AtlasProcessExplorerBinaries[$key]
}

function Get-AtlasProcessExplorerFileSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
}

function Get-AtlasProcessExplorerFileSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{ Exists = $false; Bytes = $null }
    }
    return [pscustomobject]@{
        Exists = $true
        Bytes = [IO.File]::ReadAllBytes($Path)
    }
}

function Restore-AtlasProcessExplorerFileSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][psobject]$Snapshot
    )
    if ($Snapshot.Exists) {
        $parent = Split-Path -Parent $Path
        if (-not [IO.Directory]::Exists($parent)) {
            [void](New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop)
        }
        [IO.File]::WriteAllBytes($Path, [byte[]]$Snapshot.Bytes)
    }
    elseif ([IO.File]::Exists($Path)) {
        [IO.File]::Delete($Path)
    }
}

function Copy-AtlasProcessExplorerFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [string]$ExpectedSha256
    )
    $parent = Split-Path -Parent $Destination
    if (-not [IO.Directory]::Exists($parent)) {
        [void](New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop)
    }
    $temporaryPath = "$Destination.new-$([guid]::NewGuid().ToString('N'))"
    $backupPath = "$Destination.old-$([guid]::NewGuid().ToString('N'))"

    try {
        Copy-Item -LiteralPath $Source -Destination $temporaryPath -ErrorAction Stop
        if ($ExpectedSha256 -and
            (Get-AtlasProcessExplorerFileSha256 -Path $temporaryPath) -ne $ExpectedSha256) {
            throw "The copied file for '$Destination' failed its SHA-256 check."
        }

        if ([IO.File]::Exists($Destination)) {
            [IO.File]::Replace($temporaryPath, $Destination, $backupPath, $true)
        }
        else {
            [IO.File]::Move($temporaryPath, $Destination)
        }
        if ($ExpectedSha256 -and
            (Get-AtlasProcessExplorerFileSha256 -Path $Destination) -ne $ExpectedSha256) {
            throw "The published file '$Destination' failed its SHA-256 check."
        }
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
        if ([IO.File]::Exists($backupPath)) { [IO.File]::Delete($backupPath) }
    }
}

function Get-AtlasProcessExplorerDebugger {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$IfeoPath)
    if (-not (Test-Path -LiteralPath $IfeoPath -ErrorAction Stop)) {
        return [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }
    }
    $key = Get-Item -LiteralPath $IfeoPath -ErrorAction Stop
    if ($key.GetValueNames() -notcontains 'Debugger') {
        return [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }
    }
    return [pscustomobject]@{
        Exists = $true
        Value = [string]$key.GetValue(
            'Debugger',
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        Kind = [string]$key.GetValueKind('Debugger')
    }
}

function Write-AtlasProcessExplorerDebugger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$IfeoPath,
        [Parameter(Mandatory = $true)][psobject]$State
    )
    if ($State.Exists) {
        if ($State.Kind -notin @('String', 'ExpandString')) {
            throw "The IFEO Debugger registry kind '$($State.Kind)' is unsupported."
        }
        if (-not (Test-Path -LiteralPath $IfeoPath -ErrorAction Stop)) {
            [void](New-Item -Path $IfeoPath -Force -ErrorAction Stop)
        }
        $kind = [Microsoft.Win32.RegistryValueKind]([string]$State.Kind)
        (Get-Item -LiteralPath $IfeoPath -ErrorAction Stop).SetValue(
            'Debugger',
            [string]$State.Value,
            $kind
        )
    }
    elseif (Test-Path -LiteralPath $IfeoPath -ErrorAction Stop) {
        (Get-Item -LiteralPath $IfeoPath -ErrorAction Stop).DeleteValue('Debugger', $false)
    }

    $actual = Get-AtlasProcessExplorerDebugger -IfeoPath $IfeoPath
    if ($actual.Exists -ne [bool]$State.Exists -or
        ($State.Exists -and
            ($actual.Value -cne [string]$State.Value -or $actual.Kind -ne [string]$State.Kind))) {
        throw 'The Task Manager IFEO Debugger value did not retain the requested state.'
    }
}

function Test-AtlasProcessExplorerDebuggerValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$State,
        [Parameter(Mandatory = $true)][string]$ExpectedPath
    )
    return $State.Exists -and $State.Kind -eq 'String' -and
        ([string]$State.Value).Equals($ExpectedPath, [StringComparison]::OrdinalIgnoreCase)
}

function Get-AtlasProcessExplorerShortcutTarget {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not [IO.File]::Exists($Path)) {
        return $null
    }
    $shell = $null
    $shortcut = $null
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        return [string]$shortcut.TargetPath
    }
    catch {
        return $null
    }
    finally {
        if ($null -ne $shortcut) {
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)
        }
        if ($null -ne $shell) {
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
        }
    }
}

function Write-AtlasProcessExplorerShortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )
    $shell = $null
    $shortcut = $null
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        $shortcut.TargetPath = $TargetPath
        $shortcut.Save()
    }
    finally {
        if ($null -ne $shortcut) {
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)
        }
        if ($null -ne $shell) {
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
        }
    }
    if (-not [IO.File]::Exists($Path)) {
        throw "The Process Explorer shortcut was not created at '$Path'."
    }
}

function Get-AtlasProcessExplorerPcwStart {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$PcwPath)
    $start = [int](Get-ItemProperty -LiteralPath $PcwPath -Name Start -ErrorAction Stop).Start
    if ($start -notin 0..4) {
        throw "The pcw service has unsupported Start value '$start'."
    }
    return $start
}

function Invoke-AtlasProcessExplorerPcwStartUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$WindowsPath,
        [Parameter(Mandatory = $true)][string]$PcwPath,
        [Parameter(Mandatory = $true)][ValidateRange(0, 4)][int]$Start
    )
    $startNames = @('boot', 'system', 'auto', 'demand', 'disabled')
    $scPath = [IO.Path]::Combine($WindowsPath, 'System32', 'sc.exe')
    & $scPath @('config', 'pcw', 'start=', $startNames[$Start]) | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "sc.exe could not set pcw to '$($startNames[$Start])' (exit $LASTEXITCODE)."
    }
    $actual = Get-AtlasProcessExplorerPcwStart -PcwPath $PcwPath
    if ($actual -ne $Start) {
        throw "The pcw service retained unexpected Start value '$actual'."
    }
}

function Close-AtlasProcessExplorerPackageProcess {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$PackagePath)
    $prefix = [IO.Path]::GetFullPath($PackagePath).TrimEnd('\') + '\'
    foreach ($process in @(Get-Process -Name procexp, procexp64, procexp64a -ErrorAction SilentlyContinue)) {
        $processPath = $null
        try { $processPath = [string]$process.Path } catch { continue }
        if (-not $processPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $process.Kill()
        if (-not $process.WaitForExit(10000)) {
            throw "Process Explorer process $($process.Id) did not stop within ten seconds."
        }
    }
}

function Read-AtlasProcessExplorerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [switch]$AllowMissing
    )
    if (-not [IO.File]::Exists($StatePath)) {
        if ($AllowMissing) { return $null }
        throw 'The Process Explorer ownership state is missing.'
    }
    $item = Get-Item -LiteralPath $StatePath -Force -ErrorAction Stop
    if ($item.Length -le 0 -or $item.Length -gt 4096) {
        throw 'The Process Explorer ownership state is not a bounded JSON file.'
    }
    try {
        $state = [IO.File]::ReadAllText($item.FullName) | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "The Process Explorer ownership state is invalid JSON: $($_.Exception.Message)"
    }
    foreach ($name in @(
            'SchemaVersion', 'PackageVersion', 'Architecture',
            'InstalledBinarySha256', 'PcwChanged', 'PcwPriorStart'
        )) {
        if ($state.PSObject.Properties.Name -notcontains $name) {
            throw "The Process Explorer ownership state is missing '$name'."
        }
    }
    if ([int]$state.SchemaVersion -ne 1 -or
        [string]$state.PackageVersion -notmatch '^\d+(?:\.\d+){1,3}$' -or
        [string]$state.Architecture -notin @('X86', 'X64', 'ARM64') -or
        [string]$state.InstalledBinarySha256 -notmatch '^[0-9a-f]{64}$' -or
        $state.PcwChanged -isnot [bool]) {
        throw 'The Process Explorer ownership state has invalid values.'
    }
    if ($state.PcwChanged) {
        if ($null -eq $state.PcwPriorStart -or [int]$state.PcwPriorStart -notin 0..3) {
            throw 'The Process Explorer pcw ownership state is invalid.'
        }
    }
    elseif ($null -ne $state.PcwPriorStart) {
        throw 'Unchanged pcw state cannot contain a prior Start value.'
    }
    return $state
}

function Write-AtlasProcessExplorerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [Parameter(Mandatory = $true)][psobject]$State
    )
    $parent = Split-Path -Parent $StatePath
    if (-not [IO.Directory]::Exists($parent)) {
        [void](New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop)
    }
    $temporaryPath = "$StatePath.new-$([guid]::NewGuid().ToString('N'))"
    $backupPath = "$StatePath.old-$([guid]::NewGuid().ToString('N'))"
    try {
        $utf8 = New-Object Text.UTF8Encoding($false)
        [IO.File]::WriteAllText(
            $temporaryPath,
            ($State | ConvertTo-Json -Depth 3 -Compress),
            $utf8
        )
        if ([IO.File]::Exists($StatePath)) {
            [IO.File]::Replace($temporaryPath, $StatePath, $backupPath, $true)
        }
        else {
            [IO.File]::Move($temporaryPath, $StatePath)
        }
        [void](Read-AtlasProcessExplorerState -StatePath $StatePath)
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) { [IO.File]::Delete($temporaryPath) }
        if ([IO.File]::Exists($backupPath)) { [IO.File]::Delete($backupPath) }
    }
}

function Assert-AtlasProcessExplorerInstallOwnership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$Layout,
        [AllowNull()][psobject]$ExistingState,
        [Parameter(Mandatory = $true)][psobject]$Debugger,
        [AllowNull()][string]$ShortcutTarget,
        [Parameter(Mandatory = $true)][int]$PcwStart,
        [Parameter(Mandatory = $true)][string]$ExpectedBinarySha256
    )
    if ($Debugger.Exists -and
        -not (Test-AtlasProcessExplorerDebuggerValue -State $Debugger -ExpectedPath $Layout.BinaryPath)) {
        throw "Process Explorer will not replace another Task Manager Debugger ('$($Debugger.Value)')."
    }
    if ([IO.File]::Exists($Layout.ShortcutPath) -and
        ([string]::IsNullOrWhiteSpace($ShortcutTarget) -or
            -not $ShortcutTarget.Equals($Layout.BinaryPath, [StringComparison]::OrdinalIgnoreCase))) {
        throw "Process Explorer will not replace the existing Start menu shortcut '$($Layout.ShortcutPath)'."
    }
    if ($null -ne $ExistingState -and $ExistingState.PcwChanged -and
        $PcwStart -ne 4 -and $PcwStart -ne [int]$ExistingState.PcwPriorStart) {
        throw "Process Explorer will not overwrite the newer pcw Start value '$PcwStart'."
    }
    if ($null -ne $ExistingState -and [IO.File]::Exists($Layout.BinaryPath)) {
        $currentHash = Get-AtlasProcessExplorerFileSha256 -Path $Layout.BinaryPath
        if ($currentHash -notin @(
                [string]$ExistingState.InstalledBinarySha256,
                $ExpectedBinarySha256
            )) {
            throw 'Process Explorer will not overwrite a package Atlas no longer owns.'
        }
    }
    if ($null -eq $ExistingState -and [IO.File]::Exists($Layout.BinaryPath)) {
        $signature = Get-AuthenticodeSignature -LiteralPath $Layout.BinaryPath
        if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
            $null -eq $signature.SignerCertificate -or
            $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Corporation(,|$)') {
            throw 'Process Explorer will not overwrite an unowned package binary.'
        }
    }
}

function ConvertTo-AtlasProcessExplorerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Architecture,
        [Parameter(Mandatory = $true)][string]$InstalledBinarySha256,
        [Parameter(Mandatory = $true)][int]$PcwStart,
        [Parameter(Mandatory = $true)][bool]$DisablePcw,
        [AllowNull()][psobject]$ExistingState
    )
    $pcwChanged = $false
    $pcwPriorStart = $null
    if ($null -ne $ExistingState -and $ExistingState.PcwChanged) {
        $pcwChanged = $true
        $pcwPriorStart = [int]$ExistingState.PcwPriorStart
    }
    elseif ($DisablePcw -and $PcwStart -ne 4) {
        $pcwChanged = $true
        $pcwPriorStart = $PcwStart
    }

    return [pscustomobject]@{
        SchemaVersion = 1
        PackageVersion = $script:AtlasProcessExplorerVersion
        Architecture = $Architecture.ToUpperInvariant()
        InstalledBinarySha256 = $InstalledBinarySha256.ToLowerInvariant()
        PcwChanged = $pcwChanged
        PcwPriorStart = $pcwPriorStart
    }
}

function Invoke-AtlasProcessExplorerLocked {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][scriptblock]$Action)
    $mutex = New-Object Threading.Mutex($false, 'Global\AtlasOS.ProcessExplorer.Package.v1')
    $lockTaken = $false
    try {
        try { $lockTaken = $mutex.WaitOne(10000) }
        catch [Threading.AbandonedMutexException] { $lockTaken = $true }
        if (-not $lockTaken) {
            throw 'Another Process Explorer package operation is still running.'
        }
        return & $Action
    }
    finally {
        if ($lockTaken) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Install-AtlasProcessExplorerPackageCore {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][bool]$DisablePcw)
    $layout = Get-AtlasProcessExplorerLayout
    $architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToUpperInvariant()
    $binary = Get-AtlasProcessExplorerBinary -Architecture $architecture
    $existingState = Read-AtlasProcessExplorerState -StatePath $layout.StatePath -AllowMissing
    $debuggerBefore = Get-AtlasProcessExplorerDebugger -IfeoPath $layout.IfeoPath
    $shortcutTarget = Get-AtlasProcessExplorerShortcutTarget -Path $layout.ShortcutPath
    $pcwBefore = Get-AtlasProcessExplorerPcwStart -PcwPath $layout.PcwPath
    Assert-AtlasProcessExplorerInstallOwnership -Layout $layout `
        -ExistingState $existingState -Debugger $debuggerBefore `
        -ShortcutTarget $shortcutTarget -PcwStart $pcwBefore `
        -ExpectedBinarySha256 $binary.Sha256

    $stagingPath = New-AtlasProtectedStagingDirectory
    $binaryBefore = Get-AtlasProcessExplorerFileSnapshot -Path $layout.BinaryPath
    $shortcutBefore = Get-AtlasProcessExplorerFileSnapshot -Path $layout.ShortcutPath
    $stateBefore = Get-AtlasProcessExplorerFileSnapshot -Path $layout.StatePath
    $binaryTouched = $false
    $shortcutTouched = $false
    $debuggerTouched = $false
    $pcwTouched = $false
    try {
        $sourceBinary = $null
        if (-not [IO.File]::Exists($layout.BinaryPath) -or
            (Get-AtlasProcessExplorerFileSha256 -Path $layout.BinaryPath) -ne $binary.Sha256) {
            $archivePath = [IO.Path]::Combine($stagingPath, 'ProcessExplorer.zip')
            Invoke-AtlasPinnedDownload -Uri $script:AtlasProcessExplorerUri `
                -Destination $archivePath `
                -Sha256 $script:AtlasProcessExplorerArchiveSha256 `
                -ExpectedBytes $script:AtlasProcessExplorerArchiveBytes | Out-Null
            $extractedPath = [IO.Path]::Combine($stagingPath, 'extracted')
            Expand-Archive -LiteralPath $archivePath -DestinationPath $extractedPath -ErrorAction Stop
            $sourceBinary = [IO.Path]::Combine($extractedPath, $binary.ArchiveName)
            if (-not [IO.File]::Exists($sourceBinary)) {
                throw "The '$architecture' Process Explorer binary is absent from the archive."
            }
            $sourceItem = Get-Item -LiteralPath $sourceBinary -Force -ErrorAction Stop
            if ((Get-AtlasProcessExplorerFileSha256 -Path $sourceBinary) -ne $binary.Sha256 -or
                $sourceItem.VersionInfo.FileVersion -ne $script:AtlasProcessExplorerVersion) {
                throw "The '$architecture' Process Explorer binary failed its identity checks."
            }
            $signature = Get-AuthenticodeSignature -LiteralPath $sourceBinary
            if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
                $null -eq $signature.SignerCertificate -or
                $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Corporation(,|$)') {
                throw "The '$architecture' Process Explorer binary is not validly signed by Microsoft."
            }
            Close-AtlasProcessExplorerPackageProcess -PackagePath $layout.PackagePath
            $binaryTouched = $true
            Copy-AtlasProcessExplorerFile -Source $sourceBinary `
                -Destination $layout.BinaryPath -ExpectedSha256 $binary.Sha256
        }

        $state = ConvertTo-AtlasProcessExplorerState -Architecture $architecture `
            -InstalledBinarySha256 $binary.Sha256 -PcwStart $pcwBefore `
            -DisablePcw $DisablePcw -ExistingState $existingState
        Write-AtlasProcessExplorerState -StatePath $layout.StatePath -State $state

        if (-not [IO.File]::Exists($layout.ShortcutPath)) {
            $shortcutTemplate = [IO.Path]::Combine($stagingPath, 'Process Explorer.lnk')
            Write-AtlasProcessExplorerShortcut `
                -Path $shortcutTemplate -TargetPath $layout.BinaryPath
            $shortcutTouched = $true
            Copy-AtlasProcessExplorerFile `
                -Source $shortcutTemplate -Destination $layout.ShortcutPath
        }
        $debuggerTouched = $true
        Write-AtlasProcessExplorerDebugger -IfeoPath $layout.IfeoPath -State ([pscustomobject]@{
                Exists = $true
                Value = $layout.BinaryPath
                Kind = 'String'
            })
        if ($DisablePcw -and $pcwBefore -ne 4) {
            $pcwTouched = $true
            Invoke-AtlasProcessExplorerPcwStartUpdate -WindowsPath $layout.WindowsPath `
                -PcwPath $layout.PcwPath -Start 4
        }
        $actualTarget = Get-AtlasProcessExplorerShortcutTarget -Path $layout.ShortcutPath
        if ([string]::IsNullOrWhiteSpace($actualTarget) -or
            -not $actualTarget.Equals($layout.BinaryPath, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'The common Start menu shortcut did not retain the Process Explorer target.'
        }

    }
    catch {
        $originalError = $_
        $rollbackFailures = New-Object Collections.Generic.List[string]
        if ($pcwTouched) {
            try {
                Invoke-AtlasProcessExplorerPcwStartUpdate -WindowsPath $layout.WindowsPath `
                    -PcwPath $layout.PcwPath -Start $pcwBefore
            }
            catch { $rollbackFailures.Add("pcw: $($_.Exception.Message)") }
        }
        if ($debuggerTouched) {
            try { Write-AtlasProcessExplorerDebugger -IfeoPath $layout.IfeoPath -State $debuggerBefore }
            catch { $rollbackFailures.Add("IFEO: $($_.Exception.Message)") }
        }
        if ($shortcutTouched) {
            try {
                Restore-AtlasProcessExplorerFileSnapshot `
                    -Path $layout.ShortcutPath -Snapshot $shortcutBefore
            }
            catch { $rollbackFailures.Add("shortcut: $($_.Exception.Message)") }
        }

        if ($rollbackFailures.Count -eq 0) {
            try { Restore-AtlasProcessExplorerFileSnapshot -Path $layout.StatePath -Snapshot $stateBefore }
            catch { $rollbackFailures.Add("state: $($_.Exception.Message)") }
            if ($rollbackFailures.Count -eq 0 -and $binaryTouched) {
                try {
                    Restore-AtlasProcessExplorerFileSnapshot `
                        -Path $layout.BinaryPath -Snapshot $binaryBefore
                }
                catch { $rollbackFailures.Add("package: $($_.Exception.Message)") }
            }
        }
        if ($rollbackFailures.Count -ne 0) {
            throw "Process Explorer install failed: $($originalError.Exception.Message); rollback failed: $($rollbackFailures -join '; ')"
        }
        throw $originalError
    }
    finally {
        if ([IO.Directory]::Exists($stagingPath)) {
            Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Write-AtlasProcessExplorerUserPreference {
    [CmdletBinding()]
    param()
    $preferencePath = 'HKCU:\SOFTWARE\Sysinternals\Process Explorer'
    if (-not (Test-Path -LiteralPath $preferencePath)) {
        [void](New-Item -Path $preferencePath -Force -ErrorAction Stop)
    }
    New-ItemProperty -LiteralPath $preferencePath -Name OneInstance `
        -PropertyType DWord -Value 1 -Force -ErrorAction Stop | Out-Null
}

function Install-AtlasProcessExplorerPackage {
    [CmdletBinding()]
    param([switch]$DisablePcw)
    $disablePcwRequested = [bool]$DisablePcw
    Invoke-AtlasProcessExplorerLocked -Action {
        Install-AtlasProcessExplorerPackageCore -DisablePcw $disablePcwRequested
    }
}

function Restore-AtlasProcessExplorerIntegration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$Layout,
        [AllowNull()][psobject]$State
    )
    $debugger = Get-AtlasProcessExplorerDebugger -IfeoPath $Layout.IfeoPath
    if (Test-AtlasProcessExplorerDebuggerValue -State $debugger -ExpectedPath $Layout.BinaryPath) {
        Write-AtlasProcessExplorerDebugger -IfeoPath $Layout.IfeoPath -State ([pscustomobject]@{
                Exists = $false
                Value = $null
                Kind = $null
            })
    }

    $shortcutTarget = Get-AtlasProcessExplorerShortcutTarget -Path $Layout.ShortcutPath
    if (-not [string]::IsNullOrWhiteSpace($shortcutTarget) -and
        $shortcutTarget.Equals($Layout.BinaryPath, [StringComparison]::OrdinalIgnoreCase)) {
        [IO.File]::Delete($Layout.ShortcutPath)
        if ([IO.File]::Exists($Layout.ShortcutPath)) {
            throw 'The Atlas-owned Process Explorer shortcut could not be removed.'
        }
    }

    if ($null -ne $State -and $State.PcwChanged) {
        $pcwStart = Get-AtlasProcessExplorerPcwStart -PcwPath $Layout.PcwPath
        if ($pcwStart -eq 4) {
            Invoke-AtlasProcessExplorerPcwStartUpdate -WindowsPath $Layout.WindowsPath `
                -PcwPath $Layout.PcwPath -Start ([int]$State.PcwPriorStart)
        }
    }
}

function Uninstall-AtlasProcessExplorerPackageCore {
    [CmdletBinding()]
    param()
    $layout = Get-AtlasProcessExplorerLayout
    $state = Read-AtlasProcessExplorerState -StatePath $layout.StatePath -AllowMissing
    Restore-AtlasProcessExplorerIntegration -Layout $layout -State $state
    $debugger = Get-AtlasProcessExplorerDebugger -IfeoPath $layout.IfeoPath
    if (Test-AtlasProcessExplorerDebuggerValue -State $debugger -ExpectedPath $layout.BinaryPath) {
        throw 'Task Manager still redirects to the Atlas Process Explorer package; the package was retained.'
    }
    Close-AtlasProcessExplorerPackageProcess -PackagePath $layout.PackagePath
    if ([IO.File]::Exists($layout.BinaryPath)) {
        $removeBinary = $false
        if ($null -ne $state) {
            $removeBinary = (Get-AtlasProcessExplorerFileSha256 -Path $layout.BinaryPath) -eq
                [string]$state.InstalledBinarySha256
        }
        else {
            $signature = Get-AuthenticodeSignature -LiteralPath $layout.BinaryPath
            $removeBinary = $signature.Status -eq [System.Management.Automation.SignatureStatus]::Valid -and
                $null -ne $signature.SignerCertificate -and
                $signature.SignerCertificate.Subject -match '(^|,\s*)CN=Microsoft Corporation(,|$)'
        }
        if ($removeBinary) {
            [IO.File]::Delete($layout.BinaryPath)
        }
    }
    if ([IO.File]::Exists($layout.StatePath)) {
        [IO.File]::Delete($layout.StatePath)
    }
    if ([IO.Directory]::Exists($layout.PackagePath) -and
        @(Get-ChildItem -LiteralPath $layout.PackagePath -Force -ErrorAction Stop).Count -eq 0) {
        [IO.Directory]::Delete($layout.PackagePath)
    }
}

function Uninstall-AtlasProcessExplorerPackage {
    [CmdletBinding()]
    param()
    Invoke-AtlasProcessExplorerLocked -Action {
        Uninstall-AtlasProcessExplorerPackageCore
    }
}
