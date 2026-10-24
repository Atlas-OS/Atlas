[CmdletBinding()]
param(
    [switch]$Recover,
    [switch]$Discard,
    [switch]$LibraryOnly
)

Set-StrictMode -Version 3.0
$script:AtlasCbsRetryMutexName = 'Global\AtlasOS.CbsRetry'

function Get-AtlasCbsRetryStatePath {
    Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Recovery\CbsRetry.json'
}

function Get-AtlasCbsRetryLauncher {
    '"{0}"' -f (Join-Path ([Environment]::GetFolderPath('Windows')) `
            'AtlasModules\Scripts\Entry\Invoke-AtlasCbsRetry.cmd')
}

function Get-AtlasCbsRetryInstruction {
    <#
    .SYNOPSIS
        What to tell the user about a CBS retry in the given phase. Every message about
        the retry uses this or Get-AtlasCbsRetryLauncher, so they all name the same command.
    #>
    param([ValidateSet('Pending', 'Armed')][string]$Phase = 'Armed')

    $launcher = Get-AtlasCbsRetryLauncher
    if ($Phase -ceq 'Armed') {
        return "Windows starts in Safe Mode with Command Prompt until the retry is done. At that command prompt, run $launcher to retry the packages, or $launcher /discard to give up the retry."
    }
    return "Run $launcher /discard as an administrator to give up the retry and use Atlas's Safe Mode tools again."
}

function Get-AtlasCbsRetryPromptPaths {
    [pscustomobject]@{
        SavedPrompt    = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Recovery\CbsRetryPrompt.json'
        EnvironmentKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    }
}

function Set-AtlasCbsRetryPrompt {
    <#
    .SYNOPSIS
        Shows the retry's instruction at the Safe Mode command prompt. Safe Mode with
        Command Prompt starts only a bare program name as its shell: a command with
        arguments, or a script, gets the Explorer desktop instead. So cmd.exe stays the
        shell and the machine-wide PROMPT carries the instruction. The value it replaces
        is saved once, so arming again never saves Atlas's own prompt.
    #>
    param($Paths = (Get-AtlasCbsRetryPromptPaths))

    if (![IO.File]::Exists($Paths.SavedPrompt)) {
        $property = (Get-ItemProperty -LiteralPath $Paths.EnvironmentKey -ErrorAction Stop).PSObject.Properties['PROMPT']
        $saved = [ordered]@{
            Present = $null -ne $property
            Value   = if ($null -ne $property) { [string]$property.Value } else { '' }
        }
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Paths.SavedPrompt))
        [IO.File]::WriteAllText($Paths.SavedPrompt, ($saved | ConvertTo-Json -Compress),
            (New-Object Text.UTF8Encoding($false)))
    }
    # In PROMPT, $_ is a line break and $P$G the usual path prompt; a literal $ is $$.
    $launcher = (Get-AtlasCbsRetryLauncher).Replace('$', '$$')
    $prompt = 'Atlas: Safe Mode package retry$_Run {0} to retry the packages, or add /discard to give up the retry.$_$_$P$G' -f $launcher
    Set-ItemProperty -LiteralPath $Paths.EnvironmentKey -Name PROMPT -Type String -Value $prompt -ErrorAction Stop
}

function Restore-AtlasCbsRetryPrompt {
    <#
    .SYNOPSIS
        Puts back the machine-wide PROMPT Set-AtlasCbsRetryPrompt replaced. Without a
        saved value there is nothing of Atlas's to undo; an unreadable one removes
        Atlas's prompt, so cmd.exe shows its default again.
    #>
    param($Paths = (Get-AtlasCbsRetryPromptPaths))

    if (![IO.File]::Exists($Paths.SavedPrompt)) { return }
    $saved = try {
        Get-Content -LiteralPath $Paths.SavedPrompt -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch { $null }
    $value = ''
    if ($null -ne $saved -and $null -ne $saved.PSObject.Properties['Present'] -and
        $null -ne $saved.PSObject.Properties['Value'] -and [bool]$saved.Present) {
        $value = [string]$saved.Value
    }
    if ($value) {
        Set-ItemProperty -LiteralPath $Paths.EnvironmentKey -Name PROMPT -Type String -Value $value -ErrorAction Stop
    }
    elseif ($null -ne (Get-ItemProperty -LiteralPath $Paths.EnvironmentKey -ErrorAction Stop).PSObject.Properties['PROMPT']) {
        Remove-ItemProperty -LiteralPath $Paths.EnvironmentKey -Name PROMPT -ErrorAction Stop
    }
    [IO.File]::Delete($Paths.SavedPrompt)
}

function Get-AtlasLegacyCbsRetryStatePath {
    Join-Path ([Environment]::GetFolderPath('Windows')) `
        'System32\safeModePackagesToInstall.atlasmodule'
}

function Get-AtlasLegacyCbsRetryShell {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', $false)
    if ($null -eq $key) { return '' }
    try {
        return [string]$key.GetValue('Shell', '',
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    }
    finally { $key.Dispose() }
}

function Remove-AtlasLegacyCbsRetryList {
    <#
    .SYNOPSIS
        Removes the Safe Mode package list Atlas 0.5 left in System32. 0.5 never deleted
        it, so it records a past component failure, not a retry to resume. It's kept
        only while 0.5's own retry is still set to run, which replacing Atlas's files
        would break.
    #>
    param([string]$Path = (Get-AtlasLegacyCbsRetryStatePath))

    if (![IO.File]::Exists($Path)) { return }
    # 0.5 armed its retry by adding packageInstall.ps1 -SafeMode to the Winlogon shell,
    # and that run put the shell back.
    if ((Get-AtlasLegacyCbsRetryShell) -like '*packageInstall.ps1*-SafeMode*') {
        throw 'Atlas 0.5 is still set to retry installing its Windows component packages when Windows next starts. Restart Windows to let it finish, then update Atlas again.'
    }
    $packages = try {
        @(Get-Content -LiteralPath $Path -ErrorAction Stop |
                ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ }) -join ', '
    }
    catch { "unreadable: $($_.Exception.Message)" }
    if ([string]::IsNullOrEmpty($packages)) { $packages = 'none' }
    Write-Output "Removing the Safe Mode package list Atlas 0.5 left at '$Path' (packages: $packages)."
    try { [IO.File]::Delete($Path) }
    catch {
        Write-Warning "The Atlas 0.5 Safe Mode package list '$Path' couldn't be removed: $($_.Exception.Message)"
    }
}

function Read-AtlasCbsRetryState {
    param([string]$Path = (Get-AtlasCbsRetryStatePath))
    if (![IO.File]::Exists($Path)) { return $null }
    $state = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($state.Version -ne 1 -or [string]$state.Phase -notin @('Pending', 'Armed') -or
        @($state.Packages).Count -eq 0) {
        throw "CBS retry state '$Path' is invalid."
    }
    foreach ($package in @($state.Packages)) {
        if ([string]::IsNullOrWhiteSpace([string]$package) -or ![IO.Path]::IsPathRooted([string]$package)) {
            throw "CBS retry state '$Path' contains a non-absolute package path."
        }
    }
    return $state
}

function Write-AtlasCbsRetryState {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Pending', 'Armed')][string]$Phase,
        [Parameter(Mandatory = $true)][string[]]$Packages,
        [string]$Path = (Get-AtlasCbsRetryStatePath)
    )
    if ($Packages.Count -eq 0) { throw 'At least one CBS package is required.' }
    $absolute = @($Packages | ForEach-Object {
        if (![IO.Path]::IsPathRooted($_)) { throw "CBS package path '$_' is not absolute." }
        [IO.Path]::GetFullPath($_)
    })
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    $state = [ordered]@{
        Version = 1; Phase = $Phase; Packages = $absolute
        UpdatedUtc = [DateTime]::UtcNow.ToString('o')
    }
    [IO.File]::WriteAllText($Path, ($state | ConvertTo-Json -Compress),
        (New-Object Text.UTF8Encoding($false)))
    return [pscustomobject]$state
}

