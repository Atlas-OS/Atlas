# Atlas.Appx domain: install-state-bound current-user package cache clearing.
#
# Machine-wide AppX removal stays in the TrustedInstaller phase. Cache deletion is
# deliberately split into a medium, non-elevated child created from the exact install
# state identity. The child derives only its own registered profile and refuses every
# reparse point before deleting with non-recursive file-system primitives.

function ConvertTo-AtlasAppxCacheSid {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label
    )

    try {
        $sid = New-Object System.Security.Principal.SecurityIdentifier($Value)
    }
    catch {
        throw "$Label is not a valid SID."
    }

    if (-not $sid.IsAccountSid() -or
        -not $sid.Value.Equals($Value, [StringComparison]::Ordinal) -or
        $sid.Value -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20') -or
        $sid.Value.StartsWith('S-1-5-32-', [StringComparison]::Ordinal)) {
        throw "$Label is not a canonical user account SID."
    }
    return $sid.Value
}

function Test-AtlasAppxCachePathContained {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Candidate,
        [switch]$AllowRoot
    )

    if (-not [IO.Path]::IsPathRooted($Root) -or -not [IO.Path]::IsPathRooted($Candidate)) {
        return $false
    }
    $separator = [IO.Path]::DirectorySeparatorChar
    $alternate = [IO.Path]::AltDirectorySeparatorChar
    $rootPath = [IO.Path]::GetFullPath($Root).Replace($alternate, $separator).TrimEnd($separator)
    $candidatePath = [IO.Path]::GetFullPath($Candidate).Replace($alternate, $separator).TrimEnd($separator)
    if ($candidatePath.Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
        return [bool]$AllowRoot
    }
    return $candidatePath.StartsWith(
        $rootPath + $separator,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Resolve-AtlasAppxCacheNormalDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ContainmentRoot,
        [string]$ExpectedParent,
        [switch]$AllowRoot,
        [switch]$AllowMissing
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not (Test-AtlasAppxCachePathContained -Root $ContainmentRoot `
            -Candidate $fullPath -AllowRoot:$AllowRoot)) {
        throw "AppX cache directory escaped its allowed root: '$fullPath'."
    }

    try {
        $attributes = [IO.File]::GetAttributes($fullPath)
    }
    catch [IO.FileNotFoundException] {
        if ($AllowMissing) { return $null }
        throw "Required AppX cache directory is missing: '$fullPath'."
    }
    catch [IO.DirectoryNotFoundException] {
        if ($AllowMissing) { return $null }
        throw "Required AppX cache directory is missing: '$fullPath'."
    }

    if (($attributes -band [IO.FileAttributes]::Directory) -eq 0) {
        throw "AppX cache path is not a directory: '$fullPath'."
    }
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "AppX cache directory is a reparse point: '$fullPath'."
    }
    if ($ExpectedParent) {
        $actualParent = [IO.Directory]::GetParent($fullPath)
        if ($null -eq $actualParent -or
            -not $actualParent.FullName.Equals(
                [IO.Path]::GetFullPath($ExpectedParent),
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw "AppX cache directory is not a direct child of '$ExpectedParent': '$fullPath'."
        }
    }
    return $fullPath
}

function Resolve-AtlasAppxCacheNormalFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ContainmentRoot
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not (Test-AtlasAppxCachePathContained -Root $ContainmentRoot -Candidate $fullPath)) {
        throw "AppX cache executable or script escaped its protected root: '$fullPath'."
    }

    $rootPath = [IO.Path]::GetFullPath($ContainmentRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $ancestor = [IO.Directory]::GetParent($fullPath)
    $reachedRoot = $false
    while ($null -ne $ancestor) {
        if (-not (Test-AtlasAppxCachePathContained -Root $rootPath `
                -Candidate $ancestor.FullName -AllowRoot)) {
            throw "AppX cache executable or script has an ancestor outside its protected root: '$fullPath'."
        }
        $ancestorAttributes = [IO.File]::GetAttributes($ancestor.FullName)
        if (($ancestorAttributes -band [IO.FileAttributes]::Directory) -eq 0 -or
            ($ancestorAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "AppX cache executable or script has a non-normal ancestor: '$($ancestor.FullName)'."
        }
        if ($ancestor.FullName.TrimEnd(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ).Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
            $reachedRoot = $true
            break
        }
        $ancestor = $ancestor.Parent
    }
    if (-not $reachedRoot) {
        throw "AppX cache executable or script is not rooted beneath its protected directory: '$fullPath'."
    }

    try {
        $attributes = [IO.File]::GetAttributes($fullPath)
    }
    catch {
        throw "Required AppX cache executable or script is missing: '$fullPath'."
    }
    if (($attributes -band [IO.FileAttributes]::Directory) -ne 0 -or
        ($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "AppX cache executable or script is not a normal file: '$fullPath'."
    }
    return $fullPath
}

