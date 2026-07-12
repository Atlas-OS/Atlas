# Features phase.
# Windows optional-feature work via DISM: enable DirectPlay, remove the Steps Recorder
# capability (fresh installs only), and clean the component store. Runs as TrustedInstaller; requires
# online sources, so its custom.yml call lives inside the NO LOCAL BUILD marker block.
Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext
$dism = Join-Path -Path $context.WinDir -ChildPath 'System32\dism.exe'

function Invoke-AtlasDism {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Write-AtlasLog -Message "DISM: $Description"
    $output = & $dism @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    # 0 = success; 3010 = success, reboot required. Anything else is a failure.
    if ($exitCode -ne 0 -and $exitCode -ne 3010) {
        $detail = (@($output) | ForEach-Object { "$_" }) -join ' '
        throw "DISM '$Description' failed with exit code $exitCode. Output: $detail"
    }
}

Invoke-AtlasDism -Description 'Enabling DirectPlay' -Arguments @(
    '/Online', '/Enable-Feature', '/FeatureName:DirectPlay', '/NoRestart', '/All'
)

if (-not $context.IsUpgrade) {
    Invoke-AtlasDism -Description 'Removing the Steps Recorder capability' -Arguments @(
        '/Online', '/Remove-Capability', '/CapabilityName:App.StepsRecorder~~~~0.0.1.0', '/NoRestart'
    )
}

Invoke-AtlasDism -Description 'Cleaning the component store' -Arguments @(
    '/Online', '/Cleanup-Image', '/StartComponentCleanup'
)
