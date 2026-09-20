# Features phase.
# Windows optional-feature work via DISM: enable DirectPlay, remove the Steps Recorder
# capability (fresh installs only), and clean the component store. Runs as
# TrustedInstaller and requires online component sources.
Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext
$dism = Join-Path -Path $context.WinDir -ChildPath 'System32\dism.exe'

function Get-AtlasDismExitDisposition {
    param(
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [int[]]$DeferredExitCode = @()
    )

    if ($ExitCode -eq 0 -or $ExitCode -eq 3010) {
        return 'Success'
    }
    if ($DeferredExitCode -contains $ExitCode) {
        return 'Deferred'
    }
    return 'Failure'
}

function Invoke-AtlasDism {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description,
        [int[]]$DeferredExitCode = @()
    )

    Write-AtlasLog -Message "DISM: $Description"
    $output = & $dism @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $disposition = Get-AtlasDismExitDisposition `
        -ExitCode $exitCode -DeferredExitCode $DeferredExitCode
    if ($disposition -ceq 'Deferred') {
        Write-AtlasLog -Level Warning -Message (
            "DISM '$Description' was deferred because Windows has pending operations " +
            "(exit code $exitCode). Component cleanup can complete after reboot."
        )
        return
    }
    if ($disposition -ceq 'Failure') {
        $detail = (@($output) | ForEach-Object { "$_" }) -join ' '
        throw "DISM '$Description' failed with exit code $exitCode. Output: $detail"
    }
}

function Remove-AtlasStepsRecorder {
    # Enumerate instead of querying a hard-coded name: Windows can remove the
    # capability from its catalog altogether, making that name an error (87).
    $capabilities = @(Dism\Get-WindowsCapability -Online -ErrorAction Stop | Where-Object {
        $_.Name -like 'App.StepsRecorder~~~~*'
    })
    if ($capabilities.Count -eq 0) {
        Write-AtlasLog -Message 'Steps Recorder is not listed as a Windows capability; skipping removal.'
        return
    }
    foreach ($capability in $capabilities) {
        if ([string]$capability.State -eq 'NotPresent') {
            Write-AtlasLog -Message "Steps Recorder capability '$($capability.Name)' is already absent; skipping removal."
            continue
        }
        if ([string]$capability.State -ne 'Installed') {
            throw "Steps Recorder capability '$($capability.Name)' has unexpected state '$($capability.State)'. Complete pending Windows servicing and restart before retrying."
        }
        Invoke-AtlasDism -Description 'Removing the Steps Recorder capability' -Arguments @(
            '/Online', '/Remove-Capability', "/CapabilityName:$($capability.Name)", '/NoRestart'
        )
    }
}

function Enable-AtlasDirectPlay {
    $feature = Dism\Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction Stop
    if ([string]$feature.State -eq 'Enabled') {
        Write-AtlasLog -Message 'DirectPlay is already enabled; skipping change.'
        return
    }
    Invoke-AtlasDism -Description 'Enabling DirectPlay' -Arguments @(
        '/Online', '/Enable-Feature', '/FeatureName:DirectPlay', '/NoRestart', '/All'
    )
}

Enable-AtlasDirectPlay

if (-not $context.IsUpgrade) {
    Remove-AtlasStepsRecorder
}

Invoke-AtlasDism -Description 'Cleaning the component store' -Arguments @(
    '/Online', '/Cleanup-Image', '/StartComponentCleanup'
) -DeferredExitCode @(-2146498554) # 0x800f0806: pending operations