function Get-AtlasAppxCacheIdentityEvidence {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ($null -eq $identity -or $null -eq $identity.User) {
        throw 'The AppX cache child has no Windows account identity.'
    }
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        $sid = $identity.User.Value
        $profileKeyPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
        $profileKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($profileKeyPath)
        if ($null -eq $profileKey) {
            throw "The current AppX cache user has no registered profile for SID '$sid'."
        }
        try {
            $registeredProfile = [string]$profileKey.GetValue(
                'ProfileImagePath',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
        }
        finally {
            $profileKey.Close()
        }
        if ([string]::IsNullOrWhiteSpace($registeredProfile)) {
            throw "The current AppX cache user has an empty registered profile path."
        }

        return [pscustomobject]@{
            UserSid              = $sid
            IsAdministrator      = $principal.IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator
            )
            ProfileRoot          = [Environment]::GetFolderPath(
                [Environment+SpecialFolder]::UserProfile
            )
            RegisteredProfileRoot = [Environment]::ExpandEnvironmentVariables($registeredProfile)
        }
    }
    finally {
        $identity.Dispose()
    }
}

function Assert-AtlasAppxCacheUserIdentity {
    param(
        [Parameter(Mandatory = $true)][string]$ExpectedUserSid,
        [scriptblock]$EvidenceReader = { Get-AtlasAppxCacheIdentityEvidence }
    )

    $expectedSid = ConvertTo-AtlasAppxCacheSid -Value $ExpectedUserSid `
        -Label 'Expected AppX cache user SID'
    $evidenceValues = @(& $EvidenceReader)
    if ($evidenceValues.Count -ne 1 -or $null -eq $evidenceValues[0]) {
        throw 'The AppX cache identity reader must return exactly one identity.'
    }
    $evidence = $evidenceValues[0]
    foreach ($propertyName in @(
            'UserSid', 'IsAdministrator', 'ProfileRoot', 'RegisteredProfileRoot'
        )) {
        if ($evidence.PSObject.Properties.Name -notcontains $propertyName) {
            throw "The AppX cache identity is missing '$propertyName'."
        }
    }

    $actualSid = ConvertTo-AtlasAppxCacheSid -Value ([string]$evidence.UserSid) `
        -Label 'Actual AppX cache child SID'
    if (-not $actualSid.Equals($expectedSid, [StringComparison]::Ordinal)) {
        throw 'The AppX cache child SID differs from the install-state-bound user.'
    }
    if ($evidence.IsAdministrator -isnot [bool] -or [bool]$evidence.IsAdministrator) {
        throw 'The AppX cache child is not an exact unelevated user process.'
    }

    foreach ($pathValue in @(
            [string]$evidence.ProfileRoot, [string]$evidence.RegisteredProfileRoot
        )) {
        if ([string]::IsNullOrWhiteSpace($pathValue) -or -not [IO.Path]::IsPathRooted($pathValue)) {
            throw 'The AppX cache identity contains an invalid profile path.'
        }
    }
    $profileRoot = [IO.Path]::GetFullPath([string]$evidence.ProfileRoot)
    $registeredProfileRoot = [IO.Path]::GetFullPath([string]$evidence.RegisteredProfileRoot)
    if (-not $profileRoot.Equals($registeredProfileRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The shell user profile differs from the protected SID-to-profile registration.'
    }
    return $profileRoot
}

function Get-AtlasAppxCacheCurrentSessionId {
    param(
        [scriptblock]$ProcessReader = { [Diagnostics.Process]::GetCurrentProcess() }
    )

    $processValues = @(& $ProcessReader)
    if ($processValues.Count -ne 1 -or $null -eq $processValues[0]) {
        throw 'The AppX cache current-process reader must return exactly one process.'
    }
    $currentProcess = $processValues[0]
    try {
        if ($currentProcess.PSObject.Properties.Name -notcontains 'SessionId') {
            throw 'The AppX cache child process has no Windows session identity.'
        }
        $sessionId = [int]$currentProcess.SessionId
    }
    catch {
        throw "The AppX cache child could not read its Windows session identity: $($_.Exception.Message)"
    }
    finally {
        if ($currentProcess -is [IDisposable]) {
            $currentProcess.Dispose()
        }
    }

    if ($sessionId -lt 1) {
        throw 'AppX cache cleanup requires a nonzero interactive Windows session.'
    }
    return $sessionId
}

function Get-AtlasAppxCachePattern {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('AppxSupport', 'StartMenu')]
        [string]$Mode
    )

    if ($Mode -eq 'AppxSupport') {
        return @(
            '*MicrosoftWindows.Client.CBS*'
            '*Microsoft.Windows.Search*'
            '*Microsoft.Windows.SecHealthUI*'
        )
    }
    return @('Microsoft.Windows.StartMenuExperienceHost*')
}

function Get-AtlasAppxCacheChildDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Parent,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$ContainmentRoot
    )

    foreach ($directory in @([IO.Directory]::GetDirectories(
                $Parent,
                $Pattern,
                [IO.SearchOption]::TopDirectoryOnly
            ))) {
        Resolve-AtlasAppxCacheNormalDirectory -Path $directory `
            -ContainmentRoot $ContainmentRoot -ExpectedParent $Parent
    }
}

function Stop-AtlasAppxPackageProcess {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private fixed-policy helper is already inside a checked, noninteractive cleanup operation.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 2147483647)]
        [int]$SessionId
    )

    $packageRoot = Resolve-AtlasAppxCacheNormalDirectory -Path $PackageDirectory `
        -ContainmentRoot $PackageDirectory -AllowRoot
    foreach ($exePath in @([IO.Directory]::GetFiles(
                $packageRoot,
                '*.exe',
                [IO.SearchOption]::TopDirectoryOnly
            ))) {
        $exeName = [IO.Path]::GetFileNameWithoutExtension($exePath)
        foreach ($process in @(Get-Process -Name $exeName -ErrorAction SilentlyContinue)) {
            try {
                # Keep the exact object returned by Get-Process and reject other logon
                # sessions before consulting its executable path or passing it to the sink.
                if ([int]$process.SessionId -ne $SessionId) { continue }
                if ([string]::IsNullOrWhiteSpace([string]$process.Path)) { continue }
                $processPath = [IO.Path]::GetFullPath([string]$process.Path)
                if (Test-AtlasAppxCachePathContained -Root $packageRoot -Candidate $processPath) {
                    Stop-Process -InputObject $process -Force -ErrorAction Stop
                    $waitCompleted = $process.WaitForExit(5000)
                    if (-not $waitCompleted -or -not [bool]$process.HasExited) {
                        throw "Package process '$($process.ProcessName)' did not exit within 5 seconds."
                    }
                }
            }
            catch {
                # A target can exit naturally between enumeration and the stop sink.
                # Treat that as the same proven postcondition; all other failures abort.
                $alreadyExited = try { [bool]$process.HasExited } catch { $false }
                if ($alreadyExited) { continue }
                throw "Couldn't stop package process '$($process.ProcessName)': $($_.Exception.Message)"
            }
        }
    }
}

