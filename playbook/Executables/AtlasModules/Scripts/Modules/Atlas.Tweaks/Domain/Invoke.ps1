# Atlas.Tweaks domain: tweak application.
#
# A tweak is a data-only .psd1 (see Scripts\Tweaks\README.md for the schema). Keys are
# applied in a fixed order. Required work fails immediately; only entries that
# explicitly declare IgnoreErrors remain best-effort.

function Get-AtlasTweakEntryValue {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Entry,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [object]$Default
    )

    if ($Entry.ContainsKey($Key) -and $null -ne $Entry[$Key]) {
        return $Entry[$Key]
    }

    return $Default
}

function Test-AtlasArchMatch {
    # Private twin of the Atlas.Registry architecture gate.
    param(
        [string]$Arch,

        [Parameter(Mandatory = $true)]
        [bool]$IsArm64
    )

    if ([string]::IsNullOrEmpty($Arch)) {
        return $true
    }

    switch ($Arch.ToUpperInvariant()) {
        'ARM64' { return $IsArm64 }
        'X64' { return -not $IsArm64 }
        default { throw "Unknown architecture gate '$Arch' (expected 'X64' or 'ARM64')." }
    }
}

function Get-AtlasTweakUserSid {
    param([Parameter(Mandatory = $true)][object]$Context)

    if (-not $Context.IsInstallStateBacked -or $Context.IsOobe -or
        [string]::IsNullOrWhiteSpace([string]$Context.InteractiveUserSid)) {
        throw 'RunAs=User requires a non-OOBE install-state user SID.'
    }
    try {
        return (New-Object Security.Principal.SecurityIdentifier(
                [string]$Context.InteractiveUserSid
            )).Value
    }
    catch {
        throw "RunAs=User received an invalid install-state user SID '$($Context.InteractiveUserSid)'."
    }
}

