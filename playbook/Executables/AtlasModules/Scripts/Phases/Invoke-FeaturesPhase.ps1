# Features phase.
# Windows optional-feature work via DISM: enable DirectPlay, remove the Steps Recorder
# capability (fresh installs only), and clean the component store. Runs elevated; requires
# online sources, so its shim call lives inside the NO LOCAL BUILD block of atlas\start.yml.
Assert-AtlasPrivilege -Administrator

$context = Get-AtlasContext
$dism = Join-Path -Path $context.WinDir -ChildPath 'System32\dism.exe'

function Invoke-AtlasDism {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Write-AtlasLog -Message "DISM: $Description"
    $output = & $dism @Arguments 2>&1
    # 0 = success; 3010 = success, reboot required. Anything else is a failure.
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
        $detail = (@($output) | ForEach-Object { "$_" }) -join ' '
        Write-AtlasLog -Message "DISM '$Description' exited with code $LASTEXITCODE - $detail" -Level Warning
    }
}

Invoke-AtlasDism -Description 'Enabling DirectPlay' -Arguments @(
    '/Online', '/Enable-Feature', '/FeatureName:DirectPlay', '/NoRestart', '/All'
)

# The Steps Recorder capability is removed only on fresh installs (matching the old
# onUpgrade: false action).
if (-not $context.IsUpgrade) {
    Invoke-AtlasDism -Description 'Removing the Steps Recorder capability' -Arguments @(
        '/Online', '/Remove-Capability', '/CapabilityName:App.StepsRecorder~~~~0.0.1.0', '/NoRestart'
    )
}

Invoke-AtlasDism -Description 'Cleaning the component store' -Arguments @(
    '/Online', '/Cleanup-Image', '/StartComponentCleanup'
)