function Clear-AtlasAppxDirectoryContent {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$ContainmentRoot,
        [string]$ExcludeFileName,
        [ValidateRange(1, 100000)][int]$MaximumEntries = 100000
    )

    $target = Resolve-AtlasAppxCacheNormalDirectory -Path $Directory `
        -ContainmentRoot $ContainmentRoot -AllowMissing
    if ($null -eq $target) { return }

    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $filesToDelete = New-Object 'System.Collections.Generic.List[string]'
    $directoriesToDelete = New-Object 'System.Collections.Generic.List[string]'
    $pending.Push($target)
    $entryCount = 0

    # Preflight the complete tree before the first deletion. A static reparse point therefore
    # leaves the cache byte-for-byte untouched instead of causing partial cleanup.
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        $null = Resolve-AtlasAppxCacheNormalDirectory -Path $current `
            -ContainmentRoot $target -AllowRoot
        foreach ($entry in @([IO.Directory]::GetFileSystemEntries($current))) {
            $entryCount++
            if ($entryCount -gt $MaximumEntries) {
                throw "AppX cache deletion tree exceeds $MaximumEntries entries."
            }
            $fullPath = [IO.Path]::GetFullPath($entry)
            if (-not (Test-AtlasAppxCachePathContained -Root $target -Candidate $fullPath)) {
                throw "AppX cache entry escaped its deletion root: '$fullPath'."
            }
            $attributes = [IO.File]::GetAttributes($fullPath)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "AppX cache deletion tree contains a reparse point: '$fullPath'."
            }
            if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) {
                $directoriesToDelete.Add($fullPath)
                $pending.Push($fullPath)
                continue
            }
            if ($ExcludeFileName -and
                $current.Equals($target, [StringComparison]::OrdinalIgnoreCase) -and
                [IO.Path]::GetFileName($fullPath).Equals(
                    $ExcludeFileName,
                    [StringComparison]::OrdinalIgnoreCase
                )) {
                continue
            }
            $filesToDelete.Add($fullPath)
        }
    }

    foreach ($filePath in $filesToDelete) {
        if (-not [IO.File]::Exists($filePath)) {
            if ([IO.Directory]::Exists($filePath)) {
                throw "AppX cache file changed into a directory: '$filePath'."
            }
            continue
        }
        $attributes = [IO.File]::GetAttributes($filePath)
        if (($attributes -band ([IO.FileAttributes]::Directory -bor
                    [IO.FileAttributes]::ReparsePoint)) -ne 0) {
            throw "AppX cache file changed type before deletion: '$filePath'."
        }
        [IO.File]::Delete($filePath)
    }

    foreach ($directoryPath in @($directoriesToDelete | Sort-Object Length -Descending)) {
        if (-not [IO.Directory]::Exists($directoryPath)) {
            if ([IO.File]::Exists($directoryPath)) {
                throw "AppX cache directory changed into a file: '$directoryPath'."
            }
            continue
        }
        $attributes = [IO.File]::GetAttributes($directoryPath)
        if (($attributes -band [IO.FileAttributes]::Directory) -eq 0 -or
            ($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "AppX cache directory changed type before deletion: '$directoryPath'."
        }
        if (@([IO.Directory]::GetFileSystemEntries($directoryPath)).Count -ne 0) {
            throw "AppX cache directory changed after preflight: '$directoryPath'."
        }
        [IO.Directory]::Delete($directoryPath, $false)
    }
}