function Clear-AtlasCbsRetryState {
    param([string]$Path = (Get-AtlasCbsRetryStatePath))
    if ([IO.File]::Exists($Path)) { [IO.File]::Delete($Path) }
}

function Invoke-WithAtlasCbsRetryLock {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)
    $mutex = New-Object Threading.Mutex($false, $script:AtlasCbsRetryMutexName)
    $held = $false
    try {
        try { $held = $mutex.WaitOne([TimeSpan]::FromSeconds(30)) }
        catch [Threading.AbandonedMutexException] { $held = $true }
        if (!$held) { throw 'Timed out waiting for the Atlas CBS retry lock.' }
        & $Action
    }
    finally {
        if ($held) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Invoke-AtlasCbsRetrySafeMode {
    param([ValidateSet('CommandPrompt', 'Exit')][string]$Mode)
    $requestedMode = $Mode
    if ($null -eq (Get-Command Set-AtlasSafeMode -CommandType Function -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot 'SafeMode.ps1') -LibraryOnly
    }
    Set-AtlasSafeMode -Mode $requestedMode -AllowCbsRetryPending:($requestedMode -ceq 'CommandPrompt')
    if ($requestedMode -ceq 'CommandPrompt') { Set-AtlasCbsRetryPrompt } else { Restore-AtlasCbsRetryPrompt }
}

function Resolve-AtlasCbsRetryInstaller {
    # Servicing needs a TrustedInstaller token. Checking it before Safe Mode or the state
    # changes keeps a retry started with any other token armed, so it can run again.
    $command = Get-Command Install-AtlasCbsPackage -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        $modulePath = Join-Path ([Environment]::GetFolderPath('Windows')) `
            'AtlasModules\Scripts\Modules\Atlas.Software\Atlas.Software.psd1'
        if (![IO.File]::Exists($modulePath)) {
            throw "The installed Atlas.Software module is unavailable at '$modulePath'."
        }
        Import-Module -Name $modulePath -Force -ErrorAction Stop
        $command = Get-Command Install-AtlasCbsPackage -CommandType Function -ErrorAction Stop
    }
    Assert-AtlasPrivilege -TrustedInstaller
    return $command
}

function Invoke-AtlasCbsRetryInstaller {
    param([string[]]$Packages, [Parameter(Mandatory = $true)]$Installer)
    $result = & $Installer -Packages $Packages -LiteralPaths
    if ($null -ne $result -and $null -ne $result.PSObject.Properties['FailedPackages'] -and
        @($result.FailedPackages).Count -ne 0) {
        throw "CBS packages still failed in Safe Mode: $(@($result.FailedPackages) -join ', ')"
    }
    return $result
}

function Enable-AtlasCbsRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string[]]$Packages,
        [string]$StatePath = (Get-AtlasCbsRetryStatePath),
        [scriptblock]$SafeModeCommand
    )
    Invoke-WithAtlasCbsRetryLock {
        $packagesToArm = @($Packages | ForEach-Object {
            if (![IO.Path]::IsPathRooted($_)) { throw "CBS package path '$_' is not absolute." }
            [IO.Path]::GetFullPath($_)
        })
        $existing = Read-AtlasCbsRetryState -Path $StatePath
        if ($null -ne $existing) {
            if ([string]$existing.Phase -ceq 'Armed') { throw 'A CBS retry is already armed.' }
            $existingPackages = @($existing.Packages)
            $samePackages = $existingPackages.Count -eq $packagesToArm.Count
            for ($index = 0; $samePackages -and $index -lt $packagesToArm.Count; $index++) {
                $samePackages = [string]::Equals(
                    [string]$existingPackages[$index], $packagesToArm[$index],
                    [StringComparison]::OrdinalIgnoreCase)
            }
            if (!$samePackages) { throw 'A different CBS retry is already pending.' }
        }
        else {
            [void](Write-AtlasCbsRetryState -Phase Pending -Packages $packagesToArm -Path $StatePath)
        }
        if ($SafeModeCommand) { & $SafeModeCommand 'CommandPrompt' }
        else { Invoke-AtlasCbsRetrySafeMode -Mode CommandPrompt }
        Write-AtlasCbsRetryState -Phase Armed -Packages $packagesToArm -Path $StatePath
    }
}

function Invoke-AtlasCbsRetryRecovery {
    [CmdletBinding()]
    param(
        [string]$StatePath = (Get-AtlasCbsRetryStatePath),
        [scriptblock]$SafeModeCommand,
        [scriptblock]$Installer
    )
    Invoke-WithAtlasCbsRetryLock {
        $state = Read-AtlasCbsRetryState -Path $StatePath
        if ($null -eq $state) { throw 'No CBS retry is pending.' }
        if ([string]$state.Phase -cne 'Armed') {
            throw "The CBS retry is pending but has not been armed for Safe Mode. $(Get-AtlasCbsRetryInstruction -Phase Pending)"
        }
        $install = if ($Installer) { $Installer } else { Resolve-AtlasCbsRetryInstaller }
        if ($SafeModeCommand) { & $SafeModeCommand 'Exit' }
        else { Invoke-AtlasCbsRetrySafeMode -Mode Exit }
        [void](Write-AtlasCbsRetryState -Phase Pending -Packages @($state.Packages) -Path $StatePath)
        [void](Invoke-AtlasCbsRetryInstaller -Packages @($state.Packages) -Installer $install)
        Clear-AtlasCbsRetryState -Path $StatePath
    }
}

function Invoke-AtlasCbsRetryDiscard {
    <#
    .SYNOPSIS
        Gives up a CBS retry: leaves Safe Mode and removes the retry state, so Atlas can
        be updated and its Safe Mode tools work again. Returns whether there was a retry
        to give up.
    #>
    [CmdletBinding()]
    param(
        [string]$StatePath = (Get-AtlasCbsRetryStatePath),
        [scriptblock]$SafeModeCommand
    )
    Invoke-WithAtlasCbsRetryLock {
        # Not read first, so damaged state can be given up too. Atlas refuses every other
        # Safe Mode change while retry state exists, so Safe Mode set now is the retry's.
        if (![IO.File]::Exists($StatePath)) { return $false }
        if ($SafeModeCommand) { & $SafeModeCommand 'Exit' }
        else { Invoke-AtlasCbsRetrySafeMode -Mode Exit }
        Clear-AtlasCbsRetryState -Path $StatePath
        return $true
    }
}

function Clear-AtlasUnarmedCbsRetry {
    <#
    .SYNOPSIS
        Gives up a retry that isn't armed, before Atlas's files are replaced. Arming and
        recovery hold the lock while Pending, so Pending found here is left over: a
        failed Safe Mode retry, or Atlas 0.5's list as an earlier build recorded it.
        Nothing resumes it, and it would block every update.
    #>
    param([string]$StatePath = (Get-AtlasCbsRetryStatePath))
    Invoke-WithAtlasCbsRetryLock {
        $state = Read-AtlasCbsRetryState -Path $StatePath
        if ($null -eq $state -or [string]$state.Phase -cne 'Pending') { return }
        Write-Output "Giving up the CBS retry that was never armed (packages: $(@($state.Packages) -join ', '))."
        Clear-AtlasCbsRetryState -Path $StatePath
        # Arming that failed after setting the prompt leaves it too.
        Restore-AtlasCbsRetryPrompt
    }
}

function Test-AtlasCbsRetryInstallUnfinished {
    # An install that arms the retry ends at its components step, so the rest of it
    # still has to run. Only whether its state file exists: reading it, as
    # Get-AtlasContext does, can throw on damaged state after the retry has worked.
    [IO.File]::Exists((Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\Install\active.json'))
}

function Test-AtlasCbsRetryNormalBoot {
    # A boot state that can't be read counts as Safe Mode.
    $bootState = try {
        [string](Get-CimInstance -ClassName Win32_ComputerSystem -Property BootupState).BootupState
    }
    catch { '' }
    $bootState -eq 'Normal boot'
}

function Request-AtlasCbsRetryRestart {
    if (Read-AtlasYesNo -Question 'Restart Windows now?') {
        $null = & ([IO.Path]::Combine([Environment]::GetFolderPath('System'), 'shutdown.exe')) /r /t 0
    }
}

function Invoke-AtlasCbsRetryCommand {
    <#
    .SYNOPSIS
        Retries the armed packages (Recover) or gives the retry up (Discard), as
        Invoke-AtlasCbsRetry.cmd asks at the Safe Mode command prompt. The broker's
        CbsRetry operation runs Recover again with a TrustedInstaller token. Returns
        the exit code.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Recover', 'Discard')][string]$Mode,
        [string]$StatePath = (Get-AtlasCbsRetryStatePath)
    )

    if ($Mode -ceq 'Recover' -and (Test-AtlasTrustedInstaller)) {
        # The broker's CbsRetry operation gives this process no console, so the
        # transcript and the log keep the outcome.
        try {
            Start-AtlasPhase -Phase 'CbsRetry'
            [void](Invoke-AtlasCbsRetryRecovery -StatePath $StatePath)
            Stop-AtlasPhase
            return 0
        }
        catch {
            Write-AtlasLog -Level Error -Message "The Safe Mode retry of the CBS packages failed: $($_.Exception.Message)" -ErrorRecord $_
            Stop-AtlasPhase -Failed
            return 1
        }
    }

    $title = 'Safe Mode package retry'
    Set-AtlasLogConsoleStyle -Style Interactive
    Write-AtlasTitle -Text $title
    try {
        Assert-AtlasPrivilege -Administrator
        if ($Mode -ceq 'Discard') {
            if (Invoke-AtlasCbsRetryDiscard -StatePath $StatePath) {
                $done = 'The retry was given up. Windows starts normally from the next restart.'
                if (Test-AtlasCbsRetryInstallUnfinished) { $done += ' After the restart, open Atlas to try installing again.' }
                Write-AtlasSuccess -Text $done
                # Safe Mode's command prompt has no Start menu to restart from.
                if (!(Test-AtlasCbsRetryNormalBoot)) { Request-AtlasCbsRetryRestart }
            }
            else { Write-AtlasNote -Text 'No retry was waiting, so nothing was changed.' }
            return 0
        }
        $state = Read-AtlasCbsRetryState -Path $StatePath
        if ($null -eq $state) {
            Write-AtlasNote -Text 'No retry is waiting, so nothing was changed.'
            return 0
        }
        if ([string]$state.Phase -cne 'Armed') {
            throw "The retry isn't set to run in Safe Mode. $(Get-AtlasCbsRetryInstruction -Phase Pending)"
        }
        # Outside Safe Mode the retry would most likely fail as the first attempt did.
        if (Test-AtlasCbsRetryNormalBoot) { throw "The retry runs in Safe Mode. $(Get-AtlasCbsRetryInstruction)" }

        Write-AtlasStep -Text 'Installing the packages again. This can take several minutes...'
        try { [void](Invoke-AtlasTrustedInstaller -Operation CbsRetry -TimeoutSeconds 3600) }
        catch {
            # A retry that reached servicing has already left Safe Mode; say what's left.
            $after = try { Read-AtlasCbsRetryState -Path $StatePath } catch { $null }
            $next = if ($null -ne $after) { " $(Get-AtlasCbsRetryInstruction -Phase ([string]$after.Phase))" } else { '' }
            throw "The packages didn't install: $($_.Exception.Message)$next"
        }
    }
    catch {
        Write-AtlasLog -Level Error -Message "$title failed: $($_.Exception.Message)" -ErrorRecord $_ -NoConsole
        Write-AtlasNotApplied -Title $title -Reason $_.Exception.Message -DetailsPath (Get-AtlasInstallLogPath)
        return 1
    }

    $done = 'The packages are installed. Windows starts normally from the next restart.'
    if (Test-AtlasCbsRetryInstallUnfinished) { $done += ' After the restart, open Atlas to finish installing it.' }
    Write-AtlasSuccess -Text $done
    Request-AtlasCbsRetryRestart
    return 0
}

if (!$LibraryOnly) {
    if ($Recover -eq $Discard) { throw 'Specify -Recover or -Discard, or use -LibraryOnly.' }
    $scriptsRoot = [IO.Path]::GetDirectoryName($PSScriptRoot)
    $trustBootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
    if (![IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap
    $ErrorActionPreference = 'Stop'
    Import-Module -Name ([IO.Path]::Combine($scriptsRoot, 'Modules', 'Atlas.Core', 'Atlas.Core.psd1')) `
        -Force -ErrorAction Stop
    exit (Invoke-AtlasCbsRetryCommand -Mode $(if ($Recover) { 'Recover' } else { 'Discard' }))
}