function Invoke-AtlasTweakServiceEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    foreach ($entry in $Entries) {
        $ignoreErrors = [bool](Get-AtlasTweakEntryValue -Entry $entry -Key 'IgnoreErrors' -Default $false)
        try {
            $serviceName = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Name')
            if (-not $serviceName) {
                throw 'Service entry has no Name.'
            }

            $operation = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Operation' -Default 'Change')
            switch ($operation) {
                'Change' {
                    # Written straight to the service key because Set-Service cannot
                    # touch protected/driver services even as TrustedInstaller.
                    $startupType = Get-AtlasTweakEntryValue -Entry $entry -Key 'StartupType'
                    if ($null -eq $startupType -or [int]$startupType -lt 0 -or [int]$startupType -gt 4) {
                        throw "Service entry has no valid StartupType (expected 0-4, got '$startupType')."
                    }

                    $serviceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"
                    Set-ItemProperty -LiteralPath $serviceKey -Name 'Start' `
                        -Value ([int]$startupType) -Type DWord -Force -ErrorAction Stop
                }
                'Stop' {
                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                }
                'Start' {
                    Start-Service -Name $serviceName -ErrorAction Stop
                }
                default {
                    throw "Unknown service operation '$operation'."
                }
            }
        }
        catch {
            $entryName = Get-AtlasTweakEntryValue -Entry $entry -Key 'Name' -Default '<no name>'
            if ($ignoreErrors) {
                Write-AtlasLog -Message "Ignored service entry failure (service: '$entryName'): $($_.Exception.Message)" -Level Warning
                continue
            }
            throw
        }
    }
}

function Invoke-AtlasTweakScheduledTaskEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$WinDir
    )

    $schtasksPath = Join-Path -Path $WinDir -ChildPath 'System32\schtasks.exe'
    foreach ($entry in $Entries) {
        $ignoreErrors = [bool](Get-AtlasTweakEntryValue -Entry $entry -Key 'IgnoreErrors' -Default $false)
        try {
            $taskPath = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Path')
            if (-not $taskPath) {
                throw 'Scheduled task entry has no Path.'
            }

            $operation = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Operation' -Default 'Disable')
            $stateArgument = switch ($operation) {
                'Disable' { '/DISABLE' }
                'Enable' { '/ENABLE' }
                default { throw "Unknown scheduled task operation '$operation'." }
            }

            Invoke-AtlasHiddenProcess -FilePath $schtasksPath `
                -ArgumentList @('/Change', '/TN', $taskPath, $stateArgument) -Wait | Out-Null
        }
        catch {
            $entryPath = Get-AtlasTweakEntryValue -Entry $entry -Key 'Path' -Default '<no path>'
            if ($ignoreErrors) {
                Write-AtlasLog -Message "Ignored scheduled task entry failure (task: '$entryPath'): $($_.Exception.Message)" -Level Warning
                continue
            }
            throw
        }
    }
}

function Invoke-AtlasTweakRunEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [Parameter(Mandatory = $true)]
        [bool]$IsArm64,

        [Parameter(Mandatory = $true)]
        [string]$WinDir,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Context
    )

    foreach ($entry in $Entries) {
        $ignoreErrors = [bool](Get-AtlasTweakEntryValue -Entry $entry -Key 'IgnoreErrors' -Default $false)
        $runAs = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'RunAs' -Default '')

        try {
            $arch = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Arch' -Default '')
            if (-not (Test-AtlasArchMatch -Arch $arch -IsArm64 $IsArm64)) {
                continue
            }

            $exe = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Exe')
            if (-not $exe) {
                throw 'Run entry has no Exe.'
            }
            $exe = $exe -replace '\{windir\}', $WinDir

            $arguments = @()
            if ($entry.ContainsKey('Args')) {
                $arguments = @($entry['Args'])
                if ($entry['Args'] -isnot [array] -or
                    @($arguments | Where-Object { $_ -isnot [string] }).Count) {
                    throw 'Run entry Args must be an array of strings.'
                }
                $arguments = [string[]]@($arguments -replace '\{windir\}', $WinDir)
            }

            $allowedExitCodes = [int[]]@(0)
            if ($entry.ContainsKey('AllowedExitCodes')) {
                $dismPath = Join-Path -Path $WinDir -ChildPath 'System32\dism.exe'
                if ($runAs -or
                    -not [string]::Equals($exe, $dismPath, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "AllowedExitCodes is restricted to @(0, 3010) on '$dismPath'."
                }
                $allowedExitCodes = [int[]]@(0, 3010)
            }

            if (-not [string]::IsNullOrWhiteSpace($runAs)) {
                if ($runAs -cne 'User') {
                    throw "Run entry has unsupported RunAs '$runAs'."
                }
                $expectedUserSid = Get-AtlasTweakUserSid -Context $Context
                $arguments += @('-ExpectedUserSid', $expectedUserSid)
                $serializedArguments = ConvertTo-AtlasWindowsArgumentString `
                    -ArgumentList ([string[]]$arguments)
                $exitCode = Invoke-AtlasAsUser -FilePath $exe -Arguments $serializedArguments
                if ($exitCode -ne 0) {
                    throw "RunAs=User entry '$exe' exited with code $exitCode."
                }
                continue
            }

            Invoke-AtlasHiddenProcess -FilePath $exe `
                -ArgumentList ([string[]]$arguments) -Wait `
                -AllowedExitCode $allowedExitCodes | Out-Null
        }
        catch {
            if ($ignoreErrors -and [string]::IsNullOrWhiteSpace($runAs)) {
                $entryExe = Get-AtlasTweakEntryValue -Entry $entry -Key 'Exe' -Default '<no executable>'
                Write-AtlasLog -Message "Ignored Run entry failure (executable: '$entryExe'): $($_.Exception.Message)" -Level Warning
                continue
            }
            throw
        }
    }
}

function Invoke-AtlasTweakRemovePathEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [Parameter(Mandatory = $true)]
        [bool]$IsArm64,

        [Parameter(Mandatory = $true)]
        [string]$WinDir
    )

    $windowsRoot = [IO.Path]::GetFullPath($WinDir).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $windowsPrefix = $windowsRoot + [IO.Path]::DirectorySeparatorChar

    foreach ($entry in $Entries) {
        $ignoreErrors = [bool](Get-AtlasTweakEntryValue -Entry $entry -Key 'IgnoreErrors' -Default $false)
        try {
            $arch = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Arch' -Default '')
            if (-not (Test-AtlasArchMatch -Arch $arch -IsArm64 $IsArm64)) {
                continue
            }

            $declaredPath = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Path')
            if (-not $declaredPath) {
                throw 'RemovePaths entry has no Path.'
            }
            if (-not $declaredPath.StartsWith('{windir}\', [StringComparison]::OrdinalIgnoreCase)) {
                throw "RemovePaths entry '$declaredPath' must start with '{windir}\'."
            }

            $relativePath = $declaredPath.Substring('{windir}\'.Length)
            $targetPath = [IO.Path]::GetFullPath([IO.Path]::Combine($windowsRoot, $relativePath))
            if (-not $targetPath.StartsWith($windowsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                throw "RemovePaths entry '$declaredPath' resolves outside the Windows directory."
            }
            if (Test-Path -LiteralPath $targetPath) {
                Remove-Item -LiteralPath $targetPath -Recurse -Force -ErrorAction Stop
            }
        }
        catch {
            $entryPath = Get-AtlasTweakEntryValue -Entry $entry -Key 'Path' -Default '<no path>'
            if ($ignoreErrors) {
                Write-AtlasLog -Message "Ignored RemovePaths entry failure (path: '$entryPath'): $($_.Exception.Message)" -Level Warning
                continue
            }
            throw
        }
    }
}

function Invoke-AtlasTweak {
    <#
    .SYNOPSIS
        Loads a tweak .psd1, checks its gates and applies its keys in order: Registry,
        Services, ScheduledTasks, Run, RemovePaths, then the companion Script.
        Every required sub-step failure is fatal; individual entries may opt into
        reviewed best-effort behavior with IgnoreErrors.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateSet('All', 'Machine', 'CurrentUser', 'DefaultUser')]
        [string]$RegistryScope = 'All',

        [switch]$RegistryOnly,

        [psobject]$Context
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Tweak file not found: '$Path'."
    }

    $tweak = Import-AtlasDataFile -LiteralPath $Path
    if (-not $tweak.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace([string]$tweak['Name'])) {
        throw "Tweak file '$Path' has no 'Name' key."
    }

    $tweakName = [string]$tweak['Name']
    if (-not $PSBoundParameters.ContainsKey('Context')) {
        $Context = Get-AtlasContext
    }
    $skipReason = Get-AtlasTweakSkipReason -Tweak $tweak -Context $Context
    if ($skipReason) {
        Write-AtlasLog -Message "Skipping tweak '$tweakName': $skipReason."
        return
    }

    Write-AtlasLog -Message "Applying tweak '$tweakName'."

    if ($tweak.ContainsKey('Registry') -and $tweak['Registry']) {
        Invoke-AtlasRegistryEntries -Entries $tweak['Registry'] `
            -Scope $RegistryScope -StopOnError -IsArm64 ([bool]$Context.IsArm64)
    }

    if ($RegistryOnly) {
        return
    }

    if ($tweak.ContainsKey('Services') -and $tweak['Services']) {
        Invoke-AtlasTweakServiceEntries -Entries $tweak['Services']
    }

    if ($tweak.ContainsKey('ScheduledTasks') -and $tweak['ScheduledTasks']) {
        Invoke-AtlasTweakScheduledTaskEntries -Entries $tweak['ScheduledTasks'] `
            -WinDir ([string]$Context.WinDir)
    }

    if ($tweak.ContainsKey('Run') -and $tweak['Run']) {
        Invoke-AtlasTweakRunEntries -Entries $tweak['Run'] -IsArm64 ([bool]$Context.IsArm64) `
            -WinDir ([string]$Context.WinDir) -Context $Context
    }

    if ($tweak.ContainsKey('RemovePaths') -and $tweak['RemovePaths']) {
        Invoke-AtlasTweakRemovePathEntries -Entries $tweak['RemovePaths'] `
            -IsArm64 ([bool]$Context.IsArm64) -WinDir ([string]$Context.WinDir)
    }

    if ($tweak.ContainsKey('Script') -and $tweak['Script']) {
        $scriptPath = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath ([string]$tweak['Script'])
        $runAs = [string](Get-AtlasTweakEntryValue -Entry $tweak -Key 'RunAs' -Default '')
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            throw "Tweak '$tweakName': companion script '$scriptPath' is missing."
        }

        if ([string]::IsNullOrWhiteSpace($runAs)) {
            & $scriptPath
            return
        }
        if ($runAs -cne 'User') {
            throw "Tweak '$tweakName' has unsupported companion RunAs '$runAs'."
        }
        if ($Context.IsOobe) {
            Write-AtlasLog -Message "Skipping tweak '$tweakName' RunAs=User companion during OOBE."
            return
        }

        $expectedUserSid = Get-AtlasTweakUserSid -Context $Context
        $arguments = ConvertTo-AtlasWindowsArgumentString -ArgumentList @(
            '-NoProfile', '-NoLogo', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath,
            '-ExpectedUserSid', $expectedUserSid
        )
        $powerShellPath = Join-Path -Path $Context.WinDir `
            -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath -Arguments $arguments
        if ($exitCode -ne 0) {
            throw "Tweak '$tweakName' companion script (RunAs=$runAs) exited with code $exitCode."
        }
    }
}

function Invoke-AtlasTweakCategory {
    <#
    .SYNOPSIS
        Applies every tweak of a manifest category in order. A missing or failing tweak
        is fatal; individual entries must declare IgnoreErrors to be best-effort.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TweaksRoot,

        [ValidateSet('All', 'Machine', 'CurrentUser', 'DefaultUser')]
        [string]$RegistryScope = 'All',

        [switch]$RegistryOnly,

        [psobject]$Context
    )

    if ($null -eq $Context) {
        $Context = Get-AtlasContext
    }
    if (-not $TweaksRoot) {
        $TweaksRoot = Join-Path -Path $Context.AtlasModulesPath -ChildPath 'Scripts\Tweaks'
    }

    $manifest = Get-AtlasTweakManifest -Path (Join-Path -Path $TweaksRoot -ChildPath 'tweaks.manifest.psd1')

    $category = $manifest['Categories'] |
        Where-Object { [string]$_['Name'] -ceq $Name } | Select-Object -First 1
    if ($null -eq $category) {
        throw "Category '$Name' is not defined in the tweak manifest."
    }

    $tweakNames = @($category['Tweaks'])
    $categoryRoot = Join-Path -Path $TweaksRoot -ChildPath $Name

    Write-AtlasLog -Message "Applying tweak category '$Name' ($(@($tweakNames).Count) tweak(s))."

    foreach ($tweakName in $tweakNames) {
        $relativePath = ([string]$tweakName -replace '/', '\') + '.psd1'
        $tweakFile = Join-Path -Path $categoryRoot -ChildPath $relativePath

        Invoke-AtlasTweak -Path $tweakFile -RegistryScope $RegistryScope `
            -RegistryOnly:$RegistryOnly -Context $Context
    }
}

function Get-AtlasTweakCategoryPostUserRegistryRefresh {
    <#
    .SYNOPSIS
        Returns the ordered, de-duplicated post-live-HKCU shell refresh operations
        declared by applicable definitions in one tweak category.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TweaksRoot,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context
    )

    if (-not $TweaksRoot) {
        if ($null -eq $Context.PSObject.Properties['AtlasModulesPath'] -or
            [string]::IsNullOrWhiteSpace([string]$Context.AtlasModulesPath)) {
            throw 'Post-user-registry refresh resolution requires a protected AtlasModulesPath.'
        }
        $TweaksRoot = Join-Path -Path ([string]$Context.AtlasModulesPath) -ChildPath 'Scripts\Tweaks'
    }

    $manifest = Get-AtlasTweakManifest `
        -Path (Join-Path -Path $TweaksRoot -ChildPath 'tweaks.manifest.psd1')
    $category = $manifest['Categories'] |
        Where-Object { [string]$_['Name'] -ceq $Name } | Select-Object -First 1
    if ($null -eq $category) {
        throw "Category '$Name' is not defined in the tweak manifest."
    }

    $categoryRoot = Join-Path -Path $TweaksRoot -ChildPath $Name
    $operations = @()
    foreach ($tweakName in @($category['Tweaks'])) {
        $relativePath = ([string]$tweakName -replace '/', '\') + '.psd1'
        $tweakPath = Join-Path -Path $categoryRoot -ChildPath $relativePath
        $tweak = Import-AtlasDataFile -LiteralPath $tweakPath
        if ($null -ne (Get-AtlasTweakSkipReason -Tweak $tweak -Context $Context) -or
            -not $tweak.ContainsKey('PostUserRegistryRefresh')) {
            continue
        }

        $operation = [string]$tweak['PostUserRegistryRefresh']
        if ($script:AtlasTweakPostUserRegistryRefreshOperations -cnotcontains $operation) {
            throw "Tweak '$Name/$tweakName' has invalid PostUserRegistryRefresh operation '$operation'."
        }
        if ($operations -cnotcontains $operation) {
            $operations += $operation
        }
    }

    return $operations
}
