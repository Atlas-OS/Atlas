# Microsoft Edge's removal for the uninstall-edge choice, shared by the Components phase
# (Fresh and Rebase) and the Choices phase (Choose again). Runs as TrustedInstaller; the
# phase imports Atlas.Core and Atlas.Services.
#
# Not handled here: Edge's installed and provisioned package families (Atlas.Appx).

function Invoke-AtlasEdgeRemoval {
    <#
    .SYNOPSIS
        Removes Microsoft Edge for the whole PC, cleans the installing user's Edge
        leftovers in their own process, keeps Edge's elevation service off and
        deprovisions both Edge package families.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptsRoot,

        # The install context: IsOobe and the installing user's InteractiveUserSid.
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Context
    )

    $powerShellExe = [IO.Path]::Combine(
        [Environment]::SystemDirectory,
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe'
    )

    # Edge's machine removal runs under this TrustedInstaller token; the installing user's
    # leftovers are cleaned in their own process, which is skipped during OOBE.
    $removeEdgeScript = Join-Path -Path $ScriptsRoot -ChildPath 'Operations\Remove-Edge.ps1'
    Invoke-AtlasHiddenProcess -FilePath $powerShellExe -ArgumentList @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', $removeEdgeScript,
        '-UninstallEdge', '-NonInteractive', '-MachineContext'
    ) -Wait | Out-Null

    if (-not $Context.IsOobe) {
        $interactiveUserSid = [string]$Context.InteractiveUserSid
        if ([string]::IsNullOrWhiteSpace($interactiveUserSid)) {
            throw 'Edge current-user cleanup requires the install-state user SID.'
        }
        $userCleanupScript = Join-Path -Path $ScriptsRoot `
            -ChildPath 'Operations\Remove-EdgeCurrentUserData.ps1'
        $userArguments = ConvertTo-AtlasWindowsArgumentString -ArgumentList ([string[]]@(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', $userCleanupScript,
            '-ExpectedUserSid', $interactiveUserSid
        ))
        $edgeCleanupStarted = [datetime]::UtcNow
        $userExitCode = Invoke-AtlasAsUser -FilePath $powerShellExe -Arguments $userArguments
        if ($userExitCode -ne 0) {
            # Machine removal completed. Optional user-owned leftovers must not block
            # the remaining install phases; the child still refuses unsafe paths or identities.
            . (Join-Path $ScriptsRoot 'Install\Tasks\Get-AtlasUserFailureDetail.ps1')
            $failureDetail = Get-AtlasUserFailureDetail -UserSid $interactiveUserSid `
                -TranscriptPattern '*-edge-cleanup-*.log' -NotBefore $edgeCleanupStarted
            Write-AtlasLog -Level Warning -Message `
                "Exact-user Edge leftover cleanup exited with code $userExitCode; continuing installation.$failureDetail"
        }
    }

    # Remove-Edge.ps1 already stopped and disabled Edge's services; this keeps them off if one is left.
    foreach ($service in @('MicrosoftEdgeElevationService')) {
        # Edge service names vary across supported package/build combinations.
        Set-AtlasServiceStartup -Name $service -StartupType 4 -AllowMissing
    }

    # Keep the shared EdgeUpdate services and tasks for WebView2. This block handles
    # browser services and deprovision keys. The checked AppX removal takes Edge's
    # installed and provisioned packages off afterward.

    foreach ($deprovisionKey in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
    )) {
        New-Item -Path $deprovisionKey -Force | Out-Null
    }
}