function Clear-AtlasAppxCacheForProfile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('AppxSupport', 'StartMenu')]
        [string]$Mode,

        [Parameter(Mandatory = $true)][string]$ProfileRoot,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 2147483647)]
        [int]$SessionId
    )

    $profileRootPath = Resolve-AtlasAppxCacheNormalDirectory -Path $ProfileRoot `
        -ContainmentRoot $ProfileRoot -AllowRoot
    $appData = Resolve-AtlasAppxCacheNormalDirectory `
        -Path ([IO.Path]::Combine($profileRootPath, 'AppData')) `
        -ContainmentRoot $profileRootPath -ExpectedParent $profileRootPath -AllowMissing
    if ($null -eq $appData) { return }
    $localAppData = Resolve-AtlasAppxCacheNormalDirectory `
        -Path ([IO.Path]::Combine($appData, 'Local')) `
        -ContainmentRoot $profileRootPath -ExpectedParent $appData -AllowMissing
    if ($null -eq $localAppData) { return }
    $packagesRoot = Resolve-AtlasAppxCacheNormalDirectory `
        -Path ([IO.Path]::Combine($localAppData, 'Packages')) `
        -ContainmentRoot $profileRootPath -ExpectedParent $localAppData -AllowMissing
    if ($null -eq $packagesRoot) { return }

    foreach ($pattern in @(Get-AtlasAppxCachePattern -Mode $Mode)) {
        # Process stopping runs in the same exact unelevated token. Package installation
        # locations are never deletion roots.
        foreach ($package in @(Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$package.InstallLocation) -and
                [IO.Path]::IsPathRooted([string]$package.InstallLocation)) {
                Stop-AtlasAppxPackageProcess -PackageDirectory ([string]$package.InstallLocation) `
                    -SessionId $SessionId
            }
        }

        foreach ($packageDirectory in @(Get-AtlasAppxCacheChildDirectory `
                    -Parent $packagesRoot -Pattern $pattern -ContainmentRoot $profileRootPath)) {
            Clear-AtlasAppxDirectoryContent `
                -Directory ([IO.Path]::Combine($packageDirectory, 'TempState')) `
                -ContainmentRoot $packageDirectory

            $localState = Resolve-AtlasAppxCacheNormalDirectory `
                -Path ([IO.Path]::Combine($packageDirectory, 'LocalState')) `
                -ContainmentRoot $packageDirectory -ExpectedParent $packageDirectory -AllowMissing
            if ($null -eq $localState) { continue }
            foreach ($cacheDirectory in @(Get-AtlasAppxCacheChildDirectory `
                        -Parent $localState -Pattern '*Cache*' `
                        -ContainmentRoot $packageDirectory)) {
                Clear-AtlasAppxDirectoryContent -Directory $cacheDirectory `
                    -ContainmentRoot $packageDirectory -ExcludeFileName 'SettingsCache.txt'
            }
        }
    }
}

