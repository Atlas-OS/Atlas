# Components phase.
# Removes Windows components: the Security Center startup item, Smart App Control,
# Microsoft Edge (option gated), OneDrive, the Teams chat auto-install policy and the
# CBS component packages (option gated). Runs as TrustedInstaller; child-script and
# CBS package failures throw to the one-shot orchestrator, which returns the install's
# single nonzero status to the custom.yml shim.
#
# Not handled here: the 'iso: only' OfflineSys WdBoot delete (AME-only, in custom.yml)
# and Edge's installed/provisioned package-family removal (the AppxSupport phase).

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Services\Atlas.Services.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force -ErrorAction Stop

# Preserve the former components.yml ordering without an elevated-user identity split.
# Machine removal runs in a fixed child contract under this TI token; user-owned HKCU and
# LocalAppData cleanup is a separate exact-user process and is omitted during OOBE.
if (Test-AtlasOption -Name 'uninstall-edge') {
    $context = Get-AtlasContext
    $powerShellExe = [IO.Path]::Combine(
        [Environment]::SystemDirectory,
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe'
    )
    $removeEdgeScript = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal\Remove-Edge.ps1'
    Invoke-AtlasHiddenProcess -FilePath $powerShellExe -ArgumentList @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', $removeEdgeScript,
        '-UninstallEdge', '-KeepAppX', '-NonInteractive', '-MachineContext'
    ) -Wait | Out-Null

    if (-not $context.IsOobe) {
        $interactiveUserSid = [string]$context.InteractiveUserSid
        if ([string]::IsNullOrWhiteSpace($interactiveUserSid)) {
            throw 'Edge current-user cleanup requires the install-state user SID.'
        }
        $userCleanupScript = Join-Path -Path (Split-Path -Parent $PSScriptRoot) `
            -ChildPath 'Internal\Remove-EdgeCurrentUserData.ps1'
        $userArguments = ConvertTo-AtlasWindowsArgumentString -ArgumentList ([string[]]@(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', $userCleanupScript,
            '-ExpectedUserSid', $interactiveUserSid
        ))
        $userExitCode = Invoke-AtlasAsUser -FilePath $powerShellExe -Arguments $userArguments
        if ($userExitCode -ne 0) {
            throw "Exact-user Edge data cleanup failed with exit code $userExitCode."
        }
    }
}

# Remove Security Center startup item
Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'SecurityHealth' -Force -ErrorAction SilentlyContinue

# Disable Smart App Control
# Causes slow app loading issues and sends data to Microsoft
$ciPolicyKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy'
if (-not (Test-Path -LiteralPath $ciPolicyKey)) {
    New-Item -Path $ciPolicyKey -Force | Out-Null
}
Set-ItemProperty -LiteralPath $ciPolicyKey -Name 'VerifiedAndReputablePolicyState' -Value 0 -Type DWord -Force

# Microsoft Edge
if (Test-AtlasOption -Name 'uninstall-edge') {
    $edgeServices = @('edgeupdate', 'edgeupdatem', 'MicrosoftEdgeUpdate', 'MicrosoftEdgeElevationService')
    foreach ($service in $edgeServices) {
        Stop-AtlasService -Name $service
    }
    foreach ($service in $edgeServices) {
        # Edge service names vary across supported package/build combinations.
        Set-AtlasServiceStartup -Name $service -StartupType 4 -AllowMissing
    }

    Remove-AtlasScheduledTask -Path 'MicrosoftEdgeUpdateTaskMachineCore' -IgnoreMissing
    Remove-AtlasScheduledTask -Path 'MicrosoftEdgeUpdateTaskMachineUA' -IgnoreMissing

    # This block handles the pieces that need TrustedInstaller: services, scheduled
    # tasks and the deprovision keys. The checked AppxSupport phase removes Edge's
    # installed and provisioned packages afterward.

    foreach ($deprovisionKey in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
    )) {
        New-Item -Path $deprovisionKey -Force | Out-Null
    }
}

# OneDrive
# The actual OneDrive setup in Windows is stripped at a component-level in the miscellaneous package
try {
    Remove-AtlasOneDrive
}
catch {
    Write-AtlasLog -Level Warning -Message "Removing OneDrive failed: $($_.Exception.Message)"
}

# Windows components and Telemetry (CBS packages)
# Install-AtlasCbsPackage throws on failure after registering the Safe Mode retry
# fallback, making this ordered step fail so the orchestrator returns nonzero.
if (Test-AtlasOption -Name 'defender-disable') {
    Install-AtlasCbsPackage -Packages @(
        '*Z-Atlas-NoDefender-Package*',
        '*Z-Atlas-NoTelemetry-Package*'
    ) -NonInteractive | Out-Null

    # MDCoreSvc (Defender Core Service) survives the NoDefender package but its binary is
    # removed with Defender, so SCM fails it 0x80070002 (event 7023) on every boot. The
    # Start value can't be changed here: Defender Tamper Protection is still enforced at
    # the kernel level through this phase and denies the write even as TrustedInstaller.
    # Defer it to a one-shot startup task that runs after the install reboot, once Defender
    # is fully gone and the write succeeds.
    $mdCoreTaskName = 'AtlasDisableMDCoreSvc'
    $mdCoreArgs = "/c schtasks /delete /tn `"$mdCoreTaskName`" /f > nul & " `
        + "reg add `"HKLM\SYSTEM\CurrentControlSet\Services\MDCoreSvc`" /v Start /t REG_DWORD /d 4 /f > nul"
    $mdCoreTask = @{
        'TaskName'  = $mdCoreTaskName
        'Settings'  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        'Trigger'   = New-ScheduledTaskTrigger -AtStartup
        'Principal' = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        'Force'     = $true
        'Action'    = New-ScheduledTaskAction -Execute 'cmd' -Argument $mdCoreArgs
    }
    Register-ScheduledTask @mdCoreTask | Out-Null
}
if (Test-AtlasOption -Name 'defender-enable') {
    Uninstall-AtlasCbsPackage -Packages @('*Z-Atlas-NoDefender-Package*') | Out-Null
    Install-AtlasCbsPackage -Packages @('*Z-Atlas-NoTelemetry-Package*') -NonInteractive | Out-Null
}

# Prevent Teams chat from being reinstalled. This key is TrustedInstaller-protected,
# which is why the write belongs in this phase rather than the AppX snapshot phase
# or an AME !registryValue action.
$communicationsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications'
if (-not (Test-Path -LiteralPath $communicationsKey)) {
    New-Item -Path $communicationsKey -Force | Out-Null
}
Set-ItemProperty -LiteralPath $communicationsKey -Name 'ConfigureChatAutoInstall' -Value 0 -Type DWord -Force
