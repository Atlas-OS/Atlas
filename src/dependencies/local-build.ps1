Param(
    [switch]$AddLiveLog,
    [switch]$ReplaceOldPlaybook,
    [switch]$DontOpenPbLocation,
    [switch]$NoPassword,
    [ValidateSet('Dependencies', 'Requirements', 'WinverRequirement', 'Verification', IgnoreCase = $true)]
    [string[]]$Removals,
    [string]$FileName = 'Atlas Test'
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$removeDependencies = $false
$removeRequirements = $false
$removeWinverRequirement = $false
$removeVerification = $false
# track build time cuz why not
$buildStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if ($Removals) {
    foreach ($removal in $Removals) {
        switch ($removal.ToLowerInvariant()) {
            'dependencies' { $removeDependencies = $true }
            'requirements' { $removeRequirements = $true }
            'winverrequirement' { $removeWinverRequirement = $true }
            'verification' { $removeVerification = $true }
        }
    }
}

$runtimeInformation = [System.Runtime.InteropServices.RuntimeInformation]
$osPlatform = [System.Runtime.InteropServices.OSPlatform]
$IsWindowsPlatform = $runtimeInformation::IsOSPlatform($osPlatform::Windows)
$IsLinuxPlatform = $runtimeInformation::IsOSPlatform($osPlatform::Linux)
$IsMacOSPlatform = $runtimeInformation::IsOSPlatform($osPlatform::OSX)
# lazy temp staging so we only touch disk when needed
$rootTempDir = $null
$playbookTempPath = $null
$filesListPath = $null

# create temp playbook tree only when we patch files
function Get-PlaybookTempPath {
    if (-not $script:rootTempDir) {
        $script:rootTempDir = New-TemporaryDirectory
        $script:playbookTempPath = Join-Path -Path $script:rootTempDir.FullName -ChildPath 'playbook'
        New-Item -ItemType Directory -Path $script:playbookTempPath -Force | Out-Null
    }

    return $script:playbookTempPath
}

function Set-ParentDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Resolve-SevenZipPath {
    # look for 7-zip or nanazip, fall back to the installed copy on windows
    $candidates = @('7z', '7zz')

    foreach ($candidate in $candidates) {
        $commandInfo = Get-Command -Name $candidate -ErrorAction SilentlyContinue
        if ($commandInfo) {
            return $commandInfo.Source
        }
    }

    if ($IsWindowsPlatform) {
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')
        if ($programFiles) {
            $installedPath = Join-Path -Path $programFiles -ChildPath '7-Zip\7z.exe'
            if (Test-Path -LiteralPath $installedPath) {
                return $installedPath
            }
        }
    }

    throw 'This script requires 7-Zip or NanaZip to be installed to continue.'
}

function Invoke-SevenZip {
    param(
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [string]$ErrorContext = '7-Zip operation',
        [string]$ArchivePath
    )

    $previousErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $processOutput = & $script:SevenZipPath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    $recovered = $false

    if ($ArchivePath) {
        # cleanup
        $archiveDirectory = Split-Path -Path $ArchivePath -Parent
        $archiveLeaf = Split-Path -Path $ArchivePath -Leaf
        $primaryTempPath = "$ArchivePath.tmp"

        $candidateItems = @()
        if (Test-Path -LiteralPath $primaryTempPath) {
            $candidateItems += Get-Item -LiteralPath $primaryTempPath
        }

        if ($archiveDirectory) {
            $additionalCandidates = Get-ChildItem -LiteralPath $archiveDirectory -Filter "$archiveLeaf.tmp*" -ErrorAction SilentlyContinue
            foreach ($item in $additionalCandidates) {
                if ($primaryTempPath -and ($item.FullName -eq $primaryTempPath)) {
                    continue
                }
                $candidateItems += $item
            }
        }

        if ($candidateItems) {
            $candidateItems = $candidateItems | Sort-Object LastWriteTime -Descending
            $targetName = $archiveLeaf

            foreach ($candidate in $candidateItems) {
                for ($attempt = 0; $attempt -lt 5 -and -not $recovered; $attempt++) {
                    try {
                        Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
                        Rename-Item -LiteralPath $candidate.FullName -NewName $targetName -Force
                        $recovered = $true
                        break
                    }
                    catch {
                        if ($attempt -eq 4) {
                            $warningMessage = "Failed to recover archive from temporary file '{0}': {1}" -f $candidate.FullName, $_.Exception.Message
                            Write-Warning $warningMessage
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }

                if ($recovered) {
                    break
                }
            }

            if (Test-Path -LiteralPath $ArchivePath) {
                foreach ($candidate in $candidateItems) {
                    if (Test-Path -LiteralPath $candidate.FullName) {
                        Remove-Item -LiteralPath $candidate.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }

    if ($exitCode -ne 0 -and $recovered) {
        $exitCode = 0
    }

    if ($exitCode -ne 0) {
        $message = "$ErrorContext failed with exit code $exitCode while executing '$script:SevenZipPath'."
        if ($processOutput) {
            $message += " Output:`n$($processOutput -join [Environment]::NewLine)"
        }
        throw $message
    }

    return $processOutput
}

function New-TemporaryDirectory {
    $tempPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)
    return New-Item -ItemType Directory -Path $tempPath -Force
}

function Get-AvailableArchiveName {
    param(
        [Parameter(Mandatory = $true)][string]$BaseName,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [switch]$AllowReplace
    )

    $candidate = $BaseName

    if ($AllowReplace -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        try {
            $archiveFullPath = [IO.Path]::Combine($WorkingDirectory, $candidate)
            $stream = [IO.File]::Open($archiveFullPath, 'Open', 'Read', 'Write')
            $stream.Close()
            Remove-Item -LiteralPath $candidate -Force
        }
        catch {
            Write-Warning "Couldn't replace '$candidate', it's in use."
            $AllowReplace = $false
        }
    }

    $counter = 1
    while ((-not $AllowReplace) -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $candidate = "{0} ({1}).apbx" -f $DisplayName, $counter
        $counter++
    }

    return $candidate
}

function Set-PowerShellModulesProfileEntry {
    $psEditorVariable = Get-Variable -Name psEditor -Scope Global -ErrorAction SilentlyContinue
    if (-not $psEditorVariable) {
        return
    }

    $psEditorValue = $psEditorVariable.Value
    if (-not $psEditorValue) {
        return
    }

    $workspacePath = $psEditorValue.Workspace.Path
    if (-not $workspacePath) {
        return
    }

    $userEnvTarget = [System.EnvironmentVariableTarget]::User
    if ([Environment]::GetEnvironmentVariable('LOCALBUILD_DONT_ASK_FOR_MODULES', $userEnvTarget) -eq "$true") {
        return
    }

    $title = 'Adding to PowerShell profile'
    $description = @"
Atlas includes some PowerShell modules by default that aren't usually recognised by the VSCode PowerShell extension.
Would you like to add to your PowerShell profile to automatically recognise these modules when developing Atlas?`n`n
"@

    $choice = $Host.UI.PromptForChoice($title, $description, ('&Yes', '&No', "&Don't ask me again"), 0)
    $setDontAsk = {
        [Environment]::SetEnvironmentVariable('LOCALBUILD_DONT_ASK_FOR_MODULES', $true, $userEnvTarget)
    }

    switch ($choice) {
        0 {
            if (-not (Test-Path -LiteralPath $PROFILE)) {
                Set-ParentDirectory -Path $PROFILE
                New-Item -Path $PROFILE -ItemType File -Force | Out-Null
            }

            $profileContent = if (Test-Path -LiteralPath $PROFILE) {
                Get-Content -Path $PROFILE -Raw -Encoding UTF8
            }
            else {
                ''
            }

            if ($profileContent -notmatch '#--LOCAL-BUILD-MODULES-START--#') {
                Add-Content -Path $PROFILE -Value @'
#--LOCAL-BUILD-MODULES-START--#
$workspace = $psEditor.Workspace.Path
$modulesFile = "$workspace\.atlasPsModulesPath"
if ([bool](Test-Path 'Env:\VSCODE_*') -and (Test-Path $workspace -EA 0) -and (Test-Path $modulesFile -EA 0)) {
    $modulePath = Join-Path $workspace (Get-Content $modulesFile -Raw)
    if (!(Test-Path $modulePath -PathType Container)) {
        Write-Warning "Couldn't find module path specified in '$modulesFile', no Atlas modules can be loaded."
    } else {
        $env:PSModulePath += [IO.Path]::PathSeparator + $modulePath
    }
}
#--LOCAL-BUILD-MODULES-END--#
'@
            }

            & $PROFILE
            & $setDontAsk
        }
        2 {
            & $setDontAsk
        }
    }
}

$script:SevenZipPath = Resolve-SevenZipPath
Set-PowerShellModulesProfileEntry

$enteredPlaybookDirectory = $false
$rootTempDir = $null

try {
    # make sure we actually sitting on a playbook
    if (-not (Test-Path -LiteralPath 'playbook.conf' -PathType Leaf)) {
        if (Test-Path -LiteralPath 'playbook' -PathType Container) {
            Push-Location -LiteralPath 'playbook'
            $enteredPlaybookDirectory = $true
            if (-not (Test-Path -LiteralPath 'playbook.conf' -PathType Leaf)) {
                throw 'playbook.conf file not found in playbook directory.'
            }
        }
        else {
            throw 'playbook.conf file not found in the current directory.'
        }
    }

    $currentLocation = Get-Location
    $workingDirectory = $currentLocation.ProviderPath

    $apbxFileName = Get-AvailableArchiveName -BaseName "$FileName.apbx" -WorkingDirectory $workingDirectory -DisplayName $FileName -AllowReplace:$ReplaceOldPlaybook.IsPresent
    $apbxPath = Join-Path -Path $workingDirectory -ChildPath $apbxFileName

    $playbookConfPatternTokens = @()
    if ($removeRequirements) { $playbookConfPatternTokens += '<Requirement>' }
    if ($removeWinverRequirement) { $playbookConfPatternTokens += '<string>', '</SupportedBuilds>', '<SupportedBuilds>' }
    if ($removeVerification) { $playbookConfPatternTokens += '<ProductCode>' }

    $stagedPlaybookConf = $false
    if ($playbookConfPatternTokens.Count -gt 0) {
        $playbookTempPath = Get-PlaybookTempPath
        $tempPlaybookConfPath = Join-Path -Path $playbookTempPath -ChildPath 'playbook.conf'
        $pattern = [string]::Join('|', $playbookConfPatternTokens)
        Get-Content -Path 'playbook.conf' -Encoding UTF8 | Where-Object { $_ -notmatch $pattern } | Set-Content -Path $tempPlaybookConfPath -Encoding UTF8
        $stagedPlaybookConf = Test-Path -LiteralPath $tempPlaybookConfPath
    }

    $customYmlRelativePath = Join-Path -Path 'Configuration' -ChildPath 'custom.yml'
    # copy custom.yml so we can sneak in live log entry without touching real file
    $stagedCustomYml = $false
    if ($AddLiveLog) {
        if (Test-Path -LiteralPath $customYmlRelativePath -PathType Leaf) {
            $playbookTempPath = Get-PlaybookTempPath
            $tempCustomYmlPath = Join-Path -Path $playbookTempPath -ChildPath $customYmlRelativePath
            Set-ParentDirectory -Path $tempCustomYmlPath
            Copy-Item -Path $customYmlRelativePath -Destination $tempCustomYmlPath -Force

            $customYml = Get-Content -Path $tempCustomYmlPath
            $actionsIndex = $customYml.IndexOf('actions:')
            if ($actionsIndex -ge 0) {
                $liveLogScript = {
                    $a = Join-Path (Get-ChildItem (Join-Path $([Environment]::GetFolderPath('CommonApplicationData')) '\AME\Logs') -Directory |
                        Sort-Object LastWriteTime -Descending |
                        Select-Object -First 1).FullName '\OutputBuffer.txt';
                    while ($true) { Get-Content -Wait -LiteralPath $a -EA 0 | Write-Output; Start-Sleep 1 }
                }
                $liveLogText = [string]$liveLogScript
                $liveLogText = $liveLogText -replace '"', '"""'
                $liveLogText = $liveLogText -replace "'", "''"
                $liveLogText = $liveLogText.Trim() -replace "`r?`n", ' '

                $liveLogAction = "  - !cmd: {command: 'start `"AME Wizard Live Log`" PowerShell -NoP -C `"$liveLogText`"'}"

                $preActions = @()
                if ($actionsIndex -ge 0) {
                    $preActions = $customYml[0..$actionsIndex]
                }

                $postActions = @()
                if ($actionsIndex + 1 -lt $customYml.Count) {
                    $postActions = $customYml[($actionsIndex + 1)..($customYml.Count - 1)]
                }

                $updatedCustomYml = @()
                $updatedCustomYml += $preActions
                $updatedCustomYml += $liveLogAction
                $updatedCustomYml += $postActions

                $updatedCustomYml | Set-Content -Path $tempCustomYmlPath -Encoding UTF8
                $stagedCustomYml = $true
            }
            else {
                Write-Warning "Can't find 'actions:' in '$customYmlRelativePath', not adding live log."
                Remove-Item -LiteralPath $tempCustomYmlPath -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Warning "Can't find '$customYmlRelativePath', not adding live log."
        }
    }

    $startYmlRelativePath = Join-Path -Path (Join-Path -Path 'Configuration' -ChildPath 'atlas') -ChildPath 'start.yml'
    # clone start.yml when we strip the dependency block for local builds
    $stagedStartYml = $false
    if ($removeDependencies) {
        if (Test-Path -LiteralPath $startYmlRelativePath -PathType Leaf) {
            $playbookTempPath = Get-PlaybookTempPath
            $tempStartYmlPath = Join-Path -Path $playbookTempPath -ChildPath $startYmlRelativePath
            Set-ParentDirectory -Path $tempStartYmlPath
            Copy-Item -Path $startYmlRelativePath -Destination $tempStartYmlPath -Force

            $startYmlContent = Get-Content -Path $tempStartYmlPath -Raw -Encoding UTF8
            $blockPattern = '  ################ NO LOCAL BUILD ################.*?  ################ END NO LOCAL BUILD ################\r?\n?'
            $updatedStartYml = [regex]::Replace($startYmlContent, $blockPattern, '', 'Singleline')

            if ($updatedStartYml -ne $startYmlContent) {
                Set-Content -Path $tempStartYmlPath -Value $updatedStartYml -Encoding UTF8
                $stagedStartYml = $true
            }
            else {
                Write-Warning "Couldn't find NO LOCAL BUILD block in '$startYmlRelativePath', not removing dependencies section."
                Remove-Item -LiteralPath $tempStartYmlPath -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Warning "Can't find '$startYmlRelativePath', not removing dependencies section."
        }
    }

    # update the oem version so the wizard displays the correct build tag
    $oemYmlRelativePath = Join-Path -Path (Join-Path -Path 'Configuration' -ChildPath 'tweaks') -ChildPath (Join-Path -Path 'misc' -ChildPath 'config-oem-information.yml')
    if (Test-Path -LiteralPath $oemYmlRelativePath -PathType Leaf) {
        try {
            $confXml = [xml](Get-Content -Path 'playbook.conf' -Raw -Encoding UTF8)
            $playbookNode = $confXml.Playbook

            if ($playbookNode -and $playbookNode.Version -match '^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$') {
                $versionLabel = "v$($playbookNode.Version)"
                if ($playbookNode.Title -match '\(dev\)') {
                    $versionLabel += ' (dev)'
                }

                $oemContent = Get-Content -Path $oemYmlRelativePath -Raw -Encoding UTF8
                $updatedOemContent = $oemContent -replace 'AtlasVersionUndefined', $versionLabel

                if ($updatedOemContent -ne $oemContent) {
                    $playbookTempPath = Get-PlaybookTempPath
                    $tempOemYmlPath = Join-Path -Path $playbookTempPath -ChildPath $oemYmlRelativePath
                    Set-ParentDirectory -Path $tempOemYmlPath
                    Set-Content -Path $tempOemYmlPath -Value $updatedOemContent -Encoding UTF8
                }
                else {
                    Write-Warning "Couldn't find OEM string 'AtlasVersionUndefined', not updating OEM version."
                }
            }
            else {
                Write-Warning "Invalid version format in 'playbook.conf', not setting OEM version."
            }
        }
        catch {
            Write-Warning "Failed to process OEM information: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Can't find '$oemYmlRelativePath', not setting OEM version."
    }

    # skip local script + staged overrides so we dont pack duplicates
    $excludeFiles = @('local-build.*', '*.apbx')
    if ($stagedCustomYml) { $excludeFiles += 'custom.yml' }
    if ($stagedStartYml) { $excludeFiles += 'start.yml' }
    if ($stagedPlaybookConf) { $excludeFiles += 'playbook.conf' }

    $filesListPath = [IO.Path]::GetTempFileName()
    $rootPathNormalized = $workingDirectory.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $rootPrefix = $rootPathNormalized + [IO.Path]::DirectorySeparatorChar

    $filesToInclude = Get-ChildItem -File -Exclude $excludeFiles -Recurse
    $relativePaths = foreach ($file in $filesToInclude) {
        $fullName = $file.FullName
        if ($fullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $relative = $fullName.Substring($rootPrefix.Length)
        }
        elseif ($fullName.StartsWith($rootPathNormalized, [StringComparison]::OrdinalIgnoreCase)) {
            $relative = $fullName.Substring($rootPathNormalized.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        }
        else {
            $relative = $file.Name
        }

        $relative = $relative -replace '\\', '/'

        $relative
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($filesListPath, $relativePaths, $utf8NoBom)

    $passwordArgs = @()
    if (-not $NoPassword) {
        $passwordArgs += '-pmalte'
    }

    # use store mode for speed and keep 7-zip output quiet
    $archiveArgs = @('a', '-tzip', '-y', '-mx1', '-bso0', '-bse0', '-bsp0')
    if ($IsWindowsPlatform) {
        $archiveArgs += '-spf'
    }
    $archiveArgs += $passwordArgs
    $archiveArgs += $apbxPath
    # dont add extra quotes around the @ syntax as it breaks 7z parser
    $archiveArgs += "@$filesListPath"

    Invoke-SevenZip -ArgumentList $archiveArgs -ErrorContext 'Creating APBX archive' -ArchivePath $apbxPath

    if ($playbookTempPath -and (Test-Path -LiteralPath $playbookTempPath)) {
        $stagedFiles = Get-ChildItem -Path $playbookTempPath -File -Recurse -ErrorAction SilentlyContinue
        if ($stagedFiles) {
            Push-Location -LiteralPath $playbookTempPath
            try {
                $updateArgs = @('u', '-bso0', '-bse0', '-bsp0')
                $updateArgs += $passwordArgs
                $updateArgs += $apbxPath
                $updateArgs += '*'

                Invoke-SevenZip -ArgumentList $updateArgs -ErrorContext 'Adding staged overrides' -ArchivePath $apbxPath
            }
            finally {
                Pop-Location
            }
        }
    }

    $apbxTmpPath = "$apbxPath.tmp"
    if (Test-Path -LiteralPath $apbxTmpPath) {
        Remove-Item -LiteralPath $apbxPath -Force -ErrorAction SilentlyContinue
        Rename-Item -LiteralPath $apbxTmpPath -NewName (Split-Path -Path $apbxPath -Leaf)
    }

    if ($buildStopwatch.IsRunning) {
        $buildStopwatch.Stop()
    }

    $elapsedSeconds = [Math]::Round($buildStopwatch.Elapsed.TotalSeconds, 2)
    Write-Host ("Built successfully in {0}s! Path: `"{1}`"" -f $elapsedSeconds, $apbxPath) -ForegroundColor Green

    if (-not $DontOpenPbLocation) {
        if (-not $IsWindowsPlatform) {
            Write-Warning "Can't open the APBX directory because the system isn't Windows."
        }
        else {
            try {
                # ping explorer to highlight the fresh build and close old windows
                $targetDirectory = Split-Path -Path $apbxPath
                $shellApp = New-Object -ComObject Shell.Application
                $matchingWindows = @()

                foreach ($window in $shellApp.Windows()) {
                    try {
                        $folderPath = $window.Document.Folder.Self.Path
                        if ($folderPath -and ($folderPath -eq $targetDirectory)) {
                            $matchingWindows += $window
                        }
                    }
                    catch {
                        continue
                    }
                }

                foreach ($window in $matchingWindows) {
                    try {
                        $window.Quit()
                    }
                    catch {
                        continue
                    }
                }
            }
            catch {
                Write-Warning "Unable to close existing File Explorer windows: $($_.Exception.Message)"
            }

            Start-Process -FilePath 'explorer.exe' -ArgumentList "/select,`"$apbxPath`""
        }
    }
}
finally {
    if ($filesListPath -and (Test-Path -LiteralPath $filesListPath)) {
        Remove-Item -LiteralPath $filesListPath -Force -ErrorAction SilentlyContinue
    }

    if ($rootTempDir -and (Test-Path -LiteralPath $rootTempDir.FullName)) {
        Remove-Item -LiteralPath $rootTempDir.FullName -Force -Recurse -ErrorAction SilentlyContinue
    }

    if ($enteredPlaybookDirectory) {
        Pop-Location
    }

    if ($buildStopwatch.IsRunning) {
        $buildStopwatch.Stop()
    }

    $rootTempDir = $null
    $playbookTempPath = $null
    $filesListPath = $null
}