function Clear-AtlasAppxCache {
    <#
    .SYNOPSIS
        Clears only the exact install-state-bound current user's fixed AppX cache groups.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('AppxSupport', 'StartMenu')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedUserSid
    )

    $profileRoot = Assert-AtlasAppxCacheUserIdentity -ExpectedUserSid $ExpectedUserSid
    # Read the child process session only after SID and profile registration have
    # been validated. Every package-process sink receives this nonzero binding.
    $sessionId = Get-AtlasAppxCacheCurrentSessionId
    Clear-AtlasAppxCacheForProfile -Mode $Mode -ProfileRoot $profileRoot `
        -SessionId $sessionId
}

function Invoke-AtlasUserAppxCacheCleanupCore {
    param(
        [Parameter(Mandatory = $true)][psobject]$Context,
        [Parameter(Mandatory = $true)]
        [ValidateSet('AppxQuiesce', 'AppxSupport', 'StartMenu')]
        [string]$Mode,
        [Parameter(Mandatory = $true)][scriptblock]$Launcher
    )

    if ($Context.IsInstallStateBacked -isnot [bool] -or -not [bool]$Context.IsInstallStateBacked) {
        throw 'AppX user cache cleanup requires active Atlas install state.'
    }
    if ($Context.IsOobe -isnot [bool]) {
        throw 'The install state has an invalid OOBE value for AppX cache cleanup.'
    }
    if ([bool]$Context.IsOobe) {
        return 0
    }

    $expectedSid = ConvertTo-AtlasAppxCacheSid -Value ([string]$Context.InteractiveUserSid) `
        -Label 'Install-state AppX cache user SID'
    if ([string]::IsNullOrWhiteSpace([string]$Context.WinDir) -or
        -not [IO.Path]::IsPathRooted([string]$Context.WinDir) -or
        [string]::IsNullOrWhiteSpace([string]$Context.AtlasModulesPath) -or
        -not [IO.Path]::IsPathRooted([string]$Context.AtlasModulesPath)) {
        throw 'The install state has invalid paths for AppX cache cleanup.'
    }

    $windowsPath = [IO.Path]::GetFullPath([string]$Context.WinDir)
    $modulesPath = [IO.Path]::GetFullPath([string]$Context.AtlasModulesPath)
    $expectedModulesPath = [IO.Path]::Combine($windowsPath, 'AtlasModules')
    if (-not $modulesPath.Equals($expectedModulesPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The AppX cache helper path is outside the protected Windows payload root.'
    }
    $powerShellPath = Resolve-AtlasAppxCacheNormalFile `
        -Path ([IO.Path]::Combine(
            $windowsPath, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe'
        )) -ContainmentRoot $windowsPath
    $scriptPath = Resolve-AtlasAppxCacheNormalFile `
        -Path ([IO.Path]::Combine(
            $modulesPath, 'Scripts', 'Internal', 'Clear-AtlasUserAppxCache.ps1'
        )) -ContainmentRoot $modulesPath
    $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ' +
        "-File `"$scriptPath`" -Mode $Mode -ExpectedUserSid $expectedSid"

    $results = @(& $Launcher $powerShellPath $arguments $windowsPath)
    if ($results.Count -ne 1 -or
        ($results[0] -isnot [int] -and $results[0] -isnot [long])) {
        throw 'The install-state-bound AppX cache launcher must return one integer exit code.'
    }
    $exitCode = [long]$results[0]
    if ($exitCode -lt [int]::MinValue -or $exitCode -gt [int]::MaxValue) {
        throw 'The install-state-bound AppX cache launcher returned an invalid exit code.'
    }
    if ([int]$exitCode -ne 0) {
        throw "The install-state-bound AppX cache child failed with exit code $exitCode."
    }
    return [int]$exitCode
}

function Invoke-AtlasUserAppxCacheCleanup {
    <#
    .SYNOPSIS
        Launches fixed cache cleanup as the exact install-state-bound medium user.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('AppxQuiesce', 'AppxSupport', 'StartMenu')]
        [string]$Mode
    )

    if (-not (Test-AtlasSystem)) {
        throw '[privilege] AppX user cache cleanup must be launched from SYSTEM.'
    }
    $context = Get-AtlasContext
    $launcher = {
        param([string]$FilePath, [string]$Arguments, [string]$WorkingDirectory)
        Invoke-AtlasAsUser -FilePath $FilePath -Arguments $Arguments `
            -WorkingDirectory $WorkingDirectory -Wait $true -TimeoutSeconds 900
    }
    [void](Invoke-AtlasUserAppxCacheCleanupCore -Context $context -Mode $Mode `
            -Launcher $launcher)
    if ([bool]$context.IsOobe) {
        Write-AtlasLog -Message "Skipped $Mode AppX user cache cleanup during OOBE."
        return
    }
    if ($Mode -ceq 'AppxQuiesce') {
        Write-AtlasLog -Message 'Quiesced AppX package processes for the install-state-bound user.'
    }
    else {
        Write-AtlasLog -Message "Cleared $Mode AppX caches for the install-state-bound user."
    }
}
