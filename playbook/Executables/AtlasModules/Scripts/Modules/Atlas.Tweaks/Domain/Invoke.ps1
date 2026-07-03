# Atlas.Tweaks domain: tweak application.
#
# A tweak is a data-only .psd1 (see Scripts\Tweaks\README.md for the schema). Keys are
# applied in a fixed order and every sub-step is wrapped so a single failing entry logs
# a warning instead of aborting the tweak, and a failing tweak never aborts a category.

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

function Invoke-AtlasTweakServiceEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    foreach ($entry in $Entries) {
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
                    if (-not (Test-Path -LiteralPath $serviceKey)) {
                        Write-AtlasLog -Message "Service '$serviceName' does not exist; not changing its startup type." -Level Warning
                    }
                    else {
                        Set-ItemProperty -LiteralPath $serviceKey -Name 'Start' -Value ([int]$startupType) -Type DWord -Force
                    }
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
            Write-AtlasLog -Message "Service entry failed (service: '$entryName'): $($_.Exception.Message)" -Level Warning
        }
    }
}

function Invoke-AtlasTweakScheduledTaskEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    foreach ($entry in $Entries) {
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

            $output = & schtasks.exe /Change /TN "$taskPath" $stateArgument 2>&1
            if ($LASTEXITCODE -eq 1) {
                Write-AtlasLog -Message "Scheduled task '$taskPath' was not found; nothing to $($operation.ToLowerInvariant())." -Level Warning
            }
            elseif ($LASTEXITCODE -ne 0) {
                $details = (@($output) | ForEach-Object { "$_" }) -join ' '
                throw "schtasks.exe exited with code $LASTEXITCODE - $details"
            }
        }
        catch {
            $entryPath = Get-AtlasTweakEntryValue -Entry $entry -Key 'Path' -Default '<no path>'
            Write-AtlasLog -Message "Scheduled task entry failed (task: '$entryPath'): $($_.Exception.Message)" -Level Warning
        }
    }
}

