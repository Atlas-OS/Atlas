# Components phase.
# Removes Windows components: the Security Center startup item, Smart App Control,
# Microsoft Edge (option gated), OneDrive, the Teams chat auto-install policy and the
# CBS component packages (option gated). Runs as TrustedInstaller; child-script and
# CBS package failures throw to the one-shot orchestrator, which returns the install's
# single nonzero status to the custom.yml shim.
#
# Not handled here: Edge's installed/provisioned package-family removal (the AppxSupport phase).

Assert-AtlasPrivilege -TrustedInstaller

$scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Services\Atlas.Services.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Security\Atlas.Security.psd1') -Force -ErrorAction Stop
# Shared with the Choices phase, which applies the same choices on a Choose again update.
. (Join-Path $scriptsRoot 'Install\Tasks\Set-AtlasDefenderChoice.ps1')
. (Join-Path $scriptsRoot 'Install\Tasks\Invoke-AtlasEdgeRemoval.ps1')

$powerShellExe = [IO.Path]::Combine(
    [Environment]::SystemDirectory,
    'WindowsPowerShell',
    'v1.0',
    'powershell.exe'
)

# A Rebase leaves Edge and OneDrive when they were installed before Windows moved:
# someone, on any account, kept or put them back and may use them. Without the
# record, both are left.
$keepEdge = $false
$keepOneDrive = $false
if ((Get-AtlasContext).IsRebase) {
    . (Join-Path $scriptsRoot 'Preparation\WindowsTransition.ps1')
    $rebase = Get-AtlasWindowsTransitionRebase
    $keepEdge = $null -eq $rebase -or [bool]$rebase.Carry.edge
    $keepOneDrive = $null -eq $rebase -or [bool]$rebase.Carry.oneDrive
    if ($keepEdge -and (Test-AtlasOption -Name 'uninstall-edge')) { Write-AtlasLog -Message 'Left Edge: it was installed before Windows moved.' }
    if ($keepOneDrive) { Write-AtlasLog -Message 'Left OneDrive: it was installed before Windows moved.' }
}
$removeEdge = (Test-AtlasOption -Name 'uninstall-edge') -and -not $keepEdge

if ($removeEdge) {
    Invoke-AtlasEdgeRemoval -ScriptsRoot $scriptsRoot -Context (Get-AtlasContext)
}

Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'SecurityHealth' -Force -ErrorAction SilentlyContinue

# Turn off Smart App Control: it slows app loading and sends data to Microsoft.
$ciPolicyKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy'
if (-not (Test-Path -LiteralPath $ciPolicyKey)) {
    New-Item -Path $ciPolicyKey -Force | Out-Null
}
Set-ItemProperty -LiteralPath $ciPolicyKey -Name 'VerifiedAndReputablePolicyState' -Value 0 -Type DWord -Force

# Windows keeps the inbox OneDriveSetup.exe; Atlas doesn't strip it at component level.
# Uninstall and machine cleanup run here as TrustedInstaller; HKCU and profile leftovers
# are cleaned only in the installing user's own token.
try {
    if (-not $keepOneDrive) { Remove-AtlasOneDrive }
}
catch {
    $containmentUnconfirmed = $false
    for ($exception = $_.Exception; $null -ne $exception; $exception = $exception.InnerException) {
        if ($exception.Data.Contains('AtlasProcessMayStillBeRunning') -and
            [bool]$exception.Data['AtlasProcessMayStillBeRunning']) {
            $containmentUnconfirmed = $true
            break
        }
    }
    if ($containmentUnconfirmed) {
        throw
    }
    Write-AtlasLog -Level Warning -Message "Removing OneDrive failed: $($_.Exception.Message)"
}

$oneDriveContext = Get-AtlasContext
if (-not $oneDriveContext.IsOobe -and -not $keepOneDrive) {
    $interactiveUserSid = [string]$oneDriveContext.InteractiveUserSid
    if ([string]::IsNullOrWhiteSpace($interactiveUserSid)) {
        throw 'OneDrive current-user cleanup requires the install-state user SID.'
    }
    $oneDriveUserScript = Join-Path -Path $scriptsRoot `
        -ChildPath 'Operations\Remove-OneDriveCurrentUserData.ps1'
    $oneDriveUserArguments = ConvertTo-AtlasWindowsArgumentString -ArgumentList ([string[]]@(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', $oneDriveUserScript,
        '-ExpectedUserSid', $interactiveUserSid, '-DeferFileCleanup'
    ))
    $oneDriveCleanupStarted = [datetime]::UtcNow
    $oneDriveUserExitCode = Invoke-AtlasAsUser -FilePath $powerShellExe `
        -Arguments $oneDriveUserArguments
    if ($oneDriveUserExitCode -ne 0) {
        # OneDrive can leave locked cache files or profile-specific state that its
        # own uninstaller cannot remove. Machine removal is already complete here;
        # optional user-owned leftovers must not make the Atlas install fail.
        . (Join-Path $scriptsRoot 'Install\Tasks\Get-AtlasUserFailureDetail.ps1')
        $failureDetail = Get-AtlasUserFailureDetail -UserSid $interactiveUserSid `
            -TranscriptPattern '*-onedrive-cleanup-*.log' -NotBefore $oneDriveCleanupStarted
        Write-AtlasLog -Level Warning -Message `
            "Exact-user OneDrive leftover cleanup exited with code $oneDriveUserExitCode; continuing because only user-owned cleanup remains.$failureDetail"
    }
}

# Windows components and Telemetry (CBS packages)
# Install-AtlasCbsPackage throws on failure after registering the Safe Mode retry
# fallback, making this ordered step fail so the orchestrator returns nonzero. A
# Rebase is a first installation too: the Windows that rebuilt itself lost Atlas's
# packages, so both choices put NoTelemetry back as a Fresh install does.
if (Test-AtlasOption -Name 'defender-disable') {
    $null = Set-AtlasDefenderChoice -State Disable -Fresh
}
if (Test-AtlasOption -Name 'defender-enable') {
    $null = Set-AtlasDefenderChoice -State Enable -Fresh
}

# Prevent Teams chat from being reinstalled. This key is TrustedInstaller-protected,
# which is why the write belongs in this phase rather than the AppX snapshot phase
# or an AME !registryValue action.
$communicationsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications'
if (-not (Test-Path -LiteralPath $communicationsKey)) {
    New-Item -Path $communicationsKey -Force | Out-Null
}
Set-ItemProperty -LiteralPath $communicationsKey -Name 'ConfigureChatAutoInstall' -Value 0 -Type DWord -Force