function Invoke-AtlasTweakRunEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [Parameter(Mandatory = $true)]
        [bool]$IsArm64
    )

    foreach ($entry in $Entries) {
        $ignoreErrors = [bool](Get-AtlasTweakEntryValue -Entry $entry -Key 'IgnoreErrors' -Default $false)

        try {
            $arch = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Arch' -Default '')
            if (-not (Test-AtlasArchMatch -Arch $arch -IsArm64 $IsArm64)) {
                continue
            }

            $exe = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Exe')
            if (-not $exe) {
                throw 'Run entry has no Exe.'
            }

            $wait = [bool](Get-AtlasTweakEntryValue -Entry $entry -Key 'Wait' -Default $true)
            $arguments = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Args' -Default '')

            $startParams = @{
                FilePath = $exe
                PassThru = $true
            }
            if ($arguments) {
                $startParams['ArgumentList'] = $arguments
            }
            if ($wait) {
                $startParams['Wait'] = $true
                $startParams['NoNewWindow'] = $true
            }

            $process = Start-Process @startParams
            if ($wait) {
                # 3010 = ERROR_SUCCESS_REBOOT_REQUIRED (DISM and installers), still a success.
                $exitCode = $process.ExitCode
                if ($exitCode -ne 0 -and $exitCode -ne 3010) {
                    throw "'$exe' exited with code $exitCode."
                }
            }
        }
        catch {
            if ($ignoreErrors) {
                $null = $_
            }
            else {
                $entryExe = Get-AtlasTweakEntryValue -Entry $entry -Key 'Exe' -Default '<no exe>'
                Write-AtlasLog -Message "Run entry failed (exe: '$entryExe'): $($_.Exception.Message)" -Level Warning
            }
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

    foreach ($entry in $Entries) {
        try {
            $arch = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Arch' -Default '')
            if (-not (Test-AtlasArchMatch -Arch $arch -IsArm64 $IsArm64)) {
                continue
            }

            $targetPath = [string](Get-AtlasTweakEntryValue -Entry $entry -Key 'Path')
            if (-not $targetPath) {
                throw 'RemovePaths entry has no Path.'
            }

            $targetPath = $targetPath -replace '\{windir\}', $WinDir
            if (Test-Path -LiteralPath $targetPath) {
                Remove-Item -LiteralPath $targetPath -Recurse -Force -ErrorAction Stop
            }
        }
        catch {
            $entryPath = Get-AtlasTweakEntryValue -Entry $entry -Key 'Path' -Default '<no path>'
            Write-AtlasLog -Message "RemovePaths entry failed (path: '$entryPath'): $($_.Exception.Message)" -Level Warning
        }
    }
}

function Invoke-AtlasTweak {
    <#
    .SYNOPSIS
        Loads a tweak .psd1, checks its gates and applies its keys in order: Registry,
        Services, ScheduledTasks, StopProcesses, Run, RemovePaths, then the companion
        Script. Each sub-step failure is logged as a warning and processing continues.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Tweak file not found: '$Path'."
    }

    $tweak = Import-PowerShellDataFile -LiteralPath $Path
    if (-not $tweak.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace([string]$tweak['Name'])) {
        throw "Tweak file '$Path' has no 'Name' key."
    }

    $tweakName = [string]$tweak['Name']
    $skipReason = Get-AtlasTweakSkipReason -Tweak $tweak
    if ($skipReason) {
        Write-AtlasLog -Message "Skipping tweak '$tweakName': $skipReason."
        return
    }

    Write-AtlasLog -Message "Applying tweak '$tweakName'."
    $context = Get-AtlasContext

    if ($tweak.ContainsKey('Registry') -and $tweak['Registry']) {
        try {
            Invoke-AtlasRegistryEntries -Entries $tweak['Registry']
        }
        catch {
            Write-AtlasLog -Message "Tweak '$tweakName': Registry step failed: $($_.Exception.Message)" -Level Warning
        }
    }

    if ($tweak.ContainsKey('Services') -and $tweak['Services']) {
        try {
            Invoke-AtlasTweakServiceEntries -Entries $tweak['Services']
        }
        catch {
            Write-AtlasLog -Message "Tweak '$tweakName': Services step failed: $($_.Exception.Message)" -Level Warning
        }
    }

    if ($tweak.ContainsKey('ScheduledTasks') -and $tweak['ScheduledTasks']) {
        try {
            Invoke-AtlasTweakScheduledTaskEntries -Entries $tweak['ScheduledTasks']
        }
        catch {
            Write-AtlasLog -Message "Tweak '$tweakName': ScheduledTasks step failed: $($_.Exception.Message)" -Level Warning
        }
    }

    if ($tweak.ContainsKey('StopProcesses') -and $tweak['StopProcesses']) {
        try {
            foreach ($processName in @($tweak['StopProcesses'])) {
                Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-AtlasLog -Message "Tweak '$tweakName': StopProcesses step failed: $($_.Exception.Message)" -Level Warning
        }
    }

    if ($tweak.ContainsKey('Run') -and $tweak['Run']) {
        try {
            Invoke-AtlasTweakRunEntries -Entries $tweak['Run'] -IsArm64 ([bool]$context.IsArm64)
        }
        catch {
            Write-AtlasLog -Message "Tweak '$tweakName': Run step failed: $($_.Exception.Message)" -Level Warning
        }
    }

    if ($tweak.ContainsKey('RemovePaths') -and $tweak['RemovePaths']) {
        try {
            Invoke-AtlasTweakRemovePathEntries -Entries $tweak['RemovePaths'] -IsArm64 ([bool]$context.IsArm64) -WinDir ([string]$context.WinDir)
        }
        catch {
            Write-AtlasLog -Message "Tweak '$tweakName': RemovePaths step failed: $($_.Exception.Message)" -Level Warning
        }
    }

    if ($tweak.ContainsKey('Script') -and $tweak['Script']) {
        $scriptPath = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath ([string]$tweak['Script'])
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            Write-AtlasLog -Message "Tweak '$tweakName': companion script '$scriptPath' is missing." -Level Warning
        }
        else {
            try {
                & $scriptPath
            }
            catch {
                Write-AtlasLog -Message "Tweak '$tweakName': companion script failed: $($_.Exception.Message)" -Level Warning
            }
        }
    }
}

function Invoke-AtlasTweakCategory {
    <#
    .SYNOPSIS
        Applies every tweak of a manifest category in order. A missing tweak file or a
        failing tweak is logged as an error and the remaining tweaks still run.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TweaksRoot
    )

    if (-not $TweaksRoot) {
        $TweaksRoot = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Tweaks'
    }

    $manifest = Get-AtlasTweakManifest -Path (Join-Path -Path $TweaksRoot -ChildPath 'tweaks.manifest.psd1')

    $category = $null
    foreach ($candidate in @($manifest['Categories'])) {
        if ([string]$candidate['Name'] -eq $Name) {
            $category = $candidate
            break
        }
    }

    if ($null -eq $category) {
        throw "Category '$Name' is not defined in the tweak manifest."
    }

    $tweakNames = @()
    if ($category.ContainsKey('Tweaks') -and $category['Tweaks']) {
        $tweakNames = @($category['Tweaks'])
    }

    Write-AtlasLog -Message "Applying tweak category '$Name' ($(@($tweakNames).Count) tweak(s))."

    foreach ($tweakName in $tweakNames) {
        $relativePath = ([string]$tweakName -replace '/', '\') + '.psd1'
        $tweakFile = Join-Path -Path (Join-Path -Path $TweaksRoot -ChildPath $Name) -ChildPath $relativePath

        if (-not (Test-Path -LiteralPath $tweakFile -PathType Leaf)) {
            Write-AtlasLog -Message "Tweak file missing for '$Name/$tweakName': '$tweakFile'." -Level Error
            continue
        }

        try {
            Invoke-AtlasTweak -Path $tweakFile
        }
        catch {
            Write-AtlasLog -Message "Tweak '$Name/$tweakName' failed: $($_.Exception.Message)" -Level Error
        }
    }
}
